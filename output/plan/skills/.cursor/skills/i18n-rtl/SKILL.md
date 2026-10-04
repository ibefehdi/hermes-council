---
name: i18n-rtl
description: Applies internationalization and right-to-left conventions to the spa/salon SaaS frontend (English + Arabic). Covers Lingui message catalogs and ICU pluralization, RTL rules with logical CSS properties, mirrored icons, Intl formatting of money (integer minor units, KWD 3 decimals) and dates per branch time zone, and Arabic search normalization. Use when adding user-facing text, plurals, formatters, layout rules, searchable text, or Arabic/RTL fixes in apps/* or packages/i18n.
---

# i18n and RTL conventions

EN + AR with full RTL is a release gate for every user-facing change (ADR-40, NFR-7, US-SEC-1).

## Quick start / rules

1. User-facing text goes through Lingui macros - never hardcode strings, never concatenate translated fragments:

```tsx
import { Trans, Plural } from '@lingui/macro'

<Trans>Book new appointment</Trans>
<Plural
  value={count}
  zero="No clients"
  one="1 client"
  two="# clients"
  few="# clients"
  many="# clients"
  other="# clients"
/>  // every Arabic category the message needs - the quick-start example matches the reference
```

2. Keys: Lingui auto-generates ids from source text; explicit dotted `id` (`booking.conflict.title`) only for stable programmatic references. Catalogs: `packages/i18n/locales/{en,ar}/messages.po`. After adding messages run `pnpm i18n:extract && pnpm i18n:compile`; missing Arabic entries fail CI.
3. Locale handling: `<I18nProvider>` sets `document.documentElement.lang` and `dir` from the persisted user preference. Full sentences with interpolation - translators must be able to reorder:

```tsx
<Trans>Booking for {clientName} starts at {time}</Trans>   // yes
<>{'Booking for'} {name}</>                                 // no - fragments
```

4. Formatting: components never call `toLocaleString` inline. Use `useFormat()` from `@repo/i18n`:

```ts
const { money, date, time, dateTime, relative } = useFormat()
money(12500)                 // KWD 12.500  /  د.ك ١٢٫٥٠٠   (argument is integer minor units)
dateTime(appointment.effective_start)  // branch time zone
relative(appointment.effective_start)  // "in 2 hours"
```

5. Money: integer minor units (fils) everywhere in code; only `money()` formats, with fraction digits from the tenant currency's exponent in the `currencies` table (KWD = 3). Never floats, never string-decimal arithmetic (ADR-17).
6. Time zones: wire format is UTC (`timestamptz`); rendering uses the **branch's** IANA zone (`branch.timezone`, default `Asia/Kuwait`). Date pickers operate in branch-local time; conversion via `@repo/core` pure functions (tested for overnight and DST cases); show the zone label near timestamps where ambiguity is possible. Report day boundaries are computed in SQL with the branch zone (ADR-21) - never in the browser.
7. RTL layout: logical CSS properties only - `margin-inline-start`, `padding-inline-end`, `inset-inline-start`, `text-align: start`. Physical `left`/`right` properties are stylelint errors. Flexbox/grid flow with `dir`; rare exceptions use `:dir(rtl)` and a PR note.
8. Icons: directional icons (arrows, chevrons, back) mirror under `[dir='rtl']` via `@repo/ui` auto-flipping primitives (`flipOnRtl`); non-directional icons never mirror. Test each new directional icon in `ar`.
9. Bilingual data: operator-facing entities have `name_en`/`name_ar` (ADR-16); display falls back `name_ar → name_en` for AR users and the reverse for EN users; never show an empty label when a fallback exists.
10. Arabic search: user input passes `normalizeSearch()` from `@repo/i18n` before querying; searchable tables have a normalized `search_text` column (diacritics stripped, alef/ya/ta-marbuta unified, digits unified) - the same normalization on both sides (ADR-40). EN and AR input both match (US-CL-6).
11. Date math near DST or midnight boundaries requires a Vitest case using `Intl` with the branch zone - no manual hour arithmetic.
12. Both locales are release-blocking: Playwright runs critical journeys in `en`/LTR and `ar`/RTL.
13. Mixed-direction text (round 2, F-i18n-1): wrap embedded LTR runs inside RTL copy - phone numbers, emails, Latin handles inside Arabic names - in `<bdi>` (or `dir="auto"` with `unicode-bidi: isolate` in CSS) so they do not reorder the surrounding line. Receipts, client lists, and appointment cards carry a Vitest/RTL-screenshot case with an Arabic name plus a Western phone number.
14. Calendar/shift-grid locale (round 2, F-cov-7): week start and 12/24-hour rendering come from the branch's `first_day_of_week`/`time_format` settings (ADR-52; Gulf default Saturday, 24h) - never hardcode a week start or rely on the `Intl` default.

## Examples

Arabic-aware plural (ICU covers Arabic's six categories via `Intl.PluralRules`):

```tsx
<Plural
  value={results}
  zero="No results"
  one="One result"
  two="# results"
  few="# results"
  many="# results"
  other="# results"
/>
```

Branch-time-zone listing:

```ts
const { dateTime } = useFormat()
const branchTz = useBranch().timezone
rows.map(a => <td>{dateTime(a.effective_start, { timeZone: branchTz })}</td>)
```

RTL-safe spacing:

```css
/* yes */ .drawer { padding-inline-start: 24px; }
/* no  */ .drawer { padding-left: 24px; }
```

## Additional resources

- [reference.md](reference.md): catalog workflow commands, formatter signatures, Arabic plural categories, RTL icon checklist, calendar locale setup, stylelint enforcement.
