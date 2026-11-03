#!/usr/bin/env python3
"""Give Tajawal the Arabic presentation forms the PDF library asks it for.

Why this exists
---------------
The `pdf` package shapes Arabic itself. Instead of handing the font the
letters and letting OpenType pick the joined forms, it rewrites the text into
Unicode's Arabic Presentation Forms-B block (U+FE70-U+FEFF) and looks each one
up in the font's cmap.

Tajawal's cmap carries the initial, medial and final forms but not the
isolated ones. Where the package asks for an isolated form the lookup fails
and the letter is dropped or drawn over its neighbour. In practice:

    شهري   printed as   شهر      (the yeh vanishes)
    سنوي   printed as   سنو
    أخرى   printed as   أخري     (the wrong letter)

It hits any word whose last letter follows a non-joining letter (ا د ذ ر ز و),
which includes all four report period names. Urdu and Persian reports are set
in Noto Naskh Arabic, whose cmap is complete, so they were never affected.

What this does
--------------
Adds cmap entries only. No glyph, metric, name or table is touched, so the
typeface is unchanged and the file grows by a few hundred bytes. Each missing
presentation form is mapped to the glyph of the letter it decomposes to,
which is what a complete font (Noto Naskh Arabic, for one) already does.

Run it after replacing a Tajawal file with a fresh download:

    pip install fonttools
    python3 tool/patch_arabic_pdf_fonts.py

It is idempotent, and test/pdf_arabic_forms_test.dart fails if it was not run.
"""

from __future__ import annotations

import sys
import unicodedata
from pathlib import Path

try:
    from fontTools.ttLib import TTFont
except ImportError:
    sys.exit('fontTools is needed: pip install fonttools')

FONTS = (
    'assets/fonts/Tajawal-Regular.ttf',
    'assets/fonts/Tajawal-Bold.ttf',
)

# Arabic Presentation Forms-B.
FIRST, LAST = 0xFE70, 0xFEFF


def base_letter(code: int) -> int | None:
    """The letter a presentation form stands for, or None if it is not one."""
    decomposition = unicodedata.decomposition(chr(code))
    if not decomposition:
        return None
    parts = decomposition.split()
    if parts[0].startswith('<'):
        parts = parts[1:]
    # Lam-alef ligatures decompose to two letters; leave those alone.
    if len(parts) != 1:
        return None
    return int(parts[0], 16)


def patch(path: Path) -> int:
    font = TTFont(str(path))
    cmap = font.getBestCmap()

    additions: dict[int, str] = {}
    for code in range(FIRST, LAST + 1):
        if code in cmap:
            continue
        letter = base_letter(code)
        if letter is None:
            continue
        glyph = cmap.get(letter)
        if glyph is not None:
            additions[code] = glyph

    if not additions:
        print(f'{path}: already complete')
        return 0

    for table in font['cmap'].tables:
        # The Unicode and Windows subtables; the legacy Mac one is byte-sized.
        if table.format in (4, 12) and table.platformID in (0, 3):
            table.cmap.update(additions)

    font.save(str(path))
    print(f'{path}: added {len(additions)} presentation forms')
    return len(additions)


def main() -> None:
    root = Path(__file__).resolve().parent.parent
    for name in FONTS:
        path = root / name
        if not path.exists():
            sys.exit(f'missing: {path}')
        patch(path)


if __name__ == '__main__':
    main()
