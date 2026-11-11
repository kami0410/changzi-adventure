# 昌子大冒险 · 记忆索引

> 常驻索引（≤8 KB）。只放摘要与“何时加载”；1.0 之前的逐程细节在 [旧索引归档](archive-index-pre-1.0.md)。
> 规则见工作室 `docs/memory/README.md`；协议见 `memory-index` skill。

## 游戏概览

- **昌子大冒险**（`changzi-adventure`）：2D 横版动作 Roguelite，语言同时是构筑核心与叙事核心。
- 版本 **`1.1.1`**（1.1.1 修复 1.1.0 进关卡死；1.0 正式版 2026-11-08 确认；1.0.1 手机触屏与屏幕适配；1.1.0 言灵改写世界、动作帧、流畅度、可读性）；修复走 1.0.x，新内容走 1.x（[版本策略](decisions/2026-11-02-versioning.md)）。
- 第 1–4 章全线可玩 + 五个结局；Hub 五位 NPC（闻烬/白榆在通关第一章后登场）。
- 事实来源：[GDD](../GDD.md)（顶部「1.1.0 规则」最新）· [剧情圣经](../story-bible.md) · [AI 言灵](../ai-skill-hook.md) · [素材许可](../../ASSETS.md) · [README](../../README.md)。

## 系统速查（细节见 GDD 对应节）

- **关卡**：第 1 章线性 9 房（`MDSChapterRoom`，8×2 随机布局）；第 2–4 章大图（`ChapterPlanData` + `MDSBigRoom`，9 区 22 门、召唤电梯、单向落台、长椅、枢纽开捷径）。路由在 `game.gd` 的 `MDS_*`/`CHAPTER_PLAN_PATHS`。
- **战斗**：游荡式普通战（精英/Boss 锁门）；翻滚 + 完美闪避 + 空中冲刺 + 二段跳；平台单向可穿越；遭遇变数 + 章节异象（`RunMutators`）+ 每日挑战（`GameFlow.daily_seed`）。
- **敌人**：24 种 `EnemyData` + 4 Boss，全部逐帧动作（`CreatureArt` + `assets/sprites/creatures/`；1.1 的 20 个来自 Magpie 动作表），每章一种主打新怪。
- **言灵**：离线推演 + 可选 AI；13 形态；言灵权能（`WorldPowers`：时停/处决/改写敌名/瞬移/无敌/墨阶/揭图/破封/写残页）；法典（`Profile.grimoire`）。
- **世界改写（1.1）**：`WorldActs` 动词表（45 动作 / 9 触发 / 11 倍率，强度不封顶、数量封顶）+ `ActLexicon` 离线读法 + `SpeakBar` 战斗中按 T 开口；AI NPC 有记忆与祝福。
- **成长与 Hub**：档案馆祭坛、词条熟练度、信任四档、NPC 个人事件（五位）、AI NPC 白名单职能（AI 数值不受离线上限）。
- **表现**：`Perf` 画质档位（手机自动流畅）、`DepthHaze` 纵深雾、`SurfaceEdge` 平台顶边、角色身份描边（`PixelSprite.apply_role`）、pixelfx 像素特效（`VFX`）、墨晕转场（`ink_fade.gdshader`）、纸纹（`PaperGrain`）、配乐 v2（名册动机 + 四章战斗层）。
- **输入与屏幕**：键盘/手柄/触屏（`TouchOverlay` + `Flow.using_touch`）；按比例缩放，逻辑高 720。
- **存档**：`user://profile.cfg`（Profile）+ 局内 run save（`RunSave`，含 `daily`）。

## 管线与工具

- 美术：`tools/import_art_pack.py`（`art_inbox/` → `assets/`）、`tools/import_magpie_sheets.py`（Magpie 动作表 → 逐帧条）、`tools/build_region_backdrops.py`（区域背景）、`tools/export_vfx.mjs`（pixelfx 特效）。
- 音频：`tools/generate_music.py`（配乐 v2）、`tools/generate_sfx_extra.py`、`tools/generate_voice.py`（SAPI 原型）。
- 测试：`tests/run_tests.gd`（单元，`--filter=`）、`tests/integration_*.gd`（14 套，用 `tools/run_integration.sh` 串行跑）、`tests/capture_*.gd`（窗口模式截图）。
- 插件：MDS 3.2.0、Aseprite Wizard 9.8.0（MIT）；字体 Fusion Pixel 12px（OFL）。

## 决策（ADR）

