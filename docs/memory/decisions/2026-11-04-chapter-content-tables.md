# ADR：章节内容按章节查表（事件 / 权柄池 / Boss 文案）

- 日期：2026-11-04（第 32 程）
- 状态：已采纳，第 1 章保持原数据与原行为，第 2 章仍不可达
- 相关：[第 2 章计划与大区图](2026-11-04-chapter2-big-map-graph.md)、[平衡、成长与 AI 权限](2026-11-02-balance-authority.md)、[宇宙史官叙事（剧情圣经）](../../story-bible.md)

## 背景

第 1 章 demo 把事件文案、Boss 入场/阶段文案和权柄授予都写死在「第 1 章」
分支里：`game.gd` 直接读 `Ch1EventData`，`_grant_chapter_authority` 对非第 1
章直接返回，`BossEntranceData`/`BossPhaseData` 只有第 1 章表。第 2 章大区
世界与计划已经落地，继续按第 1 章写死会让第 2 章事件/Boss/权柄无处挂载，
或错误回落到第 1 章文案。监工任务单要求本步只做数据与路由泛化：不开放第 2
章可达性、不实现 Boss 2 独特机制、不新增事件效果系统。

## 决定

1. **事件数据按章节分模块**：每个有事件内容的章节一个 `*EventData`
   （`Ch1EventData` / `Ch2EventData` / `Ch3EventData`），暴露同名 `variants()` / `pick()` 与
   同名常量（污染成本、残页奖励、兜底残页）。`game.gd` 用
   `_event_data(room_id)` 一张按章节查的表取「文案 + 数值」；第 1 章仍用原键
   （房间 id）与原数值，第 2 章用计划事件节点 id（`ch2_event/event`）。
2. **事件选项的效果类型冻结**：只允许「污染 + 解明残页词 / 兜底残页」与
   「残页奖励」两类既有结算。新章节只写文案，不新增效果钩子。
3. **变体选择不消耗 run RNG**：`hash(run_seed:节点 id)` 固定轮换，保证续玩
   或重新进区不改变文案、不移动掉落序列。
4. **权柄池属于章节计划**：`ChapterPlanData.authority_pool` 只列基础项；
   条件追加项统一由 `AuthorityController.build_pool` 从 `ContentLibrary`
   按既有 `unlock_condition`（corruption / records / profile_records）追加。
   第 2 章基础池与第 1 章相同（续命/改写），不发明新效果。
5. **Boss 文案按章节 + 阶段查表**：`BossEntranceData.variants(chapter)`、
   `BossPhaseData.variants(phase, chapter)`；没有表的章节返回空（静默），
   不再回落到第 1 章。第 1 章保留原选句键，避免现有 run 的句子漂移。
6. **未完成章节的自动触发保持关闭**：第 2 章事件页在 `game.gd` 里只有数据
   路由，没有自动触发点；由集成测试显式驱动验证。等第 2 章可达时再加真实
   触发（`ch2_event` 区需要一个主 Arena 或独立事件触发器）。
   - 2026-11-04 第 34 程更新：已按区域级触发接上第 2 章事件区，见
     [第 2 章事件区触发](2026-11-04-chapter2-event-trigger.md)；本条其余
     口径（章节仍不可达、事件键按节点 id、效果不扩展）不变。

## 后果

- 增加一章内容 = 加一个事件数据模块、在计划里写 `authority_pool`/事件节点、
  在 Boss 表里加一组文案；`game.gd` 不再按章号写死文案或授予条件。
- 第 1 章的事件文案、数值、章末流程、Boss 选句与权柄授予行为保持不变；
  第 3 章已于第 42 程按本 ADR 补数据模块、计划基础权柄池与 Boss 文案。
  - 2026-11-05 第 53 程更新：第 4 章也按本 ADR 补了 `Ch4EventData`、
    计划基础权柄池与 Boss 入场/阶段文案；四章数据模块齐全，但第 3/4 章
    计划仍未路由、仍不可达（第 4 章 `content_pending` 仍推迟波次表）。
- 事件效果仍是固定两类，扩展效果需要另写机制 ADR，不能塞进文案表。
- 第 2 章计划区域还没有 `wave` 键，大区 Arena 暂不生成敌人；波次接线是
  后续内容步骤，不在本 ADR 范围内。
