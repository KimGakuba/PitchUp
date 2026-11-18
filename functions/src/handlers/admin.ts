import { getAuth } from "firebase-admin/auth";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { onCall } from "firebase-functions/v2/https";
import type { CallableRequest } from "firebase-functions/v2/https";
import { requireAdmin, requireUser } from "../lib/auth";
import {
  failedPrecondition,
  notFound,
  parseInput,
  permissionDenied,
} from "../lib/errors";
import { notifyUsers } from "../lib/notifications";
import {
  registerTokenSchema,
  resolveReportSchema,
  setUserRoleSchema,
  setUserStatusSchema,
} from "../lib/validation";
import type { Role } from "../lib/auth";

/** Shared by admin endpoints and report resolution. */
export async function applyUserStatus(
  uid: string,
  suspend: boolean,
  adminUid: string,
  reason?: string,
): Promise<void> {
  if (uid === adminUid) {
    throw failedPrecondition("You cannot change your own account status");
  }
  const db = getFirestore();
  const userRef = db.collection("users").doc(uid);
  const snap = await userRef.get();
  if (!snap.exists) throw notFound("User not found");
  const role = (snap.get("role") as Role | undefined) ?? "player";
  const status = suspend ? "suspended" : "active";

  await userRef.update({
    status,
    moderationReason: reason ?? null,
    moderatedAt: FieldValue.serverTimestamp(),
    moderatedBy: adminUid,
  });
  await getAuth().setCustomUserClaims(uid, { role, status, suspended: suspend });
  if (suspend) {
    await getAuth().revokeRefreshTokens(uid);
  }
  await notifyUsers(
    [uid],
    {
      title: suspend ? "Account suspended" : "Account reinstated",
      body: suspend
        ? "Your PitchUp account has been suspended. Contact support for details."
        : "Your PitchUp account is active again. Welcome back.",
      data: { type: "moderation", status },
    },
    { notificationId: `moderation_${uid}_${status}_${Date.now()}` },
  );
}

export async function applyUserRole(
  request: CallableRequest<unknown>,
  uid: string,
  role: Role,
): Promise<void> {
  const admin = await requireAdmin(request);
  const db = getFirestore();
  const userRef = db.collection("users").doc(uid);
  const snap = await userRef.get();
  if (!snap.exists) throw notFound("User not found");
  const status = String(snap.get("status") ?? "active");
  await userRef.update({ role });
  await getAuth().setCustomUserClaims(uid, {
    role,
    status,
    suspended: status === "suspended",
  });
  await getAuth().revokeRefreshTokens(uid);
  await notifyUsers(
    [uid],
    {
      title: "Account role updated",
      body: `Your PitchUp role is now ${role}. Sign in again to see the new tools.`,
      data: { type: "role", role },
    },
    { notificationId: `role_${uid}_${role}_${Date.now()}` },
  );
  void admin;
}

/**
 * Phase 2/8 — the ONLY writer of role custom claims. Rules forbid clients
 * from editing `users.role`; this callable is admin-only and keeps the
 * Firestore copy and the Auth claim in sync.
 */
export const setUserRole = onCall(async (request) => {
  const input = parseInput(setUserRoleSchema, request.data);
  await applyUserRole(request, input.uid, input.role);
  return { uid: input.uid, role: input.role };
});

/** Phase 8 — suspend or reactivate a player/owner account. */
export const setUserStatus = onCall(async (request) => {
  const admin = await requireAdmin(request);
  const input = parseInput(setUserStatusSchema, request.data);
  await applyUserStatus(input.uid, input.suspend, admin.uid, input.reason);
  return { uid: input.uid, status: input.suspend ? "suspended" : "active" };
});

/** Phase 8 — resolve a report, optionally suspending/reactivating the target. */
export const resolveReport = onCall(async (request) => {
  const admin = await requireAdmin(request);
  const input = parseInput(resolveReportSchema, request.data);
  const db = getFirestore();
  const reportRef = db.collection("reports").doc(input.reportId);
  const snap = await reportRef.get();
  if (!snap.exists) throw notFound("Report not found");
  const report = snap.data() ?? {};
  const targetId = String(report.targetId ?? "");
  if (!targetId) throw failedPrecondition("Report has no target");

  if (input.action === "suspend") {
    await applyUserStatus(targetId, true, admin.uid, input.notes);
  } else if (input.action === "activate") {
    await applyUserStatus(targetId, false, admin.uid, input.notes);
  }

  const status =
    input.action === "dismiss" ? "dismissed" : "resolved";
  await reportRef.update({
    status,
    resolution: input.action,
    resolutionNotes: input.notes ?? null,
    resolvedBy: admin.uid,
    resolvedAt: FieldValue.serverTimestamp(),
  });

  const reporterId = String(report.reporterId ?? "");
  if (reporterId) {
    await notifyUsers(
      [reporterId],
      {
        title: "Report reviewed",
        body: `Your report was ${status}. Thank you for keeping PitchUp safe.`,
        data: { type: "report", reportId: input.reportId, status },
      },
      { notificationId: `report_${input.reportId}_${status}` },
    );
  }

  return { reportId: input.reportId, status, resolution: input.action };
});

/** Phase 8 — registers/refreshes an FCM token for push notifications. */
export const registerFcmToken = onCall(async (request) => {
  const user = await requireUser(request);
  const input = parseInput(registerTokenSchema, request.data);
  if (user.status === "suspended") {
    throw permissionDenied("Suspended accounts cannot register for push");
  }
  await getFirestore()
    .collection("users")
    .doc(user.uid)
    .update({ fcmTokens: FieldValue.arrayUnion(input.token) });
  return { registered: true };
});

/** Removes a token on sign-out so the device stops receiving pushes. */
export const unregisterFcmToken = onCall(async (request) => {
  const user = await requireUser(request);
  const input = parseInput(registerTokenSchema, request.data);
  await getFirestore()
    .collection("users")
    .doc(user.uid)
    .update({ fcmTokens: FieldValue.arrayRemove(input.token) });
  return { unregistered: true };
});
