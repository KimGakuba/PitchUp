/**
 * Seeds the Firebase Emulator Suite with demo data for local development.
 * Run the emulators first (`npm run emulators` from the repo root), then in
 * another terminal: `npm run seed` from the repo root.
 *
 * This writes directly as an admin client, bypassing the Cloud Functions that
 * own booking/slot/game writes in production (createBooking, convertToGame,
 * joinGame, ...). Seed data is the only code path allowed to do that.
 */
import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

process.env.FIRESTORE_EMULATOR_HOST ??= "localhost:8080";
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= "localhost:9099";

const PROJECT_ID = "demo-pitchup";
const DEMO_PASSWORD = process.env.PITCHUP_DEMO_PASSWORD ?? "pitchup123";

initializeApp({ projectId: PROJECT_ID });

const db = getFirestore();
const auth = getAuth();

type Role = "player" | "owner" | "admin";
type Sport = "football" | "basketball";

interface SeedUser {
  uid: string;
  name: string;
  email: string;
  phone: string;
  role: Role;
  position?: string;
  reliabilityScore: number;
  gamesPlayed: number;
  noShows: number;
}

const USERS: SeedUser[] = [
  {
    uid: "user-kim",
    name: "Kim Gakuba",
    email: "kim@pitchup.rw",
    phone: "+250780000001",
    role: "player",
    position: "Midfielder",
    reliabilityScore: 92,
    gamesPlayed: 32,
    noShows: 1,
  },
  {
    uid: "user-alice",
    name: "Alice Umutoni",
    email: "alice@pitchup.rw",
    phone: "+250780000002",
    role: "player",
    position: "Forward",
    reliabilityScore: 98,
    gamesPlayed: 54,
    noShows: 0,
  },
  {
    uid: "user-jean-claude",
    name: "Jean Claude Mugisha",
    email: "owner@pitchup.rw",
    phone: "+250780000003",
    role: "owner",
    reliabilityScore: 100,
    gamesPlayed: 0,
    noShows: 0,
  },
  {
    uid: "user-admin",
    name: "System Administrator",
    email: "admin@pitchup.rw",
    phone: "+250780000004",
    role: "admin",
    reliabilityScore: 100,
    gamesPlayed: 0,
    noShows: 0,
  },
];

interface SeedVenue {
  id: string;
  ownerId: string;
  name: string;
  sport: Sport;
  format: string;
  surface: string;
  sector: string;
  address: string;
  pricePerHour: number;
  amenities: string[];
  rating: number;
  ratingCount: number;
}

const VENUES: SeedVenue[] = [
  {
    id: "venue-kigali-arena-football",
    ownerId: "user-jean-claude",
    name: "Kigali Arena Football Ground",
    sport: "football",
    format: "7-a-side",
    surface: "Artificial turf",
    sector: "Remera",
    address: "KG 7 Ave, Remera",
    pricePerHour: 20000,
    amenities: ["Floodlights", "Changing rooms", "Parking"],
    rating: 4.9,
    ratingCount: 128,
  },
  {
    id: "venue-kigali-arena-hoops",
    ownerId: "user-jean-claude",
    name: "Kigali Arena Outdoor Hoops",
    sport: "basketball",
    format: "full-court",
    surface: "FIBA full court",
    sector: "Remera",
    address: "KG 7 Ave, Remera",
    pricePerHour: 15000,
    amenities: ["Floodlights", "Scoreboard"],
    rating: 4.9,
    ratingCount: 94,
  },
  {
    id: "venue-remera-cage",
    ownerId: "user-jean-claude",
    name: "Remera Five-A-Side Cage",
    sport: "football",
    format: "5-a-side",
    surface: "Artificial turf",
    sector: "Remera",
    address: "Remera, Kigali",
    pricePerHour: 15000,
    amenities: ["Floodlights"],
    rating: 4.8,
    ratingCount: 76,
  },
  {
    id: "venue-club-rafiki",
    ownerId: "user-jean-claude",
    name: "Club Rafiki Basketball Court",
    sport: "basketball",
    format: "full-court",
    surface: "Concrete",
    sector: "Nyamirambo",
    address: "Nyamirambo, Kigali",
    pricePerHour: 12000,
    amenities: ["Seating"],
    rating: 4.8,
    ratingCount: 61,
  },
  {
    id: "venue-nyarutarama-sports",
    ownerId: "user-jean-claude",
    name: "Nyarutarama Sports Pitch and Hoops",
    sport: "football",
    format: "11-a-side",
    surface: "Natural grass",
    sector: "Nyarutarama",
    address: "Nyarutarama, Kigali",
    pricePerHour: 25000,
    amenities: ["Floodlights", "Parking", "Changing rooms"],
    rating: 4.7,
    ratingCount: 43,
  },
  {
    id: "venue-kicukiro-centre",
    ownerId: "user-jean-claude",
    name: "Kicukiro Football Centre",
    sport: "football",
    format: "7-a-side",
    surface: "Artificial turf",
    sector: "Kicukiro",
    address: "Kicukiro, Kigali",
    pricePerHour: 18000,
    amenities: ["Floodlights", "Parking"],
    rating: 4.6,
    ratingCount: 37,
  },
  {
    id: "venue-nyamirambo-community",
    ownerId: "user-jean-claude",
    name: "Nyamirambo Community Pitch",
    sport: "football",
    format: "5-a-side",
    surface: "Artificial turf",
    sector: "Nyamirambo",
    address: "Nyamirambo, Kigali",
    pricePerHour: 12000,
    amenities: ["Floodlights"],
    rating: 4.5,
    ratingCount: 29,
  },
];

