---
name: sprite-float-blur-fix
description: 角色浮空、像素发糊、Boss 场景空白的根因与修复方案（未实施；NPC 已回退原尺寸）
type: system
status: archived
updated: 2026-11-02
load_when: 修角色贴图位置/缩放/清晰度、脚底阴影、Boss 场景背景时
---

# 角色浮空与像素发糊：诊断与修复方案

> 2026-11-02 已在 0.9.0 修复，见 [画面打磨](../sessions/2026-11-02-visual-polish.md)。下文保留为诊断记录。

## 现状

- 2026-11-02：NPC 放大到 1.55 后浮空约 44 px、像素发糊。按用户要求**已回退**到原值
  （`scripts/hub/npc.gd`：`scale 1.1`、`offset (0, -48)`，与上次提交一致）。
  原值下贴图底边正好在地面；但白榆贴图底部有 7 行透明，原值下也浮约 8 px（闻烬 2 行，约 2 px）。
- 下面其余问题只记录，**没有修**。用户要求先做核心玩法，之后再按本文件修。

## 根因 1：`Sprite2D.offset` 的单位算错（浮空或陷地）

`Sprite2D.offset` 在**贴图像素空间**，绘制时还会乘 `scale`。`centered = true` 时，
贴图第 r 行像素的本地 y = `(offset.y - tex_h / 2 + r) * scale`。

现有代码把“缩放后的高度”写进了 offset，只有 `scale == 1` 时才对：

- `scripts/game.gd` `_apply_art`：`offset.y = 16 - tex_h * 0.5 * art_scale`
- `scripts/enemies/enemy.gd` `_attach_scene_art`：同一公式
- NPC 1.55 版本也是同一错误（已回退）

脚底误差（碰撞体底部 y = 16 减去贴图底边）= `16 - s * (16 + tex_h / 2 * (1 - s))`：

| 对象 | 贴图 | scale | 结果 |
|---|---|---|---|
| 普通敌人 | 96 | 1.05 | 浮约 2 px |
| 镜面狙手 / 残页群 | 96 | 1.2 | 浮约 8 px（残页群是飞行单位，悬空本身是设计） |
| 错字巨兽 | 96 | 1.3 | 浮约 14 px |
| 第二章 Boss 肺钟守卫（借用 typo_beast） | 96 | 2.15 | 浮约 100 px |
| 墨骸史官 | 256 | 0.82 | 陷进地面约 16 px |
| 最后的读者 / 笑面史官 | 256 | 0.9 | 陷进地面约 10 px |
| NPC（1.55 版，已回退） | 96 | 1.55 | 浮约 44 px |

贴图底部的透明行也没算：baiyu 7 行、mask_enemy 3 行、wenjin 2 行、seat_husk 2 行、mirror_sniper 1 行。

## 根因 2：`ActorMotion` 阴影少乘了 scale（看起来悬在影子上方）

- `scripts/presentation/actor_motion.gd` `_draw_shadow`：
  `foot_y = root.y + top_left.y + size.y * scale.y`，
  应为 `root.y + (top_left.y + 最低不透明行) * scale.y`。
- 玩家：脚底实际在 y ≈ 15.6，阴影画在 y ≈ 30，低了约 14 px，画进了地面。NPC 低约 8 px。
- `_squash` 以节点原点为轴缩放，不是以脚底为轴；落地压扁时脚底会上下动几像素。
  应把 `draw_set_transform` 的原点放在脚底。

## 根因 3：像素发糊、不均匀

1. **非整数缩放 + 最近邻**：96 px 贴图按 1.05/1.1/1.2/1.3/1.55/2.15 显示，
   有的像素 1 px 宽、有的 2 px 宽，轮廓抖、细节糊。
2. **切块旋转**：`ActorMotion` 把贴图切成头/躯干/腿后旋转（前倾、摆腿、点头）并非等比压扁，
   最近邻采样下边缘锯齿闪烁。
3. **窗口拉伸**：`stretch/mode = canvas_items`，1920×1080 时再整体 ×1.5，更不均匀。
4. **源图**：生成图先 LANCZOS 缩到 96 px 再量化（见 `assets/asset-manifest.json` pipeline），
   像素簇本身是软的，不是逐像素绘制。
5. **文字**：Ark Pixel 12px 字体在 14/16/18/20/22 等非 12 倍数字号下，笔画粗细不均
   （放大看 NPC 名字“阿砚”就是糊的）。

## 修复方案（按顺序，做一步截图验一步）

1. 新建 `scripts/presentation/pixel_sprite.gd`（草稿见下），按 alpha 阈值找最低不透明行，
   统一算 offset；`game.gd` `_apply_art`、`enemy.gd` `_attach_scene_art`、`npc.gd`、
   `player.tscn` 都改用它。脚底对齐碰撞体底部：敌人 16、玩家 16、NPC 0。
