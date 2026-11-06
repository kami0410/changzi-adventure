# 第 75 程 · Windows 导出（brief79）

> 发布前置程。依据 `.supervisor/DECISIONS.md`「再更正：Release 直接带 Windows 包」
> （2026-11-06 13:42 用户拍板）：本次发布 = 里程碑快照推送 GitHub main + 网页版
> 更新 + GitHub Release `v0.12.0`（pre-release，直接带 Windows 包）。本程只做
> Windows 导出与 zip 打包/验证；推送、网页更新、Release 创建与资产上传不在本程，
> 由监工执行（Release 创建/上传需用户本人配合 passkey）。

## 任务 0 · 基线核验（HEAD `7d11fc2`，Godot 4.7.stable.official.5b4e0cb0f）

- `--headless --path . --import` / `--quit` 退出 0、无脚本错误。
- 单元 `tests/run_tests.gd` **13,490 / 0**。
- 十一套集成全部跑完，与第 74 程逐套件一致、全 0 失败：
  `integration_playability` **899** / `integration_ch1_demo` **109** /
  `integration_run_save` **613** / `integration_gamepad` **207** /
  `integration_ui_prompts` **113** / `integration_ch1_event` **59** /
  `integration_menus` **445** / `integration_ai_settings` **45** /
  `integration_ch2_bigmap` **2,315** / `integration_ch3_bigmap` **4,358** /
  `integration_ch4_bigmap` **5,133**。
- `tests/check_exit_clean.sh` **10/10 clean**；`check_pixel_assets.py --demo`
  **36 / 0**。
- 结论：基线无漂移，可导出。

## 任务 1 · 导出链路核验

- 引擎：`~/workspace/tools/godot/bin/Godot_v4.7-stable_linux.x86_64`
  （4.7.stable.official.5b4e0cb0f）。
- 模板：`~/.local/share/godot/export_templates/4.7.stable/` 已安装，
  `version.txt` = `4.7.stable`，含 `windows_release_x86_64.exe`
  （109,160,448 bytes）与 debug/32-bit/ARM64 全套。
- 预设：仓库 `export_presets.cfg` 的 `Windows Desktop`，`runnable=true`、
  `export_filter="all_resources"`、`export_path="build/windows/changzi-adventure.exe"`、
  `binary_format/embed_pck=true`、图标 `res://assets/branding/changzi.ico`（存在）。
  **本程未改导出预设。**
- 运行时非资源文件核查：MDS 世界文件 `.mdsworld.json` 用 `FileAccess` 读取；
  在 Godot 4.7 中 `.json` 被识别为 `JSON` 资源（`ResourceLoader.exists` 为 true），
  因此 `all_resources` 会把它打进 PCK，无需 `include_filter`。四个章节世界
  JSON 与 `assets/audio/manifest.json` 均确认可被资源系统识别。

## 任务 2 · 导出

命令（仓库根目录）：

```bash
~/workspace/tools/godot/bin/Godot_v4.7-stable_linux.x86_64 --headless --path . \
  --export-release "Windows Desktop" build/windows/changzi-adventure.exe
```

- **退出码 0**，耗时 **20 秒**；完整输出存
  `artifacts/releases/v0.12.0/export.log`（1,732 行，206,557 bytes）。
- 导出前删除了第 3 程遗留的旧 `build/windows/changzi-adventure.exe`，确保产物
  来自当前 HEAD。
- 导出日志中的非致命告警：
  - `Invalid version number "0.11.0-demo"` ×2：Windows 预设未设数值版
    `application/file_version`/`product_version`，回落到非纯数字的
    `project.godot config/version`；exe 的 VERSIONINFO 数值版本为空，不影响运行。
  - 导出器自身退出告警 `973 ObjectDB instances were leaked` /
    `8 resources still in use`：与第 3 程同源，属编辑器/导出器侧；游戏运行退出
    仍为 0 泄漏（`check_exit_clean.sh` 10/10）。
  - `Unable to open Android 'build-tools' directory`：与 Windows 导出无关。

## 任务 3 · 产物验证

