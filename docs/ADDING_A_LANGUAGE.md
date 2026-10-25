# Adding a language

`AppLang` (`lib/core/l10n/app_lang.dart`) is the one language registry. The
supported locales, the language menu in the top bar and the Settings switch
are all built from it, so a new language shows up everywhere once it is listed
there. `test/languages_test.dart` fails until the required pieces exist.

## Required

1. **Registry** – add an entry to `AppLang`, e.g. `tr('tr', 'Türkçe')`.
   Right-to-left languages pass `rtl: true` (layout, PDF and legal pages
   follow it).
2. **Strings** – copy `lib/l10n/app_en.arb` to `lib/l10n/app_<code>.arb`,
   set `"@@locale": "<code>"` and translate every value. Keep the
   placeholders (`{amount}`, `{name}` …) exactly as in English. Run
   `flutter gen-l10n` (or any `flutter` build/test, which runs it).
3. **`pick`** – add an optional named parameter for the new code to
   `AppLang.pick` and a case to its `switch`, falling back to `en`.
4. Run `flutter analyze` and `flutter test`.

## Ready but not yet offered

Pass `hidden: true` to the `AppLang` entry (as German, Portuguese, Italian, Dutch, Bosnian, Albanian, Russian, Swahili, Hausa, Afrikaans, Persian, Hindi, Chinese, Japanese and Korean are): the language is
built and tested but stays out of the menus, Settings and the supported
locales, so a phone in that language gets the default. Preview it with
`--dart-define=NEW_LANGS=true`; remove `hidden: true` to release it.

## Optional content (falls back to English when missing)

Pass the new code to the existing `lang.pick(...)` calls:

| Content | File |
| --- | --- |
| Category labels | `lib/features/transactions/domain/categories.dart` (`_<code>` map) |
| Month names | `lib/core/l10n/month_names.dart` |
| Hijri month names | `lib/features/zakat/domain/hijri_date.dart` |
| Quarter / period labels | `lib/features/reports/presentation/reports_page.dart`, `export_pdf_button.dart` |
| In-app guide | `lib/features/guide/domain/guide_content.dart` (`_start<Code>`, `_topics<Code>`) |
| Privacy & terms | `lib/features/legal/domain/legal_content.dart` (`_privacy<Code>`, `_terms<Code>`, `_reach<Code>`) – section counts must match English |
| Quick-entry words | `lib/features/quick_entry/domain/quick_entry_parser.dart` (amount multipliers, date words, category keywords) |
| Biometric prompt | `lib/features/app_lock/data/device_auth_io.dart` |
| Legal web pages | `tool/export_legal.dart` (one `<article>` per language) |
| Password e-mail | `supabase/templates/recovery.html` (then paste it into the Supabase dashboard) |
| AI assistant | `supabase/functions/_shared/ai/gateway.ts` reply-language hint |

## Website (dgotix-site)

Add `data-<code>` text to the translated spans, an `<option>` in
`<select id="lang">`, and the language to the maps in `site.js`.

## Currency for a new market

If the language opens a new market, add its currency to
`lib/core/money/currency.dart` (`Currencies.all`), a flag at
`assets/flags/<country>.png` (96×72), an indicative rate in
`rates_controller.dart` (`_seed`) and a row in the `currencies` catalog of
`supabase/schema.sql` and `supabase/setup_all.sql` (the test checks this).

## Notes

- Fonts: Tajawal covers Arabic and most Latin languages. Check the new
  language's letters against `assets/fonts/Tajawal-Regular.ttf`. Missing
  Latin letters fall back to Inter (`SbInter`, as for Turkish ğ ş İ); a
  script Tajawal lacks needs its own family, chosen per language in
  `DsTypography.textTheme` and in the PDF export (as Urdu uses Noto Naskh
  Arabic, `SbNaskh`).
- Upper-case labels go through `AppLang.upper` (Turkish i → İ).
- French uses a narrow no-break space (U+202F) before `; : ! ? »`.
- Do not run `dart format` on whole files; it rewrites unrelated lines.
