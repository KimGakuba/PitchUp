/**
 * Phase 4 — ZERO double-booking guarantee.
 *
 * Inside a single Firestore transaction we (1) re-read the venue, (2) read
 * every 30-minute slot document for the requested range, and (3) abort if any
 * document exists (booked OR manually blocked). If all are free we write the
 * booking plus every slot doc. Firestore's transactional isolation means two
 * concurrent requests for the same range cannot both commit.
 */
export declare const createBooking: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    bookingId: string;
    ref: string;
    totalPrice: number;
    date: string;
    startTime: string;
    durationMin: number;
    venueId: string;
    venueName: string;
    slotIds: string[];
}>, unknown>;
/**
 * Phase 4 — cancellation. Frees every slot that still belongs to the booking,
 * cancels a linked pickup game, and notifies participants. Cancellation is
 * always allowed; cancelling within 2 hours of kickoff is recorded as a late
 * cancellation (mock payments have no automatic refund).
 */
export declare const cancelBooking: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    bookingId: string;
    alreadyCancelled: boolean;
    freedSlots: never[];
    cancelledGameId?: undefined;
} | {
    bookingId: string;
    freedSlots: string[];
    cancelledGameId: string | null;
    alreadyCancelled?: undefined;
}>, unknown>;
/**
 * Phase 5 — turn an upcoming booking into a public pickup game. The booking
 * owner becomes the organizer and the first confirmed player.
 */
export declare const convertToGame: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    gameId: string;
    costPerPlayer: number;
}>, unknown>;
/**
 * Phase 3/4 — owner blocks or unblocks 30-minute slots for their venue.
 * Blocking creates slot docs (presence = unavailable); unblocking only
 * removes docs that are manually blocked, never booked ones.
 */
export declare const setSlotBlocked: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    changed: number;
    skipped: string[];
    blocked: boolean;
}>, unknown>;
