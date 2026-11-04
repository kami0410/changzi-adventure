# 2026-11-04 · 菜单 A/B、设置测试与第一章文案

> 第 6 程（监工派发）。只在本地 `supervisor-dev` 提交，不 push；未改 NPC 立绘，未做打包/导出/签名/实机验证。

## 起点

- 基线全绿：单元 3670 / 0；六套集成 267 / 11 / 35 / 78 / 9 / 14；退出泄漏 10/10。
- 本程按候选优先级补齐菜单回归、设置测试、音量持久化、日志噪音与内容文案。

## 菜单与焦点

- `StoryOverlay` 普通剧情页接受 `ui_cancel`/`pause` 关闭；选择页仍必须选择，B 不跳过。
- `DialogueUI` 打开时聚焦「继续」按钮，记录打开前焦点，关闭/取消后恢复。
- `ShopUI` 打开聚焦首个条目；购买重建列表后按 item id 保留焦点；关闭恢复原焦点。
- 新增场景内 `ConfirmPanel`（`scripts/ui/confirm_panel.gd`）：标题「新游戏」确认改用它，替代无头下收不到合成输入的 native `ConfirmationDialog`；支持 A 确认、B 取消、关闭后焦点回到「新游戏」。
- 验证：`tests/integration_menus.gd` 78 / 0，真实手柄事件覆盖地图、剧情、运行内商店、奖励、权柄、结束屏、Hub 对话/商店/档案馆、Hub 设置子页、标题确认。

## 设置与存档

- Hub 设置子页（AI/键位/操作说明）补 20 项实景断言：打开/关闭/焦点回归/捕获释放。
- AI 设置新增 `tests/integration_ai_settings.gd` 40 / 0；`AIService.config_path` 可注入临时路径，测试绝不读写真实 `ai_config.cfg`，不访问网络。
- 主音量写入 `Profile.master_volume`（默认 1.0、读档钳制、`[settings]` 持久化）；`GameFlow._ready()` 启动应用，`reset_profile()` 保留；`SettingsMenu` 拖动即写 Profile，`auto_save=false` 时不写盘。

## 测试日志噪音

- 全量单元改为仍同步运行，但给离树调用加防御：`AudioManager.play_sfx/play_music` 不在树内不 `play()`；权柄/奖励 UI 与暂停菜单确认框在树外跳过 `grab_focus`/`popup_centered`。
- 结果连续多次 0 失败、0 条引擎 `ERROR`；未改产品在正常树内的行为。

## 第一章文案填充

- 新增 `scripts/data/ch1_event_data.gd`：事件房 3 个文案变体；按 `run_seed + room_id` 用 `posmod(hash(...))` 稳定选取，**不消耗 run RNG**，续玩/掉落序列不变。机制常量统一为污染 8 / 拿残页 12 / 无词兜底 6。
- `MemoryStele.EPITAPHS` 4 条碑文，按 `stele_id` 稳定选取；奖励 roll 不变。
- 测试：`tests/test_ch1_content.gd` 102 项；`integration_ch1_event` 增至 20 / 0，断言展示文案与 seed 变体一致。

## 最终验证

- 单元 **3782 / 0**；结构 267 / 0；输入 11 / 0；run save 35 / 0；手柄 78 / 0；UI 提示 9 / 0；第一章事件 20 / 0；菜单 78 / 0；AI 设置 40 / 0；`--headless --import` 通过；退出泄漏 10/10。
- 已知未决：暂停菜单打开设置后关闭仍是「恢复游戏」而不是回暂停菜单，等用户拍板，本程未改。

## 经验

- 无头模式下 native `Window`/`ConfirmationDialog` 不接收 `Input.parse_input_event` 的 A/B，UI 测试优先用场景内 Control。
- `OptionButton` 模拟选择要先 `select(n)` 再 `item_selected.emit(n)`。
- GDScript lambda 按值捕获局部变量；计数用 `Array[int]` 等可变容器。
- 新增 `class_name` 脚本后先跑 `--headless --import` 再跑测试。
