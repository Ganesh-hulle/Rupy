# AI Agent Guide (Morpheus)

This document helps new AI agents quickly understand the project, its architecture, and the workflows used to develop, test, and deploy it. Read this before making changes.

## Goal
Build an industry-standard finance app with modular, maintainable code and a clean, well-organized directory structure.

## Project Overview
Morpheus is a Flutter finance companion with:
- Expenses, budgets, accounts, and card management.
- Firestore + Firebase Auth cloud sync.
- Local SQLite cache for cards and bank data.
- Encrypted storage for sensitive fields (cards/accounts) before upload.
- App lock using device authentication.
- Push notifications for card reminders using Cloud Tasks + FCM.
- Monthly snapshots for per-card utilization summaries.

## Tech Stack
- Flutter (Dart), Material 3 UI.
- Firebase: Auth, Firestore, Messaging, Cloud Functions Gen 2.
- Local storage: SQLite via `sqflite`.
- Notifications: `flutter_local_notifications`, FCM.
- Cloud Tasks for scheduled pushes.

## High-Level Architecture
- UI: Flutter screens under `lib/`.
- State management: `bloc` and `flutter_bloc`.
- Repositories:
  - `lib/cards/card_repository.dart` (cards; local + Firestore)
  - `lib/expenses/repositories/expense_repository.dart`
  - `lib/accounts/accounts_repository.dart`
- Services:
  - `lib/services/notification_service.dart` (FCM + local notifications + test push)
  - `lib/services/app_lock_service.dart` (local_auth)
  - `lib/services/encryption_service.dart` (AES encryption)

## Key Features and Where They Live
- Cards UI: `lib/creditcard_management_page.dart`
- Add/Edit Card dialog: `lib/add_card_dialog.dart`
- Settings: `lib/settings/settings_page.dart`, `lib/settings/settings_cubit.dart`
- App lock gate: `lib/lock/app_lock_gate.dart`
- Expenses dashboard: `lib/expenses/view/expense_dashboard_page.dart`
- Notification pipeline: `lib/services/notification_service.dart`
- Cloud functions: `functions/index.js`

## Data Model (Firestore)
User-scoped documents:
- `users/{uid}/cards/{cardId}`
  - encrypted fields: bankName, holderName, cardNumber, expiryDate, cvv
  - reminders: `reminderEnabled`, `reminderOffsets`, `billingDay`, `graceDays`
- `users/{uid}/accounts/{accountId}` (encrypted fields)
- `users/{uid}/expenses/{expenseId}`
- `users/{uid}/deviceTokens/{token}`
- `users/{uid}`: `timezone`, `timezoneUpdatedAt`
- `users/{uid}/reminderLogs/{cardId_offset_dueDate}`
- `users/{uid}/cardReminderTasks/{cardId}`
- `users/{uid}/cardSnapshots/{YYYY-MM}`

## Local Storage (SQLite)
- Cards are cached locally for offline usage.
- Bank icons come from a bundled SQLite file in `assets/tables/`.

## Encryption
Sensitive fields are encrypted on-device before writing to Firestore.
Update the key/IV in:
- `lib/services/encryption_service.dart`

Cloud Functions need the same values:
- `CARD_ENCRYPTION_KEY`
- `CARD_ENCRYPTION_IV`

Keep secrets out of the repo.

## Notifications and Reminders
Local notifications:
- `NotificationService.showInstantNotification`

Push notifications:
- Cloud Tasks + FCM (server-side send)
- Test push button in card UI calls `sendTestPush` callable function.

## Cloud Functions (Gen 2) Overview
Functions (region `europe-west1`):
- `sendCardReminders`: daily reconcile for missing tasks.
- `syncCardReminders`: Firestore onWrite trigger for cards.
- `syncUserTimezone`: Firestore onWrite trigger for user timezone changes.
- `sendCardReminderTask`: HTTP handler invoked by Cloud Tasks.
- `sendTestPush`: Callable function for UI test button.
- `computeMonthlyCardSnapshots`: monthly server-side summary.

Cloud Tasks queue:
- `card-reminders` in `europe-west1`.

Security:
- `TASKS_WEBHOOK_SECRET` protects the Cloud Tasks endpoint via header.
- If not set, the task endpoint is public (anyone can call it).

## Timezone Handling
- The app resolves the device timezone and persists it to `users/{uid}`.
- Functions use `timezone` to schedule reminders correctly for each user.

## Build and Run (App)
Common commands:
- `flutter pub get`
- `flutter run`
- `dart format lib`

Android notes:
- `MainActivity` uses `FlutterFragmentActivity` for biometric auth.
- Android Gradle plugin is set in `android/settings.gradle.kts`.

## Build and Deploy (Functions)
From `functions/`:
- `npm install`
- `firebase deploy --only functions`

If Cloud Tasks queue is missing:
- `gcloud tasks queues create card-reminders --location=europe-west1`

## Required Firebase APIs
- Cloud Functions, Cloud Run, Eventarc, Cloud Tasks, Cloud Scheduler, Pub/Sub

## Dependencies and Version Constraints
Key packages:
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging`
- `flutter_local_notifications`, `timezone`, `flutter_timezone`
- `local_auth` (requires `FlutterFragmentActivity` on Android)
- `cloud_functions` (for callable test push)

Functions:
- `firebase-functions` v7 (Gen 2)
- `firebase-admin`
- `@google-cloud/tasks`
- `luxon`

## Testing and QA
There are no automated tests in this repo by default.
Manual validation checklist:
- App lock toggle and biometric prompt behavior.
- Card add/edit, reminder offsets, and network logo rendering.
- Test notification (local) and test push (server) from UI.
- Reminder scheduling in Firestore and Cloud Tasks queue.
- Monthly snapshot writes in Firestore (runs on 1st each month).

## Common Pitfalls
- Missing `FlutterFragmentActivity` causes biometric auth to fail.
- Missing Google Services files will break Android/iOS builds.
- Missing Eventarc permissions can block Gen 2 Firestore triggers.
- Region mismatch: callable functions must be called with `region: europe-west1`.
- Encryption key/IV mismatch: server cannot decrypt card data.

## Conventions
- Keep edits ASCII unless a file already contains Unicode.
- Prefer `rg` for searching.
- Use `apply_patch` for small single-file edits.
- Avoid removing unrelated changes.

## How to Extend
To add a new reminder type:
- Add fields to card schema.
- Update scheduling logic in `functions/index.js`.
- Update UI and storage models.

To add a new dashboard summary:
- Decide whether it should be client-computed or server-computed.
- For server summaries, add a scheduled Gen 2 function and write into `users/{uid}/...`.

## Contact Points in Code
If you are unsure where to change something, start with:
- Cards: `lib/creditcard_management_page.dart`
- Notifications: `lib/services/notification_service.dart`
- Functions: `functions/index.js`
- Settings: `lib/settings/settings_page.dart`
