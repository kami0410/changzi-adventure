# 交接说明 · 昌子大冒险 Chapter 1 Demo

> 版本：`0.11.0-demo`（2026-11-03）
> 引擎：Godot **4.7.2 stable 标准版**（GDScript，不是 .NET）
> 仓库根目录就是 Godot 项目根目录，可以直接用 Godot 打开。

## 这是什么

这是一份可继续开发的 Chapter 1 试玩 demo。按
[Chapter 1 demo 审阅与实施计划](docs/superpowers/plans/2026-11-02-chapter1-demo-review-and-plan.md)
执行了 T1–T14 + T4b：像素统一、语言解码/权柄真机制、离线言灵、6+6 demo 武器/遗物、
Boss 三阶段、教学、Profile v2、真实输入集成与 Windows/Android 构建。

## 快速开始

1. 从 [Godot 官网](https://godotengine.org/download) 下载 **Godot 4.7.2 stable 标准版**。
   本仓库**不包含** `tools/godot` 引擎二进制，也不包含 `build/` 产物。
2. 用 Godot 打开仓库根目录的 `project.godot`。
3. 运行主场景 `scenes/main.tscn`，或直接运行 `scenes/hub/hub.tscn` 看 Hub。

命令行验证（Windows，Godot 可执行文件路径按本机替换）：

```bash
godot --headless --path . --import
godot --headless --path . -s tests/run_tests.gd
godot --headless --path . -s tests/integration_playability.gd
godot --headless --path . -s tests/integration_ch1_demo.gd
godot --headless --path . res://scenes/main.tscn --quit-after 400
```

构建：

```bash
godot --headless --path . --export-debug "Windows Desktop" build/windows/changzi-adventure.exe
godot --headless --path . --export-debug "Android" build/android/changzi-adventure.apk
```

## 目录

| 路径 | 内容 |
|---|---|
| `scenes/` / `scripts/` | 游戏场景与 GDScript |
| `resources/` | 词、短语、武器、遗物、权柄、章节计划、TileSet |
| `assets/` | 像素 sprite、背景、立绘、UI、音频、字体 |
| `tests/` | 单元测试、结构集成、真实输入集成、像素门禁 |
| `docs/GDD.md` | 玩法事实来源；§22 是 0.11 demo 实际规则 |
| `docs/memory/` | 游戏记忆索引、决策 ADR、阶段总结 |
| `docs/studio-memory/` | 工作室记忆（原 `GameCreateStudio/docs/memory`） |
| `docs/playtest/ch1-demo-checklist.md` | 5–10 人封闭试玩清单 |
| `docs/superpowers/plans/` | 本次实施计划（唯一执行清单） |
| `.claude/skills/` | 项目技能（34 个，含来源/许可说明 `_licenses/`） |
| `addons/` | Metroidvania Developer System、Aseprite Wizard（MIT，保留各自 LICENSE） |
| `tools/` | 小工具脚本（Python/GDScript），不含引擎二进制 |

## Demo 内容

- 标题 → Hub → `ch1_01` 教学 → `ch1_02` → `ch1_03`（隐藏书库门）→ `ch1_04` 精英 →
  `ch1_05` 事件 → `ch1_06` → `ch1_rest` → `ch1_boss` → 权柄二选一 → 章末选择 →
  “第一章 demo 结束 / 未完待续”。
- Hub 只开放陆沉/阿砚/咕噜；闻烬/白榆保留资产但 demo 不可交互。
- 语言：6 个初始已解码 + 12 个起始残页词；陆沉每次回 Hub 解 1 个；未解码可施放但
  `[不稳定]` + 污染；解码/已发现组合跨局保存。
- 权柄：续命（每局一次复活）、改写（每局一次重掷清房奖励），Chapter 1 Boss 掉落。
- 离线言灵完整可玩；AI 是可选的设置项，默认关闭、无内置密钥。
- 6 把 demo 武器 / 6 件遗物，各带独特行为；其余资产保留给完整版。
- HUD 12/16/20 字号、整数缩放、失焦暂停、离开/重开确认。

## 验证结果

- 单元：`3413 passed, 0 failed`
- 结构集成：`267 checks, 0 failures`
- 真实输入 demo 集成：`11 checks, 0 failures`
- `scripts/check_game.ps1 -Game changzi-adventure`：PASSED（脚本在工作区根目录，不在本仓库）
- 像素门禁：`python tests/check_pixel_assets.py --demo` → 36 assets / 0 failures
- Windows 导出运行：120 FPS（8.33 ms/frame）
- Windows/Android 构建均在本地产出；构建产物未提交。

## 已知问题 / 未完成

1. `--quit-after` 强制退出仍间歇报 `8 ObjectDB / 4 resources` 泄漏 warning；
   `AudioManager.shutdown()` 已接入，但不是所有强制退出路径都能零泄漏。
2. T16 局内 run save/resume 未实现（P1），关闭应用会丢当前局。
3. 人工 1080p/1440p 截图、Boss phase 2/3 实机截图、5–10 人封闭试玩尚未进行。
4. 旧 v1 存档里基于 meanings 的 `discovered_phrases` 无法在新 Codex 还原（新签名按词 id）。
5. 部分完整版内容仍是占位：Boss 安全区是程序绘制、第 2–4 章仍用旧绘画背景。
6. 存档 v2 有 `.bak`，但“主文件缺失 + 备份存在”路径需要继续实机验证。

## 下一步建议（P1/P2）

- T15 手柄 + 焦点导航；T16 局内 run save/resume；T17 权柄 P1（吞噬/归档）+ 叙事；
  T18 发行准备。
- 先做 5–10 人封闭试玩，只修 Top 5，不加系统；指标见
  `docs/playtest/ch1-demo-checklist.md`。

## 素材与许可

- 代码：MIT（见 `LICENSE`）。
- 美术/音频：项目内原创或 AI 生成后手工/脚本清理；第三方字体/插件保留各自许可。
- **本仓库不包含真人照片**。原 `assets/references/`（真人参考图）已从公开仓库排除；
  游戏内使用风格化原创像素形象。
- SAPI 配音仍是内部原型，不应用于正式商用发布；完整版需替换。
