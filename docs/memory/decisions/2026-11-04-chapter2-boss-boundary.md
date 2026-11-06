# 第 2 章 Boss 2 独特机制与章末边界

- 日期：2026-11-04（第 35 程）
- 状态：已实施（第 2 章仍不可达，只在测试/探针层进入）

## 背景

第 1 章 Boss 走 `CampaignData.chapters[0].boss_scene = ink_archivist_ch1.tscn`（`InkArchivistCh1 extends InkArchivist`）；`game._spawn_boss` 统一负责生成、血条、阶段横幅、权柄三选一、outro/choice 与结束屏。第 2 章此前只有 `boss_script = ink`、数值（360 HP / 14 伤害 / 75 速度）、立绘与入场/阶段文案，没有专属场景；剧情圣经只给「钟摆与肺叶组成的巨物，攻击有清晰前摇」和章末「续气 / 敲碎」抉择，没有攻击数值或阶段机制表。

## 决定

### 1. 独特机制放在 Boss 场景子类，由计划路由

- 新增 `scripts/bosses/lung_bell_guardian.gd`（`LungBellGuardian extends InkArchivist`）与同名 `scenes/bosses/lung_bell_guardian.tscn`。
- `chapter_2_demo.tres` 的 `boss_scene` 指向该场景；`game._spawn_boss` 原有优先级不变：战役表 `boss_scene`（第 1 章）→ 计划 `boss_scene`（第 2 章）→ 旧脚本兜底。因此第 1 章仍选 `InkArchivistCh1`，第 2 章选 `LungBellGuardian`。
- 不改 `InkArchivist` 基类、`InkArchivistCh1`、`game._spawn_boss` 的通用生成/阶段/权柄/结束流程；Boss 2 只覆写 `_process`、`check_phase`、`take_damage`、`_perform_attack` 与死亡清场。

### 2. 肺钟守卫的机制与暂定数值

剧情圣经/计划只有定性描述，以下数值是本程采用的**暂定口径**，由 `tests/test_ch2_boss.gd` 锁定；后续试玩校准必须同时改测试并在状态文件登记。

- **呼吸循环**：吸气 2.4 s（受到伤害 ×0.5）→ 呼气 1.4 s（受到伤害 ×1.5，并释放扩散气环：560 px / 720 px/s / 0.8× 攻击力）。阶段 2 起呼气额外在玩家位置留下墨池（0.35×、70 px、4 s）；阶段越高节奏越快（0.7× 下限）。用 sprite tint + 气环给清晰前摇。
- **钟摆**：基础攻击为正反两枚 `HostileBolt`（前方 0.7×、后方 0.75×），读作钟摆横扫；阶段 2 起每第 3 次改为钟鸣环（620 px / 760 px/s / 0.9×）；气弹 `InkBomb`（0.8×，留池）。
- **钉子**：阶段 3 起周期性暴露（暴露 5 s，受到伤害 ×1.5；闭合 7 s，受到伤害 ×0.6；周期 12 s），作为阶段 3 的输出窗口。阶段 1–2 仍按呼吸承伤。
- 理由：呼吸对应「肺叶 / 每响一次呼出记忆」，钟摆对应「钟摆与肺叶」，钉子对应阿砚「给肺钟打过一颗钉子」的剧情；三者在同一套清晰前摇下读得出来。

### 3. 第 2 章结束语义

- `_complete_chapter` 在章末选择结算后，对 `_chapter == 1` 调用现有 `_finish(true)`，停在第 2 章结束屏，不再 `_start_chapter(2)` 进入未实现的第 3 章。
- 第 1 章分支（`_chapter == 0`：`demo_cleared` + `_finish(true)`）一字未改；第 3/4 章保留原有自动续章，避免破坏既有结构测试覆盖。
  - 2026-11-05 更新（第 46 程）：第 3 章也已在章末收口（`_chapter == 2` → `_finish(true)`），见 [第 3 章章末收口](2026-11-05-chapter3-ending.md)；本句「第 3/4 章保留原有自动续章」现在只对第 4 章成立。
- **采用口径（歧义已记录）**：第 2 章末沿用现有结束屏与结局记录（默认 `unfinished`），不新增「待续」UI、结局 id 或存档键。第 2 章仍不可达，当前只由测试/探针验证。若未来开放第 2 章 demo，需要决定是否改为章节完成屏，避免提前解锁结局画廊。

### 4. 大图生成高度修正

- 大区 `ArenaRoom` 的原点位于可走地面（`BigRoomData` 表面），旧 `_spawn_group` / `_spawn_boss` 固定 +250 px 生成会把第 2 章敌人/Boss 埋到地下。
- `game.gd` 新增 `_enemy_spawn_y()`：`big_map` 计划生成在 `-ENEMY_FOOT_Y - 2`，第 1 章/第 3–4 章仍 250 px。只影响大图分支，第 1 章生成路径与波次不变。

## 后果

- 第 2 章 Boss 区有专属机制与场景，通用 Boss 流程（血条、阶段横幅、权柄池、outro/choice、存档）全部复用。
- 第 1 章 Boss 场景、数值、阶段、权柄与结束流程无回归；第 2 章仍不可达（第一章章末不进入第 2 章）。
- 新增测试：`tests/test_ch2_boss.gd`、`tests/integration_playability.gd` 第 2 章 Boss/章末段、`tests/integration_run_save.gd` 第 2 章边界段、`tests/test_ch2_plan.gd` 计划路由断言。

## 红线

不改 MDS 插件、言灵/权柄/战斗框架、敌人美术、NPC 立绘、存档键与格式；不新增移动能力；不开放第 2 章可达性；不删旧世界/旧场景；不做打包/导出/安装器/签名/安卓/触屏。
