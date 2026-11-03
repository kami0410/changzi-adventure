"""Recolour modal scenes for the archive-page UI (ink text on paper).

Maps the old light-on-dark text colours in modal scenes to ink roles, turns
the shade behind each modal into the shared ink-night wash, removes the
spaced-out uppercase kicker labels, and gives the HUD its own ink theme.
Direction: docs/memory/decisions/2026-11-02-ui-direction.md.

Run from the game folder:  python -I tools/recolor_ui_scenes.py
"""

from __future__ import annotations

import pathlib
import re

GAME = pathlib.Path(__file__).resolve().parents[1]

INK = "Color(0.106, 0.122, 0.141, 1)"
INK_SOFT = "Color(0.29, 0.29, 0.271, 1)"
INK_FAINT = "Color(0.42, 0.4, 0.36, 1)"
CINNABAR = "Color(0.659, 0.196, 0.18, 1)"
SEAL_GOLD = "Color(0.52, 0.38, 0.12, 1)"
VERDIGRIS = "Color(0.16, 0.42, 0.39, 1)"
SHADE = "Color(0.051, 0.071, 0.094, 0.84)"

# Old text colour (as written in the scenes) -> ink role.
TEXT_MAP = {
    "Color(0.94, 0.92, 0.84, 1)": INK,
    "Color(0.92, 0.9, 0.82, 1)": INK,
    "Color(0.8, 0.78, 0.7, 1)": INK_SOFT,
    "Color(0.5, 0.56, 0.58, 1)": INK_FAINT,
    "Color(0.52, 0.58, 0.6, 1)": INK_FAINT,
    "Color(0.62, 0.7, 0.72, 1)": INK_SOFT,
    "Color(0.28, 0.88, 0.8, 1)": CINNABAR,
    "Color(0.35, 0.95, 0.86, 1)": CINNABAR,
    "Color(0.85, 0.68, 0.3, 1)": SEAL_GOLD,
    "Color(0.86, 0.82, 0.62, 1)": SEAL_GOLD,
    "Color(0.55, 0.45, 0.22, 1)": SEAL_GOLD,
}

MODAL_SCENES = [
    "scenes/ui/codex.tscn", "scenes/ui/inventory_ui.tscn", "scenes/ui/dialogue_ui.tscn",
    "scenes/ui/pause_menu.tscn", "scenes/hub/shop_ui.tscn", "scenes/ui/settings_menu.tscn",
    "scenes/ui/ending_screen.tscn",
]

SHADE_RE = re.compile(r'(\[node name="(?:Backdrop|Dim)" type="ColorRect"[^\]]*\][^\[]*?)color = Color\([^)]*\)', re.S)
KICKER_RE = re.compile(r'text = "[A-Z](?: [A-Z\']+)+(?:   [A-Z\'](?: [A-Z\']+)*)*"')


def recolor(path: pathlib.Path) -> int:
    text = path.read_text(encoding="utf-8")
    original = text
    for old, new in TEXT_MAP.items():
        text = text.replace(f"theme_override_colors/font_color = {old}", f"theme_override_colors/font_color = {new}")
    # Header rules (ColorRect accents) become cinnabar seals.
    text = re.sub(r'(\[node name="Rule" type="ColorRect"[^\]]*\][^\[]*?)color = Color\([^)]*\)',
                  lambda m: f"{m.group(1)}color = {CINNABAR}", text, flags=re.S)
    text = SHADE_RE.sub(lambda m: f"{m.group(1)}color = {SHADE}", text)
    # Spaced-out uppercase kickers ("A R C H I V E   S U S P E N D E D") carry no information.
    text = KICKER_RE.sub('text = ""', text)
    # The pause title had a dark outline for dark backgrounds; ink on paper needs none.
    text = text.replace("theme_override_colors/font_outline_color = Color(0.01, 0.02, 0.035, 1)\n", "")
    if text != original:
        path.write_text(text, encoding="utf-8", newline="\n")
        return 1
    return 0


def hud_theme() -> int:
    path = GAME / "scenes/ui/hud.tscn"
    text = path.read_text(encoding="utf-8")
    original = text
    text = text.replace('[ext_resource type="Theme" path="res://resources/ui/theme.tres" id="2_h022r"]',
                        '[ext_resource type="Theme" path="res://resources/ui/hud_theme.tres" id="2_h022r"]')
    if text != original:
        path.write_text(text, encoding="utf-8", newline="\n")
        return 1
    return 0


def main() -> None:
    changed = sum(recolor(GAME / rel) for rel in MODAL_SCENES)
    changed += hud_theme()
    print(f"recoloured {changed} scenes")


if __name__ == "__main__":
    main()
