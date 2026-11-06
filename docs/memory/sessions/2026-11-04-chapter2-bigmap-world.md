# 2026-11-04 · 第 2 章大地图施工第 4 步（后半）：真实大区世界与 region 语义（第 31 程）

> 把第 30 程的 9 区计划做成可加载的真实大区世界与房间场景，并让
> `game.gd` 读计划的 region 语义（起始区、清房目标、坠落平面）。第 2 章
> 仍不可达；第 1 章 9 个房间仍走 `MDSChapterRoom`，世界文件、波次、进度与
> 结算未改。旧 9 小房间第 2 章世界原地保留、未删除、未改语义，仅不再被
> `game.gd` 引用。

## 1. 真实大区世界与房间

- `resources/rooms/ch2_bigmap/*.tres`（9 个 `BigRoomData`）：
  - 尺寸按计划 2560×1440 / 2560×2160 / 3840×2160；地面贴房间底边
    （`H-16`，16 px 厚），平台按 80 px 阶梯链布置，满足第 28 程校验
    （垂直上升 ≤80 px、水平边缘 ≤120 px，只有最低面豁免支撑）。
  - `tile_set` 复用 `ch1_tiles.tres`；`backdrop_path` 指向
    `breathing_ruins.png`（绘画图，`backdrop_pixel_art = false`）；每区
    独立 `backdrop_modulate`；`ambient_kind` 为 `motes`/`embers`，密度 0.5。
- `scenes/mds/ch2_bigmap/*.tscn`（9 个 `MDSBigRoom`）：
  - 根节点脚本 `mds_big_room.gd`，`data` 指向对应 `.tres`，
    `fall_margin = 240.0`（房间 metadata `fall_below_bounds = 240`）。
  - 内容按计划节点 id 命名：`Arena`/`Arena2`（`ArenaRoom`）、`Chest1/2`
    （`TreasureChest`）、`Stele1/2`（`MemoryStele`）；事件区的战斗节点名
    `Event`，作者 `encounter_id = ch2_event/event`。
  - 枢纽：`Shop`（`ch2_hub_shop`）、`Bench`、`Stele1`、`Lift`。
  - 纵井：`Arena`/`Arena2`、`Chest1`、3 个 `OneWayPlatform`、`Lift`。
  - 作者门 `ch2_entry/shortcut_arrival`（TOUCH、无 `to`），作为枢纽捷径的
    到达点，不弹交互提示。
- `scenes/mds/chapter_2_bigmap.mdsworld.json` + `chapter_2_bigmap_world.tscn`：
  - 9 个房间、单矩形、世界原点按 32 px 对齐；`start_room = ch2_entry`；
    区域 `Breathing Ruins` 带雾 + 萤火天气、`backdrop_image` 与
    `boss_background: spore_drift`。
  - 20 扇有向门 + 2 扇只到达门（`ch2_entry/shortcut_arrival`、
    `ch2_boss/left1`）；2 扇显式单向：`elite_boss` 与带
    `requires = ["ch2_shortcut"]` 的 `hub_shortcut_entry`。侧门在
    地面以上 90 px，底门在地面线，顶门在上边缘，电梯列避开平台。
  - 房间不重叠；双向门两侧房间相邻，捷径是刻意传送、不相邻。
- 第 29 程道具骨架接入：枢纽/纵井/精英/书库等竖向房间放
  `MovingPlatform`（从地面升到 y≈100、顶门下方，行程在并集内）；
  纵井 3 个单向落台；枢纽长椅与带 `requires` 的捷径门自动生成
  `MDSGateBarrier`。本程只做骨架，无事件文案、敌人波次或战斗内容。

## 2. `game.gd` 接计划（region 语义）

- 新增 `CHAPTER_PLAN_PATHS`：第 1 章 `chapter_1_demo.tres`，第 2 章
  `chapter_2_demo.tres`，第 3/4 章留空（继续走 `CampaignData.rooms` +
  `ROOM_WAVES`）。
- `_start_mds_chapter` 按章节加载计划；新局起始房间 = 计划入口
  （`ch2_entry`），无计划/无入口时回退 `chN_01`。
- 第 2 章世界/场景常量切到 `chapter_2_bigmap_world.tscn` /
  `chapter_2_bigmap.mdsworld.json`；第 1、3、4 章条目不变。
- 坠落平面继续走第 27 程解析链：计划 region 的 `fall_below_bounds`
  （`size.y + 240`）→ 房间 metadata → 默认 850。纵井/精英/Boss
  （2160 高）平面为 2400，下层平台 y≈1500–2100 不会被误杀。
- 清房目标从计划派生：第 2 章 7（支路 A 2 + 支路 B 1 + 纵井 2 +
  精英 1 + 事件 1），HUD 分母为 8（含 Boss）；第 1 章仍 6/7。
