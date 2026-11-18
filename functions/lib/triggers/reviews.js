"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onReviewCreated = void 0;
const firestore_1 = require("firebase-admin/firestore");
const firestore_2 = require("firebase-functions/v2/firestore");
const v2_1 = require("firebase-functions/v2");
const notifications_1 = require("../lib/notifications");
/**
 * Phase 7 — when a review is created:
 *  1. mark it `verified` only if the author has a completed booking at the
 *     venue (verified reviews make the "Verified player" badge trustworthy);
 *  2. re-aggregate the venue's average rating atomically;
 *  3. notify the venue owner.
 *
 * The client can only create a review with `verified: false` (enforced in
 * Firestore rules); this trigger is the only writer of the flag.
 */
exports.onReviewCreated = (0, firestore_2.onDocumentCreated)("reviews/{reviewId}", async (event) => {
    const reviewId = event.params.reviewId;
    const data = event.data?.data();
    if (!reviewId || !data)
        return;
    const db = (0, firestore_1.getFirestore)();
    const venueId = String(data.venueId ?? "");
    const userId = String(data.userId ?? "");
    const rating = Number(data.rating);
    if (!venueId || !userId || !Number.isInteger(rating)) {
        v2_1.logger.warn("Ignoring malformed review", { reviewId });
        return;
    }
    const completed = await db
        .collection("bookings")
        .where("userId", "==", userId)
        .where("venueId", "==", venueId)
        .where("status", "==", "completed")
        .limit(1)
        .get();
    const verified = !completed.empty;
    if (verified !== data.verified) {
        await event.data?.ref.update({ verified });
    }
    const venueRef = db.collection("venues").doc(venueId);
    const ownerId = await db.runTransaction(async (tx) => {
        const venueSnap = await tx.get(venueRef);
        if (!venueSnap.exists)
            return null;
        const currentRating = Number(venueSnap.get("rating") ?? 0);
        const currentCount = Number(venueSnap.get("ratingCount") ?? 0);
        const nextCount = currentCount + 1;
        const nextRating = Math.round(((currentRating * currentCount + rating) / nextCount) * 10) / 10;
        tx.update(venueRef, {
            rating: nextRating,
            ratingCount: nextCount,
        });
        return String(venueSnap.get("ownerId") ?? "") || null;
    });
    if (ownerId) {
        await (0, notifications_1.notifyUsers)([ownerId], {
            title: "New venue review",
            body: `${verified ? "Verified player" : "Player"} rated your venue ${rating}/5.`,
            data: { type: "review", venueId, reviewId },
        }, { notificationId: `review_${reviewId}` });
    }
});
//# sourceMappingURL=reviews.js.map