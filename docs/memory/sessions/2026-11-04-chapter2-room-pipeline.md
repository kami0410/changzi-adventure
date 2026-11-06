# 2026-11-04 · 第 2 章大地图施工第 2 步：房间生产管线（第 28 程）

> 只做管线：未创建/调整第 2 章地图、房间、世界 JSON、房间计划、事件、权柄或
> Boss 内容，未改章节可达性，未新增移动能力，未改 MDS 插件本体。第 1 章仍走
> `MDSChapterRoom`，全部基线数字不变。「待用户确认」第 9/10 项保持开放，本管线
> 对「大区图 + 短过渡」与「字面单场景无缝」两种口径都成立（房间仍是 MDS 加载
> 单元，可变尺寸、多层均可）。

## 1. 新增 `BigRoomData` + `MDSBigRoom`

- `scripts/levels/big_room_data.gd`（`BigRoomData`，Resource）：
  - `size` 为无 MDS 父节点时的后备尺寸；在 MDS 世界里以房间局部矩形并集为准。
  - `ground`：`{x, y, width, height=64}`，`x` 左缘、`y` 可行走面、`height` 下方填充；
    多层地面就是不同 `y` 的地面条目（梯田）。
  - `platforms`：`{x, y, width}`，固定 16 px 厚。
  - 有 `tile_set` 时按 16 px 网格吸附；可选 4 个瓦片坐标与灰盒颜色。
  - 背景：`backdrop_path` / `backdrop_texture`、整数 `backdrop_scale`、像素/绘画
    过滤、`backdrop_modulate`。
  - 氛围：`ambient_kind`（none/motes/embers）、`ambient_color`（透明则取区域色）、
    `ambient_density`。
- `scripts/levels/mds_big_room.gd`（`MDSBigRoom`，Node2D）：
  - `_ready` 读取 `data` / `data_path` 后 `build()`；`build()` 可重复调用（先清理
    自己生成的节点，保留作者子节点）。
  - 从父 `MDSWorldGame` 读取当前房间的局部矩形并集、区域、天气/动态背景/视差；
    相机限制仍由 MDS 的 `apply_camera_limits` 按并集设置。
  - 地面/平台：`TileMapLayer` 只做视觉（`collision_enabled=false`），碰撞用每段
    地面/平台一个 `StaticBody2D` + `RectangleShape2D`；大房间不会每格一个碰撞体。
  - 静态背景按并集宽度平铺（2560 宽用 2 列 1280 图，3840 宽用 3 列），
    平铺覆盖整个并集而不是单屏。
  - `auto_gates=true` 时按世界 JSON 的 `gates` 生成 `MDSGate`（TOUCH/INTERACT、
    侧向碰撞形状、门提示）；同名作者门优先。
  - 写入房间 metadata `fall_below_bounds`（默认 200 px），接第 27 程
    `game.gd` 的坠落平面解析链；章节计划仍优先。
- `scripts/presentation/big_room_ambient.gd`（`BigRoomAmbient`）：只绘制相机窗口
  与房间并集的交集（外加 64 px 余量），默认取 MDS 区域色；`motes` 横漂、
  `embers` 上升，默认关闭，不复制 MDS 天气。

## 2. 可达性校验（不超过现有跳跃能力）

- `BigRoomData.MAX_JUMP_HEIGHT = 500² / (2×1350) ≈ 92.6 px`，与 `player.gd` 的
  `jump_velocity=-500`、`gravity=1350` 对齐；单元测试直接实例化 `Player` 比较。
- `MAX_STEP = 80 px`：每个表面到其「攀爬来源面」（下方最近、水平重叠或边缘
  ≤120 px 的表面）的高差不得超过 80，留约 12 px 输入余量。
- `MAX_HORIZONTAL_STEP = 120 px`：80 px 上升时跳跃水平航程约 150 px，扣除身位与
  落点余量后的上限。
- `validate()` 还拒绝越界、缺字段、非正宽高、无下方支撑的悬空平台；构建器把问题
  写进 `validation_errors` 并 `push_warning`，不静默丢几何。

## 3. 测试

- 新增单元 `tests/test_big_room.gd`（**73** 断言）：
  - 跳跃常量与 Player 实际导出值一致；80 px 通过、84 px 失败；水平 120 通过、
    121 失败；悬空平台、越界、坏字段、零尺寸、世界边界覆盖 `size`。
  - 吸附：浮点几何不吸附；有 tileset 时地面 `(10,647,100×30) → (0,640,112×32)`、
    平台 `(30,100,50) → (16,96,64×16)`。
  - 构建：两层地面 + 两层平台、碰撞体位置/尺寸/层、灰盒视觉、坠落 metadata。
  - 平铺：400×300 图覆盖 1600×900 → 12 块；缩放 2 → 4 块且覆盖 1600×1200；
    像素/绘画过滤。
  - 瓦片路径：TileMapLayer 存在、无碰撞、地面 30 格/填充 30 格、平台 10/10，
    矩形碰撞仍在，且不再生成灰盒。
  - 氛围：motes/embers、区域色、默认关闭。
  - 第 1 章：9 个 `ch1_*.tscn` 全部仍是 `MDSChapterRoom`，没有房间切到新管线；
    `WIDTH=1280`、`FLOOR_Y=560` 不变。
- 结构集成新增 **55** 断言（`tests/integration_playability.gd`），使用永久夹具
  `tests/fixtures/big_room/`（不是章节内容）：
  - 2560×1440 房间：MDS 并集边界、相机四边限制、两层地面 + 4 层平台。
  - 真实 `Player` 下落落点：底层地面、梯田、1200/1040/960 三层平台。
  - 背景：区域 `Wide Ruins` 的 1280×720 图铺 4 块覆盖 2560×1440；天气含
    `fireflies`、动态背景 `aurora`，且 `MDSWeather`/`MDSBackground` 已挂上。
  - 门：世界 JSON 生成 `right1`（TOUCH，位置正确）与 `door1`（INTERACT，带
    「按 … 进入」提示）。
  - 氛围：相机窗口小于房间并集、随玩家移动、始终在并集内。
  - L 形房间：两个局部矩形、并集 3840×1440、缺口外不可行走、缺口内第二矩形可
    行走、相机限制为世界 2560..6400；`Lower Vault` 的 mid 背景铺 6 块覆盖
    3840×1440、天气含 `embers`、动态背景 `ember_glow`；真实落点在第二矩形的
    地面与平台都正确。

## 4. 验证

- 单元 **5779 / 0**（基线 5706 + 61 + 12）。
- 八套集成全部 0 失败：结构 **351**（基线 296 + 55）、第一章 demo **101**、
  run save **561**、手柄 **207**、UI 提示 **113**、第一章事件 **59**、
  菜单 A/B **391**、AI 设置 **45**。
- `--headless --import` / `--quit` 退出 0、`ERROR` 0；退出泄漏 **10/10 clean**；
  demo 像素资产 **36 / 0**；临时探针未创建，测试夹具保留在 `tests/fixtures/`。
- 未改第 2 章世界 JSON/场景/计划/可达性，未新增移动/移动平台/塌陷平台/单向落台。
