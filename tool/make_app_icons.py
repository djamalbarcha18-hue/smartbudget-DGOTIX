#!/usr/bin/env python3
"""Draws every app icon from the DGOTIX mark: a white logo on a blue gradient.

The logo's shape is the alpha channel of assets/launcher/icon_foreground.png,
so this can be run again after changing the colors below. Then run
`dart run flutter_launcher_icons` to regenerate the Android launcher icons.

Writes:
  assets/launcher/icon_foreground.png  white logo, transparent (adaptive icon)
  assets/launcher/icon_monochrome.png  same, for Android 13+ themed icons
  assets/launcher/icon_background.png  the blue gradient (adaptive icon)
  assets/launcher/icon_full.png        square icon (older launchers, iOS)
  assets/launcher/play_store_icon_512.png
  web/icons/Icon-192.png, Icon-512.png                 home-screen icons
  web/icons/Icon-maskable-192.png, Icon-maskable-512.png  logo in the safe zone
  web/favicon.png                      rounded, for browser tabs

Needs Pillow (pip install pillow).
"""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
LAUNCHER = ROOT / "assets" / "launcher"
WEB = ROOT / "web"

TOP = (43, 142, 255)      # gradient, top
BOTTOM = (14, 104, 224)   # gradient, bottom (brand blue #1680F7 in between)
LOGO = (255, 255, 255)

FULL_LOGO_WIDTH = 0.66    # share of the icon the logo spans on square icons
MASKABLE_LOGO_WIDTH = 0.56  # inside the 80% safe circle of maskable icons


def gradient(size: int) -> Image.Image:
    column = Image.new("RGB", (1, size))
    for y in range(size):
        t = y / (size - 1)
        column.putpixel((0, y), tuple(
            round(TOP[i] + (BOTTOM[i] - TOP[i]) * t) for i in range(3)))
    return column.resize((size, size))


def logo_mask() -> Image.Image:
    alpha = Image.open(LAUNCHER / "icon_foreground.png").convert("RGBA").split()[3]
    return alpha.crop(alpha.getbbox())


def square_icon(size: int, mask: Image.Image, logo_width: float) -> Image.Image:
    base = gradient(size)
    w = round(size * logo_width)
    h = round(mask.height * w / mask.width)
    m = mask.resize((w, h), Image.LANCZOS)
    base.paste(Image.new("RGB", (w, h), LOGO), ((size - w) // 2, (size - h) // 2), m)
    return base


def rounded(icon: Image.Image) -> Image.Image:
    size = icon.width
    shape = Image.new("L", (size, size), 0)
    ImageDraw.Draw(shape).rounded_rectangle(
        [0, 0, size - 1, size - 1], round(size * 0.225), fill=255)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(icon, (0, 0), shape)
    return out


def main() -> None:
    source = Image.open(LAUNCHER / "icon_foreground.png").convert("RGBA")
    alpha = source.split()[3]
    mask = logo_mask()

    # Adaptive icon layers keep the existing logo placement (the launcher
    # insets the foreground by 16%).
    white = Image.new("RGBA", source.size, LOGO + (0,))
    white.putalpha(alpha)
    white.save(LAUNCHER / "icon_foreground.png")
    white.save(LAUNCHER / "icon_monochrome.png")
    gradient(source.width).save(LAUNCHER / "icon_background.png")

    full = square_icon(1024, mask, FULL_LOGO_WIDTH)
    full.save(LAUNCHER / "icon_full.png")
    full.resize((512, 512), Image.LANCZOS).save(LAUNCHER / "play_store_icon_512.png")

    for size in (192, 512):
        full.resize((size, size), Image.LANCZOS).save(WEB / "icons" / f"Icon-{size}.png")
        square_icon(size, mask, MASKABLE_LOGO_WIDTH).save(
            WEB / "icons" / f"Icon-maskable-{size}.png")
    rounded(square_icon(256, mask, 0.70)).resize((64, 64), Image.LANCZOS).save(
        WEB / "favicon.png")


if __name__ == "__main__":
    main()
