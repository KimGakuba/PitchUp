"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.unregisterFcmToken = exports.registerFcmToken = exports.resolveReport = exports.setUserStatus = exports.setUserRole = void 0;
exports.applyUserStatus = applyUserStatus;
exports.applyUserRole = applyUserRole;
const auth_1 = require("firebase-admin/auth");
const firestore_1 = require("firebase-admin/firestore");
const https_1 = require("firebase-functions/v2/https");
const auth_2 = require("../lib/auth");
const errors_1 = require("../lib/errors");
const notifications_1 = require("../lib/notifications");
const validation_1 = require("../lib/validation");
/** Shared by admin endpoints and report resolution. */
async function applyUserStatus(uid, suspend, adminUid, reason) {
    if (uid === adminUid) {
        throw (0, errors_1.failedPrecondition)("You cannot change your own account status");
    }
    const db = (0, firestore_1.getFirestore)();
    const userRef = db.collection("users").doc(uid);
    const snap = await userRef.get();
    if (!snap.exists)
        throw (0, errors_1.notFound)("User not found");
    const role = snap.get("role") ?? "player";
    const status = suspend ? "suspended" : "active";
    await userRef.update({
        status,
        moderationReason: reason ?? null,
        moderatedAt: firestore_1.FieldValue.serverTimestamp(),
        moderatedBy: adminUid,
    });
    await (0, auth_1.getAuth)().setCustomUserClaims(uid, { role, status, suspended: suspend });
    if (suspend) {
        await (0, auth_1.getAuth)().revokeRefreshTokens(uid);
    }
    await (0, notifications_1.notifyUsers)([uid], {
        title: suspend ? "Account suspended" : "Account reinstated",
        body: suspend
            ? "Your PitchUp account has been suspended. Contact support for details."
            : "Your PitchUp account is active again. Welcome back.",
        data: { type: "moderation", status },
    }, { notificationId: `moderation_${uid}_${status}_${Date.now()}` });
}
async function applyUserRole(request, uid, role) {
    const admin = await (0, auth_2.requireAdmin)(request);
    const db = (0, firestore_1.getFirestore)();
    const userRef = db.collection("users").doc(uid);
    const snap = await userRef.get();
    if (!snap.exists)
        throw (0, errors_1.notFound)("User not found");
    const status = String(snap.get("status") ?? "active");
    await userRef.update({ role });
    await (0, auth_1.getAuth)().setCustomUserClaims(uid, {
        role,
        status,
        suspended: status === "suspended",
    });
    await (0, auth_1.getAuth)().revokeRefreshTokens(uid);
    await (0, notifications_1.notifyUsers)([uid], {
        title: "Account role updated",
        body: `Your PitchUp role is now ${role}. Sign in again to see the new tools.`,
        data: { type: "role", role },
    }, { notificationId: `role_${uid}_${role}_${Date.now()}` });
    void admin;
}
/**
 * Phase 2/8 — the ONLY writer of role custom claims. Rules forbid clients
 * from editing `users.role`; this callable is admin-only and keeps the
 * Firestore copy and the Auth claim in sync.
 */
exports.setUserRole = (0, https_1.onCall)(async (request) => {
    const input = (0, errors_1.parseInput)(validation_1.setUserRoleSchema, request.data);
    await applyUserRole(request, input.uid, input.role);
    return { uid: input.uid, role: input.role };
});
/** Phase 8 — suspend or reactivate a player/owner account. */
exports.setUserStatus = (0, https_1.onCall)(async (request) => {
    const admin = await (0, auth_2.requireAdmin)(request);
    const input = (0, errors_1.parseInput)(validation_1.setUserStatusSchema, request.data);
    await applyUserStatus(input.uid, input.suspend, admin.uid, input.reason);
    return { uid: input.uid, status: input.suspend ? "suspended" : "active" };
});
/** Phase 8 — resolve a report, optionally suspending/reactivating the target. */
exports.resolveReport = (0, https_1.onCall)(async (request) => {
    const admin = await (0, auth_2.requireAdmin)(request);
    const input = (0, errors_1.parseInput)(validation_1.resolveReportSchema, request.data);
    const db = (0, firestore_1.getFirestore)();
    const reportRef = db.collection("reports").doc(input.reportId);
    const snap = await reportRef.get();
    if (!snap.exists)
        throw (0, errors_1.notFound)("Report not found");
    const report = snap.data() ?? {};
    const targetId = String(report.targetId ?? "");
    if (!targetId)
        throw (0, errors_1.failedPrecondition)("Report has no target");
    if (input.action === "suspend") {
        await applyUserStatus(targetId, true, admin.uid, input.notes);
    }
    else if (input.action === "activate") {
        await applyUserStatus(targetId, false, admin.uid, input.notes);
    }
    const status = input.action === "dismiss" ? "dismissed" : "resolved";
    await reportRef.update({
        status,
        resolution: input.action,
        resolutionNotes: input.notes ?? null,
        resolvedBy: admin.uid,
        resolvedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    const reporterId = String(report.reporterId ?? "");
    if (reporterId) {
        await (0, notifications_1.notifyUsers)([reporterId], {
            title: "Report reviewed",
            body: `Your report was ${status}. Thank you for keeping PitchUp safe.`,
            data: { type: "report", reportId: input.reportId, status },
        }, { notificationId: `report_${input.reportId}_${status}` });
    }
    return { reportId: input.reportId, status, resolution: input.action };
});
/** Phase 8 — registers/refreshes an FCM token for push notifications. */
exports.registerFcmToken = (0, https_1.onCall)(async (request) => {
    const user = await (0, auth_2.requireUser)(request);
    const input = (0, errors_1.parseInput)(validation_1.registerTokenSchema, request.data);
    if (user.status === "suspended") {
        throw (0, errors_1.permissionDenied)("Suspended accounts cannot register for push");
    }
    await (0, firestore_1.getFirestore)()
        .collection("users")
        .doc(user.uid)
        .update({ fcmTokens: firestore_1.FieldValue.arrayUnion(input.token) });
    return { registered: true };
});
/** Removes a token on sign-out so the device stops receiving pushes. */
exports.unregisterFcmToken = (0, https_1.onCall)(async (request) => {
    const user = await (0, auth_2.requireUser)(request);
    const input = (0, errors_1.parseInput)(validation_1.registerTokenSchema, request.data);
    await (0, firestore_1.getFirestore)()
        .collection("users")
        .doc(user.uid)
        .update({ fcmTokens: firestore_1.FieldValue.arrayRemove(input.token) });
    return { unregistered: true };
});
//# sourceMappingURL=admin.js.map