# 2026-11-06 第 58 程：第 4 章章末收口

## 目标

参照第 46 程对第 3 章的做法，给最终章第 4 章补上显式章末收口：Boss 4 击败 →
权柄 → 第 4 章 outro → 章末选择 → 战役结束/停章，不自动进入不存在的后续章节。
只做章末流程与测试层：第 4 章仍不可达、计划仍不接入 `game.gd`
（`CHAPTER_PLAN_PATHS[3]` 仍空）、世界仍不被 `game.gd` 引用；不做第 4 章大图
验收、不扩展 Boss 4 机制、不新编剧情文本。

## 先核查（事实以仓库为准）

- `_complete_chapter` 原有分支：第 1 章（`_chapter == 0`）置 `demo_cleared`
  后 `_finish(true)`；第 2 章（`_chapter == 1`）在章末选择后 `_finish(true)`
  （第 35 程收口）；第 3 章（`_chapter == 2`）`_finish(true)`（第 46 程收口）；
  其余章节走 `_chapter + 1 < CampaignData.chapter_count()` 自动
  `_start_chapter(_chapter + 1)`，否则 `_finish(true)`。
- 第 4 章是最后一章（`CampaignData.chapter_count() == 4`）：旧兜底
  `_chapter + 1 < chapter_count()` 对 `_chapter == 3` 为假，因此本来就落到
  `else` 的 `_finish(true)`——行为上已经结束战役，但没有显式分支，代码与测试
  都没有把「第 4 章 = 战役终点」写清楚。
- 第 4 章章末文本与语音齐全：`CampaignData.chapter(3)` 已有 4 句 `outro`、
  `choice` 两个选项（重写名册：仁慈 +1；焚毁名册：污染 +12）与
  `voice_outro = ch4_outro`（`assets/audio/voice/zh_cn/ch4_outro.ogg` 存在）；
  `_apply_chapter_choice` 已有 `smiling_theater` 分支（选项 1 置
  `_burned_final`，结局由 `CampaignData.ending_for` 选「焚毁档案」）。
  本程未新编任何剧情文本、未新设选项。
- 续玩/重载逻辑是章节无关的：`_on_mds_room_loaded` 的 Boss 区分支在
  `_boss_defeated` 时调用 `_resume_boss_aftermath`（不二次生成 Boss），
  `_resume_boss_aftermath` 在无权柄时补授予、随后 `_complete_chapter`；
  `_start_mds_chapter` 从 run save 恢复 `_boss_defeated`。第 4 章沿用同一逻辑，
  本程只补断言、不改逻辑。
- 章末选择界面、结局记录、续玩行为沿用第 35/46 程口径：`_story` 结算页 →
  `_story` 选择页 → `_apply_chapter_choice` → `_finish(true)`（结局屏 +
  `Profile.record_ending` + `Flow.end_run`）；第 4 章不另起流程。

## 改动

- `scripts/game.gd`：`_complete_chapter` 在既有第 3 章分支之后新增
  `_chapter == 3` 分支，调用现有 `_finish(true)` 结束战役。第 1/2/3 章分支与
  `_chapter + 1 < chapter_count()` / `else` 兜底未改；只更新了第 3 章分支上方
  已过时的注释（原注释称「Chapter 4 keeps its legacy end-of-campaign finish」）。
  行为与旧的 `else` 兜底等价，本程把战役终点写成显式分支并由测试锁定。
- `tests/integration_playability.gd`（869 → **894**，+25）：
  - `_test_ch4_bigmap_boss` 扩为完整章末链路：把第 52 程大区世界与第 4 章计划
    临时挂到真实主场景（`ch4_boss` 起始），走真实 `room_loaded` 生成
    `SmilingArchivist`；在真实 Boss 上击败 → 权柄二选一（基础池含续命/改写，
    按钮数 = `build_pool` 池大小）→ 第 4 章 outro → 章末选择 → `_finish(true)`
    结束战役；断言 `_chapter` 仍为 3、`_finished`、结局屏可见、`_boss_defeated`
    已记录；测试后 `_restore_chapter_world` 恢复旧第 4 章世界。
  - 同一函数新增章末内容锁定：`CampaignData.chapter_count() == 4`、4 句
    outro、`ch4_outro` 语音键与 OGG 资产、两个章末选项（重写名册/焚毁名册）；
    outro 页标题/正文/语音 id、选择页标题/正文/按钮文案与
    `CampaignData.chapter(3)` 原文逐字一致；选项 0 的仁慈 +1、零污染、
    `_burned_final == false`、结局 id 按 `ending_for` 规则选取并写入
    `Profile.endings`。
  - 同一函数开头锁定本程不变项：`CHAPTER_PLAN_PATHS[3]` 仍空、
    `MDS_WORLD_FILES[3]` 仍指旧 `chapter_4.mdsworld.json`、第 4 章计划清房
    目标 7、7 个遭遇节点、`ch4_branch_a/Arena` 波次表、权柄基础池
    （续命/改写）与 `boss_scene` 指向 `smiling_archivist.tscn`。
  - `_test_mds_chapter` 的旧线性世界遍历补 `chapter_index == 3` 分支：
    `_finished`、`_chapter == 3`、结局屏可见（「停在第 4 章/战役结束」）；
    同时把第 3 章分支的过时注释改为「Chapter 4 is still unreachable」，并把
    章末等待从「第 1/3 章」扩到「第 1/3/4 章」（`_finish` 有 0.65 s 结算延迟）。
- 不变项（本程未改）：`CHAPTER_PLAN_PATHS[3]` 仍空、旧第 4 章 9 房 / 17 门 /
  世界文件仍在、第 4 章计划波次表/权柄池/事件触发口径/Boss 4 机制与
  `boss_scene` 不变（由 `test_ch4_plan` / `test_ch4_content` / `test_ch4_boss` /
  `test_ch4_world` 与 `integration_ch4` 相关断言锁定）；第 1 章 Boss/流程/
  9 房间/6 波次/事件/清房目标 6 与章末流程不变；第 2/3 章计划/大区世界/事件
  触发/权柄池/Boss 机制/章末收口不变。

## 未做（按任务单）

第 4 章接入 `game.gd` / 可达性开放；第 4 章大图验收；Boss 4 机制扩展（剧情
圣经的「改写规则/删除词/复制昌子的武器」、GDD 的「舞台机关」）；`ch4_shortcut`
授予（屏障保持默认封闭）；战斗密度（未扩波/增遭遇，旧世界每房 5–6 只 vs 大图
每遭遇 2 只只记录）；`mask_enemy` / `seat_husk` 独立数值与行为（仍是第 1 章
敌人的美术变体，共享场景/数据，只记录现状）；舞台母题呈现层（未改
`TheaterBackdrop`、未新绘背景）；阿砚同行；新移动能力；NPC 立绘；MDS 插件；
打包/导出/安装器/签名/安卓/触屏。待确认第 11–16 项未施工、未猜测；第 50 程
专节 E 的开放问题候选仍只记录、不编号。

## 验证（本机 Godot 4.7.stable.official.5b4e0cb0f）

- 基线（改动前，HEAD `3ee5438`）：`--headless --path . --import` 退出 0、
  `ERROR` 0；单元 **12657 / 0**；十套集成
  **869 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209 / 4235** 全 0 失败；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与交接一致，无漂移。
- 改动后：单元 **12657 / 0**（未变，新断言在集成层）；可玩性集成
  **894 / 0**（869 + 25）；其余九套集成数字与基线一致、全 0 失败；
  `--import` / `--quit` 退出 0、`ERROR` 0；退出泄漏 **10/10 clean**；
  demo 像素资产 **36 / 0**。
