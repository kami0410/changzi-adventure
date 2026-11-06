# 2026-11-04 · 第 2 章内容数据层第 1 步：事件 + 权柄池 + Boss 文案（第 32 程）

> 把第 2 章的事件、权柄与 Boss 文案从「第 1 章写死」变成「按章节查表的
> 数据」，但第 2 章仍不可达。第 1 章事件数据、文案、数值与选句键一字未改；
> 第 2 章事件页与权柄授予只在测试层驱动验证。Boss 2 独特机制、波次接线与
> 章节过渡留给后续内容程。

## 1. 第 2 章事件数据

- 新增 `scripts/data/ch2_event_data.gd`（`Ch2EventData`）：
  - 7 组文案：呼气 / 钟摆 / 灯芯 / 钉子 / 肺叶 / 死名 / 余气，全部围绕
    剧情圣经第 2 章的肺钟、雾、死者名字，以及 `CampaignData` 开场里
    阿砚留下的灯与打过的钉子；不新增设定、关键道具或 NPC 弧线。
  - 机制固定两项，与第 1 章事件页同构：读 → 污染 +8，解明一个残页词
    （无词可解改发残页 +6）；拿 → 残页 +12。没有新增效果类型。
  - `pick(run_seed, event_id)` 用 `hash("%d:%s")` 固定轮换，键为计划事件
    节点 id `ch2_event/event`，不消耗 run RNG。
- `scripts/game.gd`：
  - 新增 `_event_data(room_id)` 章节表：第 1 章 `Ch1EventData.pick` + 原
    常量；第 2 章 `Ch2EventData.pick` + `RoomProgress.event_encounter_id`。
  - `_open_ch1_event_*` 泛化为 `_open_chapter_event` /
    `_open_event_after_transition`，`_grant_event_word` 接收本章兜底残页。
  - 自动触发仍只在 `_chapter == 0`；第 2 章事件区不自动打开第 1 章页。
    后续接线点：第 2 章可达时给 `ch2_event` 加真实触发（当前该区只有
    名为 `Event` 的 `ArenaRoom`，没有 `Arena` 主节点，命中不了
    `_on_mds_room_loaded` 的 `is_primary` 事件分支）。

## 2. 第 2 章权柄池

- `resources/chapters/chapter_2_demo.tres` 增加
  `authority_pool = [续命, 改写]`；条件项不写进池，继续由
  `AuthorityController.build_pool` 从 `ContentLibrary` 追加：
  吞噬（本局污染 ≥ 40）、归档（本局记录 ≥ 2），顺序为 ContentLibrary
  顺序（archive → devour）。
- `_grant_chapter_authority` 守卫改为「有计划且池非空」；第 1 章池与授予
  行为不变，第 2 章在测试里走完整 Boss → 权柄 → 章末流程。
- 没有发明新权柄机制；现有四效果（revive/rewrite/devour/archive）之外的
  构想不写入池，避免出现选了没效果的选项。

## 3. Boss 文案数据

- `BossEntranceData`：新增 `CH2_LINES` 8 条（肺钟、雾、钟摆、阿砚的钉子），
  `variants(1)` 返回第 2 章表；第 3–4 章仍静默。
- `BossPhaseData`：签名向后兼容扩展为
  `variants(phase, chapter_index = 0)` / `pick(run_seed, phase, chapter_index = 0)`；
  第 2 章阶段 2/3 各 8 条。第 1 章保留原选句键 `"%d:%d"`（句子不漂移），
  第 2 章用 `"%d:%d:%d"`；第 3–4 章返回空，不再回落到第 1 章文案。
- Boss 名「肺钟守卫」、HP 360、伤害 14、速度 75、立绘
  `lung_bell_guardian.png`、`boss_script = ink` 均未改，测试锁定。
- 未实现阶段机制与专属攻击（Boss 2 独特机制随第 2 章 Boss 任务做）。

## 4. 遭遇与波次校验

- 计划 7 个遭遇节点唯一且全部 `region/Node` 锚定；6 个战斗遭遇（事件
  节点 `ch2_event/event` 除外）与 `ROOM_WAVES[1]` 的 6 波按计划顺序对应；
  每波敌人都有场景与 `resources/enemies/*.tres`；五种第 2 章敌人全部出现
  在波次中；清房目标仍 7。
- 未新增/改动波次、未给计划加 `wave`、未布置敌人（按任务单只校验）。
  **已知缺口**：`game.gd` 计划分支读 `plan_room["wave"]`，第 2 章计划尚无
  该键，大区 `Arena` 目前不会生成敌人；后续按「计划顺序 ↔
  `ROOM_WAVES[1]` 顺序」落 `wave` 即可，不需要另起波次表。

## 5. 验证（HEAD 见状态文件）

- 基线（`23a16a7`）：单元 7244/0；八套集成 581/101/588/207/113/59/391/45；
  退出泄漏 10/10；像素资产 36/0。
- 收尾：单元 **7733 / 0**（+489，新增 `tests/test_ch2_content.gd`）；
  集成 **601 / 102 / 588 / 207 / 113 / 59 / 391 / 45** 全部 0 失败；
  `--import` / `--quit` 退出 0、`ERROR` 0；退出泄漏 10/10；像素 36/0。
- 新增断言覆盖：事件确定性/效果类型/消息格式/RNG；权柄基础项、条件边界与
  顺序、第 1 章池不变；Boss 入场/阶段第 2 章文案可查、不回落第 1 章、
  第 1 章选句键不变；计划遭遇/波次对应与清房目标 7；第 1 章事件集成与
  9 个 `MDSChapterRoom` 行为无回归；第 2 章仍不可达。

## 6. 未做

第 2 章可达性、Boss 2 独特机制/专属攻击、新战斗遭遇与计划 `wave` 接线、
二段跳/蹬墙跳/攀爬、MDS 插件、言灵/权柄/战斗框架、敌人美术/NPC 立绘、
删除旧世界/旧场景、打包/导出/安装器/签名/商店/安卓/触屏。
