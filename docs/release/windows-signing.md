# Windows 代码签名与安装器接入

> 适用：Chapter 1 demo（当前 `0.11.0-demo`）及后续 Windows 发行版。
> 状态：**未签名**。安装器脚本与签名流程已就绪，但真实证书尚未取得。

## 唯一用户侧阻塞项

**需要一张真实的 Windows 代码签名证书。** 证书申请需要用户/工作室的主体资料、
身份或企业验证以及付费，属于用户侧事务；本仓库不购买、不生成、不伪造证书。

- 没有证书时：安装器可以正常编译和安装，但 Windows SmartScreen 会提示
  “未知发布者”，部分企业环境可能直接拦截。
- 自签名证书不能用于正式发行：它无法建立 SmartScreen/Windows 信任，只是
  把“未知发布者”换成“不受信任的发布者”，因此本仓库不提供假证书脚本。
- 证书类型（OV / EV、文件型 `.pfx` / 硬件令牌 / 云 HSM）由用户按预算和
  发行渠道选择；选定后按本文接入即可，应用代码与安装器脚本不需要改。

## 前置条件

- Windows 10/11 构建机（或带 Windows 签名步骤的 CI runner）。
- Windows SDK 的 `signtool.exe`（通常位于
  `C:\Program Files (x86)\Windows Kits\10\bin\<版本>\x64\signtool.exe`）。
- Inno Setup 6.3 或更新版本（`ISCC.exe`）；安装器脚本见
  [`packaging/windows/changzi-adventure.iss`](../../packaging/windows/changzi-adventure.iss)。
- 代码签名证书：
  - 文件型：`.pfx` + 密码；
  - 证书存储：证书已导入当前用户/机器的 Personal 存储；
  - EV/云签名：使用证书厂商提供的签名工具或云签名服务（这类证书通常
    不可导出为 `.pfx`，不能直接套用下面的 `/f` 命令）。

## 1. 构建未签名的 release exe

在仓库根目录：

```powershell
godot --headless --path . --export-release "Windows Desktop" build/windows/changzi-adventure.exe
```

产物是单文件 exe（PCK 已嵌入），约 125.7 MiB。版本号来自
`project.godot` 的 `config/version`；同步修改安装器脚本顶部的
`MyAppVersion` / `MyAppVersionNumeric`。

## 2. 签名游戏 exe

先签游戏本体，再打安装包；这样安装包内嵌的是已签名的 exe。

文件型证书（密码从环境变量读取，禁止写进脚本/仓库）：

```powershell
$env:CERT_PASSWORD = "<从密钥管理工具注入，不要提交>"
signtool sign /fd SHA256 /td SHA256 /tr http://timestamp.digicert.com `
  /f C:\secure\changzi-codesign.pfx /p $env:CERT_PASSWORD `
  build\windows\changzi-adventure.exe
```

证书已在证书存储中时：

```powershell
signtool sign /fd SHA256 /td SHA256 /tr http://timestamp.digicert.com `
  /a build\windows\changzi-adventure.exe
```

- `SHA256`：文件摘要与时间戳摘要都用 SHA-256；现代 Windows 不需要 SHA-1。
- `/tr` + `/td`：RFC 3161 时间戳。没有时间戳的签名在证书到期后失效；
  带时间戳的签名在证书有效期内签出的文件可以长期验证。
- `/a`：自动选择最合适的证书；多证书环境也可用 `/sha1 <指纹>` 或
  `/n "<证书主题>"` 精确指定。
- 时间戳服务器可换用：
  - DigiCert：`http://timestamp.digicert.com`
  - Sectigo：`http://timestamp.sectigo.com`
  - GlobalSign：`http://timestamp.globalsign.com/tsa/r6advanced1`
  若某个服务器临时不可用，换另一个重试即可。

## 3. 编译安装器

未启用签名时直接编译：

```powershell
ISCC.exe packaging\windows\changzi-adventure.iss
```

产物：`build\windows\installer\changzi-adventure-0.11.0-demo-setup.exe`。

签名启用后，安装器应在编译完成后单独签名：

```powershell
signtool sign /fd SHA256 /td SHA256 /tr http://timestamp.digicert.com `
  /f C:\secure\changzi-codesign.pfx /p $env:CERT_PASSWORD `
  build\windows\installer\changzi-adventure-0.11.0-demo-setup.exe
```

## 4. 让 Inno Setup 自动签名（可选）

Inno Setup 支持在编译时自动签名 setup 和 uninstaller。证书到位后：

