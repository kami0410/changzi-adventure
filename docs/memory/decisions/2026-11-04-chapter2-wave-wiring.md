# 第 2 章波次接线：按遭遇节点 id 锚定的 `wave`

- 日期：2026-11-04（第 33 程）
- 状态：已实施（第 2 章仍不可达，只在测试层驱动）

## 背景

第 32 程完成第 2 章内容数据层第 1 步后，计划 `chapter_2_demo.tres` 的 7 个遭遇节点里已有 6 场战斗 + 1 个事件，并校验了「计划顺序 ↔ `ROOM_WAVES[1]` 六波」一一对应；但计划区域没有 `wave` 键，`game.gd` 的大区 `Arena` 不会生成敌人。第 2 章真实大区世界里一个区可以有两场战斗（`ch2_branch_a` 的 `Arena`/`Arena2`、`ch2_well` 的 `Arena`/`Arena2`），所以波次不能按房间 id 锚定。

## 决定

1. **大图计划的 `wave` 是字典，键 = 遭遇节点 id（`region/Node`）**，值 = 该场战斗的敌人 id 数组；不是房间级数组、也不是位置数组。
   - 第 1 章线性计划不改：`wave` 仍是房间级 `Array`，`wave_for(room_id, encounter_id)` 在 `Array` 分支直接返回它（忽略 encounter id）。
2. **每个战斗遭遇恰好一波非空波次**；事件节点 `ch2_event/event` 不带波次；Boss 区（`ch2_boss`）没有 `encounters`，也不消耗普通波次。
3. **波次内容不新写**：六场战斗按计划顺序直接使用既有 `ROOM_WAVES[1]` 的六波：

   | 计划顺序 | 遭遇节点 | 波次（= `ROOM_WAVES[1][i]`） |
   |---|---|---|
   | 1 | `ch2_branch_a/Arena` | `choir_summoner`, `page_swarm` |
   | 2 | `ch2_branch_a/Arena2` | `rust_whisperer`, `collapse_husk` |
   | 3 | `ch2_branch_b/Arena` | `lung_moth`, `breath_hound` |
   | 4 | `ch2_well/Arena` | `ink_bomber`, `blank_man` |
   | 5 | `ch2_well/Arena2` | `breath_hound`, `rust_whisperer` |
   | 6 | `ch2_elite/Arena` | `page_swarm`, `collapse_husk` |

   口径说明：`ch2_event/event` 在 `plan.encounter_ids()` 的扁平顺序里位于第 5、6 场战斗之间；「计划顺序」指**过滤掉事件节点后**的战斗顺序。波次里出现的 `ink_bomber`/`blank_man`/`page_swarm` 是既有波次内容，本程不修改。
4. **校验**：`ChapterPlanData.validate_waves()`（由 `validate()` 调用，仅对 `big_map` 生效）检查：`wave` 必须是字典；键必须是本区 `encounters` 列表里的节点 id；值必须是非空敌人 id 数组；非事件区的每个遭遇都必须有波次；事件区的遭遇不得有波次。
5. **运行时接线**：`game.gd` 的 `_on_mds_room_loaded` 大图分支按遭遇节点 id 调 `_plan_wave(room_id, encounter_id)`；每个未清战斗遭遇各自入 `_rooms`、各自生成自己的一波（沿用前 2 个立即出场、其余 `queue_wave` 的既有节奏），锁门/清怪/奖励/进度继续走第 27 程的节点 id 语义。第 1 章分支、`ROOM_WAVES`、奖励与进度一字未改。

## 后果

- 第 2 章真实大区的 6 场战斗都会生成各自的敌人；一区两场互不共享波次、互不整房结算。
- 第 2 章仍不可达；事件页没有自动触发点（本程刻意不做），Boss 独特机制未实现。
- 第 1 章 9 个 `MDSChapterRoom` 的生成路径与基线一致（单元 7819/0、第一章 demo 集成 102/0）。
- 若未来某场战斗需要多波，`wave` 的值仍是一维敌人数组；需要多波时应扩展为「数组的数组」并同步 `_populate_room` 的切分规则，而不是另起房间级键。

## 红线

不改波次内容、不新增敌人/美术、不改战斗框架、不改 MDS 插件、不改存档格式、不开放第 2 章可达性、不新增移动能力。
