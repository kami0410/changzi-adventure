# Godot 工具调研

日期：2026-11-02
方法：子代理只用网页搜索和网页阅读，没有下载或安装任何东西。版本、日期和许可来自文末链接，**主控没有逐条复核**；安装前要再看一次官方页面。
项目约束：Godot 4.7.2 标准版、只用 GDScript、GL Compatibility、Windows + Android、目标 120 FPS。

不在本文范围：
- 动画导入与骨骼工具（Aseprite Wizard、AnimSheet、SpriteForge、DragonBones、Spine 等）见 [2026-11-01 交接](../memory/sessions/2026-11-01-handoff-mds-ai.md) 第 5 节。
- MDS 见 [MDS 评估](metroidvania-developer-system.md)。

## 结论表

| 工具 | 用途 | 最新版本（日期） | Godot 支持 | 代码 | 许可 | 大小 | 结论 |
|---|---|---|---|---|---|---|---|
| Phantom Camera | 相机跟随、构图、转场、震屏 | 0.11.0.4（2026-10-27） | 最低 4.4.1；4.5–4.7 已确认，4.7.2 未测 | 纯 GDScript（可选 C# 包装） | MIT | 未查到 | 以后重做相机时再试 |
| Dialogic 2 | 可视化对话与剧情编辑 | 2.0-alpha-20（2026-07-21） | 最低 4.5；4.6、4.7 已确认 | 纯 GDScript | MIT | 未查到（较大） | 暂不用：alpha，版本之间存档和接口不兼容 |
| godot-ink | Ink 剧情运行时 | 1.1.2（2024-02-12） | 只支持 .NET 版 | C# | MIT | — | 不用：标准版和 Android 用不了 |
| inkgd | Ink 运行时（GDScript） | 0.5.0（2023-08-28） | 没有 Godot 4 正式版 | GDScript | MIT | — | 不用：停更 |
| Yarn Spinner（GDScript） | Yarn 剧情运行时 | 3.2.0-alpha8（2026-07-28） | 最低 4.6；4.7 未确认 | 纯 GDScript | YSPL（不是 MIT） | — | 不用：抢先体验版，许可有附加条款 |
| GUT | 单元测试 | 9.7.1（2026-07-10） | 9.7.0 起支持 4.7 | 纯 GDScript | MIT | — | 不用：项目已有自建测试（2960 项） |
| gdUnit4 | 单元与场景测试、mock | 6.2.2（2026-10-07） | 4.5–4.7.1 已确认 | 纯 GDScript | MIT | — | 不用；需要场景模拟或 mock 时再考虑 |
| Pixelorama | 像素画与动画编辑器（独立软件） | 1.2.3（2026-09-15） | 独立运行 | — | MIT | Windows 压缩包 40.9 MB | 可选：人工修像素时用 |
| LibreSprite | 像素编辑器（Aseprite 分支） | 1.3（2026-10-02） | 独立运行 | — | GPL-2.0 | Windows 压缩包 41.6 MB | 不用：更新慢，GPL |
| 内置监视器与分析器 | 帧时间、绘制调用、远程调试 | 引擎自带 | 4.7.2 | — | MIT | 0 | 用：`tests/bench_spells.gd` 已在用 `Performance` 监视器 |
| LimboConsole | 游戏内开发控制台（命令、补全） | 0.8.0（2026-06-20） | 4.3+；4.7 未确认 | 纯 GDScript | MIT | 7.0 MB | 试玩阶段值得装，只放调试版 |
| Profily | 发布版性能面板（FPS、1% 低帧、绘制调用、内存） | 1.0.3（2026-08-01） | 最低 4.6；第三方报告 4.7.2 能加载 | 静态类型 GDScript | MIT | 256 KB | 可选：自写面板能覆盖大部分需求 |
| Godot Input Prompts | 按键提示图标、输入设备切换 | 2.3.0（2024-05-04） | 4.1+；4.5–4.7 未确认 | 纯 GDScript | MIT（图标 CC0） | 约 220 KB | 不用：没有触屏提示 |
| VFX 2D Free | 着色器 2D 特效（有像素模式） | 1.0.1（2026-09-29） | 4.3–4.7，含 Compatibility | 纯 GDScript | CC BY 4.0（完整包付费） | 未查到 | 可选：免费版只有 4 种，需署名 |
| Godot VFX Library | 35 种以上特效 | 未查到 | 文档只写 Forward+/Mobile | — | MIT | 未查到 | 要先测 GL Compatibility |

## 建议

- **试玩阶段**：LimboConsole（刷怪、给词、跳章），用 `OS.is_debug_build()` 守住，发布版排除。
- **性能**：先用内置监视器加一个自写的帧时间面板；需要发布版 1% 低帧时再装 Profily。
- **相机**：现有相机够用；重做竞技场构图或转场时再试 Phantom Camera。
- **剧情**：继续用现有 `StoryOverlay` / `DialogueUI`；只有在需要可视化编辑大量分支时再评估 Dialogic 2。
- **不用**：Ink（要 .NET 或已停更）、Yarn Spinner（alpha、YSPL）、GUT/gdUnit4（已有测试）、LibreSprite、Input Prompts。
- **本地化**：引擎自带的 CSV/POT + TranslationServer 够用，不需要插件。
- 任何安装都要先问用户。

## 来源

- Phantom Camera：<https://github.com/ramokz/phantom-camera/releases>、<https://godotengine.org/asset-library/asset/1822>
- Dialogic 2：<https://github.com/dialogic-godot/dialogic/releases/tag/2.0-alpha-20>、<https://github.com/dialogic-godot/dialogic/blob/main/LICENSE>
- godot-ink：<https://github.com/paulloz/godot-ink/releases/tag/v1.1.2>
- inkgd：<https://github.com/ephread/inkgd/releases/tag/0.5.0>
- Yarn Spinner（GDScript）：<https://github.com/YarnSpinnerTool/YarnSpinner-Godot-GDScript/releases/tag/v3.2.0-alpha8>、<https://github.com/YarnSpinnerTool/YarnSpinner-Godot-GDScript/blob/main/LICENSE.md>
- GUT：<https://github.com/bitwes/Gut/releases/tag/v9.7.1>、<https://store.godotengine.org/asset/bitwes/gut/>
- gdUnit4：<https://github.com/godot-gdunit-labs/gdUnit4/releases>、<https://godotengine.org/asset-library/asset/4390>
- Pixelorama：<https://github.com/Orama-Interactive/Pixelorama/releases/tag/v1.2.3>、<https://github.com/Orama-Interactive/Pixelorama/blob/master/LICENSE>
- LibreSprite：<https://github.com/LibreSprite/LibreSprite/releases/tag/v1.3>、<https://packages.msys2.org/packages/mingw-w64-ucrt-x86_64-libresprite>
- LimboConsole：<https://github.com/limbonaut/limbo_console/releases/tag/v0.8.0>、<https://godotengine.org/asset-library/asset/3338>
- Profily：<https://store.godotengine.org/asset/javier-garrido/profily/>
- Godot Input Prompts：<https://godotengine.org/asset-library/asset/2140>
- VFX 2D Free：<https://godotengine.org/asset-library/asset/5496>
