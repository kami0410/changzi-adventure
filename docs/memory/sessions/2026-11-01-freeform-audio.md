---
name: freeform-audio-0.4.0
description: 取消语法、自由言灵、8形态、配乐配音、残影与调研结论
type: session
status: active
updated: 2026-11-01
load_when: 继续做自由技能、AI解析、动画演出、音频或下一轮内容时
---

# 0.4.0 言出法随 · 有声版

## 用户要求

“必须符合语法太拉了，我们的技能组应该没有语法，甚至可以言出法随；后续甚至可以通过接入 AI 分析自己创造技能。整个游戏的动画还需要进一步加强。配音也是，需要谱曲。详细搜寻制作这种游戏的经验，多多调查，能并行子代理就加速。”

## 决策

- **取消语法**：`PhraseResolver` 只校验 1–4 个词/空词；任意词性/顺序；重复词 ×0.55 并 +污染；词数增加 → 墨耗/冷却上升、稳定度下降。
- **自由言灵**：`SpellSynthesizer` 离线匹配已知词（词义/ID/符文/读音），无匹配则确定性生成“未名之词”；`remote_provider` 是未来 AI 钩子，返回值经形态白名单与数值钳制。
- **稀疏共鸣**：雷火、时焰、血护、渊召、生命·记录、时间·深渊、污染·权柄、生命·深渊；不做全组合表。
- **8 形态**：焰/连锁雷/噬血束/时渊/护写/回声/渊蚀/墨刃；单字也能按标签成型。
- **音频**：五首原创程序化循环配乐 + 18 段 SAPI 中文旁白；音频 Autoload 常驻，剧情暂停时继续；语音 duck 音乐。SAPI 仅原型，正式发行替换。
- **动画**：cast 姿态、施法色环、翻滚/施法残影、相机前瞻、闪屏、Boss 登场 letterbox、近战命中顿帧。
- **调研**：四个并行子代理分别研究自由组合、动作演出、音频、AI 架构；结论整理在 `docs/research/2026-11-01-freeform-action-audio.md`。

## 关键文件

- `scripts/language/phrase_resolver.gd`、`spell_style.gd`、`spell_synthesizer.gd`、`resolved_phrase.gd`
- `scripts/ui/codex_ui.gd`（自由输入框/1–4 词/稳定度/形态）
- `scripts/audio/audio_manager.gd`、`tools/generate_music.py`、`tools/generate_voice.py`
- `scripts/presentation/screen_fx.gd`、`player.gd`、`actor_motion.gd`
- `docs/ai-skill-hook.md`、`docs/audio/README.md`、`docs/research/2026-11-01-freeform-action-audio.md`

## 验收

- 全量：1702 passed, 0 failed。
- 集成：55 checks, 0 failures；章节音乐在剧情暂停时 `playing=true`，配音 `playing=true`。
- 成品资源包：56 checks, 0 failures（含 tests 未打包检查）；Windows 启动冒烟无警告；APK versionCode 4 / 0.4.0 / arm64 / 图标与 v2+v3 签名通过。
- 包体：Windows 109.5 MiB、Windows ZIP 43.49 MiB、Android 38.76 MiB（含 1.6MB 配乐 + 0.9MB 配音）。
- `test_audio`：Voice 总线、OGG 资源、播放器创建；`test_freeform_synthesis`：已知句/未知句/混合共鸣/AI 钳制。
- 实际渲染：自由言灵界面、1 言推演、连锁雷/时渊、无光海、标题。

## 已知限制

- 配音是 SAPI Huihui 原型，机械音；商用授权不明确，必须替换。
- 配乐为程序化合成，有 demo 感；可替换同名 OGG。
- 自由文本匹配是词义/ID/符文/读音的最长匹配，尚未做真正分词/LLM；AI 钩子只做了钳制入口。
- 动作仍非独立手绘逐帧；Boss 2 仍复用精英造型。
- Android 未真机验证。
- 音频/特效在退出时仍有少量 ObjectDB/resource 警告（测试/场景立即退出导致），不影响运行。
