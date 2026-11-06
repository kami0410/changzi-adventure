# 第 3 章 Boss 3「最后的读者」机制与计划路由

- 日期：2026-11-05（第 45 程）
- 状态：已实施（第 3 章仍不可达，只在测试/探针层进入）

## 背景

- 第 39 程核查：`scripts/bosses/last_reader.gd`（`LastReader extends InkArchivist`）
  与 `scenes/bosses/last_reader.tscn` 已存在，已有镜面三连弹与「读页」封印短语；
  第 3 章计划当时没有 `boss_scene`，`game._spawn_boss` 靠 `boss_script == "reader"`
  兜底路由到该场景。第 42 程已补第 3 章入场 8 条与阶段 2/3 各 8 条文案；
  Boss 数值 380 HP / 15 伤害 / 78 速度、立绘 `last_reader.png` 与白 tint 未改。
- 剧情圣经第三章：Boss「用镜面弹幕和『读页』封印昌子的短语」；节拍为
  「最后的读者是一个孩子，他读完了所有结局」「交出空白的最后一页」「故事需要
  有人翻页」。圣经没有攻击数值或阶段机制表。
- 第 2 章 Boss 2 的先例：独特机制放 Boss 场景子类、由章节计划 `boss_scene`
  路由、通用 Boss 流程一律复用、暂定数值由测试锁定。

## 决定

### 1. 场景路由

- 继续以 `LastReader extends InkArchivist` 作为第 3 章专属场景，不另起 Boss 框架。
- `resources/chapters/chapter_3_demo.tres` 的 `boss_scene` 指向
  `res://scenes/bosses/last_reader.tscn`。
- `game._spawn_boss` 原有优先级不变：战役表 `boss_scene`（第 1 章）→ 计划
  `boss_scene`（第 3 章及第 2 章）→ `boss_script == "smiling"` →
  `boss_script == "reader"` 兜底。第 3 章战役表仍不写 `boss_scene`，`boss_script`
  仍为 `"reader"`，因此旧世界/无计划时仍可兜底到同一场景。
- 不改 `InkArchivist` 基类、`InkArchivistCh1`、`LungBellGuardian` 与通用生成/
  血条/阶段横幅/权柄/outro/结束流程。

### 2. 机制与暂定数值

剧情圣经只有定性描述，以下数值是本程采用的**暂定口径**，由
`tests/test_ch3_boss.gd` 锁定；后续试玩校准必须同步改测试并在状态文件登记。

- **镜面弹幕**：以玩家方向为轴的对称扇形。阶段 1/2/3 = **3 / 5 / 7** 枚，
  张角 **0.28 / 0.40 / 0.52 rad**，每枚 **0.7×** 攻击力、速度 **270**。
- **读页**：阶段 2 起每第 3 次攻击；地面 `InkWarning`（**0.8×** 攻击力）标记
  玩家位置，并封印一个短语槽 **3.0 s**，槽位随攻击计数交替（0/1）。阶段 3
  每 4 次攻击轮到一次。
- **空白页**：阶段 3 起周期 **11 s**——空白页展开 **4.5 s**（承伤 **×1.5**）、
  合书 **6.5 s**（承伤 **×0.6**）；进入阶段 3 时先展开。用 sprite tint
  （暖白 / 冷灰蓝）提示窗口。这是阶段 3 的输出窗口。
- 阶段 1–2 承伤 **×1.0**。攻击轮换：阶段 1 纸页波/镜面弹幕交替；阶段 2 加入
  读页，其余节拍在纸页波与镜面弹幕间交替；阶段 3 沿用既有四拍
  改写 / 读页 / 镜面弹幕 / 墨雨。
- 理由：镜面弹幕与读页直接来自剧情圣经的 Boss 定义；空白页来自「空白的最后
  一页」「故事翻到最后一页」的章节文案，作为阶段 3 的可读输出窗口，不新增
  剧情事实。

### 3. 大图生成高度

- 第 35 程的 `game._enemy_spawn_y()` 已对任意 `big_map` 计划返回
  `-ENEMY_FOOT_Y - 2`（-18 px），第 3 章计划挂上后自动生效。
- 本程不修改该函数，只补单元断言（计划在 → -18；无计划 → 旧 250 px）与
  真实大区集成断言（Boss 生成在 `Arena` 地面线之上）。

### 4. 章末边界（未改）

- 第 3 章 `_complete_chapter` 仍会自动续进第 4 章；章末收口（停章/章节完成屏）
  是后续单独一程的工作，本程不碰 `_complete_chapter` / `_finish` 的章节分支。

## 后果

- 第 3 章计划拥有 `boss_scene`，通用 Boss 流程全部复用；Boss 3 有可测试的
  阶段行为与数值窗口。
- **第 3 章仍不可达**：`CHAPTER_PLAN_PATHS[2]` 仍为空，`game.gd` 仍走旧
  `chapter_3.mdsworld.json` 与 9 个 `MDSChapterRoom`；old 世界与旧 17 门未改。
- 第 1 章 Boss/流程/9 房间/6 波次/事件/清房目标 6 不变；第 2 章计划/波次表/
  大区世界/事件触发/权柄池/Boss 2 机制与文案不变。
- 新增测试：`tests/test_ch3_boss.gd`（90 断言）、`tests/integration_playability.gd`
  第 3 章 Boss 段；就地更新 `test_ch3_plan` / `test_ch3_content` / `test_ch3_world`
  的「无 `boss_scene`」期望。

## 红线

不改 MDS 插件、言灵/权柄/战斗框架、敌人美术、NPC 立绘、存档键与格式；
不新增移动能力；不开放第 2–4 章可达性；不删旧世界/旧场景；不做第 3 章大图
验收/门视觉/章末收口；不做打包/导出/安装器/签名/安卓/触屏。
