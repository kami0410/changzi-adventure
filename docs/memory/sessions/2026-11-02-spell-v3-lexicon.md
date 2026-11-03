---
name: 2026-11-02-spell-v3-lexicon
description: 0.8.0 言灵 v3：13 形态、AI 组件全部真实生效、92 词、120 FPS 压测、MDS 3 房间 spike 通过
type: session
status: active
updated: 2026-11-02
load_when: 改法术/言灵/AI 意图/词库、做性能优化、决定 MDS 是否接入时
---

# 0.8.0 言灵 v3 与词库扩充

## 做了什么

- **NPC 放大回退**：按用户要求把 `npc.gd` 恢复到 0.7.0（scale 1.1、offset -48）。浮空/发糊的根因和修法写在
  [issues/2026-11-02-sprite-float-blur.md](../issues/2026-11-02-sprite-float-blur.md)，**未修**。
- **法术管线重写**（`scripts/combat/phrase_caster.gd`）：每次施放建一个 `SpellContext`（伤害、灼烧、减速、定身、击退、
  爆炸、吸血、命中回调），子弹/波/星/领域/回声都持有它，延迟命中也能吸血和上状态。
  - 新文件：`spell_context.gd`、`spell_targets.gd`（无物理的盒子命中，按帧缓存，跳过未进入房间的敌人）、
    `spell_bolt.gd`、`spell_beam.gd`、`ground_wave.gd`、`meteor_strike.gd`、`spell_domain.gd`、`spell_sequence.gd`。
  - 新形态：追踪弹幕 missile、贯光 beam、地裂 quake、坠星 meteor、领域 domain；漩涡改为会吸入。
  - 主形态之外的组件叠加次级层：projectiles→弹幕层、chain≥2→连锁层、summon→回声层、duration≥2→领域层。
  - `Enemy.apply_knockback/apply_stun`；`BurnStatus` 叠加时取强不叠节点。
- **AI**：prompt 写明 13 形态、全部组件含义与例子；`validate_intent` 共用 `SpellSynthesizer.INTENT_COMPONENTS`，透传 `vfx/feel`；
  `confidence<0.25` 深渊补完；非有限数丢弃；AI 伤害按“每发”（`spell.per_hit`）。
- **离线推演**：新概念标签、形态优先词（“火焰追踪弹”是弹幕不是喷火）、意图词（追踪/贯穿/爆炸/定身/击退/吸入/灼烧/持续）、
  中文数量词解析（“一百颗”“三连”），数量越大墨耗/冷却/污染越高；弹幕伤害 √ 均摊。
- **词库 50→92**：`tools/generate_words.py` 生成并注册到 `ContentLibrary`，检查像素字体覆盖；
  27 个旧词符号换成字体里有的；`tools/font_coverage.py` 报告全游戏缺字（还剩 25 个字符、83 处回退系统字体，见下）。
- **视觉/修复**：元素色优先（火系弹幕仍是火色）；施法印记；地裂碎石；第四章 Boss 房背景修复（`theater_backdrop.gd` 读取实时偏移）；
  HUD 底部提示上移不贴边；`capture_polish.gd` 先关章节开场。

## 验证

- 单测 **2960 通过 / 0 失败**（新增 `test_spell_v3.gd` 70 项、`test_lexicon.gd` 313 项）；集成 **135 / 0**。
- 截图：`tests/capture_spells.gd`、`capture_codex.gd`、`capture_bosses.gd`、`capture_hub.gd`（窗口模式）。
- 压测 `tests/bench_spells.gd`：96 弹 + 24 星 + 领域 + 9 光束×6 + 双向地裂 → 平均 8.55 ms、最差 13 ms（锁 120 时基线 8.30 ms）。
  过程中发现瓶颈是**绘制调用**（爆炸特效 +23 次/个）：已给每次施放限 24 火花/8 爆炸、合并伤害数字、批量绘制。
- MDS spike：`spikes/mds/run_spike.gd` 14/14，详情见 [MDS 评估](../../research/metroidvania-developer-system.md)。

## 坑

- 截图 PNG 是 RGBA，直接读经常显示空白；先转 RGB/JPEG。
- 无头测试里节点不在树中：`global_position` 读写无效，`SpellBolt` 用自己的 `at` 记录位置；`PhraseCaster` 无头时同步模拟弹道。
- 缓存的目标字典可能持有已释放的敌人：读 `"enemy"` 时先 `SpellTargets.alive()`，不要直接赋给有类型变量。
- `Vector2 + float` 是解析错误，会让依赖它的所有脚本编译失败，单测里表现为大量 “Nonexistent function new”。
- Ark Pixel 12px 缺约 114 个常用字（燃、热、然、摇、紧、愈…），游戏里出现时回退系统字体，像素风不统一。

## 未完成 / 下一步

- 用户选 MDS：接入 / 只借气氛（推荐）/ 不接入。
- 动画插件选型（Aseprite Wizard 等）安装前要问用户。
- 版本 0.8.0（code 8）已导出：Windows `build/windows/changzi-adventure.exe` 123 MiB；Android APK 52.5 MiB（arm64、INTERNET、调试签名校验通过；MDS 在包内约 1.1 MB；spikes/tools/tests 已排除）。成品包集成 136 检查 / 0 失败。
- 贴图浮空/发糊按 issues 文件分步修；第二章 Boss 需要专属 256 px 贴图（Magpie）。
- 缺字：换 Ark Pixel 16px 或补字形；或把台词里的缺字换词。
