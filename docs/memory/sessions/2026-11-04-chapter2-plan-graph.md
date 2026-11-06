# 2026-11-04 · 第 2 章大地图施工第 4 步（前半）：第 2 章计划与大区图骨架（第 30 程）

> 只做数据层与可验证的图结构：新增第 2 章 `ChapterPlanData` 与 9 个大区的
> 连通图骨架，用测试夹具验证；未创建/重排第 2 章实际房间场景、未改第 2 章
> 世界 JSON、未写事件/权柄/Boss 内容、未改章节可达性、未新增移动能力、
> 未改 MDS 插件/言灵/权柄/战斗框架。第 1 章 9 个房间仍走 `MDSChapterRoom`，
> 行为与基线一致。

## 1. `ChapterPlanData` 扩成大图计划（向后兼容）

- 新增导出字段：`big_map`、`start_room`、`doors`；第 1 章计划保持
  `big_map = false`、无门、无 region 尺寸，解析路径不变。
- 每个 region 条目新增可选键：`size`、`encounters`、`chests`、`steles`、
  `shortcuts`、`hidden`、`shop`/`rest`、`vertical`；`fall_y` /
  `fall_below_bounds` 继续走第 27 程解析链（计划 → 房间 metadata → 850）。
- `clear_target()`：有条目 `encounters` 时按**遭遇节点数**累加；没有该键的
  旧计划仍按 `combat`/`elite`/`event` 房型计数。第 1 章仍为 6。
- 新 API：`start_region()`、`room_ids()`、`regions_of_type()`、
  `region_size()`、`region_fall_limit()`、`encounter_ids()` / `chest_ids()` /
  `stele_ids()` / `shortcut_ids()`、`door()` / `door_targets()` /
  `reachable_from()`（有向 BFS，可切无向）、`one_way_doors()`、
  `pairs_count()`。
- 新校验：`validate()` = `validate_regions()` + `validate_graph()`：
  - region 类型、整屏尺寸（1–3 屏/轴）、坠落平面必须低于本区底边；
  - `encounters`/`chests`/`steles` 必须是 `region/Node` 节点 id、全区唯一
    （一区多内容各自结算，不回退到按 room id）；
  - 门引用的大区存在、门位在同一房间内唯一、一房对一门、`one_way` 显式；
  - 捷径 id 必须是本区发起且带 `requires` 的门；
  - 图形态：恰好一个入口/枢纽/Boss、至少两条支路、纵井/精英/事件/隐藏区
    各至少一个、枢纽有休整 + 商店 + 残碑 + 捷径、图上至少有一个环；
  - 从入口有向 BFS 必须到达所有大区（无孤立区）。

## 2. 第 2 章计划：9 个大区

`resources/chapters/chapter_2_demo.tres`（`chapter_id = breathing_ruins`）：

| 大区 | 类型 | 尺寸 | 内容 |
|---|---|---|---|
| `ch2_entry` | 入口 | 2560×1440 | 安全入口，两条支路分叉 |
| `ch2_branch_a` | 支路 | 2560×1440 | 2 场遭遇、1 宝箱 |
| `ch2_branch_b` | 支路 | 2560×1440 | 1 场遭遇、1 宝箱、1 残碑，向下接隐藏书库 |
| `ch2_hub` | 枢纽 | 2560×1440 | 休整 + 商店 `ch2_hub_shop` + 残碑 + 捷径解锁 |
| `ch2_well` | 纵向井 | 2560×2160 | 上下层、2 场遭遇、1 宝箱 |
| `ch2_vault` | 隐藏书库 | 2560×1440 | `hidden`，2 宝箱 + 2 残碑 |
| `ch2_event` | 事件 | 2560×1440 | 1 个事件遭遇、1 残碑 |
| `ch2_elite` | 精英 | 3840×2160 | 1 场精英遭遇 |
| `ch2_boss` | Boss | 3840×2160 | 独立 Boss 区，单向进入 |

- 清房目标派生为 **7**（支路 A 2 + 支路 B 1 + 纵井 2 + 精英 1 + 事件 1），
  不是写死的 6，也不是一区一场。