- 宝箱/残碑/遭遇继续按 `region/Node` 节点 id 结算（第 27 程），
  一区多内容各自独立；旧 room-key 存档仍兼容。
- 事件页仍只属于第 1 章内容（`_chapter == 0`）；第 2 章事件区暂不打开
  第 1 章事件页，保持安静。
- **两条红线**：第 1 章行为未改（9 个 `MDSChapterRoom`、原世界 JSON、
  波次/进度/结算/章末 `_finish(true)`）；第 2 章仍不可达（第 1 章结束
  直接结束 demo，不自动进入第 2 章）。达成方式：只改世界/计划来源与
  章节判断，不改可达性链路。

## 3. 测试

- 新增 `tests/test_ch2_world.gd`（**727** 断言）：
  - 真实世界 ↔ 计划：9 区 id/类型/尺寸/遭遇/宝箱/残碑/捷径/隐藏/商店/
    休整/纵井标记、起始区、区域天气与背景；世界图从入口 BFS 到枢纽、
    隐藏书库、Boss 与全部 9 区。
  - 门：20 扇有向 + 2 扇到达门；计划每扇门的前向/回程门位与单向标记；
    门位在对应边、房间不重叠、双向门相邻、捷径不相邻且显式单向。
  - 9 个房间场景：`MDSBigRoom`、`BigRoomData` 按并集校验为空、
    尺寸/瓦片/背景/氛围/坠落余量、底边有地面。
  - 内容节点：遭遇/宝箱/残碑按计划节点名存在，事件区作者遭遇 id，
    枢纽商店 id + 长椅，入口作者到达门；顶门房间的电梯列避开平台。
  - 夹具隔离：`fixture: true`、无 `scene_path`、与真实世界逐区一致；
    `game.gd` 不引用夹具。
  - 旧世界保留：旧第 2 章 9 个 1280×720 `MDSChapterRoom` 房间仍在、
    旧世界场景仍指向旧 JSON；第 1 章世界 9 房仍 `MDSChapterRoom`，
    第 1 章计划仍 9 房/清房目标 6/无图。
  - `game.gd` 四个世界/场景/计划槽位：第 1、3、4 章不变，第 2 章指向
    新世界与新计划；新世界场景 `starting_room = ch2_entry`、分房加载、
    区域天气/背景开启。
- `tests/integration_playability.gd` 扩到 **581** 断言（+189）：
  - 第 2 章从计划入口开始，坠落平面 1680，清房目标 7、分母 8；
  - 9 区逐区加载、按并集校验、区域背景/天气、门节点与模式；
  - 枢纽商店/长椅/捷径屏障（`ch2_shortcut` 解锁并写入 MDS 存档）；
  - 纵井下层（y≈2100）不被坠落保护误杀、不掉血；
  - 书库两箱两碑按节点 id 各自结算，重载后只保留未领取内容；
  - 事件区不打开第 1 章事件页；精英 → Boss 单向门；
  - 支路 A 两场遭遇各自计数、重复 `cleared` 不重复结算；
  - 补满 7 场后进入 Boss，击杀 → 章末文案 → 选择 → 第 3 章；
  - 第 1 章结束仍不进入第 2 章（`chapter_1_ends_without_entering_chapter_2`）。

## 4. 验证（本程末实测，Godot 4.7.stable.official.5b4e0cb0f）

- `--headless --path . --import` / `--quit`：退出 0、`ERROR` 0。
- 全量单元 **7244 / 0**（基线 6517 + 新增 727）。
- 八套集成全部 0 失败、各日志 `ERROR` 0：结构/可玩性 **581**（基线 392
  + 189）、第一章 demo **101**、run save **588**、手柄 **207**、UI 提示
  **113**、第一章事件 **59**、菜单 A/B **391**、AI 设置 **45**。
- `tests/check_exit_clean.sh <godot> 10` → **10/10 clean**；
  demo 像素资产 **36 / 0**。
- 临时探针 `tests/probe_ch2map32.gd`、`tests/probe_ch2world32.gd`
  （施工中用于逐区几何/世界加载）用完删除，未留在仓库。

## 5. 未做（按任务单）

- 第 2 章事件文案、权柄池、Boss 机制/文本、敌人波次与战斗内容；
- 章节可达性（第 2–4 章仍不可达）；二段跳/蹬墙跳/攀爬；
- MDS 插件修改、言灵/权柄/战斗框架修改、敌人美术/NPC 立绘；
- 删除旧世界/旧房间场景；打包/导出/安装器/签名/商店/安卓/触屏。

## 6. 提交

- `ea68f3a` 真实大区世界、9 个 `BigRoomData` 与 9 个房间场景；
- `767ffaf` `game.gd` 计划加载与 region 语义；
- `852606c` 世界/计划接线单元测试 + 可玩性集成扩展 + 夹具镜像；
- `<本提交>` 状态、ADR、本 session、记忆索引。仅本地 `supervisor-dev`，
  不推送、不更新网页版。
