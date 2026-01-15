# AI Agent Guide (Rupy)
This guide helps AI coding agents understand the project, architecture, and workflows. Read before making changes.

# Rupy Project Architecture & Guide

This document serves as a comprehensive guide to the Rupy project architecture. It is designed to be used as a template for creating similar high-quality, production-ready Flutter applications.

## 🚀 Technical Stack

| Category | Technology | Package(s) |
|----------|------------|------------|
| **Framework** | Flutter | `flutter` |
| **Language** | Dart | `dart` |
| **State Management** | BLoC / Cubit | `flutter_bloc`, `bloc`, `equatable` |
| **Backend / BaaS** | Firebase | `firebase_core`, `firebase_auth`, `cloud_firestore`, `cloud_functions`, `firebase_messaging` |
| **Local Storage** | Key-Value & SQL | `shared_preferences`, `sqflite`, `flutter_secure_storage` |
| **Immutable Data** | Code Generation | `freezed`, `json_serializable` |
| **Monitoring** | Error Logging | `sentry_flutter`, `firebase_crashlytics` |
| **Security** | Auth & Encryption | `local_auth`, `encrypt`, `crypto` |
| **UI Components** | Charts & SVGs | `fl_chart`, `flutter_svg`, `google_fonts` |

---

## 📂 Project Structure

The project follows a **Feature-First** architecture mixed with Clean Architecture principles.

```
lib/
├── auth/                  # Authentication feature (Login, Bloc, Repositories)
├── accounts/              # Accounts management feature
├── expenses/              # Core feature: Expense tracking
│   ├── bloc/              # State management (Events, States, BLoC)
│   ├── models/            # Data models (immutable, json_serializable)
│   ├── repositories/      # Data access layer (Firestore interactions)
│   └── view/              # UI Screens and Widgets
├── settings/              # App settings (Theme, Security configs)
├── services/              # Global application services (Wrappers)
│   ├── auth_service.dart
│   ├── notification_service.dart
│   └── ...
├── data/                  # Shared data layer
│   └── database/          # Local SQL database (Sqflite)
├── theme/                 # App styling and themes
├── utils/                 # Extensions and helper functions
├── widgets/               # Shared UI components
├── main.dart              # Entry point & Initializations
└── firebase_options.dart  # Firebase configuration (Generated)
```

---

## 🏗 Core Architectures

### 1. State Management (BLoC Pattern)
We use `flutter_bloc` to separate business logic from UI.
-   **Events**: Triggers driven by user interaction (e.g., `LoadExpenses`, `AddExpense`).
-   **States**: Immutable snapshots of the UI (e.g., `ExpensesLoading`, `ExpensesLoaded`).
-   **Bloc/Cubit**: Handles events and emits new states.
-   **Dependency Injection**: `RepositoryProvider` and `MultiBlocProvider` are used in `main.dart` to inject dependencies down the widget tree.

### 2. Data Persistence Layer
The app uses a hybrid approach for data storage:
-   **Cloud Firestore**: Primary storage for user content (Expenses, Budgets, Recurring Transactions). Data is structured under `users/{uid}/collection_name`.
-   **Shared Preferences**: Stores local user preferences (Theme mode, Dashboard layout, App Lock status).
-   **Sqflite**: Used for caching or storing static reference data (e.g., Bank lists) found in `lib/data/database/`.
-   **Secure Storage**: Used for sensitive keys and tokens via `EncryptionService`.

### 3. Authentication Flow
-   **Service**: `AuthService` handles Google Sign-In and Firebase Auth interactions.
-   **Bloc**: `AuthBloc` manages the authentication state (`Authenticated`, `Unauthenticated`).
-   **Gatekeeper**: `AuthGate` in `main.dart` listens to `AuthBloc` and switches the root widget between `SplashPage`, `SignUpPage`, and `AppNavShell`.
-   **Biometrics**: `AppLockGate` wraps the content to require FaceID/TouchID if enabled in settings.

### 4. Security
-   **Encryption**: `EncryptionService` provides AES encryption for sensitive local data.
-   **Local Auth**: `local_auth` package is used to gate access to the app for verified users.

### 5. Monitoring & Stability
-   **Sentry**: Captures application errors and performance traces.
-   **Crashlytics**: Firebase Crashlytics provides redundant crash reporting.
-   **ErrorReporter**: A service wrapper (`lib/services/error_reporter.dart`) abstracts the logging logic, allowing multiple reporters to be initialized.

---

## 🛠 Usage as a Template

To use this project as a template for a new application:

### Step 1: Initialization
1.  Copy the project structure.
2.  Run `flutter create .` to regenerate platform folders if needed.
3.  Update `pubspec.yaml` `name` and `description`.

### Step 2: Firebase Setup
1.  Create a new project in Firebase Console.
2.  Run `flutterfire configure` to generate the new `firebase_options.dart`.
3.  Enable **Authentication** (Google, Email) and **Firestore** in the console.

### Step 3: Architecture Implementation
When adding a new feature (e.g., "Goals"):
1.  Create a folder `lib/goals/`.
2.  Define **Models** (`goal.dart`) using `freezed` or `json_serializable`.
3.  Create **Repository** (`goal_repository.dart`) responsible for fetching/saving Goals to Firestore.
4.  Create **Bloc** (`goal_bloc.dart`) to handle business logic.
5.  Create **UI** (`goal_page.dart`) that consumes the Bloc.

### Step 4: Theming
Modify `lib/theme/app_theme.dart` to change the color palette and typography to match your new brand.

### Step 5: Clean Up
-   Remove `expenses` specific logic if building a different type of app.
-   Keep `auth`, `settings`, and `services` as they are reusable core modules.

---

## 📝 Best Practices Used
-   **Strict Linting**: `flutter_lints` is enabled.
-   **Immutable State**: All states are immutable objects (using `Equatable` or `Freezed`).
-   **Service Locator**: Dependencies provided via Context (`RepositoryProvider`).
-   **Async Handling**: `FutureBuilder` is avoided in favor of Bloc side-effects for better control.