- 宝箱 5 个、残碑 5 个，全部是 `region/Node` 节点 id；隐藏书库一区两箱两碑。
- 每区写 `fall_below_bounds = 240`：坠落平面在本区底边以下，纵井下层不会被
  850 px 规则误杀。
- 门的语义：`one_way = false` 为双向；`one_way = true` 必须显式标注，目标
  房间仍有一个无 `to` 的到达门。图里只有两扇单向门：`elite_boss`（Boss 区
  单向进入）与 `hub_shortcut_entry`（枢纽 → 入口，`requires = ["ch2_shortcut"]`）。

## 3. 图骨架是测试夹具

`tests/fixtures/big_room/ch2_graph.mdsworld.json`：顶层 `fixture: true`，
没有 `scene_path`，标明是测试资产、不是章节内容、永远不会被游戏加载。它以
MDS 世界形状镜像计划：9 个房间矩形/原点/类型/门/内容 id，门位落在对应边上。
测试交叉校验：

- 计划 region 集合 = 夹具房间集合，类型/尺寸/内容 id/隐藏标记逐一相同；
- 每扇双向门在两侧都有互指的门位，每扇单向门只有出发门 + 目标房间的到达门；
- 夹具里每个有 `to` 的门都能在计划里找到（正向或双向门的反向），没有未声明
  的传送；
- 从入口 BFS 覆盖 9 区（含枢纽/隐藏书库/Boss），无孤立区、无重复房对；
- 房间矩形不重叠，双向门连接的两个大区在世界坐标上真正相邻；捷径是显式的
  非相邻传送门；
- 每个大区已配置坠落平面且平面在本区底边以下；
- 计划派生的清房目标 = 图上的遭遇总数（7）。

## 4. 第 1 章零变化

`chapter_1_demo.tres`、`ch1_layout.tres`、9 个 `ch1_*.tscn` 一字未改；
`ChapterPlanData` 的新字段都有安全默认值。单元测试断言第 1 章仍为 9 个房间、
清房目标 6、无 door/region 尺寸/encounter 列表、`validate()` 为空；结构集成
继续断言第 1 章 9 个房间走 `MDSChapterRoom`、坠落平面 850、第 2 章仍是旧
运行时（默认清房目标 6）。

## 5. 本程未做（按任务单）

- 未接入 `game.gd`：第 2 章仍走现有 `ch2_01`…`ch2_boss` 小房间世界，region
  id 与新图不同；等真实大区世界/房间场景落地后再接 `_start_mds_chapter` 与
  `_on_mds_room_loaded`。
- 未创建/重排第 2 章实际房间场景，未改 `chapter_2.mdsworld.json`，未写第 2 章
  事件文本/权柄池/Boss 机制/敌人美术，未改章节可达性（第 2–4 章仍不可达），
  未新增二段跳/蹬墙跳/攀爬，未改 MDS 插件本体或言灵/权柄/战斗框架。

## 6. 验证（本程末实测，Godot 4.7.stable.official.5b4e0cb0f）

- 任务 0 基线：在 `git worktree` 的干净 `2560f29` 副本上 `--import` 退出 0、
  `ERROR` 0；单元 **5861 / 0**，与第 29 程收尾数字逐项一致。
- `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0。
- 全量单元 **6517 / 0**（基线 5861 + 新增 `test_ch2_plan` 656）。
- 八套集成全部 0 失败、各日志 `ERROR` 0：结构 **392**、第一章 demo **101**、
  run save **588**、手柄 **207**、UI 提示 **113**、第一章事件 **59**、
  菜单 A/B **391**、AI 设置 **45**（与第 29 程基线一致，无回归）。
- 退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。
- 临时探针未创建；工作区干净。

## 7. 后续

按计划建第 2 章真实大区世界（`chapter_2.mdsworld.json` 的 9 个 region 矩形/
门）与 `MDSBigRoom` 场景；再给 `game.gd` 补 region 语义（`_mds_room_index`、
事件数据分章、枢纽休息判定、第 2 章权柄池/Boss 机制），全部绿后再由监工决定
是否开放第 2 章可达性。
