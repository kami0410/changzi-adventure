# 2026-11-05 · 第 4 章大地图施工第 2 步：真实大区世界（第 52 程）

> 把第 51 程的 9 区计划做成可加载的第 4 章真实大区世界与房间场景（只做结构层）。
> `game.gd` 未改，第 4 章仍走旧 `chapter_4.mdsworld.json` / 9 个
> `MDSChapterRoom` 小房间，`CHAPTER_PLAN_PATHS[3]` 仍为空，第 4 章仍不可达。
> 旧世界、旧房间场景、第 1–3 章计划与世界均未改未删。本程复用第 28/29/31/37/41 程
> 的既有管线，不改管线本体，不新增移动能力。

## 1. 真实大区世界与房间

- `resources/rooms/ch4_bigmap/*.tres`（9 个 `BigRoomData`）：
  - 尺寸按计划：2560×1440（入口/支路/枢纽/书库/事件）、2560×2160（纵井）、
    3840×2160（精英、Boss）。
  - 地面贴房间底边（`H-16`，16 px 厚）；平台按 80 px 阶梯链布置，全部通过
    `BigRoomData.validate()`（上升 ≤80 px、水平边缘 ≤120 px，只有最低面豁免支撑）。
  - `tile_set` 复用 `ch1_tiles.tres`；`backdrop_path` 指向既有
    `assets/backgrounds/smiling_theater.png`（1536×864 绘画图，
    `backdrop_pixel_art = false`）；每区独立 `backdrop_modulate`（入口白 /
    支路暖 / 枢纽灯黄 / 纵井灰紫 / 书库冷紫 / 事件暖橙 / 精英红 / Boss 血红）。
  - 氛围 `ambient_kind = embers`（灰烬母题，对应旧世界区域天气的 ash），
    密度 0.5。没有新增 theater 层，也没有新绘任何背景。
- `scenes/mds/ch4_bigmap/*.tscn`（9 个 `MDSBigRoom`）：
  - 根脚本 `mds_big_room.gd`，`data` 指向对应 `.tres`，`fall_margin = 240.0`
    （房间 metadata `fall_below_bounds = 240`，与计划一致）。
  - 内容节点严格用计划 `region/Node` id，不新增 id：`ch4_branch_a` 的
    `Arena`/`Arena2`/`Chest1`、`ch4_branch_b` 的 `Arena`、`ch4_well` 的
    `Arena`/`Arena2`/`Chest1`、`ch4_elite` 的 `Arena`、`ch4_hub` 的
    `Stele1`/`Shop`(`ch4_hub_shop`)/`Bench`、`ch4_vault` 的 `Chest1`/`Stele1`。
  - 事件区节点名 `Event`，作者 `encounter_id = ch4_event/event`；Boss 区只放
    结构 `Arena`（Boss 4 机制/`boss_scene`/文案属后续内容程，未做）。
  - 入口 `ch4_entry` 作者 `SpawnPoint`（`save_point` 组，(400,1328) = 第一级
    台阶面 1344 − `FOOT_Y` 16），并作者到达门 `shortcut_arrival`
    （`MDSGate.Mode.TOUCH`、无 `to`），沿用第 37/41 程口径；未改 MDS 出生
    回退顺序与第 1–3 章出生点。
- 纵向/捷径骨架（第 29 程管线，未改本体）：
  - `ch4_branch_b` / `ch4_hub` / `ch4_vault` 各 1 台 `MovingPlatform`
    （地面 → y=100，覆盖顶门列、列内无平台）；`ch4_well` 1 台电梯
    （2144 → 100）+ 3 个 `OneWayPlatform`；`ch4_elite` 1 台电梯
    （到达顶门 y=1920 下方）。
  - 枢纽 `BenchCheckpoint` 长椅；捷径门由世界 JSON 的 `requires` 自动生成
    `MDSGateBarrier`（默认封闭，无新增授予来源）。
  - 电梯未写 `speed`，沿用 `MovingPlatform.speed` 的管线默认 **80 px/s**
    （`scripts/levels/moving_platform.gd`）。第 12 项（70 px/s 节奏）只针对
    第 2 章，本程未给第 4 章定速度、未改第 2 章数值。

## 2. 独立世界

