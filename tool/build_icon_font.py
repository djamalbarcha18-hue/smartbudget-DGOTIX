"""Builds assets/fonts/icons/SbIcons.ttf: SmartBudget's own icons.

Why: Material's "savings" icon is a pig-shaped piggy bank, which many of our
users would rather not see; this font adds a money box (a jar with a coin going
into the slot of its lid) as an ordinary IconData.

Glyphs are drawn on Material's 24×24 grid (y down) and converted to a font.
The trip items' icons (flights, stay…) are Lucide icons (lucide.dev,
ISC licence, notice below), their 2-unit strokes turned into outlines.

Run after changing a shape (needs: pip install fonttools skia-pathops):
    python3 tool/build_icon_font.py

Lucide licence (for the trip item icons):
    ISC License. Copyright (c) for portions of Lucide are held by Cole Bemis
    2013-2022 as part of Feather (MIT). All other copyright (c) for Lucide
    are held by Lucide Contributors 2022.
    Permission to use, copy, modify, and/or distribute this software for any
    purpose with or without fee is hereby granted, provided that the above
    copyright notice and this permission notice appear in all copies.
    THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
    WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
    MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
    ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
    WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
    ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
    OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
"""
import math
import pathops
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.svgLib.path import parse_path

UPM = 1024
K = 0.5522847498  # cubic circle constant


def rrect(x0, y0, x1, y1, r):
    p = pathops.Path()
    p.moveTo(x0 + r, y0)
    p.lineTo(x1 - r, y0)
    p.cubicTo(x1 - r + r * K, y0, x1, y0 + r - r * K, x1, y0 + r)
    p.lineTo(x1, y1 - r)
    p.cubicTo(x1, y1 - r + r * K, x1 - r + r * K, y1, x1 - r, y1)
    p.lineTo(x0 + r, y1)
    p.cubicTo(x0 + r - r * K, y1, x0, y1 - r + r * K, x0, y1 - r)
    p.lineTo(x0, y0 + r)
    p.cubicTo(x0, y0 + r - r * K, x0 + r - r * K, y0, x0 + r, y0)
    p.close()
    return p


def rect(x0, y0, x1, y1):
    return rrect(x0, y0, x1, y1, 0.0001)


def circle(cx, cy, r):
    p = pathops.Path()
    p.moveTo(cx + r, cy)
    p.cubicTo(cx + r, cy + r * K, cx + r * K, cy + r, cx, cy + r)
    p.cubicTo(cx - r * K, cy + r, cx - r, cy + r * K, cx - r, cy)
    p.cubicTo(cx - r, cy - r * K, cx - r * K, cy - r, cx, cy - r)
    p.cubicTo(cx + r * K, cy - r, cx + r, cy - r * K, cx + r, cy)
    p.close()
    return p


def op(a, b, kind):
    return pathops.op(a, b, kind)


U, D, I = pathops.PathOp.UNION, pathops.PathOp.DIFFERENCE, pathops.PathOp.INTERSECTION


def money_box_outlined():
    # Jar: rounded body, a lid with a coin slot, a coin going in.
    body = op(rrect(4.5, 9.5, 19.5, 21.5, 4), rrect(6.5, 11.5, 17.5, 19.5, 2), D)
    lid = rrect(7, 6.8, 17, 9.6, 1)
    lid = op(lid, rect(9.4, 6, 14.6, 7.9), D)           # slot in the lid
    coin = op(circle(12, 4.3, 3.1), rrect(11.25, 2.4, 12.75, 5.6, 0.75), D)
    coin = op(coin, rect(6, 0, 18, 6.6), I)             # sinking into the slot
    coins = op(rrect(8.5, 15.8, 15.5, 17.5, 0.85),       # coins inside
               rrect(9.5, 13.2, 14.5, 14.9, 0.85), U)
    out = op(body, lid, U)
    return op(op(out, coin, U), coins, U)


def money_box_filled():
    body = rrect(4.5, 9.5, 19.5, 21.5, 4)
    lid = op(rrect(7, 6.8, 17, 9.6, 1), rect(9.4, 6, 14.6, 7.9), D)
    body = op(body, rrect(8.5, 15.2, 15.5, 16.9, 0.85), D)  # coin marks
    body = op(body, rrect(9.5, 12.6, 14.5, 14.3, 0.85), D)
    coin = op(circle(12, 4.3, 3.1), rrect(11.25, 2.4, 12.75, 5.6, 0.75), D)
    coin = op(coin, rect(6, 0, 18, 6.6), I)
    return op(op(body, lid, U), coin, U)


def svg_circle(cx, cy, r):
    return (f"M{cx - r} {cy}a{r} {r} 0 1 0 {2 * r} 0"
            f"a{r} {r} 0 1 0 {-2 * r} 0Z")


def stroked(*paths, width=2.0):
    """Lucide-style line art: SVG path data (24 grid, y down) stroked with
    round caps and joins, as one filled outline."""
    line = pathops.Path()
    pen = line.getPen()
    for d in paths:
        parse_path(d, pen)
    line.stroke(width, pathops.LineCap.ROUND_CAP, pathops.LineJoin.ROUND_JOIN,
                4)
    line.convertConicsToQuads(0.02)  # round caps come out as conics
    return pathops.simplify(line, fix_winding=True)


