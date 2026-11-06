# 第 2 章事件区：按区域类型触发的真实事件页

- 日期：2026-11-04（第 34 程）
- 状态：已实施（第 2 章仍不可达，只在测试层进入）

## 背景

第 32 程把事件页做成按章节查表（`_event_data` / `_open_chapter_event`），但自动触发条件仍是第 1 章的 `is_primary and _chapter == 0 and room_type == "event"`。第 2 章真实大区世界的 `ch2_event` 场景只有 `Event`（`ArenaRoom`）与 `Stele1`，没有主节点 `Arena`，因此 `is_primary` 永远不成立；计划 `chapter_2_demo.tres` 里该区 `type = "event"`、`encounters = ["ch2_event/event"]`。结果是第 2 章事件页只由测试直接调用，正常进入该区不会打开。

## 决定

1. **触发挂在区域级，不依赖主 `Arena`**：`_on_mds_room_loaded` 的 `ArenaRoom` 循环结束后，对 `big_map` 计划中 `type == "event"` 且本章有事件数据（`_event_data(room_id)` 非空）的区域统一处理：未结算则设目标并调用既有的 `_open_event_after_transition(room_id)`，已结算则只把目标改为「事件已经读过」。
   - 第 1 章的事件房继续走原来的 `is_primary` 分支，代码路径与文案不变；两种触发都汇入同一个 `_open_chapter_event`。
   - 大图事件区即使将来没有 `ArenaRoom` 节点也能触发，因为事件页属于区域（计划的 `type` + 事件节点），不属于某个战斗 Arena。
2. **键与结算沿用第 27 程的节点 id 语义**：事件节点 id = `RoomProgress.event_encounter_id(room_id)`，对 `ch2_event` 即计划里的 `ch2_event/event`；页面文案用 `Ch2EventData.pick(run_seed, 事件节点 id)`，按局 seed + 节点 id 确定性轮换，不消耗 run RNG。结算调 `_mark_encounter_cleared(room_id, 事件节点 id)`，只记一次、计入清房目标 7。
3. **一次性语义**：进入区域时先查 `_cleared_encounters`（含旧 room-key 兼容）。结算后再次进入或重载不会重开页面、不会重复发奖励；未结算时离开区域会取消延迟打开的页面（沿用第 1 章 `_open_event_after_transition` 的取消规则）。
4. **不新写文案/数值**：目标文本沿用第 1 章的「事件 · 读或不读」「事件已经读过」；效果仍是第 32 程落地的两项——读 → 污染 +8 并解明一个残页词（无词可解则残页 +6）；拿 → 残页 +12。

## 后果

- 第 2 章 `ch2_event` 现在有真实自动触发点；测试用 `mds.load_room("ch2_event")`（与门/检查点相同的房间加载路径）进入即可验证，不再直接调用开页函数。
- 第 2 章仍不可达：第一章章末仍按现有流程收口，不进入第 2 章；Boss 独特机制与章节过渡未做。
- 第 1 章 9 个 `MDSChapterRoom`、事件房触发/文案/选项/数值、6 场波次与清房目标 7 均未改动。

## 红线

不改 MDS 插件、言灵/权柄/战斗框架、存档键与格式；不新增效果类型或数值；不开放第 2 章可达性；不新增移动能力；不删旧世界/旧场景。
