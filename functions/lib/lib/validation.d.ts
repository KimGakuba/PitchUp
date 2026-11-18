import { z } from "zod";
export declare const roleSchema: z.ZodEnum<["player", "owner", "admin"]>;
export declare const sportSchema: z.ZodEnum<["football", "basketball"]>;
export declare const providerSchema: z.ZodEnum<["mtn", "airtel"]>;
export declare const paymentStatusSchema: z.ZodEnum<["pending", "success", "failed"]>;
export declare const attendanceSchema: z.ZodEnum<["present", "excused", "no_show"]>;
export declare const dateSchema: z.ZodEffects<z.ZodString, string, string>;
export declare const timeSchema: z.ZodEffects<z.ZodString, string, string>;
export declare const durationSchema: z.ZodEffects<z.ZodNumber, number, number>;
export declare const phoneSchema: z.ZodString;
export declare const idSchema: z.ZodString;
export declare const createBookingSchema: z.ZodObject<{
    venueId: z.ZodString;
    date: z.ZodEffects<z.ZodString, string, string>;
    startTime: z.ZodEffects<z.ZodString, string, string>;
    durationMin: z.ZodEffects<z.ZodNumber, number, number>;
}, "strip", z.ZodTypeAny, {
    venueId: string;
    date: string;
    startTime: string;
    durationMin: number;
}, {
    venueId: string;
    date: string;
    startTime: string;
    durationMin: number;
}>;
export declare const cancelBookingSchema: z.ZodObject<{
    bookingId: z.ZodString;
    reason: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    bookingId: string;
    reason?: string | undefined;
}, {
    bookingId: string;
    reason?: string | undefined;
}>;
export declare const convertToGameSchema: z.ZodObject<{
    bookingId: z.ZodString;
    title: z.ZodString;
    maxPlayers: z.ZodNumber;
}, "strip", z.ZodTypeAny, {
    title: string;
    bookingId: string;
    maxPlayers: number;
}, {
    title: string;
    bookingId: string;
    maxPlayers: number;
}>;
export declare const joinGameSchema: z.ZodObject<{
    gameId: z.ZodString;
}, "strip", z.ZodTypeAny, {
    gameId: string;
}, {
    gameId: string;
}>;
export declare const leaveGameSchema: z.ZodObject<{
    gameId: z.ZodString;
}, "strip", z.ZodTypeAny, {
    gameId: string;
}, {
    gameId: string;
}>;
export declare const setTeamsSchema: z.ZodObject<{
    gameId: z.ZodString;
    teamA: z.ZodArray<z.ZodString, "many">;
    teamB: z.ZodArray<z.ZodString, "many">;
}, "strip", z.ZodTypeAny, {
    gameId: string;
    teamA: string[];
    teamB: string[];
}, {
    gameId: string;
    teamA: string[];
    teamB: string[];
}>;
export declare const markAttendanceSchema: z.ZodObject<{
    gameId: z.ZodString;
    attendance: z.ZodRecord<z.ZodString, z.ZodEnum<["present", "excused", "no_show"]>>;
}, "strip", z.ZodTypeAny, {
    gameId: string;
    attendance: Record<string, "present" | "excused" | "no_show">;
}, {
    gameId: string;
    attendance: Record<string, "present" | "excused" | "no_show">;
}>;
export declare const postResultSchema: z.ZodObject<{
    gameId: z.ZodString;
    scoreA: z.ZodNumber;
    scoreB: z.ZodNumber;
}, "strip", z.ZodTypeAny, {
    gameId: string;
    scoreA: number;
    scoreB: number;
}, {
    gameId: string;
    scoreA: number;
    scoreB: number;
}>;
export declare const initiatePaymentSchema: z.ZodObject<{
    purpose: z.ZodEnum<["game", "booking"]>;
    targetId: z.ZodString;
    provider: z.ZodEnum<["mtn", "airtel"]>;
    phone: z.ZodString;
}, "strip", z.ZodTypeAny, {
    phone: string;
    purpose: "game" | "booking";
    targetId: string;
    provider: "mtn" | "airtel";
}, {
    phone: string;
    purpose: "game" | "booking";
    targetId: string;
    provider: "mtn" | "airtel";
}>;
export declare const simulatePaymentSchema: z.ZodObject<{
    paymentId: z.ZodString;
    outcome: z.ZodEnum<["success", "failed"]>;
}, "strip", z.ZodTypeAny, {
    paymentId: string;
    outcome: "success" | "failed";
}, {
    paymentId: string;
    outcome: "success" | "failed";
}>;
export declare const setSlotBlockedSchema: z.ZodObject<{
    venueId: z.ZodString;
    date: z.ZodEffects<z.ZodString, string, string>;
    slotIds: z.ZodArray<z.ZodString, "many">;
    blocked: z.ZodBoolean;
    reason: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    venueId: string;
    date: string;
    slotIds: string[];
    blocked: boolean;
    reason?: string | undefined;
}, {
    venueId: string;
    date: string;
    slotIds: string[];
    blocked: boolean;
    reason?: string | undefined;
}>;
export declare const setUserRoleSchema: z.ZodObject<{
    uid: z.ZodString;
    role: z.ZodEnum<["player", "owner", "admin"]>;
}, "strip", z.ZodTypeAny, {
    role: "player" | "owner" | "admin";
    uid: string;
}, {
    role: "player" | "owner" | "admin";
    uid: string;
}>;
export declare const setUserStatusSchema: z.ZodObject<{
    uid: z.ZodString;
    suspend: z.ZodBoolean;
    reason: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    uid: string;
    suspend: boolean;
    reason?: string | undefined;
}, {
    uid: string;
    suspend: boolean;
    reason?: string | undefined;
}>;
export declare const resolveReportSchema: z.ZodObject<{
    reportId: z.ZodString;
    action: z.ZodEnum<["resolve", "dismiss", "suspend", "activate"]>;
    notes: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    reportId: string;
    action: "suspend" | "resolve" | "dismiss" | "activate";
    notes?: string | undefined;
}, {
    reportId: string;
    action: "suspend" | "resolve" | "dismiss" | "activate";
    notes?: string | undefined;
}>;
export declare const registerTokenSchema: z.ZodObject<{
    token: z.ZodString;
}, "strip", z.ZodTypeAny, {
    token: string;
}, {
    token: string;
}>;
export declare const reviewSchema: z.ZodObject<{
    venueId: z.ZodString;
    rating: z.ZodNumber;
    text: z.ZodString;
}, "strip", z.ZodTypeAny, {
    venueId: string;
    rating: number;
    text: string;
}, {
    venueId: string;
    rating: number;
    text: string;
}>;
export declare const venueSchema: z.ZodObject<{
    name: z.ZodString;
    sport: z.ZodEnum<["football", "basketball"]>;
    format: z.ZodString;
    surface: z.ZodString;
    sector: z.ZodEnum<["Remera", "Nyarutarama", "Kicukiro", "Kimihurura", "Nyamirambo"]>;
    address: z.ZodString;
    pricePerHour: z.ZodNumber;
    amenities: z.ZodArray<z.ZodString, "many">;
    photos: z.ZodArray<z.ZodString, "many">;
}, "strip", z.ZodTypeAny, {
    name: string;
    sport: "football" | "basketball";
    format: string;
    surface: string;
    sector: "Remera" | "Nyarutarama" | "Kicukiro" | "Kimihurura" | "Nyamirambo";
    address: string;
    pricePerHour: number;
    amenities: string[];
    photos: string[];
}, {
    name: string;
    sport: "football" | "basketball";
    format: string;
    surface: string;
    sector: "Remera" | "Nyarutarama" | "Kicukiro" | "Kimihurura" | "Nyamirambo";
    address: string;
    pricePerHour: number;
    amenities: string[];
    photos: string[];
}>;
