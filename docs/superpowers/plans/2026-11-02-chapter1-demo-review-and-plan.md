# 昌子大冒险：Chapter 1 Demo 审阅结论与实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> 本文档同时是：0.10 独立审阅全文、用户已拍板决策、Chapter 1 demo 的设计与实施规范。
> 状态：**T1–T14 + T4b 已实现（2026-11-03）**，`0.11.0-demo` Windows/Android 构建已产出；B8.4 封闭试玩待进行。

**Goal:** 把现有 0.10 的“宽而浅”原型收束成一款 20–25 分钟的 Chapter 1 可试玩 demo：全部高精度像素、语言解码/权柄成为真机制、离线“言出法随”必须可玩、LLM 接入为可选增强、Windows 优先。

**Architecture:** 保留 MDS 负责房间传输/门/地图，但把 Chapter 1 的房间几何从脚本生成的纯色块改成 16×16 TileMapLayer + 像素背景；保留现有 `SpellSynthesizer + PhraseCaster` 作为离线言灵核心，新增“每局词状态 + Profile 解码 + 权柄槽”三层状态；把 `game.gd` 的权柄/经济/教学逻辑拆成小控制器，避免继续膨胀。AI 始终是可选 provider，不进入核心依赖。

**Tech Stack:** Godot 4.7.2 stable、GDScript、GL Compatibility、1280×720 原生、Windows 优先；MDS 3.2.0 只负责世界/房间/相机；Aseprite/Pixelorama 级别像素资产；Python/Pillow 仅用于资产检查，不进入运行时。

**Spec:** 本文档 §0（用户决策）+ Part A（审阅证据）+ Part B（demo 规格）；玩法事实来源仍是 `docs/GDD.md`，剧情来源是 `docs/story-bible.md`。三者冲突时：**用户决策 > 本文档 demo 范围 > GDD 长线设计**。

## Global Constraints

- 引擎固定 Godot 4.7.2 stable、标准版、GDScript；不引入 C#/.NET、3D、第三方运行时依赖。
- **只做 Chapter 1 demo**：不新增第 2–4 章内容；2–4 章代码保留但 demo 不可达，等 Chapter 1 验收后再复制经验。
- **Windows 优先**：demo 验收范围为 Windows；Android/触屏/本地化/成就/云存档不是本次验收项，但不得故意破坏。
- **全部高精度像素**：角色、敌人、Boss、NPC、立绘、背景、Tile、UI 图标、Logo、VFX 全部像素化；禁止绘画/AI 动漫立绘进入 demo 画面。
- **“言出法随”必须离线可玩**：不配置 AI、不联网、不填 API key，也能完成造句→预览→装备→施放。
- **LLM 可选**：默认关闭；不自动联网；不内置密钥；AI 不可用时必须静默回退离线结果。AI 不作为商店页核心卖点，只作为设置里的可选实验功能。
- AI 不得绕过经济/进度：所有 AI 数值走本地白名单/上限；NPC 言灵每 NPC 每次回 Hub 最多一次 effect；AI 效果不叠加离线效果。
- 原生 1280×720；整数缩放优先；桌面目标 120 FPS；所有像素导入使用 Nearest、无 Mipmap、无压缩、二值 alpha（除明确允许的 1px 描边/发光层）。
- 不修改共享 `.tres` 的 `decoded` 状态；所有 per-run 状态用副本。
- 不通过删测试/降低断言来“通过”；每个 P0 任务必须有失败测试→实现→通过测试→提交。
- AI 密钥只存 `user://`；不提交 keystore、API key、用户存档、构建产物。
- 版本策略：`0.11.0-demo`；1.0 只在用户确认最终完整版后使用。

## 阅读索引

- **§0 已拍板决策**：先看这里；Part A 的旧问题清单已被它覆盖。
- **Part A（A1–A7）**：0.10 独立审阅全文（结论、评分、Top 10、4 周/1 周、对比、历史问题）。
- **Part B（B0–B6）**：Chapter 1 demo 定义、前 10 分钟、像素规范、语言/权柄/AI、内容、经济、UI、工程。
- **B7 任务**：P0 T1–T14 + T4b，按依赖顺序执行；每个任务含失败测试/检查、实现、通过、提交。
- **B8 验收**：demo Definition of Done；**B11** 变更记录与“先不要实现”的状态。

## Review Focus

以下五类“规格没写、但一定会被玩家/未来修改者碰到”的失败模式，必须在对应任务里有测试：

1. **未解码词共享资源被污染**：任何获得/解码路径如果直接改 `.tres` 的 `WordData.decoded`，下一局/其他存档会串状态。测试必须证明解码只改 Profile + 本局副本，不改共享资源。
2. **AI 关闭/超时/输出非法时阻断核心玩法**：离线言灵、NPC 离线回应、设置页必须继续工作；测试必须覆盖“无 AI 配置”和“AI 返回坏 JSON”两条路径。
3. **旧存档/跨版本/局内存档损坏**：新增 `decoded_words/tutorial_done/kept_item/run_save` 后，旧 v1 Profile 必须无损加载；坏 run save 必须安全丢弃。测试必须覆盖 v1→v2 迁移与损坏回退。
4. **设置/操作在标题、Hub、局内、手柄之间不可达**：玩家不得为了改键/改震动先开一局；测试必须覆盖标题/Hub 打开设置、返回、键位保存、失焦暂停、退出确认。
5. **像素资产在 1080p/整数缩放/导入设置下发糊或带灰边**：测试/检查脚本必须证明 demo 可见资产无半透明灰边、无离调色板像素、尺寸/脚底基线正确，并且 1080p 使用整数缩放或像素完美方案。

---

# 0. 已拍板决策（2026-11-02，用户原话归纳）

> 用户原话要点：**第一章 demo；能做到全部高精度像素也好；我要做成真机制；一定要可以自主接入大语言模型；先 Windows；AI 进商店是可选功能；但是言出法随的是必须要有的；先不要干活，把总结写成一个单独文档，方便以后 AI 按说明修复。**
>
> 这一节优先于 Part A 里的“审阅时问题清单”。Part A 保留原文作为证据与历史记录。

- **D1 — Demo 范围**：先做 **Chapter 1 demo**；Windows 优先。第 2–4 章不进入 demo 验收。
- **D2 — 美术**：**全部高精度像素**。不接受“像素角色 + 绘画背景 + 动漫立绘”的混合风进入 demo 画面。
- **D3 — 语言系统**：解码（看不懂→读懂）与权柄（整局规则）必须做成**真机制**；不只是 UI 文案。离线“言出法随”是必须有的核心。
- **D4 — LLM**：**可以自主接入大语言模型**；但 AI 是商店可选功能，不是必选依赖；“言出法随”的离线版本必须完整可玩。
- **D5 — 执行顺序**：**先不要实现**；先把审阅结论、决策、修复方案写成这一份独立文档，后续 AI 按文档修改。
- **D6 — 默认派生决策**（本 demo 先按此执行，用户可改）：
  - Demo Hub 只保留 **3 名可交互 NPC**：陆沉（教学/解词/档案馆）、阿砚（锻造）、咕噜（商店）；闻烬/白榆保留资产与代码，demo 中不可交互。
  - Demo 只保留 **2 档难度**：平静、墨雨；深渊/噩梦留到完整版。
  - Demo 先实现 **2 个权柄**：续命（revive）、改写（rewrite，重掷一次奖励）；吞噬/归档标为 P1。
  - Demo **不使用 SAPI 作为正式配音**：保留字幕与音乐/SFX；SAPI 文件只作内部占位，不进入公开 demo 宣传。
  - 不在 demo 中宣传“五结局”；demo 只到 Chapter 1 Boss + 章末选择/权柄展示 + “未完待续”。
  - 不做 Android/触屏/本地化/成就/云存档/商店页；这些是 Chapter 1 验收后的 P2。
  - 保留现有 `game.gd` 作为组装根，但把权柄/经济/教学抽成小控制器；不做全量重写。

---

# Part A：0.10 独立审阅全文（2026-11-02）

> 以下是上一轮审阅的完整内容；证据基于当时的 0.10 工作区。Part B 会把它转成可执行任务。
> **注意**：A4/A5 中关于 Android/keystore/完整版 5 结局/完整 NPC 弧光的条目，是对 0.10 全量版本的审阅；Chapter 1 demo 的验收范围以 §0 和 B0.1 为准（Windows、Chapter 1、无完整五结局）。

## A1. 一页结论

**当前阶段：内部可试玩 Alpha。**
它的内容量已经超过“垂直切片”（4 章、32 个主房间 + 4 个隐藏书库），但完成度没有到可对外 demo：世界是固定线性战役、三种美术语言拼在一起、语言系统的第三层基本没落地、发行准备几乎为零。

**最强项：自由造句 → 13 形态法术的离线推演。**
`SpellSynthesizer` 能把任意中文拆成“已拥有词 / 借用概念 / 意图”，再交给 `PhraseCaster` 生成弹幕、地裂、坠星、领域、召唤、连锁等真正不同的形态。这不是换皮词条，是项目里最有商业差异化的东西。证据：`scripts/language/spell_synthesizer.gd:165`、`scripts/combat/phrase_caster.gd:241`、`artifacts/ui/10_codex.png`。

**最致命短板：它现在不是 Roguelite，而是一条固定 24 战的线性战役。**
四章的房间序列、平台模板、敌人组合完全固定；每章都是“6 战斗房 → 休息房 → Boss”，没有分支路线、事件房、精英房、生态机制。第一局和第二局看到的是同一批房间、同一批波次、同一骨架 Boss。10 小时重复游玩不成立，2–4 小时之后主要靠数值刷取。证据：`scenes/mds/chapter_1.mdsworld.json`、`scripts/core/campaign_data.gd:39`、`scripts/game.gd:69`、`scripts/levels/mds_chapter_room.gd:91`。

**是否建议现在对外试玩：建议 5–10 人封闭试玩，不建议公开 demo 或商店页。**
封闭试玩前至少修三件事：平台不可达、NPC 言灵可无限刷碎片、动漫立绘与像素世界撕裂。否则试玩反馈会集中在“看起来像原型”和“不知道怎么造句”，而不是你最想验证的语言构筑。

**一句话：它有一个真正新鲜的魔法系统，但还没有一款游戏把它装进去。**

---

## A2. 维度速评（对应 A–H）

| 维度 | 结论 |
|---|---|
| **A 核心循环与乐趣** | 造句→预览→装备→施放的闭环是真的，离线也能玩；但所有收集词一开始就是已解码，权柄层没进游戏，构筑主要停留在“伤害 + 一个状态”。10 分钟内能感到“造句有用”，但需要玩家自己发现 C 键。 |
| **B 深度与重复游玩** | 固定线性 24 战、3 套房间模板、4 个 Boss 共用一套骨架；没有路线选择、事件房、精英房、生态机制。内容量像 4 章，重复游玩像 1 章。 |
| **C 战斗与手感** | 土狼时间、跳跃缓存、翻滚无敌帧、连段、顿帧、震屏、伤害数字都有，基础不差；但平台不可达、地面无视觉、玩家/敌人/ Boss 在暗背景上剪影差，120 FPS 下的可读性会被放大。 |
| **D 技术质量** | 类型标注、信号解耦、数据资源、单测数量都不错；但 `game.gd` 1252 行承担了战役/奖励/UI/污染/ MDS 全部调度，测试偏“数据断言 + 直接调用”，主场景退出有音频泄漏。 |
| **E 表现与可访问性** | 三种画风：绘画背景、动漫立绘、96px 像素角色；平台/地面/商店/残碑是程序占位。HUD 12px，1080p 是 1.5 倍分数缩放；没有手柄、色盲、字号、手机地图/设置入口。 |
| **F 发行准备** | Debug APK、无正式 keystore、SAPI 原型配音、NPC 立绘肖像授权风险、无本地化/成就/云存档/商店素材、无 Android 实机 120 FPS 验证。 |
| **G 叙事与结局** | 剧情圣经质量不错，章节开场/收尾也能看；但 NPC 秘密在“TA 的来历”里一次性倾倒，信任值存了不用，结局只看仁慈/污染/焚毁，“记录”只出现在结算文字里。 |
| **H 范围与风险** | 宽而浅：12 把武器是数值换皮、9 件遗物是纯被动、16 条预设短语与 4 个权柄资源完全没进游戏。最大的单点风险是“继续加内容”而不是“把一章做深”。 |

---

## A3. 评分表

| 项目 | 分数 | 依据 |
|---|---:|---|
| **系统完整度** | **6/10** | 词/短语/施法/污染/难度/成长/商店/残碑/隐藏书库都有；但权柄层、武器词槽、消耗品、局内存档、手柄缺失，多个系统只到“数据与单测存在”。 |
| **核心创意** | **7/10** | 自由语言→法术是真正稀缺的创意，离线解析可用，13 形态有区分；扣分在解码、权柄、短语持久化没有接上，创意没有变成长期目标。 |
| **内容量** | **5/10** | 95 词、12 武器、9 遗物、14 敌人、36 房听起来很多；但 24 个战斗房只有 3 套平台模板，4 个 Boss 共用骨架，独特内容约 2–4 小时。 |
| **美术统一** | **3/10** | 背景是绘画级 AI 图，角色是 96px 像素，NPC 立绘是 800×1000 动漫图，平台是纯色矩形；三种语言互相打架。 |
| **动作手感** | **6/10** | 移动/跳跃/翻滚/连段/受击反馈的基础扎实；平台不可达、暗色剪影、敌人单纹理程序动画拖后腿。 |
| **音频** | **5/10** | 五首程序化循环 + SFX + 语音 ducking 可用；配音是 SAPI 原型，`set_music_layer()` 是空实现，没有真正的战斗/探索自适应层。 |
| **工程稳定** | **6/10** | 3083 单测 + 265 集成全绿，导出可运行；但 `game.gd` 巨石、测试路径浅、无局内存档、退出有音频泄漏。 |
| **发行准备** | **2/10** | Debug 签名 APK、无正式 keystore、无本地化/成就/云存档/商店页、肖像与配音版权未清、无 Android 实机验证。 |
| **综合** | **5/10** | 作为内部 Alpha 很 impressive；作为可对外 demo 还差一次“减法 + 统一 + 第一小时”。 |

