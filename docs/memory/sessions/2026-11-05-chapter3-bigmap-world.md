# 2026-11-05 · 第 3 章大地图施工第 2 步：真实大区世界（第 41 程）

> 把第 40 程的 9 区计划做成可加载的第 3 章真实大区世界与房间场景（只做结构层）。
> `game.gd` 未改，第 3 章仍走旧 `chapter_3.mdsworld.json` / 9 个
> `MDSChapterRoom` 小房间，`CHAPTER_PLAN_PATHS[2]` 仍为空，第 3 章仍不可达。
> 旧世界、旧房间场景、第 1/2 章计划与世界均未改未删。本程复用第 28/29/31/37 程
> 的既有管线，不改管线本体，不新增移动能力。

## 1. 真实大区世界与房间

- `resources/rooms/ch3_bigmap/*.tres`（9 个 `BigRoomData`）：
  - 尺寸按计划：2560×1440（入口/支路/枢纽/书库/事件）、2560×2160（纵井）、
    3840×2160（精英、Boss）。
  - 地面贴房间底边（`H-16`，16 px 厚）；平台按 80 px 阶梯链布置，全部通过
    `BigRoomData.validate()`（上升 ≤80 px、水平边缘 ≤120 px，只有最低面豁免支撑）。
  - `tile_set` 复用 `ch1_tiles.tres`；`backdrop_path` 指向既有
    `assets/backgrounds/lightless_sea.png`（绘画图，`backdrop_pixel_art = false`）；
    每区独立 `backdrop_modulate`；氛围 `motes`，密度 0.5。
- `scenes/mds/ch3_bigmap/*.tscn`（9 个 `MDSBigRoom`）：
  - 根脚本 `mds_big_room.gd`，`data` 指向对应 `.tres`，`fall_margin = 240.0`
    （房间 metadata `fall_below_bounds = 240`，与计划一致）。
  - 内容节点严格用计划 `region/Node` id，不新增 id：`ch3_branch_a` 的
    `Arena`/`Arena2`/`Chest1`、`ch3_branch_b` 的 `Arena`、`ch3_well` 的
    `Arena`/`Arena2`/`Chest1`、`ch3_elite` 的 `Arena`、`ch3_hub` 的
    `Stele1`/`Shop`(`ch3_hub_shop`)/`Bench`、`ch3_vault` 的 `Chest1`/`Stele1`。
  - 事件区节点名 `Event`，作者 `encounter_id = ch3_event/event`；Boss 区只放
    结构 `Arena`（Boss 3 机制/`boss_scene` 属后续内容程，未做）。
  - 入口 `ch3_entry` 作者 `SpawnPoint`（`save_point` 组，(400,1328) = 第一级
    台阶面 1344 − `FOOT_Y` 16），并作者到达门 `shortcut_arrival`
    （`MDSGate.Mode.TOUCH`、无 `to`），沿用第 37 程第 2 章口径；未改 MDS 出生
    回退顺序与第 1/2 章出生点。
- 纵向/捷径骨架（第 29 程管线，未改本体）：
  - `ch3_branch_b` / `ch3_hub` / `ch3_vault` 各 1 台 `MovingPlatform`
    （地面 → y=100，覆盖顶门列、列内无平台）；`ch3_well` 1 台电梯
    （2144 → 100）+ 3 个 `OneWayPlatform`；`ch3_elite` 1 台电梯
    （到达顶门 y=1920 下方）。
  - 枢纽 `BenchCheckpoint` 长椅；捷径门由世界 JSON 的 `requires` 自动生成
    `MDSGateBarrier`（默认封闭，无新增授予来源）。
  - 电梯未写 `speed`，沿用 `MovingPlatform.speed` 的管线默认 **80 px/s**
    （`scripts/levels/moving_platform.gd`）。第 12 项（70 px/s 节奏）只针对
    第 2 章，本程未给第 3 章定速度、未改第 2 章数值。

## 2. 独立世界

- `scenes/mds/chapter_3_bigmap.mdsworld.json` + `chapter_3_bigmap_world.tscn`：
  - 9 区、单矩形、世界原点 32 px 对齐；`start_room = ch3_entry`。
  - 区域 `Lightless Sea`：`color #2c3a66`、雾 + 雨、`boss_background:
    deep_water`；不写 `backdrop_image`、无 sea 层（第 15 项留空）。
  - 22 门 = 20 有向 + 2 只到达（`ch3_entry/shortcut_arrival`、
    `ch3_boss/left1`）；显式单向 `elite_boss`（进 Boss 不可返回）与
    `hub_shortcut_entry`（`requires = ["ch3_shortcut"]`，来源待第 16 项，
    默认不可通行）。
  - 侧门在地面上方 90 px、底门在地面线、顶门在上边缘；房间不重叠、
    双向门相邻、捷径刻意不相邻。
  - 世界 JSON 由第 40 程夹具镜像生成（逐区字段一致，仅加 `scene_path`），
    夹具本身只更新了注释（不再声称真实世界不存在），门图/区域未改。
- 旧 `chapter_3.mdsworld.json` / `chapter_3_world.tscn` 与 9 个
  `MDSChapterRoom` 场景原地保留、未改语义、未删除；新世界本程不被
  `game.gd` 引用。

## 3. 测试

