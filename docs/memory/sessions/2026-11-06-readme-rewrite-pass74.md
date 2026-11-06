# 第 74 程 · README 重写（brief78）

> 发布前置程。依据 `.supervisor/DECISIONS.md`「用户批准发布一版 + README 重写」
> 与后续三次改口：本次发布 = 里程碑快照推送 GitHub main + 网页版更新 +
> GitHub Release `v0.12.0`（pre-release，直接带 Windows 包）。本程只重写仓库根
> `README.md`；Windows 导出、推送、网页更新、Release 创建与资产上传都不在本程。

## 任务 0 · 基线核验（HEAD `34475c1`，Godot 4.7.stable.official.5b4e0cb0f）

- `--headless --path . --import` / `--quit` 退出 0。
- 单元 `tests/run_tests.gd` **13,490 / 0**。
- 十一套集成全部跑完，与第 73 程逐套件一致、全 0 失败：
  `integration_playability` **899** / `integration_ch1_demo` **109** /
  `integration_run_save` **613** / `integration_gamepad` **207** /
  `integration_ui_prompts` **113** / `integration_ch1_event` **59** /
  `integration_menus` **445** / `integration_ai_settings` **45** /
  `integration_ch2_bigmap` **2,315** / `integration_ch3_bigmap` **4,358** /
  `integration_ch4_bigmap` **5,133**。
- `tests/check_exit_clean.sh` **10/10 clean**；`check_pixel_assets.py --demo`
  **36 / 0**。
- 结论：基线无漂移，可施工。

## 任务 1 · README 重写

### 结构

按 DECISIONS 的重写口径改为：

简介 → 当前可玩范围 → 已建成但未开放 → 核心系统（言出法随 / 权柄 /
信任分层 / 结局画廊）→ 操作 → 运行 → 开发状态。

旧 README 的 0.11.0-demo（2026-11-03）、0.10.0（2026-11-02）、0.7.0
（2026-11-01）三段版本日志和名为「当前状态」的旧日志整段删除；历史细节只指向
`docs/` 与 git 记录，不再在 README 里堆版本流水。

### 可玩 / 未开放口径

- 当前可玩写为第一章「墨雨档案馆」+ T17 系统：9 个房间区域（4 战斗 + 精英 +
  事件 + 休整 + 隐藏书库 + Boss）、清房目标 6、墨骸史官三阶段战；吞噬/归档权柄、
  四档信任分层、结局画廊；四档难度、局内存档与手柄。
- 第 2–4 章统一写为「已建成并通过各自的系统验收，因主流程接线未完成暂不可达」，
  列出每章 9 个连通大区、22 扇门、纵向/捷径/事件/隐藏书库/Boss 与三章各自的
  大图验收断言数（2,315 / 4,358 / 5,133）。
- 删除「依次穿过四章」「章末选择会改变结局」这类与现状不符的笼统说法。
- 结局按实现核实：demo 内可达 3/5（深渊回响、未完的注脚、记录中断）；「复原」
  需要跨章仁慈 ≥2，而第一章章末只能 +1；「焚毁档案」只在第四章流程触发。
  两者都暂不可达，README 明确写出。

### 删除 / 修正

- 删除 SAPI 旁白宣传段与 `docs/audio/README.md` 的旁白引导；删除 Android /
  触屏行与「触屏」操作。
- 配乐口径统一：旧文一处「六首 + 22 段旁白」、一处「五首 + 18 段旁白」；新文只在
  「运行」写一次「6 首原创循环曲目」，不提旁白段数。
- 旧测试数字 3083 / 265 改为单元 13,490、集成 14,296。
- 旧「50 个可收集词」「8 种法术形态」改为 95 词条、13 形态。
- 旧流程「六房 + 精英/事件/休息/书库 → 墨骸史官 → 续命/改写 → 未完待续」不再
  作为主叙述；改为「第一章 → 章末选择 → 结局屏 → 回 Hub」。

## 核实的数字与来源

| 数字 | 来源（仓库实测） |
|---|---|
| 词条 95（39 名词 / 29 动词 / 27 修饰） | `resources/words/*.tres` 95 个；`tests/test_content_expanded.gd` 锁定 95 与 39/29/27 |
| 首次开局 18 个词（6 已解码 + 12 未解码） | `Profile.DEFAULT_OWNED` 18、`Profile.DEFAULT_DECODED` 6、`RunLoot.DEMO_FRAGMENT_WORDS` 12 |
| demo 6 武器 / 6 遗物；内容库 12 / 9 / 14 | `ContentLibrary.DEMO_WEAPONS` / `DEMO_RELICS` / `WEAPONS` / `RELICS` / `ENEMIES` |
| 第一章 9 房间、清房目标 6 | `resources/chapters/chapter_1_demo.tres`（4 combat + 1 elite + 1 event + rest + boss + vault） |
| 13 种法术形态 | `scripts/language/spell_style.gd::SpellStyle.NAMES` |
| 4 档难度 | `scripts/core/difficulty.gd` |
| 档案馆 4 方向、demo 上限 10 | `scripts/core/archive_data.gd::TRACKS` / `MAX_LEVEL` |
| 信任 0/2/6/12 四档 | `scripts/core/trust_data.gd::THRESHOLDS` / `TIER_NAMES` |
| 5 个结局 | `scripts/core/campaign_data.gd::ENDINGS` |
| 6 首配乐 | `assets/audio/manifest.json` music.tracks（6 条） |
| 155 个脚本 / 26,849 行（约 2.7 万） | `scripts/` 下 `.gd` 统计（不含 addons/tests） |
| 单元 13,490 | `tests/run_tests.gd` 收尾复跑 |
| 11 套集成 14,296 断言 | 899 / 109 / 613 / 207 / 113 / 59 / 445 / 45 / 2,315 / 4,358 / 5,133 |
| 第 2/3/4 章大图验收 2,315 / 4,358 / 5,133 | 同上 |

关于 brief 里的「可收集 50」：仓库没有 collectible 标记，95 个词全部在
`ContentLibrary.WORDS`；demo 实际开局拥有 18 个。按「核不实宁可不写」，
README 只写 95 与 18。

## 自查与验证

- 结构顺序符合重写口径；全文无 SAPI / Android / 触屏 /「依次穿过四章」/ 旧版本号。
- 可玩与未开放分区明确，未把第 2–4 章或未达成结局写成可玩。
- 配乐数字全文只出现一次（6 首），其余数字各只出现一处且可在仓库复核。
- 只改 `README.md`；提交 `a5053a4`（docs）。
- 基线复跑与开工前逐项一致，无产品代码/场景/资源/测试改动；未推送、未更新网页版、
  未创建 Release、未宣布里程碑；第 2–4 章仍不可达、第 11–16 项未碰。

## 下一程

Windows 导出程（按 DECISIONS「再更正」排在 README 程之后、里程碑推送与 Release
之前）：用既有 `export_presets.cfg` Windows 预设从当前 HEAD 导出并打 zip，核验
exe + pck + 体积、记录导出日志与文件清单；Windows 实机首跑不在该程范围。
