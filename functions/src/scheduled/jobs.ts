import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions/v2";
import { kigaliDateString, kigaliToUtc } from "../domain/slots";
import { notifyUsers } from "../lib/notifications";

/**
 * Phase 8 — marks bookings completed once kickoff + duration has passed.
 * Runs every 30 minutes; the linked pickup game is completed too.
 */
export const completePastBookings = onSchedule(
  { schedule: "every 30 minutes", timeZone: "Africa/Kigali" },
  async () => {
    const db = getFirestore();
    const today = kigaliDateString(new Date());
    const snap = await db
      .collection("bookings")
      .where("status", "==", "upcoming")
      .where("date", "<=", today)
      .limit(400)
      .get();

    const now = Date.now();
    const batch = db.batch();
    const completedIds: string[] = [];
    for (const doc of snap.docs) {
      const data = doc.data();
      const kickoff = kigaliToUtc(
        String(data.date),
        String(data.startTime),
      ).getTime();
      const end = kickoff + Number(data.durationMin) * 60_000;
      if (end > now) continue;
      batch.update(doc.ref, {
        status: "completed",
        completedAt: FieldValue.serverTimestamp(),
      });
      completedIds.push(doc.id);
    }
    if (completedIds.length > 0) {
      await batch.commit();
      for (let i = 0; i < completedIds.length; i += 10) {
        const games = await db
          .collection("games")
          .where("bookingId", "in", completedIds.slice(i, i + 10))
          .get();
        if (games.empty) continue;
        const gameBatch = db.batch();
        for (const game of games.docs) {
          gameBatch.update(game.ref, { status: "completed" });
        }
        await gameBatch.commit();
      }
    }
    logger.info("completePastBookings", { completed: completedIds.length });
  },
);

/**
 * Phase 8 — 2-hour kickoff reminders. Runs every 30 minutes and de-duplicates
 * with a `reminders/{bookingId}` marker document so players are only pinged
 * once even if the scheduler retries.
 */
export const sendKickoffReminders = onSchedule(
  { schedule: "every 30 minutes", timeZone: "Africa/Kigali" },
  async () => {
    const db = getFirestore();
    const now = Date.now();
    const today = kigaliDateString(new Date());
    const tomorrow = kigaliDateString(new Date(now + 24 * 60 * 60_000));

    const snap = await db
      .collection("bookings")
      .where("status", "==", "upcoming")
      .where("date", "in", [today, tomorrow])
      .limit(400)
      .get();

    let sent = 0;
    for (const doc of snap.docs) {
      const data = doc.data();
      const kickoff = kigaliToUtc(
        String(data.date),
        String(data.startTime),
      ).getTime();
      const minutesUntil = (kickoff - now) / 60_000;
      if (minutesUntil < 90 || minutesUntil > 150) continue;

      const marker = db.collection("reminders").doc(doc.id);
      const markerSnap = await marker.get();
      if (markerSnap.exists) continue;

      const gameSnap = await db
        .collection("games")
        .where("bookingId", "==", doc.id)
        .limit(1)
        .get();
      const game = gameSnap.docs[0]?.data();
      const uids = new Set<string>([String(data.userId)]);
      if (game && Array.isArray(game.playerIds)) {
        for (const uid of game.playerIds as string[]) uids.add(uid);
      }

      await notifyUsers(
        [...uids],
        {
          title: "Kickoff in 2 hours",
          body: `Your game at ${String(data.startTime)} is coming up. Bring water and your boots.`,
          data: { type: "reminder", bookingId: doc.id },
        },
        { notificationId: `reminder_${doc.id}` },
      );
      await marker.set({
        bookingId: doc.id,
        sentAt: FieldValue.serverTimestamp(),
      });
      sent += 1;
    }
    logger.info("sendKickoffReminders", { sent });
  },
);
