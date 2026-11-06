# 2026-11-06 第 68 程：全游戏例行扫描（brief72）

## 背景与范围

按 `SUPERVISOR_STATUS.md` 与 `.supervisor/DECISIONS.md` 的收口规则做一次
全游戏例行扫描：逐项检查第 1 章 demo 与 Hub/菜单/存档等系统，只找**新的
产品行为缺陷**；不做测试覆盖补充、性能优化、文案轮换这类增益项，也不开
任何新功能。

扫描面（brief72）：

1. 各覆盖页的关闭/返回路径与焦点；
2. 标题/暂停/设置子页/商店/事件/对话的首帧焦点与设备切换；
3. run save 在各写盘点的落盘、续玩恢复、坏档容错与清除；
4. 第 1 章 9 房间 + Hub 的冷/热加载、门过渡、Boss 战帧耗时；
5. 第 1 章与 Hub 的事件/对话/提示文案；
6. 隐藏书库进入路径与结局余味的回归抽查。

本程明确不做（原文要点）：闻烬/白榆可见性与个人事件、阿砚「叫出真名」、
关键道具物品化、结局 id/正文/判定/存档/画廊规则、结局余味配音/插画/独立
场景、第 60 程问题 1/3/6/5/7、第 4 章 Boss 4 机制扩展/舞台母题/捷径授予/
战斗密度、第 2–4 章可达性、章节计划接入 `game.gd`、`CHAPTER_PLAN_PATHS` /
`MDS_WORLD_FILES` 默认值、待确认第 11–16 项、新移动能力、NPC 立绘、MDS
插件本体、新绘/拼凑美术、打包/签名/网页版。

## 任务 0 · 基线核验

- HEAD `250bcd6`，分支 `supervisor-dev`，工作区干净，无会话在跑。
- Godot `4.7.stable.official.5b4e0cb0f`（`--headless --path .
  --import` / `--quit` 均退出 0、`ERROR` 0）。
- 单元 `tests/run_tests.gd`：**13429 passed / 0 failed**。
- 十一套集成（逐套跑完，各日志 `ERROR` 0）：
  `integration_playability` **894** / `integration_ch1_demo` **102** /
  `integration_run_save` **613** / `integration_gamepad` **207** /
  `integration_ui_prompts` **113** / `integration_ch1_event` **59** /
  `integration_menus` **419** / `integration_ai_settings` **45** /
  `integration_ch2_bigmap` **2315** / `integration_ch3_bigmap` **4358** /
  `integration_ch4_bigmap` **5133**。
- `tests/check_exit_clean.sh <godot> 10` → **10/10 clean**；
  `tests/check_pixel_assets.py --demo` → **36 / 0**。
- 与第 67 程自称逐项一致，无基线漂移。Magpie 网关全程可用。

## 扫描经过与逐项结论

### 1. 关闭回退

逐层核对 `game.gd::_input` 的模态顺序、`_toggle_overlay`/`_close_overlay`、
`PauseMenu` 与 `SettingsMenu` 的子页栈，以及 Hub 各页的 `_unhandled_input`：

- 暂停 → 设置 → AI/键位/帮助：Esc/B/Start 先关最上层子页，再关设置；
  设置从暂停打开时经 `_pause_return_overlay`/`_pause_return_focus` 回到
  暂停菜单并还原打开前的焦点。既有 `integration_menus` 已覆盖这些链路。
- 背包/图鉴/帮助/地图/商店/事件页/权柄/归档/奖励/结局屏/画廊都有
  `ui_cancel`（手柄 B）与键盘等价出口；权柄/归档/奖励是必选模态，B/Esc
  只被吞掉、不关页。
- 从暂停进入设置后再按快捷键切换到别的页面，会清掉 `_pause_return_*`，
  关闭后直接回游戏。`_toggle_overlay` 的注释明确写了「页面并列替换」的
  口径，属既有设计而非死路，未按缺陷处理。

结论：**未发现新缺陷**。

### 2. 焦点

