# 2026-11-08 · 0.14.0-demo：翻滚、召唤电梯、地图随机性、地块美术

## 起点

- 本地 `games/changzi-adventure` 是 11-02 的旧版（`feat/chapter1-demo` @ `bc8ae5a`）。GitHub `kami0410/changzi-adventure` 是另起的历史（`5ccc970` 首个公开版 → `c76d6c4` v0.13.0，四章全通）。
- 旧本地提交备份在分支 `legacy-local`（`bc8ae5a`），`main` 重置到 `origin/main`（`c76d6c4`），已设上游。
- 用户要求：加翻滚、提升地图随机性、美术优化、电梯可手动召唤，其余自由发挥，全程不问。

## 做了什么

- **翻滚**（`player.gd`）：地面翻滚/空中冲刺、无敌 0.30 s + 0.06 s 可受击收尾、碰撞体压低到 40 px、向后滚、输入缓冲、完美闪避（`perfect_dodged` → `game.gd` 顿帧 + 6 墨 + 金闪）、翻滚接重击。表现层 `ActorMotion` 新增 `roll`：蜷身帧绕身体中心转一圈 + 速度弧。`cancel_dodge()` 只清翻滚给的无敌。
- **召唤电梯**（`moving_platform.gd` `call_mode`）：15 台 `Lift` 开启；呼叫面板/电梯上按 E；320 px/s 带加减速；面板按 `MDSBigRoom._notify_child_surfaces()` 传来的地面决定放哪侧；提示文字跟随键位/手柄；新音效 `elevator_call.wav`。
- **捷径**：到达 `chN_hub` 即授予 `chN_shortcut`（待定第 16 项结案）。
- **随机性**：第 1 章 8 种布局 × 镜像（`MDSChapterRoom.PATTERNS`、出生点禁区）；`EncounterVariation`（替换/加人/精英·迅潮·群潮/站位），`Flow.encounter_variation` 开关给核对原始波次的验收套件用。修了原第 2 号布局 200 px 的跳跃缺口。
- **美术**：`tools/build_chapter_tiles.py` → `assets/tiles/ch1–4/tiles.png` + `resources/tiles/ch1–4_tiles.tres`（4×2，第 2 行变体/深层）；`TileVariants` 选变体；大图背景按行压暗；镜头贴底下让 96 px（`Player.hud_bottom_pad`，大图房间地板下多画 8 行）。
- **其他**：帮助页补电梯/翻滚说明；README、GDD §0.14 规则；版本 `0.14.0-demo`，标题页读项目设置。新音效 `perfect_dodge.wav`（`tools/generate_sfx_extra.py`）。

## 踩坑

- 三套大图验收并行跑会共用 `user://` 存档互相污染，必须串行。
- 第 3/4 章验收「卡死」的真因：`cancel_dodge()` 原先无条件清零无敌，坠落回位把测试设的 100 s 无敌清掉 → 玩家死亡 → `_finish` 暂停游戏 → 之后的 `load_room` 过渡永远等不完。真实游戏里同样会吞掉受击无敌，已修。
- 随机布局曾把平台放在门的到达点上，玩家出生在平台里卡住（ch1_demo 书库返回用例）；加了到达点/书库门禁区。
- Git Bash heredoc 会吞掉 `\\` 续行，补丁一律写成 scratchpad 里的 .py 文件再跑。

## 验证

- 见本文件末尾「测试数字」。`integration_ui_prompts` 的 `built_once_codex_ai_hint_*` 2 项在本机原版（`c76d6c4` 未改动的 worktree）同样失败，属本机 AI 设置环境差异，非本次回归。

## 未做 / 后续

- 翻滚仍复用跳跃蜷身帧旋转，没有专门的翻滚逐帧图。
- 第 2–4 章大图几何本身仍固定，随机性只来自遭遇变数；可考虑区域级道具/危险物随机。
- 精英残页、完美闪避回墨的数值需试玩再调。
