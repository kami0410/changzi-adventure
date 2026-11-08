"""Normalizes the 2026-11-08 art delivery (art_inbox/) into game assets.

The pack was drawn against docs/art/昌子大冒险-美术需求清单.pdf. Every image
is re-saved as RGBA with binary alpha (the delivery uses palette PNGs with a
transparent index) and moved to the folder the game loads from:

- creatures: 10 monsters x 6 action strips -> assets/sprites/creatures/<id>/
  plus creatures.json (frame size, frame counts, union opaque rect).
- player: roll / air dash / finisher strips -> assets/sprites/player/frames/.
  The air dash was delivered at half the hero's scale (2x nearest) and the
  finisher about 25% larger (0.8x nearest) so all poses share one body size.
- region mid layers -> assets/backgrounds/layers/ch<c>_mid_<theme>.png. The
  far paintings feed tools/build_region_backdrops.py.
- props, elevator parts, affix icons, title key art, 阿砚 (forge god) sprite
  and portraits.

- terrain tiles: the delivered atlases keep the 4x2 layout but every tile
  carries a 1 px dark outline (a seam every 16 px once tiled) and only the
  row-1 ground/platform tiles have the bright walkable top line. The repair
  drops the outline, copies the top line onto both variants and thickens the
  4 px platform slab into a 16 px block so the hanging tile below attaches.

Usage: python tools/import_art_pack.py
"""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
INBOX = ROOT / "art_inbox"
ASSETS = ROOT / "assets"

CREATURES = [
    "watcher_eye", "ink_wisp", "skull_lantern", "abyss_jelly", "name_snake", "echo_bat",
    "rust_bellman", "drowned_scribe", "spine_centipede", "string_puppet",
]
ANIMS = {"idle": 4, "move": 4, "windup": 2, "attack": 3, "hurt": 1, "death": 5}
FPS = {"idle": 7, "move": 10, "windup": 8, "attack": 12, "hurt": 10, "death": 10}
THEMES = {
    2: ["ruins", "vault", "well", "boss"],
    3: ["shore", "library", "well", "boss"],
    4: ["stage", "seats", "fly", "boss"],
}


def rgba(path: Path) -> Image.Image:
    """Palette PNG -> RGBA with alpha forced to 0/255."""
    im = Image.open(path).convert("RGBA")
    a = im.getchannel("A").point(lambda v: 255 if v >= 128 else 0)
    im.putalpha(a)
    # Fully transparent pixels get a neutral colour so filtering never bleeds.
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            if px[x, y][3] == 0:
                px[x, y] = (0, 0, 0, 0)
    return im


def frames(strip: Image.Image, count: int) -> list[Image.Image]:
    w = strip.width // count
    return [strip.crop((i * w, 0, (i + 1) * w, strip.height)) for i in range(count)]


def import_creatures() -> None:
    out_root = ASSETS / "sprites" / "creatures"
    manifest = {}
    for cid in CREATURES:
        out = out_root / cid
        out.mkdir(parents=True, exist_ok=True)
        union = None
        size = None
        anims = {}
        for anim, count in ANIMS.items():
            strip = rgba(INBOX / f"enemy_{cid}_{anim}.png")
            cells = frames(strip, count)
            size = cells[0].size
            strip.save(out / f"{anim}.png", optimize=True)
            for cell in cells:
                box = cell.getbbox()
                if box and anim != "death":
                    union = box if union is None else (
                        min(union[0], box[0]), min(union[1], box[1]),
                        max(union[2], box[2]), max(union[3], box[3]))
            anims[anim] = {"frames": count, "fps": FPS[anim]}
        manifest[cid] = {
            "frame_size": list(size),
            "opaque_rect": [union[0], union[1], union[2] - union[0], union[3] - union[1]],
            "anims": anims,
        }
    (out_root / "creatures.json").write_text(json.dumps(manifest, indent=1, ensure_ascii=False), encoding="utf-8")
    print("creatures:", len(manifest))


def import_player() -> None:
    out = ASSETS / "sprites" / "player" / "frames"
    roll = frames(rgba(INBOX / "player_roll.png"), 8)
    for i, f in enumerate(roll):
        f.save(out / f"roll_{i}.png")
    dash = frames(rgba(INBOX / "player_airdash.png"), 3)
    for i, f in enumerate(dash):
        f.resize((f.width * 2, f.height * 2), Image.NEAREST).save(out / f"airdash_{i}.png")
    fin = frames(rgba(INBOX / "player_finisher.png"), 5)
    for i, f in enumerate(fin):
        f.resize((128, 128), Image.NEAREST).save(out / f"finisher_{i}.png")
    print("player: roll 8, airdash 3, finisher 5")


def import_layers() -> None:
    out = ASSETS / "backgrounds" / "layers"
    for chapter, themes in THEMES.items():
        for theme in themes:
            rgba(INBOX / f"ch{chapter}_{theme}_mid.png").save(out / f"ch{chapter}_mid_{theme}.png", optimize=True)
    for old in out.glob("ch*_mid_[ab].png"):
        old.unlink()
        imp = old.with_suffix(".png.import")
        if imp.exists():
            imp.unlink()
    print("mid layers: 12")