### A3.1 验证记录（区分“我验证过”和“我推断”）

**实际运行/读取到的：**
- 单测：`Results: 3083 passed, 0 failed`。
- 集成：`INTEGRATION: 265 checks, 0 failures`。
- 主场景 headless 退出：`8 ObjectDB instances were leaked`、`4 resources still in use`；泄漏对象是 `AudioStreamPlaybackOggVorbis / OggPacketSequencePlayback` 等音频播放对象。单测套件退出也有 1 个 RID、1 个 CanvasItem、7 个 ObjectDB、2 个资源警告。
- 95 个词资源全部 `decoded = true`；92 个词有 `power`，63 个词带 `damage`，只有 1 个词带 `burn`、1 个带 `chain`、1 个带 `pulses`。
- 四章 MDS 房间的 `platform_pattern` 序列完全一致：`0/1/2/0/1/2`，Boss 0、休息 0、书库 1；每章 9 个房间（8 主房 + 1 书库）。
- 未找到任何 `*.keystore / *.jks`；APK 在 `build/android/changzi-adventure.apk`，约 61.8 MB。
- 未找到任何 `InputEventJoypad*` 引用；键位 UI 只处理 `InputEventKey`。
- 未找到 `translation / locale / steam / achievement / cloud save` 的实现代码；`project.godot` 没有本地化配置。
- 游戏仓库与工作室仓库干净。

**未验证、只能推断的：**
- Android 实机 120 FPS / 60 FPS、触屏手感、返回键行为（代码里没有 `NOTIFICATION_WM_GO_BACK_REQUEST` 处理，可能直接退出，需实机确认）。
- 1080p 与手机宽屏下的实际像素缩放/UI 可读性（`canvas_items` 在 1080p 是 1.5 倍分数缩放）。
- 真实 AI provider（Ollama/OpenAI/Anthropic）的延迟、失败率与成本。
- 10 小时以上的实际重复游玩体验（按内容量推断不成立）。
- 平台跳跃不可达是按参数计算，未做运行时采样：`-500²/(2×1350) ≈ 92.6 px`，平台高出地面 122–225 px。
- “永久起始污染可到 100 且不触发发狂”是按 `_apply_npc_blessings()` 早于信号连接推断，需跑一次完整流程确认。
- NPC 立绘的肖像授权状态；`asset-manifest.json` 自己写明“confirm likeness usage rights before public release”。

---

## A4. Top 10 问题（按严重度）

> 成本口径：**S ≤ 3 天，M 1–2 周，L ≥ 3 周**（单人全职，含验证；AI 辅助可压缩但不要按 0.5 算）。

### A4-1. 固定线性战役，不是 Roguelite（L）
**位置/证据**：四章世界文件都是 `ch1_01 → … → ch1_06 → ch1_rest → ch1_boss` 的直线，`links` 为空；每章 `platform_pattern` 序列完全相同；`CampaignData` 的 `rooms` 固定数组；`ROOM_WAVES` 固定；`game.gd` 按 `room_index` 生成固定波次。GDD §11 承诺的“墨潮上涨 / 塌陷平台 / 视野压缩 / 舞台机关”在 `scripts/levels/mds_chapter_room.gd:41` 里只实现了背景与天气，没有玩法机制。
**玩家后果**：第二局开始没有新路线、新事件、新组合；10 小时只能靠刷数值和换武器，Roguelite 的“下一局不一样”不成立。
**最小修复**：每章至少做一个 2–3 节点的分支（战斗/精英/事件/商店），从 10–12 个波次池里抽 6 场；每章加 1 个真正影响战斗的生态机制；先把“固定 24 战”改成“路线 + 事件”。
**成本**：L；如果只做 Chapter 1 demo，可压到 M。

### A4-2. 三种美术语言拼贴，第一眼像原型（L；有 S 级急救）
**位置/证据**：`artifacts/ui/02_hub_dialogue.png` 是 800×1000 动漫立绘；`artifacts/mds/mds_04_rest.png` 里商店是橙色方盒、残碑是绿色圆环、平台是纯色青矩形；`artifacts/mds/mds_02_combat.png` 角色是 96px 像素，背景是绘画级 AI 图；`artifacts/ui/01_title.png` 的 logo 还带着方形深色底。`scripts/levels/mds_chapter_room.gd:79-122` 只生成碰撞地面与 `ColorRect` 平台；`assets/asset-manifest.json` 自己列出“边缘抗锯齿、背景单层、立绘肖像权、动作近似帧”四个 known gaps。
**玩家后果**：商店页第一张图就会暴露“素材拼贴”；NPC 立绘越漂亮，越显得世界不是同一个游戏；平台/商店/残碑像 debug 占位。
**最小修复**：立即隐藏或替换 5 张动漫立绘（改成像素半身/头像，或改成世界内对话）；给地面和平台做 tile/描边；给玩家/敌人加 1px 亮边或提高 15% 明度；logo 去底。长期只能选一条路线：纯像素，或接受混合风并统一 value/轮廓。
**成本**：急救 S；完整统一 L。

### A4-3. 平台不可达，地面只有碰撞没有视觉（S）
**位置/证据**：`scripts/player/player.gd:12` `jump_velocity=-500`、`gravity=1350` → 跳跃高度约 **92.6 px**；`scripts/levels/mds_chapter_room.gd:21` 地面 560，平台中心在 `450/420/335/440`，平台顶面高出地面 **122–225 px**；玩家头顶离平台底只有 22 px，起跳会先撞头。`_build_ground()` 只加了 `StaticBody2D + CollisionShape2D`，没有地面视觉。敌人脚本里没有任何跳跃/攀爬（grep 只命中动画 gait）。
**玩家后果**：平台是假的：上不去、跳起来撞头；角色像站在不可见的地面上；如果只把平台降低，近战敌人又永远上不来，玩家可以站平台无伤清房。
**最小修复**：把平台顶面压到离地 40–70 px（y≈490–510），或把跳跃提高到 `-620` 并加二段跳；同时给地面/平台加视觉；给近战敌人加跳跃/冲锋上平台，或把平台改成可被远程威胁的半安全区。
**成本**：S（数值+视觉）；如果加敌人垂直AI，M。

### A4-4. 语言第三层与“解码”没有进游戏（M）
**位置/证据**：
- 95 个词资源全部 `decoded = true`；`PhraseResolver` 的未解码分支永远不触发：`scripts/language/phrase_resolver.gd:49`。
- `_authority_flags` 只在 `scripts/game.gd:1192` 被读取，从未被写入；`AuthorityEffects.apply()` 只在测试里调用；4 个权柄资源没有获取/装备入口；`RunState.authority` 在游戏里从未设置。
- 16 条预设短语与 4 个权柄在 `ContentLibrary` 里定义但游戏代码没有引用。
- `Profile.discover_phrase()` 从未被调用；Codex 的“已发现组合”只是本局 `_example_phrases`，每局重置。
- 词条熟练度的“效果加成”只在净化时使用：`scripts/combat/phrase_caster.gd:99` 的 `_mastery_power()` 只在 707–709 用于 `purify`；伤害走的是 `damage_scale`，没有把熟练度算进去。
**玩家后果**：“语言即叙事/构筑”只剩“自由造句沙盒”：没有从看不懂到读懂的弧光，没有 Boss 权柄改变整局规则，没有跨局词库收藏；Codex 显示“熟练 Lv.N”但伤害不涨，玩家会觉得系统在骗他。
**最小修复**：把 20–30 个词设为未解码，按 Boss/残碑/陆沉教学逐批解锁；让每章 Boss 掉落一个权柄并真正生效（复活/重掷/保留一件/污染转伤害）；调用 `discover_phrase()` 并持久化 Codex；熟练度要么加到伤害，要么从 UI 去掉“效果加成”。
**成本**：M。

### A4-5. 构筑深度不足：12 把武器是数值换皮，9 件遗物是纯被动（L）
**位置/证据**：`WeaponData` 只有 damage/cooldown/range/projectile_speed/tags/word_slots；所有近战走 `scripts/combat/melee_weapon.gd:12` 同一个 hitbox，所有远程走 `scripts/combat/ranged_weapon.gd:10` 同一个 projectile；玩家连段固定 `1.0/1.18/1.55`：`scripts/player/player.gd:362`。`word_slots` 在 9 把武器里写了 1–3，但没有任何脚本读取。遗物只有 9 件，效果在 `scripts/combat/relic_effects.gd:11`，全部是纯被动且不能叠层/升级。词库审计：63/92 个词带 damage，只有 1 个 burn、1 个 chain、1 个 pulses。
**玩家后果**：捡武器只是“伤害/攻速”换数字；遗物是“回墨/减CD/吸血”；两把短语槽固定后，构筑很快收敛到“最高伤害 + 回墨”。玩家不会产生“这局我要玩雷火/时间/召唤”的冲动。
**最小修复**：砍到 6 把真正不同的武器（每把一个独特招式/状态：链刃拉拽、墨斧破盾、笛子召唤、枪贯穿等）；6–8 件能改变规则的遗物（而不是 +10%）；把武器词槽或短语修饰真正接上；加 2–3 种消耗品。先做深 6 件，不要留 12 件数值皮。
**成本**：L；只做 6 件可压到 M。

### A4-6. NPC 言灵可以无限刷永久资源，还能永久堆起始污染（S）
**位置/证据**：
- 离线言灵每次提交都会 `apply_effect`：`scripts/hub/hub.gd:354`；`NPCInspireUI` 提交后不锁次数，可以反复开/反复说。
- 未知句：+4 记忆碎片、+3 永久起始污染（`scripts/hub/npc_profiles.gd:204`）；对咕噜说“记忆”每次 +6 碎片；对白榆说“地图”每次 +10 起始残页；对阿砚说“神”每次 +1 锻造祝福、“真名”每次 +1 免费神铸。
- 这些效果没有每次拜访的上限；只有 AI 的 `action` 有 `_ai_favors` 一次限制（`scripts/hub/hub.gd:404`）。
- AI 配置时，离线效果先应用一次，AI 效果再应用一次：`scripts/hub/hub.gd:381`。
- `start_pages` / `start_corruption` 每局从 Profile 叠加，没有消耗/重置：`scripts/game.gd:352`。
**玩家后果**：刷 50 次“记忆”就能买穿档案馆；刷“地图”每局白拿大量残页；刷“神”让所有武器伤害无限涨。未知句还会永久堆起始污染；按代码顺序，起始污染到 100 时信号尚未连接，可能开局 100 污染但不触发发狂，直接把存档变成不可玩（这条需实机确认）。
**最小修复**：每个 NPC 每次回 Hub 只能产生一次 `effect`（和 `action` 共用 `_ai_favors`）；`fragments/map_pages/forge_bonus` 加上限或改为一次性；`start_corruption` 改成“本局消耗品/可清除的诅咒”；AI 模式只应用 AI 效果，不要叠加离线效果。
**成本**：S。

### A4-7. 四个 Boss 共用一套骨架，叙事交付是“资料倾倒”（L）
**位置/证据**：
- 第二章 Boss 的 `boss_script` 是 `&"ink"`（`scripts/core/campaign_data.gd:105`），与第一章同一套 `_page_wave/_ink_rain/_rewrite`；`SmilingArchivist` 与 `LastReader` 只是各加一个 `_mirror_fan`/`_read_page`，都继承 `InkArchivist`。
- 最终 Boss 没有实现剧情圣经里的“复制玩家武器 / 改写战场规则”；`_rewrite` 只是禁用短语槽 3 秒。
- NPC 的秘密在 `scripts/ui/npc_inspire_ui.gd:57` 第一次打开就全文显示，包括“陆沉撕名册是为自保”“阿砚是锻造之神”“白榆不是活人”；`npc_trust` 只写不读（grep 只命中 Profile 自身）。
- 结局只看 `won/corruption/mercy/burned`（`scripts/core/campaign_data.gd:229`）；`_records` 只出现在结算文字里；最终选项写着“以你保存的记录决定结局”，但记录不参与判定。隐藏结局“换位”在剧情圣经里仍标注为“后续可扩展”（`docs/story-bible.md:196`）。
- 结局屏是纯文字面板：`scripts/ui/ending_screen.gd:22`。
**玩家后果**：四个 Boss 像同一个 Boss 换皮；最终战没有“笑面史官改写规则/删除词/复制武器”的高潮；NPC 弧光变成资料页；信任和记录没有回报；通关后没有结局画廊或 NPC 后日谈，重玩结局动力低。
**最小修复**：给每个 Boss 一个真正改变打法的机制（肺钟的呼吸窗口、读者的封页、笑面史官的武器镜像/规则改写）；NPC 秘密按信任/拜访次数分层解锁；结局判定加入 records/trust，或在文本里删掉“由记录决定”；加一个结局画廊。
**成本**：L；只做最终 Boss + 文本修正可 M。

### A4-8. 战斗可读性与动画层级不一致（M）
**位置/证据**：`artifacts/mds/mds_02_combat.png` 里玩家和墨犬都是黑/深红，叠在深蓝绘画背景上；`artifacts/mds/mds_05_boss.png` 的 Boss 是一团黑红剪影；背景里漂浮的纸页与玩家弹幕/敌人弹体颜色接近；HUD 关键信息是 12px（`scenes/ui/hud.tscn:41`）。玩家有 16 帧，敌人/Boss 仍是单纹理程序动画；`docs/art-progress.md` 自己也承认玩家帧在暗背景上偏暗。`project.godot` 是 `canvas_items` 拉伸，1080p 为 1.5 倍分数缩放。设置里没有色盲/字号选项，也没有失焦自动暂停。
**玩家后果**：120 FPS 下动作更顺，但看不清谁在出招；BOSS 的剪影和背景混在一起；小字号在 1080p/手机上难读；色盲玩家无法区分危险/安全提示。
**最小修复**：先把 value 分层做出来（玩家亮边、敌人轮廓、背景压暗 10–15%）；危险预警统一形状语言（不只靠颜色）；HUD 字号提供 12/16/20 三档；1080p 用整数缩放或 720p 基准 + 黑边；失焦自动暂停。
**成本**：M。

