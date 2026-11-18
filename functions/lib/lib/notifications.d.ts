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
export declare function notifyUsers(uids: string[], payload: NotificationPayload, options?: {
    notificationId?: string;
}): Promise<void>;
