import { HttpsError } from "firebase-functions/v2/https";
import { z } from "zod";
export declare function invalidArgument(message: string, details?: unknown): HttpsError;
export declare function notFound(message: string): HttpsError;
export declare function permissionDenied(message: string): HttpsError;
export declare function failedPrecondition(message: string, details?: unknown): HttpsError;
export declare function alreadyExists(message: string): HttpsError;
export declare function unauthenticated(message?: string): HttpsError;
/** Parses input with zod, translating failures into a clean HttpsError. */
export declare function parseInput<T extends z.ZodTypeAny>(schema: T, data: unknown): z.infer<T>;
