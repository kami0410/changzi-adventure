---
name: 2026-11-02-growth-difficulty-0.9.3
description: 0.9.3 数值定价、四档难度、档案馆/词条熟练度成长、AI NPC 权限、E 拾取
type: session
status: active
updated: 2026-11-02
load_when: 改技能数值/难度/永久成长/AI NPC 行为/拾取时
---

# 0.9.3 数值与成长

用户选择“数值 + 成长”，同时追加：拾取按 E、四档难度、技能伤害协调、
AI 对话要能真正改变 NPC 的职能（例如讨价还价）。

## 拾取

- `Pickup` 不再一碰就收：接触只点亮 `E 拾取 · 名称`，玩家按 E 才收。
- `Game._try_pickup_nearest()` 在交互链路里排在商店/宝箱之后、残碑之前；
  武器交换仍然会把旧武器掉在身后。

## 难度

- 新增 [Difficulty](../../../scripts/core/difficulty.gd)：`平静 / 墨雨 / 深渊 / 噩梦` 四档。
  - 敌人生命 ×1.0/1.25/1.5/1.85；
  - 敌人伤害 ×1.0/1.15/1.3/1.5（通过 `player.damage_taken_multiplier` 统一结算，避免和敌人数据重复乘算）；
  - 残页/碎片收益 ×1.0/1.15/1.3/1.6；
  - 污染获取 ×1.0/1.0/1.15/1.3。
- 标题界面改为难度下拉 + 当前难度说明；HUD 区域标题显示“区域 · 难度”。
- 章节/奖励/击杀/结局奖励全部走难度倍率。

## 数值定价

- `PhraseResolver` 的墨耗/冷却改由**实际效果预算**决定：
  - 形态脉冲数、弹幕数量、范围计入 `shape_scale`；
  - 伤害、治疗、护盾、净化、减速、定身、吸血、爆炸、连锁、召唤、击退各有预算权重；
  - 墨耗公式 `(6 + power*1.4 + budget*0.9) * complexity`，上限 95；
  - 冷却 `(1.2 + power*0.12 + budget*0.075) * complexity`，范围 0.8–9 秒。
- 200k 随机组合审计（`tests/balance_audit.gd`）：最高伤害组件 22、最高伤害/墨 0.421、
  墨耗 [8, 77]、冷却 [1.33, 6.38]；`tests/test_balance.gd` 以 30k 样本做回归阈值。
- 组合预览（Codex）仍显示实际墨耗/冷却。

## 永久成长

- **档案馆祭坛**（`ArchiveUI`，陆沉服务「档案馆升级」打开）：
  - 生命上限每级 +10、墨量每级 +5、言灵伤害每级 +4%、污染抗性每级降低获取；
  - 成本指数上涨、等级无上限；`Profile.archive_levels` 持久化；开局由 `Game._apply_archive_upgrades()` 应用。
- **词条熟练度**：
  - 每次成功施放，短语里的真实词获得 1 XP；每 5 XP 一级；
  - 墨耗折扣与效果加成都用 `level/(level+30)` 递减、无上限；
  - `Profile.word_mastery` 持久化；Codex 词条会显示“熟练 Lv.N”；
  - 借用概念/野生词不计熟练度。

## AI 对 NPC 的权限

- AI 返回新增可选 `action`：`{id, discount 0..0.35, free}`；
- `NPCProfiles` 为每个 NPC 白名单：陆沉 lore/decode、阿砚 forge/forge_god、咕噜 shop/rumor、
  闻烬 intel/contract、白榆 map/shortcut；
- `NPCProfiles.validate_action` 只接受白名单，折扣钳制；`Hub._apply_ai_action` **每个 NPC
  每次回 Hub 只能破例一次**：
  - 咕噜：可给临期商店折扣并直接打开货架（讨价还价）；
  - 阿砚：直接锻造/免费神铸；
  - 其他：免费或折扣执行对应职能。
- AI 输出仍是数据，客户端校验后才执行；离线推演不变。

## 验证

- 单测 **3083/0**；集成 **229/0**；`check_game.ps1` 通过。
- 截图：`artifacts/ui/01_title.png`（难度下拉）、`05b_archive.png`（档案馆升级页）。
- 数值审计：`tests/balance_audit.gd -- --samples=200000`。
- 版本 0.9.3，versionCode 12；Windows release 135.5 MiB、Android debug 58.9 MiB（debug 签名）。

## 待办

- 遗物叠层/重复遗物升级尚未实现（成长目前是档案馆 + 词条熟练度）。
- AI action 需要真实 AI provider 才能实际走通，当前有白名单/解析/折扣单测。
- 难度目前只影响敌人生命/伤害、收益、污染；尚未做“梦魇专属词条/敌人变体”。
