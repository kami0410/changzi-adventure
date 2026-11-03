"""Normalize the generated chapter-four art to game sizes."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
C = ROOT / "assets" / "concept"


def cover(image: Image.Image, size):
    scale = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize((round(image.width * scale), round(image.height * scale)), Image.LANCZOS)
    left = (resized.width - size[0]) // 2
    top = (resized.height - size[1]) // 2
    return resized.crop((left, top, left + size[0], top + size[1]))


def fit(image: Image.Image, size, content):
    alpha = image.getchannel("A")
    box = alpha.getbbox()
    if box:
        image = image.crop(box)
    image.thumbnail((content, content), Image.LANCZOS)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    canvas.alpha_composite(image, ((size[0] - image.width) // 2, size[1] - image.height))
    return canvas


cover(Image.open(C / "environments" / "smiling_theater_source.png").convert("RGB"), (1536, 864)).save(
    ROOT / "assets" / "backgrounds" / "smiling_theater.png", optimize=True
)
fit(Image.open(C / "characters" / "last_reader_source.png").convert("RGBA"), (256, 256), 248).save(
    ROOT / "assets" / "sprites" / "bosses" / "last_reader.png", optimize=True
)
fit(Image.open(C / "characters" / "mask_enemy_source.png").convert("RGBA"), (96, 96), 92).save(
    ROOT / "assets" / "sprites" / "enemies" / "mask_enemy.png", optimize=True
)
fit(Image.open(C / "characters" / "seat_husk_source.png").convert("RGBA"), (96, 96), 92).save(
    ROOT / "assets" / "sprites" / "enemies" / "seat_husk.png", optimize=True
)
print("chapter 4 art normalized")
