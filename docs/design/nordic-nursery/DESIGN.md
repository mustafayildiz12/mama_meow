---
name: Coo Care — Nordic Nursery
colors:
  primary: '#F08080'
  on-primary: '#FFFFFF'
  primary-container: '#FDEDE6'
  on-primary-container: '#2D2B2A'
  secondary: '#FBCDBB'
  on-secondary: '#2D2B2A'
  secondary-container: '#FDEDE6'
  on-secondary-container: '#2D2B2A'
  tertiary: '#C2D5C6'
  on-tertiary: '#2D2B2A'
  tertiary-container: '#E8F0EA'
  on-tertiary-container: '#2D2B2A'
  background: '#FAF6F0'
  on-background: '#2D2B2A'
  surface: '#FAF6F0'
  surface-container-lowest: '#FFFFFF'
  surface-container-low: '#FFFFFF'
  surface-container: '#F5F0E8'
  surface-container-high: '#FDEDE6'
  on-surface: '#2D2B2A'
  on-surface-variant: '#66625E'
  outline: '#DDD3C6'
  outline-variant: '#EDE6DC'
  error: '#AE4F48'
  on-error: '#FFFFFF'
  error-container: '#FDEDE6'
  on-error-container: '#2D2B2A'
  terra-accent: '#F08080'
  terra-ink: '#AE4F48'
  sand-pink: '#FBCDBB'
  sand-tint: '#FDEDE6'
  sage-green: '#C2D5C6'
  sage-tint: '#E8F0EA'
  linen-white: '#FAF6F0'
  cotton-white: '#FFFFFF'
  hairline: '#EDE6DC'
  muted-dark: '#2D2B2A'
  muted-soft: '#66625E'
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

# Design System: Coo Care — Nordic Nursery

Coo Care Baby Tracker ("MamaMeow") is a mobile app for parents: logging baby activities (nursing,
solids, sleep, diaper, pumping, medicine, journal), asking an AI cat companion ("Ask Meow"),
listening to parenting podcasts ("Learn") and reading weekly/monthly reports. The UI is English.

This is the colour sibling of "Warm Cotton & Berry": same layout, typography, shapes and
components — only the palette changes.

## 1. Visual Theme & Atmosphere

**Natural, soft and minimalist — a gender-neutral Scandinavian nursery.** A linen canvas,
pillow-white cards, one terracotta accent and calm sand and sage tones. It is used by tired
parents, often one-handed and at night, so it must stay calm and uncluttered.

- **Colour simplification is the core rule.** The whole UI uses exactly five brand colours —
  Terra Accent, Sand Pink, Sage Green, Linen White and Muted Dark — plus white and the tints /
  shades listed below. No blues, purples, teals, yellows, saturated greens or rainbow gradients,
  not even for activity coding, charts or status.
- Light theme only. Flat tonal layering, generous whitespace, rounded friendly shapes.
- No emojis in titles, buttons or navigation; use rounded line icons instead. The cat mascot
  ("Meow") appears only in the Ask Meow header, empty states, login and the paywall.

## 2. Color Palette & Roles

### Brand palette (the only five hues)
- **Terra Accent (`#F08080`)**: The single accent. Primary buttons, floating add buttons, the
  selected bottom-navigation pill, selected chips/segments, toggles, progress fill and the first
  chart series. Never used for large background areas.
- **Sand Pink (`#FBCDBB`)**: Supporting warm tone. Progress tracks, selected borders, avatar rings,
  illustrations and the second chart series.
- **Sage Green (`#C2D5C6`)**: Calm counterpoint. Tip / insight cards, featured content, the third
  chart series.
- **Linen White (`#FAF6F0`)**: The app canvas behind every screen.
- **Muted Dark (`#2D2B2A`)**: All primary text and icons. Never pure black.

### Derived tints and shades (same hues, no new colours)
- **Cotton White (`#FFFFFF`)**: Cards, sheets, inputs, bottom navigation bar.
- **Sand Tint (`#FDEDE6`)**: Light Sand Pink. Activity tiles (alternating), unselected chip fill,
  user chat bubbles, error containers.
- **Sage Tint (`#E8F0EA`)**: Light Sage. Activity tiles (alternating), tip cards, AI answer
  highlights, the premium card.
- **Terra Ink (`#AE4F48`)**: Darker Terra Accent, used **only for small accent text** that must be
  readable: links ("See all", "Forgot password?"), the selected tab label, inline errors, prices.
  4.9:1 on linen.
