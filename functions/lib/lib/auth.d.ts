import type { CallableRequest } from "firebase-functions/v2/https";
export type Role = "player" | "owner" | "admin";
export interface UserRecord {
    uid: string;
    role: Role;
    status: string;
    name?: string;
    phone?: string;
    fcmTokens?: string[];
}
/**
 * Reads the role exclusively from the Firebase Auth custom claim — never
 * from request data or the Firestore document. The Firestore `users.role`
 * copy exists only for display/queries; a Cloud Function keeps both in sync.
 */
export declare function claimRole(request: CallableRequest<unknown>): Role;
export declare function requireUid(request: CallableRequest<unknown>): string;
export declare function requireUser(request: CallableRequest<unknown>): Promise<UserRecord>;
export declare function requireRole(request: CallableRequest<unknown>, roles: Role[]): Promise<UserRecord>;
export declare function requireAdmin(request: CallableRequest<unknown>): Promise<UserRecord>;
export declare function isAdmin(request: CallableRequest<unknown>): boolean;
