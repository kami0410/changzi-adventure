# 2026-11-04 第 33 程：第 2 章内容数据层第 2 步——波次接线

## 目标

把第 2 章计划里的 6 场战斗遭遇接到既有六波敌人上，让大区 `Arena` 能按遭遇节点 id 生成敌人；只接线，不做 Boss 机制、不开放章节。

## 改动

- `resources/chapters/chapter_2_demo.tres`：4 个战斗区（`ch2_branch_a`、`ch2_branch_b`、`ch2_well`、`ch2_elite`）补 `wave` 字典，共 6 个键（遭遇节点 id）。事件区、Boss 区、入口/枢纽/书库不带 `wave`。
- `scripts/data/chapter_plan_data.gd`：
  - `wave_for(room_id, encounter_id := "")`：大图字典按节点 id 查；线性计划（第 1 章）仍返回房间级数组。
  - `validate_waves()`：大图计划的波次表校验（键锚定遭遇、值非空、战斗遭遇必有一波、事件遭遇不得有波）；接入 `validate()`，第 1 章计划跳过。
- `scripts/game.gd`：
  - `_plan_wave(room_id, encounter_id)` 包装计划查询。
  - `_on_mds_room_loaded` 新增 `big_map` 分支：每个未清战斗遭遇按自己的 `wave` 生成并登记到 `_rooms`；事件区/Boss 区不消耗普通波次；一区多遭遇各自锁门、清怪、奖励、进度（沿用第 27 程节点 id 语义）。第 1 章原分支与 `ROOM_WAVES` 路径未改。
- 测试：
  - 新增 `tests/test_ch2_waves.gd`（67 断言）：六场战斗与 `ROOM_WAVES[1]` 按计划顺序一一对应、事件无波、Boss 无普通波、键唯一且锚定、`wave_for` 的大图/线性行为、七类坏波次表校验、第 1 章计划不变。
  - `tests/test_ch2_content.gd` 扩到 508（+19）：同一映射与波次表校验。
  - `tests/integration_playability.gd` 扩到 636（+35）：逐区检查每个战斗 Arena 的生成数量/敌人种类与计划波次一致、事件 Arena 为空且不登记、Boss 区无普通波；支路 A 第二场遭遇单独锁门（第一场不重锁）；清完 7 场后重载支路 A，两个 Arena 都不再生成、也不登记。

## 口径与歧义

- 事件节点在扁平遭遇列表里位于第 5、6 场战斗之间；「计划顺序」按过滤事件后的六场战斗计。测试锁定该口径。
- 六波沿用 `ROOM_WAVES[1]` 原文，包含 `ink_bomber`/`blank_man`/`page_swarm` 等第 1 章也在用的敌人 id；本程不改波次内容。
- 大图 `wave` 是「遭遇节点 id → 敌人数组」的字典；第 1 章仍是房间级数组。见 ADR `docs/memory/decisions/2026-11-04-chapter2-wave-wiring.md`。

## 验证（本机 Godot 4.7.stable.official.5b4e0cb0f）

- 基线（改动前）：单元 7733/0；八套集成 601/102/588/207/113/59/391/45 全 0 失败；退出泄漏 10/10；像素资产 36/0；`--import`/`--quit` 退出 0、ERROR 0。
- 改动后：单元 **7819/0**（+86）；结构/可玩性 **636/0**（+35）、第一章 demo **102/0**、run save **588/0**、手柄 **207/0**、UI 提示 **113/0**、第一章事件 **59/0**、菜单 A/B **391/0**、AI 设置 **45/0**；退出泄漏 **10/10**；像素资产 **36/0**；`--import`/`--quit` 退出 0、ERROR 0。

## 未做（按任务单）

Boss 2 独特机制与专属攻击；第 2 章事件区真实自动触发；章节过渡；第 2 章可达性；新敌人/美术；移动能力；MDS 插件、言灵/权柄/战斗框架；打包/签名/安卓。
