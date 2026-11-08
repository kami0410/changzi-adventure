# 第 97 程 · 全流程 1→4 集成验收（brief101）

> 目标：一条局从新局打到结局屏，证明四章接线后主流程在真实输入/真实场景/真实存档
> 下走得通、跨章状态结转正确、两条结局路径都落盘。只做验收与缺陷修复：不改章节
> 计划/波次/事件文案/Boss 数值与机制、不改 `ending_for` 与存档形状、不新增捷径授予、
> 不动相机/HUD/电梯/门逻辑。第 11–16 项未碰；README 的过期口径按第 81 程先例另排一程。

## 交接

- HEAD `b6bd5b5`（第 91 程收尾），`supervisor-dev`，工作区只有一件未提交文件
  `tests/probe_chain_boot.gd`（第 96 程遗留）。
- 第 92 程（brief96）基线跑绿、做完缺口分析后在写链路前中断（无提交）；
  第 93/94/95 程（brief97/98/99）启动即死（日志只有 `[claude-code:unrecognized_model]`）；
  第 96 程（brief100）无声夭折、零提交，只留下那件探针。本程为**全新重跑**。
- 基线逐项复现：导入/退出 0；单元 **13,551 / 0**；十一套集成 **847 / 109 / 675 / 207 /
  113 / 73 / 458 / 45 / 2,331 / 4,364 / 5,133**（合计 14,395）全 0 失败；退出 **10/10**；
  像素 **40 / 0**。

## 遗留探针

`tests/probe_chain_boot.gd`：40 行、5 条断言，`extends SceneTree`，用
`user://probe_profile.cfg` + `reset_profile()`，加载 Hub 断言教学激活，再
`hub.request_run()` 断言新场景是游戏脚本、`_chapter == 0`、开场页已开。单独跑 **5/5 通过**。
它只覆盖本程链路开头那一小段，已被 `_test_full_campaign_chain()` 前 20 条断言更强地覆盖，
**删除**，工作区恢复干净。

## 链路（`tests/integration_playability.gd::_test_full_campaign_chain`）

+628 断言，接在既有 `_run` 尾部。真实输入 / 真实场景 / 真实存档；**无传送作弊、无内部
结算函数跳关**——清房靠真实 `Enemy.take_damage`、走门靠 `MDSGate.use()`、章节推进靠章末
选择、检查点全走 `RunSave` 落盘与 `RunSave.read` 读回。

新局 → Hub 教学三步（`tutorial_done` 落盘）→ `hub.request_run()` → 第 1 章（`ch1_01`…`ch1_06`
逐门实走、`ch1_03` 书库往返、`ch1_05` 事件页、清房 6/7、休整房、Boss 1、权柄 → outro →
章末选择「带回档案馆」）→ 第 2 章大图（支路 B 1 场、支路 A 2 场、事件区一次性、纵井 2 场、
精英 1 场 = 7；Boss 2 → 权柄 → outro → 「替它续气」）→ 第 3 章大图（同路线；Boss 3 →
「带读者离开」）→ 第 4 章大图（同路线；Boss 4 → 「焚毁名册」）→ 战役结束 + 结局屏；
再从**真实 Boss 4 检查点**续玩一次、走「重写名册」拿第二个结局。

战斗奖励一律取第 3 张休整卡（回复/墨量/净化），事件页取第 2 项，所以污染只受章末选择影响。

## 交棒断言（每处都查）

- 路由：`CHAPTER_PLAN_PATHS[i]` 的 `resource_path`、`MDS_WORLD_FILES[i]`、`MDS_CHAPTER_SCENES[i]`、
  `plan.big_map`、起始区 `chN_entry`。
- 开场：眉题含「第 N 章」、标题 = `chapter["title"]`、逐句开场文本（按数组长度：6 / 7 / 7 / 8 句）、
  配乐 = `chapter["music"]`、语音以 `chN_intro.ogg` 结尾。
