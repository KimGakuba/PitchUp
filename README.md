# PITCHUP

Book the pitch. Find your team. Play together.

A pitch-booking and pickup-game app for Kigali, Rwanda — football (5/7/11-a-side
turf) and basketball (full court, 3x3). All money amounts are integer RWF.

## Stack

- **App**: Flutter (Dart), mobile-first (Android, iOS). State via `provider`
  (`ChangeNotifier`). Firebase Auth, Firestore, Storage, Cloud Messaging, and
  callable Functions are wired directly through the FlutterFire plugins.
- **Backend**: Firebase — Auth, Firestore, Cloud Functions (TypeScript, 2nd
  gen), Storage, Cloud Messaging, Security Rules, Emulator Suite.
- **Region**: `europe-west1`.

## Project structure

```
app/         Flutter app (lib/, android/, ios/, test/)
functions/   Cloud Functions (TypeScript, 2nd gen)
firebase/    firebase.json, firestore.rules, firestore.indexes.json, storage.rules, .firebaserc
scripts/     seed.ts — populates the Emulator Suite with demo data
```

## Prerequisites

- Flutter SDK 3.47+ with a configured Android and/or iOS toolchain
  (`flutter doctor`)
- Node.js 20+
- No global Firebase CLI install needed — it is a dev dependency invoked by the
  root npm scripts.

## Setup

From the repo root:

```bash
npm install
cd app && flutter pub get && cd ..
```

## Running the backend (Emulator Suite)

```bash
npm run emulators            # Auth, Firestore, Functions, Storage, Emulator UI at http://localhost:4000
# or, to persist data across restarts:
npm run emulators:import     # imports firebase/emulator-data on start, exports on exit
```

In a second terminal, seed demo data:

```bash
npm run seed
```

The seed is idempotent and recreates demo users, venues, claimed slots,
bookings, and pickup games. Demo sign-in:

| Role   | Email              | Password    |
| ------ | ------------------ | ----------- |
| Player | `kim@pitchup.rw`   | `pitchup123` |
| Player | `alice@pitchup.rw` | `pitchup123` |
| Owner  | `owner@pitchup.rw` | `pitchup123` |
| Admin  | `admin@pitchup.rw` | `pitchup123` |

Override the demo password with `PITCHUP_DEMO_PASSWORD` when seeding.

Roles come from Firebase Auth custom claims (`player`, `owner`, `admin`).
The Firestore `users.role` field is display/query state only.

## Running the app

```bash
cd app
flutter run
```

By default the app connects to the local Emulator Suite in debug builds.

- Android emulator host: `10.0.2.2`
- iOS simulator: `localhost`
- Physical device: pass your machine's LAN IP, e.g.
  `flutter run --dart-define=FIREBASE_EMULATOR_HOST=192.168.1.20`
- To use deployed Firebase instead of the emulators, pass
  `--dart-define=USE_FIREBASE_EMULATOR=false`

### Testing on a physical phone (emulators)

The phone and this machine must be on the same Wi-Fi network.

```bash
npm run emulators                       # terminal 1 (repo root)
npm run seed                            # terminal 2 (repo root)
cd app && flutter run \
  --dart-define=FIREBASE_EMULATOR_HOST=<this-machine-LAN-IP>   # terminal 3
```

Debug builds already allow cleartext HTTP to the emulators on both platforms:
Android via `android/app/src/debug/res/xml/network_security_config.xml`, iOS
via the `NSAllowsLocalNetworking` entry in `ios/Runner/Info.plist`. If the
phone cannot connect, open firewall ports 8080, 9099, 9199 and 5001, and avoid
guest/AP-isolated Wi-Fi.

### Tests & analysis

```bash
cd app
flutter analyze
flutter test
```

Or from the repo root: `npm run app:analyze` / `npm run app:test`
(and `npm run app:run` to launch the app).

Backend:

```bash
npm run build -w functions
npm test -w functions

# Security rules tests need the Firestore emulator running:
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 npm run test:rules -w functions
```

## Payments

Payments use a `PaymentProvider` adapter. The local/demo build uses
`MockProvider`; `simulatePaymentOutcome` settles a payment from the app's
debug UI. The production webhook is `paymentWebhook`, verified with the
`x-pitchup-signature` HMAC header and `PAYMENT_WEBHOOK_SECRET`. Disable the mock
callable in deployed environments with `PAYMENTS_MOCK_ENABLED=false`.

## Environment variables / secrets

- The Flutter app reads public Firebase client config from
  `app/lib/firebase_options.dart`.
- Payment aggregator API keys and `PAYMENT_WEBHOOK_SECRET` live in Secret
  Manager / Cloud Functions environment configuration, never in the app bundle.
- Optional local overrides: `FIREBASE_EMULATOR_HOST`, `USE_FIREBASE_EMULATOR`,
  `PITCHUP_DEMO_PASSWORD`.

## Deploying

```bash
cd firebase
npx firebase deploy --only firestore:rules,storage:rules,functions
```

Build mobile binaries with `flutter build apk` or `flutter build ipa` from
`app/`. The Flutter web target is not configured in this project.

## Implemented features

1. Project scaffold, design system, navigation shell, and Emulator seed.
2. Phone/password auth, user profiles, custom-claim roles, session handling.
3. Venue explore/details, owner create/edit, photo upload, amenities.
4. Slot-based booking transaction, availability UI, receipt, cancellation.
5. Pickup games: conversion, join/leave, roster, teams, cost sharing.
6. Payment adapter, mock MoMo/Airtel flow, idempotent webhook settlement.
7. Attendance, reliability score, results, reviews.
8. Admin tools (roles, suspension, reports), push notifications, scheduled jobs.
9. Hardened Firestore/Storage rules, indexes, and automated tests.
