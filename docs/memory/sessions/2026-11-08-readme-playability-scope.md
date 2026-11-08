# 第 99 程 · README 口径更新（brief103）

> 目标：把仓库根 `README.md` 的过期口径改到与「第 1–4 章全线可达」一致——可玩范围、
> 章末走向、结局可达性与判定点、测试数字。只改 `README.md`；游戏代码 / 场景 / 资源 /
> 测试 / 配置零改动，章节路由与可达性未动，第 11–16 项待拍板内容不碰。

## 交接

- HEAD `34bcdd7`（第 97 程收尾）、分支 `supervisor-dev`、工作区干净。
- 第 91 程把第 4 章接入主流程（第 3 章章末不再停章），第 97 程完成全流程 1→4 集成验收；
  第 81 程写的「第 1–3 章可玩 / 第 4 章不可达 / 焚毁档案不可达成 / 复原在第三章末达成」
  四处因此全部过期。
- 第 98 程（brief102）被状态文件记为「启动即死」，**实际未死**：`session102.log` 里的
  `[claude-code:unrecognized_model]` 只是模型名未识别警告。该会话仍在跑同一个 README 任务，
  本程读文件期间 `README.md` 连续变了三个版本（md5 `5888e2f5…` → `024b9452…` → `dfaa2b4f…`）。

## 并发写入处理

- 本程请第 98 程会话停手并交回（它已确认停手、未提交、未动状态文件与记忆）。
- 本程按冻结后的最终内容逐行复核后再提交。**账面归属**：`README.md` 改动由第 98 程会话
  起草、第 99 程会话复核并提交（`77e673a`）；状态文件、记忆文档与全部提交只由本程写入，
  避免两个会话同时向 5,888 行的手维护状态文件追加。
- 基线由两个会话各自独立复跑，数字逐项一致。

## 基线（本程实测，与 brief103 预期一致）

- `--headless --import` / `--quit` 退出 0。
- 单元 **13,551 / 0**。
- 十一套集成 **1,475 / 109 / 677 / 207 / 113 / 73 / 458 / 45 / 2,331 / 4,364 / 5,133**
  （合计 **14,985**）全部 0 失败，三个大图套件跑完。
- `tests/check_exit_clean.sh` **10/10 clean**。
- `tests/check_pixel_assets.py --demo` **40 / 0**。

## 核实的旧口径（逐条）

| 位置 | 旧口径 | 现状（核实依据） | 处理 |
|---|---|---|---|
| 第 11 行 | 「可玩第 1–3 章……第三章章末选择后进入结局屏」 | `game.gd::_complete_chapter`：第 1 章末 → `_start_chapter(1)`、第 2 章末 → `_start_chapter(2)`、第 3 章末 → `_start_chapter(3)`、第 4 章末 → `_finish(true)` | 改为第 1–4 章 |
| 第 15 行 | 「本章章末停章，不再继续」 | 第 46 程的停章已被第 91 程取代 | 删句 |
| 第 22 行 | demo 可达 4 个结局；「焚毁档案」暂不可达成；「复原」在第 1–3 章中至少两章选仁慈 | `CampaignData.ending_for(won, corruption, mercy, burned)`（`scripts/core/campaign_data.gd:262-272`）无章节参数、只在战役结束调用；优先级 burned → abyss(≥60) → restored(mercy≥2) → unfinished，失败为 interrupted | 改为五结局全可达，写明判定点与优先级 |
| 第 26–30 行 | 整节「已建成但未开放」，称第 4 章不可达 | 第 91 程 `CHAPTER_PLAN_PATHS[3]` / `MDS_WORLD_FILES[3]` / `MDS_CHAPTER_SCENES[3]` 全部指向第 4 章 | 整节删除，第 4 章并入可玩范围 |
| 第 30 行 | 「第 2–4 章捷径屏障无游戏内授予来源」 | **仍然属实**：`scripts/` 全库无任何 `chN_shortcut` 授予，只有世界 JSON 与计划里的 `requires` | 保留为独立条目，未虚构来源 |
| 第 21 行 | 「本次里程碑新增：吞噬 / 归档权柄、四档信任分层、结局画廊」（v0.12.0/T17 旧口径） | 里程碑内容见状态文件「项目现状」与第 91/97 程专节 | 改为第 2–4 章大地图/事件/Boss 接线 + 全流程 1→4 验收 |
| 第 97 行 | 单元 13,549、集成 14,326 | 本程实测 13,551 / 14,985 | 更新 |
| 第 103 行 | 「第 1–3 章已接入……第 4 章仍不可达」 | 第 1–4 章均已接入 | 改写 |

## 复核中额外改正的三处（brief103 未点名，但按仓库实况已不成立）

