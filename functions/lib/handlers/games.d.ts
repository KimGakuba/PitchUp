declare function bookingForGame(db: FirebaseFirestore.Firestore, bookingId: string): Promise<FirebaseFirestore.DocumentData>;
/**
 * Phase 5 — transactional join. Enforces capacity and recomputes
 * `costPerPlayer = ceil(totalPrice / confirmedPlayers)` so every member sees
 * the same integer RWF share. The organizer absorbs the rounding remainder.
 */
export declare const joinGame: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    alreadyJoined: boolean;
    costPerPlayer: number;
    organizerShare?: undefined;
    confirmedPlayers?: undefined;
    organizerId?: undefined;
} | {
    alreadyJoined: boolean;
    costPerPlayer: number;
    organizerShare: number;
    confirmedPlayers: number;
    organizerId: string;
}>, unknown>;
/**
 * Phase 5 — transactional leave. The organizer cannot leave (they must cancel
 * the booking, which also cancels the game). The split is recomputed for the
 * remaining players.
 */
export declare const leaveGame: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    left: boolean;
    costPerPlayer: number;
    confirmedPlayers: number;
}>, unknown>;
/**
 * Phase 7 — organizer/admin attendance. Present increments `gamesPlayed`,
 * no-show increments `noShows`, excused changes neither. Reliability is
 * recalculated from the resulting counters.
 */
export declare const markAttendance: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    gameId: string;
    updated: string[];
    alreadyMarked: number;
}>, unknown>;
/**
 * Organizer/admin assigns Team A / Team B. The two arrays must partition the
 * confirmed player list exactly (no duplicates, no outsiders).
 */
export declare const setTeams: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    gameId: string;
    teamA: string[];
    teamB: string[];
}>, unknown>;
/** Phase 7 — organizer/admin posts the final score and notifies attendees. */
export declare const postResult: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    gameId: string;
    scoreA: number;
    scoreB: number;
}>, unknown>;
export { bookingForGame };
