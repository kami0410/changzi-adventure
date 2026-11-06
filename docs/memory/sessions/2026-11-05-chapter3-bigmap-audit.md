# 2026-11-05 · 第 3 章大地图可行性核查（第 39 程）

> 只查不施工：未改第 3 章可达性，未新建计划/大区/房间/事件/权柄/Boss 内容，未改
> `game.gd` 章节路由，未新增移动能力。完整表格与依据见 `SUPERVISOR_STATUS.md`
> 「第 3 章大地图可行性核查」专节。临时探针 `tests/tmp_ch3_audit.gd` 测后删除。
>
> 标记：**【已核实】** 读代码/资源或实跑探针可复现；**【推断】** 由已核实事实推导、
> 尚未实跑；**【待施工验证】** 必须等真实大图内容落地后才能定论。

## 结论

- **第 2 章走通的大区连通图路线可以直接承载第 3 章，不需要改 MDS、存档或战斗框架。**
  `BigRoomData` + `MDSBigRoom` 不含任何章节判断；第 27 程的按节点 id 结算、按区域坠落平面、
  计划派生清房目标对第 3 章同样适用。第 3 章现有旧世界可像第 2 章旧世界一样原地保留、
  不再引用。**【已核实】**
- **真正的缺口在内容层，不在引擎层**：第 3 章没有计划（`chapter_3_demo.tres` 不存在、
  `CHAPTER_PLAN_PATHS[2]` 为空）、没有大区/房间数据、没有事件数据、没有权柄池、
  没有 Boss 入场/阶段文案、没有第 3 章大图验收套件；这些与第 2 章施工前的缺口同类。
  **【已核实】**
- **第 3 章比第 2 章多出的差异点**：① 无光海的海面母题目前只由 `MDSChapterRoom` 的
  `LivingBackdrop(sea=true)` 提供，大区管线没有对应层；② GDD §11 的「视野压缩」没有任何
  实现；③ 现有捷径门是无条件交互门，大图 `shortcuts` 需要 `ch3_shortcut` 授予来源；
  ④ Boss「最后的读者」已有专属脚本/场景/立绘/背景/语音与部分独特攻击，但走
  `boss_script` 旧分支、无计划 `boss_scene`、无入场/阶段文案、无测试锁定。
  **【已核实】**（视觉损失与视野压缩的实际观感为 **【待施工验证】**）
- **施工顺序**沿用第 2 章：计划/图骨架 → 真实大区世界 → 内容数据层 → Boss 机制 →
  系统验收；每步前置依赖见下。第 3 章可达性仍须单独拍板，且不能早于第 2 章。

## A. 第 3 章现有内容盘点（全部已核实）

### 世界与房间

- `scenes/mds/chapter_3_world.tscn` + `chapter_3.mdsworld.json`：9 个 MDS 房间、17 扇门
  （7 right / 7 left / 3 door）、`links`/`pins` 为空、`start_room = ch3_01`。
- 全部 **1280×720 单矩形、单层地面**（地面面 y=560，StaticBody 80 px），平台按
  `platform_pattern` 0/1/2 建 2/2/1 块；没有多矩形、没有多层、没有纵向结构。
- 房间清单：

| 房间 | 名称 | 类型 | 内容 | 门 |
|---|---|---|---|---|
| `ch3_01` | 无光海岸 | 战斗 | 无 | right1 |
| `ch3_02` | 墨潮浅滩 | 战斗 | 无 | left1/right1 |
| `ch3_03` | 沉船书库 | 战斗 | 宝箱×1、书库门 | left1/right1/door1 |
| `ch3_04` | 静水回廊 | 战斗 | 无 | left1/right1 |
| `ch3_05` | 深渊裂口 | 战斗 | 宝箱×1 | left1/right1 |
| `ch3_06` | 第三页之门 | 战斗 | 无 | left1/right1 |
| `ch3_rest` | 引路人的灯 | 休整 | 商店、残碑、捷径门 door2→`ch3_02` | left1/right1/door2 |
| `ch3_boss` | 最后的读者 | Boss | Arena/Boss | left1 |
| `ch3_vault` | 隐藏书库 | 书库（`kind=REST`） | 宝箱、残碑、返回门 door1→`ch3_03` | door1 |

