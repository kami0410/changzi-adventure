# 第 4 章章末收口

- 日期：2026-11-06（第 58 程）
- 状态：已实施（第 4 章仍不可达，只在测试/探针层进入）

## 背景

第 46 程给第 3 章末做了停章。第 4 章是 `CampaignData` 的最后一章
（`chapter_count() == 4`）：`_complete_chapter` 的旧兜底
`_chapter + 1 < chapter_count()` 对第 4 章为假，本来就会走 `else` 的
`_finish(true)`，行为上已经结束战役，但没有显式分支，代码与测试都没有把
「第 4 章 = 战役终点」写清楚。第 57 程完成后，第 4 章已有计划、真实大区世界、
事件文案、波次接线、权柄池与 Boss 4 机制/`boss_scene` 路由。

## 决定

1. `_complete_chapter` 在既有第 3 章分支之后新增 `_chapter == 3` 分支，调用
   现有 `_finish(true)` 结束战役。第 1/2/3 章分支与
   `_chapter + 1 < chapter_count()` 兜底不改；行为与旧的 `else` 兜底等价。
2. 沿用第 35/46 程口径：章末选择界面、结局记录（`Profile.record_ending` /
   `Flow.end_run`）、续玩行为全部复用，不另起第 4 章专属章末流程；不新增
   「待续」UI、结局 id 或存档键。
3. 未新编剧情文本：`CampaignData.chapter(3)` 已有 4 句 outro、两个选项、
   `ch4_outro` 语音；`_apply_chapter_choice` 已有 `smiling_theater` 分支
   （选项 1 置 `_burned_final`，由 `ending_for` 选焚毁结局）。
4. 续玩/重载沿用章节无关的 `_boss_defeated` → `_resume_boss_aftermath`：
   Boss 4 已死时续玩直接续接权柄/章末流程，不二次生成 Boss；本程只补断言。
5. 测试就近扩展 `tests/integration_playability.gd` 的 `_test_ch4_bigmap_boss`：
   真实大区世界 + 计划临时挂载走完 Boss 4 击败 → 权柄 → 第 4 章 outro →
   章末选择 → 战役结束；同时锁定章末原文/语音/选项与结局规则。旧线性世界的
   结构遍历补「第 4 章 = 战役终点」断言。

## 后果

- 第 4 章末不再走隐式兜底，而是显式结束战役；`CHAPTER_PLAN_PATHS[3]` 仍空、
  计划仍未接入 `game.gd`、第 4 章仍不可达（旧 9 房线性世界仍被游戏引用）。
- 第 1/2/3 章的 Boss / 流程 / 波次 / 事件 / 章末收口无回归；第 4 章计划/世界/
  Boss 4 机制/数值无改动。
- 可玩性集成 869 → **894**（+25）；单元与其余九套集成数字不变，全 0 失败。

## 红线

不改 MDS 插件、言灵/权柄/战斗框架、敌人/NPC 美术、存档键与格式；不开放第
2–4 章可达性；不新增移动能力；不做 Boss 4 机制扩展（删除词/复制武器/舞台
机关）；不做第 4 章大图验收（下一程）；待确认第 11–16 项不施工、不猜测；
不做打包/导出/安装器/签名/安卓/触屏。
