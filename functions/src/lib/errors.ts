import { HttpsError } from "firebase-functions/v2/https";
import { z } from "zod";

export function invalidArgument(message: string, details?: unknown): HttpsError {
  return new HttpsError("invalid-argument", message, details);
}

export function notFound(message: string): HttpsError {
  return new HttpsError("not-found", message);
}

export function permissionDenied(message: string): HttpsError {
  return new HttpsError("permission-denied", message);
}

export function failedPrecondition(message: string, details?: unknown): HttpsError {
  return new HttpsError("failed-precondition", message, details);
}

export function alreadyExists(message: string): HttpsError {
  return new HttpsError("already-exists", message);
}

export function unauthenticated(message = "Sign-in required"): HttpsError {
  return new HttpsError("unauthenticated", message);
}

/** Parses input with zod, translating failures into a clean HttpsError. */
export function parseInput<T extends z.ZodTypeAny>(
  schema: T,
  data: unknown,
): z.infer<T> {
  const result = schema.safeParse(data);
  if (!result.success) {
    const first = result.error.issues[0];
    const path = first?.path.join(".");
    throw invalidArgument(
      path ? `${path}: ${first?.message}` : (first?.message ?? "Invalid input"),
      result.error.flatten(),
    );
  }
  return result.data;
}
