# 第 10 程 · 设备/改键提示与事件续玩一致性

日期：2026-11-04 · 分支 `supervisor-dev` · 基线 HEAD `c76405c`（第 9 程收尾）。

## 基线

单元 3959 / 0；结构集成 269 / 0；run save 35 / 0；手柄 96 / 0；UI 提示 50 / 0；
第一章 demo 17 / 0；第一章事件 20 / 0；菜单 89 / 0；AI 设置 40 / 0；
`--headless --import` 与 `--quit` 退出 0；退出泄漏 10/10 clean；demo 像素资产 36 / 0。

「输入集成 14」是历史标签，仓库内没有独立 `integration_input.gd`；输入覆盖在
`integration_ch1_demo.gd`，第 9 程已由 14 增至 17。

## 本程修复

1. **设备切换后的一次性提示**（MDS 房门、首次 Hub 教程、暂停页脚、结束屏、
   剧情/事件页、图鉴装备按钮、图鉴 AI 未配置提示、对话页）改为监听
   `Flow.input_device_changed` 重建文案；`GameFlow.key_label` 对内置 UI 动作
   （`ui_accept` 只有 keycode）回退读 keycode，确认键显示 Enter 而不是空串。
2. **AI 设置页手柄入口焦点**：手柄打开落到「启用 AI 解读」开关（A 可切换），
   键盘仍落到接口地址输入框。
3. **地图叠在模态页上**：地图自己拥有暂停而不在 `_overlay` 栈；图鉴打开时按 M
   会把地图叠上去，关闭地图后世界在恢复运行而图鉴仍可见。现在 `_overlay`
   非空时 M 不打开地图；普通游戏中的 M 开/关地图不变。
4. **事件房变体续玩**：固定非零 seed 进入 `ch1_05`，保存后重启续玩，断言
   回到同一房间并重开同一 eyebrow/title/选项文案；`RunSave` 的 seed/rng_state
   往返被真实覆盖。
5. **改键后的缓存键位**：`GameFlow` 新增 `keybinds_changed`，HUD 控制条改为
   逐项 `prompt_label()` 生成；拾取物、残碑、记忆商店、Hub NPC/传送门/训练碑、
   MDS 房门、暂停页脚、教程、图鉴装备按钮、结束屏都监听并刷新。

## 验证

- 单元 3959 / 0。
- 集成：结构 269、第一章 demo 17、run save 35、手柄 96、UI 提示 **90**、
  第一章事件 **31**、菜单 **99**、AI 设置 **45**，全部 0 失败。
- 退出泄漏 10/10 clean；导入/退出码 0；像素资产 36 / 0。
- 临时探针 `probe_stale_prompts` / `probe_dialogue_device` / `probe_keybind_prompts`
  均在转成断言后删除。

## 交接

下一程候选见 `SUPERVISOR_STATUS.md`「下一程从这里继续」。待用户确认第 7 项
（暂停菜单打开设置后关闭的去向）保持现状，未改。
