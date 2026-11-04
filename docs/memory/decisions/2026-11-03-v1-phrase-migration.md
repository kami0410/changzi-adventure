---
name: 2026-11-03-v1-phrase-migration
description: v1 已发现短语按 meanings 存储，迁移时不猜测还原，只保留原始字符串到 legacy 桶
type: decision
status: accepted
updated: 2026-11-03
load_when: 改 Profile 存档、Codex 已发现组合、存档迁移时
---

# ADR：v1 已发现短语迁移

## 背景

v1 的 `Profile.discovered_phrases` 按**词义显示名**记录组合（例如 `呓·火`）；
当前签名按**排序后的词 id** 记录（`gr,grguan|2`），由 `PhraseResolver` 生成。
两种格式之间不存在可靠映射：同一个词义可能对应多个词，别名/解码状态也会改变
显示名。按 meanings 反推词 id 会显示玩家从未施放过的组合。

## 决定

采用安全默认（用户 2026-11-03 拍板）：

1. 加载时把 `progress/discovered_phrases` 里的条目分区：
   - 匹配当前签名格式的进入 `discovered_phrases`，继续被 Codex 展示；
   - 其余原始字符串进入 `legacy_discovered_phrases`，原样保留、去重。
2. `legacy_discovered_phrases` 保存到 `progress/legacy_discovered_phrases`；
   **不展示、不参与任何玩法逻辑**，也不在后续加载时重新分类。
3. `Profile.discover_phrase()` 只接受当前格式，旧格式字符串无法再写入 active 列表。
4. 迁移是幂等的：已迁移存档重复加载/保存不会重复、不会丢数据。

当前格式判定集中在 `Profile.is_current_phrase_signature()`：
`id1,id2|count`，计数与 id 数一致，id 只允许小写字母/数字/下划线，拒绝
合成野生词 `__*`。

## 后果

- 旧存档玩家的旧组合不会在新 Codex 中出现；这是有意的，避免虚构记录。
- 原始字符串仍留在存档中，未来若要做人工映射工具/统计，数据还在。
- 新增测试 `tests/test_profile_v2.gd::_test_discovered_phrase_migration`
  覆盖纯旧档、混合档、已迁移档重复加载。
- 不要再把 meanings 用作任何跨局持久化键；显示名可以变，id 才稳定。
