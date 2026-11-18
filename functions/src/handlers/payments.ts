import { createHmac, timingSafeEqual } from "node:crypto";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { onCall, onRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { z } from "zod";
import { computeCostSplit, amountForPlayer } from "../domain/cost";
import { requireUser } from "../lib/auth";
import {
  failedPrecondition,
  invalidArgument,
  notFound,
  parseInput,
  permissionDenied,
} from "../lib/errors";
import { notifyUsers } from "../lib/notifications";
import {
  initiatePaymentSchema,
  simulatePaymentSchema,
} from "../lib/validation";
import { getPaymentProvider } from "../payments";

type SettleStatus = "success" | "failed";

interface SettleInput {
  paymentId: string;
  providerRef: string;
  status: SettleStatus;
  source: string;
}

/**
 * Single idempotent settlement path used by both the HTTP webhook and the
 * emulator-only simulator. A payment may settle from `pending` exactly once;
 * later callbacks are acknowledged without side effects.
 */
export async function settlePayment(input: SettleInput): Promise<{
  paymentId: string;
  status: SettleStatus | "pending";
  alreadySettled: boolean;
}> {
  const db = getFirestore();
  const paymentRef = db.collection("payments").doc(input.paymentId);

  const outcome = await db.runTransaction(async (tx) => {
    const snap = await tx.get(paymentRef);
    if (!snap.exists) throw notFound("Payment not found");
    const payment = snap.data() ?? {};
    if (payment.status === "success" || payment.status === "failed") {
      return {
        alreadySettled: true,
        status: payment.status as SettleStatus,
        userId: String(payment.userId ?? ""),
        gameId: payment.gameId ? String(payment.gameId) : null,
        bookingId: payment.bookingId ? String(payment.bookingId) : null,
        amount: Number(payment.amount ?? 0),
        description:
          payment.status === "success" ? "Payment confirmed" : "Payment failed",
      };
    }
    if (
      input.providerRef &&
      payment.providerRef &&
      input.providerRef !== payment.providerRef
    ) {
      throw invalidArgument("Provider reference does not match this payment");
    }

    tx.update(paymentRef, {
      status: input.status,
      providerRef: payment.providerRef ?? input.providerRef,
      settledAt: FieldValue.serverTimestamp(),
      settlementSource: input.source,
    });

    if (input.status === "success") {
      if (payment.gameId) {
        tx.set(
          db
            .collection("games")
            .doc(String(payment.gameId))
            .collection("players")
            .doc(String(payment.userId)),
          { paymentStatus: "paid" },
          { merge: true },
        );
      }
      if (payment.bookingId) {
        tx.update(db.collection("bookings").doc(String(payment.bookingId)), {
          paymentStatus: "success",
        });
      }
    } else if (payment.bookingId) {
      tx.update(db.collection("bookings").doc(String(payment.bookingId)), {
        paymentStatus: "failed",
      });
    }

    return {
      alreadySettled: false,
      status: input.status,
      userId: String(payment.userId ?? ""),
      gameId: payment.gameId ? String(payment.gameId) : null,
      bookingId: payment.bookingId ? String(payment.bookingId) : null,
      amount: Number(payment.amount ?? 0),
      description:
        input.status === "success" ? "Payment confirmed" : "Payment failed",
    };
  });

  if (!outcome.alreadySettled && outcome.userId) {
    await notifyUsers(
      [outcome.userId],
      {
        title: outcome.description,
        body:
          input.status === "success"
            ? `We received ${outcome.amount} RWF. Your spot is secured.`
            : `Your ${outcome.amount} RWF payment did not go through. Try again.`,
        data: {
          type: "payment",
          paymentId: input.paymentId,
          status: input.status,
        },
      },
      { notificationId: `payment_${input.paymentId}` },
    );
  }

  return {
    paymentId: input.paymentId,
    status: outcome.status,
    alreadySettled: outcome.alreadySettled,
  };
}

/**
 * Phase 6 — server-side payment initiation. The client never sends an amount;
 * the server derives it from the booking/game so it cannot be tampered with.
 */
export const initiatePayment = onCall(async (request) => {
  const user = await requireUser(request);
  const input = parseInput(initiatePaymentSchema, request.data);
  const db = getFirestore();

  let amount: number;
  let description: string;
  let gameId: string | null = null;
  let bookingId: string | null = null;

  if (input.purpose === "game") {
    const gameSnap = await db.collection("games").doc(input.targetId).get();
    if (!gameSnap.exists) throw notFound("Game not found");
    const game = gameSnap.data() ?? {};
    const playerIds = Array.isArray(game.playerIds)
      ? (game.playerIds as string[])
      : [];
    if (!playerIds.includes(user.uid)) {
      throw permissionDenied("Join the game before paying");
    }
    const bookingSnap = await db
      .collection("bookings")
      .doc(String(game.bookingId))
      .get();
    if (!bookingSnap.exists) throw notFound("Linked booking not found");
    const booking = bookingSnap.data() ?? {};
    const split = computeCostSplit(
      Number(booking.totalPrice),
      playerIds.length,
    );
    amount = amountForPlayer(split, user.uid, String(game.organizerId));
    description = `PitchUp: ${String(game.title ?? "Pickup game")}`;
    gameId = input.targetId;

    const paid = await db
      .collection("payments")
      .where("gameId", "==", gameId)
      .where("userId", "==", user.uid)
      .where("status", "==", "success")
      .limit(1)
      .get();
    if (!paid.empty) throw failedPrecondition("You already paid for this game");
  } else {
    const bookingSnap = await db.collection("bookings").doc(input.targetId).get();
    if (!bookingSnap.exists) throw notFound("Booking not found");
    const booking = bookingSnap.data() ?? {};
    if (booking.userId !== user.uid) {
      throw permissionDenied("You can only pay for your own booking");
    }
    if (booking.paymentStatus === "success") {
      throw failedPrecondition("This booking is already paid");
    }
    amount = Number(booking.totalPrice);
    description = `PitchUp booking ${String(booking.ref ?? input.targetId)}`;
    bookingId = input.targetId;

    const paid = await db
      .collection("payments")
      .where("bookingId", "==", bookingId)
      .where("status", "==", "success")
      .limit(1)
      .get();
    if (!paid.empty) throw failedPrecondition("This booking is already paid");
  }

  if (!Number.isInteger(amount) || amount <= 0) {
    throw failedPrecondition("Payment amount is invalid");
  }

  const provider = getPaymentProvider(input.provider);
  const initiation = await provider.initiate({
    paymentId: "pending",
    amount,
    phone: input.phone,
    provider: input.provider,
    description,
  });

  const paymentRef = db.collection("payments").doc();
  await paymentRef.set({
    userId: user.uid,
    gameId,
    bookingId,
    amount,
    provider: input.provider,
    phone: input.phone,
    status: "pending",
    providerRef: initiation.providerRef,
    createdAt: FieldValue.serverTimestamp(),
  });

  return {
    paymentId: paymentRef.id,
    providerRef: initiation.providerRef,
    status: "pending",
    amount,
    message: initiation.message,
  };
});

/**
 * Emulator-only shortcut that mimics the aggregator callback. Disabled when
 * PAYMENTS_MOCK_ENABLED=false (production). Only the payer or an admin may
 * trigger it, because it can mark a payment successful.
 */
export const simulatePaymentOutcome = onCall(async (request) => {
  if ((process.env.PAYMENTS_MOCK_ENABLED ?? "true") !== "true") {
    throw permissionDenied("Mock payments are disabled");
  }
  const user = await requireUser(request);
  const input = parseInput(simulatePaymentSchema, request.data);
  const db = getFirestore();
  const snap = await db.collection("payments").doc(input.paymentId).get();
  if (!snap.exists) throw notFound("Payment not found");
  if (snap.get("userId") !== user.uid && user.role !== "admin") {
    throw permissionDenied("You cannot settle this payment");
  }
  return settlePayment({
    paymentId: input.paymentId,
    providerRef: String(snap.get("providerRef") ?? ""),
    status: input.outcome,
    source: "mock-simulator",
  });
});

const webhookSchema = z.object({
  paymentId: z.string().min(1),
  providerRef: z.string().min(1),
  status: z.enum(["success", "failed"]),
});

function signatureFor(body: string, secret: string): string {
  return createHmac("sha256", secret).update(body).digest("hex");
}

/**
 * Phase 6 — public HTTPS webhook for aggregator callbacks. Requests are
 * authenticated with an HMAC-SHA256 signature over the raw body. Settlement
 * is idempotent, so aggregator retries are safe.
 *
 * Production: set PAYMENT_WEBHOOK_SECRET in Secret Manager and wire the
 * aggregator's signing secret here (adapt per provider).
 */
export const paymentWebhook = onRequest(async (request, response) => {
  if (request.method !== "POST") {
    response.status(405).json({ error: "Method not allowed" });
    return;
  }
  const secret = process.env.PAYMENT_WEBHOOK_SECRET;
  if (!secret) {
    logger.error("PAYMENT_WEBHOOK_SECRET is not configured");
    response.status(500).json({ error: "Webhook not configured" });
    return;
  }
  const raw = request.rawBody?.toString("utf8") ?? "";
  const received = String(request.get("x-pitchup-signature") ?? "");
  const expected = signatureFor(raw, secret);
  const valid =
    received.length === expected.length &&
    timingSafeEqual(Buffer.from(received), Buffer.from(expected));
  if (!valid) {
    response.status(401).json({ error: "Invalid signature" });
    return;
  }

  let parsed: z.infer<typeof webhookSchema>;
  try {
    parsed = webhookSchema.parse(JSON.parse(raw));
  } catch {
    response.status(400).json({ error: "Invalid payload" });
    return;
  }

  try {
    const result = await settlePayment({
      paymentId: parsed.paymentId,
      providerRef: parsed.providerRef,
      status: parsed.status,
      source: "webhook",
    });
    response.status(200).json(result);
  } catch (error) {
    logger.error("Payment webhook failed", error);
    response.status(500).json({ error: "Settlement failed" });
  }
});
