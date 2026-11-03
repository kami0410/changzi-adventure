# Metroidvania Developer System 评估

日期：2026-11-01
来源：[Godot Asset Library 5523](https://godotengine.org/asset-library/asset/5523)、[作者仓库](https://github.com/arunsrajan/MetroidvaniaDeveloperSystem)

## 是什么

`Metroidvania Developer System`（MDS）v3.2.0，作者 arunsrajan，MIT。它是 Godot 编辑器插件，不是 Claude/Agent 技能，也不是运行时框架的替代品。

- 地图：自由绘制不规则房间、门、区域；可从轮廓生成整片区域并自动拆房。
- 房间：自动地形/背景/装饰绘制、自由岩石、洞穴生成。
- 气氛：30 种 shader 效果（雨、雾、尘暴、熔岩、蒸汽、蛛网、苔藓、触须等），视差与动态背景，Boss 房生物背景。
- 检查：房间物理可达性、进度/回溯分析、地图校验、JSON/PNG/Graphviz/Markdown 导出。
- 运行：`MDSWorldGame` 房间切换、门/屏障、快速旅行、已探索/已击败状态、适合不规则房间的相机、区域标题、游戏内地图。

官方标注 Godot 4.6+，**已在 4.7.2 测试**；MIT；需要复制到 `addons/MetroidvaniaDeveloperSystem/` 并在 Project Settings → Plugins 启用。MetSys 只在 MetSys 模式下需要。

## 对《昌子大冒险》的匹配度

**高匹配：**
- 我们下一阶段最缺的正是“更大的地图、房间图、门/捷径、游戏内地图、区域气氛、相机”。
- 它的物理可达性/回溯检查能直接减少“房间进不去/打完回不来”的 bug。
- 大气 shader 与生物背景可以补第四章和后续生态区。
- 游戏内地图/快速旅行符合“死亡细胞式大地图”的方向。

**低匹配/风险：**
- 当前项目是**手写连续横版关卡 + 自定义 `game.gd`**，不是 MDS 的 `MDSWorldGame` 架构。直接接入意味着迁移房间/门/相机/存档，而不是装一个插件就变好。
- 它主要解决“世界结构与气氛”，不解决我们刚完成的角色/敌人程序动画、攻击变体、战斗特效和 120 FPS；这些仍由现有 `ActorMotion`/`CombatFX` 负责。
- 插件会引入一套新的场景/节点命名与运行时约定，和现有 `Room`、`CampaignData`、`MemoryStele`、`RunShop` 的接线需要一层适配。
- 需要下载插件包；按你的要求，**下载前必须先问你**。

## 安装状态（2026-11-01）

- 已下载官方 v3.2.0 ZIP（9.8 MB）并安装核心 addon 到 `addons/MetroidvaniaDeveloperSystem/`（351 文件，约 2.2 MB）；未安装可选 asset_packs。
- 已在 `project.godot` 启用插件。
- 冲突：MDS 自带全局类 `Room`，与项目 `scripts/levels/room.gd` 冲突；已把项目类重命名为 `ArenaRoom`，测试通过。
- 尚未迁移任何现有章节；只完成安装与编辑器加载验证。

## 建议

不要直接改主线。先做一个**独立分支的 1 天 spike**：

1. 下载并安装到 `addons/MetroidvaniaDeveloperSystem/`，确认 4.7.2 编辑器能启用。
2. 只做一个 3 房间测试图：1 个战斗房、1 个宝箱房、1 个 Boss 门；不放现有剧情。
3. 验证四件事：房间切换是否稳定、相机是否适合横版动作、现有 `Player`/`Enemy` 能否直接复用、导出包是否排除编辑器插件资源。
4. 通过后再决定是“只借气氛/地图”还是“迁移整章地图”。

## 结论

**有用，但应作为地图/气氛工具评估，不是当前动画与战斗问题的解决方案。** 当前 0.7.0 先把角色、敌人、特效、NPC、剧情和 120 FPS 做扎实；MDS 放到独立分支试装，避免把可玩版本拖进一次大迁移。


## 3 房间 spike 结果（2026-11-02）

位置：`spikes/mds/`（不进导出包；`export_presets.cfg` 已排除 `spikes/*`、`tools/*`）。

- 世界：`spike.mdsworld.json`，战斗房 → 宝箱房 → Boss 房，三个 1280×720 房间横向相连，靠 `right1/left1` 门切换。
- 房间：`spike_room.gd` 在代码里搭地面、放现有 `ArenaRoom`（门 + 敌人追踪）、现有敌人场景/贴图、`TreasureChest`、墨骸史官（`InkArchivist`）和 `MDSGate`。
- 运行：`spikes/mds/run_spike.gd`（窗口模式）。**14/14 检查通过**：
  - `MDSWorldGame` 直接接受现有 `scenes/player/player.tscn`（无需改玩家）；相机限制到房间；
  - `ArenaRoom` 在 MDS 房间里正常锁门/清怪；门切换后玩家落在入口门内侧；宝箱可开；Boss 用现有脚本生成；
  - 区域天气（雾 + 灰）和 Boss 房动态背景（void_pulse）按世界文件自动挂上。
- 性能（RTX 5060 Ti，GL Compatibility，1280×720）：锁 120 FPS 时帧时间 8.2 ms（与无 MDS 一致）；不锁帧时 Boss 房 + 天气 + 动态背景 0.56 ms/帧，再加热浪（读屏幕纹理）+ 生物背景 0.94 ms/帧。**手机端未测**。
- 发现：
  - 这份安装的 MDS **没有全局 `Room` 类**（`Room → ArenaRoom` 改名仍保留，无害）。
  - 门有 0.35 秒到达冷却；`MDSGate.interact_action` 默认 `ui_up`，接入时应改成 `interact`。
  - MDS 的 `defeated_ids` 按节点路径记录，我们的敌人是运行时生成的，接入时要自己给 object id。
  - 编辑器脚本与运行时脚本互相引用，**不能简单按文件夹排除**；排除编辑器部分只省约 0.6 MB，不值得冒险。

## 2026-11-02 决定

用户选择**选项 1：全量接入为主线世界框架**（不再只借气氛）。
约束、迁移顺序与验收见 [ADR：MDS 全量接入](../memory/decisions/2026-11-02-mds-full.md)。

## 结论（等用户三选一）

1. **接入为主线世界框架**：需要把四章 12000 px 连续关卡拆成房间场景 + 世界 JSON，重写 `game.gd` 的章节/检查点/存档；估计 2–3 周。收益：游戏内地图、回溯、快速旅行、可视化地图编辑。
2. **只借气氛（推荐）**：保留现有章节结构，把 `MDSEnvironment.build()` 的天气/动态背景/视差挂到各章和 Boss 房；约 1 天，几乎零风险，可随时撤回。
3. **不接入**：卸载插件，包体少约 2.2 MB。
