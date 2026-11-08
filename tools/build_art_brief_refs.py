"""Builds the reference sheets embedded in the art brief PDF (docs/art/refs/)."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "art" / "refs"
BG = (24, 28, 36, 255)
FONT = ImageFont.truetype("C:/Windows/Fonts/msyh.ttc", 18)


def sheet(items, scale=2, pad=16, label=True, bg=BG):
    imgs = []
    for path, caption in items:
        im = Image.open(ROOT / path).convert("RGBA")
        bbox = im.getbbox() or (0, 0, im.width, im.height)
        im = im.crop(bbox)
        im = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
        imgs.append((im, caption))
    h = max(i.height for i, _ in imgs) + pad * 2 + (28 if label else 0)
    w = sum(i.width for i, _ in imgs) + pad * (len(imgs) + 1)
    out = Image.new("RGBA", (w, h), bg)
    d = ImageDraw.Draw(out)
    x = pad
    for im, caption in imgs:
        out.alpha_composite(im, (x, h - pad - im.height - (28 if label else 0)))
        if label:
            d.text((x, h - pad - 22), caption, font=FONT, fill=(220, 220, 210, 255))
        x += im.width + pad
    return out


def grid(paths, cols, cell_w, captions=None):
    ims = [Image.open(ROOT / p).convert("RGB") for p in paths]
    rows = (len(ims) + cols - 1) // cols
    cell_h = int(cell_w * ims[0].height / ims[0].width)
    out = Image.new("RGB", (cols * cell_w, rows * (cell_h + (26 if captions else 0))), BG[:3])
    d = ImageDraw.Draw(out)
    for i, im in enumerate(ims):
        x, y = (i % cols) * cell_w, (i // cols) * (cell_h + (26 if captions else 0))
        out.paste(im.resize((cell_w, cell_h)), (x, y))
        if captions:
            d.text((x + 6, y + cell_h + 2), captions[i], font=FONT, fill=(220, 220, 210))
    return out


def vfx_strip(ids, frames_each=5):
    manifest = json.load(open(ROOT / "assets/vfx/vfx_manifest.json", encoding="utf-8"))["effects"]
    rows = []
    for i in ids:
        e = manifest[i]
        im = Image.open(ROOT / f"assets/vfx/{i}.png").convert("RGBA")
        fw, fh = e["frame_size"]
        c = e["columns"]
        n = e["frames"]
        tiles = []
        for k in range(0, n, max(1, n // frames_each))[:frames_each]:
            x, y = (k % c) * fw, (k // c) * fh
            tiles.append(im.crop((x, y, x + fw, y + fh)).resize((fw * 2, fh * 2), Image.NEAREST))
        w = sum(t.width for t in tiles)
        row = Image.new("RGBA", (w, max(t.height for t in tiles)), BG)
        x = 0
        for t in tiles:
            row.alpha_composite(t, (x, 0))
            x += t.width
        rows.append(row)
    W = max(r.width for r in rows)
    H = sum(r.height for r in rows)
    out = Image.new("RGBA", (W, H), BG)
    y = 0
    for r in rows:
        out.alpha_composite(r, (0, y))
        y += r.height
    return out


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    fr = "assets/sprites/player/frames/"
    sheet([("assets/sprites/player/player_idle.png", "待机"), (fr + "run_1.png", "跑"), (fr + "jump_1.png", "跳"),
           (fr + "attack_1.png", "攻击"), (fr + "dodge_0.png", "旧闪避"), (fr + "cast_0.png", "施法"),
           (fr + "hurt_0.png", "受击")]).save(OUT / "r1_player.png")
    en = "assets/sprites/enemies/"
    sheet([(en + "ink_hound.png", "墨犬"), (en + "hanging_scribe.png", "悬吊书吏"), (en + "choir_summoner.png", "唱诗召唤者"),
           (en + "mirror_sniper.png", "镜面狙击手"), (en + "breath_hound.png", "呼吸猎犬"), (en + "typo_beast.png", "错字巨兽")],
          scale=1).save(OUT / "r2_enemies.png")
    sheet([("assets/sprites/bosses/ink_archivist.png", "墨骸史官"), ("assets/sprites/bosses/lung_bell_guardian.png", "肺钟守卫"),
           ("assets/sprites/bosses/last_reader.png", "最后的读者")], scale=1).save(OUT / "r3_bosses.png")
    grid(["assets/backgrounds/pixel/ink_archive_far.png", "assets/backgrounds/pixel/ink_archive_mid.png"], 2, 640,
         ["第1章 远景（目标质量）", "第1章 中景（透明层）"]).save(OUT / "r4_ch1_pixel_bg.png")
    shots = ["artifacts/screens/ch2/ch2_entry_panorama.png", "artifacts/screens/ch3/ch3_entry_panorama.png",
             "artifacts/screens/ch4/ch4_entry_theater.png", "artifacts/screens/ch2/ch2_well_shaft.png"]
    grid(shots, 2, 640, ["第2章 入口（现状）", "第3章 入口（现状）", "第4章 入口（现状）", "第2章 纵井（现状）"]).save(OUT / "r5_current.png")
    tiles = Image.new("RGBA", (4 * (64 * 5 + 20), 32 * 5 + 30), BG)
    d = ImageDraw.Draw(tiles)
    for c in range(1, 5):
        t = Image.open(ROOT / f"assets/tiles/ch{c}/tiles.png").convert("RGBA").resize((320, 160), Image.NEAREST)
        tiles.alpha_composite(t, ((c - 1) * 340, 0))
        d.text(((c - 1) * 340, 164), f"第{c}章 地块 4×2（16px）", font=FONT, fill=(220, 220, 210))
    tiles.save(OUT / "r6_tiles.png")
    vfx_strip(["creature_eye", "creature_skull", "creature_wisp", "creature_jelly", "creature_snake", "creature_bat"]).save(OUT / "r7_creatures_placeholder.png")
    props = Image.new("RGBA", (384 * 2, 64 * 2 * 4), BG)
    for c in range(1, 5):
        p = Image.open(ROOT / f"assets/sprites/props/dressing_ch{c}.png").convert("RGBA").resize((768, 128), Image.NEAREST)
        props.alpha_composite(p, (0, (c - 1) * 128))
    props.save(OUT / "r8_props_placeholder.png")
    Image.open(ROOT / "artifacts/ui/15_hud_combat.png").convert("RGB").save(OUT / "r9_hud.png")
    print("refs ->", OUT)


if __name__ == "__main__":
    main()
