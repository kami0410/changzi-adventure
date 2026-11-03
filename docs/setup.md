# 环境搭建与导出

## 本机工具清单

| 工具 | 路径/版本 | 用途 |
|---|---|---|
| Godot | `tools/godot/Godot_v4.7.2-stable_win64.exe`（4.7.2.stable） | 编辑器 |
| Godot console | `tools/godot/Godot_v4.7.2-stable_win64_console.exe` | 无头检查/导出 |
| 导出模板 | `tools/godot/editor_data/export_templates/4.7.2.stable/` | Windows/Android 导出 |
| JDK | `D:\Android\jdk-21`（JDK 21） | Android 构建/签名 |
| Android SDK | `D:\Android\Sdk` | Android 导出 |
| build-tools | `36.0.0` | apksigner/aapt |
| NDK | `28.2.13676358`（r28c） | 原生构建 |
| CMake | `3.22.1` | 原生构建 |
| adb | `D:\Android\Sdk\platform-tools\adb.exe`（37.0.1） | 设备安装/调试 |
| Flutter | `D:\Android\flutter`（3.47.7） | 本机已有，Godot 不使用 |

## Godot 便携模式

`tools/godot/` 下有 `._sc_` 标记文件，Godot 进入 **self-contained/portable 模式**：

- 编辑器设置：`tools/godot/editor_data/editor_settings-4.7.tres`
- 导出模板：`tools/godot/editor_data/export_templates/4.7.2.stable/`
- 项目列表缓存：`tools/godot/editor_data/projects.cfg`

这样引擎、配置、模板都留在项目文件夹内，不污染 `%APPDATA%`。

### 重新安装

1. 从 [Godot 4.7.2 发布页](https://godotengine.org/download/archive/4.7.2-stable/) 下载 `Godot_v4.7.2-stable_win64.exe.zip` 与 `Godot_v4.7.2-stable_export_templates.tpz`。
2. 解压编辑器到 `tools/godot/`。
3. 解压 `.tpz`，把其中 `templates/` 的内容放到 `tools/godot/editor_data/export_templates/4.7.2.stable/`。
4. 确认 `tools/godot/._sc_` 存在。
5. 校验：`tools/godot/Godot_v4.7.2-stable_win64_console.exe --version` 输出 `4.7.2.stable.official...`。

## Android 编辑器设置

`editor_settings-4.7.tres` 中已配置：

```text
export/android/java_sdk_path = "D:/Android/jdk-21"
export/android/android_sdk_path = "D:/Android/Sdk"
```

官方推荐 JDK 17，但文档明确“更高版本也支持”；本机 JDK 21 已实际完成 Android 导出。若遇到 Gradle/签名异常，再安装 Temurin 17 到 `D:\Android\jdk-17` 并切换路径。

## 常用命令

```powershell
# 新建游戏
powershell -ExecutionPolicy Bypass -File scripts/new_game.ps1 -Slug my-game -Name "我的游戏"

# 无头检查
powershell -ExecutionPolicy Bypass -File scripts/check_game.ps1 -Game my-game

# 调试导出（Windows + Android）
powershell -ExecutionPolicy Bypass -File scripts/export_game.ps1 -Game my-game -Platform All

# 只导出 Windows
powershell -ExecutionPolicy Bypass -File scripts/export_game.ps1 -Game my-game -Platform Windows

# Release 导出（Android 需要先配置 keystore）
powershell -ExecutionPolicy Bypass -File scripts/export_game.ps1 -Game my-game -Platform All -Release
```

## Android 导出要点

- `project.godot` 必须开启 `rendering/textures/vram_compression/import_etc2_astc=true`，否则 Godot 4.7 会拒绝 Android 导出。
- 模板默认：`minSdk 24`、`targetSdk 36`、`compileSdk 36`、`arm64-v8a`。
- 调试 APK 使用 Godot 自动生成的 debug keystore，验证可直接安装。
- 首次导出会自动创建 debug keystore；如失败，检查 `%USERPROFILE%\.android\debug.keystore`。
- Release AAB 需要把导出预设的 `gradle_build/use_gradle_build` 改为 `true`，并配置 release keystore；当前模板只保证 debug APK。
- 国内渠道 SDK、支付、登录、隐私合规不在当前范围。

## 故障排查

| 现象 | 处理 |
|---|---|
| `Cannot export ... configuration errors` 提到 ETC2/ASTC | 确认 `import_etc2_astc=true`，重新导入项目 |
| 找不到 `apksigner`/`zipalign` | 确认 `D:\Android\Sdk\build-tools\36.0.0` 存在；或安装 35.0.1 |
| NDK 版本报错 | 先试现有 28.2；失败再装 `sdkmanager "ndk;28.1.13356709"` |
| JDK 相关 Gradle 错误 | 安装 Temurin 17，改 `export/android/java_sdk_path` |
| 导出模板不匹配 | 模板目录必须是 `4.7.2.stable`，不能混用其它版本 |
| 设备安装失败 | `adb devices` 确认已授权；卸载同包名旧应用后重试 |

## M0 验证记录（2026-10-31）

- `check_game.ps1 -Game m0-pipeline`：通过。
- Windows 导出：`build/windows/m0-pipeline.exe`（约 99 MB），无头启动通过。
- Android 导出：`build/android/m0-pipeline.apk`（约 28 MB），apksigner 签名通过。
- APK 元数据：`com.gamecreatestudio.m0_pipeline`、versionCode 1、versionName 0.1.0、minSdk 24、targetSdk 36、arm64-v8a。
- 本机当前没有连接 Android 设备，未做真机安装验证。
