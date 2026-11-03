# 昌子大冒险 · 记忆索引

> 常驻索引（≤8 KB）。规则见工作室 `docs/memory/README.md`；协议见 `memory-index` skill。

## 游戏概览

- **昌子大冒险**（slug：`changzi-adventure`）
- 2D 横版动作 Roguelite；核心是道具/构筑，语言同时作为构筑与叙事核心。
- 版本：`0.11.0-demo`（Chapter 1 demo）；1.0 只在用户确认最终完整版后使用（[版本策略](decisions/2026-11-02-versioning.md)）。
- 当前目标：Chapter 1 demo，Windows 优先；范围与决策见 [Chapter 1 demo ADR](decisions/2026-11-03-chapter1-demo.md)。
- 昌子：失忆的宇宙史官，被克苏鲁式污染侵蚀，在破碎末日世界找回权柄与记忆。
- [GDD 与 0.11 demo 规则](../GDD.md) — 长线设计与当前落地范围；改玩法前读。
- 素材与许可说明见 [ASSETS.md](../../ASSETS.md)。
- [角色像素概念](../../assets/concept/characters/README.md)。
- [剧情圣经](../story-bible.md) — 四章、五结局、五名 NPC 的完整弧光；写台词/结局前读。

## 世界与系统

- 语言：词 → 短语 → 权柄；污染 0–100；见 GDD §7。0.8 言灵 v3 组件→效果表见 [AI 言灵](../ai-skill-hook.md)。
- 战斗：2 武器 + 2 短语 + 1 权柄；墨量资源；见 GDD §8。武器可掉落/拾取（按 E），换装时旧武器掉在身后。
- 难度：平静/墨雨/深渊/噩梦四档；敌人生命/伤害、收益、污染倍率见 [平衡与权限 ADR](decisions/2026-11-02-balance-authority.md)。
- 成长：档案馆祭坛（生命/墨量/言灵伤害/污染抗性，无上限指数成本）+ 词条熟练度（使用累积，递减增益）。
- AI NPC：对话可执行白名单职能（讨价还价/锻造等），每 NPC 每次回 Hub 一次破例，客户端校验。
- 道具：武器/短语/遗物/词/消耗品；见 GDD §9。HUD 左上角常驻遗物状态，背包页有完整列表。
- 污染：25/50/75 分档加敌人伤害、短语墨耗/冷却；100 进入 30 秒发狂（生命上限压到 40%），撑过才恢复。净化词（净化/洗涤/赦免）、圣+水/生命共鸣、净墨灯、休整 -12。
- 单局：Hub + 分支路线 + 2–3 个生态区；见 GDD §10–11。
- 探索：四章主路各有隐藏书库（宝箱 + 记忆碑），休息室有回长廊的捷径；门扉由 `chapter_door.gd` 绘制，首次进书库有金色反馈。
- 叙事：碎片投放 + 3 主结局 + 1 隐藏；见 GDD §12。

## 工具与插件

- **Aseprite Wizard 9.8.0**（MIT）`addons/AsepriteWizard/`：Aseprite 逐帧动画导入；已在项目设置启用。
- **Metroidvania Developer System 3.2.0**（MIT）`addons/MetroidvaniaDeveloperSystem/`：世界/房间/地图框架；四章已接入。
- **Fusion Pixel 12px Monospaced zh_hans**（OFL）`assets/fonts/`：UI 主字体，0 缺字；Ark Pixel 仅留作基线。
- `tools/slice_anim_sheet.py`：Magpie 多帧横条 → 共用缩放/调色板/脚底基线的玩家动作帧；改帧管线时读。

## 决策

- 2026-10-31：确认主角、5 名 NPC + 笑面史官最终 Boss 的定位。
- 2026-10-31：语言同时作为构筑核心与叙事核心。
- [ADR-0001：高精度像素美术](decisions/2026-10-31-pixel-art.md)。
- [MDS 全量接入](decisions/2026-11-02-mds-full.md) — 用户已定用 MDS 做世界/房间/相机/地图框架；全四章已落地，见 [MDS 全四章](sessions/2026-11-02-mds-migration.md)。
- [平衡、成长与 AI 权限](decisions/2026-11-02-balance-authority.md) — 效果预算定价、四档难度、无上限成长、AI 白名单职能；改数值/成长/AI 前读。
- [美术技术规范 0.9](decisions/2026-11-02-art-spec.md) — 尺寸、整数缩放、二值 alpha、轮廓、脚底；做贴图或改角色渲染前读。
- [逐帧动作管线 0.10](decisions/2026-11-02-frame-animation.md) — 生成横条、统一切片、脚底/影子锚定、状态切帧；改玩家动作前读。
- [UI 方向 0.9](decisions/2026-11-02-ui-direction.md) — 档案纸页、配色令牌、12/24/36/48 字号；改 UI 前读。
- 2026-10-31 M1：自由造句、连续横版区域、全员完整动画、完整 Hub + 基底升级；详见 [GDD v0.2 决策](../GDD-v0.2-decisions.md)。

