# 2026-11-06 第 62 程：第 4 章大图门视觉专项与敌人美术核查

## 背景

第 59 程完成第 4 章大地图系统验收后，第 4 章只剩三项表现/美术审计——第 49 程对
第 3 章做过的同类工作：① 大图门视觉专项；② 地图标题复核；③ 敌人美术核查。
本程只做这三项（测试与记录为主），不改门逻辑、不接入 `game.gd`、不开放可达性、
不碰待确认第 11–16 项，也不修第 60 程样图里发现的表现问题。brief65 / 第 61 程
因 Magpie 网关中断从未启动，本程按同一任务单接力。

## 任务 0 · 基线核验

HEAD `e5e5f17`，工作区干净，Godot 4.7.stable.official.5b4e0cb0f。

- `--headless --import` / `--quit` 退出 0、`ERROR` 0。
- 单元 **12657 / 0**；十一套集成 **894 / 102 / 613 / 207 / 113 / 59 / 391 / 45 /
  2209 / 4235 / 4869** 全 0 失败；退出泄漏 **10/10 clean**；demo 像素资产
  **36 / 0**。与第 60 程交接完全一致，无漂移。

## 任务 1 · 第 4 章大图门视觉专项

### 核查（先查后做）

- 第 37 程的 `GateVisual` 由 `MDSBigRoom._add_gate_visuals()` 通用挂载（自动门 +
  作者门）；第 52 程 9 个第 4 章场景全部是 `MDSBigRoom`、`auto_gates` 全开，
  22 扇门已被通用管线自动覆盖，**未另起视觉实现**。
- 22 扇构成（`scenes/mds/chapter_4_bigmap.mdsworld.json` 事实）：
  `left` 5、`right` 5、`top` 5、`bot` 5、中置 `door` 2；20 有向 + 2 仅到达
  （`ch4_entry/shortcut_arrival`、`ch4_boss/left1`）。
- 单向/条件门：`ch4_elite/right1` → `ch4_boss/left1`（Boss 单向，到达门无返回
  过渡）；`ch4_hub/shortcut`（door，`requires = ["ch4_shortcut"]`，单向回入口，
  自动生成 `MDSGateBarrier`，默认封闭）。两者均只读核查，未改语义。

### 逐门核验结果（22/22 通过，无产品缺陷）

| 区 | 门 | side | 类型 | 门底落面 `floor_offset` | 标题 |
|---|---|---|---|---|---|
| `ch4_entry` | `right1` | right | 有向 | 90（地面 1424） | 前往 笑面剧场 · 笑面回廊 |
| `ch4_entry` | `bot1` | bot | 有向 | 0（地面舱口 1424） | 前往 笑面剧场 · 空座中庭 |
| `ch4_entry` | `shortcut_arrival` | door | 仅到达 | 16（台阶面 1344） | 来路 |
| `ch4_branch_a` | `left1` | left | 有向 | 90 | 前往 笑面剧场 · 剧场前厅 |
| `ch4_branch_a` | `bot1` | bot | 有向 | 0 | 前往 笑面剧场 · 熄灯的后台 |
| `ch4_branch_b` | `top1` | top | 有向 | —（天花板舱口，房间顶 8） | 前往 笑面剧场 · 剧场前厅 |
| `ch4_branch_b` | `right1` | right | 有向 | 90 | 前往 笑面剧场 · 熄灯的后台 |
| `ch4_branch_b` | `bot1` | bot | 有向 | 0 | 前往 笑面剧场 · 隐藏书库 |
| `ch4_hub` | `top1` | top | 有向 | — | 前往 笑面剧场 · 笑面回廊 |
| `ch4_hub` | `left1` | left | 有向 | 90 | 前往 笑面剧场 · 空座中庭 |
| `ch4_hub` | `bot1` | bot | 有向 | 0 | 前往 笑面剧场 · 舞台侧廊 |
| `ch4_hub` | `right1` | right | 有向 | 90 | 前往 笑面剧场 · 第四页之幕 |
| `ch4_hub` | `shortcut` | door | 有向（单向/条件） | 90 | 前往 笑面剧场 · 剧场前厅 |
| `ch4_well` | `top1` | top | 有向 | —（房间顶 8；标题夹到 x=0） | 前往 笑面剧场 · 熄灯的后台 |
| `ch4_well` | `right1` | right | 有向 | 90 | 前往 笑面剧场 · 血幕书库 |
| `ch4_vault` | `top1` | top | 有向 | — | 前往 笑面剧场 · 空座中庭 |
| `ch4_event` | `left1` | left | 有向 | 90 | 前往 笑面剧场 · 熄灯的后台 |
| `ch4_event` | `bot1` | bot | 有向 | 0 | 前往 笑面剧场 · 血幕书库 |
| `ch4_elite` | `left1` | left | 有向 | 90 | 前往 笑面剧场 · 舞台侧廊 |
| `ch4_elite` | `top1` | top | 有向 | — | 前往 笑面剧场 · 第四页之幕 |
| `ch4_elite` | `right1` | right | 有向 | 90 | 前往 笑面剧场 · 最后的舞台 |
| `ch4_boss` | `left1` | left | 仅到达 | 90 | 来路 |

