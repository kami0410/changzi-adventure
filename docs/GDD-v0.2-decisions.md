# 昌子大冒险 · v0.2 决策更新（2026-10-31）

> 本文件覆盖 GDD §7、§10、§13、§17 中与以下选择冲突的内容。

## 22.1 语言：自由造句

- 每个词有 `grammar_role`（NOUN / VERB / MODIFIER）、`tags`、`power`、`corruption`、`components`。
- 合法句式：
  - `MODIFIER + NOUN`：被动/属性型（例：`grlufai + gr` = 被侵蚀的生命）。
  - `VERB + NOUN`：主动型（例：`grguan + gr` = 记录生命）。
  - `MODIFIER + VERB + NOUN`：三段型（例：`chinao + grguan + gr` = 深渊中记录生命）。
- 玩家在“造句台”任选 2–3 个词，`PhraseResolver` 实时推导效果；不是从预设列表里选。
- 效果 = 词的 `components` 合并 + 标签共鸣 + 冲突规则；`power` 决定墨耗与冷却。
- 未知词、污染词、冲突标签会增加风险/污染，但也能造出更强或更不稳定的句子。
- 8 条预设短语只作为教学/图鉴示例，不是唯一组合。
- M1 词表：4 NOUN + 4 VERB + 4 MODIFIER = 12 词，可产生数十种有效组合。
- 边界必须明确：0/1 个词、重复词、角色不匹配、未知词、冲突标签。
- 造句台在 Hub 与休息点可用；局内保存 2 个短语槽。

### 效果组件（初稿）

`damage`、`heal`、`lifesteal`、`slow`、`summon`、`shield`、`ink_gain`、`corruption_gain`、`area`、`projectile`、`duration`、`cooldown_mod`、`move_speed`。

### 冲突/共鸣示例

- `life + archive`：记录生命 → 命中回血 + 存储伤害。
- `time + abyss`：时间深渊 → 减速 + 虚空区域。
- `corruption + authority`：侵蚀权柄 → 伤害提高 + 污染增加。
- `life + abyss`：冲突 → 高伤害/高污染，标记为“不稳定”。

## 22.2 关卡：连续横版区域

- 每个生态区是一张连续横版地图，由手工 chunk 拼接；相机跟随；战斗触发锁门；有分支、秘密、休息点。
- 不是节点地图，不是每节点一间独立房。
- seed 控制 chunk 顺序、敌人刷新、掉落、商店；chunk 内部手工设计。
- M1：2 个生态区，每区 6–8 个 chunk，至少 1 个分支、1 个休息/商店、结尾 Boss 房。
- 关键接口：`BiomeAssembler.generate(seed, biome) -> BiomeLayout`；`Room.lock_until_cleared()`。

## 22.3 美术：全员完整动画

- M1 验收线：
  - 昌子：idle / run / jump / fall / dodge / hit / death / 近战三段 / 远程射击 / 施法。
  - 6 武器：每把独立攻击动画/VFX；近战三段或远程射击/蓄力。
  - 5 敌人 + 1 精英：idle / move / attack / hit / death；精英额外攻击。
  - Boss：idle / 3 攻击 / 阶段转换 / hit / death。
  - 3 NPC：idle / talk / gesture。
- 规格：角色 96×96、Boss 256×256、tile 32×32；每动作 6–10 帧；12–24 FPS；统一 pivot/调色板/轮廓光。
- 管线：Magpie 出关键姿势/概念 → Pixelorama/Aseprite 逐帧 → `create-game-assets` QA → Godot `SpriteFrames` + `AnimationPlayer`。
- 代码先用占位 `SpriteFrames` 把状态机跑通，最终 sprite 替换，不改接口。
- 详细任务见 `docs/superpowers/plans/2026-10-31-pixel-art-production.md`。

## 22.4 Hub：完整 Hub + 基底升级

- Hub 是可走动 2D 场景，M1 三个功能 NPC：
  - 陆沉：解码词、解锁句式。
  - 阿砚：永久升级武器基底（伤害、连击速度、词槽），作用于该 archetype 的所有局内掉落。
  - 咕噜：用记忆碎片买词/消耗品。
- 永久 vs 局内：
  - 永久：记忆碎片、已解锁词、武器基底等级、句式、图鉴。
  - 局内：武器实例、词条、遗物、短语；死亡丢失。
  - 织录者/守钟人 M1 先做占位/预告，M2 开放。
- Profile 存档保存永久部分；RunState 保存局内部分。

## 22.5 其他 M1 决定

- 权柄：第一区精英后掉落 1 个（4 选 1），验证第三层。
- Boss：墨骸史官；笑面史官只在结尾幻象/过场露脸，不可打。
- Android：M1 验收 = 构建 + 启动；触屏操作、性能测试放 M2。
- 美术全量动画与代码并行；代码用占位帧，最终资产替换。
