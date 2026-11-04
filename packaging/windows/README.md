# Windows 发行包

本目录只放打包脚本，不放构建产物。

## 文件

- `changzi-adventure.iss`：Inno Setup 6.3+ 安装器脚本（per-user 安装、开始菜单/
  可选桌面快捷方式、卸载项；不删除玩家存档）。

## 构建流程

1. 在仓库根目录导出 release 版（需要本机已安装 4.7 导出模板）：

   ```powershell
   godot --headless --path . --export-release "Windows Desktop" build/windows/changzi-adventure.exe
   ```

2. 在 Windows 上用 Inno Setup 编译安装器：

   ```powershell
   ISCC.exe packaging\windows\changzi-adventure.iss
   ```

3. 产物：

   ```
   build\windows\installer\changzi-adventure-0.11.0-demo-setup.exe
   ```

## 版本与签名

- 安装器顶部的 `MyAppVersion` / `MyAppVersionNumeric` 必须与
  `project.godot` 的 `config/version` 同步。
- 当前默认**不签名**。真实代码签名证书是唯一的用户侧阻塞项；证书到位后按
  [`docs/release/windows-signing.md`](../../docs/release/windows-signing.md)
  接入 `signtool`、时间戳和 Inno 的 `SignTool` / `SignedUninstaller`。
- 不要提交 `.pfx` / `.p12` / 密码或任何证书私钥。

## 存档位置

Windows 上的进度保存在 `%APPDATA%\Godot\app_userdata\昌子大冒险`。安装器与
卸载器都不触碰该目录，卸载不会删除存档。
