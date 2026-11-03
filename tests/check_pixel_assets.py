#!/usr/bin/env python3
"""Pixel-art QA gate for the Chapter 1 demo (plan B2.4).

Checks every demo-visible sprite against the pixel contract:
  - exact canvas size
  - alpha is binary (0 or 255)
  - all four corners transparent
  - opaque colour count within the palette budget
  - foot baseline: lowest opaque row is the canvas bottom row
  - import settings: no compression, no mipmaps

Usage (from the game folder):
  python tests/check_pixel_assets.py --demo
Exit code 0 = all pass, 1 = at least one failure. Each failure is printed as
`path: reason`. Tracked; never imported by the game.
"""

from __future__ import annotations

import argparse
import pathlib
import sys

import numpy as np
from PIL import Image

GAME = pathlib.Path(__file__).resolve().parents[1]

PLAYER_FRAME_SIZES = {
    "player_idle": 96,
    "run": 112,
    "jump": 112,
    "cast": 112,
    "attack": 160,
    "dodge": 160,
    "hurt": 160,
}

DEMO_ENEMIES = [
    "ink_hound",
    "scribe_bug",
    "blank_man",
    "typo_beast",
    "ink_bomber",
    "page_swarm",
]

# Per-category palette budget from plan B2.1/B2.2.
MAX_COLORS = 32


def demo_specs() -> list[dict]:
    specs: list[dict] = [
        {"path": "assets/sprites/player/player_idle.png", "size": (96, 96)},
    ]
    for name in ("far", "mid"):
        specs.append({
            "path": f"assets/backgrounds/pixel/ink_archive_{name}.png",
            "size": (1280, 720),
            "corners": False,
            "baseline": False,
        })
    for name in ("luchen", "ayan", "guru"):
        specs.append({
            "path": f"assets/portraits/pixel/{name}.png",
            "size": (192, 256),
            "corners": False,
            "baseline": False,
        })
    specs.append({
        "path": "assets/branding/logo_pixel.png",
        "size": (256, 256),
        "baseline": False,
    })
    specs.append({
        "path": "assets/tiles/ch1/tiles.png",
        "size": (64, 16),
        "corners": False,
        "baseline": False,
        "tile_grid": True,
    })
    for name, size in (
        ("shop", (96, 96)),
        ("stele", (48, 64)),
        ("chest", (48, 32)),
        ("door", (48, 96)),
        ("training_dummy", (48, 72)),
    ):
        specs.append({"path": f"assets/sprites/props/{name}.png", "size": size})
    for action, size in PLAYER_FRAME_SIZES.items():
        if action == "player_idle":
            continue
        for frame in sorted((GAME / "assets/sprites/player/frames").glob(f"{action}_*.png")):
            specs.append({
                "path": str(frame.relative_to(GAME)).replace("\\", "/"),
                "size": (size, size),
            })
    for name in DEMO_ENEMIES:
        specs.append({"path": f"assets/sprites/enemies/{name}.png", "size": (96, 96)})
    specs.append({"path": "assets/sprites/bosses/ink_archivist.png", "size": (256, 256)})
    return specs


def check_import_settings(game: pathlib.Path, rel: str) -> str | None:
    import_file = game / (rel + ".import")
    if not import_file.exists():
        return "missing .import file"
    text = import_file.read_text(encoding="utf-8", errors="ignore")
    if "compress/mode=0" not in text:
        return "import uses compression (compress/mode != 0)"
    if "mipmaps/generate=false" not in text:
        return "import generates mipmaps"
    return None


def check_sprite(game: pathlib.Path, spec: dict) -> list[str]:
    rel = spec["path"]
    path = game / rel
    if not path.exists():
        return ["missing file"]
    errors: list[str] = []
    image = Image.open(path).convert("RGBA")
    if image.size != spec["size"]:
        errors.append(f"size {image.width}x{image.height} (expected {spec['size'][0]}x{spec['size'][1]})")

    arr = np.asarray(image)
    pixels = arr.reshape(-1, 4)
    alpha_values = {int(value) for value in np.unique(pixels[:, 3])}
    if not alpha_values <= {0, 255}:
        errors.append("non-binary alpha (semi-transparent edge)")

    if spec.get("corners", True):
        corners = [
            image.getpixel((0, 0))[3],
            image.getpixel((image.width - 1, 0))[3],
            image.getpixel((0, image.height - 1))[3],
            image.getpixel((image.width - 1, image.height - 1))[3],
        ]
        if any(corners):
            errors.append("opaque corner pixel")

    colors = {tuple(int(channel) for channel in pixel[:3]) for pixel in pixels if pixel[3] > 0}
    if len(colors) > spec.get("max_colors", MAX_COLORS):
        errors.append(f"{len(colors)} colours (max {spec.get('max_colors', MAX_COLORS)})")

    if spec.get("tile_grid") and (image.width % 16 or image.height % 16):
        errors.append("tile sheet is not a multiple of 16x16")

    if spec.get("baseline", True):
        bbox = image.getchannel("A").getbbox()
        if bbox is None:
            errors.append("fully transparent")
        elif bbox[3] != image.height:
            errors.append(f"foot baseline {image.height - bbox[3]}px above canvas bottom")

    import_error = check_import_settings(game, rel)
    if import_error:
        errors.append(import_error)
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Pixel-art QA gate")
    parser.add_argument("--demo", action="store_true", help="check the Chapter 1 demo asset set")
    parser.add_argument("--all", action="store_true", help="alias for --demo for now")
    args = parser.parse_args()
    if not (args.demo or args.all):
        parser.print_help()
        return 2

    specs = demo_specs()
    failures = 0
    for spec in specs:
        errors = check_sprite(GAME, spec)
        for error in errors:
            failures += 1
            print(f"FAIL {spec['path']}: {error}")

    print(f"Checked {len(specs)} assets, {failures} failure(s)")
    return 0 if failures == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
