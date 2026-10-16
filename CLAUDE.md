# CLAUDE.md
claude --resume 148a6f21-dd40-4d9e-be3f-1e2fe257a275
This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

MamaMeow ("Coo Care Baby Tracker") is a Flutter mobile app (Android/iOS, with a web target) that
helps parents track baby activities, get AI parenting answers, and listen to parenting podcasts.
Flutter 3.44 / Dart SDK `^3.12.0`. Codebase comments and many identifiers are in Turkish; the app UI
ships in English only.

## Commands

```bash
flutter pub get                     # install dependencies
flutter run                         # run on connected device/emulator
flutter analyze                     # static analysis (flutter_lints 6); must stay at "No issues found!"
flutter build apk                   # Android release build (needs android/key.properties for signing)
flutter build ios                   # iOS release build
dart run flutter_launcher_icons     # regenerate launcher icons from assets/full-logo.png

# End-to-end smoke test against the real Firebase project: logs in with the test account from
# .env.example (username=/password=, git-ignored), visits every tab, report and reminder page and
# fails on any FlutterError. Optional: --dart-define=RUN_AI_TEST=true (makes one real AI call).
tool/run_integration_test.sh <device-id>
```

There are no unit tests (`test/` does not exist); `integration_test/app_flow_test.dart` is the only
test. It creates no activity records, but it does sign the test account in and out.

### Firebase Cloud Functions (`functions/`, TypeScript, Node 22)

```bash
cd functions
npm ci              # install (node_modules is not committed)
npm run lint        # eslint (.js/.ts) — keep at 0 warnings
npm run build       # tsc compile to lib/
npm run serve       # build + run local emulator
npm run deploy      # firebase deploy --only functions  (runs lint + build as predeploy)
firebase functions:secrets:set OPENAI_API_KEY   # one-time; required by the OpenAI proxy
```

The globally installed Firebase CLI on the dev machine is old (13.5.1) and fails on the
`nodejs22` runtime with a misleading "deprecated runtime" assertion; use
`npx firebase-tools@latest deploy --only functions` (and the same `npx` prefix for `secrets:*`).

`functions/src/index.ts` defines four callables (all `us-central1`, all require auth):
- `wipeUser` — deletes the caller's RTDB data (`pathsFor()`) and Storage files
  (`storagePrefixesFor()`). Update both lists whenever a new per-user path is added.
- `deleteAccount` — `wipeUser` + deletes the Auth user server-side. The client
  (`databaseService.deleteAccount()`) calls it first and falls back to `wipeUser` + client-side
  `user.delete()` when the function isn't deployed yet (`not-found`).
- `openaiChat` / `openaiTranscribe` — the OpenAI proxy (see AI layer below).

Security rules are versioned here: `database.rules.json` and `storage.rules` (deploy with
`npx firebase-tools@latest deploy --only database,storage`; validate first with `--dry-run`). Every
per-user node (`users`, `questionAi`, activities) is owner-only; `appInfo`/`updates`/`podcasts`
are public-read, client-write-denied (edit them in the console). Any new top-level node is
**denied by default** — add a rule for it. Never edit rules only in the console.

`mama_meow_readme.md` (Turkish) is the project README.

## Architecture

### Startup sequence
`main()` → `AppInitService.initApp()` (`lib/service/app_init_service.dart`) runs only what must
happen before `runApp`: `Firebase.initializeApp`, Crashlytics hooks (collection disabled in debug),
RTDB disk persistence (**must** be enabled before any RTDB access), the two `GetStorage` buckets
(`"local"` = per-user, erased on logout; `"info"` = device-level, e.g. reminders), timezone,
RevenueCat, and session restore (`users/<uid>` → `currentMeowUser`, with an 8 s timeout).
`AppInitService.initAfterFirstFrame()` (post-frame callback in `main.dart`) then requests the
notification permission, initializes `NotificationService` and schedules re-engagement nudges.
`audioHandler` (podcast `audio_service` handler) is a global in `main.dart`.

### Navigation (go_router)
- Route table: `lib/constants/app_pages.dart` (`router`); path constants in `app_routes.dart`.
  `pushNamed`/`goNamed` take route **names** (`'login'`, `'askMeow'`, …), never `AppRoutes.*` paths.
- Post-auth UI is a `StatefulShellRoute.indexedStack` with 4 tabs (My Baby, Ask Meow, Learn,
  Profile) rendered by `AppShellScaffold` (`lib/screens/navigationbar/bottom_nav_bar.dart`). Tab
  state survives login/logout, so screens listen to `FirebaseAuth.authStateChanges()` /
  `InAppPurchaseService().premiumNotifier` instead of loading once in `initState`.
- `initialLocation` is `/myBaby` and guests are allowed in: there is no global auth redirect.
  Gating is **per action**: check `authenticationService.getUser() == null` and
  `context.pushNamed('login')`. Activity services and the AI proxy assume a signed-in user.
