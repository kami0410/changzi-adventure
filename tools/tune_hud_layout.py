"""Tighten the HUD layout for the 12/24 px pixel type scale.

The HUD was laid out for 16-22 px text; after snapping to 12/24 the panels
were half empty. This shrinks them to their content, puts health/ink/
corruption values on the same line as their bars, and gives the boss bar a
proper weight. Node names and paths stay the same (hud.gd and tests use them).

Run from the game folder:  python -I tools/tune_hud_layout.py
"""

from __future__ import annotations

import pathlib
import re

GAME = pathlib.Path(__file__).resolve().parents[1]
HUD = GAME / "scenes" / "ui" / "hud.tscn"

BONE = "Color(0.91, 0.882, 0.812, 1)"
BONE_DIM = "Color(0.62, 0.64, 0.64, 1)"
CYAN = "Color(0.561, 0.91, 0.863, 1)"
GOLD = "Color(0.847, 0.706, 0.416, 1)"
DANGER = "Color(0.93, 0.42, 0.36, 1)"


def set_block(text: str, node: str, props: dict[str, str]) -> str:
    """Rewrites properties of one [node name="node" ...] block (adds missing ones)."""
    pattern = re.compile(r'(\[node name="%s"[^\]]*\]\n)(.*?)(?=\n\[|\Z)' % re.escape(node), re.S)
    match = pattern.search(text)
    if match is None:
        raise SystemExit(f"node {node} not found")
    lines = match.group(2).split("\n")
    keys = {line.split(" = ")[0]: i for i, line in enumerate(lines) if " = " in line}
    for key, value in props.items():
        if value is None:
            if key in keys:
                lines[keys[key]] = ""
            continue
        if key in keys:
            lines[keys[key]] = f"{key} = {value}"
        else:
            lines.append(f"{key} = {value}")
    body = "\n".join(line for line in lines if line != "")
    return text[: match.start(2)] + body + text[match.end(2):]


def main() -> None:
    text = HUD.read_text(encoding="utf-8")
    # Top-left vitals: compact strip.
    text = set_block(text, "TopLeft", {
        "custom_minimum_size": "Vector2(236, 98)",
        "offset_left": "16.0", "offset_top": "14.0", "offset_right": "252.0", "offset_bottom": "112.0",
    })
    text = set_block(text, "Name", {"theme_override_colors/font_color": BONE})
    for label, color in (("Health", BONE), ("Ink", BONE), ("Corruption", BONE_DIM)):
        text = set_block(text, label, {"theme_override_colors/font_color": color})
    for bar in ("HealthBar", "InkBar", "CorruptionBar"):
        text = set_block(text, bar, {"custom_minimum_size": "Vector2(0, 6)"})
    # Top-right chapter block.
    text = set_block(text, "TopRight", {
        "custom_minimum_size": "Vector2(260, 98)",
        "offset_left": "-276.0", "offset_top": "14.0", "offset_right": "-16.0", "offset_bottom": "112.0",
    })
    text = set_block(text, "Region", {"theme_override_colors/font_color": CYAN})
    text = set_block(text, "Progress", {"theme_override_colors/font_color": GOLD})
    text = set_block(text, "Objective", {"theme_override_colors/font_color": BONE})
    text = set_block(text, "Score", {"theme_override_colors/font_color": BONE_DIM})
    # Boss bar: wide, heavy, centred under the top edge.
    text = set_block(text, "BossPanel", {
        "custom_minimum_size": "Vector2(560, 46)",
        "offset_left": "-280.0", "offset_top": "14.0", "offset_right": "280.0", "offset_bottom": "60.0",
    })
    text = set_block(text, "BossName", {"theme_override_colors/font_color": DANGER, "theme_override_font_sizes/font_size": "12"})
    text = set_block(text, "BossBar", {"custom_minimum_size": "Vector2(0, 10)"})
    # Bottom slots: slimmer cards, lifted off the edge.
    text = set_block(text, "BottomSlots", {
        "custom_minimum_size": "Vector2(760, 52)",
        "offset_left": "-380.0", "offset_top": "-80.0", "offset_right": "380.0", "offset_bottom": "-28.0",
        "theme_override_constants/separation": "8",
    })
    for card in ("WeaponCard1", "WeaponCard2", "PhraseCard1", "PhraseCard2"):
        text = set_block(text, card, {"custom_minimum_size": "Vector2(184, 52)"})
    for caption in ("WeaponCaption1", "WeaponCaption2", "PhraseCaption1", "PhraseCaption2"):
        text = set_block(text, caption, {"theme_override_colors/font_color": BONE_DIM})
    for value in ("WeaponValue1", "WeaponValue2", "PhraseValue1", "PhraseValue2"):
        text = set_block(text, value, {"theme_override_colors/font_color": BONE})
    for status in ("PhraseStatus1", "PhraseStatus2"):
        text = set_block(text, status, {"theme_override_colors/font_color": CYAN})
    text = set_block(text, "ControlsHint", {"theme_override_colors/font_color": BONE_DIM})
    # Pickup / status toast: bone text with ink outline, under the top blocks.
    text = set_block(text, "Message", {
        "offset_top": "128.0", "offset_bottom": "160.0",
        "theme_override_colors/font_color": GOLD,
        "theme_override_colors/font_outline_color": "Color(0.051, 0.071, 0.094, 1)",
        "theme_override_constants/outline_size": "6",
    })
    HUD.write_text(text, encoding="utf-8", newline="\n")
    print("hud layout tuned")


if __name__ == "__main__":
    main()
