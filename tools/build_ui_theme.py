"""Write resources/ui/theme.tres and the shared UI styleboxes from one token set.

Direction: docs/memory/decisions/2026-11-02-ui-direction.md. Modal windows are
aged archive pages (paper) laid on an ink-dark desk; the HUD is a quiet ink
strip. Re-run after changing a token; every file below is generated.

Run from the game folder:  python -I tools/build_ui_theme.py
"""

from __future__ import annotations

import pathlib

GAME = pathlib.Path(__file__).resolve().parents[1]
UI = GAME / "resources" / "ui"

TOKENS = {
    "ink_night": (0.051, 0.071, 0.094),
    "paper": (0.788, 0.749, 0.651),
    "paper_dim": (0.725, 0.689, 0.598),
    "paper_shade": (0.612, 0.569, 0.478),
    "paper_deep": (0.659, 0.616, 0.522),
    "ink": (0.106, 0.122, 0.141),
    "ink_soft": (0.290, 0.290, 0.271),
    "cinnabar": (0.659, 0.196, 0.180),
    "cyan": (0.561, 0.910, 0.863),
    "bone": (0.910, 0.882, 0.812),
    "gold": (0.847, 0.706, 0.416),
    "violet": (0.600, 0.400, 0.820),
    "moss": (0.400, 0.640, 0.420),
    "rare": (0.380, 0.560, 0.840),
}


def color(name: str, alpha: float = 1.0) -> str:
    r, g, b = TOKENS[name]
    return f"Color({r:.3f}, {g:.3f}, {b:.3f}, {alpha:.3f})"


def flat(sub_id: str | None, bg: str, border: str | None = None, width: int = 0, margins=(0, 0, 0, 0),
         shadow: str | None = None, shadow_size: int = 0, shadow_offset=(0, 0), expand=0) -> list[str]:
    lines = [f'[sub_resource type="StyleBoxFlat" id="{sub_id}"]'] if sub_id else ['[resource]']
    left, top, right, bottom = margins
    if any(margins):
        lines += [f"content_margin_left = {left:.1f}", f"content_margin_top = {top:.1f}",
                  f"content_margin_right = {right:.1f}", f"content_margin_bottom = {bottom:.1f}"]
    lines.append(f"bg_color = {bg}")
    if border and width:
        lines += [f"border_width_left = {width}", f"border_width_top = {width}",
                  f"border_width_right = {width}", f"border_width_bottom = {width}",
                  f"border_color = {border}"]
    if expand:
        lines += [f"expand_margin_left = {expand:.1f}", f"expand_margin_top = {expand:.1f}",
                  f"expand_margin_right = {expand:.1f}", f"expand_margin_bottom = {expand:.1f}"]
    if shadow:
        lines += [f"shadow_color = {shadow}", f"shadow_size = {shadow_size}",
                  f"shadow_offset = Vector2({shadow_offset[0]}, {shadow_offset[1]})"]
    lines.append("anti_aliasing = false")
    return lines


def standalone(name: str, body: list[str]) -> None:
    text = '[gd_resource type="StyleBoxFlat" format=3]\n\n' + "\n".join(body) + "\n"
    (UI / f"{name}.tres").write_text(text, encoding="utf-8", newline="\n")


