import { MockProvider } from "./mock-provider";
import type { PaymentProvider, ProviderId } from "./types";

export * from "./types";

/**
 * Selects the active provider. Today everything runs through the mock.
 * To go live, add e.g. `MtnMomoProvider` / `FlutterwaveProvider` and return it
 * here; no handler changes are required.
 */
export function getPaymentProvider(provider: ProviderId): PaymentProvider {
  const mode = process.env.PAYMENT_PROVIDER_MODE ?? "mock";
  if (mode !== "mock") {
    throw new Error(
      `Payment provider mode "${mode}" is not implemented. Configure real credentials first.`,
    );
  }
  return new MockProvider(provider);
}
