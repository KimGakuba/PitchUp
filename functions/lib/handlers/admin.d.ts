import type { CallableRequest } from "firebase-functions/v2/https";
import type { Role } from "../lib/auth";
/** Shared by admin endpoints and report resolution. */
export declare function applyUserStatus(uid: string, suspend: boolean, adminUid: string, reason?: string): Promise<void>;
export declare function applyUserRole(request: CallableRequest<unknown>, uid: string, role: Role): Promise<void>;
/**
 * Phase 2/8 — the ONLY writer of role custom claims. Rules forbid clients
 * from editing `users.role`; this callable is admin-only and keeps the
 * Firestore copy and the Auth claim in sync.
 */
export declare const setUserRole: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    uid: string;
    role: "player" | "owner" | "admin";
}>, unknown>;
/** Phase 8 — suspend or reactivate a player/owner account. */
export declare const setUserStatus: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    uid: string;
    status: string;
}>, unknown>;
/** Phase 8 — resolve a report, optionally suspending/reactivating the target. */
export declare const resolveReport: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    reportId: string;
    status: string;
    resolution: "suspend" | "resolve" | "dismiss" | "activate";
}>, unknown>;
/** Phase 8 — registers/refreshes an FCM token for push notifications. */
export declare const registerFcmToken: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    registered: boolean;
}>, unknown>;
/** Removes a token on sign-out so the device stops receiving pushes. */
export declare const unregisterFcmToken: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    unregistered: boolean;
}>, unknown>;
