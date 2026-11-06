# 2026-11-06 第 69 程：全游戏例行扫描（brief73）

## 背景与范围

按 `SUPERVISOR_STATUS.md` 与 `.supervisor/DECISIONS.md` 的收口规则再做一次
全游戏例行扫描：逐项检查第 1 章 demo 与 Hub/菜单/存档等系统，只找**新的
产品行为缺陷**；找到就修并补回归断言，找不到就如实记录基线。不开新功能。

扫描面（brief73）：

1. 各覆盖页的关闭/返回路径与焦点；
2. 标题/暂停/设置子页/商店/事件/对话的首帧焦点与设备切换；
3. run save 在各写盘点的落盘、续玩恢复、坏档容错与清除；
4. 第 1 章 9 房间 + Hub 的冷/热加载、门过渡、Boss 战帧耗时；
5. 第 1 章与 Hub 的事件/对话/提示文案；
6. 隐藏书库进入路径、结局余味、档案馆满级行的回归抽查。

本程明确不做（原文要点）：闻烬/白榆可见性与个人事件、阿砚「叫出真名」、
关键道具物品化、结局 id/正文/判定/存档/画廊规则、结局余味配音/插画/独立
场景、第 60 程问题 1/3/6/5/7、第 4 章 Boss 4 机制扩展/舞台母题/捷径授予/
战斗密度、第 2–4 章可达性、章节计划接入 `game.gd`、`CHAPTER_PLAN_PATHS` /
`MDS_WORLD_FILES` 默认值、待确认第 11–16 项、新移动能力、NPC 立绘、MDS
插件本体、新绘/拼凑美术、打包/签名/网页版。

## 任务 0 · 基线核验

- HEAD `a034d30`，分支 `supervisor-dev`，工作区干净，无会话在跑。
- Godot `4.7.stable.official.5b4e0cb0f`（`--headless --path .
  --import` / `--quit` 均退出 0、`ERROR` 0）。
- 单元 `tests/run_tests.gd`：**13434 passed / 0 failed**。
- 十一套集成（逐套跑完，各日志 `ERROR` 0）：
  `integration_playability` **894** / `integration_ch1_demo` **102** /
  `integration_run_save` **613** / `integration_gamepad` **207** /
  `integration_ui_prompts` **113** / `integration_ch1_event` **59** /
  `integration_menus` **428** / `integration_ai_settings` **45** /
  `integration_ch2_bigmap` **2315** / `integration_ch3_bigmap` **4358** /
  `integration_ch4_bigmap` **5133**。
- `tests/check_exit_clean.sh <godot> 10` → **10/10 clean**；
  `tests/check_pixel_assets.py --demo` → **36 / 0**。
- 与第 68 程自称逐项一致，无基线漂移。Magpie 网关全程可用。

## 扫描经过与逐项结论

### 1. 关闭回退

复核 `game.gd::_input` 的模态顺序、`_toggle_overlay`/`_close_overlay`、
`PauseMenu`/`SettingsMenu` 的子页栈与 Hub 各页的 `_unhandled_input`：
暂停 → 设置 → AI/键位/帮助先退子页再退设置并还原焦点；背包/图鉴/帮助/
地图/商店/事件页/权柄/归档/奖励/结局屏/画廊都有 `ui_cancel` 与键盘出口；
权柄/归档/奖励为必选模态，B/Esc 只吞不关。替换页面会清 `_pause_return_*`
是注释写明的并列替换口径，不是死路。**未发现新缺陷**（menus 433、gamepad
207 复跑）。

### 2. 焦点

标题有/无存档分别聚焦「继续本局」/「开始旅程」；暂停/子页/商店/事件/
对话/画廊首帧与关闭还原、键鼠与手柄切换均一致。**未发现新缺陷**。

### 3. 存档边界

`RunSave._has_valid_shape` 覆盖全部写出键；第 27 程新增的按节点 id 进度键
是可选键、旧档仍读房间键（`d01aebc` 兼容口径，未提升 `SAVE_VERSION`）；
坏档回退 `.bak` 并提升；失焦先保存再暂停、关窗走 `save_run_on_exit`；
死亡先清档再开归档、胜利保留 Boss 检查点直到 `Flow.end_run`，
`_resume_boss_aftermath` 补授权柄。`integration_run_save` 613 复跑通过。
**未发现新缺陷**。

