# 2026-11-05 第 49 程：第 3 章大图门视觉专项与敌人美术核查

## 背景

第 48 程完成第 3 章大地图系统验收后，第 3 章只剩两项已知缺口：① 门视觉专项（第 37 程对第 2 章做过的同类工作）；② 地图标题/敌人美术核查（第 38 程对第 2 章做过的同类工作）。本程只做这两项表现/美术审计，不动门逻辑、不接入 `game.gd`、不开放可达性、不碰待确认第 11–16 项。

## 任务 0 · 基线核验

HEAD `28ee4c1`，工作区干净，Godot 4.7.stable.official.5b4e0cb0f。

- `--headless --import` / `--quit` 退出 0、`ERROR` 0。
- 单元 **10207 / 0**；十套集成 **754 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209 / 3424** 全 0 失败；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。
- 与第 48 程交接一致，无基线漂移。

## 任务 1 · 第 3 章大图门视觉

### 核查（先查后做）

- 第 37 程的 `GateVisual` 不是第 2 章专用代码：`MDSBigRoom._build_gates()` 生成自动门后统一调用
  `_add_gate_visuals()`，遍历房间内所有 `MDSGate`（自动门 + 作者门）补视觉。
- 第 41 程的 9 个第 3 章场景全部使用 `scripts/levels/mds_big_room.gd`、`auto_gates` 全开，
  因此 22 扇门（20 有向 + 2 仅到达）已被通用管线自动覆盖；**无需另起视觉实现**。
- 22 扇构成（世界文件事实）：`left` 5、`right` 5、`top` 5、`bot` 5、中置 `door` 2；
  仅到达门 = `ch3_entry/shortcut_arrival`（door）与 `ch3_boss/left1`（left）。

### 逐门断言（扩展 `tests/integration_ch3_bigmap.gd`）

在既有每门断言（存在、可见、side、caption 非空、前往/来路文案、零碰撞、非 CollisionObject2D）之上新增：

- 视觉不移动门：`marker.position == Vector2.ZERO`。
- 门底落面：left/right/door 门的 `floor_offset` 使门底等于门下方真实地面/台阶面
  （`built_ground_surfaces` / `built_platform_surfaces` 现算）；bot 舱口 offset = 0 且门位就在地面线上；
  top 舱口贴房间顶、向下展开且不越界。左右门与中置门的门扉矩形保持在房间内。
- 标题内收与高度：right 标题 `x = -CAPTION_WIDTH`、left `x = 0`、top/bot/door 居中，
  再按房间内缩矩形夹取；y 按 side 规则（左右门在门上方、top 在舱口下、bot 在舱口上）；
  标题矩形必须落在房间边界内。
- 有向门 `arrival == false`（绘制路径据此画朝向箭头），仅到达门 `arrival == true`（标「来路」、不画箭头）。
- 汇总：22 门 = 20 有向 + 2 到达；side 直方图 5/5/5/5/2。计数按房间覆盖写，重访不累加。

### 发现并修复的真实缺陷：舱口贴墙时标题框越界

- 现象：`ch3_well/top1` 门位 x = 80，天花板舱口标题按门中心居中（200 px 宽），
  标签框左边为 x = −20，越出房间左边界 20 px。第 2 章 `ch2_well/top1`（同样 x = 80）同源。
- 根因：第 37 程「边上门的标题向房间内对齐」只实现在 `_caption_x()` 的 left/right 分支；
  top/bot 分支直接返回居中值，未按房间边界内收。
- 修复（纯表现层、共享逻辑一次修好两章）：
  - `GateVisual` 新增可选 `caption_area`（marker 局部坐标、已按标题尺寸内缩的房间矩形）；
    非空时 `_caption_x()` / `_caption_y()` 把标题夹进该矩形，空值保持原 side 规则。
  - `MDSBigRoom._add_gate_visuals()` 给每个 marker 传 `room_bounds - Vector2(CAPTION_WIDTH, CAPTION_HEIGHT)`。
  - 影响：`ch3_well/top1` 与 `ch2_well/top1` 的标题内收 20 px；其余门标题位置不变
    （左右门原本就在房间内，中置门照旧）。
- 回归断言：`test_big_room` 新增舱口内收 x / y 两条；第 3 章集成逐门断言
  `caption_rect` 必须被 `room_bounds.encloses()`（修复前该断言在 `ch3_well/top1` 会失败）。
- 记录：已补进 [大区门视觉 ADR](../decisions/2026-11-05-big-map-gate-visuals-spawn.md)「补充（第 49 程）」。

### 不变边界

- 纯 `Node2D`（`z=-1`），无碰撞/信号/输入；门位、模式、单向语义（`ch3_elite/right1` 进 Boss 不可返回）、
  `requires`/`MDSGateBarrier`（`ch3_hub/shortcut` 默认封闭）、过渡目标一字未改。
