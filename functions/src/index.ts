import { initializeApp } from "firebase-admin/app";
import { setGlobalOptions } from "firebase-functions/v2";
import { onCall } from "firebase-functions/v2/https";

initializeApp();

// europe-west1 is the closest reliable Firebase Functions region to East
// Africa at the time of writing; revisit if GCP adds an africa-* region with
// the same product coverage (Auth triggers, Firestore triggers, etc).
setGlobalOptions({ region: "europe-west1" });

/** Health check used by the emulator smoke test and uptime monitoring. */
export const ping = onCall(() => ({
  ok: true,
  service: "pitchup-functions",
  time: Date.now(),
}));

export {
  cancelBooking,
  convertToGame,
  createBooking,
  setSlotBlocked,
} from "./handlers/bookings";

export {
  joinGame,
  leaveGame,
  markAttendance,
  postResult,
  setTeams,
} from "./handlers/games";

export {
  initiatePayment,
  paymentWebhook,
  simulatePaymentOutcome,
} from "./handlers/payments";

export {
  registerFcmToken,
  resolveReport,
  setUserRole,
  setUserStatus,
  unregisterFcmToken,
} from "./handlers/admin";

export { onReviewCreated } from "./triggers/reviews";
export { onUserProfileCreated } from "./triggers/users";

export {
  completePastBookings,
  sendKickoffReminders,
} from "./scheduled/jobs";
