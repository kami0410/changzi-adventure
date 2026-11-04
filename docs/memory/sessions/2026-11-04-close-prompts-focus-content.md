# 2026-11-04 · 第 9 程：关闭提示、焦点边缘与文案填充

> 第 8 程启动失败（`unrecognized_model`，无提交/无状态更新）；本程为事实上的第 8 程接力，编号第 9 程。

## 背景

第 7 程留下候选 A（模态页关闭提示写死 Esc）、B（图鉴/背包焦点）、C（纯文案变体）。
工作区有第 8 程孤儿探针 `tests/probe_close_prompts.gd`，核查后确认正是候选 A 的探针。

## 完成项

1. **基线**：单元 3874 / 0，八套集成 269/14/35/80/9/20/89/40，退出泄漏 10/10 clean，无回归。
2. **候选 A · 关闭提示设备感知**：`GameFlow.close_prompt(keyboard_alts := "Esc")` 返回手柄 B 或键盘快捷键；交易所、档案馆、言灵、图鉴、背包、说明、键位、地图、设置九处接入，并监听 `input_device_changed` 实时刷新。探针 17/17；`integration_ui_prompts` +28 → 37 / 0。
3. **候选 B · 焦点边缘**：Hub 图鉴打开时焦点为 null、A 无反应；运行内图鉴入口焦点落在「返回」，A 直接关页；入口选择不跳过禁用按钮。
   - `GameFlow.first_pressable_button()` 跳过 disabled/不可见；`CodexUI.focus_entry()` 优先第一个词的「选择」；`game._toggle_overlay` 记录/恢复打开前焦点；Hub 教程图鉴同样处理。
   - 探针 21/21；`integration_gamepad` +16 → 96 / 0。
4. **候选 C · 文案**：`Ch1ShopData.BUY_LINES` 5 句成交反馈（seed+摊位+行号稳定，不耗 run RNG）；事件 5 → 7 变体；残碑 6 → 8 条；5 名 NPC 各 5 → 7 句。**未改任何数值、系统、立绘或 AI 提示词**。
   - 单元 3952 / 0；`integration_ch1_demo` +3 → 17 / 0。
5. **额外修复**：运行内记忆商店「按 E」不随设备刷新；词奖励描述写死「按 C」；Hub NPC/传送门/训练碑提示只在 `_ready` 读一次。统一改为 `/root/Flow` 懒解析 + `input_device_changed` 刷新，词奖励改为「可在语言图鉴里组合新短语」。
   - `integration_ui_prompts` 50 / 0；`test_demo_loot` 140 / 0（并修正夹具对 `RefCounted` 调 `free()` 导致 Profile 泄漏）。

## 验证（收尾）

- 单元 **3959 / 0**（退出 0 泄漏）；结构 269 / 0；输入 14 / 0；run save 35 / 0；手柄 96 / 0；UI 提示 50 / 0；第一章 demo 17 / 0；第一章事件 20 / 0；菜单 89 / 0；AI 设置 40 / 0。
- `--headless --import` / `--quit` 退出 0；`tests/check_exit_clean.sh` 10/10 clean。

## 取舍

- 关闭图鉴/背包后若没有可回归的既有焦点控件，焦点为 null 是正确结果（这些场景没有可聚焦 HUD 控件）；只在打开前焦点仍有效且可见时恢复。
- 词奖励描述去掉具体键位而不是在数据层读设备，避免 `RunLoot` 依赖 UI 状态。
- 「事件变体在 run save/resume 后一致」仍未单独补集成，留给下一程（seed 稳定性已由单元测试覆盖）。

## 提交

`1897364` 基线+探针核查 · `01f7ff7` 关闭提示 · `2580fb9` 图鉴入口焦点 · `11d5022` 文案填充 · `e3b7a31` 残留键位文案 · `4e65028` Hub 提示刷新。