def build_styleboxes() -> None:
    # HUD and in-world cards stay ink-dark; rarity shows in the border colour.
    slot = dict(margins=(10, 6, 10, 6), shadow=color("ink_night", 0.6), shadow_size=0)
    standalone("slot_common", flat(None, color("ink_night", 0.86), color("bone", 0.22), 1, **slot))
    standalone("slot_rare", flat(None, color("ink_night", 0.86), color("rare", 0.9), 1, **slot))
    standalone("slot_epic", flat(None, color("ink_night", 0.86), color("violet", 0.9), 1, **slot))
    standalone("slot_legendary", flat(None, color("ink_night", 0.86), color("gold", 0.95), 1, **slot))
    standalone("slot_corrupt", flat(None, color("ink_night", 0.86), color("moss", 0.9), 1, **slot))
    standalone("slot_hover", flat(None, color("ink_night", 0.92), color("cyan", 0.95), 2, **slot))
    standalone("slot_selected", flat(None, color("ink_night", 0.95), color("bone", 1.0), 2, **slot))
    standalone("panel_inner", flat(None, color("paper_deep", 1.0), color("paper_shade", 1.0), 1, margins=(8, 8, 8, 8)))
    # Equipment cards inside paper pages: deeper paper, rarity on the border.
    page = dict(margins=(10, 6, 10, 6))
    standalone("card_common", flat(None, color("paper_deep", 1.0), color("ink_soft", 0.7), 1, **page))
    standalone("card_rare", flat(None, color("paper_deep", 1.0), "Color(0.180, 0.300, 0.560, 1)", 2, **page))
    standalone("card_epic", flat(None, color("paper_deep", 1.0), "Color(0.380, 0.180, 0.470, 1)", 2, **page))
    standalone("card_legendary", flat(None, color("paper_deep", 1.0), "Color(0.520, 0.380, 0.120, 1)", 2, **page))
    standalone("card_corrupt", flat(None, color("paper_deep", 1.0), "Color(0.200, 0.400, 0.220, 1)", 2, **page))
    standalone("card_hover", flat(None, color("paper_shade", 1.0), color("cinnabar", 1.0), 2, **page))
    standalone("card_selected", flat(None, color("paper_shade", 1.0), color("ink", 1.0), 2, **page))
    # Keyboard focus on a reward card: an underline, not a frame. A full
    # outline made the first unselected card read as already chosen.
    focus_body = [
        '[resource]',
        'content_margin_left = 10.0',
        'content_margin_top = 6.0',
        'content_margin_right = 10.0',
        'content_margin_bottom = 6.0',
        'bg_color = Color(0, 0, 0, 0)',
        'border_width_bottom = 3',
        f'border_color = {color("gold", 0.9)}',
        'anti_aliasing = false',
    ]
    (UI / "card_focus.tres").write_text(
        '[gd_resource type="StyleBoxFlat" format=3]\n\n' + "\n".join(focus_body) + "\n",
        encoding="utf-8", newline="\n")
    standalone("combo_card", flat(None, color("paper_deep", 1.0), color("gold", 1.0), 1, margins=(10, 8, 10, 8)))
    standalone("word_card_decoded", flat(None, color("paper_deep", 1.0), color("ink_soft", 0.8), 1, margins=(8, 6, 8, 6)))
    standalone("word_card_locked", flat(None, color("paper_shade", 1.0), color("ink_soft", 0.5), 1, margins=(8, 6, 8, 6)))
    standalone("bar_background", flat(None, color("ink_night", 0.95), color("bone", 0.18), 1))
    standalone("bar_health", flat(None, "Color(0.690, 0.180, 0.176, 1)", "Color(0.890, 0.380, 0.330, 1)", 1))
    standalone("bar_ink", flat(None, "Color(0.180, 0.560, 0.520, 1)", color("cyan", 1.0), 1))
    standalone("bar_corruption", flat(None, "Color(0.360, 0.190, 0.470, 1)", "Color(0.560, 0.380, 0.700, 1)", 1))
    standalone("bar_boss", flat(None, "Color(0.620, 0.150, 0.160, 1)", "Color(0.930, 0.420, 0.360, 1)", 1))