- 世界 JSON 把 `ch3_vault` 标成 `type: rest`，与第 1/2/4 章一致；游戏逻辑按 `_vault`
  后缀识别书库，不依赖该字段。
- 场景全部是 `MDSChapterRoom`（`chapter_index = 2`），背景用 `lightless_sea.png`
  （1536×864 RGB 绘画）+ `LivingBackdrop(sea=true)`；`room_darkness=false`、
  `room_weather=true`、`room_parallax=false`、`room_background=true`、`fade_time=0.22`。
- 区域 `Lightless Sea`：雾 + 雨；`background` 为空、无 `backdrop_image`；
  Boss 房 `boss_background=deep_water`（探针确认 `MDSEnvironment.background_for_room`
  返回 `deep_water`，世界场景 `room_background=true`）。
- 结构覆盖：`integration_playability` 的逐章循环已经实走过第 3 章 6 战斗房 + 书库 +
  休整 + Boss（属于现有 671 断言的一部分），但只是旧线性结构，不是大图。

### 主线文本与语音

- `CampaignData` 第 3 章：**6 句开场、4 句章末、2 个章末选项**；目标「穿过无光海，
  找到最后的读者」；区域「无光海」；音乐 `chapter_sea.ogg` 存在。
- 语音：`ch3_intro.ogg` / `ch3_outro.ogg` 存在；`boss_reader_phase2/3.ogg` 存在。
- 章末选项效果已实现：带读者离开 → 仁慈 +1、恢复 20 生命；留下最后一页 →
  污染 +8、获得一件未拥有遗物（`game.gd` 的 `&"lightless_sea"` 分支）。
- Boss：名「最后的读者」、HP 380、伤害 15、速度 78、`boss_script = &"reader"`、
  立绘 `last_reader.png`（256×256 RGBA，画面是持书的孩子）、`boss_scale=1.0`、
  白色 tint、`boss_voice = "reader"`；**没有** `boss_scene` 键。
- 专属脚本/场景：`scripts/bosses/last_reader.gd`（`LastReader extends InkArchivist`）
  与 `scenes/bosses/last_reader.tscn` 存在；已实现镜面三连弹（`_mirror_fan`）与
  「读页」封印短语（`_read_page` → `InkWarning` + `disable_phrase_slot`），
  阶段 1 纸页波、阶段 2 每 3 次读页、阶段 3 改写/读页/镜面/墨雨轮换。
- 专属背景：没有独立 Boss 房图片，使用 MDS 的 `deep_water` 动态背景（区域级配置），
  探针确认 `MDSEnvironment.background_for_room` 返回 `deep_water`（世界场景
  `room_background=true`）。Boss 立绘由 `game.gd` 的 `_apply_art` 在运行时挂上
  （探针确认路径）。

### 敌人与波次

- `ROOM_WAVES[2]` **已配置 6 波**；`CampaignData.rooms[2]` 的 6 组首发敌人也都存在。
  探针逐房生成首发组，数量/组合与数据一致。
- 第 3 章用到的 9 种 spawn id、场景与数据都存在：
  `echo_enemy`、`hanging_scribe`、`rust_whisperer`、`mirror_sniper`、`typo_beast`、
  `collapse_husk`、`scribe_bug`、`lung_moth`、`page_swarm`。
- 美术接线（第 38 程同一口径）：
  - **已接线专属精灵**（`ENEMY_ART`，白 tint）：`echo_enemy`、`hanging_scribe`、
    `mirror_sniper`、`typo_beast`、`scribe_bug`、`page_swarm`。
  - **回退第 1 章美术**（`ENEMY_ART_FALLBACK`，`#c8e1cd`）：`rust_whisperer`→`scribe_bug`、
    `collapse_husk`→`blank_man`、`lung_moth`→`hanging_scribe`。三种都在第 38 程缺失清单内，
    没有新增第 3 章专属缺口。
  - 命名细节：`echo_enemy` 场景内的 `EnemyData.id` 是 `amnesiac_echo`（失忆回声）；
    美术表按 spawn id `echo_enemy` 解析，实际渲染正确。日后若按 data id 做美术审计，
    需要同时认这两个名字。