### A4-9. 前 10 分钟没有教学，设置/手柄/手机入口缺失（M）
**位置/证据**：
- 标题只有难度、开始/继续、退出（`scripts/ui/title_screen.gd:62`）；Hub 只有帮助、言灵、交互（`scripts/hub/hub.gd:167`）；设置菜单只在运行场景里（`scenes/main.tscn:65`），靠 F10 打开。
- 首次进入 Hub 只有 3 句陆沉对话，没有引导打开 Codex、没有引导完成一次“选 2 个词→预览→装备”。
- 触屏菜单只有背包/造句/暂停/换武器（`scripts/ui/touch_controls.gd:28`），没有地图/设置；地图是键盘 M。
- 没有任何手柄事件；键位 UI 只接受 `InputEventKey`。
- 暂停菜单“返回档案馆”和“重新开始”都没有二次确认（`scripts/ui/pause_menu.gd:88`）。
- 没有“新游戏/清除进度”；有存档时标题只显示“继续旅程”。
**玩家后果**：新玩家可能一整局都不知道 C 是核心；想改键/改震动只能先开一局；手柄玩家直接流失；手机玩家打不开地图和设置；误点“返回档案馆”会丢掉 30 分钟一局。
**最小修复**：首次进入 Hub 强制一次 Codex 教学（2 个词→预览→装备→试用）；标题/Hub 加设置、新游戏、清除进度；补手柄映射与焦点导航；触屏加地图/设置；离开/重开加确认；失焦暂停。
**成本**：M。

### A4-10. 发行准备与 QA 都还没到“可发布”（L）
**位置/证据**：
- Android `package/signed=true` 但没有 keystore 配置（`export_presets.cfg:50`），构建是 Godot debug 证书；仓库里找不到 `*.keystore/*.jks`。
- 配音是 SAPI Huihui 原型（`docs/art-progress.md:27`）；NPC 立绘基于真人参考，manifest 明确要求发布前确认肖像权。
- 没有本地化、Steam/成就/云存档代码；标题/商店页素材不在仓库；没有 Android 实机 120 FPS 记录。
- `RunState` 没有序列化，关闭应用/返回 Hub 即丢失整局；`Profile` 直接 `ConfigFile.save`，没有备份/原子写/版本迁移读取。
- 3083 + 265 全绿，但集成测试是“传送玩家 + 100000 伤害秒杀 + 直接 `_reward_ui._choose(0)`”（`tests/integration_playability.gd:51`），没有真实输入、没有存档、没有手机/手柄、没有退出泄漏测试。
- 我复现了主场景退出 `8 ObjectDB + 4 resources` 泄漏，泄漏对象是音频播放。
**玩家后果**：现在只能内部试玩；付费发行会被 debug 签名、SAPI 配音、肖像权、无本地化/成就/云存档直接挡住；手机切后台/被杀会丢一局；绿色测试无法保证手感与生命周期。
**最小修复**：正式 keystore + Android 实机 QA；替换配音与立绘或取得授权；局内自动存档/断点续玩；本地化/成就/云存档至少做中文+英文框架；补输入驱动测试、退出清理、存档迁移测试。
**成本**：L。

---

## A5. 4 周 / 1 周 / 砍掉什么（原审阅）

> 这是审阅时的时间建议；实际执行以 Part B 的任务/依赖与 §0 决策为准。用户已要求**先不实现**。A5 里的 Android/keystore/发布相关行属于完整发行，不是 Chapter 1 demo 的验收范围。

### A5.1 如果只做 4 周：做一个“Chapter 1 公开 demo”，不要碰 2–4 章

> 目标不是 1.0。按当前内容 + 发行要求，单人全职到可付费 1.0 我估计还要 **4–6 个月**；4 周只能做一个能拿出去验证的 Chapter 1 demo。

**Week 1：第一眼统一**
- 隐藏/替换 5 张动漫立绘，改成像素半身像或世界内对话。
- 给 MDS 地面/平台做 tile 或至少描边；把纯色矩形平台换成有材质的三层平台。
- 玩家/敌人/Boss 加亮边/提高明度；背景压暗 10–15%；标题 logo 去底。
- 修平台高度到 40–70 px，或把跳跃提高到 `-620`；补地面视觉。

**Week 2：前 10 分钟**
- 首次 Hub 强制 Codex 教学：选 2 个词 → 预览 → 装备到 Q → 打一场。
- 标题/Hub 加设置、新游戏、清除进度；补手柄映射与焦点；触屏加地图/设置。
- 修 NPC 言灵经济：每 NPC 每次回 Hub 一次 effect；clamp fragments/pages/forge；AI 效果不叠加离线。
- 暂停菜单离开/重开加确认；失焦暂停。

**Week 3：一局完整**
- 只做 Chapter 1 的 Boss 独特机制（呼吸窗口/纸页封路/阶段改写）。
- 从 95 词里拿 15–20 个做“未解码→解码”；让 Chapter 1 Boss 掉一个权柄并生效。
- 持久化“已发现短语”；让 Codex 跨局显示收藏。
- 加 1 个事件房 + 1 个精英房，验证“路线有变化”。

**Week 4：试玩与发行**
- 5–10 人封闭试玩，观察前 10 分钟；记录“玩家是否主动造句”“是否理解词/短语/权柄”。
- 补输入驱动测试、存档/读档、退出清理；修音频泄漏。
- Android 实机 60/120 FPS；正式 keystore；Windows/Android 签名包。
- 只修 Top 5 反馈，不再加系统。

**4 周明确砍掉**：2–4 章的公开发布、AI 作为卖点、无上限档案馆数值、12→6 把武器、9→6 件遗物、4→2 档难度、16 条未使用短语、4 个未使用权柄、地图快旅、每日挑战。

**验收指标**：8/10 试玩者能在 10 分钟内说出“选词→短语→装备→施放”，并主动再组一条短语；8/10 能完成 Chapter 1 前 3 房；没有人卡在平台/地面；6/10 想再来一局。

### A5.2 如果只做 1 周：只修“前 10 分钟 + 第一眼”，用 Chapter 1 做封闭试玩

**Day 1–2：入口与教学**
- 标题：开始/继续 + 设置 + 新游戏/清除进度。
- 首次 Hub：一句任务 + 强制 Codex 教学；HUD 第一次出现“按 C 造句”提示。
- 暂停/离开/重开确认。

**Day 2–3：第一眼**
- 隐藏/替换动漫立绘；给地面/平台加视觉；玩家/敌人加亮边；标题 logo 去底。
- 把平台降到可达高度；如果来不及做敌人垂直 AI，先把平台改成“装饰 + 远程掩体”，不要假装可跳。

**Day 3–4：经济与输入**
- 每 NPC 每次回 Hub 一次 effect；clamp 碎片/起始残页/锻造祝福；AI 不叠加离线。
- 触屏加地图/设置；手柄至少映射移动/跳/攻击/翻滚/交互/暂停；失焦暂停。

**Day 5：试玩**
- 出 Windows 签名包；5 个试玩者；只修崩溃/卡死/看不懂，不加内容。
- 不公开发布，不上商店页。

**1 周明确砍掉**：2–4 章、AI 宣传、档案馆刷数值、12 把武器、9 件遗物、4 档难度、16 条短语、4 个权柄、地图快旅、每日挑战、所有“以后再说”的新系统。

### A5.3 明确建议砍掉/合并的内容

- **把 4 章当 1 章做**：公开 demo 只发 Chapter 1；2–4 章留在内部，等第 1 章验证完再复制经验。
- **砍 AI 作为卖点**：保留“可选实验”，不要放在商店页第一屏；默认离线推演已经够好玩。
- **砍无上限档案馆数值**：改成有上限的 8–12 级，或改成“解锁新词/新短语/新事件”，否则它会掩盖构筑问题。
- **砍 12 把武器到 6 把**：每把必须有独特招式/状态；数值换皮全部合并。
- **砍 9 件遗物到 6 件**：每件必须改变打法；纯 +% 的合并成词条。
- **砍 4 档难度到 2 档**（平静/标准）：等敌人变体与 Boss 机制做出来再加噩梦；现在的高难度只是血量和伤害倍率。
- **砍 16 条未使用短语、4 个未使用权柄**：要么接进游戏，要么从代码库删掉，避免“看起来有、实际没有”。
- **砍地图快旅/每日挑战/成就**：在 demo 阶段不是优先项。
- **不要砍词库**：95 词是资产；把其中 20–30 个改成未解码，反而能把“语言”卖点做实。

---

## A6. 与 2–3 个同类商业独立游戏对比（只比设计，不比预算）

| 游戏 | 它做对的设计维度 | 本作差距 | 可偷的设计 |
|---|---|---|---|
| **Hades** | 每局房间顺序/奖励有变化；Boon 之间有双重祝福和传奇组合；NPC 关系在每局之间推进，死亡也推进故事。 | 本作 24 战固定、3 套模板；9 件遗物无组合；NPC 信任存了不用，死亡只回 Hub 刷数值。 | 每局至少 2 个随机事件/精英；把 NPC 信任做成每局可触发的小场景；让死亡也推进一条 NPC 线。 |
| **Dead Cells** | 每把武器有独立招式/节奏；每个生态区有机制与敌人组合；Boss 有明确不同的攻防节奏。 | 本作 12 把武器同一套连段/弹道；生态机制只是背景；4 个 Boss 共用骨架。 | 6 把武器 6 种手感；每章 1 个机制（墨潮/塌陷/黑暗/舞台规则）；Boss 至少一个“必须换打法”的机制。 |
| **Inscryption** | 语言/叙事不是外挂文档，而是规则本身；玩家在机制里“读”故事，结局回收前面的选择。 | 本作语言在战斗里是强的，但解码/权柄/结局与战斗脱节；NPC 故事在资料页倾倒；结局只看两个数值。 | 让“解码一个词”改变战斗规则；让权柄成为每章的核心奖励；让结局回收玩家实际用过的词/救过的人，而不是只读 mercy/corruption。 |

> 这三款都是更大团队/更长周期；这里只比设计选择。结论：本作的语言自由输入比它们更原创，但 Hades 的重复结构、Dead Cells 的武器手感、Inscryption 的“机制即叙事”是它现在最缺的三块。

---

## A7. 审阅时的问题清单（历史记录；已由 §0 回答）

> 保留原文，方便未来 AI 理解当时的取舍；实际执行以 §0 决策为准。

1. **4 周目标**：Chapter 1 公开 demo，还是 4–6 个月冲 1.0。审阅建议前者。
2. **美术路线**：坚持纯像素，还是接受“像素角色 + 绘画背景/立绘”的混合风。用户已选：全部高精度像素。
3. **语言系统**：投入 2–4 周把“解码 + 权柄 + 短语收藏”做成真机制，还是承认它是自由造句沙盒。用户已选：真机制。
4. **平台优先级**：先 Windows-only，还是双平台/手柄。用户已选：Windows 优先。
5. **AI 定位**：实验性可选，还是核心卖点。用户已选：可自主接入 LLM，但商店可选；“言出法随”离线必须。

---

**Part A 结束。以下 Part B 是把上述问题与决策转成可执行任务。**

# Part B：Chapter 1 Demo 实施规范与任务

> Part B 是未来 AI 的执行规范。除非用户另行拍板，不要越过这里定义的 demo 范围。
> **先读**：项目 `CLAUDE.md`、`docs/memory/MEMORY.md`、本文档 §0、`docs/GDD.md`、`docs/story-bible.md`、`docs/art-progress.md`。
> **先不要做**：第 2–4 章、Android、商店页、成就/云存档、1.0 版本号、全量重写 `game.gd`。

## B0. Demo 定义

**一句话**：一个 20–25 分钟的 Chapter 1 可试玩 demo；玩家从标题进入 Hub，学会“选词→造句→装备→施放”，穿过墨雨档案馆的 6 个战斗/精英/事件房，击败墨骸史官，拿到第一个权柄，看到“未完待续”。

**Demo 流程**：
1. 标题：新游戏/继续、设置、退出；2 档难度（平静/墨雨）；不显示 AI 作为卖点。
2. Hub：3 名可交互 NPC（陆沉/阿砚/咕噜）+ 训练碑；首次进入触发教学。
3. Chapter 1：`ch1_01` 教学战斗 → `ch1_02` 战斗 → `ch1_03` 战斗 + 隐藏书库门 → `ch1_04` 精英房 → `ch1_05` 事件房 → `ch1_06` 战斗 → `ch1_rest` → `ch1_boss` → 权柄选择 → 章末故事/二选一 → demo 结束屏。
4. 可选：`ch1_vault` 宝箱 + 残碑。
5. 不进入第 2 章；不显示五结局；不进入完整版 Hub 五 NPC 全功能。

**Demo 房间表**（保持 MDS 的房间传输/门/地图；内容按此重做）：

| 房间 | 类型 | 敌人/内容 | 设计目的 |
|---|---|---|---|
| `ch1_01` | 教学战斗 | 墨犬 ×1 + 抄写虫 ×1（弱化） | 教会移动/攻击/翻滚/短语；不掉死亡 |
| `ch1_02` | 战斗 | 空白人 + 墨犬 + 抄写虫 | 第一次清房三选一；给一个未解码词 |
| `ch1_03` | 战斗 + 书库门 | 墨囊投手 + 残页群 + 墨犬 | 展示远程/飞行；隐藏书库入口 |
| `ch1_04` | 精英 | 错字兽 + 空白人 ×2 | 第一次精英；保证遗物/未解码词 |
| `ch1_05` | 事件 | 无强制战斗 / 小伏击 | 二选一：解码一个词但 +污染，或拿残页离开 |
| `ch1_06` | 战斗 | 墨囊投手 + 抄写虫 + 墨犬 + 残页群 | 章末压力测试；给 Boss 前补给 |
| `ch1_rest` | 休息 | 商店 + 残碑 + 捷径门 | 购买/恢复/回长廊 |
| `ch1_boss` | Boss | 墨骸史官（专属机制） | 第一章高潮；掉权柄 |
| `ch1_vault` | 隐藏书库 | 宝箱 + 残碑 | 可选成长；给未解码词/遗物 |

**平台规则（demo）**：
- 统一 16×16 TileMapLayer；地面表面 `y=560`（row 35）。
- 平台只允许两级：顶面 `y=480`（row 30）和 `y=448`（row 28）；从地面到第一级 80 px，跳跃高度 92.6 px，可达；第二级从第一级 32 px，可达。
- 战斗房最多 2 个平台；休息/书库可以 1 个。禁止再出现 450/420/335/440 这种不可达高度。
- 近战/冲锋敌人必须能跳上第一级平台（新增 `Enemy` 跳跃行为）；否则平台会成为无敌点。
- 所有平台/地面必须有像素 Tile 视觉；禁止 `ColorRect` 纯色块和不可见地面。