def build_theme() -> None:
    sub: list[str] = []
    # Paper page: paper on a 2 px ink edge (the page lies on the desk).
    sub += flat("page", color("paper_dim", 1.0), color("ink", 1.0), 2, margins=(22, 18, 22, 18),
                shadow=color("ink_night", 0.7), shadow_size=0, shadow_offset=(6, 6))
    sub.append("")
    sub += flat("button_normal", color("paper_dim", 0.0), color("ink", 0.85), 1, margins=(16, 6, 16, 6))
    sub.append("")
    sub += flat("button_hover", color("paper_deep", 1.0), color("cinnabar", 1.0), 2, margins=(16, 6, 16, 6))
    sub.append("")
    sub += flat("button_pressed", color("paper_shade", 1.0), color("cinnabar", 1.0), 2, margins=(16, 7, 16, 5))
    sub.append("")
    sub += flat("button_disabled", color("paper_dim", 0.0), color("ink_soft", 0.35), 1, margins=(16, 6, 16, 6))
    sub.append("")
    sub += flat("button_focus", "Color(0, 0, 0, 0)", color("cinnabar", 1.0), 2, expand=2)
    sub.append("")
    sub += flat("line_edit", color("paper", 1.0), color("ink", 0.9), 1, margins=(10, 6, 10, 6))
    sub.append("")
    sub += flat("line_edit_focus", "Color(0, 0, 0, 0)", color("cinnabar", 1.0), 2, expand=1)
    sub.append("")
    sub += flat("progress_bg", color("ink_night", 0.95), color("bone", 0.18), 1)
    sub.append("")
    sub += flat("progress_fill", "Color(0.180, 0.560, 0.520, 1)", color("cyan", 1.0), 1)
    sub.append("")
    sub += ['[sub_resource type="StyleBoxLine" id="rule"]', f"color = {color('paper_shade', 1.0)}",
            "thickness = 1", "grow_begin = 0.0", "grow_end = 0.0"]
    sub.append("")
    sub += ['[sub_resource type="StyleBoxLine" id="rule_v"]', f"color = {color('paper_shade', 1.0)}",
            "thickness = 1", "grow_begin = 0.0", "grow_end = 0.0", "vertical = true"]
    sub.append("")
    sub += flat("scroll_grabber", color("ink_soft", 0.6), None, 0, margins=(4, 0, 4, 0))
    sub.append("")
    sub += flat("scroll_track", color("paper_shade", 0.5), None, 0, margins=(4, 0, 4, 0))
    sub.append("")
    sub += flat("option_popup", color("paper", 1.0), color("ink", 1.0), 2, margins=(6, 6, 6, 6))
    sub.append("")

    props = [
        '[resource]',
        'default_font = ExtResource("1_font")',
        'default_font_size = 12',
        f'Button/colors/font_color = {color("ink", 1.0)}',
        f'Button/colors/font_hover_color = {color("cinnabar", 1.0)}',
        f'Button/colors/font_focus_color = {color("cinnabar", 1.0)}',
        f'Button/colors/font_pressed_color = {color("ink", 1.0)}',
        f'Button/colors/font_disabled_color = {color("ink_soft", 0.55)}',
        'Button/font_sizes/font_size = 24',
        'Button/styles/normal = SubResource("button_normal")',
        'Button/styles/hover = SubResource("button_hover")',
        'Button/styles/pressed = SubResource("button_pressed")',
        'Button/styles/disabled = SubResource("button_disabled")',
        'Button/styles/focus = SubResource("button_focus")',
        f'CheckButton/colors/font_color = {color("ink", 1.0)}',
        f'CheckButton/colors/font_hover_color = {color("cinnabar", 1.0)}',
        f'CheckButton/colors/font_focus_color = {color("cinnabar", 1.0)}',
        'CheckButton/font_sizes/font_size = 12',
        f'Label/colors/font_color = {color("ink", 1.0)}',
        'Label/font_sizes/font_size = 12',
        'Label/constants/line_spacing = 4',
        f'LineEdit/colors/font_color = {color("ink", 1.0)}',
        f'LineEdit/colors/font_placeholder_color = {color("ink_soft", 0.6)}',
        f'LineEdit/colors/caret_color = {color("cinnabar", 1.0)}',
        f'LineEdit/colors/selection_color = {color("cinnabar", 0.3)}',
        'LineEdit/font_sizes/font_size = 12',
        'LineEdit/styles/normal = SubResource("line_edit")',
        'LineEdit/styles/focus = SubResource("line_edit_focus")',
        f'TextEdit/colors/font_color = {color("ink", 1.0)}',
        'TextEdit/styles/normal = SubResource("line_edit")',
        'TextEdit/styles/focus = SubResource("line_edit_focus")',
        f'RichTextLabel/colors/default_color = {color("ink", 1.0)}',
        'RichTextLabel/font_sizes/normal_font_size = 12',
        'PanelContainer/styles/panel = SubResource("page")',
        'Panel/styles/panel = SubResource("page")',
        'HSeparator/styles/separator = SubResource("rule")',
        'VSeparator/styles/separator = SubResource("rule_v")',
        'ProgressBar/styles/background = SubResource("progress_bg")',
        'ProgressBar/styles/fill = SubResource("progress_fill")',
        'VScrollBar/styles/grabber = SubResource("scroll_grabber")',
        'VScrollBar/styles/grabber_highlight = SubResource("scroll_grabber")',
        'VScrollBar/styles/grabber_pressed = SubResource("scroll_grabber")',
        'VScrollBar/styles/scroll = SubResource("scroll_track")',
        f'OptionButton/colors/font_color = {color("ink", 1.0)}',
        'OptionButton/font_sizes/font_size = 12',
        'OptionButton/styles/normal = SubResource("button_normal")',
        'OptionButton/styles/hover = SubResource("button_hover")',
        'OptionButton/styles/focus = SubResource("button_focus")',
        'PopupMenu/styles/panel = SubResource("option_popup")',
        f'PopupMenu/colors/font_color = {color("ink", 1.0)}',
        f'PopupMenu/colors/font_hover_color = {color("cinnabar", 1.0)}',
        'PopupMenu/font_sizes/font_size = 12',
        f'SpinBox/colors/font_color = {color("ink", 1.0)}',
    ]
    count = sum(1 for line in sub if line.startswith("[sub_resource")) + 2
    head = [f'[gd_resource type="Theme" load_steps={count} format=3]', "",
            '[ext_resource type="FontFile" path="res://assets/fonts/fusion-pixel-12px-monospaced-zh_hans.ttf.woff2" id="1_font"]', ""]
    text = "\n".join(head + sub + props) + "\n"
    (UI / "theme.tres").write_text(text, encoding="utf-8", newline="\n")

    # HUD theme: same font, light text on ink strips, no paper.
    hud = [
        '[gd_resource type="Theme" load_steps=3 format=3]', "",
        '[ext_resource type="FontFile" path="res://assets/fonts/fusion-pixel-12px-monospaced-zh_hans.ttf.woff2" id="1_font"]', "",
    ]
    hud += flat("strip", color("ink_night", 0.82), None, 0, margins=(12, 8, 12, 8))
    hud += ["", '[resource]', 'default_font = ExtResource("1_font")', 'default_font_size = 12',
            f'Label/colors/font_color = {color("bone", 1.0)}',
            f'Label/colors/font_shadow_color = {color("ink_night", 0.95)}',
            'Label/constants/shadow_offset_x = 1', 'Label/constants/shadow_offset_y = 1',
            'Label/font_sizes/font_size = 12',
            'PanelContainer/styles/panel = SubResource("strip")',
            'ProgressBar/styles/background = SubResource("strip")']
    (UI / "hud_theme.tres").write_text("\n".join(hud) + "\n", encoding="utf-8", newline="\n")

    # Ink theme for screens drawn straight on the dark desk (title screen):
    # bone text, cyan focus, no paper. Same button shapes as the paper theme.
    ink: list[str] = [
        '[gd_resource type="Theme" load_steps=7 format=3]', "",
        '[ext_resource type="FontFile" path="res://assets/fonts/fusion-pixel-12px-monospaced-zh_hans.ttf.woff2" id="1_font"]', "",
    ]
    ink += flat("btn", color("ink_night", 0.0), color("bone", 0.55), 1, margins=(16, 6, 16, 6))
    ink.append("")
    ink += flat("btn_hover", color("ink_night", 0.6), color("cyan", 1.0), 2, margins=(16, 6, 16, 6))
    ink.append("")
    ink += flat("btn_pressed", color("ink_night", 0.9), color("cyan", 1.0), 2, margins=(16, 7, 16, 5))
    ink.append("")
    ink += flat("btn_focus", "Color(0, 0, 0, 0)", color("cyan", 1.0), 2, expand=2)
    ink.append("")
    ink += flat("btn_disabled", color("ink_night", 0.0), color("bone", 0.2), 1, margins=(16, 6, 16, 6))
    ink += ["", '[resource]', 'default_font = ExtResource("1_font")', 'default_font_size = 12',
            f'Label/colors/font_color = {color("bone", 1.0)}', 'Label/font_sizes/font_size = 12',
            f'Button/colors/font_color = {color("bone", 1.0)}',
            f'Button/colors/font_hover_color = {color("cyan", 1.0)}',
            f'Button/colors/font_focus_color = {color("cyan", 1.0)}',
            f'Button/colors/font_pressed_color = {color("bone", 1.0)}',
            f'Button/colors/font_disabled_color = {color("bone", 0.35)}',
            'Button/font_sizes/font_size = 24',
            'Button/styles/normal = SubResource("btn")', 'Button/styles/hover = SubResource("btn_hover")',
            'Button/styles/pressed = SubResource("btn_pressed")', 'Button/styles/focus = SubResource("btn_focus")',
            'Button/styles/disabled = SubResource("btn_disabled")',
            f'CheckButton/colors/font_color = {color("bone", 0.85)}',
            f'CheckButton/colors/font_hover_color = {color("cyan", 1.0)}',
            f'CheckButton/colors/font_focus_color = {color("cyan", 1.0)}',
            'CheckButton/font_sizes/font_size = 12',
            'CheckButton/styles/focus = SubResource("btn_focus")']
    (UI / "ink_theme.tres").write_text("\n".join(ink) + "\n", encoding="utf-8", newline="\n")


def main() -> None:
    build_styleboxes()
    build_theme()
    print("theme and styleboxes written to", UI)


if __name__ == "__main__":
    main()
