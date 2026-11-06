# 2026-11-06 第 70 程：全游戏例行扫描（brief74）

## 背景与范围

按 `SUPERVISOR_STATUS.md` 与 `.supervisor/DECISIONS.md` 的收口规则再做一次
全游戏例行扫描：逐项检查第 1 章 demo 与 Hub/菜单/存档等系统，只找**新的
产品行为缺陷**；找到就修并补回归断言，找不到就如实记录基线。不开新功能、
不推送、不更新网页版、不宣布里程碑。

扫描面（brief74）：

1. 各覆盖页的关闭/返回路径与焦点；
2. 标题/暂停/设置子页/商店/事件/对话的首帧焦点与设备切换；
3. run save 在各写盘点的落盘、续玩恢复、坏档容错与清除；
4. 第 1 章 9 房间 + Hub 的冷/热加载、门过渡、Boss 战帧耗时；
5. 第 1 章与 Hub 的事件/对话/提示文案；
6. 隐藏书库进入路径、结局余味、档案馆满级行、第 69 程文案修正的回归抽查。

本程明确不做（原文要点）：闻烬/白榆可见性与个人事件、阿砚「叫出真名」、
关键道具物品化、结局 id/正文/判定/存档/画廊规则、结局余味配音/插画/独立
场景、第 60 程问题 1/3/6/5/7、第 4 章 Boss 4 机制扩展/舞台母题/捷径授予/
战斗密度、第 2–4 章可达性、章节计划接入 `game.gd`、`CHAPTER_PLAN_PATHS` /
`MDS_WORLD_FILES` 默认值、待确认第 11–16 项、新移动能力、NPC 立绘、MDS
插件本体、新绘/拼凑美术、打包/签名/网页版。

## 任务 0 · 基线核验

- HEAD `381bf26`，分支 `supervisor-dev`，工作区干净，无会话在跑。
- Godot `4.7.stable.official.5b4e0cb0f`（`--headless --path . --import` /
  `--quit` 均退出 0、`ERROR` 0）。
- 单元 `tests/run_tests.gd`：**13451 passed / 0 failed**。
- 十一套集成（逐套跑完，各日志 `ERROR` 0）：
  `integration_playability` **894** / `integration_ch1_demo` **102** /
  `integration_run_save` **613** / `integration_gamepad` **207** /
  `integration_ui_prompts` **113** / `integration_ch1_event` **59** /
  `integration_menus` **433** / `integration_ai_settings` **45** /
  `integration_ch2_bigmap` **2315** / `integration_ch3_bigmap` **4358** /
  `integration_ch4_bigmap` **5133**。
- `tests/check_exit_clean.sh <godot> 10` → **10/10 clean**；
  `tests/check_pixel_assets.py --demo` → **36 / 0**。
- 与第 69 程自称逐项一致，无基线漂移。Magpie 网关全程可用。

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

标题有/无存档分别聚焦「继续本局」/「开始旅程」；暂停菜单打开即抓可用项；
设置子页关闭把焦点还给打开它的按钮；商店/事件/对话/画廊/权柄/归档/奖励
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

临时探针（测后删除）在真实主场景内实测：

- Hub 冷加载：首次 `load` **977.0 ms**、`instantiate` **5.1 ms**、
  `_ready`+首帧 **603.4 ms**；随后两次（依赖已缓存）`load` 6.3 ms、
  `_ready`+首帧 368.4 / 367.9 ms。
- `main.tscn` 冷加载：首次 `load` **2346.9 ms**、`instantiate` 5.9 ms、
  `_ready`+首帧 **687.7 ms**；随后两次 `load` 7.6 / 9.8 ms、
  `_ready`+首帧 627.5 / 696.3 ms。与第 68 程（Hub 971.8–1095.2、
  `main.tscn` 2023.5–2127.8）及第 69 程（Hub 905.5–981.5、
  `main.tscn` 2015.9–2357.9）同量级。
- 首房 3 个 120 帧窗口：avg **8.25 / 8.33 / 8.33**（120 FPS 预算 8.33）、
  p95 8.61 / 8.62 / 8.62、max 8.68 / 8.73 / 9.59；过门后 120 帧 avg 8.33、
  p95 8.68、max 8.94；未见持续掉帧。
- 门过渡 `ch1_01 ↔ ch1_02`：完整淡出+淡入 **442.1 / 449.6 ms**（作者
  `fade_time = 0.22` 两段 + 房间构建），到新房间激活 **121.8 / 221.7 ms**；
  第 68/69 程记录的 226.6–274.8 ms 是「到房间激活」段的同量级读数，端点
  口径不同，未发现产品侧退化。
- 对照第 21/22 程与第 68/69 程基线：帧间隔贴 120 FPS 预算、冷加载与门
  过渡同量级，**只记录、不优化**。

### 5. 文案（发现并修复 5 项 / 8 处）

1. **局内商店「缝合书页」数值写反。**
   `RunLoot.shop_offers` 写「恢复 45 生命与 30 墨量」，`game.gd::_apply_reward`
   实际是 `heal(35)` / `restore_ink(45)` / 污染 −12；`RestOfferData.EFFECT_TEXT`
   也是 35/45。探针经真实主场景 `_apply_reward` 复现：卡面 45/30，实际
   +35 HP / +45 墨 / −12 污染。修复：卡面改为「恢复 35 生命与 45 墨量，
   并净化 12 点污染。」；未改任何数值。
