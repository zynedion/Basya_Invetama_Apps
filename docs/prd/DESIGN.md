---
name: Modern Gotong Royong
colors:
  surface: '#f7f9ff'
  surface-dim: '#c2ddfb'
  surface-bright: '#f7f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#edf4ff'
  surface-container: '#e3efff'
  surface-container-high: '#d9eaff'
  surface-container-highest: '#cfe5ff'
  on-surface: '#001d34'
  on-surface-variant: '#3d4948'
  inverse-surface: '#17324a'
  inverse-on-surface: '#e8f1ff'
  outline: '#6d7a78'
  outline-variant: '#bcc9c8'
  surface-tint: '#006a66'
  primary: '#006a66'
  on-primary: '#ffffff'
  primary-container: '#08a39e'
  on-primary-container: '#00312f'
  inverse-primary: '#5fd9d3'
  secondary: '#006c4b'
  on-secondary: '#ffffff'
  secondary-container: '#7cfac3'
  on-secondary-container: '#007350'
  tertiary: '#006c49'
  on-tertiary: '#ffffff'
  tertiary-container: '#00a773'
  on-tertiary-container: '#003320'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#7ef6ef'
  primary-fixed-dim: '#5fd9d3'
  on-primary-fixed: '#00201f'
  on-primary-fixed-variant: '#00504d'
  secondary-fixed: '#7cfac3'
  secondary-fixed-dim: '#5edda8'
  on-secondary-fixed: '#002114'
  on-secondary-fixed-variant: '#005138'
  tertiary-fixed: '#6ffbbe'
  tertiary-fixed-dim: '#4edea3'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005236'
  background: '#f7f9ff'
  on-background: '#001d34'
  surface-variant: '#cfe5ff'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.03em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.01em
  title-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 26px
  title-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  title-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 13px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  caption:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  space-2xs: 0.25rem
  space-xs: 0.5rem
  space-sm: 0.75rem
  space-md: 1rem
  space-lg: 1.25rem
  space-xl: 1.5rem
  space-2xl: 2rem
  space-3xl: 2.5rem
  screen-edge-padding: 1rem
  card-gutter: 0.75rem
  bottom-nav-height: 4.5rem
---

## Brand & Style

This design system establishes a confident, trustworthy, and digitally native aesthetic for a modern Indonesian mobile cooperative (koperasi simpanan dan investasi). By fusing contemporary fintech clarity with the communal spirit of *gotong royong*, the interface transforms traditional cooperative finance into an approachable, institutional-grade wealth engine.

The design movement merges **Modern Clean Fintech** with tactile **Atmospheric Glass and Gradient Accents**. The interface relies on generous spatial breathing room, luminous teal-to-mint energy gradients, crisp micro-borders, and disciplined typography. The resulting experience feels secure, modern, and optimistic—removing bureaucracy while elevating collective financial progress.

## Colors

The palette leverages a signature sea-teal to luminous mint gradient, symbolizing prosperous growth, stability, and digital clarity. 

- **Primary Brand Tier**: `#08A39E` anchors key interactive touchpoints, primary buttons, and navigational focus. Supported by `#19B3A1` (interactive hover/active) and `#4BD0A7`.
- **Signature Gradient**: Linear progression from `#5FDEA9` to `#08A39E` (135° angle), reserved for primary balance hero cards, key milestone achievements, and high-impact actions.
- **Canvas & Structure**: Base canvas `#F5F7F9` delivers clean contrast against elevated pure white `#FFFFFF` cards. Structural hairline borders use `#E2E8F0`.
- **Text & Contrast Hierarchy**: Primary dark navy text `#17324A` guarantees WCAG AAA legibility. Secondary operational text uses `#5F6B76`, and subdued metadata uses `#94A3B8`.
- **Financial Directionals**: Yield/gain/incoming transfers use `#10B981` paired with a soft `#ECFDF5` badge tint. Expense/withdrawal/risk indicators use `#EF4444` paired with `#FEF2F2`.

## Typography

Typography relies on **Plus Jakarta Sans** across all roles to project a refined, modern geometric feel with high vertical legibility.

- **Monetary Hierarchy**: Total asset values and primary card balances utilize `headline-xl` (36px) or `headline-lg` (28px) with tabular figures (`font-variant-numeric: tabular-nums`) to prevent horizontal jitter during dynamic value counters. Currency symbols (`Rp`) are set slightly lighter or smaller to maintain visual focus on the numeric equity.
- **Section Titles**: Level titles leverage `title-md` (18px) and `title-lg` (20px) in semibold (600), creating scannable card groups on dense mobile viewports.
- **Body & Captions**: Operational text uses `body-md` (14px) and `body-sm` (13px) in `#5F6B76` for descriptions, terms, and auxiliary information, ensuring high legibility in mobile environments under direct sunlight.

## Layout & Spacing

The layout is built specifically for **mobile portrait touch interactions**, adhering to an 8pt base grid system:

