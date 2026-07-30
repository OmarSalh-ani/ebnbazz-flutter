"""Remove solid cream/white backgrounds from onboarding PNG illustrations."""

from __future__ import annotations

import os
from pathlib import Path

from PIL import Image

ASSETS_DIR = Path(__file__).resolve().parent.parent / "assets" / "illustrations" / "onboarding"

# Known background tones used in generated artwork.
BG_SAMPLES = [
    (255, 255, 255),
    (250, 248, 245),
    (245, 240, 232),
    (240, 235, 225),
    (225, 202, 180),  # #E1CAB4
    (237, 230, 220),
    (248, 245, 238),
    (255, 253, 249),
]


def color_distance(a: tuple[int, int, int], b: tuple[int, int, int]) -> float:
    return ((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2) ** 0.5


def is_background(rgb: tuple[int, int, int], threshold: float = 34.0) -> bool:
    return any(color_distance(rgb, sample) <= threshold for sample in BG_SAMPLES)


def remove_background(path: Path, threshold: float = 34.0) -> None:
    image = Image.open(path).convert("RGBA")
    pixels = image.load()
    width, height = image.size

    corner_colors = [
        pixels[0, 0][:3],
        pixels[width - 1, 0][:3],
        pixels[0, height - 1][:3],
        pixels[width - 1, height - 1][:3],
    ]

    samples = list(BG_SAMPLES)
    for color in corner_colors:
        if color not in samples:
            samples.append(color)

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            rgb = (r, g, b)
            if any(color_distance(rgb, sample) <= threshold for sample in samples):
                pixels[x, y] = (r, g, b, 0)

    image.save(path, format="PNG")
    print(f"Processed {path.name}")


def main() -> None:
    for name in sorted(os.listdir(ASSETS_DIR)):
        if name.lower().endswith(".png"):
            remove_background(ASSETS_DIR / name)


if __name__ == "__main__":
    main()
