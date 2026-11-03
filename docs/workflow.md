# 多游戏工作流

## 目录约定

```
D:\GameCreateStudio\
├─ tools\                    # Godot 4.7.2 + 导出模板（本地，git 忽略）
├─ templates\game_project\   # 新游戏模板
├─ games\<slug>\             # 每款游戏：独立 Godot 项目 + 独立 git 仓库
├─ shared\design\            # 共享设计模板
├─ shared\addons\            # 可复用插件
├─ scripts\                  # new_game / check_game / export_game
└─ docs\                     # 工作室级文档
```

- 根目录是一个 git 仓库，只跟踪模板、脚本、文档；`games/*` 与 `tools/*` 被忽略。
- `games/<slug>` 内部各自 `git init`，发布、分支、tag 互不影响。
- 工具物理上留在 `tools/`，不提交二进制；版本记录在 `tools/manifest.json`。

## 新建游戏

```powershell
powershell -ExecutionPolicy Bypass -File scripts/new_game.ps1 -Slug my-game -Name "我的游戏"
```

脚本会：

1. 复制 `templates/game_project` 到 `games/my-game`。
2. 替换项目名、导出文件名、Android 包名占位符。
3. `git init -b main` 并做初始提交。
4. 如果系统没有 git 身份，写入仓库级占位身份 `GameCreateStudio <gamecreatestudio@localhost>`。

建议先设置真实身份：

```bash
git config --global user.name "你的名字"
git config --global user.email "you@example.com"
```

## 日常循环

```powershell
# 无头导入 + 脚本错误检查
powershell -ExecutionPolicy Bypass -File scripts/check_game.ps1 -Game my-game

# Windows + Android 调试导出
powershell -ExecutionPolicy Bypass -File scripts/export_game.ps1 -Game my-game -Platform All
```

- 改脚本后至少跑一次 `check_game`。
- 改场景后手动运行主场景。
- 改导出配置后重新导出两个平台。
- 每次提交前确认 `git status` 不包含 `.godot/`、`build/`、keystore。

## 版本与发布

- 每款游戏在自己的仓库里打 tag，例如 `v0.1.0`；如需工作室级索引，可再用 `game/<slug>/v0.1.0`。
- `build/` 是导出产物，不提交。
- Windows 发布包、Android AAB、签名 keystore 单独归档，不入库。
- Android 上架前再配置 release keystore、AAB（Gradle 构建）和商店素材。

## 引擎升级

1. 更新 `tools/manifest.json` 与 `docs/setup.md`。
2. 下载新版本到 `tools/godot/`，安装匹配的导出模板。
3. 先用 `templates/game_project` 生成一个临时项目，验证 Windows/Android 导出。
4. 再逐个升级 `games/<slug>`，每个游戏单独提交。

不要直接覆盖正在使用的引擎版本；保留旧版本直到所有游戏迁移完成。

## 共享资源

- `shared/design/`：美术风格、试玩清单、命名表；GDD 模板在 `templates/game_project/docs/GDD.md`。
- `shared/addons/`：确认兼容 Godot 4.7 后再复制进具体游戏的 `addons/`，并在 `project.godot` 启用插件。

## 记忆与技能

- **每个大任务/里程碑结束后**，更新 `docs/memory/MEMORY.md` 索引，并写
  `docs/memory/sessions/YYYY-MM-DD-<topic>.md`；游戏内任务写到
  `games/<slug>/docs/memory/`。
- 先读索引，只加载与当前任务匹配的主题文件；协议见 `memory-index` skill。
- 项目技能在 `.claude/skills/`，来源与版本见 `docs/skills.md`。
- 美术：`create-game-assets`（art direction + 资产管线）+ `magpie-art`（Magpie MCP）。
  生成图必须规范化、检查 alpha/尺寸/剪影，不能直接当成品。
- 新装技能需要新开 Claude Code 会话；在游戏目录单独开会话时，根目录技能不会自动加载。

## AI 工具链（可选）

- 编辑器 MCP：`hi-godot/godot-ai`（要求 Godot 4.7+）。
- 已安装精选技能：设计/类型、Godot 实现、GodotPrompter、`memory-index`、`magpie-art`。
- 启用前必须先有 git 提交；MCP 自动写入后逐次 review diff。
