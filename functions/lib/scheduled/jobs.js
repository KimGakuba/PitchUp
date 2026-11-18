"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendKickoffReminders = exports.completePastBookings = void 0;
const firestore_1 = require("firebase-admin/firestore");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const v2_1 = require("firebase-functions/v2");
const slots_1 = require("../domain/slots");
const notifications_1 = require("../lib/notifications");
/**
 * Phase 8 — marks bookings completed once kickoff + duration has passed.
 * Runs every 30 minutes; the linked pickup game is completed too.
 */
exports.completePastBookings = (0, scheduler_1.onSchedule)({ schedule: "every 30 minutes", timeZone: "Africa/Kigali" }, async () => {
    const db = (0, firestore_1.getFirestore)();
    const today = (0, slots_1.kigaliDateString)(new Date());
    const snap = await db
        .collection("bookings")
        .where("status", "==", "upcoming")
        .where("date", "<=", today)
        .limit(400)
        .get();
    const now = Date.now();
    const batch = db.batch();
    const completedIds = [];
    for (const doc of snap.docs) {
        const data = doc.data();
        const kickoff = (0, slots_1.kigaliToUtc)(String(data.date), String(data.startTime)).getTime();
        const end = kickoff + Number(data.durationMin) * 60_000;
        if (end > now)
            continue;
        batch.update(doc.ref, {
            status: "completed",
            completedAt: firestore_1.FieldValue.serverTimestamp(),
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
            if (games.empty)
                continue;
            const gameBatch = db.batch();
            for (const game of games.docs) {
                gameBatch.update(game.ref, { status: "completed" });
            }
            await gameBatch.commit();
        }
    }
    v2_1.logger.info("completePastBookings", { completed: completedIds.length });
});
/**
 * Phase 8 — 2-hour kickoff reminders. Runs every 30 minutes and de-duplicates
 * with a `reminders/{bookingId}` marker document so players are only pinged
 * once even if the scheduler retries.
 */
exports.sendKickoffReminders = (0, scheduler_1.onSchedule)({ schedule: "every 30 minutes", timeZone: "Africa/Kigali" }, async () => {
    const db = (0, firestore_1.getFirestore)();
    const now = Date.now();
    const today = (0, slots_1.kigaliDateString)(new Date());
    const tomorrow = (0, slots_1.kigaliDateString)(new Date(now + 24 * 60 * 60_000));
    const snap = await db
        .collection("bookings")
        .where("status", "==", "upcoming")
        .where("date", "in", [today, tomorrow])
        .limit(400)
        .get();
    let sent = 0;
    for (const doc of snap.docs) {
        const data = doc.data();
        const kickoff = (0, slots_1.kigaliToUtc)(String(data.date), String(data.startTime)).getTime();
        const minutesUntil = (kickoff - now) / 60_000;
        if (minutesUntil < 90 || minutesUntil > 150)
            continue;
        const marker = db.collection("reminders").doc(doc.id);
        const markerSnap = await marker.get();
        if (markerSnap.exists)
            continue;
        const gameSnap = await db
            .collection("games")
            .where("bookingId", "==", doc.id)
            .limit(1)
            .get();
        const game = gameSnap.docs[0]?.data();
        const uids = new Set([String(data.userId)]);
        if (game && Array.isArray(game.playerIds)) {
            for (const uid of game.playerIds)
                uids.add(uid);
        }
        await (0, notifications_1.notifyUsers)([...uids], {
            title: "Kickoff in 2 hours",
            body: `Your game at ${String(data.startTime)} is coming up. Bring water and your boots.`,
            data: { type: "reminder", bookingId: doc.id },
        }, { notificationId: `reminder_${doc.id}` });
        await marker.set({
            bookingId: doc.id,
            sentAt: firestore_1.FieldValue.serverTimestamp(),
        });
        sent += 1;
    }
    v2_1.logger.info("sendKickoffReminders", { sent });
});
//# sourceMappingURL=jobs.js.map