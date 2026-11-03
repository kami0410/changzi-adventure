---
name: 2026-11-01-handoff-mds-ai
description: 新对话交接：MDS 已安装并启用、Room→ArenaRoom、NPC 放大未验收；下一步 AI 言灵权限/词库/动画插件/MDS 主线评估
metadata:
  type: project
---

# 交接：MDS 安装后的下一步

日期：2026-11-01
状态：0.7.0 世界与同行者版 + MDS 编辑器插件已安装；未提交 git。

## 当前已验证

- 0.7.0：14 种敌人、程序化骨骼动画、CombatFX/SpellVFX、五 NPC AI 言灵、剧情圣经、120 FPS、键位/操作说明、每章两座宝箱。
- MDS 3.2.0（MIT，Godot 4.6+，测试过 4.7.2）已下载并安装到：
  `addons/MetroidvaniaDeveloperSystem/`（351 个文件，约 2.2 MB；未安装可选 asset_packs）。
- `project.godot` 已启用：
  `enabled=PackedStringArray("res://addons/MetroidvaniaDeveloperSystem/plugin.cfg")`
- **关键冲突已解决**：MDS 自带全局类 `Room`，与项目的 `scripts/levels/room.gd` 冲突。
  已将项目类重命名为 `ArenaRoom`，更新了 `game.gd`、`summoner_enemy.gd`、测试。**不要再改回 `Room`**，否则 MDS 编辑器插件会大量解析失败。
- 重命名后全量测试：**2115 通过，0 失败**；集成测试：**135 检查通过**。
- `--headless --editor --path . --quit` 已能加载 MDS，无解析错误。
- 下载源包在 `tools/downloads/mds/MetroidvaniaDeveloperSystem-3.2.0.zip`；解压在 `tools/tmp/mds_extract`（临时）。
- 之前下载的 rembg 模型在 `tools/models/rembg/u2net/u2net.onnx`；`tools/README.md` 已记录。

## 之后刚改、尚未验收

- `scripts/hub/npc.gd`：NPC 立绘 `sprite_scale = 1.55`（原来 1.1），按贴图高度重算 offset、名字/提示位置和碰撞半径。**尚未重跑测试/截图**；先验证 Hub 五 NPC 是否过大、名字是否被裁、脚底是否对齐，再调 `sprite_scale`。

## 用户最新的明确要求

1. **MDS 可作为主线优化游戏**；但用户要求“先调研，然后问我”，不要直接迁移四章关卡。
2. **AI 言灵生成的技能要真正达到效果**：现在 AI 的 `projectiles` 等参数没有在 `PhraseCaster._cast_spell` 中兑现；要扩大 AI 权限、做更多技能特效。
3. **词库远远不够**：50 词需要扩到更多（目标至少 80–100），并让 AI 能使用更多概念。
4. **NPC 相对背景太小**：已改 1.55，待验收。
5. **尽可能多调研相关有用工具**，并说明取舍。
6. 先调研 MDS 主线接入，再问用户是否迁移；不要擅自大改关卡。

## 下一步任务（按优先级）

### 1. 验收 NPC 放大
- 跑 `tests/run_tests.gd`、`tests/integration_playability.gd`。
- 启动 Hub 截图 1280×720：五 NPC 的名字、提示、脚底、碰撞；必要时把 `sprite_scale` 调到 1.4–1.7。
- 检查玩家与 NPC 的比例；如果玩家也偏小，单独调 `player.tscn` 的 Sprite scale，别把 NPC 调回去。

### 2. MDS 主线接入调研 + 3 房间 spike
- 打开编辑器 MetDevSys 标签，先只创建一个独立测试 world：
  - 3 个房间：1 战斗房、1 宝箱房、1 Boss 门；
  - 复用现有 `Player`、`Enemy`、`ArenaRoom`；
  - 验证 `MDSWorldGame` 是否接受现有玩家场景、现有 `ArenaRoom` 能否作为房间场景、相机是否适合横版动作。
- 必须验证：
  - GL Compatibility 渲染下 atmosphere shader 是否正常；
  - Android 导出是否把 addon/编辑器资源排除，包体增加多少；
  - `MDSWorldGame` 是否要求修改 `game.gd` 的章节/存档/房间清场逻辑；
  - 120 FPS 与大量 shader 粒子的性能。
- 不要直接把四章迁移到 MDS。做完 spike 后向用户报告“可接入/只借气氛/不接入”三选一。

### 3. AI 言灵权限与特效（重要 bug）
- 现状：
  - `SpellSynthesizer._from_intent` 接受 `pulses/projectiles/spread/duration/burn/chain/knockback`；
  - 但 `PhraseCaster._cast_spell` **没有把 `projectile` 写进 components，也没有调用 `_spawn_projectile`**；`_spawn_projectile` 只在 legacy `_apply_legacy` 路径调用。
  - 结果：AI 给 `projectiles: 20` 也可能完全不出现弹幕。
