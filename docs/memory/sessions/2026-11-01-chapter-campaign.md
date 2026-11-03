---
name: chapter-campaign-0.3.0
description: 三章冒险、36词、8种法术形态、章节抉择与专属图标
type: session
status: active
updated: 2026-11-01
load_when: 继续扩充剧情、生态区、法术、Boss 或品牌资产时
---

# 0.3.0 三章冒险版

## 背景

用户反馈 0.2.0 没有明显 bug，但表现力弱、内容单薄、目标不清、流程短、没有专属图标，并补充“不同词组合差别不大、技能不够华丽、词也要丰富多样”。这轮把“能跑”升级为一条有开头、推进、选择与收束的完整单局。

## 本轮落地

- **三章主线**：墨雨档案馆 → 呼吸废墟 → 无光海；每章 2 场战斗 + 1 个 Boss + 1 块可选残碑；Hub 任务对话、章节开场字幕、章末回收与二选一。
- **三个 Boss**：墨骸史官、肺钟守卫（精英造型调色，已记录为限制）、笑面史官（新生成 256 透明立绘）。
- **36 词**：新增风暴、静默、更鼓、悲鸣、鬼眼、闪火、悬鱼、毒药、回望、引燃、记忆、规则；图鉴显示每个词改变的玩法维度。
- **8 种法术形态**：焰、连锁雷、噬血束、时渊、护写、回声、渊蚀、墨刃；判定、轨迹、持续效果和 HUD/图鉴标签均不同。
- **表现**：标题界面、专属书页之眼图标、Windows ICO/Android 启动图标、无光海背景、平台灯、章节色调/音乐音高、法术粒子与命中数字。
- **结局**：复原、焚毁档案、深渊回响、未完的注脚、记录中断；依据章末选择、污染与是否存活。
- **存档**：Profile 记录 endings、runs_completed、records_found；旧存档兼容。
- **测试**：`test_campaign`、`test_spell_identity`、`test_spell_caster` 覆盖章节、结局、法术形状与召唤；`integration_playability` 三章 53 项检查。

## 关键文件

- `scripts/core/campaign_data.gd`：章节/台词/敌人/Boss/抉择/结局。
- `scripts/game.gd`：三章编排、章节切换、残碑、结局。
- `scripts/language/spell_style.gd` + `scripts/combat/phrase_caster.gd`：法术形态与结算。
- `scripts/presentation/spell_vfx.gd`、`vortex_zone.gd`、`echo_sentinel.gd`、`burn_status.gd`：表现与持续效果。
- `scripts/ui/story_overlay.gd`、`title_screen.gd`：叙事与标题。
- `scripts/levels/memory_stele.gd`、`scenes/levels/lightless_sea.tscn`：探索与第三生态区。
- `assets/branding/icon_512.png` + `changzi.ico`、`assets/backgrounds/lightless_sea.png`、`assets/sprites/bosses/smiling_archivist.png`。

## 验收证据

- 全量：1671 passed, 0 failed。
- 三章完整流程：53 checks, 0 failures（房外/房内、两场战斗、Boss、章末剧情与选择、下一章、结局）。
- 实际 OpenGL 渲染：标题、章节开场、战斗、焰/连锁/时渊、无光海、笑面史官 Boss。
- 工作室 `check_game.ps1` 通过；Windows 107.03 MiB、Android 36.46 MiB、Windows ZIP 41.23 MiB。
- APK versionCode 3 / versionName 0.3.0 / minSdk24 / targetSdk36 / arm64；v2/v3 签名验证通过；`aapt` 显示 adaptive launcher icon。
- Windows exe 已用 `ExtractAssociatedIcon` 提取实际嵌入图标并目视确认；成品包默认 Hub 启动通过。
- 用编辑器二进制挂载成品资源包运行 `integration_playability`：54 checks, 0 failures（含“tests 未打进包”检查）。
- Android 无连接设备，真机触控与性能未验证。

## 仍未完成

独立手绘逐帧图集、更多生态区/支线、第二章 Boss 的独立造型、正式音频、Android 真机验收。三章是完整单局，但不是完整商业成品。

## 用户沟通结论

之前多轮停留在“试玩版”不是引擎限制，而是把每轮范围压得太小、优先保证可运行。0.3.0 起把表现、内容量、目标感与品牌资产当作本体交付，而不是无限后置。