1. Inno Setup IDE → **Tools → Configure Sign Tools… → Add**：
   - Name：`signtool`
   - Command：
     ```
     "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe" sign /fd SHA256 /td SHA256 /tr http://timestamp.digicert.com /a $f
     ```
     其中 `$f` 由 Inno 替换为待签名文件；按实际 SDK 版本调整路径。
2. 打开 `packaging/windows/changzi-adventure.iss`，取消这两行的注释：
   ```
   SignTool=signtool
   SignedUninstaller=yes
   ```
3. 重新编译。`SignTool` 已配置但不可用时，`ISCC` 会直接报错而不是产出
   未签名安装包，这正是我们想要的护栏。

命令行/CI 也可以不落盘配置，直接用 `/S` 定义签名工具：

```powershell
ISCC.exe /Ssigntool="C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe sign /fd SHA256 /td SHA256 /tr http://timestamp.digicert.com /a $f" `
  packaging\windows\changzi-adventure.iss
```

（`/S` 的整段命令要作为一个参数传入；仍建议先用 IDE 配置验证一次。）

## 5. 验证签名

```powershell
signtool verify /pa /v build\windows\changzi-adventure.exe
signtool verify /pa /v build\windows\installer\changzi-adventure-0.11.0-demo-setup.exe
```

或 PowerShell：

```powershell
Get-AuthenticodeSignature .\build\windows\changzi-adventure.exe |
  Format-List Status, StatusMessage, SignerCertificate, TimeStamperCertificate
```

检查点：

- `Status` 为 `Valid`；
- `SignerCertificate` 是预期主体；
- `TimeStamperCertificate` 非空（证明时间戳生效）；
- 双击安装器时发布者显示为证书主体，而不是“未知发布者”。

## 6. CI 接入

文件型证书可以放进 CI secret，但必须按密钥处理：

1. 将 `.pfx` 做 Base64 存入 secret（例如 `WINDOWS_CERT_PFX_BASE64`），
   密码存入另一个 secret（`WINDOWS_CERT_PASSWORD`）。
2. Job 内解码到临时目录，调用 `signtool`，结束后删除临时文件
   （Windows runner 的 `$env:RUNNER_TEMP`）。
3. 只签 `build/windows/` 下的产物；不要把 `.pfx`、密码、临时文件放进
   artifact 或缓存。
4. 若使用 EV 硬件令牌或云 HSM（Azure Trusted Signing、DigiCert KeyLocker
   等），按厂商提供的 CI 插件/CLI 调用，不能导出 `.pfx`。

示例（GitHub Actions，Windows runner）：

```yaml
- name: Decode signing certificate
  shell: pwsh
  run: |
    $pfx = Join-Path $env:RUNNER_TEMP "codesign.pfx"
    [IO.File]::WriteAllBytes($pfx, [Convert]::FromBase64String($env:CERT_PFX_BASE64))
    "PFX_PATH=$pfx" >> $env:GITHUB_ENV
  env:
    CERT_PFX_BASE64: ${{ secrets.WINDOWS_CERT_PFX_BASE64 }}

- name: Sign game exe
  shell: pwsh
  run: |
    signtool sign /fd SHA256 /td SHA256 /tr http://timestamp.digicert.com `
      /f "$env:PFX_PATH" /p $env:CERT_PASSWORD build\windows\changzi-adventure.exe
  env:
    CERT_PASSWORD: ${{ secrets.WINDOWS_CERT_PASSWORD }}

- name: Remove certificate
  if: always()
  shell: pwsh
  run: Remove-Item -Force "$env:PFX_PATH" -ErrorAction SilentlyContinue
```

## 7. 发布前检查清单

- [ ] `project.godot` 的 `config/version` 与安装器 `MyAppVersion` 一致。
- [ ] release 导出成功，exe 能启动（Windows 实机）。
- [ ] 游戏 exe 已签名且时间戳有效。
- [ ] 安装器已编译；启用签名时安装器与 uninstaller 均已签名。
- [ ] `signtool verify /pa /v` 对两个产物均通过。
- [ ] 卸载后 `%APPDATA%\Godot\app_userdata\昌子大冒险` 中的存档仍在。
- [ ] 仓库中没有 `.pfx` / `.p12` / 密码 / 证书导出文件。

## 8. 现状与后续

- 已完成（不需要证书）：安装器脚本、版本/图标/快捷方式/卸载项、per-user
  安装、存档保留策略、签名接入说明与校验步骤。
- 未完成（需要用户）：取得真实代码签名证书；决定 OV/EV 与证书保管方式；
  如走 CI，配置证书 secret 或云签名服务。
- 在证书到位前，安装器保持未签名状态是预期行为；不要用自签名证书冒充发布签名。
