# Morpheus

A Flutter finance companion with budgets, expenses, cards, accounts, and secure cloud sync.

## Features
- **Expenses & Budgets**: Add/edit/delete expenses, set period budgets, plan future spend, and view monthly/yearly totals with category mix and 6‑month burn charts.
- **Forex awareness**: EUR is the default currency; automatic rate fetch via Frankfurter API with EUR→INR badge and budget conversions.
- **Export**: CSV export for expenses plus budget summary/future expenses (saves to Downloads on Android or Documents elsewhere).
- **Cards & Accounts**: Manage cards and bank accounts with Firestore + SQLite cache, edit/delete actions, and optional card color customization with icon lookup from bundled bank data.
- **Security**: Data is encrypted end‑to‑end using `EncryptionService` before sending to Firestore; app theme uses Material 3 with a reusable theme system.
- **Auth**: Google Sign‑In with silent session restore, manual login, logout from the dashboard, and Firebase Auth integration.
- **UI polish**: Bottom navigation with Expenses as the default tab, overflow‑safe layouts, and refreshed add/edit dialogs.

## Requirements
- Flutter 3.8+ and Dart 3.8+
- Firebase project with Google Sign‑In enabled; update `google-services.json`/`GoogleService-Info.plist` accordingly.
- Android/iOS tooling (Android Studio/Xcode) and a configured emulator/device.

## Getting Started
1. Install dependencies:  
   ```bash
   flutter pub get
   ```
2. Configure Firebase: add platform configs, then run:  
   ```bash
   flutterfire configure
   ```
3. Run the app:  
   ```bash
   flutter run
   ```

## Notes
- **Permissions**: Exports request storage access on Android; files land in `Download/morpheus_exports/…` (or Documents on other platforms).
- **Encryption**: Cards/accounts are encrypted before Firestore writes; decryption happens on fetch. Existing unencrypted docs should be re‑saved to apply encryption.
- **Bank icons**: The bundled `banks.sqlite` supplies bank icons; these are stored with cards and shown beside bank names.
- **Customization**: Card color picker supports presets and custom hues; theming lives under `lib/theme/`.

## Scripts
- Format code: `dart format lib`
- Run app: `flutter run`

## License
MIT (see project license if present).
