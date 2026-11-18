/**
 * Slot math shared by every booking/availability handler.
 *
 * A "slot" is one 30-minute block at a venue. Slot documents live at
 * `venues/{venueId}/slots/{YYYYMMDD_HHmm}`. A slot document's *presence*
 * means the block is unavailable (booked or manually blocked), so booking
 * creation is a pure create-if-absent transaction over these doc IDs.
 *
 * All wall-clock times are Kigali local time (Africa/Kigali, UTC+2 with no
 * daylight saving). Firestore keeps the Date strings used for display.
 */
export declare const SLOT_MINUTES = 30;
export declare const OPEN_HOUR = 7;
export declare const CLOSE_HOUR = 22;
export declare const ALLOWED_DURATIONS: readonly [60, 90, 120];
export type DurationMin = (typeof ALLOWED_DURATIONS)[number];
export interface LocalDateTimeParts {
    year: number;
    month: number;
    day: number;
    hour: number;
    minute: number;
}
export declare function parseLocalDate(date: string): {
    year: number;
    month: number;
    day: number;
};
export declare function parseTime(time: string): {
    hour: number;
    minute: number;
};
export declare function isAllowedDuration(value: number): value is DurationMin;
export declare function dateKey(date: string): string;
/** Converts a Kigali wall-clock date/time into an absolute Date (UTC). */
export declare function kigaliToUtc(date: string, time: string): Date;
/** Formats an absolute Date as the Kigali calendar date `YYYY-MM-DD`. */
export declare function kigaliDateString(date: Date): string;
/**
 * Returns the 30-minute slot document IDs covering
 * `[startTime, startTime + durationMin)`, e.g.
 * `["20260214_1800", "20260214_1830", "20260214_1900"]`.
 */
export declare function slotIdsFor(date: string, startTime: string, durationMin: number): string[];
/**
 * Throws with a human-readable message when a booking range is outside
 * opening hours (07:00–22:00), is not 30-minute aligned, or is in the past.
 */
export declare function assertBookableRange(date: string, startTime: string, durationMin: number, now?: Date): void;
/** Every 30-minute slot ID between 07:00 and 22:00 for a given date. */
export declare function allSlotIdsForDate(date: string): string[];
/** Booking price for a duration; RWF is integer-only, so round to nearest. */
export declare function computeBookingPrice(pricePerHour: number, durationMin: number): number;
