"use strict";
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
Object.defineProperty(exports, "__esModule", { value: true });
exports.ALLOWED_DURATIONS = exports.CLOSE_HOUR = exports.OPEN_HOUR = exports.SLOT_MINUTES = void 0;
exports.parseLocalDate = parseLocalDate;
exports.parseTime = parseTime;
exports.isAllowedDuration = isAllowedDuration;
exports.dateKey = dateKey;
exports.kigaliToUtc = kigaliToUtc;
exports.kigaliDateString = kigaliDateString;
exports.slotIdsFor = slotIdsFor;
exports.assertBookableRange = assertBookableRange;
exports.allSlotIdsForDate = allSlotIdsForDate;
exports.computeBookingPrice = computeBookingPrice;
exports.SLOT_MINUTES = 30;
exports.OPEN_HOUR = 7;
exports.CLOSE_HOUR = 22;
exports.ALLOWED_DURATIONS = [60, 90, 120];
const KIGALI_OFFSET_MINUTES = 120;
const DATE_RE = /^(\d{4})-(\d{2})-(\d{2})$/;
const TIME_RE = /^(\d{2}):(\d{2})$/;
function parseLocalDate(date) {
    const match = DATE_RE.exec(date);
    if (!match)
        throw new Error(`Invalid date "${date}", expected YYYY-MM-DD`);
    const year = Number(match[1]);
    const month = Number(match[2]);
    const day = Number(match[3]);
    const probe = new Date(Date.UTC(year, month - 1, day));
    if (probe.getUTCFullYear() !== year ||
        probe.getUTCMonth() !== month - 1 ||
        probe.getUTCDate() !== day) {
        throw new Error(`Invalid calendar date "${date}"`);
    }
    return { year, month, day };
}
function parseTime(time) {
    const match = TIME_RE.exec(time);
    if (!match)
        throw new Error(`Invalid time "${time}", expected HH:mm`);
    const hour = Number(match[1]);
    const minute = Number(match[2]);
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        throw new Error(`Invalid time "${time}"`);
    }
    return { hour, minute };
}
function isAllowedDuration(value) {
    return exports.ALLOWED_DURATIONS.includes(value);
}
function dateKey(date) {
    const { year, month, day } = parseLocalDate(date);
    return `${year}${String(month).padStart(2, "0")}${String(day).padStart(2, "0")}`;
}
/** Converts a Kigali wall-clock date/time into an absolute Date (UTC). */
function kigaliToUtc(date, time) {
    const { year, month, day } = parseLocalDate(date);
    const { hour, minute } = parseTime(time);
    return new Date(Date.UTC(year, month - 1, day, hour, minute - KIGALI_OFFSET_MINUTES));
}
/** Formats an absolute Date as the Kigali calendar date `YYYY-MM-DD`. */
function kigaliDateString(date) {
    const shifted = new Date(date.getTime() + KIGALI_OFFSET_MINUTES * 60_000);
    return shifted.toISOString().slice(0, 10);
}
/**
 * Returns the 30-minute slot document IDs covering
 * `[startTime, startTime + durationMin)`, e.g.
 * `["20260214_1800", "20260214_1830", "20260214_1900"]`.
 */
function slotIdsFor(date, startTime, durationMin) {
    const { hour, minute } = parseTime(startTime);
    if (minute % exports.SLOT_MINUTES !== 0) {
        throw new Error("Start time must align to a 30-minute boundary");
    }
    if (!isAllowedDuration(durationMin)) {
        throw new Error("Duration must be 60, 90 or 120 minutes");
    }
    const key = dateKey(date);
    let minutes = hour * 60 + minute;
    const end = minutes + durationMin;
    const ids = [];
    while (minutes < end) {
        const hh = String(Math.floor(minutes / 60)).padStart(2, "0");
        const mm = String(minutes % 60).padStart(2, "0");
        ids.push(`${key}_${hh}${mm}`);
        minutes += exports.SLOT_MINUTES;
    }
    return ids;
}
/**
 * Throws with a human-readable message when a booking range is outside
 * opening hours (07:00–22:00), is not 30-minute aligned, or is in the past.
 */
function assertBookableRange(date, startTime, durationMin, now = new Date()) {
    const { hour, minute } = parseTime(startTime);
    if (minute % exports.SLOT_MINUTES !== 0) {
        throw new Error("Start time must align to a 30-minute boundary");
    }
    if (!isAllowedDuration(durationMin)) {
        throw new Error("Duration must be 60, 90 or 120 minutes");
    }
    const startMinutes = hour * 60 + minute;
    const endMinutes = startMinutes + durationMin;
    if (startMinutes < exports.OPEN_HOUR * 60 || endMinutes > exports.CLOSE_HOUR * 60) {
        throw new Error("Bookings are only available between 07:00 and 22:00");
    }
    if (kigaliToUtc(date, startTime).getTime() <= now.getTime()) {
        throw new Error("Cannot book a time in the past");
    }
}
/** Every 30-minute slot ID between 07:00 and 22:00 for a given date. */
function allSlotIdsForDate(date) {
    const key = dateKey(date);
    const ids = [];
    for (let minutes = exports.OPEN_HOUR * 60; minutes < exports.CLOSE_HOUR * 60; minutes += exports.SLOT_MINUTES) {
        const hh = String(Math.floor(minutes / 60)).padStart(2, "0");
        const mm = String(minutes % 60).padStart(2, "0");
        ids.push(`${key}_${hh}${mm}`);
    }
    return ids;
}
/** Booking price for a duration; RWF is integer-only, so round to nearest. */
function computeBookingPrice(pricePerHour, durationMin) {
    if (!Number.isInteger(pricePerHour) || pricePerHour < 0) {
        throw new Error("pricePerHour must be a non-negative integer (RWF)");
    }
    if (!isAllowedDuration(durationMin)) {
        throw new Error("Duration must be 60, 90 or 120 minutes");
    }
    return Math.round((pricePerHour * durationMin) / 60);
}
//# sourceMappingURL=slots.js.map