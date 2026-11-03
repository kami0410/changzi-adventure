# 昌子大冒险 项目约定

@docs/memory/MEMORY.md

## 引擎与语言

- Godot **4.7.2 stable**，标准版，只使用 **GDScript**。
- 2D 项目，渲染器 **GL Compatibility**；不要引入 3D 或 .NET 依赖。
- 脚本尽量使用静态类型：`func foo() -> void`、`var speed: float = 200.0`。

## 目录

- `scenes/`：按 player / enemies / ui / levels 分组。
- `scripts/`：与场景同名（`player.tscn` → `scripts/player.gd`）。
- `assets/`：`sprites/`、`audio/`、`fonts/`；概念图放 `assets/concept/`。
- `resources/`：自定义 `Resource`。
- `docs/GDD.md`：玩法与范围。
- `docs/memory/`：游戏级记忆索引与阶段总结。
- `build/`、`.godot/`：不提交。

## 命名

- 文件与目录：`snake_case`。
- 节点：`PascalCase`，根节点与文件名一致。
- 变量/函数：`snake_case`；信号用过去式（`died`、`health_changed`）。
- 常量：`UPPER_SNAKE_CASE`。

## 代码

- 用 `signal` 解耦场景；跨场景依赖通过信号或组。
- 可调参数用 `@export`，不硬编码数值。
- 节点引用用 `@onready` + 相对路径；不要在 `_process` 里 `get_node`。
- 物理与移动放 `_physics_process(delta)`，UI/计时放 `_process(delta)`。
- 输入动作在 `project.godot` 的 `[input]`：`move_left/right/up/down`、`jump`、`attack`、`dodge`、`interact`、`pause`、`restart`。
- 暂停逻辑：控制节点 `PROCESS_MODE_ALWAYS`，游戏实体保持 `PAUSABLE`。

## 记忆

- 每个大任务/里程碑结束后，更新 `docs/memory/MEMORY.md` 并写
  `docs/memory/sessions/YYYY-MM-DD-<topic>.md`。
- 稳定设计决策写 ADR 到 `docs/memory/decisions/`；GDD 是玩法事实来源。
- 协议见工作室根目录的 `memory-index` skill。

## 技能与美术

- 工作室技能在根目录 `.claude/skills/`；优先从工作室根目录启动 Claude Code。
- 美术走 `create-game-assets` + `magpie-art`；生成图必须规范化、检查 alpha/尺寸/剪影。
- 新装技能需要新开会话才会加载。

## 验证

- 无头导入：用本机 Godot 4.7.2 可执行文件运行 `--headless --path . --quit`（本仓库不含引擎二进制）。
- 改场景后手动运行主场景；改导出配置后跑 Windows/Android 导出。
- 提交前确认 `git status` 不包含 `.godot/`、`build/`、keystore。

## Git

- 小步提交；消息说明“做了什么 / 为什么”。
- 不提交导入缓存、导出产物、签名文件。
- 启用 MCP 自动写入前必须先有提交，并逐次 review diff。
