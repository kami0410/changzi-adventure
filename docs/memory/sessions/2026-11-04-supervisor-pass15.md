# 第 15 程 · 暂停设置回退、关闭路径与长局稳定性

日期：2026-11-04 · 分支：`supervisor-dev`（本地）

## 结果

- 全量单元 **4198 / 0**；八套集成 **269 / 22 / 176 / 128 / 113 / 34 / 128 / 45**（结构 / 第一章 demo / run save / 手柄 / UI 提示 / 第一章事件 / 菜单 A/B / AI 设置），全部 0 失败。
- `--headless --import`、`--headless --quit` 退出 0；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。
- 工作区干净，无遗留探针/基准脚本。

## 任务 0–1 · 残局与基线

- 第 14 程遗留的 `tests/probe_pause_settings_14.gd` 仍可运行：手柄路径复现「暂停 → 设置 → B 关闭 → `paused=false`、暂停菜单不可见、焦点 null」；键盘路径因其只设 `physical_keycode`（内置 `ui_accept`/`ui_cancel` 按 `keycode` 匹配）在打开设置一步失败，属探针缺陷，修正后 19 项断言 6 项按预期失败。
- 基线单元 4122 / 0、八套集成 269 / 19 / 146 / 112 / 113 / 34 / 110 / 45、退出 10/10，与第 14 程完全一致。

## 任务 2 · 暂停菜单设置回退（监工拍板）

- 口径来源：`.supervisor/DECISIONS.md`（2026-11-04）——关闭设置返回暂停菜单并恢复打开前的焦点，不直接恢复游戏。
- 实现：`game.gd` 在暂停菜单打开设置时记录来源页与焦点控件；`_close_overlay()` 关闭该页时保持暂停、`pause_menu.open_pause()` 重新显示暂停菜单并恢复焦点（原控件失效则保留 Resume 兜底）。设置被其他覆盖页替换时清空来源标记，避免陈旧状态。
- 未改：设置内容、保存逻辑、暂停恢复逻辑、布局、数值；设置子页仍逐层关闭；标题/Hub/游戏内快捷键打开设置的既有行为不变。
- 验证：手柄 Start → 设置 → B 回暂停（焦点在 SettingsButton）→ B 恢复游戏；键盘 P → Enter → Esc；键盘/手柄混合往返。`integration_gamepad` 112 → **128 / 0**；`integration_run_save` 的暂停循环按新口径改写，146 → **152 / 0**。

## 任务 3 · 关闭回退类残留

三个真实事件复现的缺陷：

1. **AI 子页关闭不恢复焦点**：`SettingsMenu.close_subpage()` 只认 `close()`，而 `AISettingsUI` 用 `close_page()`，走了 `visible=false` 分支、不 emit `closed`；焦点不恢复，一次性连接残留，重开时报引擎 ERROR。修复：识别 `close_page()`。
2. **设置键滞留子页**：子页打开时按 F10 会整页关闭设置并恢复游戏，子页留在屏幕上。修复：设置快捷键先 `close_subpage()`，与 B/Esc、Hub 口径一致。
3. **换覆盖页残留子页**：AI 子页打开时按 C 打开图鉴，两个模态页叠加。修复：`_toggle_overlay` 替换设置页、`_close_overlay` 关闭设置页时调用 `SettingsMenu.close_subpages()`。

验证：`integration_menus` 110 → **128 / 0**；探针删除。

## 任务 4 · 长局与边界

- 新口径下长局（ch1_rest、生命/墨量/残页/污染/词/遗物/武器/短语/已清房间）连走 3 轮暂停—设置—回暂停—恢复后保存、退出、**主存档正常续玩**，逐项断言一致。
- 新增边界：暂停菜单打开时退出（暂停动作写档），重启后续玩仍回原房间、数值一致、`paused=false`、暂停菜单不恢复。
- `integration_run_save` 152 → **176 / 0**。未改存档格式、v1 安全默认、坏档口径。

## 任务 5 · 性能

- 测「暂停 → 设置 → 回暂停 → 恢复游戏」往返（40 轮，`auto_save=false`，只计同步调用）：pause_open 0.435 ms、settings_open 0.722 ms、settings_close_to_pause 0.252 ms、resume 0.401 ms；最差 2.303 ms，低于 120 FPS 一帧（8.33 ms）。
- 首版把 `await process_frame` 计入，四步都读到约 8 ms（即一帧等待），已修正。无优化必要，未改代码。

## 任务 6 · 内容

- 类别：污染分档警告（4 档各 1 句 → 各 4 句，共 16 句）。分档 1–3 的机制文本（敌人伤害/墨耗/冷却百分比）逐字保留；分档 4 为失控文案。
- 新增 `CorruptionWarningData`：按 `hash(run_seed:tier)` 稳定选取，不消耗 `run.rng`；`RunState.corruption_tier_warning()` 改为调用它。
- 测试：`test_corruption_warnings` 76 项；`integration_ch1_demo` 19 → **22 / 0**（真实 HUD 显示与 seed 选中句一致）。全量单元 4122 → **4198 / 0**。

## 提交

`2e1e860` 基线/探针核实 · `d121e70` 暂停设置回退 · `20bd97c` 关闭回退残留 · `93ac375` 长局续玩边界 · `03a7581` 性能记录 · `c13424c` 污染警告文案