interface SeedBooking {
  id: string;
  ref: string;
  venueId: string;
  userId: string;
  /** Days from today (negative = past). */
  daysFromNow: number;
  startTime: string;
  durationMin: 60 | 90 | 120;
  totalPrice: number;
  status: "upcoming" | "completed" | "cancelled";
  paymentStatus: "pending" | "success" | "failed";
}

const BOOKINGS: SeedBooking[] = [
  {
    id: "booking-sat-football",
    ref: "PU-0001-26",
    venueId: "venue-remera-cage",
    userId: "user-kim",
    daysFromNow: 2,
    startTime: "18:00",
    durationMin: 90,
    totalPrice: 20000,
    status: "upcoming",
    paymentStatus: "pending",
  },
  {
    id: "booking-sat-hoops",
    ref: "PU-0002-26",
    venueId: "venue-kigali-arena-hoops",
    userId: "user-alice",
    daysFromNow: 2,
    startTime: "20:00",
    durationMin: 90,
    totalPrice: 22500,
    status: "upcoming",
    paymentStatus: "pending",
  },
  {
    id: "booking-sun-clash",
    ref: "PU-0003-26",
    venueId: "venue-nyarutarama-sports",
    userId: "user-kim",
    daysFromNow: 3,
    startTime: "17:00",
    durationMin: 60,
    totalPrice: 25000,
    status: "upcoming",
    paymentStatus: "pending",
  },
  {
    id: "booking-kim-solo",
    ref: "PU-0004-26",
    venueId: "venue-kigali-arena-football",
    userId: "user-kim",
    daysFromNow: 4,
    startTime: "19:00",
    durationMin: 60,
    totalPrice: 20000,
    status: "upcoming",
    paymentStatus: "pending",
  },
  {
    id: "booking-kim-completed",
    ref: "PU-0005-26",
    venueId: "venue-remera-cage",
    userId: "user-kim",
    daysFromNow: -10,
    startTime: "18:00",
    durationMin: 90,
    totalPrice: 22500,
    status: "completed",
    paymentStatus: "success",
  },
  {
    id: "booking-kim-cancelled",
    ref: "PU-0006-26",
    venueId: "venue-club-rafiki",
    userId: "user-kim",
    daysFromNow: -3,
    startTime: "20:00",
    durationMin: 60,
    totalPrice: 12000,
    status: "cancelled",
    paymentStatus: "failed",
  },
];

interface SeedGame {
  id: string;
  bookingId: string;
  organizerId: string;
  title: string;
  sport: Sport;
  maxPlayers: number;
  costPerPlayer: number;
  playerIds: string[];
  status: "open" | "full" | "completed";
}

const GAMES: SeedGame[] = [
  {
    id: "game-sat-evening-football",
    bookingId: "booking-sat-football",
    organizerId: "user-kim",
    title: "Saturday Evening Football",
    sport: "football",
    maxPlayers: 10,
    costPerPlayer: 3334, // ceil(20000 / 6)
    playerIds: ["user-kim", "user-alice"],
    status: "open",
  },
  {
    id: "game-sat-night-hoops",
    bookingId: "booking-sat-hoops",
    organizerId: "user-alice",
    title: "Saturday Night 5v5 Hoops Showcase",
    sport: "basketball",
    maxPlayers: 10,
    costPerPlayer: 3750,
    playerIds: ["user-alice"],
    status: "open",
  },
  {
    id: "game-sun-sunset-clash",
    bookingId: "booking-sun-clash",
    organizerId: "user-kim",
    title: "Sunday Sunset 7-a-side Clash at Nyarutarama",
    sport: "football",
    maxPlayers: 14,
    costPerPlayer: 1786, // ceil(25000 / 14)
    playerIds: ["user-kim"],
    status: "open",
  },
  {
    id: "game-last-week-football",
    bookingId: "booking-kim-completed",
    organizerId: "user-kim",
    title: "Last Week's Remera 5-a-side",
    sport: "football",
    maxPlayers: 10,
    costPerPlayer: 2500,
    playerIds: ["user-kim", "user-alice"],
    status: "completed",
  },
];

