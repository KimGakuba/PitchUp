"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.postResult = exports.setTeams = exports.markAttendance = exports.leaveGame = exports.joinGame = void 0;
exports.bookingForGame = bookingForGame;
const firestore_1 = require("firebase-admin/firestore");
const https_1 = require("firebase-functions/v2/https");
const cost_1 = require("../domain/cost");
const slots_1 = require("../domain/slots");
const reliability_1 = require("../domain/reliability");
const auth_1 = require("../lib/auth");
const errors_1 = require("../lib/errors");
const notifications_1 = require("../lib/notifications");
const validation_1 = require("../lib/validation");
async function bookingForGame(db, bookingId) {
    const snap = await db.collection("bookings").doc(bookingId).get();
    if (!snap.exists)
        throw (0, errors_1.notFound)("Linked booking not found");
    return snap.data() ?? {};
}
function kickoffOf(booking) {
    return (0, slots_1.kigaliToUtc)(String(booking.date), String(booking.startTime));
}
/**
 * Phase 5 — transactional join. Enforces capacity and recomputes
 * `costPerPlayer = ceil(totalPrice / confirmedPlayers)` so every member sees
 * the same integer RWF share. The organizer absorbs the rounding remainder.
 */
exports.joinGame = (0, https_1.onCall)(async (request) => {
    const user = await (0, auth_1.requireUser)(request);
    const input = (0, errors_1.parseInput)(validation_1.joinGameSchema, request.data);
    const db = (0, firestore_1.getFirestore)();
    const outcome = await db.runTransaction(async (tx) => {
        const gameRef = db.collection("games").doc(input.gameId);
        const gameSnap = await tx.get(gameRef);
        if (!gameSnap.exists)
            throw (0, errors_1.notFound)("Game not found");
        const game = gameSnap.data() ?? {};
        if (game.status === "cancelled") {
            throw (0, errors_1.failedPrecondition)("This game was cancelled");
        }
        if (game.status === "completed") {
            throw (0, errors_1.failedPrecondition)("This game already finished");
        }
        const playerIds = Array.isArray(game.playerIds)
            ? game.playerIds
            : [];
        if (playerIds.includes(user.uid)) {
            return { alreadyJoined: true, costPerPlayer: Number(game.costPerPlayer) };
        }
        const bookingSnap = await tx.get(db.collection("bookings").doc(String(game.bookingId)));
        if (!bookingSnap.exists)
            throw (0, errors_1.notFound)("Linked booking not found");
        const booking = bookingSnap.data() ?? {};
        if (kickoffOf(booking).getTime() <= Date.now()) {
            throw (0, errors_1.failedPrecondition)("This game has already kicked off");
        }
        const maxPlayers = Number(game.maxPlayers);
        if (playerIds.length >= maxPlayers) {
            throw (0, errors_1.failedPrecondition)("This game is full");
        }
        const nextPlayerIds = [...playerIds, user.uid];
        const split = (0, cost_1.computeCostSplit)(Number(booking.totalPrice), nextPlayerIds.length);
        tx.update(gameRef, {
            playerIds: nextPlayerIds,
            costPerPlayer: split.perPlayer,
            status: nextPlayerIds.length >= maxPlayers ? "full" : "open",
        });
        tx.set(gameRef.collection("players").doc(user.uid), {
            joinedAt: firestore_1.FieldValue.serverTimestamp(),
            paymentStatus: "pending",
            attendance: null,
        });
        return {
            alreadyJoined: false,
            costPerPlayer: split.perPlayer,
            organizerShare: split.organizerShare,
            confirmedPlayers: nextPlayerIds.length,
            organizerId: String(game.organizerId),
        };
    });
    if (!outcome.alreadyJoined && outcome.organizerId) {
        await (0, notifications_1.notifyUsers)([outcome.organizerId], {
            title: "Player joined your game",
            body: `${user.name ?? "A player"} joined. ${outcome.confirmedPlayers} confirmed — ${outcome.costPerPlayer} RWF each.`,
            data: { type: "game_join", gameId: input.gameId },
        }, { notificationId: `game_join_${input.gameId}_${user.uid}` });
    }
    return outcome;
});
/**
 * Phase 5 — transactional leave. The organizer cannot leave (they must cancel
 * the booking, which also cancels the game). The split is recomputed for the
 * remaining players.
 */
