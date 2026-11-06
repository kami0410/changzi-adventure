# 2026-11-04 第 34 程：第 2 章内容数据层第 3 步——事件区真实自动触发

## 目标

给第 2 章 `ch2_event` 事件区接上真实自动触发：进入大图分支的房间时通过既有按章节查表路由打开第 2 章事件页；按事件节点 id 一次性结算，重载不重复。只接触发，不开放第 2 章可达性，不做 Boss 机制与章节过渡。

## 改动

- `scripts/game.gd`：
  - `_on_mds_room_loaded` 在 `ArenaRoom` 循环之后新增区域级分支：`big_map` 计划里 `type == "event"` 且本章有事件数据（`_event_data(room_id)` 非空）时，未结算 → 设目标「事件 · 读或不读」并 `_open_event_after_transition(room_id)`；已结算 → 设目标「事件已经读过」。
  - 为什么是区域级：第 2 章 `ch2_event` 只有 `Event`（`ArenaRoom`）与 `Stele1`，没有主节点 `Arena`，原第 1 章分支的 `is_primary` 永远不成立。事件页属于区域（计划的 `type` + 事件节点），不依赖某个战斗 Arena。
  - 页面路由不变：`_event_data(room_id)` → `_open_chapter_event(room_id)`；第 2 章用 `Ch2EventData.pick(run_seed, RoomProgress.event_encounter_id(room_id))`，键即计划事件节点 id `ch2_event/event`；两项效果、数值、文案全部沿用第 32 程。
  - 结算沿用 `_mark_encounter_cleared(room_id, event_encounter_id(room_id))`，复用 `cleared_encounters` 存档键；只记一次、计入清房目标 7。
- 测试：
  - `tests/integration_playability.gd` 扩到 651（+15）：从大图房间加载路径进入 `ch2_event` 自动开页（不再直接调开页函数）；文案/选项来自 `Ch2EventData`、开页不消耗 run RNG；拿 → 残页 +12，读 → 污染 +8 且解明一个残页词（无词则残页 +6）；`ch2_event/event` 只结算一次并计入进度；结算后重载不重开、不暂停、不重复奖励；真实 run save 写入 `cleared_encounters`（临时档用完清理）。
  - `tests/test_ch2_content.gd` 扩到 510（+2）：`RoomProgress.event_encounter_id("ch2_event")` 必须等于计划里的 `ch2_event/event`，锁定触发键与结算键一致。
- 文档：新增 ADR `docs/memory/decisions/2026-11-04-chapter2-event-trigger.md`；在旧的内容查表 ADR 加一条第 34 程更新注记。

## 口径与歧义

- **触发点歧义**：第 1 章的事件房有主 `Arena`，触发挂在 `is_primary`；第 2 章事件区的 `Event` 节点不是主 `Arena`。本程采用「区域级触发」：`big_map` + `type == "event"` + 本章有事件数据，不看 Arena 是否 primary。第 1 章原分支不动，两者汇入同一个 `_open_chapter_event`；测试锁定该口径。
- **结算键**：按计划事件节点 id `ch2_event/event`（`RoomProgress.event_encounter_id`），不是整房 id；未新增存档键。续玩由现有 run save 的 `cleared_encounters` 还原覆盖，重载断言锁定触发查询。
- **未结算离开**：沿用第 1 章 `_open_event_after_transition` 的取消规则（离开区域后不补开页）；未结算时再次进入仍会开页。

## 验证（本机 Godot 4.7.stable.official.5b4e0cb0f）

- 基线（改动前）：单元 7819/0；八套集成 636/102/588/207/113/59/391/45 全 0 失败；退出泄漏 10/10；像素资产 36/0；`--import`/`--quit` 退出 0、ERROR 0。
- 改动后：单元 **7821/0**（+2）；结构/可玩性 **651/0**（+15）、第一章 demo **102/0**、run save **588/0**、手柄 **207/0**、UI 提示 **113/0**、第一章事件 **59/0**、菜单 A/B **391/0**、AI 设置 **45/0**；退出泄漏 **10/10**；像素资产 **36/0**；`--import`/`--quit` 退出 0、ERROR 0。
- 第 1 章事件房（触发、文案、选项、数值）、9 个 `MDSChapterRoom`、6 场波次与清房目标不变；第 2 章仍不可达。

## 未做（按任务单）

第 2 章可达性；Boss 2 独特机制与专属攻击；章节过渡；新敌人/敌人美术/NPC 立绘；二段跳/蹬墙跳/攀爬；MDS 插件；言灵/权柄/战斗框架；删除旧世界/旧场景；打包/导出/安装器/签名/安卓/触屏。
