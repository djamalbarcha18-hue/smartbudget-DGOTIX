# Reports (PDF)

Four reporting periods — monthly, quarterly, half-yearly and yearly — all of
them PRO. The PDF is built on the device from data already there; nothing is
sent anywhere to make one.

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

One request per export, through the same gateway as everything else, so the
server's existing quota, daily limit and monthly cost ceiling apply unchanged
— there is no second allowance to keep in step. A few hundred words in and
out: on the cheapest model in the registry that is a fraction of a cent, and
a PRO account's ceiling is $2 a month.

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
