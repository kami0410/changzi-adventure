# 素材与第三方许可

## 项目素材

- `assets/sprites/`、`assets/backgrounds/pixel/`、`assets/portraits/pixel/`、
  `assets/tiles/`、`assets/branding/logo_pixel.png`、`assets/audio/`：
  为《昌子大冒险》制作的项目素材（AI 生成后经脚本规范化/手工清理，或程序绘制）。
- `assets/concept/`：概念/源图，用于本项目继续制作；不保证适合其他项目。
- **1.0 美术包**（2026-11-08，项目方委托生成并交付，`art_inbox/`；生成提示词与来源记录见
  `art_inbox/_sources/generation-prompts.json`，原始生成图不入库）：10 种生物怪动作条、第 2–4 章 12 张区域原画
  与中景、四章地块与道具、电梯部件、词缀图标、标题主视觉、主角翻滚/空中冲刺/终结重击、阿砚（锻造之神）精灵与立绘。
  由 `tools/import_art_pack.py` 规范化后放入 `assets/`；`assets/backgrounds/regions/` 由 `tools/build_region_backdrops.py`
  从区域原画合成。阿砚的面部形象由项目方提供并授权用于本作。
- **真人参考照片不在本仓库**：原 `assets/references/` 已排除，避免肖像权风险。
- 游戏内 NPC 使用风格化原创像素形象；旧 800×1000 立绘仅保留给完整版参考。

## 第三方

- `addons/MetroidvaniaDeveloperSystem/`：MIT，保留其 LICENSE。
- `addons/AsepriteWizard/`：MIT，保留其 LICENSE。
- `assets/fonts/`：Fusion Pixel / Ark Pixel，OFL，保留其 LICENSE 文件。
- `.claude/skills/_licenses/`：技能来源与许可记录。
- `assets/vfx/`：战斗特效序列帧，由 `tools/export_vfx.mjs` 从 **pixelfx 0.3.0**（MIT，
  https://github.com/patch-gg/pixelfx ，其模拟核心改编自 Sprite Fusion pixel-art VFX，MIT）渲染并换成本作调色；
  许可见 `assets/vfx/LICENSE-pixelfx.txt`。源码快照来自工作室素材库（`素材库-素材包-2026-11-08/sources/pixelfx`）。
- `resources/shaders/ink_fade.gdshader`：移植自 **gl-transitions** 的 InkBleed（作者 gre，MIT，
  https://github.com/gl-transitions/gl-transitions ），源码快照来自工作室素材库（条目 0017）。
- `resources/shaders/paper_grain.gdshader`：参考 **Paper Shaders**（Apache-2.0，https://shaders.paper.design ）的
  paper-texture 思路自行编写，未复制上游代码。

## 音频

- 配乐为项目内程序化原创素材（`tools/generate_music.py`，v2：8 首 + 4 条战斗层，共用「名册」主导动机）；
  音效由 `tools/generate_sfx_extra.py` 等脚本合成。
- 中文语音为本机 Windows SAPI 合成的原型配音（`tools/generate_voice.py`）。商业发行前应替换为真人或商用授权 TTS；
  这一项需要项目方决定，不属于代码工作。