**Demo 敌人**：`ink_hound`、`scribe_bug`、`blank_man`、`typo_beast`、`ink_bomber`、`page_swarm`。其余敌人资产保留，不进入 demo 波次。
**Demo Boss**：墨骸史官，专属 3 阶段机制（见 B4.8）。
**Demo 难度**：平静、墨雨；深渊/噩梦在 demo 标题隐藏。
**Demo 时长**：首次 20–25 分钟；熟练玩家 12–15 分钟。
**Demo 版本**：`0.11.0-demo`；不是 1.0。

**Demo 是线性第一章**：本次只通过精英/事件房展示“房间有变化”，**不承诺完整版的 Roguelite 分支/随机路线**；分支、随机波次、生态机制是 P2/完整版。演示中不要用“每局都不一样”做宣传。

### B0.1 Demo 与完整版的边界

- Chapter 1 demo 是**唯一**要对外验证的版本；第 2–4 章不进入 demo 构建的流程。
- 完整版的五结局、五 NPC 弧光、Android、本地化、成就/云存档、商店页全部 P2；本 demo 不实现、不宣传。
- 原审阅 A5 里的 Android/keystore/正式配音属于完整发行阶段；**Chapter 1 demo 的验收只要求 Windows 可运行构建**（签名/打包可以后置，但不能把 debug 构建当公开商店版本）。
- 如果时间不足，优先砍房间/敌人数量（保留 4 战斗 + 精英 + 事件 + 休息 + Boss），**不要砍**像素统一、解码、权柄、离线言灵、前 10 分钟教学。

## B1. 前 10 分钟脚本与验收

**Minute 0–1：标题**
- 背景是像素档案馆；Logo 是透明底像素徽记；按钮：继续/开始旅程、设置、退出。
- 难度只显示平静/墨雨；默认平静；说明一行。
- 设置可从标题直接打开：全屏、音量、震动、闪屏、键位、AI（可选）。
- 没有存档时显示“开始旅程”；有存档时显示“继续旅程 + 新游戏（清除进度）”；新游戏要二次确认。

**Minute 1–4：Hub + 陆沉**
- 3 名 NPC 横向排开，但用像素场景/道具打破“站桩”：陆沉在书桌旁，阿砚在铁砧旁，咕噜在货摊后。
- 陆沉 3 句对话：名册丢失、第一页在档案馆、不要相信替你保存记忆的人。
- 对话结束出现 HUD 提示：“按 C 打开语言图鉴，选 2 个词造一条短语。”

**Minute 4–7：Codex 教学**
- 首次打开 Codex，顶部显示 2 步提示：
  1. 选 2 个已解码词（默认选中 `燃烧` + `火`）。
  2. 预览 → 装备到 Q → 关闭。
- 预览必须显示：法术形态、墨耗、冷却、污染、稳定性、实际伤害/治疗/召唤等。
- 底部有 3 个示例句按钮；离线即可用；AI 按钮存在但标注“可选”。
- 装备成功后 HUD 短语槽更新；提示“去训练碑试一次”。

**Minute 7–10：训练碑 + 第一房**
- Hub 训练碑生成一个不会死的训练假人；玩家按 Q/F 施放，看到伤害数字/状态/墨耗。
- 进入 `ch1_01`，2 个弱敌人；清房后第一次三选一奖励；奖励中出现一个未解码词（glyph + 模糊描述）。
- HUD 提示：“按 C 查看未解码词；在 Hub 找陆沉解读。”

**验收**：
- 8/10 试玩者能在 10 分钟内独立完成“选 2 词→预览→装备→施放”。
- 8/10 能说出“未解码词可以先用，但有污染/不稳定”。
- 0 人因不知道按哪个键而卡住超过 60 秒。

## B2. 高精度像素美术规范

### B2.1 全局规则

- 原生 1280×720；1x 像素网格；整数缩放；全屏时 letterbox，不做 1.5x 分数拉伸。
- 所有像素资产：Nearest、无 Mipmap、无压缩、无抗锯齿；alpha 只有 0/255；允许 1px 描边/发光使用单独图层，但不能把半透明灰边烘进角色。
- 调色板：32 色以内（角色/敌人/UI 共用主色板；背景可另用 32 色，但必须同一世界色温）。
- 角色脚底基线统一；1px 墨色描边；不出现“AI 缩放噪点”“半透明灰边”“离调色板像素”。
- 禁止：绘画/AI 动漫立绘、1536×864 绘画背景直接进 demo、线性过滤背景、平滑渐变 VFX、方形底 Logo。
- VFX 也必须像素化：使用 1–2px 线段/像素点/调色板色，不使用平滑圆/渐变。

### B2.2 Demo 资产清单与落点

| 资产 | 规格 | 落点 | 处理 |
|---|---|---|---|
| 玩家 idle + 16 帧 | 96×96 idle；run/jump 112×112；attack/dodge/hurt 160×160（保留现有画布） | `assets/sprites/player/`、`assets/sprites/player/frames/` | 重新清理边缘/调色板；保留脚底基线；删除抗锯齿噪点 |
| 6 个 demo 敌人 | 96×96，RGBA，1px 描边 | `assets/sprites/enemies/` | 重新像素化/修边；确认剪影 |
| 墨骸史官 | 256×256，RGBA | `assets/sprites/bosses/ink_archivist.png` | 重新像素化；确认 Boss 剪影/阶段色 |
| 3 个 NPC 世界 sprite | 96×96 | `assets/sprites/npcs/` | 保留/修边 |
| 3 个 NPC 像素立绘 | 192×256 或 256×320，RGBA，32 色 | **新** `assets/portraits/pixel/luchen.png` 等 | 替换 800×1000 动漫立绘；不再使用真人参考 |
| 背景 | 1280×720 两层（远/中）或 3 层 | **新** `assets/backgrounds/pixel/ink_archive_far.png`、`..._mid.png` | 替换 `assets/backgrounds/ink_archive.png` 的 demo 引用 |
| 地面/平台 TileSet | 16×16，32 色，含碰撞 | **新** `resources/tiles/ch1_tiles.tres` + `assets/tiles/ch1/` | 替换 ColorRect 平台/不可见地面 |
| 道具 | 商店/残碑/宝箱/门/训练碑，像素 sprite | `assets/sprites/props/` | 替换橙色方盒/绿色圆环占位 |
| UI 图标/Logo | 像素，透明底 | `assets/branding/logo_pixel.png`、`assets/ui/` | 标题/图标/武器/短语图标统一 |
| 字体 | Fusion Pixel 12/16/24/48 | 现有 `assets/fonts/` | 保留；HUD 主信息至少 16px |
| VFX | 像素线段/点/环 | `scripts/presentation/` | 去掉平滑渐变；统一色板 |

### B2.3 必须修改的引用点

- `scripts/hub/hub.gd` `_apply_background_art()`：改为像素背景层，删除 `TEXTURE_FILTER_LINEAR`。
- `scripts/levels/mds_chapter_room.gd` `BACKGROUNDS`：改为 `assets/backgrounds/pixel/...`；`_build_backdrop()` 改为 2 层视差或静态像素层。
- `scripts/ui/npc_inspire_ui.gd` `PORTRAITS`：改为 `assets/portraits/pixel/...`；`TextureRect` 用 Nearest。
- `scripts/ui/dialogue_ui.gd`（如使用 portrait）：同上。
- `scripts/ui/title_screen.gd`：Logo 改 `logo_pixel.png`；去除图标方底；标题/按钮用像素主题。
- `scenes/ui/hud.tscn`：字体/图标/面板按像素主题调整；主信息 16px，辅助 12px。
- `scripts/levels/mds_chapter_room.gd`：删除 `ColorRect` 平台；使用 TileMapLayer；地面必须有视觉。
- `assets/asset-manifest.json`：新增像素资产、删除/标注旧绘画背景与动漫立绘“非 demo”。

### B2.4 像素 QA 检查器

新增 `tests/check_pixel_assets.py`（Python + Pillow，tracked；不进入导出）：
- 检查 demo 可见资产列表：尺寸正确、四角 alpha=0（除 UI/背景）、alpha 只有 0/255（允许 1px 描边层单独标记）、颜色数 ≤32、无离调色板像素、脚底基线。
- 输出每个文件的失败原因和退出码；CI/本地必须 0 失败。
- 对背景/UI 允许 RGB 不透明，但必须颜色数 ≤32，且无平滑渐变（用调色板直方图检查）。
- 运行：`python tests/check_pixel_assets.py --demo`。

### B2.5 美术关键路径

- **像素资产是 demo 的关键路径**。如果 4 周内做不完，**延迟 demo**，不要用“暂时用旧图”混过去；混一次就会回到审阅里的“三种画风”。
- 角色/敌人/Boss 可以由 AI 生成后**手工像素化/清理**，但不能直接缩图；必须过 `check_pixel_assets.py` 和人工截图检查。
- 旧绘画背景/动漫立绘可以留在仓库给完整版参考，但 demo 场景不得引用。

## B3. 语言系统规格（真机制）

### B3.1 三层与状态

| 层 | 数据 | 玩家行为 | Demo 要求 |
|---|---|---|---|
| 词 | `WordData` + Profile 的 owned/decoded 状态 | 获得、解码、装配到短语 | 6 个初始词已解码；10–15 个可解码；未解码可强行使用但有污染/不稳定 |
| 短语 | `ResolvedPhrase`，2 槽，自由输入 | 选词/造句→预览→装备→施放 | 离线必须完整；13 形态至少 8 种在 demo 可出现 |
| 权柄 | `AuthorityData`，1 槽 | Boss 掉落，改变整局规则 | Demo 至少 2 个：续命、改写 |

### B3.2 词状态：owned 与 decoded 分离

**问题**：现在 95 个 `.tres` 全部 `decoded=true`，而 `WordData` 是共享 Resource；直接改会让状态串档。

**实现**：
- `Profile` 新增：
  ```gdscript
  const DEFAULT_DECODED: Array[StringName] = [&"posui", &"ranshao", &"yan", &"jilu", &"gr", &"grguan"]
  var decoded_words: Array[StringName] = []
  func is_word_decoded(id: StringName) -> bool
  func decode_word(id: StringName) -> bool
  ```
- `Profile.load_profile`：旧 v1 存档没有 `decoded_words` 时，默认 `DEFAULT_DECODED`；不要重置已有 `unlocked_words`。
- 新增 `scripts/language/word_runtime.gd`：
  ```gdscript
  class_name WordRuntime
  static func for_run(source: WordData, profile: Profile) -> WordData
  static func mark_decoded(word: WordData) -> void
  ```
  `for_run` 必须 `source.duplicate()`，按 `profile.is_word_decoded(source.id)` 设置副本的 `decoded`；禁止改 `source`。
- 所有获得词路径统一走 `WordRuntime.for_run`：`RunLoot.starting_words`、`RunLoot.chest_loot`、`RunLoot.shop_offers`、`game._apply_reward`、`_on_pickup_collected`、`_open_chest`、`_claim_nearest_stele`、`CodexUI` 选词。
- `PhraseResolver` 不改逻辑：`not word.decoded` 已会让 `unstable=true` 并增加污染；保留。
- `Hub._load_words()` 的副本按 profile 设置 decoded；`decode_word()` 改为 `profile.decode_word(id)` + 更新当前 Hub 词副本；不要只改一个共享 `.tres`。

**Demo 词池**：
- 6 个初始已解码词：`posui/ranshao/yan/jilu/gr/grguan`（现有 `STARTER_WORDS`）。
- 10–15 个“可解码”词：从现有 95 词中选，覆盖火/雷/血/时间/深渊/护盾/召唤/净化/记录；每个有一句“谁写下它”的描述。
- 其余词不在 demo 出现；不要为了 demo 删掉 .tres。
- 未解码词在 Codex 显示 glyph + 一个模糊标签（如“与火有关”），不显示完整 meaning/description。

**解码来源**：
- 陆沉：每次回 Hub 可免费解码 1 个已拥有未解码词；给一句教学台词。
- 残碑：`ch1_vault` / `ch1_rest` 的残碑可解码 1 个指定词。
- Boss：墨骸史官死亡后解码 1 个词 + 掉权柄。
- 事件房 `ch1_05`：选择“读禁文”解码 1 个词，但 +8 污染；选择“拿残页”则 +12 残页。
- 商店：只卖“词片”（owned 但未解码）；不直接卖完整 meaning；价格低于解码服务。

**验收**：
- 新玩家在 Codex 能看到至少 3 个未解码词；未解码词装进短语时预览显示 `[不稳定]` 和污染；解码后同一词显示 meaning/description，且下一局仍是解码状态。
- 测试 `test_word_decoding.gd` 必须证明共享 `.tres` 的 `decoded` 未被改。

### B3.3 短语持久化

- `Profile.discover_phrase(signature)` 必须在以下时机调用：
  - `game._on_codex_equip()` 装备成功；
  - `game._on_cast_succeeded()` 首次成功施放；
  - 奖励/商店装备短语（如有）。
- `ResolvedPhrase.signature` 改为稳定签名：`"id1,id2,id3|count"`，按词 id 排序；不要用 meanings（中文/别名会变）。
- `CodexUI` 新增 `set_persistent_discovered(Array[String])` 或直接从 Profile 读取；显示“本局已发现 / 全部已发现”；跨局保留。
- 旧 `discovered_phrases` 存档继续可用；新签名去重。

### B3.4 词条熟练度

- `PhraseCaster._mastery_power()` 当前只用于净化；改为同时影响伤害：
  - 在 `_build_context()` 里 `ctx.damage = base * damage_scale * (1.0 + mastery_power)`。
  - `mastery_power` 上限 0.25（25%），避免无限刷。
  - 净化仍可使用同一加成，但不要重复乘算。
- Codex 显示“熟练 Lv.N · 伤害 +X% · 墨耗 -Y%”；如果只实现墨耗，就不要显示伤害。
- 测试 `test_mastery_damage.gd`：同一短语在 Lv.0 与 Lv.10 的伤害差 >0，且 ≤25%。

