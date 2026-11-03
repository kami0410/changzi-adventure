---
name: chapter1-demo-0.11
description: Chapter 1 demo 范围、像素-only、解码/权柄真机制、AI 可选/离线强制
type: decision
status: active
updated: 2026-11-03
load_when: 继续 Chapter 1 demo、完整版前移、或讨论像素/解码/权柄/AI 取舍时
---

# Chapter 1 demo（0.11.0-demo）决策

承接 [Chapter 1 demo 审阅与实施计划](../../superpowers/plans/2026-11-02-chapter1-demo-review-and-plan.md)。用户已拍板：

1. **只做 Chapter 1 demo**：不新增第 2–4 章流程，2–4 章代码保留但 demo 不可达。
2. **全部高精度像素**：demo 画面不出现绘画背景/动漫立绘/纯色矩形平台；角色/敌人/Boss/背景/立绘/道具/Logo/VFX 同一像素语言。
3. **解码与权柄是真机制**：词有 owned/decoded 两层；未解码可施放但 `[不稳定]` + 污染；解码跨局保存；Boss 掉续命/改写并真正生效。
4. **离线言灵必须完整可玩**：不联网、不填 key 也能造句→预览→装备→施放；AI 只是可选增强。
5. **Windows 优先**：demo 验收只要求 Windows 可启动；Android/触屏/本地化/成就/云存档是后续 P2。
6. **版本 0.11.0-demo**：1.0 只在用户确认最终完整版后使用。

相关技术约定：
- [像素美术规范](2026-11-02-art-spec.md) 的 demo 子集：≤32 色、二值 alpha、底边对齐、整数缩放。
- 共享 `WordData.decoded` 不再被运行时修改；per-run 副本由 `WordRuntime` 生成。
- Profile v2 原子写 + `.bak`；旧 v1 存档无损加载。
