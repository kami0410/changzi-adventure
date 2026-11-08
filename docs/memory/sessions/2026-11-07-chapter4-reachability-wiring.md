# 第 91 程 · 第 4 章可达性接线第 1 步（brief95）

> 目标：把第 3 章章末选择接到第 4 章大图世界，让第 4 章在正式流程中可达；
> 只动章节路由与章末分支。第 4 章计划/波次/事件文案/Boss 4 数值与机制、
> 第 1–3 章房间/波次/事件/奖励/`ending_for`、存档形状均不改。
> 不碰待确认第 11–16 项（`ch4_shortcut` 仍默认封闭、无游戏内授予；
> 不做舞台母题呈现层、Boss 4 机制扩展、额外波次/遭遇、阿砚同行）。

## 交接

- 第 89/90 程（brief93/94）启动即死（`session93.log` / `session94.log` 只有
  `[claude-code:unrecognized_model]`，零产出、无提交、未做扫描）；本程按
  `.supervisor/DECISIONS.md` 2026-11-07 09:45 的监工拍板全新开工，不接续
  session93/94。HEAD `1bb7743`、`supervisor-dev`、工作区干净。
- 基线先复现，与第 88 程逐项一致、无漂移：`--headless --import` / `--quit`
  退出 0；单元 **13,549 / 0**；十一套集成 **887 / 109 / 675 / 207 / 113 / 73 /
  458 / 45 / 2,331 / 4,364 / 5,133**（合计 14,395）全 0 失败；退出泄漏
  **10/10 clean**；demo 像素 **40 / 0**。

## 核查（接线缺口）

- 唯一缺口是四个路由点，其余全部就位：
  - `CHAPTER_PLAN_PATHS[3] == ""`（第 4 章没有计划）；
  - `MDS_WORLD_FILES[3] == "res://scenes/mds/chapter_4.mdsworld.json"`（旧 9 小房间世界）；
  - `MDS_CHAPTER_SCENES[3]` 指向旧 `chapter_4_world.tscn`；
  - `_complete_chapter` 的 `_chapter == 2` 分支仍 `_finish(true)`（第 3 章末停章）。
- 第 4 章其余内容均已落地并被测试锁定：`chapter_4_demo.tres`（9 区、清房目标 7、
  6 战斗遭遇 + 1 事件占位、`boss_scene = smiling_archivist.tscn`、权柄池续命/改写）、
  9 个 `BigRoomData` + 9 个 `MDSBigRoom`、独立世界 `chapter_4_bigmap.mdsworld.json`、
  `Ch4EventData`、Boss 4 机制（第 57 程）、第 4 章章末收口（第 58 程）与
  `integration_ch4_bigmap.gd` 5,133 断言（第 59/62 程）；开场 8 句 + `ch4_intro` 语音、
  outro 4 句 + `ch4_outro`、`chapter_theater.ogg` 配乐均在 `CampaignData`。
- 旧第 4 章 9 房世界/场景留在磁盘上供对照，接线后不再被 `game.gd` 引用；
  与第 2/3 章旧世界同口径。存档形状不变：没有新键。

## 接线

- `scripts/game.gd` 四个点位（只改路由与章末分支）：
  - `CHAPTER_PLAN_PATHS[3] = "res://resources/chapters/chapter_4_demo.tres"`；
  - `MDS_WORLD_FILES[3] = "res://scenes/mds/chapter_4_bigmap.mdsworld.json"`；
  - `MDS_CHAPTER_SCENES[3] = preload("res://scenes/mds/chapter_4_bigmap_world.tscn")`；
  - `_complete_chapter` 的 `_chapter == 2` 分支由 `_finish(true)` 改为
    `_start_chapter(3)`（章末选项/效果不变、不记录结局）；第 4 章末
    `_chapter == 3 → _finish(true)`（第 58 程）未改。
  - `_load_chapter_plan` 与 `CHAPTER_PLAN_PATHS` 的注释由「Chapters 2–3」改为
    「Chapters 2–4」。
- 第 4 章全程走既有路径，无新增分支：起始区 `ch4_entry`（`SpawnPoint`）、
  清房目标 7（HUD 分母 8）、坠落平面 `1440 + 240 = 1680`、开场/outro/配乐/
  事件页/权柄/Boss 4 均由 `CampaignData`、计划与既有大图流程生效。

## 全链路实走（真实路由，无测试专用挂载）

第 3 章章末选择 → 第 4 章开场（8 句 + `ch4_intro` + `chapter_theater.ogg`）→
`ch4_entry` 出生落地（`is_on_floor`）→ 真实清 `ch4_branch_a/Arena`
（锁门 → 波次全灭 → 奖励页 → 计数 1/7）→ `ch4_event` 一次性事件页
（拿 +12 残页 / 读 +8 污染 + 解词，settle 一次、重载不重开）→ Boss 4
（`SmilingArchivist`，HP 520 / 伤害 18 / 速度 92 全按战役表）→ 权柄三选一 →
第 4 章 outro（4 句 + `ch4_outro`）→ 章末选择（重写名册，仁慈 +1、污染不变）→
战役结束 + 结局按 `ending_for` 写入 `Profile.endings`。

## 测试改动（逐项，均为新行为下的期望更新）

