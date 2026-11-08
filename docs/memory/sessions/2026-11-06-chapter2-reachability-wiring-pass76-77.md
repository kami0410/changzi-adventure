# 第 76–77 程 · 第 2 章可达性接线第 1 步（brief80 中断 → brief81 接力）

> 目标：把第 1 章章末选择接到第 2 章大图世界，让第 2 章在正式流程中可达；
> 只动章节路由与章末分支。第 2 章计划/波次/事件/Boss 2 数值、第 1 章房间/
> 波次/事件/奖励/结局判定、存档形状均不改；第 3/4 章仍不可达；
> `ch2_shortcut` 仍无游戏内授予，电梯速度、相机/HUD 不动。

## 第 76 程（brief80）：核查 + 未提交改动

- 第 76 程完成接线缺口核查，结论：`CHAPTER_PLAN_PATHS[1]`、
  `MDS_WORLD_FILES[1]`、`MDS_CHAPTER_SCENES[1]` 与 `CampaignData` 第 2 章
  开场/语音/配乐均已就位；唯一缺口是 `game.gd::_complete_chapter` 的第 1 章
  分支仍 `_finish(true)` 结束 demo。
- 该程把分支改为 `demo_cleared = true` 后 `_start_chapter(1)`，但进程因网关
  中断夭折，改动留在工作区未提交、未跑全量基线。`.supervisor/session80.log`
  只留下 gap-audit 输出。

## 第 77 程（brief81）：核验、补齐与验收

### 接线核验

- `_complete_chapter` 第 1 章分支最终为：
  `demo_cleared = true` → `Flow.save_profile()` → `_start_chapter(1)` → return。
  - `demo_cleared` 的语义不变（Hub NPC 个人事件读它）；原 `_finish(true)`
    负责的 `Flow.save_profile()` 显式补回，保证章末完成即落盘。
  - `_apply_chapter_choice` 的选项/效果（治疗/遗物/护盾/武器强化/焚毁标记、
    `_mercy`、污染）一字未改；其 `save_run_now()` 在 `_ending_pending` 期间
    照旧跳过，第 1 章 Boss 检查点保留。
- 路由全部走既有路径，无新增分支：`_start_chapter(1)` →
  `_start_mds_chapter(1)` 读 `CHAPTER_PLAN_PATHS[1]`、`MDS_WORLD_FILES[1]`、
  `MDS_CHAPTER_SCENES[1]`；起始区 `ch2_entry`（`SpawnPoint`）、清房目标 7
  （HUD 分母 8）、坠落平面 `1440 + 240 = 1680`、开场 6 句 + `ch2_intro` 语音
  + `chapter_breathing.ogg` 均由既有 `CampaignData`/计划路径生效。
- 第 2 章末仍按第 35/46 程口径 `_finish(true)` 停章，不进第 3 章。

### 测试改动

- `tests/integration_playability.gd`
  - `_test_mds_chapter` 第 1 章段改为断言自然交棒：`_chapter == 1`、未
    `_finished`、无结束屏、第 2 章开场已打开（标题/正文/语音/配乐）、计划为
    `big_map`、`demo_cleared` 已置位。
  - 章循环识别「交棒中的第 2 章开场」，不再二次 `_start_chapter(1)`；第 2 章
    段断言 `SpawnPoint` 出生贴合、落地 `is_on_floor()`、清房 0/7（HUD 8）、
    坠落平面 1680。
  - `_test_ch2_big_map` 的两场遭遇改为真实战斗清房（锁定 → 击杀 → 奖励 →
    计数 +1/+2 → 只结算一次），不再直接 `cleared.emit()`。
  - 链路覆盖：第 1 章通关 → 章末选择 → 第 2 章开场 → 大图加载/出生 →
    真实遭遇清房计数 → Boss 2 → 权柄 → outro → 章末选择 → 停章。
- `tests/integration_menus.gd`：键盘/手柄章末选择后断言进入第 2 章开场
  （可见、暂停、焦点在「继续」）；再直接 `_finish(true)` 保留结束屏首帧
  焦点覆盖。
- `tests/integration_run_save.gd`：三条章末边界改为第 2 章开场；关闭开场后
  大图启动、检查点写 `chapter=1`/`room=ch2_entry`；开场期间退出仍保留
  第 1 章 Boss 检查点（重放章末而非跳内容）。

### 验收

- playability **899 → 913 / 0**、menus **445 → 456 / 0**、
  run_save **613 → 624 / 0**。
- 单元 **13,490 / 0**；十一套集成逐套件：913 / 109 / 624 / 207 / 113 /
  59 / 456 / 45 / 2,315 / 4,358 / 5,133，全 0 失败。
- `tests/check_exit_clean.sh` **10/10**；`check_pixel_assets.py --demo`
  **36 / 0**。

### 边界与未做

- 未改第 2 章计划/波次/事件/Boss 2 数值；未改第 1 章内容与结局判定。
- `CHAPTER_PLAN_PATHS[2]/[3]`、`MDS_WORLD_FILES[2]/[3]` 未动，第 3/4 章仍
  不可达。
- `ch2_shortcut` 仍无游戏内授予（第 11 项未拍板）；电梯 80 px/s、相机/HUD
  未动。
- 未推送、未更新网页版、未创建 Release；未改 MDS 插件。
- 记录待办：仓库根 `README.md` 与网页版仍写「第 2–4 章不可达」，第 2 章现已
  可达，需监工决定在后续程更新；本程未改。

## 提交

- `feat: hand chapter 1 off to the chapter 2 big map (pass 77, continues pass 76)`
- `test: cover the chapter 1 to chapter 2 handoff across suites (pass 77)`
- `docs: record pass 76-77 chapter 2 reachability wiring`
