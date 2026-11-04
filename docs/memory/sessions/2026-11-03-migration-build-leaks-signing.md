# 2026-11-03 存档迁移 + 构建验证 + 测试夹具泄漏 + 签名地基（第 3 程）

## 完成

- **v1 `discovered_phrases` 迁移（清单 #4）**
  - 采用用户拍板的安全默认：不回推 meanings，只保留新格式。
  - `Profile` 新增 `legacy_discovered_phrases`；加载时把旧格式字符串从
    `progress/discovered_phrases` 分拣到 `progress/legacy_discovered_phrases`，
    原样保留、去重、不展示、不参与逻辑；重复加载/保存幂等。
  - 新格式判定 `Profile.is_current_phrase_signature()`：`id1,id2|count`，
    拒绝旧 meanings 字符串与合成野生词 `__*`；`discover_phrase()` 只收新格式。
  - 测试 `test_profile_v2.gd::_test_discovered_phrase_migration` 覆盖纯旧档、
    混合档、已迁移档重复加载；`test_flow.gd` roundtrip 改用新签名。
  - ADR：[v1 已发现短语迁移](../decisions/2026-11-03-v1-phrase-migration.md)。
- **Windows release 导出验证**
  - 命令：`godot --headless --path . --export-release "Windows Desktop" build/windows/changzi-adventure.exe`
  - 产物：131,767,792 bytes（约 125.7 MiB），PE32+ x86-64，尾部 `GDPC` 魔数确认
    PCK 已嵌入，单 exe 可分发。导出器自身退出泄漏属编辑器侧，不影响产物。
- **测试夹具退出泄漏（清单 #12）**
  - 逐文件 `--filter` 定位 5 个泄漏源：`test_ai_optional.gd`（`hub.profile`）、
    `test_ch1_plan.gd` / `test_demo_loot.gd` / `test_word_decoding.gd`（`Profile`）、
    `test_spell_v3.gd`（内联 `StubEnemy` 及其 `BurnStatus` 子节点）。
  - 补齐 `free()` 后，全量单元测试连续 10 次退出均为 0 ObjectDB / 0 resource / 0 RID。
- **Windows 发行地基（清单 #9 前置）**
  - `packaging/windows/changzi-adventure.iss`（Inno Setup 6.3+）：per-user x64、
    快捷方式、卸载项、安装后启动、不删除存档；`SignTool` / `SignedUninstaller`
    预置为注释，证书到位后启用。
  - `docs/release/windows-signing.md`：signtool SHA-256 + RFC3161 时间戳、证书
    存储/`.pfx` 两种方式、Inno 自动签名、CI secret 处理、验证命令与检查清单。
  - `packaging/windows/README.md`；`.gitignore` 增加 `*.pfx` / `*.p12` / `*.pvk`。
  - **真实代码签名证书是唯一用户侧阻塞项**；未购买、未生成自签名证书。
  - 本机为 Linux，无 Inno Setup/Wine，`.iss` 未实际编译；需 Windows 构建机做最终验证。

## 验证

- 单元 `tests/run_tests.gd`：3519 passed / 0 failed；连续 10 次运行均 0 泄漏。
- 结构集成 267 / 0；输入集成 11 / 0；run save 集成 27 / 0；手柄集成 34 / 0。
- 退出泄漏回归 `tests/check_exit_clean.sh` 10/10 clean。
- Windows release 导出成功（见上）。

## 已知遗留

- `.iss` 需在 Windows 上用 `ISCC.exe` 编译验证；release exe 需 Windows 实机启动验证。
- 代码签名等待真实证书；证书到位前安装器保持未签名。
- 1080p 实机截图、5–10 人封闭试玩仍搁置/待人工。