function kigaliNow(): Date {
  return new Date(Date.now() + 2 * 60 * 60_000);
}

function dateFor(daysFromNow: number): Date {
  const d = kigaliNow();
  d.setUTCDate(d.getUTCDate() + daysFromNow);
  return d;
}

function dateString(date: Date): string {
  return date.toISOString().slice(0, 10);
}

/** 30-min slot IDs (`YYYYMMDD_HHmm`) covering [start, start + duration). */
function slotIdsFor(date: string, startTime: string, durationMin: number): string[] {
  const [h, m] = startTime.split(":").map(Number);
  const key = date.replaceAll("-", "");
  const ids: string[] = [];
  let minutes = h * 60 + m;
  const end = minutes + durationMin;
  while (minutes < end) {
    const hh = String(Math.floor(minutes / 60)).padStart(2, "0");
    const mm = String(minutes % 60).padStart(2, "0");
    ids.push(`${key}_${hh}${mm}`);
    minutes += 30;
  }
  return ids;
}

async function clearCollection(path: string): Promise<void> {
  await db.recursiveDelete(db.collection(path));
}

async function seedUsers(): Promise<void> {
  for (const user of USERS) {
    await auth
      .createUser({
        uid: user.uid,
        phoneNumber: user.phone,
        email: user.email,
        emailVerified: true,
        password: DEMO_PASSWORD,
        displayName: user.name,
      })
      .catch(async (err) => {
        if (err.code === "auth/uid-already-exists") {
          await auth.updateUser(user.uid, {
            displayName: user.name,
            email: user.email,
            emailVerified: true,
            password: DEMO_PASSWORD,
            phoneNumber: user.phone,
          });
        } else {
          throw err;
        }
      });

    await auth.setCustomUserClaims(user.uid, {
      role: user.role,
      status: "active",
      suspended: false,
    });

    await db.collection("users").doc(user.uid).set({
      name: user.name,
      email: user.email,
      phone: user.phone,
      role: user.role,
      position: user.position ?? null,
      reliabilityScore: user.reliabilityScore,
      gamesPlayed: user.gamesPlayed,
      noShows: user.noShows,
      status: "active",
      fcmTokens: [],
      createdAt: Timestamp.now(),
    });
  }
  console.log(`Seeded ${USERS.length} users (Auth + Firestore).`);
}

async function seedVenues(): Promise<void> {
  for (const venue of VENUES) {
    await db
      .collection("venues")
      .doc(venue.id)
      .set({
        ownerId: venue.ownerId,
        name: venue.name,
        sport: venue.sport,
        format: venue.format,
        surface: venue.surface,
        sector: venue.sector,
        address: venue.address,
        geo: { lat: -1.9441, lng: 30.0619 },
        pricePerHour: venue.pricePerHour,
        amenities: venue.amenities,
        photos: [],
        rating: venue.rating,
        ratingCount: venue.ratingCount,
        status: "active",
      });
  }
  console.log(`Seeded ${VENUES.length} venues.`);
}

async function seedBookings(): Promise<void> {
  for (const booking of BOOKINGS) {
    const date = dateString(dateFor(booking.daysFromNow));
    await db.collection("bookings").doc(booking.id).set({
      ref: booking.ref,
      venueId: booking.venueId,
      userId: booking.userId,
      date,
      startTime: booking.startTime,
      durationMin: booking.durationMin,
      totalPrice: booking.totalPrice,
      status: booking.status,
      paymentStatus: booking.paymentStatus,
      createdAt: Timestamp.now(),
    });

    if (booking.status === "upcoming") {
      const batch = db.batch();
      for (const slotId of slotIdsFor(
        date,
        booking.startTime,
        booking.durationMin,
      )) {
        batch.set(
          db
            .collection("venues")
            .doc(booking.venueId)
            .collection("slots")
            .doc(slotId),
          { status: "booked", bookingId: booking.id },
        );
      }
      await batch.commit();
    }
  }
  console.log(`Seeded ${BOOKINGS.length} bookings (+ upcoming slots).`);
}

