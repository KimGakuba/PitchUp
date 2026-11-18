/**
 * Phase 8 — marks bookings completed once kickoff + duration has passed.
 * Runs every 30 minutes; the linked pickup game is completed too.
 */
export declare const completePastBookings: import("firebase-functions/v2/scheduler").ScheduleFunction;
/**
 * Phase 8 — 2-hour kickoff reminders. Runs every 30 minutes and de-duplicates
 * with a `reminders/{bookingId}` marker document so players are only pinged
 * once even if the scheduler retries.
 */
export declare const sendKickoffReminders: import("firebase-functions/v2/scheduler").ScheduleFunction;
