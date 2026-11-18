import type { PaymentInitiation, PaymentProvider, PaymentRequest, ProviderId } from "./types";
/**
 * Local-development provider that simulates the MTN MoMo / Airtel Money
 * USSD prompt. It always starts `pending`; the outcome arrives through
 * `simulatePaymentOutcome` (emulator only) or the signed webhook, exactly
 * like a real aggregator callback.
 */
export declare class MockProvider implements PaymentProvider {
    readonly id: ProviderId;
    constructor(id: ProviderId);
    initiate(request: PaymentRequest): Promise<PaymentInitiation>;
}