- 出生：`SpawnPoint` 存在、距标记 < 2 px、`is_on_floor`（不是空中坠落）。
- 数字：清房目标 7（第 1 章 6）、HUD「档案  0 / 8」（第 1 章 `/ 7`）、坠落平面 = 区高 + 240
  （第 2–4 章 1680）、地图标题按 region 派生。
- 结转：`demo_cleared`（内存 + 磁盘）、仁慈 1/2/3、`Profile.endings` 通关前为空、
  `cleared_in_chapter == 0`、`cleared_encounters` 为空、`boss_defeated == false`——全部从
  **磁盘上的 run save** 读回。

## 跨章结转

- 权柄（第 83 程 `authority.chapter`）：每章 Boss 死后 `_authority_granted_chapter == 本章`；
  第 4 章 Boss 死检查点仍带第 3 章的值（2），续玩时三选一重新给（不吞），选完更新为 3。
- 局内存档：每章交棒后与每次权柄授予后各读回一次（章节、房间、清房进度、仁慈、权柄、
  `boss_defeated`）。
- Boss 已死续玩（第 84 程）：目标条 = 「笑面史官已经倒下」、不二次生成 Boss、outro → 章末
  选择 → 战役结束照常。
- 结局：`flow.last_ending["id"]`、结束屏标题、`Profile.endings`、结局画廊四处一致；
  焚毁路径实走 → `burned`，续玩重写 → `restored`，两条同时在 `Profile.endings`、画廊均解锁，
  结束屏 `Echoes` 非空。

## 「复原」判定点（核实第 81 程 README 口径）

`CampaignData.ending_for(won, corruption, mercy, burned)` **没有章节参数**，判定只发生在
战役结束（第 4 章末）。所以第 81 程 README 的「跨章仁慈 ≥ 2 且污染 < 60 可在第三章末达成」
在第 91 程接通第 4 章后已过期。本程如实断言：仁慈累计 3、第 4 章末选「重写名册」→ `restored`；
选「焚毁名册」→ `burned`（优先于 `abyss`/`restored`）。判定规则未改，README 未改（另排一程）。

## 修复的产品缺陷（1 项）

**Boss 已死检查点续玩会把死掉 Boss 的房间重新锁上。** 真实检查点是击杀当帧写的，位置落在
Boss 房内；`_update_room_locks()` 只跳过「已锁/已清」的房间，于是续玩时重新锁上玩家所在的
Boss 房：重放 Boss 入场音效、把「<Boss>已经倒下」目标条改写回新的击杀命令，而权柄三选一
已经在后面排着。

- 修复：`_update_room_locks()` 在 `_boss_defeated` 为真时跳过 Boss 房（`_is_boss_room()`），
  普通房间照旧锁门、清房记账不受影响。
- 既有五个续玩测试都没抓到：它们手写的存档把玩家放在 Boss 房**外**。把
  `integration_run_save` 的 aftermath 存档位置改成真实落点（`ch1_boss` 世界原点 x=8960 +
  Arena 局部 (640, 280) → `[9600, 490]`，落在 `|x|<530`、`-260<y<300` 的入场带内）。
- **反向验证**：临时回退修复 → 该套件复现 2 条失败；恢复后 0 失败。
- 回归断言：`run_save_aftermath_dead_boss_room_stays_open` / `..._no_entrance_replay`、
  `chain_resume_dead_boss_room_stays_open` / `..._no_entrance_replay` /
  `..._keeps_chapter_music`。

## 收尾基线

- 单元 **13,551 / 0**；十一套集成 **1,475 / 109 / 677 / 207 / 113 / 73 / 458 / 45 /
  2,331 / 4,364 / 5,133**（合计 **14,985**）全 0 失败；退出 **10/10**；像素 **40 / 0**。
- 提交（`supervisor-dev`）：`fix:` 死 Boss 房不重锁 / `test:` aftermath 真实落点 + 2 条回归 /
  `test:` 全流程链路 +628 / `docs:` 本记录、状态文件与记忆索引。
- 未推送、未更新网页版、未创建 Release；第 11–16 项未碰；README 四处过期口径待单独一程。
