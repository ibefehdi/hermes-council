---
name: airbnb-design
description: Visual design system for the spa/salon SaaS frontend, based on Airbnb's design language (white canvas, Rausch red accent, near-black ink, soft radii, single shadow tier) and adapted for an English/Arabic RTL back-office app, with light and dark themes. Use when building or styling any screen, component, layout, form, table, calendar, dialog or design token, when editing packages/ui or tokens.css, when working on dark mode or the theme switcher, or when choosing colours, fonts, spacing, radii, shadows, states or motion.
---

# Airbnb design system (adapted for the spa SaaS)

All visual decisions live here. `react-frontend` and `i18n-rtl` define structure, data and language; this skill defines how things look. Only `packages/ui` imports tokens; feature code uses `packages/ui` components.

- Tokens as CSS variables: [tokens.css](tokens.css) (copy into `packages/ui/src/tokens.css`).
- Full source design analysis: [reference.md](reference.md) (Airbnb DESIGN.md from VoltAgent/awesome-design-md, MIT). Use it for component details not covered below.

## Core look

- Pure white canvas (`--color-canvas` #ffffff), near-black ink text (`--color-ink` #222222, never pure black). Dark theme inverts this to a near-black canvas and near-white ink (see Dark mode); everything else in this skill applies to both themes.
- One accent: Rausch (`--color-primary` #ff385c). Use it sparingly, for the primary action on a screen, the selected state, and brand moments. At most two Rausch elements visible at once; neutralise the rest.
- Soft shapes: buttons and inputs 8px radius, cards and dialogs 14px, pills and avatars fully rounded, no hard corners on interactive elements.
- Flat by default. One shadow (`--shadow-float`) for dropdowns, popovers, floating cards and the sticky booking panel; a 50% black scrim behind modals. No other elevation tiers.
- Modest type weights: 400 body, 500 UI labels and buttons, 600 titles, 700 only for page titles and big numbers (for example the day's revenue).

## Colour rules

| Token | Light | Dark | Use |
|---|---|---|---|
| `--color-primary` | #ff385c | #ff385c | Accent: icons, selected indicators, focus ring, large CTA text (see contrast rule) |
| `--color-primary-strong` | #e00b41 | #e00b41 | Fill of text-bearing primary buttons and pressed state (4.9:1 with white) |
| `--color-primary-disabled` | #ffd1da | #5a1f2c | Disabled primary fill |
| `--color-canvas` | #ffffff | #141414 | Page background, cards, inputs, secondary buttons |
| `--color-surface-raised` | #ffffff | #1c1c1c | Dialogs, popovers, dropdowns, sheets, floating cards |
| `--color-ink` | #222222 | #f2f2f2 | Headings, body, icons; fill of toasts and selected date cells |
| `--color-on-ink` | #ffffff | #141414 | Text and icons on an ink fill |
| `--color-body` | #3f3f3f | #d6d6d6 | Long-form text |
| `--color-muted` | #6a6a6a | #a3a3a3 | Secondary text, labels, inactive tabs (5.4:1 or better) |
| `--color-muted-soft` | #929292 | #7c7c7c | Disabled text and input outlines only (3:1 or better) |
| `--color-hairline` | #dddddd | #3a3a3a | Dividers, table rules, card borders (decorative only) |
| `--color-surface-soft` | #f7f7f7 | #242424 | Hover rows, filter bands, read-only fields, calendar off-hours |
| `--color-surface-strong` | #f2f2f2 | #2e2e2e | Icon-button fill, selected row |
| `--color-error` | #c13515 | #ff6b4a | Error text and outlines; destructive button fill |
| `--color-on-error` | #ffffff | #141414 | Text on a destructive button |

Contrast rules (WCAG 2.2 AA, checked):
- White text on `#ff385c` is 3.5:1, which fails for normal text. Primary buttons with text use `--color-primary-strong` as fill; `#ff385c` is fine for icons, indicators, large text (24px+, or 18.66px+ at 600) and non-text UI.
- Input and checkbox outlines must reach 3:1: use `--color-muted-soft` at rest, 2px `--color-ink` on focus. `--color-hairline` is for decoration only.
- Never put `--color-muted-soft` on running text.

Product extensions (not in Airbnb's palette; the app needs them for statuses). All pass 4.5:1 on every surface of their theme:

| Token | Light | Dark | Use |
|---|---|---|---|
| `--color-success` | #0b7a3e | #3ccf7e | Completed, paid, active |
| `--color-warning` | #a15c00 | #f0a33a | Pending, unpaid, expiring |
| `--color-info` | #1d5fd1 | #6ea0ff | Informational notices, links in dense tables |

Appointment statuses use a neutral pill (surface-strong fill, ink text) plus a coloured dot or icon, never colour alone: booked = muted, confirmed = info, arrived/in progress = primary, completed = success, no-show = error, cancelled = muted-soft with strikethrough text.

## Typography

- Airbnb Cereal is proprietary: never ship it. Latin: **Inter** (variable). Arabic: **IBM Plex Sans Arabic**. Stack in `--font-sans`; the browser picks the Arabic face for Arabic glyphs automatically.
- Scale (px / weight / line-height): page title 28/700/1.3; section title 22/600/1.25; card title 18/600/1.3; label and button 16/500/1.25; body 16/400/1.5; dense body (tables, calendar, card meta) 14/400/1.43; caption 13/400/1.4; badge 12/600/1.2. Nothing below 12px.
- Arabic: line-height +0.1 over the Latin value, letter-spacing always 0, no uppercase styling, no italics (use weight for emphasis).
- Numbers in tables, prices, times and the calendar use `font-variant-numeric: tabular-nums`. Money is formatted by `useFormat()` (KWD, 3 decimals); do not hand-format.

## Spacing, layout, radii

- 4px grid. Tokens: 2, 4, 8, 12, 16, 24, 32, 48, 64px (`--space-*`). No arbitrary values.
- This is a back-office app, not a marketplace: page padding 24px (16px on mobile), card padding 16 to 24px, gaps 8 to 16px. 64px section spacing only on marketing and booking-site pages.
- Breakpoints (from Airbnb): mobile < 744px, tablet 744 to 1127px, desktop 1128 to 1439px, wide >= 1440px. Reception tablets are first-class: every front-desk screen must work at 768 x 1024 in both orientations.
- Content max width 1440px; forms max 640px.
- Radii: `--radius-sm` 8px (buttons, inputs, chips), `--radius-md` 14px (cards, dialogs, sheets), `--radius-xl` 32px (large promo surfaces), `--radius-full` (pills, avatars, icon buttons).
- Full-height layouts use `100dvh`, never `100vh`. Fixed bars respect `env(safe-area-inset-*)`.

## RTL

- Logical properties only: `margin-inline-start`, `padding-inline-end`, `inset-inline-start`, `border-start-start-radius`, `text-align: start`. Never `left`/`right` in CSS or style props.
- Mirror directional icons (arrows, chevrons, back, undo/redo, send) with `[dir="rtl"] .icon-directional { transform: scaleX(-1); }`. Do not mirror clocks, checkmarks, media play, or logos.
- Calendar time runs top to bottom in both directions; staff columns follow reading direction (first column on the right in Arabic).
- Phone numbers, emails, codes and prices inside Arabic text are wrapped in `<bdi>` or `dir="ltr"` spans by the formatting helpers.

## Dark mode

Airbnb has no dark theme; this one is a product extension that keeps the same shapes, type, spacing and single accent and only swaps colour and shadow tokens.

- Three settings: **System** (default, follows `prefers-color-scheme`), **Light**, **Dark**. The choice sets `data-theme="light"` or `data-theme="dark"` on `<html>`; System removes the attribute. [tokens.css](tokens.css) handles all three, so components never branch on theme.
- Store the choice in `localStorage` under `theme` (`system` | `light` | `dark`). Apply it with an inline script in the `<head>` of `index.html`, before the app bundle, so the page never flashes the wrong theme, and add `<meta name="color-scheme" content="light dark">`:

  ```html
  <script>
    try {
      const t = localStorage.getItem("theme");
      if (t === "light" || t === "dark") document.documentElement.dataset.theme = t;
    } catch {}
  </script>
  ```
- The switcher lives in the user menu as a three-option segmented control with translated labels (en and ar). It changes only the current device; it is not a tenant setting.
- Canvas is near-black (#141414), never pure black; ink is near-white (#f2f2f2), never pure white.
- Depth comes from lighter surfaces, not shadows: anything floating (dialog, popover, dropdown, sheet, floating card) uses `--color-surface-raised` plus `--shadow-float`, which in dark adds a faint 1px light ring so edges stay visible. The scrim darkens to 70%.
- Rausch and `--color-primary-strong` are unchanged, so primary buttons look the same in both themes.
- Anything drawn as "ink fill" (toast, selected date, selected segmented option) uses `--color-on-ink` for its text, never a hard-coded white.
- Photos, logos and tenant-uploaded images are not inverted or filtered. Charts and the calendar take their colours from tokens, so they switch automatically.
- Every dark pair is contrast-checked: text tokens reach 4.5:1 on canvas, raised, soft and strong surfaces; `--color-muted-soft` reaches 3:1 on all of them; the Rausch contrast rule above applies unchanged.
- Printed receipts and PDFs always render in light, whatever the screen theme (the dark blocks in tokens.css are `@media screen` only).

## Components (packages/ui)

- **Button**: primary (`--color-primary-strong` fill, `--color-on-primary` 16/500 text, 48px height desktop, 44px dense, 8px radius, 12 x 24px padding); secondary (`--color-canvas` fill, 1px ink outline, ink text); tertiary (ink text, underline on hover); destructive (`--color-error` fill, `--color-on-error` text, always behind a confirm dialog); icon button (40px circle, `--color-surface-strong` fill, `aria-label` required).
- **Input / select / textarea**: `--color-canvas` fill, 1px `--color-muted-soft` outline, 8px radius, 48px height (56px with floating label), label above in 14/500 muted, focus = 2px ink outline, no glow. Error = `--color-error` outline plus message below the field, linked with `aria-describedby`.
- **Card**: `--color-canvas` fill, 1px hairline border, 14px radius, no shadow unless floating (then `--color-surface-raised` and `--shadow-float`).
- **Table**: 14px dense body, 48px rows (40px compact), hairline row dividers, `--color-surface-soft` hover, sticky header, numeric columns aligned to the end.
- **Dialog**: `--color-surface-raised` fill, 14px radius, `--shadow-float`, `--color-scrim` backdrop, max width 560px (forms) or 880px (detail), sheet from the bottom on mobile. Destructive or irreversible actions use an alert dialog naming what will happen.
- **Date picker**: 40px circular day cells; selected = ink fill with `--color-on-ink` text; range = surface-soft lozenge; today = 1px ink ring.
- **Calendar (schedule-x)**: theme through tokens only; appointment blocks use a 4px start-edge status bar on a canvas or surface-soft block, ink text, 8px radius; current-time line in `--color-primary`.
- **Tabs**: ink label with 2px ink underline when active, muted when inactive.
- **Toast**: ink background, `--color-on-ink` text, 8px radius, bottom-centre, auto-dismiss after 5s except errors.
- **Empty states**: one line of muted text, one primary action. No illustrations unless the owner supplies them.
- **Loading**: skeletons matching the final layout; no spinners for page loads.

## States and motion

- Focus: 2px `--color-primary` outline with 2px offset on every interactive element (inputs use the 2px ink outline instead). Never remove focus indicators.
- Hover: rows and list items `--color-surface-soft`; secondary buttons `--color-surface-soft`; floating cards gain `--shadow-float`.
- Disabled: `opacity: 0.5`, `cursor: not-allowed`, still readable.
- Motion only when it aids understanding (dialogs, sheets, toasts): 150 to 200ms, `ease-out`, animate `transform` and `opacity` only, and respect `prefers-reduced-motion`.
- Touch targets at least 44 x 44px.

## Tenant branding

Tenants may later brand their booking site and receipts. Branding overrides `--color-primary` and `--color-primary-strong` only, and a brand colour is accepted only if `--color-primary-strong` reaches 4.5:1 with white (compute it on save). The back-office keeps the default palette so support staff see one product.

## Checklist for any UI change

1. Uses `packages/ui` components and tokens; no raw hex, `white`/`black` keywords, px outside the scale, or inline styles.
2. Checked in English and Arabic (RTL) at mobile, tablet (768 x 1024) and desktop widths, in both light and dark themes.
3. Contrast rules above hold; status is never shown by colour alone.
4. Keyboard path works and focus is visible; icon-only buttons have labels.
5. Loading, empty and error states exist.
