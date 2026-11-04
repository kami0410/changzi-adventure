# 2026-11-03 第一章打磨 + 内容厚度 + AI 健康检查（第 4 程）

## 完成

- **基线**：单元 3519 / 0；结构 267 / 0；输入 11 / 0；run save 27 / 0；手柄 34 / 0；
  `--headless --import` 通过；`tests/check_exit_clean.sh` 10/10。
- **打磨 1 · Hub 手柄 Y 双触发**：Y 同时映射 `interact` 与 `npc_inspire`，打开言灵面板后
  同一次按键又触发交互把对话盖回来。`_open_active_inspiration()` 返回是否打开，成功即消费本帧；
  手柄集成 34 → 39。
- **打磨 2 · 世界提示随设备**：`Pickup` / `TreasureChest` / `MemoryStele` 统一读
  `Flow.prompt_label(&"interact")` 并监听 `input_device_changed`；新增
  `tests/integration_ui_prompts.gd`（9 checks）。三个脚本改为从 `/root/Flow` 解析而不是直接引用
  全局，避免 `-s` 测试脚本预编译顺序问题。
- **打磨 3 · 坏档拒绝**：`RunSave` 增加结构校验，畸形但可解析的存档整体丢弃，不再半恢复；
  `RunSave` 与 `Profile` 都支持 `.bak` 读取后提升为主文件，写失败时不再先删主文件；
  `test_run_save` 58、`test_profile_v2` 71、run save 集成 30。
- **打磨 4 · tile 碰撞**：第一章每房原先把地板下方 9 行、平台下方 1 行也写入带碰撞的
  `TileMapLayer`（约 860 格）。拆出 `GroundFill` / `PlatformsFill`（`collision_enabled = false`），
  仅表面行保留碰撞，约 110 格/房，视觉不变。
- **打磨 5 · 退出边界**：奖励界面打开时 `save_run_now()` 返回 false，避免“房间已清、奖励未选”
  被写进检查点后永久丢奖励；`save_run_on_exit()` 在 `auto_save` 时先保存 Profile，
  保证词条熟练度/局内解码在中途关窗时也保留。
- **内容 1 · 事件“读禁文”**：demo 开局已拥有全部 18 个词（6 已解码 + 12 残页），旧逻辑按
  “未拥有”找词恒为空，只发 6 残页。新增 `RunLoot.owned_undecoded_words()` /
  `decode_owned_word()`，事件从已拥有未解码池随机解明一个，Profile 与本局副本同时解锁，
  成功后立即保存 Profile；全部解明才回退残页。新增 `tests/integration_ch1_event.gd`（14 checks）。
- **内容 2 · 击杀掉落池**：`_on_enemy_died()` 原用 `ContentLibrary.WEAPONS`（完整版表），
  第一章可能掉出非 demo 武器；改为 `RunLoot.dropped_weapon()`，复用章节武器池。
- **AI 健康检查**：默认关闭、无内置 key、未配置/失败保留离线；补测三 provider 的默认
  endpoint/model 与 key 传输、NPC Ollama/OpenAI 请求构造、Codex AI 替换预览/旧句忽略/
  失败保留/不自动装备。未改任何默认行为。真实 provider 联调仍需手工验证。

## 验证

- 单元 `tests/run_tests.gd`：**3664 passed / 0 failed**。
- 结构集成 267 / 0；输入集成 11 / 0；run save 集成 35 / 0；手柄集成 39 / 0；
  UI 提示 9 / 0；第一章事件 14 / 0。
- `--headless --import` 通过；`tests/check_exit_clean.sh` 10/10 clean。

## 边界

- 打包、安装器编译、代码签名、Windows 实机验证、1080p 实机截图：很久以后的发行阶段事项，
  现阶段不做；第 3 程脚本与文档原地保留。
- 下一程继续第一章打磨；候选问题（权柄选择 vs 暂停、标题设置焦点、设置子页 `_overlay`、
  键位页焦点、Hub 新游戏旧 Profile）需先复现再改。