- 最新：[1.1 世界动作 / 画质 / 可读性](decisions/2026-11-11-world-acts-1.1.md) · [1.0 正式版](decisions/2026-11-08-release-1.0.md) · [翻滚/电梯/随机性 0.14](decisions/2026-11-08-roll-lift-variety.md) · [版本策略](decisions/2026-11-02-versioning.md)。
- 美术：[像素美术](decisions/2026-10-31-pixel-art.md) · [美术规范](decisions/2026-11-02-art-spec.md) · [逐帧动作](decisions/2026-11-02-frame-animation.md) · [UI 方向](decisions/2026-11-02-ui-direction.md)。
- 系统：[平衡与 AI 权限](decisions/2026-11-02-balance-authority.md) · [MDS 全量接入](decisions/2026-11-02-mds-full.md) · [短语迁移](decisions/2026-11-03-v1-phrase-migration.md) · [第 1 章 demo](decisions/2026-11-03-chapter1-demo.md) · [NPC 个人事件](decisions/2026-11-06-npc-personal-events.md)。
- 大图：[房间管线](decisions/2026-11-04-big-room-pipeline.md) · [第 2 章图](decisions/2026-11-04-chapter2-big-map-graph.md) · [内容按章查表](decisions/2026-11-04-chapter-content-tables.md) · [波次接线](decisions/2026-11-04-chapter2-wave-wiring.md) · [事件触发](decisions/2026-11-04-chapter2-event-trigger.md) · [Boss 2 边界](decisions/2026-11-04-chapter2-boss-boundary.md) · [地面门宽限](decisions/2026-11-04-floor-arrival-grace.md) · [门视觉/出生点](decisions/2026-11-05-big-map-gate-visuals-spawn.md) · [地图标题](decisions/2026-11-05-map-title-chapter-region.md)。
- 第 3/4 章：[第 3 章图](decisions/2026-11-05-chapter3-plan-graph.md) · [Boss 3](decisions/2026-11-05-chapter3-boss3.md) · [第 3 章章末](decisions/2026-11-05-chapter3-ending.md) · [第 4 章图](decisions/2026-11-05-chapter4-plan-graph.md) · [第 4 章章末](decisions/2026-11-06-chapter4-ending.md)。

## 已知问题 / 需要项目方

- 1.1 的手机流畅度只在桌面 / 模拟器验证，真机帧率待用户反馈。
- 改预热 / 加载路径后必须窗口模式跑 `tests/repro_enter_level.gd`（无头测试不启动预热，1.1.0 因此漏掉进关卡死）。
- 中文语音为 Windows SAPI 原型，商业发行前需换真人或授权 TTS。
- Android 发行包为调试签名（仓库不含 keystore）；安卓实测用雷电模拟器 + adb（只能模拟单指）。
- [角色浮空/像素发糊](issues/2026-11-02-sprite-float-blur.md)（0.9 已修，留作排障参考）。

## 调研

- [Godot 工具调研](../research/2026-11-02-godot-tools.md) · [MDS 评估](../research/metroidvania-developer-system.md)。

## 里程碑

- 2026-10-31～11-03：概念、GDD、核心系统、M1 切片、0.4–0.11 迭代、第 1 章 demo（逐程见归档）。
- 2026-11-04～11-07：第 2–4 章大图逐程施工、验收与接线，全流程 1→4（第 26–101 程，见归档）。
- 2026-11-08 [0.14.0](sessions/2026-11-08-roll-lift-variety-0.14.md)：翻滚、召唤电梯、随机性、地块与区域美术。
- 2026-11-08 [0.15.0](sessions/2026-11-08-roaming-creatures-vfx-0.15.md)：游荡战斗、6 新怪、像素特效、美术需求 PDF。
- 2026-11-08 **[1.0.0](sessions/2026-11-08-release-1.0.md)**：全套美术、4 新怪、言灵权能/法典、章节异象、每日挑战、墨晕转场、配乐 v2、闻烬/白榆、记忆索引精简。
- 2026-11-09 **[1.0.1](sessions/2026-11-09-mobile-1.0.1.md)**：触屏重写（多点触控、Hub 通用）、按比例缩放与宽屏延伸、二段跳、平台单向与抬高；雷电模拟器实测。
- 2026-11-11 **[1.1.0](sessions/2026-11-11-optimize-1.1.md)**：安卓流畅度、16 敌人 + 4 Boss 动作帧、言灵改写世界 / 常驻规则 / 开口即言灵、画面可读性。
- 2026-11-11 **1.1.1**：修复 1.1.0 从 Hub 进关卡死（预热死锁）；见 [1.1 会话](sessions/2026-11-11-optimize-1.1.md)。
