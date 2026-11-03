---
name: 2026-11-01-final-playable
description: 完成可玩版：Hub、第二生态区、短语/权柄、像素资产、触屏、音频、双平台包
type: session
status: active
updated: 2026-11-01
load_when: 回顾可玩版内容、构建结果或下一轮迭代时
---

# 2026-11-01：可玩版出包

## 完成

- **Hub**：可走动「最后的档案馆」，陆沉（解码）、阿砚（武器基底升级）、咕噜（商店）、传送门；Profile 通过 `Flow` 全局共享。
- **流程**：Hub → 传送门 → 墨雨档案馆（2 房）→ 呼吸废墟（2 房）→ 墨骸史官 → 结算屏 → R 回 Hub；死亡也可回 Hub 并保留记忆碎片。
- **战斗/构筑**：
  - 2 武器槽（1/2 切换）、2 短语槽（Q/F 释放）、翻滚、跳跃、墨量。
  - 自由造句解析器 + 造句台选词/预览/装备。
  - 4 权柄；M1 掉落“续命”，死亡时自动触发一次。
  - 敌人掉落武器/词/遗物，拾取即时进入构筑。
- **内容**：24 词、16 短语、8 遗物、12 武器、10 敌人、2 生态区、1 Boss。
- **UI/表现**：HUD、背包、图鉴/造句台、暂停、设置、结算；中文像素字体；静态像素角色/敌人/Boss/NPC/背景；生成式 SFX + 16 秒循环环境音乐。
- **移动端**：触屏移动/攻击/跳跃/翻滚/交互/短语 1-2；F10 设置。
- **验证**：`1445 passed, 0 failed`；Hub 与单局场景无头运行无脚本错误；Windows/Android 导出成功。
- **产物**：
  - Windows `build/windows/changzi-adventure.exe`（105 MB）。
  - Android `build/android/changzi-adventure.apk`（34 MB，debug 签名，targetSdk 36）。
  - UI 截图：`artifacts/hub_art.png`、`run_art.png` 等（git 忽略）。

## 仍未完成

- 逐帧像素动画：当前主角/敌人/Boss/NPC 是静态单帧 + 翻转/闪白/位移；没有 SpriteFrames 动画。
- 遗物 `effect_id` 仍是语义占位，没有实际战斗效果。
- 只有 2 生态区 / 1 Boss；GDD 目标中的 4 生态区、3 主 Boss + 最终 Boss、多结局尚未实现。
- Android 只验证构建/签名，没有真机安装与触屏手感验证。
- 音频为程序生成占位，不是正式配乐/音效设计。
- 商店/升级 UI 为功能级，未做完整美术包装。

## 下一步

1. 用户试玩，按反馈修 bug 与手感。
2. 逐帧像素动画与武器动作/VFX。
3. 遗物效果、更多权柄联动。
4. 第三/第四生态区、更多 Boss 与多结局。
5. Android 真机测试、AAB/release keystore、正式音频。
