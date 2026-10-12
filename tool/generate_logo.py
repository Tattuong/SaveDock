#!/usr/bin/env python3
"""DateBridge launcher: a clock face, readable at icon size."""

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SIZE = 1024
PAGE = (244, 246, 251, 255)
BLUE = (59, 108, 255, 255)
INK = (27, 36, 55, 255)
WHITE = (255, 255, 255, 255)
CX = CY = 512


def _hand(draw: ImageDraw.ImageDraw, angle: float, length: float, width: int) -> None:
    rad = math.radians(angle)
    x = CX + math.sin(rad) * length
    y = CY - math.cos(rad) * length
    draw.line((CX, CY, x, y), fill=INK, width=width)
    r = width / 2
    draw.ellipse((x - r, y - r, x + r, y + r), fill=INK)


def _mark(canvas: Image.Image) -> None:
    draw = ImageDraw.Draw(canvas)
    draw.ellipse((244, 244, 780, 780), fill=BLUE)
    draw.ellipse((300, 300, 724, 724), fill=WHITE)
    for angle in (0, 90, 180, 270):
        rad = math.radians(angle)
        outer = 196
        inner = 168
        x0 = CX + math.sin(rad) * inner
        y0 = CY - math.cos(rad) * inner
        x1 = CX + math.sin(rad) * outer
        y1 = CY - math.cos(rad) * outer
        draw.line((x0, y0, x1, y1), fill=BLUE, width=16)
    # 10:10, the usual watch-face pose.
    _hand(draw, 300, 118, 28)
    _hand(draw, 60, 168, 22)
    draw.ellipse((492, 492, 532, 532), fill=BLUE)


def main() -> None:
    assets = ROOT / "assets"
    assets.mkdir(exist_ok=True)

    logo = Image.new("RGBA", (SIZE, SIZE), PAGE)
    _mark(logo)
    logo.convert("RGB").save(assets / "logo.png", optimize=True)

    splash = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    _mark(splash)
    splash_path = ROOT / "android/app/src/main/res/drawable-nodpi/splash_icon.png"
    splash_path.parent.mkdir(parents=True, exist_ok=True)
    splash.save(splash_path, optimize=True)
    print(f"wrote {assets / 'logo.png'}")


if __name__ == "__main__":
    main()