- **Mobile Viewport Boundaries**: Default horizontal edge inset is fixed at `16px` (`space-md`), expanding to `20px` (`space-lg`) on devices exceeding 400px width.
- **Vertical Hierarchy**: Components within a single functional group stack with `12px` (`space-sm`) gaps. Unrelated section modules separate with `24px` (`space-xl`) to `32px` (`space-2xl`) intervals.
- **Thumb Zone Anchoring**: Crucial primary actions and the 5-destination bottom navigation bar sit within the bottom 25% of the screen. Safe area padding accounts for modern iOS home indicators and Android navigation gestures.

## Elevation & Depth

Visual hierarchy uses clean **tonal layering** alongside **ambient, tinted drop shadows** rather than harsh, opaque drop shadows:

- **Level 0 (Base Canvas)**: `#F5F7F9` background, zero elevation.
- **Level 1 (Standard Surface / Cards)**: Pure `#FFFFFF` surface with a `1px` structural outline in `#E2E8F0` and an ambient shadow: `0 4px 16px -2px rgba(23, 50, 74, 0.04), 0 2px 6px -1px rgba(23, 50, 74, 0.02)`.
- **Level 2 (Active Cards & Floating Modules)**: `#FFFFFF` surface with `0 8px 24px -4px rgba(8, 163, 158, 0.08), 0 4px 12px -2px rgba(23, 50, 74, 0.04)`.
- **Level 3 (Signature Gradient Cards)**: Gradient surface (`#5FDEA9` to `#08A39E`) with a soft glow shadow: `0 12px 28px -6px rgba(8, 163, 158, 0.30)`.
- **Level 4 (Bottom Navigation Bar & Modals)**: Frosted backdrop surface (`rgba(255, 255, 255, 0.94)` with `backdrop-filter: blur(12px)`) with top border `1px solid rgba(226, 232, 240, 0.8)` and directional shadow: `0 -4px 20px rgba(23, 50, 74, 0.05)`.

## Shapes

The interface embraces a friendly yet architectural roundedness:

- **Primary Cards & Containers**: Feature `rounded-2xl` (`16px`), creating comfortable bounding boxes that cushion complex monetary tables.
- **Buttons & Form Fields**: Standard inputs and full-width CTAs feature `12px` border-radii, balancing structure and clickability.
- **Tags, Directional Badges, & Action Pills**: Fully circular/pill geometry (`9999px`) for quick-scan attributes and tags.
- **Quick Action Icons**: Pure circular frames (`50%` radius) measuring `48px` to `56px` in diameter, providing consistent landing targets.

## Components

### Hero Investment & Savings Card
- **Surface**: Signature gradient (`#5FDEA9` to `#08A39E`) at a 135° diagonal angle with `rounded-2xl` corners.
- **Typography**: Label "Total Simpanan & Investasi" in white with 80% opacity, headline balance in bold 32px white with tabular numerals, Rupiah prefix at 20px.
- **Sub-metrics**: Yield percentage pill (`+8.4% p.a.`) featuring a white translucent background (`rgba(255,255,255,0.2)`) and crisp white text.

### Quick Action Circular Icon Buttons
- Row of 4–5 circular actions (e.g., "Setor", "Tarik", "Transfer", "Katalog Unit").
- Circular container `52px` diameter, surfaced in `#ECFDF5` or pure `#FFFFFF` with `#E2E8F0` hairline border.
- Icon rendered in `#08A39E` (24px size), accompanied below by a single-line label in `caption` weight in `#17324A`.

### Transaction & Portfolio List Items
- Container: Borderless white row with bottom separator `1px solid #F1F5F9`.
- Leading slot: 40px rounded-xl squircle container housing categorical icons with soft contextual tints.
- Title & Subtitle: Transaction counterparty or fund name in `title-sm` (`#17324A`), date & time in `body-sm` (`#5F6B76`).
- Trailing Cash & Direction Badge: 
  - Inflow / Dividends: `+ Rp 1.250.000` in `#10B981`, optional pill badge showing `+ Masuk`.
  - Outflow / Installments: `- Rp 450.000` in `#EF4444`, optional pill badge showing `- Keluar`.

### Investment Sparkline Indicators
- Embedded miniature vector charts inside portfolio summary cards.
- Line stroke: 2px in `#10B981` (upward) or `#EF4444` (downward) accompanied by a subtle 10% opacity vertical linear gradient fill below the curve.
- No axis grids; inline performance percentage label right-aligned.

### Buttons & Input Fields
- **Primary Button**: Solid `#08A39E` fill, `#FFFFFF` text, `title-sm` (16px semibold), height `48px`, `rounded-xl`. Pressed state shifts to `#19B3A1`.
- **Secondary Button**: Crisp `#FFFFFF` background, `1.5px solid #08A39E`, text in `#08A39E`.
- **Currency Input**: Large interactive field with static `Rp` prefix in `#5F6B76` (24px) and input text in `#17324A` (32px bold), underlaid by a 2px active border in `#08A39E`.

### Bottom Navigation Bar
- Fixed at the bottom of the mobile viewport, height `72px` + safe-area bottom inset.
- Five equidistant items: **Beranda**, **Investasi**, **Transaksi**, **Multiguna**, and **Profil**.
- Active State: Icon and label in `#08A39E` with a subtle 4px mint dot indicator beneath. Inactive State: `#94A3B8` icon and typography.