# 2026-11-05 · 第 4 章内容数据层第 1 步：事件 + 权柄池 + Boss 文案（第 53 程）

> 沿用第 32 程（第 2 章）与第 42 程（第 3 章）的做法，把第 4 章的事件文案、
> 权柄基础池与 Boss 入场/阶段文案补成「按章节查表」的数据层。本程不产生任何
> 可玩行为变化：第 4 章计划仍未接入 `game.gd`（`CHAPTER_PLAN_PATHS[3]` 仍空），
> 第 4 章仍不可达，事件区没有真实触发点，波次未接线、Boss 4 机制/`boss_scene`
> 未做、可达性/章节路由/章末流程均未动。

## 1. 第 4 章事件数据

- 新增 `scripts/data/ch4_event_data.gd`（`Ch4EventData`）：
  - 7 组文案：纸人 / 面具 / 名册 / 幕布 / 台词 / 聚光灯 / 谢幕，取材自
    `CampaignData.chapter(3)` 的开场（纸人只为最后一页鼓掌、笑面史官记得所有
    名字、「这次换你写我」）与章末（一页写满昌子名字的纸、纸人的最后一句
    「谢幕」），以及 GDD/剧情圣经的舞台、面具、名册、谢幕母题；只做氛围文本，
    不新增设定、不写出「未来的昌子」等未实现剧情事实。
  - 机制固定两项，与第 1/2/3 章事件页同构：读 → 污染 +8，解明一个残页词
    （无词可解改发残页 +6）；拿 → 残页 +12。常量与第 3 章一致，测试锁定，
    没有新增效果类型。
  - `pick(run_seed, event_id)` 用 `hash("%d:%s")` 固定轮换，键为计划事件
    节点 id `ch4_event/event`，不消耗 run RNG。
- `scripts/game.gd` 的 `_event_data(room_id)` 扩到第 4 章：
  第 1 章仍 `Ch1EventData.pick(run_state.run_seed, room_id)` + 原常量；
  第 2–4 章都用 `RoomProgress.event_encounter_id(room_id)` 作为键。
  超出章节范围（索引 ≥ 4）仍返回 `{}`（无事件页）。测试用脱离场景树的
  `game.gd` 实例逐章调用 `_event_data` 验证路由，不依赖真实可达性。

## 2. 第 4 章权柄池

- `resources/chapters/chapter_4_demo.tres` 增加
  `authority_pool = [续命, 改写]`（与第 1/2/3 章同一基础池）。条件项不写进
  池，继续由 `AuthorityController.build_pool` 从 `ContentLibrary` 追加：
  吞噬（本局污染 ≥ 40）、归档（本局记录 ≥ 2），顺序为 archive → devour。
- `game.gd` 的 `_grant_chapter_authority` 在第 32 程已经是「按计划
  `authority_pool` 授予」，本程无需改代码；计划补池后，第 4 章一旦接入
  即走同一路径。第 1/2/3 章授予行为与池未变，测试锁定。
- 没有发明新权柄；现有四效果（revive/rewrite/devour/archive）之外不写池。

## 3. Boss 文案数据

- `BossEntranceData`：新增 `CH4_LINES` 8 条（帷幕、纸人鼓掌、同行者的名字、
  没走完的版本、聚光灯、写满名字的册子、面具下没有脸、「这次换你写我」），
  `variants(3)` 返回第 4 章表；超出范围（索引 4）仍静默。
- `BossPhaseData`：新增 `CH4_PHASE2_LINES` / `CH4_PHASE3_LINES` 各 8 条
  （舞台机关、纸人观众、名册翻页、聚光灯、笑脸裂开、谢幕）；`variants(phase, 3)`
  返回第 4 章表；超出范围仍返回空。第 1 章保留原选句键 `"%d:%d"`，第 2/3/4 章
  用 `"%d:%d:%d"`（第 2/3 章句子不漂移），不回落到第 1/2/3 章。
  - `BossEntranceData` 的既有实现一直用 `"%d:%d" % [run_seed, chapter_index]`
    （第二段是章节索引，天然按章节区分），本程核查后保持原样，只加表；
    若改成 `"%d:%d:%d"` 会让第 2/3 章已选句子漂移，测试也按原键锁定。
- `game.gd` 的 `_on_boss_phase` 与 `_boss_entrance` 在第 32 程已按
  `_chapter` 取文案，本程只补表，无流程改动。
- Boss 名「笑面史官」、HP 520、伤害 18、速度 92、立绘
  `smiling_archivist.png`、`boss_script = smiling` 均未改，测试锁定。
- 未实现 Boss 4 专章机制（剧情圣经的「改写规则/删除词/复制武器」与 GDD 的
  「舞台机关」）、计划 `boss_scene` 路由，也未改旧 `chapter_4.mdsworld.json`
  的 Boss 脚本分支；这些留给后续程。

## 4. 遭遇与波次校验

- 计划 7 个遭遇节点唯一且全部 `region/Node` 锚定；6 个战斗遭遇（事件
  节点 `ch4_event/event` 除外）按计划顺序与 `ROOM_WAVES[3]` 的 6 波
  一一对应；每波敌人都有场景，`ROOM_WAVES[3]` 实际使用的 7 种第 4 章敌人
  全部出现在波次中；清房目标仍 7。
- 本程**不接线**（任务单第 2 步留给后续程）：计划仍 `content_pending = true`，
  7 个区域都没有 `wave` 键，`wave_for()` 对六个战斗节点全返回空；把标志清零的
  副本调用 `validate_waves()` 会报恰好 6 条「缺波次」且不向事件节点要波——这
  就是下一步要补的内容，不需要另起波次表（按计划顺序落 `ROOM_WAVES[3]`）。
