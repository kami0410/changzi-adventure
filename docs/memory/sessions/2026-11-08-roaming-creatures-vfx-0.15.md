# 2026-11-08 · 0.15.0-demo：游荡战斗、新怪物、像素特效、美术需求 PDF

## 用户要求

- 发布 0.14（已发：GitHub Release v0.14.0，Windows zip + Android 调试 apk）。
- 用工作室素材库（`素材库-素材包-2026-11-08`，视频/动效参考库）丰富攻击特效等。
- 本机无法出图：把需要的图、参考图、提示词整理成 PDF，交给别人画。
- 怪物种类少、地图玩着怪；不喜欢分波出怪，要像《死亡细胞》那样怪物在各处游荡。
- 权限：除「AI 言出法随」与 NPC 设定外都可改（之后又放开「创造技能」可按我的想法优化）。

## 做了什么

- **素材库盘点**：525 条效果记录 + 17 个来源快照；对游戏最有用的是 pixelfx（MIT，约 200 个程序化像素特效，可在 Node 里直接渲染为序列帧）。其余（GLSL 转场、mojs、paper-shaders 等）留作后续（转场/纸张着色器）。
- `tools/export_vfx.mjs`：用素材库里的 pixelfx 渲染 35 个特效 + 6 套小生物循环，换成本作调色板（青/金/血/墨/骨），裁掉拖尾空帧、长特效降帧、按共同外框裁切 → `assets/vfx/*.png` + `vfx_manifest.json`（8 MB）。自带人形/宝箱的特效（disintegrate、shatter、respawn-beam、heal、chest-open、soul-rise）已替换为无形体版本。
- `VFX`（`scripts/presentation/vfx.gd`）：一次性播放 / 跟随目标循环，全局上限 48；接入挥砍、命中、完美闪避、受击、回血、重落地、敌人出场/死亡、精英/Boss、宝箱、复位、言灵施法与命中、燃烧/减速。
- **新怪物 6 种**：`CreatureArt`（逐帧换贴图 + 统一外框防抖动，`PixelSprite.set_opaque_rect`）、新行为 `HoverShooterEnemy`（追踪泪弹，`HostileBolt.set_homing`）、`KamikazeEnemy`、`PulseEnemy`；焚颅/噬名蛇/回声蝠复用飞行/冲锋/群体行为。通过 `EncounterVariation` 的 `featured` 名单进入各章战斗（验收套件关闭变数，原始波次不变）。史莱姆与小鸟画风偏可爱，未采用。
- **游荡战斗**：`ArenaRoom.start_roaming()`（不锁门，全灭即结算）、`game.gd` `_roaming_for/_roaming_spots`、`Enemy` 巡逻（`patrol_radius`、台沿/墙检测）与 `aggro_vertical`；精英/Boss 仍锁门。目标栏显示「游荡的敌人 · 还剩 N」。`Flow.roaming_encounters`。
- **音效**：`AudioManager` 音高随机 ±7%；`tools/generate_sfx_extra.py` 新增 enemy_die / elite_die / wisp_blast / jelly_pulse。
- **美术需求 PDF**：`tools/build_art_brief_refs.py` + `tools/build_art_brief.py` → `docs/art/昌子大冒险-美术需求清单.pdf`（21 页，副本在工作室根目录）：统一规范、9 张参考图、主角动作 3 项、新怪物 10 种（6 替换 + 4 新增）、区域背景 12 张（远景 + 透明中景）、地块/道具/电梯、标题主视觉与词缀图标，每项含规格、命名与中英提示词。交付放 `art_inbox/`（已建，含 `.gdignore`）。

## 踩坑

- `VFX` 继承 `AnimatedSprite2D`，静态函数不能叫 `play`（与实例方法冲突）→ `VFX.spawn`。
- 游荡战斗区的 `Enemies` 根节点会被「进区前冻结」逻辑设成 DISABLED，敌人不动也打不到（`integration_ch1_demo` 抓到）；游荡区不冻结、刷怪后显式 PAUSABLE，并加回归断言。
- 敌人变「活」后，`integration_ch1_demo` 的跳跃检查会被游荡怪撞飞打断：测试在跳前给短暂无敌并等落地。

## 验证

- 单元 13,774 / 0；集成 playability 1,475、ch1_demo 111（连跑 3 次）、ch1_event 73、run_save 695、gamepad 212、menus 459、ai_settings 45、ch2 2,335、ch3 4,258、ch4 5,023 全 0 失败；ui_prompts 仍是 2 条本机环境性失败。
- 截图：`tests/capture_vfx.gd`、`tests/capture_roaming.gd`（输出 `artifacts/screens/vfx|roaming/`）。

## 后续

- 外部画师交付后：替换 6 种新怪物、区域背景、翻滚动作、道具与电梯。
- 素材库的 GLSL 转场可用于房间切换 / 死亡转场；paper-shaders 的纸张颗粒可做 UI 底纹。
- 言灵「创造技能」体验优化（用户已放开）：待做。