### 章节计划与内容数据

- **`chapter_3_demo.tres` 不存在**；`CHAPTER_PLAN_PATHS[2]` 为空；`_load_chapter_plan(2)`
  返回 null；`tests/test_ch2_world.gd` 有断言 `ch2_game_ch3_has_no_plan_yet` 锁住此状态，
  新建计划时必须同步更新该测试。
- **没有第 3 章大区目录/资源**：`resources/rooms/ch3_bigmap/`、`scenes/mds/ch3_bigmap/`
  均不存在。
- **没有事件数据**：`_event_data()` 对第 3 章返回 `{}`（没有 `Ch3EventData`），
  大图事件分支不会开页；当前旧世界本身也没有 event 类型房间。
- **没有权柄池**：`_grant_chapter_authority()` 在 `_chapter_plan == null` 时直接返回，
  第 3 章 Boss 击败后不会开权柄三选一（探针确认计划为空）。
- **Boss 路由**：`_spawn_boss` 优先级为 章节 `boss_scene` → 计划 `boss_scene` →
  `boss_script == "smiling"` → `boss_script == "reader"` → 默认。第 3 章没有前两者，
  靠 `boss_script == "reader"` 路由到 `READER_SCENE`（探针确认脚本为 `last_reader.gd`）。
- **Boss 入场/阶段文案**：`BossEntranceData.variants(2)` = `[]` → `pick()` 返回空串；
  `BossPhaseData.variants(2/3, 2)` = `[]` → `pick()` 返回空串。第 3 章 Boss 入场静默、
  阶段横幅只有机械前缀，不会回落到第 1 章文案。
- **章节推进**：`_complete_chapter()` 只在 `_chapter == 0/1` 停章；第 3 章（`_chapter == 2`）
  仍走旧自动续章，会进入第 4 章。
- **地图标题**：第 38 程已按区域派生，第 3 章显示「无光海地图」（探针确认）。
- **清房目标/坠落平面**：无计划 → 清房目标 6、HUD 分母 7、坠落平面 850（探针确认）。

### 叙事

- 剧情圣经第 3 章节拍：「最后的读者是一个孩子，他读完了所有结局」「你会赢，也会输，
  还会在同一个地方反复醒过来」「故事需要有人翻页」；目前**只有文本**，没有对应事件房、
  对话节点或剧情实体。Boss 立绘是持书的孩子，与「孩子」设定一致，但 `CampaignData`
  的开场/章末台词只称「最后的读者」，没有把「孩子」写成台词。
- **没有 NPC 同行实体**：仓库没有 companion/follower 控制器；阿砚只出现在第 2 章文本与
  Hub 铁匠铺。MDS 自带 `carry_over` 组（可把节点带过门），但项目未使用。第 3 章也没有
  同行角色实体。

## B. 承载力结论（只写第 3 章差异点）

第 26 程已证的通用结论（大房间/多矩形、门/无缝、相机限制、存档、地图、Boss 房接入）
不再重复；以下是第 3 章需要单独看的点：

1. **房间生产管线可直接用** **【已核实】**：`MDSBigRoom`/`BigRoomData` 无章节判断；
   第 2 章已用 9 区真实世界验证。第 3 章只需新增 `ch3_bigmap` 数据/场景/世界，
   旧 `chapter_3.mdsworld.json` 与世界场景原地保留、不再引用（与第 2 章处理一致）。
2. **解耦同样适用** **【已核实】**：按 `region/Node` 的一次性结算、按区域坠落平面、
   计划派生清房目标、按遭遇节点 id 的波次，都是章节无关代码；第 3 章只要写计划即可。
