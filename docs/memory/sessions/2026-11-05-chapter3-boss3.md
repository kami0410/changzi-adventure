# 2026-11-05 第 45 程：第 3 章 Boss 3「最后的读者」机制与 `boss_scene` 路由

## 目标

参照第 35 程对第 2 章 Boss 2 的做法，给第 3 章 Boss 3 接上独特机制与计划
`boss_scene` 路由，并在测试层验证路由、数值、阶段行为与生成位置。只做机制与
测试层：第 3 章仍不可达、计划仍不接入 `game.gd`、章末收口与大图验收留给后续程。

## 先核查（事实以仓库为准）

- 第 39 程记录的 Boss 3 现状全部属实：`scripts/bosses/last_reader.gd`
  （`LastReader extends InkArchivist`）与 `scenes/bosses/last_reader.tscn` 已存在；
  脚本已有镜面三连弹（`_mirror_fan`）与「读页」封印短语（`_read_page`），
  阶段 1 纸页波、阶段 2 每 3 次读页、阶段 3 改写/读页/镜面/墨雨轮换。
- `CampaignData.chapter(2)`：名「最后的读者」、HP 380 / 伤害 15 / 速度 78、
  `boss_script = &"reader"`、立绘 `last_reader.png`、白 tint；**没有** `boss_scene`。
- 第 3 章计划 `chapter_3_demo.tres` 此前没有 `boss_scene`，Boss 区只留占位备注；
  `game._spawn_boss` 的兜底 `boss_script == "reader"` 仍会选同一个场景。
- 第 42 程已补入场 8 条、阶段 2/3 各 8 条文案；剧情圣经第三章只给
  「镜面弹幕和『读页』封印昌子的短语」与空白最后一页的定性描述，没有攻击数值。
- 本程未改 HP / 伤害 / 速度 / 立绘 / `boss_script`，只在其上扩展机制与路由。

## 机制与暂定口径

沿用第 35 程的复用方式：独特机制放在 Boss 场景子类，通用 Boss 流程
（生成、血条、阶段横幅、权柄、outro/结束）全部复用，不另起 Boss 框架。

- **镜面弹幕**：以玩家方向为轴的对称扇形。阶段 1/2/3 = **3 / 5 / 7** 枚，
  张角 **0.28 / 0.40 / 0.52 rad**，每枚 **0.7×** 攻击力、速度 **270**。
- **读页**：阶段 2 起每第 3 次攻击；`InkWarning`（**0.8×** 攻击力）标记玩家
  位置，并封印一个短语槽 **3.0 s**，槽位随攻击计数交替。阶段 3 每 4 拍轮到一次。
- **空白页**：阶段 3 起周期 **11 s**——空白页展开 **4.5 s**（承伤 **×1.5**）、
  合书 **6.5 s**（承伤 **×0.6**）；进入阶段 3 时先展开。sprite tint 暖白/冷灰蓝
  提示窗口。阶段 1–2 承伤 **×1.0**。
- 攻击轮换：阶段 1 纸页波/镜面弹幕交替；阶段 2 加入读页，其余节拍在纸页波与
  镜面弹幕间交替；阶段 3 沿用既有四拍（改写/读页/镜面/墨雨）。
- **数值口径**：剧情圣经没有攻击数值，以上是本程采用的**暂定口径**，由
  `tests/test_ch3_boss.gd` 锁定；后续试玩校准必须同步改测试并在状态文件登记。

## 路由与不变项

- `chapter_3_demo.tres` 的 `boss_scene` 指向 `res://scenes/bosses/last_reader.tscn`。
- `_spawn_boss` 优先级不变：战役表 `boss_scene`（第 1 章）→ 计划 `boss_scene`
  → `boss_script == "smiling"` → `boss_script == "reader"` 兜底。第 3 章战役表
  仍不写 `boss_scene`，`boss_script` 仍为 `"reader"`，旧世界/无计划时仍兜底到
  同一场景。第 1/2 章 Boss 与流程未改。
