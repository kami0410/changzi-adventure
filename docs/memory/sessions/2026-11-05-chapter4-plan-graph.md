# 2026-11-05 · 第 4 章计划与图骨架（第 51 程）

> 第 4 章大地图施工第 1 步（对应第 50 程核查 D 节第 1 项）。本程只做计划层：
> 新建计划资源、图骨架夹具与交叉校验测试；不建真实大区世界/房间，不接入
> `game.gd`，不改第 4 章可达性，不写波次/事件/权柄/Boss 内容。
> 第 1–3 章行为与派生结果不变；第 2–4 章仍不可达。
>
> 本程为接力重试：首次尝试（brief53 / session53）因 Magpie 网关中断夭折，
> 日志只有 `[claude-code:unrecognized_model]`，无提交、无文档、无残留；本程从零执行。

## 本程产物

1. **`resources/chapters/chapter_4_demo.tres`**（新文件，9 区连通图，
   `chapter_id = smiling_theater`、`big_map = true`、`start_room = ch4_entry`）：

   | 区 | 类型 | 尺寸 | 遭遇/内容 |
   |---|---|---|---|
   | `ch4_entry` | entrance | 2560×1440 | 无遭遇；注释记录舞台母题仍只在 `TheaterBackdrop` + 绘画、大图呈现待定 |
   | `ch4_branch_a` | branch | 2560×1440 | `Arena`、`Arena2`；宝箱 `Chest1`（对应旧 `ch4_03` 血幕书库） |
   | `ch4_branch_b` | branch | 2560×1440 | `Arena` |
   | `ch4_hub` | hub | 2560×1440 | 休整 + 商店 `ch4_hub_shop` + 残碑 + 捷径解锁 |
   | `ch4_well` | well | 2560×2160 | `Arena`、`Arena2`；宝箱 `Chest1`（对应旧 `ch4_05` 舞台侧廊）；`vertical` |
   | `ch4_vault` | vault | 2560×1440 | 隐藏；宝箱 + 残碑 |
   | `ch4_event` | event | 2560×1440 | `ch4_event/event` 占位（无波次、无文案） |
   | `ch4_elite` | elite | 3840×2160 | `Arena` |
   | `ch4_boss` | boss | 3840×2160 | 末端占位；无 `boss_scene`、无入场/阶段文案 |

   - **清房目标 = 7**：6 个战斗遭遇（支路 A 2、支路 B 1、纵井 2、精英 1）+ 1 个事件占位，
     由 `clear_target()` 按遭遇节点数派生，不写死；第 1 章仍 6、第 2/3 章仍 7。
     旧第 4 章有 6 波（`ROOM_WAVES[3]`），六个战斗遭遇正好按计划顺序一一对应，
     但本程不写 `wave` 表。
   - **3 个宝箱、2 个残碑**：与旧世界同数（旧 `ch4_03` / `ch4_05` / 书库各一箱；
     旧 `ch4_rest` / 书库各一碑），全部 `region/Node` 节点 id。
   - **11 扇门 = 9 双向 + 2 显式单向**：`elite_boss`（进 Boss，不可返回）与
     `hub_shortcut_entry`（枢纽 → 入口捷径，`requires: ["ch4_shortcut"]`，单向）。
     图内有两个回环（入口↔支路↔枢纽、枢纽↔纵井↔精英↔事件），Boss 为末端。
   - **Boss 门取舍**：旧线性世界 `ch4_boss/left1` 可返回 `ch4_rest`；大图计划按
     第 2/3 章先例把 Boss 门做成显式单向（`elite_boss`），旧世界原样保留未改，
     差异写入门与 Boss 区注释，并由测试分别锁定两种行为。
   - **坠落平面**：每区 `fall_below_bounds = 240`，即区高 + 240，沿用第 27 程口径；
     纵井（2160 高）的下层不会被 850 px 规则误杀。
   - **`content_pending = true`**：只推迟 `validate_waves()`；区域字段、节点 id、
     门图照常校验。后续内容程接完 `ROOM_WAVES[3]` 六波后按第 43 程约定清零。
   - **不写的内容**：`wave`、`authority_pool`、`boss_scene`、Boss 入场/阶段文案、
     事件文本/效果、`ch4_shortcut` 授予来源、敌人独立数值。计划里只有明确标注的占位。
2. **`tests/fixtures/big_room/ch4_graph.mdsworld.json`**（图骨架夹具）：
   顶层 `fixture: true` + `content_pending: true`，无 `scene_path`、无房间场景、
   游戏从不引用；镜像旧世界区域 `Smiling Theater` 的灰烬/光柱与
   `boss_background=blood_moon`，不写 `backdrop_image`（不为舞台母题预设方案）。
   20 扇有向门 + 2 扇到达门，与计划的 11 条门记录互校；顶层注释记录舞台母题、
   `ch4_shortcut` 来源、`Ch4EventData`、Boss 4 机制/文案、战斗密度、
   `mask_enemy`/`seat_husk` 独立数值与 Boss 单向门取舍均待后续程/拍板。
