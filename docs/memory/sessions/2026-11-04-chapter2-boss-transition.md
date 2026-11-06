# 2026-11-04 第 35 程：第 2 章 Boss 2 独特机制与章末收口

## 目标

实现第 2 章 Boss「肺钟守卫」的独特机制，并让第 2 章完成后停在本章末尾、不自动进入未实现的第 3 章。保持第 1 章 Boss 与结束流程不变、第 2 章仍不可达；机制与过渡只通过测试/探针验证。

## 改动

- `scripts/bosses/lung_bell_guardian.gd`（新增）：`LungBellGuardian extends InkArchivist`。
  - 呼吸循环：吸气 2.4 s（承伤 ×0.5）/ 呼气 1.4 s（承伤 ×1.5 + 气环 560 px、0.8×）；阶段 2 起呼气留墨池；阶段越高节奏越快（0.7× 下限）。
  - 钟摆：正反两枚 `HostileBolt`（0.7× / 0.75×）；阶段 2 起每第 3 次钟鸣环（620 px、0.9×）；气弹 `InkBomb`（0.8×、留池）。
  - 钉子：阶段 3 起暴露 5 s（承伤 ×1.5）→ 闭合 7 s（承伤 ×0.6），12 s 周期。
  - 死亡清空气环；sprite tint 给出呼吸/钉子状态；`_on_phase_started` 重置节奏与钉子窗口。
- `scenes/bosses/lung_bell_guardian.tscn`（新增）：与第 1 章 Boss 场景同构（`CharacterBody2D` + 碰撞 + 血条），只挂新脚本。
- `resources/chapters/chapter_2_demo.tres`：`boss_scene = lung_bell_guardian.tscn`。`game._spawn_boss` 原有优先级不变：战役表 `boss_scene`（第 1 章）→ 计划 `boss_scene`（第 2 章）→ 旧脚本兜底。
- `scripts/game.gd`：
  - `_enemy_spawn_y()`：大图 `ArenaRoom` 原点在可走地面，敌人/Boss 生成在 `-ENEMY_FOOT_Y - 2`；第 1 章/第 3–4 章仍 250 px。修复了第 2 章敌人生成在地下的真实缺陷。
  - `_complete_chapter()`：`_chapter == 1` 时在章末选择结算后调用现有 `_finish(true)`，停在第 2 章结束屏；第 1 章分支与第 3/4 章自动续章不变。
- 测试：
  - 新增 `tests/test_ch2_boss.gd`（51 断言）：计划路由/数值/场景类型；吸气承伤、呼气增伤与气环；钟摆双向、气弹留池、阶段 2 钟鸣；阶段 3 钉子窗口与重新暴露；死亡清气环；第 1 章 Boss 仍是 `InkArchivistCh1` 且没有呼吸/钉子方法。
  - `tests/integration_playability.gd` 扩到 665（+14）：第 1 章 Boss 仍是 `InkArchivistCh1`；第 2 章波次生成点在地面之上；`ch2_boss` 生成 `LungBellGuardian`、初始吸气、承伤系数、生成点在地面之上、真实呼气生成气环；第 2 章章末选择后停在 `_chapter == 1`、`_finished`、结束屏可见。
  - `tests/integration_run_save.gd` 扩到 613（+25）：第 2 章 Boss 击败 → 权柄三选一（断言授予来自第 2 章计划池）→ 存档 → 续玩不二次生成 Boss、权柄/残页/击杀不重复、outro/choice 可继续 → 选择后停在第 2 章并清档。
  - `tests/test_ch2_plan.gd`：第 2 章计划拥有 `boss_scene` 且指向新场景；第 1 章计划仍指向 `ink_archivist_ch1.tscn`。
- 文档：新增 ADR `docs/memory/decisions/2026-11-04-chapter2-boss-boundary.md`；本 session；更新 `docs/memory/MEMORY.md` 与 `SUPERVISOR_STATUS.md`。

## 口径与歧义

- **机制层归属**：独特机制放 Boss 场景子类，由第 2 章计划 `boss_scene` 路由；通用 Boss 流程（生成/血条/阶段横幅/权柄/outro/结束）一律复用。第 1 章仍由战役表 `boss_scene` 优先，计划字段只影响第 2 章。
- **数值口径**：剧情圣经/计划只有「钟摆与肺叶」「清晰前摇」「钉子」等定性描述，没有攻击数值。本程采用呼吸 2.4/1.4 s、0.5×/1.5×、钟摆双向、钟鸣 620 px、钉子 5 s 暴露/7 s 闭合等暂定值，由测试锁定；后续试玩校准要同步改测试并登记状态文件。
- **第 2 章结束**：沿用现有 `_finish(true)` 结束屏与结局记录（默认 `unfinished`），不新增「待续」UI、结局 id 或存档键。第 2 章仍不可达，当前只由测试/探针验证；若未来开放第 2 章 demo，需要决定是否改为章节完成屏、避免提前解锁结局画廊。
- **第 3/4 章**：保留原有自动续章，避免破坏既有结构测试覆盖；只有第 2 章加停止边界。

## 验证（本机 Godot 4.7.stable.official.5b4e0cb0f）

- 基线（HEAD `571b36c`，改动前）：单元 7821/0；八套集成 651/102/588/207/113/59/391/45 全 0 失败；退出泄漏 10/10；像素资产 36/0；`--import`/`--quit` 退出 0、ERROR 0。与第 34 程收尾逐项一致。
- 改动后：单元 **7873/0**（+52）；结构/可玩性 **665/0**（+14）、第一章 demo **102/0**、run save **613/0**（+25）、手柄 **207/0**、UI 提示 **113/0**、第一章事件 **59/0**、菜单 A/B **391/0**、AI 设置 **45/0**；退出泄漏 **10/10**；像素资产 **36/0**；`--import`/`--quit` 退出 0、ERROR 0。
- 第 1 章 9 个 `MDSChapterRoom`、6 场波次、事件房触发/文案/数值、Boss 场景与结束流程不变；第 2 章清房目标 7、6 场波次不变；第 2 章仍不可达。

## 未做（按任务单）

第 2 章可达性；第 3 章内容；第 1 章 Boss/战斗框架/敌人美术/NPC 立绘改动；新增移动能力；MDS 插件；言灵/权柄/战斗框架；删除旧世界/旧场景；打包/导出/安装器/签名/安卓/触屏。