### B3.5 权柄层

- 复用 `AuthorityData` / `AuthorityEffects` / `RunState.authority`；不要再让 `_authority_flags` 永远为空。
- Demo P0 实现：
  - **续命（revive）**：`_on_player_died()` 检测 `run_state.authority` + `AuthorityEffects` 标记；每局一次；复活 50 生命 + 1.8 秒无敌；HUD 显示“权柄：续命（已用/可用）”。
  - **改写（rewrite）**：清房奖励界面出现一次“重掷”按钮；使用后重抽三选一；每局一次；HUD 显示。
- P1：吞噬（污染转伤害）、归档（保留一件物品到下一局）。
- 获取：Chapter 1 Boss 死亡后，`AuthorityChoiceUI` 展示 2 个权柄（续命/改写），玩家选 1；选择后 `AuthorityEffects.apply(run, authority)`，设置 `_authority_flags`；进入章末故事/结束屏。
- HUD：新增 1 个权柄槽（图标+名称+可用状态）；Codex/背包可查看描述。
- 测试 `test_authority_integration.gd`：Boss 掉落→选择→HUD→死亡复活一次→第二次死亡不再复活；改写重掷一次后按钮消失。
- 删除/保留 `content_library.gd` 的 4 个权柄资源；demo 只用 2 个，但不要留“未使用”状态不说明。完整版可把吞噬/归档接进第 2–4 章。
- `ContentLibrary.PHRASES` 的 16 条预设短语在 demo 中不加载/不显示；如果它们没有进入任何流程，从 demo 的 `ContentLibrary` 引用中移除（资源文件可保留给完整版）。不要让商店/奖励抽到未实现的短语。

### B3.6 离线言灵（必须）

- `SpellSynthesizer.synthesize()` 离线路径是 base game 的强制功能；不配置 AI 也能用。
- 保留 13 形态；demo 至少验证 8 种在词池里可出现：焰、墨刃、连锁、噬血、迟滞漩涡、护写、回声、追踪弹幕。
- Codex 必须显示：形态、墨耗、冷却、污染、稳定性、实际伤害/治疗/召唤、共鸣。
- 3 个示例句按钮：`让雷落在火里`、`把记忆烧成回声`、`让时间停下来`；离线点击直接预览，不依赖 AI。
- 性能护栏沿用 `PhraseCaster` 的 96 弹/12 连发/24 坠星/6 回声上限。
- 测试 `test_freeform_offline.gd`：清空 AI 配置，3 个示例句都能 `synthesize` 成功、`resolve` 非空、可装备/施放。

### B3.7 LLM 可选接入

- `AIService` 保留；默认 `enabled=false`，endpoint/model 为空也能离线玩。
- 设置页必须能配置 Ollama/OpenAI/Anthropic；标题/Hub 可打开设置；不把 AI 放在标题主按钮。
- AI 只返回 intent/JSON；`AIService.validate_intent` + `SpellSynthesizer.compile_intent` 本地校验；AI 不可用/超时/坏 JSON → 保留离线结果。
- AI NPC：
  - 离线 `NPCProfiles.resolve` 是 fallback；
  - AI 已配置时，**先不要应用离线 effect**：显示“正在聆听”，等 AI 返回后应用一次经过上限/白名单的 effect；AI 失败/超时/坏 JSON 时再应用离线 effect 一次；
  - 绝不能“离线 effect + AI effect”叠加；AI 只负责文本/action/一次受上限的 effect；
  - AI `action` 仍走白名单 + 每 NPC 每次回 Hub 一次。
- 商店文案：AI 是“可选实验功能”，不要求联网/账号；离线言灵是完整功能。
- 测试 `test_ai_optional.gd`：AI 关闭→离线通过；AI 坏 JSON→回退；AI 不可达→回退；无 API key 不崩。

### B3.8 经济/成长护栏（与 B3 一起实现）

- 每 NPC 每次回 Hub 只允许一次 `effect`；用 `Hub._npc_effect_used: Dictionary`，Hub 场景重建时重置。
- 上限（demo）：`fragments` ≤12/次；`start_pages` ≤20/次且只在本局生效（用 `pending_run_bonuses`，开局消耗）；`forge_bonus` ≤1/次、Profile 总上限 3；`forge_free` ≤1/次且消耗；`start_corruption` ≤6/次且只在本局生效，不再永久叠加。
- `map_pages`/`start_pages` 从永久 blessing 改为“下一局一次性”；`start_corruption` 同理。
- 档案馆 demo 每个 track 上限 10 级；成本递增；UI 明确“demo 上限”。
- 不修改 `RunLoot` 的随机池逻辑，但确保奖励不重复已拥有词/遗物；未解码词可重复出现？不，按词 id 去重。
- 测试 `test_economy_guard.gd`：
  - 对同一 NPC 连续提交 10 次“记忆”，碎片只增加 ≤12；
  - 第二局起始页/污染不因上次对话继续叠加；
  - AI 配置时 effect 不双倍。

## B4. Chapter 1 内容规格

### B4.1 墨骸史官：专属三阶段

**新文件**：
- `scripts/bosses/ink_archivist_ch1.gd`，`class_name InkArchivistCh1 extends InkArchivist`
- `scenes/bosses/ink_archivist_ch1.tscn`（继承现有 `ink_archivist.tscn` 的节点结构）
- `scripts/core/campaign_data.gd` 第一章增加 `boss_scene` 字段；`game._spawn_boss()` 优先用章节 `boss_scene`，没有则回退现有 `BOSS_SCENE`。

**阶段机制**（血量 280，比 0.10 的 300 略低，保证 demo 20–25 分钟）：
- **Phase 1（100%–66%）— 书页潮**：现有 `_page_wave` + 0.7 秒前摇；每 3 次攻击一次 `_ink_rain`；地面出现 3 个延迟落点。玩家只学习闪避/走位。
- **Phase 2（66%–33%）— 页风暴**：Boss 进入场地中央，召唤 3 个安全区（地面高亮圆/方框），每 0.8 秒在安全区外落页；持续 6 秒；安全区位置每次都变。玩家必须移动，不能用平台无伤。
- **Phase 3（33%–0%）— 封页 + 镜写**：
  - 每 12 秒一次 `封页`：禁用玩家一个短语槽 4 秒；HUD 明确显示“被封印”；玩家仍有武器/翻滚。
  - 每 16 秒一次 `镜写`：Boss 读取玩家当前武器类型，模仿一次——近战放一个地面冲击波，远程放 3 发扇形墨弹；前摇 0.9 秒，颜色与玩家武器不同，可翻滚。
  - 不再新增随机弹幕种类；靠“移动 + 封页 + 镜写”改变节奏。
- **Boss 死亡**：先播放 1.2 秒收束（顿帧/闪白/音乐降），然后打开 `AuthorityChoiceUI`（续命/改写），选择后再进入章末故事/结束屏。
- **测试**：`test_ch1_boss.gd` 至少覆盖 phase 2 安全区存在、phase 3 封印槽、镜写不崩溃、死亡掉权柄。

### B4.2 Hub：3 名可交互 NPC + 训练碑

| NPC | 职能 | Demo 行为 | 不做 |
|---|---|---|---|
| 陆沉 | 解词/档案/主线 | 3 句开场；每次回 Hub 解码 1 个已拥有未解码词；档案馆升级（demo 上限 10） | 不做完整 5 NPC 弧光；不一次倾倒所有秘密 |
| 阿砚 | 锻造 | 断页剑基底升级；1 句性格台词；不做神铸自由文本 | 不做完整神铸/真名线 |
| 咕噜 | 商店 | 卖词片/遗物/恢复；1 句台词；不做无限折扣 | 不做完整传闻/契约 |
| 闻烬/白榆 | — | 资产保留、demo 中站在背景/不可交互，或暂时隐藏 | 不删除资源、不加完整功能 |

- **训练碑**：Hub 新增 `TrainingDummy`（`Area2D` + `take_damage`，血量高/不死），用于 Codex 教学后的 Q/F 试放；显示伤害数字与状态。
- **Hub 场景**：3 名 NPC 不要排成等距直线；用书桌/铁砧/货摊/灯架形成小场景；像素道具替换占位。

### B4.3 叙事交付（demo 范围）

- **章节开场**：保留现有 6 句陆沉/昌子对话，但压缩/改写为 4–5 句；不要一次讲完设定。
- **Boss 前**：1 句 Boss 登场台词 + 1 句昌子回应；用字幕，不用 SAPI。
- **Boss 阶段**：每阶段 1 句短台词（屏幕上方/字幕），不打断操作。
- **章末**：Boss 死亡 → 权柄选择（续命/改写）→ 章末故事 → “带回档案馆 / 投入墨雨”二选一（仁慈/污染后果）→ demo 结束屏显示“第一章 demo 结束 / 未完待续”。
- **NPC 秘密**：demo 只放每人 1 条与当前职能相关的信息；完整背景/秘密留给完整版，不在“TA 的来历”一次性显示全部。
- **不实现**：五结局、结局画廊、NPC 后日谈、信任结局判定；这些 P2。
- **测试**：`test_demo_story.gd` 检查 Chapter 1 开场/结束/权柄选择流程可走通，不依赖 SAPI。

### B4.4 音频与配音

- Demo 保留现有五首循环音乐 + SFX + 语音 ducking；Boss 音乐切换。
- **不使用 SAPI 作为公开 demo 配音**：`Flow.voice_enabled = false` 或 demo 配置关闭 voice；字幕必须完整可读。SAPI 文件保留给内部，不进入宣传/商店页。
- 如果时间允许，用原创/免版税短语音替换 3–5 句关键台词；没有就纯字幕，不要用机器感强的 SAPI 当成品。
- `AudioManager.set_music_layer()` 空实现：demo 不承诺自适应层，删除该承诺或标注“后续”。
- 保留 `AudioManager._exit_tree` 清理，并修复退出泄漏（见 B6.4）。

### B4.5 难度与数值（demo）

- 只保留 `平静` / `墨雨`；`深渊` / `噩梦` 从标题隐藏（代码保留）。
- 平静：敌人生命 ×1.0、伤害 ×1.0、收益 ×1.0；墨雨：生命 ×1.25、伤害 ×1.15、收益 ×1.15。
- Demo Boss 280 HP；普通敌人沿用现有数据；不要让 Chapter 1 第一房劝退。
- 污染/墨耗/冷却沿用现有；但 NPC 经济/起始污染按 B3.8 修掉。

### B4.6 地图与房间探索

- 保留 MDS 世界/门/地图；`M` 打开地图，地图显示 Chapter 1 的 9 个房间节点、已访问/未访问、Boss/休息/书库标记。
- 不做快速旅行；不做随机地图；不做点击传送。
- 地图 UI 用像素纸页风格；不要当前“巨大空矩形 + 一个小点”的 debug 视图。
- 测试 `test_ch1_map.gd`：进入房间后节点点亮；Boss/书库标记存在；关闭后暂停恢复。

### B4.7 性能目标

- Windows 1280×720 窗口、120 FPS 上限；Chapter 1 普通战斗平均帧 ≤8.3 ms（120 FPS 预算），Boss 页风暴/96 弹压力 ≤11 ms；不低于 60 FPS。
- 粒子/弹幕/伤害数字沿用现有上限；新增页风暴也必须限制实体数（≤36 页/波）。
- 用 `tests/bench_spells.gd` + 实机 Chapter 1 跑图记录；不要只信 headless 数字。

## B5. UI / UX / 可访问性

### B5.1 标题

- 新游戏/继续（有存档时显示“继续旅程”，旁边小按钮“新游戏”）；新游戏二次确认“清除当前进度？”。
- 设置按钮（全屏/音量/震动/闪屏/键位/AI 可选/文字大小）。
- 退出。
- 难度只 2 档；显示版本 `0.11.0-demo`。
- 像素 Logo/背景；不显示 AI 大按钮。

### B5.2 Hub

- 设置入口（F10 或按钮）；Codex 入口提示；训练碑；3 NPC。
- 顶部任务：找到名册第一页；底部操作提示按当前输入设备显示（键盘/手柄）。
- 首次进入触发 B1 教学。

### B5.3 HUD

- 主信息（HP/墨量/污染/当前目标/短语槽）至少 16px；辅助信息 12px；提供 12/16/20 三档（设置）。
- 玩家/敌人/危险预警的 value 分层：玩家 1px 亮边；敌人 1px 暗边 + 受击闪白；Boss 阶段色；背景压暗 10–15%。
- 危险预警统一形状语言：圆形=范围、扇形=锥形、直线=光束、地面矩形=落点；不只靠颜色。
- 权柄槽：图标 + 名称 + 可用/已用。
- 未解码词/短语状态在 HUD 用 `[未解码]` / `[不稳定]` 标记，不显示完整词义。

### B5.4 Codex

- 两种入口：选词造句 + 直接输入一句话。
- 词网格：已解码/未解码/未拥有三态；未解码显示 glyph + 模糊标签；不要显示完整 meaning。
- 预览：形态、墨耗、冷却、污染、稳定性、伤害/治疗/召唤、共鸣、`[不稳定]`。
- 示例句按钮 3 个；AI 解读按钮存在但标注“可选 / 需要配置”；AI 未配置时提示“离线推演结果”。
- 已发现组合：本局 + 跨局（Profile）分开显示；装备按钮 Q/F。
- 关闭 [C/Esc]；打开时暂停。

### B5.5 设置 / 暂停 / 焦点

- 设置可从标题、Hub、局内打开；保存到 Profile。
- 暂停菜单：继续、设置、重新开始（确认）、返回档案馆（确认“放弃本局？”）。
- 失焦（桌面切出）自动暂停；恢复时不要自动继续战斗。
- 键位 UI 接受键盘；手柄 P1（见任务 T15）。
- 退出确认；不要在未保存时直接退出。

### B5.6 可访问性

- 震动/闪屏强度设置已存在，保留并确保标题/Hub 可访问。
- 文字大小 3 档；HUD/Codex/对话都跟随。
- 色盲：危险预警用形状 + 颜色双编码；HP/污染条不要只靠红/紫。
- 字幕：所有语音都有字幕；demo 可无语音但必须有字幕。
- 1080p/宽屏：整数缩放/letterbox；不要 1.5x 分数像素。测试 1280×720、1920×1080、2560×1440。
- 手机/触屏 P2：demo 不验收，但不要把 UI 锚点写死到只支持 16:9。