3. **`tests/test_ch4_plan.gd`**（778 断言）：计划形状/类型/尺寸/坠落平面/内容 id/
   清房目标/图可达性/单向门/捷径占位/待内容标记 + `content_pending` 只推迟波次表
   （关掉标志必须报六条缺波次）+ 6 场战斗 ↔ `ROOM_WAVES[3]` 六波按计划顺序对应
   （事件节点无波次）+ 计划↔夹具逐区逐门交叉校验 + 夹具几何（不重叠、门在正确边、
   门位在房间内、区域相邻、捷径不邻接）+ 第 1–3 章计划不变 + 旧第 4 章世界不变
   （9 房/17 门/7 right/7 left/3 door/Boss 门仍返回休息区）+ `game.gd` 路由槽仍为空、
   旧世界仍被使用、`ch4_bigmap` 目录尚未创建。
4. **路由锁同步**：`tests/test_ch2_world.gd`、`tests/test_ch3_content.gd`、
   `tests/integration_playability.gd` 在既有「第 4 章计划槽为空」断言旁补
   「计划资源已存在但未接入」——空槽现在是路由决策，不是缺文件。
   无计划时清房目标 6 / 坠落平面 850 的行为断言仍原样成立（本程未接 `game.gd`）。

## 与旧第 4 章内容的对应

旧 9 房（6 战斗 + 休整 + Boss + 书库）被组织为 9 个大区：入口对应剧场前厅；
支路 A 容纳笑面回廊两场、支路 B 对应空座中庭、纵井对应舞台侧廊（两场）、
精英区对应血幕书库；休整、Boss、书库沿用原角色。事件区是结构占位
（旧第 4 章没有事件房），为后续 `Ch4EventData` 留节点。旧世界
`chapter_4.mdsworld.json` / `chapter_4_world.tscn` 与 9 个 `MDSChapterRoom`
场景未改、未删、仍被游戏使用。

## 待确认项与开放问题（本程全部留空）

- **舞台母题（第 50 程专节 E 候选）**：未给大区管线加 theater 层、未改
  `TheaterBackdrop`、未新绘背景；计划入口区注释与夹具顶层注释只记录现状
  （聚光灯/地面光斑/浮尘 + `smiling_theater.png`）与「待定」。
- **`ch4_shortcut` 来源**：未新增任何授予交互/事件/掉落；捷径门只有
  `requires: ["ch4_shortcut"]` 的封闭占位，注释写明来源待拍板；
  `game.gd` 源码仍不含 `ch4_shortcut`（测试锁定）。
- **是否新增事件区**：本程按第 2/3 章先例加了结构占位区（清房目标 7），
  但未写 `Ch4EventData`、未加触发；事件文案/效果留待内容程。
- **Boss 4 机制范围**：未做、未设计。计划不写 `boss_scene`，旧
  `boss_script == "smiling"` 分支与 `SmilingArchivist` 场景/数值原样保留；
  剧情圣经三阶段「改写规则/删除词/复制武器」与 GDD「舞台机关」的差距只记录。
- **战斗密度**：本程不扩波、不增遭遇；旧世界每房 5–6 只 vs 大图每遭遇 2 只
  （`ROOM_WAVES` 单波）的差异只记录，留待内容程/拍板。
- **`mask_enemy`/`seat_husk` 独立数值与行为**：未做；计划不写敌人数值，
  两者仍是第 1 章敌人的美术变体（共享场景/数据）。
- **章末边界**：未改 `_complete_chapter`；第 4 章是最后一章、章末已走
  `_finish(true)`。第 3 章停章替身（`_chapter == 2` → `_finish(true)`）
  须在可达性拍板后解开，是本阶段前置。
- **阿砚同行**：未做；仓库仍无 companion/follower 控制器，只在本记录重申缺失。

## 验证（收尾）

- 基线（HEAD `b1af454`，Godot 4.7.stable.official.5b4e0cb0f）：
  `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0；单元 **10315 / 0**；
  十套集成 **754 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209 / 4235** 全 0 失败；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与交接一致，无漂移。
- 改动后：单元 **11095 / 0**（+780：`test_ch4_plan.gd` 778 + 两处路由锁 2）；
  可玩性集成 **755 / 0**（+1 路由锁），其余九套不变；`--import`/`--quit` 退出 0、
  `ERROR` 0；退出泄漏 **10/10 clean**；像素资产 **36 / 0**。
- 临时探针：本程未写探针脚本；工作区收尾干净。

## 未做（按任务单）

第 4 章真实大区世界/房间（`resources/rooms/ch4_bigmap/`、`scenes/mds/ch4_bigmap/`、
世界 JSON/场景）、`Ch4EventData`、波次接线、权柄池、Boss 4 机制/`boss_scene`/
入场与阶段文案/专项测试、第 4 章大图验收套件、第 2–4 章可达性、第 11/12/13 项
相关数值/相机/HUD、第 14/15/16 项机制、阿砚同行、新移动能力、NPC 立绘、
MDS 插件本体、敌人/场景美术、打包/导出/安装器/签名/安卓/触屏。
