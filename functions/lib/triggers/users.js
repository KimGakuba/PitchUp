"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onUserProfileCreated = void 0;
const auth_1 = require("firebase-admin/auth");
const firestore_1 = require("firebase-functions/v2/firestore");
const v2_1 = require("firebase-functions/v2");
const ROLES = new Set(["player", "owner", "admin"]);
/**
 * Phase 2 — when a profile document is created, mirror its role into the Auth
 * custom claim. Rules only allow self-creation with `role == "player"`, so
 * this cannot be used for privilege escalation. Admins upgrade roles through
 * the `setUserRole` callable.
 */
exports.onUserProfileCreated = (0, firestore_1.onDocumentCreated)("users/{uid}", async (event) => {
    const uid = event.params.uid;
    const data = event.data?.data();
    if (!uid || !data)
        return;
    const rawRole = String(data.role ?? "player");
    const role = ROLES.has(rawRole) ? rawRole : "player";
    try {
        await (0, auth_1.getAuth)().setCustomUserClaims(uid, {
            role,
            status: String(data.status ?? "active"),
            suspended: data.status === "suspended",
        });
    }
    catch (error) {
        v2_1.logger.error("Failed to set initial role claim", { uid, error });
    }
});
//# sourceMappingURL=users.js.map