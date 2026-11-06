# ADR：第 2 章计划与大区连通图骨架（数据层）

- 日期：2026-11-04（第 30 程，第 31 程补施工进展）
- 状态：已采纳；数据层 + 真实大区世界已落地并接入 `game.gd`（第 2 章仍不可达）
- 相关：[第 2 章大地图可行性核查](../../../SUPERVISOR_STATUS.md)、[房间生产管线](2026-11-04-big-room-pipeline.md)、[纵向/捷径道具](2026-11-04-big-room-pipeline.md)、[MDS 全量接入](2026-11-02-mds-full.md)

## 背景

监工拍板（2026-11-04 深夜）第 9 项为**大区连通图**：第 2–4 章大地图由
6–9 个大区（MDS room）组成，门/短过渡连接，图内可回环、有纵深；第 10 项为
**A：不新增移动能力**。可行性核查 E 节的施工顺序第 1 步（数据/计划）与
第 4 步的前半段，就是本章的计划资源与图骨架。

本程只做数据与可验证的图结构：不建实际房间场景、不改第 2 章世界 JSON、
不开放可达性、不写事件/权柄/Boss 内容。

## 决定

1. **`ChapterPlanData` 向后兼容地扩成大图计划**：
   - `big_map`：第 1 章保持 `false`，行为与解析完全不变。
   - `start_room`：入口大区 id；空则取第一个 `type = entrance`。
   - `doors`：大区图边，见第 4 条。
   - 每个 region 条目新增可选键：`size`（`[宽, 高]`，整屏 1280×720 的 1–3 倍）、
     `encounters`（`region/Node` 节点 id，可多个）、`chests`/`steles`
     （节点 id，可多个）、`shortcuts`（门 id）、`hidden`、`shop`/`rest`、
     `vertical`，以及原有的 `fall_y` / `fall_below_bounds`。
   - `clear_target()`：有条目 `encounters` 时按**遭遇节点数**计数；没有该键
     的旧计划（第 1 章）继续按 `combat`/`elite`/`event` 房型计数，仍为 6。
   - `validate()` / `validate_regions()` / `validate_graph()`：尺寸、坠落平面、
     节点 id 唯一且锚定到所属大区、门/门位唯一、显式单向、可达性、图形态
     （入口/枢纽/支路/纵井/精英/事件/Boss/隐藏区）一次校验。
2. **第 2 章计划资源** `resources/chapters/chapter_2_demo.tres`，9 个大区：
   - `ch2_entry`（入口）→ `ch2_branch_a` / `ch2_branch_b`（两条可回环支路）
     → `ch2_hub`（休整 + 商店 + 残碑 + 捷径解锁）→ `ch2_well`（纵向井，多层）
     → `ch2_event` / `ch2_elite` → `ch2_boss`；`ch2_vault` 是
     `ch2_branch_b` 下的隐藏书库。
   - 尺寸 2560×1440（2×2 屏）、2560×2160（2×3 屏）、3840×2160（3×3 屏）。
   - 每区写 `fall_below_bounds = 240`，坠落平面在整区底边以下，纵向井的下层
     不会被 850 px 规则误杀。
   - 清房目标由计划派生为 **7**（支路 A 与纵井各 2 场、支路 B/精英/事件各
     1 场），不是写死的 6，也不是一区一场。
   - 宝箱 5 个、残碑 5 个，全部是 `region/Node` 节点 id；隐藏书库一区两箱
     两碑，按节点各自结算。
3. **计划暂不接入 `game.gd`**：第 2 章仍走现有 9 个 `ch2_01`…`ch2_boss`
   小房间世界，region id 与新图不同。现在把计划加载进第 2 章会把波次/进度
   指向不存在的房间。等真实大区世界与房间场景落地时再接
   `_start_mds_chapter` 与 `_on_mds_room_loaded`；本程用测试验证计划本身。
4. **门的语义**：一扇门一条 `doors` 记录，`from`/`to` 是 region，`from_gate`/
   `to_gate` 是 MDS 世界 JSON 的门名。`one_way = false` 表示双向（目标房间的
   `to_gate` 指回 `from`）；`one_way = true` 必须显式标注，目标房间仍有一个
   无 `to` 的到达门。`requires` 是 MDS 能力/物件 id（本图只有枢纽捷径
   `hub_shortcut_entry` 需要 `ch2_shortcut`）。
5. **图骨架是测试夹具，不是章节内容**：
   `tests/fixtures/big_room/ch2_graph.mdsworld.json` 以 MDS 世界形状镜像计划
   （房间矩形/原点/类型/门/内容 id），顶层 `fixture: true` 标明测试资产，
   没有 `scene_path`，永远不会被游戏加载。测试交叉校验计划 ↔ 夹具：
   - 从入口 BFS 能到全部 9 区（枢纽/隐藏书库/Boss 都在内）；Boss 单向进入；
   - 每扇门双向或显式单向；无孤立区；无重复房对；
   - 每个大区已配置坠落平面，且平面在房间底边以下；
   - 宝箱/残碑/遭遇 id 全区唯一、按节点结算；
   - 计划派生的清房目标 = 图上的遭遇总数（7）；
   - 第 1 章计划仍是 9 房、清房目标 6、无图、无 region 尺寸，校验为空。

## 第 31 程进展：真实大区世界与 region 语义

- 9 个 `BigRoomData`（`resources/rooms/ch2_bigmap/`）与 9 个 `MDSBigRoom`
  场景（`scenes/mds/ch2_bigmap/`）按本计划的尺寸/内容 id/门名落地；
  架构按第 28 程管线，道具按第 29 程管线（电梯、单向落台、长椅、
  条件捷径门），无事件/战斗内容。
- 独立世界文件 `scenes/mds/chapter_2_bigmap.mdsworld.json` +
  `chapter_2_bigmap_world.tscn`；旧 `chapter_2.mdsworld.json` /
  `chapter_2_world.tscn` 原样保留、不再被 `game.gd` 引用。
- `tests/fixtures/big_room/ch2_graph.mdsworld.json` 继续是测试夹具
  （`fixture: true`、无 `scene_path`），并镜像真实世界的门位/尺寸；
  测试断言 `game.gd` 从不引用夹具。
- `game.gd` 通过 `CHAPTER_PLAN_PATHS` 加载本计划：新局起始区 =
  `start_room`，清房目标 = `clear_target()`（7），坠落平面 =
  `region_fall_limit()`（区高 + 240）。第 1 章仍走 `ch1_01`、目标 6、
  平面 850，9 个房间仍 `MDSChapterRoom`。
- 第 2 章仍不可达：第 1 章章末仍 `_finish(true)`，不自动进入第 2 章。
  后续开放可达性时再补事件/权柄/Boss 内容与章节过渡。

## 后果与边界

- 第 1 章零行为变化：`chapter_1_demo.tres`、`ch1_layout.tres`、9 个
  `ch1_*.tscn` 一字未改；单元与结构集成继续断言第 1 章仍走
  `MDSChapterRoom`、清房目标 6、坠落平面 850。
- 第 2 章仍不可达；旧第 2 章世界 JSON/场景未删、未改语义，只是不再被
  `game.gd` 引用。未新增移动能力、未碰 MDS 插件、未写第 2 章事件文本/
  权柄池/Boss 机制。
- 后续施工：第 2 章事件数据/权柄池/Boss 内容 → 章节过渡与可达性。
  region 语义（起始区、清房目标、坠落平面）已接入 `game.gd`。
