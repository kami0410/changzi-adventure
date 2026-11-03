# 昌子 · 美术风格测试（2026-10-31）

## 文件

| 文件 | 方向 | 用途 |
|---|---|---|
| `changzi_pixel.png` | 高精度像素 / 多姿态概念 | 评估像素角色与动作剪影 |
| `changzi_painterly.png` | 手绘/厚涂 2D | 评估整体氛围与插画质感 |

## 生成信息

- 工具：Magpie MCP（`mcp__magpie-image__generate_image`）
- 模型：`codex/gpt-image-2`
- 参考图：`../../references/01_protagonist_changzi.jpg`
- 日期：2026-10-31

## 提示词摘要

- 像素版：full-body 2D side-scrolling character concept, cosmic historian Changzi, black archivist coat with dark red trim, glasses, fractured glowing codex, high-detail pixel art, limited palette (midnight blue / sickly cyan / bone white / blood red), eldritch glyphs, dark archive ruins, clean silhouette, no text/UI.
- 手绘版：same character and costume, hand-painted gothic 2D illustration, cinematic rim light, deep midnight blue and eldritch green, ink corruption, floating glyphs, broken apocalyptic archive, detailed fabric, atmospheric cosmic horror, no text/UI.

## 使用说明

- 这两张是**风格测试**，不是最终资产；像素版不是可直接切图的 sprite sheet。
- 基于真人参考做了风格化处理；对外发布前确认肖像使用授权，最终游戏使用原创风格化角色。
- 选定方向后，用同一套 prompt 模板批量生成 NPC 与 Boss，并记录到资产 manifest。