2. 修 `ActorMotion._draw_shadow`，把 squash 的轴心改到脚底。
3. **只用整数缩放**：角色 1× 或 2×。要更大就按目标尺寸重新出图（例如 NPC 128 px），
   别在运行时放大。第二章 Boss 要单独出 256 px 贴图，不要再把 96 px 放大 2.15。
4. 必须非整数缩放或旋转时：给 `ActorMotion` 节点挂下方“平滑像素”shader，贴图过滤改 LINEAR。
   GL Compatibility 支持 `fwidth`。`ActorMotion` 在同一个 CanvasItem 里还画圆和线，
   挂材质后要确认这些图元颜色不变。
5. **字体**：只用 12/24/36 字号；或改用 Ark Pixel 16px 版（需要下载，先问用户）。
6. **源图**：主角/NPC/Boss 用 Pixelorama 或 Aseprite 逐像素清理，或按目标尺寸重新生成；
   不要再用 LANCZOS 缩放，改用最近邻缩放加手工修。

## 代码草稿

`scripts/presentation/pixel_sprite.gd`：

```gdscript
class_name PixelSprite
extends RefCounted

## Sprite2D.offset 在贴图像素空间（先于 scale），脚底高度要除以 scale。
## 每张贴图只扫描一次，找最低不透明行，让它落在 foot_y。

const ALPHA_THRESHOLD := 24  # 和 asset 管线的 alpha 阈值一致；get_used_rect() 会把淡光晕也算进去
static var _feet: Dictionary = {}

static func opaque_rect(texture: Texture2D) -> Rect2i:
	var id := texture.get_instance_id()
	if _feet.has(id):
		return _feet[id]
	var image := texture.get_image()
	var rect := Rect2i(Vector2i.ZERO, Vector2i(texture.get_size()))
	if image != null and not image.is_empty():
		var top := -1; var bottom := -1; var left := image.get_width(); var right := -1
		for y in image.get_height():
			for x in image.get_width():
				if image.get_pixel(x, y).a8 > ALPHA_THRESHOLD:
					if top < 0: top = y
					bottom = y
					left = mini(left, x); right = maxi(right, x)
		if bottom >= 0:
			rect = Rect2i(left, top, right - left + 1, bottom - top + 1)
	_feet[id] = rect
	return rect

## 让贴图水平居中、最低不透明行落在本地 foot_y。
static func ground_offset(texture: Texture2D, scale: float, foot_y: float = 0.0) -> Vector2:
	var rect := opaque_rect(texture)
	var size := texture.get_size()
	var centre_x := rect.position.x + rect.size.x * 0.5 - size.x * 0.5
	return Vector2(-centre_x, foot_y / scale + size.y * 0.5 - rect.end.y)
```

`resources/shaders/pixel_smooth.gdshader`（任意缩放/旋转下像素仍均匀；节点过滤要设 LINEAR）：

```glsl
shader_type canvas_item;

void fragment() {
	vec2 texture_size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 texel = UV * texture_size;
	vec2 seam = floor(texel + 0.5);
	vec2 texels_per_pixel = max(fwidth(texel), vec2(0.0001));
	texel = seam + clamp((texel - seam) / texels_per_pixel, -0.5, 0.5);
	COLOR = texture(TEXTURE, texel / texture_size) * COLOR;
}
```

已验证：headless 下 `Texture2D.get_image()` 能读回导入后的贴图（这些贴图是无损导入）。
注意 `Image.get_used_rect()` 只看 alpha > 0，比 PIL 阈值 24 的结果多算几行淡光晕（baiyu 差 3 行），
所以草稿里用阈值扫描。

## 验证方法

- 截图脚本（必须窗口模式，`--headless` 不渲染）：
  `tests/capture_hub.gd`（Hub 全景 + 走到每个 NPC 旁）、`tests/capture_bosses.gd`（四章 Boss 房）。

  ```
  tools/godot/Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 --script tests/capture_hub.gd -- --out-dir=res://artifacts/audit
  ```

- 截图是 RGBA PNG，看图前先转成 RGB/JPEG（直接读 RGBA 大图经常显示空白）。
- 建议加单测：对每个角色贴图，算最低不透明行的本地 y 与碰撞体底部之差，要求 ≤ 2 px。

## 同一轮发现的其他画面问题（未修）

- **第四章 Boss 房背景全灰**：`scripts/presentation/theater_backdrop.gd` `_process` 把远景
  `_far.position.x` 固定在 `view_width * 0.5 + 30`（章节最左端），不跟相机走。
  应像 `living_backdrop.gd` 一样用 `_camera.get_screen_center_position().x - _base_x`。
- **第二章 Boss**借用 96 px 的 typo_beast 放大 2.15：又糊又浮空约 100 px，需要专属 256 px 贴图。
- **HUD 底部操作提示**贴着屏幕下边缘被裁：`scenes/ui/hud.tscn` 的 `ControlsHint` 没有底部余量。
- **`tests/capture_polish.gd`** 没关章节开场的 StoryOverlay，之后的截图全被遮住。
