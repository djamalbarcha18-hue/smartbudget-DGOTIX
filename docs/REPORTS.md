# Reports (PDF)

Four reporting periods — monthly, quarterly, half-yearly and yearly. The PDF
is built on the device from data already there; nothing is sent anywhere to
make one.

## What is free and what is PRO

| | Free | PRO |
|---|---|---|
| The document, with every section below | this month and last | every period |
| Quarter, half-year, year | — | ✅ |
| The written analysis | — | ✅ |

A report you cannot take with you is not a report, so the export itself is
everyone's (`Feature.reportPdf`, free). What PRO sells is the longer periods
— the screen already forces a free plan to the current or previous month
through `Feature.advancedReports` — and the analysis, which is gated on the
same feature plus an assistant request to spend.

## What the page holds

Each section appears only when the account has something to put in it; a
panel of zeroes tells the reader nothing.

| | |
|---|---|
| Header | the DGOTIX logo, drawn from `assets/brand/dgotix-logo.svg` as vector, with the wordmark set in type as the fallback if the asset cannot be read |
| Four headline figures | income, expenses, left over, savings rate |
| The written analysis | PRO, and only when asked for |
| Against the period before | the four figures, this period and last, with the move — in points for the savings rate, because a rate moving 11.3% → 26.0% rose by 14.7 points, not by 130% |
| Budget · Debts · Health | planned/spent/left with a meter, the debt balances, the health score out of 100 |
| The year | twelve months as grouped columns — **green income, red expenses, blue left over**, with the three words under the title saying which is which |
| Largest categories | the five biggest expenses as proportional bars, red, following the same rule |
| Income and expenses | the full tables |

Everything is computed by `ReportFigures` and turned into the page by
`ReportDocument` — neither touches Flutter or the network, so the whole
document is built in tests for all twenty-three languages
(`test/report_pdf_languages_test.dart`, `test/report_document_test.dart`).

### The three colours

Green is income, red is expenses, blue is what is left over, everywhere on
the page. A month that spent more than it took in has no upward bar to draw,
so its left-over bar hangs **below the line** instead of vanishing — all
three bars share one scale, so the heights can be read against each other.

Colour is never the only carrier: the legend names each one in the report's
own language, and every figure is also in the tables for a reader printing
in black and white.

The budget meter keeps blue, turning red only when the plan is overspent —
there it is a progress bar with a warning state, not a breakdown of money.

### Drawn, not charted

The bars are drawn from rows and containers rather than the library's chart
widgets, which place their own axes and do not mirror for a right-to-left
page. The library does mirror a row, so one list gives January at the right
in Arabic and at the left in English, with no special case and no reversing
(reversing it ourselves flipped it back — that bug is why this note exists).

### The comparison crosses the year

January's previous period is last December, Q1's is Q4, the first half's is
the second half of the year before. `ReportRange.previous` carries its own
year for exactly this, and the figures are built from every transaction the
account has rather than the selected year's, so the comparison does not
quietly vanish each January.

A move too small to print is not a direction: anything that would round to
0.0 is shown as flat and uncoloured, so a month that gained 0.004 points
never reads "-0.0" in red.

## The written commentary

A PRO reader can ask DGOTIX AI to write the report's commentary. It is off by
default and switched on per export, because it spends one of the account's
assistant requests.

### The register

An analyst's note, not prose. Two sentences and three steps, no more:

| | |
|---|---|
| Reading | two sentences, each carrying a ratio or an amount and naming its category |
| Next | exactly three steps, one line each, under twelve words, each with a target figure and what it frees |
| Length | 80 words at most |

Motivation comes from arithmetic — the figure the next period could reach and
what it is worth — not from praise. Congratulating, scolding and any
encouragement without a number are ruled out, as are metaphor, imagery,
adjectives of mood and narrative.

Two things make that hold rather than hope it does:

- **The shares are computed here, not by the model.** The brief carries the
  expense ratio and every category's share of its side, already worked out.
  A language model is a poor calculator, and a commentary that disagrees with
  the table beside it is worse than no commentary. These are derived from the
  figures the report already prints — nothing new leaves the device.
- **Length is enforced, not requested.** A word cap in a prompt is a request.
  `clean()` keeps the first `kInsightMaxLines` (6) lines and drops the rest,
  so an overrun loses whole lines and never a half sentence.

### What leaves the device

