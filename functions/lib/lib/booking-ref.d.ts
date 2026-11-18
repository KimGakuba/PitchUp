import type { Firestore, Transaction } from "firebase-admin/firestore";
/**
 * Reserves the next booking sequence inside the caller's transaction and
 * returns a human-facing reference in the `PU-XXXX-XX` format, where the last
 * two digits are the Kigali calendar year. `counters/bookings` is
 * infrastructure state, not part of the public data model.
 */
export declare function nextBookingRef(db: Firestore, tx: Transaction, now?: Date): Promise<{
    ref: string;
    sequence: number;
}>;