# The trip items, from Lucide (plane, bed, utensils, bus, ticket, gift,
# shield-check, tag).
def trip_flights():
    return stroked("M17.8 19.2 16 11l3.5-3.5C21 6 21.5 4 21 3c-1-.5-3 0-4.5 "
                   "1.5L13 8 4.8 6.2c-.5-.1-.9.1-1.1.5l-.3.5c-.2.5-.1 1 .3 "
                   "1.3L9 12l-2 3H4l-1 1 3 2 2 3 1-1v-3l3-2 3.5 5.3c.3.4.8.5 "
                   "1.3.3l.5-.2c.4-.3.6-.7.5-1.2z")


def trip_stay():
    return stroked("M2 4v16", "M2 8h18a2 2 0 0 1 2 2v10", "M2 17h20",
                   "M6 8v9")


def trip_food():
    return stroked("M3 2v7c0 1.1.9 2 2 2h4a2 2 0 0 0 2-2V2", "M7 2v20",
                   "M21 15V2a5 5 0 0 0-5 5v6c0 1.1.9 2 2 2h3Zm0 0v7")


def trip_transport():
    return stroked("M8 6v6", "M15 6v6", "M2 12h19.6",
                   "M18 18h3s.5-1.7.8-2.8c.1-.4.2-.8.2-1.2 0-.4-.1-.8-.2-1.2"
                   "l-1.4-5C20.1 6.8 19.1 6 18 6H4a2 2 0 0 0-2 2v10h3",
                   svg_circle(7, 18, 2), "M9 18h5", svg_circle(16, 18, 2))


def trip_activities():
    return stroked("M2 9a3 3 0 0 1 0 6v2a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-2"
                   "a3 3 0 0 1 0-6V7a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2Z",
                   "M13 5v2", "M13 17v2", "M13 11v2")


def trip_gifts():
    return stroked("M4 8h16a1 1 0 0 1 1 1v2a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9"
                   "a1 1 0 0 1 1-1Z", "M12 8v13",
                   "M19 12v7a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2v-7",
                   "M7.5 8a2.5 2.5 0 0 1 0-5A4.8 8 0 0 1 12 8a4.8 8 0 0 1 "
                   "4.5-5 2.5 2.5 0 0 1 0 5")


def trip_emergency():
    return stroked("M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 "
                   "4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17"
                   " 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z",
                   "m9 12 2 2 4-4")


def trip_other():
    return stroked("M12.586 2.586A2 2 0 0 0 11.172 2H4a2 2 0 0 0-2 2v7.172a2"
                   " 2 0 0 0 .586 1.414l8.704 8.704a2.426 2.426 0 0 0 3.42 0"
                   "l6.58-6.58a2.426 2.426 0 0 0 0-3.42z",
                   svg_circle(7.5, 7.5, 0.5))


GLYPHS = {
    "moneybox": (0xE000, money_box_outlined),
    "moneybox_filled": (0xE001, money_box_filled),
    "trip_flights": (0xE002, trip_flights),
    "trip_stay": (0xE003, trip_stay),
    "trip_food": (0xE004, trip_food),
    "trip_transport": (0xE005, trip_transport),
    "trip_activities": (0xE006, trip_activities),
    "trip_gifts": (0xE007, trip_gifts),
    "trip_emergency": (0xE008, trip_emergency),
    "trip_other": (0xE009, trip_other),
}


def to_glyph(path):
    pen = TTGlyphPen(None)
    s = UPM / 24.0
    # 24-grid, y down  ->  font units, y up.
    tpen = TransformPen(Cu2QuPen(pen, max_err=0.5, reverse_direction=True),
                        (s, 0, 0, -s, 0, UPM))
    path.draw(tpen)
    return pen.glyph()


def main():
    order = [".notdef"] + list(GLYPHS)
    fb = FontBuilder(UPM, isTTF=True)
    fb.setupGlyphOrder(order)
    fb.setupCharacterMap({cp: name for name, (cp, _) in GLYPHS.items()})
    glyphs = {".notdef": TTGlyphPen(None).glyph()}
    for name, (_, fn) in GLYPHS.items():
        glyphs[name] = to_glyph(fn())
    fb.setupGlyf(glyphs)
    fb.setupHorizontalMetrics({n: (UPM, 0) for n in order})
    fb.setupHorizontalHeader(ascent=UPM, descent=0)
    fb.setupNameTable({"familyName": "SbIcons", "styleName": "Regular"})
    fb.setupOS2(sTypoAscender=UPM, sTypoDescender=0, usWinAscent=UPM,
                usWinDescent=0)
    fb.setupPost()
    fb.save("assets/fonts/icons/SbIcons.ttf")
    print("wrote assets/fonts/icons/SbIcons.ttf")


if __name__ == "__main__":
    main()
