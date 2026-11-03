# Fonts

## Fusion Pixel Font 12px Monospaced (Simplified Chinese) — 游戏内 UI 字体

- 文件：`fusion-pixel-12px-monospaced-zh_hans.ttf.woff2`
- 来源：https://github.com/TakWolf/fusion-pixel-font
- 版本：`2026.10.25`
- 许可：OFL-1.1，见 `LICENSE-fusion-pixel-font.txt`（内含 Ark Pixel / Cubic 11 / Galmuri 的许可见上游 `LICENSES/`）
- 用途：`theme.tres`、`hud_theme.tres`、`ink_theme.tres` 及世界内文字；字号只用 12/24/36/48。
- 为什么换：Ark Pixel 12px 2026.10.25 仍缺 23 个常用汉字和 ⚠/∞；上游 README 明确建议
  10/12px 先用 Fusion Pixel 过渡。Fusion Pixel 以 Ark Pixel 为基底缝合补字，风格一致。
  `python tools/font_coverage.py` 现在报告 0 缺字。
- Godot 导入：`font_data_dynamic`，抗锯齿 0、subpixel 0、系统回退 true；字体本身是像素字体，
  Godot 会自动关闭 hinting/subpixel。

## Ark Pixel Font 12px Monospaced (upstream reference)

- 文件：`ark-pixel-12px-monospaced-zh_hans.ttf`
- 来源：https://github.com/TakWolf/ark-pixel-font
- 版本：`2026.10.25`，许可 MIT（见 `LICENSE-ark-pixel-font.txt`）。
- 现在不再被主题引用，保留作为上游基线与将来回切参考；若确认不再需要可从包体删除。
