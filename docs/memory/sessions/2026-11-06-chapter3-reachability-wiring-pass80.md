# 第 80 程 · 第 3 章可达性接线第 1 步（brief84，第 79 程启动即死的接力重跑）

> 目标：把第 2 章章末选择接到第 3 章大图世界，让第 3 章在正式流程中可达；
> 只动章节路由与章末分支。第 3 章计划/波次/事件文案/Boss 3 数值与机制、
> 第 1/2 章房间/波次/事件/奖励/`ending_for`、存档形状均不改；第 4 章仍不可达；
> `ch3_shortcut` 仍无游戏内授予（第 16 项），不实现视野压缩（第 14 项）与
> 海面母题（第 15 项），电梯速度（第 12 项）与相机/HUD（第 13 项）不动。

## 交接

- 第 79 程（brief83）在启动时因 `[claude-code:unrecognized_model]` 死亡，
  零产出、无提交；本程按 brief84 全新重跑，HEAD `7242cdc`、`supervisor-dev`、
  工作区干净。
- 基线先复现：`--headless --import` / `--quit` 退出 0、`ERROR` 0；单元
  **13,549 / 0**；十一套集成 **913 / 109 / 624 / 207 / 113 / 59 / 456 / 45 /
  2,330 / 4,362 / 5,133** 全 0 失败；退出泄漏 **10/10 clean**；demo 像素
  **40 / 0**。与第 78 程逐项一致，无漂移。

## 核查（接线缺口）

- 唯一缺口是四个路由点，其余全部就位：
  - `CHAPTER_PLAN_PATHS[2] == ""`（第 3 章没有计划）；
  - `MDS_WORLD_FILES[2] == "res://scenes/mds/chapter_3.mdsworld.json"`（旧 9 小房间世界）；
  - `MDS_CHAPTER_SCENES[2]` 指向旧 `chapter_3_world.tscn`；
  - `_complete_chapter` 的 `_chapter == 1` 分支仍 `_finish(true)`（第 2 章末停章）。
- 第 3 章其余内容均已落地并被测试锁定：`chapter_3_demo.tres`（9 区、清房目标 7、
  6 战斗遭遇 + 1 事件占位、`boss_scene = last_reader.tscn`、权柄池续命/改写）、
  9 个 `BigRoomData` + 9 个 `MDSBigRoom`、独立世界 `chapter_3_bigmap.mdsworld.json`、
  `Ch3EventData`、Boss 3 机制、第 3 章章末停章分支；开场 6 句 + `ch3_intro` 语音、
  outro 4 句 + `ch3_outro` 语音、`chapter_sea.ogg` 配乐均在 `CampaignData`。
- 旧第 3 章 9 房世界/场景留在磁盘上供对照，但接线后不再被 `game.gd` 引用；
  与第 2 章旧世界同口径。存档形状不变：没有新键，章节推进仍走既有
  `_start_chapter`/`_build_run_save`。

## 接线

- `scripts/game.gd` 四个点位（只改路由）：
  - `CHAPTER_PLAN_PATHS[2] = "res://resources/chapters/chapter_3_demo.tres"`；
  - `MDS_WORLD_FILES[2] = "res://scenes/mds/chapter_3_bigmap.mdsworld.json"`；
  - `MDS_CHAPTER_SCENES[2] = preload("res://scenes/mds/chapter_3_bigmap_world.tscn")`；
  - `_complete_chapter` 的 `_chapter == 1` 分支由 `_finish(true)` 改为
    `_start_chapter(2)`（章末选项/效果不变、不记录结局）。
- 第 3 章全程走既有路径，无新增分支：起始区 `ch3_entry`（`SpawnPoint`）、
  清房目标 7（HUD 分母 8）、坠落平面 `1440 + 240 = 1680`、开场/outro/配乐/
  事件页/权柄/Boss 3 均由 `CampaignData`、计划与既有大图流程生效。
- 第 3 章末仍按第 46 程口径 `_finish(true)` 停章，不进第 4 章。

## 测试改动（逐项，均为新行为下的期望更新）