- `build/windows/changzi-adventure.exe`：**132,104,632 bytes**（约 126.0 MiB），
  `file` = `PE32+ executable (GUI) x86-64 ... for MS Windows`。
  SHA-256 `7d4811f43ae27d378cd79570b1e36db9f9ab2dfb35602819185a2e39abd94242`。
- **PCK 内嵌**（`embed_pck=true`）：exe 偏移 109,174,272 起为 `GDPC` 头，
  内嵌数据 **22,930,348 bytes**；尾部 12 字节为 size+`GDPC` 尾标。
  - 用 `--export-pack "Windows Desktop" /tmp/pass75_standalone.pck` 独立导出同
    资源集，产物 **22,930,348 bytes**，与从 exe 提取的内嵌 PCK **逐字节一致**
    （`cmp` IDENTICAL，SHA-256 均为
    `20ba3fff908bfc31a43039b95bf2170ad51f9fe053629fac4942dda9726c3a9f`）。
  - 在临时空项目里 `ProjectSettings.load_resource_pack()` 加载提取出的 PCK，
    逐项检查 12 个关键路径（hub/main 场景、四个章节世界 JSON、第一章计划资源、
    Fusion 字体、Boss 贴图、音频 manifest、`scripts/game.gd`）：
    **MISSING=0**；JSON 为直接文件，场景/字体/贴图/脚本经导入重映射后
    `ResourceLoader.exists` 均为 true。
  - `--headless --main-pack /tmp/pass75_embedded.pck --quit`（隔离
    `XDG_DATA_HOME`）**退出 0**、无脚本错误——导出数据包可被引擎完整加载。
- 说明：本预设是**单文件 exe**（PCK 内嵌），因此 zip 里没有独立的 `.pck` 文件；
  上面的独立 `--export-pack` 与逐字节比对就是对「exe + pck 齐全」的验证。
  仓库既有发行文档（`docs/release/windows-signing.md`、`packaging/windows/README.md`）
  同样按单文件 exe 描述。

## 任务 4 · zip 打包

- 路径：`artifacts/releases/v0.12.0/changzi-adventure-v0.12.0-windows.zip`
  （`artifacts/` 已被 `.gitignore` 覆盖，不提交）。
- 内容（`unzip -l`）：1 个文件 `changzi-adventure.exe`，未压缩
  **132,104,632 bytes**；无 0 字节文件。
- zip 体积：**59,572,799 bytes**（约 56.8 MiB；deflate 压缩率 55%）。
  SHA-256 `9e14c4359960f0bae20b341e24d671995ca020550b7d1f24cc02805607024e9e`。
- `unzip -t` 通过；zip 内 exe 的 SHA-256 与源 exe 一致
  （`7d4811f4…4242`）。
- 同目录另留 `changzi-adventure.exe`（源 exe）与 `export.log`，均为本地记录，
  不提交。

## 验证口径与边界

- 本程通过口径：导出退出 0 + 数据包完整（独立导出逐字节一致、关键路径齐全、
  可被 `--main-pack` 加载）+ zip 完整可解压 + 体积合理（exe 126.0 MiB、
  zip 56.8 MiB，与导出日志产物大小一致）。
- **Windows 实机首跑未做，也不在本程范围**：本机是 Linux VM，无法运行
  Windows exe；未使用 wine/虚拟机硬跑。Release notes 必须如实写
  「Windows 实机首跑待验证」。

## 版本口径（记录，未改）

- 本次 Release tag / zip 文件名用 `v0.12.0`；但 `project.godot config/version`、
  标题屏版本标签、Android 预设 `version/name` 仍为 `0.11.0-demo`，按本程任务单
  「不改游戏代码/产品配置」未动。因此 Windows exe 的数值版本元数据为空
  （见上）。版本号统一是后续独立决定，本程不猜、不改。

## 收尾

- 未推送、未更新网页版、未创建 Release、未上传任何资产；第 2–4 章仍不可达，
  `CHAPTER_PLAN_PATHS[2]/[3]` 未动。
- 本程只新增记录文档与状态文件更新；产品代码/场景/资源/测试/导出预设零改动。
