---
name: 2026-11-02-versioning
description: 版本号从 0.9.1 起递增，1.0 只留给用户确认的最终完整版
type: decision
status: accepted
updated: 2026-11-08
load_when: 改 project.godot 版本、export_presets 版本、写发布说明时
---

# ADR：版本号策略

- 当前版本线：**0.9.3** 起，每个可交付批次递增 patch（0.9.2 → 0.9.3 → …）。
- **1.0 不使用**，直到用户明确同意“做出来最终完整版了”。
- 每次递增同时更新：
  - `project.godot` 的 `config/version`
  - `export_presets.cfg` 的 `version/name` 与 `version/code`（Android versionCode 每次 +1）
  - 发布说明/记忆索引
- 0.9.0 画面打磨；0.9.1 试玩修复；0.9.2 四章 MDS + 净化；0.9.3 数值、成长、难度、AI 权限。

## 2026-11-08 更新：1.0.0

- 用户确认 0.15 之后的这一版为正式 1.0（「这一版做完之后就是正式1.0版本了」），版本号改为 `1.0.0`，Android versionCode 14。
- 之后的修复走 1.0.x，新内容走 1.x。
