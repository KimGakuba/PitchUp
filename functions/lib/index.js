"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendKickoffReminders = exports.completePastBookings = exports.onUserProfileCreated = exports.onReviewCreated = exports.unregisterFcmToken = exports.setUserStatus = exports.setUserRole = exports.resolveReport = exports.registerFcmToken = exports.simulatePaymentOutcome = exports.paymentWebhook = exports.initiatePayment = exports.setTeams = exports.postResult = exports.markAttendance = exports.leaveGame = exports.joinGame = exports.setSlotBlocked = exports.createBooking = exports.convertToGame = exports.cancelBooking = exports.ping = void 0;
const app_1 = require("firebase-admin/app");
const v2_1 = require("firebase-functions/v2");
const https_1 = require("firebase-functions/v2/https");
(0, app_1.initializeApp)();
// europe-west1 is the closest reliable Firebase Functions region to East
// Africa at the time of writing; revisit if GCP adds an africa-* region with
// the same product coverage (Auth triggers, Firestore triggers, etc).
(0, v2_1.setGlobalOptions)({ region: "europe-west1" });
/** Health check used by the emulator smoke test and uptime monitoring. */
exports.ping = (0, https_1.onCall)(() => ({
    ok: true,
    service: "pitchup-functions",
    time: Date.now(),
}));
var bookings_1 = require("./handlers/bookings");
Object.defineProperty(exports, "cancelBooking", { enumerable: true, get: function () { return bookings_1.cancelBooking; } });
Object.defineProperty(exports, "convertToGame", { enumerable: true, get: function () { return bookings_1.convertToGame; } });
Object.defineProperty(exports, "createBooking", { enumerable: true, get: function () { return bookings_1.createBooking; } });
Object.defineProperty(exports, "setSlotBlocked", { enumerable: true, get: function () { return bookings_1.setSlotBlocked; } });
var games_1 = require("./handlers/games");
Object.defineProperty(exports, "joinGame", { enumerable: true, get: function () { return games_1.joinGame; } });
Object.defineProperty(exports, "leaveGame", { enumerable: true, get: function () { return games_1.leaveGame; } });
Object.defineProperty(exports, "markAttendance", { enumerable: true, get: function () { return games_1.markAttendance; } });
Object.defineProperty(exports, "postResult", { enumerable: true, get: function () { return games_1.postResult; } });
Object.defineProperty(exports, "setTeams", { enumerable: true, get: function () { return games_1.setTeams; } });
var payments_1 = require("./handlers/payments");
Object.defineProperty(exports, "initiatePayment", { enumerable: true, get: function () { return payments_1.initiatePayment; } });
Object.defineProperty(exports, "paymentWebhook", { enumerable: true, get: function () { return payments_1.paymentWebhook; } });
Object.defineProperty(exports, "simulatePaymentOutcome", { enumerable: true, get: function () { return payments_1.simulatePaymentOutcome; } });
var admin_1 = require("./handlers/admin");
Object.defineProperty(exports, "registerFcmToken", { enumerable: true, get: function () { return admin_1.registerFcmToken; } });
Object.defineProperty(exports, "resolveReport", { enumerable: true, get: function () { return admin_1.resolveReport; } });
Object.defineProperty(exports, "setUserRole", { enumerable: true, get: function () { return admin_1.setUserRole; } });
Object.defineProperty(exports, "setUserStatus", { enumerable: true, get: function () { return admin_1.setUserStatus; } });
Object.defineProperty(exports, "unregisterFcmToken", { enumerable: true, get: function () { return admin_1.unregisterFcmToken; } });
var reviews_1 = require("./triggers/reviews");
Object.defineProperty(exports, "onReviewCreated", { enumerable: true, get: function () { return reviews_1.onReviewCreated; } });
var users_1 = require("./triggers/users");
Object.defineProperty(exports, "onUserProfileCreated", { enumerable: true, get: function () { return users_1.onUserProfileCreated; } });
var jobs_1 = require("./scheduled/jobs");
Object.defineProperty(exports, "completePastBookings", { enumerable: true, get: function () { return jobs_1.completePastBookings; } });
Object.defineProperty(exports, "sendKickoffReminders", { enumerable: true, get: function () { return jobs_1.sendKickoffReminders; } });
//# sourceMappingURL=index.js.map