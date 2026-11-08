# 素材与第三方许可

## 项目素材

- `assets/sprites/`、`assets/backgrounds/pixel/`、`assets/portraits/pixel/`、
  `assets/tiles/`、`assets/branding/logo_pixel.png`、`assets/audio/`：
  为《昌子大冒险》制作的项目素材（AI 生成后经脚本规范化/手工清理，或程序绘制）。
- `assets/concept/`：概念/源图，用于本项目继续制作；不保证适合其他项目。
- **真人参考照片不在本仓库**：原 `assets/references/` 已排除，避免肖像权风险。
- 游戏内 NPC 使用风格化原创像素形象；旧 800×1000 立绘仅保留给完整版参考。

## 第三方

- `addons/MetroidvaniaDeveloperSystem/`：MIT，保留其 LICENSE。
- `addons/AsepriteWizard/`：MIT，保留其 LICENSE。
- `assets/fonts/`：Fusion Pixel / Ark Pixel，OFL，保留其 LICENSE 文件。
- `.claude/skills/_licenses/`：技能来源与许可记录。
- `assets/vfx/`：战斗特效与 6 种新怪物的动画序列帧，由 `tools/export_vfx.mjs` 从 **pixelfx 0.3.0**（MIT，
  https://github.com/patch-gg/pixelfx ，其模拟核心改编自 Sprite Fusion pixel-art VFX，MIT）渲染并换成本作调色；
  许可见 `assets/vfx/LICENSE-pixelfx.txt`。源码快照来自工作室素材库（`素材库-素材包-2026-11-08/sources/pixelfx`）。
- `assets/backgrounds/regions/`、`assets/backgrounds/layers/`：由本项目四张背景插画程序化派生（`tools/build_region_backdrops.py`、`tools/build_dressing.py`）。

## 音频

- 配乐为项目内程序化/原创素材；SAPI 中文语音是内部原型，正式发布前应替换为
  真人或商用授权 TTS。
