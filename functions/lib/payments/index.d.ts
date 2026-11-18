import type { PaymentProvider, ProviderId } from "./types";
export * from "./types";
/**
 * Selects the active provider. Today everything runs through the mock.
 * To go live, add e.g. `MtnMomoProvider` / `FlutterwaveProvider` and return it
 * here; no handler changes are required.
 */
export declare function getPaymentProvider(provider: ProviderId): PaymentProvider;
