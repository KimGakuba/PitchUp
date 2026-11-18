export type ProviderId = "mtn" | "airtel";
export type ProviderStatus = "pending" | "success" | "failed";

export interface PaymentRequest {
  paymentId: string;
  amount: number; // integer RWF
  phone: string; // E.164
  provider: ProviderId;
  description: string;
}

export interface PaymentInitiation {
  providerRef: string;
  status: ProviderStatus;
  /** Message shown to the player, e.g. "Check your phone for the MoMo prompt". */
  message: string;
}

/**
 * Payment aggregator seam. A real integration (MTN MoMo API, Airtel Money,
 * Flutterwave, Pesapal, Paypack, ...) implements this interface and is
 * selected in `getPaymentProvider()`. Handlers never talk to an aggregator
 * directly, so swapping providers is a one-file change.
 *
 * Implementations MUST NOT be reachable from the client directly and MUST
 * read credentials from Secret Manager / environment, never the app bundle.
 */
export interface PaymentProvider {
  readonly id: ProviderId;
  initiate(request: PaymentRequest): Promise<PaymentInitiation>;
}
