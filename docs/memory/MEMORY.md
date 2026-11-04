# 昌子大冒险 · 记忆索引

> 常驻索引（≤8 KB）。规则见工作室 `docs/memory/README.md`；协议见 `memory-index` skill。

## 游戏概览

- **昌子大冒险**（slug：`changzi-adventure`）
- 2D 横版动作 Roguelite；核心是道具/构筑，语言同时作为构筑与叙事核心。
- 版本 `0.11.0-demo`（Chapter 1 demo）；1.0 仅用于用户确认的最终完整版（[版本策略](decisions/2026-11-02-versioning.md)）。
- 当前目标：Chapter 1 demo，Windows 优先；范围见 [Chapter 1 demo ADR](decisions/2026-11-03-chapter1-demo.md)。
- 昌子：失忆的宇宙史官，被克苏鲁式污染侵蚀，在破碎末日世界找回权柄与记忆。
- [GDD 与 0.11 规则](../GDD.md) · [剧情圣经](../story-bible.md) · [素材许可](../../ASSETS.md) · [角色像素概念](../../assets/concept/characters/README.md)。改玩法/台词/结局前读。

## 世界与系统

- 语言：词 → 短语 → 权柄；污染 0–100；见 GDD §7。0.8 言灵 v3 组件→效果表见 [AI 言灵](../ai-skill-hook.md)。
- 战斗：2 武器 + 2 短语 + 1 权柄；墨量资源；见 GDD §8。武器可掉落/拾取（E），换装时旧武器掉在身后。
- 权柄：续命/改写为基底；吞噬（污染 ≥ 40，伤害最高 ×1.6）与归档（记录 ≥ 2，死亡带一件物品到下一局）按条件追加；见 [T17 记录](sessions/2026-11-04-t17-authorities-trust-gallery.md)。
- 难度：平静/墨雨/深渊/噩梦四档；生命/伤害、收益、污染倍率见 [平衡与权限 ADR](decisions/2026-11-02-balance-authority.md)。
- 成长：档案馆祭坛（生命/墨量/言灵伤害/污染抗性，无上限指数成本）+ 词条熟练度（使用累积，递减增益）。
- AI NPC：对话可执行白名单职能（讨价还价/锻造等），每 NPC 每次回 Hub 一次破例，客户端校验。
- 信任：4 档陌生/熟悉/信任/托付，阈值 0/2/6/12，由 `npc_trust` 现算（无新存档键）；影响对话态度、离线/AI 回复、商店/锻造折扣、托付免费锻造、起始残页；见 `TrustData`。
- 道具：武器/短语/遗物/词/消耗品；见 GDD §9。HUD 左上角常驻遗物状态，背包页有完整列表。
- 污染：25/50/75 分档加敌人伤害、短语墨耗/冷却；100 发狂 30 秒（生命上限 40%），撑过恢复。净化：净化词/圣+水/生命共鸣/净墨灯/休整 -12。分档警告每档 4 句，按局种子+档位轮换（`CorruptionWarningData`，不耗 run RNG）。
- 单局：Hub + 分支路线 + 2–3 个生态区；见 GDD §10–11。
- 探索：四章主路各有隐藏书库（宝箱 + 记忆碑），休息室有回长廊捷径；门扉由 `chapter_door.gd` 绘制，首次进书库有金色反馈。
- 第四章舞台用专属插画 `assets/backgrounds/smiling_theater.png`，`TheaterBackdrop` 只叠加聚光灯/浮尘；已接入，不是缺美术。
- 叙事：碎片投放 + 3 主结局 + 1 隐藏；见 GDD §12。结局画廊从标题页进入，`CampaignData.ENDINGS` 为五个结局的唯一来源，解锁只读 `Profile.endings` id。

## 工具与插件

- **Aseprite Wizard 9.8.0**（MIT）`addons/AsepriteWizard/`：逐帧动画导入；已启用。
- **Metroidvania Developer System 3.2.0**（MIT）`addons/MetroidvaniaDeveloperSystem/`：世界/房间/地图框架；四章已接入。
- **Fusion Pixel 12px Monospaced zh_hans**（OFL）`assets/fonts/`：UI 主字体，0 缺字；Ark Pixel 仅留基线。
- `tools/slice_anim_sheet.py`：Magpie 多帧横条 → 共用缩放/调色板/脚底基线的玩家动作帧；改帧管线时读。

## 决策

