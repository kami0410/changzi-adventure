# 第 12 程 · 提示缓存、焦点、边界存档、续玩启动与休整卡文案

日期：2026-11-04 · 分支 `supervisor-dev` · 基线 HEAD `9e38398`（第 11 程收尾）。

## 基线

单元 3969 / 0；结构集成 269 / 0；第一章 demo 17 / 0；run save 73 / 0；手柄 100 / 0；
UI 提示 104 / 0；第一章事件 31 / 0；菜单 110 / 0；AI 设置 45 / 0；
`--headless --import` 与 `--quit` 退出 0；退出泄漏 10/10 clean；像素资产 36 / 0。

## 修复与断言

1. **提示/文案缓存**（临时探针 8 项 / 5 失败复现两类）：
   - Hub 左上目标提示永远写死「A/D 移动 · E 交互」→ 缓存 Hint 标签，监听
     `input_device_changed` / `keybinds_changed`，按当前设备生成键位。UI 提示集成
     104 → 108。
   - 图鉴「AI 未配置」状态把 `settings` 键写死进文案 → `_ai_config_hint` 标记该状态，
     统一走 `_set_ai_status()`，设备/改键时重建提示。UI 提示 108 → 111。
   探针先 8/2 后 8/0，转成 7 项集成断言后删除。

2. **焦点边缘**（只补断言，未复现产品缺陷）：图鉴选词重建后焦点仍在同一词的
   「取消选择」；言灵页提交按钮 `set_busy(true/false)` 后焦点仍在可见控件；真实 B
   关闭言灵页后无隐藏焦点残留。手柄集成 100 → 109。

3. **长局与边界存档**（只扩展集成，不改存档格式/口径）：长局中 3 轮「暂停 → 设置 →
   关闭」不扰动生命 66、残页 58、房间 `ch1_rest`；`ch1_boss` 存活存档重新生成 Boss；
   `boss_defeated=true` 存档续接权柄/章末/结局且不生成第二个 Boss；主文件与 `.bak`
   同时损坏、未来版本号均按坏档丢弃并提示。run save 73 → 115。

4. **续玩启动性能**（临时基准 `tests/bench_resume_boot.gd`，测完删除）：
   - 方法：构造长局 `ch1_rest` 存档，连续 6 次以 `resume_requested=true` 真实启动
     `main.tscn`，计时 instantiate / add_child / MDS 世界 / 房间就绪；另测 Hub、biome、
     去掉 `game.gd` 的 main 与各 UI 子场景单独 add 作对照。
   - 基线：cold 2069.1 ms，warm median 1996.6 / avg 2005.5 / min 1960.7 /
     max 2045.6；instantiate 约 202–210 ms，add_child 约 1.84–1.91 s，房间就绪 +110 ms。
     分阶段定位到图鉴在 `_ready` + `bind` + `set_discovered` + `set_persistent_discovered`
     对隐藏页面完整重建 3–4 次，启动期合计约 0.8–1.2 s。
   - 修复：`CodexUI._ready()` 仅在可见时刷新；新增 `bind_state()`，先挂 run、本局组合与
     Profile 组合，再统一刷新一次；`game.gd` 改走 `bind_state()`。只改刷新时机与次数。
   - 结果：cold 1524.1 ms，warm median 1466.7 / avg 1478.1 / min 1442.8 / max 1551.0；
     warm median 降低 529.9 ms（约 26.5%）。剩余一次图鉴重建未再压缩，避免把开销
     挪到首次打开。

5. **休整卡文案轮换**：新增 `RestOfferData`，8 组标题/短句；`RunLoot.choices` 按
   `run_seed + room_number` 用 `hash` 选取，不消费 run RNG。效果行仍为「恢复 35 生命与
   45 墨量。污染降低 12。」；每间房仍只有一张休整卡。内容测试 +80 项
   （变体/唯一性/数字/占位符/稳定性/轮换/不推进 RNG/接入一致）。

## 验证（HEAD `c1fe6b7`）

- 单元 **4049 / 0**。
- 集成：结构 269、第一章 demo 17、run save **115**、手柄 **109**、UI 提示 **111**、
  第一章事件 31、菜单 110、AI 设置 45，全部 0 失败。
- 导入/退出码 0；退出泄漏 10/10 clean；像素资产 36 / 0；import/quit 日志 ERROR 计数 0。
- 临时 `probe_prompt_cache_12` / `probe_focus_edges_12` / `probe_boundary_save_12` /
  `bench_resume_boot` 均已删除；无残留探针、`.godot/`、`build/`、keystore 或截图产物。

## 提交

`9e38398` 基线 → `7d1e8e0` Hub 目标提示 → `765bc47` 图鉴 AI 提示 →
`318f20c` 手柄焦点断言 → `7df10cb` 长局/边界存档 → `46a108d` 续玩启动优化 →
`c1fe6b7` 休整卡文案 → 本状态/记忆收尾文档提交。

## 交接

下一程候选见 `SUPERVISOR_STATUS.md`「下一程从这里继续」。续玩启动优化后剩余大头是
隐藏 UI 首次构建与场景 `add_child`；继续优化需先复测同一基准，避免把开销挪到首次
打开页面。待用户确认第 7 项（暂停菜单打开设置后关闭的去向）保持现状，未改。
