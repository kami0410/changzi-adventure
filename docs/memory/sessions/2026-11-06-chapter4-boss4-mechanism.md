# 2026-11-06 第 57 程：第 4 章 Boss 4「笑面史官」机制与 `boss_scene` 路由

## 目标

按第 50 程核查 D 节第 4 项的既定口径，给第 4 章 Boss 4「笑面史官」接上计划
`boss_scene` 路由，并用专项测试锁定既有机制（镜面弹幕、纸页波、墨雨、改写）、
数值、阶段映射与大图生成高度。只做机制与测试层：第 4 章仍不可达、计划仍不接入
`game.gd`、世界仍不被 `game.gd` 引用；不扩展机制（删除词/复制武器/舞台机关）、
不做章末收口与大图验收。

## 先核查（事实以仓库为准）

- `scripts/bosses/smiling_archivist.gd`（`SmilingArchivist extends InkArchivist`）与
  `scenes/bosses/smiling_archivist.tscn` 已存在；第 50 程记录的机制属实：
  - 阶段 1：纸页波；
  - 阶段 2：每第 3 次攻击为镜面弹幕，其余纸页波；
  - 阶段 3：四拍轮换 `%4` = 改写 / 镜面弹幕 / 墨雨 / 纸页波；
  - 镜面弹幕 = 3 枚、张角 ±0.34 rad、每枚 `int(攻击力 × 0.7)`、速度 280；
  - 纸页波、墨雨、改写全部继承自 `InkArchivist`（阶段 ≥2 纸页波双发；墨雨
    3 个 `InkWarning`、`int(攻击力 × 0.75)`；改写封印一个短语槽 3.0 s）。
- `CampaignData.chapter(3)`：名「笑面史官」、HP 520 / 伤害 18 / 速度 92、
  `boss_script = &"smiling"`、立绘 `smiling_archivist.png`、白 tint；**没有**
  `boss_scene`。
- 第 4 章计划 `chapter_4_demo.tres` 此前没有 `boss_scene`，Boss 区只留占位备注。
- `game._spawn_boss` 优先级：战役表 `boss_scene`（第 1 章）→ 计划 `boss_scene`
  （第 2/3 章及本程第 4 章）→ `boss_script == "smiling"` → `boss_script ==
  "reader"` → 默认；本轮只给计划补字段，优先级与兜底未改。
- 大图生成高度：`_enemy_spawn_y()` 在 `_chapter_plan != null and big_map` 时返回
  `-ENEMY_FOOT_Y - 2`（-18 px），否则 250 px；函数未改，只补断言。
- 第 53 程已补 `BossEntranceData` 8 条入场 + `BossPhaseData` 阶段 2/3 各 8 条，
  选句键为 `"%d:%d:%d"`（含章节索引），第 4 章不回落第 1/2/3 章。

## 路由与不变项

- `resources/chapters/chapter_4_demo.tres` 新增
  `[ext_resource type="PackedScene" path="res://scenes/bosses/smiling_archivist.tscn"]`
  并写 `boss_scene = ExtResource("5_smiling")`；Boss 区备注同步改为「已路由 +
  入场/阶段文案已编写 + 机制扩展仍待拍板」。
- 通用 Boss 流程（生成/血条/阶段横幅/权柄/outro/结束）全部复用，未另起框架。
- 数值与立绘未改：HP 520 / 伤害 18 / 速度 92 / `smiling_archivist.png` /
  `boss_script = smiling`；镜面弹幕与墨雨的既有数值未改。以上为**暂定口径**，
  由 `tests/test_ch4_boss.gd` + 可玩性集成锁定；后续试玩校准须同步改测试并登记。
- 第 4 章仍不可达：`CHAPTER_PLAN_PATHS[3]` 仍空、`MDS_WORLD_FILES[3]` 仍指旧
  `chapter_4.mdsworld.json`、旧第 4 章 9 房/17 门世界仍在；计划清房目标 7、
  7 个遭遇、波次表（`content_pending = false`）、基础权柄池不变；事件触发口径
  不变；`game.gd` 仍无 `chapter_4_bigmap` / `ch4_shortcut` 引用。
- 第 1/2/3 章 Boss 场景与计划 `boss_scene` 未改；`_complete_chapter` 与章节路由
  未改（第 4 章章末收口是下一程的事）。

