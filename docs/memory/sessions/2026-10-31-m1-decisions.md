---
name: 2026-10-31-m1-decisions
description: 确认 M1 的四个高风险设计选择
type: session
status: active
updated: 2026-10-31
load_when: 实现语言、关卡、动画或 Hub 时
---

# 2026-10-31：M1 四个关键决策

Builder check 提出 7 个会改变实现的问题，其中 4 个由用户拍板：

1. **语言：自由造句**。玩家任选 2–3 个词，按句式/标签/components 实时推导效果；8 条预设只作教学示例。
2. **关卡：连续横版区域 + 房间**。手工 chunk 拼接、相机跟随、战斗锁门、分支/秘密；不是节点地图。
3. **美术：全员完整动画**。昌子 12 组动作、6 武器独立攻击、5 敌人 + 精英、Boss 7 组动作、3 NPC。
4. **Hub：完整 Hub + 基底升级**。可走动 Hub；陆沉/阿砚/咕噜三个功能 NPC；永久升级武器基底，局内掉落词条；profile 存档。

另外 3 个由主控按 M1 范围决定：

- 权柄：第一区精英后 4 选 1，验证第三层。
- Boss：墨骸史官；笑面史官只做结尾过场。
- Android：M1 只验收构建 + 启动；触屏放 M2。

## 影响

- 代码计划需要 `PhraseResolver`、`BiomeAssembler`、`SentenceForgeUI`、完整 Hub/Profile 字段。
- 美术是最大工作量，单独建 `2026-10-31-pixel-art-production.md`；代码先用占位 SpriteFrames。
- 详细决策见 `docs/GDD-v0.2-decisions.md`。