3. **背景/氛围差异（第 2 章没有的）** **【已核实】**：第 3 章现有海面母题由
   `MDSChapterRoom._build_backdrop()` 的 `LivingBackdrop(sea=true)` 提供（海面线、
   波光、漂浮纸屑、塔影、地面暗带）；大区管线只有 `BigRoomData` 的平铺静态背景
   （`lightless_sea.png` 可平铺）与 `BigRoomAmbient` 的 `motes`/`embers`，
   **没有 sea 层**。第 2 章大图也丢掉了它自己的 `LivingBackdrop`，但第 3 章的海面
   是主题核心，损失更明显。是否补一个 ambient/背景层，属表现口径，需在施工前定；
   本程只记录事实，不设计新机制。**【待施工验证】** 实际观感与平铺接缝。
4. **GDD「视野压缩」没有实现** **【已核实】**：仓库没有视野遮罩/光照半径/黑暗度玩法
   脚本；MDS 世界场景 `room_darkness=false`，第 3 章没有开启；`ChapterAtmosphere` 里
   只有 Boss 动态背景的 `vignette` 美术参数，不是视野机制。GDD §11 把「污染、视野压缩」
   列为无光海机制，但当前既没有黑暗系统，也没有把污染和视野关联的逻辑。大区管线不会
   自动带来它；这是第 3 章独有的新机制缺口，需先拍板再排期。
5. **没有水域物理** **【已核实】**：没有游泳/溺水/水面碰撞/水体制动脚本；
   「无光海」目前是背景与叙事。按既定口径不新增移动能力，因此不需要水域机制，
   但也不存在可复用的水面脚本。**【推断】** 大图若要做「海面/深水」分层，只能靠
   背景、平台与门，不靠新物理。
6. **纵向结构是新增内容而非新管线** **【已核实】**：现有 9 房全部 1280×720 单层；
   大区管线的高差预算与第 2 章相同（≤80 px 台阶、≤120 px 水平边缘），top/bot 门、
   单向落台、塌陷平台、移动平台都可用。第 3 章 GDD 没有「上下分层/塌陷平台」条目，
   纵向与否属关卡设计选择，不是能力限制。
7. **Boss 3 已有实现但没接计划** **【已核实】**：`LastReader`、场景、立绘、`deep_water`
   背景、reader 阶段语音、镜面弹/读页攻击都已存在，且探针确认实际生成的是
   `last_reader.gd`；缺的是计划 `boss_scene` 路由（现走 `boss_script` 旧分支）、
   入场/阶段文案、以及任何针对 `LastReader` 的测试锁定。相对第 2 章施工前（完全无
   独特机制），第 3 章 Boss 的机制工作量更小，但需要与第 2 章的「计划 `boss_scene`」
   口径统一。
8. **捷径语义不同** **【已核实】**：第 3 章现有捷径是 `ch3_rest` 的 `door2` 无条件
   交互门直达 `ch3_02`；第 2 章大图的 `shortcuts` 用 `MDSGateBarrier` + ability
   （`ch2_shortcut`）。第 3 章没有 `ch3_shortcut` 的授予来源；若大图计划写
   `shortcuts`，需要先定来源（与第 2 章待确认第 11 项同类）。
9. **章末边界要再做一次** **【已核实】**：第 3 章现在 `_complete_chapter()` 自动进
   第 4 章；第 3 章大图落地后若第 4 章仍未完成，需要像第 2 章那样 `_finish(true)`
   停章，否则会进入未完成的第 4 章。
10. **敌人美术无新增缺口** **【已核实】**：3 种回退敌人都在第 38 程缺失清单内；
    其余 6 种有既有精灵。没有第 3 章专属的新缺图。
11. **背景是绘画而非像素** **【已核实】**：`lightless_sea.png` 1536×864 RGB，
    与第 2 章 `breathing_ruins.png` 同一已知缺口；大区平铺时是否出现明显接缝
    **【待施工验证】**。
12. **入口出生点要作者化** **【已核实】**：现有 `MDSChapterRoom` 只在 `room_index` 0/1
    生成 `SavePoint`；大图入口若沿用房间标签锚点会空中坠落（第 37 程已修过第 2 章）。
    第 3 章大图入口必须作者 `SpawnPoint`（`save_point` 组，脚底 = 地面 − `FOOT_Y`）。
