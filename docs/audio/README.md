# 音频资产与生成管线

## 目录

- `assets/audio/music/`：6 首 OGG 循环配乐（含第四章剧场）。
- `assets/audio/voice/zh_cn/`：22 段中文旁白/剧情/Boss/结局。
- `assets/audio/*.wav`：既有程序生成 SFX（hit/attack/jump/dodge/pickup/ui_click/music_ambient）。
- `tools/generate_music.py`：numpy/scipy 合成配乐，ffmpeg 转 OGG、响度归一化。
- `tools/generate_voice.py`：调用 Windows SAPI Huihui 生成 WAV，ffmpeg 转 OGG。
- `tools/voice_lines.json`：配音文本清单（UTF-8）。

## 配乐

| 文件 | 长度 | 用途 |
|---|---|---|
| `title.ogg` | 24s | 标题界面 |
| `chapter_archive.ogg` | 32s | 第一章 / Hub |
| `chapter_breathing.ogg` | 32s | 第二章 |
| `chapter_sea.ogg` | 40s | 第三章 |
| `chapter_theater.ogg` | 36s | 第四章 笑面剧场 |
| `boss.ogg` | 24s | 四个 Boss 战 |

- 44.1kHz 立体声 OGG q4，运行时 `AudioManager` 设置 `loop = true`。
- 母带峰值约 -1 dBFS，ffmpeg `loudnorm=I=-16:TP=-1.5:LRA=11`。
- 生成脚本保留全部合成参数；可直接替换同名 OGG 换成正式作曲。

## 配音

- 22 段：陆沉任务、四章开场/章末、四个 Boss 的 2/3 阶段、五种结局。
- 22.05kHz 单声道 WAV → OGG q3；高通 85Hz、轻微 90ms 回声、响度 -18 LUFS；Boss 降调。
- 播放：`AudioManager.play_voice(id)`；`StoryOverlay`、Hub 任务、Boss 阶段、结局触发；语音期间 Music 总线 duck 到 -14dB，结束后回 -6dB。

## 重要限制

**SAPI 的 Huihui 只是原型音色。** Microsoft 对 SAPI 输出的商用再分发授权并不明确；正式商业发行前必须：

1. 换成有书面授权的真人配音；或
2. 使用明确允许商用的付费 TTS（如 Azure S0 付费层、Kokoro-82M v1.1-zh 等），并遵守其条款；
3. 在商店页面/内容调查中披露 AI 语音（如适用）；
4. 不要克隆真人声音；涉及真人声音的合成需单独同意与显著标识。

## 音量/总线

- Master → Music(-6) / SFX(-3) / UI(-4) / Voice(-2)。
- 运行时在 Master 上加 `AudioEffectHardLimiter`（ceiling -0.3）。
- 音乐/语音使用 `PROCESS_MODE_ALWAYS`，剧情暂停时继续播放。
- 当前没有做污染值驱动的动态失真层；后续可在 `AudioManager.set_music_layer` 扩展。

## 复现

```bash
python tools/generate_music.py
python tools/generate_voice.py
```

需要 Windows 中文 SAPI voice、`ffmpeg`、Python 3.10+、numpy/scipy。
