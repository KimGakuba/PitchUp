"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.notifyUsers = notifyUsers;
const firestore_1 = require("firebase-admin/firestore");
const messaging_1 = require("firebase-admin/messaging");
const v2_1 = require("firebase-functions/v2");
/**
 * Writes a `notifications/{id}` document for each user and best-effort sends
 * an FCM push to every registered token. Invalid tokens are pruned from the
 * user document. Never throws for delivery problems: in-app notifications
 * are still persisted.
 */
async function notifyUsers(uids, payload, options = {}) {
    const unique = [...new Set(uids.filter(Boolean))];
    if (unique.length === 0)
        return;
    const db = (0, firestore_1.getFirestore)();
    const refs = unique.map((uid) => db.collection("users").doc(uid));
    const snaps = await db.getAll(...refs);
    const tokensByUid = new Map();
    for (const snap of snaps) {
        if (!snap.exists)
            continue;
        const tokens = snap.get("fcmTokens") ?? [];
        const valid = tokens.filter((t) => typeof t === "string");
        tokensByUid.set(snap.id, valid);
        const notificationRef = options.notificationId
            ? db.collection("notifications").doc(`${options.notificationId}_${snap.id}`)
            : db.collection("notifications").doc();
        await notificationRef.set({
            userId: snap.id,
            title: payload.title,
            body: payload.body,
            read: false,
            createdAt: firestore_1.FieldValue.serverTimestamp(),
            data: payload.data ?? {},
        });
    }
    const allTokens = [...tokensByUid.values()].flat();
    if (allTokens.length === 0)
        return;
    try {
        const response = await (0, messaging_1.getMessaging)().sendEachForMulticast({
            tokens: allTokens,
            notification: { title: payload.title, body: payload.body },
            data: payload.data,
        });
        const stale = [];
        response.responses.forEach((result, index) => {
            if (result.success)
                return;
            const code = result.error?.code;
            if (code === "messaging/registration-token-not-registered" ||
                code === "messaging/invalid-registration-token") {
                const token = allTokens[index];
                if (token)
                    stale.push(token);
            }
        });
        if (stale.length > 0) {
            const batch = db.batch();
            for (const [uid, tokens] of tokensByUid) {
                const remaining = tokens.filter((t) => !stale.includes(t));
                if (remaining.length !== tokens.length) {
                    batch.update(db.collection("users").doc(uid), { fcmTokens: remaining });
                }
            }
            await batch.commit();
        }
    }
    catch (error) {
        v2_1.logger.warn("FCM multicast failed", error);
    }
}
//# sourceMappingURL=notifications.js.map