"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __exportStar = (this && this.__exportStar) || function(m, exports) {
    for (var p in m) if (p !== "default" && !Object.prototype.hasOwnProperty.call(exports, p)) __createBinding(exports, m, p);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getPaymentProvider = getPaymentProvider;
const mock_provider_1 = require("./mock-provider");
__exportStar(require("./types"), exports);
/**
 * Selects the active provider. Today everything runs through the mock.
 * To go live, add e.g. `MtnMomoProvider` / `FlutterwaveProvider` and return it
 * here; no handler changes are required.
 */
function getPaymentProvider(provider) {
    const mode = process.env.PAYMENT_PROVIDER_MODE ?? "mock";
    if (mode !== "mock") {
        throw new Error(`Payment provider mode "${mode}" is not implemented. Configure real credentials first.`);
    }
    return new mock_provider_1.MockProvider(provider);
}
//# sourceMappingURL=index.js.map