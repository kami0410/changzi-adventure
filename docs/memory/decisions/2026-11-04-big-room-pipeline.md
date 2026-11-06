# ADR：第 2–4 章房间生产管线（BigRoomData + MDSBigRoom）

- 日期：2026-11-04（第 28 程）
- 状态：已采纳，第 1 章不迁移
- 相关：[第 2 章大地图可行性核查](../../../SUPERVISOR_STATUS.md)、[MDS 全量接入](2026-11-02-mds-full.md)、[逐帧动作管线](2026-11-02-frame-animation.md)

## 背景

第一章的 `MDSChapterRoom` 是固定模板：1280×720、单层地面、地面 y=560、
至多 3 个固定平台、单 Arena、按 `chapter_index` 硬编码背景。第 2–4 章按
用户 2026-11-04 拍板走大地图结构，需要可变尺寸、多层地面/平台、按区背景与
氛围的房间。监工任务单要求本程只做管线，不做第 2 章内容、不开可达性、不新增
移动能力，并且管线要同时兼容「大区图 + 短过渡」与「字面单场景无缝」两种待定
口径。

## 决定

1. **新增 `BigRoomData`（Resource）+ `MDSBigRoom`（Node2D）**，放在
   `scripts/levels/`；第一章的 `MDSChapterRoom` 与其 9 个房间场景一字不改。
   第 1 章走旧管线，第 2–4 章房间按需在新管线里建场景。
2. **MDS 仍是房间权威**：房间矩形、并集边界、相机限制、天气、动态背景、
   视差继续由 MDS 世界 JSON 与 `MDSWorldGame` 负责。`MDSBigRoom` 只读取：
   - 房间局部矩形并集 → `room_bounds`（世界局部 union 覆盖 `BigRoomData.size`；
     `size` 只在没有 MDS 父节点时作后备，供单元测试/灰盒用）。
   - `MDSEnvironment.spec_for_room` / `background_for_room` /
     `parallax_for_room` → 按房间→区域→世界解析，不按章号硬编码。
   - 相机限制由 `MDSWorldGame.apply_camera_limits` 按并集设置，管线不另建相机。
3. **几何数据**：`ground` 字典 `{x, y, width, height=64}`（`x` 左缘、`y` 可行走面、
   `height` 下方填充），`platforms` 字典 `{x, y, width}`（固定 16 px 厚）。
   所有坐标为房间局部像素，与 MDS 门位同一坐标系。有 `tile_set` 时按 16 px
   网格吸附，瓦片外观与碰撞矩形共用边缘；没有 `tile_set` 时用纯色灰盒。
4. **可达性约束由数据层执行**：`BigRoomData.validate()` 拒绝：
   - 超出房间并集的地面/平台；
   - 非数值/非正宽度、非法高度；
   - 任何表面高出其「攀爬来源面」超过 `MAX_STEP = 80 px`（现有跳跃顶点约
     92.6 px，`jump_velocity=-500`、`gravity=1350`，留约 12 px 余量）；
   - 找不到下方支撑面的悬空平台（水平边缘距离超过 `MAX_HORIZONTAL_STEP =
     120 px` 视为不可达；80 px 上升时跳跃水平航程约 150 px，预留身位/落点）。
   `MDSBigRoom` 构建时把校验问题 `push_warning` 出来并保留在
   `validation_errors`，不静默丢几何。
5. **碰撞与视觉分离**：外观用 `TileMapLayer`（`collision_enabled=false`）或
   `ColorRect`；碰撞用少量 `StaticBody2D` + `RectangleShape2D`（每段地面/平台
   一个），因此大房间不会产生每格碰撞体，平台顶面与瓦片完全对齐。
6. **静态背景按房间宽度平铺**：`backdrop_image` 依次取
   蓝图 `backdrop_path` → MDS 房间 → 区域 → 世界；蓝图 `backdrop_texture`
   优先（测试/灰盒）。按整数 `backdrop_scale` 平铺覆盖整个并集，像素图用
   nearest、绘画图用 linear。动态背景/天气仍由 MDS 按区域叠加。
7. **氛围按区且受相机范围约束**：`BigRoomAmbient` 只绘制相机窗口与房间并集的
   交集（外加 64 px 余量），颜色默认取 MDS 区域色；`motes`/`embers` 两种，
   默认关闭，不复制 MDS 天气。
