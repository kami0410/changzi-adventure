---
name: 2026-10-31-m1-integration
description: 合并四模块、接入主场景与 UI、完成 M1 可玩切片和双平台导出
type: session
status: active
updated: 2026-10-31
load_when: 回顾 M1 状态、UI 集成或导出结果时
---

# 2026-10-31：M1 可玩切片

## 完成

- 4 个并行 worktree 全部合并：weapons、enemies、ui、levels。
- 主场景接入连续关卡 `biome_1`、玩家、房间敌人、墨骸史官 Boss、HUD/背包/暂停/图鉴。
- 武器接到玩家输入：2 槽、1/2 切换、J 攻击、L 翻滚、Space 跳跃。
- 中文像素字体 Ark Pixel 12px（MIT）接入 `resources/ui/theme.tres`，关闭抗锯齿/子像素定位。
- Boss 血条改为接近 Boss 房才显示；背包/图鉴用 Tab/C 开关，不叠加暂停菜单。
- 导出：
  - Windows `build/windows/changzi-adventure.exe`（约 101 MB），无头启动通过。
  - Android `build/android/changzi-adventure.apk`（约 30 MB），签名通过；包名
    `com.gamecreatestudio.changzi_adventure`，targetSdk 36，minSdk 24。
- 测试：主分支 **469 passed, 0 failed**。
- UI 实机截图：`artifacts/ui_main_final.png`、`ui_inventory.png`、`ui_codex.png`、`ui_pause.png`（已 git 忽略）。

## 已知缺口

- 正式像素动画尚未生产：当前角色/敌人/Boss 是几何占位；美术计划在
  `docs/superpowers/plans/2026-10-31-pixel-art-production.md`。
- Hub 场景尚未搭建；Hub 的对话/商店/Profile 逻辑已存在。
- 只做了 1 个生态区、2 个战斗房、1 个 Boss；正式版需要更多内容。
- Android 只验证构建与签名，没有真机安装/触屏操作。
- 音频只有总线与占位管理器，没有正式素材。
- 背包/图鉴打开时不暂停游戏；正式版需要设计更好的暂停/叠加规则。

## 下一步

1. 像素动画生产：主角、6 武器、5 敌人 + 精英、Boss、3 NPC。
2. Hub 场景 + 陆沉/阿砚/咕噜功能 UI。
3. 第二生态区、更多词/短语/武器、完整单局循环。
4. 真机 Android 测试、性能与触屏。
5. 音频素材、商店素材、发布流程。