2. **档案馆买到第 10 级后的提示仍报下一次价格。**
   `ArchiveUI._buy` 成功后固定拼「下次需要 %d 碎片」，而同一行已显示
   「已满级/已达上限」，`ArchiveData.MAX_LEVEL = 10` 再也买不了。修复：
   新等级达到上限时改报「升至 Lv.%d，已达 demo 上限」，其余等级仍报
   下一次价格。
3. **阿砚「神铸」描述与消息跟实际祝福不符。**
   描述写「花费 25 记忆碎片…免费提升 1 级基底」，自相矛盾；消息固定写
   「锻造祝福 +1」，但 `FORGE_BONUS_TOTAL_CAP = 3.0` 封顶时实际加 0、
   接近封顶时只加余量；代码还硬编码 3.0。修复：描述改为「断页剑基底直接
   提升 1 级，并获得锻造祝福（上限 3）」；`_forge_god` 改用
   `NPCProfiles.FORGE_BONUS_TOTAL_CAP`，按实得 0 / 0.5 / 1 点如实报数
   （封顶时「锻造祝福已至上限」）。
4. **咕噜货架描述只说「换词」。**
   黑市 18 件货里有 3 件遗物（深渊钟、净墨灯、不朽档案），描述会让玩家
   漏看遗物。修复：改为「换词与遗物」。
5. **零污染遗物的奖励卡印「污染 +0」。**
   `RunLoot.choices`/`elite_choices` 无条件拼污染行，而
   `clean_ink_lantern.corruption = 0`（第 1 章 demo 遗物池内）；Hub 商店
   早已用 `corruption > 0` 守卫。修复：新增 `_relic_reward_text()`，仅正
   污染才写该行；其余遗物（如 `ink_heart` +1）仍正常显示。

其余抽查（第 1 章事件 7 组文案、Hub 五名 NPC 问候/态度/离线回应、残碑/
休息/死亡/污染提示、难度说明、档案馆四轨描述、教程三步与帮助键位说明）
未发现新错字或与数值/剧情圣经冲突的点。

### 6. 回归抽查

隐藏书库真实 `door1` 进入（ch1_demo 102/0）、结局余味未解锁不泄露/已解锁
展示（单元 `test_ending_echoes` + menus 画廊）、第 68 程档案馆满级行
（`test_growth` + menus，本程又补买到第 10 级后的提示）、第 69 程三处 Hub
文案（`test_hub_final` 契约/情报断言）均复跑通过，**未发现回归**。

### 7. 未修的记录项

设置页的「全屏」切换只改 `DisplayServer.window_set_mode`，未写入 `Profile`
（音量/震动/闪烁/字号/AI/键位均持久化），重启后回到窗口模式。补持久化会
新增 Profile 键、改变设置存档形状，任务单未要求，本程只记录、不修、
不新增待确认条目。其余无新增产品缺陷；第 11–16 项未碰，第 2–4 章仍不可达。

## 修复与回归断言

| 文件 | 改动 |
|---|---|
| `scripts/core/run_loot.gd` | 缝合书页文案改为 35 生命/45 墨量；新增 `_relic_reward_text()`（零污染不写「污染 +0」）并用于 `choices`/`elite_choices` |
| `scripts/ui/archive_ui.gd` | 买到 demo 上限时状态提示改报上限，不再报下一次价格 |
| `scripts/hub/hub.gd` | `_forge_god` 改用 `NPCProfiles.FORGE_BONUS_TOTAL_CAP`，按实际增加的祝福报数 |
| `scripts/hub/npc_profiles.gd` | 神铸描述改为「基底直接提升 1 级…（上限 3）」；咕噜货架描述补「与遗物」 |
| `tests/test_shop.gd` | +1：缝合书页文案 |
| `tests/test_hub_final.gd` | +9：咕噜货架 2 + 神铸 7 |
| `tests/test_demo_loot.gd` | +4：零污染/有污染遗物卡 |
| `tests/integration_menus.gd` | +12：档案馆最终一级 3 + 神铸 9 |
| `tests/integration_playability.gd` | +5：缝合书页标题/三项实际数值/文案与数值一致 |

结果：单元 **13451 → 13465 / 0**；菜单集成 **433 → 445 / 0**；可玩性集成
**894 → 899 / 0**。修复后复跑 gamepad 207、run_save 613、ui_prompts 113
全 0 失败；收尾完整套件见下。

## 收尾复跑（全绿）

- 单元 **13465 / 0**。
- 十一套集成 **899 / 102 / 613 / 207 / 113 / 59 / 445 / 45 / 2315 / 4358 /
  5133**，全 0 失败、各日志 `ERROR` 0。
- `--headless --import` / `--quit` 退出 0、`ERROR` 0；退出泄漏
  **10/10 clean**；demo 像素 **36 / 0**。
- 临时探针（`tests/_probe_rest_offer.gd`、`tests/_probe_perf.gd`、
  `tests/_probe_door.gd`）复现/测量后删除；`git status` 仅含产品/测试/
  文档改动，无导入缓存或产物。
- 第 2–4 章仍不可达，`CHAPTER_PLAN_PATHS[2]/[3]` 与 `MDS_WORLD_FILES`
  未动；未推送、未更新网页版、未宣布里程碑。

## 提交

- `808ec47` `fix:` 产品代码（4 个脚本）：缝合书页数值、档案馆满级提示、
  神铸实报、咕噜货架描述、零污染遗物卡。
- `249f774` `test:` 回归断言（5 个测试文件）：单元 +14、菜单集成 +12、
  可玩性集成 +5。
- `f93b58a` `docs:` 状态文件第 70 程专节/本程日志/下一程第 ⑲ 条、
  本 session 文档、`docs/memory/MEMORY.md` 索引行。
