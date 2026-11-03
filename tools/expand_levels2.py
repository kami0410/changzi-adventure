"""Expand each chapter again: 6 combat rooms + boss, 12,000 px wide."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "scenes" / "levels"
LEVELS = {
    "biome_1.tscn": ("ink_archive_fifth", "ink_archive_sixth"),
    "biome_breathing.tscn": ("breathing_ruins_fifth", "breathing_ruins_sixth"),
    "lightless_sea.tscn": ("lightless_sea_fifth", "lightless_sea_sixth"),
    "smiling_theater.tscn": ("smiling_theater_fifth", "smiling_theater_sixth"),
}

def room(name, x, room_id):
    return f'''[node name="{name}" parent="." instance=ExtResource("1_room")]
position = Vector2({x}, 280)
room_id = &"{room_id}"

'''

def platform(name, x, y):
    return f'''[node name="{name}" type="StaticBody2D" parent="."]
position = Vector2({x}, {y})

[node name="Visual" type="ColorRect" parent="{name}"]
offset_left = -120.0
offset_top = -12.0
offset_right = 120.0
offset_bottom = 12.0
mouse_filter = 2
color = Color(0.2, 0.18, 0.2, 1)

[node name="CollisionShape2D" type="CollisionShape2D" parent="{name}"]
shape = SubResource("RectangleShape2D_platform")

'''

for file_name, (fifth_id, sixth_id) in LEVELS.items():
    path = ROOT / file_name
    text = path.read_text(encoding="utf-8")
    text = text.replace("size = Vector2(8400, 80)", "size = Vector2(12000, 80)")
    text = text.replace("position = Vector2(4200, 40)", "position = Vector2(6000, 40)")
    text = text.replace("offset_right = 8400.0", "offset_right = 12000.0")
    text = text.replace("position = Vector2(7040, 280)", "position = Vector2(9600, 280)")
    text = text.replace("world_width = 8400.0", "world_width = 12000.0")
    marker = '[node name="MemoryStele"'
    if marker not in text:
        marker = '[node name="SpawnPoint"'
    addition = (room("RoomFifth", 7040, fifth_id) + room("RoomSixth", 8320, sixth_id)
                + platform("PlatformFifth", 7920, 440) + platform("PlatformSixth", 9040, 460))
    text = text.replace(marker, addition + marker, 1)
    path.write_text(text, encoding="utf-8")
    print("expanded again", file_name)