- 修复方向：
  - `_from_intent`：当 `projectiles > 0` 时补 `components[&"projectile"] = 1.0`；保留 `pulses/spread/duration/burn/chain`。
  - `_cast_spell`：根据 `style.shape` 与 components 生成弹幕/多段/持续区域；不要只靠 8 形态。
  - 扩展 AI 允许字段：`homing/pierce/explosion/beam/aura/trail/screen_shake/hit_stop` 等，映射到 `CombatFX`/`SpellVFX`/`Projectile`。
  - 允许 AI 返回 `vfx` 配方（颜色、轨迹、粒子密度、环数），本地只做有限/非负/可渲染校验；数值不设上限。
  - 增加至少 3 种新视觉：追踪弹幕、地裂/冲击波、领域/光环；复用 `CombatFX` 的 telegraph/bomb/beam_impact/ring/shockwave。
  - 测试：AI 伤害 999 不截断、projectiles 实际生成、duration 实际持续、深渊污染低 confidence 仍高收益高污染。

### 4. 词库扩充
- 目标 50 → 80–100 个 `WordData`。
- 新词优先补 AI 概念：ice/wind/light/shadow/dream/star/moon/door/mirror/feather/bone/heart/eye/crown/flower/song/sound/memory/holy/time/space/order/chaos/name/ink/word 等。
- 每个词需要：id、glyph、phoneme、meaning、grammar_role、tags、power、corruption、components、description。
- 同步 `ContentLibrary.WORDS` 和测试计数（`test_content_expanded` 目前硬编码 50/17/13/20，需更新）。
- AI `TAG_WORDS`/`_from_intent` 的概念表同步扩充，确保 AI 词义能匹配。

### 5. 动画工具调研/选型
已调研（不要重复搜）：
- **Aseprite Wizard** v9.8.0，MIT，Godot 4 分支；.aseprite tag→SpriteFrames/AnimationPlayer，支持 frame duration、方向、layer regex、bake/CI。适合真正逐帧动画。
- **AnimSheet** 2.0，MIT，批量扫描 sheet/zip，自动识别网格并生成 AnimatedSprite2D 或 Sprite2D+AnimationPlayer。
- **SpriteFrames Batch Importer**、**Batch Sheet Importer**、**Sprite Sheet Builder Importer**（PNG+JSON/Sparrow），适合已有 atlas。
- **SpriteForge**（itch.io）适合脏 sheet、去背景、切图。
- **Godot 内置 Skeleton2D/Bone2D + Polygon2D**：无需插件，适合 cutout；大量骨骼 CPU 成本高。
- **Godot-DragonBones v2**（MIT，GDExtension，Godot 4.2+）与 **Spine** 官方 runtime（需 Spine 授权）适合骨骼动画；Spine 成本/许可更重。
- 性能结论：大量 2D 角色优先 AnimatedSprite2D/SpriteFrames；AnimationPlayer/AnimationTree 每个实例有固定成本，离屏/待机要禁用 process；Skeleton2D 多骨骼在大量单位上很贵。
- 建议：先用 Aseprite Wizard 做 1 个 8 帧玩家跑步/攻击循环样板；保留现有 `ActorMotion` 作为程序化 fallback；不要一次性把所有角色改成骨骼。
- **安装任何插件前先问用户**（MDS 已获批准；Aseprite Wizard 等尚未）。

### 6. 更多工具调研方向
- Phantom Camera（相机）、Dialogic / Ink / Yarn Spinner（对话）、GUT / gdUnit4（测试）、Pixelorama / LibreSprite（像素美术）、Godot Profiler/性能插件。
- 记录“用途/大小/许可/4.7.2 兼容/是否值得装”，不要未经同意下载。

### 7. 剧情与内容
- 剧情圣经已有四章/五结局/五 NPC；下一步是支线任务、NPC 个人事件链、可收集档案页和环境叙事，不是再改主线骨架。

### 8. 导出
- `scripts/export_game.ps1` 被当前权限分类器拒绝；未出 Windows/Android 包。需要用户允许或在权限设置加规则后再跑。
- 导出前先跑 `check_game.ps1`；MDS 插件是否影响导出需要专门验证。

## 关键约定

- 用户要求：**以后下载任何东西先问**；MDS 已批准，其他插件/模型先征得同意。
- 不提交 git，除非用户明确要求。
- `Room` 已改名 `ArenaRoom`，不要回退。
- 设计技能已使用：`game-feel`、`godot-animation`、`2d-essentials`、`create-game-assets`、`level-design`。