- `tests/integration_playability.gd`
  - `_test_ch3_bigmap_boss` 尾部：第 3 章章末选择后不再停章/结束屏，改为断言
    `_chapter == 3`、未 `_finished`、无结束屏、第 4 章开场已打开（眉题/正文）、
    计划为 `big_map`、`chapter_theater.ogg` 与 `ch4_intro.ogg` 已生效；
    `chapter_3_boss_recorded_defeated` 删除（新章会重置 `_boss_defeated`，
    该断言在交棒后概念不成立）。
  - 新增 `_test_ch4_big_map`（真实链路）：计划起始区 `ch4_entry`、`SpawnPoint`
    出生贴合、落地 `is_on_floor()`、清房 0/7（HUD 8）、坠落 1680、地图标题
    「笑面剧场地图」；真实战斗清 `ch4_branch_a/Arena`（锁定 → 击杀 → 奖励 →
    计数 +1 → 节点 id 结算）；随后事件区与 Boss 4 两段改为在真实路由世界上运行。
  - `_test_ch4_bigmap_event_trigger` / `_test_ch4_bigmap_boss`：删除测试专用
    世界挂载与拆卸，改用 `scene._mds_world`（真实路由世界）；HUD 进度按
    「已清数 + 1 / 8」现算（链路里已清过一场）。事件读的污染断言加测试脚手架
    `relic_effects._purify_seconds = 0.0`，挡住 `clean_ink_lantern` 每 5 s 的
    −1 污染 tick 落进 0.3 s 结算窗口（断言仍为精确值）。
  - 章循环：第 4 章段改走真实大图链路，不再恢复旧线性世界、不再跑第 4 章旧
    9 房结构遍历（该结构已不被游戏加载；九区/22 门/纵向/一次性/Boss 等覆盖由
    `tests/integration_ch4_bigmap.gd` 5,133 断言承担）；`_restore_chapter_world`
    辅助删除。
- `tests/integration_ch3_bigmap.gd`：第 3 章末由「停在本章 + 结束屏」改为
  进入第 4 章开场（`_chapter == 3`、未结束、无结束屏、开场眉题、第 4 章计划
  生效）；清房计数断言移到交棒之前（新章会重置计数）；「Boss 已死不二次生成」
  改为在交棒后手工重挂第 3 章世界、置 `_boss_defeated` 再进 `ch3_boss` 验证
  （避免持有已释放的 `MDSWorld` 引用）。
- `tests/integration_ch4_bigmap.gd`：路由锁与章末锁改为「已接线路由」，
  套件仍自行挂载世界以便一次走完九区（注释已说明）。
- 路由锁逐条更新：`test_ch2_world`、`test_ch3_content`、`test_ch3_boss`、
  `test_ch4_plan`、`test_ch4_content`、`test_ch4_boss`、`test_ch4_world`；
  辅助函数改名（`_test_stays_unwired` → `_test_routed`、
  `_test_routing_unchanged` → `_test_routing`、
  `_test_chapter_four_still_unwired` → `_test_chapter_four_wiring`），
  旧第 4 章世界与场景的存在性断言全部保留，断言数量以等量补齐（未放宽）。
- `tests/capture_bigmap_chapters.gd`、`tests/test_map_overlay.gd`：过期
  「不可达」注释同步。

## 验收

- 单元 **13,551 / 0**（+2：`test_ch2_world` / `test_ch3_content` 各补 1 条
  第 4 章计划存在性断言；路由锁逐条替换，数量不降）。
- 十一套集成：`integration_playability` **847 / 0**（887 → −40：删除第 4 章旧
  9 房结构遍历与其默认清房/坠落断言，新增真实链路/交棒/出生/战斗清房断言；
  与第 80 程第 3 章 913 → 878 同口径，第 4 章结构覆盖由
  `integration_ch4_bigmap` 5,133 断言承担）、`integration_ch1_demo` 109 /
  `integration_run_save` 675 / `integration_gamepad` 207 /
  `integration_ui_prompts` 113 / `integration_ch1_event` 73 /
  `integration_menus` 458 / `integration_ai_settings` 45 /
  `integration_ch2_bigmap` 2,331 / `integration_ch3_bigmap` 4,364 /
  `integration_ch4_bigmap` 5,133（合计 **14,355**），全 0 失败。
- 退出泄漏 **10/10 clean**、demo 像素 **40 / 0**；三个大图套件均跑完，
  逐套 `EXIT=0`、日志无 `ERROR:`。

## 边界与未做

- 未改第 4 章计划内容/波次/事件文案/Boss 4 数值与机制、门/电梯/长椅/捷径逻辑；
  未改第 1–3 章房间/波次/事件/奖励/`ending_for`；未改存档形状。
- `ch4_shortcut` 仍默认封闭、无游戏内授予（第 16 项）；未做舞台母题呈现层、
  Boss 4 机制扩展（删词/抄武器/舞台陷阱）、额外波次/遭遇、阿砚同行。
- 未改 MDS 插件、NPC 立绘、AI 言灵接入、相机/HUD、电梯速度。
- 未推送、未更新网页版、未创建 Release；未做打包/安装器/签名。
- 记录待办：仓库根 `README.md` 仍写「第 4 章不可达」，待监工安排更新。

## 提交

- `feat: route the chapter 4 big map into the campaign (pass 91)`
- `test: walk chapter 4 through the real campaign route (pass 91)`
- `docs: record the chapter 4 reachability wiring (pass 91)`
