"""Slice a generated action strip into normalized, animation-ready frames.

A generated strip is one image; shipping it as-is would give every frame its
own scale and palette. This tool cuts the strip on transparent gaps, fits all
frames with one shared scale, quantizes them with one shared palette and puts
their feet on one baseline, so the animation does not shimmer.

Usage (from the game folder):
  python -I tools/slice_anim_sheet.py SRC --outdir DIR --prefix run --frames 4
      [--canvas 96] [--height 92] [--colors 24] [--alpha 128] [--gap 6]
"""

from __future__ import annotations

import argparse
import importlib.util
import pathlib
import sys

import numpy as np
from PIL import Image

GAME = pathlib.Path(__file__).resolve().parents[1]
NORMALIZE = GAME / "tools" / "normalize_sprite.py"


def _load_normalizer():
    spec = importlib.util.spec_from_file_location("normalize_sprite", NORMALIZE)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def column_groups(mask: np.ndarray, gap: int) -> list[tuple[int, int]]:
    cols = np.where(mask.any(axis=0))[0]
    if len(cols) == 0:
        return []
    groups: list[tuple[int, int]] = []
    start = prev = int(cols[0])
    for value in cols[1:]:
        value = int(value)
        if value - prev > gap:
            groups.append((start, prev))
            start = value
        prev = value
    groups.append((start, prev))
    return groups


def fit_groups(groups: list[tuple[int, int]], count: int) -> list[tuple[int, int]]:
    """Merge the closest neighbours or split the widest cell until `count`."""
    while len(groups) > count:
        best = min(range(len(groups) - 1), key=lambda i: groups[i + 1][0] - groups[i][1])
        groups[best] = (groups[best][0], groups[best + 1][1])
        del groups[best + 1]
    while len(groups) < count:
        widest = max(range(len(groups)), key=lambda i: groups[i][1] - groups[i][0])
        start, end = groups[widest]
        middle = (start + end) // 2
        groups[widest:widest + 1] = [(start, middle), (middle + 1, end)]
    return groups


def premultiplied_resize(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    return image.convert("RGBa").resize(size, Image.LANCZOS).convert("RGBA")


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser()
    parser.add_argument("src")
    parser.add_argument("--outdir", required=True)
    parser.add_argument("--prefix", required=True)
    parser.add_argument("--frames", type=int, default=4)
    parser.add_argument("--canvas", type=int, default=96)
    parser.add_argument("--height", type=int, default=92)
    parser.add_argument("--colors", type=int, default=24)
    parser.add_argument("--alpha", type=int, default=128)
    parser.add_argument("--gap", type=int, default=6)
    parser.add_argument("--min-cluster", type=int, default=4)
    # "min" fits the widest frame; "height" keeps one pixel height and lets a
    # weapon extend sideways (use a wider --canvas for those sets).
    parser.add_argument("--fit", choices=["min", "height"], default="min")
    args = parser.parse_args()

    normalizer = _load_normalizer()
    source = Image.open(GAME / args.src).convert("RGBA")
    alpha = np.asarray(source)[:, :, 3]
    mask = alpha >= args.alpha
    groups = fit_groups(column_groups(mask, args.gap), args.frames)
    if len(groups) != args.frames:
        raise SystemExit(f"expected {args.frames} frames, found {len(groups)}")

    crops: list[Image.Image] = []
    for start, end in groups:
        column = mask[:, start:end + 1]
        rows = np.where(column.any(axis=1))[0]
        box = (start, int(rows[0]), end + 1, int(rows[-1]) + 1)
        crops.append(source.crop(box))

    max_w = max(crop.width for crop in crops)
    max_h = max(crop.height for crop in crops)
    limit_w = args.canvas - 2
    if args.fit == "height":
        scale = args.height / max_h
    else:
        scale = min(limit_w / max_w, args.height / max_h)
    scaled = [
        premultiplied_resize(crop, (max(1, round(crop.width * scale)), max(1, round(crop.height * scale))))
        for crop in crops
    ]

    strip_w = sum(frame.width for frame in scaled)
    strip_h = max(frame.height for frame in scaled)
    strip = Image.new("RGBA", (strip_w, strip_h), (0, 0, 0, 0))
    offsets: list[tuple[int, int]] = []
    x = 0
    for frame in scaled:
        offsets.append((x, frame.width))
        strip.alpha_composite(frame, (x, strip_h - frame.height))
        x += frame.width
    strip = normalizer.quantize(strip, args.colors, args.alpha)

    outdir = GAME / args.outdir
    outdir.mkdir(parents=True, exist_ok=True)
    report = []
    for index, (offset, width) in enumerate(offsets):
        frame = strip.crop((offset, 0, offset + width, strip_h))
        frame = normalizer.crop_opaque(frame, 0)
        frame = normalizer.drop_small_clusters(frame, args.min_cluster)
        padded = Image.new("RGBA", (frame.width + 2, frame.height + 2), (0, 0, 0, 0))
        padded.alpha_composite(frame, (1, 1))
        frame = normalizer.add_outline(padded, normalizer.OUTLINE)
        final = normalizer.place(frame, args.canvas)
        out = outdir / f"{args.prefix}_{index}.png"
        final.save(out)
        report.append({
            "frame": str(out.relative_to(GAME)).replace("\\", "/"),
            "art": frame.size,
            "colors": len({tuple(c) for c in np.asarray(final)[np.asarray(final)[..., 3] == 255][:, :3]}),
        })
    print({"scale": round(scale, 4), "frames": report})


if __name__ == "__main__":
    main()
