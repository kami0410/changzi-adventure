# 2026-11-05 · 第 4 章大地图可行性核查（第 50 程）

> 只查不施工：未改第 4 章可达性，未新建计划/大区/房间/事件/权柄/Boss 内容，未改
> `game.gd` 章节路由；未新增测试、未改产品代码；未创建临时探针（结论来自读代码/资源
> 与既有测试实跑）。完整摘要见 `SUPERVISOR_STATUS.md`「第 4 章大地图可行性核查
> （第 50 程）」专节。
>
> 标记：**【已核实】** 读代码/资源或既有测试可复现；**【推断】** 由已核实事实推导、
> 尚未实跑；**【待施工验证】** 必须等真实大图内容落地后才能定论。

## 结论

- **可行性：可以直接承载，不需要改 MDS、存档、战斗或房间管线。** `BigRoomData` +
  `MDSBigRoom` 不含任何章节判断；第 27 程的按节点 id 结算、按区域坠落平面、计划派生
  清房目标、按遭遇节点 id 的波次都是章节无关的。第 4 章现有旧世界可以像第 2/3 章旧世界
  一样原地保留、不再引用。**【已核实】**
- **缺口集中在内容层**：第 4 章没有计划（`chapter_4_demo.tres` 不存在、
  `CHAPTER_PLAN_PATHS[3]` 为空）、没有大区/房间数据、没有事件数据、没有权柄池、
  Boss 入场/阶段文案静默、Boss 4 无专章机制打磨与测试、没有第 4 章大图验收套件；
  与第 2/3 章施工前的缺口同类。**【已核实】**
- **第 4 章独有差异**：① 舞台母题目前只由 `MDSChapterRoom` 的 `TheaterBackdrop`
  （聚光灯/光斑/浮尘）提供，大区管线只有平铺绘画 + `BigRoomAmbient`；② Boss 4
  「笑面史官」已有专属脚本/场景/立绘/语音与部分独特攻击（镜面弹幕），但没有专章机制
  打磨、没有入场/阶段文案、没有测试锁定，剧情圣经的三阶段「改写规则/删除词/复制武器」
  与 GDD 的「舞台机关」大多未实现；③ 捷径 `door2` 是无条件交互门，大图 `shortcuts`
  需要能力 id 与授予来源；④ 章末边界本身就是战役终点（已是 `_finish(true)`，无需再改），
  但第 3 章的停章替身必须先解开；⑤ 入口出生点必须作者 `SpawnPoint`。**【已核实】**
- **美术更正（用户 2026-11-04 事实）**：第 4 章美术素材已经画好并已接线——舞台绘画、
  Boss 立绘、8 种实际使用的敌人精灵（含 `mask_enemy`/`seat_husk` 两个第 4 章美术变体）、
  配乐、开场/章末/Boss 阶段语音全部存在；**没有缺失的第 4 章专属敌人美术，也没有
  回退第 1 章美术的敌人**。README/GDD 的旧「程序化绘制、待替换插画」记录已在第 7 程更正，
  本次复核与当前文档一致。**【已核实】**
- **施工顺序**沿用第 2/3 章：计划/图骨架 → 真实大区世界 → 内容数据层 → Boss 机制 →
  系统验收；每步前置依赖见下。第 4 章可达性仍须单独拍板，且不能早于第 2/3 章。

## A. 第 4 章现有内容盘点

### 世界与房间【已核实，既有集成实走】

- `scenes/mds/chapter_4_world.tscn` + `chapter_4.mdsworld.json`：9 个 MDS 房间、
  **17 扇门**（7 right / 7 left / 3 door）、`links`/`pins` 为空、`start_room = ch4_01`。
- 全部 **1280×720 单矩形、单层地面**（地面面 y=560，StaticBody 80 px），平台按
  `platform_pattern` 0/1/2 建 2/2/1 块；没有多矩形、多层或纵向结构。
- 场景全部 `MDSChapterRoom`（`chapter_index = 3`）；世界设置
  `room_darkness=false`、`room_weather=true`、`room_parallax=false`、
  `room_background=true`、`fade_time=0.22`、`gate_cooldown=0.35`、`keep_momentum=true`。
