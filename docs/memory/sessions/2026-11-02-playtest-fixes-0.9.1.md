---
name: 2026-11-02-playtest-fixes-0.9.1
description: 0.9.1 试玩修复：首页相机、对话框立绘/言灵按钮、奖励卡可读性、操作说明排版、污染惩罚、武器交换掉落、HUD 遗物栏、咕噜笑声
type: session
status: active
updated: 2026-11-02
load_when: 继续试玩修复、改对话框/HUD/污染/武器掉落、准备 0.9.x 版本时
---

# 0.9.1 试玩修复

用户试玩反馈的五条问题，加上武器掉落与遗物状态栏两条追加需求。
版本号规则：从 0.9.1 起递增，1.0 只在用户确认“最终完整版”后使用（见
[版本策略](../decisions/2026-11-02-versioning.md)）。

## 1. 首页左右移动抖动

- 根因：`Player._update_camera` 直接把 `facing.x * 32` 写进 `Camera2D.offset`。
  转身时整帧瞬间横移 64 px（对比两张截图约 95 屏幕像素，正是 1.4 倍缩放后的 64）。
  Hub 是单屏房间，相机被 `limit_left/right` 锁死，只有 offset 在动，所以像世界在滑。
- 修法：look-ahead 改为指数平滑，且与实际速度成比例；`camera_look_ahead` 导出，
  Hub 的 Player 实例设为 0。关卡里仍保留朝向前瞻，但不再瞬移。

## 2. 对话框：言灵按钮与半屏立绘

- `言灵对话 [Y]` 从 `_root` 左下角动态按钮移到面板按钮行内（左侧，继续/关闭在右）。
- 新增 `PortraitFrame` + `Portrait`：左侧 400×500（约七成屏高），按 4:5 比例，
  `STRETCH_KEEP_ASPECT_CENTERED`，不允许非等比拉伸。
- 立绘来源：用户指出角色有原图，使用 `assets/concept/characters/*_pixel.png`
  高分辨率概念图裁成上半身，输出到 `assets/portraits/`（800×1000，LANCZOS，
  亮度 0.92）。这是插画，不是 1× 精灵，显示时用线性过滤 + mipmap 保比例。
- `DialogueUI.PORTRAITS` 按中文说话人映射五名 NPC；无立绘的说话人隐藏画框。

## 3. 奖励卡未选中不可读

- 根因：奖励按钮用主题的 `button_normal`（透明底）+ 纸页主题的深墨字，未选中卡在
  暗背景上几乎看不见。
- 修法：奖励按钮显式套 `card_common` / `card_hover` / `card_selected`，未选中也是
  不透明纸底；类别朱砂、标题墨色、描述墨灰。标题“留下哪一页记忆？”显式骨白。

## 4. 操作说明排版

- 标题 24→48，栏题 24→36，正文 12→24（仍只用 12/24/36/48 四个清晰字号）。
- 面板高度改为随内容自适应（原来固定 620，下方空三分之一），宽度 960 以兼容 4:3；
  关闭按钮前加分隔线。

## 5. 污染值惩罚

- `RunState`：25/50/75/100 四档，新增档位名（低语/侵蚀/深渊/失控）与倍率：
  - 敌人伤害 +15/30/45/60%
  - 短语墨耗 +15/30/45/60%
  - 短语冷却 +0/20/35/50%
- `Game` 监听 `corruption_tier_changed`：每档弹提示 + 紫闪 + 震屏；
  `player.damage_taken_multiplier` 随档位更新；`PhraseCaster` 用实际墨耗/冷却，
  HUD 显示的墨耗也是实际值。
- 100：失控，1 秒后强制结束本局，显示“深渊回响”结局（`_finish(false, forced_ending)`）。
- HUD 污染行显示“污染 76/100 · 深渊”，颜色分档。

## 6. 武器掉落与拾取（追加需求）

- 武器不再被奖励/宝箱/商店直接覆盖：`_acquire_weapon()` 交换当前武器，旧武器在
  玩家身后 90 px 生成 `Pickup`，可走回去拾回；拾回时再交换，形成无损循环。
- 普通敌人 4% 概率掉武器；飞行敌人掉落到 y≥540 的可达高度。
- 新增 `PICKUP_SCENE` 接线；修复 Pickup 在 `_ready` 之后设坐标会被浮动漫步 tween
  拉回原点的问题（先设 position 再 add_child）。

## 7. HUD 遗物状态栏（追加需求）

- 左上角状态面板新增“遗物 N · 名称…”两行截断显示，金色；悬停 tooltip 显示
  名称 + 效果全文。背包页原本已有遗物列表，保持不变。

## 8. 咕噜笑声

- 用户提供 `奶龙大笑_爱给网_aigei_com.wav`，转成
  `assets/audio/voice/zh_cn/guru_laugh.ogg`（ffmpeg highpass + loudnorm）。
- 仅“咕噜”说话时：打开对话 45%、翻页 30% 概率播放；headless 不播。
- 来源与授权存疑，已写进 `assets/audio/manifest.json` 的 `gag` 段；
  商业发布前需确认或替换。

## 第二轮补充（同日试玩）

