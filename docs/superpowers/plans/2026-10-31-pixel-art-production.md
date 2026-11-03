# 昌子大冒险 像素美术生产 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 M1 垂直切片交付一整套可导入 Godot 的高精度像素动画与 UI 资产，覆盖昌子、6 武器、5 敌人 + 精英、墨骸史官、3 个 NPC 与核心 UI。

**Architecture:** 先锁定 art bible（调色板、像素网格、pivot、帧率、轮廓规则），再按“角色 base rig → 武器 overlay → 敌人 → Boss → NPC → UI”生产；Magpie 只出关键姿势/概念，最终帧用 Pixelorama/Aseprite 逐帧完成，经 `create-game-assets` QA 脚本检查后导入 Godot `SpriteFrames`。

**Tech Stack:** Magpie MCP、Pixelorama/Aseprite、Python/Pillow（create-game-assets 脚本）、Godot 4.7.2 SpriteFrames/AnimationPlayer。

**Spec:** `games/changzi-adventure/docs/GDD.md` + `GDD-v0.2-decisions.md` §22.3

## Global Constraints

- 角色 96×96，Boss 256×256，tile 32×32；原生 1280×720。
- 每个动作 6–10 帧，12–24 FPS；统一 pivot（脚底中心）与碰撞盒参考。
- 调色板：午夜蓝、病态青、骨白、干血红；污染用黑绿/紫黑；不得随意加高饱和色。
- 轮廓光统一从右上；阴影/墨汁方向统一。
- 所有 sprite 必须透明背景、无文字/UI/水印；alpha 检查通过。
- 生成图不能直接当最终帧；必须切图、对齐、去背、统一调色板。
- 不覆盖已有参考图与概念图；最终资产放 `assets/sprites/`，动画资源放 `resources/animation/`。

## Review Focus

- 同一角色跨动作的比例/服装/武器是否漂移。
- 96×96 下剪影是否可读；Boss 256×256 是否有压迫感。
- 武器 overlay 与手部 pivot 是否对齐；近战三段是否能看出起手/命中/收招。
- 透明边缘是否有黑边/白边；像素是否被插值模糊。
- 帧率与循环是否自然；idle/run 循环首尾是否衔接。
- UI 图标在 32×32/64×64 下是否可辨识。

---

### Task 1: Art bible、调色板与像素网格

**Files:**
- Create: `docs/art-bible.md`
- Create: `assets/sprites/_palette/palette.png`（16–24 色）
- Create: `assets/sprites/_guides/character_grid_96.png`、`boss_grid_256.png`
- Test: 人工检查 + `create-game-assets` 的 `asset_report.py`

**Interfaces:**
- Produces: 调色板、pivot 规则、帧率、轮廓/阴影规则；后续所有资产引用。

- [ ] **Step 1: 写 art bible**

写清：像素网格、调色板 hex、pivot、轮廓光、阴影、污染色、角色/敌人/Boss 比例、UI 图标规格。

- [ ] **Step 2: 生成调色板与网格参考图**

用 Pixelorama/Aseprite 或脚本生成 16–24 色 palette PNG 与 96/256 网格 guide。

- [ ] **Step 3: 验收**

`python .claude/skills/create-game-assets/scripts/asset_report.py assets/sprites/_palette/palette.png --expect-size <WxH> --json` 通过；人工确认颜色数量与对比度。

- [ ] **Step 4: 提交**