- 区域 `Smiling Theater`：灰烬 + 光柱天气；`background` 为空、无 `backdrop_image`；
  Boss 房 `boss_background = blood_moon`。背景由 `MDSChapterRoom` 的
  `BACKGROUNDS[3] = smiling_theater.png` 提供（见 B 节）。

| 房间 | 名称 | 类型 | 内容 | 门 |
|---|---|---|---|---|
| `ch4_01` | 剧场前厅 | 战斗 | 无 | right1 |
| `ch4_02` | 笑面回廊 | 战斗 | 无 | left1/right1 |
| `ch4_03` | 血幕书库 | 战斗 | 宝箱×1、书库门 | left1/right1/door1 |
| `ch4_04` | 空座中庭 | 战斗 | 无 | left1/right1 |
| `ch4_05` | 舞台侧廊 | 战斗 | 宝箱×1 | left1/right1 |
| `ch4_06` | 第四页之幕 | 战斗 | 无 | left1/right1 |
| `ch4_rest` | 熄灯的后台 | 休整 | 商店、残碑、捷径门 door2→`ch4_02` | left1/right1/door2 |
| `ch4_boss` | 笑面剧场 | Boss | Arena/Boss | left1 |
| `ch4_vault` | 隐藏书库 | 书库（`kind=REST`） | 宝箱、残碑、返回门 door1→`ch4_03` | door1 |

- 宝箱 3（`ch4_03`、`ch4_05`、`ch4_vault`）、残碑 2（`ch4_rest`、`ch4_vault`）、
  商店 1（`ch4_rest`，id `ch4_rest_shop`）、残碑文本 id `ch4_rest_stele`；
  与第 3 章旧世界同构。
- 捷径 `ch4_rest/door2` 是**单向**交互门（直达 `ch4_02`，目标房没有回门）；
  `ch4_boss/left1` 可返回 `ch4_rest`（与第 2/3 章大图 Boss 单向门不同）。
- 旧线性结构已被 `integration_playability` 的逐章循环实走（6 战斗房 + 书库 + 休整 +
  Boss + 章末），并最终到达战役结局；但没有第 4 章大图结构覆盖。

### 主线文本与语音【已核实】

- `CampaignData` 第 4 章：**8 句开场、4 句章末、2 个章末选项**；目标「穿过空座，走上
  舞台，结束这场演出」；区域「笑面剧场」；音乐 `chapter_theater.ogg` 存在。
- 语音：`ch4_intro.ogg` / `ch4_outro.ogg` 存在；Boss 阶段
  `boss_smiling_phase2.ogg` / `boss_smiling_phase3.ogg` 存在（Boss 1 阶段无横幅、
  无语音，与其它章一致）。
- 章末选项效果已实现：重写名册 → 仁慈 +1；焚毁名册 → 污染 +12，并置
  `_burned_final = true`（影响最终结局）。
- 叙事审计表里「第 4 章 7 句开场」是旧记录；实际是 **8 句**（第 1/2/3 章分别为
  6/7/7 句），本程按代码重新计数。

### Boss 4「笑面史官」【已核实】

- `CampaignData`：HP **520**、伤害 **18**、速度 **92**、`boss_script = &"smiling"`、
  立绘 `assets/sprites/bosses/smiling_archivist.png`（256×256 RGBA）、`boss_scale=1.0`、
  白色 tint、`boss_voice = "smiling"`；**没有** `boss_scene` 键。
- 专属脚本/场景：`scripts/bosses/smiling_archivist.gd`
  （`SmilingArchivist extends InkArchivist`，36 行）+
  `scenes/bosses/smiling_archivist.tscn` 存在；`_spawn_boss` 在无 `boss_scene`/
  计划路由时按 `boss_script == "smiling"` 选中它。
- 已有独特攻击：**镜面弹幕**（`_mirror_fan`，3 枚 ×0.7 攻击力、速度 280、张角
  ±0.34 rad）；阶段 1 纸页波；阶段 2 每第 3 次镜面弹幕、其余纸页波；阶段 3
  改写/镜面/墨雨/纸页波轮换。基类的 `_page_wave`（阶段 ≥2 双发）、`_ink_rain`、
  `_rewrite`（临时封印一个短语槽）都继承。
