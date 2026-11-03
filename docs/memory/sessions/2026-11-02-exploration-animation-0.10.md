---
name: exploration-animation-0.10
description: 0.10.0 探索与逐帧动画：隐藏书库/捷径验收、门扉视觉、16 帧玩家动作管线、ActorMotion 锚定与残影修复
type: session
status: active
updated: 2026-11-02
load_when: 继续打磨探索、玩家动画或改帧管线时读
---

# 0.10.0 探索与逐帧动画（2026-11-02）

## 起点

接手上一会话未完成的「探索 + 动画」：四章隐藏书库/捷径的代码与测试已写入但未验收；玩家动作帧是从概念图裁切并用 rembg 抠图，比例与风格不一致，且 `ActorMotion` 里残留调试圆点与打印。

## 探索

- 四章各有 `chN_vault` 隐藏书库（宝箱 + 记忆碑），由主路 `chN_03` 的 `door1` 进入；休息室 `door2` 为回到 `chN_02` 长廊的捷径。世界文件 `scenes/mds/chapter_N.mdsworld.json` 中的 gate 连线与 `_on_mds_room_loaded` 的 vault 分支已接通。
- 新增 `scripts/presentation/chapter_door.gd`：门扉替代原来的黑色 ColorRect，落地、带金色书本（书库）/青色箭头（捷径）纹样、脉冲内光、上浮微粒与标题；门底从悬空 22 px 修到地面。
- 进入隐藏书库首次触发金色扩散环 + `pickup` 音效，objective 改为“搜查隐藏书库”；`_discovered_vaults` 每局清空。
- 集成测试 `tests/integration_playability.gd` 265 项全绿，覆盖四章 vault 进入/返回、宝箱/记忆碑、捷径去/回。

## 动画

- 管线决策见 [逐帧动作管线 ADR](../decisions/2026-11-02-frame-animation.md)。
- 新帧：跑步 4、跳跃/下落 3、近战 3、施法 2、受击/踉跄 2、闪避 2，共 16 帧。源横条在 `assets/concept/anim/`，成品在 `assets/sprites/player/frames/`。
- 新增 `tools/slice_anim_sheet.py`：按 alpha 列间隙切帧（可合并/切分到目标数）、所有帧共用同一缩放与调色板、1 px 墨色描边、脚底基线；`--fit height` 用于挥剑这类横向很宽的帧（攻击画布 160×96）。
- `scripts/player/player.gd`：按动作状态选帧；跑步 12 fps 循环，攻击/施法/闪避按 `ActorMotion.action_progress()` 切帧，受击固定 recoil 帧，死亡切到踉跄帧后交给程序化塌缩；残影按当前纹理单独计算脚底偏移，并按 `facing` 翻转。
- `scripts/presentation/actor_motion.gd`：按每帧不透明区域重新锚定水平中心与脚底；影子宽度固定为 idle 纹理宽度，避免挥剑帧把影子拉宽；删除调试圆点/打印；新增 `action_progress()`。
- `tests/capture_anim.gd` 与 `artifacts/anim_contact.png` 用于在真实场景里检查 idle/run/attack/dodge/jump/cast/hurt/run_left。

## 验证

- `tests/run_tests.gd`：3083 项通过，0 失败。
- `tests/integration_playability.gd`：265 项通过，0 失败。
- 窗口渲染复查：`artifacts/mds/mds_04b_vault.png`、`artifacts/mds/mds_04_rest.png`、`artifacts/anim_contact.png`。
- 导出：`build/windows/changzi-adventure.exe`（含 console）、`build/android/changzi-adventure.apk`（versionCode 13 / versionName 0.10.0，Godot debug 证书，仅内部试玩）；旧 0.9.3 构建归档到 `build/archive/0.9.3/`，Windows 包为 `build/changzi-adventure-0.10.0-windows.zip`。
- 提交：游戏仓库 main 与 `fix/playability-polish` 已同步到 0.10.0 里程碑，工作室文档已提交。
- 未做：Android 实机 120 FPS 复查；正式发布前需换正式 keystore 并重签 APK。

## 已知瑕疵 / 下一步

- 生成帧衣摆和剑刃仍有少量抗锯齿噪点；受击/倒地只有两帧，可在正式版补中间帧。
- 玩家帧在暗背景上偏暗，必要时加一点青边光或提高 3–5% 亮度。
- 支线剧情、正式授权配音仍待补。
