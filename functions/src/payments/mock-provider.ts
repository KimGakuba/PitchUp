import { randomBytes } from "node:crypto";
import type {
  PaymentInitiation,
  PaymentProvider,
  PaymentRequest,
  ProviderId,
} from "./types";

/**
 * Local-development provider that simulates the MTN MoMo / Airtel Money
 * USSD prompt. It always starts `pending`; the outcome arrives through
 * `simulatePaymentOutcome` (emulator only) or the signed webhook, exactly
 * like a real aggregator callback.
 */
export class MockProvider implements PaymentProvider {
  constructor(readonly id: ProviderId) {}

  async initiate(request: PaymentRequest): Promise<PaymentInitiation> {
    if (!Number.isInteger(request.amount) || request.amount <= 0) {
      throw new Error("Payment amount must be a positive integer (RWF)");
    }
    const prefix = this.id === "mtn" ? "MOMO" : "AIRTEL";
    const providerRef = `${prefix}-${randomBytes(6).toString("hex").toUpperCase()}`;
    const label = this.id === "mtn" ? "MTN MoMo" : "Airtel Money";
    return {
      providerRef,
      status: "pending",
      message: `Mock ${label}: a USSD prompt was sent to ${request.phone}. Approve it to pay.`,
    };
  }
}