async function seedGames(): Promise<void> {
  for (const game of GAMES) {
    await db.collection("games").doc(game.id).set({
      bookingId: game.bookingId,
      venueId: BOOKINGS.find((b) => b.id === game.bookingId)?.venueId,
      organizerId: game.organizerId,
      title: game.title,
      sport: game.sport,
      maxPlayers: game.maxPlayers,
      costPerPlayer: game.costPerPlayer,
      playerIds: game.playerIds,
      teamA: game.status === "completed" ? game.playerIds.slice(0, 1) : [],
      teamB: game.status === "completed" ? game.playerIds.slice(1) : [],
      status: game.status,
      createdAt: Timestamp.now(),
    });

    const playersBatch = db.batch();
    for (const uid of game.playerIds) {
      playersBatch.set(
        db.collection("games").doc(game.id).collection("players").doc(uid),
        {
          joinedAt: Timestamp.now(),
          paymentStatus: game.status === "completed" ? "paid" : "pending",
          attendance: game.status === "completed" ? "present" : null,
        },
      );
    }
    await playersBatch.commit();
  }

  await db.collection("results").doc("game-last-week-football").set({
    scoreA: 3,
    scoreB: 2,
    postedBy: "user-kim",
    postedAt: Timestamp.now(),
  });
  console.log(`Seeded ${GAMES.length} games (+ rosters, result).`);
}

async function seedReviews(): Promise<void> {
  const reviews = [
    {
      id: "review-1",
      venueId: "venue-kigali-arena-football",
      userId: "user-kim",
      userName: "Kim Gakuba",
      rating: 5,
      text: "Best turf in Kigali. Lights are bright and the pitch drains well after rain.",
      verified: true,
      daysAgo: 6,
    },
    {
      id: "review-2",
      venueId: "venue-kigali-arena-hoops",
      userId: "user-alice",
      userName: "Alice Umutoni",
      rating: 5,
      text: "Great outdoor court, good rims and a scoreboard that actually works.",
      verified: false,
      daysAgo: 12,
    },
    {
      id: "review-3",
      venueId: "venue-remera-cage",
      userId: "user-kim",
      userName: "Kim Gakuba",
      rating: 4,
      text: "Cage is tight and fun for 5-a-side. Bring water, shade is limited.",
      verified: true,
      daysAgo: 20,
    },
    {
      id: "review-4",
      venueId: "venue-club-rafiki",
      userId: "user-alice",
      userName: "Alice Umutoni",
      rating: 4,
      text: "Solid concrete court in Nyamirambo. Friendly crowd every evening.",
      verified: false,
      daysAgo: 30,
    },
  ];

  for (const review of reviews) {
    await db.collection("reviews").doc(review.id).set({
      venueId: review.venueId,
      userId: review.userId,
      userName: review.userName,
      rating: review.rating,
      text: review.text,
      verified: review.verified,
      createdAt: Timestamp.fromMillis(
        Date.now() - review.daysAgo * 24 * 60 * 60 * 1000,
      ),
    });
  }
  console.log(`Seeded ${reviews.length} reviews.`);
}

async function seedPaymentsAndReports(): Promise<void> {
  await db.collection("payments").doc("payment-completed-booking").set({
    gameId: null,
    bookingId: "booking-kim-completed",
    userId: "user-kim",
    amount: 22500,
    provider: "mtn",
    phone: "+250780000001",
    status: "success",
    providerRef: "MOMO-SEED0001",
    createdAt: Timestamp.fromMillis(Date.now() - 10 * 24 * 60 * 60 * 1000),
  });

  await db.collection("payments").doc("payment-pending-game").set({
    gameId: "game-sat-evening-football",
    bookingId: null,
    userId: "user-kim",
    amount: 3334,
    provider: "airtel",
    phone: "+250780000001",
    status: "pending",
    providerRef: "AIRTEL-SEED0002",
    createdAt: Timestamp.now(),
  });

  await db.collection("reports").doc("report-1").set({
    reporterId: "user-alice",
    targetId: "user-jean-claude",
    reason: "Venue was double-booked and the owner did not respond.",
    status: "open",
    createdAt: Timestamp.now(),
  });

  await db.collection("notifications").doc("notification-welcome-kim").set({
    userId: "user-kim",
    title: "Welcome to PitchUp",
    body: "Book the pitch. Find your team. Play together.",
    read: false,
    createdAt: Timestamp.now(),
    data: { type: "welcome" },
  });
  console.log("Seeded payments, a report and a notification.");
}

async function seedCounters(): Promise<void> {
  await db.collection("counters").doc("bookings").set({
    seq: BOOKINGS.length,
  });
  console.log(`Booking counter starts at ${BOOKINGS.length}.`);
}

async function main(): Promise<void> {
  console.log(`Seeding project "${PROJECT_ID}" via emulators...`);
  const collections = [
    "users",
    "venues",
    "bookings",
    "games",
    "payments",
    "reviews",
    "results",
    "notifications",
    "reports",
    "counters",
    "reminders",
  ];
  for (const collection of collections) {
    await clearCollection(collection);
  }
  await seedUsers();
  await seedVenues();
  await seedBookings();
  await seedGames();
  await seedReviews();
  await seedPaymentsAndReports();
  await seedCounters();
  console.log("Done.");
  console.log(
    `Demo sign-in: kim@pitchup.rw / ${DEMO_PASSWORD} (player), owner@pitchup.rw (owner), admin@pitchup.rw (admin).`,
  );
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
