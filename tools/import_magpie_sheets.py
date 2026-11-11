"""Cuts Magpie action sheets into creature strips (1.1).

A sheet is one generated image, 4 rows x 6 columns of the same character:
idle, move, attack (2 wind-up frames + 4 strike frames) and death. The model
is given the game's own sprite as a reference, so the figure keeps its design;
this tool makes the result usable in the game:

  1. the hazy, half-transparent backdrop is removed with an alpha threshold;
  2. each grid cell's figure is found by its connected pixels, stray specks
     are dropped;
  3. everything is scaled so the idle figure is exactly as tall as the sprite
     the game already uses (same on-screen size, same collider);
  4. frames are placed on a common canvas with one foot line per row, so the
     figure does not slide or bob between frames;
  5. strips and a creatures.json entry are written.

Usage:
  python tools/import_magpie_sheets.py                # every sheet in assets/concept/magpie
  python tools/import_magpie_sheets.py ink_hound      # one id
  python tools/import_magpie_sheets.py --preview DIR  # also write contact sheets

Sheets are named <id>_sheet.png. The reference sprite is looked up in
assets/sprites/bosses and assets/sprites/enemies.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parent.parent
SHEETS = ROOT / "assets" / "concept" / "magpie"
OUT = ROOT / "assets" / "sprites" / "creatures"
MANIFEST = OUT / "creatures.json"
REFERENCE_DIRS = [ROOT / "assets" / "sprites" / "bosses", ROOT / "assets" / "sprites" / "enemies"]

ROWS, COLS = 4, 6
ALPHA_CUT = 150          # sheet alpha at or above this is figure, below is haze
REF_ALPHA = 24           # same threshold as the asset pipeline
SPECK_SHARE = 0.004      # components smaller than this share of the cell's largest are dropped
ANIMS = {
    # name: (row, first column, frame count, fps)
    "idle": (0, 0, 6, 7),
    "move": (1, 0, 6, 10),
    "windup": (2, 0, 2, 6),
    "attack": (2, 2, 4, 12),
    "hurt": (3, 0, 1, 10),
    "death": (3, 0, 6, 12),  # 0.5 s: rooms wait for the body before clearing
}


def reference_for(creature_id: str) -> Path | None:
    for folder in REFERENCE_DIRS:
        path = folder / f"{creature_id}.png"
        if path.exists():
            return path
    return None


def opaque_bbox(alpha: np.ndarray, cut: int) -> tuple[int, int, int, int] | None:
    ys, xs = np.nonzero(alpha >= cut)
    if ys.size == 0:
        return None
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def split_bands(profile: np.ndarray, count: int, length: int) -> list[tuple[int, int]]:
    """Splits an occupancy profile into `count` bands at its emptiest gaps.

    Starts from the even grid and moves each boundary to the emptiest line
    within a third of a cell, so a figure that leans over its cell edge is not
    cut in half."""
    step = length / count
    cuts = [0]
    for index in range(1, count):
        centre = int(round(index * step))
        reach = int(step / 3)
        lo, hi = max(centre - reach, 1), min(centre + reach, length - 1)
        window = profile[lo:hi]
        best = lo + int(np.argmin(window))
        # Prefer the middle of the emptiest run.
        empties = np.nonzero(window == window.min())[0]
        if empties.size:
            best = lo + int(empties[np.argmin(np.abs(empties - (centre - lo)))])
        cuts.append(best)
    cuts.append(length)
    return [(cuts[i], cuts[i + 1]) for i in range(count)]


def clean_cell(mask: np.ndarray) -> np.ndarray:
    """Keeps the figure, drops specks that are not part of it."""
    labels, count = ndimage.label(mask, structure=np.ones((3, 3)))
    if count <= 1:
        return mask
    sizes = ndimage.sum(mask, labels, index=range(1, count + 1))
    keep = np.zeros(count + 1, dtype=bool)
    keep[1:] = sizes >= sizes.max() * SPECK_SHARE
    return keep[labels]


def process(creature_id: str, preview_dir: Path | None) -> dict | None:
    sheet_path = SHEETS / f"{creature_id}_sheet.png"
    ref_path = reference_for(creature_id)
    if not sheet_path.exists() or ref_path is None:
        print(f"skip {creature_id}: sheet or reference sprite missing")
        return None
    sheet = np.array(Image.open(sheet_path).convert("RGBA"))
    reference = Image.open(ref_path).convert("RGBA")
    ref_box = opaque_bbox(np.array(reference)[:, :, 3], REF_ALPHA + 1)
    ref_height = ref_box[3] - ref_box[1]
    mask = sheet[:, :, 3] >= ALPHA_CUT
    height, width = mask.shape
    row_bands = split_bands(mask.sum(axis=1), ROWS, height)

    cells: list[list[dict | None]] = []
    for top, bottom in row_bands:
        band = mask[top:bottom]
        col_bands = split_bands(band.sum(axis=0), COLS, width)
        row: list[dict | None] = []
        for left, right in col_bands:
            cell_mask = clean_cell(band[:, left:right])
            box = opaque_bbox(cell_mask.astype(np.uint8), 1)
            if box is None:
                row.append(None)
                continue
            x0, y0, x1, y1 = box
            rgba = sheet[top + y0:top + y1, left + x0:left + x1].copy()
            rgba[:, :, 3] = np.where(cell_mask[y0:y1, x0:x1], 255, 0)
            row.append({
                "image": Image.fromarray(rgba, "RGBA"),
                # Position inside the cell, relative to the cell centre.
                "dx": x0 - (right - left) / 2.0,
                "bottom": top + y1,
                "height": y1 - y0,
            })
        cells.append(row)

    idle_heights = [cell["height"] for cell in cells[0] if cell]
    if not idle_heights:
        print(f"skip {creature_id}: no idle frames found")
        return None
    scale = ref_height / float(np.median(idle_heights))

    # One foot line per row: the lowest opaque pixel of the row.
    placed: list[list[dict | None]] = []
    extent_left = extent_right = extent_up = 1.0
    for row in cells:
        present = [cell for cell in row if cell]
        if not present:
            placed.append([None] * COLS)
            continue
        baseline = max(cell["bottom"] for cell in present)
        out_row: list[dict | None] = []
        for cell in row:
            if cell is None:
                out_row.append(None)
                continue
            image: Image.Image = cell["image"]
            size = (max(int(round(image.width * scale)), 1), max(int(round(image.height * scale)), 1))
            small = image.resize(size, Image.Resampling.BOX)
            data = np.array(small)
            data[:, :, 3] = np.where(data[:, :, 3] >= 128, 255, 0)
            small = Image.fromarray(data, "RGBA")
            x = cell["dx"] * scale
            lift = (baseline - cell["bottom"]) * scale
            out_row.append({"image": small, "x": x, "lift": lift})
            extent_left = max(extent_left, -x)
            extent_right = max(extent_right, x + small.width)
            extent_up = max(extent_up, lift + small.height)
        placed.append(out_row)

    half = int(np.ceil(max(extent_left, extent_right))) + 2
    frame_w = half * 2
    frame_h = int(np.ceil(extent_up)) + 4
    foot = frame_h - 2

    def frame(cell: dict | None) -> Image.Image:
        canvas = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
        if cell is not None:
            image = cell["image"]
            canvas.alpha_composite(image, (int(round(half + cell["x"])), int(round(foot - cell["lift"] - image.height))))
        return canvas

    folder = OUT / creature_id
    folder.mkdir(parents=True, exist_ok=True)
    entry: dict = {"frame_size": [frame_w, frame_h], "anims": {}, "source": "magpie"}
    union: tuple[int, int, int, int] | None = None
    for name, (row, first, count, fps) in ANIMS.items():
        frames = [frame(placed[row][first + i]) for i in range(count)]
        # A missing cell repeats its neighbour instead of blinking out.
        for i, cell in enumerate(placed[row][first:first + count]):
            if cell is None:
                frames[i] = frames[i - 1] if i > 0 else frames[min(i + 1, count - 1)]
        strip = Image.new("RGBA", (frame_w * count, frame_h), (0, 0, 0, 0))
        for i, image in enumerate(frames):
            strip.paste(image, (i * frame_w, 0))
            if name == "idle":
                box = opaque_bbox(np.array(image)[:, :, 3], 1)
                if box is not None:
                    union = box if union is None else (
                        min(union[0], box[0]), min(union[1], box[1]), max(union[2], box[2]), max(union[3], box[3]))
        strip.save(folder / f"{name}.png")
        entry["anims"][name] = {"frames": count, "fps": fps}
    if union is None:
        union = (0, 0, frame_w, frame_h)
    # Feet on the shared foot line even when an idle frame bobs above it.
    entry["opaque_rect"] = [union[0], union[1], union[2] - union[0], foot - union[1]]
    if preview_dir is not None:
        preview_dir.mkdir(parents=True, exist_ok=True)
        sheet_out = Image.new("RGBA", (frame_w * COLS, frame_h * ROWS), (40, 44, 52, 255))
        for r, row in enumerate(placed):
            for c, cell in enumerate(row):
                sheet_out.alpha_composite(frame(cell), (c * frame_w, r * frame_h))
        reference_box = reference.crop(ref_box)
        sheet_out.alpha_composite(reference_box, (0, 0))
        sheet_out.save(preview_dir / f"{creature_id}.png")
    print(f"{creature_id}: scale {scale:.3f}, frame {frame_w}x{frame_h}, ref height {ref_height}")
    return entry


def main() -> None:
    args = sys.argv[1:]
    preview_dir: Path | None = None
    if "--preview" in args:
        index = args.index("--preview")
        preview_dir = Path(args[index + 1])
        del args[index:index + 2]
    ids = args or sorted(path.name[:-len("_sheet.png")] for path in SHEETS.glob("*_sheet.png"))
    manifest = json.loads(MANIFEST.read_text(encoding="utf8")) if MANIFEST.exists() else {}
    for creature_id in ids:
        entry = process(creature_id, preview_dir)
        if entry is not None:
            manifest[creature_id] = entry
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=1) + "\n", encoding="utf8")


if __name__ == "__main__":
    main()
