# AI 言灵（可选）

## 现在的行为

- 默认**离线**：`SpellSynthesizer` 仍然先给出本地推演，游戏不依赖网络。
- 只有在语言图鉴里点 **“AI 解读”** 时，当前这句话才会发送到你配置的服务。
- AI 返回**意图**：名称、描述、形态、词义标签、可选组件；本地只做技术校验（有限数、非负、可渲染），**不再钳制数值上限**。玩家想得越夸张，AI 可以给得越强；代价由 AI 的 `ink_cost`、`cooldown`、`corruption_gain` 和“深渊污染”承担。
- AI 无法理解/`confidence` 很低时，本地把这句话当作**深渊污染**：仍然可以很强，但污染极高。
- AI 返回非法形态、空词义、非有限数值时，客户端拒绝该结果，保留离线推演。
- Hub 的五个 NPC 也可以调用 AI；AI 用角色口吻回复，并可返回 `effect` 改变 NPC 的职能（折扣、神铸、起始残页/污染、情报、信任）。未配置时使用 `NPCProfiles` 的离线回应。
- 结果不会自动装备；玩家看过预览后自己点“装备到 Q/F”。
- 密钥只保存在本机 `user://ai_config.cfg`，**不会打进 PCK/APK**。导出的游戏可以被人检查，因此共享版本应使用自建代理而不是把主密钥塞进客户端。

## 配置

游戏内：`F10`（设置）→ **AI 言灵设置**。

| 服务 | 接口地址 | 模型示例 | 说明 |
|---|---|---|---|
| Ollama（本地，默认） | `http://127.0.0.1:11434/api/chat` | `qwen2.5:7b` | 先安装 Ollama 并 `ollama pull qwen2.5:7b`；无需密钥，数据不出本机 |
| OpenAI 兼容 | `http://127.0.0.1:1234/v1/chat/completions` 或你的代理 | `local-model` / 你的模型 | LM Studio、vLLM、自建代理等；密钥可选 |
| Anthropic | `https://api.anthropic.com/v1/messages` | `claude-opus-5-5` | 需要 `x-api-key`；模型可在设置里改 |

启用后打开语言图鉴，输入一句话，点 **“AI 解读”**：
1. 先出现本地推演；
2. 状态显示“AI 正在读这句话…”；
3. 成功后显示 `[AI]` 结果，失败则保留本地结果并提示原因。

## 请求与安全

- 请求体包含固定的 system prompt（只解析意图）和玩家当前句子；句子里的 `< >` 会被替换，避免伪造标签。
- Anthropic 使用 `x-api-key` 和 `anthropic-version: 2023-06-01`；OpenAI 兼容使用 `Authorization: Bearer`；Ollama 使用本地 `/api/chat` + `format: json`。
- 输出校验：
  - 形态白名单（13 种）：`blade/flame/chain/blood/vortex/ward/sentinel/void`，0.8 新增 `missile` 追踪弹幕、`beam` 贯穿光束、`quake` 地裂冲击波、`meteor` 坠星、`domain` 随身领域；
  - 词义白名单：`SpellSynthesizer.TAG_WORDS`（0.8 新增 `earth/water/space/order/chaos/name/ink/word/silence` 等）；
  - 名称 ≤24 字、描述 ≤120 字，剥离 `< >` 与 URL；
  - 组件数值只拒绝 NaN/无穷/负数，**不设上限**，全部在战斗中真实生效（见下表）；
  - 可选 `vfx`（副色、尺寸、拖尾、环数、符文数）与 `feel`（震屏、顿帧）只做可渲染范围限制；
  - `confidence < 0.25` → 深渊补完：伤害 ≥18、范围 +0.6、污染 +20；
  - 墨耗/冷却/污染只保证非负。

## 0.8 组件 → 战斗效果

| 组件 | 实际效果 | 落地代码 |
|---|---|---|
| `damage` | 每次命中伤害（AI 意图按“每发”结算，弹幕不再均摊） | `SpellContext.strike` |
| `projectiles` | 真的发射这么多枚 `SpellBolt`（单次上限 96 枚实体，伤害不设限）；主形态不是弹幕时叠加一层弹幕 | `PhraseCaster._cast_missiles` |
| `pulses` | 整个法术按 0.14 秒间隔重复释放 | `PhraseCaster._repeat` / `SpellBeam.pulses` |
| `spread` | 扇面角度（弧度）：弹幕/光束/火焰的张角；≥0.75π 时地裂双向 | 各形态 |
| `duration` | 延长领域/漩涡/回声/护盾/灼烧/减速 | `SpellContext.extra_duration` |
| `burn` | 每 0.6 秒灼烧伤害，持续时间随 `duration` | `BurnStatus` |
| `chain` | 连锁跳跃次数；弹幕命中后也会跳 | `_cast_chain` / `SpellBolt._jump_from` |
| `homing` | 追踪强度；弹幕分摊到不同目标 | `SpellBolt._steer` |
| `pierce` | 穿透敌人数（每穿一个伤害 ×0.85） | `SpellBolt` |
| `explosion` | 命中溅射半径（1 ≈ 60 px） | `SpellContext.explode` |
| `stun` | 定身秒数（重型敌人按血量缩短） | `Enemy.apply_stun` |
| `knockback` | 击退力度（速度上限 1600 px/s） | `Enemy.apply_knockback` |
| `pull` | 漩涡/领域把敌人吸向中心 | `SpellDomain` |
| `summon` | 召唤回声数量（上限 6），回声发射追踪弹 | `EchoSentinel` |
| `shield/heal/lifesteal/move_speed/ink_gain/corruption_gain` | 自身护盾/治疗/吸血/加速/回墨/污染 | `PhraseCaster` |

离线输入同样生效：句子里的“追踪/贯穿/爆炸/定身/击退/吸入/灼烧/持续”等词和“一百颗”“三连”这类数量词会变成上面的组件；说得越大，墨耗、冷却和污染越高。
- NPC 输出：`reply` 不超过 240 字；`mood` 白名单；`effect` 只应用已知键，数值有限即可，不设上限。
- 超时、HTTP 错误、网络失败、AI 正在处理上一句时，都不会阻塞游戏；UI 保留本地结果。
- 请求失败不会重试；当前是单次可选的升级，不做后台轮询。
- 同一句在当前会话内缓存，不重复发送。

## 当前限制

- 本次开发环境没有 Ollama、没有可用的 API key，因此**没有做真实联网调用**；协议构造、响应解析、校验、配置读写、编译路径、NPC 回复解析都有单元测试（`tests/test_ai.gd`、`tests/test_npc_inspiration.gd`、`tests/test_freeform_synthesis.gd`）。
- NPC AI 与技能 AI 共用同一 `HTTPRequest`；一次只能处理一句，UI 会显示等待状态。
- Anthropic 端的真实模型行为/费用需由你用自己的密钥验证；游戏默认不启用 AI。
- 没有做内容审核服务、代理限流、账号计费；共享版本请使用自建代理、短期 token、额度限制与必要的 Moderation。
- 没有把 AI 结果写入 Profile 的“已发现组合”历史；当前只在本局内使用，避免把不可复现的 AI 文本永久保存。

## 下一步

- 可选的 `SkillCompiler` 独立化、prompt/schema 版本号、意图缓存落盘。
- 代理端做限流/审核/计费；客户端只拿短期 token。
- 预生成常见句意图包，完全离线时也有更丰富的命名与描述。
