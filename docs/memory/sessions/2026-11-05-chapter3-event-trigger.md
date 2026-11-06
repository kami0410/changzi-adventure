# 2026-11-05 第 44 程：第 3 章内容数据层第 3 步——事件区真实自动触发

## 目标

沿用第 34 程对第 2 章的做法，给第 3 章 `ch3_event` 事件区接上区域级真实自动
触发，并在测试层验证选句确定性、读/拿效果、一次性结算与清房目标。只做触发
机制与测试层：不接入 `game.gd`、不开放可达性、不产生可玩行为变化。

## 结论：通用分支已经覆盖第 3 章，无需新增触发路径

- 第 34 程在 `scripts/game.gd::_on_mds_room_loaded` 加的区域级事件分支是
  **章节无关**的判定：

  ```gdscript
  if big_map and room_type == "event" and not _event_data(room_id).is_empty():
  ```

  其中 `big_map` 只看当前计划是否为 `big_map`，`room_type` 来自计划区域，
  `_event_data(room_id)` 按 `_chapter` 查表。
- 第 42 程已把 `_event_data` 扩到第 3 章（`_chapter == 2` → `Ch3EventData`）。
  因此第 3 章计划挂上后，进入 `ch3_event` 就会自动打开第 3 章事件页，键 =
  `RoomProgress.event_encounter_id("ch3_event")` = 计划事件节点 id
  `ch3_event/event`。
- 本程没有为第 3 章另写触发路径，也没有改 `game.gd` 的行为；只在
  `_on_mds_room_loaded` 该分支的注释里补了一句「分支章节无关，第 2–3 章只要
  有事件数据就适用，可达性仍由计划槽决定」。

## 触发与效果口径（沿用既有实现）

| 项目 | 第 3 章实际行为 |
|---|---|
| 触发条件 | 大图区域 + `type == "event"` + 本章有事件数据；进入 `ch3_event` 即触发 |
| 选句 | `Ch3EventData.pick(run_seed, "ch3_event/event")`，按局 seed + 节点 id 确定性轮换 |
| run RNG | 选句与「拿」不消耗；「读」在解明残页词时沿用 `_grant_event_word` 的 run RNG |
| 读 | 污染 +8（经 `corruption_gain_multiplier`、上限 100）+ 解明一个残页词；无词可解 → 残页 +6 |
| 拿 | 残页 +12 |
| 结算 | 写 `cleared_encounters["ch3_event/event"]`，清房计数 +1、HUD 分母 8 |
| 一次性 | 重载/再进不重开页面、不重复发奖励、不重复计数；未结算离开会取消延迟开页 |

## 改动

- `scripts/game.gd`：仅注释补充（无行为改动）。
- `tests/test_ch3_content.gd`（601 → **614**）：新增 `_test_event_trigger_inputs`，
  把第 3 章计划挂到独立 `game.gd` 实例，验证触发判定三项输入、触发键 = 计划
  事件节点 id、事件节点无普通波、清房目标 7 / HUD 分母 8、同一键的一次性
  结算语义。不改章节路由。
- `tests/integration_playability.gd`（671 → **705**）：新增
  `_test_ch3_bigmap_event_trigger`，把第 41 程的 `chapter_3_bigmap_world.tscn`
  与第 3 章计划临时挂到真实主场景（与 `_start_mds_chapter` 同构，`ch3_event`
  为起始区），走真实 `room_loaded` 触发验证：
  - 进入即开页，文案/标题/两选项 = `Ch3EventData.pick(run_seed, 节点 id)`；
  - 开页与「拿」不耗 run RNG（「读」解明残页词时沿用既有 run RNG）；拿 →
    残页 +12 且提示文案正确；
  - 结算键 / 清房计数 +1 / run save 落盘同一键；
  - 重载不重开、不暂停、不重复计数、不重复奖励；
  - 回退结算后重进再验「读」→ 污染 +8（含倍率与上限）+ 解明一残页词或兜底 +6；
  - 测试后 `_restore_chapter_world` 重新进入第 3 章，既有旧世界结构巡检照常跑。
- 未新增套件：按第 34 程的分工就近扩展现有单元/集成套件。

## 不变项

- `CHAPTER_PLAN_PATHS[2]` 仍空，`game.gd` 仍使用旧 `chapter_3.mdsworld.json` 与
  9 个 `MDSChapterRoom`；章节路由、章末流程（第 3 章末仍会自动进第 4 章）未改。
- 第 3 章计划波次表、权柄池、事件文案、大区世界与场景未改。
- 第 1 章 9 房间/6 波次/事件/清房目标 6、第 2 章计划/波次表/大区世界/事件数据/
  事件触发/权柄池/Boss 文案均未改。
- 第 2/3 章仍不可达；未开放任何可达性。

## 验证（本机 Godot 4.7.stable.official.5b4e0cb0f）

- 基线（改动前，HEAD `cecaffa`）：单元 **10100 / 0**；九套集成
  **671 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209** 全 0 失败；退出泄漏
  **10/10 clean**；demo 像素资产 **36 / 0**；`--import` / `--quit` 退出 0、`ERROR` 0。
- 改动后：单元 **10113 / 0**（+13，全部来自 `test_ch3_content`）；可玩性集成
  **705 / 0**（+34）；其余八套集成数字与基线一致、全 0 失败；`--import` /
  `--quit` 退出 0、`ERROR` 0；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。

## 未做（按任务单）

第 3 章接入 `game.gd` / 可达性 / 章节路由 / 章末流程；Boss 3 机制 / `boss_scene` /
专属场景；第 3 章大图验收套件；第 3 章门视觉专项；阿砚同行；新移动能力；
NPC 立绘；MDS 插件本体；敌人/场景美术；打包/导出/安装器/签名/安卓/触屏。
待确认第 11/12/13/14/15/16 项未施工、未猜测；第 3 章章末自动进第 4 章的缺口
仍在，留给后续章末收口程。
