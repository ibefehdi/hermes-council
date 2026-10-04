---
name: i18n-rtl
description: Applies internationalization and right-to-left conventions to the spa/salon SaaS frontend (English + Arabic). Covers Lingui message catalogs and ICU pluralization, RTL rules with logical CSS properties, mirrored icons, and Intl formatting of currency (KWD 3 decimals), dates, and times per branch time zone. Use when adding user-facing text, plurals, formatters, layout rules, or Arabic/RTL fixes in apps/* or packages/i18n.
---

# i18n and RTL conventions

## Quick start / rules

1. User-facing text goes through Lingui macros — never hardcode strings, never concatenate translated fragments:

```tsx
import { Trans, Plural } from '@lingui/macro'

<Trans>Book new appointment</Trans>
<Plural value={count} one="1 client" other="# clients" />  // ICU: use zero/two/few/many when Arabic needs them
```

2. Keys: Lingui auto-generates ids from source text; explicit `id` only for stable programmatic references. Catalogs: `packages/i18n/locales/{en,ar}/messages.po`. After adding messages run `pnpm i18n:extract && pnpm i18n:compile`.
3. Locale handling: `<I18nProvider>` sets `document.documentElement.lang` and `dir` from the user's preference. Full sentences with interpolation — translators must be able to reorder words:

```tsx
<Trans>Booking for {clientName} starts at {time}</Trans>  // ✅
<>{'Booking for'} {name}</>                                 // ❌ fragments
```

4. Formatting: components never call `toLocaleString` inline. Use `useFormat()` from `@repo/i18n`:

```ts
const { money, date, time, dateTime, relative } = useFormat()
money(12500)                 // KWD 12.500  /  د.ك ١٢٫٥٠٠  (amount in fils)
dateTime(booking.startsAt)   // branch time zone, per-branch
relative(booking.startsAt)   // "in 2 hours" via Intl.RelativeTimeFormat
```

5. Money: integers in fils everywhere (state, cache, DB); only `money()` formats. KWD uses 3 decimals (`minimumFractionDigits: 3, maximumFractionDigits: 3`); tenant currency is data, not code.
6. Time zones: wire format is UTC (`timestamptz`); rendering uses the **branch's** time zone (`branch.iana_tz`, default `Asia/Kuwait`) via `Intl.DateTimeFormat({ timeZone })`. Date inputs and pickers operate in branch-local time; conversion via `@repo/core` pure functions. Show the tz label near timestamps when ambiguity is possible.
7. RTL layout: logical CSS properties only — `margin-inline-start`, `padding-inline-end`, `inset-inline-start`, `text-align: start`. `left`/`right` physical properties are lint errors (stylelint rule in the repo). Flexbox/grid flow with `dir`; rare exceptions use `:dir(rtl)`.
8. Icons: directional icons (arrows, chevrons, back) mirror under `[dir='rtl']` (`scaleX(-1)` or auto-flipping SVG); non-directional icons never mirror. Test each new directional icon in `ar`.
9. Any date math near DST or midnight boundaries must be covered by a Vitest case using `Intl` with the branch tz — no manual hour arithmetic.
10. Both locales are release-blocking: Playwright runs critical journeys in `en`/LTR and `ar`/RTL; a missing Arabic message fails CI (`lingui extract` diff check).

## Examples

Arabic-aware plural (ICU handles Arabic's six plural categories automatically via `Intl.PluralRules`):

```tsx
import { Plural } from '@lingui/macro'

<Plural
  value={results}
  zero="No results"
  one="One result"
  two="# results"      // Arabic: صفر / واحد / اثنان categories exist; provide all used categories
  few="# results"
  many="# results"
  other="# results"
/>
```

Branch-time-zone listing:

```ts
// bookings arrive as UTC ISO strings; render in the selected branch's tz
const { dateTime } = useFormat()
const branchTz = useBranch().ianaTz
rows.map(b => <td>{dateTime(b.startsAt, { timeZone: branchTz })}</td>)
```

RTL-safe spacing:

```css
/* ✅ */ .drawer { padding-inline-start: 24px; }
/* ❌ */ .drawer { padding-left: 24px; }
```

## Additional resources

- [reference.md](reference.md): catalog workflow commands, formatter signatures, RTL icon checklist, schedule-x Arabic locale setup.
