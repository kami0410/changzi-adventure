"""Report game text characters that the Ark Pixel font cannot draw.

Godot falls back to a system font for missing glyphs, so they render in a
different, non-pixel style (or as tofu on devices without CJK fonts).

Run from the game folder:  python tools/font_coverage.py
"""

from __future__ import annotations

import collections
import pathlib
import sys

from fontTools.ttLib import TTFont

GAME = pathlib.Path(__file__).resolve().parents[1]
FONT = GAME / "assets" / "fonts" / "fusion-pixel-12px-monospaced-zh_hans.ttf.woff2"
PATTERNS = ["scripts/**/*.gd", "resources/**/*.tres", "scenes/**/*.tscn"]


def interesting(ch: str) -> bool:
    code = ord(ch)
    return code >= 0x2000 and not ch.isspace()


def main() -> None:
    cmap = TTFont(str(FONT)).getBestCmap()
    missing: collections.Counter[str] = collections.Counter()
    where: dict[str, set[str]] = collections.defaultdict(set)
    for pattern in PATTERNS:
        for path in GAME.glob(pattern):
            text = path.read_text(encoding="utf-8", errors="ignore")
            for ch in text:
                if interesting(ch) and ord(ch) not in cmap:
                    missing[ch] += 1
                    where[ch].add(path.name)
    sys.stdout.reconfigure(encoding="utf-8")
    print(f"distinct missing characters: {len(missing)}, occurrences: {sum(missing.values())}")
    for ch, count in missing.most_common():
        print(f"{ch} U+{ord(ch):04X} x{count}  {', '.join(sorted(where[ch])[:4])}")


if __name__ == "__main__":
    main()
