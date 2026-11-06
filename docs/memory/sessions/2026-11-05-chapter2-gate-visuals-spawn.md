# 2026-11-05 第 37 程：第 2 章自动门视觉与新局出生点

## 背景

第 36 程验收记录了两个表现缺口：世界 JSON 自动生成的 `MDSGate` 只有触发区、没有门扉/提示视觉；第 2 章新局出生点落在房间标签下方的空中，落到台阶后才稳定。两项都不涉及门/战斗逻辑，属于表现层与出生坐标。本程只修这两项，不开放第 2 章可达性，不改第 1 章内容/出生流程，不改 MDS 插件。

## 任务 1 · 自动门视觉

### 做法

- 新增 `scripts/presentation/gate_visual.gd`（`class_name GateVisual`）：复用既有手动门 `ChapterDoor` 的视觉语言——同一 `assets/sprites/props/door.png`、同一 accent 边框（`#69e0d2`）、上浮墨尘、HUD theme 12 px 描边标题；不新增贴图、不引入第二种门风格。
- `MDSBigRoom` 新增 `GATE_VISUAL_NAME = "GateVisual"` 与 `_add_gate_visuals()`：`_build_gates()` 生成完自动门后，给当前房间**所有** `MDSGate`（自动门 + 作者门）挂一个视觉子节点；`auto_gates = false` 时只做视觉补全；作者场景可用同名节点覆盖。
- side 感知：left/right 为立门，门宽向房间内展开、门底按门下方最近的 `built_ground_surfaces` / `built_platform_surfaces` 对齐（台阶 16 px、地面 90 px，不再写死）；top/bot 把同一贴图横置成天花板/地面舱口，保持在房间矩形内。
- 提示：有去向的门标「前往 <目标区名>」并画朝向箭头；无去向的到达门（`ch2_entry/shortcut_arrival`、`ch2_boss/left1`）标「来路」、不画箭头。贴边的门标题向房间内对齐，避免被房间边界裁切。
- 纯 `Node2D` 子节点：`z_index = -1`（在角色与 `MDSGateBarrier` 之后、背景/氛围之前），无碰撞、无信号、无输入；门位、模式、单向语义、`requires`/`MDSGateBarrier` 判定、过渡目标一律未动。

### 验收

- `tests/test_big_room.gd` 新增 `_test_gate_visuals`（+28 断言）：z、标题文本/位置、side 分支、arrival 文案、零碰撞、节点类型、`GATE_VISUAL_NAME`、门底落面计算；并断言第 1 章 9 个场景 `GateVisual` 数量为 0。
- `tests/integration_ch2_bigmap.gd` 新增逐门视觉验收：九区每一扇世界门都有可见 `GateVisual`、side 一致、caption 非空且与目标区名/来路一致、无 `CollisionObject2D`；记录 `gate_visual_regions`，收尾断言 **9 区、22 扇门视觉**（20 连通 + 2 到达）。
- 用 `xvfb-run` + OpenGL 离屏截图做了外观 QA（侧门+箭头+标题、入口到达门、天花板舱口；截图在 `/tmp/ch2_gate_caps/`，未提交）。QA 中发现大区相机限制 = 房间边界时，角色站在区底会被底部 HUD 面板遮住一部分；属相机取景/HUD 安全区的既有问题，超出本程范围，只记录为待确认第 13 项。

## 任务 2 · 第 2 章新局出生点

### 根因

`MDSWorldGame._spawn_position()` 的优先级是：到达门 → 显式世界坐标 → 房间内 `save_point`/`bench` → `MDSWorld.get_room_label_pos()`。最后这个回退返回**房间最大矩形的中心**，是给地图标签用的锚点；`ch2_entry` 是 2560×1440，锚点 (1280, 720)，比第一级台阶面（y = 1344）高 624 px。地面碰撞与落地判定没有问题，错的是出生坐标。第 1 章房间有程序化 `SavePoint`，所以从未暴露。

### 修复

- `scenes/mds/ch2_bigmap/ch2_entry.tscn` 作者一个 `Marker2D`：`SpawnPoint`，组 `save_point`，位置 `(400, 1328)` = 第一级台阶面 1344 − `Player.FOOT_Y` 16。
- 走 MDS 既有优先级选中该标记；不改 MDS 出生回退顺序，不改第 1 章出生/Hub 流程。经门进入 `ch2_entry` 仍用门落点，不受影响。

### 验收

- `tests/test_ch2_world.gd`：`ch2_entry` 的 `SpawnPoint` 存在、属于 `save_point` 组、`y == platforms[0].y - Player.FOOT_Y`。
- `tests/integration_ch2_bigmap.gd` 第 2 章启动后断言：`SpawnPoint` 存在/组正确/脚底 = 台阶面；玩家在标记处；`_spawn_position("ch2_entry", "", Vector2.INF)` 命中标记；标记比房间标签锚点低 400+ px；第一物理帧 `is_on_floor()`；0.3 秒内位置不漂移。
- 探针实测（已删除）：第一帧起 `pos=(400,1328)`、`vel=(0,0)`、`floor=true`，0.8 秒内不动。

## 测试与验证

- 基线（HEAD `959c90d`）：单元 **7873 / 0**；九套集成 **665 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 1303** 全 0 失败；退出泄漏 **10/10**；像素资产 **36 / 0**；`--headless --import` / `--quit` 退出 0、`ERROR` 0。与交接一致，无漂移。
- 改动后：单元 **7901 / 0**（+28）；八套既有集成 **665 / 102 / 613 / 207 / 113 / 59 / 391 / 45** 不变、第 2 章大地图 **2202 / 0**（+899）；退出泄漏 **10/10**；像素 **36 / 0**；`--import`/`--quit` 退出 0、`ERROR` 0。
- 第 1 章 9 个 `MDSChapterRoom`、6 波次、事件房、清房目标 6、Boss 与结束流程未改；第 2 章仍不可达（只在测试/探针层驱动）。

## 未做

第 2 章可达性（待确认第 11 项未定）；待确认第 11/12 项本身；阿砚同行、敌人专属美术、第 2 章地图标题；新增移动能力；NPC 立绘；MDS 插件（本程零改动）；打包/导出/安装器/签名/安卓/触屏。临时探针与截图均已删除/未提交，工作区干净。