- 缺口：剧情圣经第 4 章节拍说「三阶段：改写规则、删除词、复制昌子的武器」，
  GDD §11 说「规则改写、舞台机关」；当前没有删除词、没有复制玩家武器、没有舞台机关，
  `_rewrite` 只是临时封印短语槽。Boss 4 也没有 `test_ch4_boss` 之类的专项测试
  （`test_boss.gd` 只测基类 `InkArchivist`），集成遍历只把它击杀、未断言类型/机制。

### 敌人与波次【已核实】

- `ROOM_WAVES[3]` **已配置 6 波**；`CampaignData.rooms[3]` 的 6 组首发敌人也都存在。
- 第 4 章实际用到 **8 种 spawn id**：`mask_enemy`、`seat_husk`、`echo_enemy`、
  `choir_summoner`、`typo_beast`、`mirror_sniper`、`ink_bomber`、`page_swarm`。
- 美术接线（第 38/49 程同一口径）：**8 种全部有专属精灵、全部在 `ENEMY_ART`、
  全部白 tint，`ENEMY_ART_FALLBACK` 命中 0 项**——第 4 章与第 1 章一样是零回退章节；
  第 2/3 章缺图的 `rust_whisperer`/`lung_moth`/`collapse_husk` 不在第 4 章波次里。
- 两个第 4 章美术变体：`mask_enemy` 复用 `hanging_scribe.tscn`（数据 id
  `hanging_scribe`，flyer 动画），`seat_husk` 复用 `collapse_husk.tscn`
  （数据 id `collapse_husk`，elite 动画）；只有精灵是第 4 章专属，数值/行为沿用
  第 1 章敌人。美术按 spawn id 解析，实际渲染正确。
- 命名细节沿用第 49 程：`echo_enemy` 数据资源 id 是 `amnesiac_echo`，美术按 spawn id
  接线。

### 章节计划与内容数据【已核实】

- **`chapter_4_demo.tres` 不存在**；`CHAPTER_PLAN_PATHS[3]` 为空；
  `_load_chapter_plan(3)` 返回 null；`resources/rooms/ch4_bigmap/`、
  `scenes/mds/ch4_bigmap/` 均不存在。
- **没有事件数据**：`_event_data()` 对第 4 章返回 `{}`（没有 `Ch4EventData`）；
  旧世界也没有 event 房。
- **没有权柄池**：`_grant_chapter_authority()` 在 `_chapter_plan == null` 时直接返回，
  第 4 章 Boss 击败后不会开权柄三选一（第 1 章有线性计划，所以有）。
- **Boss 路由**：`_spawn_boss` 优先级 = 章节 `boss_scene` → 计划 `boss_scene` →
  `boss_script == "smiling"` → `boss_script == "reader"` → 默认；第 4 章靠
  `smiling` 档路由到既有场景。
- **Boss 入场/阶段文案**：`BossEntranceData.variants(3)` = `[]` → 空串；
  `BossPhaseData.variants(2/3, 3)` = `[]` → 空串；入场静默、阶段横幅只有机械前缀，
  不会回落到第 1 章文案（第 2/3 章测试锁定此状态）。
- **章节推进**：`_complete_chapter()` 没有第 4 章专属分支；第 4 章是最后一章，
  章末选择后走 `_finish(true)` 结束战役（既有集成 `campaign_reaches_ending` 已覆盖）。
  第 3 章的停章替身（`_chapter == 2` → `_finish(true)`）是第 4 章可达性的前置。
- **地图标题**：第 38 程派生规则下第 4 章显示「笑面剧场地图」（`test_map_overlay`
  明确断言，集成也复跑）。
- **清房目标/坠落平面**：无计划 → 清房目标 6、HUD 分母 7、坠落平面 850
  （`integration_playability` 的 `chapter_4_fall_plane_default` /
  `chapter_4_clear_target_default` 已断言）。
- **测试面**：第 4 章旧线性全流程由 `integration_playability` 逐章循环覆盖
  （含背景绘画/`TheaterBackdrop` 轻量覆盖、地图标题、6 房清理、书库、休整、
  Boss 击杀、章末选择、最终结局），但没有第 4 章大图验收套件、没有 Boss 4 类型/
  机制断言、没有第 4 章敌人美术专项审计。

