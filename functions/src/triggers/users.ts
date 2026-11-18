import { getAuth } from "firebase-admin/auth";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions/v2";

const ROLES = new Set(["player", "owner", "admin"]);

/**
 * Phase 2 — when a profile document is created, mirror its role into the Auth
 * custom claim. Rules only allow self-creation with `role == "player"`, so
 * this cannot be used for privilege escalation. Admins upgrade roles through
 * the `setUserRole` callable.
 */
export const onUserProfileCreated = onDocumentCreated(
  "users/{uid}",
  async (event) => {
    const uid = event.params.uid;
    const data = event.data?.data();
    if (!uid || !data) return;
    const rawRole = String(data.role ?? "player");
    const role = ROLES.has(rawRole) ? rawRole : "player";
    try {
      await getAuth().setCustomUserClaims(uid, {
        role,
        status: String(data.status ?? "active"),
        suspended: data.status === "suspended",
      });
    } catch (error) {
      logger.error("Failed to set initial role claim", { uid, error });
    }
  },
);
