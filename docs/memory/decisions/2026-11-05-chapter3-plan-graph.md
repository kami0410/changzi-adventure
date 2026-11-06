# ADR：第 3 章计划与图骨架（数据层）

- 日期：2026-11-05（第 40 程）
- 状态：已采纳；仅数据层与测试夹具，未接入 `game.gd`，第 3 章仍不可达
- 相关：[第 3 章大地图可行性核查](../../../SUPERVISOR_STATUS.md)、
  [第 2 章计划与大区连通图](2026-11-04-chapter2-big-map-graph.md)、
  [第 2–4 章房间生产管线](2026-11-04-big-room-pipeline.md)、
  [纵向/捷径道具](2026-11-04-big-room-pipeline.md)

## 背景

第 39 程核查确认：第 2 章走通的大区连通图路线可直接承载第 3 章，缺口集中在
内容层。按核查 C 节顺序，第 1 步是计划与图骨架。本程沿用第 30 程对第 2 章的
做法，为第 3 章立一个可校验的计划与图骨架，为后续真实大区世界打地基。

## 决定

1. **第 3 章计划 = 9 区连通图**（`resources/chapters/chapter_3_demo.tres`），
   与第 2 章同构：入口 → 两条可回环支路 → 枢纽 → 纵井 → 事件/精英 → Boss，
   隐藏书库挂在支路下。
   - 区：`ch3_entry`、`ch3_branch_a`、`ch3_branch_b`、`ch3_hub`、`ch3_well`、
     `ch3_vault`、`ch3_event`、`ch3_elite`、`ch3_boss`。
   - 尺寸沿用第 2 章的整屏口径：2560×1440、2560×2160（纵井）、3840×2160
     （精英/Boss）；每区 `fall_below_bounds = 240`。
   - 11 扇门 = 9 双向 + 2 显式单向（`elite_boss` 进 Boss 不可返回、
     `hub_shortcut_entry` 捷径单向）。图内有两个回环，Boss 是末端。
2. **遭遇按旧第 3 章 6 波派生，但本程不写波次**：6 个战斗遭遇
   （支路 A 2、支路 B 1、纵井 2、精英 1）正好对应 `ROOM_WAVES[2]` 六波；
   事件区再加 1 个占位遭遇，`clear_target()` 派生为 **7**。第 1 章仍 6、
   第 2 章仍 7，本程未改动既有章节的派生结果。
3. **`ChapterPlanData.content_pending`（新增，默认 `false`）**：计划结构先于
   内容落地时置 `true`；`validate()` 仍校验区域、节点 id 与门图，只跳过
   `validate_waves()`。这样计划本身可校验，同时明确「波次待内容程」；
   第 1/2 章计划为 `false`，行为与校验结果不变。后续内容程接完波次后
   应把标志改回 `false`，测试会把关（同一计划关掉标志必须报六条缺波次）。
4. **占位必须显式标注，不编造内容**：
   - 事件区只有节点 id `ch3_event/event`，无文案/效果，注释指向后续
     `Ch3EventData`；
   - Boss 区只有类型与末端门，不写 `boss_scene`、不改旧
     `boss_script == "reader"` 分支、不写入场/阶段文案；
   - 捷径门 `hub_shortcut_entry` 写 `requires: ["ch3_shortcut"]` 并注释
     「授予来源待拍板（状态第 16 项）」，因此默认不可通行；`game.gd` 不含
     `ch3_shortcut`（测试锁定），本程未新增任何授予来源。
5. **图骨架是测试夹具，不是章节内容**：
   `tests/fixtures/big_room/ch3_graph.mdsworld.json` 顶层 `fixture: true`、
   `content_pending: true`，没有房间场景、没有 `scene_path`、游戏从不引用
   （测试检查 `game.gd` 不含夹具路径）。测试交叉校验计划 ↔ 夹具：
   - 入口 BFS 可达全部 9 区；Boss 单向进入；无孤立区；无重复房对；
   - 计划 11 条门 ↔ 夹具 20 扇有向门 + 2 扇到达门，双向/单向/`requires` 一致；
   - 房间世界矩形不重叠、门所在区域相邻（捷径除外）、门位在正确边且落在房间内；
   - 每区坠落平面 > 房间高度；清房目标 = 夹具遭遇总数（7）；
   - 节点 id 全区唯一且锚定 `region/Node`。
6. **待拍板项不预设**：第 14 项视野压缩、第 15 项海面母题均未实现、未预设；
   夹具只镜像旧世界区域（雾/雨、`boss_background=deep_water`、无
   `backdrop_image`），不给大区管线加 sea 层、不改 `LivingBackdrop`、
   不新绘背景。第 16 项见第 4 条。章末自动进第 4 章的行为本程未改。

## 后果与边界

- 第 1/2 章零行为变化：两章计划 `content_pending = false`，`validate()` 结果不变；
  `game.gd`、章节路由、波次、战斗、存档、相机/HUD、MDS 插件均未改。
- 第 3 章仍不可达：`CHAPTER_PLAN_PATHS[2]` 仍为空（既有测试锁定），旧
  `chapter_3.mdsworld.json` / `chapter_3_world.tscn` 与 9 个 `MDSChapterRoom`
  场景原样保留、继续被游戏使用。
- 后续施工：第 3 章真实大区世界（房间数据/场景/世界/出生点/门视觉）→
  `Ch3EventData` + 波次 + 权柄池 + Boss 文案/路由 → Boss 3 机制 → 大图验收；
  真实大区世界前需先定第 15 项海面母题（以及第 14/16 项），本程不猜。
- 第 2–4 章可达性仍须单独拍板，第 3 章不能早于第 2 章。
