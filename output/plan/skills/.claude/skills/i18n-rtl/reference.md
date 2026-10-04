# i18n-rtl reference

## Catalog workflow

```bash
pnpm i18n:extract    # lingui extract - merges new messages into locales/{en,ar}/messages.po, marks removed obsolete
pnpm i18n:compile    # lingui compile - build-time ICU compile, no runtime parser shipped (~4 kB core)
pnpm i18n:check      # CI: fails if en/ar are out of sync (missing or untranslated entries)
```

Catalogs live in `packages/i18n/locales/` (PO format); translators edit the `ar` catalog directly. Keep interpolations `{name}` untouched; never reorder placeholders manually - ICU reorders at runtime.

## Formatter signatures (`useFormat()` from `@repo/i18n`)

```ts
money(minorUnits: number, currency?: string): string
// Intl.NumberFormat, style currency; fraction digits from the currencies-table exponent (KWD = 3)

date(iso: string, opts?: Intl.DateTimeFormatOptions): string       // branch tz by default
time(iso: string, opts?: Intl.DateTimeFormatOptions): string
dateTime(iso: string, opts?: Intl.DateTimeFormatOptions): string    // opts.timeZone defaults to branch.timezone
relative(iso: string): string                                       // Intl.RelativeTimeFormat + Intl.PluralRules
```

Branch zone comes from the selected branch record (`timezone`, default `Asia/Kuwait`); pass an explicit `timeZone` when rendering another branch's data. All wire timestamps are UTC ISO/timestamptz.

## Search normalization (`normalizeSearch()` from `@repo/i18n`)

Applies to query input; the database applies the same rules in generated `search_text` columns:

- Strip Arabic diacritics (harakat, tanwin, shadda) and the tatweel.
- Unify alef forms (أ إ آ ا → ا), ya (ى → ي), ta marbuta (ة → ه).
- Unify Arabic-Indic and extended digits (٠-٩, ۰-۹ → 0-9).
- Lowercase Latin; collapse whitespace.

Covered by unit tests with fixture pairs (e.g. "أحمد" matches "احمد", "٩٦٥" matches "965").

## Arabic plural categories

ICU/`Intl.PluralRules` provides `zero, one, two, few, many, other` for `ar`. Provide every category the message needs - omitting `zero`/`two` is the most common Arabic bug. Prefer moving the plural to the top of a sentence so translators see the phrase whole.

## RTL icon checklist

- Mirrored under `[dir='rtl']`: back/forward arrows, chevrons, next/previous pagination, "open drawer" chevron, undo, indentation.
- Never mirrored: clocks, calendars, gear/settings, avatars, media controls (play), logos, currency glyphs, phone handsets.
- Implementation: auto-flipping SVG components in `@repo/ui` take a `flipOnRtl` prop - never hand-write `scaleX(-1)` in feature code.

## Calendar locale

Register the Arabic locale pack for the calendar library (schedule-x: `@schedule-x/translations`) next to our Lingui provider in `features/calendar`; library chrome (Today, prev/next) uses it, while appointment copy goes through our catalogs. Verify column order and the time axis mirror correctly in `ar` - mirroring follows `dir` on the wrapper element.

## Stylelint enforcement

`declaration-property-value-disallowed-list` blocks `margin-left|margin-right|padding-left|padding-right|left|right` (exceptions only inside reviewed physical-position cases documented in the PR). Use `inset-inline-start/end`, `margin-inline`, `padding-inline`, `text-align: start`.

## Receipts and print

Receipt templates render per the client's preferred language (fallback to branch default): branch name/address bilingual, invoice number, lines with service names from the item's bilingual snapshot, totals via `money()`. Print CSS is tested in both directions (RTL print layouts flip margins and alignment).
