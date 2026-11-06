# 2026-11-04 · 第 2 章大地图施工第 1 步：基础解耦（第 27 程）

> 只做解耦：未创建/调整第 2 章地图、房间、世界 JSON 或可达性，未新增移动能力，
> 第 1 章行为保持不变，第 2–4 章仍不可达。「待用户确认」第 9/10 项保持开放，
> 本步设计对「大区图 + 短过渡」与「字面单场景无缝」两种口径都成立。

## 1. 坠落平面按房间/区域

- `game.gd` 的固定 `fall_y > 850.0` 改为 `> _fall_limit_local`；房间加载时
  `_resolve_fall_limit()` 依次读取：章节计划房间键 `fall_y`（房间局部绝对 y）或
  `fall_below_bounds`（房间并集底边以下）→ 房间节点 metadata 同名键 →
  `ChapterPlanData.DEFAULT_FALL_Y`（850）。
- 第 1 章计划 9 个房间都没有配置，行为仍是 850 px；无计划的第 2–4 章同样回退 850。
- 断言：`test_room_progress` 覆盖默认/两种配置/非法值/优先级；`integration_playability`
  实测第 1 章 y=700 安全、y=851 回退到检查点并按难度伤害倍率扣 15 基础伤害；
  合成计划把平面配到 2000 后，y=1200 的下层区域不再被误杀、y=2001 才回退。

## 2. 一次性内容与清场进度按节点 id

- 新增 `RoomProgress`（`scripts/core/room_progress.gd`）：id 取作者 `content_id`/
  `encounter_id`，否则 `room_id/节点名`；同房重复名用 `#2`/`#3` 唯一化；旧 room-key
  记录经 `is_recorded(ids, legacy_rooms, ...)` 兼容回退。
- `_cleared_encounters` 取代 `_mds_cleared_rooms`；宝箱/残碑用 `TreasureChest.content_id` /
  `MemoryStele.content_id`；遭遇用 `ArenaRoom.encounter_id`。房间加载时收集全部直接子
  `ArenaRoom`，逐个接线、禁用其 `Enemies` 处理并按键记录；`Arena` 仍是主节点，继续负责
  事件、Boss、计划波次与房间级目标文案。
- 存档：新增可选键 `progress.cleared_encounters`、`world.claimed_stele_ids`、
  `world.opened_chest_ids`；旧键 `cleared_rooms` / `claimed_steles` / `opened_chests`
  读入 `_legacy_*` 并原样写回，**不从新进度反推旧键**，避免多内容房续玩时把整房内容
  误判为已消费。旧档不判坏档、不丢档；新键类型错误仍拒绝。
- 第 1 章单房单内容与基线一致：`ch1_01/Arena`、`ch1_03/Chest`、`ch1_vault/Chest`、
  `ch1_vault/Stele`、`ch1_rest/Stele`、`ch1_05/event`。
- 断言：单元 `test_room_progress` / `test_run_save`；集成 `ch1_demo`（一房两箱两碑、
  重载只恢复已记录项、重复清房不计、legacy room-key 压制）、`run_save`（旧格式检查点
  加载、旧键继续压制并写回、新 id 落盘）、`playability`（同房第二个 Arena 注册、
  独立 id、信号接线、重复清房不计数/不重复发奖）。

## 3. 章节清房目标读计划

- `ChapterPlanData.clear_target()`：默认统计 `combat`/`elite`/`event` 房型（第 1 章
  计划 = 6），可用 `clear_target_override` 覆盖；无计划章节仍回退 6。
- `game.gd` 的上限判断、HUD 分母（目标 + Boss）、奖励种子、改写房号全部改读目标；
  第 1 章仍是 6 / 7，数值与基线一致。
- 断言：单元第 1 章 = 6、派生计数、覆盖值、空计划；集成四章均为 6 / 7。

## 验证

- 单元 5706 / 0；八套集成 296 / 101 / 561 / 207 / 113 / 59 / 391 / 45，全部 0 失败。
- `--headless --import` 与 `--quit` 退出 0、`ERROR` 0；退出泄漏 10/10 clean；
  demo 像素资产 36 / 0。临时探针用后删除，未改第 2 章世界 JSON/场景/可达性。
