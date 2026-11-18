"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.reliabilityScore = reliabilityScore;
/**
 * Reliability = attended / (attended + noShows) * 100, rounded to the
 * nearest whole percent. Excused absences are not counted in either side
 * of the fraction.
 *
 * `users.gamesPlayed` counts attended games (present), while `users.noShows`
 * counts unexcused absences, so the formula below matches the stored fields.
 */
function reliabilityScore(gamesPlayed, noShows) {
    const attended = Math.max(0, gamesPlayed);
    const missed = Math.max(0, noShows);
    const denominator = attended + missed;
    if (denominator === 0)
        return 100;
    return Math.round((attended / denominator) * 100);
}
//# sourceMappingURL=reliability.js.map