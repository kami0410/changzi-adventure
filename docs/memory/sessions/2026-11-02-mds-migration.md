---
name: 2026-11-02-mds-migration
description: 0.9.2 MDS 全四章迁移：32 房世界、门/相机/地图、game.gd 接线与验证
type: session
status: active
updated: 2026-11-02
load_when: 继续 MDS、改章节房间/门/地图、接快旅/存档时
---

# MDS 全四章迁移（0.9.2）

依据：[MDS 全量接入 ADR](../decisions/2026-11-02-mds-full.md) 与
[MDS 调研](../../research/metroidvania-developer-system.md)。

## 交付

- 世界文件 `scenes/mds/chapter_1..4.mdsworld.json`，每章 8 个 1280×720 房间（横向 0..8960）：
  6 个战斗房、1 个休整房（残碑 + 商店）、1 个 Boss 房，共 **32 间**。
  房间之间有 `left1/right1` 门；每章有独立区域天气与 Boss 动态背景：
  - 第一章：雾 + 灰烬，`void_pulse`；背景 `ink_archive.png`。
  - 第二章：孢子雾 + 萤火，`spore_drift`；背景 `breathing_ruins.png`，`LivingBackdrop.breathing`。
  - 第三章：海雾 + 雨，`deep_water`；背景 `lightless_sea.png`，`LivingBackdrop.sea`。
  - 第四章：灰烬 + 光柱，`blood_moon`；背景 `smiling_theater.png` + `TheaterBackdrop`。
- 房间场景 `scenes/mds/ch1_*.tscn` … `ch4_*.tscn`（32 个）+ `scripts/levels/mds_chapter_room.gd`：
  按 `chapter_index` 选择背景/氛围；统一生成地面、平台、`ArenaRoom`、宝箱/残碑/商店、`MDSGate`；
  每章第一间有 save_point（x=40，位于战斗区外），其余房间从门内侧 120 px 进入。
- `scenes/mds/chapter_1..4_world.tscn`：四个 `MDSWorldGame`，`room_darkness=false`、
  天气/动态背景开、玩家与相机由 `game.gd` 注入。
- `game.gd`：
  - `_setup_campaign` 隐藏/禁用全部四个旧线性 `Level`，只保留为休眠 fallback。
  - `_start_chapter(index)` → `_start_mds_chapter(index)`：剧情后实例化对应章节的 MDS 世界，
    `process_mode=PAUSABLE`；四章循环切换。
  - `_on_mds_room_loaded(room_id)`：把当前 `ArenaRoom` 注册进 `_rooms`，按 `chapter["rooms"]`
    和 `ROOM_WAVES[0]` 生成敌人；Boss 房生成 `InkArchivist`；残碑/商店/宝箱按房间节点收集；
    已清房间（`_mds_cleared_rooms`）不再生成/锁门。
  - `_on_mds_room_loaded` 用 `_chapter` 选择 `ROOM_WAVES[_chapter]`/`CampaignData.chapter(_chapter)`；
    门的真实切换已在每章集成测试中验证（`MDSGate.use()` → 下一房）。
  - 每章结束仍走现有 `_complete_chapter`；下一章 `_teardown_mds()` 后加载新世界。
- 地图：`scripts/ui/map_overlay.gd` + `MDSWorldMapView`，`M` 打开/关闭；`set_world()` 随章节切换
  world file，已访问房间点亮，地图随 `MDSWorldGame` 自动更新。
- 输入：`project.godot` 新增 `map` = M；HUD/操作说明已列出。

## 验证

- 单测 3040/0；集成 **222/0**，四章都覆盖：MDS 起始房、6 房清怪/奖励、休整房商店/残碑、Boss、
  每章真实 MDS 门切换、章节转场、地图打开/揭示。
- 截图：`artifacts/mds/mds_01_entry.png`…`mds_06_map.png`（第一章，`tests/capture_mds.gd`）；
  `ch1_ink_archive.png`、`ch2_breathing_ruins.png`、`ch3_lightless_sea.png`、`ch4_smiling_theater.png`
  及各自 `chN_boss.png`（`tests/capture_mds_chapters.gd`）。
- 版本 0.9.2，versionCode 11；Windows release 135.5 MiB、Android debug 58.9 MiB（debug 签名，可装试玩机）。
- 四章共 32 个 MDS 房间；旧线性 `Level..Level4` 仍留在 main.tscn 中但被隐藏/禁用，作为 fallback。

## 设计注意

- MDS 房间是脚本生成，不是编辑器手绘地形；MDS 编辑器可编辑世界图/门/天气，但房间内容在
  `mds_chapter_room.gd`。后续若要“画房间”，需要把房间内容迁到 .tscn/TileMap。
- 章节坐标：MDS 一章一个世界（0..8960），不再与 `CHAPTER_WIDTH=12000` 线性章节共用坐标；
  迁移二至四章时应各自建 world file，而不是拼一张 48000 px 大地图。
- 清房记录在 `_mds_cleared_rooms`（本局内存）；回溯已清房间不会重复刷怪。跨局/存档的
  已探索状态尚未接 `Profile`/MDS exploration file。
- 快旅/链接（MDS `links`）尚未启用；地图先做“看”，不做“点房间传送”。

## 下一步

- 把 `_mds_cleared_rooms` 与 MDS 的 `defeated_ids`/存档合并；地图探索写入 Profile。
- 加 MDS links 做休整房 ↔ 前厅快旅，并配合 `enforce_requirements`。
- 按四章房间图做节奏/敌人组合/宝箱位置重做，然后真人试玩。
- 四章目前共用 8 房模板，后续可按生态区做不规则的 MDS 房间形状与专属装饰。
