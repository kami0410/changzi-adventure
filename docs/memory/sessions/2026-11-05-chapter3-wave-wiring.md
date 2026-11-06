# 2026-11-05 第 43 程：第 3 章内容数据层第 2 步——波次接线

## 目标

沿用第 33 程对第 2 章的做法，把第 3 章计划的 6 场战斗遭遇接到既有六波敌人上，
并把 `content_pending` 按第 40 程的约定收口。只做数据层与测试层：不接入
`game.gd`、不开放可达性、不产生可玩行为变化。

## 改动

- `resources/chapters/chapter_3_demo.tres`：
  - 4 个战斗区（`ch3_branch_a`、`ch3_branch_b`、`ch3_well`、`ch3_elite`）补
    `wave` 字典，共 6 个键（遭遇节点 id），值与 `ROOM_WAVES[2]` 六波按计划
    顺序逐字一致，未新增/修改波次内容。
  - `content_pending = true → false`：波次已落地，`validate()` 恢复校验波次表。
  - 事件区（`ch3_event`）、Boss 区（`ch3_boss`）、入口/枢纽/书库不带 `wave`。
- `scripts/data/chapter_plan_data.gd`：只更新 `content_pending` 的文档注释
  （不再以第 3 章「波次待补」为例；行为未改，默认仍 `false`）。
- 测试（就近扩展既有套件，未另起重复套件）：
  - `tests/test_ch3_content.gd`：波次段从「未接线」改为接线校验——6 个键
    恰好等于 6 个战斗遭遇节点 id、每个键的值 == `ROOM_WAVES[2]` 对应波原文、
    键锚定本区且唯一、事件节点/事件区/Boss 区无波、`validate_waves()` 干净、
    `content_pending` 已清零。新增 `_test_runtime_wave_lookup`：把第 3 章计划
    挂到独立 `game.gd` 实例上，经 `_plan_wave()` 按节点 id 读回六波（证明第 33
    程的通用大图分支可直接取用），但不改章节路由。
  - `tests/test_ch3_plan.gd`：`_test_pending_content` → `_test_wave_wiring`，
    锁定 6 个波次键、逐遭遇非空、事件/Boss 无波、计划校验干净；`content_pending`
    的局部性改为「新副本删掉波次 + 标志开 → `validate()` 干净；标志关 → 报六条
    缺波次」，保留第 40 程的关口。
  - `tests/test_ch3_world.gd`：计划侧期望同步为 `content_pending = false`、
    波次表校验干净、共 6 个波次键；世界/场景本身未改。

## 波次对应（计划顺序）

| # | 遭遇节点 | 波次（`ROOM_WAVES[2]` 原文） |
|---|---|---|
| 0 | `ch3_branch_a/Arena` | `mirror_sniper`, `hanging_scribe` |
| 1 | `ch3_branch_a/Arena2` | `rust_whisperer`, `lung_moth` |
| 2 | `ch3_branch_b/Arena` | `echo_enemy`, `collapse_husk` |
| 3 | `ch3_well/Arena` | `mirror_sniper`, `typo_beast` |
| 4 | `ch3_well/Arena2` | `hanging_scribe`, `page_swarm` |
| 5 | `ch3_elite/Arena` | `echo_enemy`, `mirror_sniper` |

事件节点 `ch3_event/event` 无波；Boss 区 `ch3_boss` 不占普通波次；清房目标仍为 7。

## 口径与处置

- **`content_pending` 的处置**：该标志在第 40 程只承载「推迟波次表校验」这一项，
  波次接线完成后按 ADR 的约定改回 `false`，让第 3 章波次表进入正常校验。
  标志本身保留在 `ChapterPlanData`（默认 `false`，向后兼容），供后续仍先立结构、
  后补波次的计划使用。图骨架夹具 `tests/fixtures/big_room/ch3_graph.mdsworld.json`
  顶层的 `content_pending: true` 是夹具元数据（不是 `ChapterPlanData` 的字段），
  本程未改，测试仍锁定其为 true。
- 波次键 = 遭遇节点 id（`region/Node`），与第 33 程第 2 章口径一致；第 1 章仍
  使用房间级数组，第 2 章计划与波次一字未改。
- 第 3 章计划仍未接入 `game.gd`（`CHAPTER_PLAN_PATHS[2]` 仍空）、事件区仍无真实
  触发点、Boss 3 仍无 `boss_scene`/机制；章末自动进第 4 章的行为未改。

## 验证（本机 Godot 4.7.stable.official.5b4e0cb0f）

- 基线（改动前，HEAD `4bdeb28`）：单元 **10084 / 0**；九套集成
  **671 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209** 全 0 失败；退出泄漏
  **10/10 clean**；demo 像素资产 **36 / 0**；`--import` / `--quit` 退出 0、`ERROR` 0。
- 改动后：单元 **10100 / 0**（+16：`test_ch3_content` 波次段与运行时读取 +31、
  `test_ch3_plan` −8、`test_ch3_world` −7，见状态文件第 43 程日志）；九套集成
  数字与基线完全一致、全 0 失败；`--import` / `--quit` 退出 0、`ERROR` 0；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。

## 未做（按任务单）

第 3 章接入 `game.gd` / 可达性 / 章节路由 / 章末流程；事件区真实自动触发；
Boss 3 机制 / `boss_scene` / 专属场景；第 3 章大图验收套件；第 3 章门视觉专项；
阿砚同行；新移动能力；NPC 立绘；MDS 插件本体；敌人/场景美术；打包/导出/安装器/
签名/安卓/触屏。待确认第 11/12/13/14/15/16 项未施工、未猜测。
