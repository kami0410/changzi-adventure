# 2026-11-03 局内存档 + 手柄（0.11.0-demo 收尾）

## 完成

- **T16 局内 run save/resume**（`scripts/core/run_save.gd`）
  - `ConfigFile` 原子写（tmp → bak → rename），版本/结构校验；坏档与未知版本自动清除；主文件缺失时读 `.bak`。
  - 保存点：进房、奖励选择、事件结果、商店买卖/关闭、残碑、宝箱、Boss 死亡、权柄选择、章末选择、暂停、失焦、窗口关闭。
  - 清除点：死亡、通关、返回 Hub、暂停菜单重开、标题新游戏。
  - 续玩恢复：章节/房间/位置、生命/墨量/污染/残页、击杀/仁慈/记录、词/武器/遗物/短语、权柄使用状态、已清房间/书库/残碑/宝箱/商店库存/发狂计时、MDS `get_save_data()`；Boss 已死时直接续接权柄/章末，不重复刷 Boss。
  - 标题新增「继续本局」；`GameFlow.run_save_path` / `resume_requested`；窗口关闭先保存再退出。
- **T15 手柄 + 焦点导航**
  - `GameFlow` 默认手柄布局：左摇杆移动、A 跳、X 攻击、B 翻滚、Y 交互/言灵、LB/RB 换武器、LT/RT 短语、十字键↑/↓/←/→ 造句/背包/地图/说明、Start 暂停/结束屏返回、Back 设置。
  - 键盘与手柄重绑互不覆盖；方向键与 Esc 作为第二键保留；`Profile.joybinds` 持久化（Profile v2 兼容）。
  - 键位页支持手柄按键捕获、双设备标签、Back 取消；捕获期间 `Flow.input_capture_active` 阻止玩法/Hub 误响应。
  - 暂停菜单新增「设置」入口；标题/暂停/设置/键位页打开即抓焦点；暂停时手柄方向键只做焦点导航。
  - HUD、帮助、对话、剧情、地图、教程、Hub、残碑、房门、结束屏提示读取 `Flow.prompt_label()`，随最后输入设备切换。

## 验证

- 单元 `tests/run_tests.gd`：3492 passed / 0 failed（含 `test_run_save.gd` 36 项、`test_gamepad.gd` 43 项）。
- 结构集成 `integration_playability.gd`：267 checks / 0 failures。
- 输入集成 `integration_ch1_demo.gd`：11 checks / 0 failures。
- run save 集成 `integration_run_save.gd`：27 checks / 0 failures。
- 手柄集成 `integration_gamepad.gd`：34 checks / 0 failures。
- `--headless --import` 通过；主场景 headless 启动无脚本错误。

## 已知遗留

- `--quit-after` 强制退出仍间歇报 ObjectDB/resource 泄漏 warning（已知项，下一步处理）。
- v1 旧存档 `discovered_phrases` 仍按旧签名保存，无法还原为按词 id 的新组合；待定迁移策略见 `SUPERVISOR_STATUS.md`。
- 5–10 人封闭试玩与 1080p/1440p 实机截图仍需人工。