- 标题有/无局内存档分别首帧聚焦「继续本局」/「开始旅程」；暂停菜单打开即
  抓可用项；设置子页关闭把焦点还给打开它的按钮；商店/事件/对话/画廊打开
  即抓首个可点项、关闭还原。
- 键盘与手柄切换由 `GameFlow.input_device_changed` 统一驱动提示与焦点；
  `integration_gamepad` 与 `integration_menus` 复跑通过。
- 新修的档案馆满级行是唯一会让焦点落在禁用按钮上的路径，已用
  `_focus_first_pressable` 的既有规则处理（见下）。

结论：**未发现新缺陷**。

### 3. 存档边界

- `RunSave._has_valid_shape` 已覆盖 `[run]/[inventory]/[progress]/[world]/
  [authority]/[mds]` 的所有写出键（含按节点 id 的进度列表、`frenzy`、权柄
  使用位）；`_restore_*` 对异常类型做兜底转换，坏档回退 `.bak` 并提升。
- `save_run_now()` 在死亡/结局/奖励页/非 MDS 时不写；失焦走
  `NOTIFICATION_APPLICATION_FOCUS_OUT`（先保存再开暂停），关窗走
  `NOTIFICATION_WM_CLOSE_REQUEST` → `save_run_on_exit`；死亡先清档再开归档
  模态，胜利保留 Boss 已死检查点直到 `Flow.end_run` 清档；「Boss 已死但
  权柄未选」续玩时由 `_resume_boss_aftermath` 重新授予权柄。
- `integration_run_save` 613 断言复跑 0 失败。

结论：**未发现新缺陷**。

### 4. 性能

用临时探针在真实主场景内实测（探针测后删除，产品代码未改）：

- Hub 冷加载 3 次：`load` **971.8 / 1095.2 / 1064.1 ms**、`instantiate`
  **28.0 / 28.9 / 5.2 ms**、`_ready` + 首帧 **552.7 / 502.3 / 480.8 ms**；
  Hub 60 帧 avg **8.09–8.12 ms**、p95 **8.53–8.63**、max **8.60–9.86**。
- `main.tscn` 冷加载 3 次：`load` **2023.5 / 2127.8 / 2077.4 ms**、
  `instantiate` **6.1–12.1 ms**、`_ready` + 首帧 **672.4–684.7 ms**。
- 第 1 章首房共 7 个 120 帧窗口（4 次运行）：avg 全部 **8.33 ms**
  （120 FPS 预算 8.33）、p95 **8.67–8.79**；5 个窗口 max 8.83–10.50，
  2 个首次进房窗口出现一次性 20.56 / 16.17 ms 尖峰，紧随其后的窗口回落
  到 9.77–10.00。
- 门过渡 `ch1_01.right1 → ch1_02`（作者 0.2 s 淡出 + 淡入）：
  **226.6 / 226.8 / 231.9 / 240.0 ms**，与第 2–4 章 228–244 ms 同量级。
- 逐房原始构建（`fade_time = 0`，首次/缓存）：`ch1_01` 5.5/5.6、
  `ch1_02` 5.5/15.1、`ch1_03` 13.5/12.1、`ch1_04` 7.0/5.9、`ch1_05`
  5.1/5.3、`ch1_06` 5.8/5.7、`ch1_rest` 17.6/10.7、`ch1_boss`
  **77.4/37.0**、`ch1_vault` 23.9/9.9 ms。
- Boss 战 120 帧：avg **8.33**、p95 **8.72–8.81**、max **8.84–12.51**。

对照第 21/22 程基线（冷启动到标题 1625/1689/2071 ms、Hub `load`
585–734 ms、Hub `_ready` 413–467 ms、`main.tscn` 约 2.9 s、首房 avg
8.26–8.31 / p95 8.64–8.71、UI 页 < 8.33 ms）：帧间隔、门过渡与逐房构建
均无持续退化；本程 Hub `load` 偏高、`main.tscn` 偏低，两者合计与基线同
量级，符合开发态首次脚本编译与文件缓存差异。按任务单只记录、不做优化。

结论：**未发现需要处理的产品性能缺陷**。

