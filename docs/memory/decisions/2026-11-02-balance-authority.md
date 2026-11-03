---
name: 2026-11-02-balance-authority
description: 效果预算定价、四档难度、无上限成长，以及 AI 对 NPC 职能的有限权限
type: decision
status: accepted
updated: 2026-11-02
load_when: 改技能数值、难度、永久成长、AI NPC 行为时
---

# ADR：数值、成长与 AI 权限

## 技能定价

短语的墨耗与冷却按**实际效果预算**计算，不只看词的 power：

- 形态脉冲、弹幕数量、范围先折算成 `shape_scale`；
- 伤害/治疗/护盾/净化/减速/定身/吸血/爆炸/连锁/召唤/击退各有预算权重；
- 墨耗上限 95，冷却 0.8–9 秒；
- 未来加词、改形态倍率或加 AI 组件时必须跑 `tests/balance_audit.gd` 与
  `tests/test_balance.gd`，防止再出现“低墨耗高爆发”。

## 难度

四档：平静 / 墨雨 / 深渊 / 噩梦。难度统一通过 `Difficulty` 读取，禁止在业务代码里写
`if Flow.difficulty > 0`。敌人伤害只通过 `player.damage_taken_multiplier` 放大一次，
不要再乘敌人 contact_damage，避免双重缩放。

## 成长

永久的、无上限的成长来自两处：

1. **档案馆祭坛**：生命、墨量、言灵伤害、污染抗性四条指数成本曲线；
2. **词条熟练度**：使用真实词获得 XP，墨耗折扣与效果加成用 `level/(level+30)` 递减。

遗物仍是本局唯一、不叠层；若以后加叠层，必须走同样的递减预算测试。

## AI 权限

AI 可以在对话中直接执行 NPC 职能，但必须满足：

- 每个 NPC 有白名单，客户端 `NPCProfiles.validate_action` 校验；
- 折扣 0–0.35 钳制；免费/破例每个 NPC 每次回 Hub 仅一次；
- AI 输出只当数据，执行前仍由 Hub 结算；
- 离线推演不执行 action，保持可玩性。

## 拾取

可掉落的武器/遗物/词改成接触提示、按 E 拾取，避免走过时自动换装。
