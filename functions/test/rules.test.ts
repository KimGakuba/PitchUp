import { readFileSync } from "node:fs";
import path from "node:path";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  addDoc,
  collection,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
} from "firebase/firestore";
import { afterAll, beforeAll, beforeEach, describe, it } from "vitest";

let testEnv: RulesTestEnvironment;

const projectId = "demo-pitchup";

const profile = {
  name: "Kim Gakuba",
  phone: "+250780000001",
  role: "player",
  position: "Midfielder",
  reliabilityScore: 100,
  gamesPlayed: 0,
  noShows: 0,
  status: "active",
  fcmTokens: [],
};

const venue = {
  ownerId: "user-jean-claude",
  name: "Kigali Arena Football Ground",
  sport: "football",
  format: "7-a-side",
  surface: "Artificial turf",
  sector: "Remera",
  address: "KG 7 Ave, Remera",
  geo: { lat: -1.94, lng: 30.06 },
  pricePerHour: 20000,
  amenities: ["Floodlights"],
  photos: [],
  rating: 4.9,
  ratingCount: 128,
  status: "active",
};

const tokens = {
  player: { role: "player", status: "active", suspended: false },
  owner: { role: "owner", status: "active", suspended: false },
  admin: { role: "admin", status: "active", suspended: false },
};

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: readFileSync(
        path.resolve(process.cwd(), "../firebase/firestore.rules"),
        "utf8",
      ),
      host: process.env.FIRESTORE_EMULATOR_HOST?.split(":")[0] ?? "127.0.0.1",
      port: Number(
        process.env.FIRESTORE_EMULATOR_HOST?.split(":")[1] ?? 8080,
      ),
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, "users", "user-kim"), profile);
    await setDoc(doc(db, "users", "user-jean-claude"), {
      ...profile,
      name: "Jean Claude Mugisha",
      role: "owner",
      phone: "+250780000003",
    });
    await setDoc(doc(db, "users", "user-admin"), {
      ...profile,
      name: "System Administrator",
      role: "admin",
      phone: "+250780000004",
    });
    await setDoc(doc(db, "venues", "venue-1"), venue);
    await setDoc(doc(db, "bookings", "booking-1"), {
      ref: "PU-0001-26",
      venueId: "venue-1",
      userId: "user-kim",
      date: "2026-12-01",
      startTime: "18:00",
      durationMin: 90,
      totalPrice: 30000,
      status: "upcoming",
      paymentStatus: "pending",
    });
    await setDoc(doc(db, "payments", "payment-1"), {
      gameId: null,
      bookingId: "booking-1",
      userId: "user-kim",
      amount: 30000,
      provider: "mtn",
      phone: "+250780000001",
      status: "pending",
    });
    await setDoc(doc(db, "reports", "report-1"), {
      reporterId: "user-kim",
      targetId: "user-jean-claude",
      reason: "No-show abuse",
      status: "open",
    });
  });
});

describe("users", () => {
  it("rejects unauthenticated profile creation", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(setDoc(doc(db, "users", "user-x"), profile));
  });

  it("lets a player create their own profile as a player", async () => {
    const db = testEnv
      .authenticatedContext("user-kim", tokens.player)
      .firestore();
    await assertSucceeds(setDoc(doc(db, "users", "user-kim"), profile));
  });

  it("blocks self-assigned admin roles", async () => {
    const db = testEnv
      .authenticatedContext("user-kim", tokens.player)
      .firestore();
    await assertFails(
      setDoc(doc(db, "users", "user-kim"), { ...profile, role: "admin" }),
    );
  });

  it("blocks edits to server-managed reliability fields", async () => {
    const db = testEnv
      .authenticatedContext("user-kim", tokens.player)
      .firestore();
    await assertFails(
      updateDoc(doc(db, "users", "user-kim"), { reliabilityScore: 50 }),
    );
    await assertSucceeds(
      updateDoc(doc(db, "users", "user-kim"), { position: "Forward" }),
    );
  });

  it("blocks writing another user's profile", async () => {
    const db = testEnv
      .authenticatedContext("user-kim", tokens.player)
      .firestore();
    await assertFails(
      updateDoc(doc(db, "users", "user-jean-claude"), { name: "Hacker" }),
    );
  });
});

