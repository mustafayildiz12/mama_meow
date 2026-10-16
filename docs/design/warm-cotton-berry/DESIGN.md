---
name: Coo Care — Warm Cotton & Berry
colors:
  primary: '#FF6584'
  on-primary: '#FFFFFF'
  primary-container: '#FFE3E9'
  on-primary-container: '#3D353A'
  secondary: '#FFA6B5'
  on-secondary: '#3D353A'
  secondary-container: '#FFE3E9'
  on-secondary-container: '#3D353A'
  tertiary: '#FFD0B8'
  on-tertiary: '#3D353A'
  tertiary-container: '#FFF0E8'
  on-tertiary-container: '#3D353A'
  background: '#FFF8F9'
  on-background: '#3D353A'
  surface: '#FFF8F9'
  surface-container-lowest: '#FFFFFF'
  surface-container-low: '#FFFFFF'
  surface-container: '#FFF0F3'
  surface-container-high: '#FFE3E9'
  on-surface: '#3D353A'
  on-surface-variant: '#6E6369'
  outline: '#E8CDD3'
  outline-variant: '#F5E3E7'
  error: '#C7365A'
  on-error: '#FFFFFF'
  error-container: '#FFE3E9'
  on-error-container: '#3D353A'
  active-berry: '#FF6584'
  berry-ink: '#C7365A'
  warm-pink: '#FFA6B5'
  pink-tint: '#FFE3E9'
  peach-pastel: '#FFD0B8'
  peach-tint: '#FFF0E8'
  cosy-ivory: '#FFF8F9'
  cotton-white: '#FFFFFF'
  hairline: '#F5E3E7'
  deep-charcoal: '#3D353A'
  charcoal-soft: '#6E6369'
typography:
  display:
    fontFamily: Nunito Sans
    fontSize: 32px
    fontWeight: '800'
    lineHeight: 38px
    letterSpacing: -0.01em
  headline-lg:
    fontFamily: Nunito Sans
    fontSize: 24px
    fontWeight: '800'
    lineHeight: 30px
  headline-md:
    fontFamily: Nunito Sans
    fontSize: 20px
    fontWeight: '800'
    lineHeight: 26px
  stat-number:
    fontFamily: Nunito Sans
    fontSize: 28px
    fontWeight: '800'
    lineHeight: 32px
  title:
    fontFamily: Nunito Sans
    fontSize: 17px
    fontWeight: '700'
    lineHeight: 24px
  body-lg:
    fontFamily: Nunito Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Nunito Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label:
    fontFamily: Nunito Sans
    fontSize: 13px
    fontWeight: '700'
    lineHeight: 16px
  caption:
    fontFamily: Nunito Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
rounded:
  sm: 0.5rem
  DEFAULT: 0.75rem
  md: 1rem
  lg: 1.5rem
  xl: 2rem
  full: 9999px
spacing:
  gutter: 12px
  margin: 20px
  space-xs: 4px
  space-sm: 8px
  space-md: 16px
  space-lg: 24px
  space-xl: 32px
---

# Design System: Coo Care — Warm Cotton & Berry

Coo Care Baby Tracker ("MamaMeow") is a mobile app for parents: logging baby activities (nursing,
solids, sleep, diaper, pumping, medicine, journal), asking an AI cat companion ("Ask Meow"),
listening to parenting podcasts ("Learn") and reading weekly/monthly reports. The UI is English.

## 1. Visual Theme & Atmosphere

**Warm, caring and premium.** The app should feel like a soft cotton blanket: a cosy ivory canvas,
pillow-white cards and one confident berry accent. It is used by tired parents, often one-handed
and at night, so it must stay calm and uncluttered.

- **Colour simplification is the core rule.** The whole UI uses exactly five brand colours —
  Active Berry, Warm Pink, Peach Pastel, Cosy Ivory and Deep Charcoal — plus white and the tints /
  shades listed below. No greens, blues, purples, teals, yellows or rainbow gradients anywhere,
  not even for activity coding, charts or status.
- Light theme only. Flat tonal layering, generous whitespace, rounded friendly shapes.
- No emojis in titles, buttons or navigation; use rounded line icons instead. The cat mascot
  ("Meow") appears only in the Ask Meow header, empty states, login and the paywall.

## 2. Color Palette & Roles

### Brand palette (the only five hues)
- **Active Berry (`#FF6584`)**: The single accent. Primary buttons, floating add buttons, the
  selected bottom-navigation pill, selected chips/segments, toggles, progress fill and the first
  chart series. Never used for large background areas.
- **Warm Pink (`#FFA6B5`)**: Supporting accent. Second chart series, progress tracks, selected
  borders, illustrations and decorative dots.
- **Peach Pastel (`#FFD0B8`)**: Warm highlight. Tip / insight cards, featured content, third chart
  series, avatar rings.
- **Cosy Ivory (`#FFF8F9`)**: The app canvas behind every screen.
- **Deep Charcoal (`#3D353A`)**: All primary text and icons. Never pure black.

