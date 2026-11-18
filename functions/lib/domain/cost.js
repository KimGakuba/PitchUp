"use strict";
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
Object.defineProperty(exports, "__esModule", { value: true });
exports.ceilDiv = ceilDiv;
exports.computeCostSplit = computeCostSplit;
exports.amountForPlayer = amountForPlayer;
function ceilDiv(numerator, denominator) {
    if (!Number.isInteger(numerator) || numerator < 0) {
        throw new Error("numerator must be a non-negative integer");
    }
    if (!Number.isInteger(denominator) || denominator <= 0) {
        throw new Error("denominator must be a positive integer");
    }
    return Math.ceil(numerator / denominator);
}
/**
 * @param totalPrice integer RWF owed for the booking
 * @param confirmedPlayers number of players currently in the game (>= 1)
 */
function computeCostSplit(totalPrice, confirmedPlayers) {
    if (!Number.isInteger(totalPrice) || totalPrice < 0) {
        throw new Error("totalPrice must be a non-negative integer (RWF)");
    }
    if (!Number.isInteger(confirmedPlayers) || confirmedPlayers < 1) {
        throw new Error("confirmedPlayers must be a positive integer");
    }
    const perPlayer = ceilDiv(totalPrice, confirmedPlayers);
    const organizerShare = totalPrice - perPlayer * (confirmedPlayers - 1);
    return { perPlayer, organizerShare, totalPrice, confirmedPlayers };
}
/** Amount a specific player owes for the game. */
function amountForPlayer(split, uid, organizerId) {
    return uid === organizerId ? split.organizerShare : split.perPlayer;
}
//# sourceMappingURL=cost.js.map