### 叙事【已核实】

- 剧情圣经第 4 章节拍：① 剧场坐满纸人；② 笑面史官逐一念出同行者名字；
  ③ 舞台机关、纸人观众、镜面狙手与合唱召引者轮番登场；④ 揭示他是未来的昌子、
  所有失败版本的集合；⑤ 三阶段改写规则/删除词/复制武器；⑥ 重写或焚毁名册。
- 现状：① 只在开场文本；② 开场文本点名陆沉/阿砚/闻烬/白榆（未提咕噜，
  也没有「所有版本」的展开）；③ 镜面狙手/合唱召引者作为敌人存在，
  纸人观众与舞台机关没有实体；④ 「未来的昌子」**没有写进任何已实现台词**，
  只在剧情圣经里；⑤ 机制见 Boss 4 节；⑥ 已实现。
- **没有 NPC 同行实体**：仓库没有 companion/follower 控制器；阿砚只在第 2 章文本
  与 Hub 出现，MDS 自带 `carry_over` 组但项目未使用。第 4 章也没有同行角色实体；
  「念出同行者名字」目前只是台词，不是可交互节拍。

## B. 第 4 章美术素材核查（用户 2026-11-04 事实更正的遗留项）

> 用户已说明第 4 章美术素材已经画好；README 旧版本「第四章舞台为程序化绘制、
> 待替换插画」是过时消息。本程只读核查，未改任何图、未改 NPC 立绘。

| 类别 | 资产 | 规格/状态 | 接线位置 |
|---|---|---|---|
| 舞台/背景 | `assets/backgrounds/smiling_theater.png` | 1536×864 RGB **绘画**（非像素） | `mds_chapter_room.gd` `BACKGROUNDS[3]` → `BackgroundArt` + `TheaterBackdrop(generated_art=true)`；旧线性 `scenes/levels/smiling_theater.tscn`（已休眠） |
| 舞台概念源 | `assets/concept/environments/smiling_theater_source.png` | 1983×793 RGB | 仅概念图，不运行时加载 |
| Boss | `assets/sprites/bosses/smiling_archivist.png` | 256×256 RGBA；alpha 0/255、四角透明、最低不透明行=底行、无压缩/无 mipmap | `CampaignData.boss_texture` → `_spawn_boss` → `_apply_art` |
| Boss 概念 | `assets/concept/characters/smiling_archivist_pixel.png`、`smiling_archivist_sprite_source.png` | 概念/源图 | 仅参考 |
| 敌人（第 4 章美术变体） | `assets/sprites/enemies/mask_enemy.png`、`seat_husk.png` | 96×96 RGBA；alpha 0/255、四角透明、底行对齐、无压缩/无 mipmap | `game.gd` `ENEMY_ART`；spawn id 在 `CampaignData.rooms[3]` / `ROOM_WAVES[3]` |
| 敌人（复用） | `echo_enemy`、`choir_summoner`、`typo_beast`、`mirror_sniper`、`ink_bomber`、`page_swarm` | 96×96 RGBA，均已接线、白 tint | 同上 |
| 道具 | `chest.png`、`stele.png`、`shop.png`、`door.png` | 第 1 章共享像素道具 | `MDSChapterRoom` / 交互物场景 |
| 地面瓦片 | `resources/tiles/ch1_tiles.tres`（`assets/tiles/ch1/tiles.png`） | 与第 2/3 章大图相同 | `BigRoomData.tile_set`（现有第 4 章 `MDSChapterRoom` 走同一瓦片集） |
| 配乐 | `assets/audio/music/chapter_theater.ogg` | 存在 | `CampaignData.music` |
| 语音 | `ch4_intro.ogg`、`ch4_outro.ogg`、`boss_smiling_phase2/3.ogg` | 存在 | `CampaignData.voice_intro/voice_outro`、`_on_boss_phase` |