- `scenes/mds/chapter_4_bigmap.mdsworld.json` + `chapter_4_bigmap_world.tscn`：
  - 9 区、单矩形、世界原点 32 px 对齐；`start_room = ch4_entry`。
  - 区域 `Smiling Theater` 镜像旧世界：`color #6a2a34`、灰烬 + 光柱天气、
    `background` 空、`boss_background: blood_moon`；不写 `backdrop_image`、
    无 theater 层（第 50 程专节 E 的舞台母题口径仍待拍板）。
  - 22 门 = 20 有向 + 2 只到达（`ch4_entry/shortcut_arrival`、
    `ch4_boss/left1`）；显式单向 `elite_boss`（进 Boss 不可返回）与
    `hub_shortcut_entry`（`requires = ["ch4_shortcut"]`，来源待第 50 程专节 E，
    默认不可通行）。
  - 侧门在地面上方 90 px、底门在地面线、顶门在上边缘；房间不重叠、
    双向门相邻、捷径刻意不相邻。
  - 世界 JSON 由第 51 程夹具镜像生成（逐区字段一致，仅加 `scene_path`），
    夹具未改语义（仍是 `fixture: true`、永不加载）。
- 旧 `chapter_4.mdsworld.json` / `chapter_4_world.tscn` 与 9 个
  `MDSChapterRoom` 场景原地保留、未改语义、未删除；旧 `ch4_boss/left1`
  仍返回 `ch4_rest`，大图世界的 Boss 门按第 2/3 章先例单向，两种行为分别锁定。
  新世界本程不被 `game.gd` 引用。

## 3. 测试

- 新增 `tests/test_ch4_world.gd`（**812** 断言）：
  - 真实世界 ↔ 计划：9 区 id/类型/尺寸/遭遇/宝箱/残碑/捷径/隐藏/商店/休整/
    纵井、起始区、区域灰烬/光柱与 `boss_background = blood_moon`、
    `background` 空、无 `backdrop_image`/theater 层。
  - 门：20 有向 + 2 只到达；11 条计划门的前向/回程门位、单向标记与
    `requires`；捷径 `requires = ["ch4_shortcut"]`、单向、door 侧；
    `elite_boss` 单向、`ch4_boss/left1` 为只到达；世界图从入口 BFS 到全部 9 区。
  - 几何：单矩形、局部原点、世界原点 32 px 网格、门在正确边/在房间内、
    房间不重叠、双向门相邻、捷径不相邻。
  - 9 场景：`MDSBigRoom`（非 `MDSChapterRoom`）、`BigRoomData` 路径/尺寸/
    校验为空/瓦片/背景/氛围/坠落余量/底边地面。
  - 内容节点：计划 id 一一对应、遭遇/宝箱/残碑数量不许多、事件区作者
    `ch4_event/event`、枢纽商店 id + 长椅、Boss 区结构 Arena、入口
    `SpawnPoint`（`save_point`、站在第一级台阶）与惰性到达门。
  - 纵向道具：纵井 3 个单向落台；5 个作者电梯区（支路 B/枢纽/书库/纵井/精英）
    有电梯、其余区没有；所有顶门房间有覆盖门列的电梯、行程向上、到达 y≤120、
    列内无平台；电梯速度 = 管线默认 80（锁定「未给第 4 章定速度」）。
  - 清房目标：世界图上的遭遇总数 = 计划 `clear_target()` = 7。
  - 不变项：`CHAPTER_PLAN_PATHS[3]` 仍空、`game.gd` 仍用旧世界/旧场景、
    `game.gd` 不引用 `chapter_4_bigmap`/`ch4_bigmap`/`ch4_shortcut`、
    场景无作者 `GateVisual`；`content_pending` 仍 true、无波次表、无
    `boss_scene`、无权柄池、无 `Ch4EventData`；第 1 章 6 波与 `Ch1EventData`、
    第 2/3 章计划/世界/事件模块、旧第 4 章 6 波表均仍在。
  - 旧第 4 章世界 9 房/17 有向门/旧场景指向不变；第 1 章计划仍 9 房/清房目标 6、
    第 2 章计划仍 9 区/11 门/清房目标 7、第 3 章计划仍 9 区/11 门/清房目标 7/
    `boss_scene` 已路由；第 2/3 章大区世界仍各 9 区。
