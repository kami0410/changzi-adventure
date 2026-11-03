---
name: 2026-11-01-world-animation-npc
description: 0.7.0 世界与同行者版：14 种敌人/程序化骨骼动画/战斗特效/五 NPC AI 言灵/剧情圣经/120 FPS/键位与宝箱
metadata:
  type: project
---

# 0.7.0 世界与同行者

## 做了什么

- **敌人**：从 10 种扩到 14 种，新增墨囊投手、合唱召引者、镜面狙手、残页群；老敌人增加 2–4 段攻击变体。房间第二波仍由 `Room.queue_wave` 追踪。
- **动画**：`ActorMotion` 重写为程序化骨骼：头/躯干/双腿分离、弹簧压缩、跑步/跳跃/受击/施法/死亡、尾/翼/触须二次运动；玩家新增三段连击、突进、围巾 `ScarfRibbon`、脚步扬尘。
- **特效**：`CombatFX` 重做斩击/命中/死亡/施法/预警/冲击波/治疗/炸弹/光束；`SpellVFX` 增加共享墨晕、符文与速度线。
- **NPC**：`NPCProfiles` 五个角色（陆沉/阿砚/咕噜/闻烬/白榆），每个有背景、性格、两条职能、关键词效果与 AI 提示词；`NPCInspireUI` 支持自由言灵、AI 回应、职能按钮；`Profile.npc_blessings/npc_trust` 持久化。阿砚 = 锻造之神。
- **AI**：`AIService.request_npc_reply` 使用角色提示词与 JSON 回复/effect；`NPCProfiles.apply_effect` 应用折扣、神铸、起始残页/污染、情报与信任。
- **剧情**：`docs/story-bible.md` 完整四章、五结局、角色弧光；`CampaignData` 开场/章末扩写。
- **可访问性/操作**：`HelpUI`（H）、`KeybindUI`（F10 → 键位设置）、`GameFlow` 运行时 InputMap 与 `Profile.keybinds` 持久化；默认 120 FPS、vsync 关闭。
- **宝箱**：`TreasureChest` 每章两座，`RunLoot.chest_loot` 可出武器/词/遗物/残页。
- **地图**：每章 6 战斗房 + Boss，7 个房间；`_setup_campaign` 按 x 排序，避免节点顺序问题。

## 验证

- `--import` 无解析错误。
- 全量测试 2114 通过；集成 135 检查通过。
- 截图验证：玩家奔跑/攻击、敌人战斗、NPC 言灵 UI、操作说明、键位设置。

## 重要坑

- 单张纹理直接放大到 1024 会变成巨物：敌人素材必须先裁 alpha、缩到 96×96；`ink_bomber` 曾漏做。
- 生成图背景不是透明，`rembg u2netp` 对暗背景不可靠；纯黑底图用阈值抠图，复杂场景用 silueta 后手工修边。
- `Inventory.add_word()` 返回 void，不能写进 `if`。
- 集成测试卡住先看早期解析错误，不要只等超时。
- 下载模型/插件前先问用户；u2net 模型已移到 `tools/models/rembg/u2net`。
