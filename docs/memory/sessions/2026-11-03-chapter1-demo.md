# 2026-11-03 Chapter 1 demo（0.11.0-demo）

## 完成

按 `docs/superpowers/plans/2026-11-02-chapter1-demo-review-and-plan.md` 执行 T1–T14 + T4b：

- **像素统一**：`tests/check_pixel_assets.py` 门禁；两层 1280×720 像素档案馆背景、16×16 TileMapLayer 地面/平台、像素道具/Logo；3 张 192×256 NPC 卡片从原 800×1000 立绘裁出，脸不变；旧动画立绘不撤销。
- **Chapter 1 数据**：`ChapterPlanData` + `resources/chapters/chapter_1_demo.tres` 九房；`ch1_04` 精英（必出遗物）、`ch1_05` 事件（读禁文/拿残页）。
- **平台**：row 35 地面、row 30/28 平台；敌人可跳上第一级；`Enemy.try_jump_toward_target`。
- **武器/遗物**：demo 6+6；断页剑三击加成、链刃拉拽、墨斧破韧、墨弹枪穿透、回声笛三连、符枪标记减速；`word_slots` 假字段删除。
- **语言**：`WordRuntime` per-run 副本；Profile `decoded_words`；6 初始解码 + 12 残页词；陆沉每次解 1 个；Codex 未解码显示 glyph+模糊标签；短语签名按词 id 排序并跨局收藏；熟练度伤害 +≤25%。
- **权柄**：`AuthorityController` + `AuthorityChoiceUI` + HUD 槽；续命/改写各一次；Boss 280 HP 专属三阶段（安全区/封页/镜写）。
- **经济**：每 NPC 每次回 Hub 一次 effect；碎片/起始残页/污染/锻造祝福上限；`pending_run_bonuses` 只下一局一次；AI 不双叠。
- **教学**：Hub Codex（C）+ 训练碑（E）+ 首次教学；标题设置/新游戏（确认）；暂停重开/离开确认；失焦暂停。
- **HUD/可访问性**：默认 16px 主信息、12/16/20 可调；整数缩放；危险预警形状枚举。
- **存档/音频**：Profile v2 原子写 + `.bak`；退出音频清理；音频 `shutdown()` 已接入退出；但 `--quit-after` 强制退出仍间歇报 8 ObjectDB / 4 resources 泄漏 warning（不崩溃，待后续排查）。
- **T14**：`integration_ch1_demo.gd` 真实输入 11 项；Windows/Android 构建；导出 exe 120 FPS / 8.33 ms。

## 验证

- 单元 `tests/run_tests.gd`：3413 passed, 0 failed。
- 结构集成 `integration_playability.gd`：267 checks, 0 failures。
- 输入集成 `integration_ch1_demo.gd`：11 checks, 0 failures。
- `check_game.ps1 -Game changzi-adventure`：PASSED。
- `check_pixel_assets.py --demo`：0 failures。
- 构建：`build/windows/changzi-adventure.exe`（131 MB）、`build/android/changzi-adventure.apk`（60 MB）。
- 未做：5–10 人封闭试玩；1080p/1440p 人工截图；Boss phase 2/3 实机截图。
- 已知：强制退出仍有 8 ObjectDB / 4 resources 泄漏 warning；run save/resume（T16）仍为 P1 未做。

## 已知遗留

- 事件房“读禁文”给词但尚未接 Boss/残碑解码（B3.2 的完整解码来源留待 T7/T8 后的完整版或试玩反馈）。
- 教学在 Hub 用临时 Codex；进入正式局后 Codex 使用本局 inventory。
- Boss phase 2 安全区是程序绘制的青色区域，未做像素贴图。
- 旧绘画背景仍用于第 2–4 章；demo 不引用。
