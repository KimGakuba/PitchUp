import { getFirestore } from "firebase-admin/firestore";
import type { CallableRequest } from "firebase-functions/v2/https";
import { permissionDenied, unauthenticated } from "./errors";

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
export function claimRole(request: CallableRequest<unknown>): Role {
  const raw = request.auth?.token.role;
  if (raw === "player" || raw === "owner" || raw === "admin") return raw;
  return "player";
}

export function requireUid(request: CallableRequest<unknown>): string {
  const uid = request.auth?.uid;
  if (!uid) throw unauthenticated();
  return uid;
}

export async function requireUser(
  request: CallableRequest<unknown>,
): Promise<UserRecord> {
  const uid = requireUid(request);
  const snap = await getFirestore().collection("users").doc(uid).get();
  if (!snap.exists) {
    throw permissionDenied("Your user profile is missing. Complete sign-up.");
  }
  const data = snap.data() ?? {};
  if (data.status === "suspended") {
    throw permissionDenied("Your account is suspended. Contact PitchUp support.");
  }
  return {
    uid,
    role: claimRole(request),
    status: typeof data.status === "string" ? data.status : "active",
    name: typeof data.name === "string" ? data.name : undefined,
    phone: typeof data.phone === "string" ? data.phone : undefined,
    fcmTokens: Array.isArray(data.fcmTokens)
      ? (data.fcmTokens as string[])
      : [],
  };
}

export async function requireRole(
  request: CallableRequest<unknown>,
  roles: Role[],
): Promise<UserRecord> {
  const user = await requireUser(request);
  if (!roles.includes(user.role)) {
    throw permissionDenied("You do not have permission to do that.");
  }
  return user;
}

export async function requireAdmin(
  request: CallableRequest<unknown>,
): Promise<UserRecord> {
  return requireRole(request, ["admin"]);
}

export function isAdmin(request: CallableRequest<unknown>): boolean {
  return claimRole(request) === "admin";
}
