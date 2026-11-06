# 2026-11-05 第 46 程：第 3 章章末收口

## 目标

参照第 35 程对第 2 章的做法（章末选择后 `_finish(true)` 停章，不自动进入未实现
的下一章），给第 3 章补上章末收口：第 3 章章末选择后停章，不再自动进入未实现的
第 4 章。只做章末流程与测试层：第 3 章仍不可达、计划仍不接入 `game.gd`（`CHAPTER_PLAN_PATHS[2]`
仍空）、大图验收与门视觉留给后续程。

## 先核查（事实以仓库为准）

- `_complete_chapter` 现有分支：第 1 章（`_chapter == 0`）置 `demo_cleared` 后
  `_finish(true)`；第 2 章（`_chapter == 1`）在章末选择后 `_finish(true)`（第 35
  程收口）；其余章节走 `_chapter + 1 < CampaignData.chapter_count()` 自动
  `_start_chapter(_chapter + 1)`，否则 `_finish(true)`。因此第 3 章
  （`_chapter == 2`）此前自动进入第 4 章。
- 第 3 章章末文本与语音齐全：`CampaignData.chapter(2)` 已有 4 句 `outro`、
  `choice` 两个选项（仁慈 +1 / 污染 +8）、`voice_outro = ch3_outro`
  （`assets/audio/voice/zh_cn/ch3_outro.ogg` 存在）；`_apply_chapter_choice`
  已有 `lightless_sea` 分支（选项 0 恢复 20 生命 / 选项 1 获得未拥有遗物）。
  本程未新编任何剧情文本。
- 续玩/重载逻辑是章节无关的：`_on_mds_room_loaded` 的 Boss 区分支在
  `_boss_defeated` 时调用 `_resume_boss_aftermath`（不二次生成 Boss），
  `_resume_boss_aftermath` 在无权柄时补授予、随后 `_complete_chapter`；
  `_start_mds_chapter` 从 run save 恢复 `_boss_defeated`。第 3 章沿用同一逻辑，
  本程只补断言、不改逻辑。
- 章末选择界面、结局记录、续玩行为沿用第 35 程口径：`_story` 结算页 →
  `_story` 选择页 → `_apply_chapter_choice` → `_finish(true)`（结局屏 +
  `Profile.record_ending` + `Flow.end_run`）；第 3 章不另起流程。

## 改动

- `scripts/game.gd`：`_complete_chapter` 在既有第 2 章分支之后新增
  `_chapter == 2` 分支，调用现有 `_finish(true)` 并返回，不再自动进入第 4 章。
  第 1 章分支、第 2 章分支与第 4 章分支（`_chapter + 1 < chapter_count()` /
  `else`）未改；只更新了第 2 章分支上方已过时的注释（原注释称第 3–4 章仍
  自动续章）。第 4 章仍保留原有 end-of-campaign `_finish(true)`。
- `tests/integration_playability.gd`（732 → **754**，+22）：
  - `_test_ch3_bigmap_boss` 扩为完整章末链路：把第 41 程大区世界与第 3 章计划
    临时挂到真实主场景（`ch3_boss` 起始），走真实 `room_loaded` 生成
    `LastReader`；在真实 Boss 上击败 → 权柄二选一（基础池含续命/改写，按钮数
    = `build_pool` 池大小）→ 第 3 章 outro → 章末选择 → `_finish(true)` 停章；
    断言 `_chapter` 仍为 2、`_finished`、结局屏可见、`_boss_defeated` 已记录；
    测试后 `_restore_chapter_world` 恢复旧第 3 章世界。
  - 同一函数开头锁定本程不变项：`CHAPTER_PLAN_PATHS[2]`/`[3]` 仍空、
    `MDS_WORLD_FILES[2]` 仍指向旧 `chapter_3.mdsworld.json`、第 3 章计划清房
    目标 7、7 个遭遇节点、`ch3_branch_a/Arena` 波次表、权柄基础池
    （续命/改写）与 `boss_scene` 指向 `last_reader.tscn`。
  - `_test_mds_chapter` 的第 3 章旧线性世界收口断言从「自动进第 4 章」改为
    「停在第 3 章」：`_finished`、`_chapter == 2`、结局屏可见（+3 断言），
    并移除原 `chapter_3_transitions` 断言（−1）。
  - Boss 已死续玩断言沿用既有覆盖：`_boss_defeated` 时重载不二次生成
    Boss、Boss 房内无 `LastReader`；本程只把重载前的 `paused` 复位（结局屏
    会暂停 SceneTree）。
- 不变项（本程未改）：`CHAPTER_PLAN_PATHS[2]` 仍空、旧第 3 章 9 房 / 17 门 /
  世界文件仍在、第 3 章计划波次表/权柄池/事件数据/Boss 3 机制与 `boss_scene`
  不变（由 `test_ch3_plan` / `test_ch3_content` / `test_ch3_boss` /
  `test_ch3_world` 锁定）；第 1 章 Boss/流程/9 房间/6 波次/事件/清房目标 6 与
  章末流程不变；第 2 章计划/波次表/大区世界/事件触发/权柄池/Boss 2 机制与章末
  收口不变（`integration_ch2_bigmap` 2209 / `test_ch2_*` 全绿）；第 4 章无内容
  改动。

## 未做（按任务单）

第 3 章接入 `game.gd` / 可达性开放；第 3 章大图验收套件；第 3 章门视觉专项；
第 3 章地图标题与敌人美术核查；阿砚同行；新移动能力；NPC 立绘；MDS 插件本体；
敌人/场景美术；打包/导出/安装器/签名/安卓/触屏。待确认第 11/12/13/14/15/16
项未施工、未猜测：未新增 `ch2_shortcut` / `ch3_shortcut` 授予，未改电梯速度，
未改大图相机/HUD，未实现视野压缩或海面母题。

## 验证（本机 Godot 4.7.stable.official.5b4e0cb0f）

- 基线（改动前，HEAD `1ce61f8`）：`--headless --path . --import` / `--quit`
  退出 0、`ERROR` 0；单元 **10207 / 0**；九套集成
  **732 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209** 全 0 失败；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与交接一致，无漂移。
- 改动后：单元 **10207 / 0**（未变，新断言在集成层）；可玩性集成
  **754 / 0**（732 + 22）；其余八套集成数字与基线一致、全 0 失败；
  `--import` / `--quit` 退出 0、`ERROR` 0；退出泄漏 **10/10 clean**；
  demo 像素资产 **36 / 0**。