### 5. 文案 —— 发现并修复 1 项

**缺陷**：档案馆升级已到 demo 上限 Lv.10 时，行仍显示「升级」+ 价格且
可点；点击返回「记忆碎片不足：需要 403，你只有 999999。」——这是自相矛盾
的假错误。根因是 `Profile.buy_archive_level()` 在 `>= 10` 时静默返回
false，`ArchiveUI._buy()` 无法区分「到上限」与「碎片不足」。同一 Hub 的
档案馆页写「demo 每个方向上限 10 级」，而 `NPCProfiles` 里陆沉「档案馆
升级」的职能描述却写「等级没有上限」，两处口径冲突。

**复现**（临时探针，测后删除）：`Profile` 的 `archive_levels` 设为 10、
`memory_fragments` 设为 999999，真实 `ArchiveUI` 打开后按第一行按钮：

```
PROBE before level=10 fragments=999999 cost_label=403 碎片 button=升级 disabled=false
PROBE after  level=10 fragments=999999 cost_label=403 碎片 button=升级 disabled=false
             status=记忆碎片不足：需要 403，你只有 999999。
```

**修复**：

- `ArchiveData.MAX_LEVEL = 10` 作为单一来源（长期设计仍无上限，demo 封顶）；
- `Profile.buy_archive_level()` 改读该常量；
- `ArchiveUI._buy()` 先判满级并提示「「X」已经修到 demo 上限 Lv.10。」；
- `ArchiveUI._refresh()` 满级行显示「已满级」/「已达上限」并禁用，焦点
  按既有 `_focus_first_pressable` 规则跳过禁用行；
- 页内提示改用常量；陆沉职能描述改为「demo 每个方向上限 10 级」。

未改上限数值、价格曲线、存档格式、成长设计或立绘。

**回归断言**：

- `tests/test_growth.gd` +5：上限值 = 10、连买到满、满级后拒绝、等级
  不变、不扣碎片；单元 **13429 → 13434 / 0**。
- `tests/integration_menus.gd` +9：满级行禁用/文案、焦点跳过禁用行、
  `_buy()` 不扣费/不报假缺碎片/说明上限、陆沉描述含上限；菜单集成
  **419 → 428 / 0**。

其余抽查：第 1 章事件 7 组文案、Hub 五名 NPC 问候/态度/离线回应、
残碑/休息/死亡提示/污染警告，未发现新错字或与剧情圣经冲突的点。

### 6. 回归抽查

- 隐藏书库进入路径：`integration_ch1_demo`（102/0）用真实 `door1` 门进入
  `ch1_vault`，复跑通过。
- 结局余味：`test_ending_echoes`（单元套件内）锁定未解锁不泄露余味/回收
  段，`integration_menus` 的画廊断言锁定已解锁展示与锁定占位，均复跑通过。

结论：**未发现回归**。

## 收尾验证

- 单元 **13434 / 0**（+5，全部为满级断言）。
- 十一套集成复跑：894 / 102 / 613 / 207 / 113 / 59 / **428** / 45 /
  2315 / 4358 / 5133，全 0 失败、各日志 `ERROR` 0；三个大图套件均跑完。
- `tests/check_exit_clean.sh <godot> 10` → 10/10 clean；
  `tests/check_pixel_assets.py --demo` → 36 / 0。
- 临时探针（`tests/probe68_archive.gd`、`tests/probe68_perf.gd`）已删除；
  `git status` 收尾为空。

## 提交

- `a08a69e` fix: report the archive demo cap instead of a false fragment shortage
- `f2550dc` test: lock the archive level cap and its maxed-row feedback
- `6021935` docs: record the pass 68 routine scan and archive cap fix
  （状态文件、本 session、记忆索引）

## 结论

例行扫描共发现 1 项新的产品行为缺陷（Hub 档案馆满级行的假错误与可点
状态），已修复并用 14 条新断言锁定；其余五个扫描面未发现新缺陷。性能
数字与基线同量级，按任务单只记录、不优化。未新增待拍板项，第 11–16 项
未碰，第 2–4 章仍不可达。
