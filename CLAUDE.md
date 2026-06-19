# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

MamaMeow is a Flutter mobile app (Android/iOS, with a web target) that helps parents track baby
activities, get AI parenting answers, and listen to parenting podcasts. Dart SDK `^3.9.0`.
Codebase comments and many identifiers are in Turkish; the app UI ships in English only.

## Commands

```bash
flutter pub get                     # install dependencies
flutter run                         # run on connected device/emulator
flutter run -d chrome               # run web build
flutter analyze                     # static analysis / lint (uses flutter_lints via analysis_options.yaml)
flutter build apk                   # Android release build
flutter build ios                   # iOS release build
dart run flutter_launcher_icons     # regenerate launcher icons from assets/full-logo.png
```

There are no Dart unit tests in this project (no `test/` directory). `flutter analyze` is the only
automated check.

### Firebase Cloud Functions (`functions/`, TypeScript, Node 22)

```bash
cd functions
npm run lint        # eslint (.js/.ts)
npm run build       # tsc compile to lib/
npm run serve       # build + run local emulator
npm run deploy      # firebase deploy --only functions  (runs lint + build as predeploy)
```

The only function is `wipeUser` (callable) which deletes all Realtime Database data for the
authenticated user across every activity path.

## Architecture

### Startup sequence
`main()` (`lib/main.dart`) → `AppInitService.initApp()` (`lib/service/app_init_service.dart`) wires
everything before `runApp`: Crashlytics error hooks, `Firebase.initializeApp`, two `GetStorage`
buckets (`"local"` and `"info"`), RevenueCat purchases, timezone + local notifications, and route
selection. It then enables Realtime Database disk persistence and initializes the
`audio_service` background handler (`audioHandler`, a global in `main.dart`). The app is a
`MaterialApp.router` driven by go_router.

### Navigation (go_router)
- Route table: `lib/constants/app_pages.dart` (the `router`). Path/name string constants live in
  `lib/constants/app_routes.dart`.
- Post-auth UI is a `StatefulShellRoute.indexedStack` with 4 tabs (My Baby, Ask Meow, Learn,
  Profile) rendered by `AppShellScaffold` (`lib/screens/navigationbar/bottom_nav_bar.dart`).
- `AppInitService.initRoute()` computes `AppRoutes.initialRoute` from auth + premium state, but note
  `router` currently hardcodes `initialLocation: AppRoutes.myBaby` and allows guest access (auth
  redirect logic was removed).
- Each `my-baby` activity has nested `*-report` and `*-reminders` sub-routes.

### Service layer (the core pattern)
Business logic lives in `lib/service/` as classes, each exposed as a **global singleton instance at
the bottom of its file** (e.g. `final SleepService sleepService = SleepService();`,
`databaseService`, `authenticationService`). There is no DI framework — import the global and call
it. State is held in module-level globals in `lib/constants/app_constants.dart` (e.g.
`currentMeowUser`, `apiValue`, `systemPrompt`, `askMiaModel`, `entitlementIsActive`).

Key services:
- `service/activities/*_service.dart` — one per activity (sleep, nursing, diaper, solid, pumping,
  medicine, journal). All follow the same shape: read/write Firebase Realtime Database under
  `<activityPlural>/<uid>/<epochMillisKey>`, plus `today/week/month` range queries and a
  `today...CountStream()`. Date-range helpers come from the `DateParts` extension on `DateTime`
  (defined per-service, e.g. `startOfDay`, `startOfWeekTR`, `endOfMonth`).
- `service/database_service.dart` — user records under `users/<uid>`, and `getBasicAppInfo()` which
  pulls remote config-style values (`aiKey`, `askMiaModel`, `systemPrompt`, `suggestionPrompt`,
  version/update URLs) from the `appInfo` node into the globals.
- `service/authentication_service.dart` — Firebase Auth: email/password, Google, Apple sign-in.
- `service/in_app_purchase_service.dart` — RevenueCat (`purchases_flutter`); premium gated on the
  `"premium"` entitlement (`entitlementIsActive`). API keys are hardcoded per platform here.

### AI / GPT layer (`lib/service/gpt_service/`)
Calls the **OpenAI API directly over HTTP** (no backend proxy). The bearer key (`apiValue`) and
model (`askMiaModel`) are fetched at runtime from the Firebase `appInfo` node, not bundled.
- `gpt_service.dart` (`GptService`) — Ask Meow chat (`askMia`, supports image input), suggestions,
  and Whisper audio transcription. Prompts are personalized via `currentMeowUser` (baby name/age).
- `<activity>_ai_service.dart` — generates per-activity report insights. Each sends a
  **pre-computed/reduced JSON summary** to the model with a strict "do NOT recompute, interpret
  only" system prompt and a strict JSON output schema, used to build PDF reports.
- All chat responses are expected to be **strict JSON** matching a schema in the system prompt
  (parsed into `MiaAnswer` / report models). Default fallback prompts live in `app_constants.dart`
  (`emptySystemPrompt`, `emptySuggestionPrompt`).

### Reminders & notifications
`flutter_local_notifications` + `timezone`. Each activity has its own scheduler under
`lib/screens/navigationbar/my-baby/<activity>/<activity>_reminder_schecule.dart` (note the
misspelling "schecule"/"schecular" is used consistently) defining a unique Android notification
channel and a `base` integer for deterministic, non-colliding schedule IDs across activities.
`service/permissions/` handles Android exact-alarm policy/permission.

### Data models
`lib/models/` — plain Dart classes with `fromMap`/`toMap` (or `fromJson`/`toJson`). Subfolders:
`activities/`, `reminders/`, `ai_models/`, `dummy/`. No code generation; serialization is hand-written.

### Reports
Per-activity report flow: `*_report_compute(d).dart` reduces raw activity records → summary →
`*_ai_service.dart` for AI insight → `*_report_pdf_builder.dart` builds a PDF (`pdf` package) →
`open_filex` to view. Charts use `syncfusion_flutter_charts`.

## Conventions & gotchas

- **Global singletons everywhere.** Add new services as `final fooService = FooService();` at file
  bottom and import the instance. App-wide mutable state goes in `app_constants.dart`.
- **Turkish comments and mixed-language identifiers** are normal; match the surrounding style.
- **Filenames contain typos that are load-bearing** (imports depend on them): `motification_service.dart`,
  `push_notiication.dart`, `*_schecule.dart`, `*_schecular.dart`, `updata_available_modal.dart`. Do
  not "fix" these without updating all references.
- **Secrets are runtime-fetched** (OpenAI key from Firebase `appInfo`), but RevenueCat keys are
  hardcoded in `in_app_purchase_service.dart`. Firebase config is committed
  (`lib/firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist`).
- **Snackbars/loaders** use shared helpers: `customSnackBar` (`utils/custom_widgets/custom_snackbar.dart`)
  and `rootScaffoldMessengerKey` (`constants/app_globals.dart`).
- **Localization** is scaffolded (`AppLocalization`) but only English (`Locale("en")`) is supported;
  AI prompts ask the model to reply in the user's language.
- App version is set in `pubspec.yaml` (`version:`); update there for releases.
