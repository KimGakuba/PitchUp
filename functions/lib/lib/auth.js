"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.claimRole = claimRole;
exports.requireUid = requireUid;
exports.requireUser = requireUser;
exports.requireRole = requireRole;
exports.requireAdmin = requireAdmin;
exports.isAdmin = isAdmin;
const firestore_1 = require("firebase-admin/firestore");
const errors_1 = require("./errors");
/**
 * Reads the role exclusively from the Firebase Auth custom claim — never
 * from request data or the Firestore document. The Firestore `users.role`
 * copy exists only for display/queries; a Cloud Function keeps both in sync.
 */
function claimRole(request) {
    const raw = request.auth?.token.role;
    if (raw === "player" || raw === "owner" || raw === "admin")
        return raw;
    return "player";
}
function requireUid(request) {
    const uid = request.auth?.uid;
    if (!uid)
        throw (0, errors_1.unauthenticated)();
    return uid;
}
async function requireUser(request) {
    const uid = requireUid(request);
    const snap = await (0, firestore_1.getFirestore)().collection("users").doc(uid).get();
    if (!snap.exists) {
        throw (0, errors_1.permissionDenied)("Your user profile is missing. Complete sign-up.");
    }
    const data = snap.data() ?? {};
    if (data.status === "suspended") {
        throw (0, errors_1.permissionDenied)("Your account is suspended. Contact PitchUp support.");
    }
    return {
        uid,
        role: claimRole(request),
        status: typeof data.status === "string" ? data.status : "active",
        name: typeof data.name === "string" ? data.name : undefined,
        phone: typeof data.phone === "string" ? data.phone : undefined,
        fcmTokens: Array.isArray(data.fcmTokens)
            ? data.fcmTokens
            : [],
    };
}
async function requireRole(request, roles) {
    const user = await requireUser(request);
    if (!roles.includes(user.role)) {
        throw (0, errors_1.permissionDenied)("You do not have permission to do that.");
    }
    return user;
}
async function requireAdmin(request) {
    return requireRole(request, ["admin"]);
}
function isAdmin(request) {
    return claimRole(request) === "admin";
}
//# sourceMappingURL=auth.js.map