- 第 1 章无 `GateVisual`；第 2 章 22 扇门断言仍 2209 / 0；第 3 章仍不可达。

## 任务 2 · 第 3 章敌人美术核查

### 核查结果（以 `ROOM_WAVES[2]` 六波实际引用为准）

| 敌人 | 来源 | 专属精灵 | 现状 | 结论 |
|---|---|---|---|---|
| `mirror_sniper` | 第 3 章专属 | `assets/sprites/enemies/mirror_sniper.png` | 已在 `ENEMY_ART`，不在回退表 | 已接线，白 tint；测试锁定 |
| `hanging_scribe` | 沿用第 1 章 | `hanging_scribe.png` | 已在 `ENEMY_ART` | 白 tint |
| `echo_enemy` | 沿用第 1 章 | `echo_enemy.png` | 已在 `ENEMY_ART`；数据资源名为 `amnesiac_echo.tres` | 白 tint |
| `typo_beast` | 沿用第 1 章 | `typo_beast.png` | 已在 `ENEMY_ART` | 白 tint |
| `page_swarm` | 沿用第 1 章 | `page_swarm.png` | 已在 `ENEMY_ART` | 白 tint |
| `rust_whisperer` | 沿用第 2 章 | 无 | 回退 `scribe_bug` | 缺口，`#c8e1cd` 回退 |
| `lung_moth` | 沿用第 2 章 | 无 | 回退 `hanging_scribe` | 缺口，`#c8e1cd` 回退 |
| `collapse_husk` | 沿用第 2 章 | 无 | 回退 `blank_man` | 缺口，`#c8e1cd` 回退 |

- 六波实际引用 8 种敌人：5 种有专属 PNG 并已接线，3 种无专属美术（与第 38 程第 2 章缺口清单一致）。
- 3 个缺失敌人在 `assets/concept/enemies/` 也没有原图（该目录只有 `choir_summoner`、`ink_bomber`、
  `mirror_sniper`、`page_swarm` 的 raw 图）。按任务单不新绘、不拼凑、不猜测。
- `echo_enemy` 是刷怪/场景 id，其数据资源沿用旧名 `amnesiac_echo.tres`（`id = amnesiac_echo`）；
  美术接线按刷怪 id 走 `ENEMY_ART`，已用测试锁死别名。

### 测试锁定

- `tests/test_enemy_art.gd` 扩到 **200 断言**（原 94，+106）：
  - 第 3 章 8 种敌人都有场景、唯一美术来源、数据资源存在（含 `echo_enemy` 别名）；
  - 5 种已接线敌人用自己的 PNG、不在回退表、tint 为白；
  - 3 种缺失敌人仍在回退表、回退源是第 1 章美术、tint 为 `ENEMY_FALLBACK_TINT`，
    且标准路径 `<id>.png` 尚不存在（日后补图未接线会失败）；
  - 审计集合由 `ROOM_WAVES[2]` 现算：8 种逐个核对，波次若引入未审计敌人即失败。
- `tests/integration_ch3_bigmap.gd` 在真实遭遇中锁定实际生成结果：
  `ch3_branch_a/Arena` 的 `mirror_sniper`、`hanging_scribe` 用各自 PNG 且白 tint；
  `Arena2` 的 `rust_whisperer`、`lung_moth` 用第 1 章回退图与 `#c8e1cd`。

### 地图标题复核

- 第 38 程的派生规则未动；第 3 章集成既有断言 `scene._map_overlay.title_text() == "无光海地图"`
  本程复跑仍成立，`CampaignData.chapter(2)["region"] == "无光海"`。第 1 章「档案馆地图」未改。

## 验证

- 基线：单元 10207 / 0；十套集成 754 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209 / 3424 全 0 失败。
- 改动后：
  - 单元 **10315 / 0**（+108：敌人美术 94 → 200 即 +106；`test_big_room` 111 → 113 即 +2）。
  - 第 3 章大图集成 **4235 / 0**（3424 → 4235，+811；逐门/逐区重访累计）。
  - 第 2 章大图集成 **2209 / 0**（共享门视觉改动无回归）。
  - 其余八套集成与基线一致、全 0 失败；`--import` / `--quit` 退出 0、`ERROR` 0；
    退出泄漏 10/10 clean；demo 像素资产 36 / 0。
- 未改产品玩法/门逻辑/敌人贴图；第 1/2 章敌人美术与波次未改；第 3 章仍不可达。

## 未做

第 3 章可达性（须单独拍板，且不早于第 2 章）；`CHAPTER_PLAN_PATHS[2]` 接入；待确认第 11–16 项
（`ch2_shortcut`/`ch3_shortcut` 来源、电梯节奏、大区底部相机/HUD、视野压缩、海面母题）；
3 个缺失敌人的专属美术（无现成素材，不新绘）；阿砚同行；新移动能力；NPC 立绘；MDS 插件；
打包/导出/安装器/签名/安卓/触屏。临时探针已删除。
