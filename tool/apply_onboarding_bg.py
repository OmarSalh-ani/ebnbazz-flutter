"""Composite onboarding illustrations onto a soft white-beige background."""

from __future__ import annotations

import os
from pathlib import Path

from PIL import Image, ImageDraw

ASSETS_DIR = Path(__file__).resolve().parent.parent / "assets" / "illustrations" / "onboarding"

# Soft white-beige palette
BG_EDGE = (237, 228, 216)      # #EDE4D8
BG_CENTER = (251, 248, 243)    # #FBF8F3


def make_beige_canvas(size: tuple[int, int]) -> Image.Image:
    width, height = size
    canvas = Image.new("RGBA", size, BG_EDGE + (255,))
    pixels = canvas.load()
    cx, cy = width * 0.5, height * 0.38
    max_dist = (width * width + height * height) ** 0.5 * 0.55

    for y in range(height):
        for x in range(width):
            dist = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
            t = min(dist / max_dist, 1.0)
            r = int(BG_CENTER[0] + (BG_EDGE[0] - BG_CENTER[0]) * t)
            g = int(BG_CENTER[1] + (BG_EDGE[1] - BG_CENTER[1]) * t)
            b = int(BG_CENTER[2] + (BG_EDGE[2] - BG_CENTER[2]) * t)
            pixels[x, y] = (r, g, b, 255)

    return canvas


def apply_background(path: Path) -> None:
    illustration = Image.open(path).convert("RGBA")
    canvas = make_beige_canvas(illustration.size)
    canvas.alpha_composite(illustration)
    canvas.convert("RGB").save(path, format="PNG", optimize=True)
    print(f"Updated {path.name}")


def main() -> None:
    for name in sorted(os.listdir(ASSETS_DIR)):
        if name.lower().endswith(".png"):
            apply_background(ASSETS_DIR / name)


if __name__ == "__main__":
    main()