- `tests/integration_playability.gd`
  - `_test_ch2_big_map` 尾部：第 2 章章末选择后不再停章/结束屏，改为断言
    `_chapter == 2`、未 `_finished`、无结束屏、第 3 章开场已打开（眉题/正文）、
    计划为 `big_map`、`chapter_sea.ogg` 与 `ch3_intro.ogg` 已生效。
  - 新增 `_test_ch3_big_map`（真实链路）：计划起始区 `ch3_entry`、`SpawnPoint`
    出生贴合、落地 `is_on_floor()`、清房 0/7（HUD 8）、坠落 1680、地图标题
    「无光海地图」；真实战斗清 `ch3_branch_a/Arena`（锁定 → 击杀 → 奖励 →
    计数 +1 → 节点 id 结算）；随后事件区与 Boss 3 两段照旧但改为在真实路由
    世界上运行。
  - `_test_ch3_bigmap_event_trigger` / `_test_ch3_bigmap_boss`：删除测试专用
    世界挂载与拆卸，改用 `scene._mds_world`（真实路由世界）；路由锁由
    「槽 2 为空 + 旧世界」改为「计划/大图世界已接线 + 第 4 章仍不路由」。
  - 章循环：交棒识别从「仅第 1 章」推广到「本章索引与当前章一致 + 开场未选」；
    第 3 章段改走真实大图链路，不再恢复旧线性世界、不再跑第 3 章旧 9 房结构遍历
    （该结构已不被游戏加载；九区/22 门/纵向/一次性/Boss 等覆盖由
    `tests/integration_ch3_bigmap.gd` 4,364 断言承担）。
  - 第 4 章两段测试的「第 3 章槽为空 / 旧世界」锁同步改为第 3 章已接线。
- `tests/integration_run_save.gd`：第 2 章 Boss 检查点续玩的章末改为「进入第 3 章
  开场」；开场期间仍保留第 2 章 Boss 检查点（`chapter == 1`），关闭开场后
  `ch3_entry` 加载并把检查点推进为 `chapter == 2`/`room == ch3_entry`。
- `tests/integration_ch2_bigmap.gd`：Boss 2 后的续玩边界由「停章/结束屏」改为
  「进入第 3 章开场、未结束、无结束屏」。
- `tests/test_ch2_world.gd`、`test_ch3_plan.gd`、`test_ch3_world.gd`、
  `test_ch3_content.gd`、`test_ch3_boss.gd`、`test_ch4_plan.gd`、
  `test_ch4_content.gd`、`test_ch4_boss.gd`、`integration_ch3_bigmap.gd`、
  `integration_ch4_bigmap.gd`、`integration_playability.gd` 的路由锁逐条更新为
  新期望；第 4 章计划/世界/场景仍不路由、旧第 3/4 章世界仍在磁盘上（断言保留）。

## 验收

- 单元 **13,549 / 0**（路由锁逐条替换，数量不变）。
- 十一套集成：`integration_playability` **878 / 0**（913 → −35：删除第 3 章旧 9 房
  结构遍历与两条默认清房/坠落断言，新增真实链路/交棒/出生/战斗清房断言；
  第 3 章结构覆盖由 `integration_ch3_bigmap` 4,364 断言承担）、
  `integration_ch1_demo` 109 / `integration_run_save` **631 / 0**（+7）、
  `integration_gamepad` 207 / `integration_ui_prompts` 113 /
  `integration_ch1_event` 59 / `integration_menus` 456 /
  `integration_ai_settings` 45 / `integration_ch2_bigmap` **2,331 / 0**（+1）/
  `integration_ch3_bigmap` **4,364 / 0**（+2）/ `integration_ch4_bigmap` **5,133 / 0**。
- 退出泄漏 **10/10 clean**、demo 像素 **40 / 0**；十一套集成顺序全量跑完，
  逐套 `EXIT=0`、日志无 `ERROR:`。

## 边界与未做

- 未改第 3 章计划内容/波次/事件文案/Boss 3 数值与机制、门/电梯/长椅/捷径逻辑；
  未改第 1/2 章房间/波次/事件/奖励/`ending_for`；未改存档形状。
- `ch3_shortcut` 仍默认封闭、无游戏内授予（第 16 项）；未实现视野压缩（第 14 项）
  与海面母题（第 15 项）；电梯速度（第 12 项）与相机/HUD（第 13 项）未动。
- 第 4 章仍不可达；未做第 3 章演出打磨、未改第 3 章美术。
- 未推送、未更新网页版、未创建 Release；未改 MDS 插件、NPC 立绘、AI 言灵接入。
- 记录待办：仓库根 `README.md` 仍写「第 2–4 章不可达」，现第 2/3 章可达，
  需监工决定后续程更新；本程未改。

## 提交

- `feat: hand chapter 2 off to the chapter 3 big map (pass 80)`
- `test: cover the chapter 2 to chapter 3 handoff across suites (pass 80)`
- `docs: record pass 80 chapter 3 reachability wiring`
