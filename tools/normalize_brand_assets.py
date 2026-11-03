"""Normalize generated brand art into deterministic game assets."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
CONCEPT = ROOT / "assets" / "concept"

def cover_square(image: Image.Image, size: int) -> Image.Image:
    w, h = image.size
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    return image.crop((left, top, left + side, top + side)).resize((size, size), Image.LANCZOS)

def trim_alpha(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    box = alpha.getbbox()
    return image.crop(box) if box else image

# One icon emblem, safe inside Android rounded masks.
emblem = Image.open(CONCEPT / "branding" / "changzi_emblem_source.png").convert("RGBA")
icon_dir = ROOT / "assets" / "branding"
icon_dir.mkdir(parents=True, exist_ok=True)
master = cover_square(emblem, 512)
master.save(icon_dir / "icon_512.png", optimize=True)
sizes = [432, 256, 192, 128, 64, 48, 32, 16]
for size in sizes:
    master.resize((size, size), Image.LANCZOS).save(icon_dir / f"icon_{size}.png", optimize=True)
master.resize((256, 256), Image.LANCZOS).save(icon_dir / "changzi.ico", sizes=[(s, s) for s in sizes] + [(256, 256)])

# Final boss sprite: transparent, 256x256, feet on baseline.
boss = trim_alpha(Image.open(CONCEPT / "characters" / "smiling_archivist_sprite_source.png").convert("RGBA"))
boss.thumbnail((248, 248), Image.LANCZOS)
canvas = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
canvas.alpha_composite(boss, ((256 - boss.width) // 2, 256 - boss.height))
boss_dir = ROOT / "assets" / "sprites" / "bosses"
boss_dir.mkdir(parents=True, exist_ok=True)
canvas.save(boss_dir / "smiling_archivist.png", optimize=True)

# Lightless Sea backdrop: exact 1536x864, cover-cropped.
sea = Image.open(CONCEPT / "environments" / "lightless_sea_source.png").convert("RGB")
target = (1536, 864)
scale = max(target[0] / sea.width, target[1] / sea.height)
resized = sea.resize((round(sea.width * scale), round(sea.height * scale)), Image.LANCZOS)
left = (resized.width - target[0]) // 2
top = (resized.height - target[1]) // 2
resized.crop((left, top, left + target[0], top + target[1])).save(ROOT / "assets" / "backgrounds" / "lightless_sea.png", optimize=True)

print("icon", master.size, "boss", canvas.size, "sea", target)