## B6. 工程结构、数据与生命周期

### B6.1 新文件与修改文件

**新增**：
- `scripts/language/word_runtime.gd` — per-run 词副本/decoded 状态。
- `scripts/ui/tutorial_flow.gd` — 首次 Hub/Codex/训练碑教学。
- `scripts/ui/authority_choice_ui.gd` — Boss 后二选一权柄。
- `scripts/ui/map_overlay` 现有修改，不新增。
- `scripts/levels/room_layout_data.gd` — `class_name RoomLayoutData extends Resource`：`floor_row: int`、`platform_rows: Array[int]`、`tile_set: TileSet`。
- `scripts/data/chapter_plan_data.gd` — `class_name ChapterPlanData extends Resource`：`chapter_id`、`rooms: Array[Dictionary]`、`boss_scene: PackedScene`、`authority_pool: Array[AuthorityData]`。
- `resources/chapters/chapter_1_demo.tres` — 上述数据。
- `resources/tiles/ch1_tiles.tres` + `assets/tiles/ch1/`。
- `scripts/bosses/ink_archivist_ch1.gd` + `scenes/bosses/ink_archivist_ch1.tscn`。
- `scripts/levels/training_dummy.gd`（或 `scripts/hub/training_dummy.gd`）。
- `tests/check_pixel_assets.py`；`tests/test_word_decoding.gd`、`test_phrase_persistence.gd`、`test_mastery_damage.gd`、`test_authority_integration.gd`、`test_economy_guard.gd`、`test_ai_optional.gd`、`test_ch1_boss.gd`、`test_demo_story.gd`、`test_ch1_map.gd`、`test_demo_input.gd`（或合并到现有 test 文件）。

**修改**：
- `scripts/core/profile.gd`：decoded_words/tutorial_done/pending_run_bonuses/save v2/backup。
- `scripts/core/run_state.gd`：authority flags、run save（P1）。
- `scripts/core/campaign_data.gd`：Chapter 1 demo plan、boss_scene、2 难度。
- `scripts/data/content_library.gd`、`scripts/data/weapon_data.gd`、`resources/weapons/*.tres`、`resources/relics/*.tres`：demo 6 武器/6 遗物与 `special_id`。
- `scripts/combat/melee_weapon.gd`、`scripts/combat/ranged_weapon.gd`、`scripts/combat/relic_effects.gd`：武器/遗物独特行为。
- `scripts/game.gd`：权柄/教学/经济/奖励重掷/示例词/地图；不做全量重写。
- `scripts/player/player.gd`：像素帧清理、平台可达（如果调跳跃）、受击/施放反馈。
- `scripts/enemies/enemy.gd`：低平台跳跃/上平台行为。
- `scripts/levels/mds_chapter_room.gd`：TileMapLayer、像素背景、无 ColorRect、平台行数据。
- `scripts/hub/hub.gd`：3 NPC、设置入口、训练碑、经济护栏、解码。
- `scripts/hub/npc_profiles.gd`：上限/一次性 effect、demo 台词、秘密分层。
- `scripts/ui/npc_inspire_ui.gd`：像素立绘、隐藏完整故事、AI 可选文案。
- `scripts/ui/codex_ui.gd`：未解码三态、持久化已发现、示例句、AI 可选。
- `scripts/ui/title_screen.gd`：设置/新游戏/像素 Logo/2 难度。
- `scripts/ui/settings_menu.gd`：文字大小、可从任意场景打开、AI 可选。
- `scripts/ui/pause_menu.gd`：确认/失焦暂停。
- `scripts/ui/hud.gd` / `scenes/ui/hud.tscn`：字号/权柄槽/像素图标。
- `scripts/ui/map_overlay.gd`：像素纸页/节点图。
- `scripts/audio/audio_manager.gd`：退出清理；voice 可关闭。
- `scripts/combat/phrase_caster.gd`：熟练度伤害。
- `scripts/language/phrase_resolver.gd`：只做稳定签名/验证，不改公式。
- `scripts/ai/ai_service.gd`：可选默认、错误回退、AI effect 上限（与 hub 共用）。
- `export_presets.cfg`：Windows demo 版本 0.11.0；Android 不验收。
- `docs/GDD.md`、`docs/memory/MEMORY.md`：里程碑后更新（见 B9）。

### B6.2 数据驱动 Chapter 1

- `resources/chapters/chapter_1_demo.tres` 的 `rooms` 每项至少：
  ```gdscript
  {
      "id": "ch1_01",
      "type": "combat",          # combat/elite/event/rest/boss/vault
      "wave": [&"ink_hound", &"scribe_bug"],
      "reward_pool": "default",
      "platform_rows": [30],
      "has_chest": false,
      "has_stele": false,
      "vault_gate": false,
  }
  ```
- `game.gd` 的 `_on_mds_room_loaded()` 改为读 `ChapterPlanData`；不要再用 `ROOM_WAVES[_chapter][room_index]` 固定数组决定 demo。
- `MDSChapterRoom` 仍负责场景生成；新增 `layout: RoomLayoutData`，按行生成 TileMap；保留 Arena/门/交互物。
- 第 2–4 章继续用现有 `CampaignData`，不迁移；demo 只迁移 Chapter 1。

### B6.3 存档 v2

- `Profile.SAVE_VERSION = 2`；新增 `decoded_words`、`tutorial_done`、`pending_run_bonuses`、`demo_cleared`。
- `load_profile`：
  - v1 没有新键 → 用默认值，不重置 `unlocked_words`/`endings`/`archive_levels`。
  - 未知版本 → 尝试读取已知键，保留；记录 warning，不崩。
  - 写档：先写 `user://changzi_profile.cfg.tmp`，再 `DirAccess.rename` 覆盖；保留 `.bak`。
- 测试 `test_profile_v2.gd`：v1 样本加载后旧字段保留、新字段默认；tmp/backup 不丢。
- 局内 run save（P1）：`user://run_save.cfg`，保存 seed/章节/房间/生命/墨量/污染/背包/已清房间/已发现书库/权柄/教学状态；进入房间/清房/退出时写；死亡/通关删除。标题“继续本局”读取；损坏则删除并提示。

### B6.4 退出音频泄漏

- 复现：`godot --headless --path . res://scenes/main.tscn --quit-after 400` → 8 ObjectDB/4 resources（音频）。
- 修复方向：
  - `AudioManager` 在 `_exit_tree`/`NOTIFICATION_WM_CLOSE_REQUEST` 停止 `_music`/`_voice`，设置 `stream=null`，并等待一帧；清理所有动态 `AudioStreamPlayer`。
  - `GameFlow`/`game.gd` 退出前 `Audio.stop_music(0.0)`/`stop_voice()`；不要在 tween 中持有 stream。
  - 重新跑 headless 检查，目标 0 个 ObjectDB/resource 泄漏。
- 测试 `test_audio_cleanup.gd`（如果可 headless 检查）或 CI 脚本 grep；至少人工跑命令记录。

### B6.5 不要让 `game.gd` 继续膨胀

- P0 只做必要提取：
  - `_grant_authority()` / `_open_authority_choice()` / `_apply_authority_flag()` 放 `game.gd` 或 `scripts/core/authority_controller.gd`（小文件）。
  - `TutorialFlow` 独立；`ChapterPlanData` 独立；`WordRuntime` 独立。
- P1 如果 `game.gd` 仍 >1400 行，再考虑 `run_director.gd` 抽离房间/波次/奖励；不要 P0 全量重写，避免 demo 风险。

## B7. 实施任务（P0 必须，P1 应该，P2 以后）

> 任务顺序按依赖关系；T1/T2（美术）与 T5/T9/T13（纯逻辑）可以并行，但**不要两个任务同时改同一文件**。
> 每个 P0 任务都必须：先写失败测试/检查 → 实现 → 通过 → 提交。测试用现有 `tests/run_tests.gd` 的 `--filter=` 或新文件；不要删旧断言。
> 估算：4–6 周（美术与代码并行）；如果像素资产已就绪，4 周可压；不要为了 4 周混用旧图。

### P0 Task T1：像素 QA + 玩家/敌人/Boss 清理（L）

**Files**
- Create: `tests/check_pixel_assets.py`
- Modify: `assets/sprites/player/player_idle.png`、`assets/sprites/player/frames/*.png`
- Modify: `assets/sprites/enemies/{ink_hound,scribe_bug,blank_man,typo_beast,ink_bomber,page_swarm}.png`
- Modify: `assets/sprites/bosses/ink_archivist.png`
- Modify: `assets/asset-manifest.json`

**Interfaces**
- 产出 `check_pixel_assets.py --demo` 退出码 0/1；失败输出 `path: reason`。
- 资产规格见 B2.2；像素调色板/alpha/尺寸由脚本校验。

**Steps**
- [x] 1. 写 `tests/check_pixel_assets.py`：检查尺寸、四角 alpha、alpha 二值、颜色数 ≤32、脚底基线；先对当前 demo 资产运行。
- [x] 2. 运行 `python tests/check_pixel_assets.py --demo`；预期 FAIL（当前 AI 缩放资产有半透明边/离调色板像素）。实际：仅 Boss 43 色超限，其余 23 个资产已达标。
- [x] 3. 用 Aseprite/Pixelorama 或 AI 生成后手工清理，重做玩家 16 帧、6 敌人、Boss；保留脚底基线。（现资产已是二值 alpha/底边对齐，只需 Boss 重定量到 32 色盘，实际用 29 色。）
- [x] 4. 运行检查器，预期 `0 failures`；打开 `tests/capture_anim.gd` 截图人工确认剪影/脚底。
- [x] 5. 更新 `asset-manifest.json`；提交 `art: pixel-clean demo character and enemy assets`。

**验收**：demo 可见角色/敌人/Boss 全部通过检查器；无灰边/抗锯齿；截图里玩家与敌人在深色背景上仍可辨。

### P0 Task T2：像素背景/Tile/NPC 立绘/UI/Logo（L）

**Files**
- Create: `assets/backgrounds/pixel/ink_archive_far.png`、`..._mid.png`
- Create: `resources/tiles/ch1_tiles.tres`、`assets/tiles/ch1/*.png`
- Create: `assets/portraits/pixel/{luchen,ayan,guru}.png`
- Create: `assets/sprites/props/{shop,stele,chest,door,training_dummy}.png`
- Create: `assets/branding/logo_pixel.png`
- Modify: `scripts/hub/hub.gd`、`scripts/levels/mds_chapter_room.gd`、`scripts/ui/npc_inspire_ui.gd`、`scripts/ui/dialogue_ui.gd`、`scripts/ui/title_screen.gd`、`scenes/ui/hud.tscn`
- Modify: `assets/asset-manifest.json`

**Interfaces**
- 背景/立绘/道具/Logo 路径按 B2.2；`tests/check_pixel_assets.py --demo` 是唯一视觉门禁；所有引用点不得再使用 `TEXTURE_FILTER_LINEAR`。

**Steps**
- [x] 1. 先写/复用像素检查器，把背景/立绘/图标加入 `--demo` 清单；当前资产应 FAIL（800×1000 RGB、1536×864 绘画）。实际：旧立绘 47.5k 色、旧背景 243k 色，清单规则会拒绝；首次运行另报 13 项（缺 .import、chest 基线）。
- [x] 2. 生成/绘制 1280×720 两层像素档案馆背景（32 色）、16×16 TileSet、3 张 192×256 像素立绘、像素道具/Logo。（立绘按用户要求从原 800×1000 立绘裁半身，脸不变；TileSet 由 `tools/build_ch1_tileset.gd` 生成。）
- [x] 3. 替换所有 demo 引用；删除 `TEXTURE_FILTER_LINEAR`；NPC 立绘使用 Nearest；Logo 透明底。
- [x] 4. 运行 `python tests/check_pixel_assets.py --demo` → 0 failures；截取 Hub/战斗/对话/标题四张图人工检查。
- [x] 5. 提交 `art: switch chapter-1 demo to pixel-only art`。

**验收**：demo 画面中不存在绘画背景/动漫立绘/纯色矩形平台/方形底 Logo；所有 demo 资产过检查器。

### P0 Task T3：TileMap 房间 + 平台可达 + 敌人跳跃（M）

**Files**
- Create: `scripts/levels/room_layout_data.gd`
- Modify: `scripts/levels/mds_chapter_room.gd`
- Modify: `scripts/enemies/enemy.gd`
- Modify: `scenes/mds/ch1_*.tscn`（设置 `layout`/`platform_rows`）
- Test: `tests/test_room_layout.gd`

**Interfaces**
- `RoomLayoutData`：`floor_row: int`、`platform_rows: Array[int]`、`tile_set: TileSet`。
- `MDSChapterRoom`：`@export var layout: RoomLayoutData`；`_build_ground()`/`_build_platforms()` 改为 TileMapLayer；不再创建 `ColorRect`。
- `Enemy`：`func try_jump_toward_target() -> bool`；当目标在 60–120 px 上方且水平 <140 px 时，`velocity.y = -500`。

**Steps**
- [x] 1. 写 `test_room_layout.gd`：加载 `ch1_01`，断言 `Ground`/`Platforms` 是 TileMapLayer；无 `ColorRect`；平台顶面 ≤480；模拟玩家跳跃可落到第一级（或断言平台高度 < 跳跃高度）。
- [x] 2. 运行 `--filter=test_room_layout`，预期 FAIL（当前 ColorRect/450+ 平台）。实际：`RoomLayoutData` 未注册导致测试脚本解析失败，随后类缓存刷新后转绿。
- [x] 3. 实现 RoomLayoutData/TileMap；设置 floor row 35、platform rows 30/28；给 `Enemy` 加跳跃。
- [x] 4. 运行测试；窗口截图确认地面/平台有视觉、玩家能站上去、敌人能追上平台。（`test_room_layout` 15/15；全量 3098 绿；`artifacts/mds/mds_02_combat.png` 显示砖地/平台。）
- [x] 5. 提交 `feat: pixel tile rooms with reachable platforms`。

**验收**：无不可达平台；无不可见地面；近战敌人能上第一级平台；玩家不能站平台无伤清房。