- **程序化/生成部分**：舞台不再依赖程序化帷幕/观众席——`TheaterBackdrop` 的
  `generated_art=true` 分支只叠加聚光灯锥、地面光斑与浮尘，其余绘制分支跳过；
  Boss 房背景是 MDS 的 `blood_moon` 动态背景（与第 1–3 章 Boss 背景同类，不是
  「待替换占位」）；地面/平台由 `ch1_tiles` 生成瓦片，是大图管线的既定做法。
- **没有第 4 章专属 tileset / 道具**：`assets/tiles/` 只有 `ch1`，与第 2/3 章一致；
  不是缺美术，而是既定路线（绘画背景 + 生成地面 + 共享像素道具）。
- **调色观察**：`mask_enemy`/`seat_husk` 各 25 色、Boss 45 色；与第 2/3 章同批
  敌人/Boss 素材一致（普通敌人多为 24–25 色、Boss 45 色），属既有规范偏差
  （art-spec 普通敌人 24 / Boss 40），不是第 4 章独有缺口；本程不改图。
- **结论**：用户「第 4 章美术已经画好」与仓库一致；第 4 章实际用到的 8 种敌人
  全部有专属精灵且已接线，Boss/舞台/音频齐全，**没有发现缺失或未接线的第 4 章
  美术素材**。README/GDD 当前表述已正确（第 7 程更正），本程无需再改文档；
  NPC 立绘未读改、未替换。

## C. 承载力结论（只写第 4 章差异点）

1. **房间管线可直接用【已核实】**：`MDSBigRoom`/`BigRoomData` 无章节判断；
   第 2/3 章 9 区真实世界已验证。第 4 章只需新增 `ch4_bigmap` 数据/场景/世界，
   旧世界原地保留、不再引用。
2. **解耦同样适用【已核实】**：按 `region/Node` 的一次性结算、按区域坠落平面、
   计划派生清房目标、按遭遇节点 id 的波次，都是章节无关代码。
3. **舞台母题差异【已核实】**：第 4 章舞台由 `TheaterBackdrop` 的聚光灯/光斑/浮尘
   + 绘画提供；大区管线只有平铺静态背景（`BigRoomData.backdrop_path`）与
   `BigRoomAmbient` 的 `motes`/`embers`，**没有 theater 层**。区域天气（灰烬 + 光柱）
   仍由 MDS 按区域生效，可以补一部分氛围；聚光灯/吊灯/观众席的舞台感会丢。
   是否补 theater ambient 层属表现口径，需拍板；实际观感与平铺接缝
   **【待施工验证】**。
4. **背景是绘画而非像素【已核实】**：`smiling_theater.png` 1536×864 RGB；第 2/3 章
   大图已经用绘画平铺（`backdrop_pixel_art=false`、线性过滤），第 4 章可以照做。
   平铺接缝（1536×864 贴图铺 2560×1440 等区）**【待施工验证】**；第 4 章没有专属
   tileset，地面继续用 `ch1_tiles`，与第 2/3 章一致。
5. **Boss 4 已有实现但没接计划【已核实】**：`SmilingArchivist`、场景、立绘、Boss 语音、
   镜面弹幕/纸页波/墨雨/改写都已存在；缺计划 `boss_scene` 路由、入场/阶段文案、
   专章机制打磨与测试锁定。相对第 2/3 章施工前（完全无独特机制或只有旧机制），
   Boss 4 的起点更好，但要补的内容仍与第 2/3 章同工序。
6. **捷径语义不同【已核实】**：现有 `ch4_rest/door2` 是无条件单向交互门直达
   `ch4_02`；第 2/3 章大图 `shortcuts` 用 `MDSGateBarrier` + ability
   （`ch2_shortcut`/`ch3_shortcut`）。第 4 章没有 `ch4_shortcut` 授予来源；
   若大图计划写 `shortcuts`，需先定来源（与待确认第 11/16 项同类）。
7. **章末边界不用再改【已核实】**：第 4 章是最后一章，`_complete_chapter()` 已经走
   `_finish(true)`，不会越界到不存在的第 5 章。但第 4 章可达性要求先解开第 3 章的
   停章替身（`_chapter == 2` → `_finish(true)`），并接入第 3 章计划
   （`CHAPTER_PLAN_PATHS[2]`）；这属于可达性拍板后的工作，不在本章施工步骤内。
