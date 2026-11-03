# 已安装技能

技能安装在项目根目录的 `.claude/skills/`，**随项目走，不进全局配置**。
每个技能是独立文件夹 + `SKILL.md`，Claude 只在任务匹配时加载正文。

新装或修改技能后，需要**新开一个 Claude Code 会话**才会出现在技能列表里。

## 来源与版本

| 来源 | Commit | 许可 | 数量 |
|---|---|---|---:|
| [awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills) | `19d93f97c9c1ea0f8b306e77aa81e0d3e352d3e9` | Apache-2.0 | 23 |
| [GodotPrompter](https://github.com/jame581/GodotPrompter) | `d7b26cdb5fae14d4ef7b713c5bf259395e75c3c6` | MIT | 8 |
| 自建 | — | 本项目 | 2 |

源仓库克隆在 `tools/skill-sources/`（git 忽略）；许可证在
`.claude/skills/_licenses/`。安装脚本：`scripts/install_skills.ps1`。

## 设计与类型

| 技能 | 用途 |
|---|---|
| `roguelike` | Roguelike/Roguelite 的局内循环、随机性、元进度；实时动作部分配合 `platformer` |
| `platformer` | 横版平台游戏：跳跃、关卡节奏、摄像机、移动手感 |
| `game-ai` | 敌人 AI、行为树、追击/巡逻/远程决策 |
| `physics-tuning` | 物理参数、碰撞、重力、跳跃曲线调校 |
| `game-feel` | 打击感、镜头、反馈、手感调校 |
| `level-design` | 关卡节奏、房间、引导、难度曲线 |
| `game-ui-ux` | HUD、菜单、可读性、可访问性 |
| `dialogue-systems` | 对话系统与叙事数据结构 |
| `procedural-gen` | 程序化生成关卡/内容 |
| `create-game-assets` | **完整美术工作流**：art direction brief、资产清单、2D/3D 管线、QA 脚本 |
| `audio-design` | 音效、音乐、混音与实现 |
| `shader-programming` | 着色器与视觉风格实现 |
| `prototype-fast` | 快速原型与灰盒验证 |

## Godot 实现

| 技能 | 用途 |
|---|---|
| `godot-2d-movement` | 2D 移动、碰撞、平台跳跃 |
| `godot-animation` | AnimationPlayer、动画树、状态切换 |
| `godot-tilemap` | TileMapLayer、自动图块、关卡拼装 |
| `godot-ui-control` | Control 布局、主题、响应式 UI |
| `godot-signals-groups` | 信号、组、解耦 |
| `godot-resources` | Resource、数据驱动配置 |
| `godot-gdscript` | GDScript 语言与模式 |
| `godot-gdscript-headless-testing` | 无头测试与 CI |
| `godot-export` | Windows/Android 导出与预设 |
| `godot-shaders` | Godot 着色器与材质 |

## GodotPrompter

| 技能 | 用途 |
|---|---|
| `2d-essentials` | Godot 2D 基础与项目结构 |
| `player-controller` | 玩家控制器、状态与输入 |
| `state-machine` | 状态机架构 |
| `inventory-system` | 背包/物品系统 |
| `save-load` | 存档、版本迁移 |
| `godot-testing` | 测试策略与工具 |
| `godot-code-review` | 代码审查清单 |
| `godot-debugging` | 调试流程与常见错误 |

## 自建

| 技能 | 用途 |
|---|---|
| `memory-index` | 读取/更新 `docs/memory/` 索引；每个大任务后写阶段总结 |
| `magpie-art` | 用 Magpie MCP 生成概念图、风格板、精灵草稿，并接入 `create-game-assets` 流程 |

## 美术工作流

1. 用 `create-game-assets` 锁技术规格、写 art-direction brief、建 asset manifest。
2. 用 `magpie-art` 调 Magpie 生成 1–4 个 hero/style board 变体。
3. 在游戏实际尺寸下检查剪影、配色、可读性。
4. 通过后用参考图生成同族资产，规范化、去背、切图、导入。
5. 在游戏里验证，记录来源/许可到 manifest。

生成图不能直接当成品；`create-game-assets` 的 QA 脚本和人工检查是必过门槛。

## 更新流程

```powershell
# 重新拉取源仓库并复制精选技能（不会动 memory-index / magpie-art）
powershell -ExecutionPolicy Bypass -File scripts/install_skills.ps1 -Refresh
```

更新后：

1. 运行 `check_game.ps1` 确认现有游戏不受影响。
2. review `.claude/skills/` 的 diff。
3. 更新本文件的 commit 与技能表。
4. 提交根仓库。
