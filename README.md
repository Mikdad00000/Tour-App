# Tour Expense Manager

Flutter (Android) app to manage group tour finances with hybrid FCM + BLE notifications and offline-first sync.

## Concept

One **admin** (treasurer) manages the group's pooled cash. Four kinds of transactions:

| Type | paidBy | from pool? | participants | notifies |
|---|---|---|---|---|
| `shared` | admin | yes | all | all |
| `partial` | admin | yes | subset | participants → expense; others → info-only |
| `individual` | self | no | self | nobody |
| `peer_loan` | any member A | no | borrowers | borrowers (`accept/dispute`) |

Plus **deposit**: member → admin.

Settle-up runs a min-transactions algorithm over the admin pool **and** all unsettled peer loans.

## Stack

- Flutter 3.x + Riverpod
- Firebase (Auth/Firestore/FCM/Storage/Functions)
- drift (SQLite) — offline-first mirror; UI reads local
- flutter_blue_plus — BLE peer-to-peer fallback when offline
- workmanager — background sync

## Layout

```
lib/
  core/        config, db, sync, connectivity, notification, location, pdf
  features/    auth, trip, deposit, expense, budget, settle, activity, reports
  shared/      widgets, theme
functions/     Firebase Cloud Functions (TypeScript)
android/       Android shell + manifest
test/          unit tests (settlement calculator)
```

## Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutterfire configure   # writes lib/core/config/firebase_options.dart
cd functions && npm install && npm run build
firebase deploy --only functions,firestore
flutter run
```

## Verification

- `flutter test` — settlement calculator unit tests
- Manual multi-device — see `docs/test-plan.md` (3 phones, 4 expense types, offline + BLE)