describe("venues", () => {
  it("allows public venue reads", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertSucceeds(getDoc(doc(db, "venues", "venue-1")));
  });

  it("lets an owner create their own venue", async () => {
    const db = testEnv
      .authenticatedContext("user-jean-claude", tokens.owner)
      .firestore();
    await assertSucceeds(
      setDoc(doc(db, "venues", "venue-2"), {
        ...venue,
        rating: 0,
        ratingCount: 0,
      }),
    );
  });

  it("blocks players from creating venues", async () => {
    const db = testEnv
      .authenticatedContext("user-kim", tokens.player)
      .firestore();
    await assertFails(setDoc(doc(db, "venues", "venue-2"), venue));
  });

  it("blocks owners from faking another owner", async () => {
    const db = testEnv
      .authenticatedContext("user-jean-claude", tokens.owner)
      .firestore();
    await assertFails(
      setDoc(doc(db, "venues", "venue-2"), {
        ...venue,
        ownerId: "user-kim",
        rating: 0,
        ratingCount: 0,
      }),
    );
  });

  it("blocks owners from editing the aggregated rating", async () => {
    const db = testEnv
      .authenticatedContext("user-jean-claude", tokens.owner)
      .firestore();
    await assertFails(
      updateDoc(doc(db, "venues", "venue-1"), { rating: 5 }),
    );
    await assertSucceeds(
      updateDoc(doc(db, "venues", "venue-1"), { pricePerHour: 22000 }),
    );
  });
});

describe("server-owned collections", () => {
  it("blocks client writes to slots", async () => {
    const db = testEnv
      .authenticatedContext("user-jean-claude", tokens.owner)
      .firestore();
    await assertFails(
      setDoc(doc(db, "venues", "venue-1", "slots", "20261201_1800"), {
        status: "booked",
        bookingId: "booking-1",
      }),
    );
  });

  it("blocks client writes to bookings", async () => {
    const db = testEnv
      .authenticatedContext("user-kim", tokens.player)
      .firestore();
    await assertFails(
      updateDoc(doc(db, "bookings", "booking-1"), { status: "cancelled" }),
    );
  });

  it("lets a booking owner read their booking, but not someone else's", async () => {
    const kim = testEnv
      .authenticatedContext("user-kim", tokens.player)
      .firestore();
    await assertSucceeds(getDoc(doc(kim, "bookings", "booking-1")));

    const alice = testEnv
      .authenticatedContext("user-alice", tokens.player)
      .firestore();
    await assertFails(getDoc(doc(alice, "bookings", "booking-1")));
  });

  it("blocks client writes to payments", async () => {
    const db = testEnv
      .authenticatedContext("user-kim", tokens.player)
      .firestore();
    await assertFails(
      updateDoc(doc(db, "payments", "payment-1"), { status: "success" }),
    );
  });

  it("allows admins to read moderation reports", async () => {
    const db = testEnv
      .authenticatedContext("user-admin", tokens.admin)
      .firestore();
    await assertSucceeds(getDoc(doc(db, "reports", "report-1")));
  });

  it("blocks players from reading reports", async () => {
    const db = testEnv
      .authenticatedContext("user-kim", tokens.player)
      .firestore();
    await assertFails(getDoc(doc(db, "reports", "report-1")));
  });
});

describe("reviews", () => {
  it("allows a player review with verified=false", async () => {
    const db = testEnv
      .authenticatedContext("user-kim", tokens.player)
      .firestore();
    await assertSucceeds(
      addDoc(collection(db, "reviews"), {
        venueId: "venue-1",
        userId: "user-kim",
        userName: "Kim Gakuba",
        rating: 5,
        text: "Great turf and lights.",
        verified: false,
        createdAt: serverTimestamp(),
      }),
    );
  });

  it("blocks self-verified reviews and spoofed names", async () => {
    const db = testEnv
      .authenticatedContext("user-kim", tokens.player)
      .firestore();
    await assertFails(
      addDoc(collection(db, "reviews"), {
        venueId: "venue-1",
        userId: "user-kim",
        userName: "Kim Gakuba",
        rating: 5,
        text: "Verified by me",
        verified: true,
        createdAt: serverTimestamp(),
      }),
    );
    await assertFails(
      addDoc(collection(db, "reviews"), {
        venueId: "venue-1",
        userId: "user-kim",
        userName: "Someone Else",
        rating: 5,
        text: "Spoofed name",
        verified: false,
        createdAt: serverTimestamp(),
      }),
    );
  });
});
