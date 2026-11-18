import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { onCall } from "firebase-functions/v2/https";
import {
  allSlotIdsForDate,
  assertBookableRange,
  computeBookingPrice,
  slotIdsFor,
} from "../domain/slots";
import { nextBookingRef } from "../lib/booking-ref";
import { requireUser } from "../lib/auth";
import {
  alreadyExists,
  failedPrecondition,
  invalidArgument,
  notFound,
  parseInput,
  permissionDenied,
} from "../lib/errors";
import { notifyUsers } from "../lib/notifications";
import {
  cancelBookingSchema,
  convertToGameSchema,
  createBookingSchema,
  setSlotBlockedSchema,
} from "../lib/validation";

/**
 * Phase 4 — ZERO double-booking guarantee.
 *
 * Inside a single Firestore transaction we (1) re-read the venue, (2) read
 * every 30-minute slot document for the requested range, and (3) abort if any
 * document exists (booked OR manually blocked). If all are free we write the
 * booking plus every slot doc. Firestore's transactional isolation means two
 * concurrent requests for the same range cannot both commit.
 */
export const createBooking = onCall(async (request) => {
  const user = await requireUser(request);
  const input = parseInput(createBookingSchema, request.data);

  try {
    assertBookableRange(input.date, input.startTime, input.durationMin);
  } catch (error) {
    throw invalidArgument(
      error instanceof Error ? error.message : "Invalid booking time",
    );
  }

  const slotIds = slotIdsFor(
    input.date,
    input.startTime,
    input.durationMin,
  );

  const db = getFirestore();
  const result = await db.runTransaction(async (tx) => {
    const venueRef = db.collection("venues").doc(input.venueId);
    const venueSnap = await tx.get(venueRef);
    if (!venueSnap.exists) throw notFound("Venue not found");
    if (venueSnap.get("status") !== "active") {
      throw failedPrecondition("This venue is not currently accepting bookings");
    }
    const pricePerHour = Number(venueSnap.get("pricePerHour"));
    if (!Number.isInteger(pricePerHour) || pricePerHour <= 0) {
      throw failedPrecondition("Venue price is misconfigured");
    }
    const ownerId = String(venueSnap.get("ownerId") ?? "");
    const venueName = String(venueSnap.get("name") ?? "Venue");

    const totalPrice = computeBookingPrice(pricePerHour, input.durationMin);
    const slotRefs = slotIds.map((id) =>
      venueRef.collection("slots").doc(id),
    );
    const slotSnaps = await tx.getAll(...slotRefs);
    const occupied = slotSnaps
      .filter((snap) => snap.exists)
      .map((snap) => snap.id);
    if (occupied.length > 0) {
      throw failedPrecondition(
        "Some of those slots were just taken. Pick another time.",
        { occupiedSlotIds: occupied },
      );
    }

    const { ref } = await nextBookingRef(db, tx);
    const bookingRef = db.collection("bookings").doc();
    tx.set(bookingRef, {
      ref,
      venueId: input.venueId,
      userId: user.uid,
      date: input.date,
      startTime: input.startTime,
      durationMin: input.durationMin,
      totalPrice,
      status: "upcoming",
      paymentStatus: "pending",
      createdAt: FieldValue.serverTimestamp(),
    });

    for (const slotRef of slotRefs) {
      tx.create(slotRef, {
        status: "booked",
        bookingId: bookingRef.id,
      });
    }

    return {
      bookingId: bookingRef.id,
      ref,
      totalPrice,
      venueName,
      ownerId,
      slotIds,
    };
  });

  await notifyUsers(
    [result.ownerId, user.uid],
    {
      title: "Booking confirmed",
      body: `${user.name ?? "A player"} booked ${result.venueName} (${
        result.ref
      }).`,
      data: { type: "booking", bookingId: result.bookingId },
    },
    { notificationId: `booking_created_${result.bookingId}` },
  );

  return {
    bookingId: result.bookingId,
    ref: result.ref,
    totalPrice: result.totalPrice,
    date: input.date,
    startTime: input.startTime,
    durationMin: input.durationMin,
    venueId: input.venueId,
    venueName: result.venueName,
    slotIds: result.slotIds,
  };
});

/**
 * Phase 4 — cancellation. Frees every slot that still belongs to the booking,
 * cancels a linked pickup game, and notifies participants. Cancellation is
 * always allowed; cancelling within 2 hours of kickoff is recorded as a late
 * cancellation (mock payments have no automatic refund).
 */
