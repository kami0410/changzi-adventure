# 第 3 章章末收口

- 日期：2026-11-05（第 46 程）
- 状态：**已被第 91 程取代**——第 3 章末选择后不再停章，改为 `_start_chapter(3)`
  进入第 4 章大图（章末选择界面与选项效果仍按本文第 2/3 条复用）。本文件保留
  作历史口径；第 4 章末仍 `_finish(true)` 结束战役，见
  [第 4 章章末收口](2026-11-06-chapter4-ending.md)、
  [第 4 章可达性接线第 1 步](../sessions/2026-11-07-chapter4-reachability-wiring.md)。

## 背景

第 35 程对第 2 章末做了停章：`_complete_chapter` 在章末选择结算后对
`_chapter == 1` 调用 `_finish(true)`，不再自动进入未实现的第 3 章；当时第 3/4
章保留原有自动续章。第 45 程完成后，第 3 章已有计划（9 区图）、真实大区世界、
事件文案、波次接线、权柄池与 Boss 3「最后的读者」机制/`boss_scene` 路由，但
第 3 章末仍会自动进入未实现的第 4 章。

## 决定

1. `_complete_chapter` 在既有第 2 章分支之后新增 `_chapter == 2` 分支，调用
   现有 `_finish(true)` 停章。第 1 章分支、第 2 章分支与第 4 章分支
   （`_chapter + 1 < chapter_count()` / `else`）不改；第 4 章保留原有
   end-of-campaign `_finish(true)`。
2. 沿用第 35 程口径：章末选择界面、结局记录（`Profile.record_ending` /
   `Flow.end_run`）、续玩行为全部复用，不另起第 3 章专属章末流程；不新增
   「待续」UI、结局 id 或存档键。
3. 未新编剧情文本：`CampaignData.chapter(2)` 已有 4 句 outro、两个选项、
   `ch3_outro` 语音，`_apply_chapter_choice` 已有 `lightless_sea` 分支
   （选项 0 恢复 20 生命 / 选项 1 获得未拥有遗物）。
4. 续玩/重载沿用章节无关的 `_boss_defeated` → `_resume_boss_aftermath` 逻辑：
   Boss 3 已死时续玩直接续接权柄/章末流程，不二次生成 Boss；本程只补断言，
   不新增分支。
5. 测试就近扩展 `tests/integration_playability.gd` 的 `_test_ch3_bigmap_boss`：
   把第 41 程大区世界与第 3 章计划临时挂到真实主场景，走真实流程
   Boss 3 击败 → 权柄二选一 → 第 3 章 outro → 章末选择 → 停章；旧线性世界的
   结构遍历同步改为「停在第 3 章」。同函数锁定 `CHAPTER_PLAN_PATHS[2]/[3]`
   仍空、`MDS_WORLD_FILES[2]` 仍指旧 `chapter_3.mdsworld.json`、计划清房目标/遭遇
   节点/波次表/权柄池与 `boss_scene` 不变。

## 后果

- 第 3 章末不再进入第 4 章；`CHAPTER_PLAN_PATHS[2]` 仍空、计划仍未接入
  `game.gd`、第 3 章仍不可达（旧 9 房线性世界仍被游戏引用）。
- 第 1 章、第 2 章的 Boss / 流程 / 波次 / 事件 / 章末收口无回归；第 4 章无
  内容改动。
- 可玩性集成 732 → **754**（+22）；其余八套集成与单元测试数字不变，全 0 失败。

## 红线

不改 MDS 插件、言灵/权柄/战斗框架、敌人/NPC 美术、存档键与格式；不开放第
2–4 章可达性；不新增移动能力；第 3 章大图验收套件、门视觉、地图标题/敌人美术
核查留后续程；待确认第 11–16 项不施工、不猜测；不做打包/导出/安装器/签名/
安卓/触屏。
