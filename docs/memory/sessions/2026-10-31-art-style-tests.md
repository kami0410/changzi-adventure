---
name: 2026-10-31-art-style-tests
description: 生成昌子的像素与手绘两张美术风格测试
type: session
status: active
updated: 2026-10-31
load_when: 讨论美术方向、角色生成或资产管线时
---

# 2026-10-31：昌子美术风格测试

## 完成

- 用 Magpie（`codex/gpt-image-2`）以 `01_protagonist_changzi.jpg` 为参考，
  生成两张风格测试：
  - `assets/concept/style-tests/changzi_pixel.png`：高精度像素、多姿态。
  - `assets/concept/style-tests/changzi_painterly.png`：手绘/厚涂单幅。
- 记录提示词、模型、参考图与使用限制到同目录 `README.md`。
- 两张都保留了参考人物的眼镜、短发、黑色档案官外套、红色内衬与破碎书卷。

## 决策

- 用户选择**纯像素**；正式管线按高精度像素执行，手绘版只作概念参考。
- 详见 [ADR-0001](../decisions/2026-10-31-pixel-art.md)。

## 下一步

- 批量生成 NPC 与最终 Boss 的像素风形象。
- 写 GDD v0.1。

## 下一步

- 根据用户选择确定美术方向。
- 写 GDD v0.1：语言系统、战斗、道具层级、单局结构、垂直切片范围。
