"""Expand the four chapter maps from 3 rooms to 4 combat rooms + boss."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "scenes" / "levels"
LEVELS = {
    "biome_1.tscn": "ink_archive_fourth",
    "biome_breathing.tscn": "breathing_ruins_fourth",
    "lightless_sea.tscn": "lightless_sea_fourth",
    "smiling_theater.tscn": "smiling_theater_fourth",
}

PLATFORMS = """
[node name="PlatformBranch" type="StaticBody2D" parent="."]
position = Vector2(5360, 460)

[node name="Visual" type="ColorRect" parent="PlatformBranch"]
offset_left = -120.0
offset_top = -12.0
offset_right = 120.0
offset_bottom = 12.0
mouse_filter = 2
color = Color(0.2, 0.18, 0.2, 1)

[node name="CollisionShape2D" type="CollisionShape2D" parent="PlatformBranch"]
shape = SubResource("RectangleShape2D_platform")

[node name="PlatformTreasure" type="StaticBody2D" parent="."]
position = Vector2(6640, 440)

[node name="Visual" type="ColorRect" parent="PlatformTreasure"]
offset_left = -120.0
offset_top = -12.0
offset_right = 120.0
offset_bottom = 12.0
mouse_filter = 2
color = Color(0.18, 0.16, 0.19, 1)

[node name="CollisionShape2D" type="CollisionShape2D" parent="PlatformTreasure"]
shape = SubResource("RectangleShape2D_platform")
"""

for file_name, room_id in LEVELS.items():
    path = ROOT / file_name
    text = path.read_text(encoding="utf-8")
    text = text.replace("size = Vector2(5760, 80)", "size = Vector2(8400, 80)")
    text = text.replace("position = Vector2(2880, 40)", "position = Vector2(4200, 40)")
    text = text.replace("offset_right = 5760.0", "offset_right = 8400.0")
    text = text.replace('position = Vector2(4480, 280)', 'position = Vector2(7040, 280)')
    marker = '[node name="MemoryStele"'
    if marker not in text:
        marker = '[node name="SpawnPoint"'
    addition = f'''[node name="RoomFourth" parent="." instance=ExtResource("1_room")]
position = Vector2(5760, 280)
room_id = &"{room_id}"

{PLATFORMS}

'''
    text = text.replace(marker, addition + marker, 1)
    path.write_text(text, encoding="utf-8")
    print("expanded", file_name)
