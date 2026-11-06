# 2026-11-06 第 72 程：全游戏例行扫描（brief76）

## 背景与范围

第 71 程（brief75）开局即因 Magpie 网关中断夭折：`.supervisor/session75.log`
只有网关报错与会话启动两行，零产出、无提交。本程是第 71 程例行扫描的全新
重跑，不假设第 71 程留下任何工作。

按 `SUPERVISOR_STATUS.md` 与 `.supervisor/DECISIONS.md` 的收口规则再做一次
全游戏例行扫描：逐项检查第 1 章 demo 与 Hub/菜单/存档等系统，只找**新的
产品行为缺陷**；找到就修并补回归断言，找不到就如实记录基线。不开新功能、
不推送、不更新网页版、不宣布里程碑。

扫描面（brief76）：

1. 各覆盖页的关闭/返回路径与焦点；
2. 标题/暂停/设置子页/商店/事件/对话的首帧焦点与设备切换；
3. run save 在各写盘点的落盘、续玩恢复、坏档容错与清除；
4. 第 1 章 9 房间 + Hub 的冷/热加载、门过渡、Boss 战帧耗时；
5. 第 1 章与 Hub 的事件/对话/提示文案；
6. 隐藏书库进入路径、结局余味、档案馆满级行、第 69/70 程文案修正的回归抽查。

本程明确不做（原文要点）：闻烬/白榆可见性与个人事件、阿砚「叫出真名」、
关键道具物品化、结局 id/正文/判定/存档/画廊规则、结局余味配音/插画/独立
场景、第 60 程问题 1/3/6/5/7、第 4 章 Boss 4 机制扩展/舞台母题/捷径授予/
战斗密度、第 2–4 章可达性、章节计划接入 `game.gd`、`CHAPTER_PLAN_PATHS` /
`MDS_WORLD_FILES` 默认值、待确认第 11–16 项、新移动能力、NPC 立绘、MDS
插件本体、新绘/拼凑美术、打包/签名/网页版。

## 任务 0 · 基线核验

- HEAD `3847343`，分支 `supervisor-dev`。
- Godot `4.7.stable.official.5b4e0cb0f`（`--headless --path . --import` /
  `--quit` 均退出 0、`ERROR` 0）。
- 单元 `tests/run_tests.gd`：**13465 passed / 0 failed**。
- 十一套集成（逐套跑完，各日志 `ERROR` 0）：
  `integration_playability` **899** / `integration_ch1_demo` **102** /
  `integration_run_save` **613** / `integration_gamepad` **207** /
  `integration_ui_prompts` **113** / `integration_ch1_event` **59** /
  `integration_menus` **445** / `integration_ai_settings` **45** /
  `integration_ch2_bigmap` **2315** / `integration_ch3_bigmap` **4358** /
  `integration_ch4_bigmap` **5133**。
- `tests/check_exit_clean.sh <godot> 10` → **10/10 clean**；
  `tests/check_pixel_assets.py --demo` → **36 / 0**。
- 与第 70 程记录逐项一致，无基线漂移。本程未出现 Magpie 网关中断。

## 扫描经过与逐项结论

### 1. 关闭回退

复核 `game.gd::_input` 的模态顺序（权柄/归档必选模态吞 B/Esc、地图先于
覆盖页、暂停先退设置子页）、`_toggle_overlay`/`_close_overlay`、
`PauseMenu`/`SettingsMenu` 的子页栈，以及 Hub 各页的 `_unhandled_input`
（对话/商店/档案馆/帮助/灵感/教程图鉴均用 `pause`/`ui_cancel` 退出）。
背包是只读页、打开不抓焦点，但 `ui_cancel` 出口存在，不是死路；
`_pause_return_*` 在页面并列替换时清空是注释写明的口径，不是缺陷。
**未发现新缺陷**（menus 445、gamepad 207 复跑）。

### 2. 焦点

标题有/无存档分别聚焦「继续本局」/「开始旅程」（`integration_menus`
`title_first_focus_no_save` / `title_first_focus_with_save` 直接断言）；
暂停菜单打开即抓可用项；设置子页关闭把焦点还给打开它的按钮
（`SettingsMenu._on_subpage_closed`）；商店/事件/对话/画廊/权柄/归档/奖励
打开即抓首个可点项、关闭还原；键盘与手柄切换由
`GameFlow.input_device_changed` 统一驱动提示与焦点。**未发现新缺陷**。

### 3. 存档边界

逐点核对写盘调用：进房、奖励选择、事件结算、商店买/关、残碑、宝箱、
Boss 死亡、权柄授予、暂停、失焦、关窗（`save_run_on_exit`）均有
`save_run_now()`；`save_run_now()` 在死亡/结局/奖励页/非 MDS 时拒绝写入。
`RunSave.read()` 对坏档回退 `.bak` 并提升、结构无效则清理；死亡先清档再
开归档（`_death_committed`），胜利保留 Boss 已死检查点直到 `Flow.end_run`
清档，「Boss 已死但权柄未选」由 `_resume_boss_aftermath` 重新授予。
`integration_run_save` 613 复跑通过。**未发现新缺陷**。

### 4. 性能（只记录）

临时探针（测后删除）在真实主场景内实测，每项 3 个新进程样本：

- Hub 冷加载：`load` **753.1 / 792.2 / 905.1 ms**、`_ready`+首帧
  **461.6 / 468.0 / 556.4 ms**。与第 68 程（`load` 971.8–1095.2）、
  第 69 程（905.5–981.5）、第 70 程（977.0 / 603.4）同量级。
- `main.tscn`：**2779.9 / 2801.1 / 2921.8 ms**，比第 69/70 程
  （2015.9–2357.9）高约 20–25%，仍同量级，按任务单只记录、不优化。
