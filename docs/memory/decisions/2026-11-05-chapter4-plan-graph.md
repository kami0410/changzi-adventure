# ADR：第 4 章计划与图骨架（数据层）

- 日期：2026-11-05（第 51 程）
- 状态：已采纳；仅数据层与测试夹具，未接入 `game.gd`，第 4 章仍不可达
- 相关：[第 4 章大地图可行性核查](../../../SUPERVISOR_STATUS.md)、
  [第 2 章计划与大区连通图](2026-11-04-chapter2-big-map-graph.md)、
  [第 3 章计划与图骨架](2026-11-05-chapter3-plan-graph.md)、
  [第 2–4 章房间生产管线](2026-11-04-big-room-pipeline.md)

## 背景

第 50 程核查确认：第 2/3 章走通的大区连通图路线可直接承载第 4 章，缺口集中在
内容层。按核查 D 节顺序，第 1 步是计划与图骨架。本程沿用第 30/40 程做法，
为第 4 章立一个可校验的计划与图骨架，为后续真实大区世界打地基。
首次尝试（brief53 / session53）因 Magpie 网关中断夭折；本程为接力重试，从零执行。

## 决定

1. **第 4 章计划 = 9 区连通图**（`resources/chapters/chapter_4_demo.tres`），
   与第 2/3 章同构：入口 → 两条可回环支路 → 枢纽 → 纵井 → 事件/精英 → Boss，
   隐藏书库挂在支路下。
   - 区：`ch4_entry`、`ch4_branch_a`、`ch4_branch_b`、`ch4_hub`、`ch4_well`、
     `ch4_vault`、`ch4_event`、`ch4_elite`、`ch4_boss`。
   - 尺寸沿用整屏口径：2560×1440、2560×2160（纵井）、3840×2160（精英/Boss）；
     每区 `fall_below_bounds = 240`。
   - 11 扇门 = 9 双向 + 2 显式单向（`elite_boss` 进 Boss 不可返回、
     `hub_shortcut_entry` 捷径单向）。图内有两个回环，Boss 是末端。
2. **遭遇按旧第 4 章 6 波派生，但本程不写波次**：6 个战斗遭遇
   （支路 A 2、支路 B 1、纵井 2、精英 1）正好按计划顺序对应 `ROOM_WAVES[3]`
   六波；事件区再加 1 个占位遭遇，`clear_target()` 派生为 **7**。第 1 章仍 6、
   第 2/3 章仍 7，既有章节的派生结果未改动。
3. **`content_pending = true`**：计划结构先于内容落地；`validate()` 仍校验区域、
   节点 id 与门图，只跳过 `validate_waves()`。内容程接完波次后按第 43 程约定
   清零；测试把同一计划关掉标志后必须报六条缺波次。
4. **Boss 门取舍**：旧线性世界 `ch4_boss/left1` 可返回 `ch4_rest`；大图计划按
   第 2/3 章先例把 Boss 门做成显式单向。旧世界原样保留，两种行为分别由测试锁定，
   差异写入门与 Boss 区注释。**没有**改 `_complete_chapter`（第 4 章是最后一章，
   章末已走 `_finish(true)`；第 3 章停章替身须在可达性拍板后解开）。
5. **占位必须显式标注，不编造内容**：
   - 事件区只有节点 id `ch4_event/event`，无文案/效果，注释指向后续 `Ch4EventData`；
   - Boss 区只有类型与末端门，不写 `boss_scene`、不改旧
     `boss_script == "smiling"` 分支、不写入场/阶段文案与机制；
   - 捷径门 `hub_shortcut_entry` 写 `requires: ["ch4_shortcut"]` 并注释
     「授予来源待拍板（第 50 程专节 E）」，因此默认不可通行；`game.gd` 不含
     `ch4_shortcut`（测试锁定），本程未新增任何授予来源；
   - 舞台母题、战斗密度、`mask_enemy`/`seat_husk` 独立数值、阿砚同行均只记录，
     未建模、未实现。
6. **图骨架是测试夹具，不是章节内容**：
   `tests/fixtures/big_room/ch4_graph.mdsworld.json` 顶层 `fixture: true`、
   `content_pending: true`，没有房间场景、没有 `scene_path`、游戏从不引用。
   测试交叉校验计划 ↔ 夹具：入口 BFS 全可达、Boss 单向进入、无孤立区、
   计划 11 条门 ↔ 夹具 20 扇有向门 + 2 扇到达门、房间不重叠、门位在正确边、
   区域相邻（捷径除外）、坠落平面与清房目标 = 图上遭遇总数（7）、节点 id 唯一且锚定。
7. **计划已存在但本程不路由**：`CHAPTER_PLAN_PATHS[3]` 仍为空，`game.gd` 仍用旧
   `chapter_4.mdsworld.json` / `chapter_4_world.tscn`。既有「第 4 章计划槽为空」
   测试保留，并补「计划资源已存在但未接入」断言，区分路由决策与缺文件。

## 后果与边界

- 第 1–3 章零行为变化：计划未接入游戏，波次、战斗、存档、相机/HUD、MDS 插件均未改。
- 第 4 章仍不可达：旧 9 房世界与场景原样保留、继续被游戏使用；没有
  `resources/rooms/ch4_bigmap/` / `scenes/mds/ch4_bigmap/`，没有 `Ch4EventData`，
  Boss 4 文案/机制/测试维持第 50 程核查的缺口。
- 后续施工：第 4 章真实大区世界 → 内容数据层 → Boss 4 机制 → 系统验收；
  真实大区世界前需先定舞台母题呈现口径（第 50 程专节 E），本程不猜。
- 第 2–4 章可达性仍须单独拍板，第 4 章不能早于第 2/3 章。