- **人物介绍排版**：`NPCInspireUI` 重做。标题 48、副标题/栏题 24、正文 24；左侧
  200×250 立绘（同 `assets/portraits/`）+ 来历（可滚动）+ 底部横排“职能”卡；
  右侧“对话”记录 + 24px 输入框与言灵按钮。回复颜色改为纸页可读的墨色/暗金/深紫。
- **奖励默认焦点**：第一张卡不再红框。新增 `resources/ui/card_focus.tres`：透明底 +
  3px 金色下划线，键盘焦点与“已选中”区分开；`tools/build_ui_theme.py` 会重新生成它。
- **污染 100 改为发狂**：不再直接结算。进入 30 秒发狂，生命上限压到 40%（当前生命
  同步压低），敌人伤害仍按 100 档 1.6 倍；HUD 污染行变成“污染 100/100 · 发狂 N 秒”；
  撑过 30 秒后恢复生命上限、至少回到 50% 生命，污染回落到 90，避免立即再次触发。
  发狂中死亡仍按正常死亡结算。`RunState.set_corruption()` 维护 tier 缓存，
  保证再次冲到 100 还能触发。
- **咕噜货源**：从 3 个词扩到 12 个词 + 2 件遗物（污染之眼 34、不朽档案 60）。
  遗物购买写入 `Profile.stored_relics`，下一局开局由 `Game._apply_stored_relics()`
  带入并清空；商店列表改为 `ScrollContainer`，14 条可滚动。
- **工具落位**：
  - Aseprite Wizard 9.8.0（MIT）→ `addons/AsepriteWizard/`，已在
    `project.godot` 启用；需本机 Aseprite 才能导出动画。
  - Fusion Pixel 12px Monospaced zh_hans（OFL，2026.10.25）→ `assets/fonts/`，
    替换 Ark Pixel 作为主题字体；`font_coverage.py` 从 25 个缺字降到 **0**。
    Ark Pixel 保留作上游基线，不再被引用。⚠ 改“！”，∞ 改“◯”。

## 第三轮补充：净化手段

污染惩罚变重后，玩家需要更多主动净化：

- 新词：`净化`（holy/life/purify，净化 4、治疗 2）、`洗涤`（water/holy/purify，净化 3、治疗 1、减速）、
  `赦免`（order/holy/purify，净化 6、护盾 2）。三词都进入词库、掉落池和咕噜货架。
- 共鸣：净化 + 圣 / 水 / 生命 分别追加净化与治疗；`SpellSynthesizer` 新增 purify 概念，
  自由言灵输入“净化/洗涤/赦免/洁净”也能借用回响。
- 结算：`PhraseCaster` 用 `purify` 组件抵消 `corruption_gain`，净减少时发 `purified`
  信号，Game 弹“净化：污染 -N”并青绿闪屏。
- 新遗物 `净墨灯`（`purify_flow`）：每 5 秒净化 1 点，清空房间额外 -4；可在咕噜处购买。
- 休整从 -8 提升到 -12，局内商店的“缝合书页”同样净化 12。
- 测试：词库 95、遗物 9、商店 18 条；净化解析/施放/遗物测试；单测 3040/0。

## 验证

- 单测 2982/0；集成 145/0（新增武器交换/拾回、30 秒发狂、对话立绘与按钮位置、
  HUD 污染文本、污染倍率与墨耗/冷却断言）；`check_game.ps1` 通过；`font_coverage.py` 0 缺字。
  截图新增 `04_npc_inspire`、`05_hub_shop`、`fix_reward`（金色焦点下划线）。
- 截图：`artifacts/ui/fix_dialogue.png`、`fix_reward.png`、`fix_help.png`、
  `fix_corruption_hud.png`（`tests/capture_fixes.gd`，需窗口模式）。
- 导出 0.9.1（全部修复后最终重导）：Windows release `build/windows/changzi-adventure.exe` 136 MiB；
  Android debug `build/android/changzi-adventure.apk` 58.8 MiB，已用 debug keystore 签名（META-INF/ANDROIDD），可装试玩机。
  Android release 需要自己的 release keystore，当前没有配置。
- `export_presets.cfg` 版本名 0.9.1、versionCode 10。

## 坑

- 截图脚本在 `--headless` 下会卡在 `RenderingServer.frame_post_draw`，必须窗口运行；
  可用 `--position 4000,4000` 放到屏幕外。
- Ark Pixel 12px zh_hans 2026.10.25 确实缺 25 个常用字（摇燃然热愈执施警瞬滚漩慈雾毁拖奖即紧聆筑掰药缘 + ⚠∞）；
  官方 README 建议 10/12px 用 Fusion Pixel 过渡字体。下一阶段可作为回退字体补上。
- 立绘是高分辨率插画，不要用 nearest 放大；保持比例与线性过滤才不糊。

## 下一步

- MDS 全量接入（用户已决定，见 [ADR](../decisions/2026-11-02-mds-full.md)）；第一章试点已在 0.9.2 落地，见 [MDS 全四章](2026-11-02-mds-migration.md)。
- Aseprite Wizard 动画插件：下载前需用户确认。
- Fusion Pixel 回退字体补 25 字。
- 第一章关卡按 MDS 房间图重做 + 真人试玩。
