"""Builds assets/fonts/icons/SbIcons.ttf: SmartBudget's own icons.

Why: Material's "savings" icon is a pig-shaped piggy bank, which many of our
users would rather not see; this font adds a money box (a jar with a coin going
into the slot of its lid) as an ordinary IconData.

Glyphs are drawn on Material's 24×24 grid (y down) and converted to a font.
Run after changing a shape (needs: pip install fonttools skia-pathops):
    python3 tool/build_icon_font.py
"""
import math
import pathops
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen

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


GLYPHS = {
    "moneybox": (0xE000, money_box_outlined),
    "moneybox_filled": (0xE001, money_box_filled),
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