- 更新 `tests/test_ch4_plan.gd`（778 → **796** 断言）：第 51 程锁的
  「`ch4_bigmap` 大区数据/场景目录尚未创建」改为「目录存在且每区 `.tres`/`.tscn`
  都存在」，其余计划/夹具/路由断言不变。
- 临时探针 `tests/probe_ch4world52.gd`：用真实 `MDSWorldGame` 逐区加载
  `chapter_4_bigmap_world.tscn`，确认 9 区 `validation_errors` 全空、
  `fall_below_bounds = 240`、每区门数与世界 JSON 一致（合计 22）、枢纽
  1 个 `MDSGateBarrier`、背景覆盖房间并集、`Ambient` 节点存在、入口出生点
  (400,1328)；**0 失败**，测后删除（连同 `.uid`）。

## 4. 验证（本程末实测，Godot 4.7.stable.official.5b4e0cb0f）

- 基线（改动前）：`--headless --import` / `--quit` 退出 0、`ERROR` 0；
  单元 **11095 / 0**；十套集成 **755 / 102 / 613 / 207 / 113 / 59 / 391 / 45 /
  2209 / 4235** 全 0 失败；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。
  与交接逐项一致，无基线漂移。
- 改动后：`--headless --import` / `--quit` 退出 0、`ERROR` 0；单元
  **11925 / 0**（基线 11095 + 830：`test_ch4_world` 812 + `test_ch4_plan`
  目录锁改存在性 +18）；十套集成数字与基线完全一致、全 0 失败；退出泄漏
  **10/10 clean**；demo 像素资产 **36 / 0**；工作区干净、无临时探针。
- 第 1 章 9 房/6 波次/事件/清房目标 6/结束流程无回归；第 2 章计划/世界/
  Boss 2/集成无回归；第 3 章计划/世界/集成无回归；第 2/3/4 章仍不可达。

## 5. 待确认项留空情况

- 舞台母题：只按既有区域氛围落地（`Smiling Theater` 灰烬 + 光柱、
  `blood_moon` Boss 背景、`smiling_theater.png` 静态平铺 + `embers` 氛围）；
  未给大区管线加 theater 层、未改 `TheaterBackdrop`、未新绘背景。
- `ch4_shortcut` 来源：未新增任何授予该能力的交互/事件/掉落；捷径门保持
  `requires` 且默认不可通行。
- 战斗密度：未扩波、未增遭遇；旧世界每房 5–6 只 vs 大图每遭遇 2 只
  （`ROOM_WAVES` 单波）的差异只记录，留待内容程/拍板。
- `mask_enemy`/`seat_husk` 独立数值与行为：未做，仍为第 1 章敌人的美术变体。
- Boss 4 机制范围：未做、未设计；Boss 区只有结构末端占位。
- 章末边界：未改 `_complete_chapter`；第 3 章停章替身
  （`_chapter == 2` → `_finish(true)`）仍待可达性拍板后解开。
- 阿砚同行：未做；仓库仍无 companion/follower 控制器，只记录缺失。
- 第 11/12/13/14/15/16 项（第 2/3 章）未碰；第 12 项只针对第 2 章，
  本程第 4 章电梯沿用的是管线默认值。

## 6. 未做（按任务单）

- 第 4 章接入 `game.gd`、可达性开放、章节路由与章末流程；
- `Ch4EventData`、波次接线、权柄池、Boss 4 机制/`boss_scene`/入场与阶段文案、
  第 4 章大图验收套件；
- 第 4 章门视觉专项打磨（管线运行时共享的 `GateVisual` 自动生成属既有行为，
  未改、未加作者覆盖）；
- 阿砚同行、新移动能力、NPC 立绘、MDS 插件本体、敌人/场景美术、
  打包/导出/安装器/签名/安卓/触屏。

## 7. 提交

- `0125562` feat: build the chapter 4 big-map region world（9 个 `BigRoomData`、
  9 个 `MDSBigRoom` 场景、独立世界 JSON/场景、`test_ch4_world.gd`、
  `test_ch4_plan.gd` 目录断言更新）；
- `695b505` docs: record the chapter 4 real region world（状态文件、本 session、
  记忆索引）。仅本地 `supervisor-dev`，不推送、不更新网页版。