8. **入口出生点要作者化【已核实】**：`MDSChapterRoom` 只在 `room_index` 0/1 生成
   `SavePoint`；大图入口若沿用房间标签锚点会空中坠落（第 37 程已修过第 2 章）。
   第 4 章大图入口必须作者 `SpawnPoint`（`save_point` 组，脚底 = 地面 − `FOOT_Y`）。
9. **清房目标/坠落平面【已核实】**：旧世界无计划 → 目标 6、HUD 分母 7、坠落 850；
   大图计划会按遭遇节点派生目标，并按第 2/3 章口径每区 `fall_below_bounds = 240`。
10. **事件区是可选项【已核实】**：旧第 4 章没有事件房，`_event_data()` 对第 4 章
    返回 `{}`。若大图要加事件区，需要 `Ch4EventData` + 读/拿效果，并把清房目标
    从 6 提到 7；若不加，目标保持 6。这是内容口径，需拍板。
11. **权柄池缺口【已核实】**：无计划 → Boss 4 击败后没有权柄三选一。大图计划补
    `authority_pool = [续命, 改写]`（条件项仍走 `ContentLibrary` 的吞噬/归档）即可
    与第 2/3 章一致。
12. **敌人美术无缺口【已核实】**：第 4 章 8 种敌人全部有专属精灵、无回退；与第 2/3 章
    的缺图清单不重叠。`mask_enemy`/`seat_husk` 是美术变体、数值/场景沿用第 1 章敌人，
    是否需要独立数值属内容口径。
13. **战斗密度口径【已核实】**：旧第 4 章每战斗房是「首发 3–4 + 波次 2」共 5–6 只；
    第 2/3 章大图每个战斗遭遇只用 `ROOM_WAVES` 的 2 只。若第 4 章照第 2/3 章大图
    口径，战斗密度会下降；若要维持旧密度，需要扩波或增遭遇（改 `ROOM_WAVES[3]`
    或计划波次）。这是内容选择，需拍板。
14. **性能【推断】**：第 4 章大区尺寸/内容尚未落地，无法实测；第 2/3 章验收基线为
    普通区首次 6.0–9.2 ms、热 6.1–7.7 ms，Boss 冷 41 ms / 热 24 ms，门过渡
    228–234 ms。第 4 章若沿用 2560×1440/3840×2160 区与绘画平铺，量级应相当；
    `blood_moon` Boss 背景的实际开销需按第 36/48 程同一口径实测。**【待施工验证】**

## D. 施工顺序建议与前置依赖

1. **计划/图骨架**：新建 `chapter_4_demo.tres`（`big_map`、`start_room`、`doors`、
   region 键：尺寸/遭遇/宝箱/残碑/捷径/隐藏/坠落平面/波次/权柄池/`boss_scene`），
   写图骨架夹具，接入 `CHAPTER_PLAN_PATHS[3]`，同步改
   `tests/test_ch2_world.gd`/`test_ch3_content.gd`/`integration_playability` 中
   「第 4 章计划槽为空」的锁。
   **前置**：第 4 章区图/节拍设计（区数、入口→支路→枢纽→纵向→事件/精英→Boss +
   隐藏书库）；是否加事件区；捷径授予来源；战斗密度口径。
2. **真实大区世界**：新建 `resources/rooms/ch4_bigmap/*.tres`、
   `scenes/mds/ch4_bigmap/*.tscn`、独立 `chapter_4_bigmap.mdsworld.json` + `_world.tscn`；
   每区 `backdrop_path = smiling_theater.png`（`backdrop_pixel_art=false`），
   沿用区域灰烬/光柱与 `boss_background=blood_moon`；入口作者 `SpawnPoint`；
   门由世界 JSON 自动生成并自动挂 `GateVisual`；纵向按需用既有单向落台/塌陷平台/
   移动平台/长椅；旧第 4 章世界保留。
   **前置**：步骤 1；舞台母题呈现口径（是否补 theater ambient 层）。
