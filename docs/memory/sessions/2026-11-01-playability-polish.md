---
name: playability-polish-0.2.0
description: 试玩反馈修复、清房构筑循环、动作比例、HUD 与导出验收
type: session
status: active
updated: 2026-11-01
load_when: 继续修复试玩问题、调整手感与 UI、准备下一轮内容制作时
---

# 0.2.0 试玩体验迭代

## 设计与执行约束

用户要求难题以及决定游戏好玩程度的玩法、动作、UI 由主控亲自完成，不派子代理。先前启动的两个实现代理在写入代码前已停止，本轮核心实现与验收均由主控完成。

当前规则以 [GDD 的 0.2.0 章节](../../GDD.md) 和 [试玩说明](../../playtest-0.2.0.md) 为准。

## 修复与新增

- 房门在安全进入后才锁；休眠的房间不提前追击，清房开门并给三选一奖励。ContentLibrary 显式引用资源，避免导出目录 remap 导致空词/短语。
- 开局六个基础词加局外解锁，两把武器与两条合法短语；清房成长；唯一词/遗物去重；奖励使用局内 RNG。
- 八种遗物实际效果、基础/击杀回墨、武器继承基底升级、护盾/移速/回声组件；续命使用明确复活 API。
- Player 调整加速、土狼时间、跳跃缓存、可变跳高、翻滚冷却与穿敌；ActorMotion 将现有单帧图切成身体和腿部程序动画；敌人/Boss/NPC 动作、伤害数字和斩击、落地尘、死亡反馈。
- 玩家约 110 像素高，敌人/Boss/NPC 比例和碰撞匹配；地面上移到 y=560，为 HUD 留出空间。
- 远程敌人使用可躲避墨弹；Boss 三阶段、弹幕、落墨预警；流动墨门、远景视差、中景柱廊、纸页/尘/雾。
- 紧凑 HUD 真实目标/进度/武器状态/短语冷却墨耗；背包/造句/设置暂停互斥；奖励独占暂停；结算/暂停可以回 Hub。
- 实际按钮点击复现并修复造句在 signal 内 free 发信按钮的问题，保留新词卡键盘焦点；换短语不重置冷却。
- 修复 Flow 创建 Profile 未作为子节点释放导致的退出泄漏；测试输出不再有 ObjectDB/resource 泄漏错误。

## 验收证据

- `tests/run_tests.gd`：1480 passed, 0 failed。
- `tests/integration_playability.gd`：29 checks, 0 failures，覆盖房外/房内门、三次奖励、菜单暂停、续命和 Boss 结算。
- 用 Godot 编辑器二进制 `--main-pack build/windows/changzi-adventure.exe --script <absolute integration script> -- --expect-packed`：30 checks, 0 failures，包括确认包内排除了 tests。
- 注意 Godot 4.7 的默认导出模板禁用路径覆盖，exe 的 `--script` 参数不会执行外部测试；原直接 exe 测试因此未退出，已停止。成品 exe 默认 Hub 的 `--headless --quit-after 120` 冒烟正常。
- 实际 OpenGL 渲染 Hub、战斗/攻击、背包、造句、三选一与 Boss；40 帧跑步/攻击/翻滚/跳跃预览。960×540、1280×720、1600×900、1600×720 布局检查未越界。
- 工作室 `check_game.ps1` 通过；Windows/Android 双平台导出；APK versionCode 2 / versionName 0.2.0 / minSdk24 / targetSdk36 / arm64，v2/v3 签名验证通过。
- 最终导出资源包实际 OpenGL 运行并点击造句按钮，Hub/战斗/背包/造句/奖励截图无脚本错误；截图脚本通过 --out-dir 将产物写入工作区 artifacts。
- `adb devices` 无设备，Android 真机手感、触控与性能未验证。
- 交付 Windows exe 104.35 MiB；含试玩说明 ZIP 38.59 MiB；Android APK 33.06 MiB。最终 SHA256 见 artifacts/polish-build-manifest.json。

## 仍未完成

独立手绘逐帧图集、完整四生态区/更多 Boss/多结局、正式音频、Android 真机验收。当前是可玩迭代，不是完整商业成品。

## 工作区

游戏分支 `fix/playability-polish`，本轮改动未提交、未推送；打包输出在被忽略的 build 目录。长期目标与原参考素材保留。