8. **门由世界 JSON 生成**：`auto_gates=true` 时按 `world.get_gates(room_id)`
   生成 `MDSGate`（TOUCH/INTERACT、侧向形状、从 Flow 取交互提示）；同名作者
   门优先，便于场景覆盖。门连接仍只存在于世界 JSON。
9. **坠落平面元数据**：房间根节点写入 `fall_below_bounds = fall_margin`
   （默认 200 px，低于并集底边），接第 27 程 `game.gd` 的解析链；章节计划里
   的 `fall_y`/`fall_below_bounds` 仍优先。
10. **不依赖待定口径**：房间仍是 MDS 加载单元（兼容大区图与单场景两种口径），
    没有新增二段跳/蹬墙跳/攀爬，也没有移动/塌陷/单向平台；这些留给下一步。

## 后果与边界

- 第 1 章零迁移风险：旧 `MDSChapterRoom`、`ch1_layout.tres`、9 个房间场景与
  旧测试全部保留并通过。
- 第 2 章仍未可达；本程没有新增/修改任何第 2 章世界 JSON、房间场景、计划、
  事件、权柄或 Boss 内容。
- 验证：单元 `tests/test_big_room.gd` 覆盖校验、吸附、平铺、灰盒/碰撞与
  「第一章仍走旧管线」；结构集成用 `tests/fixtures/big_room/` 的 2560×1440
  与 L 形 3840×1440 世界验证 MDS 并集/相机限制、多层落点、按区背景与天气、
  相机窗口氛围和门生成。夹具是测试资产，不是章节内容。
- 后续做第 2 章时，先写房间计划/世界矩形，再给每个房间配 `BigRoomData`；
  移动平台/塌陷平台/单向落台是下一步的关卡道具，不改本 ADR 的几何契约。

## 第 29 程补充：纵向/捷径道具（第 2 章施工第 3 步）

在第 28 程几何契约之上补可复用的关卡道具，仍不改玩家跳跃/战斗数值、不新增移动能力（口径 A：不加二段跳/蹬墙跳/攀爬）：

1. **单向落台（`OneWayPlatform`）**：`StaticBody2D` + `one_way_collision` 顶面；上方可站立、下方跳跃直接穿过。站在上面按「下 + 跳」时，`player.gd` 与脚下平台建立 0.3 s 碰撞例外并向下起跳，因此不需要新按键；在实心地面上「下 + 跳」仍是普通跳跃（第 1 章行为不变）。平台按 `one_way_platforms` 组识别，只对带 `allows_drop_through()` 的组内物体生效。
2. **塌陷平台（`CollapsingPlatform`）**：站立触发 `IDLE → WARNING`（颜色/裂纹/抖动，`warn_time`）→ `FALLING`（关闭碰撞、视觉下落，`fall_time`）→ `GONE`（`respawn_time` 后复位）。`game.gd` 在坠落回退与玩家死亡时调用组内 `reset_now()`，检查点不会落在已塌的平台上；塌落本身不改坠落平面解析链（计划 → metadata → 默认 850 的优先级不变）。
3. **移动平台/电梯（`MovingPlatform`）**：`AnimatableBody2D` + `sync_to_physics`，`travel` 为相对作者位置的位移，支持水平/垂直/斜向；站立玩家由 CharacterBody2D 现有平台逻辑承载。`MDSBigRoom.build()` 把房间并集交给子道具（`set_room_bounds`），`travel` 越界时收紧到并集内；作者位置本身在并集外时原地不动。相机限制仍由 MDS 按同一并集设置。
4. **长椅检查点（`BenchCheckpoint`）**：交互（现有 `interact`）更新 `_last_checkpoint` 并调用现有 `save_run_now()`；**不新增存档键、不改存档版本**，续玩仍走 MDS 精确坐标。第 1 章仍只在进房时设检查点，代码未改。
5. **捷径**：世界 JSON 的门带 `requires` 时，`MDSBigRoom.auto_gates` 在生成 `MDSGate` 的同时生成 `MDSGateBarrier`（能力/物件/Boss 条件复用 MDS 既有机制，开门状态进 MDS 存档）。不新增可破坏墙运行时脚本；若后续内容确需可破坏墙，另排一程。
6. **测试夹具**：`tests/fixtures/big_room/world.mdsworld.json` 增加一个带 `requires` 的 `shortcut` 门，用于验证条件门生成与解锁；夹具是测试资产，不是章节内容。第 1 章 9 个房间场景一字未改，单元测试断言其中没有这些新道具。