- `GetStartedPage` (onboarding + Terms consent) is registered but currently unreachable.
- `/adminUpdate` (publishes `updates/<version>`) is only registered in debug builds, and the DB
  rules deny client writes to `updates/` — it only works if an admin rule is added.
- Each `my-baby` activity has nested `*-report` and `*-reminders` sub-routes.

### Service layer (the core pattern)
Business logic lives in `lib/service/`, mostly as **global singleton instances at the bottom of each
file** (`sleepService`, `databaseService`, `authenticationService`, …). No DI framework. App-wide
mutable state is in `lib/constants/app_constants.dart` (`currentMeowUser`, `systemPrompt`,
`askMiaModel`, …); AI prompt globals default to the built-in `empty*` constants until `appInfo`
loads.

- **Activities** (`service/activities/`): every activity service (sleep, nursing, diaper, solid,
  pumping, medicine) extends `ActivityStore<T>` (`activity_store.dart`): records live at
  `<rootPath>/<uid>/<13-digit epoch-ms key>`, range queries use `orderByKey().startAt/endAt` on
  that key, `ActivityRtdb.nextKey()` guarantees unique increasing keys, `ActivityRtdb.write()`
  returns after 4 s when offline (the write is queued by persistence), and `todayCount()` streams
  follow auth changes and roll over at midnight. A malformed record is skipped and logged, never
  fails a whole list. Journal and custom solids have their own services.
- **Event time vs. save time:** the record key/`createdAt` is the *save* time; the time the user
  picked is stored separately as `"HH:mm"` (`diaperTime`, `startTime`, `eatTime`, …). Use the
  models' `eventAt` getters / `resolveEventTime()` for anything time-of-day related.
- **Dates:** `lib/utils/date_range.dart` is the single source for `ReportPeriod`
  (today/week/month), the `DateParts` extension (Monday-based weeks, DST-safe) and `DateRange`.
  Old per-page enums (`SleepReportMode`, …) are typedefs of `ReportPeriod`.
- **Platform checks:** use `PlatformInfo` (`lib/utils/platform_info.dart`); `dart:io Platform`
  throws on web and `package:get` is not a declared dependency.
- `database_service.dart` — `users/<uid>`, `appInfo` config (model, prompts, store versions),
  account deletion. `appInfo` is publicly readable — never put secrets in it.
- `authentication_service.dart` — email/password, Google (`google_sign_in` 7: `GoogleSignIn.instance`,
  `initialize()` once, `authenticate()`), Apple. Social sign-in returns `SocialSignInResult` codes.
  `logoutFromFirebase()` also logs out of RevenueCat, cancels reminders and erases `localStorage`.
- `in_app_purchase_service.dart` — RevenueCat. Premium = active `"premium"` entitlement
  (`checkUserHaveProduct()` / `isPremium()` / `premiumNotifier`). Identity calls are serialized.
  API keys are hardcoded per platform.
- Growth: `analytic_service.dart` (Firebase Analytics — uid only, never email or question text),
  `review_service.dart`, `re_engagement_service.dart`.

### AI / GPT layer (`lib/service/gpt_service/`)
All OpenAI traffic goes through `openAiProxyService` → the `openaiChat` / `openaiTranscribe`
callables; the key exists only as the `OPENAI_API_KEY` functions secret. Never call
`api.openai.com` from the client.
- `common/ai_common.dart`: `decodeJsonObject` (fence-stripping, lenient), `babyPersonalization()`
  (reads `currentMeowUser` at call time), the shared report output schema and `requestAiReport()`
  (JSON mode, ≤ 800 tokens). Shared insight model: `models/ai_models/ai_report_insight.dart`;
  per-activity insight classes are typedefs of it.
- `gpt_service.dart` — Ask Meow (`askMia`, image input; returns `null` on failure), suggestions,
  `transcribeAudio` (returns `null` on failure).
- `<activity>_ai_service.dart` — sends a **pre-computed** summary with a "do NOT recompute,
  interpret only" prompt; models parse output leniently (`lenient_json.dart`).
- Server-side limits (functions/src/index.ts): model allowlist (unknown models — including
  `appInfo/askMiaModel` — silently become `gpt-4o-mini`), max 800 tokens, role/size validation,
  daily quotas (60 chat / 40 transcribe under `usage/<uid>/<yyyy-mm-dd>`, refunded when OpenAI
  fails). Add a new model to `ALLOWED_CHAT_MODELS` and redeploy before using it.

### Reminders & notifications
- `lib/service/reminders/`: one config-driven implementation for all six categories.
  `ReminderConfig`/`ReminderCategory` (channel, texts, storage keys, UI), `ReminderStore`
  (GetStorage `"info"`, keys `<x>_reminders_list_v1`), `ReminderScheduler` (serialized; one daily
  notification when all 7 days are selected, otherwise per weekday; inexact fallback when exact
  alarms are denied), `cancelAndClearAllReminders()`.