```bash
git -C games/changzi-adventure add docs/art-bible.md assets/sprites/_palette assets/sprites/_guides
git -C games/changzi-adventure commit -m "art: add pixel art bible, palette, and guides" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 2: 昌子 base rig 与全套动画

**Files:**
- Create: `assets/sprites/player/changzi_idle.png`、`changzi_run.png`、`changzi_jump.png`、`changzi_fall.png`、`changzi_dodge.png`、`changzi_hit.png`、`changzi_death.png`、`changzi_melee_1/2/3.png`、`changzi_ranged.png`、`changzi_cast.png`
- Create: `resources/animation/player_frames.tres`（SpriteFrames）
- Test: Godot 导入 + `AnimationPlayer` 播放全部 clip

**Interfaces:**
- Produces: `player_frames.tres`，animation 名称 `idle/run/jump/fall/dodge/hit/death/melee_1/melee_2/melee_3/ranged/cast`。

- [ ] **Step 1: 用 Magpie 出 3–4 张关键姿势参考**

以 `assets/concept/style-tests/changzi_pixel.png` 为风格参考；只作姿势/服装参考。

- [ ] **Step 2: 逐帧绘制 12 个动作**

每个动作 6–10 帧；统一 pivot；检查循环首尾。

- [ ] **Step 3: 生成 SpriteFrames 并在 Godot 播放**

导入 Godot，创建 `player_frames.tres`；用测试场景逐一播放，确认无错帧/模糊。

- [ ] **Step 4: QA**

`asset_report.py` 检查尺寸/alpha/颜色数；人工在 96×96 实际尺寸看剪影。

- [ ] **Step 5: 提交**

---

### Task 3: 6 把武器的攻击动画与 VFX

**Files:**
- Create: `assets/sprites/weapons/` 6 组攻击帧/overlay
- Create: `assets/vfx/` 命中/挥砍/墨弹/符枪粒子
- Modify: `resources/animation/player_frames.tres` 增加武器动作
- Test: 每把武器在 Godot 中播放独立攻击动作

**Interfaces:**
- Produces: 6 把武器的 `attack_1/attack_2/attack_3`（近战）或 `fire/charge`（远程）动画；VFX 场景。

- [ ] **Step 1: 定义 6 把武器 archetype 与动作差异**

近战：断页剑（3 段）、墨斧（2 段重击）、链刃（3 段范围）；远程：墨弹枪（射击）、符枪（蓄力）、书页飞刃（回旋）。

- [ ] **Step 2: 逐帧/overlay 制作攻击动作**

玩家身体共用 base rig，武器与 VFX 用 overlay；手部 pivot 对齐。

- [ ] **Step 3: 在 Godot 中逐把播放并检查命中帧**

命中帧与 hitbox 开启帧对齐。

- [ ] **Step 4: 提交**

---

### Task 4: 5 种敌人 + 1 精英

**Files:**
- Create: `assets/sprites/enemies/` 6 组 sprite sheet
- Create: `resources/animation/enemy_frames/` 6 个 `.tres`
- Test: Godot 播放 idle/move/attack/hit/death

**Interfaces:**
- 敌人：墨犬、抄写虫、空白人、悬吊书吏、失忆回声；精英：错字兽。
- animation 名称：`idle/move/attack/hit/death`；精英额外 `special`。

- [ ] **Step 1: 用 Magpie 出 6 张关键姿势参考**
- [ ] **Step 2: 逐帧绘制 5–8 帧/动作**
- [ ] **Step 3: 导入 SpriteFrames，检查 pivot 与碰撞盒**
- [ ] **Step 4: 提交**

---

### Task 5: Boss 墨骸史官

**Files:**
- Create: `assets/sprites/bosses/ink_archivist/` sprite sheets（256×256）
- Create: `resources/animation/ink_archivist_frames.tres`
- Test: Godot 播放 idle/3 攻击/phase/hit/death

**Interfaces:**
- animation：`idle`、`page_wave`、`ink_rain`、`rewrite`、`phase`、`hit`、`death`。
- 关键帧与 Boss 攻击预警/命中判定对齐。

- [ ] **Step 1: 画 256×256 关键姿势与攻击预警**
- [ ] **Step 2: 逐帧完成 7 个动作**
- [ ] **Step 3: 在 Boss 房间实际尺寸预览**
- [ ] **Step 4: 提交**

---

### Task 6: 3 个功能 NPC + 2 个预告 NPC

**Files:**
- Create: `assets/sprites/npcs/luchen/`、`ayan/`、`gulu/`、`shouzhong/`、`zhilu/`
- Create: `resources/animation/npc_frames/` 5 个 `.tres`
- Test: idle/talk/gesture 播放

- [ ] **Step 1: 按参考图与角色定位画 idle/talk/gesture**
- [ ] **Step 2: 咕噜用非人比例；陆沉/阿砚保持像素与服装一致性**
- [ ] **Step 3: 在 Hub 场景实际尺寸预览**
- [ ] **Step 4: 提交**

---

### Task 7: UI、图标与中文像素字体

**Files:**
- Create: `assets/sprites/ui/` HUD 框、按钮、槽位
- Create: `assets/sprites/icons/words/` 12 个、`phrases/` 8 个、`weapons/` 6 个、`relics/` 8 个
- Create: `assets/fonts/` 中文像素字体（确认授权）
- Test: 32×32/64×64 图标可辨识；HUD 在 1280×720 与 16:9/20:9 不裁切

- [ ] **Step 1: 确定 UI 网格与九宫格**
- [ ] **Step 2: 画核心图标与 HUD**
- [ ] **Step 3: 导入 Godot Theme，检查缩放**
- [ ] **Step 4: 提交**

---

### Task 8: 导入、QA 与资产 manifest

**Files:**
- Modify: `resources/animation/*.tres`
- Create: `assets/asset-manifest.json`
- Test: 全部动画在 Godot 中播放；`asset_report.py` 全部通过；无黑边/白边/模糊

- [ ] **Step 1: 批量检查尺寸/alpha/颜色数**

```bash
python .claude/skills/create-game-assets/scripts/asset_report.py assets/sprites/player/changzi_idle.png --expect-size 96x96 --require-alpha --max-colors 32 --json
```

- [ ] **Step 2: 生成 contact sheet 并人工检查**

```bash
python .claude/skills/create-game-assets/scripts/build_preview_sheet.py assets/sprites/player/*.png --out output/player-preview.png --columns 4 --cell-size 192
```

- [ ] **Step 3: 在 Godot 中逐个播放，检查 pivot/循环/命中帧**
- [ ] **Step 4: 记录 provenance 到 asset-manifest.json**
- [ ] **Step 5: 提交**

---

## Self-Review

- **Spec coverage:** §22.3 的每个角色/动作都有 Task；风格、调色板、QA 在 Task 1/8。
- **Task right-sizing:** 每个 Task 交付一组可播放的动画，独立验收。
- **Review Focus:** 比例漂移（Task 2/4/5）、武器对齐（Task 3）、透明边缘（Task 8）、UI 缩放（Task 7）。
- **Proportion:** 本计划只定义资产与验收，不替美术写每一帧。
