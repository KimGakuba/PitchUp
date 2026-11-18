"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.venueSchema = exports.reviewSchema = exports.registerTokenSchema = exports.resolveReportSchema = exports.setUserStatusSchema = exports.setUserRoleSchema = exports.setSlotBlockedSchema = exports.simulatePaymentSchema = exports.initiatePaymentSchema = exports.postResultSchema = exports.markAttendanceSchema = exports.setTeamsSchema = exports.leaveGameSchema = exports.joinGameSchema = exports.convertToGameSchema = exports.cancelBookingSchema = exports.createBookingSchema = exports.idSchema = exports.phoneSchema = exports.durationSchema = exports.timeSchema = exports.dateSchema = exports.attendanceSchema = exports.paymentStatusSchema = exports.providerSchema = exports.sportSchema = exports.roleSchema = void 0;
const zod_1 = require("zod");
const slots_1 = require("../domain/slots");
exports.roleSchema = zod_1.z.enum(["player", "owner", "admin"]);
exports.sportSchema = zod_1.z.enum(["football", "basketball"]);
exports.providerSchema = zod_1.z.enum(["mtn", "airtel"]);
exports.paymentStatusSchema = zod_1.z.enum(["pending", "success", "failed"]);
exports.attendanceSchema = zod_1.z.enum(["present", "excused", "no_show"]);
exports.dateSchema = zod_1.z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, "Use YYYY-MM-DD")
    .refine((value) => {
    try {
        (0, slots_1.parseLocalDate)(value);
        return true;
    }
    catch {
        return false;
    }
}, "Invalid calendar date");
exports.timeSchema = zod_1.z
    .string()
    .regex(/^\d{2}:\d{2}$/, "Use HH:mm")
    .refine((value) => {
    try {
        (0, slots_1.parseTime)(value);
        return true;
    }
    catch {
        return false;
    }
}, "Invalid time");
exports.durationSchema = zod_1.z
    .number()
    .int()
    .refine((value) => slots_1.ALLOWED_DURATIONS.includes(value), "Duration must be 60, 90 or 120 minutes");
exports.phoneSchema = zod_1.z
    .string()
    .regex(/^\+250\d{9}$/, "Use an Rwandan phone number, e.g. +250780000001");
exports.idSchema = zod_1.z.string().min(1).max(128);
exports.createBookingSchema = zod_1.z.object({
    venueId: exports.idSchema,
    date: exports.dateSchema,
    startTime: exports.timeSchema,
    durationMin: exports.durationSchema,
});
exports.cancelBookingSchema = zod_1.z.object({
    bookingId: exports.idSchema,
    reason: zod_1.z.string().trim().max(300).optional(),
});
exports.convertToGameSchema = zod_1.z.object({
    bookingId: exports.idSchema,
    title: zod_1.z.string().trim().min(3).max(80),
    maxPlayers: zod_1.z.number().int().min(2).max(40),
});
exports.joinGameSchema = zod_1.z.object({
    gameId: exports.idSchema,
});
exports.leaveGameSchema = zod_1.z.object({
    gameId: exports.idSchema,
});
exports.setTeamsSchema = zod_1.z.object({
    gameId: exports.idSchema,
    teamA: zod_1.z.array(exports.idSchema).max(40),
    teamB: zod_1.z.array(exports.idSchema).max(40),
});
exports.markAttendanceSchema = zod_1.z.object({
    gameId: exports.idSchema,
    attendance: zod_1.z.record(zod_1.z.string().min(1), exports.attendanceSchema),
});
exports.postResultSchema = zod_1.z.object({
    gameId: exports.idSchema,
    scoreA: zod_1.z.number().int().min(0).max(999),
    scoreB: zod_1.z.number().int().min(0).max(999),
});
exports.initiatePaymentSchema = zod_1.z.object({
    purpose: zod_1.z.enum(["game", "booking"]),
    targetId: exports.idSchema,
    provider: exports.providerSchema,
    phone: exports.phoneSchema,
});
exports.simulatePaymentSchema = zod_1.z.object({
    paymentId: exports.idSchema,
    outcome: zod_1.z.enum(["success", "failed"]),
});
exports.setSlotBlockedSchema = zod_1.z.object({
    venueId: exports.idSchema,
    date: exports.dateSchema,
    slotIds: zod_1.z.array(zod_1.z.string().min(1)).min(1).max(64),
    blocked: zod_1.z.boolean(),
    reason: zod_1.z.string().trim().max(120).optional(),
});
exports.setUserRoleSchema = zod_1.z.object({
    uid: exports.idSchema,
    role: exports.roleSchema,
});
exports.setUserStatusSchema = zod_1.z.object({
    uid: exports.idSchema,
    suspend: zod_1.z.boolean(),
    reason: zod_1.z.string().trim().max(300).optional(),
});
exports.resolveReportSchema = zod_1.z.object({
    reportId: exports.idSchema,
    action: zod_1.z.enum(["resolve", "dismiss", "suspend", "activate"]),
    notes: zod_1.z.string().trim().max(300).optional(),
});
exports.registerTokenSchema = zod_1.z.object({
    token: zod_1.z.string().min(10).max(4096),
});
exports.reviewSchema = zod_1.z.object({
    venueId: exports.idSchema,
    rating: zod_1.z.number().int().min(1).max(5),
    text: zod_1.z.string().trim().min(3).max(1000),
});
exports.venueSchema = zod_1.z.object({
    name: zod_1.z.string().trim().min(3).max(120),
    sport: exports.sportSchema,
    format: zod_1.z.string().trim().min(1).max(40),
    surface: zod_1.z.string().trim().min(1).max(60),
    sector: zod_1.z.enum([
        "Remera",
        "Nyarutarama",
        "Kicukiro",
        "Kimihurura",
        "Nyamirambo",
    ]),
    address: zod_1.z.string().trim().min(3).max(200),
    pricePerHour: zod_1.z.number().int().min(1000).max(1_000_000),
    amenities: zod_1.z.array(zod_1.z.string().trim().min(1).max(40)).max(20),
    photos: zod_1.z.array(zod_1.z.string().url()).max(10),
});
//# sourceMappingURL=validation.js.map