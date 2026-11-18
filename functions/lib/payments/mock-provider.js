"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MockProvider = void 0;
const node_crypto_1 = require("node:crypto");
/**
 * Local-development provider that simulates the MTN MoMo / Airtel Money
 * USSD prompt. It always starts `pending`; the outcome arrives through
 * `simulatePaymentOutcome` (emulator only) or the signed webhook, exactly
 * like a real aggregator callback.
 */
class MockProvider {
    id;
    constructor(id) {
        this.id = id;
    }
    async initiate(request) {
        if (!Number.isInteger(request.amount) || request.amount <= 0) {
            throw new Error("Payment amount must be a positive integer (RWF)");
        }
        const prefix = this.id === "mtn" ? "MOMO" : "AIRTEL";
        const providerRef = `${prefix}-${(0, node_crypto_1.randomBytes)(6).toString("hex").toUpperCase()}`;
        const label = this.id === "mtn" ? "MTN MoMo" : "Airtel Money";
        return {
            providerRef,
            status: "pending",
            message: `Mock ${label}: a USSD prompt was sent to ${request.phone}. Approve it to pay.`,
        };
    }
}
exports.MockProvider = MockProvider;
//# sourceMappingURL=mock-provider.js.map