import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { logger } from "firebase-functions/v2";

export interface NotificationPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

/**
 * Writes a `notifications/{id}` document for each user and best-effort sends
 * an FCM push to every registered token. Invalid tokens are pruned from the
 * user document. Never throws for delivery problems: in-app notifications
 * are still persisted.
 */
export async function notifyUsers(
  uids: string[],
  payload: NotificationPayload,
  options: { notificationId?: string } = {},
): Promise<void> {
  const unique = [...new Set(uids.filter(Boolean))];
  if (unique.length === 0) return;
  const db = getFirestore();
  const refs = unique.map((uid) => db.collection("users").doc(uid));
  const snaps = await db.getAll(...refs);

  const tokensByUid = new Map<string, string[]>();

  for (const snap of snaps) {
    if (!snap.exists) continue;
    const tokens = (snap.get("fcmTokens") as unknown[] | undefined) ?? [];
    const valid = tokens.filter((t): t is string => typeof t === "string");
    tokensByUid.set(snap.id, valid);
    const notificationRef = options.notificationId
      ? db.collection("notifications").doc(`${options.notificationId}_${snap.id}`)
      : db.collection("notifications").doc();
    await notificationRef.set({
      userId: snap.id,
      title: payload.title,
      body: payload.body,
      read: false,
      createdAt: FieldValue.serverTimestamp(),
      data: payload.data ?? {},
    });
  }

  const allTokens = [...tokensByUid.values()].flat();
  if (allTokens.length === 0) return;

  try {
    const response = await getMessaging().sendEachForMulticast({
      tokens: allTokens,
      notification: { title: payload.title, body: payload.body },
      data: payload.data,
    });
    const stale: string[] = [];
    response.responses.forEach((result, index) => {
      if (result.success) return;
      const code = result.error?.code;
      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token"
      ) {
        const token = allTokens[index];
        if (token) stale.push(token);
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
  } catch (error) {
    logger.warn("FCM multicast failed", error);
  }
}