- 2026-10-31：确认主角、5 名 NPC + 笑面史官最终 Boss；语言同时作为构筑核心与叙事核心。
- [ADR-0001：高精度像素美术](decisions/2026-10-31-pixel-art.md)；[美术技术规范 0.9](decisions/2026-11-02-art-spec.md)（尺寸、整数缩放、二值 alpha、轮廓、脚底）。
- [MDS 全量接入](decisions/2026-11-02-mds-full.md) — MDS 做世界/房间/相机/地图；全四章已落地。
- [平衡、成长与 AI 权限](decisions/2026-11-02-balance-authority.md) — 效果预算定价、四档难度、无上限成长、AI 白名单；改数值/成长/AI 前读。
- [逐帧动作管线 0.10](decisions/2026-11-02-frame-animation.md) — 生成横条、统一切片、脚底/影子锚定、状态切帧；改玩家动作前读。
- [UI 方向 0.9](decisions/2026-11-02-ui-direction.md) — 档案纸页、配色令牌、12/24/36/48 字号；改 UI 前读。
- [v1 已发现短语迁移](decisions/2026-11-03-v1-phrase-migration.md) — 不猜测 meanings；旧串留在 `legacy_discovered_phrases`，不展示、不参与逻辑；改 Profile 前读。
- 2026-10-31 M1：自由造句、连续横版区域、全员完整动画、完整 Hub + 基底升级；见 [GDD v0.2 决策](../GDD-v0.2-decisions.md)。
- 2026-11-03：Windows 打包/安装器/签名/实机验证推迟到很久以后发行阶段；脚本与 `docs/release/windows-signing.md` 留档，不扩展、不删除。

## 已知问题

- [角色浮空/像素发糊](issues/2026-11-02-sprite-float-blur.md) — 根因与修法；0.9 已修（见 visual-polish）。

## 调研

- [Godot 工具调研](../research/2026-11-02-godot-tools.md) — 相机/对话/测试/调试/性能/特效插件的版本、许可、结论；装插件前读。
- [MDS 评估与 3 房间 spike](../research/metroidvania-developer-system.md) — 已定全量接入；动 MDS 前读。

## 待定

- 笑面史官身份、语言语法、单局长度、污染净化、垂直切片 Boss、中文像素字体、工作名、每日挑战；详见 GDD §20。

## 最近阶段

- 2026-10-31：[角色参考](sessions/2026-10-31-character-references.md)、[美术测试](sessions/2026-10-31-art-style-tests.md)、[GDD v0.1](sessions/2026-10-31-gdd-v0.1.md)、[核心系统](sessions/2026-10-31-core-systems.md)、[M1 切片](sessions/2026-10-31-m1-integration.md)。
- 2026-11-01：[试玩 0.2](sessions/2026-11-01-playability-polish.md)、[三章 0.3](sessions/2026-11-01-chapter-campaign.md)、[言出法随 0.4](sessions/2026-11-01-freeform-audio.md)、[深度 0.5](sessions/2026-11-01-depth-0.5.md)、[AI 言灵 0.6](sessions/2026-11-01-ai-intent.md)、[世界 0.7](sessions/2026-11-01-world-animation-npc.md)、[出包](sessions/2026-11-01-final-playable.md)（历史）。
- 2026-11-02：[画面 0.9](sessions/2026-11-02-visual-polish.md)、[言灵 v3](sessions/2026-11-02-spell-v3-lexicon.md)、[试玩 0.9.1](sessions/2026-11-02-playtest-fixes-0.9.1.md)、[MDS](sessions/2026-11-02-mds-migration.md)、[成长 0.9.3](sessions/2026-11-02-growth-difficulty-0.9.3.md)、[探索 0.10](sessions/2026-11-02-exploration-animation-0.10.md)。
- 2026-11-03：[Chapter 1 demo 0.11](sessions/2026-11-03-chapter1-demo.md)、[存档+手柄](sessions/2026-11-03-run-save-gamepad.md)、[退出泄漏](sessions/2026-11-03-exit-leak-save-recovery.md)、[迁移+构建+签名](sessions/2026-11-03-migration-build-leaks-signing.md)、[第一章打磨](sessions/2026-11-03-polish-ai-content.md)。
- 2026-11-04 第 11–23 程：[菜单焦点](sessions/2026-11-04-ui-focus-controller.md)、[菜单 A/B+内容](sessions/2026-11-04-supervisor-menus-content.md)、[第一章焦点+内容](sessions/2026-11-04-chapter1-focus-content.md)、[关闭提示+焦点+文案](sessions/2026-11-04-close-prompts-focus-content.md)、[设备/改键](sessions/2026-11-04-device-keybind-prompts.md)、[11](sessions/2026-11-04-supervisor-pass11.md)/[12](sessions/2026-11-04-supervisor-pass12.md)/[13](sessions/2026-11-04-supervisor-pass13.md)/[15](sessions/2026-11-04-supervisor-pass15.md)/[17](sessions/2026-11-04-supervisor-pass17.md)/[18](sessions/2026-11-04-supervisor-pass18.md)/[19](sessions/2026-11-04-supervisor-pass19.md)/[20](sessions/2026-11-04-supervisor-pass20.md)/[21](sessions/2026-11-04-supervisor-pass21.md)/[23](sessions/2026-11-04-supervisor-pass23.md) 程（焦点/退出边界/存档/性能/文案/空态）。
- 2026-11-04 T17：[吞噬/归档](sessions/2026-11-04-t17-authorities-trust-gallery.md)、信任分层（4 档/折扣/起始页）、结局画廊（标题入口/占位/兼容）。
