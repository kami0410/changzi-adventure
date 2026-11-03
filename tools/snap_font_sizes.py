"""Snap every UI font size in the game to the pixel font's integer scale.

Ark Pixel 12px only renders crisp at 12, 24, 36 or 48 px. Sizes in between
(14/16/18/20...) are drawn from scaled outlines and come out soft. This maps
each size to the nearest crisp step and records the scale so the change is
reviewable:

    <= 18  -> 12   body, captions, values
    19-30  -> 24   headings, numbers that matter, buttons
    31-42  -> 36   screen titles
    >= 43  -> 48   title screen

Run from the game folder:  python -I tools/snap_font_sizes.py [--check]
"""

from __future__ import annotations

import pathlib
import re
import sys

GAME = pathlib.Path(__file__).resolve().parents[1]
PATTERNS = ["scripts/**/*.gd", "scenes/**/*.tscn", "resources/ui/*.tres"]

GD_CALL = re.compile(r'(add_theme_font_size_override\(\s*"(?:font_size|normal_font_size|bold_font_size)"\s*,\s*)(\d+)(\s*\))')
TSCN_PROP = re.compile(r'^((?:theme_override_font_sizes/(?:font_size|normal_font_size)|[A-Za-z]+/font_sizes/font_size|default_font_size) = )(\d+)$', re.M)


def snap(size: int) -> int:
    if size <= 18:
        return 12
    if size <= 30:
        return 24
    if size <= 42:
        return 36
    return 48


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")
    check_only = "--check" in sys.argv
    changed_files = 0
    changes: dict[tuple[int, int], int] = {}
    for pattern in PATTERNS:
        for path in sorted(GAME.glob(pattern)):
            text = path.read_text(encoding="utf-8")

            def replace(match: re.Match) -> str:
                old = int(match.group(2))
                new = snap(old)
                if new != old:
                    changes[(old, new)] = changes.get((old, new), 0) + 1
                return f"{match.group(1)}{new}{match.group(3) if match.lastindex and match.lastindex >= 3 else ''}"

            updated = GD_CALL.sub(replace, text)
            updated = TSCN_PROP.sub(lambda m: f"{m.group(1)}{snap(int(m.group(2)))}" if True else "", updated)
            for match in TSCN_PROP.finditer(text):
                old = int(match.group(2))
                if snap(old) != old:
                    changes[(old, snap(old))] = changes.get((old, snap(old)), 0) + 1
            if updated != text:
                changed_files += 1
                if not check_only:
                    path.write_text(updated, encoding="utf-8", newline="\n")
    for (old, new), count in sorted(changes.items()):
        print(f"{old:>3} -> {new:<3} x{count}")
    print(f"{'would change' if check_only else 'changed'} {changed_files} files")


if __name__ == "__main__":
    main()