- 事件区真实自动触发同样留给后续程；本程只锁定触发谓词的输入（区域
  `type = event`、节点 id 一致、`_event_data` 非空、事件节点无波、清房目标
  7 / HUD 分母 8、结算键一致）。

## 5. 测试

- 新增 `tests/test_ch4_content.gd`（613 断言）：
  - 事件 7 组唯一、键齐全、标题无占位符、眉标不与第 1/2/3 章重名；确定性、
    按节点变化、跨局轮换、不消耗 run RNG；消息格式与常量（与第 3 章一致）。
  - `game.gd` 章节事件路由（第 1/2/3 章原键与原数据、第 4 章新表、
    超出范围为空）。
  - 权柄基础池 revive/rewrite；吞噬 39/40、归档 1/2 边界；双条件顺序与去重；
    第 1/2/3 章池不变。
  - Boss 入场 8 条、阶段 2/3 各 8 条：非空、≤24 字、无占位符、不与第 1/2/3 章
    重名、唯一、选句稳定/轮换、第 1/2/3 章选句键不变、超出范围静默。
  - Boss 4 数值/立绘/脚本未改、战役表无 `boss_scene`、计划仍无 `boss_scene`。
  - 7 个遭遇节点唯一且锚定、6 场战斗 ↔ `ROOM_WAVES[3]` 六波顺序、
    事件节点无波、清房目标 7、计划仍无 `wave` 表（清零标志的副本报 6 条
    缺波次）、`content_pending` 保持 true。
  - 事件触发谓词输入（区域类型/节点 id/事件页存在/无波/清房目标与 HUD 分母/
    结算键一次性）。
  - 锁不变项：`CHAPTER_PLAN_PATHS[2]/[3]` 仍空、`MDS_WORLD_FILES[3]` 仍指
    旧第 4 章世界、旧 9 房/17 门/世界场景仍在、第 4 章大区世界仍在、
    第 1 章 9 房计划/6 波/事件/清房目标 6、第 2 章计划/大区世界/事件/权柄池/
    Boss 文案、第 3 章计划（已接线波次/`boss_scene`）/事件/权柄池/Boss 文案
    均不变；`game.gd` 仍不提 `chapter_4_demo.tres`/`chapter_4_bigmap`/
    `ch4_shortcut`。
- 同步更新既有测试：
  - `tests/test_ch4_plan.gd`：原「无 authority_pool」改为「基础池 =
    revive/rewrite」；Boss 入场/阶段文案、`Ch4EventData` 存在性从「静默/未
    作者」改为「已作者」（断言数不变）。
  - `tests/test_ch4_world.gd`：原「无 authority_pool / 无事件模块」改为
    「基础池已作者化 / 事件模块存在」（断言数不变）。
  - `tests/test_ch2_content.gd`：原「第 4 章静默」改为「第 4 章有自己的文案、
    超出范围静默」（+2）。
  - `tests/test_ch3_content.gd`：第 4 章事件路由从「无页面」改为「使用自己的
    文案 + 常量、超出范围无页面」；第 4 章 Boss 文案从「静默」改为「已作者」
    （+4）。
  - `tests/test_boss_entrance_content.gd`：第 4 章从「静默」改为「有自己的
    文案」，超出范围静默（+1）。
  - `tests/integration_ch1_demo.gd`：同一条集成断言的期望改为「第 3/4 章
    都有文案」（断言数不变）。
  - `tests/fixtures/big_room/ch4_graph.mdsworld.json`：只更新说明文字
    （`Ch4EventData` 已作者、事件触发仍缺、Boss 文案已作者），图形数据未改。
- `chapter_4_demo.tres` 的事件区注释从「由后续 `Ch4EventData` 程作者」改为
  「已在 `Ch4EventData` 作者」；`chapter_plan_data.gd`/`game.gd` 的过时注释
  同步到「第 2–4 章都有大图计划、第 3–4 章尚未接线」。

## 6. 验证（HEAD 见状态文件）

- 基线（`18ce085`）：单元 **11925 / 0**；十套集成 **755 / 102 / 613 / 207 /
  113 / 59 / 391 / 45 / 2209 / 4235** 全 0 失败；`--import`/`--quit` 退出 0、
  `ERROR` 0；退出泄漏 10/10；demo 像素资产 36 / 0。
- 收尾：单元 **12545 / 0**（= 基线 11925 + 新测试 613 + 既有测试净 +7）；
  十套集成数字与基线一致（全部 0 失败）；`--import`/`--quit` 退出 0、
  `ERROR` 0；退出泄漏 10/10 clean；demo 像素资产 36 / 0。
- 第 1 章 9 房间/6 波次/事件/清房目标 6/结束流程无回归；第 2 章计划、
  大区世界、事件、权柄池、Boss 文案无回归；第 3 章计划/大区世界/事件/
  权柄池/Boss 文案无回归；第 2/3/4 章仍不可达。

## 7. 未做

第 4 章接入 `game.gd`/可达性/章节路由/章末流程、波次接线（计划 `wave`，
第 2 步）、事件区真实自动触发验证（第 3 步）、Boss 4 机制/`boss_scene`/
专属测试、第 4 章大图验收套件、舞台母题呈现、`ch4_shortcut` 授予来源、
战斗密度、`mask_enemy`/`seat_husk` 独立数值、阿砚同行、新移动能力、
NPC 立绘、MDS 插件本体、敌人/场景美术、打包/导出/安装器/签名/安卓/触屏。
待确认第 11–16 项全部未施工、未猜测；第 50 程专节 E 的第 4 章开放问题候选
仍只记录、不编号、未拍板，本程未擅自决定。