3. **内容数据层**：`Ch4EventData`（若加事件区；按 seed + 节点 id）、计划 `wave`
   （遭遇节点 id → 敌人数组，可复用 `ROOM_WAVES[3]` 原文）、计划 `authority_pool`
   （续命/改写 + 条件项）、`BossEntranceData`/`BossPhaseData` 第 4 章文案、
   计划 `boss_scene` 指向 `smiling_archivist.tscn`；同步把「第 4 章静默」的测试期望
   改为已授权文案。
   **前置**：步骤 1–2；事件文案/权柄池/战斗密度口径。
4. **Boss 4 机制**：复用现有 `SmilingArchivist` 的镜面弹幕/纸页波/墨雨/改写；
   按计划 `boss_scene` 接线；补 `test_ch4_boss` 锁定阶段映射与攻击；是否扩展
   「删除词/复制武器/舞台机关」另行拍板（本程不设计）。
   **前置**：步骤 3（路由与文案）；机制范围口径。
5. **系统验收**：新增 `tests/integration_ch4_bigmap.gd`，按第 36/48 程同一口径覆盖
   连通/边界相机/纵向/过渡/一次性/多遭遇/捷径/隐藏/Boss/续玩/性能，并补第 4 章
   专属断言（舞台绘画平铺与接缝、`blood_moon` Boss 背景、`SmilingArchivist`
   脚本/立绘、地图标题「笑面剧场地图」、章末结束战役、8 种敌人美术无回退）；
   先保持第 4 章不可达，全绿后再由监工单独拍板可达性。
   **前置**：步骤 1–4。

## E. 开放问题候选（只记录，不编号、不擅自决定）

- **第 4 章舞台母题呈现口径**：大图是否补 `TheaterBackdrop` 的聚光灯/吊灯/浮尘层
  （新 ambient/背景层），还是接受平铺绘画 + 区域灰烬/光柱 + `BigRoomAmbient`。
  影响观感与平铺接缝，需拍板后施工。与第 3 章的海面母题同类。
- **第 4 章捷径 `ch4_shortcut` 授予来源**：现有 `door2` 无条件；大图 `shortcuts`
  需要能力 id 与游戏内授予来源（Hub NPC/事件/精英/书库）。与待确认第 11/16 项同类。
- **第 4 章是否新增事件区**：旧世界没有 event 房；加则需 `Ch4EventData` 与效果，
  清房目标 6→7；不加则保持 6。属内容口径。
- **Boss 4 机制范围**：剧情圣经的三阶段「改写规则/删除词/复制昌子的武器」与
  GDD 的「舞台机关」对现实现（镜面弹幕 + 基类改写/墨雨）的差距；补多少、怎么补
  需先拍板，避免与第 2/3 章 Boss 机制口径不一致。
- **战斗密度**：大图沿用 `ROOM_WAVES[3]` 每遭遇 2 只（第 2/3 章先例），还是扩波/
  增遭遇维持旧第 4 章每房 5–6 只的密度。属内容/平衡口径。
- **`mask_enemy`/`seat_husk` 是否要独立数值与行为**：目前只是第 1 章敌人的美术变体
  （共享场景/数据）；若第 4 章把它们当独立敌人，需要新数据/行为，属内容设计。
- **阿砚同行**：跟随/战斗/对话是新机制，仓库没有 companion/follower 控制器；
  本程只在记录中重申缺失，不实现、不排期（与第 2 章同一状态）。

## F. 本程未做

- 未做第 4 章计划/图骨架/大区世界/内容数据/Boss 机制/验收套件任何施工。
- 未开放第 2/3/4 章可达性；未把任何章节计划接入 `game.gd`，未改章节路由。
- 未改第 11/12/13/14/15/16 项相关数值、相机、HUD、海面母题、视野压缩、捷径授予。
- 未新增移动能力、未改 NPC 立绘、未改 MDS 插件、未新绘/拼凑任何美术。
- 未做打包导出、安装器、签名、上架、安卓/触屏。
- 未新增测试与产品代码；临时探针未创建，无需清理。

## 验证

- 基线（HEAD `38a3b05`，Godot 4.7.stable.official.5b4e0cb0f）：
  `--headless --import` / `--quit` 退出 0、`ERROR` 0；单元 **10315 / 0**；
  十套集成 **754 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209 / 4235** 全 0 失败；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与本程交接基线一致，无漂移。