def import_props_and_parts() -> None:
    props = ASSETS / "sprites" / "props"
    for chapter in range(1, 5):
        im = rgba(INBOX / f"props_ch{chapter}.png")
        # Bottom-align every 64 px slot so props stand on their surface.
        fixed = Image.new("RGBA", im.size, (0, 0, 0, 0))
        for i, cell in enumerate(frames(im, im.width // 64)):
            box = cell.getbbox()
            if box:
                piece = cell.crop(box)
                fixed.alpha_composite(piece, (i * 64 + (64 - piece.width) // 2, 64 - piece.height))
        fixed.save(props / f"dressing_ch{chapter}.png", optimize=True)
    for name in ["lift_car", "lift_panel_idle", "lift_panel_active", "lift_rail"]:
        rgba(INBOX / f"{name}.png").save(props / f"{name}.png", optimize=True)
    icons = ASSETS / "ui" / "icons"
    icons.mkdir(parents=True, exist_ok=True)
    for name in ["affix_elite", "affix_swift", "affix_horde"]:
        rgba(INBOX / f"{name}.png").save(icons / f"{name}.png", optimize=True)
    print("props 4, lift parts 4, affix icons 3")


def import_tiles() -> None:
    for chapter in range(1, 5):
        src = rgba(INBOX / f"tiles_ch{chapter}.png")
        tiles = {(c, r): src.crop((c * 16, r * 16, c * 16 + 16, r * 16 + 16)) for c in range(4) for r in range(2)}

        def col(t, x):
            return t.crop((x, 0, x + 1, 16))

        def row(t, y):
            return t.crop((0, y, 16, y + 1))

        for key in [(0, 0), (1, 0), (0, 1), (1, 1), (2, 0), (2, 1)]:
            t = tiles[key]
            t.paste(col(t, 1), (0, 0))
            t.paste(col(t, 14), (15, 0))
        for key in [(1, 0), (1, 1)]:
            tiles[key].paste(row(tiles[key], 1), (0, 0))
        if chapter in (2, 3):
            # The rubble/reef fills are speckled; tiled every 16 px the specks
            # form a dot grid. Half-blend with a wrapped median calms them.
            for key in [(0, 0), (0, 1), (1, 0), (1, 1)]:
                t = tiles[key]
                wrap = Image.new("RGBA", (48, 48))
                for dx in range(3):
                    for dy in range(3):
                        wrap.paste(t, (dx * 16, dy * 16))
                calm = wrap.filter(ImageFilter.MedianFilter(3)).crop((16, 16, 32, 32))
                keep_top = t.crop((0, 0, 16, 2))
                tiles[key] = Image.blend(t, calm, 0.85 if chapter == 2 else 0.6)
                tiles[key].paste(keep_top, (0, 0))
        tiles[(0, 0)].paste(row(tiles[(0, 1)], 0), (0, 0))
        tiles[(2, 0)].paste(row(tiles[(2, 1)], 0), (0, 0))
        for key, fill_key in [((2, 0), (1, 0)), ((2, 1), (1, 1))]:
            body = tiles[fill_key].crop((0, 4, 16, 16))
            body = Image.blend(body, Image.new("RGBA", body.size, (6, 8, 12, 255)), 0.35)
            tiles[key].paste(body, (0, 4))
            tiles[key].paste(Image.new("RGBA", (16, 1), (11, 15, 20, 255)), (0, 15))
        out = Image.new("RGBA", (64, 32), (0, 0, 0, 0))
        for (c, r), t in tiles.items():
            out.paste(t, (c * 16, r * 16))
        out.save(ASSETS / "tiles" / f"ch{chapter}" / "tiles.png")
    print("tiles: 4 chapters repaired")


def import_title_and_ayan() -> None:
    key = Image.open(INBOX / "title_keyart.png").convert("RGB")
    key.save(ASSETS / "backgrounds" / "title_keyart.webp", lossless=True, method=6)
    # 阿砚 · 锻造之神: in-world sprite (128 native), dialogue pixel portrait
    # (192x256, upper body) and the 800x1000 painted portrait (native crop).
    sprite = rgba(INBOX / "forge_god_sprite.png")
    box = sprite.getbbox()
    piece = sprite.crop(box)
    canvas = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    canvas.alpha_composite(piece, ((128 - piece.width) // 2, 128 - piece.height))
    canvas.save(ASSETS / "sprites" / "npcs" / "ayan.png")
    portrait = Image.open(INBOX / "forge_god_portrait.png").convert("RGB")
    portrait.crop((112, 0, 912, 1000)).save(ASSETS / "portraits" / "ayan.png")
    upper = portrait.crop((176, 20, 848, 916)).resize((192, 256), Image.LANCZOS).convert("RGBA")
    upper.save(ASSETS / "portraits" / "pixel" / "ayan.png")
    print("title key art, 阿砚 sprite + portraits")


def main() -> None:
    import_creatures()
    import_player()
    import_layers()
    import_props_and_parts()
    import_tiles()
    import_title_and_ayan()


if __name__ == "__main__":
    main()