- Notification IDs: `100_000_000 + idIndex*10_000_000 + reminderId*10 + slot`. **Never reorder
  `ReminderCategory.idIndex`.** Re-engagement uses fixed 90001–90003. Legacy IDs
  (`legacyBase + id*10 + weekday`) are cancelled by a one-time migration.
- `NotificationService` (`motification_service.dart`) initializes the plugin exactly once (tap
  routing via payload); other code must never call `initialize()` again.
- UI: generic `ReminderManagerPage` / `ReminderEditorSheet` under `my-baby/reminders/`; the six
  `*_reminder_manager_page.dart` files are thin wrappers kept for the router.
- `service/permissions/` wraps the plugin's exact-alarm APIs (`AlarmPolicy.ensure()` returns after
  the user is back from Settings — check `context.mounted` afterwards).

### Reports & activity screens (`lib/screens/navigationbar/my-baby/`)
Flow: service range query → compute factory (`DiaperReportComputed.fromDiapers`,
`NursingReportComputed.fromNursings`, `MedicineReportComputed.fromMedicines`,
`SolidReportComputed.fromSolids`, `mergeSleepSessions`, `PumpingAiCompute.compute`) → the same
computed object feeds the page, `*_ai_service.dart` and `*_pdf_builder.dart` → shared via
`share_plus`. Overnight sleeps are stored as two day-split records; `mergeSleepSessions` joins them
for counts/averages.
- Shared UI in `my-baby/widgets/`: `report_widgets.dart` (palette, segmented control, cards),
  `report_helpers.dart` (`ReportPageMixin`, `ReportScaffold`, PDF export), `sheet_widgets.dart`
  (`ActivitySheetScaffold` + `SheetActionBar` with the saving guard, `ChipPickerSection`,
  `pick24hTime`).
- PDFs: `lib/utils/pdf/report_pdf.dart` (`ReportPdfTheme` caches Nunito so Turkish characters
  render; emojis are stripped). Charts use `syncfusion_flutter_charts`.

### Data models
`lib/models/` — hand-written `fromMap`/`toMap` (no codegen). Parse tolerantly with the helpers in
`models/activities/record_parsing.dart` / `models/ai_models/lenient_json.dart`; stored data
contains old field types (e.g. medicine `amount` int, solid amount as String).

## Conventions & gotchas

- **Never store passwords.** `users/<uid>/userPassword` used to hold plaintext passwords; the
  field is removed from the model and deleted on each login.
- **Global singletons + Turkish comments** are the house style; match the surrounding code.
- **Filenames contain load-bearing typos** (imports depend on them): `motification_service.dart`,
  `updata_available_modal.dart`. Don't rename without updating all references.
- **Secrets:** OpenAI key server-side only. RevenueCat keys are hardcoded in
  `in_app_purchase_service.dart`. Firebase config is committed (`lib/firebase_options.dart`,
  `google-services.json`, `GoogleService-Info.plist`). `.env*` files are git-ignored (real test
  credentials).
- **Colors:** use `AppColors` (`lib/constants/app_colors.dart`) instead of hex literals.
- **Snackbars** go through `customSnackBar` + `rootScaffoldMessengerKey`.
- **Localization** is English only; AI prompts ask the model to reply in the user's language.
- **Versioning:** `pubspec.yaml` `version:` sets versionName/CFBundleShortVersionString, but Android
  `versionCode` is hardcoded in `android/app/build.gradle.kts` — bump it for every Play upload.
- **iOS:** deployment target 15.0. Native dependencies come from **Swift Package Manager** —
  enabled per project in `pubspec.yaml` (`flutter: config: enable-swift-package-manager: true`,
  which overrides the machine's global `flutter config`). There is no Podfile/CocoaPods; versions
  are pinned in `ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved` (commit it). Flutter
  CLI builds check packages out into `build/ios/SourcePackages` (excluded from `flutter analyze`).
- **FlutterFire is held on the 4.x line** (firebase_core 4.15 → Firebase iOS SDK 12.19). FlutterFire 5
  pins iOS SDK 13, which needs gtm-session-fetcher ≥4, while `google_sign_in_ios` still pins
  GoogleSignIn 9 (gtm-session-fetcher <4) — SPM can't resolve both. Upgrade FlutterFire only once
  `google_sign_in_ios` moves to GoogleSignIn 10.
- **iOS UIScene lifecycle:** `Info.plist` declares `UIApplicationSceneManifest` with
  `FlutterSceneDelegate`; `AppDelegate` is a `FlutterImplicitEngineDelegate` and registers plugins in
  `didInitializeImplicitFlutterEngine` (not in `didFinishLaunching`). Plugins that need URL callbacks
  (google_sign_in, firebase_auth) receive them through the scene delegate.
