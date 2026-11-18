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
export declare const onReviewCreated: import("firebase-functions/core").CloudFunction<import("firebase-functions/v2/firestore").FirestoreEvent<import("firebase-functions/v2/firestore").QueryDocumentSnapshot | undefined, {
    reviewId: string;
}>>;