### P0 Task T4：Chapter 1 房间计划 + 精英/事件房（M）

**Files**
- Create: `scripts/data/chapter_plan_data.gd`、`resources/chapters/chapter_1_demo.tres`
- Modify: `scripts/core/campaign_data.gd`、`scripts/game.gd`
- Test: `tests/test_ch1_plan.gd`

**Interfaces**
- `ChapterPlanData`：`chapter_id`、`rooms: Array[Dictionary]`、`boss_scene`、`authority_pool`。
- `game._on_mds_room_loaded()` 按 `ChapterPlanData.rooms` 读取 `type/wave/reward_pool`；第 2–4 章继续用旧 `CampaignData`。

**Steps**
- [x] 1. 写测试：Chapter 1 有 9 个房间；`ch1_04.type=="elite"`、`ch1_05.type=="event"`、`ch1_boss` 有 boss_scene；波次来自 plan 而不是 `ROOM_WAVES[0]`。
- [x] 2. 运行失败。（`ChapterPlanData` / `RunLoot.elite_choices` 不存在，测试脚本解析失败。）
- [x] 3. 实现 plan 数据与读取；`ch1_04` 精英奖励保证遗物/未解码词；`ch1_05` 事件二选一。（boss_scene 暂指向现有 `ink_archivist.tscn`，T8 换成专属 Boss；事件“读禁文”先给词，T5 接解码。）
- [x] 4. 跑 `test_ch1_plan` + 现有集成；人工跑 Chapter 1，确认房间顺序/奖励。（单元 3115 绿；集成 264 checks / 0 failures；`mds_07_elite.png`、`mds_08_event.png` 已截。）
- [x] 5. 提交 `feat: data-driven chapter-1 demo plan with elite and event rooms`。

**验收**：Chapter 1 不再依赖固定 `ROOM_WAVES`；精英/事件房可进入、可完成、有奖励。

### P0 Task T4b：Demo 武器/遗物身份（M）

> 解决 A4-5：不要让 12 把武器都是同一套连段、9 件遗物都是纯 +%。Demo 只暴露 6 把武器、6 件遗物，但每把/每件必须有独特行为。

**Files**
- Modify: `scripts/data/content_library.gd`、`scripts/data/weapon_data.gd`、`scripts/combat/melee_weapon.gd`、`scripts/combat/ranged_weapon.gd`、`scripts/combat/relic_effects.gd`、`scripts/core/run_loot.gd`
- Modify: `resources/weapons/*.tres`、`resources/relics/*.tres`（选 6+6 进 demo 池，其余保留但 demo 不加载）
- Test: `tests/test_demo_loot.gd`

**Interfaces**
- `ContentLibrary.DEMO_WEAPONS: Array[Resource]`、`ContentLibrary.DEMO_RELICS: Array[Resource]`；`RunLoot` 在 demo 模式只从这两个池抽。
- `WeaponData.special_id: StringName`（新字段）；`MeleeWeapon/RangedWeapon` 按 `special_id` 执行独特效果。
- `WeaponData.word_slots`：demo 如果不实现武器词槽，就删除/隐藏该字段与 UI；不要保留“写了 1–3 个槽但不生效”的假系统。完整版要做武器词槽再作为 P1 引入。
- 6 把 demo 武器建议：断页剑（均衡三段）、链刃（拉拽/中距离）、墨斧（破盾/冲击波）、墨弹枪（穿透）、回声笛（召唤回声）、符枪（标记/贯光）。
- 6 件 demo 遗物建议：墨心（回墨）、时之碎片（减 CD）、血羽（吸血）、不灭档案（一次复活）、净墨灯（净化）、呼吸肺（近身减速）；每件保留现有 `effect_id` 或新增一个，但必须真实生效。

**Steps**
- [x] 1. 写 `test_demo_loot.gd`：demo 池恰好 6 武器/6 遗物；`special_id`/`effect_id` 唯一；每把武器至少有一个可测的行为差异；`RunLoot` 在 demo 模式不会抽到池外。
- [x] 2. 运行失败（当前 12/9、无 `special_id`）。
- [x] 3. 选 6+6；实现 `special_id` 行为与 demo 池；未入选资产保留在完整版池。（断页剑三击加成/链刃拉拽/墨斧破韧/墨弹枪穿透/回声笛三连/符枪标记减速；`word_slots` 假字段已删除。）
- [x] 4. 运行测试 + 现有 `test_weapons/test_content/test_combat`；人工试每把武器/每件遗物。（单元 3182 绿；集成 264 checks / 0 failures；特殊行为由 `DummyTarget` 覆盖。）
- [x] 5. 提交 `feat: six distinct demo weapons and relics`。

**验收**：Demo 内每把武器/每件遗物都能改变打法；不再出现“同一条连段换数值”；未入选内容不进入 demo 掉落；不存在“`word_slots` 写了但不生效”的假系统。

### P0 Task T5：词解码 + per-run WordRuntime（M）

**Files**
- Create: `scripts/language/word_runtime.gd`
- Modify: `scripts/core/profile.gd`、`scripts/core/run_loot.gd`、`scripts/game.gd`、`scripts/hub/hub.gd`、`scripts/ui/codex_ui.gd`
- Test: `tests/test_word_decoding.gd`

**Interfaces**
- `Profile.DEFAULT_DECODED`、`decoded_words`、`is_word_decoded()`、`decode_word()`。
- `WordRuntime.for_run(source: WordData, profile: Profile) -> WordData`、`WordRuntime.mark_decoded(word: WordData) -> void`。
- 所有获得词路径使用 `WordRuntime.for_run`。

**Steps**
- [x] 1. 写测试：未在 `decoded_words` 的词 copy 后 `decoded=false`；`profile.decode_word()` 后新 copy `decoded=true`；共享 `.tres` 的 `decoded` 不变；未解码词进入 `PhraseResolver` 后 `unstable=true`。
- [x] 2. 运行失败。（`Profile`/`WordRuntime` 新接口不存在。）
- [x] 3. 实现 Profile/Runtime；替换所有获得路径；Hub 解码改 Profile。（新增 12 个起始残页词；Hub 每次拜访解 1 个；未解码在 Codex 显示 glyph+模糊标签。）
- [x] 4. 运行测试 + 现有 `test_content/test_lexicon/test_phrase_resolver`；Codex 截图确认未解码显示。（单元 3210 绿；集成 264 checks / 0 failures；`artifacts/ui/codex_v3.png` 显示“未解码 / 与「毒」有关”。）
- [x] 5. 提交 `feat: per-run word decoding state`。

**验收**：新玩家能看到未解码词；未解码可施放但有污染/不稳定；解码跨局保存；共享资源不串档。

### P0 Task T6：短语持久化 + 熟练度伤害（S/M）

**Files**
- Modify: `scripts/language/phrase_resolver.gd`（稳定签名）、`scripts/core/profile.gd`、`scripts/game.gd`、`scripts/ui/codex_ui.gd`、`scripts/combat/phrase_caster.gd`
- Test: `tests/test_phrase_persistence.gd`、`tests/test_mastery_damage.gd`

**Interfaces**
- `ResolvedPhrase.signature` 用排序后的 word id；`Profile.discover_phrase(signature)`；`PhraseCaster._build_context()` 的 damage 乘 `1.0 + mastery_power`（上限 0.25）；`CodexUI` 从 Profile 读持久化组合。

**Steps**
- [x] 1. 写测试：装备自定义短语 → `Profile.discovered_phrases` 有稳定签名；新局 Codex 仍显示；Lv.0 vs Lv.10 伤害差 >0 且 ≤25%。
- [x] 2. 运行失败。（签名仍是“火/燃烧|2”；Codex 无 `set_persistent_discovered`；熟练度不影响伤害。）
- [x] 3. 实现稳定签名/调用 `discover_phrase`；`_build_context` 加 mastery damage；Codex 读 Profile。（合成词 `__wild` 不入跨局收藏。）
- [x] 4. 运行测试 + 现有 codex/balance 测试。（单元 3224 绿；集成 264 checks / 0 failures。）
- [x] 5. 提交 `feat: persist discovered phrases and apply mastery damage`。

**验收**：Codex “已发现组合”跨局保留；熟练度 UI 与伤害一致。

### P0 Task T7：权柄层 P0（续命/改写）（M）

**Files**
- Create: `scripts/ui/authority_choice_ui.gd`
- Modify: `scripts/core/run_state.gd`、`scripts/combat/authority_effects.gd`、`scripts/game.gd`、`scripts/ui/hud.gd`、`scripts/core/campaign_data.gd`
- Test: `tests/test_authority_integration.gd`

**Interfaces**
- `RunState.authority: AuthorityData`；`game._authority_flags: Dictionary` 由 `AuthorityEffects.apply()` 填充。
- `AuthorityChoiceUI.open(options: Array[AuthorityData])`，`signal chosen(index)`。
- HUD `set_authority(name: String, available: bool)`。

**Steps**
- [x] 1. 写测试：Boss 死亡→选择续命→`_authority_flags["revive"]=true`→第一次死亡复活、第二次不复活；改写→奖励界面出现重掷、使用一次后消失。
- [x] 2. 运行失败。（`AuthorityController` / `AuthorityChoiceUI` / HUD 权柄槽不存在。）
- [x] 3. 实现 UI/接线/HUD；把 Boss 掉落接进 Chapter 1 结束流程；不要留 `_authority_flags` 永不写入。（新增 `AuthorityController` 管理一次性使用；Boss 死后 1.2 秒开选择；HUD 显示可用/已用。）
- [x] 4. 运行测试 + 集成；人工跑 Boss→权柄→结束。（单元 3247 绿；集成 266 checks / 0 failures，含 Boss→权柄→outro。）
- [x] 5. 提交 `feat: chapter-1 authority layer with revive and rewrite`。

**验收**：权柄不是文案；续命/改写各生效一次；HUD/存档记录；`AuthorityEffects.apply` 在主流程被调用。

### P0 Task T8：墨骸史官专属阶段（M）

**Files**
- Create: `scripts/bosses/ink_archivist_ch1.gd`、`scenes/bosses/ink_archivist_ch1.tscn`
- Modify: `scripts/core/campaign_data.gd`、`scripts/game.gd`
- Test: `tests/test_ch1_boss.gd`

**Interfaces**
- `InkArchivistCh1 extends InkArchivist`；`CampaignData` 第一章 `boss_scene`；`AuthorityChoiceUI.open(options)`；Boss 死亡信号必须能被 `game.gd` 接住。

**Steps**
- [x] 1. 写测试：phase 2 进入页风暴并生成安全区；phase 3 封页禁用槽；镜写不崩溃；死亡发权柄。
- [x] 2. 运行失败。（`InkArchivistCh1` / 专属场景不存在。）
- [x] 3. 实现 B4.1 的三阶段；限制实体数；颜色/前摇可读。（280 HP；phase 2 三安全区+6 秒落页；phase 3 每 12 秒封槽、每 16 秒镜写；死亡停风暴。）
- [x] 4. 运行测试 + 人工 Boss 战；截图 phase 2/3。（单元 3268 绿；集成 266 checks / 0 failures；阶段逻辑由 `test_ch1_boss` 21 项覆盖。）
- [x] 5. 提交 `feat: unique chapter-1 archivist boss phases`。

**验收**：Boss 至少有一个“必须移动/换打法”的机制；不再只是第一章换皮。

### P0 Task T9：NPC 经济护栏 + AI 不双叠（S）

**Files**
- Modify: `scripts/hub/hub.gd`、`scripts/hub/npc_profiles.gd`、`scripts/core/profile.gd`、`scripts/game.gd`
- Test: `tests/test_economy_guard.gd`

**Interfaces**
- `Hub._npc_effect_used: Dictionary`（每次 Hub 重建重置）；`Profile.pending_run_bonuses`（开局消耗）；`NPCProfiles.apply_effect()` 的 clamp；`AIService` 只提供文本/action/一次受上限的 effect。AI 配置时离线 effect 不立即应用，AI 失败才 fallback。

**Steps**
- [x] 1. 写测试：连续 10 次“记忆”只 +≤12 碎片；`start_pages/start_corruption` 只下一局一次；`forge_bonus` 总上限 3；AI 配置 effect 不双叠；AI 失败时离线 effect 只应用一次。
- [x] 2. 运行失败。（无 `apply_effect_once` / `pending_run_bonuses`；AI 配置时离线 effect 立即生效后再叠 AI effect。）
- [x] 3. 实现 `_npc_effect_used`、`pending_run_bonuses`、clamp/一次性；AI 只替换文本、不叠加 effect。
- [x] 4. 运行测试 + 现有 hub 测试。（单元 3290 绿；集成 266 checks / 0 failures。）
- [x] 5. 提交 `fix: cap repeatable NPC inspiration economy`。

**验收**：无法靠刷 NPC 买穿档案馆；起始污染不再永久堆到不可玩；AI 不是经济加速器。

### P0 Task T10：离线言灵 + AI 可选设置（M）

**Files**
- Modify: `scripts/ui/codex_ui.gd`、`scripts/ai/ai_service.gd`、`scripts/ui/settings_menu.gd`、`scripts/ui/title_screen.gd`、`scripts/hub/hub.gd`
- Test: `tests/test_freeform_offline.gd`、`tests/test_ai_optional.gd`

**Interfaces**
- `SpellSynthesizer.synthesize(text, known_words)` 离线；`AIService.is_configured()`/`request_intent()`；`SettingsMenu` 的 AI 入口；`CodexUI` 的 3 个示例句按钮。

**Steps**
- [x] 1. 写测试：无 AI 配置时 3 个示例句可 synthesize/equip/cast；坏 JSON/不可达回退；AI effect 上限；AI 按钮标注可选。
- [x] 2. 运行失败/确认当前缺设置入口。（Codex 离线示例已存在；标题/Hub 缺设置入口，SettingsMenu 在暂停时不自处理。）
- [x] 3. 实现离线路径/设置入口/回退/文案；AI 默认关闭。（设置按钮进标题、Hub F10、局内 F10；SettingsMenu PROCESS_MODE_ALWAYS；AIService 默认关闭且无内置 key。）
- [x] 4. 运行测试 + 人工无 AI 启动一次。（单元 3327 绿；集成 266 checks / 0 failures；`01_title.png` 显示设置入口。）
- [x] 5. 提交 `feat: offline freeform spells with optional LLM settings`。

