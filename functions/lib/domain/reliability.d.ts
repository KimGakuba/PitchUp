/**
 * Reliability = attended / (attended + noShows) * 100, rounded to the
 * nearest whole percent. Excused absences are not counted in either side
 * of the fraction.
 *
 * `users.gamesPlayed` counts attended games (present), while `users.noShows`
 * counts unexcused absences, so the formula below matches the stored fields.
 */
export declare function reliabilityScore(gamesPlayed: number, noShows: number): number;
export type AttendanceValue = "present" | "excused" | "no_show" | null;
