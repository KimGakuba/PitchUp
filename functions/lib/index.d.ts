/** Health check used by the emulator smoke test and uptime monitoring. */
export declare const ping: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    ok: boolean;
    service: string;
    time: number;
}>, unknown>;
export { cancelBooking, convertToGame, createBooking, setSlotBlocked, } from "./handlers/bookings";
export { joinGame, leaveGame, markAttendance, postResult, setTeams, } from "./handlers/games";
export { initiatePayment, paymentWebhook, simulatePaymentOutcome, } from "./handlers/payments";
export { registerFcmToken, resolveReport, setUserRole, setUserStatus, unregisterFcmToken, } from "./handlers/admin";
export { onReviewCreated } from "./triggers/reviews";
export { onUserProfileCreated } from "./triggers/users";
export { completePastBookings, sendKickoffReminders, } from "./scheduled/jobs";