Only the figures the report already prints: the four totals and the biggest
eight category lines. **No transaction, note, merchant, date, wallet or
account.** That is enforced by shape — `ReportInsight.brief` takes the
computed summary and the category totals, and neither file so much as imports
the transaction model. `test/report_insight_test.dart` fails if either ever
does.

### What it costs

At most one request per export, through the same gateway as everything else,
so the server's existing quota, daily limit and monthly cost ceiling apply
unchanged — there is no second allowance to keep in step. A page of figures
in, eighty words out: on the cheapest model in the registry that is a
fraction of a cent, and a PRO account's ceiling is $2 a month.

Often no request at all. `ReportInsightCache` keys an analysis by a digest of
exactly what the assistant was given — account, language, period and the
whole brief — so re-exporting the same report reads the text back from the
device and spends nothing. One new transaction, a changed budget or another
language changes the digest and a fresh analysis is written: a cached
sentence about figures that have moved would be worse than no sentence. The
twelve most recent are kept, on the device, in the app's own preferences.

### When it is not there

A refused request, an exhausted quota or no network all give null, and the
report is produced exactly as it is without one — same layout, no error, no
empty block. `ReportPdfData.hasInsight` requires both the heading and the
text, so a half-filled answer is treated as none.

## The letters Tajawal was missing

The `pdf` package shapes Arabic itself: rather than hand the font the letters
and let OpenType choose the joined shapes, it rewrites the text into Unicode's
Arabic Presentation Forms-B block (U+FE70-U+FEFF) and looks each form up in
the font's cmap.

Tajawal carries the initial, medial and final forms but **not the isolated
ones**. Where the package asked for an isolated form the lookup failed:

| should print | printed |
|---|---|
| شهري | شهر |
| سنوي | سنو |
| ربع سنوي | ربع سنو |
| أخرى | أخري |
| جاري | جار |

It hit any word whose last letter follows a non-joining letter (ا د ذ ر ز و),
**including all four report period names** and the category أخرى. Urdu and
Persian reports are set in Noto Naskh Arabic, whose cmap is complete, so they
were never affected; neither were the app's own screens, which use the system
shaper.

`tool/patch_arabic_pdf_fonts.py` adds the 36 missing mappings to the bundled
Tajawal Regular and Bold, each to the glyph of the letter it decomposes to —
what a complete font already does. It adds cmap entries and nothing else:
outlines, metrics, names, GSUB and GPOS come out byte for byte identical, and
each file grows by a few hundred bytes. Run it after replacing a font file
with a fresh download; `test/pdf_arabic_forms_test.dart` fails if it was not
run.

## The Arabic word gap

The `pdf` package shapes Arabic itself, and for some words it emits the
letters unshaped. Where it does, the space after the word collapses and two
words print as one:

| should print | printed |
|---|---|
| دار السلام | دارالسلام |
| الادخار والاستثمار | الادخاروالاستثمار |
| إيجار السكن | إيجارالسكن |

It only ever affected the PDF; the app's own screens were always correct. The
package is at its newest release (3.13.1) and still has it, so there was no
version to upgrade to.

### What was tried

| | |
|---|---|
| non-breaking space | no change |
| zero-width space | prints a missing-glyph box |
| ZWNJ | prints a missing-glyph box |
| **a second space** | **works** |

The two zero-width characters fail for the same reason: the bundled fonts
(Tajawal, Noto Naskh Arabic) have no glyph for them.

### What we do, and what it costs

`pdfSafe()` doubles every single space in text that contains Arabic-script
characters. Latin, Cyrillic and CJK reports are untouched.

The cost is that gaps between words the package sets correctly — most of them
— come out a little wide. That is a deliberate trade: an airy line is a
blemish, two words run together is an error.

### Why not only the words that need it

Three ways of telling them apart were tried and none was dependable:

- `pdftotext` reports a space that is not visible on the page;
- word bounding boxes split Persian and Urdu lines at the wrong places;
- comparing shaped widths with and without the spaces also compares different
  letter forms, so the difference is not only the space.

The only reliable judge was a rendered page read by eye, which cannot drive a
rule in code. Rather than ship a rule that is wrong in cases nobody checked,
every gap is widened. If a later version of the package fixes the shaping,
delete the second half of `pdfSafe` and the tests in
`test/pdf_arabic_spacing_test.dart` will say whether it is still needed.