- **武器与遗物池**：`RunLoot._weapon_pool` / `_relic_pool`（`scripts/core/run_loot.gd:90-95`）
  只在 `chapter == 0` 返回 `DEMO_WEAPONS`(6) / `DEMO_RELICS`(6)，第 2–4 章返回完整
  `WEAPONS`(12) / `RELICS`(9)；`memory_stele.gd:92` 按 `ch1` 前缀同样分流。旧文
  「demo 开放其中各 6 把 / 6 件」在四章可达后不成立 → 改为「第一章 6 把 / 6 件，
  第二至四章从完整内容库抽取」。
- **NPC 个人事件闸门**：`Profile.demo_cleared` 由 `_complete_chapter` 在**第 1 章交棒时**
  置位（`scripts/game.gd:2300-2306`），不是战役结束 → 「通关一次 demo」改为「打通第一章」。
- **第 4 章插画范围**：9 个 `resources/rooms/ch4_bigmap/*.tres` 全部设了
  `backdrop_path = smiling_theater.png`，不只是舞台区 → 「舞台区使用专属插画」改为
  「全章背景使用专属剧场插画」。

## 复核数字（本程实测，README 逐条对得上）

| 数字 | 来源 |
|---|---|
| 词条 95（39 名词 / 29 动词 / 27 修饰） | `resources/words/*.tres` 95 个；`tests/test_content_expanded.gd:40-42` 锁定 |
| 首次开局 18（6 已解码 + 12 残页词） | `Profile.DEFAULT_OWNED` 18、`DEFAULT_DECODED` 6、`RunLoot.DEMO_FRAGMENT_WORDS` 12 |
| 6 / 6 / 12 / 9 / 14 | `DEMO_WEAPONS` / `DEMO_RELICS` / `WEAPONS` / `RELICS` / `ENEMIES` |
| 13 形态 | `SpellStyle.NAMES` |
| 6 首配乐 | `assets/audio/manifest.json` |
| 第 2/3/4 章各 9 区 22 门、7 个遭遇 | 世界 JSON 实点（20 有向 + 2 只到达；每章 7 个 encounter 节点） |
| 第 1 章清房目标 6 | 计划 4 combat + 1 elite + 1 event + rest + boss + vault；`CLEAR_ROOM_TYPES` 派生 |
| 155 个脚本 / 26,991 行 | `scripts/` 下 `.gd` 统计（「约 2.7 万行」成立） |

> 旧 README 的「demo 6 敌人」不成立：第 1 章波次用 7 种刷怪 id。本程未沿用该说法。

## 改写点（README 结构不变）

简介 → 当前可玩范围 → 核心系统 → 操作 → 运行 → 开发状态，与第 74/81 程一致；
只删掉「已建成但未开放」这一整节。

- 「当前可玩范围」：首句第 1–4 章接续；新增第四章「笑面剧场」条目；结局条目改写；
  里程碑条目改写；捷径说明提为独立条目。
- 「信任分层」：NPC 事件条件改「打通第一章」。
- 「运行」第 3 步按四章接续改写。
- 「开发状态」：数字更新，末条改为第 1–4 章均已接入。

全文 grep `不可达` / `暂不可达成` / `停章` / `尚未接入` / `未开放` / `第 1–3 章` /
`第三章末` 均无命中（「本次里程碑新增」为新内容，非残句）。

## 未改项 / 边界

- 只改 `README.md`；未改游戏代码、场景、资源、测试、配置；章节路由、可达性、存档形状、
  数值、NPC 立绘均未动。
- 版本号未动：`project.godot` 的 `config/version` 与标题屏仍 `0.11.0-demo`；README 不写
  版本号。版本口径若需调整属另行拍板，本程不自造版本号、不新增 Release 计划。
- 第 11–16 项（`ch2_shortcut` / `ch3_shortcut` / `ch4_shortcut` 来源、电梯速度、
  相机 / HUD、视野压缩、海面母题）未碰、未定口径。
- 未推送、未更新网页版、未创建 Release。

## 里程碑事务（只记录，本程不做）

- 网页版已由监工更新到 `34bcdd7`（`redeploy-ok: 34bcdd7`，公网 200）。
- GitHub 推送被跳过：相对 `main` 的 `39c2b891…` 含第 78 程的四张新增二进制精灵
  （`breath_hound.png` / `lung_moth.png` / `rust_whisperer.png` / `collapse_husk.png`），
  连接器快照只接受 UTF-8 文本。须用户本人从他自己的 git 推那四张图到 `main`，之后监工
  再补推其余文本改动。

## 提交

- `77e673a` — `docs: bring README up to the 1-4 chapter playable scope (pass 99)`
- `147d333` — `docs: record the README scope update (pass 99)`
- 本记录与 `MEMORY.md` 索引更新见紧随其后的 docs 提交。
