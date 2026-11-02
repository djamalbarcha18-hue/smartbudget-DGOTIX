# Reports (PDF)

Four reporting periods — monthly, quarterly, half-yearly and yearly — all of
them PRO. The PDF is built on the device from data already there; nothing is
sent anywhere to make one.

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
