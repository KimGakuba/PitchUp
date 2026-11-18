"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.nextBookingRef = nextBookingRef;
/**
 * Reserves the next booking sequence inside the caller's transaction and
 * returns a human-facing reference in the `PU-XXXX-XX` format, where the last
 * two digits are the Kigali calendar year. `counters/bookings` is
 * infrastructure state, not part of the public data model.
 */
async function nextBookingRef(db, tx, now = new Date()) {
    const counterRef = db.collection("counters").doc("bookings");
    const snap = await tx.get(counterRef);
    const current = snap.exists ? Number(snap.get("seq")) : 0;
    const sequence = (Number.isFinite(current) ? current : 0) + 1;
    tx.set(counterRef, { seq: sequence }, { merge: true });
    const kigaliYear = new Date(now.getTime() + 120 * 60_000).getUTCFullYear();
    const year = String(kigaliYear % 100).padStart(2, "0");
    return { ref: `PU-${String(sequence).padStart(4, "0")}-${year}`, sequence };
}
//# sourceMappingURL=booking-ref.js.map