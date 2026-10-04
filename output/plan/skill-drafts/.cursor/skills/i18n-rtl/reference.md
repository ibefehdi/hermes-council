# i18n-rtl reference

## Catalog workflow

```bash
pnpm i18n:extract    # lingui extract — merges new messages into locales/{en,ar}/messages.po, marks removed obsolete
pnpm i18n:compile    # lingui compile — build-time ICU compile, no runtime parser shipped (~4 kB core)
pnpm i18n:check      # CI: fails if en/ar are out of sync (missing or untranslated-while-en-has entries)
```

Catalogs live in `packages/i18n/locales/`. PO format; translators edit the `ar` catalog directly. Keep interpolations `{name}` untouched; never reorder placeholders manually — ICU reorders at runtime.

## Formatter signatures (`useFormat()` from `@repo/i18n`)

```ts
money(fils: number, currency?: string): string
// Intl.NumberFormat, style currency, 3 fraction digits for KWD (tenant currency data-driven)

date(iso: string, opts?: Intl.DateTimeFormatOptions): string       // branch tz by default
time(iso: string, opts?: Intl.DateTimeFormatOptions): string
dateTime(iso: string, opts?: Intl.DateTimeFormatOptions): string    // opts.timeZone defaults to branch.iana_tz
relative(iso: string): string                                       // Intl.RelativeTimeFormat
```

Branch tz comes from the selected branch record (`iana_tz`, default `Asia/Kuwait`); pass explicit `timeZone` when rendering another branch's data. All wire timestamps are UTC ISO/timestamptz.

## Arabic plural categories

ICU/`Intl.PluralRules` provides `zero, one, two, few, many, other` for `ar`. Provide every category the message needs — omitting `zero`/`two` is the most common Arabic bug. Prefer moving the plural to the top of a sentence so translators see the phrase whole.

## RTL icon checklist

- Mirrored under `[dir='rtl']`: back/forward arrows, chevrons, next/previous pagination, "open drawer" chevron, undo, indentation.
- Never mirrored: clocks, calendars, gear/settings, avatars, media controls (play), logos, currency glyphs.
- Implementation: auto-flipping SVG components in `@repo/ui` take `flipOnRtl` prop — do not hand-write `scaleX(-1)` in feature code.

## schedule-x Arabic locale

Register the Arabic locale pack from `@schedule-x/translations` next to our Lingui provider in `features/calendar` (see https://schedule-x.dev for locale list); the calendar header (Today, prev/next labels) uses it, while event/appointment copy goes through our Lingui catalogs. Verify the resource scheduler's column order and time axis mirror correctly in `ar` — column mirroring follows `dir` on the wrapper element.

## Stylelint enforcement

`declaration-property-value-disallowed-list` blocks `margin-left|margin-right|padding-left|padding-right|left|right` (except inside `@media` overrides or explicitly reviewed physical-position cases documented in PR description). Use `inset-inline-start/end`, `margin-inline`, `padding-inline`, `text-align: start`.