## 机制锁定（由测试固定）

| 阶段 | 攻击轮换 | 说明 |
|---|---|---|
| 1 | 纸页波 | 单发，伤害 = 攻击力 |
| 2 | 纸页波 ×2 → 镜面弹幕 | 每第 3 次为镜面弹幕；纸页波阶段 ≥2 双发 |
| 3 | 镜面弹幕 → 墨雨 → 纸页波 → 改写 | `%4` 轮换；改写固定封 0 号槽 |

- 镜面弹幕：3 枚、±0.34 rad、`int(18 × 0.7) = 12`、速度 280。
- 墨雨：3 个 `InkWarning`、`int(18 × 0.75) = 13`。
- 改写：封印 0 号短语槽 3.0 s（阶段 3 的改写落在 4 的倍数拍，恒为偶数槽）。
- 单元层限制：`test_ch4_boss` 在 `_initialize` 同步运行，节点尚未进入
  SceneTree，而 `SmilingArchivist._mirror_fan` / `_ink_rain` 有 `is_inside_tree()`
  前置。因此单元层用记录型子类锁完整节拍表、用真实脚本锁纸页波伤害与改写，
  镜面弹幕/墨雨的生成物数量、伤害与速度在 `integration_playability` 的真实树
  里锁定（3 枚 / 12 / 280；3 个预警 / 13）。

## 改动

- `resources/chapters/chapter_4_demo.tres`：`boss_scene` 指向
  `smiling_archivist.tscn`；Boss 区备注更新。
- `tests/fixtures/big_room/ch4_graph.mdsworld.json`：仅更新夹具备注（Boss 4
  已路由、机制扩展仍缺；事件触发已生效）。
- `tests/test_ch4_boss.gd`（新增，78 断言）：计划路由、场景类型、战役表数值/
  立绘/`boss_script` 未改、节拍表、纸页波伤害、改写槽位/时长、大图生成高度、
  第 4 章选句键不回落、第 1/2/3 章隔离、计划槽/旧世界/清房目标/波次/权柄池锁。
- `tests/test_ch4_plan.gd`（795 → 797）、`tests/test_ch4_world.gd`（813 → 814）、
  `tests/test_ch4_content.gd`（642 → 644）：把「计划无 `boss_scene`」的旧期望
  改为「已路由且指向 `smiling_archivist.tscn`」。
- `tests/integration_playability.gd`：新增 `_test_ch4_bigmap_boss`（真实第 4 章
  大区世界 + 计划临时挂载，`ch4_boss` 起始）：计划路由 `SmilingArchivist`、
  数值来自战役表、生成在 `Arena` 地面线之上、阶段 2/3 横幅使用第 4 章选句键、
  实树镜面弹幕/墨雨/改写生效、击败 → 权柄 → 章末选择 → 战役结束、重载不二次
  生成；测试后恢复旧第 4 章世界。可玩性集成 810 → **869**（+59）。

## 未做 / 边界

- 未开放第 2/3/4 章可达性；未把第 4 章计划或世界接入 `game.gd`；未改章节路由、
  章末流程与 `_complete_chapter`（第 4 章章末收口排下一程）。
- 未做 Boss 4 机制扩展（剧情圣经的「删除词/复制昌子的武器」、GDD 的「舞台
  机关」），未新增任何攻击手段；差距只记录在状态文件。
- 未新增 `ch4_shortcut` 授予（屏障仍默认封闭）；未扩波/增遭遇（旧世界每房 5–6
  只 vs 大图每遭遇 2 只只记录）；`mask_enemy`/`seat_husk` 独立数值未做；舞台
  母题呈现层未改；阿砚同行未做；待确认第 11–16 项未碰。

## 验证（本机 Godot 4.7.stable）

- 单元 **12657 / 0**（基线 12574 + 83：新增 `test_ch4_boss` 78 + 三个既有第 4 章
  套件净 +5）。
- 可玩性集成 **869 / 0**（基线 810 + 59）。
- 其余九套集成与基线一致、全 0 失败；`--headless --import` / `--quit` 退出 0、
  `ERROR` 0；退出泄漏 10/10 clean；demo 像素资产 36 / 0。
