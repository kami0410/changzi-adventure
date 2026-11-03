# 自由技能、动作演出与音频调研（2026-11-01）

> 目的：为《昌子大冒险》从“固定语法造句”升级为“言出法随”，并加强动画、配乐与配音。以下是对四路并行调研的整理，以及本项目实际采用/暂缓的决策。

## 1. 自由组合技能

### 结论

自由组合不能靠“无限语法”，而要靠：

1. **少量正交轴**：形态、元素、行为、目标、尺度；每个词只改 1–2 轴。
2. **任意输入必出结果**：未识别词变成“杂音/未名之词”，弱、贵、不稳，但不报错、不空放。
3. **复杂度收费**：词数增加时，墨耗/冷却超线性上升，收益次线性；甜点 3–4 词。
4. **同类递减与硬上限**：重复词 ×0.55，伤害/范围/持续/数量有 cap。
5. **稀疏共鸣**：手写少量无序对（雷火、时焰、血护、渊召），不写全组合表。
6. **词序不阻断**：词序只影响名称/主词/表现，不产生“语法错误”。
7. **可读预览**：施法前显示形态、数值、稳定度、共鸣与风险。
8. **AI 只解析意图，规则引擎结算**：LLM 不直接给数值；本地编译器独占数值与上限。

### 参考与教训

- **Noita**：修饰符挂下一法术 + 法力/充能收费；无限递归会导致数值爆炸与 wiki 依赖。
- **Magicka**：5 格队列、相克抵消、相容融合；顺序说法不透明、误伤/过强组合。
- **Scribblenauts**：名词 + 属性标签，形容词改标签；词库缺口与属性漏标会破坏可信度。
- **TotK Fuse**：材料属性叠加，但拒绝不可推演的新产物；菜单摩擦是代价。
- **Hades Duo**：稀疏手写共鸣 + 前置条件；不可无限扩展。
- **Risk of Rain 2**：proc 系数、每链每物品一次、终局 0 proc、堆叠曲线，防止指数。
- **Mages of Mystralia**：形态 + 元素 + 行为/修饰/触发，修饰只作用相邻符文。

### 本项目采用

- `PhraseResolver`：1–4 词任意组合，不看词性/顺序；重复词递减并增加污染；词数增加墨耗/冷却、降低稳定度；`SpellStyle` 按标签决定 8 种形态；`resonances` 显示共鸣。
- `SpellSynthesizer`：自由文本先匹配已拥有词的词义/ID/符文/读音；无匹配则生成确定性的“未名之词”（哈希决定标签/伤害）；`remote_provider` 预留给 AI，返回值经过白名单与钳制。
- `ResolvedPhrase`：记录 `word_count`、`stability`、`resonances`、`from_text`，供 UI 与存档。
- UI：图鉴显示“言灵”、形态、稳定度、词条；自由输入框“言出法随”；未识别句子仍然可装备。

### 暂缓

- 完整的“主词/目标/就近挂接”解析器：当前用标签优先级 + 无序组合，已经能保证任意输入有结果；等词库更大再做。
- AI 运行时生成：先做离线确定性版本；接口与风险见 [AI 技能钩子](../ai-skill-hook.md)。

## 2. 动作与演出

### 关键参数（60fps）

- 前摇：玩家轻 2–4f、重 8–14f；敌人 18–36f；Boss 30–54f。
- 后摇：6–24f，重击可到 40f，但保留冲刺取消。
- 顿帧：轻 2–3f、重 5–6f、击杀 8–12f。
- 震屏：1–6px、方向性、0.1–0.25s，像素游戏旋转最好为 0。
- 相机前瞻：32–64px，lerp 4–8/s。
- 击退：120–300px/s，0.1–0.2s 衰减。
- Boss 登场 ≤4s；阶段转换 1.5–2.5s；死亡 1.5–3s，可跳过重复演出。

### 采用

- `ScreenFX`：命中/阶段闪白、Boss 登场 letterbox。
- `HitStop`：Boss 阶段 0.07s、重击/近战命中 0.035s，使用真实时间计时。
- `ActorMotion`：新增 cast 姿态；跑步腿交替、跳落挤压、受击、死亡已有。
- `Player`：翻滚残影（4 个渐隐 ghost）、施法残影、相机前瞻、trauma² 震屏。
- `PhraseCaster`：每次施法在玩家位置生成法术色环。
- `CombatFX`/`SpellVFX`：焰、雷、时渊、护盾、召唤、渊蚀等独立轨迹。

### 暂缓

- 独立手绘逐帧图集（必须逐帧的部分：前摇/接触/倒地/Boss 亮相）。
- 披风/头发 Verlet 次级运动、受击方向性硬直、Boss 死亡慢放全流程。
- 屏幕暗角 shader、可调震屏强度选项；当前先保证不晕动、不过度闪屏。

## 3. 音频与配音

### 结论

