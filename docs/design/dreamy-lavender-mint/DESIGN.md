---
name: Coo Care — Dreamy Lavender & Mint
colors:
  primary: '#818CF8'
  on-primary: '#FFFFFF'
  primary-container: '#F3E8FF'
  on-primary-container: '#1E1B4B'
  secondary: '#C084FC'
  on-secondary: '#1E1B4B'
  secondary-container: '#F3E8FF'
  on-secondary-container: '#1E1B4B'
  tertiary: '#A7F3D0'
  on-tertiary: '#1E1B4B'
  tertiary-container: '#E6FAF1'
  on-tertiary-container: '#1E1B4B'
  background: '#F5F7FB'
  on-background: '#1E1B4B'
  surface: '#F5F7FB'
  surface-container-lowest: '#FFFFFF'
  surface-container-low: '#FFFFFF'
  surface-container: '#EEF1F8'
  surface-container-high: '#F3E8FF'
  on-surface: '#1E1B4B'
  on-surface-variant: '#5E5C7E'
  outline: '#D3D8E8'
  outline-variant: '#E4E7F2'
  error: '#5558D9'
  on-error: '#FFFFFF'
  error-container: '#F3E8FF'
  on-error-container: '#1E1B4B'
  indigo-accent: '#818CF8'
  indigo-ink: '#5558D9'
  lullaby-lila: '#C084FC'
  lila-tint: '#F3E8FF'
  mint-sage: '#A7F3D0'
  mint-tint: '#E6FAF1'
  calm-slate: '#F5F7FB'
  cotton-white: '#FFFFFF'
  hairline: '#E4E7F2'
  midnight-navy: '#1E1B4B'
  navy-soft: '#5E5C7E'
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

# Design System: Coo Care — Dreamy Lavender & Mint

Coo Care Baby Tracker ("MamaMeow") is a mobile app for parents: logging baby activities (nursing,
solids, sleep, diaper, pumping, medicine, journal), asking an AI cat companion ("Ask Meow"),
listening to parenting podcasts ("Learn") and reading weekly/monthly reports. The UI is English.

This is the colour sibling of "Warm Cotton & Berry" and "Nordic Nursery": same layout, typography,
shapes and components — only the palette changes.

## 1. Visual Theme & Atmosphere

**Calm, modern and reassuring — soothing tones that evoke sleep and health.** A cool slate canvas,
pillow-white cards, one soft indigo accent with gentle lilac and mint tones. It is used by tired
parents, often one-handed and at night, so it must stay calm and uncluttered.

- **Colour simplification is the core rule.** The whole UI uses exactly five brand colours —
  Indigo Accent, Lullaby Lila, Mint, Calm Slate and Midnight Navy — plus white and the tints /
  shades listed below. No reds, oranges, pinks, yellows, browns or rainbow gradients, not even for
  activity coding, charts or status.
- Light theme only. Flat tonal layering, generous whitespace, rounded friendly shapes.
- No emojis in titles, buttons or navigation; use rounded line icons instead. The cat mascot
  ("Meow") appears only in the Ask Meow header, empty states, login and the paywall.

## 2. Color Palette & Roles

### Brand palette (the only five hues)
- **Indigo Accent (`#818CF8`)**: The single accent. Primary buttons, floating add buttons, the
  selected bottom-navigation pill, selected chips/segments, toggles, progress fill and the first
  chart series. Never used for large background areas.
- **Lullaby Lila (`#C084FC`)**: Supporting tone. Progress tracks, selected borders, avatar rings,
  illustrations and the second chart series.
- **Mint (`#A7F3D0`)**: Fresh counterpoint. Tip / insight cards, featured content, the third chart
  series.
- **Calm Slate (`#F5F7FB`)**: The app canvas behind every screen.
- **Midnight Navy (`#1E1B4B`)**: All primary text and icons. Never pure black.

### Derived tints and shades (same hues, no new colours)
- **Cotton White (`#FFFFFF`)**: Cards, sheets, inputs, bottom navigation bar.
- **Lila Tint (`#F3E8FF`)**: Light Lullaby Lila. Activity tiles (alternating), unselected chip
  fill, user chat bubbles, error containers.
- **Mint Tint (`#E6FAF1`)**: Light Mint. Activity tiles (alternating), tip cards, AI answer
  highlights, the premium card.
- **Indigo Ink (`#5558D9`)**: Darker Indigo Accent, used **only for small accent text** that must
  be readable: links ("See all", "Forgot password?"), the selected tab label, inline errors,
  prices. 5.2:1 on slate.