> top 舱口的 `marker.floor_offset` 会按门下方地面算出一个大值（1440 房为 1416、
> 2160 房为 2136），但舱口绘制与标题不使用它；表中以「—」表示「无落地门扉」。

每一门同时核验：`GateVisual` 存在且可见、`marker.position == Vector2.ZERO`
（不移动门）、`marker.side` 与世界文件一致、门扉/舱口矩形落在房间内、标题非空
且 `caption_rect ⊆ room_bounds`、有向门 `arrival == false`、仅到达门
`arrival == true` 且文案为「来路」、视觉节点是纯 `Node2D` 且无碰撞。

标题内收：第 49 程的 `caption_area` 夹取已覆盖第 4 章同类门位——
`ch4_well/top1`（x=80）的 200 px 标题框被夹到房间内 x=0，未复现第 3 章当年的
20 px 越界。**本程未发现任何产品缺陷，`scripts/` / `scenes/` / `resources/`
零改动。**

### 新增断言（`tests/integration_ch4_bigmap.gd`）

在既有第 49 程口径之上补三类此前只间接覆盖的边界：

1. **侧门向房间内展开**：left/right 门扉的墙侧边缘必须正好落在门位 x 上
   （right 门 `door_rect.end.x == gate.x`，left 门 `door_rect.position.x == gate.x`），
   配合既有「门扉矩形在房间内」形成完整约束。
2. **舱口两轴不越界**：top/bot 横置后 96×48 的舱口矩形必须被
   `room_bounds.encloses()`（既有断言只查了竖向），横向也纳入。
3. **世界文件侧交叉校验**：从 `MDSWorld` 现算 9 区 22 门的 side 直方图必须与
   运行时一致；有向门 20、仅到达门恰为 `ch4_entry/shortcut_arrival` 与
   `ch4_boss/left1`。

第 4 章集成 **4869 → 5004 断言 / 0 失败**（逐门断言随每次区域到达重跑，
+135）。第 2/3 章门视觉断言未改，复跑 2209 / 4235 均 0 失败。

## 任务 2 · 地图标题复核（只复核，未改规则）

- 第 38 程的 `CampaignData.chapter(i)["region"]` 派生规则未动；第 4 章标题为
  「笑面剧场地图」，第 1 章冻结「档案馆地图」。
- 既有断言已覆盖，未重复造断言：
  - `tests/integration_ch4_bigmap.gd` 的 `chapter_4_map_title` 在真实第 4 章
    挂载下读 `MapOverlay.title_text()`；
  - `tests/test_map_overlay.gd` 的 `map_title_chapter_1_unchanged`（「档案馆地图」
    一字不改）、`map_title_chapter_4_region`（「笑面剧场地图」）、
    `map_title_uses_authored_region`（region + 地图）。
- 本程复跑全部通过，复核成立；未改 `MapOverlay`、未新造章节名、未碰 HUD。

## 任务 3 · 敌人美术核查（只核查/锁定，不新绘）

审计集合由 `ROOM_WAVES[3]` 现算（不是凭记忆）：

- **7 种**：`mask_enemy`、`seat_husk`、`choir_summoner`、`page_swarm`、
  `mirror_sniper`、`typo_beast`、`ink_bomber`。全部有专属 PNG
  `assets/sprites/enemies/<id>.png`、已在 `ENEMY_ART`、不在
  `ENEMY_ART_FALLBACK`、实际渲染 `Color.WHITE`（无回退 tint）。缺失清单为空。
