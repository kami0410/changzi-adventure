# 2026-11-05 第 38 程：第 2 章地图标题与敌人美术核查

## 背景

第 37 程留下两个已明确的内容/表现缺口：① 游戏内地图标题固定为「档案馆地图」，第 2 章大图沿用该标题；② 第 2 章五种敌人是否有专属美术、能否接入 `ENEMY_ART` 尚未核查。本程只做这两项：地图标题按章节数据派生，敌人美术只核查与接线、不新绘不拼凑；不开放第 2 章可达性，不改第 1 章内容，不碰待确认第 11/12/13 项。

## 任务 1 · 第 2 章地图标题

### 做法

- `scripts/ui/map_overlay.gd`：标题从 `_build()` 里的字面量改为成员 `_title`；新增 `DEFAULT_TITLE = "档案馆地图"`、`map_title(chapter_index)`、`set_chapter(chapter_index)` 与 `title_text()`。
- 派生规则：第 1 章（`chapter_index <= 0`）一字不改，返回 `DEFAULT_TITLE`；第 2–4 章读取既有 `CampaignData.chapter(i)["region"]`，返回「<区域名>地图」，第 2 章即「呼吸废墟地图」。区域为空或索引无效时回落到 `DEFAULT_TITLE`，不新造章节名。
- `set_chapter()` 先把章节记在 `_chapter_index`，`_build()` 用 `map_title(_chapter_index)` 初始化标签，因此即使 `_ready()` 之前调用也不会丢标题；`title_text()` 在未构建时也返回当前章节的标题。
- `scripts/game.gd` 的 `_start_mds_chapter()` 在 `set_world(...)` 前调用 `_map_overlay.set_chapter(chapter_index)`。因此第 1/2/3/4 章启动（含续玩）都会同步标题；返回 Hub 后再开新局也会重新设置，不会残留上一章标题。

### 验收

- 新增 `tests/test_map_overlay.gd`（16 断言）：第 1 章标题严格等于「档案馆地图」；第 2 章等于「呼吸废墟地图」且与第 1 章不同；标题来源等于 `CampaignData.chapter(1)["region"] + "地图"`；第 3/4 章按同一规则得到「无光海地图」「笑面剧场地图」；索引 -1 回落；`set_chapter()` 在 `_build()` 前/后都能生效；第 1↔2↔3 章来回切换不残留。
- `tests/integration_playability.gd`：第 1 章真实启动后断言标题仍为「档案馆地图」；第 2 章大图分支断言「呼吸废墟地图」且不是第 1 章标题；第 3/4 章结构流程各断言按区域派生的标题。第 1 章标题在真实 `_ready()` 路径上也被覆盖。
- 第 2 章仍不可达：标题只在测试显式启动第 2 章时驱动验证。

## 任务 2 · 第 2 章敌人专属美术核查与接线

### 核查结果（仓库事实）

| 敌人 | 专属精灵 | 现状 | 结论 |
|---|---|---|---|
| `choir_summoner` | `assets/sprites/enemies/choir_summoner.png`（96×96 RGBA，已在 `ENEMY_ART`） | 不在 `ENEMY_ART_FALLBACK`，实际以白 tint 渲染 | **已接线**，无需改动；用测试锁定 |
| `breath_hound` | 无 | 回退 `ink_hound`，tint `#c8e1cd` | 缺专属美术，跳过 |
| `lung_moth` | 无 | 回退 `hanging_scribe`，tint `#c8e1cd` | 缺专属美术，跳过 |
| `rust_whisperer` | 无 | 回退 `scribe_bug`，tint `#c8e1cd` | 缺专属美术，跳过 |
| `collapse_husk` | 无 | 回退 `blank_man`，tint `#c8e1cd` | 缺专属美术，跳过 |

- 四个缺失敌人只有场景内的程序化 `Polygon2D` 占位（`Body`/`Eye`/`Hood`/`Wings`/`Cracks`），不是可接入 `ENEMY_ART` 的专属贴图；`assets/concept/enemies/` 也没有它们的原图（只有 `choir_summoner`、`ink_bomber`、`mirror_sniper`、`page_swarm`）。按任务单不新绘、不拼凑、不猜测，四个继续走第 1 章精灵染绿回退。
- 本程没有新增/修改任何敌人贴图或场景美术。

### 仅做的接线与锁定

- `scripts/game.gd` 把回退 tint 提为常量 `ENEMY_FALLBACK_TINT = Color("c8e1cd")`，`_spawn_group()` 改用它；行为不变，只是让测试可以锁定「专属美术 = 白色、回退 = 绿色」的规则。
- 新增 `tests/test_enemy_art.gd`（94 断言）：五种第 2 章敌人都有场景/数据且只有唯一美术来源；`choir_summoner` 的 `ENEMY_ART` 指向自己的 PNG、不在回退表、tint 为白色；四个缺失敌人仍在回退表、回退源是第 1 章美术、tint 为 `ENEMY_FALLBACK_TINT`，且标准路径 `assets/sprites/enemies/<id>.png` 尚不存在（若日后补图而未接线，测试会失败）；第 1 章 8 种敌人各自保留自己的 PNG 且不在回退表。
- `tests/integration_ch2_bigmap.gd` 在真实第 2 章遭遇中锁定实际生成结果：`ch2_branch_a/Arena` 的 `choir_summoner` 使用 `choir_summoner.png` 且 `modulate == Color.WHITE`；`Arena2` 的 `rust_whisperer` 仍使用 `scribe_bug.png` 且 tint 为 `#c8e1cd`（记录缺口，不是新增美术）。

## 测试与验证

- 基线（HEAD `c0a5e53`）：单元 **7901 / 0**；九套集成 **665 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2202** 全 0 失败；退出泄漏 **10/10 clean**；像素资产 **36 / 0**；`--headless --import` / `--quit` 退出 0、`ERROR` 0。与交接一致，无漂移。
- 改动后：单元 **8011 / 0**（+110：地图标题 16 + 敌人美术 94）；九套集成 **671 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209** 全 0 失败（可玩性 +6、第 2 章大地图 +7）；退出泄漏 **10/10 clean**；像素资产 **36 / 0**；`--import`/`--quit` 退出 0、`ERROR` 0。
- 第 1 章 9 个 `MDSChapterRoom`、6 波次、事件房、清房目标 6、Boss 与结束流程未改；第 1 章敌人美术表与波次未改；第 2 章仍不可达。

## 未做

第 2 章可达性（待确认第 11 项未定）；第 11/12/13 项本身；四个缺失敌人的专属美术（无现成素材，按任务单不新绘）；阿砚同行；新增移动能力；NPC 立绘；MDS 插件（本程零改动）；打包/导出/安装器/签名/安卓/触屏。临时探针已删除，工作区干净。