13. **战斗房宝箱** **【已核实】**：`ch3_03`/`ch3_05` 已有宝箱，书库另有 1 个；
    计划 `chests` 支持按节点 id 多宝箱，无管线缺口，但计划必须为这三个箱子写节点 id。
14. **性能** **【推断】**：第 3 章大区尺寸/内容尚未落地，无法实测；第 2 章验收基线为
    普通区热加载 5.6–9.2 ms、Boss 区冷启 61 ms/热 10–43 ms，由 0.22 s 淡入覆盖。
    第 3 章若做更大的海面区，需按第 36 程同一口径实测。**【待施工验证】**

## C. 施工顺序建议（沿用第 2 章工序）

1. **计划/图骨架**：新建 `chapter_3_demo.tres`（`big_map`、`start_room`、`doors`、
   region 键：尺寸/遭遇/宝箱/残碑/捷径/隐藏/坠落平面/波次/权柄池/`boss_scene`），
   写图骨架夹具，接入 `CHAPTER_PLAN_PATHS[2]`，同步改
   `tests/test_ch2_world.gd` 的 `ch2_game_ch3_has_no_plan_yet` 锁。
   **前置**：第 3 章区图/节拍设计（区数、入口→支路→枢纽→纵向→事件/精英→Boss +
   隐藏书库）；「视野压缩」是否实现（影响区域与表现）；捷径授予来源。
2. **真实大区世界**：新建 `resources/rooms/ch3_bigmap/*.tres` 与
   `scenes/mds/ch3_bigmap/*.tscn`、独立 `chapter_3_bigmap.mdsworld.json` +
   `_world.tscn`；区域补 `backdrop_image=lightless_sea.png`，沿用雾/雨与
   `boss_background=deep_water`；入口作者 `SpawnPoint`；门由世界 JSON 自动生成并自动
   挂 `GateVisual`；纵向按需用既有单向落台/塌陷平台/移动平台/长椅；旧第 3 章世界保留。
   **前置**：步骤 1；海面母题呈现口径。
3. **内容数据层**：`Ch3EventData`（事件区文案，按 seed + 节点 id）、计划 `wave`
   （遭遇节点 id → 敌人数组，可复用 `ROOM_WAVES[2]` 原文）、计划 `authority_pool`
   （续命/改写 + 条件项）、`BossEntranceData`/`BossPhaseData` 第 3 章文案、
   计划 `boss_scene` 指向 `last_reader.tscn`。
   **前置**：步骤 1–2；事件文案/权柄池内容口径。
4. **Boss 3 机制**：复用现有 `LastReader` 的镜面弹/读页；按计划 `boss_scene` 接线；
   补测试锁定阶段映射与攻击；是否扩展新招式由监工/用户另行决定（本程不设计）。
   **前置**：步骤 3（路由与文案）。
5. **系统验收**：新增 `tests/integration_ch3_bigmap.gd`，按第 36 程 D 节 1–10 项
   覆盖连通/边界相机/纵向/过渡/一次性/多遭遇/捷径/隐藏/Boss/续玩，并补第 3 章专属
   断言（海面背景/天气、`deep_water` Boss 背景、`LastReader` 脚本/立绘、地图标题、
   章末停章）；先保持第 3 章不可达，全绿后再由监工单独拍板可达性。
   **前置**：步骤 1–4。

## D. 未做（按任务单）

- 未新建第 3 章计划/大区/房间/事件/权柄/Boss 内容，未改 `game.gd` 章节路由，
  未开放第 2–4 章可达性。
- 未实现「视野压缩」、海面 ambient 层、水域物理、`ch3_shortcut` 授予、Boss 3 新招式、
  NPC 同行、新移动能力、敌人/场景美术。
- 未改 MDS 插件、NPC 立绘、待确认第 11/12/13 项相关数值/相机/HUD。
- 临时探针 `tests/tmp_ch3_audit.gd` 已删除；本程只提交状态与记忆文档。