- **Muted Soft (`#66625E`)**: Secondary text, timestamps, captions, placeholder text.
- **Hairline (`#EDE6DC`)**: 1px card outlines and dividers.

### Activity coding (no extra hues)
Activities are distinguished by **icon + label**, not by colour. Activity tiles alternate Sand Tint
and Sage Tint backgrounds in a fixed order, and every activity icon is Terra Accent inside a white
squircle:
- Nursing — baby bottle icon — Sand Tint
- Solids — bowl and spoon icon — Sage Tint
- Sleep — crescent moon icon — Sand Tint
- Diaper — diaper icon — Sage Tint
- Pumping — pump / droplet icon — Sand Tint
- Medicine — pill icon — Sage Tint
- Journal — notebook icon — Sand Tint

### Charts
Series order: Terra Accent → Sand Pink → Sage Green. Axes, gridlines and labels use Muted Soft at
low opacity; bars have fully rounded tops.

## 3. Typography Rules

- **Nunito Sans** for everything: rounded, friendly and highly legible.
- Display 32/38 ExtraBold (greetings), headlines 24/30 and 20/26 ExtraBold, stat numbers 28/32
  ExtraBold, titles 17/24 Bold, body 16/24 and 14/20 Regular, labels 13/16 Bold, captions 12/16
  SemiBold.
- Sentence case everywhere. Times are 24-hour (`14:05`); durations are compact (`1h 20m`, `45m`);
  amounts carry units (`120 ml`).

## 4. Component Stylings

- **Primary button**: Terra Accent fill, white 17px Bold label, 56px tall, full pill radius, soft
  terra glow shadow `0 6px 16px rgba(240,128,128,0.30)`. One primary button per screen.
- **Secondary button**: Sand Tint fill, Muted Dark label, pill radius. **Tertiary**: Terra Ink
  text only.
- **Cards**: White, 24px radius, 1px Hairline outline, 16–20px padding, no heavy shadows.
- **Activity tiles**: Sand Tint or Sage Tint fill, 24px radius, no outline; white squircle (16px
  radius) icon holder with a terra line icon; activity name in Muted Dark Bold; last-entry meta in
  Muted Soft; a small round terra "+" quick-add button.
- **Chips & segmented controls**: 40px pill. Unselected: Sand Tint fill, Muted Dark text.
  Selected: Terra Accent fill, white Bold text (segmented control uses a sliding white thumb on a
  Sand Tint track with Terra Ink label when used for Today / Week / Month).
- **Inputs**: White, 56px tall, 16px radius, 1px Hairline border, Muted Soft placeholder; focus
  ring 2px Terra Accent. Labels above the field.
- **Bottom navigation**: White bar with a top hairline, four items (My Baby, Ask Meow, Learn,
  Profile) with rounded line icons. Active item sits in a Sand Tint pill with a Terra icon and
  Terra Ink label; inactive items are Muted Soft.
- **Bottom sheets**: White, 32px top radius, drag handle in Hairline, header with activity icon
  tile and title, sticky Save button at the bottom.
- **AI insight / tip card**: Sage Tint fill, small sparkle icon in terra, title in Muted Dark.

## 5. Layout Principles

- Mobile first, 390px wide frames, 20px side margins, 12px gutters, 4px/8px spacing grid.
- 24–32px between major sections; 48×48px minimum touch targets; primary actions in the bottom
  third (thumb zone).
- Depth comes from tonal layering (Linen canvas → White cards → Sand/Sage tints). Shadows only on
  floating elements (bottom sheets, FAB, bottom bar): `0 8px 24px rgba(45,43,42,0.08)`.

## 6. Design System Notes for Stitch Generation

- **Atmosphere keywords**: Nordic nursery, linen canvas, pillow-white rounded cards, single
  terracotta accent, soft sand and sage tints, calm gender-neutral baby app, rounded line icons.
- **Canonical colours**: Terra Accent `#F08080`, Sand Pink `#FBCDBB`, Sage Green `#C2D5C6`,
  Linen White `#FAF6F0`, Muted Dark `#2D2B2A`; tints Sand Tint `#FDEDE6`, Sage Tint `#E8F0EA`;
  text accents Terra Ink `#AE4F48`, Muted Soft `#66625E`.
- **Never** introduce blue, purple, teal, yellow or saturated green; never use rainbow
  per-activity colours.
- **Component prompts**: "56px terra pill button with white bold label"; "2-column grid of
  activity tiles alternating sand tint and sage tint, white squircle icon holder with terra line
  icon"; "white 24px-radius card with 1px linen hairline".
