# 2026-11-04 · 第 2 章大地图施工第 3 步：纵向/捷径道具管线（第 29 程）

> 只做可复用道具/物件能力，用测试夹具验证：未创建/调整第 2 章地图、房间、世界
> JSON、房间计划、事件、权柄或 Boss 内容，未改章节可达性，未新增移动能力
> （不加二段跳/蹬墙跳/攀爬），未改 MDS 插件本体、言灵/权柄/战斗框架或存档格式。
> 第 1 章 9 个房间仍走 `MDSChapterRoom`，行为与基线一致。

## 1. 单向落台 `OneWayPlatform`

- `scripts/levels/one_way_platform.gd`（`StaticBody2D`）：`size` 的左上角就是
  可行走面，与 `BigRoomData` 的房间局部坐标一致；碰撞层 1、无碰撞掩码。
- `CollisionShape2D.one_way_collision = true`（margin 2）：上方可站立，下方
  跳跃直接穿过。
- 下落穿过不新增按键：站在组 `one_way_platforms` 的平台上按「下 + 跳」，
  `player.gd` 用一次 0.3 s 的碰撞例外让玩家落下去；实心地面上「下 + 跳」仍是
  普通跳跃（第 1 章手感不变）。
- `player.gd` 只在真正按下跳且按住下时做一次薄片形状查询，不在每帧查询。
- 视觉：灰盒面板 + 顶边 + 三个向下小箭头提示可下落；`drop_through=false`
  可关掉下落。

## 2. 塌陷平台 `CollapsingPlatform`

- `scripts/levels/collapsing_platform.gd`（`StaticBody2D`）：`IDLE → WARNING →
  FALLING → GONE → IDLE`。
- 站立检测用平台上方的 `Area2D`（掩码 1，过滤 `player` 组），敌人不会触发。
- 预警：`warn_time` 内颜色向警告色过渡、左右抖动、裂纹随进度增加；之后关闭
  碰撞、视觉下落 `fall_depth`、隐藏，`respawn_time` 后复位。
- `advance(delta)` 公开，单元测试可确定性驱动状态机。
- `game.gd` 在坠落回退和玩家死亡时对 `collapsing_platforms` 组调用
  `reset_now()`，检查点/复活点不会落在已塌的平台上。
- 不改坠落平面解析链：第 27 程的「章节计划 → 房间 metadata → 默认 850」原样。

## 3. 移动平台/电梯 `MovingPlatform`

- `scripts/levels/moving_platform.gd`（`AnimatableBody2D`，`sync_to_physics`）：
  `travel` 是相对作者位置的位移，支持水平、垂直、斜向；`speed` px/s，
  `pause_time` 两端停顿，`ping_pong` 往返。
- 站立玩家由 CharacterBody2D 现有的移动平台逻辑承载（不新增控制器、不改玩家
  参数）。
- 边界：`MDSBigRoom.build()` 把房间并集通过 `set_room_bounds()` 交给子道具；
  行程按并集收紧（`effective_travel`/`travel_clamped`），作者位置本身在并集外
  时原地不动（`outside_bounds`）。相机限制由 MDS 按同一并集设置。
- `position_at_time()` / `progress_at()` 公开，单元测试覆盖往返曲线与截断。

## 4. 长椅检查点 `BenchCheckpoint`

- `scripts/levels/bench_checkpoint.gd`（`Node2D`）：交互半径 96 px，`interact`
  触发；`respawn_position()` = 长椅地面锚点 - 16 px（玩家脚底偏移）。
- `game.gd` 的 `_process` 在商店/宝箱/拾取之后、残碑之前检查长椅；交互后：
  `_last_checkpoint = bench.respawn_position()`、清零速度、HUD 提示、调用现有
  `save_run_now()`。
- **不新增存档键、不改版本**：run save 仍是同一份 `run/world/mds` 结构，续玩
  仍用 MDS 精确坐标；旧档缺键不受影响。
- 第 1 章没有长椅，进房设检查点的代码一字未改。

## 5. 捷径：条件门

- 世界 JSON 的门带 `requires` 时，`MDSBigRoom` 在自动生成 `MDSGate` 的同时生成
  `MDSGateBarrier`（同名作者门优先；作者门存在时不重复生成）。
- 复用 MDS 既有条件（ability/object/boss）与存档（`stored`）；开门状态跨房间、
  跨存档保留。
- 不新增可破坏墙运行时脚本；后续内容确需可破坏墙时另排一程。

## 6. 测试

- 新增单元 `tests/test_vertical_props.gd`：单向落台的碰撞形状/单向标志/组、
  塌陷平台完整状态机与复位、移动平台的往返曲线/正负/越界截断/作者位置越界、
  长椅半径/回位点/提示/计数、玩家跳跃参数未变。
- `tests/test_big_room.gd` 扩展：`MDSBigRoom.build()` 把并集交给移动平台并截断
  越界行程；第 1 章 9 个房间场景仍走旧构建器且不含任何新道具。
- `tests/integration_playability.gd`（结构套件，夹具世界）：单向落台上落/下落/
  下方穿过、实心地面上「下+跳」仍是跳跃、塌陷平台预警/塌落/落地/恢复、垂直
  电梯与水平渡船承载玩家、越界行程截断、条件门生成/解锁/存档。
- `tests/integration_run_save.gd`（真实游戏场景）：长椅交互更新检查点并写 run
  save（版本不变）、坠落回退到长椅、坠落时塌陷平台整组复位、复活后回到长椅
  附近；真实第 1 章实心瓦片地面上「下+跳」仍是普通跳跃。
- 夹具 `tests/fixtures/big_room/world.mdsworld.json` 增加带 `requires` 的
  `shortcut` 门；属测试资产，不是章节内容。临时探针未创建。

## 7. 未做

- 第 2 章地图/房间/世界 JSON/计划/事件/权柄/Boss/敌人美术；章节可达性；二段跳/
  蹬墙跳/攀爬；可破坏墙；打包导出/安装器/签名/安卓。待确认第 9/10 项已由监工
  拍板（大区连通图；不新增移动能力），本程按此施工。
