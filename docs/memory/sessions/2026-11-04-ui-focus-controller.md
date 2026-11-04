# 2026-11-04 菜单焦点 / 设置子页 / 手柄 UI 键（第 5 程）

## 完成

- **基线**：单元 3664 / 0；结构 267 / 0；输入 11 / 0；run save 35 / 0；手柄 39 / 0；
  UI 提示 9 / 0；第一章事件 14 / 0；`--headless --import` 通过；
  `tests/check_exit_clean.sh` 10/10 clean。
- **权柄面板与暂停键**：`AuthorityChoiceUI` 新增 `is_open()`；`game.gd::_input` 在必选面板
  打开时吞掉 `pause`/`ui_cancel`，`_toggle_pause()` 防御性返回。此前按 P/Start 会把
  SceneTree 从暂停翻回运行，面板仍留在屏幕上，再按一次会把暂停菜单叠上来。
- **设置关闭后的焦点**：`SettingsMenu` 在 `open()` 记录焦点控件，`close()` 后若仍有效且可见
  则恢复。修复标题设置关闭后焦点为 `null`、手柄/键盘无法继续导航。
- **设置子页栈**：AI 设置 / 键位 / 操作说明作为 `SettingsMenu._subpages` 管理；
  `close_subpage()` 先关最上层，`close()` 关闭全部；子页关闭后焦点回到打开它的按钮。
  `game.gd` 的 `pause`/`ui_cancel` 先尝试关子页；`_close_overlay` 绑定发送者，子页关闭
  不再误关仍在上层的设置页。此前 Esc/B 会把设置关掉、AI/Help 页留在最上层且游戏恢复。
- **手柄 A/B 面键（关键发现）**：Godot 4.7 内置 `ui_accept`/`ui_cancel` 只有键盘和
  十字键/摇杆，没有 A/B 面键；真实手柄 B 按下时 `ui_cancel=false`。`GameFlow.ensure_actions()`
  幂等补上 `ui_accept ← A`、`ui_cancel ← B`，不随玩法键重绑移除。此前所有「B 返回 / A 确认」
  在手柄上都不成立。`integration_gamepad` 用真实 A 按下驱动设置页按钮做端到端验证。
- **键位页焦点**：`_refresh()` 重建全部行按钮会清空焦点；新增 `_focus_action()`，在打开、
  开始捕获、改键成功、Back/Esc 取消后按动作重新抓取新按钮焦点。
- **Hub 新游戏 Profile 重绑**：`TitleScreen` 先 `reset_profile()` 再发 `new_game_requested`；
  Hub `_on_new_game_requested()` 走 `set_profile()`，重建 `_words` 词副本、重绑商店页，
  并 `_rebind_tutorial_run()` 用新 Profile 重建教程 RunState/codex。此前 Hub 绑定的是
  即将被释放的旧 Profile，教程 run 还会被置空。

## 验证

- 单元 `tests/run_tests.gd`：**3670 passed / 0 failed**。
- 结构集成 267 / 0；输入集成 11 / 0；run save 集成 35 / 0；手柄集成 **78 / 0**；
  UI 提示 9 / 0；第一章事件 14 / 0。
- `--headless --import` 通过；`tests/check_exit_clean.sh` 10/10 clean。

## 边界

- 未改玩法框架、NPC 立绘、AI 默认行为（默认关闭、失败静默回退）。
- 未做任何打包/导出/安装器/签名工作。
- 已知未做：暂停菜单打开设置后关闭的去向（当前直接恢复游戏）已记入状态文件待用户确认。