## 已知问题

- [角色浮空/像素发糊](issues/2026-11-02-sprite-float-blur.md) — 根因与修法；0.9 已修（见 visual-polish）。

## 调研

- [Godot 工具调研](../research/2026-11-02-godot-tools.md) — 相机/对话/测试/调试/性能/特效插件的版本、许可、结论；装插件前读。
- [MDS 评估与 3 房间 spike](../research/metroidvania-developer-system.md) — 已定全量接入；动 MDS 前读。

## 待定

- 笑面史官身份、语言语法、单局长度、污染净化、垂直切片 Boss、中文像素字体、工作名、每日挑战。
- 详见 GDD §20。

## 最近阶段

- [2026-10-31 角色参考与定位](sessions/2026-10-31-character-references.md)。
- [2026-10-31 美术风格测试](sessions/2026-10-31-art-style-tests.md)。
- [2026-10-31 GDD v0.1](sessions/2026-10-31-gdd-v0.1.md)。
- [2026-10-31 核心系统与并行模块](sessions/2026-10-31-core-systems.md)。
- [2026-10-31 M1 可玩切片](sessions/2026-10-31-m1-integration.md)。
- [2026-11-01 可玩版出包](sessions/2026-11-01-final-playable.md) — 前一版历史状态。
- [2026-11-01 试玩体验改进 0.2.0](sessions/2026-11-01-playability-polish.md) — 房门/复活/构筑/动作/HUD/真实点击回归；继续试玩修复时读。
- [2026-11-01 三章冒险 0.3.0](sessions/2026-11-01-chapter-campaign.md) — 三章/三Boss/36词/8法术形态/抉择结局/图标；扩剧情与法术时读。
- [2026-11-01 言出法随 0.4.0](sessions/2026-11-01-freeform-audio.md) — 取消语法/自由言灵/配乐配音/残影/调研；改技能或音频时读。
- [2026-11-01 深度版 0.5.0](sessions/2026-11-01-depth-0.5.md) — 第四章/最后的读者/残页商店/言灵v2/梦魇；继续完整版时读。
- [2026-11-01 AI 言灵 0.6.0](sessions/2026-11-01-ai-intent.md) — 可选 Ollama/OpenAI/Anthropic、意图校验、密钥本地化；接 AI 时读。
- [2026-11-01 世界与同行者 0.7.0](sessions/2026-11-01-world-animation-npc.md) — 14 敌人/程序化骨骼/特效/五 NPC AI 言灵/剧情圣经/120FPS/键位/宝箱；继续完整版时读。
- [2026-11-01 MDS/AI 交接](sessions/2026-11-01-handoff-mds-ai.md) — 前一版交接（已完成大部分）。
- [2026-11-02 画面打磨 0.9.0](sessions/2026-11-02-visual-polish.md) — 发糊/浮空根治、原图重做贴图、肺钟守卫新图、像素字号、档案纸页 UI、MDS 气氛；改画面前读。
- [2026-11-02 言灵 v3 0.8.0](sessions/2026-11-02-spell-v3-lexicon.md) — 13 形态、AI 组件全部生效、92 词、120 FPS 压测、MDS spike 14/14；改法术/词库/性能或定 MDS 前读。
- [2026-11-02 试玩修复 0.9.1](sessions/2026-11-02-playtest-fixes-0.9.1.md) — 首页相机、对话与人物页立绘、奖励焦点、操作说明、污染发狂、武器掉落、遗物栏、咕噜货源、Fusion 字体、Aseprite Wizard；继续试玩修复时读。
- [2026-11-02 MDS 全四章 0.9.2](sessions/2026-11-02-mds-migration.md) — 四章 32 房 MDS 世界、游戏内地图 M、game.gd 全章接线、222 项集成；继续 MDS 时读。
- [2026-11-02 数值与成长 0.9.3](sessions/2026-11-02-growth-difficulty-0.9.3.md) — 效果预算、四档难度、档案馆/词条熟练度、AI NPC 权限、E 拾取；继续调平衡时读。
- [2026-11-02 探索与动画 0.10.0](sessions/2026-11-02-exploration-animation-0.10.md) — 隐藏书库/捷径验收、门扉视觉、16 帧玩家动作与切片管线；继续打磨探索/动画时读。
- [2026-11-03 Chapter 1 demo 0.11.0](sessions/2026-11-03-chapter1-demo.md) — T1–T14 全部落地：像素统一、解码/权柄、6+6 武器遗物、Boss 三阶段、教学、Profile v2、输入集成与构建；继续 demo 试玩/修复时读。
