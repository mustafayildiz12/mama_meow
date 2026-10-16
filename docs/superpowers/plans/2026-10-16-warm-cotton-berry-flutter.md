# Warm Cotton & Berry — Flutter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Re-skin the whole MamaMeow Flutter app with the approved "Warm Cotton & Berry" design (Stitch project `4167008251874710408`), without changing app behaviour, data or navigation.

**Architecture:** One token file (`AppColors`) + one `ThemeData` (`AppTheme.light()`) + a small UI kit (`berry_ui.dart`) form the foundation. Shared sheet/report widgets are restyled first so every activity sheet and report page inherits the look; then each screen group is restyled against its Stitch reference. All hardcoded colours outside the token file are removed.

**Tech Stack:** Flutter 3.44 / Dart 3.12, Material 3, Nunito font (bundled), `flutter_svg`, `syncfusion_flutter_charts`, `pdf`.

## Global Constraints

- Spec: `docs/design/warm-cotton-berry/DESIGN.md`. Visual references: `docs/design/warm-cotton-berry/screens/*.png` (final renders) and `docs/design/warm-cotton-berry/html/*.html` (exact spacing/radius/classes of the same screens).
- Only five brand colours: Active Berry `#FF6584`, Warm Pink `#FFA6B5`, Peach Pastel `#FFD0B8`, Cosy Ivory `#FFF8F9`, Deep Charcoal `#3D353A`, plus the derived tints/shades in `AppColors`. **No green, blue, purple, teal, yellow, orange, red or grey hues anywhere in the UI** (charts, status and snackbars included).
- **No colour literals outside `lib/constants/app_colors.dart`**: no `Color(0x…)`, no `Colors.<hue>` (only `Colors.transparent` is allowed). Use `AppColors.*` or `Theme.of(context).colorScheme.*`.
- Font stays **Nunito** (bundled; do not add Nunito Sans). Sentence case, 24h times.
- Primary buttons: Active Berry fill, white bold label, pill radius, 52–56 px tall. One primary button per screen.
- Cards: white, 24 px radius, 1 px `AppColors.hairline` border, no heavy shadows. Sheets: white, 32 px top radius.
- Activity visuals come from `ActivityKind` (Task 2): line icons, alternating Pink Tint / Peach Tint tiles. Emojis are removed from titles, buttons, nav and activity tiles (emoji *content* such as food names stays).
- Do **not** change behaviour, routes, services, models, analytics, tab order or copy semantics. Restyle only (layout may follow the Stitch reference as long as every existing action stays reachable).
- No new data features: do not add queries the screen doesn't already make (the Stitch "Today timeline" and "1h 20m ago" summary are out of scope).
- Codebase style: Turkish comments, global singletons, match surrounding code. `flutter analyze` must report **No issues found!** after every task.
- Work on branch `design/warm-cotton-berry`. Never stage `CLAUDE.md` or `docs/REFACTOR_RAPORU.md` (user's own changes).

---

## File Structure

| File | Responsibility |
|---|---|
| `lib/constants/app_colors.dart` (rewrite) | Berry tokens, chart series, shadows. Legacy names kept as aliases until Task 9. |
| `lib/constants/app_theme.dart` (new) | `AppTheme.light()` — ColorScheme, text theme, all component themes. |
| `lib/main.dart` (modify) | Use `AppTheme.light()`. |
| `lib/utils/custom_widgets/berry_ui.dart` (new) | `AppCard`, `TintCard`, `IconSquircle`, `SectionHeader`, `PrimaryPillButton`, `ActivityKind`, `ActivityIcon`. |
| `assets/bottle.svg` (new) | Baby-bottle line icon (Material has none). |
| `lib/screens/navigationbar/my-baby/widgets/sheet_widgets.dart` | Sheet frame/header/action bar/section card/chip tiles in Berry style. |
| `lib/screens/navigationbar/my-baby/widgets/report_widgets.dart` / `report_helpers.dart` | One Berry report palette, segmented control, cards, scaffold. |
| `lib/utils/custom_widgets/custom_snackbar.dart`, `custom_loader.dart` | Berry snackbars/loader. |
| Screen files (Tasks 3–8) | Per-screen restyle. |

---

### Task 1: Tokens + theme foundation

**Files:**
- Rewrite: `lib/constants/app_colors.dart`
- Create: `lib/constants/app_theme.dart`
- Modify: `lib/main.dart:37-40`

**Interfaces:**
- Produces: `AppColors.{activeBerry, warmPink, peachPastel, cosyIvory, deepCharcoal, cottonWhite, pinkTint, peachTint, berryInk, charcoalSoft, hairline, outline, scrim, chartSeries, berryGlow, floatShadow}`, `AppTheme.light()`, `AppTheme.{radiusCard, radiusInput, radiusSheet, buttonHeight}`.

- [ ] **Step 1: Rewrite `app_colors.dart`**

```dart
import 'package:flutter/material.dart';

/// Warm Cotton & Berry renk token'ları (docs/design/warm-cotton-berry/DESIGN.md).
/// Uygulamada yalnızca bu dosyadaki renkler kullanılır.
class AppColors {
  AppColors._();

  // ---- 5 marka rengi ----
  static const Color activeBerry = Color(0xFFFF6584);
  static const Color warmPink = Color(0xFFFFA6B5);
  static const Color peachPastel = Color(0xFFFFD0B8);
  static const Color cosyIvory = Color(0xFFFFF8F9);
  static const Color deepCharcoal = Color(0xFF3D353A);

  // ---- Türetilmiş tonlar ----
  static const Color cottonWhite = Color(0xFFFFFFFF);
  static const Color pinkTint = Color(0xFFFFE3E9);
  static const Color peachTint = Color(0xFFFFF0E8);

  /// Küçük vurgu metinleri (link, seçili sekme etiketi, fiyat). Ivory üzerinde 4.9:1.
  static const Color berryInk = Color(0xFFC7365A);

  /// İkincil metin, zaman damgası, placeholder.
  static const Color charcoalSoft = Color(0xFF6E6369);
  static const Color hairline = Color(0xFFF5E3E7);
  static const Color outline = Color(0xFFE8CDD3);
  static const Color scrim = Color(0x663D353A);

  /// Grafik seri sırası.
  static const List<Color> chartSeries = [
    activeBerry,
    warmPink,
    peachPastel,
    berryInk,
    charcoalSoft,
  ];

  /// Birincil butonun yumuşak berry parıltısı.
  static const List<BoxShadow> berryGlow = [
    BoxShadow(color: Color(0x4DFF6584), blurRadius: 16, offset: Offset(0, 6)),
  ];

  /// Yüzen öğeler (sheet, FAB, alt menü) için gölge.
  static const List<BoxShadow> floatShadow = [
    BoxShadow(color: Color(0x143D353A), blurRadius: 24, offset: Offset(0, 8)),
  ];

  // ---- Eski adlar (Task 9'da kaldırılır) ----
  static const Color pink50 = pinkTint;
  static const Color pink100 = pinkTint;
  static const Color pink200 = warmPink;
  static const Color pink300 = warmPink;
  static const Color pink400 = activeBerry;
  static const Color pink500 = activeBerry;
  static const Color purple50 = peachTint;
  static const Color purple200 = warmPink;
  static const Color purple500 = berryInk;
  static const Color blue100 = peachTint;
  static const Color kDeepOrange = activeBerry;
  static const Color kOrange = pinkTint;
  static const Color kLightOrange = cosyIvory;
}
```

- [ ] **Step 2: Create `app_theme.dart`** — `AppTheme.light()` returning a Material 3 `ThemeData` with `fontFamily: 'Nunito'`, `scaffoldBackgroundColor: cosyIvory` and a hand-built `ColorScheme` (no `fromSeed`):
  primary activeBerry / onPrimary cottonWhite; primaryContainer pinkTint / onPrimaryContainer deepCharcoal; secondary warmPink / onSecondary deepCharcoal; secondaryContainer pinkTint / onSecondaryContainer deepCharcoal; tertiary peachPastel / onTertiary deepCharcoal; tertiaryContainer peachTint / onTertiaryContainer deepCharcoal; error berryInk / onError cottonWhite; errorContainer pinkTint / onErrorContainer deepCharcoal; surface cottonWhite / onSurface deepCharcoal / onSurfaceVariant charcoalSoft; surfaceContainerLowest/Low cottonWhite, surfaceContainer cosyIvory, surfaceContainerHigh/Highest pinkTint; outline outline; outlineVariant hairline; shadow/scrim deepCharcoal; inverseSurface deepCharcoal / onInverseSurface cosyIvory; inversePrimary warmPink; surfaceTint transparent.
  Text theme (all deepCharcoal unless noted): displaySmall 32/w800/-0.3 ls; headlineMedium 24/w800; headlineSmall 20/w800; titleLarge 20/w800; titleMedium 17/w700; titleSmall 14/w700; bodyLarge 16/w400; bodyMedium 14/w400; bodySmall 12/w600 charcoalSoft; labelLarge 16/w700; labelMedium 13/w700; labelSmall 12/w600.
  Component themes: AppBar (ivory bg, charcoal fg, elevation 0, scrolledUnderElevation 0, centerTitle, title 20/w800); ElevatedButton (berry bg, white fg, elevation 0, StadiumBorder, minimumSize `Size(64, 52)`, label 16/w700, disabled bg hairline + fg charcoalSoft); FilledButton (StadiumBorder, minimumSize `Size(64, 52)`, label 16/w700 — colours left to the scheme so `FilledButton.tonal` stays pinkTint/charcoal); OutlinedButton (charcoal fg, side 1.5 outline, StadiumBorder, minimumSize `Size(64, 52)`); TextButton (berryInk fg, w700); InputDecoration (filled white, radius 16, enabled border 1 px outline, focused 2 px activeBerry, error berryInk, hint/label charcoalSoft, floating label berryInk, contentPadding 16×18); Chip (pinkTint bg, selected activeBerry, label 13/w700 charcoal, selected label white, no side, StadiumBorder, checkmark white); Card (white, elevation 0, radius 24, 1 px hairline, margin zero); BottomSheet (white, radius top 32, surfaceTint transparent, dragHandleColor outline); Dialog (white, radius 24, title 20/w800, content 14 charcoal); SnackBar (floating, charcoal bg, white content, radius 16, actionTextColor warmPink); FAB (berry/white, CircleBorder, elevation 2); ProgressIndicator (berry, linear track pinkTint); Switch (selected track berry + white thumb, unselected track hairline + outline thumb, trackOutline transparent); Checkbox/Radio (selected berry); Slider (berry active, pinkTint inactive); Divider (hairline, 1, space 1); ListTile (iconColor charcoalSoft); SegmentedButton (selected berry/white, unselected pinkTint/charcoal, no side); TabBar (label berryInk, unselected charcoalSoft, indicator berry); TimePicker/DatePicker (white bg, radius 24; picker accents come from the scheme); PopupMenu (white, radius 16); TextSelection (cursor berry, selection warmPink 40 %, handle berry); IconTheme charcoal. Expose `static const double radiusCard = 24, radiusInput = 16, radiusSheet = 32, buttonHeight = 56;`.

- [ ] **Step 3: Use the theme** — in `lib/main.dart` replace the inline `ThemeData(...)` with `theme: AppTheme.light(),` (import `package:mama_meow/constants/app_theme.dart`).

- [ ] **Step 4: Verify** — `flutter analyze` → `No issues found!`

- [ ] **Step 5: Commit** — `git add lib/constants lib/main.dart && git commit -m "feat(design): add Warm Cotton & Berry tokens and theme"`

---

### Task 2: UI kit + shared sheet/report/snackbar/loader widgets

**Files:**
- Create: `lib/utils/custom_widgets/berry_ui.dart`, `assets/bottle.svg`
- Modify: `lib/screens/navigationbar/my-baby/widgets/sheet_widgets.dart`, `report_widgets.dart`, `report_helpers.dart`, `lib/utils/custom_widgets/custom_snackbar.dart`, `custom_loader.dart`

**Interfaces:**
- Consumes: Task 1 tokens/theme.
- Produces (used by Tasks 3–8):
  - `enum ActivityKind { nursing, solid, sleep, diaper, pumping, medicine, journal }` with getters `String label`, `Color tileColor` (pinkTint for nursing/sleep/pumping/journal, peachTint for solid/diaper/medicine).
  - `ActivityIcon({required ActivityKind kind, double size = 24, Color color = AppColors.activeBerry})` — `bottle.svg` for nursing; Material outlined icons otherwise: solid `rice_bowl_outlined`, sleep `bedtime_outlined`, diaper `baby_changing_station_outlined`, pumping `water_drop_outlined`, medicine `medication_outlined`, journal `menu_book_outlined`.
  - `IconSquircle({required Widget child, Color background = AppColors.cottonWhite, double size = 44, double radius = 16})`.
  - `AppCard({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(20), Color color = AppColors.cottonWhite, VoidCallback? onTap})` — 24 radius, 1 px hairline border.
  - `TintCard({required Widget child, Color color = AppColors.peachTint, EdgeInsetsGeometry padding = const EdgeInsets.all(20), VoidCallback? onTap})` — 24 radius, no border.
  - `SectionHeader({required String title, String? actionLabel, VoidCallback? onAction})` — 20/w800 title, Berry Ink action with trailing arrow.
  - `PrimaryPillButton({required String label, required VoidCallback? onPressed, IconData? icon, bool loading = false, double height = 56})` — berry fill + `AppColors.berryGlow`, white 17/w700 label, disabled = hairline/charcoalSoft.
  - `showActivitySheet` unchanged signature; `ActivitySheetScaffold` gains `ActivityKind? kind`, `String? title`, `String? subtitle` (renders the standard sheet header: drag handle, `IconSquircle(pinkTint)` + `ActivityIcon`, title 24/w800, subtitle charcoalSoft, close button) — the old `gradient`/`saveColor` params become optional and ignored-by-design (removed in Task 9 once callers are updated).
  - `ReportPalette.berry` (single palette) and `ReportScaffold` with `palette`/`pdfIconColor` optional (default berry).

- [ ] **Step 1: `assets/bottle.svg`** — 24×24 line icon, `stroke="#000"` (tinted at runtime), stroke-width 2, round caps/joins, no fill: nipple (rounded top), collar band, rounded-rect body with two measurement ticks. Declared by the existing `assets/` entry.

- [ ] **Step 2: `berry_ui.dart`** with the widgets listed above (Turkish doc comments, `SvgPicture.asset('assets/bottle.svg', colorFilter: ColorFilter.mode(color, BlendMode.srcIn))`).

- [ ] **Step 3: `sheet_widgets.dart`** — `sheetDecoration` → white, top radius 32, `AppColors.floatShadow` (gradient arg ignored); `ActivitySheetFrame` unchanged logic; `ActivitySheetScaffold` renders the standard header when `title != null` (drag handle 40×4 outline pill, 16 px gap, header row); `SheetActionBar` → top hairline divider, `FilledButton.tonal` "Cancel"/backLabel + `PrimaryPillButton` "Save" (52 tall, loading spinner preserved, disabled when `onSave == null`); `showSaveError` → `customSnackBar.error`-style berryInk; `SheetSectionCard` → white, radius 24, hairline border, no shadow, title 15/w700 charcoal; `TimeField` → white field radius 16 with clock icon in berry; `ChipTileStyle` presets (`orange`, `orangeLarge`, `orangeCompact`, `orangeSmall`, `teal`) all become Berry: background pinkTint, selectedBackground cottonWhite, selectedBorder activeBerry (2 px), selectedIcon activeBerry, radius 16, no shadow; `_ChipTile` adds a small berry check badge when selected and uses charcoal text. Keep preset names (callers unchanged).

- [ ] **Step 4: `report_widgets.dart` / `report_helpers.dart`** — `ReportPalette.berry` (tint pinkTint, badge peachTint, segmentFill cottonWhite, segmentBackground pinkTint, segmentActiveForeground berryInk); `RangeSegmented` → pinkTint pill track, white sliding thumb with soft shadow, labels 14/w700 (selected berryInk, unselected charcoal), no blur; `ReportSectionCard` → white `AppCard` look, leading emoji badge replaced by optional `IconSquircle(peachTint)` (keep the `leading` String param working: show it inside the squircle); `StatTile` → label 13/w600 charcoalSoft, value 28/w800 charcoal single line (FittedBox scaleDown); `RatioBarTile` → white card, track pinkTint, bar berry; `tierColor` → high activeBerry, mid warmPink, low peachPastel, else outline; `CenteredMessage` → charcoalSoft subtitle, `PrimaryPillButton` action; `LoadingView` berry. `ReportScaffold` → ivory background (no gradient), AppBar back = white circle with hairline + `arrow_back`, title 20/w800, PDF action = `IconButton(Icons.ios_share)` in charcoal; `initReport` status bar colour = cosyIvory.

- [ ] **Step 5: snackbar + loader** — `custom_snackbar.dart`: success = deepCharcoal bg + `check_circle` warmPink icon; error = berryInk bg; warning = peachPastel bg + charcoal text/icon; info = activeBerry bg. Radius 16, floating, white/charcoal text as above. `custom_loader.dart`: scrim `AppColors.scrim`, white rounded card with berry `CircularProgressIndicator` (remove pink gradient/black).

- [ ] **Step 6: Verify** — `flutter analyze` → `No issues found!`
- [ ] **Step 7: Commit** — `feat(design): Berry UI kit and shared sheet/report widgets`

---

### Task 3: Bottom navigation + My Baby + Journal

**Files:** `lib/screens/navigationbar/bottom_nav_bar.dart`, `lib/screens/navigationbar/my-baby/my_baby_screen.dart`, `lib/screens/navigationbar/my-baby/journal/journal_screen.dart`, `.../journal/add_journal_note_bottom_sheet.dart`
**Reference:** `screens/01_my_baby.png`, `html/01_my_baby.html`

- [ ] **Nav bar**: white bar, top 1 px hairline, `AppColors.floatShadow`; keep tab order and `_tabs` labels; replace PNG icons with Material outlined icons (Ask Meow `chat_bubble_outline`, My Baby `child_care_outlined`, Learn `menu_book_outlined`, Profile `person_outline`); active item = pinkTint pill (radius 999, 16×6 padding) with berry icon + berryInk 12/w700 label; inactive charcoalSoft. Semantics unchanged.
- [ ] **My Baby**: ivory `ListView` (20 px side padding). Header row: 56 px round baby photo (`currentMeowUser?.babyPicture`, fallback `IconSquircle` with `child_care` icon) with 3 px peachPastel ring, caption "Good morning/afternoon/evening" (by local hour) charcoalSoft 13/w600, title `"<babyName> · <ageRange>"` (fallback "My Baby") 24/w800. Optional bell `IconButton` is **not** added (no feature). Section "Quick log" (`SectionHeader`). 2-column grid (`GridView.count` shrinkWrap, crossAxisSpacing/mainAxisSpacing 12, childAspectRatio ≈ 1.05) of six activity tiles: fill `ActivityKind.tileColor`, radius 24, padding 16; top row = `IconSquircle(cottonWhite, 44)` with `ActivityIcon` + right-aligned 40 px round berry "+" button (opens the existing sheet via `showActivitySheet`); bottom = name 17/w700 + "N today" 13/w600 charcoalSoft from the existing count stream. Tapping the tile body opens the report route (existing `reportRoute`). Full-width Journal tile (pinkTint, row layout: squircle + "Journal" + "Write today's little story" + white round "+" with berry icon) → existing `_openJournal`. "AI tip for today" `TintCard(peachTint)`: sparkle icon + overline "AI TIP FOR TODAY" berryInk 12/w800 letterSpacing 1, title 20/w800 "Feeding cues", existing tip text (strip the 💡 emoji), white pill button "Ask Meow" (chat icon, berryInk label) → `context.goNamed('askMeow')`. Remove the gradients/emoji/baby.svg header.
- [ ] **Journal screen + add note sheet**: replace all hues with tokens; cards = `AppCard`; primary actions = `PrimaryPillButton`; chips via theme; header via `ActivitySheetScaffold`-style header where applicable (kind `journal`).
- [ ] **Verify** `flutter analyze`; no `Color(0x`/`Colors.<hue>` left in these files (`grep -nE "Color\(0x|Colors\.(?!transparent)"`).
- [ ] **Commit** `feat(design): Berry bottom nav, My Baby and journal`

### Task 4: Ask Meow

**Files:** `lib/screens/navigationbar/home/home_screen.dart`, `home/widgets/*.dart`
**Reference:** `screens/02_ask_meow.png`, `html/02_ask_meow.html`

- [ ] Header: 56 px peachTint circle with the cat asset (`assets/happy.png` or current mascot) + "Ask Meow" 24/w800 + "Your Baby's AI Cat Companion" charcoalSoft; existing actions kept (restyled as 44 px white circle buttons with hairline).
- [ ] Quick questions card: `AppCard`, sparkle icon + "Quick questions" 17/w700 + shuffle `IconButton`; each question = full-width pinkTint pill row (16 px radius 999, 14×16 padding, 14/w700 charcoal, trailing `north_east` icon). Strip emojis from the displayed question text only if they are decorative (keep data untouched — use `.replaceAll(RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true), '').trim()` at render).
- [ ] User bubble pinkTint (radius 20, bottom-right 6); Meow answer card white `AppCard` with small paw avatar (peachTint circle), "Meow" berryInk 14/w800 + sparkle, body 16/24; detailed-info expansion row; Sources as peachTint pill chips with `open_in_new`; "Share" tertiary text button with share icon; follow-up suggestions = pinkTint pills with leading "+".
- [ ] Input card: white bar pinned above nav, hairline top border; camera + mic icon buttons charcoal; pill text field (white, outline border, hint "Ask anything about your baby…"); 48 px round berry send button (white `arrow_upward`); recording state uses berry.
- [ ] Past questions list: `AppCard` rows, charcoalSoft subtitle.
- [ ] Verify + commit `feat(design): Berry Ask Meow`

### Task 5: Learn + podcast player

**Files:** `lib/screens/navigationbar/learn/learn_screen.dart`, `learn/display_podcast.dart`
**Reference:** `screens/03_learn.png`, `html/03_learn.html`

- [ ] Learn: title "Podcasts" 32/w800 + subtitle "Short episodes from pediatric experts" charcoalSoft; white pill search field (search icon, hint "Search podcasts..."); horizontal category chips (selected berry/white, others pinkTint/charcoal; drop the emoji icons); episode list inside one `AppCard`, rows = 56 px rounded cover (existing image) or `IconSquircle(pinkTint/peachTint alternating)` fallback, title 16/w600, meta charcoalSoft, 40 px pinkTint round play button with berry icon, hairline dividers; error/empty states with `PrimaryPillButton("Try Again")`.
- [ ] Podcast player (`display_podcast.dart`): ivory bg, large rounded cover (radius 24), title 24/w800, meta charcoalSoft, slider via theme (berry), 72 px berry play/pause circle with `berryGlow`, secondary controls charcoal; no other hues.
- [ ] Verify + commit `feat(design): Berry Learn and podcast player`

### Task 6: Profile + get-started forms/modals + update modal

**Files:** `lib/screens/navigationbar/profile/profile_screen.dart`, `profile/widgets/profile_card.dart`, `lib/screens/get-started/**/*.dart`, `lib/service/app_update_service.dart`
**Reference:** `screens/04_profile.png`, `html/04_profile.html`

- [ ] Profile: title "Profile" centered 20/w800. Baby card (`AppCard`, centered): 112 px round photo with 4 px peachPastel ring + 32 px berry edit badge (existing photo actions), name 32/w800, rows "Age Range" (value as pinkTint pill, berryInk 13/w700) and existing fields with berry line icons, hairline dividers. Premium card `TintCard(peachTint)`: white squircle star icon, small white pill "Parent Plus" with crown, "Be Premium" 20/w800, description, `PrimaryPillButton` (existing paywall action/label); premium-active state keeps its content in the same card style. Settings card: label "Preferences & Support" 13/w700 charcoalSoft, rows = 40 px pinkTint circle with berry icon + title 17/w700 (+ subtitle) + chevron, straight hairline dividers (`Divider` via theme) — keep every existing row/action. Account card: centered icon circle, signed-in text, `FilledButton.tonal` Logout / Login, "Delete account" berryInk underlined text button (keep existing confirmation flow). Footer: version text charcoalSoft.
- [ ] Get-started page, baby info form, all modals (terms, baby info, update baby info, update email/password, update-available): replace hues with tokens; buttons via theme/`PrimaryPillButton`; inputs via theme; modal surfaces white radius 24.
- [ ] `app_update_service.dart` dialog colours → tokens.
- [ ] Verify + commit `feat(design): Berry profile and onboarding modals`

### Task 7: Paywall + auth

**Files:** `lib/screens/premium/**/*.dart`, `lib/screens/auth/**/*.dart`
**Reference:** `screens/07_paywall.png`, `screens/08_login.png`, matching HTML

- [ ] Paywall: ivory bg; top row "Restore" berryInk text button + 44 px white circle close; hero 192 px circle (peachTint) with the existing mascot image (`assets/orange-cat.png`/current asset) clipped; white pill badge "For tired parents" with heart; headline "Unlock Premium Features" 32/w800 centered; subtitle charcoalSoft. Benefits `AppCard`: rows with `IconSquircle(pinkTint)` + berry icon, title 17/w800, advantages joined as subtitle charcoalSoft, inset hairline dividers. Plan selector (`package_card.dart`): two side-by-side white cards radius 24; selected = 2 px berry border + berry check circle + top "Best value" berry pill badge where the existing logic marks the recommended plan; price 32/w800, per-period text berryInk w700; unselected = hairline border + empty circle. CTA `PrimaryPillButton` with arrow (existing label logic). Legal footer charcoalSoft links. Feature carousel (if still used) restyled with tokens.
- [ ] Login & register: ivory bg; close button 44 px pinkTint circle; centered 192 px peachTint circle with mascot (`assets/orange-cat.png` or existing logo asset); "Welcome Back!" 32/w800 (register keeps its own title); subtitle charcoalSoft; labels 14/w700 above fields; `AuthTextField` → theme input (56 px, radius 16, white, outline border, berry focus, leading icons charcoalSoft, eye toggle); "Forgot password?" berryInk right-aligned; `PrimaryPillButton("Sign In")` (keep the exact text "Sign In" — the integration test taps it); divider "or continue with"; Apple + Google as white outlined pills side by side (keep provider logos); footer "Don't have an account? Sign Up" with berryInk underlined link. Forgot-password dialog via theme. Keep hint texts `Enter your email` / `Enter your password` unchanged (test finders).
- [ ] Verify + commit `feat(design): Berry paywall and auth`

### Task 8: Activity sheets, reports, reminders, PDF

**Files:** `lib/screens/navigationbar/my-baby/{nursing,solid,sleep,diaper,pumping,medicine}/*.dart` (sheets + report pages, not `*_computed`/`*_compute` logic), `.../reminders/*.dart`, `lib/service/reminders/reminder_config.dart` (UI colour fields only), `lib/utils/pdf/report_pdf.dart`
**Reference:** `screens/05_add_nursing_sheet.png`, `screens/06_sleep_report.png`

- [ ] Every add sheet: pass `kind:` + `title:` (e.g. "Add Nursing") + `subtitle:` (existing date line) to `ActivitySheetScaffold`, drop its `gradient`/`saveColor` arguments and any custom header that duplicates it; replace remaining hues (teal/orange/purple/blue/grey) with tokens; selectable cards use the shared `ChipTileStyle` presets; segmented choices (e.g. Nursing/Bottle, Left/Right) use the pinkTint track + berry selected look (theme `SegmentedButton` or the same pattern as the reference). Custom-solid page likewise.
- [ ] Every report page: delete the per-page palette/colour consts, use `ReportPalette.berry`/defaults; charts (syncfusion) use `AppColors.chartSeries` in order (berry → warm pink → peach → berry ink → charcoal soft), rounded bar tops (`borderRadius: BorderRadius.vertical(top: Radius.circular(8))`), axis labels charcoalSoft, gridlines hairline; tips cards use peachTint badges; AI insight sections use `TintCard(peachTint)` with sparkle icon; "add" empty-state actions via `CenteredMessage`.
- [ ] Reminders: `reminder_config.dart` gradients/colours → tint pair (`[pinkTint, peachTint]`) and berry accents (keep `idIndex` order and every other field untouched); manager page + editor sheet restyled with `AppCard`, theme switches/chips, `PrimaryPillButton`.
- [ ] `report_pdf.dart`: PDF accent/table colours → `PdfColor.fromInt(0xFFFF6584)` family (berry, warm pink, peach, charcoal text). This is the only place besides `app_colors.dart` allowed to hold hex values (PDF colours are a different type) — define them as private consts at the top of the file with a comment.
- [ ] Verify + commit `feat(design): Berry activity sheets, reports and reminders`

### Task 9: Cleanup, full verification

- [ ] Remove legacy aliases (`pink50 … kLightOrange`) from `AppColors`; remove now-unused `gradient`/`saveColor`/`palette`/`pdfIconColor` params from shared widgets and their call sites; delete unused nav PNG references only if no longer used anywhere (keep asset files).
- [ ] `grep -rnE "Color\(0x" lib --include=*.dart | grep -v app_colors.dart | grep -v report_pdf.dart` → empty. `grep -rnoE "Colors\.[a-zA-Z]+" lib --include=*.dart | grep -v "Colors.transparent"` → empty.
- [ ] `flutter analyze` → `No issues found!`
- [ ] Run the app on an iOS simulator via `flutter drive` with the screenshot driver (`test_driver/integration_test.dart`, writes `build/screenshots/*.png`) using the existing `integration_test/app_flow_test.dart` → test passes, no FlutterErrors; compare screenshots with `docs/design/warm-cotton-berry/screens/`.
- [ ] Commit `chore(design): remove legacy colours and finish Berry migration`
