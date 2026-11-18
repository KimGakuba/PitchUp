type SettleStatus = "success" | "failed";
interface SettleInput {
    paymentId: string;
    providerRef: string;
    status: SettleStatus;
    source: string;
}
/**
 * Single idempotent settlement path used by both the HTTP webhook and the
 * emulator-only simulator. A payment may settle from `pending` exactly once;
 * later callbacks are acknowledged without side effects.
 */
export declare function settlePayment(input: SettleInput): Promise<{
    paymentId: string;
    status: SettleStatus | "pending";
    alreadySettled: boolean;
}>;
/**
 * Phase 6 — server-side payment initiation. The client never sends an amount;
 * the server derives it from the booking/game so it cannot be tampered with.
 */
export declare const initiatePayment: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    paymentId: string;
    providerRef: string;
    status: string;
    amount: number;
    message: string;
}>, unknown>;
/**
 * Emulator-only shortcut that mimics the aggregator callback. Disabled when
 * PAYMENTS_MOCK_ENABLED=false (production). Only the payer or an admin may
 * trigger it, because it can mark a payment successful.
 */
export declare const simulatePaymentOutcome: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    paymentId: string;
    status: SettleStatus | "pending";
    alreadySettled: boolean;
}>, unknown>;
/**
 * Phase 6 — public HTTPS webhook for aggregator callbacks. Requests are
 * authenticated with an HMAC-SHA256 signature over the raw body. Settlement
 * is idempotent, so aggregator retries are safe.
 *
 * Production: set PAYMENT_WEBHOOK_SECRET in Secret Manager and wire the
 * aggregator's signing secret here (adapt per provider).
 */
export declare const paymentWebhook: import("firebase-functions/v2/https").HttpsFunction;
export {};