- 大图生成高度沿用第 35 程的 `_enemy_spawn_y()`：任意 `big_map` 计划返回
  `-ENEMY_FOOT_Y - 2`（-18 px），第 3 章计划挂上后自动生效；本程不改函数，
  只补断言。
- 第 3 章仍不可达：`CHAPTER_PLAN_PATHS[2]` 仍空、`game.gd` 仍走旧第 3 章
  `chapter_3.mdsworld.json` 与 9 个 `MDSChapterRoom`；第 3 章章末仍会自动进
  第 4 章（章末收口是后续单独一程，本程不碰）。
- 第 3 章计划波次表/权柄池/事件数据/大区世界未改；旧第 3 章 9 房/17 门/世界
  场景仍在。第 1 章 Boss/流程/9 房间/6 波次/事件/清房目标 6 不变；第 2 章计划/
  波次表/大区世界/事件触发/权柄池/Boss 2 机制与文案不变。

## 改动

- `scripts/bosses/last_reader.gd`：新增镜面弹幕按阶段扩扇、读页封印时长/槽位
  记录与 `phrase_sealed` 信号、阶段 3 空白页承伤窗口与 `blank_page_changed`
  信号、阶段 tint；攻击轮换接入镜面弹幕；`take_damage` 应用承伤倍率；
  死亡关闭空白页。守卫从 `is_inside_tree()` 改为 `get_parent() == null`，与
  Boss 2 的写法一致，也让单元测试可在 `SceneTree._initialize` 环境驱动。
- `resources/chapters/chapter_3_demo.tres`：新增 `last_reader.tscn` 外部资源与
  `boss_scene`，更新 Boss 区备注（`boss_script == reader` 保留为兜底）。
- `tests/test_ch3_boss.gd`（新增，90 断言）：计划路由/场景类型、Campaign 数值/
  立绘/`boss_script` 不变、镜面弹幕三阶段数量/张角/伤害、读页封印槽位/时长/
  预警、阶段轮换、空白页承伤窗口与信号、生成高度（计划 → -18 / 无计划 → 250）、
  死亡关闭空白页、第 1/2 章隔离与计划槽仍空。
- `tests/integration_playability.gd`（705 → **732**，+27）：新增
  `_test_ch3_bigmap_boss`，把第 41 程大区世界与第 3 章计划临时挂到真实主场景
  （`ch3_boss` 起始），走真实 `room_loaded` 生成：`LastReader` 由计划路由、
  数值来自战役表、生成在 `Arena` 地面线之上、阶段 2 文案用第 3 章选句键、
  空白页窗口在真实 Boss 上开合、继承的纸页波/墨雨在真实树内生成、Boss 击败后
  重载不再二次生成；测试后 `_restore_chapter_world` 恢复旧世界。
- 就地更新 `test_ch3_plan`（726 → **728**）、`test_ch3_content`（614 → **615**）、
  `test_ch3_world`（764 → **765**）的「无 `boss_scene`」期望，并保持其余不变项
  断言原样。

## 未做（按任务单）

第 3 章接入 `game.gd` / 可达性 / 章节路由 / 章末流程（第 3 章末仍自动进第 4 章）；
第 3 章大图验收套件；第 3 章门视觉专项；阿砚同行；新移动能力；NPC 立绘；
MDS 插件本体；敌人/场景美术；打包/导出/安装器/签名/安卓/触屏。待确认第
11/12/13/14/15/16 项未施工、未猜测。

## 验证（本机 Godot 4.7.stable.official.5b4e0cb0f）

- 基线（改动前，HEAD `ae22f96`）：单元 **10113 / 0**；九套集成
  **705 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209** 全 0 失败；退出泄漏
  **10/10 clean**；demo 像素资产 **36 / 0**；`--import` / `--quit` 退出 0、`ERROR` 0。
- 改动后：单元 **10207 / 0**（基线 +94：`test_ch3_boss` +90、`test_ch3_plan` +2、
  `test_ch3_content` +1、`test_ch3_world` +1）；可玩性集成 **732 / 0**（+27）；
  其余八套集成数字与基线一致、全 0 失败；`--import` / `--quit` 退出 0、`ERROR` 0；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。
