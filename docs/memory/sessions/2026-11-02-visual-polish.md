---
name: 2026-11-02-visual-polish
description: 0.9.0 画面打磨：发糊/浮空根治、原图重做贴图、第二章 Boss 新图、像素字号、档案纸页 UI、MDS 气氛接入
type: session
status: active
updated: 2026-11-02
load_when: 改角色渲染/贴图/字体/UI 主题/HUD/背景气氛，或继续画面打磨时
---

# 0.9.0 画面打磨

依据：`create-game-assets`、`game-ui-ux`、`game-feel` 技能，`frontend-design` 技能；
规范写成 [美术规范](../decisions/2026-11-02-art-spec.md) 与 [UI 方向](../decisions/2026-11-02-ui-direction.md)。

## 发糊与浮空（已根治）

- 根因：`ActorMotion` 把贴图切块旋转、非整数缩放、最近邻采样；`Sprite2D.offset` 单位算错；阴影少乘 scale。
  详见 [issues](../issues/2026-11-02-sprite-float-blur.md)。
- 修法：
  - `resources/shaders/pixel_smooth.gdshader`：纹素中心采样，只在纹素边界做 1 px 过渡；顺带画右上青色轮廓光（随朝向翻转）。
  - `scripts/presentation/pixel_sprite.gd`：按 alpha 阈值找最低不透明行，统一算 offset（整数纹素），玩家/敌人/NPC/Boss 全部走它。
  - `ActorMotion` 改为整张贴图绕脚底变换，不再切块；绘制原点对齐屏幕像素；阴影画在真实脚底。
  - 所有角色缩放改为 1×（原 1.05/1.1/1.2/1.3/2.15/0.82/0.9）；NPC 加 `sprite_scale` 导出，默认 1。

## 贴图

- 用户说“应该有原图”：`assets/concept/` 里找到 8 张高分辨率原图（最后的读者、笑面史官、面具敌人、座位空壳、
  合唱召引者、墨囊投手、镜面狙手、残页群），用 `tools/normalize_sprite.py --batch` 重新转换：
  预乘缩放 → 二值 alpha → 只用不透明像素建调色板、给高饱和色预留 1/4 色位（青色眼睛不再变灰）→ 去小碎块 → 1 px 墨色轮廓 → 底边居中。
- 无原图的 13 张（主角、墨骸史官、墨犬等，0.2 只留了 96 px 成品）：`--cleanup` 原地二值 alpha + 轮廓，不缩放。
- 第二章 Boss 肺钟守卫：Magpie（codex/gpt-image-2）以墨骸史官为参考新画，原图
  `assets/concept/characters/lung_bell_guardian_source.png`，成品 `assets/sprites/bosses/lung_bell_guardian.png`（256 px，45 色）。
  不再借用放大 2.15 倍的错字巨兽。
- 修改前的全部贴图备份在 `/tmp/changzi_backup_2026-11-02/sprites`（临时目录，重启可能丢失；git 里也有 0.2 的版本）。

## 字体与 UI

- Ark Pixel 12px 只有 12/24/36/48 清晰：`tools/snap_font_sizes.py` 把 24 个文件里 137 处字号对齐。
- 主题由 `tools/build_ui_theme.py` 生成：
  - `theme.tres`：模态窗口是“档案纸页”（旧纸底、墨字、朱批强调、2 px 墨边）；
  - `hud_theme.tres`：HUD 与世界内文字是墨条上的骨白/病青字；
  - `ink_theme.tres`：标题画面直接画在墨色桌面上。
- `scripts/ui/ui_palette.gd`：文字颜色角色（纸上用 INK/CINNABAR…，墨上用 BONE/CYAN…）。
- `scripts/ui/modal_layer.gd`：动态弹窗（AI 设置、Hub 操作说明）放到第 70 层，不再被 Hub 顶栏压住。
- 模态打开时隐藏 HUD；`tools/recolor_ui_scenes.py` 改了 7 个场景的文字颜色并删掉“A R C H I V E…”式大写装饰标签；
  `tools/tune_hud_layout.py` 按新字号收紧 HUD；去掉 UI 文案里的“A · B · C”中点串，改成完整短句。

## 场景与气氛

- 背景远景压暗、改用线性过滤（远景是绘画风，不是像素网格），角色更突出。
- 修复：0.8 改过的第四章背景跟着相机串到了其他章节；`TheaterBackdrop` 只在本章显示。
  另一个隐患：`.tscn` 里脚本属性写在 `script = ` 之前会被丢掉（`world_width` 曾因此变回 8400）。
- **MDS 只借气氛**（用户已定 MDS 要用）：`scripts/presentation/chapter_atmosphere.gd` 给四章加 MDS 天气
  （档案馆雾+灰、呼吸废墟孢子、无光海雾+细雨、剧场灰+光柱），Boss 房加动态背景（进入 Boss 战才淡入）。
  天气 `affect_groups` 清空，不推人不伤人。

## 验证

- 单测 2960/0；集成 135/0；成品包 136/0；`check_game.ps1` 通过。
- 120 FPS 压测：满载平均 8.49 ms（基线 8.31）；MDS spike 14/14，气氛层不锁帧 0.57 ms/帧。
- 导出 0.9.0：Windows 123 MiB、Android 52.4 MiB（versionCode 9，签名校验通过，不含 spikes/tools/tests）。
- 截图脚本：`tests/capture_ui.gd`（18 个 UI 画面）、`capture_hub.gd`、`capture_bosses.gd`、`capture_spells.gd`。

## 坑

- 新的 `class_name` 要先 `--import` 重扫一次，否则别的脚本报“未声明”。
- 截图 PNG 是 RGBA，读图前转 RGB/JPEG。
- 生成 Python 补丁时，GDScript 字符串里的 `\n` 在 heredoc 里很容易转义错；复杂补丁写成 `tools/` 下的脚本再跑。

## 下一步

- 动画插件：用户已同意要用；先装 Aseprite Wizard（安装前确认下载），给主角做跑/跳/三段攻击/翻滚逐帧样板。
- 缺字：25 个字符回退系统字体（`tools/font_coverage.py`）。
- 第一章关卡结构重做、真人试玩。
