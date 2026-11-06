# 2026-11-05 第 54 程：第 4 章内容数据层第 2 步——波次接线

## 目标

沿用第 33 程（第 2 章）、第 43 程（第 3 章）已验证的做法，把第 4 章计划的
6 场战斗遭遇接到既有六波敌人上，并按第 40/43 程的约定把 `content_pending`
清零。只做数据层与测试层：不接入 `game.gd`、不开放可达性、不产生可玩行为变化。

## 改动

- `resources/chapters/chapter_4_demo.tres`：
  - 4 个战斗区（`ch4_branch_a`、`ch4_branch_b`、`ch4_well`、`ch4_elite`）补
    `wave` 字典，共 6 个键（遭遇节点 id），值与 `ROOM_WAVES[3]` 六波按计划
    顺序逐字一致，未新增/修改波次内容。
  - `content_pending = true → false`：波次已落地，`validate()` 恢复校验波次表。
  - 事件区（`ch4_event`）、Boss 区（`ch4_boss`）、入口/枢纽/书库不带 `wave`。
- 测试（就近扩展既有套件，未另起重复套件）：
  - `tests/test_ch4_content.gd`：波次段从「未接线」改为接线校验——6 个键
    恰好等于 6 个战斗遭遇节点 id、每个键的值 == `ROOM_WAVES[3]` 对应波原文、
    键锚定本区且唯一、事件节点/事件区/Boss 区无波、`validate_waves()` 与
    `validate()` 干净、`content_pending` 已清零。新增 `_test_runtime_wave_lookup`：
    把第 4 章计划挂到独立 `game.gd` 实例上，经 `_plan_wave()` 按节点 id 读回
    六波（证明第 33 程的通用大图分支可直接取用），但不改章节路由。
  - `tests/test_ch4_plan.gd`：`_test_pending_content` → `_test_wave_wiring`，
    锁定 6 个波次键、逐遭遇非空、事件/Boss 无波、计划校验干净；`content_pending`
    的局部性改为「新副本删掉波次 + 标志开 → `validate()` 干净；标志关 → 报六条
    缺波次」，保留第 40 程的关口。
  - `tests/test_ch4_world.gd`：计划侧期望同步为 `content_pending = false`、
    共 6 个波次键、`validate_waves()` 干净；世界/场景本身未改。
- 产品代码未改：`game.gd`、`ChapterPlanData`、第 4 章世界 JSON/场景、Boss 4
  数值与文案均为原样。

## 波次对应（计划顺序）

| # | 遭遇节点 | 波次（`ROOM_WAVES[3]` 原文） |
|---|---|---|
| 0 | `ch4_branch_a/Arena` | `mask_enemy`, `seat_husk` |
| 1 | `ch4_branch_a/Arena2` | `choir_summoner`, `page_swarm` |
| 2 | `ch4_branch_b/Arena` | `seat_husk`, `mirror_sniper` |
| 3 | `ch4_well/Arena` | `mask_enemy`, `typo_beast` |
| 4 | `ch4_well/Arena2` | `ink_bomber`, `mask_enemy` |
| 5 | `ch4_elite/Arena` | `mirror_sniper`, `page_swarm` |

事件节点 `ch4_event/event` 无波；Boss 区 `ch4_boss` 不占普通波次；清房目标仍为 7。

## 口径与处置

- **`content_pending` 的处置**：该标志在第 40 程只承载「推迟波次表校验」这一项，
  波次接线完成后按 ADR 的约定改回 `false`，让第 4 章波次表进入正常校验。
  标志本身保留在 `ChapterPlanData`（默认 `false`，向后兼容）。图骨架夹具
  `tests/fixtures/big_room/ch4_graph.mdsworld.json` 顶层的 `content_pending: true`
  是夹具元数据（不是 `ChapterPlanData` 的字段），本程未改，测试仍锁定其为 true。
- 波次键 = 遭遇节点 id（`region/Node`），与第 33/43 程口径一致；第 1 章仍使用
  房间级数组，第 2/3 章计划与波次一字未改。
- **战斗密度**：本程不扩波、不增遭遇、不改任何波次内容；旧世界每房 5–6 只 vs
  大图每遭遇 2 只的差异只记录在状态文件，留给内容程/拍板。
- **`mask_enemy` / `seat_husk`**：本程不做独立数值与行为；两者仍是第 1 章敌人的
  美术变体（共享场景/数据），计划与世界不写独立数值。
- **Boss 4**：本程不设计机制、不写 `boss_scene`；Boss 区只做数据层（本程未改）。
- **`ch4_shortcut`**：未新增任何授予来源，捷径屏障保持默认封闭。
- **舞台母题 / 阿砚同行**：本程未改呈现层、未实现同行。
- 第 4 章计划仍未接入 `game.gd`（`CHAPTER_PLAN_PATHS[3]` 仍空）、事件区仍无真实
  触发点、Boss 4 仍无 `boss_scene`/机制；第 4 章仍不可达。

## 验证（本机 Godot 4.7.stable.official.5b4e0cb0f）

- 基线（改动前，HEAD `c6178b3`）：单元 **12545 / 0**；十套集成
  **755 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209 / 4235** 全 0 失败；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**；`--import` / `--quit`
  退出 0、`ERROR` 0。
- 改动后：单元 **12573 / 0**（+28：`test_ch4_content` 641（+28）、
  `test_ch4_plan` 795（−1）、`test_ch4_world` 813（+1））；十套集成数字与
  基线完全一致、全 0 失败；`--import` / `--quit` 退出 0、`ERROR` 0；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。

## 未做（按任务单）

第 4 章接入 `game.gd` / 可达性 / 章节路由 / 章末流程；事件区真实自动触发验证；
Boss 4 机制 / `boss_scene`；第 4 章大图验收；`ch4_shortcut` 授予来源；战斗密度；
`mask_enemy`/`seat_husk` 独立数值；舞台母题呈现层；阿砚同行；新移动能力；
NPC 立绘；MDS 插件本体；敌人/场景美术；打包/导出/安装器/签名/安卓/触屏。
待确认第 11–16 项未施工、未猜测；第 50 程专节 E 的开放问题候选仍只记录、未编号。