exports.leaveGame = (0, https_1.onCall)(async (request) => {
    const user = await (0, auth_1.requireUser)(request);
    const input = (0, errors_1.parseInput)(validation_1.leaveGameSchema, request.data);
    const db = (0, firestore_1.getFirestore)();
    return db.runTransaction(async (tx) => {
        const gameRef = db.collection("games").doc(input.gameId);
        const gameSnap = await tx.get(gameRef);
        if (!gameSnap.exists)
            throw (0, errors_1.notFound)("Game not found");
        const game = gameSnap.data() ?? {};
        if (game.organizerId === user.uid) {
            throw (0, errors_1.failedPrecondition)("The organizer cannot leave. Cancel the booking instead.");
        }
        const playerIds = Array.isArray(game.playerIds)
            ? game.playerIds
            : [];
        if (!playerIds.includes(user.uid)) {
            throw (0, errors_1.failedPrecondition)("You are not in this game");
        }
        const bookingSnap = await tx.get(db.collection("bookings").doc(String(game.bookingId)));
        if (!bookingSnap.exists)
            throw (0, errors_1.notFound)("Linked booking not found");
        const booking = bookingSnap.data() ?? {};
        if (kickoffOf(booking).getTime() <= Date.now()) {
            throw (0, errors_1.failedPrecondition)("This game has already kicked off");
        }
        const nextPlayerIds = playerIds.filter((id) => id !== user.uid);
        const split = (0, cost_1.computeCostSplit)(Number(booking.totalPrice), nextPlayerIds.length);
        tx.update(gameRef, {
            playerIds: nextPlayerIds,
            costPerPlayer: split.perPlayer,
            status: "open",
        });
        tx.delete(gameRef.collection("players").doc(user.uid));
        return { left: true, costPerPlayer: split.perPlayer, confirmedPlayers: nextPlayerIds.length };
    });
});
/**
 * Phase 7 — organizer/admin attendance. Present increments `gamesPlayed`,
 * no-show increments `noShows`, excused changes neither. Reliability is
 * recalculated from the resulting counters.
 */
exports.markAttendance = (0, https_1.onCall)(async (request) => {
    const user = await (0, auth_1.requireUser)(request);
    const input = (0, errors_1.parseInput)(validation_1.markAttendanceSchema, request.data);
    const db = (0, firestore_1.getFirestore)();
    const gameRef = db.collection("games").doc(input.gameId);
    const result = await db.runTransaction(async (tx) => {
        const gameSnap = await tx.get(gameRef);
        if (!gameSnap.exists)
            throw (0, errors_1.notFound)("Game not found");
        const game = gameSnap.data() ?? {};
        if (game.organizerId !== user.uid && user.role !== "admin") {
            throw (0, errors_1.permissionDenied)("Only the organizer or an admin can mark attendance");
        }
        const playerIds = Array.isArray(game.playerIds)
            ? game.playerIds
            : [];
        const unknown = Object.keys(input.attendance).filter((uid) => !playerIds.includes(uid));
        if (unknown.length > 0) {
            throw (0, errors_1.invalidArgument)("Attendance contains non-players", { unknown });
        }
        const playerRefs = playerIds.map((uid) => gameRef.collection("players").doc(uid));
        const playerSnaps = await tx.getAll(...playerRefs);
        const previous = new Map();
        for (const snap of playerSnaps) {
            previous.set(snap.id, snap.get("attendance") ?? null);
        }
        const userRefs = Object.keys(input.attendance).map((uid) => db.collection("users").doc(uid));
        const userSnaps = await tx.getAll(...userRefs);
        const userById = new Map(userSnaps.map((snap) => [snap.id, snap]));
        const updated = [];
        for (const [uid, next] of Object.entries(input.attendance)) {
            const before = previous.get(uid) ?? null;
            if (before === next)
                continue;
            tx.set(gameRef.collection("players").doc(uid), { attendance: next }, { merge: true });
            const userSnap = userById.get(uid);
            if (!userSnap?.exists)
                continue;
            let gamesPlayed = Number(userSnap.get("gamesPlayed") ?? 0);
            let noShows = Number(userSnap.get("noShows") ?? 0);
            if (before === "present")
                gamesPlayed = Math.max(0, gamesPlayed - 1);
            if (before === "no_show")
                noShows = Math.max(0, noShows - 1);
            if (next === "present")
                gamesPlayed += 1;
            if (next === "no_show")
                noShows += 1;
            tx.update(userSnap.ref, {
                gamesPlayed,
                noShows,
                reliabilityScore: (0, reliability_1.reliabilityScore)(gamesPlayed, noShows),
            });
            updated.push(uid);
        }
        return {
            gameId: input.gameId,
            updated,
            alreadyMarked: playerIds.length - updated.length,
        };
    });
    return result;
});
/**
 * Organizer/admin assigns Team A / Team B. The two arrays must partition the
 * confirmed player list exactly (no duplicates, no outsiders).
 */