- 第 1 章 9 房间原始构建（`fade_time = 0`）：冷 **3.84–37.39 ms**
  （`ch1_03` 11.5–11.7、`ch1_rest` 8.6–9.0、`ch1_boss` 30.7–37.4、
  `ch1_vault` 10.1–14.2，其余 3.8–6.5）；热 **3.77–23.06 ms**。
  与第 68 程（5.1–77.4）、第 69 程（4.3–38.6）同量级或更低。
- Boss 战 120 帧：avg **8.33 / 8.33 / 8.45 ms**（120 FPS 预算 8.33）、
  peak 10.27 / 10.61 / 25.36 ms（首个样本含刚释放 Hub 的抖动），
  与第 68/69/70 程的 Boss avg 8.33 一致。
- 门过渡 `ch1_01.right1 → ch1_02`（作者 `fade_time = 0.22`，到新房间激活）：
  **225.26 / 225.56 / 225.66 ms**，与第 68 程 226.6–240.0、第 70 程激活段
  121.8–221.7 同端点、同量级，未发现退化。
- 不做任何优化改动。

### 5. 文案（发现并修复 1 项产品行为缺陷）

**跟阿砚打招呼会静默扣碎片、升级断页剑基底。**
`scripts/hub/hub.gd::talk_to_npc` 的 `&"ayan"` 分支把
`upgrade_sword_base().get("message")` 直接拼进问候语，而
`upgrade_sword_base()` 是**真正扣碎片、提升基底等级**的付费操作；
正确的付费入口是「言灵对话」面板里的「锻造基底」
（`perform_npc_function` → `upgrade_sword_base`）。无头探针在真实
`hub.tscn` 复现：碎片 **100 → 90**、基底 **Lv.0 → Lv.1**，对话里出现
「记忆碎片 -10。断页剑基底已升至 Lv.1…」。碎片不足时，每次问候还会
重复附上「记忆碎片不足」的失败消息。

修复：问候改为非交易性说明——报当前基底等级，并指向「言灵对话」里的
「锻造基底」，不写死价格（折扣/托付免费会变）：
「断页剑基底现在是 Lv.%d。要再锻一层，在「言灵对话」里选「锻造基底」——
花多少碎片，看交情。」未改锻造数值、折扣、信任或存档。

其余抽查（第 1 章事件 7 组文案、Hub 五名 NPC 问候/态度/离线回应、残碑/
休息/死亡/污染提示、难度说明、档案馆四轨描述、教程三步与帮助键位说明、
第 69/70 程修过的契约/情报/神铸/货架/缝合书页/遗物卡）未发现新错字或
与数值/剧情圣经冲突的点。

### 6. 回归抽查

隐藏书库真实 `door1` 进入（ch1_demo 102/0，`demo_vault_entered`）、结局余味
未解锁不泄露/已解锁展示（单元 `test_ending_echoes` + menus 画廊断言）、
第 68 程档案馆满级行（`test_growth` + menus）、第 69 程三处 Hub 文案
（`test_hub_final` 契约/情报断言）、第 70 程五项文案（`test_shop` /
`test_hub_final` / `test_demo_loot` + menus + playability）均复跑通过，
**未发现回归**。

### 7. 未修的记录项

- 设置页的「全屏」切换仍只改 `DisplayServer.window_set_mode`，不写
  `Profile`（第 70 程记录项，本程复核仍在）；补持久化会新增 Profile 键、
  改变设置存档形状，任务单未要求，只记录、不修、不新增待确认条目。
- 第 60 程样图问题：1/3/6（HUD 遮挡、`boss_background` 被静态背景遮住）
  与待确认第 13/15 项相关，拍板前不施工；5/7 已判定为取景限制/既有素材，
  不是缺陷，不动。
- 第 11–16 项未碰、未新增待拍板项；第 2–4 章仍不可达。

## 修复与回归断言

| 文件 | 改动 |
|---|---|
| `scripts/hub/hub.gd` | `talk_to_npc` 的阿砚分支不再调用 `upgrade_sword_base()`；改为报当前基底等级并指向「言灵对话 → 锻造基底」 |
| `tests/test_hub_final.gd` | +9：问候不扣碎片/不升级、对话提到「锻造基底」与当前 Lv.、关闭后解冻玩家、显式职能仍升级并按 10 + Lv×10 扣费 |

结果：单元 **13465 → 13474 / 0**。受影响的集成复跑：menus 445、
run_save 613、gamepad 207、ui_prompts 113、playability 899，全 0 失败；
收尾再跑其余六套，数字与基线一致。临时探针
`tests/_probe_ayan_talk.gd` / `tests/_probe_pass72_perf.gd` 测后删除。

## 收尾复跑（全绿）

- 单元 **13474 / 0**（+9）。
- 十一套集成 **899 / 102 / 613 / 207 / 113 / 59 / 445 / 45 / 2315 / 4358 /
  5133**，全 0 失败、各日志 `ERROR` 0。
- `--headless --import` / `--quit` 退出 0、`ERROR` 0；退出泄漏
  **10/10 clean**；demo 像素 **36 / 0**。
- 第 2–4 章仍不可达，`CHAPTER_PLAN_PATHS[2]/[3]` 与 `MDS_WORLD_FILES`
  未动；未推送、未更新网页版、未宣布里程碑。

## 提交

- `68bea06` `fix:` `scripts/hub/hub.gd`：阿砚问候不再静默购买锻造。
- `2381b6c` `test:` `tests/test_hub_final.gd`：+9 条回归断言。
- `<本提交>` `docs:` 状态文件第 72 程专节/第 71 程夭折记录/下一程第 ⑳ 条、
  本 session 文档、`docs/memory/MEMORY.md` 索引行。