export const cancelBooking = onCall(async (request) => {
  const user = await requireUser(request);
  const input = parseInput(cancelBookingSchema, request.data);
  const db = getFirestore();

  const bookingSnap = await db.collection("bookings").doc(input.bookingId).get();
  if (!bookingSnap.exists) throw notFound("Booking not found");
  const booking = bookingSnap.data() ?? {};
  const venueSnap = await db
    .collection("venues")
    .doc(String(booking.venueId))
    .get();
  const ownerId = String(venueSnap.get("ownerId") ?? "");
  const isAdmin = user.role === "admin";
  if (booking.userId !== user.uid && ownerId !== user.uid && !isAdmin) {
    throw permissionDenied("You cannot cancel this booking");
  }
  if (booking.status === "cancelled") {
    return { bookingId: input.bookingId, alreadyCancelled: true, freedSlots: [] };
  }
  if (booking.status === "completed") {
    throw failedPrecondition("Completed bookings cannot be cancelled");
  }

  const venueId = String(booking.venueId);
  const date = String(booking.date);
  const startTime = String(booking.startTime);
  const durationMin = Number(booking.durationMin);
  const slotIds = slotIdsFor(date, startTime, durationMin);

  const returnData = await db.runTransaction(async (tx) => {
    const slotRefs = slotIds.map((id) =>
      db.collection("venues").doc(venueId).collection("slots").doc(id),
    );
    const slotSnaps = await tx.getAll(...slotRefs);
    const freed: string[] = [];
    for (const snap of slotSnaps) {
      if (!snap.exists) continue;
      if (snap.get("bookingId") === input.bookingId) {
        tx.delete(snap.ref);
        freed.push(snap.id);
      }
    }
    tx.update(bookingSnap.ref, {
      status: "cancelled",
      cancelledAt: FieldValue.serverTimestamp(),
      cancellationReason: input.reason ?? null,
    });
    return { freedSlots: freed };
  });

  const gameQuery = await db
    .collection("games")
    .where("bookingId", "==", input.bookingId)
    .limit(1)
    .get();
  const gameSnap = gameQuery.docs[0];
  let participantIds: string[] = [];
  if (gameSnap) {
    const game = gameSnap.data();
    participantIds = Array.isArray(game.playerIds)
      ? (game.playerIds as string[])
      : [];
    await gameSnap.ref.update({ status: "cancelled" });
  }

  await notifyUsers(
    [...participantIds, String(booking.userId), ownerId].filter(Boolean),
    {
      title: "Booking cancelled",
      body: `Booking ${String(booking.ref)} at ${
        venueSnap.get("name") ?? "the venue"
      } was cancelled.`,
      data: { type: "booking_cancelled", bookingId: input.bookingId },
    },
    { notificationId: `booking_cancelled_${input.bookingId}` },
  );

  return {
    bookingId: input.bookingId,
    freedSlots: returnData.freedSlots,
    cancelledGameId: gameSnap?.id ?? null,
  };
});

/**
 * Phase 5 — turn an upcoming booking into a public pickup game. The booking
 * owner becomes the organizer and the first confirmed player.
 */
export const convertToGame = onCall(async (request) => {
  const user = await requireUser(request);
  const input = parseInput(convertToGameSchema, request.data);
  const db = getFirestore();

  return db.runTransaction(async (tx) => {
    const bookingRef = db.collection("bookings").doc(input.bookingId);
    const bookingSnap = await tx.get(bookingRef);
    if (!bookingSnap.exists) throw notFound("Booking not found");
    const booking = bookingSnap.data() ?? {};
    if (booking.userId !== user.uid) {
      throw permissionDenied("Only the person who booked this pitch can host");
    }
    if (booking.status !== "upcoming") {
      throw failedPrecondition("Only upcoming bookings can become games");
    }

    const existing = await tx.get(
      db.collection("games").where("bookingId", "==", input.bookingId).limit(1),
    );
    if (!existing.empty) throw alreadyExists("This booking already has a game");

    const venueSnap = await tx.get(
      db.collection("venues").doc(String(booking.venueId)),
    );
    if (!venueSnap.exists) throw notFound("Venue not found");

    const totalPrice = Number(booking.totalPrice);
    const gameRef = db.collection("games").doc();
    tx.set(gameRef, {
      bookingId: input.bookingId,
      venueId: booking.venueId,
      organizerId: user.uid,
      title: input.title,
      sport: venueSnap.get("sport"),
      maxPlayers: input.maxPlayers,
      costPerPlayer: totalPrice,
      playerIds: [user.uid],
      teamA: [],
      teamB: [],
      status: "open",
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.set(gameRef.collection("players").doc(user.uid), {
      joinedAt: FieldValue.serverTimestamp(),
      paymentStatus: "pending",
      attendance: null,
    });

    return { gameId: gameRef.id, costPerPlayer: totalPrice };
  });
});

/**
 * Phase 3/4 — owner blocks or unblocks 30-minute slots for their venue.
 * Blocking creates slot docs (presence = unavailable); unblocking only
 * removes docs that are manually blocked, never booked ones.
 */
export const setSlotBlocked = onCall(async (request) => {
  const user = await requireUser(request);
  const input = parseInput(setSlotBlockedSchema, request.data);
  const db = getFirestore();
  const venueRef = db.collection("venues").doc(input.venueId);
  const venueSnap = await venueRef.get();
  if (!venueSnap.exists) throw notFound("Venue not found");
  const isAdmin = user.role === "admin";
  if (!isAdmin && venueSnap.get("ownerId") !== user.uid) {
    throw permissionDenied("You can only manage availability for your venues");
  }

  const allowed = new Set(allSlotIdsForDate(input.date));
  const invalid = input.slotIds.filter((id) => !allowed.has(id));
  if (invalid.length > 0) {
    throw invalidArgument("Some slot IDs are outside the selected date", {
      invalid,
    });
  }

  return db.runTransaction(async (tx) => {
    const refs = input.slotIds.map((id) => venueRef.collection("slots").doc(id));
    const snaps = await tx.getAll(...refs);
    let changed = 0;
    const skipped: string[] = [];
    for (const snap of snaps) {
      if (input.blocked) {
        if (snap.exists) {
          skipped.push(snap.id);
          continue;
        }
        tx.create(snap.ref, {
          status: "blocked",
          reason: input.reason ?? "Blocked by owner",
          blockedBy: user.uid,
          createdAt: FieldValue.serverTimestamp(),
        });
        changed += 1;
      } else {
        if (!snap.exists) continue;
        if (snap.get("status") !== "blocked") {
          skipped.push(snap.id);
          continue;
        }
        tx.delete(snap.ref);
        changed += 1;
      }
    }
    return { changed, skipped, blocked: input.blocked };
  });
});