- **变体关系**（实测）：
  - `mask_enemy` 复用 `hanging_scribe.tscn` 与 `hanging_scribe.tres`，
    但贴图是自己的 `mask_enemy.png`；
  - `seat_husk` 复用 `collapse_husk.tscn` 与 `collapse_husk.tres`，
    贴图是自己的 `seat_husk.png`。`collapse_husk` 本身走第 1 章回退
    （→ `blank_man`），所以 `seat_husk` 的对照是 `blank_man` 的画，非
    `collapse_husk`。
- **与「8 种」记录的对账**：第 50/59 程的 8 种 = `ROOM_WAVES[3]` 的 7 种 +
  旧第 4 章 `CampaignData.chapters[3].rooms` 里额外出现的 `echo_enemy`。后者
  已有第 1 章专属美术、由 CH1/CH3 清单锁定，`ROOM_WAVES[3]` 本身不含它。
- **测试**：
  - `tests/test_enemy_art.gd` **200 → 298 断言**（+98）：7 敌逐一核对场景/数据/
    唯一美术来源/专属 PNG/白 tint；变体复用基础场景但拥有独立贴图；审计集合由
    `ROOM_WAVES[3]` 现算，未来波次引入未审计敌人会失败；缺失清单保持为空。
  - `tests/integration_ch4_bigmap.gd`：六波在真实区域逐个断言实际生成的敌人
    使用计划波次的专属 PNG 且 `modulate == Color.WHITE`（原先只显式查了
    `ch4_branch_a` 的 4 只，现覆盖全部六波）。
- 未新增/修改任何敌人贴图或场景美术；第 1/2/3 章敌人美术与波次未改。

## 测试与提交

- 单元 **12755 / 0**（12657 + 98）；第 4 章大图集成 **5004 / 0**（4869 + 135）；
  其余十套集成与基线一致全 0 失败；`--headless --import` / `--quit` 退出 0、
  `ERROR` 0；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。
- 提交：`65e815a` `test: audit chapter 4 gate visuals and enemy art`（两份测试）；
  文档提交记录本 session、状态文件、记忆索引与门视觉 ADR 补充。

## 下一程候选（只记录，本程不施工）

第 60 程样图发现的表现问题转为下一程打磨候选：① 底部 HUD 遮挡（第 13 项，
三章都受影响）；② 1536×864 背景纵向平铺接缝（`ch4_boss` 顶部黑带最明显）；
③ `boss_background`（`spore_drift` / `deep_water` / `blood_moon`）被
`MDSBigRoom` 静态背景 `z_index=-20` 遮住（动画层 `-110`）；④ 无 `Arena` 的
入口/枢纽区套用 `RestRoomData` 休整文案与目标；⑤ 纵井电梯贴房间左缘、相机
夹取后只露一条横线；⑥ Boss 脚部被底部 HUD 压住（同①）；⑦
`breathing_ruins.png` 与第 1 章色调接近。其中①⑥ 属待确认第 13 项、③与第 15
项相关，拍板前仍不施工、不定口径；②④⑤⑦ 也要等监工排期。

## 不变项与边界

- `scripts/` / `scenes/` / `resources/` 零改动；门位、模式、单向语义
  （`ch4_elite/right1` 不可返回）、`requires`/`MDSGateBarrier`
  （`ch4_hub/shortcut` 默认封闭）、过渡目标一字未改。
- `CHAPTER_PLAN_PATHS[3]` 仍空、`MDS_WORLD_FILES[3]` 仍指旧世界、旧第 4 章
  9 房/17 门世界仍在；第 2/3/4 章仍不可达，第 4 章未接入 `game.gd`。
- 未修第 60 程样图问题；未做 Boss 4 机制扩展、舞台母题呈现层、
  `ch4_shortcut` 授予、战斗密度、`mask_enemy`/`seat_husk` 独立数值、阿砚同行；
  未碰待确认第 11–16 项（只记录现状，不新增条目、不定口径）。
- 未新增移动能力、未改 NPC 立绘、未改 MDS 插件、未新绘美术；未做打包导出/
  安装器/签名/安卓/触屏。
