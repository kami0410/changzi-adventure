# 2026-11-05 第 56 程：第 4 章内容数据层第 3 步——事件区真实自动触发

## 目标

沿用第 34 程对第 2 章、第 44 程对第 3 章的做法，验证第 4 章 `ch4_event`
事件区的区域级真实自动触发，并在测试层覆盖选句确定性、读/拿效果、一次性结算
与清房目标。只做触发验证与测试层：不接入 `game.gd`、不开放可达性、不产生任何
可玩行为变化。

## 结论：通用分支已经覆盖第 4 章，无需新增触发路径

- 第 34 程在 `scripts/game.gd::_on_mds_room_loaded` 加的区域级事件分支是
  **章节无关**的判定：

  ```gdscript
  if big_map and room_type == "event" and not _event_data(room_id).is_empty():
  ```

  `big_map` 只看当前计划是否为 `big_map`，`room_type` 来自计划区域，
  `_event_data(room_id)` 按 `_chapter` 查表。
- 第 53 程已把 `_event_data` 扩到第 4 章（`_chapter == 3` → `Ch4EventData`）。
  因此第 4 章计划与大区世界挂上后，进入 `ch4_event` 就会自动打开第 4 章事件页，
  键 = `RoomProgress.event_encounter_id("ch4_event")` = 计划事件节点 id
  `ch4_event/event`。
- 本程没有为第 4 章另写触发路径，也没有改 `game.gd` 行为；只把该分支注释里的
  「Chapters 2–3」更正为「Chapters 2–4」。

## 触发与效果口径（沿用既有实现）

| 项目 | 第 4 章实际行为 |
|---|---|
| 触发条件 | 大图区域 + `type == "event"` + 本章有事件数据；进入 `ch4_event` 即触发 |
| 选句 | `Ch4EventData.pick(run_seed, "ch4_event/event")`，按局 seed + 节点 id 确定性轮换 |
| run RNG | 选句与「拿」不消耗；「读」在解明残页词时沿用 `_grant_event_word` 的 run RNG |
| 读 | 污染 +8（经 `corruption_gain_multiplier`、上限 100）+ 解明一个残页词；无词可解 → 残页 +6 |
| 拿 | 残页 +12 |
| 结算 | 写 `cleared_encounters["ch4_event/event"]`，清房计数 +1、HUD「档案 1 / 8」 |
| 一次性 | 重载/再进不重开页面、不重复发奖励、不重复计数；未结算离开会取消延迟开页 |

## 改动

- `scripts/game.gd`：仅注释更正（Chapters 2–3 → 2–4），无行为改动。
- `tests/test_ch4_content.gd`（641 → **642**）：`_test_event_trigger_inputs`
  补一条「触发键 = `RoomProgress.event_encounter_id("ch4_event")` = 计划事件节点
  id」，防止页面与结算键漂移；文件头注释更新为步骤 1–3。
- `tests/integration_playability.gd`（755 → **810**）：新增
  `_test_ch4_bigmap_event_trigger`，把第 52 程的
  `chapter_4_bigmap_world.tscn` 与第 4 章计划临时挂到真实主场景（与
  `_start_mds_chapter` 同构，`ch4_event` 为起始区），走真实 `room_loaded`
  触发验证：
  - 进入即开页，文案/标题/两选项 = `Ch4EventData.pick(run_seed, 节点 id)`；
  - 开页与「拿」不耗 run RNG；拿 → 残页 +12、提示文案与 HUD「档案 1 / 8」；
  - 结算键 / 清房计数 +1 / run save 落盘同一键；
  - 重载不重开、不暂停、不重复计数、不重复奖励；
  - 回退结算后重进再验「读」→ 污染 +8（含倍率与上限）+ 解明一残页词或兜底 +6；
  - 锁 `CHAPTER_PLAN_PATHS[3]` 空、`MDS_WORLD_FILES[3]` 仍旧世界、旧世界
    9 房/17 门仍在、第 1–3 章计划槽不变、计划清房目标 7 / 7 个遭遇 /
    波次表（`content_pending = false`）/ 无 `boss_scene`、第 1–3 章事件数值
    不变、`game.gd` 无 `ch4_event` 专属触发与 `chapter_4_bigmap` 路由；
  - 测试后 `_restore_chapter_world` 重新进入第 4 章，既有旧世界结构巡检照常跑。
- 未新增套件：沿用第 34/44 程的分工，就近扩展现有单元/集成套件。

## 不变项

- `CHAPTER_PLAN_PATHS[3]` 仍空，`game.gd` 仍使用旧 `chapter_4.mdsworld.json` 与
  9 个 `MDSChapterRoom`；章节路由与章末流程（第 4 章既有分支）未改。
- 第 4 章计划波次表、权柄池、事件文案、大区世界与场景未改；`boss_scene` 仍为空。
- 第 1/2/3 章计划、世界、事件触发与数值未改；第 1 章事件房原 `is_primary`
  触发一字未动（`integration_ch1_event` 59 断言复跑 0 失败）。
- 第 2/3/4 章仍不可达；未开放任何可达性。

## 验证（本机 Godot 4.7.stable.official.5b4e0cb0f）

- 基线（改动前，HEAD `3a37d8d`）：单元 **12573 / 0**；十套集成
  **755 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209 / 4235** 全 0 失败；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**；`--import` / `--quit`
  退出 0、`ERROR` 0。
- 改动后：单元 **12574 / 0**（+1，`test_ch4_content`）；可玩性集成 **810 / 0**
  （+55：新增 `_test_ch4_bigmap_event_trigger` 54 条 + 第 4 章旧世界恢复 1 条）；
  其余九套集成数字与基线一致、全 0 失败；`--import` / `--quit`
  退出 0、`ERROR` 0；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。

## 未做（按任务单）

第 4 章接入 `game.gd` / 可达性 / 章节路由 / 章末流程；Boss 4 机制与
`boss_scene`；第 4 章大图验收套件；`ch4_shortcut` 授予来源（屏障保持默认
封闭）；战斗密度（旧世界每房 5–6 只 vs 大图每遭遇 2 只只记录）；`mask_enemy`/
`seat_husk` 独立数值与行为；舞台母题呈现层；阿砚同行；新移动能力；NPC 立绘；
MDS 插件本体；敌人/场景美术；打包/导出/安装器/签名/安卓/触屏。待确认第
11–16 项未施工、未猜测；第 50 程专节 E 的开放问题候选仍只记录、未编号。