exports.setTeams = (0, https_1.onCall)(async (request) => {
    const user = await (0, auth_1.requireUser)(request);
    const input = (0, errors_1.parseInput)(validation_1.setTeamsSchema, request.data);
    const db = (0, firestore_1.getFirestore)();
    return db.runTransaction(async (tx) => {
        const gameRef = db.collection("games").doc(input.gameId);
        const snap = await tx.get(gameRef);
        if (!snap.exists)
            throw (0, errors_1.notFound)("Game not found");
        const game = snap.data() ?? {};
        if (game.organizerId !== user.uid && user.role !== "admin") {
            throw (0, errors_1.permissionDenied)("Only the organizer or an admin can set teams");
        }
        const playerIds = Array.isArray(game.playerIds)
            ? game.playerIds
            : [];
        const assignment = [...input.teamA, ...input.teamB];
        const unique = new Set(assignment);
        if (assignment.length !== playerIds.length ||
            unique.size !== playerIds.length ||
            playerIds.some((uid) => !unique.has(uid))) {
            throw (0, errors_1.invalidArgument)("Teams must include every confirmed player exactly once");
        }
        tx.update(gameRef, { teamA: input.teamA, teamB: input.teamB });
        return { gameId: input.gameId, teamA: input.teamA, teamB: input.teamB };
    });
});
/** Phase 7 — organizer/admin posts the final score and notifies attendees. */
exports.postResult = (0, https_1.onCall)(async (request) => {
    const user = await (0, auth_1.requireUser)(request);
    const input = (0, errors_1.parseInput)(validation_1.postResultSchema, request.data);
    const db = (0, firestore_1.getFirestore)();
    const gameRef = db.collection("games").doc(input.gameId);
    const gameSnap = await gameRef.get();
    if (!gameSnap.exists)
        throw (0, errors_1.notFound)("Game not found");
    const game = gameSnap.data() ?? {};
    if (game.organizerId !== user.uid && user.role !== "admin") {
        throw (0, errors_1.permissionDenied)("Only the organizer or an admin can post a result");
    }
    if (game.status === "cancelled") {
        throw (0, errors_1.failedPrecondition)("Cancelled games cannot have results");
    }
    await db.collection("results").doc(input.gameId).set({
        scoreA: input.scoreA,
        scoreB: input.scoreB,
        postedBy: user.uid,
        postedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    await gameRef.update({ status: "completed" });
    const playerIds = Array.isArray(game.playerIds)
        ? game.playerIds
        : [];
    await (0, notifications_1.notifyUsers)(playerIds, {
        title: "Final score posted",
        body: `${game.title ?? "Your game"}: ${input.scoreA} – ${input.scoreB}.`,
        data: { type: "result", gameId: input.gameId },
    }, { notificationId: `result_${input.gameId}` });
    return { gameId: input.gameId, scoreA: input.scoreA, scoreB: input.scoreB };
});
//# sourceMappingURL=games.js.map