- 本机 SAPI 有 `Microsoft Huihui Desktop`（zh-CN），可生成 22.05kHz 单声道 WAV；适合原型，不适合作为商用最终配音。SAPI 的商用再分发授权不明确；正式发行应换真人或付费 TTS（Azure S0、Kokoro-82M v1.1-zh 等），并在商店披露 AI 语音。
- 程序化音乐可用 numpy 合成：drone、失谐 pad、FM 钟、噪声打击，OGG q4 循环；母带峰值约 -1 dBFS，音乐约 -16 LUFS，语音约 -18 LUFS。
- 格式：音乐/语音 OGG，SFX WAV PCM16；循环用 OGG import Loop 或 WAV Forward；Android 同用 OGG。
- 总线：Master → Music/SFX/UI/Voice；Master 加 HardLimiter；语音时音乐 duck -8dB。

### 采用

- `tools/generate_music.py`：生成 title、chapter_archive、chapter_breathing、chapter_sea、boss 五首循环 OGG（约 1.6MB）。
- `tools/generate_voice.py`：用 Huihui 生成 18 段剧情/Boss/结局中文旁白（约 0.9MB），ffmpeg 做高通、轻微回声、响度归一化；Boss 音色降调。
- `AudioManager`：Music/Voice 播放器、OGG 循环、淡入淡出、语音 duck、运行时创建 Voice 总线与 Master limiter；`PROCESS_MODE_ALWAYS` 保证剧情暂停时音乐/配音继续。
- `StoryOverlay`/`Hub`/`Game`：章节开场/章末/任务/Boss 阶段/结局触发对应旁白；三章/Boss 切换音乐。

### 风险

- SAPI 机械音与商用授权：正式版必须替换；当前只在原型/试玩包使用。
- 程序化音乐有 demo 感、循环接缝可能轻微；后续可由作曲/音效设计替换同名 OGG。
- 未做自适应分层（探索/战斗/Boss 仅切曲），未做污染值驱动的失真层。

## 4. AI 技能生成的架构

### 结论

LLM 只产 `SkillIntent`（模板/元素/标签/状态/名称/描述/置信度），**数字由本地编译器重算**；离线本地解析永远先返回，远端只做异步升级；客户端不内置密钥；输出严格白名单/枚举/长度/数值钳制；失败静默回退。

### 本项目现状

- `SpellSynthesizer.remote_provider` 是可选的 `Callable`，默认不设置，完全离线。
- 远端返回字典后，`_from_payload` 只接受：
  - 形态白名单：blade/flame/chain/blood/vortex/ward/sentinel/void；
  - 伤害 1–40、墨耗 4–40、冷却 1–6、污染 0–20、治疗/护盾/减速/范围有上限；
  - 名称/描述当纯文本，不执行、不加载资源。
- 未来接入 HTTP 时，建议走自建代理 + 短期 token + 超时/重试/缓存；不要把 key 放进 PCK/APK。

### 参考

- Godot JSON/HashingContext/HTTPRequest 文档；OWASP LLM01/LLM05/LLM10；OpenAI/Anthropic 结构化输出与 prompt caching；Steam AI 内容披露；中国《深度合成规定》与声音权益相关说明。

## 5. 主要来源

- Noita wand mechanics: https://noita.wiki.gg/wiki/Advanced_Guide:_Wand_Mechanics
- Magicka spell combinations: https://magicka.fandom.com/wiki/Spell_combinations
- Scribblenauts/Objectnaut 讨论: https://monkeyslunch.com/articles/favourite-mechanics-modular-tags/
- TotK Fuse GDC/CEDEC 报道: https://www.shacknews.com/article/139210/zelda-totk-gdc-2024-panel-recap
- Hades Duo Boons: https://hades.fandom.com/wiki/Duo_Boons
- Risk of Rain 2 proc coefficient: https://riskofrain2.wiki.gg/wiki/Proc_Coefficient
- Dead Cells weapon feedback: https://www.gamedeveloper.com/design/designing-each-of-the-50-weapons-in-i-dead-cells-i-to-feel-distinctive
- Celeste feel talk: https://www.youtube.com/watch?v=yorTG9at90g
- Godot Camera2D: https://docs.godotengine.org/en/stable/classes/class_camera2d.html
- Godot audio import: https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_audio_samples.html
- System.Speech SetOutputToWaveFile: https://learn.microsoft.com/en-us/dotnet/api/system.speech.synthesis.speechsynthesizer.setoutputtowavefile
- ffmpeg loudnorm: https://ffmpeg.org/ffmpeg-filters.html#loudnorm
- OWASP LLM01: https://genai.owasp.org/llmrisk/llm01-prompt-injection/
- Godot JSON: https://docs.godotengine.org/en/stable/classes/class_json.html

> 调研由四个并行子代理完成，主控筛选并落地；具体实现与验收见 [0.4.0 试玩说明](../playtest-0.4.0.md) 和阶段记忆。