- **Navy Soft (`#5E5C7E`)**: Secondary text, timestamps, captions, placeholder text.
- **Hairline (`#E4E7F2`)**: 1px card outlines and dividers.

### Activity coding (no extra hues)
Activities are distinguished by **icon + label**, not by colour. Activity tiles alternate Lila Tint
and Mint Tint backgrounds in a fixed order, and every activity icon is Indigo Accent inside a white
squircle:
- Nursing — baby bottle icon — Lila Tint
- Solids — bowl and spoon icon — Mint Tint
- Sleep — crescent moon icon — Lila Tint
- Diaper — diaper icon — Mint Tint
- Pumping — pump / droplet icon — Lila Tint
- Medicine — pill icon — Mint Tint
- Journal — notebook icon — Lila Tint

### Charts
Series order: Indigo Accent → Lullaby Lila → Mint. Axes, gridlines and labels use Navy Soft at low
opacity; bars have fully rounded tops.

## 3. Typography Rules

- **Nunito Sans** for everything: rounded, friendly and highly legible.
- Display 32/38 ExtraBold (greetings), headlines 24/30 and 20/26 ExtraBold, stat numbers 28/32
  ExtraBold, titles 17/24 Bold, body 16/24 and 14/20 Regular, labels 13/16 Bold, captions 12/16
  SemiBold.
- Sentence case everywhere. Times are 24-hour (`14:05`); durations are compact (`1h 20m`, `45m`);
  amounts carry units (`120 ml`).

## 4. Component Stylings

- **Primary button**: Indigo Accent fill, white 17px Bold label, 56px tall, full pill radius, soft
  indigo glow shadow `0 6px 16px rgba(129,140,248,0.30)`. One primary button per screen.
- **Secondary button**: Lila Tint fill, Midnight Navy label, pill radius. **Tertiary**: Indigo Ink
  text only.
- **Cards**: White, 24px radius, 1px Hairline outline, 16–20px padding, no heavy shadows.
- **Activity tiles**: Lila Tint or Mint Tint fill, 24px radius, no outline; white squircle (16px
  radius) icon holder with an indigo line icon; activity name in Midnight Navy Bold; last-entry
  meta in Navy Soft; a small round indigo "+" quick-add button.
- **Chips & segmented controls**: 40px pill. Unselected: Lila Tint fill, Midnight Navy text.
  Selected: Indigo Accent fill, white Bold text (segmented control uses a sliding white thumb on a
  Lila Tint track with Indigo Ink label when used for Today / Week / Month).
- **Inputs**: White, 56px tall, 16px radius, 1px Hairline border, Navy Soft placeholder; focus ring
  2px Indigo Accent. Labels above the field.
- **Bottom navigation**: White bar with a top hairline, four items (My Baby, Ask Meow, Learn,
  Profile) with rounded line icons. Active item sits in a Lila Tint pill with an Indigo icon and
  Indigo Ink label; inactive items are Navy Soft.
- **Bottom sheets**: White, 32px top radius, drag handle in Hairline, header with activity icon
  tile and title, sticky Save button at the bottom.
- **AI insight / tip card**: Mint Tint fill, small sparkle icon in indigo, title in Midnight Navy.

## 5. Layout Principles

- Mobile first, 390px wide frames, 20px side margins, 12px gutters, 4px/8px spacing grid.
- 24–32px between major sections; 48×48px minimum touch targets; primary actions in the bottom
  third (thumb zone).
- Depth comes from tonal layering (Slate canvas → White cards → Lila/Mint tints). Shadows only on
  floating elements (bottom sheets, FAB, bottom bar): `0 8px 24px rgba(30,27,75,0.08)`.

## 6. Design System Notes for Stitch Generation

- **Atmosphere keywords**: dreamy lavender, calm slate canvas, pillow-white rounded cards, single
  soft indigo accent, gentle lilac and mint tints, calm modern trustworthy baby app, rounded line
  icons.
- **Canonical colours**: Indigo Accent `#818CF8`, Lullaby Lila `#C084FC`, Mint `#A7F3D0`, Calm
  Slate `#F5F7FB`, Midnight Navy `#1E1B4B`; tints Lila Tint `#F3E8FF`, Mint Tint `#E6FAF1`; text
  accents Indigo Ink `#5558D9`, Navy Soft `#5E5C7E`.
- **Never** introduce red, orange, pink, yellow or brown; never use rainbow per-activity colours.
- **Component prompts**: "56px indigo pill button with white bold label"; "2-column grid of
  activity tiles alternating lila tint and mint tint, white squircle icon holder with indigo line
  icon"; "white 24px-radius card with 1px slate hairline".
