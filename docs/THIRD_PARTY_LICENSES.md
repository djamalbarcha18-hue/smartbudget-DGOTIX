# Third-party assets

## Flag images (`assets/flags/*.png`)

The country/region flag images were generated from **flag-icons** by Panayiotis
Lipiridis, rasterized to PNG for reliable cross-platform (web/mobile) rendering.

- Project: https://github.com/lipis/flag-icons
- License: MIT

```
The MIT License (MIT)

Copyright (c) 2013 Panayiotis Lipiridis

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

## Font (`assets/fonts/Tajawal-*.ttf`)

**Tajawal** by Boutros™, bundled to render Arabic text in exported PDFs offline
(matches the app's Arabic UI typography).

- Source: https://fonts.google.com/specimen/Tajawal
- License: SIL Open Font License 1.1 (OFL) — https://openfontlicense.org

The OFL permits bundling and embedding the font in documents and applications.
Copyright (c) 2017 Boutros International. All rights reserved.


## Fonts for offline display (`assets/google_fonts/`)

The app's other Tajawal weights (ExtraLight, Light, Medium, ExtraBold, Black)
and Inter (Regular, Medium, SemiBold, used by the brand lockup) are bundled so
text looks the same with no internet; `google_fonts` loads them from the app
before trying to download. Files are the exact Google Fonts files (SHA-256
checked against the `google_fonts` package). Both are under the SIL Open Font
License 1.1: `assets/google_fonts/OFL-Tajawal.txt`, `OFL-Inter.txt` (also shown
in the app's licenses page).

## Urdu font (`assets/fonts/NotoNaskhArabic-*.ttf`)

**Noto Naskh Arabic** by the Noto Project, used for Urdu text in the app and
in exported PDFs (Tajawal has no Urdu letters). Regular and Bold instances of
the Google Fonts variable font, subset to the Arabic script (Arabic and Urdu).

- Source: https://fonts.google.com/noto/specimen/Noto+Naskh+Arabic
- License: SIL Open Font License 1.1: `assets/google_fonts/OFL-NotoNaskhArabic.txt`
  (also shown in the app's licenses page).
Copyright 2022 The Noto Project Authors (https://github.com/notofonts/arabic)

## Trip item icons (in `assets/fonts/icons/SbIcons.ttf`)

The SmartTrip item icons (plane, bed, utensils, bus, ticket, gift,
shield-check, tag, plane-takeoff, plane-landing, luggage, smartphone-nfc) are **Lucide** icons, their strokes turned into outlines
by `tool/build_icon_font.py`.

- Source: https://lucide.dev (lucide-static 0.460.0)
- License: ISC — `assets/fonts/LICENSE-Lucide.txt` (also shown in the app's
  licenses page).
Copyright (c) Lucide Contributors 2022; portions Cole Bemis 2013-2022 (Feather, MIT).
