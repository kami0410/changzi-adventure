# 2026-11-03 退出泄漏 + 存档恢复 + 截图（第 2 程）

## 完成

- **退出音频泄漏（清单 #3）**
  - 根因：`--quit-after` 强制退出时，音乐 `chapter_archive.ogg` 与语音 `ch1_intro.ogg` 的
    `AudioStreamPlaybackOggVorbis` / `OggPacketSequencePlayback` / `AudioStreamOggVorbis` /
    `OggPacketSequence` 仍被音频线程引用，引擎清理后报 8 ObjectDB + 4 resources。
  - 修法：`AudioManager.shutdown(settle_msec := 0)` 先停止全部 player，给混音线程
    `settle_msec` 毫秒结算，再释放流与 player；`_exit_tree()` 使用 `shutdown(100)`。
    游戏场景不再在 `_exit_tree` 抢先 `shutdown()`（双重停止会加大竞态）。
  - 验证：`res://scenes/main.tscn --quit-after 400` 修复前约 3/10 泄漏；修复后 30/30 干净。
    `tests/check_exit_clean.sh <godot> [runs]` 可重复验收。
  - 诊断工具：`tests/probe_exit_audio.gd` 支持 `--mode=scene-exit|shutdown|shutdown-wait|stop-wait`。
- **存档 `.bak` 恢复（清单 #5）**
  - 新增 Profile v2 测试：主文件缺失 + 备份存在、主文件损坏 + 备份存在、两者皆无。
  - 修复真实缺陷：`ConfigFile.load()` 失败后复用同一实例再加载 `.bak` 仍会失败；
    `Profile.load_profile` / `RunSave.read` 改为每次尝试使用全新 `ConfigFile`，
    且 `RunSave` 在校验失败时先尝试 `.bak`，两者都无效才清理文件，避免把仅存的备份一起删掉。
- **缺失截图（清单 #6 不需真人部分）**
  - 纯 `--headless` 是 dummy 渲染器，无法截取画面；改用 `xvfb-run` + `--rendering-driver opengl3`
    （Mesa llvmpipe）离屏渲染。
  - `tests/capture_authority_ending.gd` 产出权柄二选一与章末结束屏，1280×720 / 2560×1440
    均验证非空且内容正确，输出到 `artifacts/screens/`（gitignore）。
  - 权柄面板会暂停 SceneTree，暂停时离屏渲染不更新帧（全黑）；截图前临时 `paused = false`。
  - 1920×1080 在 `stretch/scale_mode=integer` 下实际回落到 1280×720，1080p 实机截图仍需人工。
- **Windows 导出链路**
  - 本机 `~/.local/share/godot/export_templates/4.7.stable/` 完整；`--export-debug "Windows Desktop"`
    成功产出 125.7 MB PE32+ x86-64（embedded PCK），`build/` 未提交。
  - 导出器自身退出有 ObjectDB 泄漏（编辑器侧），与游戏运行无关；本机无 Wine，exe 运行验证待 Windows。

## 验证

- 单元 `tests/run_tests.gd`：3501 passed / 0 failed。
- 结构集成 267 / 0；输入集成 11 / 0；run save 集成 27 / 0；手柄集成 34 / 0。
- 退出泄漏回归：`tests/check_exit_clean.sh` 10/10 clean。

## 已知遗留

- v1 旧存档 `discovered_phrases` 迁移仍待用户拍板（清单 #4，本程未动）。
- `tests/run_tests.gd` 自身退出仍报 12 ObjectDB / 3 resource / 2 RID（测试夹具，非游戏运行）。
- 1080p 实机截图、5–10 人封闭试玩仍待人工。
