/**
 * Cost-splitting for pickup games (integer RWF only).
 *
 * Rule: each *non-organizer* player pays `ceil(totalPrice / confirmedPlayers)`.
 * The organizer absorbs the rounding remainder, so the sum of shares is
 * exactly `totalPrice` and nobody is ever charged a fractional franc.
 *
 * Example: totalPrice = 20,000 RWF, 6 confirmed players ->
 * perPlayer = ceil(20,000 / 6) = 3,334 RWF
 * organizerShare = 20,000 - 3,334 * 5 = 3,330 RWF
 */
export interface CostSplit {
    perPlayer: number;
    organizerShare: number;
    totalPrice: number;
    confirmedPlayers: number;
}
export declare function ceilDiv(numerator: number, denominator: number): number;
/**
 * @param totalPrice integer RWF owed for the booking
 * @param confirmedPlayers number of players currently in the game (>= 1)
 */
export declare function computeCostSplit(totalPrice: number, confirmedPlayers: number): CostSplit;
/** Amount a specific player owes for the game. */
export declare function amountForPlayer(split: CostSplit, uid: string, organizerId: string): number;