### 4. 性能（只记录）

临时探针（测后删除）在真实主场景内实测：

- Hub `load` **905.5–981.5 ms**、`instantiate` 2.4–11.1 ms、`_ready`+首帧
  **355.1–508.8 ms**；Hub 60 帧 avg **8.09–8.19**、p95 8.60–8.85。
- `main.tscn` `load` **2015.9–2357.9 ms**、`instantiate` 8.4–26.6 ms、
  `_ready`+首帧 614.5–820.1 ms。
- 首房 120 帧 avg **8.27–8.33**、p95 8.64–8.96。
- 门过渡 `ch1_01.right1→ch1_02` **264.0 / 274.4 / 274.8 ms**（3 次；
  第 68 程 226.6–240.0，同量级、本次约高 15%）。
- 逐房构建（首次/缓存）：6.6/4.6、5.9/4.4、13.1/10.2、6.5/4.9、4.4/4.3、
  4.3/4.6、9.9/8.9、**38.6/23.6**（`ch1_boss`）、20.7/9.3 ms。
- Boss 战 120 帧 avg **8.33**、p95 8.72–8.84、max 11.19–14.30。

与第 68/21 程基线同量级，产品侧无持续退化；按任务单只记录、不优化。

### 5. 文案——发现并修复 2 项（3 处）

1. **陆沉「档案馆升级」开启语**写「这里的等级没有尽头」，与
   `ArchiveData.MAX_LEVEL = 10`、档案馆页「demo 每个方向上限 10 级」冲突
   （第 68 程改过同句上游的职能描述，漏了运行时消息）；服务列表句还把
   「10 级」硬编码。改为按常量生成「demo 每个方向修到 Lv.%d 为止，档案
   本身没有尽头」，服务句同步读常量。
2. **闻烬「签一份契约」**描述写「本局起始多 1 次奖励重选」，实际发放
   `start_pages +10` / `start_corruption +6`，消息也写 10 残页；工程内没有
   每局额外重选计数器（重选只来自「改写」权柄）。描述改为「本局起始多
   10 残页，但污染 +6」。
3. **闻烬「买情报」**描述/消息写「首次攻击/第一击额外伤害」，工程内没有
   首次攻击机制；实际是 `wenjin damage` 祝福 +2 由
   `RunLoot.weapon_for_run` 永久加到所有武器。两处改为「所有武器的伤害
   永久 +2」。

未改任何数值、上限、价格、存档或成长设计。其余抽查（第 1 章 7 组事件、
NPC 问候/态度/离线回应、残碑/休息/死亡/污染提示、难度说明、档案馆四轨
描述）未发现新错字或数值冲突。

### 6. 回归抽查

隐藏书库真实 `door1` 进入（ch1_demo 102/0）、结局余味未解锁不泄露/已解锁
展示（单元 `test_ending_echoes` + menus 画廊）、档案馆满级行（`test_growth`
+ menus）均复跑通过，**未发现回归**。

## 修复与回归断言

| 文件 | 改动 |
|---|---|
| `scripts/hub/hub.gd` | 档案馆开启消息按 `ArchiveData.MAX_LEVEL` 生成；服务列表句同步用常量；闻烬情报消息改为「所有武器的伤害永久 +2」 |
| `scripts/hub/npc_profiles.gd` | 契约描述改为「本局起始多 10 残页，但污染 +6」；情报描述改为「所有武器的伤害永久 +2」 |
| `tests/test_hub_final.gd` | 新增 `_test_function_copy_matches_effects`：7 条有价职能描述价格 + 契约 3 条文案 + 2 条实际发放 + 情报 5 条文案/祝福 = **+17** |
| `tests/integration_menus.gd` | 新增 5 条：档案馆开启消息写明 Lv.10/不再声称「等级没有尽头」/页面打开、服务句写明上限/不再声称「没有尽头」 |

结果：单元 **13434 → 13451 / 0**；菜单集成 **428 → 433 / 0**；
gamepad 207、run_save 613 复跑 0 失败。

## 收尾

临时性能探针测后删除；`git status` 只含产品/测试/文档改动，无导入缓存或
产物。未新增待拍板项，第 11–16 项未碰，第 2–4 章仍不可达，
`CHAPTER_PLAN_PATHS` / `MDS_WORLD_FILES` 未动；未推送、未更新网页版。