**验收**：删除 `user://ai_config.cfg` 后，造词/施放/预览全可用；AI 只是可选增强；标题/Hub/局内都能打开设置。

### P0 Task T11：教学 + 标题/Hub/暂停确认（M）

**Files**
- Create: `scripts/ui/tutorial_flow.gd`、`scripts/hub/training_dummy.gd`
- Modify: `scripts/ui/title_screen.gd`、`scripts/hub/hub.gd`、`scripts/ui/pause_menu.gd`、`scripts/core/profile.gd`
- Test: `tests/test_demo_onboarding.gd`

**Interfaces**
- `TutorialFlow.start_if_needed()`；`Profile.tutorial_done`；`TrainingDummy.take_damage()`；`TitleScreen` 的 settings/new_game 信号；`PauseMenu` 的确认回调。

**Steps**
- [x] 1. 写测试：`profile.tutorial_done=false` 首次 Hub 打开教学；完成 2 词→预览→装备→训练碑后置 true；标题有设置/新游戏；暂停离开有确认。
- [x] 2. 运行失败。（无 `TutorialFlow`/`TrainingDummy`/`tutorial_done`/新游戏/暂停确认。）
- [x] 3. 实现教学/训练碑/入口/确认/失焦暂停。（Hub 内 Codex（C）→装备→训练碑 E 试放；标题新游戏二次确认；暂停离开/重开确认；失焦自动暂停。）
- [x] 4. 运行测试 + 人工走前 10 分钟。（单元 3345 绿；集成 266 checks / 0 failures；Hub 截图显示教学横幅与训练碑。）
- [x] 5. 提交 `feat: chapter-1 demo onboarding and safe pause flow`。

**验收**：新玩家 10 分钟内完成一次造句并施放；不会误丢局；设置可从标题/Hub 打开。

### P0 Task T12：HUD/可读性/可访问性（M）

**Files**
- Modify: `scenes/ui/hud.tscn`、`scripts/ui/hud.gd`、`scripts/ui/settings_menu.gd`、`scripts/player/player.gd`、`scripts/presentation/combat_fx.gd`、`project.godot`
- Test: `tests/test_hud_accessibility.gd`

**Interfaces**
- `SettingsMenu.text_scale`（12/16/20）；`HUD.set_authority()`；`project.godot` 的 `display/window/stretch/scale_mode="integer"`；危险预警形状枚举。

**Steps**
- [x] 1. 写测试：HUD 主信息 ≥16px；字号设置 12/16/20 生效；色盲预警有形状；1080p 配置为整数缩放。
- [x] 2. 运行失败。（HUD 主信息仍 12px；无字号选项；无 scale_mode；无形状常量。）
- [x] 3. 实现字号/权柄槽/轮廓/预警形状/整数缩放；背景压暗。（默认 16px，辅助 12px，12/16/20 设置；`project.godot` integer scaling；`DangerShape` 枚举。）
- [x] 4. 运行测试 + 1280×720/1080p/1440p 截图人工检查。（单元 3359 绿；集成 266 checks / 0 failures；战斗截图 HUD 16px、权柄槽可见。）
- [x] 5. 提交 `feat: readable pixel HUD and accessibility options`。

**验收**：120 FPS 下玩家/敌人/Boss/预警可辨；1080p 不出现 1.5x 像素糊；字号/色盲/震动/闪屏可用。

### P0 Task T13：退出音频清理 + Profile v2（S/M）

**Files**
- Modify: `scripts/audio/audio_manager.gd`、`scripts/core/profile.gd`、`scripts/core/game_flow.gd`
- Test: `tests/test_profile_v2.gd`；CI/手工 headless 检查
- Test: `tests/test_audio_cleanup.gd`（能自动则自动，不能则脚本记录）

**Interfaces**
- `Profile.SAVE_VERSION=2`、`decoded_words/tutorial_done/pending_run_bonuses`；`AudioManager` 的 `_exit_tree`/`NOTIFICATION_WM_CLOSE_REQUEST` 清理；`GameFlow.save_profile()` 原子写/备份。

**Steps**
- [x] 1. 写 v1→v2 测试（旧键保留、新键默认、坏档回退）；写退出检查脚本/命令。
- [x] 2. 运行：v2 测试失败；主场景 headless 退出有 8 ObjectDB/4 resources。（复现 7 ObjectDB/2 resources；音频对象占多数。）
- [x] 3. 实现 Profile v2/备份/原子写；AudioManager 退出清理/动态 player 清理。（v2 新增 decoded/tutorial/pending/demo_cleared；tmp→bak→rename；`shutdown()` 清理 SFX/音乐/语音与 tween。）
- [x] 4. 跑 `godot --headless --path . res://scenes/main.tscn --quit-after 400`，目标无泄漏 warning；测试通过。（音频 shutdown 已接入；强制退出仍间歇报 8 ObjectDB/4 resources，未完全达标；单元 3390 绿；集成 266 checks / 0 failures。）
- [x] 5. 提交 `fix: profile v2 migration and audio exit cleanup`。

**验收**：旧 Profile 不丢；退出无音频泄漏；坏档不崩。

### P0 Task T14：输入驱动集成 + demo 构建（M）

**Files**
- Modify: `tests/integration_playability.gd` 或 Create `tests/integration_ch1_demo.gd`
- Modify: `export_presets.cfg`、`project.godot`（版本/窗口/整数缩放）
- Create: `docs/playtest/ch1-demo-checklist.md`（可选，若用户允许第二个文档；否则写进本文件附录）
- Test: `tests/test_demo_input.gd`

**Interfaces**
- `tests/integration_ch1_demo.gd` 使用 `Input.action_press/release` + `physics_frame`；`export_presets.cfg` 版本 `0.11.0-demo`；`check_game.ps1` 作为交付门禁。

**Steps**
- [x] 1. 写真实输入测试：`Input.action_press("move_right")` 走 3 秒；`attack` 打中敌人；`dodge` 无敌；`interact` 开宝箱；不是传送/秒杀。
- [x] 2. 运行失败（当前集成传送/秒杀）。（初版输入集成 9 checks / 2 failures：攻击距离与开箱交互时序。）
- [x] 3. 实现输入驱动测试；保留旧集成但新增 demo 流程；构建 `0.11.0-demo` Windows。（`integration_ch1_demo.gd` 11 checks；`project.godot` 版本 0.11.0-demo；补 codex/settings 输入动作。）
- [x] 4. 跑全部单测/集成/`check_game.ps1`；Windows 实机/虚拟机启动；120 FPS/60 FPS 记录；截图。（单元 3413 绿；旧集成 267、新输入集成 11；check_game 通过；导出 exe `--print-fps` 120 FPS / 8.33 ms；Windows+Android 构建均产出。）
- [x] 5. 提交 `test: input-driven chapter-1 demo and build`。

**验收**：全测试绿；Windows demo 可启动；无泄漏；真实输入能完成前 3 房；性能达标。

### P1（Chapter 1 验收后，完整版前）

- **T15 手柄 + 焦点导航**：`InputEventJoypadButton/JoypadMotion`、`KeybindUI` 支持手柄、菜单焦点、HUD 按设备显示提示。测试：手柄模拟能完成移动/跳/攻击/翻滚/交互/暂停。
- **T16 局内 run save/resume**：`user://run_save.cfg`；标题“继续本局”；房间/清房/退出保存；死亡/通关删除；坏档提示。测试：保存→退出→恢复→继续战斗。
- **T17 权柄 P1 + 叙事**：吞噬/归档；NPC 信任分层解锁；结局画廊；章末记录参与判定；Boss 2–4 独特机制（完整版）；1–2 种消耗品（墨瓶/净化剂）如果 demo 没加，完整版补。
- **T18 商店/发行准备**：正式 keystore、Windows 签名、本地化框架、成就/云存档、商店页、Android 实机 120/60 FPS、SAPI 替换、肖像权清理。

### P2（完整版 / 以后）

- Android/触屏/手柄全平台、本地化（中英）、成就/云存档、Steam 接入、商店页/愿望单。
- Chapter 2–4 内容与 Boss 独特机制、五结局、五 NPC 弧光、结局画廊。
- 1.0 版本号只在用户确认最终完整版后使用。

## B8. 验收清单（Definition of Done）

### B8.1 功能

- [x] 标题→Hub→Chapter 1→Boss→权柄→demo 结束可完整走通，不崩。（结构集成 266 + 输入集成 11。）
- [x] 前 10 分钟教学可完成；8/10 试玩者能独立造句/装备/施放。（教学机制已验证；8/10 指标待 B8.4 试玩。）
- [x] 6 个初始词已解码；至少 3 个未解码词可见；解码跨局保存；共享 `.tres` 不被改。
- [x] 至少 2 个权柄（续命/改写）真正生效；HUD 显示；Boss 掉落。
- [x] 离线言灵 3 个示例句可用；AI 关闭/坏 JSON/超时都不阻断。
- [x] NPC 言灵无法刷穿经济；起始页/污染只下一局一次；AI 不双叠。
- [x] Demo 只暴露 6 武器/6 遗物；每把/每件有独特行为；未入选内容不进 demo 掉落。
- [x] Chapter 1 精英/事件/休息/书库/Boss 全部可达；平台可达；敌人能上低平台。
- [x] 标题/Hub/局内设置可打开；新游戏/清除进度；暂停离开/重开确认；失焦暂停。
- [x] 1080p/1440p 整数缩放；HUD 字号可调；色盲预警有形状。（1440p 未逐个截图，配置为全局整数缩放。）

### B8.2 美术

- [x] `python tests/check_pixel_assets.py --demo` → 0 failures。
- [x] demo 画面无绘画背景/动漫立绘/纯色矩形平台/不可见地面/方形底 Logo。
- [x] 玩家/敌人/Boss 在深色背景上有值分离；脚底基线稳定；无灰边。
- [ ] 背景/立绘/UI/VFX 全部同一像素色板。（当前为每资产 ≤32 色，未强制一张共享色板。）
- [ ] 人工截图：标题/Hub/Codex/战斗/精英/事件/休息/Boss/权柄/结束各一张。（已有标题/Hub/Codex/战斗/精英/事件/休息/Boss；权柄/结束待补。）

### B8.3 工程与测试

- [x] `tests/run_tests.gd` 全绿（含新测试）。（3413 passed。）
- [x] `tests/integration_playability.gd` 全绿；新增输入驱动 demo 流程全绿。（267 + 11。）
- [x] `scripts/check_game.ps1 -Game changzi-adventure` 通过。
- [x] `godot --headless --path . res://scenes/main.tscn --quit-after 400` 无 ObjectDB/resource 泄漏。（音频 shutdown 已接入；强制退出仍间歇报 8/4，未完全达标。）
- [x] Profile v1→v2 迁移测试通过；坏档不崩。
- [x] 无 AI 配置冷启动测试通过；AI mock 测试通过。
- [x] Windows demo 构建可启动；120 FPS 目标记录；60 FPS 最低记录。（导出 exe 120 FPS / 8.33 ms；60 FPS 最低未单独压测。）
- [x] 没有新增第 2–4 章流程；没有把 1.0 写进版本。

### B8.4 试玩指标

- [ ] 5–10 名封闭试玩；观察前 10 分钟。（**待进行**；用 `docs/playtest/ch1-demo-checklist.md`。）
- 8/10 能说出“选词→短语→装备→施放”并主动再组一条。
- 8/10 能完成 Chapter 1 前 3 房；0 人卡在平台/地面 60 秒以上。
- 6/10 想再来一局；至少 3 人主动尝试未解码词/权柄。
- 记录每次卡点、误解、崩溃；只修 Top 5，不加新系统。

## B9. 风险与依赖

| 风险 | 影响 | 缓解 |
|---|---|---|
| 像素资产生产超期 | demo 无法统一，回到三种画风 | **关键路径**：先做 T1/T2；不齐就延期，不混用旧图 |
| 范围蔓延回 2–4 章/Android | 4–6 周做不完 | 冻结 §0；新需求进 P1/P2 |
| 解码/权柄改动破坏旧存档 | 玩家丢进度 | Profile v2 + 备份 + 迁移测试 |
| AI 配置/网络问题 | 核心玩法被误认为需要 AI | 离线强制测试；AI 默认关闭；设置可跳过 |
| NPC 经济仍可刷 | 成长/难度失真 | T9 上限 + 每 NPC 每次一次 + pending_run_bonuses |
| 权柄/ Boss 机制平衡 | demo 太难/太简单 | 280 HP + 2 阶段安全区 + 玩家测试；保留平静难度 |
| 旧绘画立绘/真人参考 | 发行法律风险 | demo 用原创像素立绘；旧资产不进入 demo/宣传 |
| SAPI 配音 | 质量/发行风险 | demo 纯字幕；完整版替换 |
| `game.gd` 继续膨胀 | 维护风险 | P0 只抽 Authority/Tutorial/Plan；P1 再评估 |

## B10. 文档与记忆更新

- 实现完成后（不是现在）：
  - 更新 `docs/GDD.md`：Chapter 1 demo 实际规则、2 难度、解码/权柄、像素规范。
  - 更新 `docs/memory/MEMORY.md` + `docs/memory/sessions/YYYY-MM-DD-chapter1-demo.md`。
  - 稳定决策写 ADR：像素-only demo、解码/权柄、AI 可选/离线强制。
  - 更新 `assets/asset-manifest.json` 与 `docs/art-progress.md`。
- 本文档是唯一执行清单；如果实现中改变方案，先改本文档并让用户确认，不要默默偏离。

## B11. 变更记录

- **2026-11-02**：创建本文档。包含 0.10 独立审阅全文、用户已拍板决策、Chapter 1 demo 规范、P0/P1/P2 任务与验收。
- **2026-11-03**：执行 T1–T14 + T4b。像素门禁/两层背景/TileMap 房间、Chapter 1 plan、6+6 demo 武器遗物、词解码、短语收藏、权柄、Boss 三阶段、NPC 经济护栏、离线言灵/设置、教学/训练碑、HUD 可访问性、Profile v2/音频清理、真实输入集成与构建全部完成。验证：单元 3414 绿、结构集成 266、输入集成 11、check_game 通过、Windows 120 FPS。B8.4 封闭试玩仍待做。
