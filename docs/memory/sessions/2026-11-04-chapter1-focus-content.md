# 2026-11-04 · 第一章焦点修复、内容填充与第四章美术核查

> 第 7 程（监工派发）。只在本地 `supervisor-dev` 提交，不 push；未改 NPC 立绘，未做打包/导出/签名；第 2–4 章仍 demo 不可达。

## 起点

- 基线：Godot 4.7.stable；单元 3782 / 0；八套集成 267 / 11 / 35 / 78 / 9 / 20 / 78 / 40；退出泄漏 10/10；`--import`/`--quit` 通过。

## 第四章美术核查（结论）

- 专属插画 `assets/backgrounds/smiling_theater.png`（1536×864）存在；概念源 `assets/concept/environments/smiling_theater_source.png`（1983×793）。
- 已接入 MDS 第四章（`mds_chapter_room.gd` 的 `BACKGROUNDS[3]`）与旧线性场景 `smiling_theater.tscn`。
- `TheaterBackdrop` 以 `generated_art=true` 只叠加聚光灯/地面光斑/浮尘；程序化帷幕/观众席分支保留但默认不执行。
- 第四章 7 种敌人 sprite、Boss `smiling_archivist.png`、`chapter_theater.ogg`、`ch4_intro/outro` 均在；脚本/场景/资源的 `res://` 引用扫描无缺失。
- 第四章没有专属 tileset（`assets/tiles/` 只有 ch1）；第 2–4 章设计上使用绘画背景 + 生成地面，不是缺美术。
- README/GDD 的「程序化绘制、待替换插画」已过时，已更正；后续不再按缺美术规划。

## 焦点修复

- 残页交易所：打开时聚焦首个可购买行；买下后焦点移到下一个可购买行（否则关闭按钮）；全部买不起时聚焦关闭按钮。成交提示改金色，错误仍朱红。
- 档案馆升级：打开时聚焦首个可负担行，否则关闭按钮；`_refresh()` 后焦点若变成 disabled 自动迁移。
- 言灵页：手柄打开时聚焦第一个职能按钮；键盘/鼠标仍聚焦输入框。
- 证据：临时探针 + 真实手柄事件；已转成 `integration_menus` 89 / 0、`integration_gamepad` 80 / 0。

## 内容填充（不改数值/系统）

- 交易所纸人 5 句开场白，按 `run_seed + shop_id` 稳定选取，不消耗 run RNG。
- 5 名 NPC 各 +2 句闲聊（共 5 句/人）。
- 事件房 3 → 5 个文案变体；残碑 4 → 6 条碑文。
- 测试：`test_ch1_content` 179 / 0；`test_hub_final` 124 / 0；`integration_ch1_demo` 14 / 0（真实进 `ch1_rest` 比对台词）。

## 最终验证

- 单元 3874 / 0；结构 269 / 0；输入 14 / 0；run save 35 / 0；手柄 80 / 0；UI 提示 9 / 0；第一章事件 20 / 0；菜单 89 / 0；AI 设置 40 / 0；退出泄漏 10/10；像素资产 36 / 0。
- 未决：暂停菜单设置关闭去向（待用户确认第 7 项），本程未改。

## 经验

- 模态页焦点要避开 disabled Button：Godot 会保留焦点在刚禁用的按钮上，A 被吞掉，看起来像卡死。
- 手柄无法输入 `LineEdit`，手柄入口应聚焦可操作按钮。
- 新增 `class_name` 后先 `--headless --import`；不要并行跑多个 Godot 实例，会争用 `.godot` 缓存。
