/**
 * Phase 2 — when a profile document is created, mirror its role into the Auth
 * custom claim. Rules only allow self-creation with `role == "player"`, so
 * this cannot be used for privilege escalation. Admins upgrade roles through
 * the `setUserRole` callable.
 */
export declare const onUserProfileCreated: import("firebase-functions/core").CloudFunction<import("firebase-functions/v2/firestore").FirestoreEvent<import("firebase-functions/v2/firestore").QueryDocumentSnapshot | undefined, {
    uid: string;
}>>;
