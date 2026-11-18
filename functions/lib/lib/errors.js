"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.invalidArgument = invalidArgument;
exports.notFound = notFound;
exports.permissionDenied = permissionDenied;
exports.failedPrecondition = failedPrecondition;
exports.alreadyExists = alreadyExists;
exports.unauthenticated = unauthenticated;
exports.parseInput = parseInput;
const https_1 = require("firebase-functions/v2/https");
function invalidArgument(message, details) {
    return new https_1.HttpsError("invalid-argument", message, details);
}
function notFound(message) {
    return new https_1.HttpsError("not-found", message);
}
function permissionDenied(message) {
    return new https_1.HttpsError("permission-denied", message);
}
function failedPrecondition(message, details) {
    return new https_1.HttpsError("failed-precondition", message, details);
}
function alreadyExists(message) {
    return new https_1.HttpsError("already-exists", message);
}
function unauthenticated(message = "Sign-in required") {
    return new https_1.HttpsError("unauthenticated", message);
}
/** Parses input with zod, translating failures into a clean HttpsError. */
function parseInput(schema, data) {
    const result = schema.safeParse(data);
    if (!result.success) {
        const first = result.error.issues[0];
        const path = first?.path.join(".");
        throw invalidArgument(path ? `${path}: ${first?.message}` : (first?.message ?? "Invalid input"), result.error.flatten());
    }
    return result.data;
}
//# sourceMappingURL=errors.js.map