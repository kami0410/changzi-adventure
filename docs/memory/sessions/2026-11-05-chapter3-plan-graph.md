# 2026-11-05 · 第 3 章计划与图骨架（第 40 程）

> 第 3 章大地图施工第 1 步（对应第 39 程核查 C 节第 1 项）。本程只做计划层：
> 新建计划资源、图骨架夹具与交叉校验测试；不建真实大区世界/房间，不接入
> `game.gd`，不改第 3 章可达性，不写波次/事件/权柄/Boss 内容。
> 第 1/2 章行为与派生结果不变；第 2–4 章仍不可达。

## 本程产物

1. **`ChapterPlanData.content_pending`**（向后兼容，新增 `@export bool`，默认 `false`）：
   计划结构先于内容落地时置 `true`，`validate()` 仍校验区域字段、节点 id 与门图，
   只跳过 `validate_waves()` 的波次表。第 1/2 章计划保持 `false`，校验结果不变；
   第 3 章在内容程接线波次后应改回 `false`。测试用同一计划的 `duplicate()` 把标志
   关掉，验证它仍会报出六条「encounter … needs a wave」，证明跳过范围是局部的。
2. **`resources/chapters/chapter_3_demo.tres`**（新文件，9 区连通图）：

   | 区 | 类型 | 尺寸 | 遭遇/内容 |
   |---|---|---|---|
   | `ch3_entry` | entrance | 2560×1440 | 无遭遇；注释记录第 14/15 项待拍板 |
   | `ch3_branch_a` | branch | 2560×1440 | `Arena`、`Arena2`；宝箱 `Chest1` |
   | `ch3_branch_b` | branch | 2560×1440 | `Arena` |
   | `ch3_hub` | hub | 2560×1440 | 休整 + 商店 `ch3_hub_shop` + 残碑 + 捷径解锁 |
   | `ch3_well` | well | 2560×2160 | `Arena`、`Arena2`；宝箱 `Chest1`；`vertical` |
   | `ch3_vault` | vault | 2560×1440 | 隐藏；宝箱 + 残碑 |
   | `ch3_event` | event | 2560×1440 | `ch3_event/event` 占位（无波次、无文案） |
   | `ch3_elite` | elite | 3840×2160 | `Arena` |
   | `ch3_boss` | boss | 3840×2160 | 末端占位；无 `boss_scene`、无入场/阶段文案 |

   - **清房目标 = 7**：6 个战斗遭遇（支路 A 2、支路 B 1、纵井 2、精英 1）+ 1 个事件占位，
     由 `clear_target()` 按遭遇节点数派生，不写死。旧第 3 章有 6 波（`ROOM_WAVES[2]`），
     六个战斗遭遇正好一一对应，但本程不写 `wave` 表。
   - **3 个宝箱、2 个残碑**：全部 `region/Node` 节点 id（支路 A/纵井/书库各一箱；
     枢纽/书库各一碑）。
   - **11 扇门 = 9 双向 + 2 显式单向**：`elite_boss`（进 Boss，不可返回）与
     `hub_shortcut_entry`（枢纽 → 入口捷径，`requires: ["ch3_shortcut"]`，单向）。
     图内有两个回环（入口↔支路↔枢纽、枢纽↔纵井↔精英↔事件），Boss 为末端。
   - **坠落平面**：每区 `fall_below_bounds = 240`，即区高 + 240，沿用第 27 程口径；
     纵井（2160 高）的下层不会被 850 px 规则误杀。
   - **不写的内容**：`wave`、`authority_pool`、`boss_scene`、Boss 入场/阶段文案、
     事件文本/效果、`ch3_shortcut` 授予来源。计划里只有明确标注的占位：
     事件区注释指向后续 `Ch3EventData`，Boss 区注释说明 `boss_scene` 路由留待内容程，
     捷径门注释写明授予来源待拍板（第 16 项）且默认不可通行。
3. **`tests/fixtures/big_room/ch3_graph.mdsworld.json`**（图骨架夹具）：
   顶层 `fixture: true` + `content_pending: true`，无 `scene_path`、无房间场景、
   游戏从不引用；镜像旧世界区域 `Lightless Sea` 的雾/雨与 `boss_background=deep_water`，
   不写 `backdrop_image`（不为第 15 项海面母题预设方案）。
   20 扇有向门 + 2 扇到达门，与计划的 11 条门记录互校。
4. **`tests/test_ch3_plan.gd`**（728 断言）：计划形状/类型/尺寸/坠落平面/内容 id/
   清房目标/图可达性/单向门/捷径占位/待内容标记 + 计划↔夹具逐区逐门交叉校验 +
   夹具几何（不重叠、门在正确边、门位在房间内、区域相邻、捷径不邻接）+
   第 1/2 章计划不变 + `game.gd` 路由槽仍为空 + 第 3 章旧世界文件仍在。

## 与旧第 3 章内容的对应

旧 9 房（6 战斗 + 休整 + Boss + 书库）被组织为 9 个大区：入口对应无光海岸；
支路 A 容纳墨潮浅滩/沉船书库两场、支路 B 对应静水回廊、纵井对应深渊裂口
（两场）、精英区对应第三页之门；休整、Boss、书库沿用原角色。事件区是结构占位
（旧第 3 章没有事件房），为后续 `Ch3EventData` 留节点。旧世界 `chapter_3.mdsworld.json`
/`chapter_3_world.tscn` 与 9 个 `MDSChapterRoom` 场景未改、未删、仍被游戏使用。

## 待确认项（本程全部留空）

- **第 14 项 视野压缩**：未实现、未预设数值/机制；计划入口区注释与夹具顶层注释均记「待拍板」。
- **第 15 项 海面母题**：未给大区管线加 sea 层、未改 `LivingBackdrop`、未新绘背景；
  夹具只镜像旧世界区域（无 `backdrop_image`），不预设方案。
- **第 16 项 `ch3_shortcut` 来源**：未新增任何授予交互/事件/掉落；捷径门只有
  `requires: ["ch3_shortcut"]` 的封闭占位，注释写明来源待拍板；
  `game.gd` 源码仍不含 `ch3_shortcut`（测试锁定）。
- **章末边界**：第 3 章仍会自动进第 4 章，本程未改；留待章末收口程。

## 验证（收尾）

- 基线（HEAD `01c29d5`，Godot 4.7.stable.official.5b4e0cb0f）：
  `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0；单元 **8011 / 0**；
  九套集成 **671 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209** 全 0 失败；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与交接一致，无基线漂移。
- 改动后：单元 **8739 / 0**（+728，全部来自 `test_ch3_plan.gd`）；
  九套集成与基线一致（计划未接入游戏，无行为变化）；`--import`/`--quit` 退出 0、
  `ERROR` 0；退出泄漏 **10/10 clean**；像素资产 **36 / 0**。
- 临时探针：本程未写探针脚本；工作区收尾干净。

## 未做（按任务单）

第 3 章真实大区世界/房间（`resources/rooms/ch3_bigmap/`、`scenes/mds/ch3_bigmap/`、
世界 JSON/场景）、`Ch3EventData`、波次接线、权柄池、Boss 3 机制/`boss_scene`/
入场与阶段文案、第 3 章大图验收套件、第 2–4 章可达性、第 11/12/13 项相关数值/相机/HUD、
第 14/15/16 项机制、阿砚同行、新移动能力、NPC 立绘、MDS 插件本体、敌人/场景美术、
打包/导出/安装器/签名/安卓/触屏。
