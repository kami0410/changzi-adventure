---
name: 2026-10-31-workspace-and-skills
description: 建立多游戏工作区、M0 管线、33 个技能与记忆索引
type: session
status: active
updated: 2026-10-31
load_when: 回顾工作室初始化、技能安装或 M0 验证时
---

# 2026-10-31：工作区与技能安装

## 完成

- 工作区改为多游戏结构：`tools/`、`templates/game_project/`、`games/<slug>/`、
  `shared/`、`scripts/`、`docs/`。
- Godot 4.7.2 stable 便携安装到 `tools/godot/`，导出模板装在
  `tools/godot/editor_data/export_templates/4.7.2.stable/`。
- 用模板生成 `games/m0-pipeline`（独立 git 仓库），跑通：
  - 无头检查。
  - Windows 导出（约 99 MB）。
  - Android debug APK（约 28 MB，apksigner 签名通过）。
  - APK：`com.gamecreatestudio.m0_pipeline`，targetSdk 36，arm64-v8a。
- 安装 33 个技能到 `.claude/skills/`：
  - 31 个来自 `awesome-gamedev-agent-skills` @ `19d93f9`（Apache-2.0，含
    `platformer`、`game-ai`、`physics-tuning`）和 `GodotPrompter` @ `d7b26cd`（MIT）。
  - 自建 `memory-index`、`magpie-art`。
  - 完整美术工作流：`create-game-assets`（art-direction brief、asset manifest、
    raster/3D pipeline、QA 脚本）。
- 建立记忆索引：`docs/memory/MEMORY.md` + ADR + 术语表 + 待定问题 + 本总结。
- 根 `CLAUDE.md` 通过 `@docs/memory/MEMORY.md` 自动加载索引。

## 验证

- `scripts/check_game.ps1 -Game m0-pipeline` 通过。
- Windows exe 无头启动通过。
- Android APK 元数据正确；本机无 Android 设备，未做真机安装。

## 决策

- 引擎：Godot 4.7.2 standard + GDScript。
- 每款游戏独立子目录、独立 git 仓库；根仓库只跟踪模板/脚本/文档。
- `tools/` 物理保留、git 忽略；版本记录在 `tools/manifest.json`。
- 技能采用精选包，不整包装 49-agent 的 Claude-Code-Game-Studios。
- 美术生成用 Magpie MCP，流程走 `create-game-assets` + `magpie-art`。

## 下一步

- 第一款游戏：2D 横版动作 Roguelite，核心是道具/构筑。
- 需要继续定：战斗模型、道具系统、单局结构、美术方向、叙事、垂直切片范围。
- 新技能会在下一次 Claude Code 会话加载；当前会话仍可手动按技能内容执行。