### Derived tints and shades (same hues, no new colours)
- **Cotton White (`#FFFFFF`)**: Cards, sheets, inputs, bottom navigation bar.
- **Pink Tint (`#FFE3E9`)**: Light Warm Pink. Activity tiles (alternating), unselected chip fill,
  user chat bubbles, error containers.
- **Peach Tint (`#FFF0E8`)**: Light Peach. Activity tiles (alternating), tip cards, AI answer
  highlights.
- **Berry Ink (`#C7365A`)**: Darker Active Berry, used **only for small accent text** that must be
  readable: links ("See all", "Forgot password?"), the selected tab label, inline errors,
  prices. 4.9:1 on ivory.
- **Charcoal Soft (`#6E6369`)**: Secondary text, timestamps, captions, placeholder text.
- **Hairline (`#F5E3E7`)**: 1px card outlines and dividers.

### Activity coding (no extra hues)
Activities are distinguished by **icon + label**, not by colour. Activity tiles alternate Pink Tint
and Peach Tint backgrounds in a fixed order, and every activity icon is Active Berry inside a white
squircle:
- Nursing — baby bottle icon — Pink Tint
- Solids — bowl and spoon icon — Peach Tint
- Sleep — crescent moon icon — Pink Tint
- Diaper — diaper icon — Peach Tint
- Pumping — pump / droplet icon — Pink Tint
- Medicine — pill icon — Peach Tint
- Journal — notebook icon — Pink Tint

### Charts
Series order: Active Berry → Warm Pink → Peach Pastel. Axes, gridlines and labels use Charcoal
Soft at low opacity; bars have fully rounded tops.

## 3. Typography Rules

- **Nunito Sans** for everything: rounded, friendly and highly legible.
- Display 32/38 ExtraBold (greetings), headlines 24/30 and 20/26 ExtraBold, stat numbers 28/32
  ExtraBold, titles 17/24 Bold, body 16/24 and 14/20 Regular, labels 13/16 Bold, captions 12/16
  SemiBold.
- Sentence case everywhere. Times are 24-hour (`14:05`); durations are compact (`1h 20m`, `45m`);
  amounts carry units (`120 ml`).

## 4. Component Stylings

- **Primary button**: Active Berry fill, white 17px Bold label, 56px tall, full pill radius, soft
  berry glow shadow `0 6px 16px rgba(255,101,132,0.30)`. One primary button per screen.
- **Secondary button**: Pink Tint fill, Deep Charcoal label, pill radius. **Tertiary**: Berry Ink
  text only.
- **Cards**: White, 24px radius, 1px Hairline outline, 16–20px padding, no heavy shadows.
- **Activity tiles**: Pink Tint or Peach Tint fill, 24px radius, no outline; white squircle
  (16px radius) icon holder with a berry line icon; activity name in Deep Charcoal Bold; last-entry
  meta in Charcoal Soft; a small round berry "+" quick-add button.
- **Chips & segmented controls**: 40px pill. Unselected: Pink Tint fill, Deep Charcoal text.
  Selected: Active Berry fill, white Bold text (segmented control uses a sliding white thumb on a
  Pink Tint track with Berry Ink label when used for Today / Week / Month).
- **Inputs**: White, 56px tall, 16px radius, 1px Hairline border, Charcoal Soft placeholder; focus
  ring 2px Active Berry. Labels above the field.
- **Bottom navigation**: White bar with a top hairline, four items (My Baby, Ask Meow, Learn,
  Profile) with rounded line icons. Active item sits in a Pink Tint pill with a Berry icon and
  Berry Ink label; inactive items are Charcoal Soft.
- **Bottom sheets**: White, 32px top radius, drag handle in Hairline, header with activity icon
  tile and title, sticky Save button at the bottom.
- **AI insight / tip card**: Peach Tint fill, small sparkle icon in berry, title in Deep Charcoal.

## 5. Layout Principles

- Mobile first, 390px wide frames, 20px side margins, 12px gutters, 4px/8px spacing grid.
- 24–32px between major sections; 48×48px minimum touch targets; primary actions in the bottom
  third (thumb zone).
- Depth comes from tonal layering (Ivory canvas → White cards → Pink/Peach tints). Shadows only on
  floating elements (bottom sheets, FAB, bottom bar): `0 8px 24px rgba(61,53,58,0.08)`.

## 6. Design System Notes for Stitch Generation

- **Atmosphere keywords**: warm cotton, cosy ivory canvas, pillow-white rounded cards, single berry
  accent, soft pink and peach tints, calm premium baby app, rounded line icons.
- **Canonical colours**: Active Berry `#FF6584`, Warm Pink `#FFA6B5`, Peach Pastel `#FFD0B8`,
  Cosy Ivory `#FFF8F9`, Deep Charcoal `#3D353A`; tints Pink Tint `#FFE3E9`, Peach Tint `#FFF0E8`;
  text accents Berry Ink `#C7365A`, Charcoal Soft `#6E6369`.
- **Never** introduce green, blue, purple, teal or yellow; never use rainbow per-activity colours.
- **Component prompts**: "56px berry pill button with white bold label"; "2-column grid of activity
  tiles alternating pink tint and peach tint, white squircle icon holder with berry line icon";
  "white 24px-radius card with 1px pink hairline".
