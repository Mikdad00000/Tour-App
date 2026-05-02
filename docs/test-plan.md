# Manual Verification Plan

## Pre-flight
- 3+ Android phones (BLE step needs **physical** devices — emulator BLE is unreliable)
- Firebase project with Auth (Phone), Firestore, FCM, Storage enabled
- Run `flutterfire configure` once and check in `lib/core/config/firebase_options.dart`
- Deploy: `firebase deploy --only firestore,functions`

## E2E walkthrough

1. **Onboarding** — install on Phone-1, sign in (Phone OTP), create trip "Cox", invite Phone-2 and Phone-3.
2. **Deposits** — each phone adds a deposit; admin (Phone-1) confirms each. Pool total updates everywhere.
3. **`shared` expense** — admin adds ৳1200 dinner, all 3. All phones get FCM "৳1200 খরচ — আপনার ভাগ ৳400".
4. **`partial` expense** — admin adds ৳500 ice cream, participants = {Phone-1, Phone-2}. Phone-2 gets "expense" notification; Phone-3 gets "info" notification ("ওরা আইসক্রিম খাচ্ছে").
5. **`individual` expense** — Phone-2 adds ৳200 personal souvenir. No one else is notified. Phone-2's personal budget drops ৳200.
6. **`peer_loan`** — Phone-3 opens "ধার দিলাম", picks Phone-2 as borrower, ৳300, note "টি-শার্ট কিনে দিল". Phone-2 receives "আপনি Phone-3-কে ৳300 দিবেন". Settle-up shows new transfer.
7. **`peer_loan` repaid** — Phone-3 taps "Repaid" on the loan card. Both phones get a "ধার শোধ ৳300" notification. Settle-up no longer shows the transfer.
8. **Offline test** — Airplane mode on Phone-1; admin adds an expense; turn airplane mode off after 30s. Within ~10s the expense appears on Phone-2/3 with FCM.
9. **BLE test** — Phone-1 and Phone-2 in airplane mode side-by-side, Phone-1 admin adds expense → Phone-2 should see a local notification within 30s (manufacturer-data scan). Then re-enable network — both phones' Firestore copies converge to the same record (server `updatedAt` wins).
10. **Settle-up cross-check** — at the end, run `flutter test` to verify the calculator with deterministic inputs; match against your manual sheet.

## What "pass" looks like

- Notifications arrive on the *right* set of phones for each expense type.
- Per-head amounts are correct down to the BDT (no fractional drift).
- Offline → online merge produces a single record (no duplicates).
- Settle-up's transfer list pays everyone off in ≤ N-1 transactions.