- 新增 `tests/test_ch3_world.gd`（**771** 断言）：
  - 真实世界 ↔ 计划：9 区 id/类型/尺寸/遭遇/宝箱/残碑/捷径/隐藏/商店/休整/
    纵井、起始区、区域雾/雨与 `boss_background`、区域无 `backdrop_image`/sea 层。
  - 门：20 有向 + 2 只到达；11 条计划门的前向/回程门位、单向标记与
    `requires`；捷径 `requires = ["ch3_shortcut"]`、单向、door 侧；世界图从
    入口 BFS 到全部 9 区。
  - 几何：单矩形、局部原点、世界原点 32 px 网格、门在正确边/在房间内、
    房间不重叠、双向门相邻、捷径不相邻。
  - 9 场景：`MDSBigRoom`（非 `MDSChapterRoom`）、`BigRoomData` 路径/尺寸/
    校验为空/瓦片/背景/氛围/坠落余量/底边地面。
  - 内容节点：计划 id 一一对应、遭遇/宝箱/残碑数量不许多、事件区作者
    `ch3_event/event`、枢纽商店 id + 长椅、Boss 区结构 Arena、入口
    `SpawnPoint`（`save_point`、站在第一级台阶）与惰性到达门。
  - 纵向道具：纵井 3 个单向落台；所有顶门房间有覆盖门列的电梯、行程向上、
    到达 y≤120、列内无平台；电梯速度 = 管线默认 80（锁定「未给第 3 章定速度」）。
  - 清房目标：世界图上的遭遇总数 = 计划 `clear_target()` = 7。
  - 不变项：`CHAPTER_PLAN_PATHS[2]` 仍空、`game.gd` 仍用旧世界/旧场景、
    `game.gd` 不引用 `chapter_3_bigmap`/`ch3_bigmap`/`ch3_shortcut`、
    `room_darkness = false`（第 14 项未实现）、场景无作者 `GateVisual`；
    `content_pending` 仍 true、无波次表、无 `boss_scene`、无权柄池；
    第 1 章 6 波与 `Ch1EventData`、第 2 章计划/世界/`Ch2EventData`、旧第 3 章
    6 波表均仍在。
  - 旧第 3 章世界 9 房/17 有向门/旧场景指向不变；第 1 章计划仍 9 房/清房目标 6、
    第 2 章计划仍 9 区/11 门/清房目标 7/无 pending、第 2 章世界仍 9 区。
- 更新 `tests/test_ch3_plan.gd`（728 → **730** 断言）：第 40 程锁的
  「大区数据/场景目录不存在」改为「目录存在且各有 9 个文件」，其余计划/夹具
  断言不变。
- 临时探针 `tests/probe_ch3world41.gd`：用 `MDSWorldGame` 逐区加载真实世界，
  确认 9 区 `validation_errors` 全空、22 门、枢纽 1 个 `MDSGateBarrier`、
  背景覆盖房间并集、氛围节点存在、`fall_below_bounds = 240`、入口出生点
  (400,1328)；测后删除。

## 4. 验证（本程末实测，Godot 4.7.stable.official.5b4e0cb0f）

- 基线（改动前）：`--headless --import` / `--quit` 退出 0、`ERROR` 0；
  单元 **8739 / 0**；九套集成 **671 / 102 / 613 / 207 / 113 / 59 / 391 / 45 /
  2209** 全 0 失败；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。
  与交接逐项一致，无基线漂移。
- 改动后：`--headless --import` / `--quit` 退出 0、`ERROR` 0；单元
  **9512 / 0**（基线 8739 + 第 3 章 773：计划测试 +2、世界测试 771）；
  九套集成 **671 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209** 全 0 失败、
  各日志 `ERROR` 0；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。
- 第 1 章 9 房/6 波次/事件/清房目标 6/结束流程无回归；第 2 章计划/世界/集成
  无回归；第 2 章与第 3 章仍不可达。

## 5. 待确认项留空情况

- 第 14 项（视野压缩）：未实现、未预设数值/机制；世界场景 `room_darkness = false`。
- 第 15 项（海面母题）：未给大区管线加 sea 层、未改 `LivingBackdrop`、未新绘
  背景；大区世界只用管线已有的平铺静态背景（既有 `lightless_sea.png`）与氛围。
- 第 16 项（`ch3_shortcut` 来源）：未新增任何授予该能力的交互/事件/掉落；
  捷径门保持 `requires` 且默认不可通行。
- 第 11/12/13 项（第 2 章）未碰；章末边界（第 3 章结束自动进第 4 章）未改，
  缺口仍在，属后续章末收口程。

## 6. 未做（按任务单）

- 第 3 章接入 `game.gd`、可达性开放、章节路由与章末流程；
- `Ch3EventData`、波次接线、权柄池、Boss 3 机制/`boss_scene`/入场与阶段文案、
  第 3 章大图验收套件；
- 第 3 章门视觉专项打磨（管线运行时共享的 `GateVisual` 自动生成属既有行为，
  未改、未加作者覆盖）；
- 阿砚同行、新移动能力、NPC 立绘、MDS 插件本体、敌人/场景美术、
  打包/导出/安装器/签名/安卓/触屏。

## 7. 提交

- `b86dff6` feat: build the chapter 3 big-map region world（9 个
  `BigRoomData`、9 个 `MDSBigRoom` 场景、独立世界 JSON/场景、
  `test_ch3_world.gd`、`test_ch3_plan.gd` 目录断言更新、夹具注释）；
- `662e0b4` test: lock the chapter 3 clear target and kept content（世界遭遇数
  = 清房目标 7；第 1 章 6 波、第 2 章世界、旧第 3 章 6 波、第 1/2 章事件模块）；
- `57dc444` docs: record the chapter 3 real region world（状态文件、本 session、
  记忆索引）；`e59f4a6` docs: record the pass 41 assertion additions（补充断言
  记录与提交清单）。仅本地 `supervisor-dev`，不推送、不更新网页版。
