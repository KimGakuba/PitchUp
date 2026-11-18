import { z } from "zod";
import {
  ALLOWED_DURATIONS,
  parseLocalDate,
  parseTime,
} from "../domain/slots";

export const roleSchema = z.enum(["player", "owner", "admin"]);
export const sportSchema = z.enum(["football", "basketball"]);
export const providerSchema = z.enum(["mtn", "airtel"]);
export const paymentStatusSchema = z.enum(["pending", "success", "failed"]);
export const attendanceSchema = z.enum(["present", "excused", "no_show"]);

export const dateSchema = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, "Use YYYY-MM-DD")
  .refine((value) => {
    try {
      parseLocalDate(value);
      return true;
    } catch {
      return false;
    }
  }, "Invalid calendar date");

export const timeSchema = z
  .string()
  .regex(/^\d{2}:\d{2}$/, "Use HH:mm")
  .refine((value) => {
    try {
      parseTime(value);
      return true;
    } catch {
      return false;
    }
  }, "Invalid time");

export const durationSchema = z
  .number()
  .int()
  .refine(
    (value) => (ALLOWED_DURATIONS as readonly number[]).includes(value),
    "Duration must be 60, 90 or 120 minutes",
  );

export const phoneSchema = z
  .string()
  .regex(/^\+250\d{9}$/, "Use an Rwandan phone number, e.g. +250780000001");

export const idSchema = z.string().min(1).max(128);

export const createBookingSchema = z.object({
  venueId: idSchema,
  date: dateSchema,
  startTime: timeSchema,
  durationMin: durationSchema,
});

export const cancelBookingSchema = z.object({
  bookingId: idSchema,
  reason: z.string().trim().max(300).optional(),
});

export const convertToGameSchema = z.object({
  bookingId: idSchema,
  title: z.string().trim().min(3).max(80),
  maxPlayers: z.number().int().min(2).max(40),
});

export const joinGameSchema = z.object({
  gameId: idSchema,
});

export const leaveGameSchema = z.object({
  gameId: idSchema,
});

export const setTeamsSchema = z.object({
  gameId: idSchema,
  teamA: z.array(idSchema).max(40),
  teamB: z.array(idSchema).max(40),
});

export const markAttendanceSchema = z.object({
  gameId: idSchema,
  attendance: z.record(z.string().min(1), attendanceSchema),
});

export const postResultSchema = z.object({
  gameId: idSchema,
  scoreA: z.number().int().min(0).max(999),
  scoreB: z.number().int().min(0).max(999),
});

export const initiatePaymentSchema = z.object({
  purpose: z.enum(["game", "booking"]),
  targetId: idSchema,
  provider: providerSchema,
  phone: phoneSchema,
});

export const simulatePaymentSchema = z.object({
  paymentId: idSchema,
  outcome: z.enum(["success", "failed"]),
});

export const setSlotBlockedSchema = z.object({
  venueId: idSchema,
  date: dateSchema,
  slotIds: z.array(z.string().min(1)).min(1).max(64),
  blocked: z.boolean(),
  reason: z.string().trim().max(120).optional(),
});

export const setUserRoleSchema = z.object({
  uid: idSchema,
  role: roleSchema,
});

export const setUserStatusSchema = z.object({
  uid: idSchema,
  suspend: z.boolean(),
  reason: z.string().trim().max(300).optional(),
});

export const resolveReportSchema = z.object({
  reportId: idSchema,
  action: z.enum(["resolve", "dismiss", "suspend", "activate"]),
  notes: z.string().trim().max(300).optional(),
});

export const registerTokenSchema = z.object({
  token: z.string().min(10).max(4096),
});

export const reviewSchema = z.object({
  venueId: idSchema,
  rating: z.number().int().min(1).max(5),
  text: z.string().trim().min(3).max(1000),
});

export const venueSchema = z.object({
  name: z.string().trim().min(3).max(120),
  sport: sportSchema,
  format: z.string().trim().min(1).max(40),
  surface: z.string().trim().min(1).max(60),
  sector: z.enum([
    "Remera",
    "Nyarutarama",
    "Kicukiro",
    "Kimihurura",
    "Nyamirambo",
  ]),
  address: z.string().trim().min(3).max(200),
  pricePerHour: z.number().int().min(1000).max(1_000_000),
  amenities: z.array(z.string().trim().min(1).max(40)).max(20),
  photos: z.array(z.string().url()).max(10),
});
