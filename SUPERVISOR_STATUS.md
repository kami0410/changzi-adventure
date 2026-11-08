# 监工状态 · 昌子大冒险（Windows 阶段）

> 更新时间：2026-11-08（第 101 程做全游戏例行扫描：先收尾第 100 程中断留下的「不灭档案复活用完仍被重新武装」存档修复（`world.relic_revive_used`），再跑完整基线（单元 13,559 / 十一套集成 15,003 / 退出 10/10 / 像素 40-0），然后六面扫描并修三处：暂停确认取消后仍武装会让「重新开始」同时执行「返回档案馆」而丢局、死亡横幅把遗物叫成「不灭档案」（资源名是「不朽档案」）、档案馆页关页不还焦点（一致性缺口，当前玩家不可见）；未推送、未更新网页版、未创建 Release）
> 状态文件由监工/执行 AI 维护；设计问题只记录在「待用户确认」，不擅自实现。

## 里程碑记录

- **T17 里程碑（2026-11-04，监工推送）**：第 25 程成果已由监工通过连接器快照推送到 GitHub `main`，远程提交 `4bc8801b21a218dba870c3100a27e6df73d427dd`；相对上次推送基线 `4c425a8` 为 37 个 UTF-8 文本文件（13 新增、24 修改，无删除、无二进制），对应本地 HEAD `a6d8b72`（吞噬/归档权柄、信任分层、结局画廊、残碑测试稳健性、状态与记忆收尾）。网页版已同步到同一版本（公网 200）。本程只做本地记录与第 2 章大地图核查，不再次推送。
- **v0.12.0 里程碑（2026-11-06，监工推送）**：用户 2026-11-06 13:35 批准发布一版（13:41 加 GitHub Release、13:42 加 Windows 包）。第 26–75 程成果已由监工通过连接器快照推送到 GitHub `main`，远程提交 `39c2b8915638d38dc1d5d58086736c556d551b52`（`list_commits` 回读验证）；相对上次推送基线 `a6d8b72` 为 243 个 UTF-8 文本文件（207 新增、36 修改，无删除、无二进制，共 2.65 MiB），对应本地 HEAD `7226789`（第 2–4 章大地图计划/世界/事件/波次/Boss 机制/章末收口与系统验收、NPC 个人事件第一批、结局文本加厚、例行扫描修复、README 重写、Windows 导出 v0.12.0）。推送前核查：远程 main 头仍为 T17 提交 `4bc8801…`、无他人写入；29 个已同步路径无分歧、214 个新路径抽查确认远程不存在、7 个改过但未同步过的文件远程内容与原始基线 `e8f1f31` 逐字节一致（无并发修改）；同步记录已追加第 3 条。网页版已同步更新到同一版本（`redeploy-ok: 7226789`，公网 200，https://9000-agqxti4zkm5wv27ds3qk3h33gy.instabox.tech/）。GitHub Release `v0.12.0`（pre-release）本身尚未创建：需用户本人浏览器登录 + passkey 创建并上传 `artifacts/releases/v0.12.0/changzi-adventure-v0.12.0-windows.zip`（连接器无创建 Release 接口）。
- **第 1–4 章接线里程碑（2026-11-08，监工巡查，推送部分未完成）**：网页版已同步更新到本地 HEAD `34bcdd7`（第 97 程收尾，`redeploy-ok: 34bcdd7`，公网 200，https://9000-agqxti4zkm5wv27ds3qk3h33gy.instabox.tech/），浏览器里已可玩完整 1–4 章。**GitHub `main` 推送被跳过**：相对上次推送基线（`main` = v0.12.0 提交 `39c2b891…`）的改动含 4 个新增二进制文件——第 78 程接入的第 2 章敌人精灵 `assets/sprites/enemies/breath_hound.png` / `lung_moth.png` / `rust_whisperer.png` / `collapse_husk.png`（各配一个 `.import` 文本文件；共 412 个改动文件、无删除）。连接器快照推送只接受 UTF-8 文本文件，按任务纪律含二进制即跳过推送；不要尝试 `gh auth login`、PAT、OAuth 或 git 命令行推送——那四张图只能由用户本人从他自己的 git 推送到 `main`，之后监工再补推其余文本改动。**第 101 程更新**：四张 PNG 已由用户授权、经助理用 GitHub 网页端推上 `main`，远程提交 `90a1960`（父提交 `39c2b89`），二进制障碍已解除；剩余文本改动待监工在树干净、测试全绿、无会话在跑时补推。

## 项目现状（一句话）

demo 已可完整游玩第 1–4 章（标题 → Hub 教学 → 第 1 章「墨雨档案馆」→ 章末选择 → 第 2 章「呼吸废墟」大图 → 章末选择 → 第 3 章「无光海」大图 → 章末选择 → 第 4 章「笑面剧场」大图 → 章末选择 → 结局屏 → 回 Hub），五个结局全部可达成且判定只在战役结束。第 101 程做第 100 程例行扫描的第四次接力（前三次会启动即死）：先收尾工作区里第 100 程中断留下的存档修复——不灭档案的复活是每局一次，但用掉的标志只活在 `RelicEffects` 上、不进 run save，复活后存检查点再续玩会被重新武装并免费再救一次；现写入 `world.relic_revive_used` 并在`_restore_run_save` 恢复（旧档缺键按 false，行为不变）。随后做六面例行扫描并修三处：① 暂停菜单「返回档案馆」确认取消后动作仍武装，再确认「重新开始」会同时执行两个动作，玩家被送回 Hub 且本局作废（第 73 程记为「当前不可见」，本程实测可见并修复）；② 死亡横幅把复活遗物叫成「不灭档案」，而资源名与背包/奖励/货架/ GDD 都是「不朽档案」；③ 档案馆页关闭不还焦点（Hub 轮询按键，当前玩家不可见，按一致性补齐）。收尾基线：单元 **13,575 / 0**、十一套集成 **15,009**、退出 10/10、像素 40/0。未推送、未更新网页版、未创建 Release。
局内存档与手柄支持已落地，单元/集成测试全绿，Windows 构建链路已验证。按用户 2026-11-03 的决定，打包、安装器编译、代码签名、Windows 实机验证与人工截图全部推迟到很久以后的发行阶段，现阶段不做；当前重点是在保持第一章 demo 稳定的前提下，按监工计划推进第 2 章内容。第 26 程已完成第 2 章大地图可行性核查（结论见下方专节）；第 27 程完成施工第 1 步的三项基础解耦（坠落平面按房间/区域配置、一次性内容与清房进度按节点 id、章节清房目标读计划）；第 28 程完成施工第 2 步的房间生产管线（`BigRoomData` + `MDSBigRoom`：可变尺寸/多矩形并集、多层地面与平台、按区背景平铺与按相机窗口的氛围、自动门、坠落平面 metadata）；第 29 程完成施工第 3 步的纵向/捷径道具管线（单向落台、塌陷平台、电梯/移动平台、长椅检查点、条件门捷径）；第 30 程完成施工第 4 步前半段的第 2 章计划与大区图骨架（9 区连通图、清房目标按遭遇节点派生为 7、图骨架夹具与校验）。第 31 程完成施工第 4 步后半段：9 个真实大区 `BigRoomData` + `MDSBigRoom` 场景与独立世界 `chapter_2_bigmap.mdsworld.json`/`_world.tscn` 落地，`game.gd` 按计划读起始区（`ch2_entry`）、清房目标（7）与坠落平面（区高 + 240），一区多内容按节点 id 结算；旧第 2 章 9 小房间世界原地保留但不再被引用。第 32 程完成第 2 章内容数据层第 1 步：新增 `Ch2EventData`（7 组呼吸废墟文案，按局 seed + 事件节点 id 确定性轮换）、`game.gd` 事件页/权柄授予/Boss 阶段文案改为按章节查表（第 1 章行为与文案不变）、第 2 章计划补续命/改写基础权柄池、`BossEntranceData`/`BossPhaseData` 补「肺钟守卫」入场与阶段文案，并校验计划遭遇节点与既有第 2 章波次一一对应（6 场战斗 + 1 事件，清房目标仍 7）。第 1 章仍走原 `MDSChapterRoom`、行为与基线一致，第 2–4 章仍不可达；第 2 章事件页/Boss 权柄仅在测试层驱动验证。第 33 程完成第 2 章内容数据层第 2 步的波次接线：计划 `wave` 改为「遭遇节点 id → 敌人数组」字典，6 场战斗按计划顺序各配一波（= `ROOM_WAVES[1]` 原文，波次内容未改），事件节点无波、Boss 区不占普通波次；`game.gd` 大图分支按节点生成敌人并逐场锁门/结算，第 1 章生成路径与波次不变。第 34 程完成第 2 章内容数据层第 3 步：`ch2_event` 事件区接上区域级真实自动触发（`big_map` + `type == "event"` + 本章有事件数据），进入区域即按 `Ch2EventData.pick(run_seed, 事件节点 id)` 打开第 2 章事件页；结算按 `cleared_encounters` 的 `ch2_event/event` 一次性记录，重载不重开、不重复发奖励；第 1 章事件房触发/文案/选项/数值未改，第 2 章仍不可达。第 35 程完成第 2 章 Boss 2「肺钟守卫」独特机制与章末收口：计划 `boss_scene` 路由到 `LungBellGuardian`（`InkArchivist` 子类，通用 Boss 流程复用），实现呼吸（吸气承伤 0.5× / 呼气 1.5× + 气环、阶段 2 加墨池）、钟摆双向、阶段 3 钉子窗口（5 s 1.5× / 7 s 0.6×）；第 2 章章末选择后 `_finish(true)` 停章，不再自动进入未实现的第 3 章；同时修复大图 Arena 敌人/Boss 生成在地下的高度缺陷。第 1 章 Boss/流程/9 房间/6 波次/事件均无回归，第 2 章仍不可达；Boss 数值为暂定口径并由测试锁定。第 36 程完成第 2 章大地图系统验收：按 D 节 1–10 项补齐真实集成（九区连通、边界/相机、纵向往返、过渡、一次性内容、多遭遇战斗、捷径/隐藏、Boss/章末、性能、叙事系统），共 1303 断言 0 失败；验收中发现并修复「从地面（bot）门到达后约 0.7 秒被同门弹回上一房间」的真实缺陷（MDS `floor_arrival_grace` 1.2 秒，仅 bot 门），第 1 章无回归，第 2 章仍不可达。下一步由监工按总计划安排（第 2 章仍不可达）；「待用户确认」第 9/10 项已由监工拍板（大区连通图、不新增移动能力），第 36 程新增第 11/12 项待拍板（捷径获取来源、电梯节奏）。第 37 程完成两项表现打磨：九区 22 扇门全部补上可见门扉与提示（`GateVisual` 复用 `ChapterDoor` 语言，side 感知、前往/来路提示、零碰撞零信号，门逻辑/门位/单向/条件门未动）；第 2 章新局出生点改到 `ch2_entry` 作者 `SpawnPoint`（`save_point` 组，台阶面 − `FOOT_Y`），不再从房间标签锚点空中坠落。单元 7901 / 第 2 章集成 2202，第 1 章无回归，第 2 章仍不可达；大区底部相机/HUD 遮挡记为待确认第 13 项。第 38 程完成两项内容/表现缺口：① `MapOverlay` 地图标题改为按 `CampaignData.chapter(i)["region"]` 派生——第 1 章冻结「档案馆地图」一字不改，第 2 章显示「呼吸废墟地图」，第 3/4 章同规则；② 第 2 章五种敌人美术核查：仅 `choir_summoner` 有专属精灵（已在 `ENEMY_ART`、白 tint）并由测试锁定，`breath_hound`/`lung_moth`/`rust_whisperer`/`collapse_husk` 无专属美术、继续第 1 章精灵 `#c8e1cd` 回退，缺失清单已记录。单元 8011 / 第 2 章集成 2209，第 1 章无回归，第 2 章仍不可达。第 39 程完成第 3 章大地图可行性核查（只查不施工）：9 房旧线性世界/17 门/6 波次/文本语音/Boss 3 专属脚本与立绘均已存在；缺口是计划、大区世界、事件数据、权柄池、Boss 入场/阶段文案与第 3 章大图验收套件，另有海面母题、视野压缩、捷径授予来源与章末边界四项第 3 章独有差异；第 2 章走通的大区管线可直接承载第 3 章，第 3 章施工未开始。第 40 程完成第 3 章大地图施工第 1 步（计划与图骨架）：新增 `resources/chapters/chapter_3_demo.tres`（9 区连通图：入口/两条可回环支路/枢纽/纵井/隐藏书库/事件占位/精英/Boss；6 个战斗遭遇对应旧 6 波但未接线 + 1 个事件占位 → 清房目标 7；3 宝箱/2 残碑；11 门 = 9 双向 + 2 显式单向；每区 `fall_below_bounds = 240`）与图骨架夹具 `tests/fixtures/big_room/ch3_graph.mdsworld.json`（`fixture: true`、无房间场景、永不加载），新增 `ChapterPlanData.content_pending` 只推迟波次表校验；计划未接入 `game.gd`（`CHAPTER_PLAN_PATHS[2]` 仍空），旧第 3 章 9 房世界原样保留，第 3 章仍不可达。详见下方「第 3 章计划与图骨架（第 40 程）」专节与两篇核查/施工记录。第 41 程完成第 3 章大地图施工第 2 步（真实大区世界，只做结构层）：9 个 `BigRoomData`（`resources/rooms/ch3_bigmap/`）与 9 个 `MDSBigRoom` 场景（`scenes/mds/ch3_bigmap/`）按第 40 程计划的尺寸/节点 id/门名落地，每区 `fall_below_bounds = 240`、`ch3_entry` 作者 `SpawnPoint`（台阶面 − `FOOT_Y`）；独立世界 `scenes/mds/chapter_3_bigmap.mdsworld.json` + `_world.tscn` 共 9 区 22 门（20 有向 + 2 只到达；`elite_boss` 单向、`hub_shortcut_entry` 带 `requires = ["ch3_shortcut"]` 的屏障默认封闭），旧第 3 章 9 房世界原样保留；新增 `tests/test_ch3_world.gd`（771 断言）交叉校验计划↔世界，`CHAPTER_PLAN_PATHS[2]` 仍空、第 3 章仍不可达；第 14/15/16 项留空未施工。详见下方「第 3 章真实大区世界（第 41 程）」专节。第 42 程完成第 3 章内容数据层第 1 步（只做数据层）：新增 `Ch3EventData`（7 组无光海事件文案，按局 seed + 事件节点 id `ch3_event/event` 确定性轮换，不消耗 run RNG；读/拿效果沿用第 32 程口径——读 → 污染 +8 + 解明一个残页词 / 兜底残页 +6，拿 → 残页 +12）；`game.gd` 的 `_event_data` 扩到第 3 章（第 1 章原键与原值、第 2 章 `Ch2EventData` 均不变，第 4 章仍无事件页）；`_grant_chapter_authority` 在第 32 程已按计划 `authority_pool` 授予，本程给 `chapter_3_demo.tres` 补 `authority_pool = [续命, 改写]`（条件项仍走 `ContentLibrary` 的吞噬/归档）；`BossEntranceData`/`BossPhaseData` 补第 3 章「最后的读者」8 条入场 + 8×2 条阶段文案（第 4 章仍静默，第 1/2 章选句键与文案不变，Boss 3 数值/立绘/`boss_script` 未改）；新增 `tests/test_ch3_content.gd`（570 断言）锁定事件确定性/效果类型、权柄基础+条件项、Boss 文案不回落第 1/2 章、7 个遭遇节点唯一且锚定、6 场战斗与 `ROOM_WAVES[2]` 六波按计划顺序对应（事件节点无波次）、清房目标仍 7，并锁 `CHAPTER_PLAN_PATHS[2]` 仍空、旧第 3 章 9 房/17 门/世界文件仍在、第 1/2 章计划与世界不变。计划仍未接入 `game.gd`、第 3 章仍不可达、事件区无真实触发点；已知缺口：第 3 章计划区域仍无 `wave` 键，大区 Arena 不会生成敌人，波次接线留给后续内容程；第 14/15/16 项留空未施工。第 43 程完成第 3 章内容数据层第 2 步（波次接线）：计划 4 个战斗区补 `wave` 字典，6 个战斗遭遇按计划顺序逐字接上 `ROOM_WAVES[2]` 六波，事件节点与 Boss 区不占普通波次、清房目标仍 7；`content_pending` 按第 40 程约定清零、波次表进入正常校验（标志保留在 `ChapterPlanData`；图夹具顶层的同名键是夹具元数据、未改）；第 3 章计划仍未接入 `game.gd`、事件仍无真实触发、Boss 3 仍无 `boss_scene`/机制，第 3 章仍不可达；第 14/15/16 项留空未施工。第 44 程完成第 3 章内容数据层第 3 步：`ch3_event` 事件区沿用第 34 程的通用大图区域触发（`big_map` + `type == "event"` + 本章有事件数据）接上真实自动触发——进入区域即按 `Ch3EventData.pick(run_seed, 事件节点 id)` 打开第 3 章事件页，结算按 `cleared_encounters` 的 `ch3_event/event` 一次，重载不重开、不重复奖励；读 / 拿沿用第 42 程口径（读 → 污染 +8 + 解明一个残页词 / 兜底残页 +6，拿 → 残页 +12）。未新增第 3 章专属触发路径、未接入 `game.gd`、未改章节路由与章末流程，第 3 章仍不可达；Boss 3 机制 / `boss_scene` 与第 3 章大图验收仍是后续程的事。第 45 程完成第 3 章 Boss 3「最后的读者」独特机制与 `boss_scene` 路由（只做机制与测试层）：`chapter_3_demo.tres` 的 `boss_scene` 指向既有 `last_reader.tscn`（`LastReader extends InkArchivist`，通用 Boss 流程复用），`_spawn_boss` 优先级与 `boss_script == reader` 兜底不变；机制为镜面弹幕（阶段 1/2/3 = 3/5/7 枚、张角 0.28/0.40/0.52 rad、0.7×/270）、读页封印（阶段 2 起每 3 次、0.8× 预警 + 封一个短语槽 3.0 s）、阶段 3 空白页承伤窗口（11 s 周期：展开 4.5 s ×1.5 / 合书 6.5 s ×0.6）；HP 380 / 伤害 15 / 速度 78 / 立绘 / `boss_script` 未改，数值为暂定口径并由 `test_ch3_boss` 锁定；大图生成高度沿用第 35 程 `_enemy_spawn_y()`（计划在 → -18 px）并补断言。`CHAPTER_PLAN_PATHS[2]` 仍空、第 3 章仍不可达（旧世界仍被游戏使用），章末自动进第 4 章未改；第 3 章大图验收、门视觉、章末收口仍是后续程。第 46 程完成第 3 章章末收口（只做章末流程与测试层）：`_complete_chapter` 在既有第 2 章分支之后新增 `_chapter == 2` 分支，章末选择后调用现有 `_finish(true)` 停章，不再自动进入未实现的第 4 章；第 1 章/第 2 章/第 4 章分支未改。章末文本/选项/语音本已齐全（`CampaignData` 的 4 句 outro、两选项、`ch3_outro`，`_apply_chapter_choice` 的 `lightless_sea` 分支），未新编剧情；续玩/重载沿用章节无关的 `_boss_defeated` → `_resume_boss_aftermath` 口径，本程只补断言。`tests/integration_playability.gd` 的 `_test_ch3_bigmap_boss` 扩为完整章末链路（真实大区世界 + 第 3 章计划临时挂载：Boss 3 击败 → 权柄 → outro → 章末选择 → 停章，不进入第 4 章），并在旧线性世界结构遍历里把「自动进第 4 章」改为「停在第 3 章」；可玩性集成 732 → **754**（+22）。`CHAPTER_PLAN_PATHS[2]` 仍空、第 3 章仍不可达、计划仍未接入 `game.gd`；第 3 章大图验收、门视觉、地图标题/敌人美术核查仍是后续程。第 47 程因 Magpie 网关中断夭折（`.supervisor/session49.log` 仅一行 `[claude-code:unrecognized_model]`，无提交，只留下未提交的 `tests/integration_ch3_bigmap.gd`）；第 48 程接力完成第 3 章大地图系统验收：核查并补齐验收脚本，`tests/integration_ch3_bigmap.gd` **3424 断言 0 失败**（连续两次），覆盖九区连通/22 门全走/边界相机/纵向/过渡/一次性/双遭遇/捷径隐藏/Boss/续玩/性能，并记录第 3 章性能基线（普通区首次 6.0–9.2 ms、热 6.1–7.7 ms；Boss 冷 41.1–41.4 ms / 热 24.0–24.4 ms；关动态背景 5.6–5.8 ms、关天气 19.8–20.3 ms、不生成 Boss 12.5–12.8 ms；门过渡 228–234 ms）。未发现产品缺陷（4 处验收脚本自身的断言口径/门冷却/延迟后续流程竞态/API 误用已修）；`CHAPTER_PLAN_PATHS[2]` 仍空、第 3 章仍未接入 `game.gd`、不可达；第 3 章门视觉专项、地图标题/敌人美术核查仍是后续程。第 49 程完成这两项：① 第 3 章大图门视觉专项——`GateVisual` 由 `MDSBigRoom` 通用挂载、第 41 程 9 个场景 22 扇门（20 有向 + 2 仅到达）已自动覆盖，本程补逐门断言（side、门底落面、标题内收、箭头语义、20+2 与 5/5/5/5/2 构成）并发现/修复真实缺陷「top/bot 舱口贴墙时 200 px 标题框越出房间」（`ch3_well/top1` 与 `ch2_well/top1`，x=80 左溢 20 px；`GateVisual` 新增 `caption_area`、`MDSBigRoom` 传入，标题夹入房间，左右门规则不变）；② 第 3 章敌人美术核查——`ROOM_WAVES[2]` 六波实际用 8 种：`mirror_sniper`（第 3 章专属）与沿用第 1 章的 `hanging_scribe`/`echo_enemy`/`typo_beast`/`page_swarm` 有专属 PNG、白 tint；沿用第 2 章的 `rust_whisperer`/`lung_moth`/`collapse_husk` 无专属美术、继续第 1 章回退 + `#c8e1cd`（缺失清单记录、不新绘）；`echo_enemy` 数据资源名为 `amnesiac_echo`。地图标题「无光海地图」复核不变。单元 10315/0、第 3 章大图集成 4235/0（3424 → +811）、第 2 章大图集成 2209/0，其余套件与基线一致；第 1/2 章门视觉与敌人美术无回归，第 3 章仍不可达、未接入 `game.gd`。第 50 程完成第 4 章大地图可行性核查（只查不施工）：第 2/3 章走通的 `BigRoomData` + `MDSBigRoom`、按节点 id 结算、按区域坠落平面、计划派生清房目标与按遭遇节点 id 的波次均可直接承载第 4 章；第 4 章现有旧世界 9 房/17 门/单层 1280×720、6 战斗 + 休整 + 书库 + Boss，主线文本 8 句开场/4 句章末/2 选项、`chapter_theater.ogg`、`ch4_intro/outro`、Boss 阶段语音与 Boss 4「笑面史官」专属脚本/场景/立绘（镜面弹幕 + 基类纸页波/墨雨/改写）均已存在；缺口是计划（`chapter_4_demo.tres` 不存在、`CHAPTER_PLAN_PATHS[3]` 为空）、大区世界、事件数据、权柄池、Boss 入场/阶段文案、Boss 4 专章机制与第 4 章大图验收套件。第 4 章美术素材经复核已画好并接线：舞台绘画 `smiling_theater.png`（1536×864，`TheaterBackdrop` 只叠加聚光灯/浮尘）、Boss `smiling_archivist.png`、8 种实际使用的敌人精灵全部有专属美术且无回退（含 `mask_enemy`/`seat_husk` 两个美术变体）、配乐与语音齐全；README/GDD 的旧「程序化绘制、待替换插画」记录已在第 7 程更正，本次复核与当前文档一致。第 4 章仍不可达、未接入 `game.gd`，可达性须单独拍板且不能早于第 2/3 章。第 51 程完成第 4 章大地图施工第 1 步（计划与图骨架）：新增 `resources/chapters/chapter_4_demo.tres` 9 区连通图（入口/两条可回环支路/枢纽/纵井/隐藏书库/事件占位/精英/Boss），6 个战斗遭遇按计划顺序对应旧 `ROOM_WAVES[3]` 六波但未接线 + 1 个事件占位 → 清房目标 7；3 宝箱/2 残碑；11 门 = 9 双向 + 2 显式单向（`elite_boss` 单向、`hub_shortcut_entry` 带 `requires: ["ch4_shortcut"]` 默认封闭、来源待拍板）；每区 `fall_below_bounds = 240`；`content_pending = true` 只推迟波次表。图骨架夹具 `tests/fixtures/big_room/ch4_graph.mdsworld.json` + `tests/test_ch4_plan.gd` 778 断言交叉校验；计划未接入 `game.gd`（`CHAPTER_PLAN_PATHS[3]` 仍空）、旧第 4 章 9 房世界原样保留、第 4 章仍不可达；`Ch4EventData`/权柄池/波次接线/Boss 文案与机制均未做。本程为接力重试（第 51 程首次尝试因 Magpie 网关中断夭折，无提交无残留）。第 52 程完成第 4 章真实大区世界（只做结构层）：9 个 `BigRoomData`（`resources/rooms/ch4_bigmap/`）与 9 个 `MDSBigRoom` 场景（`scenes/mds/ch4_bigmap/`）按第 51 程计划的尺寸/节点 id/内容 id 落地（2560×1440；纵井 2560×2160；精英/Boss 3840×2160；地面贴底、平台 80 px 阶梯链、`validate()` 全空；每区 `fall_margin = 240`），`ch4_entry` 作者 `SpawnPoint`（台阶面 − `FOOT_Y`）；独立世界 `scenes/mds/chapter_4_bigmap.mdsworld.json` + `chapter_4_bigmap_world.tscn`（9 区、22 门 = 20 有向 + 2 只到达、`elite_boss` 单向、`hub_shortcut_entry` 带 `requires = ["ch4_shortcut"]` 默认封闭、区域 `Smiling Theater` 灰烬/光柱 + `blood_moon` Boss 背景、`background` 空、无 `backdrop_image`/无 theater 层）；纵向/捷径骨架复用第 29 程管线（`branch_b`/`hub`/`vault`/`well`/`elite` 5 台电梯、纵井 3 个单向落台、枢纽长椅检查点），电梯沿用管线默认 80 px/s；新增 `tests/test_ch4_world.gd` 812 断言交叉校验计划↔世界，`test_ch4_plan` 的「`ch4_bigmap` 目录尚未创建」锁改为目录/文件存在（778 → 796）。世界仍不被 `game.gd` 引用（`CHAPTER_PLAN_PATHS[3]` 仍空），旧第 4 章 9 房/17 门世界原样保留，第 4 章仍不可达；舞台母题/`ch4_shortcut` 来源/战斗密度/`mask_enemy`/`seat_husk` 独立数值/Boss 4 机制/阿砚同行仍留空未施工。第 53 程完成第 4 章内容数据层第 1 步（只做数据层）：新增 `Ch4EventData`（7 组笑面剧场事件文案：纸人/面具/名册/幕布/台词/聚光灯/谢幕，按局 seed + 事件节点 id `ch4_event/event` 确定性轮换、不耗 run RNG；读 → 污染 +8 + 解明残页词/兜底残页 +6，拿 → 残页 +12）；`game.gd` 的 `_event_data` 扩到第 4 章（第 1–3 章选句键与数值不变，越界章节仍无页面）；`chapter_4_demo.tres` 补 `authority_pool = [续命, 改写]`（条件项仍走 `ContentLibrary`）；`BossEntranceData` 补「笑面史官」8 条入场、`BossPhaseData` 补阶段 2/3 各 8 条（第 1 章保留 `"%d:%d"` 选句键，第 2/3/4 章用 `"%d:%d:%d"`，不回落第 1/2/3 章）；Boss 4 数值/立绘/`boss_script` 未改，仍无 `boss_scene`/专章机制。计划仍 `content_pending = true`、7 个区域均无 `wave` 表（6 场战斗与 `ROOM_WAVES[3]` 六波仅校验计划顺序，清房目标仍 7），计划仍未接入 `game.gd`（`CHAPTER_PLAN_PATHS[3]` 仍空），旧第 4 章世界原样保留，第 4 章仍不可达。新增 `tests/test_ch4_content.gd` 613 断言；单元 12545/0，十套集成与基线一致全 0 失败。第 54 程完成第 4 章内容数据层第 2 步（波次接线，只做数据层）：`chapter_4_demo.tres` 的 4 个战斗区补 `wave` 字典，6 个战斗遭遇按计划顺序逐字接上 `ROOM_WAVES[3]` 六波（波次内容未新增/未修改），事件节点与 Boss 区不占普通波次、清房目标仍 7；`content_pending` 清零、波次表进入 `validate()` 正常校验；第 4 章计划仍未接入 `game.gd`（`CHAPTER_PLAN_PATHS[3]` 仍空）、事件区仍无真实触发、Boss 4 仍无 `boss_scene`/机制，第 4 章仍不可达。`test_ch4_content` 641（+28）、`test_ch4_plan` 795（−1）、`test_ch4_world` 813（+1）；单元 12573/0，十套集成与基线一致全 0 失败。第 56 程完成第 4 章内容数据层第 3 步（事件区真实自动触发验证，只做触发与测试层）：`ch4_event` 沿用第 34 程的通用大图区域分支（`big_map` + 类型 `event` + 本章有事件数据），进入区域即按 `Ch4EventData.pick(run_seed, "ch4_event/event")` 打开第 4 章事件页；拿 → 残页 +12，读 → 污染 +8（倍率/上限 100）+ 解明一个残页词或兜底 +6；结算写 `cleared_encounters["ch4_event/event"]`、清房计数 +1（目标 7、HUD 分母 8），重载不重开/不重复奖励，run save 落盘同一键。未新增第 4 章专属触发路径（`game.gd` 仅注释改为 Chapters 2–4）、未接入 `game.gd`、未改章节路由与章末流程，第 4 章仍不可达；`test_ch4_content` 642（+1）、可玩性集成 810（+55，含新增 `_test_ch4_bigmap_event_trigger` 54 条与第 4 章旧世界恢复 1 条），单元 12574/0，其余九套集成与基线一致全 0 失败。第 57 程完成第 4 章内容数据层第 4 步：Boss 4「笑面史官」机制核查与 `boss_scene` 路由——`chapter_4_demo.tres` 的 `boss_scene` 指向既有 `smiling_archivist.tscn`（`SmilingArchivist extends InkArchivist`），通用 Boss 流程、`_spawn_boss` 优先级（战役表 → 计划 → `boss_script == smiling` → `reader` → 默认）与兜底均未改；机制按既有实现锁定（阶段 1 纸页波；阶段 2 每第 3 次镜面弹幕 3 枚/±0.34 rad/0.7×/280、其余纸页波且阶段 ≥2 双发；阶段 3 改写 → 镜面弹幕 → 墨雨 → 纸页波四拍，墨雨 3 个 0.75× 预警、改写封 0 号短语槽 3.0 s），HP 520 / 伤害 18 / 速度 92 / 立绘 / `boss_script` 未改，数值为暂定口径并由新增 `tests/test_ch4_boss.gd`（78 断言）与可玩性集成锁定；大图生成高度沿用 `_enemy_spawn_y()`（计划在 → -18 px，无计划 → 250 px）。可玩性集成新增 `_test_ch4_bigmap_boss`（真实大区世界 + 计划临时挂载：计划路由、战役表数值、Arena 地面线之上生成、阶段 2/3 第 4 章选句键、实树镜面弹幕/墨雨/改写、击败 → 权柄 → 章末选择 → 战役结束、重载不二次生成），810 → **869**；`test_ch4_plan` 795→**797**、`test_ch4_world` 813→**814**、`test_ch4_content` 642→**644**。`CHAPTER_PLAN_PATHS[3]` 仍空、`MDS_WORLD_FILES[3]` 仍指旧世界、旧第 4 章 9 房/17 门世界仍在、第 1/2/3 章计划与世界不变、清房目标 7、波次表（`content_pending = false`）、事件触发口径、`_complete_chapter` 与章节路由均未改；第 4 章仍不可达。单元 12574 → **12657/0**，其余九套集成与基线一致全 0 失败。第 58 程完成第 4 章章末收口：`_complete_chapter` 新增显式 `_chapter == 3` 分支，章末选择后 `_finish(true)` 结束战役（与旧 `else` 兜底行为等价）；真实大区世界走完 Boss 4 → 权柄 → 第 4 章 outro → 章末选择 → 战役结束，章末原文/语音/选项与结局规则由可玩性集成锁定；第 1/2/3 章章末流程未改，第 4 章仍不可达，第 4 章大图验收未开始。第 59 程完成第 4 章大地图系统验收：`tests/integration_ch4_bigmap.gd` **4869 断言 / 0 失败**（连续两次），覆盖九区连通/22 门全走/边界相机/纵向（5 台电梯实测 80 px/s）/过渡/一次性内容/双遭遇与六波实机校验/捷径隐藏/Boss/续玩/性能/叙事与第 4 章专属（笑面剧场平铺背景、灰烬光柱、`embers`、`blood_moon`、地图标题「笑面剧场地图」、8 种敌人专属美术无回退）；未发现产品行为缺陷（只修复首次尝试遗留脚本的重复声明解析错误并补覆盖缺口），`CHAPTER_PLAN_PATHS[3]` 仍空、第 2/3/4 章仍不可达、第 4 章仍未接入 `game.gd`。第 60 程按监工 2026-11-06 的样图决定，用 xvfb + OpenGL 离屏渲染为第 2/3/4 章各拍了 3 张代表性画面（入口全景 / 纵井 / Boss 战，1280×720，共 9 张，存 `artifacts/screens/ch2|ch3|ch4/`，不提交），只截图、不改任何游戏内容；截图里发现的表现层问题（底部 HUD 遮挡、背景纵向接缝、`boss_background` 被静态背景挡住、入口区套用休整文案等）只记录在「样图截图（第 60 程）」专节，本程不修。第 63 程（施工后进程中断，由第 64 程接力核验收尾）修复了其中两项可修问题：大区静态背景改为以房间底部为锚、自下而上平铺且奇数行镜像，纵向硬接缝消除；无 `Arena` 的大图房间只有在作者了长椅或商店时才走休整文案/目标，三章入口不再套用别章休整文案。第 76–77 程完成第 2 章可达性接线第 1 步：第 1 章章末选择后不再结束 demo，而是保留 `demo_cleared`（并落盘）进入第 2 章大图世界——开场 6 句 + `ch2_intro` 语音 + `chapter_breathing.ogg`、`ch2_entry` 出生、清房目标 7（HUD 8）、坠落平面 1680、Boss 2 → 权柄 → outro → 章末停章全链路打通；第 2 章计划/波次/事件/Boss 2 数值、第 1 章内容与存档形状未改，第 3/4 章仍不可达。第 78 程接入用户提供的四张第 2 章敌人图：`breath_hound` / `lung_moth` / `rust_whisperer` / `collapse_husk` 全部写入 `ENEMY_ART`（各 96×96、25 色、白 tint），`ENEMY_ART_FALLBACK` 清空——第 2 章与第 3 章沿用的三种敌人不再回退第 1 章美术。第 79 程（brief83，第 3 章可达性接线）在启动时因 `[claude-code:unrecognized_model]` 死亡，零产出、无提交；第 80 程按 brief84 全新重跑并完成第 3 章可达性接线第 1 步：第 2 章章末选择后进入第 3 章大图世界（开场 6 句 + `ch3_intro` 语音 + `chapter_sea.ogg`、`ch3_entry` 出生、清房目标 7（HUD 8）、坠落平面 1680、Boss 3 → 权柄 → outro → 章末停章），第 3 章自此可达；第 4 章仍不可达，第 3 章计划/波次/事件/Boss 3 数值与机制、第 1/2 章内容、存档形状均未改。第 81 程只更新仓库根 `README.md` 的可玩范围与测试数字口径（第 1–3 章可玩、第 4 章仍不可达、「复原」结局随跨章仁慈可达成），未改任何游戏代码/场景/资源/测试/配置、章节路由与可达性。第 83 程完成第 1–3 章可达后的全游戏例行扫描：修复「第 2/3 章 Boss 死亡检查点续玩时，携带上一章权柄会让本章权柄三选一被跳过」的真实产品行为缺陷（新增 `authority.chapter` 存档键，旧检查点按文件内章节兼容），并把帮助页过期文案「地图（第一章）」改为「地图」；其余五个扫描面未发现新缺陷，收尾基线单元 13,549/0、十一套集成 14,354（全 0 失败）、退出 10/10、像素 40/0，第 4 章仍不可达、第 11–16 项未碰。第 84 程完成第 1–3 章可达后的又一次全游戏例行扫描：修复「Boss 已死检查点续玩时目标条写死第 1 章 Boss 名」的真实产品行为缺陷（`_on_mds_room_loaded()` 改为按本章 `chapter["boss_name"]` 取名），其余五个扫描面未发现新缺陷；收尾基线单元 13,549/0、十一套集成 14,357（全 0 失败）、退出 10/10、像素 40/0，第 4 章仍不可达、第 11–16 项未碰。第 86 程完成第 1–3 章可达后的又一次全游戏例行扫描：修复延时打开的必选页面（事件页 0.8 s、Boss 权柄三选一 1.2 s）与地图/暂停/背包/商店等页面或房间过场叠加的真实产品行为缺陷（`game.gd` 新增 `_ui_blocks_delayed_page()` 与 `_room_loaded_msec`；事件页遇到 `changing_room` 取消本次、重进重排；权柄三选一等待过场与 0.175 s 淡入结束），其余五个扫描面未发现新缺陷；收尾基线单元 13,549/0、十一套集成 14,380（全 0 失败）、退出 10/10、像素 40/0，第 4 章仍不可达、第 11–16 项未碰。

## 已完成

- 引擎与工程：Godot 4.7 + GDScript、GL Compatibility、1280×720 整数缩放、120 FPS、MDS 世界/房间/地图、Aseprite Wizard。
- 内容：Chapter 1 demo 全流程（9 房间：6 战斗/精英/事件 + 休息 + Boss + 隐藏书库），墨骸史官三阶段 Boss，章末选择与结束屏；事件房 7 种文案变体（按局 seed 轮换）、残碑 8 条碑文（按 stele id 固定）、交易所纸人 5 句开场白 + 5 句成交反馈（按局 seed/摊位/行号固定）、5 名 Hub NPC 各 11 句轮换闲聊、战斗结算休整卡 8 组文案（按局 seed + 房间号固定）、休息室 8 句入场白（按局 seed + 房间 id 固定）、两条复活路径各 8 句提示（按局 seed + 类型固定）、结局返回提示胜利/失败各 8 句（按局 seed + 胜负固定）、Hub 商店失败提示已拥有 8 句/碎片不足 8 句/查无此货 4 句（按失败类型 + 货品 id 固定）、图鉴/背包空态四类各 8 句（图鉴词/组合、背包词/遗物；按局种子 + surface id 固定，不消耗 run RNG）。
- 语言系统：6 初始已解码词 + 12 残页词；未解码可施放但 `[不稳定]`；解码/已发现组合跨局保存；共享 `.tres` 不被修改。
- 权柄：续命、改写为基础池；吞噬（污染 ≥ 40，伤害随污染最高 ×1.6）与归档（本局记录 ≥ 2，死亡时带一件武器/遗物到下一局）按条件追加；HUD 显示可用/已用。
- 离线言灵：自由造句、13 形态、3 个示例句；AI（Ollama/OpenAI/Anthropic）为可选设置项，默认关闭、失败静默回退。
- 信任分层：陌生/熟悉/信任/托付（0/2/6/12，由既有 `npc_trust` 现算）；每 NPC 每档一句态度、离线/AI 回复注入、商店/锻造折扣、阿砚托付免费锻造、新局起始残页。
- 结局画廊：标题页入口，五个结局按 GDD 顺序展示；解锁只读 `Profile.endings` id，未解锁为占位，旧档未知 id 不显示、不迁移。
- 构筑：6 把独特 demo 武器 / 6 件独特遗物；武器可掉落/拾取/切换。
- 经济护栏：NPC 言灵每次回 Hub 一次 effect，起始页/起始污染只下一局一次，AI 不双叠。
- 教学与 UI：首次 Hub 教学、训练碑、标题设置/新游戏/二次确认、暂停离开确认、失焦暂停、HUD 字号 12/16/20、色盲形状预警。
- 存档：Profile v2（原子写 + `.bak` + v1 迁移）；局内 run save（`scripts/core/run_save.gd`）。
- 第 2 章大地图第 1 步解耦（第 27 程）：坠落平面按章节计划房间键（`fall_y` / `fall_below_bounds`）或房间 metadata 配置，未配置默认 850；一次性内容与清场进度按 `room/节点` id 记录（一房多遭遇/多宝箱/多残碑各自结算），旧 room-key 存档仍可读并原样带写；章节清房目标由 `ChapterPlanData.clear_target()` 派生（第 1 章仍 6）。未创建第 2 章内容、未改可达性、未加移动能力。
- 第 2 章大地图第 2 步房间生产管线（第 28 程）：新增 `BigRoomData`（Resource）+ `MDSBigRoom`（Node2D）+ `BigRoomAmbient`。可变尺寸/多矩形房间按 MDS 局部矩形并集取边界与相机限制；多层地面/平台（地面/平台各自可多层，垂直高差校验 ≤80 px、水平边缘 ≤120 px，对齐现有跳跃约 92.6 px）；瓦片视觉与矩形碰撞分离（不是每格碰撞体）；静态背景按房间并集宽度平铺、按房间→区域→世界解析，天气/动态背景/视差仍由 MDS 按区域控制；氛围只画相机窗口与房间并集的交集；按世界 JSON 自动生成门（同名作者门优先）；房间 metadata `fall_below_bounds` 接入第 27 程坠落平面解析链。第 1 章 `MDSChapterRoom`、`ch1_layout.tres`、9 个房间场景一字未改；未创建第 2 章地图/房间/计划/事件/权柄/Boss 内容，未改可达性，未新增移动能力。
- 第 2 章大地图第 3 步纵向/捷径道具管线（第 29 程）：新增 `OneWayPlatform`（可从上方站立、下方穿过；站在上面按「下+跳」用现有输入下落穿过，不加按键、不改跳跃参数）、`CollapsingPlatform`（站立后抖动/变色/裂纹预警 → 延迟塌落 → 按 `respawn_time` 恢复；坠落回退与死亡复活时整组立即复位）、`MovingPlatform`（`AnimatableBody2D` + `sync_to_physics`，水平/垂直/斜向可配，承载站立玩家；行程按 `MDSBigRoom` 并集/相机边界收紧，越界行程自动截断）、`BenchCheckpoint`（交互更新 `_last_checkpoint` 并写现有 run save，不新增存档键）与条件门捷径（世界 JSON 门带 `requires` 时 `MDSBigRoom` 自动生成 `MDSGateBarrier`，开门状态进 MDS 存档）。第 1 章 9 个房间仍走旧管线、无任何新道具；未创建/调整第 2 章地图、世界 JSON、计划、事件、权柄或 Boss 内容，未改可达性，未新增二段跳/蹬墙跳/攀爬。
- 第 2 章大地图第 4 步前半段：计划与大区图骨架（第 30 程）：`ChapterPlanData` 向后兼容地扩出 `big_map` / `start_room` / `doors` 与 region 键（`size`、`encounters`、`chests`、`steles`、`shortcuts`、`hidden`、`shop`/`rest`、`vertical`），`clear_target()` 对有 `encounters` 的计划按遭遇节点数派生（第 1 章仍按房型得 6），并新增 `validate_regions()` / `validate_graph()`（尺寸、坠落平面、节点 id 唯一且锚定、门位唯一、显式单向、图形态、入口有向 BFS 全可达）。`resources/chapters/chapter_2_demo.tres` 落地 9 区图：入口 → 两条可回环支路 → 枢纽（休整+商店+残碑+捷径）→ 纵向井（2560×2160）→ 事件/精英 → Boss（3840×2160），另有支路下的隐藏书库（2 箱 2 碑）；清房目标派生为 7（支路 A/纵井各 2 场），宝箱 5、残碑 5，全部 `region/Node` 节点 id；每区 `fall_below_bounds = 240`。图骨架以测试夹具 `tests/fixtures/big_room/ch2_graph.mdsworld.json` 落地（顶层 `fixture: true`，无房间场景，永不加载），测试交叉校验计划 ↔ 世界形状、双向/单向门、无孤立区、房间不重叠、坠落平面、清房目标 = 图上遭遇总数。计划当时尚未接入 `game.gd`（第 31 程已接入，见下条），第 2 章仍走旧 9 小房间世界、仍不可达；未创建/重排第 2 章实际房间场景，未改第 2 章世界 JSON，未写事件/权柄/Boss 内容，未新增移动能力，未改 MDS 插件或言灵/权柄/战斗框架。
- 第 2 章大地图第 4 步后半段：真实大区世界与 region 语义（第 31 程）：9 个 `BigRoomData`（`resources/rooms/ch2_bigmap/`）与 9 个 `MDSBigRoom` 场景（`scenes/mds/ch2_bigmap/`）按计划尺寸/内容 id/门名落地；独立世界 `scenes/mds/chapter_2_bigmap.mdsworld.json` + `chapter_2_bigmap_world.tscn`（9 区、20 扇有向门 + 2 扇到达门、2 扇显式单向、区域雾/萤火与背景、每区 `fall_below_bounds = 240`）；电梯/单向落台/长椅/条件捷径门按第 29 程管线做骨架。`game.gd` 新增 `CHAPTER_PLAN_PATHS`，第 2 章按计划起始区 `ch2_entry`、清房目标 7（HUD 分母 8）、坠落平面 `size.y + 240`；宝箱/残碑/遭遇按 `region/Node` 结算；事件页仍只属于第 1 章。旧第 2 章 9 小房间世界与场景未删、未改语义，只是不再被 `game.gd` 引用；第 1 章仍 `ch1_01`、目标 6、平面 850、9 个 `MDSChapterRoom`，章末仍 `_finish(true)` 不进入第 2 章；第 2–4 章仍不可达。未写第 2 章事件文本/权柄池/Boss 机制/敌人波次，未新增移动能力，未改 MDS 插件或言灵/权柄/战斗框架。
- 第 2 章内容数据层第 1 步（第 32 程）：新增 `Ch2EventData`（7 组呼吸废墟事件文案；固定「读/拿」两选项，效果只复用污染 + 解词 / 残页；变体按局 seed + 事件节点 id `ch2_event/event` 确定性轮换，不消耗 run RNG）；`game.gd` 新增 `_event_data(room_id)` 按章节查表（第 1 章仍用 `Ch1EventData` 原键与原数值，文案/效果一字不改；第 2 章用 `Ch2EventData`，事件页仅测试层驱动，自动触发仍只属于第 1 章）、`_grant_chapter_authority` 改为按计划 `authority_pool` 授予（第 1 章授予行为不变；第 2 章基础池 = 续命/改写，条件项沿用 `ContentLibrary` 的吞噬/归档，实现在测试层验证）、`_on_boss_phase` 按章节取文案；`BossEntranceData`/`BossPhaseData` 补第 2 章「肺钟守卫」8 条入场 + 8×2 条阶段文案（第 3–4 章仍静默，第 1 章选句键保持原样）。计划 `chapter_2_demo.tres` 补 `authority_pool = [续命, 改写]`。新增 `tests/test_ch2_content.gd`（489 断言）：事件确定性/效果类型、权柄基础+条件项、Boss 文案不回落到第 1 章、Boss 数值与立绘未改、7 个遭遇节点唯一且锚定、6 场战斗与 `ROOM_WAVES[1]` 六波一一对应（事件节点无波次）、清房目标仍 7。已知缺口：第 2 章计划区域尚无 `wave` 键，大区 Arena 不会生成敌人；按本程任务单只校验既有波次/节点对应，波次接线留给后续内容程。
- 第 2 章波次接线（第 33 程）：计划 `chapter_2_demo.tres` 的 4 个战斗区补 `wave` 字典（6 个键 = 6 个战斗遭遇节点 id），事件区/Boss 区/入口/枢纽/书库不带波次；六波按计划顺序直接复用 `ROOM_WAVES[1]` 原文，未新增/修改波次内容。`ChapterPlanData.wave_for(room_id, encounter_id)` 按节点 id 查表（第 1 章仍返回房间级数组），`validate_waves()` 校验键锚定、值非空、战斗遭遇必有一波、事件遭遇不得有波。`game.gd` 大图分支按遭遇节点生成各自波次并登记 `_rooms`，一区多遭遇逐场锁门/清怪/奖励/进度；第 1 章生成路径、波次、奖励与进度一字未改。第 2 章仍不可达，事件区仍无自动触发点，Boss 独特机制未做。
- 第 2 章事件区真实触发（第 34 程）：`_on_mds_room_loaded` 新增区域级事件分支（`big_map` + `type == "event"` + `_event_data` 非空），进入 `ch2_event` 自动打开第 2 章事件页；键 = 计划事件节点 id `ch2_event/event`，文案/选项来自 `Ch2EventData`（局 seed + 节点 id，确定性、不耗 run RNG），两项效果沿用第 32 程（读 → 污染 +8 + 解明一个残页词/兜底残页 +6；拿 → 残页 +12）。结算按 `cleared_encounters` 的节点 id 一次，重载/续玩不重开、不重复发奖励；未结算离开区域会取消延迟开页。第 1 章事件房原 `is_primary` 触发与文案/数值未改；清房目标仍 7、6 场波次不变；第 2 章仍不可达；Boss 2 机制与章节过渡由第 35 程补上（见下条）。
- 第 2 章 Boss 2 与章末边界（第 35 程）：新增 `LungBellGuardian extends InkArchivist` + 同名场景，`chapter_2_demo.tres` 的 `boss_scene` 指向它；`_spawn_boss` 原有优先级不变（第 1 章战役表 → 第 2 章计划 → 旧脚本兜底），通用生成/血条/阶段横幅/权柄/outro/结束流程复用。机制：呼吸（吸气 2.4 s 承伤 0.5× / 呼气 1.4 s 承伤 1.5× + 气环 560 px、0.8×，阶段 2 起留墨池，阶段越高节奏越快）、钟摆（正反两枚 `HostileBolt`，阶段 2 起每第 3 次钟鸣环 620 px、0.9×，气弹 `InkBomb` 0.8× 留池）、阶段 3 钉子（暴露 5 s 承伤 1.5× / 闭合 7 s 承伤 0.6×，12 s 周期）。`_complete_chapter` 对第 2 章（`_chapter == 1`）在章末选择后调用现有 `_finish(true)` 停章，不自动进入第 3 章；第 1 章分支和第 3/4 章自动续章未改。大图 `ArenaRoom` 原点在地面，新增 `_enemy_spawn_y()` 使大图敌人/Boss 生成在 `-ENEMY_FOOT_Y - 2`（第 1/3/4 章仍 250 px），修复第 2 章生成在地下的缺陷。Boss 数值为暂定口径，由 `test_ch2_boss` 锁定；第 1 章 Boss/流程/9 房间/6 波次/事件未改，第 2 章仍不可达。
- 第 2 章大地图系统验收（第 36 程）：新增 `tests/integration_ch2_bigmap.gd`（1303 断言，0 失败），按 D 节 10 项在真实门/真实房间里逐项验收：计划图入口 BFS 九区全可达、20 扇连通门 + 2 扇到达门全部实走、2 扇显式单向语义正确；九区边界 = 计划尺寸、相机限制 = 世界边界、玩家不越界；电梯乘行 → top 门 → bot 门到达出速/落点正确且 2 秒内不回弹；过渡期间不叠暂停/剧情/奖励/地图/权柄/商店，坐标容差符合出点规则；书库 2 箱 2 碑按节点 id 各只发一次、重载/续玩不重复；支路两场遭遇逐场锁门/清怪/发奖、重载不重生、清房推进到 7（HUD 分母 8）；书库首次发现反馈与地图揭示、捷径门授予/开门/通行/跨存档保持；Boss 区生成/门位/文案/权柄/续玩不二次生成/章末停章。验收中发现并修复 bot 门到达回弹缺陷：`mds_world_game.gd` 新增 `floor_arrival_grace`（1.2 秒，仅 bot 门，横向/top 不变，0 可关）。第 1 章 9 房间/6 波次/事件/清房目标 6/结束流程无回归；第 2 章仍不可达。
- 第 2 章大图门视觉（第 37 程）：新增 `scripts/presentation/gate_visual.gd`（`GateVisual`），复用既有手动门 `ChapterDoor` 的 `door.png`/accent 边框/墨尘/HUD theme 12 px 描边标题；`MDSBigRoom` 在生成自动门后给当前房间所有 `MDSGate`（自动门 + 作者门）挂 `GateVisual`，`auto_gates = false` 时只补视觉。side 感知：left/right 立门向房间内展开、门底按真实地面/台阶落面对齐；top/bot 同一贴图横置为天花板/地面舱口。有去向标「前往 <目标区名>」+ 朝向箭头，无去向的到达门标「来路」无箭头；贴边门标题内收。纯 `Node2D`（`z=-1`）、无碰撞/信号/输入，门位、模式、单向语义、`requires`/`MDSGateBarrier`、过渡目标未改。九区 22 扇门视觉由测试逐门断言。
- 第 2 章新局出生点（第 37 程）：根因是 `MDSWorldGame._spawn_position()` 在无到达门/无坐标/无 `save_point` 时回退到 `MDSWorld.get_room_label_pos()`（房间最大矩形中心，地图标签锚点）；`ch2_entry` 2560×1440 的锚点 (1280,720) 比第一级台阶面 y=1344 高 624 px。`ch2_entry.tscn` 作者 `Marker2D` `SpawnPoint`（组 `save_point`，位置 (400,1328) = 台阶面 − `Player.FOOT_Y` 16），走 MDS 既有优先级；未改 MDS 回退顺序，未改第 1 章出生/Hub。新局第一物理帧即落地，0.3 秒内不漂移。
- 第 2 章地图标题（第 38 程）：`MapOverlay` 标题原本是字面量「档案馆地图」，所有章节共用；现改为 `map_title(chapter_index)` + `set_chapter(chapter_index)`，从既有 `CampaignData.chapter(i)["region"]` 派生「<区域名>地图」。第 1 章（索引 ≤ 0）冻结「档案馆地图」；第 2 章为「呼吸废墟地图」；第 3/4 章为「无光海地图」「笑面剧场地图」；区域为空/索引无效回落第 1 章标题，不新造章节名。`game.gd` 在 `set_world()` 前调用 `set_chapter()`，启动与续玩都同步；`_chapter_index` 保留，`_ready()` 前调用也不丢。单元 16 断言 + 可玩性集成 6 断言覆盖，第 1/2 章标题互不回落。第 2 章仍不可达。
- 第 2 章敌人美术核查与接线（第 38 程）：五种敌人逐一核查——`choir_summoner` 有专属精灵 `assets/sprites/enemies/choir_summoner.png`（96×96 RGBA），已在 `ENEMY_ART` 且不在 `ENEMY_ART_FALLBACK`，实际白 tint 渲染；`breath_hound`/`lung_moth`/`rust_whisperer`/`collapse_husk` 无专属精灵（场景内只有程序化 `Polygon2D` 占位，`assets/concept/enemies/` 也无原图），按任务单不新绘、不拼凑，继续回退第 1 章美术并染 `#c8e1cd`。回退 tint 提为常量 `ENEMY_FALLBACK_TINT`（行为不变）。新增 `tests/test_enemy_art.gd` 94 断言锁定：第 1 章 8 种敌人各自保留原 PNG、不在回退表；第 2 章已接线敌人用自己的 PNG 且白 tint、不走回退；四个缺失敌人回退源是第 1 章美术、标准路径尚无专属 PNG（日后补图未接线会失败）。第 2 章大地图集成在真实遭遇中断言 `choir_summoner` 用专属图/白 tint、`rust_whisperer` 仍走 `scribe_bug`/绿 tint。未新增/修改任何敌人贴图或场景美术，第 1 章敌人美术与波次未改。
- 第 3 章计划与图骨架（第 40 程）：`ChapterPlanData` 新增向后兼容的 `content_pending`（仅推迟 `validate_waves()`；区域/节点 id/门图照常校验；第 1/2 章为 `false`，校验结果不变）；新增 `resources/chapters/chapter_3_demo.tres` 9 区连通图（入口/两条可回环支路/枢纽/纵井/隐藏书库/事件占位/精英/Boss；6 个战斗遭遇对应旧 6 波但未接线 + 1 个事件占位 → 清房目标 7；3 宝箱/2 残碑；11 门 = 9 双向 + 2 显式单向，其中捷径门 `requires: ["ch3_shortcut"]`、来源待拍板且默认关闭；每区 `fall_below_bounds = 240`；无波次/权柄池/`boss_scene`/事件文案）；新增图骨架夹具 `tests/fixtures/big_room/ch3_graph.mdsworld.json`（`fixture: true`、无 `scene_path`、游戏从不引用）与 `tests/test_ch3_plan.gd`（728 断言）交叉校验计划↔夹具。计划未接入 `game.gd`（`CHAPTER_PLAN_PATHS[2]` 仍空），旧第 3 章 9 房世界/场景未改未删，第 3 章仍不可达；第 14/15/16 项仍留空未施工。
- 第 3 章真实大区世界（第 41 程，只做结构层）：9 个 `BigRoomData`（`resources/rooms/ch3_bigmap/`）与 9 个 `MDSBigRoom` 场景（`scenes/mds/ch3_bigmap/`）按第 40 程计划尺寸/内容节点 id/门名落地（2560×1440、2560×2160 纵井、3840×2160 精英/Boss；地面贴底边、平台 80 px 阶梯链、`validate()` 全空）；每区 `fall_below_bounds = 240`；`ch3_entry` 作者 `SpawnPoint`（`save_point`、台阶面 − `FOOT_Y`）与惰性到达门；纵向/捷径骨架复用第 29 程管线（`branch_b`/`hub`/`vault`/`well`/`elite` 电梯、纵井 3 单向落台、枢纽长椅、捷径屏障，电梯沿用管线默认 80 px/s）。独立世界 `scenes/mds/chapter_3_bigmap.mdsworld.json` + `chapter_3_bigmap_world.tscn`：9 区单矩形、22 门 = 20 有向 + 2 只到达、`elite_boss` 单向、`hub_shortcut_entry` 带 `requires = ["ch3_shortcut"]` 默认封闭、区域雾/雨与 `deep_water` Boss 背景、无 sea 层/无 `backdrop_image`。`tests/test_ch3_world.gd` 771 断言交叉校验计划↔世界并锁定不变项；世界仍不被 `game.gd` 引用（`CHAPTER_PLAN_PATHS[2]` 仍空），旧第 3 章 9 房世界/场景未改未删，第 3 章仍不可达；第 14/15/16 项留空。
- 第 3 章内容数据层第 1 步（第 42 程，只做数据层）：新增 `scripts/data/ch3_event_data.gd`（`Ch3EventData`，7 组无光海事件文案：倒影/盐页/小读者/镜面/海页/吊影/翻页；固定读/拿两选项，效果复用第 32 程口径——读 → 污染 +8 + 解明一个残页词 / 兜底残页 +6，拿 → 残页 +12；`pick(run_seed, "ch3_event/event")` 确定性轮换、不耗 run RNG）；`game.gd` 的 `_event_data` 扩到第 3 章（第 1 章仍 `Ch1EventData` 原键与原值，第 2 章仍 `Ch2EventData`，第 4 章仍 `{}`）；`chapter_3_demo.tres` 补 `authority_pool = [续命, 改写]`（条件项仍由 `AuthorityController.build_pool` 从 `ContentLibrary` 追加，第 1/2 章池与授予行为不变）；`BossEntranceData` 新增第 3 章 8 条入场文案、`BossPhaseData` 新增阶段 2/3 各 8 条（第 4 章仍静默；第 1 章保留 `"%d:%d"` 选句键，第 2/3 章用 `"%d:%d:%d"`，不回落第 1/2 章）；Boss 3「最后的读者」HP 380 / 伤害 15 / 速度 78 / `last_reader.png` / `boss_script = reader` 均未改。新增 `tests/test_ch3_content.gd`（570 断言）；`test_ch3_plan` 730 → 734（基础池断言）、`test_ch3_world` 771 不变、`test_ch2_content` 与 `test_boss_entrance_content` 的「第 3 章静默」期望收窄到第 4 章（−2）、`integration_ch1_demo` 同一断言改期望（数量不变）。第 3 章计划仍未接入 `game.gd`（`CHAPTER_PLAN_PATHS[2]` 仍空）、仍无 `wave` 表与事件真实触发，第 3 章仍不可达；旧第 3 章 9 房/17 门/世界场景与第 3 章大区世界均原样保留；第 14/15/16 项留空。
- 第 3 章波次接线（第 43 程，只做数据层）：`chapter_3_demo.tres` 的 4 个战斗区（`ch3_branch_a`/`ch3_branch_b`/`ch3_well`/`ch3_elite`）补 `wave` 字典，6 个键 = 6 个战斗遭遇节点 id，值按计划顺序逐字复用 `ROOM_WAVES[2]` 六波（波次内容未新增/未修改）；事件节点 `ch3_event/event` 无波，Boss 区不占普通波次，清房目标仍 7。`content_pending` 按第 40 程约定由 `true` 改回 `false`：波次表进入 `validate()` 正常校验（区域/门图校验不变），标志本身保留在 `ChapterPlanData`（默认 `false`、向后兼容）；图骨架夹具顶层的 `content_pending: true` 是夹具元数据、不是该字段，未改。测试就近扩展既有套件：`test_ch3_content` 锁定波次键集合/计划顺序取值/事件与 Boss 排除/`validate_waves()` 干净，并把第 3 章计划挂到独立 `game.gd` 实例经 `_plan_wave()` 按节点 id 读回六波（证明第 33 程通用大图分支可直接取用，但不改章节路由）；`test_ch3_plan`/`test_ch3_world` 的待接线期望同步为已接线。第 3 章计划仍未接入 `game.gd`（`CHAPTER_PLAN_PATHS[2]` 仍空）、事件无真实触发、Boss 3 无 `boss_scene`/机制，第 3 章仍不可达；第 14/15/16 项留空未施工。
- 第 3 章事件区真实触发（第 44 程，只做触发与测试层）：`_on_mds_room_loaded` 第 34 程的区域级大图事件分支是章节无关的，第 42 程 `_event_data` 已路由第 3 章，因此 `ch3_event` 事件区无需新增触发路径——计划与大区世界挂上后，进入区域即自动打开第 3 章事件页。实测（`integration_playability` 测试层驱动）：进入 `ch3_event` 即开页，文案/选项 = `Ch3EventData.pick(run_seed, "ch3_event/event")`，不耗 run RNG；拿 → 残页 +12，读 → 污染 +8（按难度/抗性倍率、上限 100）+ 解明一个残页词或兜底残页 +6；结算写 `cleared_encounters["ch3_event/event"]` 并计入清房目标 7（HUD 分母 8），重载不重开、不重复奖励、不重复计数，run save 落盘同一键。`game.gd` 仅补一段注释说明分支章节无关；未接入 `game.gd`（`CHAPTER_PLAN_PATHS[2]` 仍空）、未改章节路由/章末流程/第 1/2 章事件触发与数值，第 3 章仍不可达；Boss 3 机制/`boss_scene` 与第 3 章大图验收仍是后续程的事。单元 10113/0（+13）、可玩性集成 705（+34），其余八套集成不变且全 0 失败。
- 第 3 章 Boss 3 机制与 `boss_scene` 路由（第 45 程，只做机制与测试层）：`chapter_3_demo.tres` 的 `boss_scene` 指向既有 `scenes/bosses/last_reader.tscn`；`LastReader extends InkArchivist` 扩展独特机制，通用 Boss 流程（生成/血条/阶段横幅/权柄/outro/结束）复用，`_spawn_boss` 优先级与 `boss_script == reader` 兜底不变。机制：镜面弹幕（阶段 1/2/3 = 3/5/7 枚、张角 0.28/0.40/0.52 rad、每枚 0.7× 攻击力 / 速度 270）、读页封印（阶段 2 起每第 3 次攻击，0.8× 地面预警 + 封印一个短语槽 3.0 s，槽位交替）、阶段 3 空白页承伤窗口（11 s 周期：空白页展开 4.5 s 承伤 ×1.5 / 合书 6.5 s 承伤 ×0.6，进入阶段 3 先展开，sprite tint 提示）；阶段 1–2 承伤 ×1.0。HP 380 / 伤害 15 / 速度 78 / 立绘 / `boss_script` 未改，以上数值为暂定口径并由 `tests/test_ch3_boss.gd`（90 断言）锁定；大图生成高度沿用第 35 程 `_enemy_spawn_y()`（计划在 → -18 px，无计划 → 250 px），只补断言未改函数。`tests/integration_playability.gd` 705 → **732**（+27）：真实大区世界从 `ch3_boss` 启动，验证计划路由 `LastReader`、数值来自战役表、生成在 `Arena` 地面线之上、阶段 2 文案用第 3 章选句键、空白页窗口开合、继承的纸页波/墨雨在真实树内生成、Boss 击败后重载不二次生成；测试后恢复旧第 3 章世界。就地更新 `test_ch3_plan`（726 → 728）、`test_ch3_content`（614 → 615）、`test_ch3_world`（764 → 765）的「无 `boss_scene`」期望。`CHAPTER_PLAN_PATHS[2]` 仍空、第 3 章仍不可达（旧第 3 章 9 房/17 门/世界仍被游戏使用）、章末仍自动进第 4 章；第 1/2 章计划/世界/事件/Boss 2 与第 1 章 9 房间/6 波次无回归。单元 10207/0，九套集成全绿。
- 第 3 章章末收口（第 46 程，只做章末流程与测试层）：`_complete_chapter` 在既有第 2 章分支之后新增 `_chapter == 2` 分支，第 3 章章末选择后调用现有 `_finish(true)` 停章，不再自动进入未实现的第 4 章；第 1 章分支、第 2 章分支与第 4 章分支未改，章末选择界面/结局记录/续玩行为沿用第 35 程口径。第 3 章章末文本/选项/语音本已齐全（`CampaignData.chapter(2)` 4 句 outro、两选项、`ch3_outro` 语音；`_apply_chapter_choice` 的 `lightless_sea` 分支），未新编剧情。续玩/重载沿用章节无关的 `_boss_defeated` → `_resume_boss_aftermath` 逻辑（Boss 3 已死不二次生成、直接续接权柄/章末），本程只补断言。`tests/integration_playability.gd` 的 `_test_ch3_bigmap_boss` 把第 41 程大区世界与第 3 章计划临时挂到真实主场景，走真实流程验证 Boss 3 击败 → 权柄二选一 → 第 3 章 outro → 章末选择 → 停章（`_chapter` 仍 2、`_finished`、结局屏可见），并在开头锁定 `CHAPTER_PLAN_PATHS[2]/[3]` 仍空、`MDS_WORLD_FILES[2]` 仍指旧世界、清房目标 7/7 个遭遇节点/波次表/权柄池/`boss_scene` 不变；旧线性世界结构遍历的章末断言改为「停在第 3 章」。可玩性集成 732 → **754**（+22），其余套件不变。`CHAPTER_PLAN_PATHS[2]` 仍空、第 3 章仍不可达、计划仍未接入 `game.gd`；第 3 章大图验收、门视觉、地图标题/敌人美术核查仍是后续程。
- 第 3 章大图门视觉专项（第 49 程，只做表现层与测试）：`GateVisual` 由 `MDSBigRoom._add_gate_visuals()` 通用挂载，第 41 程 9 个 `MDSBigRoom` 场景（`auto_gates` 全开）的 22 扇门已被自动覆盖，未另起视觉实现。逐门断言（`tests/integration_ch3_bigmap.gd`）：每门有 `GateVisual`、`marker.position == Vector2.ZERO`（不移动门）、side 与世界文件一致；left/right 立门向房间内展开且门底落在真实地面/台阶面（`floor_offset` 现算），door 中置，top/bot 横置为天花板/地面舱口且不越界；right 标题 `x=-CAPTION_WIDTH`、left `x=0`、top/bot/door 居中，标题矩形必须在房间内；有向门 `arrival=false`（画朝向箭头）+「前往 <目标区名>」，仅到达门 `arrival=true`（「来路」、无箭头）；汇总 22 = 20 有向 + 2 到达、side 5/5/5/5/2。发现并修复真实缺陷：top/bot 舱口贴墙时 200 px 标题框越出房间（`ch3_well/top1`、`ch2_well/top1`，x=80 左溢 20 px）——`GateVisual` 新增可选 `caption_area`（房间按标题尺寸内缩）、`MDSBigRoom` 传入，`_caption_x()`/`_caption_y()` 夹取；空值保持原规则，左右门不受影响。纯 `Node2D`（`z=-1`）、无碰撞/信号/输入；门位、模式、单向语义（`ch3_elite/right1` 不可返回）、`requires`/`MDSGateBarrier`（`ch3_hub/shortcut` 默认封闭）、过渡目标未改；第 1 章无 `GateVisual`，第 2 章 22 扇门断言无回归。
- 第 3 章敌人美术核查与接线（第 49 程，只核查/锁定，不新绘）：以 `ROOM_WAVES[2]` 六波实际引用为准共 8 种——`mirror_sniper`（第 3 章专属）与沿用第 1 章的 `hanging_scribe`/`echo_enemy`/`typo_beast`/`page_swarm` 有专属精灵、已在 `ENEMY_ART`、不在回退表、实际白 tint（`echo_enemy` 的刷怪 id 对应数据资源 `amnesiac_echo.tres`，美术按刷怪 id 接线）；沿用第 2 章的 `rust_whisperer`（→`scribe_bug`）/`lung_moth`（→`hanging_scribe`）/`collapse_husk`（→`blank_man`）无专属美术，继续第 1 章回退并染 `ENEMY_FALLBACK_TINT`（`#c8e1cd`），缺失清单记录、`assets/concept/enemies/` 也无原图，按任务单不新绘不拼凑。`tests/test_enemy_art.gd` 94 → **200 断言**（第 3 章 8 敌逐一核对、5 接线/3 缺失、审计集合由 `ROOM_WAVES[2]` 现算）；第 3 章大图集成在真实遭遇中断言 `mirror_sniper`/`hanging_scribe` 专属图+白 tint、`rust_whisperer`/`lung_moth` 回退图+绿 tint。未新增/修改任何敌人贴图或场景美术；第 1/2 章美术与波次未改。
- 第 3 章地图标题复核（第 49 程）：第 38 程的 `CampaignData.chapter(i)["region"]` 派生规则未动，第 3 章集成既有断言「无光海地图」复跑仍成立；第 1 章「档案馆地图」一字未改。
- 第 4 章计划与图骨架（第 51 程，只做数据层）：新增 `resources/chapters/chapter_4_demo.tres` 9 区连通图（入口/两条可回环支路/枢纽/纵井/隐藏书库/事件占位/精英/Boss；2560×1440、纵井 2560×2160、精英/Boss 3840×2160）；6 个战斗遭遇按计划顺序对应 `ROOM_WAVES[3]` 六波但本程不接线，加 1 个事件占位 `ch4_event/event` → `clear_target()` 派生 7（第 1 章仍 6、第 2/3 章仍 7）；3 宝箱/2 残碑（`region/Node` 节点 id）；11 门 = 9 双向 + 2 显式单向（`elite_boss`、`hub_shortcut_entry` 带 `requires: ["ch4_shortcut"]`、来源待拍板且默认封闭）；每区 `fall_below_bounds = 240`；`content_pending = true` 只推迟波次表。Boss 门按第 2/3 章先例单向（旧世界 `ch4_boss/left1` 仍返回 `ch4_rest`，原样保留并由测试锁定）；Boss 区不写 `boss_scene`/文案/机制。新增图骨架夹具 `tests/fixtures/big_room/ch4_graph.mdsworld.json`（`fixture: true`、无房间场景、永不加载、20 扇有向门 + 2 扇到达门）与 `tests/test_ch4_plan.gd`（778 断言）；`test_ch2_world`/`test_ch3_content`/`integration_playability` 的「第 4 章计划槽为空」锁补「计划已存在但未路由」（+3）。计划未接入 `game.gd`（`CHAPTER_PLAN_PATHS[3]` 仍空），旧第 4 章 9 房/17 门世界与场景未改未删，第 4 章仍不可达。
- 第 4 章真实大区世界（第 52 程，只做结构层）：9 个 `BigRoomData`（`resources/rooms/ch4_bigmap/`）与 9 个 `MDSBigRoom` 场景（`scenes/mds/ch4_bigmap/`）按第 51 程计划落地——`ch4_entry`/`ch4_branch_a`/`ch4_branch_b`/`ch4_hub`/`ch4_vault`/`ch4_event` 2560×1440、`ch4_well` 2560×2160、`ch4_elite`/`ch4_boss` 3840×2160；地面贴底边（16 px）、平台 80 px 阶梯链、`validate()` 全空；每区 `fall_margin = 240`；复用 `ch1_tiles.tres`，`backdrop_path = smiling_theater.png`（`backdrop_pixel_art = false`）、`ambient_kind = embers`（灰烬母题）、按区暖色调；旧第 4 章世界语义不变。`ch4_entry` 作者 `SpawnPoint`（`save_point` 组，(400,1328) = 第一级台阶面 1344 − `FOOT_Y`）与惰性 `shortcut_arrival` 到达门。独立世界 `scenes/mds/chapter_4_bigmap.mdsworld.json` + `chapter_4_bigmap_world.tscn`：9 区单矩形、原点 32 px 对齐、`start_room = ch4_entry`；区域 `Smiling Theater` 镜像旧世界（灰烬 + 光柱天气、`background` 空、`boss_background = blood_moon`），不写 `backdrop_image`、不加 theater 层；22 门 = 20 有向 + 2 只到达（`ch4_entry/shortcut_arrival`、`ch4_boss/left1`），`elite_boss` 显式单向、`hub_shortcut_entry` 带 `requires = ["ch4_shortcut"]` 默认封闭；侧门在地面上方 90 px、底门在地面线、顶门在上边缘；房间不重叠、双向门相邻、捷径刻意不相邻。纵向/捷径骨架复用第 29 程管线：`ch4_branch_b`/`ch4_hub`/`ch4_vault`/`ch4_well`/`ch4_elite` 各 1 台电梯（行程覆盖顶门列并避开平台）、`ch4_well` 3 个单向落台、`ch4_hub` 长椅检查点、捷径屏障；电梯未写 `speed`，沿用 `MovingPlatform` 管线默认 **80 px/s**（第 12 项只针对第 2 章，未碰）。内容节点严格用计划 id：`Arena`/`Arena2`/`Chest1`/`Stele1`/`Shop`(`ch4_hub_shop`)/`Bench`/`Event`（`ch4_event/event`）；Boss 区只放结构 `Arena`。新增 `tests/test_ch4_world.gd` **812 断言**交叉校验计划↔世界并锁定不变项；`tests/test_ch4_plan.gd` 的「目录未创建」锁改为目录/文件存在（778 → 796）。世界仍不被 `game.gd` 引用（`CHAPTER_PLAN_PATHS[3]` 仍空），旧第 4 章 9 房/17 门世界原样保留，第 4 章仍不可达；舞台母题/`ch4_shortcut` 来源/战斗密度/`mask_enemy`/`seat_husk` 独立数值/Boss 4 机制/阿砚同行全部留空未施工。
- 第 4 章内容数据层第 1 步（第 53 程，只做数据层）：新增 `scripts/data/ch4_event_data.gd`（`Ch4EventData`，7 组笑面剧场事件文案，固定读/拿两选项；读 → 污染 +8 + 解明一个残页词 / 兜底残页 +6，拿 → 残页 +12；按 `hash("%d:%s")` + 事件节点 id `ch4_event/event` 确定性轮换，不耗 run RNG）；`game.gd` 的 `_event_data` 扩到第 4 章（第 1 章原键与原值、第 2 章 `Ch2EventData`、第 3 章 `Ch3EventData` 均不变；索引 ≥ 4 仍返回 `{}`）；`chapter_4_demo.tres` 补 `authority_pool = [续命, 改写]`（条件项仍由 `AuthorityController.build_pool` 从 `ContentLibrary` 追加吞噬/归档）；`BossEntranceData` 新增第 4 章「笑面史官」8 条入场文案、`BossPhaseData` 新增阶段 2/3 各 8 条（第 1 章保留 `"%d:%d"` 选句键，第 2/3/4 章用 `"%d:%d:%d"`；不回落到第 1/2/3 章；`BossEntranceData` 既有键 `"%d:%d" % [seed, chapter_index]` 经核查后保持原样），Boss 4 HP 520 / 伤害 18 / 速度 92 / `smiling_archivist.png` / `boss_script = smiling` 未改；计划仍 `content_pending = true`、无 `wave` 表、无 `boss_scene`，6 场战斗与 `ROOM_WAVES[3]` 六波只校验计划顺序（事件节点无波、清房目标 7）；新增 `tests/test_ch4_content.gd`（613 断言）锁定上述内容并锁 `CHAPTER_PLAN_PATHS[2]/[3]` 仍空、`MDS_WORLD_FILES[3]` 仍指旧世界、旧第 4 章 9 房/17 门世界与第 1–3 章计划/世界不变；第 4 章仍不可达，事件区无真实触发、波次接线与 Boss 4 机制未开始。
- 第 4 章波次接线（第 54 程，只做数据层）：`chapter_4_demo.tres` 的 4 个战斗区（`ch4_branch_a`/`ch4_branch_b`/`ch4_well`/`ch4_elite`）补 `wave` 字典，6 个键 = 6 个战斗遭遇节点 id，值按计划顺序逐字复用 `ROOM_WAVES[3]` 六波（`mask_enemy`+`seat_husk` / `choir_summoner`+`page_swarm` / `seat_husk`+`mirror_sniper` / `mask_enemy`+`typo_beast` / `ink_bomber`+`mask_enemy` / `mirror_sniper`+`page_swarm`），波次内容未新增/未修改；事件节点 `ch4_event/event` 无波，Boss 区不占普通波次，清房目标仍 7。`content_pending` 按第 40/43 程约定由 `true` 改回 `false`，波次表进入 `validate()` 正常校验（区域/门图校验不变），标志本身保留在 `ChapterPlanData`（默认 `false`、向后兼容）；图骨架夹具顶层的 `content_pending: true` 是夹具元数据、未改。测试就近扩展既有套件：`test_ch4_content`（641 断言，+28）锁定波次键集合/计划顺序取值/事件与 Boss 排除/`validate_waves()` 干净，并把第 4 章计划挂到独立 `game.gd` 实例经 `_plan_wave()` 按节点 id 读回六波（证明第 33 程通用大图分支可直接取用，但不改章节路由）；`test_ch4_plan`（795，−1）与 `test_ch4_world`（813，+1）的待接线期望同步为已接线；并锁 `CHAPTER_PLAN_PATHS[3]` 仍空、`MDS_WORLD_FILES[3]` 仍指旧世界、旧第 4 章 9 房/17 门世界仍在、第 1/2/3 章计划与世界不变、清房目标仍 7。产品代码（`game.gd`/`ChapterPlanData`/世界/Boss 4 数据与文案）未改；第 4 章仍不可达，事件区真实触发验证、Boss 4 机制/`boss_scene`、第 4 章大图验收未开始。
- 第 4 章 Boss 4 机制与 `boss_scene` 路由（第 57 程，只做机制与测试层）：`chapter_4_demo.tres` 的 `boss_scene` 指向既有 `scenes/bosses/smiling_archivist.tscn`（`SmilingArchivist extends InkArchivist`），通用 Boss 流程复用；`_spawn_boss` 优先级（战役表 → 计划 → `boss_script == smiling` → `reader` → 默认）与兜底未改。机制沿用既有实现并由测试锁定：阶段 1 纸页波；阶段 2 每第 3 次镜面弹幕（3 枚、张角 ±0.34 rad、每枚 `int(攻击力 × 0.7)`、速度 280），其余纸页波（阶段 ≥2 双发）；阶段 3 四拍 `%4` = 改写 → 镜面弹幕 → 墨雨 → 纸页波（墨雨 3 个 `InkWarning`、`int(攻击力 × 0.75)`；改写封 0 号短语槽 3.0 s）。数值 HP 520 / 伤害 18 / 速度 92 / 立绘 `smiling_archivist.png` / `boss_script = smiling` 未改，为暂定口径。大图生成高度沿用 `_enemy_spawn_y()`（计划在 → -18 px，无计划 → 250 px）。新增 `tests/test_ch4_boss.gd`（78 断言：计划路由、场景类型、战役表数值/立绘未改、完整节拍表、纸页波伤害、改写槽位/时长、生成高度、第 4 章选句键不回落、第 1/2/3 章隔离、计划槽/旧世界/清房目标/波次/权柄池锁）；`test_ch4_plan` 795→**797**、`test_ch4_world` 813→**814**、`test_ch4_content` 642→**644**；可玩性集成新增 `_test_ch4_bigmap_boss`（真实大区世界走完 Boss 4 → 权柄 → outro → 章末选择 → 战役结束、重载不二次生成），810→**869**。`CHAPTER_PLAN_PATHS[3]` 仍空、`MDS_WORLD_FILES[3]` 仍指旧世界、旧第 4 章 9 房/17 门世界仍在、第 1/2/3 章计划与世界不变、清房目标 7、波次表与事件触发口径不变、`_complete_chapter` 与章节路由未改；第 4 章仍不可达。未做 Boss 4 机制扩展（删除词/复制武器/舞台机关）、`ch4_shortcut` 授予、扩波/增遭遇、`mask_enemy`/`seat_husk` 独立数值、舞台母题呈现层、阿砚同行；待确认第 11–16 项未碰。
- 第 4 章章末收口（第 58 程，只做章末流程与测试层）：`_complete_chapter` 在既有第 3 章分支之后新增 `_chapter == 3` 分支，章末选择后调用现有 `_finish(true)` 结束战役（与旧 `else` 兜底行为等价，本程显式化）；第 1/2/3 章分支与 `_chapter + 1 < chapter_count()` 兜底未改，只更新过时注释。第 4 章章末文本/选项/`ch4_outro` 语音本已齐全（4 句 outro、重写/焚毁两选项、`smiling_theater` 选择分支），未新编剧情。`_test_ch4_bigmap_boss` 扩为完整章末链路并锁定第 4 章原文/语音/选项/结局规则与全部不变项，旧线性世界遍历补「停在第 4 章/战役结束」断言；可玩性集成 869 → **894**。第 4 章仍不可达、计划仍未接入 `game.gd`、未做 Boss 4 机制扩展与第 4 章大图验收。
- 第 4 章大地图系统验收（第 59 程，只做验收与测试层）：`tests/integration_ch4_bigmap.gd` **4869 断言 / 0 失败（连续两次）**，覆盖计划图九区 BFS、世界 22 门全部实走（20 连通 + 2 只到达）、2 扇单向语义、单矩形边界/相机、纵向（5 台电梯实测管线默认 80 px/s、纵井 3 单向落台、长椅、top/bot 门、坠落平面）、门过渡无叠加模态、3 箱 2 碑一次性、`ch4_branch_a` 双遭遇与其余四个战斗区逐场波次/精灵、清房 7（HUD 8）、隐藏书库首次发现/地图揭示、`hub_shortcut_entry` 屏障默认封闭且测试注入后跨存档、世界级存档恢复、Boss 4 生成/数值/立绘/入场与阶段 2/3/权柄/章末结束战役/重载不二次生成、性能基线，以及第 4 章专属表现（笑面剧场平铺背景、灰烬光柱、`embers`、`blood_moon`、其余区空背景且无 theater 层、地图标题「笑面剧场地图」、8 种敌人专属美术无回退）。未发现产品缺陷（首次尝试遗留脚本的重复声明解析错误与覆盖缺口已在测试层修复）；产品代码（`scripts/`/`scenes/`/`resources/`）未改，`CHAPTER_PLAN_PATHS[3]` 仍空、第 4 章仍不可达、未接入 `game.gd`。
- 第 4 章内容数据层第 3 步（第 56 程，只做触发与测试层）：`_on_mds_room_loaded` 第 34 程的区域级大图事件分支是章节无关判定（`big_map` + 计划区域 `type == "event"` + `_event_data` 非空），第 53 程 `_event_data` 已路由第 4 章，因此 `ch4_event` 无需第 4 章专属触发路径——计划与大区世界挂上后，进入区域即自动打开第 4 章事件页。`game.gd` 仅把该分支注释的「Chapters 2–3」更正为「Chapters 2–4」，行为零改动。测试层验证：进入 `ch4_event` 即开页，文案/标题/两选项 = `Ch4EventData.pick(run_seed, "ch4_event/event")`（不耗 run RNG）；拿 → 残页 +12 + 提示 + HUD「档案 1 / 8」，读 → 污染 +8（倍率/上限 100）+ 解明一个残页词或兜底 +6；结算写 `cleared_encounters["ch4_event/event"]`、清房计数 +1（目标 7、分母 8），run save 落盘同一键，重载不重开/不暂停/不重复计数/不重复奖励。`tests/integration_playability.gd` 新增 `_test_ch4_bigmap_event_trigger`（可玩性集成 755 → **810**，含第 4 章旧世界恢复），`tests/test_ch4_content.gd` 补触发键一致性断言（641 → **642**）；并锁 `CHAPTER_PLAN_PATHS[3]` 仍空、`MDS_WORLD_FILES[3]` 仍指旧 `chapter_4.mdsworld.json`、旧第 4 章 9 房/17 门世界仍在、第 1/2/3 章计划槽不变、计划清房目标 7/7 个遭遇/波次表（`content_pending = false`）/`boss_scene` 仍空、第 1–3 章事件数值不变、`game.gd` 无 `ch4_event` 专属触发与 `chapter_4_bigmap` 路由。第 4 章仍不可达；Boss 4 机制/`boss_scene`、第 4 章大图验收、可达性未开始；未新增 `ch4_shortcut` 授予，战斗密度/`mask_enemy`/`seat_husk` 独立数值/舞台母题/阿砚同行均未做；待确认第 11–16 项未碰。
- 样图截图（第 60 程，只截图）：新增 `tests/capture_bigmap_chapters.gd`（xvfb + OpenGL 离屏渲染；真实主场景 + 临时挂载第 2/3/4 章计划与大区世界，拍完不写回产品默认值），产出 9 张 1280×720 PNG（每章入口全景 / 纵井 / Boss 战各 1 张，存 `artifacts/screens/ch2|ch3|ch4/`，不提交）；9 张全部通过尺寸/非空/非黑非白核验（像素均值 28.5–46.5、暗像素 ≤ 1.3%、白像素 0%）。产品代码/场景/资源零改动，`CHAPTER_PLAN_PATHS` / `MDS_WORLD_FILES` / 章节路由与第 2/3/4 章不可达状态均未动；截图发现的表现问题只记录不修。
- 第 2–4 章大图样图问题修复（第 63 程，第 64 程接力核验收尾）：`MDSBigRoom._build_backdrop()` 改为以房间底部为锚、自下而上平铺，奇数行 `flip_v` 镜像，相邻瓦片共用边缘行，消除 1440/2160 高房间的纵向硬接缝（`backdrop_rect_local()` 与房间求交）；`game.gd._on_mds_room_loaded` 统计 `BenchCheckpoint`，无 `Arena` 的大图房间只有在作者了长椅或商店时才走休整目标与 `RestRoomData` 文案，三章入口改回「继续前进」；`test_big_room` +18 条镜像接缝像素断言，第 2/3/4 章大图集成 +106/+123/+129 条接缝与文案断言；9 张样图重拍后逐张核验，接缝行行差低于同段中位数。第 60 程问题 1/3/5/6/7 未修（第 13/15 项相关），第 2/3/4 章仍不可达。
- NPC 个人事件第一批（第 65 程，叙事审计 E2）：新增 `NPCEventData`（陆沉/阿砚/咕噜各一个 Hub 个人事件，对白依据 `docs/story-bible.md` 既有弧线与关键道具）、`Profile.npc_events`（`[npc] events` 存档键，旧档缺省为空）、`hub.gd` 事件对话分支。触发 = 信任档 + `Profile.demo_cleared`（陆沉 信任 6 / 阿砚 托付 12 / 咕噜 熟悉 2）；用现有 `DialogueUI` 呈现，读完最后一行才记录，中途关闭不消耗；零奖励、零数值改动、不新增背包物品；咕噜事件后不自动开商店。闻烬/白榆保持不可见、无事件。单元 +187（`test_npc_events`）、`integration_menus` +28；第 1 章/Hub 既有流程无回归，第 2–4 章仍不可达。见「NPC 个人事件（第 65 程）」专节与 ADR。
- 结局文本加厚（第 66 程，叙事审计 E3）：新增 `EndingEchoData`——五个结局 × 五名 NPC 各一句余味（25 句）+ 每结局一段同时回收「笑面史官身份」与「最后一页」的回收段（5 段）；结束屏新增 `Echoes` 标签、结局画廊已解锁条目追加余味与回收段，未解锁仍是原占位。5 个结局 id/标题/现有两句正文/`ending_for` 判定/`Profile.endings` 记录与存档格式一字未改；demo 内不可达的复原/焚毁余味照写并由测试层验证。单元 +469（`test_ending_echoes`），十一套集成与基线逐套件一致全 0 失败。见「结局文本加厚（第 66 程）」专节。
- 手柄：左摇杆移动、A 跳、X 攻击、B 翻滚、Y 交互/言灵、LB/RB 换武器、LT/RT 短语、十字键/Start/Back 菜单快捷键；键位页可重绑手柄键；HUD 与常用提示随最后输入设备切换。
- 菜单焦点：暂停菜单新增设置入口，标题/暂停/设置/键位页打开即抓取焦点，方向键/左摇杆可导航。
- 菜单回归：剧情普通页 B 关闭、对话/商店打开聚焦与关闭恢复焦点、标题「新游戏」改用场景内 `ConfirmPanel`（A 确认 / B 取消 / 焦点回归）；真实手柄 A/B 集成覆盖全部主要菜单与 Hub 设置子页。
- 设置：AI 三 provider 切换/保存有专项集成（临时配置路径，不访问网络）；主音量写入 Profile 并在启动时应用。
- 美术：demo 可见资产全像素化，`tests/check_pixel_assets.py --demo` 36 资产 0 失败。
- 测试（本机 Godot 4.7.stable 实测，第 59 程收尾，HEAD 见本程日志）：单元 **12657 passed / 0 failed**（第 52 程 11925；第 53 程 +620：新增 `test_ch4_content.gd` 613 断言 + 既有测试净 +7；第 54 程 +28：`test_ch4_content` +28、`test_ch4_plan` −1、`test_ch4_world` +1；第 56 程 +1：`test_ch4_content` 触发键一致性；第 57 程 +83：新增 `test_ch4_boss.gd` 78 + `test_ch4_plan` +2、`test_ch4_world` +1、`test_ch4_content` +2；第 58 程不变：新断言全在可玩性集成；第 59 程不变：新断言全在第 4 章大图验收套件）；十一套集成全部 0 失败——结构/可玩性 **894**、第一章 demo **102**、run save **613**、手柄 **207**、UI 提示 **113**、第一章事件 **59**、菜单 A/B **391**、AI 设置 **45**、第 2 章大地图 **2209**、第 3 章大地图 **4235**、第 4 章大地图 **4869**；`--headless --import` 与 `--quit` 退出 0、`ERROR` 0；游戏退出泄漏回归 `tests/check_exit_clean.sh` **10/10 clean**；demo 像素资产检查 **36 / 0**。第 60 程未改测试与产品代码，基线数字不变；新增仅截图脚本 `tests/capture_bigmap_chapters.gd`（不计入单元/集成断言）。第 63/64 程（样图问题修复）后：单元 **12773 / 0**（+18，`test_big_room` 新增背景镜像接缝像素断言）；十一套集成 **894 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2315 / 4358 / 5133** 全 0 失败（第 2 章 2209 → **2315**、第 3 章 4235 → **4358**、第 4 章 5004 → **5133**，新增均为背景接缝与入口文案断言），其余套件不变；退出泄漏 **10/10 clean**、demo 像素资产 **36 / 0**。第 65 程（NPC 个人事件）后：单元 **12960 / 0**（+187，全部为新增 `test_npc_events.gd`）；十一套集成 **894 / 102 / 613 / 207 / 113 / 59 / 419 / 45 / 2315 / 4358 / 5133** 全 0 失败（仅菜单 A/B 391 → **419**，+28 为真实 Hub 个人事件断言；其余十套与第 64 程基线逐套件一致）；退出泄漏 **10/10 clean**、demo 像素资产 **36 / 0**。第 66 程（结局文本加厚）后：单元 **13429 / 0**（+469，全部为新增 `test_ending_echoes.gd`）；十一套集成 **894 / 102 / 613 / 207 / 113 / 59 / 419 / 45 / 2315 / 4358 / 5133** 全 0 失败，与第 65 程逐套件一致；退出泄漏 **10/10 clean**、demo 像素资产 **36 / 0**。第 67 程（接力收尾第 66 程）复跑确认：单元 **13429 / 0**、十一套集成 **894 / 102 / 613 / 207 / 113 / 59 / 419 / 45 / 2315 / 4358 / 5133** 全 0 失败、退出泄漏 **10/10 clean**、demo 像素资产 **36 / 0**，与第 66 程自称逐项一致。
- 控制器 UI：`ui_accept`/`ui_cancel` 已补手柄 A/B（Godot 内置 UI 动作本身不带面键），菜单确认/返回在实机手柄上可用；设置页的子页（AI/键位/说明）可逐层用 B 关闭并恢复焦点。
- 构建：Windows/Android 构建配置与产物路径（产物不提交）；Windows 120 FPS 记录。第 3 程已验证 Windows debug 与 release headless 导出成功（单 exe，embedded PCK）。第 75 程按用户 2026-11-06 拍板为 v0.12.0 里程碑重新导出 release：`build/windows/changzi-adventure.exe` **132,104,632 bytes**（约 126.0 MiB，PE32+ x86-64，内嵌 PCK 22,930,348 bytes），zip **59,572,799 bytes** 存 `artifacts/releases/v0.12.0/`（不提交）；导出/打包已验证，Windows 实机首跑与代码签名/安装器仍待发行阶段。

## 未完成（按优先级）

| # | 项目 | 说明 | 预估 | 状态 |
|---|---|---|---|---|
| 1 | T16 局内 run save/resume | 已完成：进房/奖励/事件/商店/残碑/宝箱/权柄/暂停/窗口关闭保存；标题「继续本局」；死亡/通关/返回 Hub/重开删除；坏档丢弃；备份恢复；续玩保留血量/墨量/污染/背包/武器/短语/权柄/房间进度/一次性拾取/Boss 后续 | M | ✅ 已完成 |
| 2 | T15 手柄 + 焦点导航 | 已完成：全动作手柄映射与轴、键位页手柄重绑、暂停设置入口、标题/暂停/设置/键位页焦点、HUD/帮助/对话/地图/教程/残碑等提示按设备切换 | M | ✅ 已完成 |
| 3 | 退出音频泄漏 | 已完成：根因是退出时音频线程仍持有正在播放的 Ogg playback 引用；`AudioManager` 在 teardown 先 stop、留 100ms 给混音线程结算再释放流，场景层不再抢先 shutdown。验证 `--quit-after 400` 30/30 + 回归脚本 10/10 次 0 ObjectDB/resource 泄漏；`tests/check_exit_clean.sh` 可重复验收（详见日志） | S/M | ✅ 已完成 |
| 4 | v1 旧存档 `discovered_phrases` 迁移 | 已完成（按用户拍板口径）：旧 meanings 字符串原样保留在 `legacy_discovered_phrases`，不展示、不参与逻辑；只有新格式 `id1,id2|count` 进入 Codex；纯旧档/混合档/已迁移档重复加载均有自动化测试 | S | ✅ 本程完成 |
| 5 | 存档 v2 `.bak` 实机路径 | 已完成：补「主文件缺失 + 备份存在」「主文件损坏 + 备份存在」「两者皆无」自动化测试；修复 `ConfigFile` 失败后复用实例导致备份二次加载失败的真实缺陷（`Profile` 与 `RunSave` 均已修） | S | ✅ 本程完成 |
| 6 | 截图补齐 | 不需真人部分已完成：新增 `tests/capture_authority_ending.gd`，用 xvfb + OpenGL 离屏渲染产出权柄选择/结束屏 1280×720 与 2560×1440 截图（`artifacts/screens/`，未提交）；纯 `--headless` 为 dummy 渲染器无法截图。1080p 实机截图归入很久以后的发行阶段，现阶段不做 | S | ✅ 自动化部分完成 |
| 7 | 5–10 人封闭试玩 | 用户 2026-11-03 拍板搁置：不组织、不冻结功能 | — | 已搁置 |
| 8 | T17 权柄 P1 + 叙事扩展 | 吞噬/归档、信任分层、结局画廊已完成（第 25 程）；Boss 2 机制已完成（第 35 程）；Boss 3 机制已完成（第 45 程）；Boss 4 机制已完成（第 57 程：计划 `boss_scene` 路由既有 `smiling_archivist.tscn`，镜面弹幕/纸页波/墨雨/改写与数值由 `test_ch4_boss` + 可玩性集成锁定；入场/阶段文案第 53 程已编写）；NPC 个人事件第一批（第 65 程）：陆沉/阿砚/咕噜三个 Hub 事件，信任档 + `demo_cleared` 触发、一次性、零奖励；结局文本加厚（第 66 程）：五结局 × 五 NPC 余味 + 每结局「笑面史官 / 最后一页」回收，结束屏与已解锁画廊展示，判定/记录/存档不变；闻烬/白榆事件仍待拍板 | L | 🔶 三项完成，Boss 2/3/4 完成，NPC 个人事件第一批 + 结局余味完成；闻烬/白榆事件待拍板 |
| 9 | T18 发行准备 | **发行阶段事项，第 75 程按用户拍板部分提前。** 第 3 程已留档：安装器脚本 `packaging/windows/changzi-adventure.iss`、打包 README 与 `docs/release/windows-signing.md`（signtool/时间戳/Inno 签名/CI 步骤）。第 75 程已从 HEAD `7d11fc2` 重新导出 Windows release exe（132,104,632 bytes，内嵌 PCK）并打 zip（59,572,799 bytes），见「Windows 导出（第 75 程）」专节；真实代码签名证书、安装器编译、Windows 实机首跑仍推迟/待验证 | L | 导出/打包已完成；签名/安装器/实机待发行阶段 |
| 10 | 第 2–4 章 demo 化 | 第 2 章大地图可行性核查已完成（第 26 程，见下方专节）；施工第 1 步解耦（第 27 程）、第 2 步房间生产管线（第 28 程）、第 3 步纵向/捷径道具管线（第 29 程）、第 4 步前半段的计划/图骨架（第 30 程）与后半段的真实大区世界/房间 + `game.gd` region 语义（第 31 程）已完成；第 32 程完成内容数据层第 1 步（第 2 章事件数据、权柄池、Boss 入场/阶段文案、遭遇/波次校验）；第 33 程完成内容数据层第 2 步的波次接线（计划 `wave` 按遭遇节点 id、6 波对应、大区 Arena 逐节点生成），第 34 程完成内容数据层第 3 步的事件区真实自动触发（区域级触发、节点 id 一次性结算、重载不重复），第 35 程完成第 2 章 Boss 2 独特机制与章末收口（肺钟守卫呼吸/钟摆/钉子、计划 `boss_scene` 路由、第 2 章末停章、大图生成高度修正）；第 36 程完成第 2 章大地图系统验收（九区连通/边界/纵向/过渡/一次性/多遭遇/捷径/Boss/续玩全链路 1303 断言，修复 bot 门到达回弹，性能基线已记录）；第 37 程补齐第 2 章大图门视觉（九区 22 扇，`GateVisual`）与第 2 章新局出生点（`ch2_entry` `SpawnPoint`）；第 38 程补第 2 章地图标题（按章节区域派生，第 1 章不变）并完成第 2 章敌人美术核查（仅 `choir_summoner` 有专属精灵、已接线；其余四种缺美术，保留回退并记录清单）；第 39 程完成第 3 章大地图可行性核查（只查不施工：旧第 3 章 9 房/17 门/6 波/文本语音/Boss 3 专属脚本与立绘均在，缺口为计划、大区世界、事件数据、权柄池、Boss 入场/阶段文案与第 3 章大图验收套件；第 3 章独有差异为海面母题、视野压缩、捷径来源、章末边界）；第 40 程完成第 3 章计划与图骨架（9 区、6 战斗遭遇 + 1 事件占位 = 清房目标 7、3 宝箱/2 残碑、11 门 = 9 双向 + 2 单向、每区坠落平面 240；`content_pending` 只推迟波次表；计划未接入 `game.gd`）；第 41 程完成第 3 章真实大区世界（9 个 `BigRoomData` + 9 个 `MDSBigRoom` 场景 + 独立世界/场景，22 门 = 20 有向 + 2 只到达，入口 `SpawnPoint`，每区坠落 240；世界仍不被 `game.gd` 引用、计划槽仍空）；第 42 程完成第 3 章内容数据层第 1 步（`Ch3EventData`、计划基础权柄池、Boss 3 入场/阶段文案、6 场战斗 ↔ `ROOM_WAVES[2]` 六波校验；计划仍无 `wave` 表、仍未接入 `game.gd`），第 43 程完成第 3 章内容数据层第 2 步（计划 `wave` 按遭遇节点 id 接 `ROOM_WAVES[2]` 六波、事件/Boss 无普通波、清房目标 7、`content_pending` 清零），第 44 程完成第 3 章内容数据层第 3 步（`ch3_event` 区域级真实自动触发、节点 id 一次性结算、读/拿沿用第 42 程口径；未新增触发路径、仍未接入 `game.gd`），第 45 程完成第 3 章 Boss 3 独特机制与 `boss_scene` 路由（镜面弹幕/读页/空白页窗口、计划路由既有 `last_reader.tscn`、数值暂定由测试锁定；计划仍未接入 `game.gd`），第 46 程完成第 3 章章末收口（章末选择后 `_finish(true)` 停章、不自动进第 4 章；第 1/2/4 章分支未改；真实大区世界 + 计划走完 Boss 3 → 权柄 → outro → 章末选择 → 停章，可玩性集成 754），第 47 程因网关中断夭折，第 48 程完成第 3 章大地图系统验收（`tests/integration_ch3_bigmap.gd` 3424 断言 0 失败、连续两次；性能基线已记录；未发现产品缺陷），第 49 程完成第 3 章大图门视觉专项（22 扇门逐门断言 + 修复舱口贴墙标题越界）与第 3 章敌人美术核查（`ROOM_WAVES[2]` 8 种：5 接线白 tint / 3 缺美术回退；第 3 章集成 4235 断言 0 失败），第 50 程完成第 4 章大地图可行性核查（只查不施工：大区管线可直接承载；缺口为计划/大区世界/事件/权柄/Boss 文案与第 4 章验收；美术素材已画好并接线、8 种敌人无回退；第 4 章仍不可达），第 51 程完成第 4 章计划与图骨架（9 区连通图、6 战斗遭遇 + 1 事件占位 = 清房目标 7、3 宝箱/2 残碑、11 门 = 9 双向 + 2 单向、每区坠落 240；`content_pending` 只推迟波次表；计划未接入 `game.gd`，真实大区世界未开始；首次尝试因网关中断夭折，本程接力完成），第 52 程完成第 4 章真实大区世界（只做结构层：9 个 `BigRoomData` + 9 个 `MDSBigRoom` + 独立世界/场景，22 门 = 20 有向 + 2 只到达，`elite_boss` 单向、捷径屏障默认封闭，入口出生点，每区坠落 240，电梯/单向落台/长椅骨架；世界仍不被 `game.gd` 引用），第 53 程完成第 4 章内容数据层第 1 步（`Ch4EventData` 7 组事件、计划基础权柄池续命/改写、Boss 4 入场 8 条 + 阶段 2/3 各 8 条；计划仍 `content_pending`、无 `wave` 表、无 `boss_scene`，仍不被 `game.gd` 引用），第 54 程完成第 4 章内容数据层第 2 步（计划 `wave` 按遭遇节点 id 接 `ROOM_WAVES[3]` 六波、事件/Boss 无普通波、清房目标 7、`content_pending` 清零；计划仍不路由、仍不被 `game.gd` 引用），第 56 程完成第 4 章内容数据层第 3 步（事件区真实自动触发验证：`ch4_event` 沿用通用大图区域分支、进入即开第 4 章事件页、节点 id 一次性结算、重载不重复、run save 同一键；未新增触发路径、计划仍未接入 `game.gd`），第 57 程完成第 4 章内容数据层第 4 步（Boss 4 机制与 `boss_scene` 路由：计划指向既有 `smiling_archivist.tscn`，阶段映射/镜面弹幕/墨雨/改写/数值/生成高度由 `test_ch4_boss` 与可玩性集成锁定；计划仍未接入 `game.gd`），第 58 程完成第 4 章章末收口（`_complete_chapter` 显式 `_chapter == 3` → `_finish(true)` 结束战役；真实大区世界走完 Boss 4 → 权柄 → 第 4 章 outro → 章末选择 → 战役结束；可玩性集成 894），第 59 程完成第 4 章大地图系统验收（`tests/integration_ch4_bigmap.gd` 4869 断言 0 失败、连续两次；九区连通/22 门全走/边界相机/纵向/过渡/一次性/多遭遇/捷径隐藏/Boss/续玩/性能 + 第 4 章专属表现全部断言；性能基线已记录；未发现产品缺陷），第 3 章可达性未开始；第 76–77 程完成第 2 章可达性接线第 1 步（第 1 章章末选择 → 第 2 章开场/大图/Boss 2 → 章末停章，见「第 2 章可达性接线第 1 步（第 76–77 程）」专节），第 3/4 章仍不可达；第 60 程样图已产出（只截图、未改游戏内容，PNG 不提交）：`artifacts/screens/ch2/ch2_entry_panorama.png`、`ch2/ch2_well_shaft.png`、`ch2/ch2_boss_lung_bell.png`、`ch3/ch3_entry_panorama.png`、`ch3/ch3_well_shaft.png`、`ch3/ch3_boss_last_reader.png`、`ch4/ch4_entry_theater.png`、`ch4/ch4_well_backstage.png`、`ch4/ch4_boss_smiling_archivist.png`（共 9 张 1280×720）；第 62 程完成第 4 章大图门视觉专项与敌人美术核查（22 门逐门断言、地图标题复核、`ROOM_WAVES[3]` 7 敌专属美术锁定；无产品缺陷，见「第 4 章大图门视觉专项与敌人美术核查（第 62 程）」专节），第 63 程修复第 60 程样图的两项可修问题（大区背景纵向接缝、入口/枢纽休整文案路由，第 64 程接力核验与收尾，见「第 2–4 章大图样图问题修复（第 63 程）」专节）；第 80 程完成第 3 章可达性接线第 1 步（第 2 章章末选择 → 第 3 章开场/`ch3_entry` 大图 → 真实清房 → Boss 3 → 权柄 → outro → 章末停章，第 3 章已可达、第 4 章仍不可达；见「第 3 章可达性接线第 1 步（第 80 程）」专节） | L | 第 2 章施工第 1–4 步 + 内容数据第 1–3 步 + Boss 2/章末 + 第 2 章验收 + 地图标题/敌人美术核查完成；第 3 章核查 + 计划/图骨架 + 真实大区世界 + 内容数据层第 1–3 步 + Boss 3 机制/路由 + 章末收口 + 大图验收 + 门视觉专项 + 敌人美术核查完成（未接入游戏）；第 4 章核查 + 计划/图骨架 + 真实大区世界 + 内容数据层第 1–4 步（波次接线、事件区真实触发验证、Boss 4 机制/`boss_scene` 路由）完成、第 4 章章末收口完成、大图验收完成（未接入游戏）；第 60 程样图已产出（9 张 1280×720，见说明）；第 62 程完成第 4 章大图门视觉专项、地图标题复核与敌人美术核查（22 门逐门、`ROOM_WAVES[3]` 7 敌全部专属美术、无产品缺陷；未接入游戏）；第 63 程修复样图两项可修问题（背景接缝、入口休整文案），第 64 程核验收尾；第 76–77 程完成第 2 章可达性接线第 1 步（第 1 章章末 → 第 2 章大图 → Boss 2 → 章末停章，第 2 章已可达）；第 78 程接入第 2 章四敌专属美术（`breath_hound`/`lung_moth`/`rust_whisperer`/`collapse_husk` 全部接线、回退表清空、无剩余缺图）；第 80 程完成第 3 章可达性接线第 1 步（第 2 章章末 → 第 3 章大图/Boss 3 → 章末停章，第 3 章已可达）；第 4 章仍不可达；第 81 程更新 README 口径（第 1–3 章可玩、第 4 章仍不可达） |
| 11 | Android/触屏 | 本阶段明确不考虑 | — | 不排期 |
| 12 | 测试夹具退出泄漏 | 已完成：5 个测试文件未释放 `Profile` / `Enemy`（含其 `BurnStatus` 子节点）；补齐 `free()` 后全量单元测试连续 10 次退出均为 0 ObjectDB / 0 resource / 0 RID | S | ✅ 本程完成 |
| 13 | 第 2 章大地图施工 | 按「第 2 章大地图可行性核查」E 节顺序：计划/房间管线 → game.gd 解耦 → 纵向道具 → 内容 → Boss/权柄/事件 → 测试；开放可达性前保持不可达。第 27 程完成第 1 步三项基础解耦（坠落平面/节点 id/计划目标）；第 28 程完成第 2 步房间生产管线（可变尺寸/多层/按区背景/氛围/自动门/坠落 metadata）；第 29 程完成第 3 步纵向/捷径道具管线（单向落台/塌陷平台/移动平台/长椅检查点/条件门捷径），第 1 章未迁移；第 30 程完成第 4 步前半段（第 2 章计划 + 9 区图骨架/夹具）；第 31 程完成第 4 步后半段（9 个真实大区世界/房间 + `game.gd` region 语义），第 2 章仍不可达；第 32 程完成内容数据层第 1 步（`Ch2EventData`、权柄池、Boss 入场/阶段文案、遭遇/波次校验）；第 33 程完成内容数据层第 2 步（计划 `wave` 按遭遇节点 id、6 场战斗 ↔ `ROOM_WAVES[1]` 六波、大区 Arena 逐节点生成/结算），第 34 程完成内容数据层第 3 步（`ch2_event` 区域级真实自动触发、按节点 id 一次性结算、重载不重复），第 35 程完成第 2 章 Boss 2 独特机制与章末收口（肺钟守卫呼吸/钟摆/钉子、计划 `boss_scene` 路由、第 2 章末停章、大图生成高度修正），第 36 程完成第 2 章大地图系统验收（D 节 10 项 1303 断言 0 失败；修复 bot 门到达回弹；记录性能基线与后续候选）；第 37 程补齐第 2 章大图门视觉与第 2 章新局出生点（第 1 章无回归）；第 38 程补第 2 章地图标题并完成敌人美术核查/接线（第 1 章无回归）；第 39 程完成第 3 章大地图可行性核查（只查不施工，见「第 3 章大地图可行性核查（第 39 程）」专节），第 40 程完成第 3 章计划与图骨架（9 区、6 战斗遭遇 + 1 事件占位 = 清房目标 7、11 门、每区坠落平面 240；`content_pending` 只推迟波次表；计划未接入 `game.gd`，见「第 3 章计划与图骨架（第 40 程）」专节），第 41 程完成第 3 章真实大区世界（9 个 `BigRoomData` + 9 个 `MDSBigRoom` + 独立世界/场景，22 门、入口出生点、每区坠落 240；世界仍不被 `game.gd` 引用，见「第 3 章真实大区世界（第 41 程）」专节）；第 42 程完成第 3 章内容数据层第 1 步（`Ch3EventData`、权柄基础池、Boss 3 入场/阶段文案、遭遇/波次校验；计划仍无 `wave` 表、未接入 `game.gd`），第 43 程完成第 3 章内容数据层第 2 步（计划 `wave` 按遭遇节点 id 接 `ROOM_WAVES[2]` 六波、事件/Boss 无普通波、清房目标 7、`content_pending` 清零），第 44 程完成第 3 章内容数据层第 3 步（`ch3_event` 区域级真实自动触发、节点 id 一次性结算、读/拿沿用第 42 程口径；未新增触发路径、仍未接入 `game.gd`），第 45 程完成第 3 章 Boss 3 独特机制与 `boss_scene` 路由（镜面弹幕/读页/空白页窗口、计划路由既有 `last_reader.tscn`、数值暂定由测试锁定；计划仍未接入 `game.gd`），第 46 程完成第 3 章章末收口（`_complete_chapter` 新增 `_chapter == 2` 分支，章末选择后 `_finish(true)` 停章、不再自动进第 4 章；第 1/2/4 章分支未改；真实大区世界 + 计划走完 Boss 3 → 权柄 → outro → 章末选择 → 停章，可玩性集成 754），第 47 程因 Magpie 网关中断夭折（无提交），第 48 程完成第 3 章大地图系统验收（九区连通/22 门/边界相机/纵向/过渡/一次性/双遭遇/捷径隐藏/Boss/续玩/性能，3424 断言 0 失败、连续两次；性能基线已记录；未发现产品缺陷；4 处验收脚本自身口径/时序问题已修），第 49 程完成第 3 章大图门视觉专项（22 扇门逐门断言、修复 `ch3_well/top1`/`ch2_well/top1` 舱口标题越界）与敌人美术核查（8 种：5 接线 / 3 回退，缺口记录；第 3 章集成 4235 断言 0 失败），第 50 程完成第 4 章大地图可行性核查（只查不施工：大区管线可直接承载；缺口为计划/大区世界/事件/权柄/Boss 文案与第 4 章验收；美术素材已画好并接线、8 种敌人无回退；第 4 章仍不可达），第 51 程完成第 4 章计划与图骨架（9 区连通图、6 战斗遭遇 + 1 事件占位 = 清房目标 7、11 门 = 9 双向 + 2 单向、每区坠落 240；`content_pending` 只推迟波次表；计划未接入 `game.gd`、真实大区世界未开始，见「第 4 章计划与图骨架（第 51 程）」专节），第 52 程完成第 4 章真实大区世界（结构层：9 个 `BigRoomData` + 9 个 `MDSBigRoom` + 独立世界/场景，22 门 = 20 有向 + 2 只到达、`elite_boss` 单向、`hub_shortcut_entry` 带 `requires` 默认封闭、入口 `SpawnPoint`、每区坠落 240、电梯/单向落台/长椅骨架；世界仍不被 `game.gd` 引用，见「第 4 章真实大区世界（第 52 程）」专节），第 53 程完成第 4 章内容数据层第 1 步（`Ch4EventData` 7 组事件、计划基础权柄池续命/改写、Boss 4 入场 8 条 + 阶段 2/3 各 8 条；计划仍 `content_pending`、无 `wave` 表、无 `boss_scene`，仍不被 `game.gd` 引用，见「第 4 章内容数据层第 1 步（第 53 程）」专节），第 54 程完成第 4 章内容数据层第 2 步（计划 `wave` 按遭遇节点 id 接 `ROOM_WAVES[3]` 六波、事件/Boss 无普通波、清房目标 7、`content_pending` 清零；计划仍不路由，见「第 4 章内容数据层第 2 步（第 54 程）」专节），第 56 程完成第 4 章内容数据层第 3 步（事件区真实自动触发验证，见「第 4 章内容数据层第 3 步（第 56 程）」专节；计划仍不路由、世界仍不被 `game.gd` 引用），第 57 程完成第 4 章 Boss 4 机制与 `boss_scene` 路由（见「第 4 章 Boss 4 机制与 `boss_scene` 路由（第 57 程）」专节），第 58 程完成第 4 章章末收口（`_complete_chapter` 显式 `_chapter == 3` → `_finish(true)` 结束战役，可玩性集成 894；见「第 4 章章末收口（第 58 程）」专节），第 59 程完成第 4 章大地图系统验收（`tests/integration_ch4_bigmap.gd` 4869 断言 0 失败、连续两次，覆盖第 36/48 程 D 节 1–10 项 + 第 4 章专属表现；未发现产品缺陷；见「第 4 章大地图系统验收（第 59 程）」专节），第 3 章可达性未开始；第 76–77 程完成第 2 章可达性接线第 1 步（第 1 章章末选择 → 第 2 章大图/Boss 2 → 章末停章；第 3/4 章仍不可达）；第 80 程完成第 3 章可达性接线第 1 步（见「第 3 章可达性接线第 1 步（第 80 程）」专节），第 3 章已可达、第 4 章仍不可达 | L | 🔶 第 1–4 步 + 内容数据第 1–3 步 + Boss 2/章末 + 验收 + 地图标题/敌人美术完成；第 3 章核查 + 计划/图骨架 + 真实大区世界 + 内容数据层第 1–3 步 + Boss 3 机制/路由 + 章末收口 + 大图验收 + 门视觉专项 + 敌人美术核查完成（未接入游戏）；第 4 章核查 + 计划/图骨架 + 真实大区世界 + 内容数据层第 1–4 步（波次接线、事件区真实触发验证、Boss 4 机制/`boss_scene` 路由）完成、第 4 章章末收口完成、大图验收完成（未接入游戏）；第 2 章已接通（可达性第 1 步完成）；第 78 程补齐第 2 章四敌专属美术（`breath_hound`/`lung_moth`/`rust_whisperer`/`collapse_husk` 已接线、回退表清空）；第 80 程完成第 3 章可达性接线第 1 步（第 2 章章末 → 第 3 章大图/Boss 3 → 章末停章，第 3 章已可达）；下一步由监工定第 2 章演出打磨/第 11–13 项拍板与第 3 章演出打磨、第 4 章可达性（须单独拍板）；第 81 程更新 README 口径（第 1–3 章可玩、第 4 章仍不可达） |

## 叙事审计（第 24 程，只查不写）

> 依据：`docs/story-bible.md`、`docs/GDD.md`、`docs/superpowers/plans/2026-11-02-chapter1-demo-review-and-plan.md`（T17）、仓库内实际脚本/资源。只记事实与缺口；需要新增的文本只列提纲，本程不写大段剧情。

### A. 五名 NPC 的人物弧落地程度

| NPC | 已有落地 | 剧情圣经要求但未落地 |
|---|---|---|
| 陆沉 | `NPCProfiles` 3 句来历；11 句常驻闲聊；5 个关键词回应；AI system prompt；解词/讲述/档案馆三个职能 | 「撕下三页名册是为了保护自己」的承认事件；红色文件夹/入职档案；结局后交付文件夹 |
| 阿砚 | 4 句来历；11 句闲聊；6 个关键词（「神」「真名」给信任/免费锻造）；锻造基底/神铸职能 | 「拒绝承认神格→再烧一次炉」的弧线事件；叫出真名的完整分支；断页剑作为墓碑的含义；结局后走出铁匠铺 |
| 咕噜 | 3 句来历；11 句闲聊；5 个关键词（打折/碎片）；商店/传闻职能 | 「有一件东西不卖」的转折；装着「永」字的玻璃瓶；结局后「这个不卖，借你」 |
| 闻烬 | 3 句来历；11 句闲聊；5 个关键词；情报/契约职能。**demo 中 `hub.gd` 把闻烬与白榆设为不可见、`talk_to_npc` 直接返回** | 同门/除名/断尖笔的揭示；「承认自己也想被记住」的弧线；结局后重写自己的名字 |
| 白榆 | 3 句来历；11 句闲聊；5 个关键词；地图/近路职能。**demo 中不可见** | 「所有没走完的路」的身份揭示；没有终点的手绘地图；结局后新路 |

事实：五人的弧光目前都只有**静态档案文本 + 闲聊 + 关键词回应**，没有任何按进度/信任推进的个人事件、专属道具、章节插入或结局收束段落。剧情圣经列出的五件关键道具中，只有「断页剑」作为武器存在，红色文件夹、玻璃瓶、断尖笔、手绘地图均未实现。闻烬、白榆在 demo 里连闲聊都不可达。

### B. 第 2–4 章剧情节点

| 章节 | 已有文本/资源 | 可达性 | 缺口 |
|---|---|---|---|
| 第二章 · 呼吸废墟 | `CampaignData` 6 句开场、4 句章末、2 个章末选项；Boss「肺钟守卫」；9 房间 MDS 世界；`ch2_intro/outro` 语音 | **不可达**（第一章章末选择后直接 `_finish(true)`） | 第 26 程时：无第一章式 `ChapterPlanData` 房间计划/事件房/休息室/书库；阿砚带路与「打过钉子」只在开场文本里；无个人事件。第 30–35 程已补第 2 章计划、大区世界、事件、波次与 Boss 2 场景 |
| 第三章 · 无光海 | 6 句开场、4 句章末、2 个选项；Boss「最后的读者」；9 房间 MDS 世界；`ch3_intro/outro` 语音 | **不可达** | 同上；「最后的读者是孩子」只在文本；无专属事件/抉择之外的剧情节点 |
| 第四章 · 笑面剧场 | 7 句开场、4 句章末、2 个选项；Boss「笑面史官」；9 房间 MDS 世界；专属背景图与语音 | **不可达** | 同上；「念出同行者名字」「未来的昌子」等节拍只在开场文本；Boss 2–4 独特机制按 DECISIONS 本阶段不做 |

事实（第 26 程核查时）：第 2–4 章的**主线骨架文本与语音已经齐全**（开场/章末/选项/Boss 名），MDS 世界场景各 9 个房间也存在；但没有第一章那套手工房间计划、事件房、残碑/书库/休息室内容，且正常流程不可进入。Boss 2–4 的独特机制未实现（第二章与第一章共用 `ink` 脚本；第三章 `reader`、第四章 `smiling` 仅有脚本标识）。第 27–35 程已补齐第 2 章的计划/大区世界/事件/波次与 Boss 2 `LungBellGuardian`；Boss 3–4 仍未实现，本段保留为核查基线，当前状态见「已完成」。

### C. 五个结局的实际文本与可达性

| 结局 | 文本 | 记录 | demo 可达性 |
|---|---|---|---|
| 复原 restored | `CampaignData.ending_for` 已有标题+2 句正文；`ending_restored` 语音 | `Profile.record_ending` 写入 `endings` | **不可达**：需要 `mercy >= 2`，demo 只有第一章一次章末选择，最多 +1 |
| 焚毁档案 burned | 同上；`ending_burned` 语音 | 同上 | **不可达**：需要第四章最终选择「焚毁名册」，demo 停在第一章 |
| 深渊回响 abyss | 同上；`ending_abyss` 语音 | 同上 | 可达：胜利且污染 ≥ 60 |
| 未完的注脚 unfinished | 同上；`ending_unfinished` 语音 | 同上 | 可达：胜利、仁慈 < 2、污染 < 60、未焚毁（demo 默认胜利路径） |
| 记录中断 interrupted | 同上；`ending_interrupted` 语音 | 同上 | 可达：死亡/放弃 |

事实：五个结局的**标题、正文与语音都存在**，胜负与污染/仁慈/焚毁判定在 `CampaignData.ending_for` 中集中实现；`Profile.endings` 已能去重记录已达成 id，`runs_completed` / `records_found` 也在累计。缺口：`Profile` 只记 id，没有画廊/列表 UI；正文只有 2 句概述，没有剧情圣经要求的逐 NPC 结局余味（红色文件夹、走出铁匠铺、瓶子空了、重写名字、新路）。

### D. 信任分层现状

- 已有：`Profile.npc_trust`（npc_id → float）、`add_npc_trust` / `npc_trust_value`、存档读写（`[npc] trust`）；来源是 NPC 关键词效果（`trust` 键）与听不懂的句子（固定 +0.5）。
- 未实现：没有任何分层定义（阈值/名称）、没有按信任变化的对话态度、折扣、锻造祝福、起始资源或解锁条件；除存档与 `NPCProfiles.apply_effect` 写入外，**没有任何读取方**。AI prompt 也没有注入当前信任。结论：信任目前只是被保存的原始数值。
- 言灵评估器：离线 `NPCProfiles.resolve` 与 AI `AIService.request_npc_reply` 均存在，AI 默认关闭、失败回退离线、每 NPC 每次回 Hub 只结算一次（不双叠）；但两者都不读取信任。

### E. 缺口清单与文本提纲（只列提纲，不写正文）

1. **信任分层**（本程任务 3）：4 档定义（陌生/熟悉/信任/托付）、阈值、存档兼容；态度短句（每 NPC 每档 1 句）、商店/锻造折扣、锻造祝福、起始残页、离线评估器与 AI prompt 注入；保持 AI 默认关闭/静默回退/不双叠。
2. **NPC 个人事件**（后续）：每人 1 个 Hub 触发事件 + 1 个关键道具 + 1 个结局余味；触发条件用信任档 + 章节进度；闻烬/白榆需先在 demo 中可见或明确维持隐藏。
3. **结局文本加厚**（后续）：每个结局补 5 名 NPC 的余味各 1 句；补「笑面史官身份」「最后一页」的回收；不改现有 5 个 id 与判定。
4. **第 2–4 章叙事内容**（后续，随各章补完）：每章房间计划、事件房/残碑/书库、NPC 同行插入、Boss 3–4 阶段台词与机制（Boss 2 已完成，第 35 程）；仍维持不可达直到章节制作。
5. **结局画廊**（本程任务 4）：解锁记录沿用 `Profile.endings`，5 个条目、未解锁占位、标题屏入口与手柄/键盘焦点。

## 第 2 章大地图可行性核查（第 26 程，只查不施工）

> 范围：按 `.supervisor/DECISIONS.md`「关卡结构方向」核查 MDS 与第 2 章现状，回答“现有系统能否承载单张连通大图、缺口在哪、怎么排施工”。
> 本程未改第 2 章可达性、未改游戏行为、未新增关卡内容；临时探针测后删除。
> 标记：**【已核实】** 读代码/资源或实跑探针可复现；**【推断】** 由已核实事实推导、尚未实跑；**【待施工验证】** 必须等真实大图内容落地后才能定论。

### 结论摘要

- **可行性：可以承载，不需要重写 MDS 或存档系统。** MDS 的 room 是“加载单元”，不是“屏幕”：房间矩形可任意大小、可由多个矩形拼成不规则形状，门/无缝衔接/相机限制/地图/存档都按世界坐标工作。第 2 章大地图应当做成**一张连通图 = 多个大区（MDS room）组成的图**，而不是把整章塞进一个 12000 px 的单场景。
- **真正的施工面不在 MDS，而在两层**：① 房间生产管线（现有 `MDSChapterRoom` 固定 1280×720、单层地面、单 Arena，只够第 1 章模板）；② `game.gd` 的“一房一战斗/一房一拾取/固定 6 房进度”假设（多战斗区、多宝箱/残碑、纵向掉落保护都要改）。
- **已核实的硬限制**：`game.gd` 的坠落保护按“房间原点下方 850 px”判定（`scripts/game.gd:600-603`）。任何向下超过 850 px 的大房间/下层区域都会把玩家传回检查点并扣 15 血，**大图施工前必须先改成按房间/区域配置的坠落平面**。
- **未启用但已具备的能力**：MDS 的 links 快旅（`world.gd:1032`）、`MDSGateBarrier` 条件门（能力/物件/Boss 条件，开门状态进 MDS 存档）、MDSRoomCamera 的 SLIDE/BLEND 过渡与不规则房间相机分区。第 2 章世界目前 `links` 为空、世界场景没有挂 `MDSRoomCamera`。
- **需要用户拍板的两点**见文末「待用户确认」：大图是“大区图 + 短过渡”还是要字面意义的单场景无缝；垂直交通是否允许新增移动能力。

### A. MDS 系统承载力（逐项）

| 能力 | 结论 | 已核实依据 |
|---|---|---|
| 大房间尺寸 | **能直接用** | 房间几何是 `origin + rects`（32 px 网格），无最大尺寸校验；`get_room_bounds` 取矩形并集，相机限制按它设置（`core/world.gd:371-400`、`nodes/mds_world_game.gd:671-680`）。探针实测 3840×1440 房间加载、相机限制、玩家落点均正确。 |
| 多矩形/不规则房间 | **能直接用（地图/碰撞）；相机需配置** | `room_contains`/`room_at` 逐矩形判定（`core/world.gd:432-450`）；探针实测 L 形 2560×2160 房间：并集边界正确、缺口不可行走。但不挂 `MDSRoomCamera` 时相机只按并集包围盒限制，会看到缺口外的空白；要按矩形分区取景需给世界场景加 `MDSRoomCamera`（`nodes/mds_room_camera.gd:275-330,621`）。 |
| 房间衔接 | **能直接用** | 门由世界 JSON + 场景里的 `MDSGate` 节点连接；`seamless_rooms=true` 时走进相邻矩形会无门切换（`nodes/mds_world_game.gd:232-247`）。探针实测无缝跨房加载 1.6–6.1 ms（轻量测试房间），相机限制随新房更新，玩家位置保持。 |
| 房间过渡 | **能直接用；速度感需小改** | 现有世界统一 `fade_time=0.22`（`scenes/mds/chapter_2_world.tscn`）；MDS 另有 CUT/SLIDE/BLEND 和镜头分区混合（`nodes/mds_room_camera.gd:37,275-310`）。挂 `MDSRoomCamera` 后可做《死亡细胞》式滑镜/混合，**待施工验证**其在第 2 章大区上的观感与相机分区。 |
| 检查点 | **需小改** | MDS 只在“无门进入”时找 `save_point`/`bench` 组决定落点（`nodes/mds_world_game.gd:607-620`）；游戏层每次进房/事件/奖励/商店/宝箱/残碑/暂停/关窗都会写 run save，且 MDS 存档含**精确玩家坐标**（`mds_world_game.gd:908-927`、`game.gd:480-537`）。缺的是“大区内长距离跑图的中途存档点/坠落回退点”：需要一个长椅/检查点物件同时更新 `_last_checkpoint` 并写 run save。 |
| Boss 房接入 | **能直接用** | Boss 房按房间 id `_boss` 或计划 `type=boss` 识别，`ArenaRoom` 内生成 Boss，死亡后走权柄/章末流程（`game.gd:1250-1275,1740-1760`）；第 1 章与第 2–4 章结构测试均覆盖 Boss 生成。大图只需把 Boss 区作为图末端的独立 MDS 房间；大 Boss 场需重摆 `ArenaRoom` 的门/入场判定（入场半宽 530 在 `scripts/levels/room.gd:13`，门在 ±620 见 `scenes/levels/room.tscn:15,31`）。 |
| 垂直探索 | **MDS 能直接用；游戏层需小改** | 世界 JSON 的 gate side 支持 `top`/`bot`（`core/world.gd:850-859`）；从下方进入给至少 650 px/s 向上出速（`nodes/mds_world_game.gd:583-596`）。探针实测 top/bot 门侧、落点向内 96 px、bot 出速 -650 全部正确。**但** `game.gd:600-603` 的 850 px 坠落保护会误杀下层；且 `MDSChapterRoom` 地面固定 y=560、只有单层（`scripts/levels/mds_chapter_room.gd:22-25`），大房间/多层必须换房间生产管线。 |
| 支路/捷径 | **能直接用；快旅未实装** | 门可分叉、可单向（只放一侧门）；`door` 交互门已用于书库/捷径（`mds_chapter_room.gd:246-305`）。MDS links 支持成对快旅/电梯（`core/world.gd:1032`、`nodes/mds_gate.gd` 的 `link`），但四章世界 JSON 的 `links` 全为空，项目内无使用样例，启用属**小改 + 待施工验证**。 |
| 隐藏要素 | **能直接用 + 一个新小道具** | 隐藏书库模式已跑通：交互门进独立房间、首次发现金色反馈（`mds_chapter_room.gd:246-305`、`game.gd:1289-1300`）。条件门 `MDSGateBarrier` 支持能力/物件/Boss 条件且开门状态进 MDS 存档（`nodes/mds_gate_barrier.gd`）。MDS 场景扫描器识别 `breakable/destroyable/destructible/crate` 组（`scene_scanner.gd:26`），但仓库没有可破坏墙运行时脚本；要“打碎墙”需新增一个小型 breakable 道具，否则用条件门/交互门即可。 |
| 地图 | **能直接用** | 游戏内地图由 `MDSWorldMapView` 按世界文件自动缩放适配全部已访问房间（`ui/world_map_view.gd:93-103`），大地图/不同尺寸房间无需改绘制。第 2 章地图标题仍固定“档案馆地图”（`scripts/ui/map_overlay.gd:51`），属内容小缺口。 |
| 存档 | **能直接用** | MDS 的 `get_save_data/set_save_data` 保存当前房、精确坐标、已访问、abilities、stored、defeated、Boss、区域访问等（`mds_world_game.gd:908-970`）；`game.gd` 已把整份 mds 字典塞进 run save 并在续玩时回灌。大图不改变格式。 |
| 性能 | **现状已核实，大图待验证** | 见 D 节探针：真实第 2 章 1280×720 房间热加载 3.7–8.8 ms，Boss 房约 23 ms（`spore_drift` 动态背景），都被 0.22 s 淡入淡出盖住。大房间的瓦片/碰撞/装饰量级会上升，但 MDS 一次只加载一个 room，内存不会叠加整章；**待施工验证**最大区的加载耗时与帧率。 |

### B. 第 2 章现有内容盘点

**已有（已核实）**

- **世界与房间**：`scenes/mds/chapter_2_world.tscn` + `chapter_2.mdsworld.json`，9 个 MDS 房间：`ch2_01`–`ch2_06` 六间战斗房、`ch2_rest`（商店 + 残碑 + 捷径门）、`ch2_vault`（宝箱 + 残碑 + 书库门）、`ch2_boss`。全部 1280×720、单层地面、1–2 个平台模板；探针逐房加载 9/9 通过，Arena/商店/残碑/宝箱/Boss 房节点齐全。区域“Breathing Ruins”，天气雾 + 萤火，Boss 背景 `spore_drift`。
- **主线文本与语音**：`CampaignData` 第 2 章（`scripts/core/campaign_data.gd:71-112`）有 6 句开场、4 句章末、2 个章末选项；`ch2_intro`/`ch2_outro` 语音存在；Boss 名「肺钟守卫」、360 HP、14 伤害、75 速度、专属立绘 `lung_bell_guardian.png`。
- **敌人**：`breath_hound`、`lung_moth`、`rust_whisperer`、`choir_summoner`、`collapse_husk` 的场景与数据存在（`resources/enemies/`），`ROOM_WAVES` 第 2 章波次已配。
- **通用系统**：休整房入场白、残碑、商店、宝箱、书库发现、权柄/言灵/遗物/词条/难度全部章节通用；结构集成测试已覆盖第 2 章 9 房（`tests/integration_playability.gd:34-130`）。
- **旧线性关卡**：`scenes/levels/biome_breathing.tscn` 仍存在，但 `_setup_campaign` 把所有旧 Level 设为不可见 + `PROCESS_MODE_DISABLED`（`scripts/game.gd:1028-1043`），第 2 章实际走 MDS 世界；施工时不要改错对象。

**缺口（已核实）**

- **没有第 2 章房间计划**：`chapter_2_demo.tres` 不存在；`_chapter_plan` 只在 `chapter_index == 0` 加载（`scripts/game.gd:1145-1148`）。因此没有事件房类型、精英房类型、按房波次/奖励池、权柄池。
- **没有事件房与第 2 章事件文本**：事件流程固定读 `Ch1EventData`（`scripts/game.gd:1340-1344`）；第 2 章没有对应数据，做成 `type=event` 会显示第 1 章文案。
- **没有第 2 章权柄授予**：`_grant_chapter_authority` 直接 `if _chapter != 0 ... return`（`scripts/game.gd:1755-1756`）；第 2 章 Boss 击败后不会开权柄三选一。
- **Boss 无独特机制**：第 2 章无 `boss_scene`，走默认 `ink_archivist.tscn` 通用三阶段（纸页波/墨雨/改写）；`lung` 只在 `boss_voice`（阶段语音存在）。Boss 入场文案 `BossEntranceData` 只返回第 1 章（`scripts/data/boss_entrance_data.gd`）；阶段氛围 `BossPhaseData` 也固定第 1 章的纸页/镜面文案（`scripts/data/boss_phase_data.gd`），第 2 章可玩后会看到错位文案。
- **敌人无专属美术**：`ENEMY_ART` 没有第 2 章五种敌人，走 `ENEMY_ART_FALLBACK` 复用第 1 章精灵并染绿（`scripts/game.gd:40-54`）。背景 `breathing_ruins.png` 是绘画风，未做第 1 章式像素化。
- **没有 NPC 同行实体**：阿砚带路只存在于开场文本（`campaign_data.gd:74-79`）；仓库没有随行 NPC 控制器。MDS 的 `carry_over` 组可以把节点带过门（`mds_world_game.gd:776-824`），但“跟随移动 + 途中对话/战斗”是新机制。
- **没有纵向/塌陷内容**：GDD 第 2 章机制写“上下分层、塌陷平台”（`docs/GDD.md:292`），现有 9 房全是单层平地；没有移动平台/塌陷平台脚本。
- **不可达**：第 1 章章末固定 `_finish(true)`（`game.gd:1813-1817`），第 2 章正常流程进不去；本程未改。

### C. 存档与系统联动（大地图影响点）

| 影响点 | 现状（已核实） | 大地图后果 | 处理 |
|---|---|---|---|
| 局内 run save / resume | `game.gd:480-537` 存 room + 精确坐标 + `mds` 字典；MDS `set_save_data` 精确回位（`mds_world_game.gd:908-970`） | 大房间中途退出可原位续玩，无需改格式 | **能直接用** |
| 房间进度 | `_mds_cleared_rooms` 以 **room id** 为键（`game.gd:1373`），`_cleared_in_chapter` 固定 6 房（`game.gd:1477`） | 一个 room 内多场战斗会“清一场=整房已清”，且进度上限写死 6 | **需小改**：战斗/宝箱/残碑改按“节点/遭遇 id”，进度目标从计划读取 |
| 一次性拾取 | `_opened_chests[room_id]`（`game.gd:1934`）、`_claimed_steles[room_id]`（`game.gd:2005`）；续玩时整房宝箱全开、整房残碑全清（`game.gd:1226-1237`） | 大房间放多个宝箱/残碑会互相误伤 | **需小改**：按宝箱/残碑自身 id 记录 |
| 检查点/坠落 | 每次进房设 `_last_checkpoint`（`game.gd:1303`），战斗锁门再设（`:1443`）；坠落保护固定 850 px（`:600-603`） | 下层区域会被误判为坠落；长距离跑图缺少中途回退点 | **需小改**：按房间配置坠落平面 + 长椅/检查点物件 |
| Boss | `_boss_defeated`、`_resume_boss_aftermath`、Boss 房识别均与房间结构解耦（`game.gd:1250-1275,1310-1318`） | 独立 Boss 区可原样接入 | **能直接用** |
| 权柄 | 只给第 1 章池（`game.gd:1755-1756`）；`ChapterPlanData.authority_pool` 已存在（`scripts/data/chapter_plan_data.gd`） | 第 2 章 Boss 后无权柄选择 | **需小改**：放宽到有计划的章节 |
| 事件 | 固定 `Ch1EventData`（`game.gd:1340-1344`），按 room id 每房一次 | 可复用“一房一事件”结构，但需要第 2 章事件数据/模块 | **需新内容 + 小改** |
| 商店/残碑/书库/休整 | `_shop_cache` 按 shop_id；残碑/宝箱见上；`RestRoomData`/`VaultRoomData` 通用 | 多商店/多休整区可支持，只要 id 唯一 | **基本能直接用** |
| 言灵/遗物/词条/难度/信任 | 与房间结构无关，全走 run_state/Profile | 不受影响 | **能直接用** |
| 章节推进 | `_complete_chapter` 在 `_chapter >= 1` 时自动 `_start_chapter(_chapter + 1)`（`game.gd:1815-1821`） | 第 2 章做完会自动进未完成的第 3 章 | 第 2 章完成时加“停在第 2 章末”的收口条件（工程决定，不必问用户） |

### D. 性能与测试面

**探针实测（本程临时探针，测后已删除；headless，Godot 4.7.stable）**

- 合成大房间（3840×1440，约 100 个程序化平台）：加载 **1.3–3.1 ms**；L 形 2560×2160 房间加载同量级；无缝跨房 **1.6–6.1 ms**（轻量内容，不含 `game.gd` 的敌人生成/HUD）。
- 真实第 2 章世界逐房加载（CUT，无淡入淡出，含房间自建地形/背景/天气/Arena）：热加载 **3.7–8.8 ms**（普通房/休整/书库），Boss 房 **约 23 ms**（`spore_drift` 动态背景）；首次访问另有脚本编译尖峰（最高约 55–73 ms），被 0.22 s 过渡盖住。
- **推断**：大房间耗时随瓦片/装饰/敌人数量上升；只要仍用门 + 淡入，几十毫秒可被过渡掩盖；若用无缝走进重内容区，同步 `load(path)` 会掉帧。**待施工验证**最大区 + 多敌人 + 天气的实际数字。

**第 36 程验收实测（含真实敌人/天气/Boss，`fade_time = 0`）**

- 普通区热加载 **5.6–9.2 ms**；Boss 区首次 **61.0 ms**（冷启动）、第二次 **10.2 ms**、套件内热加载 **24–43 ms**（运行波动）；精英区首次 **35.0 ms**；Boss 区关闭动态背景 **11.7 ms**、关闭天气 **9.1 ms**、不生成 Boss **35.9 ms**。正常游玩由 0.22 秒淡入覆盖，未发现需要本程处理的性能缺陷。完整数字见 `docs/memory/sessions/2026-11-04-chapter2-bigmap-acceptance.md`。

**后续施工要补的测试面（第 36 程已按 1–10 项补齐，见 `tests/integration_ch2_bigmap.gd`）**

1. 大图连通性：从入口 BFS 能到休息区/书库/Boss；每扇门双向或明确单向；无孤立房间。
2. 大房间边界/相机：房间并集/多矩形缺口、相机限制、玩家不越界；不规则房间的 `MDSRoomCamera` 分区。
3. 纵向：top/bot 门落点与出速、上下层可达、坠落平面不再误杀、长椅检查点回退。
4. 衔接：门过渡、无缝边界、过渡期间不掉暂停/不叠 UI、续玩回到正确房间与坐标。
5. 一次性内容：一房多宝箱/多残碑各自只发一次；续玩不重复、不误开。
6. 战斗：一房多遭遇的逐场锁门/清怪/奖励；清房进度与 Boss 目标按计划总数。
7. 捷径/隐藏：条件门解锁状态跨存档；隐藏区首次发现反馈；地图揭示。
8. Boss：独立 Boss 区生成/续玩/击败后权柄与章末；大 Boss 场门位。
9. 性能：最大区加载耗时、淡入期间帧时间、无缝切换尖峰、天气/动态背景开销。
10. 叙事/系统：第 2 章事件文案、Boss 阶段/入场文案、权柄池、章节收口（不自动进第 3 章）。

### E. 设计要点与施工顺序

**推荐结构（第 2–4 章通用，本章只给第 2 章示例）**

- 一张连通图 = **6–9 个大区（MDS room）**，每区 1–3 屏大小（例如 2560×1440、3840×2160），用门/无缝边界连接；不是 12000 px 单场景。
- 图形态：入口 → 两三条可回环的支路 → 中央枢纽（休整 + 商店 + 残碑 + 捷径解锁）→ 纵向井/上下层 → 精英/事件区 → Boss 区。支路放隐藏书库/宝箱，捷径从枢纽接回前段。
- 纵向：平台间距按现有跳跃能力（`jump_velocity=-500`、`gravity=1350`，最大跳高约 92.6 px，`scripts/player/player.gd:12-13`、`scripts/levels/room_layout_data.gd`）控制在 ≤80 px；长距离上升用 top/bot 门、电梯/移动平台或单向落台，不硬塞台阶。
- Boss 区独立成一个 room（`ch2_boss` 或计划 `type=boss`），沿用现有 Boss 管线；大 Boss 场再调 `ArenaRoom` 门位。
- 地图仍用 `MDSWorldMapView`：每个大区是一个地图块，已访问点亮；不要合并成一个巨大矩形，否则地图退化成一块。

**施工顺序（建议，非本程施工）**

1. **数据/计划**：给 `ChapterPlanData` 增加大图字段（区的类型/战斗遭遇/宝箱残碑 id/捷径/隐藏/坠落平面/Boss），先写第 2 章计划资源。
   - **第 30 程已完成（前半）**：`ChapterPlanData` 大图字段 + `chapter_2_demo.tres`（9 区、清房目标 7）+ 图骨架夹具与校验。计划暂未接入 `game.gd`，第 2 章实际世界/房间未开工。见 ADR `docs/memory/decisions/2026-11-04-chapter2-big-map-graph.md`。
2. **房间生产管线**：新增可变尺寸、多层地面/平台的房间构建器（或改用 MDS Room view 手绘）；背景按房间宽度平铺；天气/动态背景按区/相机范围控制。现有 `MDSChapterRoom` 保留给第 1 章。
   - **第 28 程已完成**：`BigRoomData` + `MDSBigRoom` + `BigRoomAmbient`。房间尺寸/多矩形并集与相机限制走 MDS；多层地面/平台按现有跳跃（≤80 px 高差、≤120 px 水平边缘）校验；背景按并集平铺、按房间→区域→世界取图；天气/动态背景保留 MDS 按区域解析；氛围只在相机窗口内绘制；门由世界 JSON 自动生成；坠落平面写入房间 metadata。第 1 章未迁移，第 2 章内容未开工。见 ADR `docs/memory/decisions/2026-11-04-big-room-pipeline.md`。
3. **game.gd 解耦**：多遭遇注册/逐遭遇清房、按节点 id 的一次性拾取、计划驱动进度、按房间坠落平面、长椅检查点、第 2 章权柄池、事件数据分章。**第 27/31–35 程已完成**（含大图生成高度修正与第 2 章末停章）。
4. **纵向/捷径道具**：单向落台、塌陷平台（GDD 第 2 章机制）、电梯/移动平台；条件门/可破坏墙按需二选一。
5. **内容**：第 2 章区图、敌人布置、事件、休整/书库、阿砚同行（如做）、Boss 2 机制与阶段/入场文案。**第 31–35 程已完成**区图/房间、事件、波次、Boss 2 机制与阶段/入场文案；阿砚同行未做。
6. **验收**：按 D 节测试面补集成；先保持第 2 章不可达，全部绿后再由监工决定开放。

**风险/边界**

- 不改 MDS 本体、不改存档格式、不改言灵/权柄/战斗框架；新增移动平台/塌陷平台属关卡道具，不碰玩家战斗数值。
- 第 2 章做完前不开放可达性；第 3 章仍不可达，`_complete_chapter` 的自动续章要加收口。
- 如果用户要求“字面意义的单场景无缝大图”，则与上述“大区图”方案不同：需要把整章塞进一个 room（地图退化、单 Arena 限制、天气/背景/加载成本上升），不建议；见待确认第 1 项。

## 第 3 章大地图可行性核查（第 39 程，只查不施工）

> 第 40 程已完成本节 C 节第 1 步「计划/图骨架」，见下方「第 3 章计划与图骨架（第 40 程）」
> 专节；真实大区世界与后续步骤仍未开始。本节的核查结论保持第 39 程口径。
>
> 范围：回答“第 2 章走通的大区连通图路线能否直接承载第 3 章、缺口在哪、施工顺序怎么排”。
> 本程未改第 3 章可达性，未新建计划/大区/房间/事件/权柄/Boss 内容，未改 `game.gd` 章节路由；
> 临时探针 `tests/tmp_ch3_audit.gd` 测后删除。详细版见
> [第 3 章核查 session](docs/memory/sessions/2026-11-05-chapter3-bigmap-audit.md)。
> 标记：**【已核实】** 读代码/资源或实跑探针可复现；**【推断】** 由已核实事实推导、尚未实跑；
> **【待施工验证】** 必须等真实大图内容落地后才能定论。

### 结论摘要

- **可行性：可以直接承载，不需要改 MDS、存档、战斗或房间管线。** `BigRoomData` + `MDSBigRoom`
  不含任何章节判断；第 27 程的按节点 id 结算、按区域坠落平面、计划派生清房目标都是章节无关的。
  第 3 章现有旧世界可以像第 2 章旧世界一样原地保留、不再引用。**【已核实】**
- **缺口集中在内容层**：第 3 章没有计划（`chapter_3_demo.tres` 不存在、`CHAPTER_PLAN_PATHS[2]`
  为空）、没有大区/房间数据、没有事件数据、没有权柄池、没有 Boss 入场/阶段文案、没有第 3 章
  大图验收套件；与第 2 章施工前的缺口同类。**【已核实】**
- **第 3 章独有差异**：① 海面母题目前只在 `MDSChapterRoom` 的 `LivingBackdrop(sea=true)` 里，
  大区管线没有对应层；② GDD §11 的「视野压缩」没有任何实现；③ 捷径授予来源缺失；
  ④ Boss「最后的读者」已有专属脚本/场景/立绘/背景/语音与部分独特攻击，但走 `boss_script`
  旧分支、无计划 `boss_scene`、无入场/阶段文案、无测试锁定。**【已核实】**
  （海面观感与视野压缩的实际效果为**【待施工验证】**。）
- **施工顺序**沿用第 2 章：计划/图骨架 → 真实大区世界 → 内容数据层 → Boss 机制 → 系统验收；
  前置依赖见下。第 3 章可达性仍须单独拍板，且不能早于第 2 章。

### A. 第 3 章现有内容盘点

**MDS 世界与房间【已核实，探针实走】**

- `scenes/mds/chapter_3_world.tscn` + `chapter_3.mdsworld.json`：9 房、17 门
  （7 right / 7 left / 3 door）、`links`/`pins` 为空、`start_room = ch3_01`。
- 全部 **1280×720 单矩形、单层地面**（面 y=560，StaticBody 80 px），平台 2/2/1 块（pattern 0/1/2）；
  没有多矩形、多层或纵向结构。房型/内容：

| 房间 | 名称 | 类型 | 内容 | 门 |
|---|---|---|---|---|
| `ch3_01` | 无光海岸 | 战斗 | 无 | right1 |
| `ch3_02` | 墨潮浅滩 | 战斗 | 无 | left1/right1 |
| `ch3_03` | 沉船书库 | 战斗 | 宝箱×1、书库门 | left1/right1/door1 |
| `ch3_04` | 静水回廊 | 战斗 | 无 | left1/right1 |
| `ch3_05` | 深渊裂口 | 战斗 | 宝箱×1 | left1/right1 |
| `ch3_06` | 第三页之门 | 战斗 | 无 | left1/right1 |
| `ch3_rest` | 引路人的灯 | 休整 | 商店、残碑、捷径门 door2→`ch3_02` | left1/right1/door2 |
| `ch3_boss` | 最后的读者 | Boss | Arena/Boss | left1 |
| `ch3_vault` | 隐藏书库 | 书库（`kind=REST`） | 宝箱、残碑、返回门 door1→`ch3_03` | door1 |

- 场景全部 `MDSChapterRoom`（`chapter_index=2`）：背景 `lightless_sea.png`（1536×864 RGB 绘画）
  + `LivingBackdrop(sea=true)`；`room_darkness=false`、`room_weather=true`、`room_parallax=false`、
  `room_background=true`、`fade_time=0.22`。区域 `Lightless Sea` 用雾 + 雨，`background` 为空、
  无 `backdrop_image`；Boss 房 `boss_background=deep_water`（探针确认
  `MDSEnvironment.background_for_room` 返回 `deep_water`，世界场景 `room_background=true`）。
- 旧线性结构已被 `integration_playability` 的逐章循环实走（属于现有 671 断言的一部分），
  但没有大图结构覆盖。

**主线文本与语音【已核实】**

- `CampaignData` 第 3 章：**6 句开场、4 句章末、2 个章末选项**；目标「穿过无光海，找到最后的读者」；
  音乐 `chapter_sea.ogg` 存在；`ch3_intro.ogg`/`ch3_outro.ogg` 存在；
  `boss_reader_phase2/3.ogg` 存在。
- 章末效果已实现：带读者离开 → 仁慈 +1、恢复 20 生命；留下最后一页 → 污染 +8、获得未拥有遗物。
- Boss：名「最后的读者」、HP 380、伤害 15、速度 78、`boss_script=&"reader"`、
  立绘 `last_reader.png`（256×256 RGBA，持书的孩子）、`boss_scale=1.0`、白 tint、
  `boss_voice="reader"`；**没有** `boss_scene` 键。
- 专属脚本/场景：`scripts/bosses/last_reader.gd`（`LastReader extends InkArchivist`）+
  `scenes/bosses/last_reader.tscn`；已实现镜面三连弹（`_mirror_fan`）与「读页」封印短语
  （`_read_page` → `InkWarning` + `disable_phrase_slot`），阶段 1 纸页波、阶段 2 每 3 次读页、
  阶段 3 改写/读页/镜面/墨雨轮换。Boss 立绘由 `_apply_art` 运行时挂上（探针确认路径）。
- 专属背景：无独立图片，使用 MDS 的 `deep_water` 动态背景（区域级），探针确认已解析。

**敌人与波次【已核实，探针逐房生成】**

- `ROOM_WAVES[2]` **已配置 6 波**；`CampaignData.rooms[2]` 六组首发敌人与数据/场景都存在；
  探针逐房生成的首发组与数据一致。
- 第 3 章用到的 9 种 spawn id：`echo_enemy`、`hanging_scribe`、`rust_whisperer`、
  `mirror_sniper`、`typo_beast`、`collapse_husk`、`scribe_bug`、`lung_moth`、`page_swarm`。
- 美术接线（第 38 程同一口径）：
  - 已接线专属精灵（`ENEMY_ART`，白 tint）：`echo_enemy`、`hanging_scribe`、`mirror_sniper`、
    `typo_beast`、`scribe_bug`、`page_swarm`。
  - 回退第 1 章美术（`ENEMY_ART_FALLBACK`，`#c8e1cd`）：`rust_whisperer`→`scribe_bug`、
    `collapse_husk`→`blank_man`、`lung_moth`→`hanging_scribe`；三种都在第 38 程缺失清单内，
    **没有新增第 3 章专属缺图**。
  - 命名细节：`echo_enemy` 场景内的 `EnemyData.id` 是 `amnesiac_echo`；美术表按 spawn id
    `echo_enemy` 解析，实际渲染正确；日后按 data id 做美术审计需同时认这两个名字。

**章节计划与内容数据【已核实，探针】**

- **`chapter_3_demo.tres` 不存在**；`CHAPTER_PLAN_PATHS[2]` 为空；`_load_chapter_plan(2)` 返回 null；
  `tests/test_ch2_world.gd` 的 `ch2_game_ch3_has_no_plan_yet` 锁住此状态，新建计划时须同步更新。
- **没有第 3 章大区目录/资源**：`resources/rooms/ch3_bigmap/`、`scenes/mds/ch3_bigmap/` 均不存在。
- **没有事件数据**：`_event_data()` 对第 3 章返回 `{}`（无 `Ch3EventData`）；旧世界也没有 event 房。
- **没有权柄池**：`_grant_chapter_authority()` 在 `_chapter_plan == null` 时直接返回，
  第 3 章 Boss 击败后不会开权柄三选一。
- **Boss 路由**：`_spawn_boss` 优先级 = 章节 `boss_scene` → 计划 `boss_scene` →
  `boss_script == "smiling"` → `boss_script == "reader"` → 默认；第 3 章靠最后第二档路由到
  `READER_SCENE`（探针确认脚本为 `last_reader.gd`）。
- **Boss 入场/阶段文案**：`BossEntranceData.variants(2)` = `[]` → `pick()` 返回空串；
  `BossPhaseData.variants(2/3, 2)` = `[]` → `pick()` 返回空串；入场静默、阶段横幅只有机械前缀，
  不会回落到第 1 章文案。
- **章节推进**：`_complete_chapter()` 只在 `_chapter == 0/1` 停章；第 3 章（`_chapter == 2`）
  仍会自动续章进入第 4 章。
- **地图标题**：第 38 程已按区域派生，第 3 章显示「无光海地图」（探针确认）。
- **清房目标/坠落平面**：无计划 → 清房目标 6、HUD 分母 7、坠落平面 850（探针确认）。

**叙事【已核实】**

- 剧情圣经第 3 章节拍：「最后的读者是一个孩子」「故事需要有人翻页」等目前**只有文本**；
  没有对应事件房、对话节点或剧情实体。Boss 立绘是持书的孩子，但 `CampaignData` 台词只称
  「最后的读者」，没有把「孩子」写成台词。
- **没有 NPC 同行实体**：仓库没有 companion/follower 控制器；阿砚只在第 2 章文本与 Hub 出现。
  MDS 自带 `carry_over` 组但项目未使用。第 3 章也没有同行角色实体。

### B. 承载力结论（只写第 3 章差异点）

1. **房间管线可直接用【已核实】**：`MDSBigRoom`/`BigRoomData` 无章节判断；第 2 章 9 区真实世界已验证。
   第 3 章只需新增 `ch3_bigmap` 数据/场景/世界，旧世界原地保留、不再引用。
2. **解耦同样适用【已核实】**：按 `region/Node` 的一次性结算、按区域坠落平面、计划派生清房目标、
   按遭遇节点 id 的波次，都是章节无关代码。
3. **背景/氛围差异【已核实】**：第 3 章海面母题由 `LivingBackdrop(sea=true)` 提供（海面线、波光、
   漂浮纸屑、塔影、地面暗带）；大区管线只有平铺静态背景（`lightless_sea.png` 可平铺）与
   `BigRoomAmbient` 的 `motes`/`embers`，**没有 sea 层**。第 2 章大图也丢掉了自己的
   `LivingBackdrop`，但第 3 章海面是主题核心，损失更明显；是否补层属表现口径，
   本程只记录、不设计。实际观感与平铺接缝**【待施工验证】**。
4. **「视野压缩」没有实现【已核实】**：仓库没有视野遮罩/光照半径/黑暗度玩法脚本，
   第 3 章 `room_darkness=false`；`ChapterAtmosphere` 里只有 Boss 动态背景的 `vignette`
   美术参数，不是视野机制。GDD §11 把它列为无光海机制，但大区管线不会自动带来它；
   这是第 3 章独有的新机制缺口，需先拍板再排期。
5. **没有水域物理【已核实】**：没有游泳/溺水/水面碰撞/水体制动脚本；「无光海」目前是背景与叙事。
   按既定口径不新增移动能力，因此不需要水域机制，但也没有可复用水面脚本。
   **【推断】** 大图若做「海面/深水」分层，只能靠背景、平台与门，不靠新物理。
6. **纵向结构是新增内容而非新管线【已核实】**：现有 9 房全部单层；大区高差预算与第 2 章相同
   （≤80 px 台阶、≤120 px 水平边缘），top/bot 门、单向落台、塌陷平台、移动平台都可用。
   第 3 章 GDD 没有「上下分层/塌陷平台」条目，纵向与否属关卡设计选择，不是能力限制。
7. **Boss 3 已有实现但没接计划【已核实】**：`LastReader`、场景、立绘、`deep_water` 背景、
   reader 阶段语音、镜面弹/读页攻击都已存在；缺计划 `boss_scene` 路由、入场/阶段文案与测试锁定。
   相对第 2 章施工前（完全无独特机制），第 3 章 Boss 机制工作量更小，但需与第 2 章
   「计划 `boss_scene`」口径统一。
8. **捷径语义不同【已核实】**：现有 `ch3_rest` 的 `door2` 是无条件交互门直达 `ch3_02`；
   第 2 章大图 `shortcuts` 用 `MDSGateBarrier` + ability（`ch2_shortcut`）。第 3 章没有
   `ch3_shortcut` 授予来源；若大图计划写 `shortcuts`，需先定来源（与待确认第 11 项同类）。
9. **章末边界要再做一次【已核实】**：第 3 章现在会自动进第 4 章；大图落地后若第 4 章仍未完成，
   需像第 2 章那样 `_finish(true)` 停章，否则会进入未完成的第 4 章。
10. **敌人美术无新增缺口【已核实】**：3 种回退敌人都在第 38 程缺失清单内；其余 6 种有既有精灵。
11. **背景是绘画而非像素【已核实】**：`lightless_sea.png` 1536×864 RGB，与第 2 章
    `breathing_ruins.png` 同一已知缺口；大区平铺接缝**【待施工验证】**。
12. **入口出生点要作者化【已核实】**：`MDSChapterRoom` 只在 `room_index` 0/1 生成 `SavePoint`；
    大图入口若沿用房间标签锚点会空中坠落（第 37 程已修过第 2 章）。第 3 章大图入口必须作者
    `SpawnPoint`（`save_point` 组，脚底 = 地面 − `FOOT_Y`）。
13. **战斗房宝箱【已核实】**：`ch3_03`/`ch3_05` 已有宝箱，书库另有 1 个；计划 `chests` 支持按节点
    id 多宝箱，无管线缺口，但计划必须为这三个箱子写节点 id。
14. **性能【推断】**：第 3 章大区尺寸/内容尚未落地，无法实测；第 2 章验收基线为普通区热加载
    5.6–9.2 ms、Boss 区冷启 61 ms、热 10.2–43 ms，由 0.22 s 淡入覆盖。第 3 章若做更大的
    海面区，需按第 36 程同一口径实测。**【待施工验证】**

### C. 施工顺序建议与前置依赖

1. **计划/图骨架**：新建 `chapter_3_demo.tres`（`big_map`、`start_room`、`doors`、region 键：
   尺寸/遭遇/宝箱/残碑/捷径/隐藏/坠落平面/波次/权柄池/`boss_scene`），写图骨架夹具，
   接入 `CHAPTER_PLAN_PATHS[2]`，同步改 `tests/test_ch2_world.gd` 的
   `ch2_game_ch3_has_no_plan_yet` 锁。
   **前置**：第 3 章区图/节拍设计（区数、入口→支路→枢纽→纵向→事件/精英→Boss + 隐藏书库）；
   「视野压缩」是否实现；捷径授予来源。
2. **真实大区世界**：新建 `resources/rooms/ch3_bigmap/*.tres`、`scenes/mds/ch3_bigmap/*.tscn`、
   独立 `chapter_3_bigmap.mdsworld.json` + `_world.tscn`；区域补
   `backdrop_image=lightless_sea.png`，沿用雾/雨与 `boss_background=deep_water`；入口作者
   `SpawnPoint`；门由世界 JSON 自动生成并自动挂 `GateVisual`；纵向按需用既有单向落台/
   塌陷平台/移动平台/长椅；旧第 3 章世界保留。
   **前置**：步骤 1；海面母题呈现口径。
3. **内容数据层**：`Ch3EventData`（按 seed + 节点 id）、计划 `wave`（遭遇节点 id → 敌人数组，
   可复用 `ROOM_WAVES[2]` 原文）、计划 `authority_pool`（续命/改写 + 条件项）、
   `BossEntranceData`/`BossPhaseData` 第 3 章文案、计划 `boss_scene` 指向 `last_reader.tscn`。
   **前置**：步骤 1–2；事件文案/权柄池内容口径。
4. **Boss 3 机制**：复用现有 `LastReader` 的镜面弹/读页；按计划 `boss_scene` 接线；
   补测试锁定阶段映射与攻击；是否扩展新招式另行决定（本程不设计）。
   **前置**：步骤 3（路由与文案）。
5. **系统验收**：新增 `tests/integration_ch3_bigmap.gd`，按第 36 程 D 节 1–10 项覆盖
   连通/边界相机/纵向/过渡/一次性/多遭遇/捷径/隐藏/Boss/续玩，并补第 3 章专属断言
   （海面背景/天气、`deep_water` Boss 背景、`LastReader` 脚本/立绘、地图标题、章末停章）；
   先保持第 3 章不可达，全绿后再由监工单独拍板可达性。
   **前置**：步骤 1–4。

### D. 风险/边界

- 不改 MDS 本体、不改存档格式、不改言灵/权柄/战斗框架；不新增移动能力。
- 第 3 章施工前不开放第 3 章可达性；第 3 章可达性也不能早于第 2 章。
- 海面母题、视野压缩、捷径授予来源、章末停章是第 3 章施工前需要定口径的四项；
  本程只记录事实与依赖，未设计新机制、未改任何数值/相机/HUD。

## 第 3 章计划与图骨架（第 40 程，只做数据层）

> 范围：第 39 程核查 C 节第 1 步。只新建计划资源、图骨架夹具与交叉校验测试；
> 不建真实大区世界/房间，不接入 `game.gd`，不改第 3 章可达性，不写波次/事件/
> 权柄/Boss 内容。详细版见
> [第 3 章计划/图骨架 session](docs/memory/sessions/2026-11-05-chapter3-plan-graph.md)
> 与 [ADR](docs/memory/decisions/2026-11-05-chapter3-plan-graph.md)。

- **计划** `resources/chapters/chapter_3_demo.tres`：9 区连通图，与第 2 章同构——
  `ch3_entry`（入口）→ `ch3_branch_a` / `ch3_branch_b`（两条可回环支路）→
  `ch3_hub`（休整 + 商店 + 残碑 + 捷径解锁）→ `ch3_well`（纵井，2560×2160）→
  `ch3_event` 占位 / `ch3_elite` → `ch3_boss`（3840×2160，末端单向进入）；
  `ch3_vault` 是支路 B 下的隐藏书库。其余区 2560×1440，精英/Boss 3840×2160。
- **内容节点**：6 个战斗遭遇（支路 A 2、支路 B 1、纵井 2、精英 1）对应旧第 3 章
  6 波（本程不写 `wave`）；事件区 1 个占位遭遇。`clear_target()` 按遭遇节点派生
  **7**（第 1 章仍 6、第 2 章仍 7，未改动）。3 个宝箱、2 个残碑，全部
  `region/Node` 节点 id。
- **门**：11 条记录 = 9 双向 + 2 显式单向——`elite_boss`（进 Boss 不可返回）与
  `hub_shortcut_entry`（捷径，`requires: ["ch3_shortcut"]`，来源待第 16 项拍板，
  默认不可通行）。图内两个回环，Boss 为末端。每区 `fall_below_bounds = 240`。
- **`ChapterPlanData.content_pending`**（新增，默认 `false`，向后兼容）：
  计划结构先于内容落地时置 `true`，`validate()` 仍校验区域/节点 id/门图，只跳过
  波次表。第 1/2 章计划保持 `false`，校验结果不变；测试把第 3 章计划的标志临时
  关掉，确认仍报六条缺波次，证明跳过范围是局部的。
- **图骨架夹具** `tests/fixtures/big_room/ch3_graph.mdsworld.json`：
  `fixture: true`、`content_pending: true`、无 `scene_path`/房间场景、游戏从不引用；
  镜像旧世界区域 `Lightless Sea` 的雾/雨与 `boss_background=deep_water`，不写
  `backdrop_image`。20 扇有向门 + 2 扇到达门。
- **测试** `tests/test_ch3_plan.gd`（728 断言）：计划形状/类型/尺寸/坠落平面/
  内容 id/清房目标/图可达性/单向门/捷径占位/待内容标记 + 计划↔夹具逐区逐门交叉
  校验 + 夹具几何 + 第 1/2 章计划不变 + `game.gd` 路由槽仍为空 + 第 3 章旧世界文件仍在。
- **边界**：计划未接入 `game.gd`（`CHAPTER_PLAN_PATHS[2]` 仍空，既有测试锁定）；
  旧 `chapter_3.mdsworld.json` / `chapter_3_world.tscn` 与 9 个 `MDSChapterRoom`
  场景未改未删、仍被游戏使用；第 3 章仍不可达，章末仍会自动进第 4 章。
  第 14（视野压缩）、15（海面母题）、16（`ch3_shortcut` 来源）项全部留空，
  本程未实现、未预设、未猜测。

## 第 3 章真实大区世界（第 41 程，只做结构层）

> 范围：第 39 程核查 C 节第 2 步。把第 40 程的 9 区计划做成可加载的真实大区
> 世界与房间场景，只做结构层；不接入 `game.gd`、不改第 3 章可达性、不写波次/
> 事件/权柄/Boss 内容、不做第 3 章门视觉打磨。详细版见
> [第 3 章真实大区世界 session](docs/memory/sessions/2026-11-05-chapter3-bigmap-world.md)。

- **大区数据** `resources/rooms/ch3_bigmap/*.tres`：9 个 `BigRoomData`，尺寸按计划
  2560×1440 / 2560×2160（纵井）/ 3840×2160（精英、Boss）；地面贴房间底边
  （`H-16`，16 px 厚），平台按 80 px 阶梯链布置并通过第 28 程几何校验
  （上升 ≤80 px、水平边缘 ≤120 px）；复用 `ch1_tiles.tres`；
  `backdrop_path = lightless_sea.png`（既有绘画背景，`backdrop_pixel_art = false`），
  按区 `backdrop_modulate` 与 `motes` 氛围（密度 0.5）。
- **大区场景** `scenes/mds/ch3_bigmap/*.tscn`：9 个 `MDSBigRoom`，`fall_margin = 240`
  （房间 metadata `fall_below_bounds = 240`，与计划一致）；内容节点严格用计划 id：
  `ch3_branch_a` 的 `Arena`/`Arena2`/`Chest1`、`ch3_branch_b` 的 `Arena`、
  `ch3_well` 的 `Arena`/`Arena2`/`Chest1`、`ch3_elite` 的 `Arena`、
  `ch3_hub` 的 `Stele1`/`Shop`(`ch3_hub_shop`)/`Bench`、
  `ch3_vault` 的 `Chest1`/`Stele1`；事件区节点名 `Event`，作者
  `encounter_id = ch3_event/event`；Boss 区只放结构 `Arena`（Boss 内容后续程）。
- **入口出生点**：`ch3_entry` 作者 `SpawnPoint`（`save_point` 组，(400,1328) =
  第一级台阶面 1344 − `FOOT_Y` 16），沿用第 37 程第 2 章口径；不改 MDS 出生
  回退顺序、不改第 1/2 章出生点。
- **纵向/捷径骨架**（复用第 29 程管线，未新增移动能力）：`ch3_branch_b`/`ch3_hub`/
  `ch3_vault` 各 1 台电梯（地面 → y=100，覆盖顶门列且避开平台），`ch3_well`
  1 台电梯 + 3 个单向落台，`ch3_elite` 1 台电梯（到达门 y=1920 下方），枢纽
  `Bench` 长椅检查点与带 `requires` 的捷径门自动生成 `MDSGateBarrier`。
  电梯未写 `speed`，沿用 `MovingPlatform.speed` 管线默认 **80 px/s**
  （`scripts/levels/moving_platform.gd`）；第 12 项口径只针对第 2 章，本程未给
  第 3 章定速度。
- **独立世界** `scenes/mds/chapter_3_bigmap.mdsworld.json` + `chapter_3_bigmap_world.tscn`：
  9 区单矩形、原点 32 px 对齐；`start_room = ch3_entry`；区域 `Lightless Sea`
  带雾 + 雨与 `boss_background: deep_water`，不写 `backdrop_image`（第 15 项留空）；
  22 门 = 20 有向 + 2 只到达（`ch3_entry/shortcut_arrival`、`ch3_boss/left1`）；
  显式单向 `elite_boss` 与 `hub_shortcut_entry`（`requires = ["ch3_shortcut"]`，
  来源待第 16 项，屏障默认封闭）；侧门在地面上方 90 px、底门在地面线、顶门在
  上边缘；房间不重叠、双向门相邻、捷径刻意不相邻。世界 JSON 由第 40 程夹具
  镜像生成（逐区字段一致，仅加 `scene_path`），夹具未改语义。
- **测试** `tests/test_ch3_world.gd`（**771** 断言）：真实世界 ↔ 计划逐区
  类型/尺寸/遭遇/宝箱/残碑/捷径/隐藏/商店/休整/纵井；11 条计划门 ↔ 世界门位、
  双向/单向/`requires`；世界图从入口 BFS 到全部 9 区；几何（单矩形、原点 32 网格、
  门在正确边、房间不重叠、双向门相邻、捷径不相邻）；9 场景为 `MDSBigRoom`、
  `BigRoomData` 校验为空、尺寸/瓦片/背景/氛围/坠落余量/底边地面；内容节点与
  计划 id 一一对应且数量不许多、事件区作者遭遇 id、枢纽商店/长椅、入口出生点与
  到达门；顶门房间电梯覆盖门列、行程向上、列内无平台、速度 = 管线默认 80；
  夹具镜像与隔离；`CHAPTER_PLAN_PATHS[2]` 仍空、旧第 3 章 9 房/17 门/世界场景仍在、
  第 1/2 章计划与世界不变、第 3 章场景无作者 `GateVisual`、世界 `room_darkness=false`。
- **边界**：`game.gd` 未改，第 3 章仍走旧 `chapter_3.mdsworld.json` / 9 个
  `MDSChapterRoom`，`CHAPTER_PLAN_PATHS[2]` 仍空；第 3 章仍不可达、章末仍会自动
  进第 4 章。第 14（视野压缩）、15（海面母题）、16（`ch3_shortcut` 来源）项
  全部留空：未实现视野压缩、未给大区加 sea 层、未改 `LivingBackdrop`、未新绘背景、
  未新增任何授予 `ch3_shortcut` 的交互；门视觉未做第 3 章专项打磨（管线运行时
  共享的 `GateVisual` 自动生成未改，属既有管线行为）。

## 第 4 章大地图可行性核查（第 50 程，只查不施工）

> 范围：回答「第 2 章走通、第 3 章已验证的大区连通图路线能否直接承载第 4 章、
> 缺口在哪、施工顺序怎么排」。本程未改第 4 章可达性，未新建计划/大区/房间/事件/
> 权柄/Boss 内容，未改 `game.gd` 章节路由；未新增测试与产品代码，未创建临时探针。
> 详细版见 [第 4 章核查 session](docs/memory/sessions/2026-11-05-chapter4-bigmap-audit.md)。
> 标记：**【已核实】** 读代码/资源或既有测试可复现；**【推断】** 由已核实事实推导、
> 尚未实跑；**【待施工验证】** 必须等真实大图内容落地后才能定论。

### 结论摘要

- **可行性：可以直接承载，不需要改 MDS、存档、战斗或房间管线。** `BigRoomData` +
  `MDSBigRoom` 不含任何章节判断；第 27 程的按节点 id 结算、按区域坠落平面、计划派生
  清房目标、按遭遇节点 id 的波次都是章节无关的。第 4 章现有旧世界可以像第 2/3 章
  旧世界一样原地保留、不再引用。**【已核实】**
- **缺口集中在内容层**：第 4 章没有计划（`chapter_4_demo.tres` 不存在、
  `CHAPTER_PLAN_PATHS[3]` 为空）、没有大区/房间数据、没有事件数据、没有权柄池、
  Boss 入场/阶段文案静默、Boss 4 无专章机制打磨与测试、没有第 4 章大图验收套件；
  与第 2/3 章施工前的缺口同类。**【已核实】**
- **第 4 章独有差异**：① 舞台母题目前只由 `MDSChapterRoom` 的 `TheaterBackdrop`
  （聚光灯/光斑/浮尘）提供，大区管线只有平铺绘画 + `BigRoomAmbient`；② Boss 4
  「笑面史官」已有专属脚本/场景/立绘/语音与部分独特攻击（镜面弹幕），但没有专章机制
  打磨、没有入场/阶段文案、没有测试锁定，剧情圣经的三阶段「改写规则/删除词/复制武器」
  与 GDD 的「舞台机关」大多未实现；③ 捷径 `door2` 是无条件单向交互门，大图
  `shortcuts` 需要 ability id 与授予来源；④ 章末边界本身就是战役终点（已是
  `_finish(true)`，无需再改），但第 3 章的停章替身必须先解开；⑤ 入口出生点必须作者
  `SpawnPoint`。**【已核实】**
- **美术更正（用户 2026-11-04 事实）**：第 4 章美术素材已经画好并已接线——舞台绘画、
  Boss 立绘、8 种实际使用的敌人精灵（含 `mask_enemy`/`seat_husk` 两个第 4 章美术变体）、
  配乐、开场/章末/Boss 阶段语音全部存在；**没有缺失的第 4 章专属敌人美术，也没有
  回退第 1 章美术的敌人**。README/GDD 的旧「程序化绘制、待替换插画」记录已在第 7 程
  更正，本次复核与当前文档一致。**【已核实】**
- **施工顺序**沿用第 2/3 章：计划/图骨架 → 真实大区世界 → 内容数据层 → Boss 机制 →
  系统验收；前置依赖见下。第 4 章可达性仍须单独拍板，且不能早于第 2/3 章。

### A. 第 4 章现有内容盘点

**MDS 世界与房间【已核实，既有集成实走】**

- `scenes/mds/chapter_4_world.tscn` + `chapter_4.mdsworld.json`：9 房、**17 门**
  （7 right / 7 left / 3 door）、`links`/`pins` 为空、`start_room = ch4_01`。
- 全部 **1280×720 单矩形、单层地面**（地面面 y=560，StaticBody 80 px），平台按
  `platform_pattern` 0/1/2 建 2/2/1 块；没有多矩形、多层或纵向结构。
- 场景全部 `MDSChapterRoom`（`chapter_index = 3`）；世界设置
  `room_darkness=false`、`room_weather=true`、`room_parallax=false`、
  `room_background=true`、`fade_time=0.22`、`gate_cooldown=0.35`、`keep_momentum=true`。
- 区域 `Smiling Theater`：灰烬 + 光柱天气；`background` 为空、无 `backdrop_image`；
  Boss 房 `boss_background=blood_moon`。背景由 `MDSChapterRoom` 的
  `BACKGROUNDS[3] = smiling_theater.png` 提供（见 B 节）。
- 房型/内容：

| 房间 | 名称 | 类型 | 内容 | 门 |
|---|---|---|---|---|
| `ch4_01` | 剧场前厅 | 战斗 | 无 | right1 |
| `ch4_02` | 笑面回廊 | 战斗 | 无 | left1/right1 |
| `ch4_03` | 血幕书库 | 战斗 | 宝箱×1、书库门 | left1/right1/door1 |
| `ch4_04` | 空座中庭 | 战斗 | 无 | left1/right1 |
| `ch4_05` | 舞台侧廊 | 战斗 | 宝箱×1 | left1/right1 |
| `ch4_06` | 第四页之幕 | 战斗 | 无 | left1/right1 |
| `ch4_rest` | 熄灯的后台 | 休整 | 商店、残碑、捷径门 door2→`ch4_02` | left1/right1/door2 |
| `ch4_boss` | 笑面剧场 | Boss | Arena/Boss | left1 |
| `ch4_vault` | 隐藏书库 | 书库（`kind=REST`） | 宝箱、残碑、返回门 door1→`ch4_03` | door1 |

- 宝箱 3（`ch4_03`、`ch4_05`、`ch4_vault`）、残碑 2（`ch4_rest`、`ch4_vault`）、
  商店 1（`ch4_rest`，id `ch4_rest_shop`），与第 3 章旧世界同构。
- 捷径 `ch4_rest/door2` 是**单向**交互门（直达 `ch4_02`，目标房没有回门）；
  `ch4_boss/left1` 可返回 `ch4_rest`（与第 2/3 章大图 Boss 单向门不同）。
- 旧线性结构已被 `integration_playability` 的逐章循环实走（6 战斗房 + 书库 + 休整 +
  Boss + 章末），并最终到达战役结局；但没有第 4 章大图结构覆盖。

**主线文本与语音【已核实】**

- `CampaignData` 第 4 章：**8 句开场、4 句章末、2 个章末选项**；目标「穿过空座，走上
  舞台，结束这场演出」；区域「笑面剧场」；音乐 `chapter_theater.ogg` 存在；
  `ch4_intro.ogg`/`ch4_outro.ogg`、`boss_smiling_phase2/3.ogg` 均存在。
- 章末效果已实现：重写名册 → 仁慈 +1；焚毁名册 → 污染 +12，并置
  `_burned_final = true`（影响最终结局）。
- 叙事审计表里「第 4 章 7 句开场」是旧记录；实际是 **8 句**（第 1/2/3 章分别为
  6/7/7 句），本程按代码重新计数。

**Boss 4「笑面史官」【已核实】**

- `CampaignData`：HP **520**、伤害 **18**、速度 **92**、`boss_script=&"smiling"`、
  立绘 `smiling_archivist.png`（256×256 RGBA）、`boss_scale=1.0`、白 tint、
  `boss_voice="smiling"`；**没有** `boss_scene` 键。
- 专属脚本/场景：`SmilingArchivist extends InkArchivist` +
  `scenes/bosses/smiling_archivist.tscn` 存在；`_spawn_boss` 无 `boss_scene`/计划路由时
  按 `boss_script == "smiling"` 选中它。
- 已有独特攻击：**镜面弹幕**（3 枚 ×0.7 攻击力、速度 280、张角 ±0.34 rad）；
  阶段 1 纸页波；阶段 2 每第 3 次镜面弹幕、其余纸页波；阶段 3 改写/镜面/墨雨/纸页波
  轮换。基类 `_page_wave`（阶段 ≥2 双发）、`_ink_rain`、`_rewrite`（临时封印短语槽）
  都继承。
- 缺口：剧情圣经第 4 章节拍说「三阶段：改写规则、删除词、复制昌子的武器」，
  GDD §11 说「规则改写、舞台机关」；当前没有删除词、没有复制玩家武器、没有舞台机关，
  `_rewrite` 只是临时封印短语槽。Boss 4 也没有 `test_ch4_boss` 专项测试，
  集成遍历只把它击杀、未断言类型/机制。

**敌人与波次【已核实】**

- `ROOM_WAVES[3]` **已配置 6 波**；`CampaignData.rooms[3]` 的 6 组首发敌人也都存在。
- 第 4 章实际用到 **8 种 spawn id**：`mask_enemy`、`seat_husk`、`echo_enemy`、
  `choir_summoner`、`typo_beast`、`mirror_sniper`、`ink_bomber`、`page_swarm`。
- 美术接线（第 38/49 程同一口径）：**8 种全部有专属精灵、全部在 `ENEMY_ART`、
  全部白 tint，`ENEMY_ART_FALLBACK` 命中 0 项**——第 4 章与第 1 章一样是零回退章节；
  第 2/3 章缺图的 `rust_whisperer`/`lung_moth`/`collapse_husk` 不在第 4 章波次里。
- 两个第 4 章美术变体：`mask_enemy` 复用 `hanging_scribe.tscn`（数据 id
  `hanging_scribe`，flyer 动画），`seat_husk` 复用 `collapse_husk.tscn`
  （数据 id `collapse_husk`，elite 动画）；只有精灵是第 4 章专属，数值/行为沿用
  第 1 章敌人。美术按 spawn id 解析，实际渲染正确。
- `echo_enemy` 数据资源 id 是 `amnesiac_echo`，美术按 spawn id 接线（沿用第 49 程）。

**章节计划与内容数据【已核实】**

- **`chapter_4_demo.tres` 不存在**；`CHAPTER_PLAN_PATHS[3]` 为空；
  `_load_chapter_plan(3)` 返回 null；`resources/rooms/ch4_bigmap/`、
  `scenes/mds/ch4_bigmap/` 均不存在。
- **没有事件数据**：`_event_data()` 对第 4 章返回 `{}`（无 `Ch4EventData`）；
  旧世界也没有 event 房。
- **没有权柄池**：`_grant_chapter_authority()` 在 `_chapter_plan == null` 时直接返回，
  第 4 章 Boss 击败后不会开权柄三选一。
- **Boss 路由**：`_spawn_boss` 优先级 = 章节 `boss_scene` → 计划 `boss_scene` →
  `boss_script == "smiling"` → `boss_script == "reader"` → 默认；第 4 章靠
  `smiling` 档路由到既有场景。
- **Boss 入场/阶段文案**：`BossEntranceData.variants(3)` 与
  `BossPhaseData.variants(2/3, 3)` 均为 `[]` → 空串；入场静默、阶段横幅只有机械前缀，
  不会回落到第 1 章文案（第 2/3 章测试锁定此状态）。
- **章节推进**：`_complete_chapter()` 没有第 4 章专属分支；第 4 章是最后一章，
  章末选择后走 `_finish(true)` 结束战役（既有集成 `campaign_reaches_ending` 已覆盖）。
  第 3 章的停章替身（`_chapter == 2` → `_finish(true)`）是第 4 章可达性的前置。
- **地图标题**：第 38 程派生规则下第 4 章显示「笑面剧场地图」（`test_map_overlay`
  明确断言，集成也复跑）。
- **清房目标/坠落平面**：无计划 → 清房目标 6、HUD 分母 7、坠落平面 850
  （集成 `chapter_4_fall_plane_default` / `chapter_4_clear_target_default` 已断言）。

**叙事【已核实】**

- 剧情圣经第 4 章节拍：① 剧场坐满纸人；② 笑面史官逐一念出同行者名字；
  ③ 舞台机关、纸人观众、镜面狙手与合唱召引者轮番登场；④ 揭示他是未来的昌子、
  所有失败版本的集合；⑤ 三阶段改写规则/删除词/复制武器；⑥ 重写或焚毁名册。
- 现状：① 只在开场文本；② 开场文本点名陆沉/阿砚/闻烬/白榆（未提咕噜，也没有
  「所有版本」的展开）；③ 镜面狙手/合唱召引者作为敌人存在，纸人观众与舞台机关
  没有实体；④ 「未来的昌子」**没有写进任何已实现台词**，只在剧情圣经里；
  ⑤ 机制见 Boss 4 节；⑥ 已实现。
- **没有 NPC 同行实体**：仓库没有 companion/follower 控制器；阿砚只在第 2 章文本
  与 Hub 出现，MDS 自带 `carry_over` 组但项目未使用；第 4 章也没有同行角色实体。

### B. 第 4 章美术素材核查（用户 2026-11-04 事实更正的遗留项）

- **舞台/背景**：`assets/backgrounds/smiling_theater.png`（1536×864 **RGB 绘画**，
  非像素；概念源 `assets/concept/environments/smiling_theater_source.png` 1983×793）。
  已接入 `MDSChapterRoom` 的 `BACKGROUNDS[3]` → `BackgroundArt` +
  `TheaterBackdrop(generated_art=true)`，后者只叠加聚光灯锥/地面光斑/浮尘；
  旧线性 `scenes/levels/smiling_theater.tscn` 仍引用但已休眠。
- **Boss**：`assets/sprites/bosses/smiling_archivist.png`（256×256 RGBA；alpha
  0/255、四角透明、最低不透明行=底行、无压缩/无 mipmap）由
  `CampaignData.boss_texture` → `_spawn_boss` → `_apply_art` 接线；概念源
  `smiling_archivist_pixel.png`/`smiling_archivist_sprite_source.png` 仅参考。
- **敌人**：第 4 章实际使用的 8 种全部有专属 PNG（`mask_enemy.png`/`seat_husk.png`
  96×96 RGBA，alpha 0/255、四角透明、底行对齐、无压缩/无 mipmap；其余 6 种复用
  第 1/2/3 章已接线精灵），全部白 tint、**无回退**。`mask_enemy`/`seat_husk` 是
  「美术变体 spawn id」：场景/数据复用 `hanging_scribe`/`collapse_husk`，只有精灵
  专属。
- **道具/瓦片**：宝箱/残碑/商店/门使用第 1 章共享像素道具；地面/平台用
  `resources/tiles/ch1_tiles.tres`，与第 2/3 章大图一致；`assets/tiles/` 只有 ch1，
  第 4 章没有专属 tileset，属既定路线而非缺美术。
- **音频**：`chapter_theater.ogg`、`ch4_intro.ogg`、`ch4_outro.ogg`、
  `boss_smiling_phase2/3.ogg` 均存在并已接线。
- **程序化/生成部分**：舞台不再依赖程序化帷幕/观众席（`generated_art=true` 分支
  跳过）；Boss 房背景是 MDS `blood_moon` 动态背景（与第 1–3 章 Boss 背景同类，
  不是待替换占位）；地面/平台由 ch1 瓦片生成，是大图管线做法。
- **调色观察**：`mask_enemy`/`seat_husk` 各 25 色、Boss 45 色；与第 2/3 章同批素材
  一致（普通敌人多为 24–25 色、Boss 45 色），属既有规范偏差（art-spec 普通敌人 24 /
  Boss 40），不是第 4 章独有缺口；本程不改图。
- **结论**：用户「第 4 章美术已经画好」与仓库一致；**没有发现缺失或未接线的第 4 章
  美术素材**，没有需要按旧记录重新规划的项目。README/GDD 当前表述已在第 7 程更正，
  本次复核再次确认；NPC 立绘只读未改。

### C. 承载力结论（只写第 4 章差异点）

1. **房间管线可直接用【已核实】**：`MDSBigRoom`/`BigRoomData` 无章节判断；第 2/3 章
   9 区真实世界已验证。第 4 章只需新增 `ch4_bigmap` 数据/场景/世界，旧世界原地保留。
2. **解耦同样适用【已核实】**：按 `region/Node` 一次性结算、按区域坠落平面、计划派生
   清房目标、按遭遇节点 id 的波次，都是章节无关代码。
3. **舞台母题差异【已核实】**：第 4 章舞台由 `TheaterBackdrop` 的聚光灯/光斑/浮尘 +
   绘画提供；大区管线只有平铺静态背景（`BigRoomData.backdrop_path`）与
   `BigRoomAmbient` 的 `motes`/`embers`，**没有 theater 层**。区域天气（灰烬 + 光柱）
   仍由 MDS 按区域生效，可补一部分氛围；聚光灯/吊灯/观众席的舞台感会丢。是否补
   theater ambient 层属表现口径，需拍板；实际观感与平铺接缝**【待施工验证】**。
4. **背景是绘画而非像素【已核实】**：`smiling_theater.png` 1536×864 RGB；第 2/3 章
   大图已经用绘画平铺（`backdrop_pixel_art=false`、线性过滤），第 4 章可照做。
   平铺接缝（1536×864 贴图铺 2560×1440 等区）**【待施工验证】**。
5. **Boss 4 已有实现但没接计划【已核实】**：`SmilingArchivist`、场景、立绘、Boss 语音、
   镜面弹幕/纸页波/墨雨/改写均已存在；缺计划 `boss_scene` 路由、入场/阶段文案、
   专章机制打磨与测试锁定。
6. **捷径语义不同【已核实】**：现有 `ch4_rest/door2` 是无条件单向交互门直达
   `ch4_02`；第 2/3 章大图 `shortcuts` 用 `MDSGateBarrier` + ability。第 4 章没有
   `ch4_shortcut` 授予来源；若大图计划写 `shortcuts`，需先定来源（与第 11/16 项同类）。
7. **章末边界不用再改【已核实】**：第 4 章是最后一章，`_complete_chapter()` 已走
   `_finish(true)`，不会越界到第 5 章。但第 4 章可达性要求先解开第 3 章停章替身
   （`_chapter == 2` → `_finish(true)`）并接入第 3 章计划；属可达性拍板后的工作。
8. **入口出生点要作者化【已核实】**：`MDSChapterRoom` 只在 `room_index` 0/1 生成
   `SavePoint`；大图入口若沿用房间标签锚点会空中坠落（第 37 程已修过第 2 章）。
   第 4 章大图入口必须作者 `SpawnPoint`（`save_point` 组，脚底 = 地面 − `FOOT_Y`）。
9. **清房目标/坠落平面【已核实】**：旧世界无计划 → 目标 6、HUD 分母 7、坠落 850；
   大图计划按遭遇节点派生目标，并按第 2/3 章口径每区 `fall_below_bounds = 240`。
10. **事件区是可选项【已核实】**：旧第 4 章没有事件房，`_event_data()` 对第 4 章
    返回 `{}`。若大图加事件区，需要 `Ch4EventData` + 读/拿效果，并把清房目标从 6
    提到 7；若不加，目标保持 6。属内容口径。
11. **权柄池缺口【已核实】**：无计划 → Boss 4 击败后没有权柄三选一；大图计划补
    `authority_pool = [续命, 改写]`（条件项仍走 `ContentLibrary` 的吞噬/归档）即可
    与第 2/3 章一致。
12. **敌人美术无缺口【已核实】**：第 4 章 8 种敌人全部有专属精灵、无回退；
    `mask_enemy`/`seat_husk` 是美术变体、数值/场景沿用第 1 章敌人，是否需要独立数值
    属内容口径。
13. **战斗密度口径【已核实】**：旧第 4 章每战斗房是「首发 3–4 + 波次 2」共 5–6 只；
    第 2/3 章大图每个战斗遭遇只用 `ROOM_WAVES` 的 2 只。若第 4 章照大图口径，
    战斗密度会下降；若要维持旧密度需扩波或增遭遇。属内容选择。
14. **性能【推断】**：第 4 章大区尺寸/内容尚未落地，无法实测；第 2/3 章验收基线为
    普通区首次 6.0–9.2 ms、热 6.1–7.7 ms，Boss 冷 41 ms / 热 24 ms，门过渡
    228–234 ms。第 4 章若沿用 2560×1440/3840×2160 区与绘画平铺，量级应相当；
    `blood_moon` Boss 背景的实际开销需按第 36/48 程同一口径实测。**【待施工验证】**

### D. 施工顺序建议与前置依赖

1. **计划/图骨架**：新建 `chapter_4_demo.tres`（`big_map`、`start_room`、`doors`、
   region 键：尺寸/遭遇/宝箱/残碑/捷径/隐藏/坠落平面/波次/权柄池/`boss_scene`），
   写图骨架夹具，接入 `CHAPTER_PLAN_PATHS[3]`，同步改
   `tests/test_ch2_world.gd`/`test_ch3_content.gd`/`integration_playability` 中
   「第 4 章计划槽为空」的锁。
   **前置**：第 4 章区图/节拍设计；是否加事件区；捷径授予来源；战斗密度口径。
2. **真实大区世界**：新建 `resources/rooms/ch4_bigmap/*.tres`、
   `scenes/mds/ch4_bigmap/*.tscn`、独立 `chapter_4_bigmap.mdsworld.json` +
   `_world.tscn`；每区 `backdrop_path = smiling_theater.png`
   （`backdrop_pixel_art=false`），沿用区域灰烬/光柱与 `boss_background=blood_moon`；
   入口作者 `SpawnPoint`；门由世界 JSON 自动生成并自动挂 `GateVisual`；纵向按需用
   既有单向落台/塌陷平台/移动平台/长椅；旧第 4 章世界保留。
   **前置**：步骤 1；舞台母题呈现口径。
3. **内容数据层**：`Ch4EventData`（若加事件区）、计划 `wave`（遭遇节点 id → 敌人数组，
   可复用 `ROOM_WAVES[3]` 原文）、计划 `authority_pool`（续命/改写 + 条件项）、
   `BossEntranceData`/`BossPhaseData` 第 4 章文案、计划 `boss_scene` 指向
   `smiling_archivist.tscn`；同步把「第 4 章静默」测试期望改为已授权文案。
   **前置**：步骤 1–2；事件文案/权柄池/战斗密度口径。
4. **Boss 4 机制**：复用现有 `SmilingArchivist` 的镜面弹幕/纸页波/墨雨/改写；
   按计划 `boss_scene` 接线；补 `test_ch4_boss` 锁定阶段映射与攻击；是否扩展
   「删除词/复制武器/舞台机关」另行拍板。
   **前置**：步骤 3；机制范围口径。
5. **系统验收**：新增 `tests/integration_ch4_bigmap.gd`，按第 36/48 程同一口径覆盖
   连通/边界相机/纵向/过渡/一次性/多遭遇/捷径/隐藏/Boss/续玩/性能，并补第 4 章
   专属断言（舞台绘画平铺与接缝、`blood_moon` Boss 背景、`SmilingArchivist`
   脚本/立绘、地图标题「笑面剧场地图」、章末结束战役、8 种敌人美术无回退）；
   先保持第 4 章不可达，全绿后再由监工单独拍板可达性。
   **前置**：步骤 1–4。

### E. 开放问题候选（只记录，不编号、不擅自决定）

- **第 4 章舞台母题呈现口径**：大图是否补 `TheaterBackdrop` 的聚光灯/吊灯/浮尘层
  （新 ambient/背景层），还是接受平铺绘画 + 区域灰烬/光柱 + `BigRoomAmbient`。
  与第 3 章的海面母题同类。
- **第 4 章捷径 `ch4_shortcut` 授予来源**：现有 `door2` 无条件；大图 `shortcuts`
  需要 ability id 与游戏内授予来源（Hub NPC/事件/精英/书库）。与第 11/16 项同类。
- **第 4 章是否新增事件区**：旧世界没有 event 房；加则需 `Ch4EventData` 与效果，
  清房目标 6→7；不加则保持 6。
- **Boss 4 机制范围**：剧情圣经的三阶段「改写规则/删除词/复制昌子的武器」与
  GDD 的「舞台机关」对现实现的差距；补多少、怎么补需先拍板。
- **战斗密度**：大图沿用 `ROOM_WAVES[3]` 每遭遇 2 只（第 2/3 章先例），还是扩波/
  增遭遇维持旧第 4 章每房 5–6 只的密度。
- **`mask_enemy`/`seat_husk` 是否要独立数值与行为**：目前只是第 1 章敌人的美术变体
  （共享场景/数据）；若当独立敌人，需要新数据/行为。
- **阿砚同行**：跟随/战斗/对话是新机制，仓库没有 companion/follower 控制器；
  本程只在记录中重申缺失，不实现、不排期（与第 2 章同一状态）。

### F. 本程未做

- 未做第 4 章计划/图骨架/大区世界/内容数据/Boss 机制/验收套件任何施工。
- 未开放第 2/3/4 章可达性；未把任何章节计划接入 `game.gd`，未改章节路由。
- 未改第 11/12/13/14/15/16 项相关数值、相机、HUD、海面母题、视野压缩、捷径授予。
- 未新增移动能力、未改 NPC 立绘、未改 MDS 插件、未新绘/拼凑任何美术。
- 未新增测试与产品代码；未创建临时探针，无残留。

## 第 4 章计划与图骨架（第 51 程，只做数据层）

> 范围：第 4 章大地图施工第 1 步（对应第 50 程核查 D 节第 1 项）。本程只做计划层：
> 新建计划资源、图骨架夹具与交叉校验测试。**不建真实大区世界/房间，不接入
> `game.gd`，不改第 4 章可达性**，不写波次/事件/权柄/Boss 内容。
> 首次尝试（brief53 / session53）因 Magpie 网关中断夭折（日志仅
> `[claude-code:unrecognized_model]`，无提交、无文档、无残留），本程为接力重试。
> 详细版见 [第 4 章计划与图骨架 session](docs/memory/sessions/2026-11-05-chapter4-plan-graph.md)
> 与 [ADR](docs/memory/decisions/2026-11-05-chapter4-plan-graph.md)。

### 结论摘要

- **计划已落地**：`resources/chapters/chapter_4_demo.tres` 为 9 区连通图，
  与第 2/3 章同构——入口 → 两条可回环支路 → 枢纽（休整 + 商店 + 残碑 + 捷径）→
  纵井 → 事件/精英 → Boss，隐藏书库挂在支路下。
- **清房目标 7**：6 个战斗遭遇（支路 A 2、支路 B 1、纵井 2、精英 1）按计划顺序
  对应旧 `ROOM_WAVES[3]` 六波（**本程未接线**）+ 1 个事件占位
  `ch4_event/event`，由 `clear_target()` 按遭遇节点数派生；第 1 章仍 6、第 2/3 章仍 7。
- **门 11 = 9 双向 + 2 单向**：`elite_boss`（进 Boss 不可返回）与
  `hub_shortcut_entry`（枢纽 → 入口捷径，`requires: ["ch4_shortcut"]`，默认封闭、
  授予来源待拍板）。图内两个回环，Boss 为末端。
- **Boss 门取舍**：旧线性世界 `ch4_boss/left1` 可返回 `ch4_rest`；大图计划按
  第 2/3 章先例做显式单向。旧世界原样保留，两种行为分别由测试锁定。
- **坠落平面**：每区 `fall_below_bounds = 240`（区高 + 240，第 27 程口径）。
- **`content_pending = true`**：只推迟 `validate_waves()`；区域字段、节点 id、门图
  照常校验。后续内容程接完六波后按第 43 程约定清零。
- **未写内容**：`wave`、`authority_pool`、`boss_scene`、Boss 入场/阶段文案、
  事件文本/效果、`Ch4EventData`、`ch4_shortcut` 授予来源、敌人独立数值。
- **未路由**：`CHAPTER_PLAN_PATHS[3]` 仍为空；`game.gd` 仍用旧
  `chapter_4.mdsworld.json` / `chapter_4_world.tscn`；第 4 章仍不可达。
  既有「计划槽为空」测试保留，并补「计划资源已存在但未接入」断言。

### A. 计划内容（`resources/chapters/chapter_4_demo.tres`）

| 区 | 类型 | 尺寸 | 遭遇/内容 |
|---|---|---|---|
| `ch4_entry` | entrance | 2560×1440 | 无遭遇；注释记录舞台母题现状与待定 |
| `ch4_branch_a` | branch | 2560×1440 | `Arena`、`Arena2`；宝箱 `Chest1` |
| `ch4_branch_b` | branch | 2560×1440 | `Arena` |
| `ch4_hub` | hub | 2560×1440 | 休整 + 商店 `ch4_hub_shop` + 残碑 + 捷径解锁 |
| `ch4_well` | well | 2560×2160 | `Arena`、`Arena2`；宝箱 `Chest1`；`vertical` |
| `ch4_vault` | vault | 2560×1440 | 隐藏；宝箱 + 残碑 |
| `ch4_event` | event | 2560×1440 | `ch4_event/event` 占位（无波次/文案） |
| `ch4_elite` | elite | 3840×2160 | `Arena` |
| `ch4_boss` | boss | 3840×2160 | 末端占位；无 `boss_scene`/文案/机制 |

- 宝箱 3、残碑 2，与旧世界同数（旧 `ch4_03` / `ch4_05` / 书库各一箱；
  旧 `ch4_rest` / 书库各一碑），全部 `region/Node` 节点 id。
- 计划未写 `wave`：本程只在测试里校验 6 场战斗与 `ROOM_WAVES[3]` 六波按计划顺序
  一一对应；事件节点无波次。
- **Boss 区只做图骨架末端占位**：不写 `boss_scene` 路由、不改旧
  `boss_script == "smiling"` 分支、不做 Boss 4 机制、不写入场/阶段文案。

### B. 图骨架夹具（`tests/fixtures/big_room/ch4_graph.mdsworld.json`）

- 顶层 `fixture: true` + `content_pending: true`（夹具元数据），无 `scene_path`、
  无房间场景、游戏从不引用（测试检查 `game.gd` 不含夹具路径）。
- 镜像旧世界区域 `Smiling Theater`（灰烬 + 光柱、`boss_background = blood_moon`、
  `background` 空），不写 `backdrop_image`——不为舞台母题预设方案。
- 9 区世界矩形、20 扇有向门 + 2 扇到达门，与计划的 11 条门记录互校；
  捷径门带 `requires: ["ch4_shortcut"]`，`elite_boss` 与捷径为显式单向。
- 夹具顶层注释记录：舞台母题、`ch4_shortcut` 来源、`Ch4EventData`、Boss 4
  机制/路由/文案、战斗密度、`mask_enemy`/`seat_husk` 独立数值、Boss 单向门取舍
  均留给后续程/拍板。

### C. 测试与路由锁

- 新增 `tests/test_ch4_plan.gd` **778 断言**：计划形状/类型/尺寸/坠落平面/内容 id/
  清房目标/图可达性/单向门/捷径占位/待内容标记 + `content_pending` 只推迟波次表
  （关掉标志必须报六条缺波次）+ 6 场战斗 ↔ `ROOM_WAVES[3]` 六波按计划顺序对应 +
  计划↔夹具逐区逐门交叉校验 + 夹具几何（不重叠、门在正确边、门位在房间内、
  区域相邻、捷径不邻接）+ 第 1–3 章计划不变 + 旧第 4 章世界不变（9 房/17 门/
  7 right / 7 left / 3 door；`ch4_boss/left1` 仍返回 `ch4_rest`）+ `game.gd`
  路由槽仍为空、旧世界仍被使用、`ch4_bigmap` 目录尚未创建。
- 路由锁同步（各 +1 断言）：`tests/test_ch2_world.gd`、`tests/test_ch3_content.gd`、
  `tests/integration_playability.gd` 在既有「第 4 章计划槽为空」旁补
  「计划资源已存在但未接入」；无计划时清房目标 6 / 坠落平面 850 的默认行为断言
  继续成立（计划未接 `game.gd`，行为不变）。

### D. 本程留空/未做

- **舞台母题**：未给大区管线加 theater 层、未改 `TheaterBackdrop`、未新绘背景；
  只记录现状（聚光灯/地面光斑/浮尘 + `smiling_theater.png`）与待定。
- **`ch4_shortcut` 来源**：未新增任何授予交互/事件/掉落；捷径门封闭占位，
  `game.gd` 源码仍不含 `ch4_shortcut`（测试锁定）。
- **战斗密度**：未扩波、未增遭遇；旧世界每房 5–6 只 vs 大图每遭遇 2 只
  （`ROOM_WAVES` 单波）的差异只记录，留待内容程/拍板。
- **`mask_enemy`/`seat_husk` 独立数值与行为**：未做，仍为第 1 章敌人的美术变体。
- **Boss 4 机制范围**：未做、未设计；剧情圣经三阶段与 GDD「舞台机关」的差距只记录。
- **章末边界**：未改 `_complete_chapter`；第 4 章为最后一章、章末已走 `_finish(true)`；
  第 3 章停章替身（`_chapter == 2` → `_finish(true)`）须在可达性拍板后解开。
- **阿砚同行**：未做；仓库仍无 companion/follower 控制器，只记录缺失。
- 未建真实大区世界/房间、未写 `Ch4EventData`/权柄池/波次接线/Boss 文案/机制、
  未开放第 2/3/4 章可达性、未改第 11–16 项相关数值/相机/HUD/捷径授予、
  未新增移动能力、未改 NPC 立绘/MDS 插件、未新绘美术、未打包/导出/签名。

## 第 4 章真实大区世界（第 52 程，只做结构层）

> 范围：第 4 章大地图施工第 2 步（对应第 50 程核查 D 节第 2 项）。把第 51 程的
> 9 区计划做成可加载的真实大区世界与房间场景，只做结构层；不接入 `game.gd`、
> 不改第 4 章可达性、不写波次/事件/权柄/Boss 内容、不做第 4 章大图验收。
> 详细版见 [第 4 章真实大区世界 session](docs/memory/sessions/2026-11-05-chapter4-bigmap-world.md)。

- **大区数据** `resources/rooms/ch4_bigmap/*.tres`：9 个 `BigRoomData`，尺寸按计划
  2560×1440 / 2560×2160（纵井）/ 3840×2160（精英、Boss）；地面贴房间底边
  （`H-16`，16 px 厚），平台按 80 px 阶梯链布置并通过第 28 程几何校验
  （上升 ≤80 px、水平边缘 ≤120 px）；复用 `ch1_tiles.tres`；
  `backdrop_path = smiling_theater.png`（既有绘画背景，`backdrop_pixel_art = false`），
  `ambient_kind = embers`（灰烬母题）、密度 0.5，按区暖色调（入口白 / 支路暖 /
  枢纽灯黄 / 纵井灰紫 / 书库冷紫 / 事件暖橙 / 精英红 / Boss 血红）。
- **大区场景** `scenes/mds/ch4_bigmap/*.tscn`：9 个 `MDSBigRoom`，`fall_margin = 240`
  （房间 metadata `fall_below_bounds = 240`，与计划一致）；内容节点严格用计划 id：
  `ch4_branch_a` 的 `Arena`/`Arena2`/`Chest1`、`ch4_branch_b` 的 `Arena`、
  `ch4_well` 的 `Arena`/`Arena2`/`Chest1`、`ch4_elite` 的 `Arena`、
  `ch4_hub` 的 `Stele1`/`Shop`(`ch4_hub_shop`)/`Bench`、
  `ch4_vault` 的 `Chest1`/`Stele1`；事件区节点名 `Event`，作者
  `encounter_id = ch4_event/event`；Boss 区只放结构 `Arena`（Boss 内容后续程）。
- **入口出生点**：`ch4_entry` 作者 `SpawnPoint`（`save_point` 组，(400,1328) =
  第一级台阶面 1344 − `FOOT_Y` 16），沿用第 37/41 程口径；惰性 `shortcut_arrival`
  到达门（`MDSGate.Mode.TOUCH`）；不改 MDS 出生回退顺序、不改第 1–3 章出生点。
- **纵向/捷径骨架**（复用第 29 程管线，未新增移动能力）：`ch4_branch_b`/`ch4_hub`/
  `ch4_vault` 各 1 台电梯（地面 → y=100，覆盖顶门列且避开平台），`ch4_well`
  1 台电梯 + 3 个单向落台，`ch4_elite` 1 台电梯（到达门上缘的横向走廊），枢纽
  `Bench` 长椅检查点与带 `requires` 的捷径门自动生成 `MDSGateBarrier`。
  电梯未写 `speed`，沿用 `MovingPlatform.speed` 管线默认 **80 px/s**；
  「待用户确认」第 12 项只针对第 2 章，本程未给第 4 章定速度。
- **独立世界** `scenes/mds/chapter_4_bigmap.mdsworld.json` + `chapter_4_bigmap_world.tscn`：
  9 区单矩形、原点 32 px 对齐；`start_room = ch4_entry`；区域 `Smiling Theater`
  镜像旧世界（灰烬 + 光柱天气、`background` 空、`boss_background = blood_moon`），
  不写 `backdrop_image`、不加 theater 层（舞台母题仍待拍板）；22 门 = 20 有向 +
  2 只到达（`ch4_entry/shortcut_arrival`、`ch4_boss/left1`）；显式单向
  `elite_boss`（进 Boss 不可返回）与 `hub_shortcut_entry`
  （`requires = ["ch4_shortcut"]`，来源待第 50 程专节 E，屏障默认封闭）；
  侧门在地面上方 90 px、底门在地面线、顶门在上边缘；房间不重叠、双向门相邻、
  捷径刻意不相邻。世界 JSON 由第 51 程夹具镜像生成（逐区字段一致，仅加
  `scene_path`），夹具未改语义。
- **测试** `tests/test_ch4_world.gd`（**812** 断言）：真实世界 ↔ 计划逐区
  类型/尺寸/遭遇/宝箱/残碑/捷径/隐藏/商店/休整/纵井；11 条计划门 ↔ 世界门位、
  双向/单向/`requires`；世界图从入口 BFS 到全部 9 区；几何（单矩形、原点 32 网格、
  门在正确边、房间不重叠、双向门相邻、捷径不相邻）；9 场景为 `MDSBigRoom`、
  `BigRoomData` 校验为空、尺寸/瓦片/背景/氛围/坠落余量/底边地面；内容节点与
  计划 id 一一对应且数量不许多、事件区作者遭遇 id、枢纽商店/长椅、入口出生点与
  到达门；5 区电梯（默认 80 px/s）、纵井 3 个单向落台、顶门房间电梯覆盖门列、
  行程向上、列内无平台；夹具镜像与隔离；`CHAPTER_PLAN_PATHS[3]` 仍空、旧第 4 章
  9 房/17 门世界仍在（`ch4_boss/left1` 仍返回 `ch4_rest`）、第 1–3 章计划与世界
  不变、计划仍 `content_pending`/无波次/无权柄池/无 `boss_scene`、无
  `Ch4EventData`、`game.gd` 不含 `ch4_shortcut`、场景无作者 `GateVisual`。
  就地更新 `tests/test_ch4_plan.gd` 的「`ch4_bigmap` 目录尚未创建」锁为目录/
  文件存在（778 → 796，其余路由锁不变）。
- **边界**：`game.gd` 未改，第 4 章仍走旧 `chapter_4.mdsworld.json` / 9 个
  `MDSChapterRoom`，`CHAPTER_PLAN_PATHS[3]` 仍空；第 4 章仍不可达。舞台母题
  （未加大区 theater 层、未改 `TheaterBackdrop`、未新绘背景）、`ch4_shortcut`
  来源（未新增任何授予交互/事件/掉落，屏障保持封闭）、战斗密度（未扩波/未增遭遇；
  旧世界每房 5–6 只 vs 大图每遭遇 2 只只记录）、`mask_enemy`/`seat_husk` 独立
  数值与行为（未做，仍为第 1 章敌人美术变体）、Boss 4 机制范围（未做、未设计、
  不写 `boss_scene`/入场/阶段文案）、章末边界（未改 `_complete_chapter`；第 3 章
  停章替身仍待可达性拍板后解开）、阿砚同行（未做，仓库仍无 companion 控制器）
  全部留空未施工。未新增移动能力、未改 NPC 立绘/MDS 插件、未新绘美术、未打包/
  导出/签名。

## 第 4 章内容数据层第 1 步（第 53 程，只做数据层）

> 范围：第 4 章大地图施工第 3 步前半段（对应第 50 程核查 D 节第 3 项中
> 「`Ch4EventData` / `authority_pool` / Boss 入场与阶段文案」部分）。沿用第 32 程
> （第 2 章）与第 42 程（第 3 章）已验证的口径，只做数据层与测试。**波次接线
> （第 2 步）、事件区真实自动触发（第 3 步）、Boss 4 机制/`boss_scene` 与本程
> 之后的第 4 章大图验收均不做**；计划仍不路由、世界仍不被 `game.gd` 引用，
> 第 4 章仍不可达。详细版见
> [第 4 章内容数据层 session](docs/memory/sessions/2026-11-05-chapter4-content-data.md)。

- **事件数据** `scripts/data/ch4_event_data.gd`（`Ch4EventData`）：7 组笑面剧场
  文案——纸人 / 面具 / 名册 / 幕布 / 台词 / 聚光灯 / 谢幕；取材自
  `CampaignData.chapter(3)` 的开场（纸人只为最后一页鼓掌、笑面史官记得所有名字、
  「这次换你写我」）与章末（一页写满昌子名字的纸、纸人的最后一句「谢幕」），
  以及 GDD/剧情圣经的舞台、面具、名册、谢幕母题；不新增设定、不写出未实现的
  「未来的昌子」剧情事实。固定「读/拿」两选项，效果沿用第 32 程口径——读 →
  污染 +8 + 解明一个残页词（无词可解改发残页 +6），拿 → 残页 +12；
  `pick(run_seed, "ch4_event/event")` 确定性轮换、不消耗 run RNG。
- **事件路由**：`game.gd` 的 `_event_data` 扩到第 4 章（索引 3），键为计划事件
  节点 id；第 1 章仍 `Ch1EventData` 原键与原值，第 2/3 章仍 `Ch2/Ch3EventData`，
  索引 ≥ 4 仍返回 `{}`。事件区真实触发留给后续程（通用大图区域分支已存在，
  本程只锁触发谓词输入）。
- **权柄池**：`chapter_4_demo.tres` 补 `authority_pool = [续命, 改写]`；条件项
  仍由 `AuthorityController.build_pool` 从 `ContentLibrary` 追加吞噬（污染 ≥ 40）/
  归档（记录 ≥ 2），第 1/2/3 章池与授予行为不变。
- **Boss 文案**：`BossEntranceData` 新增第 4 章「笑面史官」8 条入场文案
  （`variants(3)`），`BossPhaseData` 新增阶段 2/3 各 8 条（`variants(phase, 3)`）；
  第 1 章保留 `"%d:%d"` 选句键，第 2/3/4 章用 `"%d:%d:%d"`，不回落第 1/2/3 章。
  核查确认 `BossEntranceData` 既有实现用 `"%d:%d" % [run_seed, chapter_index]`
  （第二段是章节索引，天然按章节区分），保持原样只加表；若改键会让第 2/3 章
  已选句子漂移。
- **Boss 数值/立绘/脚本未改**：笑面史官 HP 520 / 伤害 18 / 速度 92 /
  `smiling_archivist.png` / `boss_script = smiling`，计划仍无 `boss_scene`、
  无专章机制（改写规则/删除词/复制武器/舞台机关留待机制程）。
- **遭遇与波次只校验不接线**：7 个遭遇节点唯一且 `region/Node` 锚定；6 个战斗
  遭遇按计划顺序与 `ROOM_WAVES[3]` 六波一一对应（事件节点无波、Boss 区不占
  普通波）；清房目标仍 7（HUD 分母 8）。计划 7 个区域仍无 `wave` 键，
  `content_pending = true` 继续推迟 `validate_waves()`；清零标志的副本会报恰好
  6 条缺波次且不向事件节点要波——下一步按计划顺序落 `ROOM_WAVES[3]` 即可。
- **测试**：新增 `tests/test_ch4_content.gd`（**613 断言**）锁定事件确定性/
  效果类型/轮换/不耗 RNG、章节事件路由、权柄基础池 + 条件项、Boss 文案不回落
  第 1/2/3 章与选句键不变、Boss 4 数值/立绘/脚本未改、7 个遭遇节点与六波对应、
  清房目标 7、`content_pending` 保持、事件触发谓词输入，并锁
  `CHAPTER_PLAN_PATHS[2]/[3]` 仍空、`MDS_WORLD_FILES[3]` 仍指旧世界、旧第 4 章
  9 房/17 门世界与第 1–3 章计划/世界不变、`game.gd` 不含 `chapter_4_demo.tres`/
  `chapter_4_bigmap`/`ch4_shortcut`。同步更新 `test_ch4_plan`/`test_ch4_world`
  的「无 authority_pool / 无事件模块 / Boss 静默」期望，以及
  `test_ch2_content`/`test_ch3_content`/`test_boss_entrance_content`/
  `integration_ch1_demo` 中「第 4 章静默」的旧期望（改为「第 4 章有自己的文案、
  超出范围静默」）；图骨架夹具只改说明文字。
- **边界/未做**：未开放第 2/3/4 章可达性、未接入 `game.gd`、未改章节路由与
  章末流程；未做波次接线、事件区真实自动触发验证、Boss 4 机制/`boss_scene`、
  第 4 章大图验收；未新增 `ch4_shortcut` 授予、未改舞台表现/战斗密度/
  `mask_enemy`/`seat_husk` 独立数值；未做阿砚同行、新移动能力、NPC 立绘、
  MDS 插件、新绘美术、打包/导出/签名/安卓/触屏。待确认第 11–16 项未碰，
  第 50 程专节 E 的开放问题候选仍只记录、未编号、未拍板。

## 第 4 章内容数据层第 2 步（第 54 程，只做数据层）

> 范围：第 4 章大地图施工第 3 步的后半段（对应第 50 程核查 D 节第 3 项中
> 「计划 `wave` 接线 + `content_pending` 清零」）。沿用第 33 程（第 2 章）与
> 第 43 程（第 3 章）已验证的口径，只做数据层与测试。**事件区真实自动触发
> （第 3 步）、Boss 4 机制/`boss_scene`、第 4 章大图验收与本程之后的任何
> 可达性工作均不做**；计划仍不路由、世界仍不被 `game.gd` 引用，第 4 章仍
> 不可达。详细版见
> [第 4 章波次接线 session](docs/memory/sessions/2026-11-05-chapter4-wave-wiring.md)。

- **波次接线**：`chapter_4_demo.tres` 的 4 个战斗区（`ch4_branch_a`/
  `ch4_branch_b`/`ch4_well`/`ch4_elite`）补 `wave` 字典，6 个键 = 6 个战斗
  遭遇节点 id，值按计划顺序逐字复用 `ROOM_WAVES[3]` 六波（波次内容未新增、
  未修改）：`ch4_branch_a/Arena` → `mask_enemy`+`seat_husk`；
  `ch4_branch_a/Arena2` → `choir_summoner`+`page_swarm`；
  `ch4_branch_b/Arena` → `seat_husk`+`mirror_sniper`；
  `ch4_well/Arena` → `mask_enemy`+`typo_beast`；
  `ch4_well/Arena2` → `ink_bomber`+`mask_enemy`；
  `ch4_elite/Arena` → `mirror_sniper`+`page_swarm`。事件节点
  `ch4_event/event` 无波，事件区/Boss 区/入口/枢纽/书库不带 `wave`；清房目标
  仍 7（HUD 分母 8）。
- **`content_pending` 清零**：按第 40/43 程约定由 `true` 改回 `false`，波次表
  进入 `validate()` 正常校验（区域/门图校验不变）；标志本身保留在
  `ChapterPlanData`（默认 `false`、向后兼容）。图骨架夹具
  `tests/fixtures/big_room/ch4_graph.mdsworld.json` 顶层的
  `content_pending: true` 是夹具元数据、不是该字段，未改。
- **校验**（就近扩展既有套件，未另起重复套件）：
  - `tests/test_ch4_content.gd`（**641 断言**，+28）：波次段从「未接线」改为
    接线校验——6 个键恰好等于 6 个战斗遭遇节点 id、每个键的值 ==
    `ROOM_WAVES[3]` 对应波原文、键锚定本区且唯一、事件节点/事件区/Boss 区
    无波、`validate_waves()` 与 `validate()` 干净、`content_pending` 已清零；
    新增 `_test_runtime_wave_lookup`：把第 4 章计划挂到独立 `game.gd` 实例上，
    经 `_plan_wave()` 按节点 id 读回六波（证明第 33 程通用大图分支可直接
    取用），但不改章节路由。
  - `tests/test_ch4_plan.gd`（**795 断言**，−1）：`_test_pending_content` →
    `_test_wave_wiring`，锁定 6 个波次键、逐遭遇非空、事件/Boss 无波、计划
    校验干净；`content_pending` 的局部性改为「新副本删掉波次 + 标志开 →
    `validate()` 干净；标志关 → 报六条缺波次」，保留第 40 程的关口。
  - `tests/test_ch4_world.gd`（**813 断言**，+1）：计划侧期望同步为
    `content_pending = false`、6 个波次键、`validate_waves()` 干净；世界/场景
    本身未改。
  - 既有断言保留并复跑：`CHAPTER_PLAN_PATHS[3]` 仍空、`MDS_WORLD_FILES[3]`
    仍指旧世界、旧第 4 章 9 房/17 门世界仍在、第 1/2/3 章计划与世界不变、
    清房目标仍 7。
- **产品代码未改**：`game.gd`、`ChapterPlanData`、第 4 章世界 JSON/场景、
  Boss 4 数值与文案均未改动；本程只改计划资源与测试。
- **边界/未做**：未开放第 2/3/4 章可达性、未接入 `game.gd`、未改章节路由与
  章末流程；未做事件区真实自动触发验证（第 3 步，沿用第 34/44 程通用分支，
  留待下一程）、Boss 4 机制/`boss_scene`、第 4 章大图验收；未新增
  `ch4_shortcut` 授予（捷径屏障仍默认封闭）；战斗密度未扩波/未增遭遇（旧世界
  每房 5–6 只 vs 大图每遭遇 2 只的差异只记录）；`mask_enemy`/`seat_husk`
  独立数值与行为未做；舞台母题呈现层未改；阿砚同行未做；待确认第 11–16 项
  未碰，第 50 程专节 E 的开放问题候选仍只记录、未编号、未拍板。

## 第 4 章内容数据层第 3 步（第 56 程，只做触发与测试层）

> 范围：第 4 章事件区 `ch4_event` 的真实自动触发验证。沿用第 34 程（第 2 章）
> 与第 44 程（第 3 章）已验证的通用大图区域分支，本程只做核查、集成验证与
> 记录。**不接入 `game.gd`、不开放可达性、不改章节路由与章末流程、不做
> Boss 4 机制/`boss_scene`、不做第 4 章大图验收**；计划仍不路由、世界仍不被
> `game.gd` 引用，第 4 章仍不可达。详细版见
> [第 4 章事件触发 session](docs/memory/sessions/2026-11-05-chapter4-event-trigger.md)。

- **前置核查（结论：无需新增触发路径）**：`_on_mds_room_loaded` 第 34 程的
  区域级大图事件分支是章节无关判定——`big_map` + 计划区域 `type == "event"`
  + `_event_data(room_id)` 非空；第 53 程 `_event_data` 已路由第 4 章
  （`_chapter == 3` → `Ch4EventData`）。因此 `ch4_event` 事件区无需第 4 章
  专属触发路径；`game.gd` 只把该分支注释的「Chapters 2–3」更正为
  「Chapters 2–4」，行为零改动。
- **触发验证**（`tests/integration_playability.gd` 新增
  `_test_ch4_bigmap_event_trigger`，把第 52 程
  `chapter_4_bigmap_world.tscn` 与第 4 章计划临时挂到真实主场景，
  `ch4_event` 为起始区，走真实 `room_loaded`）：
  - 进入区域即开第 4 章事件页；文案/标题/两选项 =
    `Ch4EventData.pick(run_seed, "ch4_event/event")`，开页不耗 run RNG；
  - 拿 → 残页 +12、提示文案正确、HUD「档案 1 / 8」，结算写
    `cleared_encounters["ch4_event/event"]` 且清房计数 +1（清房目标 7、分母 8）；
  - 结算落进真实 run save 的同一键；重载不重开、不暂停、不重复计数、
    不重复奖励；
  - 回退结算后重进再验「读」→ 污染 +8（经倍率、上限 100）+ 解明一个残页词，
    无词可解 → 残页 +6（沿用 `Ch4EventData` / `_grant_event_word` 既有口径）；
  - 同时锁不变项：`CHAPTER_PLAN_PATHS[3]` 仍空、`MDS_WORLD_FILES[3]` 仍指旧
    `chapter_4.mdsworld.json`、旧第 4 章 9 房/17 门世界仍在、第 1/2/3 章计划槽
    不变、计划清房目标 7 / 7 个遭遇 / 波次表（`content_pending = false`）/
    `boss_scene` 仍空、第 1–3 章事件数值不变、`game.gd` 无 `ch4_event`
    专属触发与 `chapter_4_bigmap` 路由；测试后恢复第 4 章旧世界巡检。
- **单元校验**：`tests/test_ch4_content.gd`（641 → **642**）补一条
  「触发键 = `RoomProgress.event_encounter_id("ch4_event")` = 计划事件节点 id」，
  防止页面与结算键漂移。
- **产品代码未改**：`game.gd` 仅注释；`ChapterPlanData`、第 4 章计划/世界/
  场景、`Ch4EventData`、Boss 4 数值与文案均未改动。
- **边界/未做**：未开放第 2/3/4 章可达性、未接入 `game.gd`、未改章节路由与
  章末流程；未做 Boss 4 机制/`boss_scene`、第 4 章大图验收；未新增
  `ch4_shortcut` 授予（捷径屏障仍默认封闭）；战斗密度未扩波/未增遭遇（旧世界
  每房 5–6 只 vs 大图每遭遇 2 只的差异只记录）；`mask_enemy`/`seat_husk`
  独立数值与行为未做；舞台母题呈现层未改；阿砚同行未做；待确认第 11–16 项
  未碰，第 50 程专节 E 的开放问题候选仍只记录、未编号、未拍板。

## 第 4 章 Boss 4 机制与 `boss_scene` 路由（第 57 程，只做机制与测试层）

> 范围：第 4 章 Boss 4「笑面史官」的计划 `boss_scene` 路由与既有机制锁定。
> 沿用第 45 程（第 3 章 Boss 3）的做法，本程只做核查、路由、测试与记录。
> **不扩展机制（删除词/复制武器/舞台机关）、不接入 `game.gd`、不开放可达性、
> 不改章节路由与章末流程、不做第 4 章大图验收**；计划仍不路由、世界仍不被
> `game.gd` 引用，第 4 章仍不可达。详细版见
> [第 4 章 Boss 4 session](docs/memory/sessions/2026-11-06-chapter4-boss4-mechanism.md)。

- **前置核查（结论：既有实现可直接复用，无需改脚本）**：
  - `scripts/bosses/smiling_archivist.gd`（`SmilingArchivist extends InkArchivist`）
    与 `scenes/bosses/smiling_archivist.tscn` 已存在；阶段 1 纸页波，阶段 2
    每第 3 次为镜面弹幕、其余纸页波，阶段 3 四拍 `%4` = 改写 / 镜面弹幕 /
    墨雨 / 纸页波。镜面弹幕 3 枚、张角 ±0.34 rad、每枚
    `int(攻击力 × 0.7)`、速度 280；纸页波继承（阶段 ≥2 双发）；墨雨 3 个
    `InkWarning`、`int(攻击力 × 0.75)`；改写封印一个短语槽 3.0 s。
  - `CampaignData.chapter(3)`：名「笑面史官」、HP 520 / 伤害 18 / 速度 92、
    `boss_script = &"smiling"`、立绘 `smiling_archivist.png`；没有
    `boss_scene`（场景由计划路由）。
  - `game._spawn_boss` 优先级：战役表 `boss_scene`（第 1 章）→ 计划
    `boss_scene`（第 2/3/4 章）→ `boss_script == "smiling"` →
    `boss_script == "reader"` → 默认；本轮只给计划补字段，优先级与兜底未改。
  - 大图生成高度：`_enemy_spawn_y()` 在 `_chapter_plan != null and big_map` 时
    返回 `-ENEMY_FOOT_Y - 2`（-18 px），否则 250 px；函数未改，只补断言。
  - 第 53 程已补 `BossEntranceData` 8 条入场 + `BossPhaseData` 阶段 2/3 各
    8 条，选句键 `"%d:%d:%d"`（含章节索引），第 4 章不回落第 1/2/3 章。
- **路由与不变项**：`chapter_4_demo.tres` 新增
  `[ext_resource type="PackedScene" path="res://scenes/bosses/smiling_archivist.tscn"]`
  并写 `boss_scene = ExtResource("5_smiling")`；Boss 区备注同步改为「已路由 +
  入场/阶段文案已编写 + 机制扩展仍待拍板」。通用 Boss 流程（生成/血条/阶段
  横幅/权柄/outro/结束）全部复用，未另起框架。数值与立绘未改（暂定口径，
  由测试锁定）；第 1/2/3 章 Boss 场景与计划 `boss_scene` 未改；
  `_complete_chapter` 与章节路由未改。第 4 章仍不可达：
  `CHAPTER_PLAN_PATHS[3]` 仍空、`MDS_WORLD_FILES[3]` 仍指旧
  `chapter_4.mdsworld.json`、旧第 4 章 9 房/17 门世界仍在；计划清房目标 7、
  7 个遭遇、波次表（`content_pending = false`）、基础权柄池、事件触发口径
  均不变；`game.gd` 仍无 `chapter_4_bigmap` / `ch4_shortcut` 引用。
- **机制锁定（由测试固定）**：

  | 阶段 | 攻击轮换 | 说明 |
  |---|---|---|
  | 1 | 纸页波 | 单发，伤害 = 攻击力 18 |
  | 2 | 纸页波 ×2 → 镜面弹幕 | 每第 3 次为镜面弹幕；纸页波阶段 ≥2 双发 |
  | 3 | 镜面弹幕 → 墨雨 → 纸页波 → 改写 | `%4` 轮换；改写固定封 0 号槽 |

  - 镜面弹幕：3 枚、±0.34 rad、`int(18 × 0.7) = 12`、速度 280。
  - 墨雨：3 个 `InkWarning`、`int(18 × 0.75) = 13`。
  - 改写：封印 0 号短语槽 3.0 s（阶段 3 的改写落在 4 的倍数拍，恒为 0 号槽）。
  - 单元层限制：`test_ch4_boss` 在 `_initialize` 同步运行，节点尚未进入
    SceneTree，而 `SmilingArchivist._mirror_fan` / `_ink_rain` 有
    `is_inside_tree()` 前置；单元层用记录型子类锁完整节拍表、用真实脚本锁
    纸页波伤害与改写，镜面弹幕/墨雨的生成物数量、伤害与速度在
    `integration_playability` 的真实树里锁定。
- **测试**：新增 `tests/test_ch4_boss.gd`（78 断言）；`test_ch4_plan`
  795→**797**、`test_ch4_world` 813→**814**、`test_ch4_content`
  642→**644**（旧「计划无 `boss_scene`」期望改为已路由）；可玩性集成新增
  `_test_ch4_bigmap_boss`（真实第 4 章大区世界 + 计划临时挂载，`ch4_boss`
  起始：计划路由 `SmilingArchivist`、数值来自战役表、生成在 Arena 地面线
  之上、阶段 2/3 横幅使用第 4 章选句键、实树镜面弹幕/墨雨/改写生效、击败 →
  权柄 → outro → 章末选择 → 战役结束、重载不二次生成；测试后恢复旧第 4 章
  世界），810 → **869**。
- **边界/未做**：未开放第 2/3/4 章可达性、未接入 `game.gd`、未改章节路由/
  章末流程/`_complete_chapter`（第 4 章章末收口排下一程）；未做 Boss 4 机制
  扩展（剧情圣经的「删除词/复制昌子的武器」、GDD 的「舞台机关」），未新增
  任何攻击手段；未新增 `ch4_shortcut` 授予（屏障仍默认封闭）；未扩波/增遭遇
  （旧世界每房 5–6 只 vs 大图每遭遇 2 只只记录）；`mask_enemy`/`seat_husk`
  独立数值未做；舞台母题呈现层未改；阿砚同行未做；待确认第 11–16 项未碰，
  第 50 程专节 E 的开放问题候选仍只记录、未编号、未拍板。

## 第 4 章章末收口（第 58 程，只做章末流程与测试层）

> 范围：第 4 章（最终章）的章末流程收口——Boss 4 击败 → 权柄 → outro →
> 章末选择 → 战役结束/停章，不自动进入不存在的后续章节。
> 沿用第 46 程（第 3 章章末）的做法，本程只做核查、章末分支、测试与记录。
> **不接入 `game.gd`、不开放可达性、不改章节路由与可达性、不做第 4 章大图
> 验收、不扩展 Boss 4 机制、不新编剧情**；计划仍不路由、世界仍不被 `game.gd`
> 引用，第 4 章仍不可达。详细版见
> [第 4 章章末收口 session](docs/memory/sessions/2026-11-06-chapter4-chapter-end.md)。

- **前置核查（结论：章末文本/选项/语音齐全，续玩逻辑章节无关，无需新编）**：
  - `_complete_chapter` 原有分支：第 1 章（`_chapter == 0`）置
    `demo_cleared` 后 `_finish(true)`；第 2 章（`_chapter == 1`）`_finish(true)`
    （第 35 程）；第 3 章（`_chapter == 2`）`_finish(true)`（第 46 程）；其余走
    `_chapter + 1 < CampaignData.chapter_count()` → `_start_chapter`，否则
    `_finish(true)`。第 4 章（`_chapter == 3`）此前因 `chapter_count() == 4`
    落到 `else` 的 `_finish(true)`，行为上已经结束战役，但没有显式分支。
  - `CampaignData.chapter(3)`：4 句 `outro`、两选项（重写名册 仁慈 +1 /
    焚毁名册 污染 +12）、`voice_outro = ch4_outro`
    （`assets/audio/voice/zh_cn/ch4_outro.ogg` 存在）；`_apply_chapter_choice`
    已有 `smiling_theater` 分支（选项 1 置 `_burned_final`，结局按
    `CampaignData.ending_for` 选焚毁）。**未新编任何剧情文本、未新设选项**。
  - 续玩/重载逻辑章节无关：`_on_mds_room_loaded` 的 Boss 区在 `_boss_defeated`
    时调用 `_resume_boss_aftermath`（不二次生成 Boss、无权柄时补授予、随后
    `_complete_chapter`）；`_start_mds_chapter` 从 run save 恢复
    `_boss_defeated`。
- **改动**：`scripts/game.gd` 的 `_complete_chapter` 在既有第 3 章分支之后新增
  `_chapter == 3` 分支，章末选择后调用现有 `_finish(true)` 结束战役；第 1/2/3 章
  分支与 `_chapter + 1 < chapter_count()` 兜底未改，只更新第 3 章分支上方已
  过时的注释。章末选择界面/结局记录/续玩行为沿用第 35/46 程口径，不另起流程。
  （行为等价：第 4 章是最后一章，旧的 `else` 兜底本来就是 `_finish(true)`；
  本程把战役终点写成显式分支并由测试锁定。）
- **测试**：`tests/integration_playability.gd` 的 `_test_ch4_bigmap_boss` 扩为
  完整章末链路（真实第 4 章大区世界 + 计划临时挂载，`ch4_boss` 起始）：
  击败 `SmilingArchivist` → 权柄二选一 → 第 4 章 outro（4 句原文/标题/
  `ch4_outro` 语音）→ 章末选择（两选项原文）→ `_finish(true)`；断言
  `_chapter` 仍 3、`_finished`、结局屏可见、`_boss_defeated` 已记录、
  选项 0 的仁慈 +1 与零污染、`_burned_final == false`、结局 id 按
  `CampaignData.ending_for` 规则且写入 `Profile.endings`；测试后
  `_restore_chapter_world` 恢复旧第 4 章世界。同函数开头锁定不变项：
  `CHAPTER_PLAN_PATHS[3]` 仍空、`MDS_WORLD_FILES[3]` 仍指旧
  `chapter_4.mdsworld.json`、清房目标 7、7 个遭遇节点、`ch4_branch_a/Arena`
  波次表、权柄基础池、`boss_scene` 指向 `smiling_archivist.tscn`、
  `CampaignData.chapter_count() == 4`。旧线性世界结构遍历补
  `chapter_index == 3` 分支：停在第 4 章、结局屏可见（并同步更新第 3 章分支的
  过时注释与章末等待时长）。
- **不变项**：`CHAPTER_PLAN_PATHS[3]` 仍空、`MDS_WORLD_FILES[3]` 仍指旧世界、
  旧第 4 章 9 房/17 门世界仍在；第 4 章计划清房目标 7、波次表
  （`content_pending = false`）、权柄池、事件触发口径、`boss_scene` 与 Boss 4
  机制/数值不变；第 1/2/3 章计划/世界/章末流程不变；第 4 章仍不可达、未接入
  `game.gd`。
- **边界/未做**：未做第 4 章大图验收；未做 Boss 4 机制扩展（剧情圣经的
  「改写规则/删除词/复制昌子的武器」、GDD 的「舞台机关」）；未新增
  `ch4_shortcut` 授予（屏障仍默认封闭）；未扩波/增遭遇（旧世界每房 5–6 只 vs
  大图每遭遇 2 只只记录）；`mask_enemy`/`seat_husk` 独立数值未做（仍是第 1 章
  敌人的美术变体，共享场景/数据）；舞台母题呈现层未改（未改 `TheaterBackdrop`、
  未新绘背景）；阿砚同行未做；待确认第 11–16 项未碰，第 50 程专节 E 的开放
  问题候选仍只记录、未编号、未拍板。

## 第 4 章大地图系统验收（第 59 程）

> 范围：第 4 章（笑面剧场）九区大地图的系统验收，口径对齐第 36 程（第 2 章）
> 与第 48 程（第 3 章）D 节 1–10 项，并加第 4 章专属断言。只做验收与验收面内
> 的真实缺陷修复；不接入 `game.gd`、不开放可达性、不做门视觉/地图标题改动/
> 敌人美术接线。本程为 brief63 第 2 次尝试：首次（brief62）因 Magpie 网关
> 中断夭折，只留下未提交的验收脚本初稿；本程核查后修复其解析错误并补齐
> 缺口，未另起框架。详细版见
> [第 4 章大地图系统验收 session](docs/memory/sessions/2026-11-06-chapter4-bigmap-acceptance.md)。

- **前置核查（结论：验收对象与第 51–58 程落地一致）**：
  - 计划 `resources/chapters/chapter_4_demo.tres`：9 区连通图；6 个战斗遭遇 +
    1 个事件占位 → 清房目标 7；3 宝箱/2 残碑；11 门 = 9 双向 + 2 单向
    （`elite_boss`、`hub_shortcut_entry` 带 `requires = ["ch4_shortcut"]`）；
    每区 `fall_below_bounds = 240`；`content_pending = false`；
    `authority_pool = [续命, 改写]`；`boss_scene = smiling_archivist.tscn`。
  - 独立世界 `scenes/mds/chapter_4_bigmap.mdsworld.json` +
    `chapter_4_bigmap_world.tscn`：9 区、22 门 = 20 有向 + 2 只到达
    （`ch4_entry/shortcut_arrival`、`ch4_boss/left1`）；入口 `ch4_entry` 作者
    `SpawnPoint`。
  - 内容：`Ch4EventData` 7 组笑面剧场文案；计划 `wave` 六波按顺序接
    `ROOM_WAVES[3]`；Boss 4 路由既有 `SmilingArchivist`；章末显式
    `_chapter == 3` → `_finish(true)`。
- **遗留初稿核查**：`tests/integration_ch4_bigmap.gd`（1782 行）结构完整，但
  `_run()` 内 `enemy_art` / `enemy_fallback` 重复声明，GDScript 解析失败、
  从未跑通。删除重复声明后首次运行 **4766 断言 / 0 失败**；随后按任务单补
  覆盖缺口（5 台电梯逐一测速、7 组事件文案、Boss 阶段 3、权柄条件项、其余
  四个战斗区波次实机校验），最终 **4869 断言 / 0 失败（连续两次）**。
- **验收结果**：`tests/integration_ch4_bigmap.gd` **4869 断言 / 0 失败**。
  覆盖：计划图入口 BFS 九区全可达；世界 22 门全部实走（20 连通 + 2 到达）、
  2 扇单向语义正确；九区单矩形边界 = 计划尺寸、相机四边 = 世界边界；5 台
  电梯实测管线默认 80 px/s、纵井 3 个单向落台、长椅回退、top/bot 门落点与
  出速、坠落平面不误杀；门过渡无叠加暂停/剧情/奖励/地图/权柄/商店；3 宝箱 +
  2 残碑按节点 id 一次性；`ch4_branch_a` 两场遭遇逐场锁门/清怪/奖励，其余四个
  战斗遭遇在真实区域按计划波次生成；清房推进到 7（HUD 分母 8）；隐藏书库首次
  发现与地图揭示；捷径屏障默认封闭、测试注入能力后开门并跨存档保持（未新增
  游戏内授予）；世界级存档恢复到正确房间/坐标；`ch4_boss` 生成
  `SmilingArchivist`、战役数值/立绘/入场与阶段 2/3 文案、权柄池、击败 → outro
  → 章末选择 → 战役结束、重载不二次生成；地图标题「笑面剧场地图」、
  `smiling_theater.png` 平铺、灰烬/光柱、`embers`、`blood_moon` Boss 背景、
  无 theater/sea 层、8 种敌人专属美术无回退。
- **性能基线**（`fade_time = 0` 原始构建，两次运行区间）：普通区首次
  14.5–19.7 ms、热 12.3–16.6 ms；Boss 区冷 71.4–79.7 ms / 热 45.6–45.9 ms；
  关动态背景 11.6–12.0 ms、关天气 38.0–38.5 ms、不生成 Boss 21.7–22.8 ms；
  真实门过渡 236.1–243.8 ms。headless 无帧率上限，单帧耗时无代表性；大区按
  「门 + 0.22 秒淡入」过渡、`seamless_rooms = false`，故记录门过渡墙钟。
- **真实缺陷**：**未发现产品行为缺陷**；本程改动全部在验收脚本自身（遗留初稿
  重复声明导致解析失败 + 按任务单补断言），未改任何 `scripts/`/`scenes/`/
  `resources/`。战斗密度差异只记录：大图每遭遇 2 只 vs 旧世界每房 3–4 只。
- **不变项**：`CHAPTER_PLAN_PATHS[3]` 仍空、`MDS_WORLD_FILES[3]` 仍指旧世界、
  旧第 4 章 9 房/17 门世界仍在；第 4 章计划/波次/事件/权柄/Boss 4/章末流程与
  第 1/2/3 章计划/世界/流程不变；未新增 `ch4_shortcut` 授予、未改电梯速度/
  相机/HUD；第 2/3/4 章仍不可达、第 4 章仍未接入 `game.gd`。
- **边界/未做**：未做第 4 章门视觉专项、第 4 章地图标题改动、第 4 章敌人美术
  核查/接线、Boss 4 机制扩展、舞台母题呈现层、`ch4_shortcut` 授予来源、战斗
  密度调整、`mask_enemy`/`seat_husk` 独立数值、阿砚同行；待确认第 11–16 项
  未碰，第 50 程专节 E 的开放问题候选仍只记录、未编号、未拍板。

## 样图截图（第 60 程）

> 依据：`.supervisor/DECISIONS.md`「样图截图（监工决定 2026-11-06，用户想看新章节的样子）」。本程唯一产出是样图；只截图、只记录，不改任何游戏内容。

### 做法

- **渲染**：`xvfb-run -a godot --path . --resolution 1280x720 --rendering-driver opengl3 --audio-driver Dummy -s tests/capture_bigmap_chapters.gd -- --out-dir=res://artifacts/screens`。纯 `--headless` 是 dummy 渲染器、截不到图，沿用 `tests/capture_authority_ending.gd` 的离屏渲染先例。
- **挂载**：第 2–4 章仍不可达、计划也未接入 `game.gd`。截图脚本实例化真实 `scenes/main.tscn`，等第 1 章加载后，用 `integration_ch2/3/4_bigmap.gd` 同样的手法临时挂上对应章节的 `ChapterPlanData` + `chapter_N_bigmap_world.tscn`；拍完不写回任何产品默认值（`CHAPTER_PLAN_PATHS` / `MDS_WORLD_FILES` / 章节路由均未动）。
- **取景**：只把玩家放到作者地面/平台上的取景点、`Camera2D.reset_smoothing()`、必要时等电梯升到画面内；没有改数值、没有加作弊开关、没有改游戏逻辑。Boss 房间由真实 `_on_mds_room_loaded` 生成 Boss，玩家进入 `Arena` 触发范围后由真实 `_update_room_locks()` 触发入场，等 2.6 秒拍战斗中的一帧。
- 新增 `tests/capture_bigmap_chapters.gd`（随本程提交）；PNG 存 `artifacts/screens/`，按约定不提交。

### 文件清单与取景

| 文件 | 区/房间（计划尺寸） | 取景与画面内容 |
|---|---|---|
| `artifacts/screens/ch2/ch2_entry_panorama.png` | 呼吸废墟 · 入口 `ch2_entry`（2560×1440） | 玩家站在入口第二级平台 (1100,1168)；画面含左侧「来路」门视觉、底部舱口「前往 呼吸废墟 · 锈雾支路」标题（部分被底部 HUD 挡住）、平台阶梯、`breathing_ruins.png` 背景与章节 HUD。 |
| `artifacts/screens/ch2/ch2_well_shaft.png` | 呼吸废墟 · 纵井 `ch2_well`（2560×2160） | 玩家站在 `OneWay3` 单向落台 (480,1184)；左侧电梯升到画面内（约 y=1100），同帧可见单向落台、井深与背景。 |
| `artifacts/screens/ch2/ch2_boss_lung_bell.png` | 呼吸废墟 · 肺钟心室 `ch2_boss`（3840×2160） | 玩家站在右侧平台 (2420,2048)，Boss「肺钟守卫」在 `Arena` 生成并向玩家接近；画面含顶部 Boss 血条、入场句「钟摆停了一瞬，像在听你开口」、Boss 攻击预警与钟摆弹。 |
| `artifacts/screens/ch3/ch3_entry_panorama.png` | 无光海 · 无光海岸 `ch3_entry`（2560×1440） | 玩家站在入口第二级平台 (1100,1168)；蚀日、雨、左侧「来路」门、底部舱口「前往 无光海 · 静水支路」标题（部分被 HUD 挡住）、`lightless_sea.png` 背景。 |
| `artifacts/screens/ch3/ch3_well_shaft.png` | 无光海 · 深渊裂口 `ch3_well`（2560×2160） | 玩家站在 `OneWay3` (480,1184)；海面、帆船、蚀日与雨同框，是本次实测最能体现「无光海」氛围的区；左侧电梯与单向落台入画。 |
| `artifacts/screens/ch3/ch3_boss_last_reader.png` | 无光海 · 最后的读者 `ch3_boss`（3840×2160） | 玩家站在右侧平台 (2420,2048)，Boss「最后的读者」生成并接近；画面含 Boss 血条、入场句「最后的读者从海面抬起头」、镜面弹幕预警。 |
| `artifacts/screens/ch4/ch4_entry_theater.png` | 笑面剧场 · 剧场前厅 `ch4_entry`（2560×1440） | 玩家站在入口第二级平台 (1100,1168)；`smiling_theater.png` 平铺（吊灯/红幕/纸人观众/光柱）、左侧「来路」门、底部舱口「前往 笑面剧场 · 空座中庭」标题（部分被 HUD 挡住）。 |
| `artifacts/screens/ch4/ch4_well_backstage.png` | 笑面剧场 · 舞台侧廊 `ch4_well`（2560×2160） | 玩家站在 `OneWay3` (480,1184)；舞台巨书、观众席、吊灯与光柱同框；左侧电梯、单向落台入画。 |
| `artifacts/screens/ch4/ch4_boss_smiling_archivist.png` | 笑面剧场 · 最后的舞台 `ch4_boss`（3840×2160） | 玩家站在右侧平台 (2420,2048)，Boss「笑面史官」生成并接近；画面含 Boss 血条、入场句「观众席上的纸人一齐鼓掌」、Boss 自身血条与舞台背景。 |

### 核验结果

| 文件 | 尺寸 | 像素均值 | 暗像素占比 | 白像素占比 | 字节 |
|---|---|---|---|---|---|
| `ch2/ch2_entry_panorama.png` | 1280×720 | 46.5 | 0.7% | 0% | 1,655,702 |
| `ch2/ch2_well_shaft.png` | 1280×720 | 46.1 | 1.2% | 0% | 1,696,289 |
| `ch2/ch2_boss_lung_bell.png` | 1280×720 | 44.0 | 1.3% | 0% | 1,591,073 |
| `ch3/ch3_entry_panorama.png` | 1280×720 | 45.2 | 0.1% | 0% | 1,276,544 |
| `ch3/ch3_well_shaft.png` | 1280×720 | 35.1 | 0.1% | 0% | 1,260,107 |
| `ch3/ch3_boss_last_reader.png` | 1280×720 | 34.0 | 0.0% | 0% | 1,144,063 |
| `ch4/ch4_entry_theater.png` | 1280×720 | 38.9 | 0.1% | 0% | 1,400,724 |
| `ch4/ch4_well_backstage.png` | 1280×720 | 40.4 | 0.1% | 0% | 1,560,107 |
| `ch4/ch4_boss_smiling_archivist.png` | 1280×720 | 28.5 | 0.4% | 0% | 1,198,700 |

（暗像素 = 亮度 < 4；白像素 = 亮度 > 250；按 160×90 缩略图统计。）

### 截图中发现的问题（只记录，本程不修）

1. **底部 HUD 遮挡（对应待确认第 13 项）**：9 张的底部武器卡/控制条都盖住画面最下方约 80 px。Boss 三张里 Boss 与玩家的脚部被武器卡压住；入口三张里底部舱口的「前往 <区名>」标题也被盖住一部分。第 13 项原本记录的是第 2 章底部取景/HUD 遮挡，本程确认同样影响第 3、4 章。
2. **背景纵向平铺接缝**：大区背景图是 1536×864 的静态图，按房间高度纵向平铺。1440 高的入口区在屏幕 y≈144 有较浅接缝；2160 高的纵井/Boss 区更明显——`ch4_boss` 顶部约 290 px 是 `smiling_theater.png` 底部的黑色舞台地面，下一条瓦片从吊灯顶部重新开始，形成硬接缝；`ch2_boss` / `ch3_boss` 顶部同样能看到拼接线。
3. **`boss_background` 被静态背景挡住**：世界 JSON 的 `areas[...].boss_background` 已写 `spore_drift`（第 2 章）、`deep_water`（第 3 章）、`blood_moon`（第 4 章），但 `MDSBigRoom` 的静态背景 `z_index = -20` 在 MDS 动画背景 `z_index = -110` 之前，铺满房间的静态图把动画 Boss 背景完全遮住。三张 Boss 图里看不到 `deep_water` / `blood_moon` 动画层；第 3 章「海面」来自 `lightless_sea.png` 静态图而非 `deep_water`。与待确认第 15 项（第 3 章海面母题）相关但范围更大（三章 Boss 背景都受影响）。
4. **入口/枢纽区套用休整文案**：`ch2_entry` / `ch3_entry` / `ch4_entry` 这类没有 `Arena` 的大图房间会走「非书库 → 休整」分支，显示 `RestRoomData` 的一条通用文案并把目标设为「休整，或继续前进」。截图里分别是「墨迹未干的名字在墙角晾着。」「纸人把灯芯拨亮，等你开口。」「屋檐滴水，挑上的旧货都醒着。」；第 3 章入口出现「纸人」字样，读起来更像第 4 章剧场/档案馆的意象。属内容路由观察。
5. **电梯贴房间左缘**：纵井的电梯作者位置在房间 x=0..160，相机又被房间左边界夹住，所以纵井三张里电梯只以画面最左侧一条横线出现（能看出是电梯，但不醒目）。作者布局 + 相机夹取的取景限制，不是缺陷。
6. **Boss 取景**：Boss 生成在 `Arena` 局部 (110,-18)，玩家放在右侧平台后 Boss 从画面左中向玩家走来；2.6 秒那一帧能同时看到 Boss、玩家、Boss 血条、入场句与攻击预警，但 Boss 脚部仍在底部 HUD 后面（同第 1 条）。
7. **第 2 章入口背景与第 1 章色调接近**：`breathing_ruins.png` 是红月废墟，和第 1 章档案馆的既有背景色调相近；既有素材，不是本程改动，仅记录给监工判断样图代表性时参考。

### 不变项与边界

- **不变项**：`scripts/` / `scenes/` / `resources/` 零改动；`CHAPTER_PLAN_PATHS[2]/[3]` 仍空、`MDS_WORLD_FILES[2]/[3]` 仍指旧世界、旧第 2/3/4 章世界仍在；章节路由、`game.gd`、数值、电梯速度、相机/HUD、门逻辑、地图标题、敌人美术、战斗密度、`ch4_shortcut` 授予全部未动；第 2/3/4 章仍不可达。
- **未做**：未修截图里发现的问题；未做第 4 章门视觉/地图标题/敌人美术/Boss 4 机制扩展/舞台母题呈现层/战斗密度/`mask_enemy` / `seat_husk` 独立数值/阿砚同行；未碰待确认第 11–16 项（只记录现状，不新增条目、不定口径）；未新增移动能力、未改 NPC 立绘、未改 MDS 插件、未新绘美术；未做打包导出/安装器/签名/安卓/触屏。

## 第 4 章大图门视觉专项与敌人美术核查（第 62 程）

> 范围：第 4 章（笑面剧场）九区大图的表现/美术审计，口径对齐第 49 程对第 3 章
> 的先例：门视觉逐门核验、地图标题复核、敌人美术核查。只做测试与记录，不改门
> 逻辑、不接入 `game.gd`、不开放可达性、不碰待确认第 11–16 项。详细版见
> [第 4 章门视觉/敌人美术 session](docs/memory/sessions/2026-11-06-chapter4-gate-visual-enemy-art.md)。

- **前置核查**：`GateVisual` 由 `MDSBigRoom._add_gate_visuals()` 通用挂载；
  第 52 程 9 个第 4 章场景均为 `MDSBigRoom`、`auto_gates` 全开，22 扇门已被
  自动覆盖。世界文件事实：left/right/top/bot 各 5 + 中置 door 2；20 有向 +
  2 仅到达（`ch4_entry/shortcut_arrival`、`ch4_boss/left1`）；`ch4_elite/right1`
  进 Boss 不可返回；`ch4_hub/shortcut` 带 `requires = ["ch4_shortcut"]`、
  `MDSGateBarrier` 默认封闭。以上全部只读核查，未改。
- **逐门核验（22/22）**：每门 `GateVisual` 存在且可见、`marker.position ==
  Vector2.ZERO`、side 与世界文件一致、门扉/舱口在房间内、门底落在真实地面/
  台阶面（`floor_offset` 现算；侧门 90 px、`ch4_entry/shortcut_arrival` 16 px
  台阶面、bot 舱口 0）、标题非空且矩形被 `room_bounds.encloses()`、有向门
  `arrival == false`（「前往 <目标区名>」）、仅到达门 `arrival == true`
  （「来路」、无箭头）、纯 `Node2D` 零碰撞。逐门明细见 session。
- **新增断言**（`tests/integration_ch4_bigmap.gd`，+135）：① 侧门门扉墙侧边缘
  必须正好落在门位 x（向房间内展开）；② top/bot 96 px 舱口矩形两轴都不越出
  房间（既有断言只查竖向）；③ 世界文件侧直方图 == 运行时直方图、有向门 20、
  仅到达门恰为上述两扇。第 4 章集成 **4869 → 5004 断言 / 0 失败**。
- **真实缺陷**：**无**。第 49 程的 `caption_area` 夹取已覆盖第 4 章同类门位
  `ch4_well/top1`（x=80，标题夹到 x=0，不再越界）；`scripts/` / `scenes/` /
  `resources/` 零改动。
- **地图标题复核**：第 38 程 `CampaignData.region` 派生规则未动；第 4 章
  「笑面剧场地图」与第 1 章「档案馆地图」均由既有断言
  （`integration_ch4_bigmap.chapter_4_map_title`、`test_map_overlay` 的
  `map_title_chapter_1_unchanged` / `map_title_chapter_4_region`）锁定，本程
  复跑成立，未重复造断言、未改 `MapOverlay` / HUD。
- **敌人美术核查**：`ROOM_WAVES[3]` 现算 **7 种**（`mask_enemy`、`seat_husk`、
  `choir_summoner`、`page_swarm`、`mirror_sniper`、`typo_beast`、`ink_bomber`）
  ——全部专属 PNG、已在 `ENEMY_ART`、不在回退表、实际白 tint；缺失清单为空。
  `mask_enemy`/`seat_husk` 是美术变体（复用 `hanging_scribe.tscn`/
  `collapse_husk.tscn` 与对应 `.tres`，贴图各自独立；`collapse_husk` 自身走
  `blank_man` 回退，故 `seat_husk` 对照 `blank_man`）。第 50/59 程「8 种」=
  上述 7 种 + 旧第 4 章房间组额外使用的 `echo_enemy`（已有第 1 章美术、由
  CH1/CH3 清单锁定，`ROOM_WAVES[3]` 不含）。`tests/test_enemy_art.gd`
  **200 → 298 断言**（+98，审计集合由 `ROOM_WAVES[3]` 现算）；第 4 章集成
  六波真实区域逐个断言敌人专属 PNG + 白 tint（原先只显式查 `ch4_branch_a`）。
  未新增/修改任何贴图或场景美术。
- **不变项**：门位/模式/单向语义/`requires`/`MDSGateBarrier`/过渡目标未改；
  `CHAPTER_PLAN_PATHS[3]` 仍空、`MDS_WORLD_FILES[3]` 仍指旧世界、旧第 4 章
  9 房/17 门世界仍在；第 2/3/4 章仍不可达、第 4 章未接入 `game.gd`；未修
  第 60 程样图问题；未做 Boss 4 机制扩展/舞台母题/`ch4_shortcut` 授予/战斗密度/
  `mask_enemy`/`seat_husk` 独立数值/阿砚同行；第 11–16 项未碰、未新增条目。
- **下一程候选（只记录）**：第 60 程样图问题——底部 HUD 遮挡（第 13 项）、
  背景纵向平铺接缝、`boss_background` 被静态背景遮住（与第 15 项相关）、
  入口/枢纽套用休整文案、纵井电梯贴左缘、Boss 脚部被 HUD 压住（同第 13 项）、
  `breathing_ruins.png` 与第 1 章色调接近。与第 13/15 项相关的部分拍板前不施工、
  不定口径。

## 第 2–4 章大图样图问题修复（第 63 程，第 64 程接力核验收尾）

> 依据：第 60 程「样图截图」专节的问题 2（背景纵向平铺接缝）与问题 4（入口/枢纽套用休整文案）。第 63 程完成两项修复并重拍 9 张样图后进程中断（`.supervisor/session67.log` 仅一行 `[claude-code:unrecognized_model]`，无提交、状态文件未更新）；第 64 程核查在途改动、跑基线、复核截图并收尾。问题 1/3/5/6/7 不属本程范围（与待确认第 13/15 项相关或纯取景），未施工。

### 背景纵向平铺接缝（第 60 程问题 2）

- **成因**：大区静态背景是 1536×864 的绘画（顶部天空、底部地面，本身不可纵向平铺），原实现从房间顶部向下按 864 px 平铺。大区房间高 1440/2160，不是 864 的整数倍：最后一行是残瓦片，且相邻两行是「上一张的地面」直接接「下一张的天空」。`ch4_boss` 顶部约 290 px 的黑色舞台地面、`ch2_boss`/`ch3_boss` 顶部拼接线都由此而来。
- **修复**（`scripts/levels/mds_big_room.gd::_build_backdrop`）：改为以房间**底部**为锚、自下而上排瓦片——最底一行保持原方向，使绘画自己的地面线正好落在房间地面；其上每一行 `flip_v` 镜像，使上下相邻瓦片共用同一条边缘像素行（天空接天空），不再出现地面/天空硬接缝。`backdrop_rect_local()` 同步改为与 `room_bounds` 求交，报告实际可用覆盖（高房间顶部会溢出、被相机边界裁掉）。
- **验证**：9 张重截图目视无硬拼接线；对三张纵井图在唯一可见接缝行（屏幕 y=472）做行差量化：接缝行行差 2.6 / 0.5 / 3.8，低于同段中位数 3.9 / 1.3 / 4.4（同段真实美术/平台边缘可达 35–38），证明接缝处纹理连续。`test_big_room._test_backdrop_mirror_seams` 做像素级连续性断言（每个纵向相邻瓦片的接触边颜色相等，并验证接缝确实是边缘行而非简单重复）；三个大图集成套件逐区断言「底行正立且底边落在房间地面、奇数行镜像」。
- **取舍（记录）**：镜像会让同一幅画在纵向上对称重复（`ch2_well` 可取景到「双月」对称），这是在不拉伸、不重绘既有素材且素材本身不可平铺的前提下消除硬接缝的代价；比原来的天空/地面硬拼自然。未改素材、未改背景色调。

### 入口/枢纽休整文案路由（第 60 程问题 4）

- **成因**：`game.gd::_on_mds_room_loaded` 对「没有 `Arena`」的房间一律走非书库 → 休整分支：目标写「休整，或继续前进」并抽一条 `RestRoomData` 文案。第 2/3/4 章入口区既无战斗也无休整设施，却因此抽到商店/休整房文案（第 3 章入口甚至抽到「纸人…」这类偏第 4 章意象的句子）。
- **修复**：统计房间里的 `BenchCheckpoint`（`has_bench`）与既有 `_shops`；`rests_here := not big_map or has_bench or not _shops.is_empty()`。只有非大图（第 1 章保持原行为）或真正作者了长椅/商店的大图房间才走休整目标与文案；其余无 `Arena` 的大图房间目标只写「继续前进」且不抽 `RestRoomData`。书库分支不变。
- **验证**：三章入口断言目标 =「继续前进」且 `_rest_greeted` 不含入口区；三章枢纽（有 `Shop` + `Bench`）仍断言「休整，或继续前进」并抽到文案。截图复核：三张入口图右上目标均为「继续前进」，画面无休整提示。
- **未改**：`RestRoomData` 文案表、第 1 章全部房间行为、休整/商店/长椅机制与数值。

### 截图与核验（第 63 程重拍、第 64 程复核）

- 9 张 1280×720 PNG 于 2026-11-05 21:40–21:43 UTC 重拍（晚于产品改动 21:19/21:22、晚于截图脚本改动 21:38），存 `artifacts/screens/ch2|ch3|ch4/`，不提交。第 64 程复核：9 张齐全、尺寸 1280×720、非空、非全黑非全白（均值 32.1–56.5、暗像素 ≤ 0.6%、白像素 0%），玩家均在取景内。
- 截图脚本补一行 `hud.show_message("")`：真实主场景刚显示过第 1 章目标提示，挂载新章后清掉，避免样图混入别章文案；只改取景/核验，不改游戏逻辑。
- 修前 → 修后对照：入口三张由「休整，或继续前进」+ 别章休整句变为「继续前进」且无提示；`ch4_boss` 顶部约 290 px 黑的残瓦片地面带消失，画面上部恢复为剧场吊顶/红幕；`ch2_boss`/`ch3_boss` 顶部拼接线消失；纵井唯一可见接缝行纹理连续、无硬线。
- 未修事项（只记录）：问题 1/6（底部 HUD 遮挡、Boss 脚部被压）对应待确认第 13 项；问题 3（`boss_background` 被 `z_index=-20` 静态背景盖住）与第 15 项相关且范围更大；问题 5（电梯贴左缘）是作者布局 + 相机夹取的取景限制，非缺陷；问题 7（第 2 章入口背景与第 1 章色调接近）属既有素材记录。以上拍板前不动。

### 不变项与边界

- `CHAPTER_PLAN_PATHS[2]/[3]` 仍空、`MDS_WORLD_FILES[2]/[3]` 仍指旧世界、旧第 2/3/4 章世界仍在；章节路由、相机/HUD 边距与透明度、电梯速度、门逻辑、地图标题、敌人美术、战斗密度、`ch4_shortcut` 授予均未动；第 2/3/4 章仍不可达；待确认第 11–16 项未碰、未新增条目。
- 未做打包/导出/安装器/签名/安卓/触屏；未推送、未更新网页版。

## NPC 个人事件（第 65 程，叙事审计 E2 第一批）

> 依据：`docs/story-bible.md`「四位同行者 / 五位 NPC」、第 24 程叙事审计 A/E 节、现有 `NPCProfiles` / `TrustData` / `Profile.npc_trust` / Hub 对话基础设施。只做 demo 中可见的三名 Hub NPC（陆沉、阿砚、咕噜）；闻烬/白榆在 `hub.gd` 中不可见、`talk_to_npc` 直接返回，本程不设为可见、不写事件。只按圣经已有弧线写，每段对白依据的圣经原文要点见下。

### 圣经依据与事件节拍

| NPC | 圣经原文要点 | 本程事件节拍 |
|---|---|---|
| 陆沉 | 秘密：「他撕下三页名册，不是为了保护世界，而是为了保护自己不被写进『已死之人』那一栏。」弧光：「从『替昌子决定该读什么』到『承认自己也曾篡改』。」关键道具：「红色文件夹，里面是昌子最初的入职档案。」结局后：仁慈足够才把文件夹交给昌子 | 他取出红色文件夹，承认「已死之人」栏里出现自己的名字、撕页是为自保，承认一直替昌子决定该读什么；文件夹没有交给昌子（留给结局） |
| 阿砚 | 秘密：「他曾经是旧世界最后一座军械库的锻造之神。世界忘记他的神名后，他把自己降格成『守夜人』，因为守夜人不需要被记住。」弧光：「从『拒绝承认神格』到『愿意再为一个人烧一次炉』。」关键道具：「一把永远修不好的断页剑——其实是他给自己留的墓碑。」结局后：叫出真名才走出铁匠铺 | 他否认剑能修好、承认断页剑是给自己的碑；说旧世界最后一座军械库是他烧的最后一炉、改叫阿砚因为守夜人不需要名字；拒绝「神」，然后在冷炉膛里按出一点暗红：「只烧这一次……是给你。」不进入真名分支 |
| 咕噜 | 秘密：「它不是这个世界的生物，而是被烧掉的词堆里长出来的『记忆拾荒者』。它害怕的不是死，是没人再来买东西。」弧光：「从『什么都卖』到『有一件东西不卖』。」关键道具：「一只装着『永』字的玻璃瓶。」结局后：信任足够才「这个不卖，借你」 | 货架最里面的玻璃瓶装着「永」字；它说「那个不卖」，承认自己连「永」和「恒」都拆开卖过，但这只瓶子是第一次醒来时吞下的字；用「别死太早，你死了谁还来听我讲价」遮住害怕；瓶子没有送出（留给结局） |

### 触发条件与档位理由

| NPC | 事件 id | 信任档 | 门槛 | 章节进度 |
|---|---|---|---|---|
| 陆沉 | `luchen_red_folder` | 信任 | 6.0 | `Profile.demo_cleared = true` |
| 阿砚 | `ayan_furnace` | 托付 | 12.0 | `Profile.demo_cleared = true` |
| 咕噜 | `guru_bottle` | 熟悉 | 2.0 | `Profile.demo_cleared = true` |

- **章节进度 = `Profile.demo_cleared`**：Hub 在局外，`Profile` 没有更细的章节进度；`demo_cleared` 是唯一「完成过第 1 章 demo」的持久信号，且在 demo 内可达（通关 → 结局屏 → 返回 Hub）。`runs_completed` 含死亡，不作为章节进度。
- **陆沉 · 信任（6）**：该档既有态度句「有些页我本来不该给你看。但我想，你会替我记住。」正是承认篡改的关系基础；承认自己为自保撕页比日常闲聊重，低于托付又过早。
- **阿砚 · 托付（12）**：圣经弧光终点是「愿意再为一个人烧一次炉」，该档态度句「真名的事……等你准备好，再来问我一次」也把最深的话留在这里；再烧炉是「为一个人」，对应最深档；真名分支本程不做。
- **咕噜 · 熟悉（2）**：该档态度句「有些东西我不摆上架，只留给信得过的人」直接铺「有一件东西不卖」；这是它弧光的起点，熟悉即可，不需要托付。

### 实现方式

- 新增 `scripts/hub/npc_event_data.gd`（`NPCEventData`）：三名 NPC 的事件 id / 标题 / 关键道具名 / 最低信任档 / `requires_demo_cleared` / 对白行；`event_for()` 返回副本，`can_trigger(profile, npc_id)` 做一次性 + 档位 + 章节进度判定；闻烬/白榆/未知 id 无条目。
- `Profile` 新增 `npc_events: Array[String]` 与 `has_npc_event()` / `record_npc_event()`（首次返回 true）；存档写 `[npc] events`，读档缺省为空、跳过空串与重复 id，旧档无需迁移。
- `hub.gd::talk_to_npc()` 先查 `NPCEventData.can_trigger()`；可触发时用现有 `DialogueUI` 打开事件对白（替换该次常驻问候/态度/职能行），**读完最后一行才记录并保存**；中途 B/Esc 关闭或从事件页打开言灵不消耗事件。事件结束后咕噜不自动开商店；普通对话仍按原逻辑开商店。
- **零奖励**：事件不改残页/记忆碎片/信任/祝福/背包/经济/锻造/商店数值。关键道具只做对话节拍，不新增背包物品类型；物品机制缺口记录在下方「未做事项」。

### 测试结果

- 新增 `tests/test_npc_events.gd` **187 断言**：三事件存在/唯一/id/道具/档位、闻烬白榆无事件、`event_for` 返回副本；触发门槛（无信任/无进度/差 0.01 档不触发，达标触发，已看过不再触发，null/未知 id 安全）；零奖励；`[npc] events` 存档往返、重复保存不重复、旧档无键兼容；对白行数/非空/无占位符/唯一/提及关键道具/咕噜瓶子含「永」。
- `tests/integration_menus.gd` 新增 `_test_npc_personal_events`：真实 Hub 场景验证「只有信任、无章节进度不触发」；三事件分别触发、事件行替换常驻问候、读完记录一次、不扣碎片/不加信任；陆沉事件后下一次恢复普通问候；阿砚中途关闭不消耗、再谈重新触发；咕噜事件结束不弹商店、普通对话仍弹商店。**391 → 419 断言（+28）**，0 失败。
- 全量单元 **12773 → 12960 / 0**（+187，全部为新增 `test_npc_events`）；十一套集成 **894 / 102 / 613 / 207 / 113 / 59 / 419 / 45 / 2315 / 4358 / 5133** 全 0 失败（仅菜单 A/B +28，其余与第 64 程基线逐套件一致）；`--headless --import` / `--quit` 退出 0、`ERROR` 0；退出泄漏 10/10 clean；demo 像素资产 36 / 0。

### 未做事项（记录，不编号待确认）

- 结局文本加厚（E3：每个结局补五名 NPC 余味、「笑面史官身份」「最后一页」回收）——下一程候选。
- 闻烬/白榆的个人事件与可见性——待拍板；本程未设为可见、未写事件。
- 阿砚「叫出真名」完整分支（真名、锤子留在铁砧、第一次走出铁匠铺）——本程只到「再烧一次炉」。
- 关键道具的物品化（红色文件夹/玻璃瓶作为背包/收藏品）——本程按任务单只做对话节拍 + 事件标志位；若后续要物品机制，需另立物品类型与展示。
- 事件余味在结局中的回收（陆沉交付文件夹、咕噜「这个不卖，借你」、阿砚走出铁匠铺）——属 E3。

### 不变项与边界

- 第 1 章 9 房间/6 波次/事件/清房目标 6/结束流程、Hub 闲聊与关键词回应、信任数值与 `[npc] trust` 存档格式一字未改（只新增 `[npc] events`）；NPC 立绘未改；未新增背包物品类型、未改经济/锻造/商店数值。
- 第 2/3/4 章仍不可达；`CHAPTER_PLAN_PATHS[2]/[3]` 仍空、`MDS_WORLD_FILES[2]/[3]` 仍指旧世界；章节路由、相机/HUD、电梯速度、门逻辑、地图标题、敌人美术、战斗密度、`ch4_shortcut` 授予均未动。
- 待确认第 11–16 项未碰、未新增条目；未做打包/导出/安装器/签名/安卓/触屏；未推送、未更新网页版。

## 结局文本加厚（第 66 程，叙事审计 E3）

> 依据：`docs/story-bible.md`「结局（复原/焚毁档案/深渊回响/未完的注脚/记录中断）」「反派：笑面史官」「四位同行者 / 五位 NPC」、第三章节拍（最后的读者交出空白的最后一页）、第 24 程叙事审计 C/E 节、第 65 程 E2 个人事件。只写圣经已有的弧线与结局含义；不改 5 个结局 id、标题、现有 2 句正文、`ending_for` 判定、`Profile.record_ending` / `Profile.endings` 记录与存档格式。

### 「笑面史官身份」「最后一页」的圣经定义与回收

| 母题 | 圣经原文要点 | 回收方式 |
|---|---|---|
| 笑面史官身份 | 「身份：未来的昌子，或者说，是昌子所有可能版本中『最会写结局』的那一个。」「最终揭示：他的脸后面不是脸，是一页写满『昌子』的名字的纸。每一个名字都是一次失败的重来。」 | 每个结局的回收段（`CODAS`）都落到「脸后面那页写满昌子的纸」：复原把它合进名册、焚毁把它烧掉、深渊让它写满、未完把它压在名册底下、中断给它留空行 |
| 最后一页 | 第三章节拍：「他交出空白的最后一页，并说『故事需要有人翻页』」；笑面史官目标：「让昌子回到舞台上，替自己完成最后一页」；深渊结局：「昌子写下最后一页时，墨自己动了起来」 | 同一段回收里落到「最后一页」：复原没有撕、焚毁烧掉、深渊由昌子写下、未完仍空着、中断没写完 |

两处圣经都有明确定义，**无需记缺口**；回收段只使用上述定义，不新增身份或最后一页的内容。

### 五名 NPC 的结局余味（25 句）

#### 复原 restored（圣经：三页对齐、失踪者回到纸上；陆沉交文件夹、阿砚走出铁匠铺、咕噜瓶子空了、闻烬重写名字、白榆地图出现新路）

| NPC | 余味 | 圣经依据要点 |
|---|---|---|
| 陆沉 | 陆沉把红色文件夹推到昌子面前，这次没有合上。他说入职档案上的名字比你记得的完整，剩下的该由你自己读。 | 「结局 · 复原」内容「陆沉把红色文件夹交给昌子」；NPC 节「结局后：如果仁慈足够，他会把红色文件夹交给昌子」；E2 事件里他承认一直替昌子决定该读什么并合上文件夹，本句是弧光收束 |
| 阿砚 | 阿砚的炉子没有再熄。断页剑还靠在砧边，他不再说那是碑，只说等昌子下次来，再打一截新的剑脊。 | 弧光「从拒绝承认神格到愿意再为一个人烧一次炉」+ 关键道具「断页剑——其实是他给自己留的墓碑」；**不写「叫出真名/走出铁匠铺」**（该分支本程未做） |
| 咕噜 | 咕噜把玻璃瓶塞进昌子手里：这个不卖，借你。瓶子空了，它说「永」字已经用在该用的地方，账不用算。 | 「结局 · 复原」内容「咕噜的瓶子空了」；NPC 节「结局后：如果信任足够，它会把瓶子送给昌子，说『这个不卖，借你』」；E2「瓶子的账，等我哪天不在了再算」 |
| 闻烬 | 闻烬用那支断尖笔，在名册边角写了一次自己的名字。写完她把笔收起来，说这笔尖早该磨了。 | 「结局 · 复原」内容「闻烬重新写下自己的名字」；NPC 节「结局后：把笔尖磨好，重新写一次自己的名字」+ 关键道具断尖笔 |
| 白榆 | 白榆把那张没有终点的手绘地图铺开。地图边缘多出一条从未有过的路，他看了很久，说这回我陪你走一段。 | 「结局 · 复原」内容「白榆的地图出现一条新路」；NPC 节「结局后：地图上会出现一条从未有过的路，通向档案馆之外」+ 弧光「第一次和某个人一起走」 |

#### 焚毁档案 burned（圣经：名册烧了三天三夜，世界失去历史与用过去命令人的权力）

| NPC | 余味 | 圣经依据要点 |
|---|---|---|
| 陆沉 | 陆沉没有交出红色文件夹。火烧过档案馆时，他把它放在观众席第一排，像还给一个不会再来的自己。 | NPC 节「结局后：……否则它会出现在笑面剧场的观众席上」+ 焚毁结局「世界失去历史」 |
| 阿砚 | 火烧到铁匠铺时，阿砚先搬走了砧子，没管那把断页剑。他说碑烧了也好，省得有人对着一块铁念名字。 | 关键道具「断页剑是他给自己留的墓碑」+ 焚毁结局「世界失去历史」 |
| 咕噜 | 咕噜蹲在烧剩的词堆里翻找，货架空了。它说「永」字大概也烧没了，可只要还有人还价，它就还能再进一批货。 | 秘密「被烧掉的词堆里长出来的记忆拾荒者」「害怕没人再来买东西」+ 关键道具玻璃瓶 |
| 闻烬 | 闻烬没有拦那把火。她说改过的名字本来就不算数，烧了干净。断尖笔在她指间转了一圈，最后收进袖子里。 | 秘密「改写记录比杀人更彻底」+ 关键道具断尖笔 + 焚毁结局 |
| 白榆 | 白榆的地图被火烧掉一半。他看着剩下的一半说，没有终点也好，走到哪里都算新路。 | 秘密「所有没有走完的路」+ 关键道具「没有终点的手绘地图」+ 焚毁结局 |

#### 深渊回响 abyss（圣经：墨自己动起来；昌子成为污染的一部分、唯一还记得世界的人）

| NPC | 余味 | 圣经依据要点 |
|---|---|---|
| 陆沉 | 陆沉还想替昌子决定该读什么，可他已经读不懂昌子写下的句子。红色文件夹摊在桌上，入职档案被墨浸成一页空白。 | 弧光「从替昌子决定该读什么到承认自己也曾篡改」+ 深渊结局「昌子成为污染的一部分」 |
| 阿砚 | 阿砚的炉子还亮着，可他已经认不出推门进来的是谁。锤子举到一半又放下，像在等一句不会再有人说的真名。 | 秘密「世界忘记他的神名后降格成守夜人」+ 深渊结局；真名没有被叫出（未做分支），只写等待 |
| 咕噜 | 咕噜还在货架后面讲价，只是没有客人。它把玻璃瓶推给一团墨，说这个不卖——墨没有回答，它也没有收回去。 | 秘密「害怕的不是死，是没人再来买东西」+ 关键道具「永」字瓶 + 深渊结局 |
| 闻烬 | 闻烬在墨里改最后一个名字，改到一半停住了。她第一次承认，有些字被污染读过之后，连她也改不回去。 | 秘密「改写记录比杀人更彻底」+ 深渊结局「墨自己动了起来」 |
| 白榆 | 白榆还在画路，可画出的每一条都通向同一片墨。他把笔放下，说这条路他带不了，昌子得自己走。 | 秘密「所有没有走完的路」+ 深渊结局「昌子成为污染的一部分」 |

#### 未完的注脚 unfinished（圣经：名册补全但留一页空白；下一次潮水带来新名字）

| NPC | 余味 | 圣经依据要点 |
|---|---|---|
| 陆沉 | 陆沉把红色文件夹收回抽屉。他说等那一页空白补上再交给你，可他自己也知道，那一天大概不会来。 | NPC 节「结局后：如果仁慈足够……交给昌子」的未完成态 + 未完结局「仍有一页空白」 |
| 阿砚 | 阿砚把断页剑翻了个面，裂口朝里。他说等昌子把那一页空白补上，再决定这把剑是碑还是剑。 | 关键道具「断页剑是墓碑」+ 未完结局「仍有一页空白」 |
| 咕噜 | 咕噜把玻璃瓶往货架里面推了推，说瓶子的账等那一页空白补上再算。今天不谈这个。 | 关键道具玻璃瓶 + E2「瓶子的账，等我哪天不在了再算。今天不谈这个」+ 未完结局 |
| 闻烬 | 闻烬把断尖笔搁在名册上。她说等昌子想清楚要留下谁，再来找她改那一页——价钱照旧。 | 弧光「承认自己也想被记住」+ 情报贩子职能/价钱 + 未完结局 |
| 白榆 | 白榆把地图卷起来，故意留了一角空白。他说那一角等昌子自己走完，再画上去。 | 关键道具「没有终点的手绘地图」+ 未完结局「仍有一页空白」 |

#### 记录中断 interrupted（圣经：污染吞没这一页；名字淡去，记忆碎片已经写下）

| NPC | 余味 | 圣经依据要点 |
|---|---|---|
| 陆沉 | 陆沉翻开红色文件夹，昌子的入职档案停在半页。他没有往下读，只把文件夹合上，放回抽屉最里面。 | 关键道具「昌子最初的入职档案」+ 中断结局「昌子的名字从档案中淡去」+ E2 文件夹被合上 |
| 阿砚 | 阿砚把炉门关上，只留一线暗红。他说铺子今晚不开，等那个赊账的史官回来再说。 | 秘密「守夜人」+ E2「再烧一次炉」的暗红 + 中断结局「下一次你会记得更多」 |
| 咕噜 | 咕噜把玻璃瓶从货架上拿下来，又放回去。它说史官大人只是暂时赊账，账还挂在墙上，利息照算。 | 秘密「害怕没人再来买东西」+ 玻璃瓶 + 中断结局 |
| 闻烬 | 闻烬翻到昌子那一页，笔尖悬了很久，最终没有落下去。她说这一页她改不了，也不想改。 | 秘密「同门、篡改史官」+ 弧光「承认自己也想被记住」+ 中断结局 |
| 白榆 | 白榆把地图折好，放在昌子最后一次出发的地方。他说路不会消失，只是会等人。 | 秘密「所有没有走完的路」+ 关键词「路不会消失。它只是会等你走错几次之后，才愿意出现」+ 中断结局 |

### 每结局回收段（5 段，同时回收两个母题）

| 结局 | 回收段 | 圣经依据要点 |
|---|---|---|
| 复原 | 笑面史官的脸后面是一页写满「昌子」的纸，每一个名字都是一次失败的重来。复原之后，昌子把那页纸合进名册，最后一页没有撕掉——上面只留下自己选择记住的人。 | 反派节身份/最终揭示 + 复原余味「记得自己选择记住谁」 |
| 焚毁档案 | 最后一页和名册一起烧了。笑面史官那张写满「昌子」的脸在火里卷起来，每一个失败的名字都烧成同一个字。灰烬里没有人再需要结局。 | 焚毁「名册烧了三天三夜/世界失去历史」+ 反派身份 |
| 深渊回响 | 最后一页是昌子自己写的。墨动起来时，笑面史官的脸后面那页纸终于写满——上面每一个「昌子」都睁开了眼，却没有一个还叫昌子。 | 深渊「昌子写下最后一页时墨自己动了起来/成为污染的一部分」+ 反派身份 + 余味「没有昌子来读懂」 |
| 未完的注脚 | 最后一页还空着。笑面史官没有来催，只把那张写满「昌子」的纸压在名册底下，等下一次潮水带来新的名字。 | 未完「仍有一页空白/下一次潮水带来新名字」+ 反派身份 |
| 记录中断 | 最后一页没有写完。笑面史官的脸后面那页纸还留着空行，等下一次昌子醒来，再添一个名字。 | 中断「污染吞没这一页/下一次你会记得更多」+ 反派身份「每个名字都是一次失败的重来」 |

### 实现方式

- 新增 `scripts/data/ending_echo_data.gd`（`EndingEchoData`）：`ECHOES`（5 结局 × 5 NPC，一名 NPC 在一个结局里只有一句）、`CODAS`（每结局一段回收）、`ending_ids()` / `npc_ids()` / `npc_name()` / `has_ending()` / `echoes_for()`（返回副本）/ `echo_for()` / `coda_for()` / `display_text()`（「陆沉：……\n…\n\n<回收段>」，未知结局返回空串）。
- `scenes/ui/ending_screen.tscn` + `scripts/ui/ending_screen.gd`：Body 与 Reward 之间新增 `Echoes` Label（12 px、自动换行、默认隐藏）；`show_campaign_ending()` 按 `ending.id` 填 `EndingEchoData.display_text()`，无 id / 未知结局留空隐藏；旧 `show_ending()` 调用不变。
- `scripts/ui/ending_gallery_ui.gd`：每张结局卡正文后新增余味 Label；只有 `Profile.endings` 已解锁的条目显示余味与回收段，未解锁仍是原 `？？？` / `尚未记录。走过不同的选择，这一页会自己出现。` 占位；`get_entry_text()` 已解锁时追加余味，锁定条目不返回任何余味。
- 余味只在对应结局达成后展示：结束屏只拿到刚达成的 `ending`；画廊按 `Profile.endings` 的 id 判定。
- `CampaignData.ENDINGS` / `ending_for`、`Profile.record_ending` / `endings` 与存档、画廊解锁/占位规则均未改（只新增文本数据与展示读取）。

### 测试结果

- 新增 `tests/test_ending_echoes.gd` **469 断言**：五结局 × 五 NPC 齐全且唯一、每结局恰好 5 句、`echoes_for()` 返回副本、未知 id/未知 NPC 安全；文本非空/无首尾空白/含 NPC 名/句末标点/无占位符（TODO/TBD/%s/占位/待补/待定/？？？）/25 句全局唯一；主题对应（复原咕噜含「这个不卖，借你」、陆沉含文件夹、闻烬含「自己的名字」、白榆含「路」；焚毁五句都含火/烧；每段回收都含「最后一页」与「笑面史官」）；真实 `ending_screen.tscn` 的 `Echoes` 节点、深渊余味显示且不串复原、正文仍以原 `body` 开头、切换结局整块替换、`show_ending()`/未知结局为空；画廊已解锁显示、锁定不泄露、未知旧 id 不解锁；`progress/endings` 仍只写 id、存档不含余味文本、重载 id 不变；5 个 id/标题/现有正文逐字锁定、`ending_for` 五分支不变。
- 全量单元 **12960 → 13429 / 0**（+469，全部为新增 `test_ending_echoes.gd`）；十一套集成复跑全 0 失败，数字与基线逐套件一致（894 / 102 / 613 / 207 / 113 / 59 / 419 / 45 / 2315 / 4358 / 5133）；`--headless --import` / `--quit` 退出 0、`ERROR` 0；退出泄漏 10/10 clean；demo 像素资产 36 / 0。

### 未做事项（记录，不编号待确认）

- 闻烬/白榆的可见性与个人事件——待拍板；本程只在结局余味里按圣经弧线写两人，没有设为可见、没有写 Hub 事件。
- 阿砚「叫出真名」完整分支（真名、锤子留在铁砧、第一次走出铁匠铺）——余味只写到「愿意再为一个人烧一次炉」，没有写成已经叫出真名。
- 关键道具的物品化（红色文件夹/玻璃瓶/断尖笔/手绘地图进背包或收藏）。
- 结局余味的配音、逐 NPC 结局插画或独立结局场景（本程只做文本与展示读取）。
- 隐藏结局「换位」不在 5 个结局 id 内，未做。

### 不变项与边界

- `CampaignData.ENDINGS` 的 5 个 id、标题、现有两句正文与 `ending_for` 判定未改；`Profile.record_ending` / `Profile.endings` 的记录、去重与存档格式未改；结局画廊解锁/占位规则未改。
- 第 1 章 9 房间/6 波次/事件/清房目标 6/结束流程、Hub 闲聊与关键词回应、信任数值与 `[npc] trust`/`[npc] events` 存档格式、NPC 立绘、经济/锻造/商店数值均未改。
- 第 2/3/4 章仍不可达；`CHAPTER_PLAN_PATHS` / `MDS_WORLD_FILES`、章节路由、相机/HUD、电梯速度、门逻辑、地图标题、敌人美术、战斗密度、`ch4_shortcut` 授予均未动。
- 待确认第 11–16 项未碰、未新增条目；未推送、未更新网页版。

### 接力收尾（第 67 程）

- 第 66 程进程在收尾前死亡（`.supervisor/session70.log` 只有模型警告与一行
  「等待第 2/3/4 章三套大地图集成」提示，无提交）；本程按 brief71 先独立复核
  在途改动：余味只按结局 `id` 读取、旧调用/未知结局整块留空、画廊只对
  `Profile.endings` 已解锁条目显示、5 个结局 id/标题/正文/`ending_for` 判定/
  `Profile.endings` 记录与存档格式均未改——未发现实现缺陷，未返工。
- 基线复跑（Godot 4.7.stable.official.5b4e0cb0f）：`--headless --import` /
  `--quit` 退出 0、`ERROR` 0；全量单元 **13429 / 0**（与第 66 程自称一致）；
  十一套集成 **894 / 102 / 613 / 207 / 113 / 59 / 419 / 45 / 2315 / 4358 /
  5133** 全 0 失败（逐套件与第 65/66 程基线一致，三个大图套件均跑完）；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。
- 本程只做复核、复跑与按项提交，未开新功能、未改产品行为；收尾工作区干净。
  提交 hash 见下条「本程提交」。
- 本程提交：`ce4fcab` feat: thicken the five endings with NPC echoes and codas
  （`EndingEchoData`、结束屏 `Echoes`、画廊已解锁展示）；`0e60cdb` test: lock
  the ending echoes, gallery gating and save format（`test_ending_echoes.gd`
  469 断言）；文档提交 `51716ba` docs: record the ending text thickening pass
  （本状态文件、session 文档、记忆索引）。

## 待用户确认

第 35 程的两个歧义（Boss 2 数值、第 2 章末界面/结局记录）已按采用口径记录并用测试锁定，见本程日志与 ADR；不是待拍板项。第 36 程验收发现两项需要监工/用户拍板的内容口径，见第 11/12 项；在拍板前不施工、不猜测。第 37 程只新增第 13 项（大区底部相机取景/HUD 遮挡），只记录未施工。第 38 程未新增待拍板项。第 39 程只核查第 3 章，新增第 14–16 项（视野压缩、海面母题、捷径来源），均为第 3 章施工前需定、本程未施工未猜测。第 40 程只做第 3 章计划/图骨架，未新增待拍板项，第 14/15/16 项在计划与夹具里只留注释、未实现。第 11（`ch2_shortcut` 获取来源）、12（电梯节奏）、13（大区底部相机/HUD）仍开放，本程均未施工、未猜测。第 41 程只做第 3 章真实大区世界结构层，未新增待拍板项；第 14/15/16 项在真实世界里仍留空（无视野压缩、无 sea 层、捷径屏障保持封闭），未实现、未猜测。第 42 程只做第 3 章内容数据层第 1 步，未新增待拍板项；第 14/15/16 项仍未实现（无视野压缩、无 sea 层、未新增任何 `ch3_shortcut` 授予），第 11/12/13 项未碰。第 43 程只做第 3 章波次接线，未新增待拍板项；第 14/15/16 项仍留空（未实现视野压缩、未加 sea 层、未新增任何 `ch3_shortcut` 授予来源），第 11/12/13 项未碰，章末自动进第 4 章的缺口未改。第 44 程只做第 3 章事件区真实自动触发（沿用第 34 程通用分支、测试层驱动，`CHAPTER_PLAN_PATHS[2]` 仍空），未新增待拍板项；第 14/15/16 项仍留空（未实现视野压缩、未加 sea 层、未新增任何 `ch3_shortcut` 授予来源），第 11/12/13 项未碰，章末自动进第 4 章的缺口未改。第 45 程只做第 3 章 Boss 3 独特机制与计划 `boss_scene` 路由（沿用 Boss 2 做法、数值为暂定口径并由测试锁定，`CHAPTER_PLAN_PATHS[2]` 仍空、章节路由与章末流程未改），未新增待拍板项；第 14/15/16 项仍留空（未实现视野压缩、未加 sea 层、未新增任何 `ch3_shortcut` 授予来源），第 11/12/13 项未碰，章末自动进第 4 章的缺口未改。第 46 程只做第 3 章章末收口（`_complete_chapter` 新增 `_chapter == 2` 停章分支，`CHAPTER_PLAN_PATHS[2]` 仍空、章节路由与可达性未改，未新编剧情文本），未新增待拍板项；第 14/15/16 项仍留空（未实现视野压缩、未加 sea 层、未新增任何 `ch3_shortcut` 授予来源），第 11/12/13 项未碰；第 3 章末自动进第 4 章的缺口已由本程收口（停在第 3 章），第 3 章仍不可达。第 47 程因 Magpie 网关中断夭折，未产出任何结论、未新增待拍板项。第 48 程只做第 3 章大地图系统验收（新增 `tests/integration_ch3_bigmap.gd` 3424 断言，未改产品代码、未新增 `ch3_shortcut` 授予、未实现视野压缩/sea 层、未改电梯速度/相机/HUD），未新增待拍板项；第 14/15/16 项只记录现状，第 11/12/13 项未碰，第 3 章仍未接入 `game.gd`、仍不可达。第 49 程只做第 3 章大图门视觉专项与敌人美术核查（纯表现层 + 测试；未新增/修改敌人贴图，未新增 `ch3_shortcut` 授予、未实现视野压缩/sea 层、未改电梯速度/相机/HUD、未改门逻辑/门位/单向/条件门/过渡目标），未新增待拍板项；第 14/15/16 项仍留空，第 11/12/13 项未碰，第 3 章仍未接入 `game.gd`、仍不可达。第 50 程只做第 4 章大地图可行性核查（只查不施工，未改可达性/章节路由/任何数值、未新建内容、未新增测试与产品代码），未新增待拍板项；第 4 章特有的需拍板事项只记为专节「开放问题候选」，不擅自编号、不擅自决定，是否新增「待用户确认」条目由监工在验收时定。第 51 程只做第 4 章计划与图骨架（只做数据层与测试夹具；计划未接入 `game.gd`、未建真实大区世界/房间、未写 `Ch4EventData`/权柄池/波次/Boss 文案/机制，未新增任何 `ch4_shortcut` 授予，未改舞台表现/战斗密度/`mask_enemy`/`seat_husk` 数值、未改章末流程），未新增待拍板项；第 50 程专节 E 的开放问题候选仍只记录、不编号，第 11–16 项仍未施工、未猜测。第 52 程只做第 4 章真实大区世界结构层（世界未接入 `game.gd`、未写 `Ch4EventData`/权柄池/波次/Boss 文案与机制、未新增 `ch4_shortcut` 授予、未改舞台表现/战斗密度/`mask_enemy`/`seat_husk` 数值/章末流程），未新增待拍板项；第 50 程专节 E 的舞台母题/`ch4_shortcut` 来源/事件区/Boss 4 机制范围/战斗密度/`mask_enemy`/`seat_husk` 独立数值仍只记录、未拍板、未施工，第 11–16 项也未碰。第 53 程只做第 4 章内容数据层第 1 步（`Ch4EventData`/权柄池/Boss 文案；计划仍不路由、世界仍不被 `game.gd` 引用，未做波次接线/事件触发/Boss 4 机制/可达性），未新增待拍板项；第 50 程专节 E 的开放问题候选仍只记录、不编号，第 11–16 项也未碰。第 54 程只做第 4 章波次接线（计划 `wave` 按遭遇节点 id 接 `ROOM_WAVES[3]` 六波、`content_pending` 清零；计划仍不路由、世界仍不被 `game.gd` 引用，未做事件触发/Boss 4 机制/可达性），未新增待拍板项；第 50 程专节 E 的舞台母题/`ch4_shortcut` 来源/事件区/Boss 4 机制范围/战斗密度/`mask_enemy`/`seat_husk` 独立数值仍只记录、未拍板、未施工，第 11–16 项也未碰。第 56 程只做第 4 章事件区真实自动触发验证（沿用第 34/44 程通用大图区域分支、测试层驱动；计划仍不路由、世界仍不被 `game.gd` 引用，未做 Boss 4 机制/`boss_scene`、第 4 章大图验收与可达性），未新增待拍板项；第 50 程专节 E 的开放问题候选仍只记录、不编号，第 11–16 项也未碰。第 57 程只做第 4 章 Boss 4 机制与 `boss_scene` 路由（计划指向既有 `smiling_archivist.tscn`、既有机制与数值由测试锁定；计划仍不路由、世界仍不被 `game.gd` 引用，未改章节路由/章末流程，未做机制扩展/第 4 章大图验收/可达性），未新增待拍板项；第 50 程专节 E 的开放问题候选（含 Boss 4 机制扩展范围）仍只记录、不编号，第 11–16 项也未碰。第 58 程只做第 4 章章末收口（章末流程与测试层；计划仍不路由、世界仍不被 `game.gd` 引用，未改可达性/章节路由/Boss 4 机制/数值/波次/事件/章末文本，未新编剧情、未新设选项），未新增待拍板项；第 50 程专节 E 的开放问题候选（含 Boss 4 机制扩展范围）仍只记录、不编号，第 11–16 项也未碰。第 59 程只做第 4 章大地图系统验收（只跑/补验收脚本并记录，未改产品代码；计划仍不路由、世界仍不被 `game.gd` 引用，未改可达性/章节路由/门视觉/地图标题/敌人美术/战斗密度/电梯速度/相机/HUD，未新增 `ch4_shortcut` 授予），未新增待拍板项；第 50 程专节 E 的开放问题候选（含 Boss 4 机制扩展范围、舞台母题呈现层、`ch4_shortcut` 来源、战斗密度、`mask_enemy`/`seat_husk` 独立数值）仍只记录、不编号，第 11–16 项也未碰。第 60 程只做第 2–4 章样图截图（只截图、只记录；未改产品代码/场景/资源，未改可达性/章节路由/`CHAPTER_PLAN_PATHS`/`MDS_WORLD_FILES`，未修截图里发现的问题），未新增待拍板项；截图里与第 13/15 项相关或超出其范围的观察只记录现状，不新增「待用户确认」条目、不定口径，第 11–16 项仍开放、未施工。第 62 程只做第 4 章大图门视觉专项与敌人美术核查（纯表现层测试与记录；未改产品代码、未改门逻辑/门位/单向/条件门/过渡目标、未改地图标题规则/HUD、未新绘或修改任何敌人贴图，未改可达性/章节路由/`CHAPTER_PLAN_PATHS`/`MDS_WORLD_FILES`，未修第 60 程样图问题），未新增待拍板项；第 60 程样图问题只记为下一程候选，与第 13/15 项相关的部分拍板前不施工、不定口径，第 11–16 项仍开放、未施工。第 63/64 程只修第 60 程样图问题中的背景纵向接缝与入口休整文案路由（表现/文案路由修复 + 截图复核与记录），未新增待拍板项；与第 13/15 项相关的问题（底部 HUD 遮挡、`boss_background` 被静态背景遮住）仍未施工、未定口径，第 11–16 项仍开放、未施工。第 67 程只做接力复核、基线复跑与按项提交（未改产品行为、未改可达性或章节路由），未新增待拍板项；第 11–16 项仍未碰、未施工。第 79 程（brief83，第 3 章可达性接线）在启动时因 `[claude-code:unrecognized_model]` 死亡（零产出、无提交）；第 80 程（brief84）为接力全新重跑，只做第 3 章可达性接线第 1 步（章节路由 + 章末分支），未新增待拍板项；第 11–16 项仍未碰、未施工。第 89/90 程（brief93/94）基线跑绿后中途中断（第 97 程核对日志更正旧记录；零提交、无扫描结论）；第 91 程（brief95）按 `.supervisor/DECISIONS.md` 2026-11-07 09:45 的监工拍板全新开工，只做第 4 章可达性接线第 1 步（章节路由 + 章末分支），未新增待拍板项；第 50 程专节 E 的开放问题候选（舞台母题呈现层、`ch4_shortcut` 来源、Boss 4 机制扩展、战斗密度、`mask_enemy`/`seat_husk` 独立数值）仍只记录、未编号、未施工，第 11–16 项仍未碰、未施工。第 97 程为全新重跑，只做全流程 1→4 集成验收（新增链路测试 + 修 1 项死 Boss 房重锁缺陷 + 删第 96 程遗留探针），未改章节计划/波次/事件文案/Boss 数值与机制、未改编年史内容与 `ending_for`、未新增任何捷径授予、未改相机/HUD/电梯/门逻辑，未新增待拍板项；第 11–16 项仍未碰、未施工；第 60 程样图问题1/3/5/6/7 维持原结论。README 四处过期口径只记录、未改（按第 81 程先例单独一程）。第 99 程（brief103）只更新仓库根 `README.md` 的口径（可玩范围第 1–4 章、删「已建成但未开放」、五结局全可达 + 判定在战役结束、数字 13,551/14,985，并改正武器/遗物池、NPC 事件闸门、第 4 章插画范围三处旧口径；保留捷径无授予来源的说明），未改游戏代码/场景/资源/测试/配置、章节路由与可达性、存档形状、版本号，未新增待拍板项；第 11–16 项仍未碰、未施工。

1. ~~**Windows 发行形态**~~：已由用户拍板（2026-11-03）：正式发行（代码签名 + 安装器）推迟到很久以后；第 3 程的安装器脚本与签名文档留档，不扩展、不删除、现阶段不做编译验证。当前无发行阻塞项。
2. ~~**封闭试玩安排**~~：已由用户拍板（2026-11-03）：搁置，不组织、不冻结功能。
3. ~~**T17 内容扩展**~~：已由用户拍板（2026-11-03）：属完整版内容，排在 demo 收尾清单之后推进（吞噬/归档权柄、信任分层、结局画廊、Boss 2–4 机制）。
4. ~~**v1 存档兼容**~~：已由用户拍板（2026-11-03）：不猜测还原，保留原始字符串但不展示、不参与逻辑；本程已实现并补测试。
5. ~~**SAPI 配音**~~：已由用户拍板（2026-11-03）：当前阶段关闭 SAPI，只用字幕；代码与资源保留不删。
6. ~~**第 2–4 章**~~：已由用户拍板（2026-11-03）：维持「代码保留但 demo 不可达」，等 Windows 主体达标后再排入完整版内容制作。
7. ~~**暂停菜单里打开设置后关闭的去向**~~：已由监工拍板（2026-11-04，`.supervisor/DECISIONS.md`）：关闭设置返回暂停菜单并把焦点还给打开设置前选中的暂停菜单项，不直接恢复游戏。本程任务 2 已按此口径实现并补真实手柄/键盘断言，详见本程日志。
8. ~~**标题页有局内存档时的首帧焦点**~~：已由监工拍板并实现（2026-11-04，本程任务 2）。有局内存档时首帧焦点落在「继续本局」，无存档维持「继续旅程/开始旅程」；按 A 仍只关闭标题并续玩/进入 Hub，不立刻开始新局、不覆盖检查点。真实键盘与手柄断言已并入 `tests/integration_menus.gd`。不再是开放问题。
9. ~~**大地图形态的口径**~~：**已由监工拍板（见 `.supervisor/DECISIONS.md`「监工拍板（2026-11-04 深夜）：大地图两项口径」）：第 9 项定为「大区连通图」**——第 2–4 章大地图 = 6–9 个大区（MDS room）组成的连通图 + 门/短过渡，图内可回环、有纵深；不做字面意义的单场景无缝大图。第 27/28/29 程均按此口径施工，不再悬置。
10. ~~**垂直交通是否允许新增移动能力**~~：**已由监工拍板（见同一节）：第 10 项定为 A「不新增移动能力」**——不加二段跳/蹬墙跳/攀爬；纵向交通用台阶、电梯/移动平台、单向落台与 top/bot 门实现。第 29 程的单向落台「下+跳」下落穿过使用现有输入动作，属于单向落台道具行为，不是新增移动能力；第 27/28/29 程均未新增任何移动能力。
11. **第 2 章捷径 `ch2_shortcut` 的获取来源（开放问题）**：当前只有测试通过 `grant_ability("ch2_shortcut")` 授予，游戏内没有获得它的交互/事件/道具。开放第 2 章可达性前需要定：是放在 Hub NPC（信任/交易）、支路事件奖励、精英区掉落，还是书库探索奖励？不同选择会改第 2 章内容与节奏，本程未实现、未猜测。
12. **第 2 章电梯/移动平台的节奏（开放问题）**：`ch2_branch_b` 与纵向井的 `MovingPlatform` 作者速度当前为 70 px/s，乘行约 19 秒 / 29 秒。是保留慢速（强调纵向尺度/氛围）还是提高到 120–160 px/s（更紧凑）？属于手感/节奏口径，本程只验证通行，未改数值。
13. **大区底部相机取景与 HUD 遮挡（开放问题，第 37 程记录）**：第 2 章大图房间的相机限制等于房间边界，玩家站在区底（如 `ch2_entry` y≈1408）时屏幕纵向取景会让下半身落在底部 HUD 面板之后；自动门的地面舱口也会被同一面板遮住。可选口径：给大图相机加底部安全边距/垂直偏移，或调整 HUD 面板高度/透明度，或维持现状接受遮挡。属取景/UI 口径，本程只做门视觉与出生点，未改相机或 HUD，未猜测。
14. **第 3 章「视野压缩」机制口径（开放问题，第 39 程记录）**：GDD §11 把「污染、视野压缩」列为无光海机制，但仓库当前没有任何 darkness/vignette/光照半径/视野遮罩实现，第 3 章世界 `room_darkness=false`。大区管线不会自动提供；需定是否实现、用什么口径（MDS `room_darkness`/暗角/光照半径/与污染联动），再排期。本程只核查，未设计、未实现、未改世界场景。
15. **第 3 章大图海面母题（开放问题，第 39 程记录）**：现有 `LivingBackdrop(sea=true)` 的海面线、波光、漂浮纸屑与塔影只属于 `MDSChapterRoom`；大区管线只有平铺静态背景 + `BigRoomAmbient` 的 motes/embers，没有 sea 层。第 3 章大图是否保留该层、以何种方式呈现（新 ambient/背景层，或接受损失），需拍板。本程只记录，未设计、未施工。
16. **第 3 章捷径 `ch3_shortcut` 获取来源（开放问题，第 39 程记录）**：现有 `ch3_rest`→`ch3_02` 是无条件交互门；若第 3 章大图计划写 `shortcuts`，`MDSGateBarrier` 需要一个 ability id 和游戏内授予来源（Hub NPC/事件/精英/书库等）。来源选择会改第 3 章内容与节奏，本程未实现、未猜测；与第 11 项同类。

## 待用户处理（本机事务，不是设计拍板项）

- ~~**GitHub `main` 推送缺 4 个二进制文件**~~（第 99 程记录 → **第 101 程已解除**）：
  四张第 2 章敌人精灵 `breath_hound.png` / `lung_moth.png` / `rust_whisperer.png` /
  `collapse_husk.png` 已由用户授权、经助理用 GitHub 网页端推到 `main`，远程提交
  **`90a1960`**（父提交 `39c2b89` = v0.12.0 提交），文件夹列表已核验。
  **推送不再被二进制挡住**：剩余的只是文本改动，待监工在树干净、测试全绿、无会话在跑时
  补推，并同步更新网页版（当前网页版仍在 `34bcdd7`，第 99 程只改 README、不涉及游戏本体，
  故无需重推）。本程不碰推送、不更新网页版、不创建 Release。

## 例行扫描（第 68 程）

> 依据 brief72 / `.supervisor/DECISIONS.md` 的收口规则；本程只做例行扫描与
> 「扫描发现的产品行为缺陷」修复，不开新功能、不碰待确认第 11–16 项、
> 不改可达性/章节路由/结局与存档格式。

### 任务 0 · 基线核验（HEAD `250bcd6`，Godot 4.7.stable.official.5b4e0cb0f）

- `--headless --path . --import` / `--headless --path . --quit` 退出 0、`ERROR` 0。
- 单元 `tests/run_tests.gd` **13429 / 0**（与第 67 程逐字一致）。
- 十一套集成全部跑完，与第 67 程逐套件一致、全 0 失败、各日志 `ERROR` 0：
  `integration_playability` **894** / `integration_ch1_demo` **102** /
  `integration_run_save` **613** / `integration_gamepad` **207** /
  `integration_ui_prompts` **113** / `integration_ch1_event` **59** /
  `integration_menus` **419** / `integration_ai_settings` **45** /
  `integration_ch2_bigmap` **2315** / `integration_ch3_bigmap` **4358** /
  `integration_ch4_bigmap` **5133**。
- `tests/check_exit_clean.sh <godot> 10` → **10/10 clean**；
  `tests/check_pixel_assets.py --demo` → **36 / 0**。
- 结论：基线无漂移，可施工；本程全程未出现 Magpie 网关中断。

### 扫描面逐项结论

1. **关闭回退（各覆盖页 → 上一层/焦点）——未发现新缺陷。**
   逐层核对并复用既有集成：暂停 → 设置 → 子页（AI/键位/帮助）关闭时先退子页、
   再退设置、最后回暂停并还原打开设置前的焦点（`_pause_return_*` 链路，
   `integration_menus` 的 B/Esc/Start 与设置子页断言）；背包/图鉴/帮助/地图/
   商店/事件页/权柄/归档/奖励/结局屏/画廊均有 `ui_cancel`（手柄 B）与键盘
   等价出口；权柄/归档/奖励是显式必选模态，B/Esc 只被吞掉、不关页
   （`game.gd` 的 `_input` 分支）。从暂停进入设置后再按键切换到别的页面会
   清掉 `_pause_return_overlay`、关闭后直接回游戏——这是 `_toggle_overlay`
   注释写明的「页面并列替换」口径，不是死路，未按缺陷处理。
2. **焦点（标题/暂停/子页/商店/事件/对话）——未发现新缺陷。**
   标题有/无局内存档分别聚焦「继续本局」/「开始旅程」
   （`integration_menus`、`integration_run_save` 覆盖）；暂停菜单打开即抓
   可用项；设置子页关闭把焦点还给打开它的按钮；商店/事件/对话/画廊打开
   即抓首个可点项、关闭还原；键盘与手柄切换由 `GameFlow.input_device_changed`
   统一驱动提示与焦点，`integration_gamepad` 207 断言复跑 0 失败。
3. **存档边界（run save 写盘/续玩/坏档）——未发现新缺陷。**
   `RunSave._has_valid_shape` 覆盖 `[run]/[inventory]/[progress]/[world]/
   [authority]/[mds]` 的全部写出键（含第 27 程新增的按节点 id 列表、第 29 程
   的 `frenzy`、第 25 程的权柄使用位）；`_restore_*` 对类型异常做兜底转换；
   `save_run_now()` 在死亡/结局/奖励页/非 MDS 时不写，失焦与关窗分别走
   `NOTIFICATION_APPLICATION_FOCUS_OUT`（先保存再开暂停）与
   `NOTIFICATION_WM_CLOSE_REQUEST`（`save_run_on_exit`）；死亡先清档再开归档
   模态（`_death_committed`），胜利保留 Boss 已死检查点直到 `Flow.end_run`
   清档；「Boss 已死但权柄未选」在续玩时由 `_resume_boss_aftermath` 重新
   授予权柄。`integration_run_save` 613 断言复跑 0 失败。
4. **性能（第 1 章 9 房间 + Hub 冷/热、门过渡、Boss 战帧）——只记录，未发现
   需要处理的产品性能缺陷。** 本程临时探针（测后删除）在真实主场景内实测：
   - Hub 冷加载 3 次：`load` **971.8 / 1095.2 / 1064.1 ms**、`instantiate`
     **28.0 / 28.9 / 5.2 ms**、`_ready` + 首帧 **552.7 / 502.3 / 480.8 ms**；
     Hub 60 帧 avg **8.09–8.12 ms**、p95 **8.53–8.63**、max **8.60–9.86**。
   - `main.tscn` 冷加载 3 次：`load` **2023.5 / 2127.8 / 2077.4 ms**、
     `instantiate` **6.1–12.1 ms**、`_ready` + 首帧 **672.4–684.7 ms**。
   - 第 1 章首房共 7 个 120 帧窗口（4 次运行）：avg 全部 **8.33 ms**
     （120 FPS 预算 8.33）、p95 **8.67–8.79**；5 个窗口 max 8.83–10.50，
     2 个首次进房窗口出现一次性 20.56 / 16.17 ms 尖峰，紧随其后的窗口
     回落到 9.77–10.00，无可复现持续掉帧。
   - 门过渡 `ch1_01.right1 → ch1_02`（作者 0.2 s 淡出+淡入）：
     **226.6 / 226.8 / 231.9 / 240.0 ms**（与第 2–4 章 228–244 ms 同量级）。
   - 逐房原始构建（`fade_time = 0`，首次/缓存）：`ch1_01` 5.5/5.6、
     `ch1_02` 5.5/15.1、`ch1_03` 13.5/12.1、`ch1_04` 7.0/5.9、`ch1_05`
     5.1/5.3、`ch1_06` 5.8/5.7、`ch1_rest` 17.6/10.7、`ch1_boss`
     **77.4/37.0**、`ch1_vault` 23.9/9.9 ms；最重的 Boss 房冷建与第 4 章
     Boss（71.4–79.7）同量级。
   - Boss 战 120 帧：avg **8.33**、p95 **8.72–8.81**、max **8.84–12.51**。
   - 对照第 21 程基线（冷启动到标题 1625/1689/2071 ms、Hub `load`
     585–734 ms、Hub `_ready` 413–467 ms、`main.tscn` 约 2.9 s、首房 avg
     8.26–8.31/p95 8.64–8.71）：帧间隔与门过渡无退化；Hub `load` 本次偏高、
     `main.tscn` 偏低，两者合计与基线同量级，符合开发态首次脚本编译/文件
     缓存差异，未定位到产品侧持续退化，按任务单不做优化改动。
5. **文案（第 1 章 + Hub）——发现并修复 1 项。**
   缺陷：档案馆升级已到 demo 上限 Lv.10 时，行仍显示「升级」+ 价格且可点，
   点击返回「记忆碎片不足：需要 403，你只有 999999。」——与
   `Profile.buy_archive_level()` 的 `>= 10` 拒绝不一致，是自相矛盾的假错误。
   （另：`NPCProfiles` 里陆沉「档案馆升级」描述写「等级没有上限」，与同一
   Hub 的档案馆页「demo 每个方向上限 10 级」冲突，一并改正。）
   修复：`ArchiveData.MAX_LEVEL = 10` 单一来源；`Profile` 改读该常量；
   `ArchiveUI` 满级行显示「已满级」/「已达上限」并禁用，`_buy` 给出
   「「X」已经修到 demo 上限 Lv.10。」；页内提示改用常量；陆沉描述改为
   「demo 每个方向上限 10 级」。未改上限数值、价格曲线、存档或成长设计。
   回归断言：`tests/test_growth.gd` +5（上限值/买满/拒绝越限/不扣碎片），
   单元 **13429 → 13434 / 0**；`tests/integration_menus.gd` +9（满级行禁用/
   文案/焦点跳过/不扣费/不报假缺碎片/描述含上限），菜单集成
   **419 → 428 / 0**。临时探针复现前后各一次后删除。
   其余抽查：第 1 章事件 7 组文案、Hub 五名 NPC 问候/态度/离线回应、
   残碑/休息/死亡提示/污染警告未发现新错字或与剧情圣经冲突的点。
6. **回归抽查——未发现回归。** 隐藏书库进入路径由
   `integration_ch1_demo`（102/0，真实 `door1` 门进入 `ch1_vault`）复跑通过；
   结局余味未解锁不泄露/已解锁展示由 `test_ending_echoes`（单元套件内）与
   `integration_menus` 的画廊断言复跑通过。
7. **未修的记录项**：无新增产品缺陷；Hub 冷加载偏高只记录、不优化（见第 4
   项）。待确认第 11–16 项未碰、未新增条目；第 2–4 章仍不可达，
   `CHAPTER_PLAN_PATHS[2]/[3]` 与 `MDS_WORLD_FILES` 未动。

## 例行扫描（第 69 程）

> 依据 brief73 / `.supervisor/DECISIONS.md` 的收口规则；本程只做例行扫描与
> 「扫描发现的产品行为缺陷」修复，不开新功能、不碰待确认第 11–16 项、
> 不改可达性/章节路由/结局与存档格式。

### 任务 0 · 基线核验（HEAD `a034d30`，Godot 4.7.stable.official.5b4e0cb0f）

- `--headless --path . --import` / `--headless --path . --quit` 退出 0、`ERROR` 0。
- 单元 `tests/run_tests.gd` **13434 / 0**（与第 68 程逐字一致）。
- 十一套集成全部跑完，与第 68 程逐套件一致、全 0 失败、各日志 `ERROR` 0：
  `integration_playability` **894** / `integration_ch1_demo` **102** /
  `integration_run_save` **613** / `integration_gamepad` **207** /
  `integration_ui_prompts` **113** / `integration_ch1_event` **59** /
  `integration_menus` **428** / `integration_ai_settings` **45** /
  `integration_ch2_bigmap` **2315** / `integration_ch3_bigmap` **4358** /
  `integration_ch4_bigmap` **5133**。
- `tests/check_exit_clean.sh <godot> 10` → **10/10 clean**；
  `tests/check_pixel_assets.py --demo` → **36 / 0**。
- 结论：基线无漂移，可施工；本程全程未出现 Magpie 网关中断。

### 扫描面逐项结论

1. **关闭回退（各覆盖页 → 上一层/焦点）——未发现新缺陷。**
   复核暂停 → 设置 → 子页（AI/键位/帮助）先退子页、再退设置、最后回暂停
   并还原打开设置前的焦点（`_pause_return_*` 链路）；背包/图鉴/帮助/地图/
   商店/事件页/权柄/归档/奖励/结局屏/画廊均有 `ui_cancel`（手柄 B）与键盘
   等价出口；权柄/归档/奖励是显式必选模态，B/Esc 只被吞掉、不关页。
   `_toggle_overlay` 的「页面并列替换」口径（替换时清 `_pause_return_*`）
   仍是既有设计，不是死路。`integration_menus` 433、`integration_gamepad`
   207 复跑 0 失败。
2. **焦点（标题/暂停/子页/商店/事件/对话）——未发现新缺陷。**
   标题有/无局内存档分别聚焦「继续本局」/「开始旅程」；暂停菜单打开即抓
   可用项；设置子页关闭把焦点还给打开它的按钮；商店/事件/对话/画廊打开
   即抓首个可点项、关闭还原；键盘与手柄切换由 `GameFlow.input_device_changed`
   统一驱动提示与焦点。`integration_menus` / `integration_gamepad` 复跑通过。
3. **存档边界（run save 写盘/续玩/坏档）——未发现新缺陷。**
   `RunSave._has_valid_shape` 覆盖全部写出键；第 27 程新增的按节点 id 进度
   键是**可选**键、旧档仍读房间键（`d01aebc` 即按兼容口径加入，未提升
   `SAVE_VERSION`，缺新键不会误判坏档）；`_restore_*` 对类型异常做兜底转换，
   坏档回退 `.bak` 并提升。`save_run_now()` 在死亡/结局/奖励页/非 MDS 时不写；
   失焦走 `NOTIFICATION_APPLICATION_FOCUS_OUT`（先保存再开暂停），关窗走
   `NOTIFICATION_WM_CLOSE_REQUEST`（`save_run_on_exit`）；死亡先清档再开
   归档模态（`_death_committed`），胜利保留 Boss 已死检查点直到 `Flow.end_run`
   清档；「Boss 已死但权柄未选」在续玩时由 `_resume_boss_aftermath` 重新
   授予权柄。`integration_run_save` 613 断言复跑 0 失败。
4. **性能（第 1 章 9 房间 + Hub 冷/热、门过渡、Boss 战帧）——只记录，未发现
   需要处理的产品性能缺陷。** 本程临时探针（测后删除）在真实主场景内实测：
   - Hub 冷加载：`load` **905.5–981.5 ms**、`instantiate` **2.4–11.1 ms**、
     `_ready` + 首帧 **355.1–508.8 ms**；Hub 60 帧 avg **8.09–8.19 ms**、
     p95 **8.60–8.85 ms**、max 8.60–13.28 ms。
   - `main.tscn` 冷加载：`load` **2015.9–2357.9 ms**、`instantiate`
     **8.4–26.6 ms**、`_ready` + 首帧 **614.5–820.1 ms**。
   - 第 1 章首房 120 帧窗口：avg **8.27–8.33 ms**（120 FPS 预算 8.33）、
     p95 **8.64–8.96**、max 8.96–13.36；未见持续掉帧。
   - 门过渡 `ch1_01.right1 → ch1_02`（作者 0.22 s 淡入淡出，真实 TOUCH 门）：
     **264.0 / 274.4 / 274.8 ms**（3 次，比第 68 程 226.6–240.0 ms 约高
     15%，同量级；本程产品代码只改文案，未定位到产品侧退化，按任务单
     只记录不优化）。
   - 逐房原始构建（`fade_time = 0`，首次/缓存）：`ch1_01` 6.6/4.6、
     `ch1_02` 5.9/4.4、`ch1_03` 13.1/10.2、`ch1_04` 6.5/4.9、`ch1_05`
     4.4/4.3、`ch1_06` 4.3/4.6、`ch1_rest` 9.9/8.9、`ch1_boss`
     **38.6/23.6**、`ch1_vault` 20.7/9.3 ms；与第 68 程同量级（Boss 冷建
     本次更低）。
   - Boss 战 120 帧：avg **8.33**、p95 **8.72–8.84**、max 11.19–14.30。
   - 对照第 68 程（Hub `load` 971.8/1095.2/1064.1、`main.tscn`
     2023.5–2127.8、首房 8.33、门 226.6–240.0、Boss avg 8.33）：本程各项
     与第 68 程及第 21/22 程基线同量级，未发现产品侧持续退化，按任务单
     不做优化改动。
5. **文案（第 1 章 + Hub）——发现并修复 2 项（3 处文案）。**
   - **陆沉「档案馆升级」开启语自相矛盾**：`hub.gd` 的
     `perform_npc_function(&"luchen", &"archive")` 仍返回「这里的等级没有
     尽头」，与 `ArchiveData.MAX_LEVEL = 10`、档案馆页「demo 每个方向上限
     10 级」和第 68 程已改的职能描述冲突（第 68 程修了上游描述，漏了这句
     运行时消息）；同一 NPC 的对话服务列表句还把「10 级」硬编码，常量
     改动时会漂移。修复：开启语按 `ArchiveData.MAX_LEVEL` 生成
     「demo 每个方向修到 Lv.%d 为止，档案本身没有尽头」，服务列表句同步
     读常量。未改上限数值、价格曲线、存档或成长设计。
   - **闻烬「签一份契约」描述与发放不符**：描述写「本局起始多 1 次奖励
     重选」，实际代码只发放 `start_pages +10` 与 `start_corruption +6`，
     对话消息也写「多 10 残页，污染 +6」；工程内没有「每局额外奖励重选」
     计数器或消费点（重选只来自「改写」权柄）。修复：描述改为「本局起始
     多 10 残页，但污染 +6」。未改发放数值。
   - **闻烬「买情报」描述/消息与效果不符**：描述写「本局首次攻击附带额外
     伤害」、消息写「你的第一击会更疼」，工程内没有首次攻击机制；实际是
     `profile.add_npc_blessing(&"wenjin", "damage", 2.0)`，由
     `RunLoot.weapon_for_run` 把祝福值永久加到所有武器伤害。修复：描述与
     消息均改为「所有武器的伤害永久 +2」。未改祝福数值。
   其余抽查：第 1 章事件 7 组文案、Hub 五名 NPC 问候/态度/离线回应、
   残碑/休息/死亡提示/污染警告、难度说明/档案馆四轨描述未发现新错字或与
   数值/剧情圣经冲突的点。
6. **回归抽查——未发现回归。** 隐藏书库进入路径由
   `integration_ch1_demo`（102/0，真实 `door1` 门进入 `ch1_vault`）复跑
   通过；结局余味未解锁不泄露/已解锁展示由 `test_ending_echoes`（单元套件
   内）与 `integration_menus` 的画廊断言复跑通过；第 68 程的档案馆满级行
   由 `test_growth`（单元内）与 `integration_menus` 复跑通过（本程又补了
   开启语/服务句两条上限文案）。
7. **未修的记录项**：无新增产品缺陷；门过渡本次偏高 15% 与 Hub `load`
   区间波动只记录、不优化（见第 4 项）。待确认第 11–16 项未碰、未新增
   条目；第 2–4 章仍不可达，`CHAPTER_PLAN_PATHS[2]/[3]` 与
   `MDS_WORLD_FILES` 未动。

### 修复与回归断言

- `scripts/hub/hub.gd`：档案馆开启消息按 `ArchiveData.MAX_LEVEL` 生成，
  服务列表句同步用常量；闻烬情报消息改为「所有武器的伤害永久 +2」。
- `scripts/hub/npc_profiles.gd`：契约描述改为「本局起始多 10 残页，污染
  +6」；情报描述改为「所有武器的伤害永久 +2」。
- `tests/test_hub_final.gd` 新增 `_test_function_copy_matches_effects`：
  7 条「有价职能描述必须写出正确价格」+ 契约 3 条文案 + 2 条实际发放 +
  情报 5 条文案/祝福 = **+17**；单元 **13434 → 13451 / 0**。
- `tests/integration_menus.gd` 新增 5 条：档案馆开启消息写明 Lv.10、不再
  声称「等级没有尽头」、页面确实打开、陆沉对话服务句写明上限、不再声称
  「没有尽头」；菜单集成 **428 → 433 / 0**。
- `integration_gamepad` 207 / `integration_run_save` 613 复跑 0 失败；
  其余套件本程未改、基线复核时已全绿（三个大图套件均跑完）。
- 临时性能探针测后删除；`git status` 仅含产品/测试/文档改动，无导入缓存
  或产物。

## 例行扫描（第 70 程）

> 依据 brief74 / `.supervisor/DECISIONS.md` 的收口规则；本程只做例行扫描与
> 「扫描发现的产品行为缺陷」修复，不开新功能、不碰待确认第 11–16 项、
> 不改可达性/章节路由/结局与存档格式。

### 任务 0 · 基线核验（HEAD `381bf26`，Godot 4.7.stable.official.5b4e0cb0f）

- `--headless --path . --import` / `--headless --path . --quit` 退出 0、`ERROR` 0。
- 单元 `tests/run_tests.gd` **13451 / 0**（与第 69 程逐字一致）。
- 十一套集成全部跑完，与第 69 程逐套件一致、全 0 失败、各日志 `ERROR` 0：
  `integration_playability` **894** / `integration_ch1_demo` **102** /
  `integration_run_save` **613** / `integration_gamepad` **207** /
  `integration_ui_prompts` **113** / `integration_ch1_event` **59** /
  `integration_menus` **433** / `integration_ai_settings` **45** /
  `integration_ch2_bigmap` **2315** / `integration_ch3_bigmap` **4358** /
  `integration_ch4_bigmap` **5133**。
- `tests/check_exit_clean.sh <godot> 10` → **10/10 clean**；
  `tests/check_pixel_assets.py --demo` → **36 / 0**。
- 结论：基线无漂移，可施工；本程全程未出现 Magpie 网关中断。

### 扫描面逐项结论

1. **关闭回退（各覆盖页 → 上一层/焦点）——未发现新缺陷。**
   复核 `game.gd::_input` 的模态顺序（权柄/归档必选模态吞 B/Esc、地图先于
   覆盖页、暂停先退设置子页）、`_toggle_overlay`/`_close_overlay`、
   `PauseMenu`/`SettingsMenu` 子页栈，以及 Hub 各页 `_unhandled_input`
   （对话/商店/档案馆/帮助/灵感/教程图鉴均用 `pause`/`ui_cancel` 退出）；
   背包为只读页、打开不抓焦点，但 `ui_cancel` 出口存在，不是死路。
   `_pause_return_*` 在页面并列替换时清空是注释写明的口径，非缺陷。
   本程 `integration_menus` 445、`integration_gamepad` 207 复跑 0 失败。
2. **焦点（标题/暂停/子页/商店/事件/对话）——未发现新缺陷。**
   标题有/无局内存档分别聚焦「继续本局」/「开始旅程」；暂停菜单打开即抓
   可用项；设置子页关闭把焦点还给打开它的按钮；商店/事件/对话/画廊/权柄/
   归档/奖励打开即抓首个可点项、关闭还原；键盘与手柄切换由
   `GameFlow.input_device_changed` 统一驱动提示与焦点。复跑同上。
3. **存档边界（run save 写盘/续玩/坏档）——未发现新缺陷。**
   逐点核对写盘调用：进房、奖励选择、事件结算、商店买/关、残碑、宝箱、
   Boss 死亡、权柄授予、暂停、失焦、关窗（`save_run_on_exit`）均有
   `save_run_now()`；`save_run_now()` 在死亡/结局/奖励页/非 MDS 时拒绝写入。
   坏档由 `RunSave.read()` 回退 `.bak` 并提升、结构无效则清理；死亡先清档
   再开归档（`_death_committed`），胜利保留 Boss 已死检查点直到
   `Flow.end_run` 清档，「Boss 已死但权柄未选」由 `_resume_boss_aftermath`
   重新授予。`integration_run_save` 613 断言复跑 0 失败。
4. **性能（第 1 章 9 房间 + Hub 冷/热、门过渡、Boss 战帧）——只记录，未发现
   需要处理的产品性能缺陷。** 本程临时探针（测后删除）在真实主场景内实测：
   - Hub 冷加载：首次 `load` **977.0 ms**、`instantiate` **5.1 ms**、
     `_ready` + 首帧 **603.4 ms**；随后两次（依赖已缓存）`load` 6.3 ms、
     `_ready` + 首帧 368.4 / 367.9 ms。
   - `main.tscn` 冷加载：首次 `load` **2346.9 ms**、`instantiate` 5.9 ms、
     `_ready` + 首帧 **687.7 ms**；随后两次 `load` 7.6 / 9.8 ms，
     `_ready` + 首帧 627.5 / 696.3 ms。与第 68 程（Hub `load`
     971.8–1095.2、`main.tscn` 2023.5–2127.8）及第 69 程（Hub
     905.5–981.5、`main.tscn` 2015.9–2357.9）同量级。
   - 第 1 章首房 3 个 120 帧窗口：avg **8.25 / 8.33 / 8.33 ms**
     （120 FPS 预算 8.33）、p95 8.61 / 8.62 / 8.62、max 8.68 / 8.73 / 9.59；
     过门后 120 帧 avg 8.33、p95 8.68、max 8.94；未见持续掉帧。
   - 门过渡 `ch1_01 ↔ ch1_02`：完整淡出+淡入 **442.1 / 449.6 ms**（作者
     `fade_time = 0.22` 两段 + 房间构建），到新房间激活 **121.8 / 221.7 ms**；
     第 68/69 程记录的 226.6–274.8 ms 是「到房间激活」段的同量级读数，端点
     口径不同，未发现产品侧退化，按任务单只记录不优化。
   - 对照第 21/22 程与第 68/69 程基线：帧间隔贴 120 FPS 预算，冷加载与门
     过渡同量级，未做任何优化改动。
5. **文案（第 1 章 + Hub）——发现并修复 5 项（8 处文案/常量）。**
   - **局内商店「缝合书页」数值写反**：`RunLoot.shop_offers` 写「恢复 45
     生命与 30 墨量」，`game.gd::_apply_reward` 实际是 `heal(35)` /
     `restore_ink(45)` / 污染 −12；`RestOfferData.EFFECT_TEXT` 也是 35/45。
     探针经真实主场景 `_apply_reward` 复现（卡面 45/30，实际 +35 HP /
     +45 墨 / −12 污染）。修复：卡面改为「恢复 35 生命与 45 墨量，并净化
     12 点污染。」；未改任何数值。
   - **档案馆买到第 10 级后的提示仍报下一次价格**：`ArchiveUI._buy` 成功
     后固定拼「下次需要 %d 碎片」，而同一行已显示「已满级/已达上限」，
     `ArchiveData.MAX_LEVEL = 10` 再也买不了。修复：新等级达到上限时改报
     「升至 Lv.%d，已达 demo 上限」，其余等级仍报下一次价格。
   - **阿砚「神铸」描述与消息跟实际祝福不符**：描述写「花费 25 记忆碎片…
     免费提升 1 级基底」，自相矛盾；消息固定写「锻造祝福 +1」，但
     `FORGE_BONUS_TOTAL_CAP = 3.0` 封顶时实际加 0、接近封顶时只加余量；
     代码还硬编码 3.0。修复：描述改为「断页剑基底直接提升 1 级，并获得
     锻造祝福（上限 3）」；`_forge_god` 改用
     `NPCProfiles.FORGE_BONUS_TOTAL_CAP`，按实得 0 / 0.5 / 1 点如实报数
     （封顶时「锻造祝福已至上限」）。
   - **咕噜货架描述只说「换词」**：黑市 18 件货里有 3 件遗物（深渊钟、净墨
     灯、不朽档案），描述会让玩家漏看遗物。修复：改为「换词与遗物」。
   - **零污染遗物的奖励卡印「污染 +0」**：`RunLoot.choices`/`elite_choices`
     无条件拼污染行，而 `clean_ink_lantern.corruption = 0`（第 1 章 demo
     遗物池内）；Hub 商店早已用 `corruption > 0` 守卫。修复：新增
     `_relic_reward_text()`，仅正污染才写该行；其余遗物（如 `ink_heart`
     +1）仍正常显示。
   其余抽查：第 1 章事件 7 组文案、Hub 五名 NPC 问候/态度/离线回应、
   残碑/休息/死亡/污染提示、难度说明、档案馆四轨描述、教程三步与帮助
   键位说明未发现新错字或与数值/剧情圣经冲突的点。
6. **回归抽查——未发现回归。** 隐藏书库进入路径由
   `integration_ch1_demo`（102/0，真实 `door1` 门进入 `ch1_vault`）复跑
   通过；结局余味未解锁不泄露/已解锁展示由 `test_ending_echoes`（单元
   套件内）与 `integration_menus` 的画廊断言复跑通过；第 68 程档案馆
   满级行由 `test_growth` 与 `integration_menus` 复跑通过（本程又补了
   买到第 10 级后的提示）；第 69 程三处 Hub 文案修正由
   `test_hub_final` 的契约/情报断言复跑通过。
7. **未修的记录项**：设置页的「全屏」切换只改 `DisplayServer.window_set_mode`，
   未写入 `Profile`（音量/震动/闪烁/字号/AI/键位均持久化），重启后回到窗口
   模式。补持久化会新增 Profile 键、改变设置存档形状，任务单未要求，本程
   只记录、不修、不新增待确认条目。其余无新增产品缺陷；第 11–16 项未碰，
   第 2–4 章仍不可达。

### 修复与回归断言

- `scripts/core/run_loot.gd`：缝合书页文案改为 35 生命/45 墨量；新增
  `_relic_reward_text()`（零污染不写「污染 +0」）并用于 `choices`/
  `elite_choices`。
- `scripts/ui/archive_ui.gd`：买到 demo 上限时状态提示改报上限，不再报
  下一次价格。
- `scripts/hub/hub.gd`：`_forge_god` 改用 `NPCProfiles.FORGE_BONUS_TOTAL_CAP`，
  按实际增加的祝福报数。
- `scripts/hub/npc_profiles.gd`：神铸描述改为「基底直接提升 1 级…（上限 3）」；
  咕噜货架描述补「与遗物」。
- 回归断言：`tests/test_shop.gd` +1（缝合书页文案）、
  `tests/test_hub_final.gd` +9（咕噜货架 2 + 神铸 7）、
  `tests/test_demo_loot.gd` +4（零污染/有污染遗物卡），单元
  **13451 → 13465 / 0**；`tests/integration_menus.gd` +12（档案馆最终
  一级 3 + 神铸 9），菜单集成 **433 → 445 / 0**；
  `tests/integration_playability.gd` +5（缝合书页标题/三项实际数值/
  文案与数值一致），可玩性集成 **894 → 899 / 0**。
- 修复后复跑 `integration_gamepad` 207、`integration_run_save` 613、
  `integration_ui_prompts` 113 全 0 失败；收尾完整套件数字见下。
- 临时探针（`tests/_probe_rest_offer.gd`、`tests/_probe_perf.gd`、
  `tests/_probe_door.gd`）复现/测量后删除；`git status` 仅含产品/测试/
  文档改动，无导入缓存或产物。

### 收尾复跑（全绿）

- 单元 **13465 / 0**；十一套集成 **899 / 102 / 613 / 207 / 113 / 59 /
  445 / 45 / 2315 / 4358 / 5133**，全 0 失败、各日志 `ERROR` 0；
  `--headless --import` / `--quit` 退出 0、`ERROR` 0；退出泄漏
  **10/10 clean**；demo 像素 **36 / 0**。
- 第 2–4 章仍不可达，`CHAPTER_PLAN_PATHS[2]/[3]` 与 `MDS_WORLD_FILES`
  未动；未推送、未更新网页版、未宣布里程碑。

## 例行扫描（第 72 程）

> 依据 brief76 / `.supervisor/DECISIONS.md` 的收口规则。第 71 程（brief75）
> 开局即因 Magpie 网关中断夭折（`.supervisor/session75.log` 仅两行、零产出、
> 无提交）；本程是第 71 程例行扫描的全新重跑，不假设其留下任何工作。本程只做
> 例行扫描与「扫描发现的产品行为缺陷」修复，不开新功能、不碰待确认第 11–16 项、
> 不改可达性/章节路由/结局与存档格式。

### 任务 0 · 基线核验（HEAD `3847343`，Godot 4.7.stable.official.5b4e0cb0f）

- `--headless --path . --import` / `--headless --path . --quit` 退出 0、`ERROR` 0。
- 单元 `tests/run_tests.gd` **13465 / 0**（与第 70 程逐字一致）。
- 十一套集成全部跑完，与第 70 程逐套件一致、全 0 失败、各日志 `ERROR` 0：
  `integration_playability` **899** / `integration_ch1_demo` **102** /
  `integration_run_save` **613** / `integration_gamepad` **207** /
  `integration_ui_prompts` **113** / `integration_ch1_event` **59** /
  `integration_menus` **445** / `integration_ai_settings` **45** /
  `integration_ch2_bigmap` **2315** / `integration_ch3_bigmap` **4358** /
  `integration_ch4_bigmap` **5133**。
- `tests/check_exit_clean.sh <godot> 10` → **10/10 clean**；
  `tests/check_pixel_assets.py --demo` → **36 / 0**。
- 结论：基线无漂移，可施工；本程全程未出现 Magpie 网关中断。

### 扫描面逐项结论

1. **关闭回退（各覆盖页 → 上一层/焦点）——未发现新缺陷。**
   复核 `game.gd::_input` 的模态顺序（权柄/归档必选模态吞 B/Esc、地图先于
   覆盖页、暂停先退设置子页）、`_toggle_overlay`/`_close_overlay`、
   `PauseMenu`/`SettingsMenu` 子页栈，以及 Hub 各页 `_unhandled_input`
   （对话/商店/档案馆/帮助/灵感/教程图鉴均用 `pause`/`ui_cancel` 退出）；
   背包为只读页、打开不抓焦点，但 `ui_cancel` 出口存在，不是死路。
   `_pause_return_*` 在页面并列替换时清空是注释写明的口径，非缺陷。
   本程 `integration_menus` 445、`integration_gamepad` 207 复跑 0 失败。
2. **焦点（标题/暂停/子页/商店/事件/对话）——未发现新缺陷。**
   标题有/无局内存档分别聚焦「继续本局」/「开始旅程」
   （menus 的 `title_first_focus_no_save` / `title_first_focus_with_save`）；
   暂停菜单打开即抓可用项；设置子页关闭把焦点还给打开它的按钮
   （`SettingsMenu._on_subpage_closed`）；商店/事件/对话/画廊/权柄/归档/
   奖励打开即抓首个可点项、关闭还原；键盘与手柄切换由
   `GameFlow.input_device_changed` 统一驱动提示与焦点。复跑同上。
3. **存档边界（run save 写盘/续玩/坏档）——未发现新缺陷。**
   逐点核对写盘调用：进房、奖励选择、事件结算、商店买/关、残碑、宝箱、
   Boss 死亡、权柄授予、暂停、失焦、关窗（`save_run_on_exit`）均有
   `save_run_now()`；`save_run_now()` 在死亡/结局/奖励页/非 MDS 时拒绝写入。
   坏档由 `RunSave.read()` 回退 `.bak` 并提升、结构无效则清理；死亡先清档
   再开归档（`_death_committed`），胜利保留 Boss 已死检查点直到
   `Flow.end_run` 清档，「Boss 已死但权柄未选」由 `_resume_boss_aftermath`
   重新授予。`integration_run_save` 613 断言复跑 0 失败。
4. **性能（第 1 章 9 房间 + Hub 冷/热、门过渡、Boss 战帧）——只记录，未发现
   需要处理的产品性能缺陷。** 本程临时探针（测后删除）每项 3 个新进程样本：
   - Hub 冷加载：`load` **753.1 / 792.2 / 905.1 ms**、`_ready`+首帧
     **461.6 / 468.0 / 556.4 ms**；与第 68 程（`load` 971.8–1095.2）、
     第 69 程（905.5–981.5）、第 70 程（977.0 / 603.4）同量级。
   - `main.tscn`：**2779.9 / 2801.1 / 2921.8 ms**，比第 69/70 程
     （2015.9–2357.9）高约 20–25%，仍同量级，只记录不优化。
   - 第 1 章 9 房间原始构建（`fade_time = 0`）：冷 **3.84–37.39 ms**
     （`ch1_03` 11.5–11.7、`ch1_rest` 8.6–9.0、`ch1_boss` 30.7–37.4、
     `ch1_vault` 10.1–14.2，其余 3.8–6.5）、热 **3.77–23.06 ms**；与
     第 68 程（5.1–77.4）、第 69 程（4.3–38.6）同量级或更低。
   - Boss 战 120 帧：avg **8.33 / 8.33 / 8.45 ms**（120 FPS 预算 8.33）、
     peak 10.27 / 10.61 / 25.36 ms（首个样本含刚释放 Hub 的抖动），与
     第 68/69/70 程的 Boss avg 8.33 一致。
   - 门过渡 `ch1_01.right1 → ch1_02`（作者 `fade_time = 0.22`，到房间激活）：
     **225.26 / 225.56 / 225.66 ms**，与第 68 程 226.6–240.0、第 70 程激活段
     121.8–221.7 同端点、同量级，未发现退化。
   - 未做任何优化改动。
5. **文案（第 1 章 + Hub）——发现并修复 1 项产品行为缺陷。**
   - **跟阿砚打招呼会静默扣碎片、升级断页剑基底。**
     `scripts/hub/hub.gd::talk_to_npc` 的 `&"ayan"` 分支把
     `upgrade_sword_base().get("message")` 直接拼进问候语，而
     `upgrade_sword_base()` 是真正扣碎片、提升基底等级的付费操作；正确入口
     是「言灵对话」面板里的「锻造基底」（`perform_npc_function` →
     `upgrade_sword_base`）。无头探针在真实 `hub.tscn` 复现：碎片
     **100 → 90**、基底 **Lv.0 → Lv.1**，对话出现「记忆碎片 -10。断页剑基底
     已升至 Lv.1…」。碎片不足时，每次问候还会重复附上「记忆碎片不足」的
     失败消息。修复：问候改为非交易性说明——报当前基底等级并指向
     「言灵对话 → 锻造基底」，不写死价格（折扣/托付免费会变）：
     「断页剑基底现在是 Lv.%d。要再锻一层，在「言灵对话」里选「锻造基底」——
     花多少碎片，看交情。」未改锻造数值、折扣、信任或存档。
   其余抽查：第 1 章事件 7 组文案、Hub 五名 NPC 问候/态度/离线回应、
   残碑/休息/死亡/污染提示、难度说明、档案馆四轨描述、教程三步与帮助
   键位说明、第 69/70 程修过的契约/情报/神铸/货架/缝合书页/遗物卡，
   未发现新错字或与数值/剧情圣经冲突的点。
6. **回归抽查——未发现回归。** 隐藏书库真实 `door1` 进入由
   `integration_ch1_demo`（102/0，`demo_vault_entered`）复跑通过；结局余味
   未解锁不泄露/已解锁展示由 `test_ending_echoes`（单元套件内）与
   `integration_menus` 的画廊断言复跑通过；第 68 程档案馆满级行由
   `test_growth` 与 `integration_menus` 复跑通过；第 69 程三处 Hub 文案由
   `test_hub_final` 的契约/情报断言复跑通过；第 70 程五项文案由
   `test_shop`/`test_hub_final`/`test_demo_loot` + menus + playability 复跑
   通过。
7. **未修的记录项**：设置页的「全屏」切换只改
   `DisplayServer.window_set_mode`，未写入 `Profile`（第 70 程记录项，本程
   复核仍在）；补持久化会新增 Profile 键、改变设置存档形状，任务单未要求，
   只记录、不修、不新增待确认条目。第 60 程样图问题 1/3/6 与待确认第 13/15
   项相关，拍板前不施工；5/7 已判定为取景限制/既有素材，不是缺陷，不动。
   第 11–16 项未碰，第 2–4 章仍不可达。

### 修复与回归断言

- `scripts/hub/hub.gd`：`talk_to_npc` 的阿砚分支不再调用
  `upgrade_sword_base()`；改为报当前基底等级并指向「言灵对话 → 锻造基底」，
  不写死价格。
- 回归断言：`tests/test_hub_final.gd` **+9**——问候打开对话、碎片仍 100、
  基底等级不变、对话提到「锻造基底」与当前 `Lv.`、关闭后解冻玩家、显式
  `perform_npc_function(&"ayan", &"forge")` 仍升 1 级并按 `10 + Lv×10`
  扣费且消息含 `Lv.`。
- 结果：单元 **13465 → 13474 / 0**；受影响的集成复跑 menus 445、
  run_save 613、gamepad 207、ui_prompts 113、playability 899，全 0 失败。
- 临时探针（`tests/_probe_ayan_talk.gd`、`tests/_probe_pass72_perf.gd`）
  复现/测量后删除；`git status` 仅含产品/测试/文档改动，无导入缓存或产物。

### 收尾复跑（全绿）

- 单元 **13474 / 0**（+9）。
- 十一套集成 **899 / 102 / 613 / 207 / 113 / 59 / 445 / 45 / 2315 / 4358 /
  5133**，全 0 失败、各日志 `ERROR` 0。
- `--headless --import` / `--quit` 退出 0、`ERROR` 0；退出泄漏
  **10/10 clean**；demo 像素 **36 / 0**。
- 第 2–4 章仍不可达，`CHAPTER_PLAN_PATHS[2]/[3]` 与 `MDS_WORLD_FILES`
  未动；未推送、未更新网页版、未宣布里程碑。

## 例行扫描（第 73 程）

> 依据 brief77 / `.supervisor/DECISIONS.md` 的收口规则。本程只做例行扫描与
> 「扫描发现的产品行为缺陷」修复，不开新功能、不碰待确认第 11–16 项、
> 不改可达性/章节路由/结局与存档格式、不推送、不更新网页版。

### 任务 0 · 基线核验（HEAD `8b4244a`，Godot 4.7.stable.official.5b4e0cb0f）

- `--headless --path . --import` / `--quit` 退出 0。
- 单元 `tests/run_tests.gd` **13474 / 0**（与第 72 程逐字一致）。
- 十一套集成全部跑完，与第 72 程逐套件一致、全 0 失败：
  `integration_playability` **899** / `integration_ch1_demo` **102** /
  `integration_run_save` **613** / `integration_gamepad` **207** /
  `integration_ui_prompts` **113** / `integration_ch1_event` **59** /
  `integration_menus` **445** / `integration_ai_settings` **45** /
  `integration_ch2_bigmap` **2315** / `integration_ch3_bigmap` **4358** /
  `integration_ch4_bigmap` **5133**。
- `tests/check_exit_clean.sh` **10/10 clean**；`check_pixel_assets.py --demo`
  **36 / 0**。
- 结论：基线无漂移，可施工。

### 扫描面逐项结论

1. **关闭回退（各覆盖页 → 上一层/焦点）——未发现新缺陷。**
   `game.gd::_input` 的模态顺序、`PauseMenu` 的 `pause`/`ui_cancel` 退出、
   `SettingsMenu` 子页栈先关子页、`KeybindUI` 捕获态、背包/图鉴/帮助的
   `ui_cancel` 出口、地图自带暂停、局内商店/剧情/事件/对话/确认框退出、
   结局屏必选流程与画廊关闭还原焦点均复核；无死路、无 B/Esc 不一致。
2. **焦点（标题/暂停/子页/商店/事件/对话）——未发现新缺陷。**
   标题有/无局内存档分别聚焦「继续本局」/「开始旅程」；暂停打开即抓可用项；
   设置子页关闭把焦点还给打开它的按钮（`_pause_return_focus`）；各覆盖页
   打开即抓首个可点项；键盘/手柄切换由 `GameFlow.input_device_changed`
   统一驱动。
3. **存档边界（run save 写盘/续玩/坏档）——未发现新缺陷。** 进房/事件结算/
   商店购买与关闭/残碑/宝箱/Boss 死亡/权柄/暂停/失焦/窗口关闭均写盘；
   奖励选择页故意不写（续玩重放未选奖励）；死亡在归档模态前清档、失败
   `_finish` 清档、回 Hub/重开/结束战役清档；`RunSave.read()` 版本/形状
   校验失败与坏主档回退 `.bak` 并提升备份。无残留复活路径。
4. **性能（只记录、不优化）——未发现退化信号。** 临时探针（测后删除）在
   真实主场景内实测，每项 3 个新进程样本：
   - Hub 冷加载 `load` **535.4 / 527.3 / 403.1 ms**、`_ready`+首帧
     **426.7 / 476.9 / 395.0 ms**（第 72 程 753–905 / 461–556，更低）。
   - `main.tscn` `load` **1954.6 / 1998.2 / 1710.4 ms**、实例化+首帧
     **687.5 / 669.0 / 633.5 ms**（第 72 程 2779.9–2921.8，更低）。
   - 第 1 章 9 房间原始构建（预热房间脚本）：冷 **14.5–23.1 ms**
     （`ch1_03` 首次 57.3–125.6、另一次 25.6，为首次共享资源加载离群值），
     热 **14.4–25.6 ms**；地板比第 72 程热 3.77–23.06 高约 10 ms，但门过渡
     与 Boss 帧逐项同值、本程未动房间构建，按环境/测序差异记录、不优化。
   - Boss 战 120 帧：avg **8.33 / 8.33 / 8.33 ms**（120 FPS 预算 8.33）、
     p95 **9.06 / 8.70 / 8.74**、max **12.73 / 10.15 / 10.15 ms**。
   - 门过渡 `ch1_01.right1 → ch1_02`（`fade_time = 0.22`，到新房间激活）：
     **225.59 / 226.31 / 226.26 ms**，与第 72 程 225.26–225.66 同端点。
5. **文案（第 1 章 + Hub 事件/对话/提示）——未发现新矛盾。** 抽查
   `Ch1EventData` 七组事件、`RestOfferData` 效果行（35 生命 / 45 墨量 /
   污染 −12，对应 `_apply_reward`）、`VaultRoomData` 八条发现行、残碑重复
   领取（25 生命 / 30 墨量）、第 69/70/72 程已修文案，以及全仓旧串残留
   （`没有尽头`/`首次攻击`/`第一击`/`1 次奖励`/`+0`）——无新矛盾，未改文案。
6. **回归抽查——全部通过。** 隐藏书库进入/返回/无坠落伤害、结局余味
   （第 66 程）、档案馆满级（第 68 程）、第 69/70/72 程修复的断言均在
   全量单元与菜单/可玩性/第 1 章 demo 套件中复跑通过。

### 修复与回归断言

**1）Hub 词服务是无限碎片泵（真实产品行为缺陷）。**
`Hub._unlock_random_word()` 在无可解锁词时给 `memory_fragments += 8`，而
`Profile.DEFAULT_OWNED` 首次开局即含全部 18 个第 1 章词，兜底每次必走：
咕噜「买一条传闻」收 3 返 8（净 **+5**）、陆沉「讲述档案」收 6 返 8（净
**+2**），可无限连点并经 `_save_shared_profile()` 落盘。探针在真实
`hub.tscn` 复现：3 次传闻 **100 → 115**，界面层 10 次 **100 → 150**、
10 次讲述档案 **150 → 170**。修复：新增 `Hub.unlockable_word_pool()`；
`lore`/`rumor` 池空时拒绝并说明「没有新词、不收碎片」，不扣费；
`_unlock_random_word()` 不再支付碎片；有词时仍按原价扣 3 / 6 并解锁。
回归断言：`tests/test_hub_final.gd::_test_word_services` **+16**（池空不扣费、
回话含「不收钱/没要你的碎片」且不含「+8」、连点 10 次不涨、擦掉 `xue` 后
传闻扣 3 并解锁、擦掉 `dongjie` 后讲述档案扣 6 并解锁、结束池回空）。
单元 **13474 → 13490 / 0**。

**2）局内商店对已拥有的货仍扣残页（真实产品行为缺陷）。**
`game.gd::_on_shop_buy()` 先 `spend_pages` 再 `_apply_reward`；货架在首次
打开时缓存，若之后从奖励/宝箱/残碑拿到同一遗物或词，再买该行时
`add_relic`/`add_word` 静默拒绝，残页已扣且行未标记、可重复点。探针在真实
主场景复现：先放入货架上的遗物再买该行——残页 **100 → 75**、遗物数量不变、
行仍未标记。修复：新增 `game.gd::_shop_offer_owned()`，`relic`/`word` 行
扣费前检查库存，已拥有则 `RunShopUI.mark_owned()` 禁用该行、标签
「已拥有：<名>」、回话「这件你已经有了，摊主不收残页。」、**不扣残页**，
`bought` 写入缓存避免续玩再出现；其他行与正常购买流程不变。回归断言：
`tests/integration_ch1_demo.gd` 商店段 **+7**（遗物行存在/有资源、已拥有
购买不扣残页、不重复、行禁用且标签「已拥有」、回话含「不收残页」），
断言后移除测试注入的遗物。第 1 章 demo 集成 **102 → 109 / 0**。

### 未修记录（只记录，不新增待确认条目）

- `PauseMenu._ask_confirm` 取消后残留 `CONNECT_ONE_SHOT` 的 `confirmed`
  连接，下一次确认会同时触发两个动作——当前不可见（两个动作最终都走同一个
  pending scene 槽、`returned_to_hub` 无监听者），未改。
- `NPC.interact()` / `dialogue_index` 是死代码（Hub 每次对话重放全部台词），
  属 UX 观察，改动会变更对话设计，未动。
- 设置页全屏切换不写 `Profile`（沿用第 70 程记录，未修）。
- 第 60 程样图问题 1/3/5/6/7 维持第 63/64 程结论：1/6 与第 13 项相关、
  3 与第 15 项相关，拍板前不施工；5/7 不是缺陷。
- 第 11–16 项未碰、未新增待确认条目；第 2–4 章仍不可达。

### 收尾复跑（全绿）

- 单元 **13490 / 0**（+16）。
- 十一套集成 **899 / 109 / 613 / 207 / 113 / 59 / 445 / 45 / 2315 / 4358 /
  5133**，全 0 失败；三个大图套件均跑完。
- `--headless --import` / `--quit` 退出 0；退出泄漏 **10/10 clean**；
  demo 像素 **36 / 0**。
- 临时探针（`_probe_hub_words` / `_probe_pause_confirm` / `_probe_perf` /
  `_probe_shop_dup`）测后删除；工作区提交后干净。
- 未推送、未更新网页版、未宣布里程碑。

## README 重写（第 74 程）

> 依据 `.supervisor/DECISIONS.md`「用户批准发布一版 + README 重写」与三次改口
> （发布 = 里程碑推送 + 网页更新 + GitHub Release v0.12.0 预发布 + Windows 包）。
> 本程只改仓库根 `README.md`；不做 Windows 导出、不推送、不更新网页版、不创建
> Release、不改任何游戏代码/场景/资源/测试、不改章节可达性。

### 重写口径与结构

新结构（自上而下）：简介 → 当前可玩范围 → 已建成但未开放 → 核心系统
（言出法随 / 权柄 / 信任分层 / 结局画廊）→ 操作 → 运行 → 开发状态。

- 当前可玩如实写为：第一章「墨雨档案馆」9 个房间区域（4 战斗 + 精英 + 事件 +
  休整 + 隐藏书库 + Boss）、清房目标 6、墨骸史官三阶段；T17 系统（吞噬/归档、
  四档信任、结局画廊）；四档难度、局内存档与手柄。
- 第 2–4 章统一写为「已建成并通过各自的系统验收，因主流程接线未完成暂不可达」，
  不再出现「依次穿过四章」。
- 旧版本日志（0.11.0 / 0.10.0 / 0.7.0 三层倒序堆叠与「当前状态」旧日志）整段删除，
  历史细节指向 `docs/` 与 git 记录。
- 删除 SAPI 旁白宣传与 Android/触屏条目；配乐只保留一处口径（6 首，来自
  `assets/audio/manifest.json` 的 6 条 music tracks），不再提旁白段数。
- 结局表述按实现核实：demo 内可达成 3/5（深渊回响、未完的注脚、记录中断）；
  「复原」需跨章仁慈 ≥2（第一章章末只能 +1），「焚毁档案」只在第四章流程触发，
  二者暂不可达。

### 核实的数字与来源

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
README 只写 95 与 18，没有写 50。

### 删除 / 修正的旧内容

- 删除 0.11.0-demo（2026-11-03）、0.10.0（2026-11-02）、0.7.0（2026-11-01）三段版本日志与旧「当前状态」段。
- 删除「公开仓库 … 20–25 分钟」中的未核实时长与「六房 + 精英/事件/休息/书库 → 墨骸史官 → 续命/改写 → 未完待续」旧流程。
- 删除「依次穿过四章」「章末选择会改变结局」的笼统说法，改为第一章停章与 demo 可达 3 个结局。
- 删除 SAPI 旁白段、`docs/audio/README.md` 旁白宣传、Android 触屏行与「触屏」操作。
- 修正配乐口径：旧文一处「六首 + 22 段旁白」、一处「五首 + 18 段旁白」，新文只写「6 首原创循环曲目」。
- 修正旧测试数字 3083 / 265；改为单元 13,490、集成 14,296。
- 修正旧「50 个可收集词」「8 种法术形态」；改为 95 词条、13 形态。
- 补充 T17 与第 2–4 章大地图成果；第 2–4 章明确「已建成未开放」。

### 自查与验证

- 结构顺序符合 DECISIONS 重写口径；全文无 SAPI / Android / 触屏 /「依次穿过四章」/ 旧版本号。
- 可玩与未开放分区明确；未把第 2–4 章或未达成结局写成可玩。
- 数字全文各只出现一处（配乐 6 首仅「运行」一处），且均可在仓库复核。
- 只改 `README.md`；提交 `a5053a4`（docs）。
- 基线复跑：`--headless --import` / `--quit` 退出 0；单元 **13,490 / 0**；十一套集成
  **899 / 109 / 613 / 207 / 113 / 59 / 445 / 45 / 2,315 / 4,358 / 5,133** 全 0 失败；
  退出泄漏 **10/10 clean**；demo 像素 **36 / 0**（与本程开工前一致，无产品改动）。

## Windows 导出（第 75 程）

> 依据 `.supervisor/DECISIONS.md`「再更正：Release 直接带 Windows 包」与任务单
> brief79。本程只做 Windows 导出、zip 打包与验证；不推送、不更新网页版、不创建
> Release、不上传资产（这些由监工在里程碑执行，Release 创建需用户配合 passkey）。

### 导出链路

- 引擎 `Godot_v4.7-stable_linux.x86_64`（4.7.stable.official.5b4e0cb0f）；模板
  `~/.local/share/godot/export_templates/4.7.stable/` 已装，含
  `windows_release_x86_64.exe`（109,160,448 bytes）。
- 预设为仓库既有 `Windows Desktop`（`runnable=true`、`export_filter=all_resources`、
  `binary_format/embed_pck=true`、导出到 `build/windows/changzi-adventure.exe`）；
  **本程未改 `export_presets.cfg`**。
- `.mdsworld.json` 由 MDS 用 `FileAccess` 读取；Godot 4.7 把 `.json` 识别为
  `JSON` 资源（`ResourceLoader.exists` 为 true），`all_resources` 会打包，无需新增
  `include_filter`；四个章节世界 JSON 与音频 manifest 均已确认可被资源系统识别。

### 导出与产物

- 命令：`<godot> --headless --path . --export-release "Windows Desktop" build/windows/changzi-adventure.exe`
- 结果：**退出 0，20 秒**；完整日志 `artifacts/releases/v0.12.0/export.log`
  （1,732 行 / 206,557 bytes）。
- exe：**132,104,632 bytes（约 126.0 MiB）**，`PE32+ executable (GUI) x86-64,
  for MS Windows`；SHA-256 `7d4811f43ae27d378cd79570b1e36db9f9ab2dfb35602819185a2e39abd94242`。
- PCK 内嵌（`embed_pck=true`）：exe 偏移 109,174,272 起 `GDPC` 头，内嵌
  **22,930,348 bytes**。独立 `--export-pack` 导出同资源集亦为 22,930,348 bytes，
  与从 exe 提取的内嵌 PCK **逐字节一致**（SHA-256
  `20ba3fff908bfc31a43039b95bf2170ad51f9fe053629fac4942dda9726c3a9f`）；临时
  空项目加载该 PCK 逐项检查 12 个关键路径 **MISSING=0**；`--main-pack` 无头启动
  **退出 0**、无脚本错误。因此「exe + pck 齐全」按单文件 exe 的内嵌 PCK 口径
  成立（zip 内无独立 `.pck`，与仓库既有发行文档一致）。
- zip：`artifacts/releases/v0.12.0/changzi-adventure-v0.12.0-windows.zip`
  **59,572,799 bytes（约 56.8 MiB）**，SHA-256
  `9e14c4359960f0bae20b341e24d671995ca020550b7d1f24cc02805607024e9e`；
  `unzip -l` 仅 1 个文件 `changzi-adventure.exe`（132,104,632 bytes），
  `unzip -t` 通过，包内 exe 哈希与源 exe 一致（`7d4811f4…4242`）。
  `artifacts/` 已在 `.gitignore`，产物不提交。

### 告警 / 边界

- 导出日志非致命告警：`Invalid version number "0.11.0-demo"` ×2（预设未设数值
  `application/file_version`/`product_version`，exe 的 VERSIONINFO 数值版本为空，
  不影响运行）；导出器自身 `973 ObjectDB` / `8 resources` 退出告警（与第 3 程
  同源，游戏运行退出仍 0 泄漏）；Android `build-tools` 缺失提示与本导出无关。
- **Windows 实机首跑未验证**（Linux VM 跑不了 exe，未用 wine/虚拟机硬跑）；
  Release notes 必须如实写「Windows 实机首跑待验证」。`--main-pack` 只证明数据包
  可被引擎加载，不等于 Windows 运行验证。
- 版本口径：Release tag / zip 文件名用 `v0.12.0`；但 `project.godot config/version`、
  标题屏版本标签、Android 预设 `version/name` 仍为 `0.11.0-demo`，本程按任务单
  「不改游戏代码/产品配置」未动（改标题屏属游戏代码，版本号统一属后续决定）。
- 交付物（本地、不提交）：`artifacts/releases/v0.12.0/` 下
  `changzi-adventure-v0.12.0-windows.zip` + `changzi-adventure.exe` + `export.log`。
- 基线复跑：单元 **13,490 / 0**；十一套集成 **899 / 109 / 613 / 207 / 113 /
  59 / 445 / 45 / 2,315 / 4,358 / 5,133** 全 0 失败；退出泄漏 **10/10 clean**；
  demo 像素 **36 / 0**。

## 第 2 章可达性接线第 1 步（第 76–77 程）

> 第 76 程（brief80）完成缺口核查与 `game.gd` 改动后因网关中断夭折，改动留在工作区未提交；
> 第 77 程（brief81）接力核验、补齐持久化 parity、改写红断言并跑通全量基线。

### 接线

- 唯一缺口在 `scripts/game.gd::_complete_chapter` 的第 1 章分支：由 `demo_cleared = true` 后
  `_finish(true)` 结束 demo，改为 `demo_cleared = true` → `Flow.save_profile()` →
  `_start_chapter(1)` → return。
  - `demo_cleared` 语义不变（Hub NPC 个人事件读它）；`_finish(true)` 原来负责的
    `Flow.save_profile()` 显式补回。`_apply_chapter_choice` 的选项/效果
    （治疗/遗物/护盾/武器强化/焚毁标记、`_mercy`、污染）一字未改；其 `save_run_now()`
    在 `_ending_pending` 期间照旧跳过，第 1 章 Boss 检查点保留。
- 第 2 章路由全部走既有路径：`CHAPTER_PLAN_PATHS[1]`、`MDS_WORLD_FILES[1]`、
  `MDS_CHAPTER_SCENES[1]`；起始区 `ch2_entry`（`SpawnPoint`）、清房目标 7（HUD 分母 8）、
  坠落平面 1440 + 240 = 1680、开场 6 句 + `ch2_intro` 语音 + `chapter_breathing.ogg`
  均由 `CampaignData`/计划既有路径生效，未新增分支。
- 第 2 章末仍按第 35/46 程口径 `_finish(true)` 停章，不进第 3 章。

### 验收

- `tests/integration_playability.gd` **899 → 913 / 0**：第 1 章自然通关 → 章末选择 →
  第 2 章开场（标题/正文/语音/配乐/暂停）→ 大图加载、`ch2_entry` `SpawnPoint` 出生落地 →
  清房 0/7（HUD 8）、坠落平面 1680 → 真实战斗清掉 `ch2_branch_a/Arena`、`Arena2`
  （锁定 → 击杀 → 奖励 → 计数 +1/+2 → 只结算一次）→ Boss 2 → 权柄 → outro → 章末选择 →
  停章（`_chapter == 1`、`_finished`、结束屏，不进第 3 章）。
- `tests/integration_menus.gd` **445 → 456 / 0**：键盘/手柄章末选择后进入第 2 章开场
  （可见、暂停、焦点在「继续」），再用 `_finish(true)` 保留结束屏首帧焦点覆盖。
- `tests/integration_run_save.gd` **613 → 624 / 0**：章末续玩、权柄后退出、通关后退出三条
  边界改为第 2 章开场；关闭开场后大图启动、检查点写 `chapter=1`/`room=ch2_entry`；
  开场期间退出仍保留第 1 章 Boss 检查点（重放章末，不跳内容）。
- 基线：单元 **13,490 / 0**；十一套集成 **913 / 109 / 624 / 207 / 113 / 59 / 456 / 45 /
  2,315 / 4,358 / 5,133** 全 0 失败；退出泄漏 **10/10**；demo 像素 **36 / 0**。

### 边界

- 未改第 2 章计划/波次/事件/Boss 2 数值，未改第 1 章房间/波次/事件/奖励/结局判定与存档形状。
- `CHAPTER_PLAN_PATHS[2]/[3]`、`MDS_WORLD_FILES[2]/[3]` 未动，第 3/4 章仍不可达；
  `ch2_shortcut` 仍无游戏内授予（第 11 项）；电梯 80 px/s、相机/HUD 未动（第 12/13 项）。
- 未推送、未更新网页版、未创建 Release。仓库根 `README.md` 仍写「第 2–4 章不可达」
  （第 2 章现已可达），待监工决定何时更新；本程未改。

## 第 2 章四敌缺美术接入（第 78 程）

### 原图与验收口径

- 用户 2026-11-06 在 ChatGPT 按监工提示词出图，存 `.supervisor/art-inbox/`（两份原图 JPG 原地保留、未删未覆盖）：
  - `breath_hound.jpg`（1320×660，单张白底 JPG；侧面朝左、低饱和墨灰毛发、绿雾呼吸；浅色毛边需保边去底）。
  - `lung_moth+rust_whisperer+collapse_husk.jpg`（1320×445，三拼图；左→右 lung_moth / rust_whisperer / collapse_husk，肺叶翅 / 锁链铜铃 / 胸口塌陷长臂等特征齐全，需先按个体裁切）。
- 监工验收意见：后三只像素颗粒更细、偏平滑插画感；接入统一像素化 + 调色板对齐，以 breath_hound 与既有游戏内精灵为颗粒度基准，不原图直入。

### 处理口径（只做图像处理，不新绘、不拼凑）

- 去底：从图像四边 flood-fill，只去掉与边缘连通的近白像素（容差 18/255），保留被深色毛发包围的浅色毛边；输出 alpha 只有 0/255，无半透明羽化边。
- 三拼图裁切：按空白列（29–519 / 575–887 / 949–1245）分离三只，触角 / 铜铃 / 长臂全部保留。
- 缩放：统一到 96×96 画布、底部对齐；LANCZOS 缩到目标尺寸，内部再留 1 px 轮廓余量，成品四周保持透明边。
- 调色板对齐：HSV 降饱和（breath_hound 1.0、lung_moth 1.0、rust_whisperer 0.9、collapse_husk 0.85）+ 明度 0.90–0.94；中值切分量化 24 色（无抖动）+ 1 px 深色轮廓 `#101820`，alpha 二值化。
- 成品：四张 96×96 PNG、各 25 色（24 + 轮廓）、二进制 alpha、最低不透明行 = 画布最后一行、四角透明、无近白（>235）残留；浅色毛发保留为灰白高光。

### 文件清单

| 文件 | 尺寸 | 色数 | 不透明包围盒 |
|---|---|---|---|
| `assets/sprites/enemies/breath_hound.png` | 96×96 | 25 | (1,44)–(94,95)，92×50 |
| `assets/sprites/enemies/lung_moth.png` | 96×96 | 25 | (1,23)–(94,95)，92×71 |
| `assets/sprites/enemies/rust_whisperer.png` | 96×96 | 25 | (14,6)–(80,95)，67×88 |
| `assets/sprites/enemies/collapse_husk.png` | 96×96 | 25 | (13,6)–(81,95)，69×88 |

各带 Godot 生成的 `.import`（`compress/mode=0`、`mipmaps/generate=false`，与既有敌人精灵一致）。

### 接入改动

- `scripts/game.gd`：`ENEMY_ART` 新增四条（`breath_hound` / `lung_moth` / `rust_whisperer` / `collapse_husk`，指向各自 PNG）；`ENEMY_ART_FALLBACK` 清空（原四条借图 `ink_hound` / `hanging_scribe` / `scribe_bug` / `blank_man` 全撤）；`_spawn_group()` 的生成路径与 tint 规则未改（回退表为空 → 四种都走 `Color.WHITE`）。
- 未改敌人场景 / 数值 / 行为 / 波次，未改 `ENEMY_ANIM_STYLE` / `ENEMY_ART_SCALE`，未改门 / 电梯 / 长椅 / 捷径、章节路由、存档、NPC 立绘、第 1 章内容。

### 验收

- `tests/test_enemy_art.gd`：298 → **357** 断言（+59）——四敌从 `CH2_MISSING` 移入 `CH2_WIRED`、第 3 章三只移入 `CH3_WIRED`，两个缺失清单清空并加 `ch2_no_missing_enemy_art` / `ch3_no_missing_enemy_art`；回退表断言改为「表存在且为空」；每个已接线敌人新增「96×96」「有效 PNG」两条断言；第 1/2/3/4 章既有美术断言全部保留。
- `tests/integration_ch2_bigmap.gd`：2,315 → **2,330**（+15）——`ch2_branch_a/Arena2` 的 `rust_whisperer` + `collapse_husk`、`ch2_branch_b/Arena` 的 `lung_moth` + `breath_hound` 均断言专属 PNG + `Color.WHITE`（真实遭遇、真实生成路径）。
- `tests/integration_ch3_bigmap.gd`：4,358 → **4,362**（+4）——`ch3_branch_a/Arena2` 的 `rust_whisperer` / `lung_moth` 旧「第 1 章回退 + `#c8e1cd`」期望改为专属 PNG + 白 tint；`ch3_branch_b/Arena` 新增 `collapse_husk` 专属图断言。
- 像素资产复核：`tests/check_pixel_assets.py --demo` 的敌人清单补入四只（第 2 章自第 76–77 程起可达、属 demo 可见），**36 → 40 assets / 0 失败**。
- 收尾：单元 **13,549 / 0**（13,490 + 59）；十一套集成 **913 / 109 / 624 / 207 / 113 / 59 / 456 / 45 / 2,330 / 4,362 / 5,133** 全 0 失败；`--headless --import` / `--quit` 退出 0、`ERROR` 0；退出泄漏 **10/10**。
- 游戏内复核：真实遭遇中四种均以各自 PNG、`Color.WHITE`、`scale = 1.0` 生成（探针打印 + 集成断言）；1× 实际尺寸预览确认透明底干净、无白边、特征完整、非黑非白非空。

### 未改项

- 敌人数值 / 波次 / 场景 / 行为、门 / 电梯 / 长椅 / 捷径逻辑、章节路由与可达性、存档形状、NPC 立绘、第 1 章内容、第 3/4 章可达性均未动。
- 原图两份 JPG 仍在 `.supervisor/art-inbox/`；未推送、未更新网页版、未创建 Release。

## 第 3 章可达性接线第 1 步（第 80 程）

> brief84；第 79 程（brief83，同任务）在启动时因 `[claude-code:unrecognized_model]` 死亡（零产出、无提交），本程为接力全新重跑。

### 接线缺口核查

- 唯一缺口是四个路由点：`CHAPTER_PLAN_PATHS[2] == ""`、`MDS_WORLD_FILES[2]` 指旧 `chapter_3.mdsworld.json`、`MDS_CHAPTER_SCENES[2]` 指旧 `chapter_3_world.tscn`、`_complete_chapter` 的 `_chapter == 1` 仍 `_finish(true)`。
- 第 3 章计划/大区世界/区域场景/事件/Boss 3/章末停章分支（第 40–59 程）均已就位；旧第 3 章 9 房世界保留在磁盘但不再被 `game.gd` 引用；存档形状不变。

### 接线（只改路由与章末分支）

- `scripts/game.gd`：
  - `CHAPTER_PLAN_PATHS[2] = "res://resources/chapters/chapter_3_demo.tres"`；
  - `MDS_WORLD_FILES[2] = "res://scenes/mds/chapter_3_bigmap.mdsworld.json"`；
  - `MDS_CHAPTER_SCENES[2] = preload("res://scenes/mds/chapter_3_bigmap_world.tscn")`；
  - `_complete_chapter` 的 `_chapter == 1` 分支由 `_finish(true)` 改为 `_start_chapter(2)`；第 2 章章末选项/效果未改、不记录结局；第 3 章末仍 `_finish(true)` 停章，不进第 4 章。
- 第 3 章沿用既有大图流程：`ch3_entry` 出生（`SpawnPoint`）、清房目标 7（HUD 8）、坠落平面 1680（1440 + 240）、开场 6 句 + `ch3_intro` 语音 + `chapter_sea.ogg`、事件页/权柄/Boss 3/outro/章末选择均按既有内容生效。

### 测试改动（逐项，均为新行为下的期望更新）

- `integration_playability`：第 2 章章末改为断言进入第 3 章开场（`_chapter == 2`、未结束、无结束屏、开场眉题/正文/音乐/`ch3_intro` 语音）；新增 `_test_ch3_big_map`（真实链路：`ch3_entry` 出生落地、清房 0/7、坠落 1680、地图标题「无光海地图」、真实清 `ch3_branch_a/Arena` 并推进计数）；事件区/Boss 3 两段由测试专用挂载改为真实路由世界；章循环交棒识别推广到第 2 章，旧第 3 章 9 房结构遍历删除（覆盖由 `integration_ch3_bigmap` + 新真实链路承担）。
- `integration_run_save`：第 2 章 Boss 检查点续玩的章末改为进入第 3 章开场；开场期间保留第 2 章检查点，关闭后加载 `ch3_entry` 并推进为第 3 章检查点。
- `integration_ch2_bigmap`：Boss 2 后的续玩边界改为进入第 3 章开场。
- 路由锁逐条更新：`test_ch2_world`、`test_ch3_plan`、`test_ch3_world`、`test_ch3_content`、`test_ch3_boss`、`test_ch4_plan`、`test_ch4_content`、`test_ch4_boss`、`integration_ch3_bigmap`、`integration_ch4_bigmap`、`integration_playability`；第 4 章槽位仍为空、第 4 章世界/场景仍指旧世界，旧第 3/4 章世界存在性断言保留
  （`test_ch3_world` 的 `game_source.contains("ch3_bigmap") == false` 也保留：区域场景由世界文件解析，`game.gd` 只引用 `chapter_3_bigmap` 世界/场景）。

### 验收

- 单元 **13,549 / 0**（路由锁逐条替换，数量不变）。
- 十一套集成：playability **878 / 0**（913 → −35：删除第 3 章旧 9 房结构遍历与两条默认清房/坠落断言，新增真实链路/交棒/出生/战斗清房断言）、ch1_demo 109 / run_save **631 / 0**（+7）/ gamepad 207 / ui_prompts 113 / ch1_event 59 / menus 456 / ai_settings 45 / ch2 **2,331 / 0**（+1）/ ch3 **4,364 / 0**（+2）/ ch4 **5,133 / 0**。
- 退出泄漏 **10/10**、demo 像素 **40 / 0**。

### 边界

- 未改第 3 章计划/波次/事件文案/Boss 3 数值与机制、门/电梯/长椅/捷径逻辑；未改第 1/2 章房间/波次/事件/奖励/`ending_for`；未改存档形状；第 4 章仍不可达。
- `ch3_shortcut` 仍无游戏内授予（第 16 项）；未实现视野压缩（第 14 项）与海面母题（第 15 项）；电梯 80 px/s、相机/HUD 未动（第 12/13 项）。
- 未推送、未更新网页版、未创建 Release。仓库根 `README.md` 仍写「第 2–4 章不可达」（第 2/3 章现已可达），待监工决定何时更新；本程未改。

## 第 4 章可达性接线第 1 步（第 91 程）

> brief95。第 89/90 程（brief93/94）基线跑绿后中途中断（当时误记为「启动即死」，第 97 程核对日志更正：两程都记完任务 0 基线与「任务 1」标题才停，零提交），
> 本程按 `.supervisor/DECISIONS.md` 2026-11-07 09:45 的监工拍板全新开工：只做第 4 章主流程接通，
> 不碰第 11–16 项待拍板内容。

### 接线缺口核查

- 唯一缺口是四个路由点：`CHAPTER_PLAN_PATHS[3] == ""`、`MDS_WORLD_FILES[3]` 指旧
  `chapter_4.mdsworld.json`、`MDS_CHAPTER_SCENES[3]` 指旧 `chapter_4_world.tscn`、
  `_complete_chapter` 的 `_chapter == 2` 仍 `_finish(true)`。
- 第 4 章计划/大区世界/9 个区域场景/事件数据/波次/Boss 4/章末收口（第 51–59 程）均已就位并通过
  5,133 断言的系统验收；旧第 4 章 9 房世界保留在磁盘但不再被 `game.gd` 引用；存档形状不变。

### 接线（只改路由与章末分支）

- `scripts/game.gd`：
  - `CHAPTER_PLAN_PATHS[3] = "res://resources/chapters/chapter_4_demo.tres"`；
  - `MDS_WORLD_FILES[3] = "res://scenes/mds/chapter_4_bigmap.mdsworld.json"`；
  - `MDS_CHAPTER_SCENES[3] = preload("res://scenes/mds/chapter_4_bigmap_world.tscn")`；
  - `_complete_chapter` 的 `_chapter == 2` 分支由 `_finish(true)` 改为 `_start_chapter(3)`
    （第 1/2 章交棒口径不变，第 4 章末 `_chapter == 3` → `_finish(true)` 未改）；
  - `_load_chapter_plan` 与 `CHAPTER_PLAN_PATHS` 注释由「Chapters 2–3」改为「Chapters 2–4」。
- 第 4 章沿用既有大图流程：`ch4_entry` 出生（`SpawnPoint`，落地不空中坠落）、清房目标 7（HUD 分母 8）、
  坠落平面 1680（1440 + 240）、开场 8 句 + `ch4_intro` 语音 + `chapter_theater.ogg`、事件页 / 权柄 /
  Boss 4「笑面史官」/outro/章末选择按第 53–58 程既有内容生效。

### 全链路（真实路由，无测试专用挂载）

第 3 章章末选择 → 第 4 章开场（8 句 + `ch4_intro` + `chapter_theater.ogg`）→ `ch4_entry` 出生落地 →
真实 `ch4_branch_a/Arena` 清房（锁门 → 波次死亡 → 奖励页 → 计数 1/7）→ `ch4_event` 一次性事件页
（拿 +12 残页 / 读 +8 污染 + 解词，settle 一次、重载不重开）→ Boss 4 → 权柄三选一 → 第 4 章 outro →
章末选择（重写名册）→ 战役结束 + 结局写入 `Profile.endings`。

### 测试改动（逐项，均为新行为下的期望更新）

- `integration_playability`：第 3 章章末由「停章 + 结束屏」改为进入第 4 章开场（`_chapter == 3`、
  未结束、无结束屏、开场眉题/正文/音乐/`ch4_intro` 语音/第 4 章计划生效）；新增 `_test_ch4_big_map`
  （真实链路：`ch4_entry` 出生落地、清房 0/7、进度 8、坠落 1680、地图标题「笑面剧场地图」、真实清
  `ch4_branch_a/Arena` 并推进计数）；事件区/Boss 4 两段由测试专用挂载改为真实路由世界；删除旧第 4 章
  9 房结构遍历、对应「默认清房目标/默认坠落平面」断言与 `_restore_chapter_world` 辅助；第 1 章遗留线性
  结构遍历保留（只服务第 1 章）。
- `integration_ch3_bigmap`：第 3 章末由「停在本章 + 结束屏」改为进入第 4 章开场（`_chapter == 3`、
  未结束、无结束屏、开场眉题、第 4 章计划生效）；清房计数断言移到交棒之前（新章会重置计数）；
  「Boss 已死不二次生成」改为在交棒后手工重挂第 3 章世界、置 `_boss_defeated` 再进 `ch3_boss` 验证。
- `integration_ch4_bigmap`：路由锁改为「第 4 章计划槽已接、大图世界即游戏加载的世界」，章末改锁
  「计划槽仍接、旧世界仍在磁盘」；套件仍自行挂载世界以便一次走完九区（口径已在头注释写明）。
- 路由锁逐条更新：`test_ch2_world`、`test_ch3_content`、`test_ch3_boss`、`test_ch4_plan`、
  `test_ch4_content`、`test_ch4_boss`、`test_ch4_world`；旧第 4 章 9 房/17 门世界与其场景的
  存在性断言全部保留（世界原样留档，只是不再被路由）。
- 过期注释同步：`tests/capture_bigmap_chapters.gd`、`tests/test_map_overlay.gd`。

### 验收

- 单元 **13,551 / 0**（+2：`test_ch2_world` 与 `test_ch3_content` 各补 1 条第 4 章计划存在性断言；
  其余为路由锁逐条替换，数量不变）。
- 十一套集成（全 0 失败）：playability **847**（887 → −40：删除第 4 章旧 9 房结构遍历与两条默认
  清房/坠落断言，新增真实链路/交棒/出生/战斗清房断言；与第 80 程第 3 章接线 913 → 878 同例）/
  ch1_demo 109 / run_save 675 / gamepad 207 / ui_prompts 113 / ch1_event 73 / menus 458 /
  ai_settings 45 / ch2 **2,331** / ch3 **4,364** / ch4 **5,133**。
- 退出泄漏 **10/10**、demo 像素 **40 / 0**。

### 边界

- 未改第 4 章计划内容/波次表/事件文案/Boss 4 数值与机制（镜面弹幕/墨雨/改写/纸页波、HP 520 / 伤害 18 /
  速度 92 全部原样）；未改第 1/2/3 章房间/波次/事件/奖励/`ending_for`；存档形状不变。
- `ch4_shortcut` 仍无游戏内授予（屏障保持封闭）；舞台母题呈现层、Boss 4 机制扩展、战斗密度、
  `mask_enemy`/`seat_husk` 独立数值均未动。第 11–16 项未碰。
- 未推送、未更新网页版、未创建 Release。仓库根 `README.md` 仍写「第 4 章不可达」，待监工安排更新。

## 全流程 1→4 集成验收（第 97 程）

> brief101（任务与 brief99 相同）。第 92 程（brief96）基线跑绿、做完缺口分析后在写验收链之前中断（无提交）；
> 第 93/94/95 程（brief97/98/99）启动即死（日志只有 `[claude-code:unrecognized_model]` 一行）；
> 第 96 程（brief100）无声夭折、无提交，只留下未提交的 `tests/probe_chain_boot.gd`。
> 本程是**全新重跑**，不接续上述任何一程的产物。

### 遗留探针处理

- `tests/probe_chain_boot.gd`（第 96 程遗留、未提交）：实读 40 行、5 条 `check()`——`extends SceneTree`，实例化 `GameFlow`、
  关 `auto_save`、用 `user://probe_profile.cfg`、`reset_profile()`、加载 `scenes/hub/hub.tscn`，断言
  `tutorial_flow` 存在/激活/「第 1 步」，再 `hub.request_run()`，断言新场景是游戏脚本、`_chapter == 0`、
  开场页已开。单独跑过：**5 条断言全过、退出 0**。
- 处理结果：**删除**。它只是本程链路开头（Hub 教学 → `request_run()` → 第 1 章开场）的一段启动探针，
  本身不构成可提交的验收；同一路线已由本程 `_test_full_campaign_chain()` 的前 20 条断言完整覆盖且更强
  （真实教学三步 + 落盘校验 + 开场眉题/标题/配乐/语音）。删除后工作区恢复干净。

### 链路（一条局，真实输入/真实场景/真实存档）

`_test_full_campaign_chain()`（`tests/integration_playability.gd`，+628 断言；接在既有 `_run` 的尾部）。
**无传送作弊、无内部结算函数跳关**：清房靠真实敌人 `take_damage`、走门靠 `MDSGate.use()`、章节推进靠
章末选择，检查点全走 `RunSave` 真实落盘/读回。

新局 → Hub 教学（三步 + `tutorial_done` 落盘）→ `hub.request_run()` → 第 1 章（`ch1_01`…`ch1_06` 逐门实走、
`ch1_03` 书库往返、`ch1_05` 事件页、清房 6/7、休整房、Boss 1、权柄 → outro → 章末选择「带回档案馆」）→
**交棒 2** → 第 2 章大图（九区实走：支路 B 一场、支路 A 两场、事件区一次性、纵井两场、精英一场 = 7、
Boss 2 → 权柄 → outro → 章末选择「替它续气」）→ **交棒 3** → 第 3 章大图（同一路线 7 场 + 事件一次性、
Boss 3 → 权柄 → outro → 章末选择「带读者离开」）→ **交棒 4** → 第 4 章大图（同一路线 7 场 + 事件一次性、
Boss 4 → 权柄 → outro → 章末选择「焚毁名册」）→ 战役结束 + 结局屏。
随后再从**真实 Boss 4 检查点**续玩一次，走另一条章末选择（「重写名册」）拿到第二个结局。

**不变量**：战斗奖励一律取第 3 张休整卡（回复 35 / 墨量 45 / 净化 12），事件页取第 2 项，因此整条链的污染
只受章末选择影响，结局判定只由「仁慈累计」与「焚毁」两件事决定。

### 交棒断言（每处都查）

- 路由：`CHAPTER_PLAN_PATHS[i]` 指向本章计划（`plan.resource_path` 比对）、`MDS_WORLD_FILES[i]` 是本章大图
  世界文件、`MDS_CHAPTER_SCENES[i]` 是本章世界场景、`plan.big_map` 为真、起始区 `chN_entry`。
- 开场：眉题含「第 N 章」、标题 = `CampaignData.chapter(i)["title"]`、开场文本逐句比对、配乐 = `["music"]`、
  语音以 `chN_intro.ogg` 结尾。开场句数按 `CampaignData` 数组实点：第 1 章 6 句、第 2 章 **7 句**、
  第 3 章 **7 句**、第 4 章 8 句——任务单与既有记录把第 2/3 章写成「6 句」是笔误，本程只在此更正一次，
  不逐条改写历史日志；链路断言按数组长度逐句比对，不写死句数。
- 出生：`SpawnPoint` 存在、玩家距标记 < 2 px、`_chain_wait_on_floor()` 落地（非空中坠落）。
- 数字：清房目标 7（第 1 章 6）、HUD 分母「档案  0 / 8」（第 1 章 `/ 7`）、坠落平面 = 入口区高 + 240
  （第 2–4 章实为 1680）、地图标题按 `region` 派生。
- 上一章结转：`demo_cleared`（内存 + 落盘各一次）、仁慈 1/2/3 逐章累计、`Profile.endings` 在通关前保持空、
  进入本章时 `cleared_in_chapter == 0`、`cleared_encounters` 为空、`boss_defeated == false`、残页不低于
  上一章交棒时的值——全部由 `_chain_read_save()` 从**磁盘上的 run save** 读回，不只读内存。

### 跨章结转专项

- **权柄**（第 83 程 `authority.chapter` 口径）：每章 Boss 死后 `_authority_granted_chapter == 本章索引`，
  落盘 `authority.chapter` 同步；第 4 章 Boss 死时的检查点仍带**第 3 章**的 `authority.chapter`（2），
  续玩后三选一重新给（不吞），选完更新为 3。
- **局内存档**：每章交棒后与每章权柄授予后各读回一次 run save（章节、房间、清房进度、仁慈、权柄、
  `boss_defeated` 逐项比对），Boss 死时的检查点另查 `world.boss_defeated == true` 与房间 = 本章 Boss 房。
- **Boss 已死续玩**（第 84 程口径）：目标条文本 = 「笑面史官已经倒下」（按本章 `chapter["boss_name"]`）、
  不二次生成 Boss、不重放权柄、outro → 章末选择 → 战役结束照常。
- **结局**：战役结束时 `flow.last_ending["id"]`、结束屏标题、`Profile.endings`、结局画廊三处一致；
  焚毁路径（第 4 章末选「焚毁名册」）实走 → `burned`；续玩走「重写名册」→ `restored`；两个结局 id 同时
  在 `Profile.endings` 里，画廊两条均已解锁；结束屏 `Echoes` 非空。

### 「复原」判定点的实际落点（核实第 81 程 README 口径）

- `CampaignData.ending_for(won, corruption, mercy, burned)` **没有任何章节参数**：判定只发生在战役结束
  （第 4 章末）。因此「跨章仁慈 ≥ 2 且污染 < 60 可在**第三章末**达成」是第 81 程 README 的过期口径——
  当时第 3 章末就是战役末，第 91 程接通第 4 章后该口径不再成立。
- 本程如实断言：整条链仁慈累计到 3（第 1/2/3 章各选仁慈），第 4 章末选「重写名册」→ `restored`；
  若第 4 章末选「焚毁名册」→ `burned`（`burned` 优先于 `abyss`/`restored`）。判定规则未改。
- 记录（不施工）：仓库根 `README.md` 仍写「可玩第 1–3 章」「第 4 章不可达」「焚毁档案不可达成」与
  「复原可在第三章末达成」，四处均为第 91 程接线后的过期口径；README 更新按第 81 程先例单独排一程。

### 验收中发现并修复的产品缺陷（1 项）

- **Boss 已死检查点续玩会把死掉 Boss 的房间重新锁上**。真实检查点是「击杀发生在 Boss 房里」时写的，
  所以存档位置落在 Boss 房内；`_update_room_locks()` 只跳过「已锁/已清」的房间，续玩时把玩家所在的
  Boss 房重新锁上——于是重放 Boss 入场音效、把「<Boss>已经倒下」的目标条改写成新的击杀命令，
  而权柄三选一已经在后面排着。修复：`_update_room_locks()` 在 `_boss_defeated` 为真时跳过 Boss 房
  （只对 Boss 房生效，普通房间照旧锁门）。
- 既有五个续玩测试都没抓到，因为它们手写的存档都把玩家放在 Boss 房**外**；本程把
  `integration_run_save` 的 aftermath 存档位置改成真实落点（`ch1_boss` 世界原点 x=8960 + Arena 局部
  (640, 280) → `[9600, 490]`，在 `|x|<530`、`-260<y<300` 的入场带内）。**反向验证**：临时回退修复后
  该套件复现 2 条失败，恢复后 0 失败。
- 回归断言：`run_save_aftermath_dead_boss_room_stays_open` / `run_save_aftermath_no_entrance_replay`、
  `chain_resume_dead_boss_room_stays_open` / `chain_resume_dead_boss_no_entrance_replay` /
  `chain_resume_dead_boss_keeps_chapter_music`。

### 基线（收尾实测）

- `--headless --import` / `--quit` 退出 0，无脚本错误。
- 单元 **13,551 / 0**（本程未增删单元测试）。
- 十一套集成（全 0 失败）：playability **1,475**（847 → +628，全部为链路断言）/ ch1_demo 109 /
  run_save **677**（675 → +2 条死 Boss 房不重锁回归）/ gamepad 207 / ui_prompts 113 / ch1_event 73 /
  menus 458 / ai_settings 45 / ch2 **2,331** / ch3 **4,364** / ch4 **5,133**，合计 **14,985**。
- 退出泄漏 **10/10 clean**；demo 像素 **40 / 0**。

### 未修记录（只记录，不施工）

- 仓库根 `README.md` 四处过期口径（可玩范围、第 4 章不可达、焚毁档案不可达成、复原判定点）——单独一程。
- 沿用既有记录：`ch2_shortcut`/`ch3_shortcut`/`ch4_shortcut` 无游戏内授予、第 60 程样图问题 1/3/5/6/7、
  舞台母题呈现层、Boss 4 机制扩展、战斗密度、`mask_enemy`/`seat_husk` 独立数值、设置页全屏不持久、
  暂停确认取消后的 one-shot 连接残留、`NPC.interact()` 死代码、`_resume_restored` 只写不读。
- 第 11–16 项未碰、未新增待确认条目。

## 例行扫描（第 101 程）

> brief107，第 100 程例行扫描的第四次接力重跑（brief104/105/106 对应会话均启动即死、
> 零产出无提交）。本程先收尾第 100 程中断留在工作区的 revive 存档修复（任务 −1），
> 再跑完整基线（任务 0），再做六面例行扫描（任务 1）。只修玩家真会撞上的产品行为
> 缺陷，不碰第 11–16 项待拍板内容、不改可达性/章节路由/结局判定/存档形状。
> 开工时 `pgrep -af "bin/claude"` 已确认无并行会话。

### 任务 −1 · 收尾未提交的 revive 存档修复

工作区原有的三个文件改动（`scripts/core/run_save.gd`、`scripts/game.gd`、
`tests/test_run_save.gd`）核对属实：不灭档案（资源名`不朽档案`）的复活是「每局一次」，
但用掉的标志只活在 `RelicEffects` 上，从不进 run save；复活用掉后存检查点再续玩，
遗物被重新武装，同一局第二次致命伤害又被免费救回。

- **探针复现（任务 −1 要求）**：新写临时探针走真实存档链路（装遗物 → 打死 → 复活
  40 生命 → `save_run_now()` → 新场景 resume → 再打死），修复下 15/15 通过；`git stash`
  回退 `run_save.gd`+`game.gd` 后复现 3 条失败（`probe_checkpoint_carries_flag`、
  `probe_resume_flag_restored`、`probe_second_death_is_final`）。只读代码不算数，已按
  要求实跑。
- **改动**：`run_save.gd` 的 `_has_valid_shape` 把 `world.relic_revive_used` 与
  `boss_defeated` 一起做 bool 校验；`game.gd::_build_run_save` 写该键、
  `_restore_run_save` 恢复到 `relic_effects.revive_used`（旧档缺键 → false，保持原行为）。
- **顺手修**：diff 里 `check_roundtrip` 的定义行被并成一行（`... -> void:\tRunSave.write(...)`），
  虽仍是合法 GDScript，但不符合本文件风格，已恢复成两行。
- **回归**：单元补 `_test_relic_revive_flag`（读回 true/false、旧档缺键默认 false、
  非 bool 拒档删除），`test_run_save` 82 → 90；`integration_run_save` 补真实链路
  （复活 → 检查点 → 续玩 → 第二次死亡必须致命、旧档缺键默认未用），675 → 695。
  提交 `93bb2b8`，工作区回到干净基线后才开工。

### 任务 0 · 基线复核（HEAD `32cf987` + 任务 −1 提交，Godot 4.7.stable.official.5b4e0cb0f）

- `--headless --path . --import` / `--headless --path . --quit` 退出 0。
- 单元 `tests/run_tests.gd` **13,559 / 0**（基线 13,551 + 任务 −1 的 8 条）。
- 十一套集成全部跑完、全 0 失败：playability **1,475** / ch1_demo **109** /
  run_save **695** / gamepad **207** / ui_prompts **113** / ch1_event **73** /
  menus **458** / ai_settings **45** / ch2 **2,331** / ch3 **4,364** / ch4 **5,133**，
  合计 **15,003**（基线 14,985 + 任务 −1 的 18 条）。
- `tests/check_exit_clean.sh 10` → **10/10 clean**；`check_pixel_assets.py --demo` → **40 / 0**。
- 三个大图集成套件（第 2/3/4 章）按要求跑完，未跳过。

### 任务 1 · 六面扫描结论

| 扫描面 | 查了什么 · 怎么查 | 结论 |
|---|---|---|
| 1 关闭回退 | 窗口关闭（`GameFlow._notification` → `save_run_on_exit`）、失焦暂停（`game.gd._notification`）、暂停→设置→返回、返回 Hub（`return_to_hub` 清 run save）、重开（`_do_restart`）、暂停确认的取消路径；真实主场景 + 暂停菜单探针 | **发现 1 项真实缺陷（已修）**：取消一个确认后再确认另一个会同时执行两个动作，见下 |
| 2 焦点 | 标题首帧（有档优先「继续本局」，`integration_menus` 已锁）、暂停/设置子页返回、Hub 各覆盖页开页抓焦点与关页还焦点（逐页探针）、手柄方向键只做焦点导航 | **发现 1 项一致性缺口（已修）**：档案馆页关页不还焦点（Hub 轮询按键，玩家不可见），见下 |
| 3 存档边界 | 跨章权柄（`authority.chapter`）、Boss 已死检查点、`_reward_pending` 期间检查点沉默、旧检查点按文件内章节兼容、坏档删除与 `.bak` 恢复、事件页/权柄三选一打开时关窗口 | 全部仍成立，无新增缺陷（`integration_run_save` 695 断言覆盖，含本程新增的 revive 链路） |
| 4 性能 | 同第 68/69/70 程口径实测：`main.tscn` 加载 2,671.8 ms、实例化+挂载 703.4 ms、第 1 章逐房冷 442–450 / 热 446–454 ms、Boss 帧均 **8.33 ms**、门过渡 **225.7 ms**、Hub load 322.2 / ready+add 425.0 / 首帧 492.5 ms | 与基线同量级（Boss 帧与第 21/22/68/69/70 程同为 8.33 ms；门过渡 225.7 ms 在第 70 程 225.3 与第 73 程 226.3 之间），**只记录不优化** |
| 5 文案 | Hub NPC 职能描述（陆沉/阿砚/咕噜/闻烬/白榆 11 条）、档案馆满级行、局内商店与休整卡、遗物卡、污染分档警告（15/30/45% 与冷却 20/35%）、发狂提示（40% 上限、30 秒）、残碑重复给 25/30、权柄卡、Boss 入场/阶段、结局正文与余味、帮助页、死亡提示 | **发现 1 项真实缺陷（已修）**：死亡横幅把遗物叫成「不灭档案」，见下 |
| 6 回归抽查 | 隐藏书库、结局画廊与余味、档案馆 Lv.10 满级行、词服务与已拥有货架、阿砚问候不扣碎片、第 2/3/4 章九区连通/门/Boss/章末交棒 | 全部由本次跑绿的十一套套件背书，无回归 |

### 本程修的三处（每处：探针复现 → 修 → 补断言 → 跑相关套件）

**1. 暂停确认取消后仍武装，确认另一个会执行两个动作（真实缺陷，会丢局）**

- 复现：真实主场景 → 暂停 → 点「返回档案馆」→ Esc 取消 → 点「重新开始」→ 确认。
  修复前 `current_scene` 变成 `hub.tscn`（`_do_quit` 先跑、`return_to_hub()` 清了本局，
  随后 `reload_current_scene()` 的 `current_scene` 已是 null 并报
  `Parameter "current_scene" is null`）——玩家要求「重开本局」，实际被踢回档案馆且本局作废。
  第 73 程把这条记成「当前不可见」，实测可见。
- 根因：两个按钮共用同一个 `ConfirmationDialog`，各自把动作以 `CONNECT_ONE_SHOT` 挂到
  `confirmed`，取消时从不断开；第二次 `_ask_confirm` 只在同一个 action 已连接时才断开，
  于是上一次的 `_do_quit` 留了下来。
- 修法：改为单一待执行槽 `_confirm_action`；对话框只连一次 `confirmed` → `_run_confirm()`，
  每次 `_ask_confirm` 先清空再武装，确认时取出执行一次；`canceled` 与 `visibility_changed`
  （隐藏即取消）都清空。
- 回归：`test_demo_onboarding` 暂停确认用例改锁「重新武装会替换上一个动作、对话框只保留
  1 条连接、取消后不再武装」（单元 13,559 → 13,565）；`integration_gamepad` 在真实暂停
  菜单上 +5 条（取消退出后未武装、重开只武装重开、连接数 1、Esc 取消重开未武装、
  Esc 取消后暂停菜单仍在），207 → 212。
  提交 `fb41db8`（该提交信息里把基线误写成 204，实际是 207，以此处为准）。
- 说明：`integration_gamepad` 的反向验证没能跑完（回退 `pause_menu.gd` 后新断言访问不存在
  的 `_confirm_action` 让该套件挂住），已用真实场景探针作为反向证据并在提交信息里注明；
  修复后该套件 212/0 实跑通过。

**2. 死亡横幅把遗物叫成「不灭档案」（真实缺陷，文案与行为不符）**

- 复现：`resources/relics/immortal_archive.tres` 的 `display_name` 是**不朽档案**
  （GDD §9 与结局文本同）；玩家只可能在背包（`inventory_ui`）、奖励卡（`RunLoot`）、
  咕噜货架（`hub._build_shop`）看到这个名字。而 `DeathHintData.RELIC_LINES` 8 句全写
  「不灭档案」，等于复活时告诉玩家是另一件东西救了他。
- 修法：只改 8 句文案为「不朽档案」，复活数值（40 生命）、触发条件、按 seed 轮换不变。
- 回归：`test_death_hints` 补「提示名 == `RelicData.display_name`」逐句断言，
  163 → 183；第一章 demo 集成 109/0。回退文案时复现 16 条失败。提交 `55231c7`。

**3. 档案馆页关页不还焦点（一致性缺口，当前玩家不可见）**

- 复现：Hub → 陆沉「档案馆升级」→ 关页，`viewport.gui_get_focus_owner()` 变成 null；
  同批探针里设置页、说明页、对话都还焦点，只有档案馆页与「言灵」面板不还。
- 玩家可见性核实：Hub 用 `_process` 轮询 `interact`/`settings`/`codex`/`help`，不靠焦点
  导航，所以关页后仍能走动、对话、重开页面（探针 7/7 验证）。故按**一致性缺口**处理，
  不当缺陷计入收口判定。
- 修法：按 `shop_ui`/`settings_menu` 同一套接法补 `_return_focus`（`open()` 记、
  `close()` 还原）。
- 回归：`integration_menus` 档案馆块加替身按钮抓焦点，断言 B 关闭后焦点回到它，
  458 → 459；回退 `archive_ui.gd` 时该断言复现失败。提交 `e988541`。
- 未改：「言灵」面板（`npc_inspire_ui`）与说明页（`help_ui`）同样不还焦点，属同一族；
  本程不为没有玩家可见影响的路径扩大改动面，仅记录。

### 收口判定

六个面核对完，发现的都是**玩家真会撞上的产品行为缺陷**（暂停确认会丢局、死亡横幅报错
物品名），另有一项零可见影响的一致性缺口。**按 DECISIONS.md「第一章收口规则」，本程不
宣告第一章打磨达标**：六个面里仍有上述修复，且第 11–16 项与若干未修记录仍开放。是否宣
告达标、以及随后的里程碑推送与网页更新，由监工判断与执行；本程只记录结论与证据。

### 未修记录（只记录，不施工）

- 说明页与「言灵」面板关页不还焦点（同第 2 项，当前无玩家可见影响）。
- 沿用既有记录：`ch2_shortcut`/`ch3_shortcut`/`ch4_shortcut` 无游戏内授予、第 60 程样图问
  题 1/3/5/6/7、舞台母题呈现层、Boss 4 机制扩展、战斗密度、`mask_enemy`/`seat_husk`
  独立数值、设置页全屏不持久（`settings_menu._toggle_fullscreen` 只调 `DisplayServer`，
  不写 Profile）、`NPC.interact()` 死代码、`_resume_restored` 只写不读。
- 第 11–16 项未碰、未新增待确认条目。

### 未改项

- 章节路由、可达性、结局判定、存档形状（除任务 −1 明确新增的 `world.relic_revive_used`
  一个 bool 键）、数值平衡、NPC 立绘均未动。
- 未推送、未更新网页版、未创建 Release。

## README 口径更新（第 99 程）

> brief103。本程只改仓库根 `README.md` 的过期口径：把可玩范围从第 1–3 章更新为第 1–4 章、
> 把第 4 章从「已建成但未开放」并入可玩范围（整节删除）、把五个结局写成全部可达并写明
> 判定只在战役结束、同步测试规模数字。不改任何游戏代码/场景/资源/测试/配置，不改章节
> 路由与可达性，不碰第 11–16 项待拍板内容。**第 98 程（brief102）实际未死**——它只是被
> `session102.log` 里的 `[claude-code:unrecognized_model]` 警告误判为「启动即死」，真实情况
> 是该会话仍在跑同一个 README 任务；本程与它同时改到 `README.md`，见下方「并发写入处理」。

### 核实的旧口径（逐条，行号为本程实读）

| 位置 | 旧口径 | 现状（核实依据） | 处理 |
|---|---|---|---|
| 第 11 行（可玩范围首句） | 「当前 demo 可玩第 1–3 章……第三章章末选择后进入结局屏」 | `game.gd::_complete_chapter`：第 1 章末 → `_start_chapter(1)`、第 2 章末 → `_start_chapter(2)`、第 3 章末 → `_start_chapter(3)`、第 4 章末 → `_finish(true)`（第 91 程接线） | 改为第 1–4 章，结局屏在第 4 章末 |
| 第 15 行（第 3 章条目） | 「本章章末停章，不再继续」 | 第 46 程的停章已被第 91 程取代，第 3 章末进第 4 章 | 删掉该句 |
| 第 22 行（结局） | 「可达成 4 个结局」「复原……在第 1–3 章中至少两章选仁慈」「焚毁档案……暂不可达成」 | `CampaignData.ending_for(won, corruption, mercy, burned)` 无章节参数、只在战役结束调用；优先级 burned → abyss(≥60) → restored(mercy≥2) → unfinished，失败为 interrupted | 改为五个结局全部可达，写明判定点与优先级 |
| 第 26–30 行（「已建成但未开放」整节） | 「第 4 章……目前不可达」「计划尚未接入主流程」「焚毁档案……不能到达」 | 第 91 程已接入：`CHAPTER_PLAN_PATHS[3]`/`MDS_WORLD_FILES[3]`/`MDS_CHAPTER_SCENES[3]` 全部指向第 4 章 | 整节删除；第 4 章条目并入「当前可玩范围」 |
| 第 30 行（捷径说明） | 「第 2–4 章的捷径屏障目前都没有游戏内授予来源」 | 仍然属实：`scripts/` 全库无任何 `ch2_shortcut`/`ch3_shortcut`/`ch4_shortcut` 授予，只有世界 JSON 与计划里的 `requires` | **保留**为独立条目，未虚构来源 |
| 第 21 行（里程碑条目） | 「吞噬 / 归档权柄、四档信任分层、结局画廊」（v0.12.0/T17 旧口径） | 本次里程碑内容见「项目现状」与第 91/97 程专节 | 改为第 2–4 章大地图、事件与 Boss 接入主流程 + 全流程 1→4 验收 |
| 第 97 行（测试数字） | 单元 13,549、集成 14,326 | 本程实测 13,551 / 14,985 | 更新，并点出含全流程 1→4 链路 |
| 第 103 行（开发状态末条） | 「第 1–3 章已接入……第 4 章……仍不可达」 | 第 1–4 章均已接入 | 改为「第 1–4 章均已接入主流程」 |

### 改写点

- 「当前可玩范围」：首句改为第 1–4 章接续并写明第 4 章末进结局屏；新增第四章「笑面剧场」
  条目（9 区 / 22 门 / 纵向 / 单向落台 / 长椅 / 捷径 / 事件 / 隐藏书库 / 专属剧场插画 /
  清房目标 7 / Boss 4 四类招式 / 章末战役结束）。
- 「章末选择与结局」：五个结局全部可达成，逐条写明条件与优先级；明确「判定只看战役结束
  （第四章末）时的状态」，不再出现「第三章末达成」的过期说法。
- 「已建成但未开放」：整节删除；其中仍然属实的捷径屏障说明提为「当前可玩范围」下的独立条目。
- 「武器与遗物」：原文「demo 开放其中各 6 把 / 6 件 / 6 种」在第二至四章可达后已不成立——
  `RunLoot._weapon_pool`/`_relic_pool`（`scripts/core/run_loot.gd:90-95`）只在 `chapter == 0`
  返回 `DEMO_WEAPONS`/`DEMO_RELICS`，第 2–4 章返回完整 `WEAPONS`(12)/`RELICS`(9)；
  `memory_stele.gd:92` 按 `ch1` 前缀同样分流。改为「第一章 6 把 / 6 件，第二至四章从完整
  内容库抽取」。
- 「信任分层」：NPC 个人事件的闸门是 `Profile.demo_cleared`，由 `_complete_chapter` 在
  **第 1 章交棒时**置位（`scripts/game.gd:2300-2306`），不是战役结束；「通关一次 demo」
  改为「打通第一章」，否则在第 4 章末之前都读着像不可触发。
- 「运行」第 3 步按四章接续改写；「开发状态」数字与末条同步。

### 复核数字与来源（本程基线实测，与 brief103 预期逐项一致）

- `--headless --import` / `--quit` 退出 0。
- 单元 **13,551 / 0**；十一套集成 **1,475 / 109 / 677 / 207 / 113 / 73 / 458 / 45 / 2,331 / 4,364 / 5,133**（合计 **14,985**）全 0 失败，三个大图套件跑完。
- 退出泄漏 **10/10 clean**；demo 像素资产 **40 / 0**。
- README 里其余数字本程逐条复核：`scripts/` 155 个 `.gd` / 26,991 行（「约 2.7 万行」成立）；
  词条 95（`resources/words/*.tres` 95 个，`test_content_expanded` 锁 39/29/27）；开局 18
  （`Profile.DEFAULT_OWNED` 18、`DEFAULT_DECODED` 6、`DEMO_FRAGMENT_WORDS` 12）；
  `DEMO_WEAPONS` 6 / `DEMO_RELICS` 6 / `WEAPONS` 12 / `RELICS` 9 / `ENEMIES` 14；
  13 种法术形态（`SpellStyle.NAMES`）；6 首配乐（`assets/audio/manifest.json`）；
  第 2/3/4 章各 9 区 22 门（20 有向 + 2 只到达）与 7 个遭遇（世界 JSON 实点）；
  第 4 章 9 个房间全部 `backdrop_path = smiling_theater.png`，故写「全章背景」而非「舞台区」；
  第 1 章计划 4 combat + 1 elite + 1 event + rest + boss + vault，`CLEAR_ROOM_TYPES` 派生清房
  目标 6。旧口径里「demo 6 敌人」不成立（第 1 章波次用 7 种刷怪 id），本程未沿用该说法。

### 并发写入处理（第 98 程残留）

- 本程开工时 `SUPERVISOR_STATUS.md` 记第 98 程为「启动即死」；实际第 98 程会话仍在运行，
  并在本程读文件期间持续修改 `README.md`（本程先后读到 md5 `5888e2f5…` → `024b9452…` →
  `dfaa2b4f…` 三个版本）。
- 处理：请第 98 程会话停手并交回本程（它已确认停手、未提交、未动状态文件与记忆）；本程按
  冻结后的最终内容逐行复核（含把「舞台区专属插画」更正为「全章背景」、把「跨章累积仁慈」
  更正为「本局仁慈」）后再提交。**账面归属**：`README.md` 的改动由第 98 程会话起草、第 99
  程会话复核并提交（提交 `77e673a`）；状态文件、记忆文档与全部提交均只由本程会话写入，
  避免两个会话同时向 5,784 行的手维护状态文件追加。
- 基线由两个会话各自独立复跑，数字逐项一致（见上）。

### 未改项

- 游戏代码 / 场景 / 资源 / 测试 / 配置零改动；章节路由、可达性、存档形状、数值、NPC 立绘未动。
- 版本号未动：`project.godot` 的 `config/version` 与标题屏仍 `0.11.0-demo`，README 不写版本号；
  版本口径若需调整属另行拍板，本程不自造新版本号、不新增 Release 计划。
- 第 11–16 项（`ch2_shortcut`/`ch3_shortcut`/`ch4_shortcut` 来源、电梯速度、相机/HUD、
  视野压缩、海面母题）未碰、未定口径。
- 未推送、未更新网页版、未创建 Release。

## README 口径更新（第 81 程）

> brief85。本程只改仓库根 `README.md`：把「当前可玩范围」从第一章更新为第 1–3 章、
> 把「已建成但未开放」缩到只剩第 4 章、同步测试规模数字；不改任何游戏代码/场景/
> 资源/测试/配置，不改章节路由与可达性，不碰第 11–16 项待拍板内容。

### 核实的旧口径（逐条）

| 位置 | 旧口径 | 现状（核实依据） | 处理 |
|---|---|---|---|
| 当前可玩范围首句 | 「当前版本是 Chapter 1 demo……打通第一章……查看结局」 | `game.gd::_complete_chapter`：第 1 章末 → `_start_chapter(1)`、第 2 章末 → `_start_chapter(2)`、第 3 章末 → `_finish(true)`；只有第 3 章末进结局屏 | 改写为第 1–3 章 |
| 已建成但未开放 | 「第 2–4 章……主流程仍停在第一章章末，目前不可达」 | `CHAPTER_PLAN_PATHS[0..2]` 已接第 1–3 章计划，`[3]` 仍为空；`MDS_WORLD_FILES[2]` / `MDS_CHAPTER_SCENES[2]` 已指第 3 章大图（第 80 程） | 只保留第 4 章 |
| 暂不可达的原因 | 「第一章在 demo 边界停章；第 3/4 章的章节计划尚未接入主流程……」 | 第 1 章不再停章、第 3 章已接入；只剩第 4 章 | 改写；保留捷径屏障说明 |
| 章末选择与结局 | demo 可达 3 个结局；「复原」不可达成 | `_apply_chapter_choice` 按章末选项累加 `_mercy`（第 1/2/3 章选项 0 各 +1），`_start_chapter` 不重置；第 3 章末 `_finish(true)` 调 `ending_for(true, corruption, _mercy, _burned_final)`，仁慈 ≥ 2 且污染 < 60 → `restored`（`tests/test_campaign.gd::mercy_restores_archive`） | 改为 4 个结局可达，写明条件 |
| 三章大图验收数字 | 2,315 / 4,358 / 5,133 | 本程实测 2,331 / 4,364 / 5,133 | 更新 |
| 运行第 3 步 | 「打通第一章后进入章末选择与结局屏」 | 第 1 章后接第 2 章、第 2 章后接第 3 章、第 3 章末才进结局屏 | 按三章接续改写（本程唯一一处超出任务单点名四段位置的改动，属可达性表述） |
| 开发状态数字 | 单元 13,490、集成 14,296、像素 36/0 | 本程实测 13,549、14,326、40/0 | 更新 |
| 开发状态末条 | 「第 2–4 章内容已入库……三章都不可达」 | 第 1–3 章已接入，第 4 章不可达 | 改写 |

### 改写点

- 「当前可玩范围」：首句改为第 1–3 章接续；新增第二章「呼吸废墟」、第三章「无光海」条目（9 区 / 22 门 / 纵向 / 清房目标 7 / Boss 2/3 机制 / 第 3 章末停章）。
- 「章末选择与结局」：demo 可达 4 个结局，写明「复原」= 跨章仁慈 ≥ 2 且污染 < 60；「焚毁档案」仍只在第四章流程触发、不可达成。
- 「已建成但未开放」：只保留第 4 章「笑面剧场」；不可达原因只剩第 4 章计划未接入；保留「捷径屏障无游戏内授予来源」说明（第 11/16 项未拍板）。
- 「运行」第 3 步按三章接续改写。
- 「开发状态」：测试数字按本程基线实测更新，末条改为「第 1–3 章已接入、第 4 章不可达」。
- 版本：`project.godot config/version` 与标题屏仍 `0.11.0-demo`（本程未改）；README 不写版本号，实测值只记录在此。

### 复核数字（本程基线实测）

- `--headless --import` / `--quit` 退出 0、`ERROR` 0。
- 单元 **13,549 / 0**；十一套集成 **878 / 109 / 631 / 207 / 113 / 59 / 456 / 45 / 2,331 / 4,364 / 5,133**（合计 **14,326**）全 0 失败。
- 退出泄漏 **10/10 clean**；demo 像素资产 **40 / 0**。

### 复核发现（只记录、未改）

- 第 2/3 章奖励池走 `ContentLibrary.WEAPONS` / `RELICS`（12 / 9），demo 实际可获得的武器 / 遗物超过 README 写的「demo 6 把 / 6 件」；按任务单「6 武器 / 6 遗物沿用第 74 程口径」未改。
- `scripts/` 实测 **155 个 `.gd` / 26,862 行**（第 74 程记录 26,849 行）；「155 个 / 约 2.7 万行」仍成立，未改。
- `tests/check_pixel_assets.py` 的 `DEMO_ENEMIES` 未随第 3 章可达扩展：`ROOM_WAVES[2]` 使用的 `mirror_sniper` / `hanging_scribe` / `echo_enemy` 不在清单（`choir_summoner` 同样缺失，为既有缺口）；像素门禁仍 40/0。属测试覆盖缺口，本程不改测试。

### 未改项

- 游戏代码 / 场景 / 资源 / 测试 / 配置零改动；章节路由、可达性、存档、数值、NPC 立绘未动。
- 第 11–16 项（`ch2_shortcut` / `ch3_shortcut` 来源、电梯速度、相机 / HUD、视野压缩、海面母题）未碰、未定口径。
- 未推送、未更新网页版、未创建 Release。

## 例行扫描（第 83 程）

> brief87。第 1–3 章已可达 + Hub + 各系统。本程只做例行扫描与「扫描发现的
> 产品行为缺陷」修复，不开新功能、不碰待确认第 11–16 项、不改章节可达性
> （第 4 章仍不可达）、不推送、不更新网页版、不创建 Release。

### 任务 0 · 基线核验（HEAD `8773a11`，Godot 4.7.stable.official.5b4e0cb0f）

- `--headless --path . --import` / `--quit` 退出 0。
- 单元 `tests/run_tests.gd` **13,549 / 0**（与第 81 程交接一致）。
- 十一套集成全部跑完、与交接逐套件一致、全 0 失败：
  `integration_playability` **878** / `integration_ch1_demo` **109** /
  `integration_run_save` **631** / `integration_gamepad` **207** /
  `integration_ui_prompts` **113** / `integration_ch1_event` **59** /
  `integration_menus` **456** / `integration_ai_settings` **45** /
  `integration_ch2_bigmap` **2,331** / `integration_ch3_bigmap` **4,364** /
  `integration_ch4_bigmap` **5,133**。
- `tests/check_exit_clean.sh` **10/10 clean**；`check_pixel_assets.py --demo`
  **40 / 0**。
- 结论：基线无漂移，可施工。

### 扫描面逐项结论

1. **关闭回退（各覆盖页 → 上一层/焦点）——未发现新缺陷。**
   `game.gd::_input` 的模态顺序（权柄/归档必选模态吞 B/Esc、地图先于覆盖页、
   暂停先退设置子页）未变；暂停/设置/键位/背包/图鉴/帮助/地图/商店/事件/
   对话/结局屏/结局画廊逐页复核；第 2/3 章新可达的大图地图沿用同一
   `MapOverlay`（自带暂停、M/Esc/暂停均可关），结局屏与画廊在胜利/失败/
   未解锁状态下均有出口；无死路、无 B/Esc 不一致。
2. **焦点（标题/暂停/子页/商店/事件/对话/画廊）——未发现新缺陷。**
   标题有/无局内存档分别聚焦「继续本局」/「开始旅程」；暂停打开即抓可用项；
   设置子页关闭把焦点还给打开者；局内商店、事件页、对话、画廊、权柄/归档/
   奖励打开即抓首个可点项；键盘/手柄切换由 `GameFlow.input_device_changed`
   统一驱动。
3. **存档边界（run save 写盘/续玩/坏档，含新的跨章边界）——
   发现并修复 1 项真实产品行为缺陷（含向后兼容分支），见下。**
   其余核对：进房/事件结算/商店购买与关闭/残碑/宝箱/Boss 死亡/权柄/暂停/
   失焦/窗口关闭均写盘；奖励选择页故意不写（续玩重放未选奖励）；死亡在
   归档模态前清档、失败 `_finish` 清档、回 Hub/重开/结束战役清档；坏主档
   回退 `.bak`、双坏档丢弃并提示；第 1 章 → 第 2 章、第 2 章 → 第 3 章交棒
   的 `demo_cleared` 落盘、章节切换、续玩恢复、Boss 已死不二次生成均复跑。
4. **性能（只记录、不优化）——未发现退化信号。** 临时探针
   `tests/probe_pass83_perf.gd`（测后删除）在真实主场景内实测，1 个新进程
   样本、与第 68–77 程同口径：
   - Hub 冷加载 `load` **974.7 ms**、`_ready`+首帧 **502.8 / 401.7 / 375.3 ms**
     （第 72–73 程 403–1095 / 355–557，同量级）。
   - `main.tscn` `load` **2,225.6 ms**、实例化+首帧 **845.8 ms**
     （第 72–77 程 1,710–2,922 / 633–846，同量级）。
   - 第 1 章首房 120 帧：avg **8.25 ms**、p95 **8.68 ms**
     （120 FPS 预算 8.33；第 72/73 程 8.18–8.33）。
   - Boss 房加载 **447.4 ms**；Boss 战 120 帧 avg **8.43 ms**、p95 **8.74 ms**
     （第 72/73 程 8.33 / 8.72–8.84）。
   - 门过渡 `ch1_rest.right1 → ch1_boss` **253.71 ms**（第 72/73 程测的是
     `ch1_01.right1 → ch1_02` 225–275 ms；门不同，仅记录同量级）。
5. **文案（第 1–3 章 + Hub + 帮助页）——发现并修复 1 项过期文案，见下。**
   抽查第 1–3 章事件/章末/权柄/Boss 文案键与 Hub NPC 职能描述，未发现新的
   行为不符。记录未改：噩梦难度说明「只有最熟练的构筑能走完四章」以完整
   战役为口径（第 4 章已建成未开放，与 README 的 demo 范围不同口径，属设计
   意图）；`game.gd` 的「这一章还没有地图」分支在四章都有 MDS 地图后已不可
   达（死文案，无行为影响）。
6. **回归抽查——全部通过。** 隐藏书库真实 `door1` 进入/返回无冻结；结局
   余味未解锁不泄露、已解锁展示；档案馆满级提示与禁用行；第 69/70/72/73 程
   修复的 NPC 文案/词服务/商店已拥有/阿砚问候断言；第 78 程四敌专属美术；
   第 80 程第 3 章可达链路（开场 → `ch3_entry` → 真实清房 → 事件 → Boss 3 →
   权柄 → outro → 章末停章）均在单元与对应集成套件中复跑通过。

### 修复与回归断言

**1）跨章 Boss 检查点续玩会吞掉本章权柄三选一（真实产品行为缺陷）。**
`_on_boss_died` 先写 Boss 死亡检查点、再 `await _grant_chapter_authority()`；
`_resume_boss_aftermath()` 只用 `_authority.authority == null` 判断是否补授予。
权柄跨章携带后，第 2/3 章的检查点里 `authority` 非空（是上一章的），续玩被
误判为「本章已授予」，直接进 outro、本章三选一不再出现。探针在真实主场景
复现（第 2 章 Boss 房 `boss_defeated=true` + 携带第 1 章 `revive` 的检查点，
续玩 2 秒后 `authority_choice_open = false`）。修复：新增
`_authority_granted_chapter`（默认 `-1`），授予时记 `_chapter`，写入
run save 的 `authority.chapter`，恢复时读回；`_resume_boss_aftermath()` 改为
「没有权柄 **或** 当前权柄不是本章授予的」才补授予。旧检查点没有该键时按
文件内保存的章节解释（恢复发生在 `_ready`，早于 `_start_chapter`，不能用
运行时 `_chapter` 兜底），保持旧续玩行为；存档只多一个键、无需迁移。
回归断言：`tests/integration_run_save.gd` **+26**（631 → 657）——第 2 章已
授予后写盘续玩不重开（+2）、携带第 1 章权柄的检查点续玩补开本章三选一并
授予后进 outro（+17）、旧形状检查点仍不重开（+7）。

**2）帮助页把地图写成「地图（第一章）」（过期文案）。**
第 2/3 章已有可用大图地图（`MapOverlay` 按章节区域显示标题），帮助页仍写
「地图（第一章）」。改为「地图」，与键位页一致。回归断言：
`tests/integration_menus.gd` **+2**（456 → 458）——帮助页探索列存在标签恰为
「地图」的行、按键等于 `GameFlow.input_label(&"map")`。

### 未修记录（只记录，不新增待确认条目）

- 噩梦难度说明「走完四章」以完整战役为口径，第 4 章当前不可达；属设计意图，
  未改。
- `game.gd::_input` 的「这一章还没有地图」在四章都接入 MDS 后不可达，属死
  文案，无行为影响，未改。
- 沿用第 73 程既有记录：暂停确认取消后的 one-shot 连接残留（当前不可见）、
  `NPC.interact()` 死代码、设置页全屏切换不持久、第 60 程样图问题 1/3/5/6/7
  维持原结论。
- 第 11–16 项未碰、未新增待确认条目；第 4 章仍不可达。

### 收尾复跑（全绿）

- 单元 **13,549 / 0**（本程只加集成断言，单元不变）。
- 十一套集成 **878 / 109 / 657 / 207 / 113 / 45 / 458 / 59 / 2,331 / 4,364 /
  5,133**（合计 **14,354**），全 0 失败；三个大图套件均跑完。
- `--headless --import` / `--quit` 退出 0；退出泄漏 **10/10 clean**；
  demo 像素 **40 / 0**。
- 临时探针测后删除；工作区提交后干净；未推送、未更新网页版、未创建 Release。

## 例行扫描（第 84 程）

> brief88。第 1–3 章已可达 + Hub + 各系统。本程只做例行扫描与「扫描发现的
> 产品行为缺陷」修复，不开新功能、不碰待确认第 11–16 项、不改章节可达性
> （第 4 章仍不可达）、不推送、不更新网页版、不创建 Release。本程会话在提交
> 与写状态文件前中断，由第 85 程接力核验、跑通基线、提交并补记本节。

### 任务 0 · 基线核验（HEAD `1674457`，Godot 4.7.stable.official.5b4e0cb0f）

- `--headless --path . --import` / `--quit` 退出 0。
- 单元 `tests/run_tests.gd` **13,549 / 0**。
- 十一套集成（全 0 失败）：`integration_playability` **878** /
  `integration_ch1_demo` **109** / `integration_run_save` **657** /
  `integration_gamepad` **207** / `integration_ui_prompts` **113** /
  `integration_ch1_event` **59** / `integration_menus` **458** /
  `integration_ai_settings` **45** / `integration_ch2_bigmap` **2,331** /
  `integration_ch3_bigmap` **4,364** / `integration_ch4_bigmap` **5,133**。
- `tests/check_exit_clean.sh` **10/10 clean**；`check_pixel_assets.py --demo`
  **40 / 0**。
- 结论：基线无漂移，可施工。

### 扫描面逐项结论

1. **关闭回退——未发现新缺陷。** 暂停/设置/键位/背包/图鉴/帮助/地图/商店/
   事件/对话/结局屏/画廊逐页复核；第 2/3 章地图沿用同一 `MapOverlay`
   （自带暂停、M/Esc/暂停均可关）；设置页子页（AI/键位/帮助）先关子页再关
   设置。
2. **焦点——未发现新缺陷。** 标题有/无存档、暂停菜单、设置子页返回、商店/
   事件/对话/画廊首帧均抓焦点；键鼠/手柄切换由 `input_device_changed` 刷新
   提示与关闭键文案。
3. **存档边界——修复 1 项（见下）。** 第 1→2、2→3 交棒的 `demo_cleared`
   落盘、章节切换、续玩恢复、Boss 已死不二次生成由 `integration_run_save`
   复跑通过；第 83 程的 `authority.chapter` 键（跨章 Boss 检查点续玩补开
   本章权柄三选一、旧形状检查点兼容）抽查一次，657 → 659 全绿、行为未
   回退。
4. **性能（只记录，未优化）——未发现退化信号。** 临时探针（测后删除）在
   真实主场景内实测，1 个新进程样本、与第 68–83 程同口径：Hub 冷加载
   `load` **960.9 ms**、`_ready`+首帧 **550.7 / 389.8 / 393.5 ms**
   （第 83 程 974.7 / 375.3–502.8）；`main.tscn` `load` **2,217.1 ms**、
   实例化+首帧 **1,020.4 ms**（第 72–83 程 1,710–2,922 / 633–1,020）；
   第 1 章首房 120 帧 avg **8.20 ms**、p95 **8.90 ms**（第 83 程 8.25 /
   8.68）；Boss 房加载 **430.1 ms**、Boss 战 120 帧 avg **8.33 ms**、
   p95 **8.79 ms**（第 83 程 447.4 / 8.43 / 8.74）；门过渡
   `ch1_rest.right1 → ch1_boss` **246.06 ms**（第 83 程 253.71）。
   均与近期基线同量级，只记录不优化。
5. **文案（第 1–3 章 + Hub + 各界面）——修复 1 项：Boss 已死续玩的目标条
   写死第 1 章 Boss 名（见下）。** 其余抽查第 1–3 章事件/章末/权柄/Boss
   入口与阶段文案、Hub NPC 职能描述、商店/休整/档案馆文案，未发现新的行为
   不符或剧情圣经冲突。记录未改（沿用第 83 程结论）：噩梦说明「走完四章」
   为完整战役口径；`game.gd`「这一章还没有地图」分支已成死文案（无行为
   影响）；设置页全屏切换不写 Profile（补键会改设置存档形状）。
6. **回归抽查——全部通过。** 隐藏书库进入/返回无冻结；结局余味未解锁不
   泄露、已解锁展示；档案馆满级提示与禁用行；第 69/70/72/73 程 NPC 文案/
   词服务/商店已拥有/阿砚问候断言；第 78 程四敌专属美术；第 80 程第 3 章
   可达链路；第 83 程跨章权柄与帮助页「地图」文案，均在单元/对应集成套件中
   复跑通过。

### 修复与回归断言

**1）Boss 已死检查点续玩时目标条写死第 1 章 Boss 名（真实产品行为缺陷）。**
`scripts/game.gd` 的 `_on_mds_room_loaded()` 在 `_boss_defeated` 为真时调用
`hud.set_objective("墨骸史官已经倒下")`，常量字符串写死。第 2/3 章可达后，
玩家在击败「肺钟守卫」/「最后的读者」后、权柄/outro 完成前退出，续玩进入
Boss 房会看到第 1 章 Boss 名。探针 = 在 `integration_run_save` 的第 2 章
Boss 检查点续玩路径加断言，修复前实跑复现（
`run_save_ch2_resume_objective_uses_ch2_boss` FAIL，目标仍是
「墨骸史官已经倒下」）。修复：改为 `"%s已经倒下" % chapter["boss_name"]`，
第 1 章输出不变、第 2/3 章按 `CampaignData` 取本章 Boss 名。回归断言 +3：
- `integration_run_save` **657 → 659 / 0**：第 1 章检查点续玩仍为
  「墨骸史官已经倒下」；第 2 章检查点续玩为「肺钟守卫已经倒下」。
- `integration_playability` **878 → 879 / 0**：第 3 章 Boss 房重载为
  「最后的读者已经倒下」。

### 未修记录（只记录，不新增待确认条目）

- 沿用第 83 程既有记录：噩梦难度说明「走完四章」为完整战役口径；
  `game.gd`「这一章还没有地图」为死文案；暂停确认取消后的 one-shot 连接
  残留（当前不可见）、`NPC.interact()` 死代码、设置页全屏切换不持久、
  第 60 程样图问题 1/3/5/6/7 维持原结论。
- 第 11–16 项未碰、未新增待确认条目；第 4 章仍不可达。

### 收尾复跑（全绿，第 85 程接力实测）

- 单元 **13,549 / 0**；十一套集成 **879 / 109 / 659 / 207 / 113 / 59 /
  458 / 45 / 2,331 / 4,364 / 5,133**（合计 **14,357**）全 0 失败；
  退出 **10/10 clean**；demo 像素 **40 / 0**。
- 临时探针已删除；工作区提交后干净；未推送、未更新网页版、未创建 Release；
  第一章收口判定留给监工，本程不宣布里程碑。

## 例行扫描（第 85 程）

> brief89。第 1–3 章已可达 + Hub + 各系统。本程先接力收尾第 84 程（核验
> 在途 diff、复跑基线、补交 fix/test/docs 并补记），再做例行扫描与「扫描
> 发现的产品行为缺陷」修复；不开新功能、不碰待确认第 11–16 项、不改章节
> 可达性（第 4 章仍不可达）、不推送、不更新网页版、不创建 Release。

### 任务 0 · 第 84 程收尾

- 接手时 HEAD `1674457`（第 83 程），工作区 3 个未提交文件为第 84 程
  （brief88）在途改动；session88.log 声称已提交且工作区干净，与 git 不符，
  按 brief 以 git 为准。逐行核对 diff 与日志描述一致（`scripts/game.gd`
  1 行、`integration_playability.gd` +3、`integration_run_save.gd` +6）后，
  跑通全量基线并补交 `bf70390` fix、`7fa50f6` test、`67fbef6` docs（含本
  状态文件第 84 程专节、日志与「下一程从这里继续」㉚）。
- 第 84 程收尾基线：单元 **13,549 / 0**；十一套集成 **879 / 109 / 659 /
  207 / 113 / 59 / 458 / 45 / 2,331 / 4,364 / 5,133** 全 0 失败；
  退出 **10/10**；像素 **40 / 0**。

### 扫描面逐项结论

1. **关闭回退/模态——修复 1 项（见下）。** 暂停/设置/键位/背包/图鉴/帮助/
   地图/商店/事件/对话/结局屏/画廊逐页复核；权柄/归档三选一是强制模态，
   P/Esc/B 被 `_input` 守卫吞掉，不会叠暂停；第 2/3 章地图沿用同一
   `MapOverlay`。复核模态表现时发现权柄三选一打开时 HUD 未隐藏。
2. **焦点——未发现新缺陷。** 标题有/无存档、暂停、设置子页返回、商店/
   事件/对话/画廊/权柄/归档首帧均抓焦点；键鼠/手柄切换沿用
   `input_device_changed` 刷新提示与关闭键文案。
3. **存档边界——未发现新缺陷。** 第 1→2、2→3 交棒的 `demo_cleared` 落盘/
   章节切换/续玩恢复/Boss 已死不二次生成由 `integration_run_save` 复跑
   通过；第 83 程 `authority.chapter` 键与第 84 程目标条按章节取名均抽查
   无回退。
4. **性能（只记录，未优化）——未发现退化信号。** 临时探针（测后删除）在
   真实主场景内实测，3 个新进程样本、与第 68–84 程同口径：
   - Hub 冷加载 `load` **881.9–958.1 ms**、`_ready` **447.7–487.9 ms**、
     首帧 **42.7–51.8 ms**（第 84 程 960.9 / 550.7 / 389.8）。
   - `main.tscn` `load` **2,011.2–2,053.6 ms**、实例化 **625.3–647.6 ms**、
     首帧 **26.9–41.4 ms**（第 72–84 程 1,710–2,922 / 633–1,020）。
   - 第 1 章首房 120 帧 avg **8.19–8.24 ms**、p95 **8.64–8.89 ms**
     （第 84 程 8.20 / 8.90）。
   - Boss 房加载 **268.1–273.6 ms**；Boss 战 120 帧 avg **8.32–8.33 ms**、
     p95 **8.70–8.86 ms**（第 84 程 430.1 / 8.33 / 8.79）。
   - 门过渡 `ch1_rest.right1 → ch1_boss` **244.75–245.20 ms**
     （第 84 程 246.06）。均与近期基线同量级，只记录不优化。
5. **文案（第 1–3 章 + Hub + 各界面）——未发现新缺陷。** 抽查第 1–3 章
   intro/outro/章末选项/事件/Boss 入口与阶段文案、`Ch3EventData` 七组事件、
   `NPCEventData` 三组个人事件、Hub NPC 职能描述、商店/休整/档案馆文案：
   无错别字、无双标点、无与剧情圣经冲突。第 2 章 outro「阿砚看见自己的
   名字」与 `docs/story-bible.md` 第二章节拍一致；第 3 章 outro 指向剧场，
   但第 3 章末落在「未完的注脚」，语义是「还有下一页」而非剧终，成立。
   记录未改（沿用第 83/84 程结论）：噩梦说明「走完四章」为完整战役口径；
   `game.gd`「这一章还没有地图」为死文案；设置页全屏切换不写 Profile。
6. **回归抽查——全部通过。** 隐藏书库进入/返回无冻结；结局余味未解锁不
   泄露、已解锁展示；档案馆满级提示与禁用行；第 69/70/72/73 程 NPC 文案/
   词服务/商店已拥有/阿砚问候断言；第 78 程四敌专属美术；第 80 程第 3 章
   可达链路；第 83 程跨章权柄与帮助页「地图」文案；第 84 程三处 Boss 名
   目标条断言，均在单元/对应集成套件中复跑通过。

### 修复与回归断言

**1）权柄三选一打开时 HUD 未隐藏（真实产品行为缺陷）。**
`scripts/game.gd::_sync_hud_visibility()` 的模态列表包含 `_archive_choice`，
却漏了 `_authority_choice`；函数注释写的是「HUD hides under any modal page
so the page is the only thing to read」。Boss 死亡后的权柄三选一是强制模态
（84% 不透明遮罩、自带暂停），底下的 HUD 仍以约 16% 透出，与归档三选一/
暂停/事件等所有其他模态不一致。探针 `tests/probe_pass85_hud.gd`（真实主
场景，测后删除）复现：`authority_open=true hud_during_authority=true`；
修复后同一探针 `hud_during_authority=false`、关页后
`hud_after_authority=true`。修复：模态条件追加
`or (_authority_choice != null and _authority_choice.is_open())`。
回归断言 +3：
- `integration_run_save` **659 → 660 / 0**：第 2 章 Boss 检查点续玩、权柄页
  打开时 `hud.visible == false`。
- `integration_playability` **879 → 881 / 0**：第 2 章、第 3 章权柄页打开时
  HUD 均隐藏（各 +1）。

### 未修记录（只记录，不新增待确认条目）

- 沿用既有记录：噩梦难度说明「走完四章」为完整战役口径；`game.gd`
  「这一章还没有地图」为死文案；暂停确认取消后的 one-shot 连接残留（当前
  不可见）、`NPC.interact()` 死代码、设置页全屏切换不持久、第 60 程样图
  问题 1/3/5/6/7 维持原结论。
- 第 11–16 项未碰、未新增待确认条目；第 4 章仍不可达。

### 收尾复跑（全绿）

- 单元 **13,549 / 0**；十一套集成 **881 / 109 / 660 / 207 / 113 / 59 /
  458 / 45 / 2,331 / 4,364 / 5,133**（合计 **14,360**）全 0 失败；
  退出 **10/10 clean**；demo 像素 **40 / 0**。
- 两个临时探针已删除；工作区提交后干净；未推送、未更新网页版、未创建
  Release；第一章收口判定留给监工，本程不宣布里程碑。

## 例行扫描（第 86 程）

> brief90。第 1–3 章已可达 + Hub + 各系统。六个扫描面逐项核对；只修本程
> 发现的真实产品行为缺陷，不开新功能、不碰待确认第 11–16 项、不改章节
> 可达性（第 4 章仍不可达）、不推送、不更新网页版、不创建 Release。

### 任务 0 · 基线复核

- 接手时 HEAD `fcb6d38`，工作区干净，无在途改动。
- 导入/退出 0；单元 **13,549 / 0**；十一套集成 **881 / 109 / 660 / 207 /
  113 / 59 / 458 / 45 / 2,331 / 4,364 / 5,133**（合计 **14,360**）全 0
  失败；退出 **10/10**；像素 **40 / 0**。与第 85 程收尾基线逐项一致。

### 扫描面逐项结论

1. **关闭回退/模态——修复 1 族（见下）。** 逐页复核暂停/设置（含子页）/
   改键/背包/图鉴/地图/帮助/局内商店/事件页/对话/言灵/结局屏/画廊/Hub
   各页，关闭路径与焦点恢复无新缺陷。发现：延时打开的必选页面（事件页
   0.8 s、权柄三选一 1.2 s）不与页面/暂停/过场互斥。
2. **焦点——未发现新缺陷。** 标题有/无局内存档首焦点、暂停、设置子页
   返回、商店/事件/对话/画廊/权柄/归档首帧、键鼠/手柄切换均与既有断言
   一致。
3. **存档边界——未发现新缺陷。** 房间进入/奖励/事件/商店/残碑/宝箱/
   Boss 死亡/权柄/暂停/失焦/关窗写盘点，坏档/缺字段/旧档回退，死亡/
   胜利/回 Hub/重开清档，第 1→2、2→3 章交棒（`demo_cleared` 落盘、
   切章、续玩、Boss 已死不二次生成）复跑全绿；第 83 程 `authority.chapter`
   与第 84/85 程修复抽查无回退。
4. **性能（只记录，未优化）——未发现退化信号。** 临时探针（测后删除）
   在真实主场景内、同口径连续两次：
   - `main.tscn` 冷启动实例化+`_ready` **3,821 / 3,864 ms**（冷资源加载，
     与第 83 程 2,225.6 ms 同量级但偏高，只记录）。
   - 首房（ch1_01）120 帧 avg **8.27–8.29 ms**、p95 **8.65–8.68 ms**。
   - ch1_04 avg 8.28–8.29 ms。
   - Boss 房（ch1_boss）avg **8.33 ms**、p95 **8.67–8.79 ms**
     （第 85 程 8.32–8.33 / 8.70–8.86）。
   - 门过渡（`load_room` → `room_loaded`）**224–225 ms**
     （第 85 程 244.75–245.20）。
   - Hub 冷加载 **902–949 ms**、热加载 **403–410 ms**
     （第 85 程 881.9–958.1）。
   均与第 68–85 程同量级，只记录不优化。
5. **文案（第 1–3 章 + Hub + 各界面）——未发现新缺陷。** 抽查第 2/3 章
   各 7 组事件、章节 intro/outro/选项、Boss 名与阶段、Hub 服务描述、
   帮助页按键表：无空句、无未格式化占位符、无章节错位。帮助页「地图」
   已无「第一章」限定（第 83 程修复）；标题屏版本号 `0.11.0-demo` 属
   第 75 程已记录的发布口径，本程不改。
6. **回归抽查——全部通过。** 隐藏书库、结局余味、档案馆满级、第
   69/70/72/73 程文案与词服务、第 78 程敌人美术、第 80 程第 3 章可达性、
   第 83/84/85 程修复，均在单元/对应集成套件复跑通过。

### 修复与回归断言

**1）延时必选页与页面/暂停叠加（真实产品行为缺陷）。**
事件页 0.8 s、权柄三选一 1.2 s 的延时窗口内玩家可以打开地图/暂停/背包/
商店等页面，原实现到点直接开页：事件页会叠在地图之上或塞在暂停菜单
后面；`MapOverlay.close()` 无条件 `paused=false`，会在必选页仍开着时恢复
世界；权柄三选一开在暂停菜单（layer 100）后面时不可见，且其「继续」被
暂停拒绝。探针（真实主场景，测后删除）复现 `event_open=true
map_open=true` 与 `authority_open=true pause_open=true`。
修复：`scripts/game.gd` 新增 `_ui_blocks_delayed_page()`（暂停/任意页面/
奖励/商店/权柄/归档/结局屏），两个延时入口在开页前等待界面回到游戏，
而不是叠加开页。

**2）延时必选页在房间过场淡入淡出下打开（真实产品行为缺陷）。**
同一窗口内走进刚解锁的 Boss 房门时，`current_room` 要到淡出后才翻转，
原实现照样开页；MDS 淡入淡出层是 `CanvasLayer 100`（高于 `$UI` 20 与
story 30），暂停会冻结过场补间，必选页在黑色淡出下不可见、过场卡住。
探针复现 `authority_open=true paused=true changing_room=true
fade_alpha=0.68`，修复后同一路径在过场结束 + 淡入结束后才开页。
修复：`_open_event_after_transition` 读 `_mds_world.changing_room` 时取消
本次（重进仍会重排）；`_grant_chapter_authority` 等待 `changing_room`
结束，并用新增的 `_room_loaded_msec` 再等 400 ms（覆盖 `room_loaded`
之后才结束的 0.175 s 淡入），然后才开三选一。

**3）模态打开当帧 HUD 未同步隐藏（1 帧滞后，收尾复跑暴露）。**
第 85 程的 HUD 统一在 `_process` 里同步；事件页/权柄三选一打开后要等
下一帧才隐藏。收尾复跑 `integration_playability` 时
`chapter_3_authority_hides_hud` 偶发红（权柄页已打开、HUD 仍可见一帧）。
修复：两个延时入口在 `open` 之后立即调用 `_sync_hud_visibility()`，与
暂停/地图等页面一致，当帧隐藏；断言数不变。未改内容、数值、存档形状、
章节路由与可达性。

回归断言：
- `integration_ch1_event` **59 → 73 / 0**：0.8 s 窗口内开地图（页面等待、
  地图关闭后正常开页、选择后不叠加暂停菜单）；窗口内踏门（页面取消、
  不暂停、过场完成）。
- `integration_playability` **881 → 887 / 0**：1.2 s 窗口内暂停（三选一
  等待、暂停保持，恢复后走后续流程）；窗口内走门（过场期间不开、淡入
  未完成不开、过场后正常开页）。
- 反向验证：临时移除 `changing_room` 分支后 `integration_ch1_event` 复现
  3 条失败，恢复后 73/0。

### 未修记录（只记录，不新增待确认条目）

- 沿用既有记录：噩梦难度说明「走完四章」为完整战役口径；`game.gd`
  「这一章还没有地图」为死文案；暂停确认取消后的 one-shot 连接残留（当前
  不可见）、`NPC.interact()` 死代码、设置页全屏切换不持久、`_resume_restored`
  只写不读（无行为影响）、第 60 程样图问题 1/3/5/6/7 维持原结论。
- 第 11–16 项未碰、未新增待确认条目；第 4 章仍不可达。

### 收尾复跑（全绿）

- 单元 **13,549 / 0**；十一套集成 **887 / 109 / 660 / 207 / 113 / 73 /
  458 / 45 / 2,331 / 4,364 / 5,133**（合计 **14,380**）全 0 失败；
  退出 **10/10 clean**；demo 像素 **40 / 0**。
- 临时探针已删除；工作区提交后干净；未推送、未更新网页版、未创建
  Release；第一章收口判定留给监工，本程不宣布里程碑。

## 本程日志

### 2026-11-08 · 第 99 程（README 口径更新）

- 交接：HEAD `34bcdd7`（第 97 程收尾），`supervisor-dev`，工作区干净；brief103。第 98 程（brief102）被状态文件记为
  「启动即死」，实际未死——该会话仍在跑同一个 README 任务，本程读文件期间 `README.md` 连续变了三个版本
  （md5 `5888e2f5…` → `024b9452…` → `dfaa2b4f…`）。
- 并发处理：请第 98 程会话停手并交回本程（已确认停手、未提交、未动状态文件与记忆）；本程按冻结后的最终内容逐行
  复核后提交 `77e673a`。状态文件、记忆文档与全部提交只由本程写入，避免两会话同时追加同一个 5,784 行文件。
- 基线逐项复现（与 brief103 预期一致，两个会话各自独立复跑同值）：导入/退出 0；单元 **13,551 / 0**；十一套集成
  **1,475 / 109 / 677 / 207 / 113 / 73 / 458 / 45 / 2,331 / 4,364 / 5,133**（合计 **14,985**）全 0 失败（三个大图套件
  跑完）；退出 **10/10**；像素 **40 / 0**。
- README 改写八处：可玩范围第 1–3 → 第 1–4 章；删「第 3 章章末停章」；第 4 章条目并入可玩范围并补机制；整节删
  「已建成但未开放」；五个结局全部可达 + 写明判定只在战役结束与优先级；里程碑条目换成第 2–4 章接线成果；测试数字
  13,549/14,326 → 13,551/14,985；开发状态末条改为第 1–4 章均已接入。全文 grep `不可达`/`暂不可达成`/`停章`/
  `尚未接入`/`未开放`/`第 1–3 章`/`第三章末` 均无命中。
- 另按仓库实况改正三处：第二至四章武器/遗物走完整内容库（`RunLoot._weapon_pool`/`_relic_pool` 仅 `chapter == 0`
  用 `DEMO_*`），旧文「demo 开放各 6 把 / 6 件」在四章可达后不成立；NPC 个人事件闸门 `Profile.demo_cleared` 在
  第 1 章交棒时置位，改「打通第一章」；第 4 章 9 个房间全部 `backdrop_path = smiling_theater.png`，改「全章背景」。
- 保留仍然属实的说明：第 2–4 章捷径屏障无游戏内授予来源（全库无任何 `chN_shortcut` 授予），未虚构来源。
- 未改：游戏代码/场景/资源/测试/配置、章节路由与可达性、存档形状、数值、NPC 立绘、版本号（仍 `0.11.0-demo`）、
  第 11–16 项。未推送、未更新网页版、未创建 Release。
- 记录监工本巡查已完成/未完成各一件：网页版已更新到 `34bcdd7`（公网 200）；GitHub 推送因 4 个新增二进制精灵图被
  跳过，待用户本人推图后由监工补推文本改动。

### 2026-11-07 · 第 97 程（全流程 1→4 集成验收）

- 交接：HEAD `b6bd5b5`（第 91 程收尾），`supervisor-dev`，工作区只有一件未跟踪文件 `tests/probe_chain_boot.gd`
  （第 96 程遗留）；brief101（任务同 brief99）。第 92 程基线绿 + 缺口分析后中断（无提交），第 93/94/95 程
  启动即死，第 96 程无声夭折——本程为全新重跑。基线逐项复现：导入/退出 0；单元 **13,551 / 0**；十一套集成
  **847 / 109 / 675 / 207 / 113 / 73 / 458 / 45 / 2,331 / 4,364 / 5,133**（合计 14,395）全 0 失败；退出
  **10/10**；像素 **40 / 0**。
- 遗留探针：实读 40 行、5 条断言、单独跑 5/5 通过；内容只覆盖「Hub 教学 → `request_run()` → 第 1 章开场」这一段，
  已被本程链路前段（且更强）覆盖，**删除**，工作区恢复干净。
- 链路：`integration_playability` 新增 `_test_full_campaign_chain()`（+628 断言）——新局 → Hub 教学三步（含
  `tutorial_done` 落盘）→ 第 1 章 9 房逐门实走（书库往返、事件页、清房 6/7、Boss 1、权柄、outro、章末选择）→
  第 2/3/4 章大图各九区实走（每次 7 场战斗 + 事件区一次性 + Boss + 权柄 + outro + 章末选择）→ 焚毁结局；
  再从真实 Boss 4 检查点续玩拿复原结局。全程真实输入/真实场景/真实存档，无传送、无内部结算函数跳关。
- 交棒断言：路由三槽（计划/世界文件/世界场景）+ `big_map` + 起始区；开场逐句文本、配乐、语音键；`SpawnPoint`
  落地（< 2 px 且 `is_on_floor`）；清房目标与 HUD 分母；坠落平面；上一章的 `demo_cleared`/仁慈/
  `cleared_encounters`/`boss_defeated` 从磁盘 run save 读回。
- 跨章结转：`authority.chapter` 逐章更新、第 4 章 Boss 死检查点仍带第 3 章权柄并在续玩时重新给；Boss 已死
  续玩目标条按本章 `boss_name`；结局 id / 结束屏 / `Profile.endings` / 画廊四处一致。
- 「复原」判定点核实：`ending_for` 无章节参数，判定只在战役结束，第 81 程 README「可在第三章末达成」为
  过期口径（记录，不改规则、不改 README）。
- 缺陷：修 1 项真实产品缺陷——Boss 已死检查点续玩重新锁上死掉 Boss 的房（`_update_room_locks()` 现在在
  `_boss_defeated` 时跳过 Boss 房）；`integration_run_save` 的 aftermath 存档位置改为真实落点并补 2 条回归，
  playability 续玩段补 3 条回归；反向验证（回退修复）复现 2 条失败。
- 收尾：单元 **13,551 / 0**；十一套集成 **1,475 / 109 / 677 / 207 / 113 / 73 / 458 / 45 / 2,331 / 4,364 /
  5,133**（合计 **14,985**）全 0 失败；退出 **10/10**；像素 **40 / 0**。工作区提交后干净。
- 未推送、未更新网页版、未创建 Release；第 11–16 项未碰；README 四处过期口径待单独一程。

### 2026-11-07 · 第 91 程（第 4 章可达性接线第 1 步）

- 交接：HEAD `1bb7743`（第 88 程收尾），`supervisor-dev`，工作区干净；brief95。第 89/90 程（brief93/94）基线跑绿后中途中断（当时误记为「启动即死」，第 97 程核对日志更正；两程零提交）；本程按 `.supervisor/DECISIONS.md` 2026-11-07 09:45 的监工拍板全新开工，不接续 session93/94。
- 基线逐项复现（brief95 给的数字）：导入/退出 0；单元 **13,549 / 0**；十一套集成 **887 / 109 / 675 / 207 / 113 / 73 / 458 / 45 / 2,331 / 4,364 / 5,133**（合计 14,395）全 0 失败；退出 **10/10**；像素 **40 / 0**。
- 接线缺口核查：唯一缺口是四个路由点（计划槽 3 为空、世界文件/场景指旧第 4 章线性世界、`_complete_chapter` 的第 3 章分支仍 `_finish(true)`）；第 4 章计划/大区世界/区域场景/事件/波次/Boss 4/章末收口与 5,133 断言验收（第 51–59 程）均已就位，旧第 4 章 9 房世界留档但不再引用。
- 接线（只改路由与章末分支）：`CHAPTER_PLAN_PATHS[3]` 接 `chapter_4_demo.tres`；`MDS_WORLD_FILES[3]` 改指 `chapter_4_bigmap.mdsworld.json`；`MDS_CHAPTER_SCENES[3]` 改指 `chapter_4_bigmap_world.tscn`；`_complete_chapter` 的 `_chapter == 2` 由 `_finish(true)` 改为 `_start_chapter(3)`（第 4 章末 `_finish(true)` 未改）。第 4 章沿用既有大图流程：`ch4_entry` 出生（`SpawnPoint`）、清房目标 7（HUD 8）、坠落平面 1680、开场 8 句 + `ch4_intro` + `chapter_theater.ogg`。
- 全链路实走（真实路由、无测试专用挂载）：第 3 章章末选择 → 第 4 章开场 → `ch4_entry` 出生落地（`is_on_floor`）→ 真实清 `ch4_branch_a/Arena`（锁门 → 波次全灭 → 奖励页 → 计数 1/7）→ `ch4_event` 一次性事件页（拿 +12 / 读 +8 + 解词，settle 一次、重载不重开）→ Boss 4（`SmilingArchivist`，HP 520 / 伤害 18 / 速度 92 全按战役表）→ 权柄三选一 → 第 4 章 outro（4 句 + `ch4_outro`）→ 章末选择（重写名册，仁慈 +1、污染不变）→ 战役结束 + 结局按 `ending_for` 写入 `Profile.endings`。
- 测试：`integration_playability` 的章循环重构——第 3 章章末改为断言第 4 章交棒；新增 `_test_ch4_big_map`（真实链路 30 条）；事件区/Boss 4 两段由测试专用挂载改为真实路由世界；删除旧第 4 章 9 房结构遍历、两条默认清房/坠落断言与 `_restore_chapter_world`（覆盖由真实链路 + `integration_ch4_bigmap` 承担）。`integration_ch3_bigmap` 的第 3 章末改为第 4 章交棒、清房计数断言前移、Boss 重载改为手工重挂世界。`integration_ch4_bigmap` 路由锁与章末锁改为「已接线路由」，套件仍自行挂载以便一次走完九区。路由锁逐条更新 `test_ch2_world` / `test_ch3_content` / `test_ch3_boss` / `test_ch4_plan` / `test_ch4_content` / `test_ch4_boss` / `test_ch4_world`，旧第 4 章世界与场景的存在性断言全部保留；`capture_bigmap_chapters.gd` / `test_map_overlay.gd` 的过期注释同步。
- 收尾：单元 **13,551 / 0**（+2：`test_ch2_world` / `test_ch3_content` 各补 1 条第 4 章计划存在性断言）；十一套集成 **847 / 109 / 675 / 207 / 113 / 73 / 458 / 45 / 2,331 / 4,364 / 5,133**（合计 **14,355**）全 0 失败；退出 **10/10**；像素 **40 / 0**。
- 未修记录（沿用）：`ch4_shortcut` 无授予、舞台母题呈现层、Boss 4 机制扩展、战斗密度（第 50 程专节 E / 待确认第 16 项）；第 60 程样图问题 1/3/5/6/7；困难难度「走完四章」文案；设置页全屏不持久。
- 未推送、未更新网页版、未创建 Release；`README.md` 仍写「第 4 章不可达」，待监工安排更新。

### 2026-11-06 · 第 88 程（全游戏例行扫描）

- 交接：HEAD `665581c`（第 86 程收尾），`supervisor-dev`，工作区干净；brief92。第 87 程（brief91 / `session91.log`）只写完任务 0 基线就中断（日志 12 行、无扫描/提交/收尾），疑似 Magpie 网关中断；本程为全新重跑，不接续 session91。基线逐项复现：导入/退出 0；单元 **13,549 / 0**；十一套集成 **887 / 109 / 660 / 207 / 113 / 73 / 458 / 45 / 2,331 / 4,364 / 5,133**（14,380）全 0 失败；退出 **10/10**；像素 **40 / 0**。
- 扫描：六个扫描面逐项核对（关闭回退/焦点/存档边界/性能/文案/回归抽查）。面 1 用临时探针在真实主场景以真实键事件走完整页栈（地图 M/Esc/P、背包、图鉴、帮助、设置、暂停→设置→Esc 回暂停、设置内 AI/键位/帮助三子页逐层关闭），每步断言「模态 ⇒ 暂停 + HUD 隐藏 + 焦点可见」，86/86 步通过、无死路。
- 发现并修复 1 项真实产品行为缺陷（与第 86 程延时必选页同一族的最后一处）：**房间奖励页不等待其它页面/过场**。敌人尸体由 0.35 s 场景计时器释放且暂停时照走；最后一击到真正清房之间开地图/暂停/背包，房间在页面背后清空，`_on_room_cleared` 的 `_open_reward.call_deferred()` 把必选奖励页盖在页面上；地图 `close()` 无条件 `get_tree().paused = false`，关地图就在奖励页仍开着时恢复世界。探针复现两种顺序：「奖励盖地图」与「奖励盖死亡归档页」（最后一击同帧死亡，归档三选一暂停期间尸体计时器照走）。
- 修复：`scripts/game.gd` 的 `_open_reward()` 改为等价的延时页等待（房间过场结束且 `_ui_blocks_delayed_page()` 为假才开页；死亡已提交则不欠奖励）；新增 `_reward_pending`（房间结算 → 选择/放弃之间为真），`save_run_now()` 在它为真时也不写档——等待期间暂停会写检查点，而房间已记为清房，续玩会得到「已清房 + 没拿奖励」。未改奖励内容/数值/存档形状/章节路由。
- 测试：`integration_run_save` 660 → **675 / 0**（+15：真实 `_on_room_cleared` + 地图开着的等待/让位/`pending` 挡档断言；死亡归档段落改为真实杀波 + 尸体延时内死亡，断言房间清空但奖励不得盖在归档页上）。单元不变 13,549 / 0。
- 性能（只记录，两次独立进程样本）：`main.tscn` 冷启动到首房 4,308.4/4,177.3 ms；首房 120 帧 avg 8.20–8.24 / p95 8.50–8.64 ms；门过渡 228.7/226.7 ms；Boss 房 avg 8.33 / p95 8.77–8.83 ms；Hub 冷 857.0/881.6、热 457.9/476.9 ms。均与第 68–86 程同量级，未优化。
- 其余四个面（焦点/存档边界/文案/回归抽查）未发现新缺陷；只顺带把 `CampaignData` 过时的头注释「Three authored chapters」改为四章且第 1–3 章可达（注释，非玩家可见文案）。遗留未修照旧：困难难度「走完四章」（描述完整版目标）、`game.gd`「这一章还没有地图」（第 4 章不可达，当前不可见）、暂停确认一次性连接残留（当前不可见）、`NPC.interact()` 死代码、设置页全屏不持久、`_resume_restored` 只写不读、第 60 程样图问题 1/3/5/6/7。
- 收尾：单元 **13,549 / 0**、十一套集成 **14,395**（887/109/**675**/207/113/73/458/45/2,331/4,364/5,133）全 0 失败、退出 10/10、像素 40/0；临时探针删除、工作区干净；未推送、未更新网页版、未创建 Release；第一章收口判定留给监工，本程不宣布里程碑；第 4 章仍不可达、第 11–16 项未碰。

### 2026-11-06 · 第 86 程（全游戏例行扫描）

- 交接：HEAD `fcb6d38`，`supervisor-dev`，工作区干净；brief90。基线逐项复现：导入/退出 0；单元 **13,549 / 0**；十一套集成 **881 / 109 / 660 / 207 / 113 / 59 / 458 / 45 / 2,331 / 4,364 / 5,133**（14,360）全 0 失败；退出 **10/10**；像素 **40 / 0**。
- 扫描：六个扫描面逐项核对（关闭回退/焦点/存档边界/性能/文案/回归抽查）。发现并修复 1 族 2 类真实产品行为缺陷：延时打开的必选页（事件页 0.8 s、权柄三选一 1.2 s）与地图/暂停/背包/商店等页面叠加；同一窗口内踏门时在 MDS 淡入淡出层（`CanvasLayer 100`）下开页导致黑屏卡住。探针复现前后各一次。
- 修复：`scripts/game.gd` 新增 `_ui_blocks_delayed_page()` 与 `_room_loaded_msec`；事件页读 `changing_room` 取消本次、重进重排；权柄三选一等待过场结束 + 400 ms（覆盖 0.175 s 淡入）再开。未改内容/数值/存档形状/章节路由。
- 测试：`integration_ch1_event` 59 → **73 / 0**（+14）；`integration_playability` 881 → **887 / 0**（+6）；单元不变 13,549 / 0；反向验证移除 `changing_room` 分支复现 3 条失败，恢复后全绿。
- 性能（只记录）：`main.tscn` 冷启动 3,821/3,864 ms；首房 120 帧 avg 8.27–8.29 / p95 8.65–8.68 ms；Boss 房 avg 8.33 / p95 8.67–8.79 ms；门过渡 224–225 ms；Hub 冷 902–949 / 热 403–410 ms。均与近期基线同量级，未优化。
- 收尾：单元 13,549 / 0、十一套集成 **14,380** 全 0 失败、退出 10/10、像素 40/0；临时探针删除、工作区干净；未推送、未更新网页版、未创建 Release；第一章收口判定留给监工，本程不宣布里程碑；第 4 章仍不可达、第 11–16 项未碰。

### 2026-11-06 · 第 85 程（全游戏例行扫描）

- 交接：HEAD `1674457`（第 83 程），`supervisor-dev`；brief89。第 84 程会话在提交前中断，本程任务 0 先核验在途 diff（与 session88.log 描述逐行一致）、复跑全量基线并补交 `bf70390` / `7fa50f6` / `67fbef6`，补记第 84 程专节与日志。
- 基线复核（第 84 程收尾后）：导入/退出 0；单元 **13,549 / 0**；十一套集成 **879 / 109 / 659 / 207 / 113 / 59 / 458 / 45 / 2,331 / 4,364 / 5,133** 全 0 失败；退出 **10/10**；像素 **40 / 0**。
- 扫描：六个扫描面逐项核对。发现并修复 1 项：权柄三选一（强制模态）打开时 HUD 未隐藏（`_sync_hud_visibility()` 模态列表漏 `_authority_choice`，84% 遮罩下透出），探针复现前后各一次。
- 测试：`integration_run_save` 659 → **660 / 0**（+1）；`integration_playability` 879 → **881 / 0**（+2）；单元不变 13,549 / 0。
- 性能（只记录）：Hub `load` 881.9–958.1 ms；`main.tscn` load 2,011.2–2,053.6 ms；首房 120 帧 avg 8.19–8.24 / p95 8.64–8.89 ms；Boss 房加载 268.1–273.6 ms、120 帧 avg 8.32–8.33 / p95 8.70–8.86 ms；门过渡 `ch1_rest.right1 → ch1_boss` 244.75–245.20 ms。均与第 68–84 程同量级，未优化。
- 边界：未改章节路由/可达性/数值/第 4 章/第 11–16 项/NPC 立绘/核心玩法框架；未推送、未更新网页版、未创建 Release；第一章收口判定留给监工。

### 2026-11-06 · 第 84 程（全游戏例行扫描）

- 交接：HEAD `1674457`，`supervisor-dev`，工作区干净；brief88。第 83 程已修复跨章权柄续玩与帮助页地图文案。
- 基线复核：`--headless --import` / `--quit` 退出 0；单元 **13,549 / 0**；十一套集成 **878 / 109 / 657 / 207 / 113 / 59 / 458 / 45 / 2,331 / 4,364 / 5,133** 全 0 失败；退出 **10/10**；像素 **40 / 0**。
- 扫描：六个扫描面逐项核对（关闭回退/焦点/存档边界/性能/文案/回归抽查）。发现并修复 1 项：Boss 已死检查点续玩目标条写死第 1 章 Boss 名（`_on_mds_room_loaded()` 改为按本章 `chapter["boss_name"]` 取名，探针复现前后各一次）。
- 测试：`integration_run_save` 657 → **659 / 0**（+2）；`integration_playability` 878 → **879 / 0**（+1）；单元不变 13,549 / 0。
- 性能（只记录）：Hub `load` 960.9 ms、`_ready`+首帧 389.8–550.7 ms；`main.tscn` load 2,217.1 ms、boot 1,020.4 ms；首房 120 帧 avg 8.20 / p95 8.90 ms；Boss 房加载 430.1 ms、120 帧 avg 8.33 / p95 8.79 ms；门过渡 `ch1_rest.right1 → ch1_boss` 246.06 ms。均与第 68–83 程基线同量级，未优化。
- 中断与接力：本程会话在提交与写状态文件前中断（无 claude 进程在跑），`git log` 无该程提交、状态文件仍停在第 83 程；第 85 程核实在途 diff 与日志描述逐行一致后，跑通全量基线、按 fix + test + docs 三项补交并补记本节。
- 边界：未改章节路由/可达性/数值/第 4 章/第 11–16 项/NPC 立绘/核心玩法框架；未推送、未更新网页版、未创建 Release。

### 2026-11-06 · 第 83 程（全游戏例行扫描）

- 交接：HEAD `8773a11`，`supervisor-dev`，工作区干净；brief87。第 82 程（brief86）启动即死、零产出；本程为全新重跑。第 1–3 章已可达，第 4 章仍不可达。
- 基线复核：`--headless --import` / `--quit` 退出 0；单元 **13,549 / 0**；十一套集成 **878 / 109 / 631 / 207 / 113 / 59 / 456 / 45 / 2,331 / 4,364 / 5,133** 全 0 失败；退出 **10/10**；像素 **40 / 0**。
- 扫描：六个扫描面逐项核对（关闭回退/焦点/存档边界/性能/文案/回归抽查）。发现并修复 2 项：① 跨章 Boss 检查点续玩吞掉本章权柄三选一（`_authority_granted_chapter` + `authority.chapter` 存档键，旧档按文件章节兼容；探针复现前后各一次）；② 帮助页「地图（第一章）」过期文案改为「地图」。
- 测试：`integration_run_save` 631 → **657 / 0**（+26）；`integration_menus` 456 → **458 / 0**（+2）；单元不变 13,549 / 0。
- 性能（只记录）：Hub `load` 974.7 ms、`_ready`+首帧 375.3–502.8 ms；`main.tscn` load 2,225.6 ms、boot 845.8 ms；首房 120 帧 avg 8.25 / p95 8.68 ms；Boss 房加载 447.4 ms、120 帧 avg 8.43 / p95 8.74 ms；门过渡 `ch1_rest.right1 → ch1_boss` 253.71 ms。均与第 68–77 程基线同量级，未优化。
- 结果：十一套集成 **878 / 109 / 657 / 207 / 113 / 45 / 458 / 59 / 2,331 / 4,364 / 5,133** 全 0 失败；退出 10/10、像素 40/0；临时探针已删除。
- 边界：未改章节路由/可达性/数值/第 4 章/第 11–16 项/NPC 立绘/核心玩法框架；未推送、未更新网页版、未创建 Release。

### 2026-11-06 · 第 81 程（README 口径更新）

- 交接：HEAD `3813bf1`，`supervisor-dev`，工作区干净；brief85。第 80 程已把第 3 章接入主流程，第 4 章仍不可达。
- 基线复核：`--headless --import` / `--quit` 退出 0、`ERROR` 0；单元 **13,549 / 0**；十一套集成 **878 / 109 / 631 / 207 / 113 / 59 / 456 / 45 / 2,331 / 4,364 / 5,133** 全 0 失败；退出泄漏 **10/10 clean**；demo 像素 **40 / 0**。
- 核查：`game.gd` 第 1–3 章路由已接、第 3 章末 `_finish(true)` 停章、`CHAPTER_PLAN_PATHS[3]` 仍空；「复原」结局随跨章仁慈可达（`_mercy` 累加、`_start_chapter` 不重置，`ending_for` 规则由 `tests/test_campaign.gd` 锁定）；「焚毁档案」仍只在第 4 章触发；`config/version` 与标题屏仍 `0.11.0-demo`。
- 改写：README 可玩范围 → 第 1–3 章、已建成但未开放 → 只剩第 4 章、结局 → 4 个可达、运行第 3 步 → 三章接续、开发状态数字 → 本程实测；只改 `README.md`（+10 / −11），未改产品代码 / 测试 / 配置、章节路由与可达性。
- 提交：`9b7b255`（README）；状态 / 记忆记录为紧随其后的 docs 提交。
- 结果：工作区干净；未推送、未更新网页版、未创建 Release；第 11–16 项未碰。

### 2026-11-06 · 第 80 程（第 3 章可达性接线第 1 步）

- 交接：HEAD `7242cdc`，`supervisor-dev`，工作区干净；brief84（第 79 程 brief83 启动即因 `[claude-code:unrecognized_model]` 死亡，本程为接力全新重跑）。
- 基线复核：单元 13,549/0；十一套集成 913 / 109 / 624 / 207 / 113 / 59 / 456 / 45 / 2,330 / 4,362 / 5,133 全 0；退出 10/10；像素 40/0。
- 核查：唯一缺口是 `CHAPTER_PLAN_PATHS[2]` 空、`MDS_WORLD_FILES[2]`/`MDS_CHAPTER_SCENES[2]` 指旧第 3 章世界、`_complete_chapter` 的 `_chapter == 1` 停章；第 3 章计划/大区世界/事件/Boss 3/章末分支均已就位，存档形状不变。
- 接线：`game.gd` 四个路由点改指 `chapter_3_demo.tres` / `chapter_3_bigmap.mdsworld.json` / `chapter_3_bigmap_world.tscn`；`_chapter == 1` 分支改为 `_start_chapter(2)`；第 2 章选项/效果、第 3 章末停章、第 4 章不可达不变。
- 测试：playability 新增第 3 章真实链路（开场交棒 → `ch3_entry` 出生落地 → 真实清 `ch3_branch_a/Arena` → 事件区 → Boss 3 → 权柄 → outro → 章末停章），事件/Boss 段改走真实路由世界，旧 9 房遍历删除；run_save/ch2 集成 + 11 个测试文件的路由锁按新行为逐条更新。
- 结果：单元 13,549/0；集成 878 / 109 / 631 / 207 / 113 / 59 / 456 / 45 / 2,331 / 4,364 / 5,133 全 0 失败；退出 10/10、像素 40/0。
- 边界：未改第 3 章计划/波次/事件/Boss 3 数值与机制、第 1/2 章内容、存档形状；`ch3_shortcut` 无授予（第 16 项）、视野压缩/海面母题未做（第 14/15 项）、电梯/相机/HUD 未动（第 12/13 项）；未推送/未更新网页版/未创建 Release。

### 2026-11-06 · 第 78 程（第 2 章四敌缺美术接入）

- 交接：HEAD `3ab1f76`，`supervisor-dev`，工作区干净；brief82：接入用户已出的四张第 2 章敌人图。
- 基线复核：单元 13,490/0；十一套集成 913 / 109 / 624 / 207 / 113 / 59 / 456 / 45 / 2,315 / 4,358 / 5,133 全 0；退出 10/10；像素 36/0。
- 处理：breath_hound 单图 + 三拼图按空白列裁切；flood-fill 去白底（保浅色毛边）、统一缩放到 96×96、低饱和墨灰调色板、24 色量化 + `#101820` 1 px 轮廓、底部对齐；产出四张 96×96 PNG（各 25 色、二进制 alpha、四角透明、无白边）。
- 接入：`ENEMY_ART` +4、`ENEMY_ART_FALLBACK` 清空；`test_enemy_art` 298→357、ch2 集成 2,315→2,330、ch3 集成 4,358→4,362；像素复核 36→40/0。
- 收尾：单元 13,549/0；十一套集成全 0 失败；`--headless --import` / `--quit` 0 ERROR；退出 10/10。
- 边界：未改敌人数值 / 波次 / 行为、门 / 电梯 / 长椅 / 捷径、章节路由 / 可达性、存档、NPC 立绘、第 1 章内容；第 3/4 章仍不可达；未推送 / 未更新网页 / 未创建 Release。

### 2026-11-06 · 第 76–77 程（第 2 章可达性接线第 1 步）

- 交接：HEAD `247f4dd`，`supervisor-dev`。第 76 程（brief80）核查接线缺口后因网关中断夭折，
  只留下未提交的 `scripts/game.gd` 改动；本程（brief81 / 第 77 程）接力。
- 核查：`CHAPTER_PLAN_PATHS[1]` / `MDS_WORLD_FILES[1]` / `MDS_CHAPTER_SCENES[1]` 与
  第 2 章开场/语音/配乐均已就位；唯一缺口是 `_complete_chapter` 第 1 章分支仍 `_finish(true)`。
- 改动：第 1 章分支改为 `demo_cleared = true` → `Flow.save_profile()` → `_start_chapter(1)`；
  其他章节分支、章末选项/效果、第 2 章内容与存档形状未改。
- 测试：playability 增加自然交棒 + `ch2_entry` 出生/落地/清房 0、真实战斗清两场遭遇；
  menus 键盘/手柄章末 → 第 2 章开场焦点；run_save 三条章末边界 → 第 2 章开场/检查点迁移。
- 基线：单元 **13,490 / 0**；十一套集成 **913 / 109 / 624 / 207 / 113 / 59 / 456 / 45 /
  2,315 / 4,358 / 5,133** 全 0；退出 10/10；像素 36/0。
- 边界：第 3/4 章仍不可达、`ch2_shortcut` 无授予、电梯/相机/HUD 未动；未推送/未更新网页/未创建 Release。

### 2026-11-06 · 第 75 程（Windows 导出）

- 交接：HEAD `7d11fc2`，`supervisor-dev`，工作区干净；任务单 brief79：按
  DECISIONS「再更正」从当前 HEAD 导出 Windows release 包并打 zip，不做推送/
  网页更新/Release 创建，不做 Windows 实机验证。
- 任务 0 · 基线核验：`--headless --import` / `--quit` 退出 0；单元
  **13,490 / 0**；十一套集成 **899 / 109 / 613 / 207 / 113 / 59 / 445 / 45 /
  2,315 / 4,358 / 5,133** 全 0 失败（三个大图套件均跑完）；退出泄漏
  **10/10 clean**、demo 像素 **36 / 0**——与第 74 程基线逐项一致。
- 任务 1 · 模板/预设核验：4.7.stable 模板齐全（含 `windows_release_x86_64.exe`）；
  既有 Windows 预设 `runnable=true` / `embed_pck=true`，未改；`.mdsworld.json`
  在 Godot 4.7 中作为 JSON 资源导出，确认会进包。
- 任务 2 · 导出：命令见专节；**退出 0 / 20 秒**；exe **132,104,632 bytes**，
  PE32+ GUI x86-64，SHA-256 `7d4811f4…4242`；日志
  `artifacts/releases/v0.12.0/export.log`。
- 任务 3 · 验证：内嵌 PCK **22,930,348 bytes** 与独立 `--export-pack` 产物逐字节
  一致；PCK 关键路径 12/12；`--main-pack` 无头启动退出 0；zip **59,572,799 bytes**，
  1 文件、`unzip -t` OK、包内 exe 哈希一致。
- 任务 4 · 记录：新增本专节、session 文档
  `docs/memory/sessions/2026-11-06-windows-export-pass75.md`、MEMORY 索引行，
  更新「下一程从这里继续」第 ㉓ 条与基线数字；未改产品代码/场景/资源/测试/
  导出预设；未推送、未更新网页版、未创建 Release。

### 2026-11-06 · 第 74 程（README 重写）

- 交接：HEAD `34475c1`，`supervisor-dev`，工作区干净；任务单 brief78：
  只重写仓库根 `README.md`，不做 Windows 导出、不推送、不更新网页版、
  不创建 Release、不改游戏代码/场景/资源/测试。
- 任务 0 · 基线核验：`--headless --import` / `--quit` 退出 0；单元
  **13,490 / 0**；十一套集成 **899 / 109 / 613 / 207 / 113 / 59 / 445 / 45 /
  2,315 / 4,358 / 5,133** 全 0 失败（三个大图套件均跑完）；退出泄漏
  **10/10 clean**、demo 像素 **36 / 0**——与第 73 程基线逐项一致。
- 任务 1 · README 重写：按「简介 → 当前可玩范围 → 已建成但未开放 →
  核心系统 → 操作 → 运行 → 开发状态」重写；删除 0.11/0.10/0.7 三层旧日志、
  SAPI 旁白宣传、Android 触屏、「依次穿过四章」等旧说法；如实写第一章 +
  T17 为当前可玩，第 2–4 章为已建成未开放。
- 数字核实：词条 95（39/29/27）、开局 18（6 解码 + 12 未解码）、demo
  6 武器/6 遗物/6 敌人、内容库 12/9/14、13 法术形态、第一章 9 房间/清房 6、
  5 结局（demo 可达 3）、6 首配乐、155 个脚本 26,849 行、单元 13,490、
  集成 14,296、第 2/3/4 章 2,315/4,358/5,133；未采用 brief 中无法核实的
  「可收集 50」。
- 只改 `README.md`，提交 `a5053a4`（docs）；随后按本程记录更新状态文件、
  `docs/memory/sessions/2026-11-06-readme-rewrite-pass74.md` 与
  `docs/memory/MEMORY.md` 索引。
- 收尾：本程无产品代码/场景/资源/测试改动，基线数字不变；未推送、未更新
  网页版、未创建 Release、未宣布里程碑；第 2–4 章仍不可达、第 11–16 项未碰。

### 2026-11-06 · 第 73 程（全游戏例行扫描）

- 交接：HEAD `8b4244a`，`supervisor-dev`，工作区仅含本程在途改动。任务单
  brief77：只做例行扫描 + 修扫描发现的产品行为缺陷，不开新功能、不推送、
  不更新网页版。
- 任务 0 · 基线核验：与第 72 程逐项一致（单元 13474/0、十一套集成
  899 / 102 / 613 / 207 / 113 / 59 / 445 / 45 / 2315 / 4358 / 5133、
  退出 10/10、像素 36/0），三个大图套件均跑完。
- 逐面扫描：关闭回退/焦点/存档边界/回归抽查逐项复核，未发现新缺陷；性能用
  临时探针按第 68–72 程同口径实测并记录（测后删除）；文案面复核第 1 章事件/
  休整/书库/残碑与第 69/70/72 程已修文案，无新矛盾。
- 修复 1：`hub.gd` 词服务的无限碎片泵——`Profile.DEFAULT_OWNED` 首次开局即
  含全部 18 个第 1 章词，`_unlock_random_word()` 兜底每次返 8 碎片，使传闻
  净 +5、讲述档案净 +2 且可无限连点落盘；新增 `unlockable_word_pool()`，
  池空拒绝并说明不收费，有词时仍按原价解锁。单元
  **13474 → 13490/0**（+16）。
- 修复 2：`game.gd::_on_shop_buy` 对缓存货架中「后来已从奖励/宝箱/残碑拿到」
  的遗物/词仍扣残页且不发货、行可重复点；新增 `_shop_offer_owned()` 与
  `RunShopUI.mark_owned()`，已拥有则禁用不扣费。第 1 章 demo 集成
  **102 → 109/0**（+7）。
- 未修记录：暂停确认取消后的 one-shot 连接残留（当前不可见）、
  `NPC.interact()` 死代码、设置页全屏不持久、第 60 程样图问题 1/3/5/6/7
  维持原结论；第 11–16 项未碰。
- 记忆：新增 `docs/memory/sessions/2026-11-06-routine-scan-pass73.md`，更新
  `docs/memory/MEMORY.md` 索引。
- 收尾：单元 13490/0、十一套集成全 0 失败、退出 10/10、像素 36/0；临时探针
  删除、工作区干净；未推送、未更新网页版、未宣布里程碑。

### 2026-11-06 · 第 72 程（全游戏例行扫描）

- 交接：HEAD `3847343`，`supervisor-dev`，工作区干净；第 71 程开局夭折，
  本程为重跑。任务单 brief76：只做例行扫描 + 修扫描发现的产品行为缺陷，
  不开新功能、不推送、不更新网页版。
- 任务 0 · 基线核验：与第 70 程逐项一致（单元 13465/0、十一套集成
  899 / 102 / 613 / 207 / 113 / 59 / 445 / 45 / 2315 / 4358 / 5133、
  退出 10/10、像素 36/0），三个大图套件均跑完。
- 逐面扫描：关闭回退/焦点/存档边界/回归抽查复用既有套件复跑，未发现
  新缺陷；性能用临时探针按第 68/69/70 程同口径实测并记录（测后删除）；
  文案面发现并修复 1 项 Hub 产品行为缺陷——跟阿砚打招呼会静默扣碎片、
  升级断页剑基底（探针复现 100 → 90 碎片、Lv.0 → Lv.1）。
- 修复：`hub.gd::talk_to_npc` 的阿砚分支不再调用 `upgrade_sword_base()`，
  改为报当前基底等级并指向「言灵对话 → 锻造基底」，不写死价格；未改
  锻造数值、折扣、信任、存档或可达性。
- 回归断言：`test_hub_final` +9（问候不扣碎片/不升级、提到锻造基底与
  当前 Lv.、关闭后解冻、显式职能仍扣费升级），单元 13465 → **13474/0**；
  menus 445、run_save 613、gamepad 207、ui_prompts 113、playability 899
  复跑 0 失败；收尾其余六套与基线一致。
- 提交：`68bea06` `fix:`、`2381b6c` `test:`、`<本提交>` `docs:`。
- 收尾：工作区干净，临时探针已删；未推送、未更新网页版、未宣布里程碑。

### 2026-11-06 · 第 71 程（开局夭折）

- 任务单 brief75：全游戏例行扫描（与第 68–70 程同口径）。
- `.supervisor/session75.log` 仅两行：一行 `[claude-code:unrecognized_model]`
  网关报错、一行 `[2026-11-06 04:06:57] pass71 session start; HEAD=3847343;
  branch=supervisor-dev`；此后无任何输出。
- 判定：Magpie 网关中断导致开局即死，零产出、无提交、无文件改动、无文档。
  第 72 程为该任务的全新重跑，未假设/复用任何第 71 程工作。

### 2026-11-06 · 第 70 程（全游戏例行扫描）

- 交接：HEAD `381bf26`，工作区干净，无会话在跑；Magpie 网关未出现中断。
  任务单 brief74：只做例行扫描 + 修扫描发现的产品行为缺陷，不开新功能、
  不推送、不更新网页版。
- 任务 0 · 基线核验：与第 69 程逐项一致（单元 13451/0、十一套集成
  894 / 102 / 613 / 207 / 113 / 59 / 433 / 45 / 2315 / 4358 / 5133、
  退出 10/10、像素 36/0），三个大图套件均跑完。
- 逐面扫描：关闭回退/焦点/存档边界/回归抽查复用既有套件复跑，未发现
  新缺陷；性能按第 68/69 程同口径用临时探针实测并记录（测后删除）；
  文案面发现并修复 5 项（8 处）：局内商店「缝合书页」45/30 写反（实际
  35/45/−12）、档案馆买到第 10 级后仍报下一次价格、阿砚神铸固定报
  「祝福 +1」且描述写「免费」、咕噜货架只说换词（实际含 3 件遗物）、
  零污染遗物卡印「污染 +0」。
- 修复：`run_loot.gd`（卡面数值 + 遗物污染行守卫）、`archive_ui.gd`
  （满级提示）、`hub.gd`（神铸按共享上限实报）、`npc_profiles.gd`
  （神铸/货架描述）；未改任何数值、存档、上限、成长设计或可达性。
- 回归断言：`test_shop` +1、`test_hub_final` +9、`test_demo_loot` +4，
  单元 **13451 → 13465 / 0**；`integration_menus` +12，菜单集成
  **433 → 445 / 0**；`integration_playability` +5，可玩性集成
  **894 → 899 / 0**；gamepad 207、run_save 613、ui_prompts 113 复跑
  0 失败。
- 收尾：完整套件复跑全绿（见专节）；临时探针删除，工作区仅含产品/测试/
  文档改动；未新增待拍板项，第 11–16 项未碰，第 2–4 章仍不可达，
  `CHAPTER_PLAN_PATHS` / `MDS_WORLD_FILES` 未动；未推送、未更新网页版。
  提交：`808ec47`（fix）、`249f774`（test）、`f93b58a`（docs）。

### 2026-11-06 · 第 69 程（全游戏例行扫描）

- 交接：HEAD `a034d30`，工作区干净，无会话在跑；Magpie 网关开工前可用，
  全程未中断。任务单 brief73：只做例行扫描 + 修扫描发现的产品行为缺陷，
  不开新功能、不推送、不更新网页版。
- 任务 0 · 基线核验：见「例行扫描（第 69 程）」任务 0 节；与第 68 程逐项
  一致（单元 13434/0、十一套集成 894 / 102 / 613 / 207 / 113 / 59 / 428 /
  45 / 2315 / 4358 / 5133、退出 10/10、像素 36/0），三个大图套件均跑完。
- 逐面扫描：关闭回退/焦点/存档边界/回归抽查均复用既有套件复跑，未发现
  新缺陷；性能按第 68 程同口径用临时探针实测并记录（测后删除）；文案面
  发现并修复 2 项（3 处）：档案馆开启语句与 demo 上限矛盾、闻烬契约描述
  写「1 次奖励重选」但实际发 10 残页、闻烬情报描述/消息写「首次攻击」
  但实际是永久 +2 武器伤害。
- 修复：`hub.gd` 两处消息按 `ArchiveData.MAX_LEVEL`/实际效果改写；
  `npc_profiles.gd` 两处描述改为实际效果；未改任何数值、存档、上限或
  成长设计。
- 回归断言：`test_hub_final` +17（职能描述价格/契约/情报文案与实际发放），
  单元 **13434 → 13451 / 0**；`integration_menus` +5（档案馆开启语/服务句
  上限文案），菜单集成 **428 → 433 / 0**；gamepad 207、run_save 613 复跑
  0 失败。
- 收尾：临时探针删除、工作区仅含产品/测试/文档改动；未新增待拍板项，
  第 11–16 项未碰，第 2–4 章仍不可达，`CHAPTER_PLAN_PATHS` /
  `MDS_WORLD_FILES` 未动；未推送、未更新网页版。

### 2026-11-06 · 第 68 程（全游戏例行扫描）

- 交接：HEAD `250bcd6`，工作区干净，无会话在跑；Magpie 网关开工前可用，
  全程未中断。任务单 brief72：只做例行扫描 + 修扫描发现的产品行为缺陷，
  不开新功能、不推送、不更新网页版。
- 任务 0 · 基线核验：见「例行扫描（第 68 程）」任务 0 节；与第 67 程逐项
  一致（单元 13429/0、十一套集成 894…5133、退出 10/10、像素 36/0）。
- 任务 1 · 扫描：按六个扫描面逐项核对（关闭回退/焦点/存档边界/性能/文案/
  回归抽查），详见专节。发现并修复 1 项 Hub 产品行为缺陷（档案馆升级满级行
  的假「记忆碎片不足」与可点状态），先探针复现、再修、再补回归断言；其余
  扫描面未发现新缺陷，性能数字照录不优化。
- 任务 2 · 提交与记录：产品代码 + 测试 + 文档按项提交；状态文件头改为第
  68 程、新增本专节与「下一程从这里继续」第 ⑰ 条；新增
  `docs/memory/sessions/2026-11-06-routine-scan-pass68.md` 并在
  `docs/memory/MEMORY.md` 补一行索引；临时探针已删除，`git status` 收尾为空。
  提交：`a08a69e`（fix）、`f2550dc`（test）、`6021935`（docs）。

### 2026-11-06 · 第 67 程（接力收尾第 66 程的结局文本加厚）

- 交接：HEAD `0df592f`；工作区有第 66 程的 5 改 + 5 新增（产品代码 4 + 2 个
  `.uid`、测试 1 + `.uid`、状态文件/session 文档/记忆索引），无提交；第 66 程
  进程在等三套大图集成时死亡。Magpie 网关开工前复查返回 200。
- 任务 0 · 复核与基线：逐文件核对 E3 实现（`EndingEchoData` 文本与
  `display_text` 边界、结束屏 `Echoes` 整块替换、画廊未解锁不泄露、判定/
  存档未改），未发现缺陷；`--headless --import` / `--quit` 退出 0、`ERROR` 0；
  单元 **13429 / 0**；十一套集成 **894 / 102 / 613 / 207 / 113 / 59 / 419 /
  45 / 2315 / 4358 / 5133** 全 0 失败；退出泄漏 **10/10 clean**；demo 像素
  资产 **36 / 0**。数字与第 66 程自称逐项一致，无基线漂移、无回归。
- 任务 1 · 按项提交：产品代码（含两个新增 `.uid`）、测试（含 `.uid`）、
  文档三笔；另以「pin」提交补记三笔 hash；`git status` 收尾为空。
- 任务 2 · 记录：状态文件头改为第 67 程、第 66 程专节补「接力收尾（第 67 程）」、
  基线行补复跑确认、「下一程从这里继续」补第 ⑯ 条；session 文档就地补一句
  接力核验。本程未开新功能、未碰待确认第 11–16 项、未推送、未更新网页版。

### 2026-11-06 · 第 66 程（结局文本加厚，叙事审计 E3）

- 交接：HEAD `0df592f`，工作区干净，无会话在跑；Magpie 网关由监工核查正常
  （`curl http://127.0.0.1:3425/v1/models` 返回模型列表）。任务来源 brief70：
  第 65 程已完成 E2 第一批，本程做 E3——每个结局补五名 NPC 余味、补
  「笑面史官身份」「最后一页」的回收，只做文本与展示。
- 任务 0 · 基线核验（Godot 4.7.stable.official.5b4e0cb0f）：`--headless
  --import` / `--quit` 退出 0、`ERROR` 0；全量单元 **12960 / 0**；十一套集成
  **894 / 102 / 613 / 207 / 113 / 59 / 419 / 45 / 2315 / 4358 / 5133** 全
  0 失败——与第 65 程收尾逐套件一致，无基线漂移。
- 任务 1 · 结局文本加厚：新增 `EndingEchoData`（25 句余味 + 5 段回收），
  结束屏新增 `Echoes` 标签、画廊已解锁条目追加余味；未解锁仍占位。5 个
  结局 id/标题/现有正文/`ending_for` 判定/`Profile.endings` 记录与存档格式
  一字未改。圣经依据、逐句出处与回收方式见上方「结局文本加厚（第 66 程）」
  专节与 `docs/memory/sessions/2026-11-06-ending-text-thickening.md`。
- 任务 2 · 测试：新增 `tests/test_ending_echoes.gd` **469 断言**（覆盖/文本
  质量/主题对应/结束屏/画廊/存档/判定回归）。全量单元 **12960 → 13429 / 0**；
  十一套集成复跑数字与基线逐套件一致、全 0 失败；`--headless --import` /
  `--quit` 退出 0、`ERROR` 0；退出泄漏 10/10 clean；demo 像素资产 36 / 0。
- 任务 3 · 记录与提交：本专节、第 66 程条目、未完成第 8 项与「下一程」更新；
  新增 session 文档；记忆索引更新；按项提交，收尾工作区干净。
- 不变项：第 1 章 9 房间/6 波次/事件/清房目标 6/结束流程、Hub 闲聊与关键词
  回应、信任数值与 `[npc] trust`/`[npc] events` 存档格式、NPC 立绘、经济/
  锻造/商店数值均未改；第 2/3/4 章仍不可达；`CHAPTER_PLAN_PATHS` /
  `MDS_WORLD_FILES`、章节路由、相机/HUD、电梯速度、门逻辑、地图标题、
  敌人美术、战斗密度、`ch4_shortcut` 授予均未动；待确认第 11–16 项未碰、
  未新增条目；未推送、未更新网页版。

### 2026-11-06 · 第 65 程（三位可见 NPC 的 Hub 个人事件，叙事审计 E2 第一批）

- 交接：HEAD `a9e47d6`，工作区干净，无会话在跑；Magpie 网关已由监工核查正常
  （`curl http://127.0.0.1:3425/v1/models` 返回 DeepSeek V4.1 Flash）。任务来源
  brief69：第 2–4 章大地图施工已全部完成并通过系统验收，剩余未完成项均为待拍板
  项，本程转向叙事审计 E2，先做 demo 中可见的三名 Hub NPC 个人事件。
- 任务 0 · 基线核验（Godot 4.7.stable.official.5b4e0cb0f）：`--headless --import`
  / `--quit` 退出 0；单元 **12773 / 0**；`integration_playability` **894 / 0**、
  `integration_ch1_demo` **102 / 0** 已复跑并与交接一致；其余套件在基线跑到一半时
  因本程开始修改代码而中止（读到未导入的新类），收尾时统一重跑并与交接对照。
- 任务 1 · 三位 NPC 个人事件：新增 `NPCEventData`（三事件对白 + 触发判定）、
  `Profile.npc_events`（`[npc] events` 存档键）、`hub.gd` 事件对话分支。触发 =
  信任档 + `Profile.demo_cleared`：陆沉 信任（6）、阿砚 托付（12）、咕噜 熟悉（2）；
  读完最后一行才记录，中途关闭不消耗；零奖励、零数值改动；咕噜事件后不自动开
  商店。闻烬/白榆保持不可见、无事件。圣经依据、档位理由与对白节拍见上方
  「NPC 个人事件（第 65 程）」专节与 `docs/memory/sessions/2026-11-06-npc-personal-events.md`。
- 任务 2 · 测试：新增 `tests/test_npc_events.gd` **187 断言**；`integration_menus`
  新增 `_test_npc_personal_events`（真实 Hub 场景触发/一次性/早关不消耗/无奖励/
  商店不跳转），**391 → 419 / 0**（+28）。全量单元 **12773 → 12960 / 0**；
  十一套集成 **894 / 102 / 613 / 207 / 113 / 59 / 419 / 45 / 2315 / 4358 / 5133**
  全 0 失败（只有 `integration_menus` +28，其余与第 64 程基线逐套件一致）；
  `--headless --import` / `--quit` 退出 0、`ERROR` 0；退出泄漏 10/10 clean；
  demo 像素资产 36 / 0。
- 任务 3 · 记录与提交：本专节、第 65 程条目、`SUPERVISOR_STATUS.md` 未完成第 8 项
  与「下一程」更新；新增 ADR `docs/memory/decisions/2026-11-06-npc-personal-events.md`
  与 session 文档；记忆索引更新；按项提交，收尾工作区干净。
- 不变项：第 1 章 9 房间/6 波次/事件/清房目标 6/结束流程、Hub 闲聊与关键词回应、
  信任数值与 `[npc] trust` 格式未改（只新增 `[npc] events`）；NPC 立绘未改；未新增
  背包物品类型、未改经济/锻造/商店数值；第 2/3/4 章仍不可达；`CHAPTER_PLAN_PATHS` /
  `MDS_WORLD_FILES`、章节路由、相机/HUD、电梯速度、门逻辑、地图标题、敌人美术、
  战斗密度、`ch4_shortcut` 授予均未动；待确认第 11–16 项未碰、未新增条目；未推送、
  未更新网页版。

### 2026-11-06 · 第 64 程（接力核验第 63 程在途改动并收尾）

- 交接：HEAD `13426f6`；工作区有 7 个未提交文件（180 增 / 11 删），均为第 63 程
  brief67 任务 1/2/3 范围；第 63 程进程在收尾前死亡（`session67.log` 只有一行
  `[claude-code:unrecognized_model]`，无提交、状态文件未更新、session 文档未写）。
  第 2/3/4 章仍不可达，`CHAPTER_PLAN_PATHS[2]/[3]` 仍空；待确认第 11–16 项开放，
  本程不施工、不猜测。
- 任务 0 · 在途改动核查：逐文件对照 brief67 目标——`mds_big_room.gd` 背景改
  底部锚 + 奇数行镜像、`backdrop_rect_local()` 与房间求交；`game.gd` 统计
  `BenchCheckpoint` 并只在「非大图 / 有长椅 / 有商店」时走休整分支；截图脚本
  清第 1 章目标提示；四个测试文件断言与两处产品改动一一对应。无半截代码、
  无方向性错误，未做返工。
- 任务 0 · 基线核验（Godot 4.7.stable.official.5b4e0cb0f）：
  `--headless --import` / `--quit` 退出 0、`ERROR` 0；单元 **12773 / 0**
  （第 62 程 12755 + `test_big_room` 新增 18 条背景镜像/接缝断言）；
  十一套集成 **894 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2315 / 4358 /
  5133** 全 0 失败（第 2 章 2209 → 2315 +106、第 3 章 4235 → 4358 +123、
  第 4 章 5004 → 5133 +129，新增均为接缝/入口文案断言）；退出泄漏
  **10/10 clean**；demo 像素资产 **36 / 0**。除新增断言外无漂移、无回归。
- 任务 1 · 截图对照：9 张重截图齐全（2026-11-05 21:40–21:43 UTC，晚于产品与
  脚本改动），尺寸/非空/非黑非白核验通过（均值 32.1–56.5、暗像素 ≤ 0.6%、
  白像素 0%）；逐张目视确认入口目标「继续前进」、无休整句；井/ Boss 取景无
  硬拼接线。三张纵井在接缝行（屏幕 y=472）做行差量化：2.6 / 0.5 / 3.8，
  低于同段中位数（3.9 / 1.3 / 4.4），修复生效，非取景/渲染口径问题。
- 任务 2 · 记录与提交：本专节、`docs/memory/sessions/2026-11-06-bigmap-screenshot-fixes.md`、
  记忆索引、「未完成」第 10 项与「下一程」更新；按项提交，收尾工作区干净。
- 不变项：未修第 60 程问题 1/3/5/6/7（第 13/15 项相关部分拍板前不施工）；
  未碰待确认第 11–16 项、未新增条目；`CHAPTER_PLAN_PATHS` / `MDS_WORLD_FILES`、
  章节路由、相机/HUD、电梯速度、门逻辑、地图标题、敌人美术、战斗密度、
  `ch4_shortcut` 授予均未动；第 2/3/4 章仍不可达；未推送、未更新网页版。

### 2026-11-06 · 第 63 程（第 2–4 章大图样图问题修复；进程中断，第 64 程接力收尾）

- 交接：HEAD `e5e5f17`，工作区干净。任务来源 brief67：修第 60 程样图里可修的
  两项表现问题（背景纵向接缝、入口/枢纽套用休整文案）并重拍样图对照。
- 修复 1 · 背景纵向接缝：`MDSBigRoom._build_backdrop()` 改为以房间底部为锚、
  自下而上平铺，奇数行 `flip_v` 镜像，使相邻瓦片共用边缘行；`backdrop_rect_local()`
  与房间求交。成因与验证见「第 2–4 章大图样图问题修复（第 63 程）」专节。
- 修复 2 · 休整文案路由：`game.gd._on_mds_room_loaded` 统计 `BenchCheckpoint`，
  无 `Arena` 的大图房间只有作者长椅/商店时才走休整目标与 `RestRoomData` 文案，
  否则只写「继续前进」；第 1 章与书库分支不变。
- 测试与截图：`test_big_room` 新增镜像接缝像素断言；第 2/3/4 章大图集成补
  「底行正立落在房间地面、奇数行镜像」与入口/枢纽目标断言；重拍 9 张样图；
  截图脚本清掉第 1 章目标提示。
- 中断说明：本程在收尾前进程死亡，未提交、未更新状态文件与记忆。第 64 程
  核查确认上述改动完整、测试全绿、截图已反映修复，遂按原方向收尾，未返工。

### 2026-11-06 · 第 62 程（第 4 章大图门视觉专项与敌人美术核查）

- 交接：HEAD `e5e5f17`，工作区干净，无会话在跑；第 61 程（brief65）因 Magpie
  网关中断从未启动（`session65.log` 仅两行连接失败、无提交），本程为同一任务单
  的接力重试。第 2/3/4 章仍不可达，`CHAPTER_PLAN_PATHS[2]/[3]` 仍空；待确认
  第 11–16 项开放，本程不施工、不猜测。
- 任务 0 · 基线核验（Godot 4.7.stable.official.5b4e0cb0f）：
  `--headless --import` / `--quit` 退出 0、`ERROR` 0；单元 **12657 / 0**；
  十一套集成 **894 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209 / 4235 /
  4869** 全 0 失败；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。
  与第 60 程交接一致，无漂移。
- 任务 1 · 第 4 章门视觉：先读 `chapter_4_bigmap.mdsworld.json` 与 9 个场景，
  确认 22 门 = 20 有向 + 2 仅到达，side 5/5/5/5/2；全部由 `MDSBigRoom` 通用
  `GateVisual` 自动覆盖。逐门核验 22/22 通过；补三类断言（侧门内展、舱口两轴
  不越界、世界文件直方图/有向/到达交叉校验），第 4 章集成 **4869 → 5004 / 0**。
  `ch4_well/top1` 标题由第 49 程 `caption_area` 夹到 x=0，无新缺陷、未改产品代码。
- 任务 2 · 地图标题复核：「笑面剧场地图」由 `integration_ch4_bigmap` 的
  `chapter_4_map_title` 与 `test_map_overlay` 的 ch1/ch4 断言锁定，复跑成立；
  未新增断言、未改规则/HUD。
- 任务 3 · 敌人美术：`ROOM_WAVES[3]` 现算 7 种，全部专属 PNG/`ENEMY_ART`/
  白 tint/无回退；`mask_enemy`/`seat_husk` 为复用基础场景与数据的贴图变体；
  第 50/59 程「8 种」的第 8 个 `echo_enemy` 只在旧第 4 章房间组（已有第 1 章
  美术）。`test_enemy_art` 200 → **298**；第 4 章集成六波真实区域补白 tint/
  专属图断言。
- 任务 4 · 下一程候选：第 60 程样图问题（底部 HUD 遮挡/第 13 项、背景纵向
  接缝、`boss_background` 被静态背景遮住/与第 15 项相关、入口休整文案、
  电梯贴边、Boss 脚部被 HUD 压住、第 2 章背景色调）只记入下一程候选，本程未修；
  与第 13/15 项相关的部分拍板前不施工、不定口径。
- 收尾验证：单元 **12755 / 0**（+98）；第 4 章集成 **5004 / 0**（+135）；
  其余十套集成与基线一致全 0 失败；`--headless --import` / `--quit` 退出 0、
  `ERROR` 0；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。
- 本程提交：`65e815a` `test: audit chapter 4 gate visuals and enemy art`；
  随后文档提交记录本程状态、session、记忆索引与门视觉 ADR 补充。
- 不变项：`scripts/` / `scenes/` / `resources/` 零改动；门位/模式/单向语义/
  `requires`/屏障/过渡目标未改；`CHAPTER_PLAN_PATHS` / `MDS_WORLD_FILES` /
  章节路由/可达性/相机/HUD/电梯速度/数值/地图标题/敌人美术未动；第 2/3/4 章
  仍不可达；待确认第 11–16 项未碰。未做打包/导出/安装器/签名/安卓/触屏，
  未推送、未更新网页版。

### 2026-11-06 · 第 60 程（第 2–4 章样图截图，只截图）

- 交接：HEAD `4cc62fa` 前为 `8f9baa4`（第 59 程文档），工作区干净；第 2/3/4 章
  仍不可达，`CHAPTER_PLAN_PATHS[2]/[3]` 仍空；待确认第 11–16 项开放，本程不
  施工、不猜测。任务来源 `.supervisor/DECISIONS.md`「样图截图（监工决定
  2026-11-06，用户想看新章节的样子）」与 brief64 / 第 60 程。
- 任务 0 · 基线核验（Godot 4.7.stable.official.5b4e0cb0f）：
  `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0；单元
  **12657 / 0**；十一套集成 **894 / 102 / 613 / 207 / 113 / 59 / 391 / 45 /
  2209 / 4235 / 4869** 全 0 失败；退出泄漏 `tests/check_exit_clean.sh`
  **10/10 clean**；demo 像素资产 **36 / 0**。与第 59 程交接完全一致，无漂移。
- 任务 1 · 截图脚本：新增 `tests/capture_bigmap_chapters.gd`（+ 导入生成的
  `.gd.uid`）。`xvfb-run -a godot --path . --resolution 1280x720
  --rendering-driver opengl3 --audio-driver Dummy -s
  tests/capture_bigmap_chapters.gd -- --out-dir=res://artifacts/screens`；
  真实 `scenes/main.tscn` + 临时挂载第 2/3/4 章计划与大区世界（与
  `integration_ch2/3/4_bigmap.gd` 同手法），拍完不写回产品默认值。修复首轮
  两个脚本自身问题：图片路径漏加 `.png` 扩展名；`scene` 为 Variant 导致
  `room` / `y` / `player_screen` 无法推断类型（补显式类型）。Boss 取景从
  Arena 局部 x=580 改到 500（`ArenaRoom.entry_half_width = 530` 内），并等
  2.6 s 拍到入场句 + 血条 + 攻击预警。
- 任务 2 · 产出 9 张 1280×720 PNG（`artifacts/screens/ch2|ch3|ch4/`，不提交）：
  `ch2_entry_panorama.png` / `ch2_well_shaft.png` / `ch2_boss_lung_bell.png`；
  `ch3_entry_panorama.png` / `ch3_well_shaft.png` / `ch3_boss_last_reader.png`；
  `ch4_entry_theater.png` / `ch4_well_backstage.png` /
  `ch4_boss_smiling_archivist.png`。逐张核验：尺寸 1280×720、非空、非全黑
  非全白（像素均值 28.5–46.5、暗像素 ≤ 1.3%、白像素 0%），玩家均在画面内
  （入口屏幕坐标 (640,452)、纵井 (480,364)、Boss (640,612)）。取景与逐张
  画面内容见「样图截图（第 60 程）」专节与
  `docs/memory/sessions/2026-11-06-chapter-screenshots.md`。
- 任务 3 · 截图发现（只记录，本程不修）：① 底部 HUD 遮挡（第 13 项，确认
  第 3/4 章同样受影响）；② 1536×864 背景按 1440/2160 房间纵向平铺的接缝
  （`ch4_boss` 顶部约 290 px 黑带最明显）；③ `boss_background`
  （`spore_drift` / `deep_water` / `blood_moon`）被 `MDSBigRoom` 静态背景
  （`z_index = -20` vs MDS 动画背景 `-110`）完全遮住；④ 入口/枢纽区无
  `Arena` 时套用 `RestRoomData` 休整文案与目标，第 3 章入口出现「纸人」字样；
  ⑤ 纵井电梯作者位置贴房间左缘、相机夹取后只露一条横线；⑥ Boss 脚部仍在
  底部 HUD 后；⑦ `breathing_ruins.png` 与第 1 章档案馆色调接近。均只记录，
  未改产品代码、未修、未新增待确认条目。
- 提交：`4cc62fa` `test: capture chapter 2-4 sample frames`（2 文件，
  `tests/capture_bigmap_chapters.gd` + `.gd.uid`）；随后文档提交记录本程
  状态与 session。PNG 留在 `artifacts/screens/`（`artifacts/` 已 gitignore），
  不提交。
- 不变项：`scripts/` / `scenes/` / `resources/` 零改动；`CHAPTER_PLAN_PATHS` /
  `MDS_WORLD_FILES` / 章节路由 / 可达性 / 数值 / 门 / 地图标题 / 敌人美术 /
  HUD / 相机均未动；第 2/3/4 章仍不可达，待确认第 11–16 项未碰。未做打包/
  导出/安装器/签名/安卓/触屏，未推送、未更新网页版。

### 2026-11-05 · 第 59 程（第 4 章大地图系统验收，接力首次尝试）

- 交接：HEAD `70a2510`，工作区不干净——唯一未提交文件是未跟踪的
  `tests/integration_ch4_bigmap.gd`（1782 行），来自 brief62 / 第 59 程首次
  尝试（该程 01:07 启动后因 Magpie 网关中断夭折，`.supervisor/session62.log`
  只有一行 `[claude-code:unrecognized_model]`，无提交、状态未更新）。监工在
  开程前重启网关并复查 HTTP 200（DeepSeek V4.1 Flash 可用）。第 2/3/4 章仍
  不可达，`CHAPTER_PLAN_PATHS[2]/[3]` 仍空；待确认第 11–16 项开放，本程不
  施工、不猜测。
- 任务 0 · 基线核验（HEAD `70a2510`，Godot 4.7.stable.official.5b4e0cb0f）：
  `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0；单元
  **12657 / 0**；十套集成 **894 / 102 / 613 / 207 / 113 / 59 / 391 / 45 /
  2209 / 4235** 全 0 失败；demo 像素资产 **36 / 0**。与交接一致，无漂移。
- 任务 1 · 遗留初稿核查（结论：可复用，但从未跑通）：`tests/integration_ch4_bigmap.gd`
  按第 48 程第 3 章验收脚本的口径写成（真实主场景 + 计划/大区世界临时挂载、
  22 门行走、房间/相机/坠落、宝箱/残碑、双遭遇、事件、存档、Boss/章末），
  但 `_run()` 内 `enemy_art` / `enemy_fallback` 重复声明，GDScript 解析失败
  （`There is already a variable named "enemy_art" declared in this scope`）。
  删除重复声明后首次运行 **4766 断言 / 0 失败**；未重写框架。
- 任务 2 · 覆盖缺口补齐（对照任务单第 2 条清单）：① 5 台电梯
  （`branch_b`/`hub`/`vault`/`well`/`elite`）逐一实测 `speed == 80`、行程不
  夹紧、平台矩形在房间内；② `Ch4EventData` 7 组文案完整（8 个字段非空）、
  `pick` 确定且不耗 run RNG；③ Boss 阶段 3 文案；④ 权柄基础池 = 续命/改写，
  吞噬在污染 ≥ 40、归档在记录 ≥ 2 时追加；⑤ `branch_b`/`well`/`elite` 的
  四个战斗遭遇在真实区域生成并逐区校验精灵 = 计划波次；⑥ 记录战斗密度
  （大图每遭遇 2 只 vs 旧世界每房 3–4 只，只记录不改）。最终 **4869 断言 /
  0 失败，连续两次**。
- 任务 3 · 验收结论：见「第 4 章大地图系统验收（第 59 程）」专节与
  `docs/memory/sessions/2026-11-06-chapter4-bigmap-acceptance.md`。要点：
  九区 BFS 全可达、22 门全走、2 扇单向正确；九区单矩形边界/相机 = 世界边界；
  5 台电梯 80 px/s、纵井 3 单向落台、长椅/坠落/顶底门；门过渡无叠加模态；
  3 箱 2 碑一次性；`ch4_branch_a` 双遭遇逐场锁门/清怪/奖励，清房 7（HUD 8）；
  隐藏书库首次发现/地图揭示；捷径屏障默认封闭、测试注入后跨存档保持；
  世界级存档恢复；`SmilingArchivist` 生成/数值/立绘/入场与阶段 2/3/权柄/
  章末结束战役/重载不二次生成；笑面剧场平铺背景、灰烬光柱、`embers`、
  `blood_moon`、地图标题「笑面剧场地图」、8 种敌人专属美术无回退。
- 任务 4 · 性能基线（两次运行区间）：普通区首次 14.5–19.7 ms、热
  12.3–16.6 ms；Boss 冷 71.4–79.7 ms / 热 45.6–45.9 ms；关动态背景
  11.6–12.0 ms、关天气 38.0–38.5 ms、不生成 Boss 21.7–22.8 ms；门过渡
  236.1–243.8 ms。未发现需要本程处理的性能缺陷。
- 真实缺陷：**未发现产品行为缺陷**；改动全在验收脚本自身（解析错误修复 +
  补断言）。未改任何 `scripts/`/`scenes/`/`resources/`，未新增 `ch4_shortcut`
  授予，未改电梯速度/相机/HUD，未接入 `game.gd`。
- 记录：本状态文件新增「第 4 章大地图系统验收（第 59 程）」专节与本日志，
  更新项目现状/已完成/测试汇总/未完成表第 10/13 项/待确认前言/下一程；
  新增 `docs/memory/sessions/2026-11-06-chapter4-bigmap-acceptance.md`；
  `docs/memory/MEMORY.md` 补索引与第 59 程记录。
- 收尾验证：第 4 章大图验收 **4869 / 0**（连续两次）；单元 **12657 / 0**
  （不变，新断言全在集成层）；其余十套集成 **894 / 102 / 613 / 207 / 113 /
  59 / 391 / 45 / 2209 / 4235** 与基线一致、全 0 失败；
  `--headless --import` / `--quit` 退出 0、`ERROR` 0；退出泄漏
  **10/10 clean**；demo 像素资产 **36 / 0**；工作区干净、无临时探针。
- 本程提交：`49f245b` test: accept the chapter 4 big map（新增
  `tests/integration_ch4_bigmap.gd` + `.gd.uid`，4869 断言）；本条收尾文档
  提交紧随其后。
- 本程未做：第 4 章接入 `game.gd`/可达性、第 4 章门视觉专项、第 4 章地图标题
  改动、第 4 章敌人美术核查/接线、Boss 4 机制扩展（删除词/复制武器/舞台机关）、
  舞台母题呈现层、`ch4_shortcut` 授予、战斗密度调整、`mask_enemy`/`seat_husk`
  独立数值、阿砚同行、待确认第 11–16 项、新移动能力、NPC 立绘、MDS 插件、
  打包/导出/签名/安卓/触屏。

### 2026-11-05 · 第 58 程（第 4 章章末收口，只做章末流程与测试层）

- 交接：第 57 程收尾 HEAD `3ee5438`，工作区干净，无会话在跑；第 2/3/4 章仍
  不可达，`CHAPTER_PLAN_PATHS[2]/[3]` 仍空；待确认第 11–16 项开放，本程不施工、
  不猜测。
- 任务 0 · 基线核验（HEAD `3ee5438`，Godot 4.7.stable.official.5b4e0cb0f）：
  `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0；单元
  **12657 / 0**；十套集成 **869 / 102 / 613 / 207 / 113 / 59 / 391 / 45 /
  2209 / 4235** 全 0 失败；退出泄漏 **10/10 clean**；demo 像素资产
  **36 / 0**。与交接一致，无漂移。
- 任务 1 · 前置核查（结论：章末文本/选项/语音齐全，续玩逻辑章节无关，无需新编）：
  - `_complete_chapter` 原有分支：第 1 章 `_chapter == 0` → `demo_cleared` +
    `_finish(true)`；第 2 章 `_chapter == 1` → `_finish(true)`（第 35 程）；
    第 3 章 `_chapter == 2` → `_finish(true)`（第 46 程）；其余
    `_chapter + 1 < chapter_count()` → `_start_chapter`，否则 `_finish(true)`。
    第 4 章 `_chapter == 3` 此前因 `chapter_count() == 4` 落到 `else` 的
    `_finish(true)`，行为上已结束战役，但没有显式分支。
  - `CampaignData.chapter(3)`：4 句 `outro`、两选项（重写名册 仁慈 +1 /
    焚毁名册 污染 +12）、`voice_outro = ch4_outro`
    （`assets/audio/voice/zh_cn/ch4_outro.ogg` 存在）；`_apply_chapter_choice`
    已有 `smiling_theater` 分支（选项 1 置 `_burned_final`）；**未新编剧情、
    未新设选项**。
  - 续玩/重载沿用章节无关的 `_boss_defeated` → `_resume_boss_aftermath`
    （Boss 4 已死不二次生成）；本程只补断言，不改逻辑。
- 任务 2 · 章末收口：`_complete_chapter` 新增 `_chapter == 3` 分支 →
  `_finish(true)` 结束战役；第 1/2/3 章分支与 `_chapter + 1 < chapter_count()`
  兜底未改，只更新第 3 章分支上方过时注释。行为与旧 `else` 兜底等价，未产生
  可玩行为变化。
- 任务 3 · 测试：`_test_ch4_bigmap_boss` 扩为完整章末链路（+22 断言：第 4 章
  原文/语音/选项、outro/选择页文案、选项 0 仁慈 +1 与零污染、
  `_burned_final == false`、结局按 `ending_for` 规则并写入 `Profile.endings`、
  `chapter_count() == 4`）；旧线性世界遍历补第 4 章停章分支（+3）并同步等待
  时长与第 3 章注释；可玩性集成 869 → **894**。
- 任务 4 · 记录：本状态文件新增「第 4 章章末收口（第 58 程）」专节与本日志，
  更新项目现状/已完成/测试汇总/未完成表第 10/13 项/待确认前言/下一程；新增
  `docs/memory/sessions/2026-11-06-chapter4-chapter-end.md` 与 ADR
  `docs/memory/decisions/2026-11-06-chapter4-ending.md`；
  `docs/memory/MEMORY.md` 补索引与第 58 程记录。
- 收尾验证：单元 **12657 / 0**（不变，新断言全在集成层）；可玩性集成
  **894 / 0**（869 + 25）；其余九套集成 **102 / 613 / 207 / 113 / 59 / 391 /
  45 / 2209 / 4235** 与基线一致、全 0 失败；`--headless --import` / `--quit`
  退出 0、`ERROR` 0；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**；
  工作区干净、无临时探针。
- 本程提交：`6004413` feat: end the chapter 4 campaign at its boundary
  （`_complete_chapter` 显式第 4 章终点）；`fcff5e5` test: cover the chapter 4
  chapter-end closure（章末链路 + 旧世界停章断言）；本条收尾文档提交紧随其后。
- 本程未做：第 4 章接入 `game.gd`/可达性、第 4 章大图验收、Boss 4 机制扩展
  （删除词/复制武器/舞台机关）、待确认第 11–16 项、`ch4_shortcut` 授予/战斗
  密度/`mask_enemy`/`seat_husk` 独立数值/舞台母题/阿砚同行、新移动能力、
  NPC 立绘、MDS 插件、打包/导出/签名/安卓/触屏。

### 2026-11-05 · 第 57 程（第 4 章 Boss 4 机制与 `boss_scene` 路由，只做机制与测试层）

- 交接：第 56 程收尾 HEAD `870b37c`，工作区干净，无会话在跑；第 2/3/4 章仍
  不可达，`CHAPTER_PLAN_PATHS[2]/[3]` 仍空；待确认第 11–16 项开放，本程不施工、
  不猜测。Magpie 网关正常（HTTP 200 / 模型列表可读）。
- 任务 0 · 基线核验（HEAD `870b37c`，Godot 4.7.stable.official.5b4e0cb0f）：
  `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0；单元 **12574 / 0**；
  十套集成 **810 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209 / 4235** 全 0 失败；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与交接一致，无漂移。
- 任务 1 · 前置核查（结论：既有实现可直接复用，无需改脚本）：
  - `scripts/bosses/smiling_archivist.gd`（`SmilingArchivist extends
    InkArchivist`）与 `scenes/bosses/smiling_archivist.tscn` 已存在；阶段 1
    纸页波；阶段 2 每第 3 次镜面弹幕（3 枚、张角 ±0.34 rad、每枚
    `int(攻击力 × 0.7)`、速度 280），其余纸页波（阶段 ≥2 双发）；阶段 3 四拍
    `%4` = 改写 → 镜面弹幕 → 墨雨 → 纸页波（墨雨 3 个 `InkWarning`、
    `int(攻击力 × 0.75)`；改写封一个短语槽 3.0 s）。
  - `CampaignData.chapter(3)`：名「笑面史官」、HP 520 / 伤害 18 / 速度 92 /
    `boss_script = &"smiling"` / 立绘 `smiling_archivist.png`，没有 `boss_scene`。
  - `_spawn_boss` 优先级（战役表 `boss_scene` → 计划 `boss_scene` →
    `boss_script == smiling` → `reader` → 默认）与 `_enemy_spawn_y()`（计划在
    → -18 px，无计划 → 250 px）均未改，本轮只补计划字段与断言。
- 任务 2 · 路由与机制锁定：
  - `chapter_4_demo.tres` 新增 `smiling_archivist.tscn` 的 `ext_resource` 并写
    `boss_scene`；Boss 区备注更新为「已路由 + 入场/阶段文案已编写 + 机制扩展
    仍待拍板」。通用 Boss 流程（生成/血条/阶段横幅/权柄/outro/结束）全复用。
  - 新增 `tests/test_ch4_boss.gd`（78 断言）：计划路由/场景类型、战役表数值/
    立绘/`boss_script` 未改、阶段 1/2/3 完整节拍表、纸页波直伤 18、阶段 2 双发
    36、阶段 3 改写封 0 号槽/3.0 s、生成高度 -18/250、第 4 章选句键不回落
    第 1/2/3 章、第 1/2/3 章 Boss 隔离、计划槽/旧世界/清房目标 7/波次/权柄池锁。
  - `tests/test_ch4_plan.gd`（795 → **797**）、`tests/test_ch4_world.gd`
    （813 → **814**）、`tests/test_ch4_content.gd`（642 → **644**）：把「计划无
    `boss_scene`」的旧期望改为「已路由且指向 `smiling_archivist.tscn`」。
  - `tests/integration_playability.gd` 新增 `_test_ch4_bigmap_boss`：真实第 4 章
    大区世界 + 计划临时挂载（`ch4_boss` 起始），验证计划路由 `SmilingArchivist`、
    数值来自战役表、生成在 Arena 地面线之上、阶段 2/3 横幅用第 4 章选句键、
    实树镜面弹幕（3 枚 / 12 / 280）/墨雨（3 个预警 / 13）/改写（封 0 号槽）生效、
    击败 → 权柄 → outro → 章末选择 → 战役结束、重载不二次生成；测试后恢复旧
    第 4 章世界。可玩性集成 810 → **869**。
- 任务 3 · 待确认项与开放问题：未新增 `ch4_shortcut` 授予（屏障保持封闭）；
  战斗密度未扩波/未增遭遇；`mask_enemy`/`seat_husk` 独立数值未做；Boss 4 机制
  扩展（删除词/复制武器/舞台机关）未做、未设计、未新增攻击手段；舞台母题未改
  呈现层；阿砚同行未做；待确认第 11–16 项未碰。
- 任务 4 · 记录：本状态文件新增「第 4 章 Boss 4 机制与 `boss_scene` 路由
  （第 57 程）」专节、本日志，更新项目现状/已完成/未完成表第 8/10/13 项/
  待确认前言/下一程；新增
  `docs/memory/sessions/2026-11-06-chapter4-boss4-mechanism.md`；
  `docs/memory/MEMORY.md` 补索引与第 57 程记录。
- 收尾验证：单元 **12657 / 0**（= 基线 12574 + 83：新增 `test_ch4_boss` 78 +
  `test_ch4_plan` +2、`test_ch4_world` +1、`test_ch4_content` +2）；可玩性集成
  **869 / 0**（= 基线 810 + 59）；其余九套集成 **102 / 613 / 207 / 113 / 59 /
  391 / 45 / 2209 / 4235** 与基线一致、全 0 失败；`--headless --import` /
  `--quit` 退出 0、`ERROR` 0；退出泄漏 **10/10 clean**；demo 像素资产
  **36 / 0**；工作区干净、无临时探针。
- 本程提交：`fc367d1` feat: route the chapter 4 smiling archivist boss
  （第 4 章计划 `boss_scene` 路由、`test_ch4_boss` 与三个既有第 4 章套件期望
  更新、可玩性集成 `_test_ch4_bigmap_boss`）；本条收尾文档提交紧随其后。
- 本程未做：第 4 章接入 `game.gd`/可达性、Boss 4 机制扩展、第 4 章大图验收/
  章末收口、待确认第 11–16 项、`ch4_shortcut` 授予/战斗密度/`mask_enemy`/
  `seat_husk` 独立数值/舞台母题/阿砚同行、新移动能力、NPC 立绘、MDS 插件、
  打包/导出/签名/安卓/触屏。

### 2026-11-05 · 第 56 程（第 4 章内容数据层第 3 步：事件区真实自动触发，只做触发与测试层）

- 交接：第 54 程收尾 HEAD `3a37d8d`，工作区干净，无会话在跑；第 2/3/4 章仍
  不可达，`CHAPTER_PLAN_PATHS[2]/[3]` 仍空；待确认第 11–16 项开放，本程不施工、
  不猜测。本程为同一任务单第 2 次尝试：第 55 程（session58）在启动时因 Magpie
  网关中断夭折（日志仅一行 `[claude-code:unrecognized_model]`，无提交、无残留
  文件）；监工重启网关并复查 HTTP 200 后由本程接力。
- 任务 0 · 基线核验（HEAD `3a37d8d`，Godot 4.7.stable.official.5b4e0cb0f）：
  `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0；单元 **12573 / 0**；
  十套集成 **755 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209 / 4235** 全 0 失败；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与交接一致，无漂移。
- 任务 1 · 事件区真实触发验证（只做触发与测试层，见专节）：
  - 前置核查确认 `_on_mds_room_loaded` 第 34 程的区域级大图事件分支是章节无关
    判定（`big_map` + 计划区域 `type == "event"` + `_event_data(room_id)` 非空），
    第 53 程 `_event_data` 已路由第 4 章；`ch4_event` 无需第 4 章专属触发路径。
    `game.gd` 仅把该分支注释的「Chapters 2–3」更正为「Chapters 2–4」，行为零改动。
  - `tests/integration_playability.gd` 新增 `_test_ch4_bigmap_event_trigger`，
    把 `chapter_4_bigmap_world.tscn` 与第 4 章计划临时挂到真实主场景
    （`ch4_event` 为起始区），走真实 `room_loaded`：进入即开第 4 章事件页，
    文案/标题/两选项 = `Ch4EventData.pick(run_seed, "ch4_event/event")`，开页与
    「拿」不耗 run RNG；拿 → 残页 +12、提示与 HUD「档案 1 / 8」；结算写
    `cleared_encounters["ch4_event/event"]`、清房计数 +1、run save 同一键；重载
    不重开/不暂停/不重复计数/不重复奖励；回退结算后重进再验「读」→ 污染 +8
    （倍率/上限 100）+ 解明一残页词或兜底 +6。测试后恢复第 4 章旧世界巡检。
  - 同测试锁不变项：`CHAPTER_PLAN_PATHS[3]` 空、`MDS_WORLD_FILES[3]` 仍指旧
    `chapter_4.mdsworld.json`、旧第 4 章 9 房/17 门世界仍在、第 1/2/3 章计划槽
    不变、计划清房目标 7 / 7 个遭遇 / 波次表（`content_pending = false`）/
    `boss_scene` 仍空、第 1–3 章事件数值不变、`game.gd` 无 `ch4_event` 专属
    触发与 `chapter_4_bigmap` 路由。
  - `tests/test_ch4_content.gd`（641 → **642**）补「触发键 =
    `RoomProgress.event_encounter_id("ch4_event")` = 计划事件节点 id」断言，
    文件头注释更新为步骤 1–3。
- 任务 2 · 待确认项与开放问题：未新增 `ch4_shortcut` 授予（屏障保持封闭）；
  战斗密度未扩波/未增遭遇（旧世界 5–6 只 vs 大图每遭遇 2 只只记录）；
  `mask_enemy`/`seat_husk` 独立数值未做；Boss 4 机制/`boss_scene` 未做；
  舞台母题未改呈现层；阿砚同行未做；待确认第 11–16 项未碰。
- 任务 3 · 记录：本状态文件新增「第 4 章内容数据层第 3 步（第 56 程）」专节、
  本日志，更新项目现状/已完成/未完成表第 10/13 项/待确认前言/下一程；
  新增 `docs/memory/sessions/2026-11-05-chapter4-event-trigger.md`；
  `docs/memory/MEMORY.md` 补索引与第 56 程记录。
- 收尾验证：单元 **12574 / 0**（= 基线 12573 + 1，`test_ch4_content`）；可玩性
  集成 **810 / 0**（= 基线 755 + 55：新增测试 54 条 + 第 4 章旧世界恢复 1 条）；
  其余九套集成 **102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209 / 4235** 与基线
  一致、全 0 失败；`--headless --import` / `--quit` 退出 0、`ERROR` 0；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**；工作区干净、无临时探针。
- 本程提交：`4981b47` test: cover the chapter 4 event region trigger（第 4 章
  事件区触发集成测试、触发键单元断言、`game.gd` 分支注释改为 Chapters 2–4）；
  本条收尾文档提交紧随其后。
- 本程未做：第 4 章接入 `game.gd`/可达性、Boss 4 机制/`boss_scene`、第 4 章
  大图验收、待确认第 11–16 项、`ch4_shortcut` 授予/战斗密度/`mask_enemy`/
  `seat_husk` 独立数值/舞台母题/阿砚同行、新移动能力、NPC 立绘、MDS 插件、
  打包/导出/签名/安卓/触屏。

### 2026-11-05 · 第 54 程（第 4 章内容数据层第 2 步：波次接线，只做数据层）

- 交接：第 53 程收尾 HEAD `c6178b3`，工作区干净，无会话在跑；第 2/3/4 章仍
  不可达，`CHAPTER_PLAN_PATHS[2]/[3]` 仍空；待确认第 11–16 项开放，本程不施工、
  不猜测。监工在本程开始前已核查 Magpie 网关 HTTP 200，本程未遇模型调用失败。
- 任务 0 · 基线核验（HEAD `c6178b3`，Godot 4.7.stable.official.5b4e0cb0f）：
  `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0；单元 **12545 / 0**；
  十套集成 **755 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209 / 4235** 全 0 失败；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与交接一致，无漂移。
- 任务 1 · 波次接线（只做数据层，见专节）：
  - `chapter_4_demo.tres` 的 4 个战斗区补 `wave` 字典，6 个键 = 6 个战斗遭遇
    节点 id，值按计划顺序逐字复用 `ROOM_WAVES[3]` 六波（`mask_enemy`+`seat_husk`
    / `choir_summoner`+`page_swarm` / `seat_husk`+`mirror_sniper` /
    `mask_enemy`+`typo_beast` / `ink_bomber`+`mask_enemy` /
    `mirror_sniper`+`page_swarm`），波次内容未新增/未修改。
  - 事件节点 `ch4_event/event` 无波，Boss 区不占普通波次，入口/枢纽/书库不带
    `wave`；清房目标仍 7（HUD 分母 8）。
  - `content_pending` 按第 40/43 程约定由 `true` 改回 `false`，波次表进入
    `validate()` 正常校验；标志本身保留在 `ChapterPlanData`（默认 `false`、
    向后兼容）；图骨架夹具顶层的 `content_pending: true` 是夹具元数据、未改。
  - 产品代码未改：`game.gd`、`ChapterPlanData`、第 4 章世界 JSON/场景、
    Boss 4 数值与文案均保持原样。
- 任务 2 · 校验：`test_ch4_content`（641 断言，+28）波次段从「未接线」改为
  接线校验（6 个键 == 6 个战斗遭遇节点 id、逐键值 == `ROOM_WAVES[3]` 原文、
  键锚定且唯一、事件节点/事件区/Boss 区无波、`validate_waves()`/`validate()`
  干净、`content_pending` 清零），新增 `_test_runtime_wave_lookup` 把第 4 章
  计划挂到独立 `game.gd` 实例经 `_plan_wave()` 按节点 id 读回六波（不改章节
  路由）；`test_ch4_plan`（795，−1）`_test_pending_content` → `_test_wave_wiring`
  并把 `content_pending` 局部性改为「删波次 + 标志开 → 干净；标志关 → 六条
  缺波次」；`test_ch4_world`（813，+1）计划侧期望同步为已接线。既有断言保留：
  `CHAPTER_PLAN_PATHS[3]` 仍空、`MDS_WORLD_FILES[3]` 仍指旧世界、旧第 4 章
  9 房/17 门世界仍在、第 1/2/3 章计划与世界不变、清房目标仍 7。
- 任务 3 · 待确认项与开放问题：未新增 `ch4_shortcut` 授予（屏障保持封闭）；
  战斗密度未扩波/未增遭遇（旧世界 5–6 只 vs 大图每遭遇 2 只只记录）；
  `mask_enemy`/`seat_husk` 独立数值未做；Boss 4 机制/`boss_scene` 未做；
  舞台母题未改呈现层；阿砚同行未做；待确认第 11–16 项未碰。
- 任务 4 · 记录：本状态文件新增「第 4 章内容数据层第 2 步（第 54 程）」专节、
  本日志，更新项目现状/已完成/未完成表第 10/13 项/待确认前言/下一程；
  新增 `docs/memory/sessions/2026-11-05-chapter4-wave-wiring.md`；
  `docs/memory/MEMORY.md` 补索引与第 54 程记录。
- 收尾验证：单元 **12573 / 0**（= 基线 12545 + 28：`test_ch4_content` +28、
  `test_ch4_plan` −1、`test_ch4_world` +1）；十套集成
  **755 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209 / 4235** 全 0 失败
  （与基线一致）；`--headless --import` / `--quit` 退出 0、`ERROR` 0；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**；工作区干净、无临时探针。
- 本程提交：`cf909a8` feat: wire the chapter 4 plan waves（计划波次表、
  `content_pending` 清零、第 4 章测试三件套同步）；本条收尾文档提交紧随其后。
- 本程未做：第 4 章接入 `game.gd`/可达性、事件区真实自动触发验证、Boss 4
  机制/`boss_scene`、第 4 章大图验收、待确认第 11–16 项、舞台母题/战斗密度/
  `mask_enemy`/`seat_husk` 独立数值、阿砚同行、新移动能力、NPC 立绘、
  MDS 插件、打包/导出/签名/安卓/触屏。

### 2026-11-05 · 第 53 程（第 4 章内容数据层第 1 步，只做数据层）

- 交接：第 52 程收尾 HEAD `18ce085`，工作区干净，无会话在跑；第 2/3/4 章仍
  不可达，`CHAPTER_PLAN_PATHS[2]/[3]` 仍空；待确认第 11–16 项开放，本程不施工、
  不猜测。本程为同一任务单第 2 次尝试（首次 session56 因 Magpie 网关不通夭折，
  无提交无残留）；监工已重启网关并复查 HTTP 200，本程未遇模型调用失败。
- 任务 0 · 基线核验（HEAD `18ce085`，Godot 4.7.stable.official.5b4e0cb0f）：
  `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0；单元 **11925 / 0**；
  十套集成 **755 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209 / 4235** 全 0 失败；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与交接一致，无漂移。
- 任务 1 · 第 4 章内容数据层第 1 步（只做数据层，见专节）：
  - 新增 `scripts/data/ch4_event_data.gd`（`Ch4EventData`）：7 组笑面剧场事件
    文案（纸人/面具/名册/幕布/台词/聚光灯/谢幕），固定读/拿两选项；读 →
    污染 +8 + 解明一个残页词 / 兜底残页 +6，拿 → 残页 +12；按
    `hash("%d:%s")` + 事件节点 id `ch4_event/event` 确定性轮换、不耗 run RNG。
  - `game.gd` 的 `_event_data` 扩到第 4 章（索引 3）；第 1 章 `Ch1EventData`
    原键与原值、第 2/3 章 `Ch2/Ch3EventData` 不变，索引 ≥ 4 仍返回 `{}`。
  - `chapter_4_demo.tres` 补 `authority_pool = [续命, 改写]`（条件项仍由
    `AuthorityController.build_pool` 从 `ContentLibrary` 追加吞噬/归档）。
  - `BossEntranceData` 新增第 4 章「笑面史官」8 条入场文案（`variants(3)`）；
    `BossPhaseData` 新增阶段 2/3 各 8 条（`variants(phase, 3)`）；第 1 章保留
    `"%d:%d"` 选句键，第 2/3/4 章用 `"%d:%d:%d"`，不回落第 1/2/3 章。
    `BossEntranceData` 既有键 `"%d:%d" % [seed, chapter_index]` 经核查后保持原样。
  - Boss 4 HP 520 / 伤害 18 / 速度 92 / `smiling_archivist.png` /
    `boss_script = smiling` 未改；计划仍无 `boss_scene`、无专章机制。
  - 计划仍 `content_pending = true`、7 个区域均无 `wave` 表；6 场战斗与
    `ROOM_WAVES[3]` 六波只校验计划顺序（事件节点无波、Boss 区不占普通波），
    清房目标仍 7、HUD 分母 8；计划仍不被 `game.gd` 引用，第 4 章仍不可达。
  - 旧第 4 章 9 房/17 门世界与场景原样保留、不改语义、不删除。
- 任务 2 · 校验：新增 `tests/test_ch4_content.gd`（**613 断言**）锁定事件
  确定性/效果类型/轮换/不耗 RNG、章节事件路由、权柄基础池 + 条件项、Boss 文案
  不回落第 1/2/3 章与选句键不变、Boss 4 数据未改、7 个遭遇节点与
  `ROOM_WAVES[3]` 六波顺序对应、清房目标 7、`content_pending` 保持、事件触发
  谓词输入，并锁 `CHAPTER_PLAN_PATHS[2]/[3]` 仍空、`MDS_WORLD_FILES[3]` 仍指
  旧世界、旧第 4 章世界与第 1–3 章计划/世界不变。同步更新 `test_ch4_plan`/
  `test_ch4_world` 的旧占位期望，以及 `test_ch2_content`/`test_ch3_content`/
  `test_boss_entrance_content`/`integration_ch1_demo` 中「第 4 章静默」的旧
  期望；图骨架夹具只改说明文字，图形数据未改。无临时探针残留。
- 任务 3 · 待确认项与开放问题：未新增 `ch4_shortcut` 授予（屏障保持封闭）；
  战斗密度未扩波/未增遭遇（旧世界 5–6 只 vs 大图每遭遇 2 只只记录）；
  `mask_enemy`/`seat_husk` 独立数值未做；Boss 4 机制/`boss_scene` 未做；
  舞台母题未改呈现层；阿砚同行未做；待确认第 11–16 项未碰。
- 任务 4 · 记录：本状态文件新增「第 4 章内容数据层第 1 步（第 53 程）」专节、
  本日志，更新项目现状/已完成/未完成表第 10/13 项/待确认前言/下一程；
  新增 `docs/memory/sessions/2026-11-05-chapter4-content-data.md`；
  `docs/memory/MEMORY.md` 补索引与第 53 程记录。
- 收尾验证：单元 **12545 / 0**（= 基线 11925 + 新测试 613 + 既有测试净 +7）；
  十套集成 **755 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209 / 4235** 全 0 失败
  （与基线一致）；`--headless --import` / `--quit` 退出 0、`ERROR` 0；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**；工作区干净、无临时探针。
- 本程提交：`c095c8a` feat: author chapter 4 content data layer（`Ch4EventData`、
  `game.gd` 事件路由、计划权柄池、Boss 4 文案、`test_ch4_content.gd` 与既有测试
  期望更新）；文档提交 `c4ac509` docs: record the chapter 4 content data layer
  （本状态文件、会话记录、记忆索引）。
- 本程未做：第 4 章接入 `game.gd`/可达性、波次接线、事件区真实自动触发验证、
  Boss 4 机制/`boss_scene`、第 4 章大图验收、待确认第 11–16 项、舞台母题/
  战斗密度/`mask_enemy`/`seat_husk` 独立数值、阿砚同行、新移动能力、NPC 立绘、
  MDS 插件、打包/导出/签名/安卓/触屏。

### 2026-11-05 · 第 52 程（第 4 章真实大区世界，只做结构层）

- 交接：第 51 程收尾 HEAD `f6e200b`，工作区干净，无会话在跑；第 2/3/4 章仍不可达，
  `CHAPTER_PLAN_PATHS[2]/[3]` 仍空；待确认第 11–16 项开放，本程不施工、不猜测。
  监工在本程开始前已核查 Magpie 网关 HTTP 200，本程未遇模型调用失败。
- 任务 0 · 基线核验（HEAD `f6e200b`，Godot 4.7.stable.official.5b4e0cb0f）：
  `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0；单元 **11095 / 0**；
  十套集成 **755 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209 / 4235** 全 0 失败；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与交接一致，无漂移。
- 任务 1 · 真实大区世界（只做结构层，见专节）：
  - 新增 `resources/rooms/ch4_bigmap/*.tres`（9 个 `BigRoomData`）与
    `scenes/mds/ch4_bigmap/*.tscn`（9 个 `MDSBigRoom`）——尺寸/内容节点 id 严格按
    第 51 程计划（2560×1440；纵井 2560×2160；精英/Boss 3840×2160），地面贴底边、
    平台 80 px 阶梯链、`validate()` 全空、每区 `fall_margin = 240`；
    `backdrop_path = smiling_theater.png`（`backdrop_pixel_art = false`）、
    `ambient_kind = embers`、每区暖色调；复用 `ch1_tiles.tres`。
  - `ch4_entry` 作者 `SpawnPoint`（`save_point`，(400,1328) = 第一级台阶面 −
    `FOOT_Y`）与惰性 `shortcut_arrival` 到达门。
  - 独立世界 `scenes/mds/chapter_4_bigmap.mdsworld.json` +
    `chapter_4_bigmap_world.tscn`：9 区单矩形、原点 32 px 对齐、
    `start_room = ch4_entry`；区域 `Smiling Theater` 镜像旧世界（灰烬 + 光柱、
    `background` 空、`boss_background = blood_moon`），不写 `backdrop_image`、
    不加 theater 层；22 门 = 20 有向 + 2 只到达，`elite_boss` 单向、
    `hub_shortcut_entry` 带 `requires = ["ch4_shortcut"]` 默认封闭；
    世界 JSON 由第 51 程夹具镜像（仅加 `scene_path`），夹具未改语义。
  - 纵向/捷径骨架复用第 29 程管线：`ch4_branch_b`/`ch4_hub`/`ch4_vault`/
    `ch4_well`/`ch4_elite` 5 台电梯、`ch4_well` 3 个单向落台、`ch4_hub` 长椅
    检查点、捷径屏障；电梯沿用管线默认 80 px/s（未碰第 12 项第 2 章节奏）。
  - 旧第 4 章 9 房/17 门世界与场景原地保留、不改语义、不删除；新世界不被
    `game.gd` 引用（`CHAPTER_PLAN_PATHS[3]` 仍空），第 4 章仍不可达。
- 任务 2 · 校验：新增 `tests/test_ch4_world.gd`（**812 断言**）交叉校验计划 ↔ 世界
  并锁定不变项；`tests/test_ch4_plan.gd` 的「`ch4_bigmap` 目录尚未创建」锁改为
  目录/文件存在（778 → **796**），其余路由锁不变。临时探针
  `tests/probe_ch4world52.gd` 用真实 `MDSWorldGame` 逐区加载新世界：
  9 区 `validation_errors` 全空、`fall_below_bounds = 240`、门数与世界 JSON 一致
  （合计 22）、枢纽 1 个 `MDSGateBarrier`、背景平铺、`Ambient` 存在、入口出生点
  (400,1328)；**0 失败**，测后删除（含 `.uid`）。
- 任务 3 · 待确认项与开放问题：舞台母题只按既有区域氛围落地（未加大区 theater 层、
  未改 `TheaterBackdrop`、未新绘背景）；未新增任何授予 `ch4_shortcut` 的交互/事件/
  掉落（屏障保持封闭）；战斗密度未扩波/未增遭遇（旧世界 5–6 只 vs 大图 2 只只记录）；
  `mask_enemy`/`seat_husk` 独立数值未做；Boss 4 机制/`boss_scene`/文案未做；
  章末流程未改（第 3 章停章替身仍在）；阿砚同行未做（仓库仍无 companion 控制器）。
- 任务 4 · 记录：本状态文件新增「第 4 章真实大区世界（第 52 程）」专节、本日志，
  更新项目现状/已完成/未完成表第 10/13 项/待确认前言/下一程；
  新增 `docs/memory/sessions/2026-11-05-chapter4-bigmap-world.md`；
  `docs/memory/MEMORY.md` 补索引与第 52 程记录。未创建临时探针残留。
- 收尾验证：单元 **11925 / 0**（+830：`test_ch4_world` 812 + `test_ch4_plan` +18）；
  十套集成 **755 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209 / 4235** 全 0 失败
  （与基线一致）；`--headless --import` / `--quit` 退出 0、`ERROR` 0；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**；工作区干净、无临时探针。
- 本程提交：`0125562` feat: build the chapter 4 big-map region world（9 个
  `BigRoomData`、9 个 `MDSBigRoom` 场景、独立世界 JSON/场景、`test_ch4_world.gd`、
  `test_ch4_plan.gd` 目录断言更新）；文档提交 `695b505` docs: record the chapter 4 real region
  world（本状态文件、会话记录、记忆索引）。
- 本程未做：第 4 章接入 `game.gd`/可达性、`Ch4EventData`、权柄池、波次接线、
  Boss 4 机制/`boss_scene`/文案/测试、第 4 章大图验收、待确认第 11–16 项、
  舞台母题/战斗密度/`mask_enemy`/`seat_husk` 独立数值、阿砚同行、新移动能力、
  NPC 立绘、MDS 插件、打包/导出/签名/安卓/触屏。

### 2026-11-05 · 第 51 程（第 4 章计划与图骨架，只做数据层）

- 交接：第 50 程收尾 HEAD `b1af454`，工作区干净，无会话在跑；第 2/3/4 章仍不可达，
  `CHAPTER_PLAN_PATHS[2]/[3]` 仍空；待确认第 11–16 项开放，本程不施工、不猜测。
  **本程为接力重试**：第 51 程首次尝试（brief53 / session53）因 Magpie 网关中断夭折，
  日志只有 `[claude-code:unrecognized_model]`，无提交、无文档、无残留；动手前已核对
  `resources/chapters/chapter_4_demo.tres` 与 `tests/test_ch4_plan.gd` 确实不存在。
  监工在本程开始前已重启网关并复查 HTTP 200。
- 任务 0 · 基线核验（HEAD `b1af454`，Godot 4.7.stable.official.5b4e0cb0f）：
  `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0；单元 **10315 / 0**；
  十套集成 **754 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209 / 4235** 全 0 失败；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与交接一致，无漂移。
- 任务 1 · 第 4 章计划（只做数据层，见专节）：新增
  `resources/chapters/chapter_4_demo.tres`——9 区连通图（`ch4_entry` /
  `ch4_branch_a` / `ch4_branch_b` / `ch4_hub` / `ch4_well` / `ch4_vault` /
  `ch4_event` / `ch4_elite` / `ch4_boss`），6 个战斗遭遇按计划顺序对应旧
  `ROOM_WAVES[3]` 六波（本程不接线）+ 1 个事件占位 `ch4_event/event` →
  `clear_target()` 派生 7；3 宝箱/2 残碑；11 门 = 9 双向 + 2 显式单向；
  每区 `fall_below_bounds = 240`；`content_pending = true` 只推迟波次表。
  Boss 门按第 2/3 章先例单向，旧世界 `ch4_boss/left1` 仍返回 `ch4_rest`
  （原样保留，两种行为分别由测试锁定）。计划不写 `wave`/`authority_pool`/
  `boss_scene`/Boss 文案/事件数据/`ch4_shortcut` 授予；占位处均写明待后续内容程。
- 任务 2 · 图骨架夹具与校验：新增
  `tests/fixtures/big_room/ch4_graph.mdsworld.json`（`fixture: true`、
  `content_pending: true`、无房间场景、游戏从不引用；20 扇有向门 + 2 扇到达门；
  镜像 `Smiling Theater` 灰烬/光柱与 `blood_moon` Boss 背景，不写
  `backdrop_image`）与 `tests/test_ch4_plan.gd`（**778 断言**：计划形状/尺寸/
  坠落平面/内容 id/清房目标/图可达性/单向门/捷径占位/待内容标记 +
  `content_pending` 只推迟波次表 + 6 场战斗 ↔ `ROOM_WAVES[3]` 六波按计划顺序 +
  计划↔夹具逐区逐门交叉校验 + 夹具几何 + 第 1–3 章与旧第 4 章世界不变）。
- 任务 3 · 路由锁同步：`tests/test_ch2_world.gd`、`tests/test_ch3_content.gd`、
  `tests/integration_playability.gd` 在既有「第 4 章计划槽为空」旁补
  「计划资源已存在但未接入」（+3 断言）；`CHAPTER_PLAN_PATHS[3]` 仍为空，
  `game.gd` 仍用旧 `chapter_4.mdsworld.json` / `chapter_4_world.tscn`，
  无计划时清房目标 6 / 坠落平面 850 的默认行为断言原样成立。
- 任务 4 · 记录：本状态文件新增「第 4 章计划与图骨架（第 51 程）」专节，
  更新项目现状/已完成/未完成表第 10/13 项/待确认前言/下一程；
  新增 `docs/memory/sessions/2026-11-05-chapter4-plan-graph.md` 与
  `docs/memory/decisions/2026-11-05-chapter4-plan-graph.md`；
  `docs/memory/MEMORY.md` 补索引与第 51 程记录。未创建临时探针，无残留。
- 收尾验证：单元 **11095 / 0**（+780：`test_ch4_plan` 778 + 两处路由锁）；
  十套集成 **755 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209 / 4235** 全 0 失败
  （仅可玩性 +1 路由锁）；`--headless --import` / `--quit` 退出 0、`ERROR` 0；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**；工作区干净、无临时探针。
- 本程提交：`9379cbf` feat: author chapter 4 big-map plan and graph skeleton
  （计划/夹具/测试/路由锁）；文档提交 `cddb2bf` docs: record the chapter 4 plan and
  graph skeleton pass（本状态文件、会话记录、ADR、记忆索引）。
- 本程未做：第 4 章真实大区世界/房间、`Ch4EventData`、权柄池、波次接线、
  Boss 4 机制/`boss_scene`/文案/测试、第 4 章大图验收、第 2/3/4 章可达性、
  待确认第 11–16 项、舞台母题/战斗密度/`mask_enemy`/`seat_husk` 独立数值、
  阿砚同行、新移动能力、NPC 立绘、MDS 插件、打包/导出/签名/安卓/触屏。

### 2026-11-05 · 第 50 程（第 4 章大地图可行性核查，只查不施工）

- 交接：第 49 程收尾 HEAD `38a3b05`，工作区干净，无会话在跑；第 2/3/4 章仍不可达，
  `CHAPTER_PLAN_PATHS[2]/[3]` 仍空；待确认第 11–16 项开放，本程不施工、不猜测。
- 任务 0 · 基线核验（HEAD `38a3b05`，Godot 4.7.stable.official.5b4e0cb0f）：
  `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0；单元 **10315 / 0**；
  十套集成 **754 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209 / 4235** 全 0 失败；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与交接一致，无漂移。
- 任务 1 · 第 4 章大地图可行性核查（只查不施工，结论见专节）：
  - 现有世界：9 房/17 门（7 right / 7 left / 3 door）、单矩形 1280×720、单层地面、
    `MDSChapterRoom(chapter_index=3)`；6 战斗 + 休整（商店/残碑/捷径）+ 书库
    （宝箱/残碑）+ Boss；区域 `Smiling Theater` 灰烬+光柱、`boss_background=blood_moon`。
  - 文本/语音：第 4 章 8 句开场、4 句章末、2 选项；`chapter_theater.ogg`、
    `ch4_intro/outro`、`boss_smiling_phase2/3` 均在；章末焚毁分支置 `_burned_final`。
  - Boss 4：HP 520 / 伤害 18 / 速度 92 / `boss_script=smiling` / 立绘
    `smiling_archivist.png` / `boss_voice=smiling`；`SmilingArchivist` 专属脚本与场景
    已有镜面弹幕（3 枚 ×0.7、280）+ 基类纸页波/墨雨/改写；无 `boss_scene` 键、
    无入场/阶段文案、无 `test_ch4_boss`；剧情圣经的删除词/复制武器/舞台机关未实现。
  - 敌人/波次：`ROOM_WAVES[3]` 6 波 + `CampaignData.rooms[3]` 6 组首发；实际 8 种
    spawn id 全部有专属精灵、全部在 `ENEMY_ART`、白 tint、**回退表命中 0**；
    `mask_enemy`/`seat_husk` 是美术变体（场景/数据复用 `hanging_scribe`/
    `collapse_husk`）；`echo_enemy` 数据 id 仍为 `amnesiac_echo`。
  - 计划/内容：`chapter_4_demo.tres` 不存在、`CHAPTER_PLAN_PATHS[3]` 空、无
    `ch4_bigmap` 目录、无 `Ch4EventData`、无权柄池、Boss 文案静默；清房目标 6 /
    HUD 分母 7 / 坠落 850；地图标题「笑面剧场地图」；第 4 章为最后一章，
    `_complete_chapter` 已走 `_finish(true)` 结束战役。
  - 结论：大区管线章节无关、可直接承载；缺口在计划/大区世界/内容数据/Boss 4 机制/
    验收套件；施工顺序与前置依赖见专节。第 4 章可达性仍须单独拍板且不能早于第 2/3 章。
- 任务 2 · 第 4 章美术素材核查（用户 2026-11-04 事实更正遗留项，只读不改）：
  - 舞台：`smiling_theater.png` 1536×864 RGB 绘画，已接入 `MDSChapterRoom`
    `BACKGROUNDS[3]` + `TheaterBackdrop(generated_art=true)`；后者只叠加聚光灯/
    光斑/浮尘，程序化帷幕/观众席分支不执行；概念源
    `assets/concept/environments/smiling_theater_source.png` 仅参考。
  - Boss：`smiling_archivist.png` 256×256 RGBA，alpha 0/255、四角透明、底行对齐、
    无压缩/无 mipmap；由 `CampaignData.boss_texture` 接线。
  - 敌人：`mask_enemy.png`/`seat_husk.png` 96×96 RGBA 同样合规；第 4 章 8 种敌人
    全部专属精灵、无回退；没有缺失或未接线的第 4 章美术素材。
  - 道具/瓦片：共享第 1 章像素道具与 `ch1_tiles`，与第 2/3 章大图一致；
    没有第 4 章专属 tileset，属既定路线而非缺美术。
  - 音频：`chapter_theater.ogg`、`ch4_intro/outro.ogg`、`boss_smiling_phase2/3.ogg`
    均在并已接线。
  - 文档：README/GDD 的旧「程序化绘制、待替换插画」已在第 7 程更正，本次复核与
    当前描述一致；结论已记入本状态文件专节，后续按「美术已就绪」规划。
- 任务 3 · 记录：新增 `docs/memory/sessions/2026-11-05-chapter4-bigmap-audit.md`；
  本状态文件新增「第 4 章大地图可行性核查（第 50 程）」专节并更新项目现状/
  未完成表第 8/10/13 项/下一程；`docs/memory/MEMORY.md` 补索引与第 50 程记录。
  本程只改文档，未新增测试与产品代码；未创建临时探针，无残留。
- 本程提交：`821ed0c` docs: audit chapter 4 big-map feasibility（本状态文件、
  会话记录、记忆索引）。
- 本程未做：第 4 章计划/图骨架/大区世界/内容数据/Boss 机制/验收；第 2/3/4 章可达性；
  待确认第 11–16 项；阿砚同行；新移动能力；NPC 立绘；MDS 插件；打包/导出/签名/
  安卓/触屏。

### 2026-11-05 · 第 49 程（第 3 章大图门视觉专项与敌人美术核查）

- 交接：第 48 程收尾 HEAD `28ee4c1`，工作区干净，无会话在跑；第 2/3 章仍不可达，
  `CHAPTER_PLAN_PATHS[2]` 仍空；待确认第 11–16 项开放，本程不施工、不猜测。
- 任务 0 · 基线核验（HEAD `28ee4c1`，Godot 4.7.stable.official.5b4e0cb0f）：
  `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0；单元 **10207 / 0**；
  十套集成 **754 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209 / 3424** 全 0 失败；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与交接一致，无漂移。
- 任务 1 · 第 3 章大图门视觉专项（只做表现层与测试，未改门逻辑）：
  - 核查：第 37 程的 `GateVisual` 由 `MDSBigRoom._add_gate_visuals()` 通用挂载
    （自动门 + 作者门）；第 41 程 9 个第 3 章场景全部是 `MDSBigRoom`、`auto_gates`
    全开，22 扇门（20 有向 + 2 仅到达）已被通用管线自动覆盖，**未另起视觉实现**。
    22 扇构成：left/right/top/bot 各 5 + 中置 `door` 2；仅到达门 =
    `ch3_entry/shortcut_arrival`（door）与 `ch3_boss/left1`（left）。
  - 逐门断言（扩展 `tests/integration_ch3_bigmap.gd`）：每门有 `GateVisual`；
    `marker.position == Vector2.ZERO`（视觉不移动门）；side 与世界文件一致；
    left/right 门向房间内展开、门底 = 门下方真实地面/台阶面（`floor_offset` 现算），
    door 中置，top/bot 舱口贴天花板/地面且不越界；标题 x/y 按 side 规则并被夹进房间；
    有向门 `arrival=false`（绘制路径画朝向箭头）+「前往 <目标区名>」，
    仅到达门 `arrival=true`（「来路」、无箭头）；汇总 22 = 20 有向 + 2 到达、
    side 5/5/5/5/2（计数按房间覆盖写，重访不累加）。
  - 真实缺陷（就地修复）：`ch3_well/top1` 与 `ch2_well/top1`（门位 x = 80）的
    天花板舱口标题按门中心居中，200 px 标签框左边缘 x = −20，越出房间左边界 20 px。
    根因是第 37 程的「边上标题内收」只实现了 left/right，top/bot 未夹取。
    修复：`GateVisual` 新增可选 `caption_area`（marker 局部坐标、按标题尺寸内缩的
    房间矩形），`MDSBigRoom` 为每扇门传入 `room_bounds - 标题尺寸`，
    `_caption_x()`/`_caption_y()` 夹取；空值保持原 side 规则，左右门位置不变。
    回归：`test_big_room` +2（舱口内收 x/y）；第 3 章集成逐门断言标题矩形必须被
    `room_bounds.encloses()`（修复前 `ch3_well/top1` 会失败）。
  - 不变项：纯 `Node2D`（`z=-1`）、无碰撞/信号/输入；门位/模式/单向语义
    （`ch3_elite/right1` 不可返回）/`requires`/`MDSGateBarrier`（`ch3_hub/shortcut`
    默认封闭）/过渡目标一字未改；第 1 章无 `GateVisual`；第 2 章 22 扇门断言
    2209/0 无回归；第 3 章仍不可达。
- 任务 2 · 第 3 章敌人美术核查（只核查/接线锁定，不新绘不拼凑）：
  - 以 `ROOM_WAVES[2]` 六波实际引用为准，共 8 种：`mirror_sniper`（第 3 章专属）、
    沿用第 1 章的 `hanging_scribe`/`echo_enemy`/`typo_beast`/`page_swarm` —— 5 种都有
    专属 PNG、已在 `ENEMY_ART`、不在回退表、实际白 tint；沿用第 2 章的
    `rust_whisperer`（→`scribe_bug`）/`lung_moth`（→`hanging_scribe`）/
    `collapse_husk`（→`blank_man`）—— 无专属美术，继续第 1 章回退并染
    `ENEMY_FALLBACK_TINT`（`#c8e1cd`）；缺失清单记录在案，`assets/concept/enemies/`
    也无这些原图，按任务单不新绘。
  - `echo_enemy` 是刷怪/场景 id，其数据资源沿用旧名 `amnesiac_echo.tres`
    （`id = amnesiac_echo`）；美术按刷怪 id 接线，测试锁别名。
  - 测试：`tests/test_enemy_art.gd` 94 → **200 断言**（第 3 章 8 敌逐一核对场景/
    数据/唯一美术来源；5 接线白 tint、3 缺失回退第 1 章美术 + 回退 tint；
    审计集合由 `ROOM_WAVES[2]` 现算，波次改动引入未审计敌人会失败）。
    `tests/integration_ch3_bigmap.gd` 在真实遭遇中断言 `ch3_branch_a/Arena` 的
    `mirror_sniper`/`hanging_scribe` 用专属图 + 白 tint、`Arena2` 的
    `rust_whisperer`/`lung_moth` 用回退图 + `#c8e1cd`。
  - 地图标题复核：第 38 程的 `CampaignData.chapter(i)["region"]` 派生规则未动，
    第 3 章集成既有断言「无光海地图」复跑成立；第 1 章「档案馆地图」一字未改。
  - 不变项：未新增/修改任何敌人贴图或场景美术；第 1/2 章敌人美术与波次未改；
    第 3 章仍不可达。
- 任务 3 · 收尾验证：
  - 单元 **10315 / 0**（第 48 程 10207，+108：敌人美术 94 → 200 即 +106、
    `test_big_room` 111 → 113 即 +2）；第 3 章大图集成 **4235 / 0**
    （3424 → +811：逐门 visual/落面/标题内缩/箭头语义 + 真实遭遇敌人美术）；
    第 2 章大图集成 **2209 / 0**（共享门视觉改动无回归）；其余八套集成
    **754 / 102 / 613 / 207 / 113 / 59 / 391 / 45** 与基线一致、全 0 失败。
    `--headless --import` / `--quit` 退出 0、`ERROR` 0；退出泄漏 **10/10 clean**；
    demo 像素资产 **36 / 0**。
  - 记录：新增 `docs/memory/sessions/2026-11-05-chapter3-gate-visuals-enemy-art.md`，
    更新 `docs/memory/MEMORY.md` 与大区门视觉 ADR（「补充（第 49 程）」）。
    临时探针已全部清理，无残留。
- 本程提交：`2725e81` fix: keep big-map gate captions inside the room
  （`GateVisual.caption_area` + `MDSBigRoom` 传入 + `test_big_room` 舱口内收 2 条）；
  `c631a3d` test: audit chapter 3 gate visuals and enemy art（第 3 章集成逐门/落面/
  标题/敌人美术断言、`test_enemy_art` 94 → 200）；`a60080f` docs: record the
  chapter 3 gate visuals and enemy art pass（本状态文件、会话记录、记忆索引与 ADR）。
- 本程未做：第 3 章可达性/接入 `game.gd`；待确认第 11–16 项；3 个缺失敌人的
  专属美术；阿砚同行；新移动能力；NPC 立绘；MDS 插件；打包/导出/签名/安卓/触屏。

### 2026-11-05 · 第 48 程（第 3 章大地图系统验收，接力第 47 程）

- 交接：第 47 程（brief49）因 Magpie 网关中断夭折，无提交，只留下未跟踪的
  `tests/integration_ch3_bigmap.gd`（1481 行）；本程开工时网关复查 HTTP 200
  （DeepSeek V4.1 Flash 可用）。HEAD `940f505`，工作区仅该未跟踪文件。
- 任务 0 · 基线核验（HEAD `940f505`，Godot 4.7.stable.official.5b4e0cb0f）：
  `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0；单元 **10207 / 0**；
  九套集成 **754 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209** 全 0 失败；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与交接一致，无漂移。
- 任务 1 · 第 3 章大地图系统验收（只做验收与验收脚本修正，未改产品代码）：
  - 核查：第 47 程脚本按 brief49 第 2 节口径覆盖第 36 程 D 节 1–10 项与第 3 章
    专属断言，挂接手法与第 45–46 程一致（真实主场景 + 第 3 章计划/大区世界临时
    挂载，测毕恢复旧世界）；逐项核对第 40–46 程的计划/世界/事件/波次/Boss 3/
    章末收口，验收对象一致。缺口语义就地补齐，未另起框架。
  - 验收结果：`tests/integration_ch3_bigmap.gd` **3424 断言 / 0 失败**，连续两次
    运行一致。覆盖：计划图入口 BFS 九区全可达；世界 22 门 = 20 连通 + 2 到达
    全部实走，2 扇单向语义正确（`elite_boss` 进 Boss 不可返回、
    `hub_shortcut_entry` 带 `requires` 默认封闭）；九区单矩形边界 = 计划尺寸、
    相机四边 = 世界边界；电梯/顶底门/单向落台/长椅检查点/坠落平面；门过渡无
    叠加暂停/剧情/奖励/地图/权柄/商店；3 宝箱 + 2 残碑按节点 id 一次性；
    `ch3_branch_a` 两场遭遇逐场锁门/清怪/奖励，清房到 7（HUD 8）；隐藏书库首次
    发现与地图揭示；捷径屏障跨存档保持（仅测试注入 `ch3_shortcut`，未新增游戏内
    授予）；世界级存档恢复到正确房间/坐标；`LastReader` 生成/战役数值/立绘/
    入场阶段文案/权柄池/章末停章；地图标题「无光海地图」、`lightless_sea.png`
    平铺（线性过滤）、雾 + 雨、`deep_water` Boss 背景、`room_darkness=false`、
    无 sea 层（第 14/15 项只记录现状）。
  - 性能基线（`fade_time=0` 原始构建，两次运行区间）：普通区首次 6.0–9.2 ms、
    热 6.1–7.7 ms；Boss 区冷 41.1–41.4 ms / 热 24.0–24.4 ms；精英 7.3 ms；
    关动态背景 5.6–5.8 ms、关天气 19.8–20.3 ms、不生成 Boss 12.5–12.8 ms；
    真实门过渡 228–234 ms。headless 无垂直同步/帧率上限，单帧耗时无代表性；
    大区按「门 + 0.22 秒淡入」、`seamless_rooms=false`，故记录门过渡墙钟。
  - 真实缺陷：**未发现产品行为缺陷**。首次跑通过程中的失败全部在验收脚本自身，
    已就地修正并补断言：① HUD 目标断言误用章节表目标（房间加载后由房间类型
    覆盖，入口房为「休整，或继续前进」）；② 性能段在 0.35 秒门冷却内直接
    `use()`，门过渡未启动（改为等 0.45 秒）；③「不生成 Boss」测量用
    `_finished`/`_boss_defeated` 抑制延迟后续流程，`call_deferred` 在标志复位后
    才跑，打开权柄页并暂停场景树，卡住下一次淡入（改为保持
    `_boss_aftermath_started` 守卫并先跑两帧；仅测试构造态，真实流程无此问题）；
    ④ `MDSWorld.get_transition()` 不暴露 `one_way`，改为读世界门数据并断言无
    反向转移。脚本连续两次 3424/0。
  - 不变项：未改任何 `scripts/`/`scenes/`/`resources/`；`CHAPTER_PLAN_PATHS[2]`
    仍空、旧第 3 章 9 房/17 门世界仍被 `game.gd` 使用、第 3 章仍不可达；第 2 章
    仍不可达；第 1/2/4 章计划/世界/流程未动；未新增 `ch3_shortcut` 授予、
    未实现视野压缩/sea 层、未改电梯速度/相机/HUD、未做门视觉、地图标题改动、
    敌人美术接线、阿砚同行、新移动能力、NPC 立绘、MDS 插件、导出/签名/安卓。
  - 记录：新增 `docs/memory/sessions/2026-11-05-chapter3-bigmap-acceptance.md`
    （逐项结论 + 性能基线 + 脚本修正根因），并更新 `docs/memory/MEMORY.md`。
    临时诊断已全部清理，无残留探针。
- 任务 2 · 验证（HEAD 见本程日志末尾）：
  - 新增第 3 章大图集成 **3424 / 0**（连续两次）；单元 **10207 / 0**；九套既有
    集成 **754 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209** 与基线一致、
    全 0 失败；`--headless --import` / `--quit` 退出 0、`ERROR` 0；退出泄漏
    **10/10 clean**；demo 像素资产 **36 / 0**。
- 本程提交：`f50eb60` test: accept the chapter 3 big map（新增
  `tests/integration_ch3_bigmap.gd` 与 `.uid`，1502 行，3424 断言）；`3001686`
  docs: record the chapter 3 big-map acceptance pass（本状态文件 + 会话记录 +
  记忆索引）。临时诊断已全部清理，收尾工作区干净。

### 2026-11-05 · 第 47 程（第 3 章大地图系统验收，夭折）

- 交接：第 46 程收尾 HEAD `940f505`，工作区干净，第 2/3 章均不可达。
- 本程未产生任何提交：`.supervisor/session49.log` 只有一行
  `[claude-code:unrecognized_model]`，模型调用不可用；监工在第 48 程开工前重启
  Magpie 网关并复查通过（HTTP 200，DeepSeek V4.1 Flash 可用）。
- 唯一产出是未跟踪的 `tests/integration_ch3_bigmap.gd`（1481 行，结构完整、正常
  收尾），按 brief49 第 2 节口径写成，未经运行验证；由第 48 程核查、补齐并跑通。
- 状态文件、会话记录均未更新，`SUPERVISOR_STATUS.md` 仍停在第 46 程。

### 2026-11-05 · 第 46 程（第 3 章章末收口）

- 交接：第 45 程收尾 HEAD `1ce61f8`，工作区干净，第 2/3 章均不可达；
  待确认第 11/12/13/14/15/16 项开放，本程不施工、不猜测。
- 任务 0 · 基线核验（HEAD `1ce61f8`，Godot 4.7.stable.official.5b4e0cb0f）：
  `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0；单元 **10207 / 0**；
  九套集成 **732 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209** 全 0 失败；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与交接一致，无漂移。
- 任务 1 · 第 3 章章末收口（章末流程与测试层，未产生可玩行为变化）：
  - 核查：`_complete_chapter` 原有分支为第 1 章（`_chapter == 0`）置
    `demo_cleared` 后 `_finish(true)`、第 2 章（`_chapter == 1`）`_finish(true)`
    （第 35 程收口）、其余 `_chapter + 1 < chapter_count()` 自动 `_start_chapter`
    否则 `_finish(true)`——第 3 章（`_chapter == 2`）此前自动进第 4 章。
    第 3 章章末文本/选项/语音齐全（`CampaignData.chapter(2)` 4 句 outro、
    两选项、`ch3_outro` 语音；`_apply_chapter_choice` 的 `lightless_sea`
    分支：选项 0 恢复 20 生命 / 选项 1 获得未拥有遗物），**未新编剧情文本**。
    续玩/重载逻辑章节无关：`_on_mds_room_loaded` 的 Boss 区在 `_boss_defeated`
    时调用 `_resume_boss_aftermath`（不二次生成 Boss、无权柄时补授予、随后
    `_complete_chapter`），`_start_mds_chapter` 从 run save 恢复 `_boss_defeated`。
  - 改动：`scripts/game.gd` 的 `_complete_chapter` 在既有第 2 章分支之后新增
    `_chapter == 2` 分支，章末选择后调用现有 `_finish(true)` 停章，不再自动
    进入未实现的第 4 章；第 1 章分支、第 2 章分支与第 4 章分支（`_chapter + 1
    < chapter_count()` / `else`）未改，只更新第 2 章分支上方已过时的注释。
    章末选择界面/结局记录/续玩行为沿用第 35 程口径，不另起流程。
  - 校验：`tests/integration_playability.gd` 的 `_test_ch3_bigmap_boss` 扩为
    完整章末链路（第 41 程大区世界 + 第 3 章计划临时挂到真实主场景，
    `ch3_boss` 起始）：真实 Boss 上击败 `LastReader` → 权柄二选一（基础池
    续命/改写，按钮数 = `build_pool` 池大小）→ 第 3 章 outro → 章末选择 →
    `_finish(true)`；断言 `_chapter` 仍 2、`_finished`、结局屏可见、
    `_boss_defeated` 已记录，测试后 `_restore_chapter_world` 恢复旧第 3 章世界。
    同一函数开头锁定不变项：`CHAPTER_PLAN_PATHS[2]/[3]` 仍空、
    `MDS_WORLD_FILES[2]` 仍指旧 `chapter_3.mdsworld.json`、清房目标 7、
    7 个遭遇节点、`ch3_branch_a/Arena` 波次表、权柄基础池、`boss_scene`
    指向 `last_reader.tscn`。`_test_mds_chapter` 的旧线性世界章末断言由
    「自动进第 4 章」改为「停在第 3 章」（`_finished` / `_chapter == 2` /
    结局屏）；Boss 已死续玩沿用既有「重载不二次生成」断言，本程只把重载前
    `paused` 复位（结局屏会暂停 SceneTree）。
  - 不变项：第 3 章计划波次表/权柄池/事件数据/Boss 3 机制与 `boss_scene`
    不变（`test_ch3_plan` / `test_ch3_content` / `test_ch3_boss` /
    `test_ch3_world` 锁定）；旧第 3 章 9 房 / 17 门 / 世界文件仍在；第 1 章
    Boss/流程/9 房间/6 波次/事件/清房目标 6 与章末流程不变；第 2 章计划/
    波次表/大区世界/事件触发/权柄池/Boss 2 机制与章末收口不变；第 4 章无
    内容改动。`CHAPTER_PLAN_PATHS[2]` 仍空、第 3 章仍不可达、计划仍未接入
    `game.gd`。
  - 未做（按任务单）：第 3 章大图验收套件、第 3 章门视觉、第 3 章地图标题/
    敌人美术核查、第 3 章可达性开放、阿砚同行、新移动能力、NPC 立绘、MDS 插件、
    敌人/场景美术、打包/导出/签名/安卓/触屏；待确认第 11/12/13/14/15/16 项
    未施工、未猜测。
- 任务 2 · 验证（HEAD 见本程日志末尾）：
  - 单元 **10207 / 0**（与新断言前持平，本程新断言全在集成层）；
    可玩性集成 **754 / 0**（732 + 22：章末链路 11、旧世界停章 +3/−1、
    路线不变项 9）；其余八套集成 **102 / 613 / 207 / 113 / 59 / 391 / 45 /
    2209** 与基线一致、全 0 失败；`--headless --import` / `--quit` 退出 0、
    `ERROR` 0；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。
- 本程提交：`8d721e5` feat: stop chapter 3 at its own boundary（`_complete_chapter`
  新增 `_chapter == 2` 停章分支）；`bfa23ff` test: cover the chapter 3 ending
  closure（真实大区世界章末链路 11 条、旧世界停章 +3/−1、路线不变项 9 条）；
  `dacdf89` docs: record the chapter 3 ending pass（状态文件、session、ADR、
  记忆索引，并在第 2 章 ADR 标注其「第 3/4 章自动续章」只对第 4 章成立）。
  临时探针未创建，收尾工作区干净。

### 2026-11-05 · 第 45 程（第 3 章 Boss 3「最后的读者」机制与 `boss_scene` 路由）

- 交接：第 44 程收尾 HEAD `ae22f96`，工作区干净，第 2/3 章均不可达；
  待确认第 11/12/13/14/15/16 项开放，本程不施工、不猜测。
- 任务 0 · 基线核验（HEAD `ae22f96`，Godot 4.7.stable.official.5b4e0cb0f）：
  `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0；单元 **10113 / 0**；
  九套集成 **705 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209** 全 0 失败；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与交接基线一致，无漂移。
- 任务 1 · 第 3 章 Boss 3 机制与计划路由（机制/测试层，未产生可玩行为变化）：
  - 核查：第 39 程记录属实——`scripts/bosses/last_reader.gd`
    （`LastReader extends InkArchivist`）与 `scenes/bosses/last_reader.tscn`
    已存在，已有镜面三连弹与「读页」封印；战役表 HP 380 / 伤害 15 / 速度 78、
    立绘 `last_reader.png`、`boss_script == "reader"`，**没有** `boss_scene`；
    第 3 章计划此前也没有 `boss_scene`，`_spawn_boss` 靠 `boss_script` 兜底。
  - 机制（依据剧情圣经第三章「镜面弹幕和『读页』封印昌子的短语」与第 42 程
    章节文案，未新增剧情事实）：镜面弹幕按阶段 **3 / 5 / 7** 枚、张角
    **0.28 / 0.40 / 0.52 rad**、每枚 **0.7×** 攻击力、速度 **270**；读页阶段 2
    起每第 3 次攻击，`InkWarning`（**0.8×** 攻击力）标记玩家位置并封印一个
    短语槽 **3.0 s**（槽位随攻击计数交替），阶段 3 每 4 拍轮到一次；阶段 3
    空白页 **11 s** 周期——展开 **4.5 s**（承伤 **×1.5**）、合书 **6.5 s**
    （承伤 **×0.6**），进入阶段 3 先展开，sprite tint 提示窗口；阶段 1–2
    承伤 **×1.0**；阶段 3 四拍改写 / 读页 / 镜面 / 墨雨。以上全部为**暂定
    口径**，由 `tests/test_ch3_boss.gd` 锁定，后续试玩校准须同步改测试并登记。
  - 路由：`resources/chapters/chapter_3_demo.tres` 的 `boss_scene` 指向
    `res://scenes/bosses/last_reader.tscn`；`_spawn_boss` 优先级不变（战役表
    `boss_scene` → 计划 `boss_scene` → `smiling` → `reader` 兜底），第 1/2 章
    Boss 与通用生成/血条/阶段横幅/权柄/outro/结束流程未改。
  - 大图生成高度：第 35 程 `_enemy_spawn_y()` 已对任意 `big_map` 计划返回
    `-ENEMY_FOOT_Y - 2`（-18 px），第 3 章计划挂上后自动生效；本程不改函数，
    只补断言（计划 → -18、无计划 → 旧 250 px）与真实大区集成断言（生成在
    `Arena` 地面线之上）。
- 任务 2 · 校验（测试层，就近扩展现有套件，未另起重复套件）：
  - `tests/test_ch3_boss.gd`（新增，**90** 断言）：计划路由/场景类型、战役
    数值/立绘/`boss_script` 不变、三阶段镜面数量/张角/伤害、读页槽位/时长/
    预警、阶段轮换、空白页承伤窗口与信号、生成高度、死亡关闭空白页、
    第 1/2 章隔离与 `CHAPTER_PLAN_PATHS[2]/[3]` 仍空。
  - `tests/integration_playability.gd`（705 → **732**，+27）：新增
    `_test_ch3_bigmap_boss`，把第 41 程大区世界与第 3 章计划临时挂到真实主场景
    （`ch3_boss` 起始），走真实 `room_loaded` 生成：`LastReader` 由计划路由、
    数值来自战役表、生成在 `Arena` 地面线之上、阶段 2 文案用第 3 章选句键、
    空白页窗口在真实 Boss 上开合、继承的纸页波/墨雨在真实树内生成、Boss 击败
    后重载不再二次生成；测试后 `_restore_chapter_world` 恢复旧世界。
  - 就地更新 `test_ch3_plan`（726 → **728**）、`test_ch3_content`（614 → **615**）、
    `test_ch3_world`（764 → **765**）的「无 `boss_scene`」期望，其余不变项断言
    原样保留。
- 不变项：`CHAPTER_PLAN_PATHS[2]` 仍空、`game.gd` 章节路由与章末流程未改
  （第 3 章末仍自动进第 4 章）；旧第 3 章 9 房 / 17 门 / 世界文件仍在；第 3 章
  计划波次表/权柄池/事件数据/大区世界与场景未改；第 1 章 9 房间 / 6 波次 /
  事件 / 清房目标 6 不变；第 2 章计划/波次/大区世界/事件触发/权柄池/Boss 2
  机制与文案不变；`InkArchivist` 基类与 `LungBellGuardian` 未改。
- 验证（改动后）：单元 **10207 / 0**（基线 10113 +94：`test_ch3_boss` +90、
  `test_ch3_plan` +2、`test_ch3_content` +1、`test_ch3_world` +1）；九套集成
  **732** / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209 全 0 失败、各日志
  `ERROR` 0；`--import` / `--quit` 退出 0、`ERROR` 0；退出泄漏 **10/10 clean**；
  demo 像素资产 **36 / 0**。第 1 章无回归，第 2 章计划/世界/事件触发/集成无
  回归，第 2/3 章仍不可达。
- 待确认项：第 14（视野压缩，`room_darkness = false`）、15（无 sea 层、未改
  `LivingBackdrop`、未新绘背景）、16（未新增 `ch3_shortcut` 授予）全部留空
  未施工；第 11/12/13 项未碰；章末自动进第 4 章的缺口未改。未新增待拍板项。
- 未做（按任务单）：第 3 章接入 `game.gd`/可达性/章节路由/章末流程、
  第 3 章大图验收套件、第 3 章门视觉专项打磨、阿砚同行、新移动能力、NPC 立绘、
  MDS 插件本体、敌人/场景美术、打包/导出/安装器/签名/安卓/触屏。
- 本程提交：`bea43fa` feat: give the last reader its chapter 3 boss mechanics
  （Boss 3 机制、计划 `boss_scene` 路由、就地更新三个既有套件的「无
  `boss_scene`」期望）；`9b99bda` test: cover the chapter 3 boss mechanics and
  routing（`test_ch3_boss` 90 断言、可玩性集成 +27）；`1cd5f3f` docs: record
  the chapter 3 boss 3 pass（状态文件、session、ADR、记忆索引）。临时探针未
  创建，收尾工作区干净。

### 2026-11-05 · 第 44 程（第 3 章内容数据层第 3 步：事件区真实自动触发）

- 交接：第 43 程收尾 HEAD `cecaffa`，工作区干净，第 2/3 章均不可达；
  待确认第 11/12/13/14/15/16 项开放，本程不施工、不猜测。
- 任务 0 · 基线核验（HEAD `cecaffa`，Godot 4.7.stable.official.5b4e0cb0f）：
  `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0；单元 **10100 / 0**；
  九套集成 **671 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209** 全 0 失败；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与交接基线一致，无漂移。
- 任务 1 · 第 3 章事件区真实自动触发（触发机制与测试层，未产生可玩行为变化）：
  - 结论：第 34 程的 `_on_mds_room_loaded` 区域级大图事件分支本身是章节无关的
    判定（`big_map` + `type == "event"` + `_event_data(room_id)` 非空），第 42 程
    已把 `_event_data` 的路由扩到第 3 章（`Ch3EventData`）。因此 `ch3_event`
    无需新增任何触发代码：计划与大区世界挂上后，进入区域即自动打开第 3 章
    事件页，键 = 计划事件节点 id `ch3_event/event`。本程未新增第 3 章专属
    触发路径，只给该分支补了一句「章节无关」的注释说明（无行为改动）。
  - 效果与结算完全沿用既有代码：文案/选项由 `Ch3EventData.pick(run_seed,
    ch3_event/event)` 确定性轮换、不耗 run RNG；读 → 污染 +8（经难度/抗性倍率、
    上限 100）+ 解明一个残页词 / 兜底残页 +6；拿 → 残页 +12；结算写
    `cleared_encounters["ch3_event/event"]`，计入清房目标 7（HUD 分母 8）。
  - 未接入 `game.gd`：`CHAPTER_PLAN_PATHS[2]` 仍空、章节路由与章末流程未改、
    旧第 3 章 9 房世界仍被游戏使用；第 3 章仍未开放可达性。
- 任务 2 · 校验（测试层，就近扩展现有套件，未另起重复套件）：
  - `tests/test_ch3_content.gd`（601 → **614**，+13）：新增
    `_test_event_trigger_inputs`——把第 3 章计划挂到独立 `game.gd` 实例，验证
    区域触发判定的三项输入（`plan.big_map`、`ch3_event` 的 `type == "event"`、
    `_event_data("ch3_event")` 非空）、触发键 = 计划事件节点 id、事件节点无普通
    波、清房目标 7 / HUD 分母 8、`RoomProgress.is_recorded` 用同一键的一次性
    语义；不改章节路由。
  - `tests/integration_playability.gd`（671 → **705**，+34）：新增
    `_test_ch3_bigmap_event_trigger`，把第 41 程的 `chapter_3_bigmap_world.tscn`
    与第 3 章计划临时挂到真实主场景（与 `_start_mds_chapter` 同构），从
    `ch3_event` 启动并走真实 `room_loaded` 触发：进入即开第 3 章事件页、文案/
    标题/两选项 = `Ch3EventData.pick(run_seed, ch3_event/event)`、开页与「拿」
    不耗 run RNG（「读」解明残页词时沿用既有 run RNG）；拿 → 残页 +12 且提示
    文案正确、结算键 / 清房计数 +1、run save
    落盘同一键；重载不重开、不暂停、不重复计数/奖励；回退结算后重进再验读 →
    污染 +8（含倍率与上限）+ 解明一残页词或兜底 +6。测试后调用
    `_restore_chapter_world` 重新进入第 3 章，让既有旧世界结构巡检照常跑；
    `CHAPTER_PLAN_PATHS[2]`、游戏路由与旧世界均未改。
  - 不变项仍由既有断言锁定：`CHAPTER_PLAN_PATHS[2]/[3]` 仍空、旧第 3 章
    9 房/17 门/世界文件仍在、第 3 章大区世界与场景未改、第 3 章计划波次表与
    权柄池不变、第 1 章 9 房间/6 波次/事件/清房目标 6 不变、第 2 章计划/波次表/
    大区世界/事件数据/事件触发/权柄池/Boss 文案不变。
- 验证（改动后）：单元 **10113 / 0**（基线 10100 +13，全部来自
  `test_ch3_content`）；九套集成 **705** / 102 / 613 / 207 / 113 / 59 / 391 /
  45 / 2209 全 0 失败、各日志 `ERROR` 0；`--import` / `--quit` 退出 0、`ERROR` 0；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。第 1 章无回归，第 2 章
  计划/世界/事件触发/集成无回归，第 2/3 章仍不可达。
- 待确认项：第 14（视野压缩，`room_darkness = false`）、15（无 sea 层、未改
  `LivingBackdrop`、未新绘背景）、16（未新增 `ch3_shortcut` 授予）全部留空
  未施工；第 11/12/13 项未碰；章末自动进第 4 章的缺口未改。未新增待拍板项。
- 未做（按任务单）：第 3 章接入 `game.gd`/可达性/章节路由/章末流程、Boss 3
  机制/`boss_scene`/专属场景、第 3 章大图验收套件、第 3 章门视觉专项打磨、
  阿砚同行、新移动能力、NPC 立绘、MDS 插件本体、敌人/场景美术、打包/导出/
  安装器/签名/安卓/触屏。
- 本程提交：`babd537` docs: note the big-map event trigger is chapter-agnostic
  （`game.gd` 注释：分支章节无关、可达性仍由计划槽决定）；`1203ed9` test: cover
  the chapter 3 event region trigger（`test_ch3_content` +13、可玩性集成 +34）；
  `631a930` docs: record the chapter 3 event trigger（状态文件、session、记忆
  索引）；`47b9a53` docs: keep the chapter 3 trigger RNG wording exact（选句与
  「拿」不耗 RNG、「读」解词沿用既有 RNG 的措辞校正）。临时探针未创建，收尾
  工作区干净。

### 2026-11-05 · 第 43 程（第 3 章内容数据层第 2 步：波次接线）

- 交接：第 42 程收尾 HEAD `4bdeb28`，工作区干净，第 2/3 章均不可达；
  待确认第 11/12/13/14/15/16 项开放，本程不施工、不猜测。
- 任务 0 · 基线核验（HEAD `4bdeb28`，Godot 4.7.stable.official.5b4e0cb0f）：
  `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0；单元 **10084 / 0**；
  九套集成 **671 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209** 全 0 失败；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与交接基线一致，无漂移。
- 任务 1 · 第 3 章波次接线（数据层与测试层，未产生可玩行为变化）：
  - `resources/chapters/chapter_3_demo.tres`：4 个战斗区补 `wave` 字典，键 =
    6 个战斗遭遇节点 id（`ch3_branch_a/Arena`、`ch3_branch_a/Arena2`、
    `ch3_branch_b/Arena`、`ch3_well/Arena`、`ch3_well/Arena2`、
    `ch3_elite/Arena`），值按计划顺序逐字复用 `ROOM_WAVES[2]` 六波；未新增、
    未修改波次内容。事件节点 `ch3_event/event` 无波、`ch3_boss` 不占普通波次、
    清房目标仍 7。
  - `content_pending` 处置：该标志第 40 程只承载「推迟波次表校验」；波次接线
    完成后按 ADR 约定改回 `false`，`validate()` 恢复校验波次表（区域/节点 id/
    门图校验不变）。标志本身保留在 `ChapterPlanData`（默认 `false`、向后兼容）；
    图夹具 `tests/fixtures/big_room/ch3_graph.mdsworld.json` 顶层的
    `content_pending: true` 是夹具元数据（不是该字段），本程未改，测试仍锁定。
  - 仅更新 `chapter_plan_data.gd` 中 `content_pending` 的文档注释（不再以第 3 章
    「波次待补」为例）；无行为改动。`game.gd`、章节路由、章末流程、第 1/2 章
    计划与波次、第 3 章大区世界/场景均未改。
- 任务 2 · 校验（测试层，就近扩展现有套件，未另起重复套件）：
  - `tests/test_ch3_content.gd`（570 → 601）：波次段改为接线校验——6 个 `wave`
    键恰好等于 6 个战斗遭遇节点 id、每键取值 == `ROOM_WAVES[2]` 对应波原文、
    键锚定本区且唯一、事件节点/事件区/Boss 区无波、`validate_waves()` 干净、
    `content_pending = false`；新增 `_test_runtime_wave_lookup`（12 断言）：把
    第 3 章计划挂到独立 `game.gd` 实例，经 `_plan_wave()` 按节点 id 读回六波并
    验证事件/Boss/未知节点为空（证明第 33 程通用大图分支可直接取用，但不把
    计划接入 `game.gd`、不改章节路由）。
  - `tests/test_ch3_plan.gd`（734 → 726）：`_test_pending_content` 改为
    `_test_wave_wiring`，锁 6 个波次键、逐遭遇非空、事件/Boss 无波、计划校验
    干净；`content_pending` 的局部性改为「副本删波 + 标志开 → `validate()` 干净；
    标志关 → 报六条缺波次」，保留第 40 程的关口。
  - `tests/test_ch3_world.gd`（771 → 764）：计划侧期望同步为 `content_pending
    = false`、`validate_waves()` 干净、共 6 个波次键；世界/场景/门/电梯断言不变。
  - 不变项仍由既有断言锁定：`CHAPTER_PLAN_PATHS[2]/[3]` 仍空、旧第 3 章
    9 房/17 门/世界文件仍在、第 3 章大区世界与场景未改、第 1 章 9 房间/6 波次/
    事件/清房目标 6、第 2 章计划/波次表/大区世界/事件数据/权柄池/Boss 文案不变。
- 验证（改动后）：单元 **10100 / 0**（+16 = `test_ch3_content` +31、
  `test_ch3_plan` −8、`test_ch3_world` −7）；九套集成
  **671 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209** 全 0 失败、各日志
  `ERROR` 0；`--import` / `--quit` 退出 0、`ERROR` 0；退出泄漏 **10/10 clean**；
  demo 像素资产 **36 / 0**。第 1 章无回归，第 2 章计划/世界/集成无回归，
  第 2/3 章仍不可达。
- 待确认项：第 14（视野压缩，`room_darkness = false`）、15（无 sea 层、未改
  `LivingBackdrop`、未新绘背景）、16（未新增 `ch3_shortcut` 授予）全部留空
  未施工；第 11/12/13 项未碰；章末自动进第 4 章的缺口未改。未新增待拍板项。
- 未做（按任务单）：第 3 章接入 `game.gd`/可达性/章节路由/章末流程、事件区
  真实自动触发、Boss 3 机制/`boss_scene`/专属场景、第 3 章大图验收套件、
  第 3 章门视觉专项打磨、阿砚同行、新移动能力、NPC 立绘、MDS 插件本体、
  敌人/场景美术、打包/导出/安装器/签名/安卓/触屏。
- 本程提交：`0334602` feat: wire the chapter 3 waves into the plan（计划波次表、
  `content_pending` 清零与文档注释、`test_ch3_content`/`test_ch3_plan`/
  `test_ch3_world` 同步）；`f9daea5` docs: record the chapter 3 wave wiring
  （状态文件、session、记忆索引）。临时探针未创建，收尾工作区干净。

### 2026-11-05 · 第 42 程（第 3 章内容数据层第 1 步：事件 + 权柄池 + Boss 文案）

- 交接：第 41 程收尾 HEAD `64b9c93`，工作区干净，第 2/3 章均不可达；
  待确认第 11/12/13/14/15/16 项开放，本程不施工、不猜测。
- 任务 0 · 基线核验（HEAD `64b9c93`，Godot 4.7.stable.official.5b4e0cb0f）：
  `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0；单元 **9512 / 0**；
  九套集成交接基线 **671 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209**
  （其中 671 / 102 / 613 本机在改动前复测一致，其余六套沿用第 41 程收尾记录）；
  退出泄漏交接 **10/10 clean**；demo 像素资产 **36 / 0**。无基线漂移。
- 任务 1 · 第 3 章内容数据层第 1 步（只做数据层，未产生可玩行为变化）：
  - 新增 `scripts/data/ch3_event_data.gd`（`Ch3EventData`）：7 组无光海文案
    （倒影 / 盐页 / 小读者 / 镜面 / 海页 / 吊影 / 翻页），固定「读 / 拿」两项，
    效果复用第 32 程口径（读 → 污染 +8 + 解明一个残页词 / 兜底残页 +6；
    拿 → 残页 +12），常量与第 2 章一致；`pick` 按 seed + 事件节点 id
    `ch3_event/event` 轮换，不消耗 run RNG。
  - `game.gd` 的 `_event_data` 扩到第 3 章（第 1 章原键/原值、第 2 章
    `Ch2EventData`、第 4 章空均不变）；`_grant_chapter_authority` 已在第 32 程
    按计划 `authority_pool` 授予，本程只给 `chapter_3_demo.tres` 补
    `authority_pool = [续命, 改写]`（条件项仍由 `ContentLibrary` 追加）。
  - `BossEntranceData` 第 3 章 8 条入场文案、`BossPhaseData` 阶段 2/3 各 8 条；
    第 4 章仍静默；第 1 章选句键与第 2 章选句键/文案不变；Boss 3「最后的读者」
    数值（HP 380 / 伤害 15 / 速度 78）/ 立绘 / `boss_script = reader` 未改。
  - 未接入 `game.gd`、未改章节路由与章末流程；计划仍 `content_pending`、
    无 `wave` 表、无 `boss_scene`。
- 任务 2 · 校验（测试层）：新增 `tests/test_ch3_content.gd`（**570** 断言）
  覆盖事件确定性/效果类型/消息格式/RNG、四章 `_event_data` 路由、权柄基础池
  与条件边界/顺序、Boss 入场/阶段文案不回落第 1/2 章、Boss 3 数值/立绘未改、
  7 个遭遇节点唯一且锚定、6 场战斗 ↔ `ROOM_WAVES[2]` 六波顺序、事件节点无波、
  清房目标 7、计划仍无 `wave` 表（6 条缺波次错误），并锁不变项
  （`CHAPTER_PLAN_PATHS[2]/[3]` 仍空、旧第 3 章 9 房/17 门/世界文件仍在、
  第 1 章 9 房计划/6 波/事件/清房目标 6、第 2 章计划/大区世界/事件/权柄池/
  Boss 文案不变）。既有测试同步：`test_ch3_plan` 730 → 734（基础池断言）、
  `test_ch3_world` 771 不变、`test_ch2_content` 断言数不变、
  `test_boss_entrance_content` 74 → 72（静默章节收窄到第 4 章）、
  `integration_ch1_demo` 同一断言改期望（数量不变）。
- 验证（改动后）：单元 **10084 / 0**（基线 9512 + 570 + 4 − 2）；九套集成
  **671 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209** 全 0 失败、各日志
  `ERROR` 0；`--import`/`--quit` 退出 0、`ERROR` 0；退出泄漏 **10/10 clean**；
  demo 像素资产 **36 / 0**。第 1 章无回归，第 2 章计划/世界/集成无回归，
  第 2/3 章仍不可达。
- 待确认项：第 14（视野压缩，`room_darkness = false`）、15（无 sea 层、未改
  `LivingBackdrop`、未新绘背景）、16（未新增 `ch3_shortcut` 授予）全部留空
  未施工；第 11/12/13 项未碰；章末自动进第 4 章的缺口未改。未新增待拍板项。
- 未做（按任务单）：第 3 章接入 `game.gd`/可达性/章节路由/章末流程、波次
  接线（计划 `wave`）、事件区真实自动触发、Boss 3 机制/`boss_scene`/专属场景、
  第 3 章大图验收套件、第 3 章门视觉专项打磨、阿砚同行、新移动能力、NPC 立绘、
  MDS 插件本体、敌人/场景美术、打包/导出/安装器/签名/安卓/触屏。
- 本程提交：`dd68f54` feat: add the chapter 3 content data layer（`Ch3EventData`、
  计划权柄池、Boss 3 文案、章节事件路由、`test_ch3_content` 570 断言与既有测试
  同步）；`7d7c56a` docs: record the chapter 3 content data layer（状态文件、
  session、记忆索引与 ADR 更新）。临时探针 `tests/probe_free42.gd` 用完已
  删除，收尾工作区干净。

### 2026-11-05 · 第 41 程（第 3 章大地图施工第 2 步：真实大区世界，只做结构层）

- 交接：第 40 程收尾 HEAD `9f0fe84`，工作区干净，第 2/3 章均不可达；brief42/session42
  曾因 Magpie 网关不通启动失败（空日志留存），本程按 brief42 原任务完整执行。待确认
  第 11/12/13/14/15/16 项开放，本程不施工、不猜测。
- 任务 0 · 基线核验（HEAD `9f0fe84`，Godot 4.7.stable.official.5b4e0cb0f）：
  `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0；单元 **8739 / 0**；
  九套集成 **671 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209** 全 0 失败；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与交接逐项一致，无基线漂移。
- 任务 1 · 第 3 章真实大区世界与房间（只做结构层，未产生可玩行为变化）：
  - 9 个 `BigRoomData`（`resources/rooms/ch3_bigmap/*.tres`）：计划尺寸
    2560×1440 / 2560×2160（纵井）/ 3840×2160（精英、Boss）；地面贴底边
    （`H-16`，16 px 厚）、平台 80 px 阶梯链，`validate()` 全空；复用
    `ch1_tiles.tres`；背景用既有 `lightless_sea.png`（绘画图、非像素放大）、
    按区 `backdrop_modulate`、`motes` 氛围密度 0.5。
  - 9 个 `MDSBigRoom` 场景（`scenes/mds/ch3_bigmap/*.tscn`）：`fall_margin = 240`
    （metadata `fall_below_bounds = 240`）；内容节点严格按计划 id（`Arena`/
    `Arena2`/`Chest1`/`Stele1`/`Shop`/`Bench`/`Event`）；事件区作者
    `ch3_event/event`；Boss 区只放结构 `Arena`；`ch3_entry` 作者 `SpawnPoint`
    （`save_point`、(400,1328) = 台阶面 1344 − `FOOT_Y`）与惰性到达门
    `shortcut_arrival`。
  - 纵向/捷径骨架复用第 29 程管线：`branch_b`/`hub`/`vault` 各 1 电梯、
    `well` 1 电梯 + 3 单向落台、`elite` 1 电梯、枢纽长椅；电梯未写 `speed`，
    沿用 `MovingPlatform.speed` 管线默认 **80 px/s**（第 12 项只针对第 2 章，
    本程未给第 3 章定速度）。
  - 独立世界 `scenes/mds/chapter_3_bigmap.mdsworld.json` +
    `chapter_3_bigmap_world.tscn`：9 区单矩形、原点 32 px 对齐、
    `start_room = ch3_entry`；区域 `Lightless Sea` 雾 + 雨、
    `boss_background: deep_water`、无 `backdrop_image`；22 门 = 20 有向 +
    2 只到达；显式单向 `elite_boss` 与 `hub_shortcut_entry`
    （`requires = ["ch3_shortcut"]`，来源待第 16 项，屏障默认封闭）。
    世界 JSON 由第 40 程夹具镜像生成（逐区字段一致，仅加 `scene_path`）。
  - 旧第 3 章 9 小房间世界/场景原地保留、未改语义；新世界不被 `game.gd` 引用。
- 任务 2 · 校验（测试层）：新增 `tests/test_ch3_world.gd`（**771** 断言）
  交叉校验计划↔真实世界（逐区尺寸/内容 id/门/坠落/区域氛围/可达性/不重叠/
  电梯列/出生点/夹具镜像/不变项）；`tests/test_ch3_plan.gd` 728 → **730**
  （把第 40 程的「目录不存在」改为「目录存在且各 9 个文件」）。临时探针
  `tests/probe_ch3world41.gd` 用 `MDSWorldGame` 逐区加载确认 9 区 0 校验错误、
  22 门、1 个捷径屏障、背景覆盖、坠落 240、出生点正确，测后删除。
- 验证（改动后）：单元 **9512 / 0**（基线 8739 + 773）；九套集成
  **671 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209** 全 0 失败、各日志
  `ERROR` 0；`--import`/`--quit` 退出 0、`ERROR` 0；退出泄漏 **10/10 clean**；
  demo 像素资产 **36 / 0**。第 1 章无回归，第 2 章计划/世界/集成无回归，
  第 2/3 章仍不可达。
- 待确认项：第 14（视野压缩，`room_darkness = false`）、15（无 sea 层、未改
  `LivingBackdrop`、未新绘背景）、16（未新增 `ch3_shortcut` 授予）全部留空未施工；
  第 11/12/13 项未碰；章末自动进第 4 章的缺口未改。未新增待拍板项。
- 未做（按任务单）：第 3 章接入 `game.gd`/可达性/章节路由/章末流程、
  `Ch3EventData`、波次接线、权柄池、Boss 3 机制/`boss_scene`/文案、第 3 章大图
  验收套件、第 3 章门视觉专项打磨、阿砚同行、新移动能力、NPC 立绘、MDS 插件本体、
  敌人/场景美术、打包/导出/安装器/签名/安卓/触屏。
- 本程提交：`b86dff6` feat: build the chapter 3 big-map region world（9 个
  `BigRoomData`、9 个 `MDSBigRoom` 场景、独立世界 JSON/场景、世界测试、
  计划测试目录断言、夹具注释）、`662e0b4` test: lock the chapter 3 clear target
  and kept content（清房目标 7、第 1 章 6 波、第 2 章世界、旧第 3 章 6 波、
  事件模块不变项）；文档提交 `57dc444`（状态文件、session、记忆索引）、
  `e59f4a6`（补充断言记录与提交清单）。

### 2026-11-05 · 第 40 程（第 3 章大地图施工第 1 步：计划与图骨架）

- 交接：第 39 程收尾 HEAD `01c29d5`，工作区干净，第 2 章与第 3 章均不可达；待确认第 11/12/13/14/15/16 项开放，本程不施工、不猜测。
- 任务 0 · 基线核验（HEAD `01c29d5`，Godot 4.7.stable.official.5b4e0cb0f）：
  `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0；单元 **8011 / 0**；
  九套集成 **671 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209** 全 0 失败；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与交接逐项一致，无基线漂移。
- 任务 1 · 第 3 章计划与图骨架（只做计划层，未产生可玩行为变化）：
  - `ChapterPlanData` 新增 `content_pending`（默认 `false`，向后兼容）：`validate()`
    仍校验区域、节点 id 与门图，只跳过 `validate_waves()`；第 1/2 章计划保持
    `false`，校验结果不变。测试把第 3 章计划的标志临时关掉，确认仍报六条
    「encounter … needs a wave」，证明跳过范围是局部的。
  - 新增 `resources/chapters/chapter_3_demo.tres`：9 区连通图（`ch3_entry` 入口、
    `ch3_branch_a`/`ch3_branch_b` 两条可回环支路、`ch3_hub` 枢纽、`ch3_well`
    纵井、`ch3_vault` 隐藏书库、`ch3_event` 事件占位、`ch3_elite` 精英、
    `ch3_boss` 末端）。尺寸 2560×1440 / 2560×2160（纵井）/ 3840×2160（精英、Boss）；
    每区 `fall_below_bounds = 240`。
  - 内容节点：6 个战斗遭遇（支路 A 2、支路 B 1、纵井 2、精英 1）对应旧第 3 章
    `ROOM_WAVES[2]` 六波（本程不写 `wave`），事件区 1 个占位遭遇；
    `clear_target()` 派生 **7**（第 1 章仍 6、第 2 章仍 7，未改）。3 宝箱、2 残碑，
    全部 `region/Node` 节点 id。
  - 门：11 条 = 9 双向 + 2 显式单向（`elite_boss` 进 Boss 不可返回；
    `hub_shortcut_entry` 捷径 `requires: ["ch3_shortcut"]`，来源待第 16 项拍板、
    默认不可通行）。图内两个回环，Boss 为末端。
  - 占位/留空：无 `wave`、无 `authority_pool`、无 `boss_scene`、无事件文案/效果、
    无 Boss 入场/阶段文案、无 `ch3_shortcut` 授予来源；事件区/Boss 区/捷径门
    均有注释标明「待后续内容程」或「待拍板」。第 14（视野压缩）、15（海面母题）
    只在计划注释与夹具顶层注释记录，未实现、未预设数值/机制；未给大区管线加
    sea 层、未改 `LivingBackdrop`、未新绘背景。
  - 新增图骨架夹具 `tests/fixtures/big_room/ch3_graph.mdsworld.json`：
    `fixture: true`、`content_pending: true`、无 `scene_path`/房间场景、游戏从不
    引用；镜像旧世界区域 `Lightless Sea` 的雾/雨与 `boss_background=deep_water`，
    不写 `backdrop_image`；20 扇有向门 + 2 扇到达门。
  - 新增 `tests/test_ch3_plan.gd`（728 断言）：计划形状/类型/尺寸/坠落平面/内容 id/
    清房目标/图可达性/单向门/捷径占位/待内容标记 + 计划↔夹具逐区逐门交叉校验 +
    夹具几何（不重叠、门在正确边、门位在房间内、区域相邻、捷径不邻接）+
    第 1/2 章计划不变 + `game.gd` 路由槽仍为空 + 第 3 章旧世界文件仍在。
  - 未接入：`CHAPTER_PLAN_PATHS[2]` 仍为空（既有测试锁定），`game.gd` 未改；
    旧 `chapter_3.mdsworld.json` / `chapter_3_world.tscn` 与 9 个 `MDSChapterRoom`
    场景未改未删、仍被游戏使用；第 3 章仍不可达，章末仍会自动进第 4 章。
- 验证（改动后）：单元 **8739 / 0**（+728，全部来自 `test_ch3_plan.gd`）；
  九套集成 **671 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209** 全 0 失败；
  `--import`/`--quit` 退出 0、`ERROR` 0；退出泄漏 **10/10 clean**；像素资产 **36 / 0**。
  第 1 章 9 房间/6 波次/事件/清房目标 6/结束流程与第 2 章计划/世界均无回归。
- 未做（按任务单）：第 3 章真实大区世界/房间（`resources/rooms/ch3_bigmap/`、
  `scenes/mds/ch3_bigmap/`、世界 JSON/场景）、`Ch3EventData`、波次接线、权柄池、
  Boss 3 机制/`boss_scene`/入场与阶段文案、第 3 章大图验收套件、第 2–4 章可达性、
  第 11/12/13 项相关数值/相机/HUD、第 14/15/16 项机制、阿砚同行、新移动能力、
  NPC 立绘、MDS 插件本体、敌人/场景美术、打包/导出/安装器/签名/安卓/触屏。
- 本程提交：`51ce8a7` feat: author the chapter 3 big-map plan and graph skeleton（`content_pending`、第 3 章计划、图夹具、728 断言测试）；文档提交 `ccede15` docs: record the chapter 3 plan and graph skeleton（状态文件、session、ADR、记忆索引）。

### 2026-11-05 · 第 39 程（第 3 章大地图可行性核查，只查不施工）

- 交接：第 38 程收尾 HEAD `5877b2a`，工作区干净，第 2 章仍不可达；待确认第 11/12/13 项开放，本程不施工、不猜测。
- 任务 0 · 基线核验（HEAD `5877b2a`，Godot 4.7.stable.official.5b4e0cb0f）：
  `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0；单元 **8011 / 0**；
  九套集成 **671 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209** 全 0 失败；
  退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与交接逐项一致，无基线漂移。
- 任务 1 · 第 3 章大地图可行性核查（只查，未改产品代码/资源）：
  - 世界/房间：`chapter_3_world.tscn` + `chapter_3.mdsworld.json` 共 **9 房、17 门**
    （7 right / 7 left / 3 door），全部 1280×720 单矩形、单层地面（面 y=560），
    平台 2/2/1 块；`ch3_03`/`ch3_05` 各 1 宝箱，`ch3_rest` 商店+残碑+捷径门
    （door2→`ch3_02`），`ch3_vault` 宝箱+残碑+返回门，`ch3_boss` Arena/Boss；
    全部 `MDSChapterRoom`（`chapter_index=2`），背景 `lightless_sea.png`
    + `LivingBackdrop(sea=true)`，区域雾+雨、`background` 为空、
    Boss 房 `boss_background=deep_water`（探针确认 MDS 解析）。
  - 文本/语音/Boss：第 3 章 **6 句开场、4 句章末、2 个选项**；`ch3_intro/outro`、
    `boss_reader_phase2/3` 语音与 `chapter_sea.ogg` 均存在；Boss「最后的读者」
    HP 380 / 伤害 15 / 速度 78 / `boss_script=&"reader"` / 立绘 `last_reader.png`
    （256×256 RGBA，持书孩子）/ `boss_voice="reader"`；`last_reader.gd` +
    `last_reader.tscn` 存在，已实现镜面三连弹与「读页」封印短语；**没有** `boss_scene`
    键，靠 `_spawn_boss` 的 `boss_script == "reader"` 旧分支路由（探针确认实际脚本）。
  - 敌人/波次/美术：`ROOM_WAVES[2]` 已配 6 波，六组首发与数据/场景齐全；
    9 种 spawn 中 6 种已接线专属精灵（`echo_enemy`/`hanging_scribe`/`mirror_sniper`/
    `typo_beast`/`scribe_bug`/`page_swarm`），3 种继续回退第 1 章美术
    （`rust_whisperer`→`scribe_bug`、`collapse_husk`→`blank_man`、`lung_moth`→`hanging_scribe`），
    三种都在第 38 程缺失清单内，**无新增第 3 章专属缺图**；`echo_enemy` 的 data id 是
    `amnesiac_echo`，美术按 spawn id 解析（已核实渲染正确）。
  - 计划/内容数据：`chapter_3_demo.tres` 不存在、`CHAPTER_PLAN_PATHS[2]` 为空、
    测试 `ch2_game_ch3_has_no_plan_yet` 锁住；`resources/rooms/ch3_bigmap/` 与
    `scenes/mds/ch3_bigmap/` 不存在；`_event_data()` 返回 `{}`（无 `Ch3EventData`）；
    无计划权柄池（Boss 后不开权柄）；`BossEntranceData`/`BossPhaseData` 第 3 章返回
    空串/空数组（静默入场、无阶段 flavor、不回落第 1 章）；地图标题已由第 38 程
    派生为「无光海地图」；无计划时清房目标 6、HUD 分母 7、坠落平面 850；
    `_complete_chapter()` 仍会自动续章进第 4 章。
  - 叙事：剧情圣经「最后的读者是孩子」「故事需要有人翻页」等目前只有文本，
    无事件房/对话节点/剧情实体；仓库无 companion/follower 控制器（MDS `carry_over`
    未使用），第 3 章没有 NPC 同行实体。
  - 承载力结论：**第 2 章的大区连通图路线可直接承载第 3 章**——`BigRoomData` +
    `MDSBigRoom` 无章节判断，第 27 程的节点 id 结算/区域坠落平面/计划目标均章节无关；
    第 3 章旧世界可原地保留。**缺口在内容层**：计划/图骨架、真实大区世界、事件数据、
    权柄池、Boss 入场/阶段文案、第 3 章大图验收套件。
  - 第 3 章独有差异：海面母题只在 `LivingBackdrop(sea=true)` 里（大区管线无 sea 层，
    `BigRoomAmbient` 仅 motes/embers）；GDD「视野压缩」完全未实现（无 darkness/vignette，
    `room_darkness=false`）；无水域物理；Boss 3 已有专属脚本但未接计划；捷径
    `ch3_shortcut` 无授予来源；章末会自动进第 4 章；入口需作者 `SpawnPoint`；
    背景为 1536×864 绘画（与第 2 章同一已知缺口）；大区性能待实测。
  - 施工顺序建议（前置依赖见专节 C）：计划/图骨架 → 真实大区世界 → 内容数据层 →
    Boss 3 机制 → 系统验收；第 3 章可达性仍须单独拍板且不能早于第 2 章。
  - 新增待确认第 14（视野压缩口径）、15（大图海面母题）、16（`ch3_shortcut` 来源），
    均为第 3 章施工前需定，本程未设计、未施工。
- 验证（收尾，改动仅文档）：单元 **8011 / 0**；九套集成 **671 / 102 / 613 / 207 /
  113 / 59 / 391 / 45 / 2209** 全 0 失败；`--import`/`--quit` 退出 0、`ERROR` 0；
  退出泄漏 **10/10 clean**；像素资产 **36 / 0**。临时探针 `tests/tmp_ch3_audit.gd`
  已删除，工作区干净。
- 未做（按任务单）：第 3 章任何施工（计划/大区/房间/事件/权柄/Boss 内容）、第 2–4 章
  可达性、Boss 3 新机制、阿砚同行、新移动能力、NPC 立绘、MDS 插件、敌人/场景美术、
  待确认第 11/12/13 项相关数值/相机/HUD、打包/导出/安装器/签名/安卓/触屏。
- 本程提交：`109381e` docs: audit chapter 3 for the big-map pipeline（状态文件、核查 session、记忆索引）；`b154549` docs: fix the chapter 3 room wording in the status summary。本程无产品代码/资源改动。

### 2026-11-05 · 第 38 程（第 2 章地图标题 + 敌人美术核查）

- 交接：第 37 程收尾 HEAD `c0a5e53`，工作区干净，第 2 章仍不可达；待确认第 11/12/13 项开放，本程不施工、不猜测。
- 任务 0 · 基线核验（HEAD `c0a5e53`，Godot 4.7.stable.official.5b4e0cb0f）：`--headless --path . --import` / `--quit` 退出 0、`ERROR` 0；单元 **7901 / 0**；九套集成 **665 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2202** 全 0 失败；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与交接逐项一致，无基线漂移。
- 任务 1 · 第 2 章地图标题（只改标题派生，不改地图/房间）：
  - `MapOverlay` 标题从字面量改为成员 `_title`；新增 `DEFAULT_TITLE`、`map_title(chapter_index)`、`set_chapter()`、`title_text()`。第 1 章（索引 ≤0）冻结「档案馆地图」；第 2–4 章读既有 `CampaignData.chapter(i)["region"]` → 「<区域名>地图」，第 2 章为「呼吸废墟地图」；区域空/索引无效回落第 1 章标题，不新造章节名。
  - `game.gd` 在 `set_world()` 前调用 `set_chapter(chapter_index)`；`_chapter_index` 保留，`_ready()` 前调用也不丢，启动/续玩/重开走同一路径。
  - 验收：新增 `tests/test_map_overlay.gd` 16 断言（第 1/2 章标题、来源、第 3/4 章同规则、-1 回落、构建前/后、来回切换不残留）；`tests/integration_playability.gd` +6 断言（真实第 1 章标题不变、第 2 章标题正确且非第 1 章、第 3/4 章按区域派生）。第 2 章仍不可达，只在测试层驱动。
- 任务 2 · 第 2 章敌人专属美术核查与仅接线：
  - 核查：五种敌人中仅 `choir_summoner` 有专属精灵 `assets/sprites/enemies/choir_summoner.png`（96×96 RGBA），且已在 `ENEMY_ART`、不在 `ENEMY_ART_FALLBACK`，实际白 tint 渲染；无需改动，用测试锁定。
  - **缺失清单**（无现成专属精灵/原图，按任务单不新绘、不拼凑、不猜测，保持第 1 章精灵 `#c8e1cd` 回退）：`breath_hound`（→`ink_hound`）、`lung_moth`（→`hanging_scribe`）、`rust_whisperer`（→`scribe_bug`）、`collapse_husk`（→`blank_man`）。四个场景内只有程序化 `Polygon2D` 占位；`assets/concept/enemies/` 无对应原图。
  - 接线/锁定：回退 tint 提为 `ENEMY_FALLBACK_TINT`（行为不变）；新增 `tests/test_enemy_art.gd` 94 断言（第 1 章 8 敌保留原 PNG/不在回退表；第 2 章五敌场景/数据/唯一美术来源；已接线敌白 tint、不走回退；四缺失敌回退源为第 1 章美术、标准路径暂无专属 PNG，日后补图未接线会失败）；`tests/integration_ch2_bigmap.gd` +7 断言（真实遭遇中 `choir_summoner` 用专属图/白 tint，`rust_whisperer` 仍 `scribe_bug`/绿 tint）。未新增/修改任何敌人贴图或场景美术；第 1 章敌人美术与波次未改。
- 验证（改动后）：单元 **8011 / 0**（+110）；九套集成 **671 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 2209** 全 0 失败（可玩性 +6、第 2 章大地图 +7）；`--import`/`--quit` 退出 0、`ERROR` 0；退出泄漏 **10/10 clean**；像素资产 **36 / 0**。第 1 章 9 房间/6 波次/事件/清房目标 6/Boss 与结束流程未改；第 2 章仍不可达。
- 未做（按任务单）：第 2 章可达性；待确认第 11/12/13 项；四个缺失敌人的专属美术；阿砚同行；新增移动能力；NPC 立绘；MDS 插件（零改动）；打包/导出/安装器/签名/安卓/触屏。
- 本程提交：`0b469ec` feat: name each chapter's map after its region；`0468579` test: lock chapter 2 enemy art wiring；文档提交 `858f0f9` docs: record the chapter 2 map title and enemy art audit。

### 2026-11-05 · 第 37 程（第 2 章自动门视觉 + 新局出生点）

- 交接：第 36 程收尾 HEAD `959c90d`，工作区干净，第 2 章仍不可达；「待用户确认」第 11 项（`ch2_shortcut` 获取来源）明确为开放可达性前的前置，故本程不开放可达性、不碰第 11/12 项。
- 任务 0 · 基线核验（HEAD `959c90d`，Godot 4.7.stable.official.5b4e0cb0f）：`--headless --path . --import` / `--quit` 退出 0、`ERROR` 0；单元 **7873 / 0**；九套集成 **665 / 102 / 613 / 207 / 113 / 59 / 391 / 45 / 1303** 全 0 失败；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与交接逐项一致，无基线漂移。
- 任务 1 · 自动门视觉（只加表现，不改门逻辑）：
  - 新增 `scripts/presentation/gate_visual.gd`（`GateVisual`）：复用既有手动门 `ChapterDoor` 的视觉语言（同一 `door.png`、accent 边框、上浮墨尘、HUD theme 12 px 描边标题），不新增贴图、不引入第二种门风格。
  - `MDSBigRoom` 新增 `GATE_VISUAL_NAME = "GateVisual"` 与 `_add_gate_visuals()`：自动门生成后给当前房间所有 `MDSGate`（自动 + 作者门）挂视觉；`auto_gates = false` 时只补视觉；作者可用同名节点覆盖。
  - side 感知：left/right 立门向房间内展开、门底按门下方最近的地面/台阶落面对齐（台阶 16 px、地面 90 px）；top/bot 同一贴图横置为天花板/地面舱口。有去向标「前往 <目标区名>」+ 朝向箭头，无去向的到达门标「来路」无箭头；贴边门标题向房间内收。
  - 纯 `Node2D`（`z_index = -1`）、零碰撞/信号/输入；门位、模式、单向语义、`requires`/`MDSGateBarrier` 判定、过渡目标未动；MDS 插件本程零改动。
  - 验收：`tests/test_big_room.gd` 新增门视觉单测（+28 断言）并断言第 1 章 9 场景无 `GateVisual`；`tests/integration_ch2_bigmap.gd` 逐门断言九区全部世界门有可见视觉、side/caption 正确、零碰撞，收尾 **9 区 / 22 扇门视觉**（20 连通 + 2 到达）。xvfb + OpenGL 离屏截图做外观 QA（`/tmp/ch2_gate_caps/`，未提交）。
- 任务 2 · 第 2 章新局出生点（只改第 2 章大图分支的出生处理）：
  - 根因：`MDSWorldGame._spawn_position()` 在无到达门/无显式坐标/房间内无 `save_point` 时回退 `MDSWorld.get_room_label_pos()`，即**房间最大矩形中心**（地图标签锚点）；`ch2_entry` 2560×1440 → (1280,720)，比第一级台阶面 y=1344 高 624 px。地面碰撞与落地判定无错，错的是出生坐标；第 1 章房间有程序化 `SavePoint` 所以从未暴露。
  - 修复：`scenes/mds/ch2_bigmap/ch2_entry.tscn` 作者 `Marker2D` `SpawnPoint`（组 `save_point`，位置 (400,1328) = 台阶面 1344 − `Player.FOOT_Y` 16），走 MDS 既有优先级；不改 MDS 回退顺序，不改第 1 章出生/Hub 流程，经门进入仍用门落点。
  - 验收：`tests/test_ch2_world.gd` 断言标记存在/组正确/脚底 = `platforms[0].y − FOOT_Y`；集成断言玩家在标记处、`_spawn_position` 命中标记、标记比房间标签锚点低 400+ px、第一物理帧 `is_on_floor()`、0.3 秒内不漂移。探针实测首帧 `pos=(400,1328)`、`vel=(0,0)`、`floor=true`。
- 验证（改动后）：单元 **7901 / 0**（+28）；八套既有集成 **665 / 102 / 613 / 207 / 113 / 59 / 391 / 45** 全部不变、第 2 章大地图 **2202 / 0**（+899）；`--import`/`--quit` 退出 0、`ERROR` 0；退出泄漏 **10/10 clean**；像素资产 **36 / 0**。第 1 章 9 个 `MDSChapterRoom`、6 波次、事件房、清房目标 6、Boss 与结束流程未改；第 2 章仍不可达（仅在测试/探针层驱动）。
- 后续候选（超出本程范围，只记录）：大区相机限制 = 房间边界时，区底角色与地面舱口会被底部 HUD 面板遮挡（已列待确认第 13 项）；待确认第 11/12 项保持开放。
- 文档：新增 `docs/memory/sessions/2026-11-05-chapter2-gate-visuals-spawn.md`、ADR `docs/memory/decisions/2026-11-05-big-map-gate-visuals-spawn.md`；更新 `docs/memory/MEMORY.md` 与 `SUPERVISOR_STATUS.md`。临时探针与截图产物已删除/未提交。
- 未做（按任务单）：第 2 章可达性；第 11/12 项本身；阿砚同行、敌人专属美术、第 2 章地图标题；新增移动能力；NPC 立绘；MDS 插件；打包/导出/安装器/签名/安卓/触屏。
- 本程提交：`131cf14` fix: start chapter 2 on the entry step, not in mid-air；`9a5b7c0` feat: give big-map gates the manual door language；文档提交 `83d2587` docs: record the chapter 2 gate visuals and spawn fix。

### 2026-11-04 · 第 36 程（第 2 章大地图系统验收 + 地面门到达修复）

- 交接：第 35 程收尾 HEAD `0edc028`，工作区干净；第 2 章 Boss 2 已落地、章末停章、大图生成高度已修，但第 2 章仍不可达。本程只做 D 节验收面内的验证与真实缺陷修复，不开放可达性，不改第 1 章 9 房间/6 波次/事件/清房目标 6/结束流程，不扩大施工范围。
- 任务 0 · 基线核验（HEAD `0edc028`，Godot 4.7.stable.official.5b4e0cb0f，`~/workspace/tools/godot/bin/Godot_v4.7-stable_linux.x86_64`）：
  - `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0。
  - 单元 **7873 / 0**；八套集成全部 0 失败——结构/可玩性 **665**、第一章 demo **102**、run save **613**、手柄 **207**、UI 提示 **113**、第一章事件 **59**、菜单 A/B **391**、AI 设置 **45**；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与第 35 程收尾逐项一致，无基线漂移。
- 任务 1 · 第 2 章大地图验收（只加测试/探针，不改正常流程）：
  - 新增 `tests/integration_ch2_bigmap.gd`：从第 1 章正常启动后由测试进入第 2 章计划世界，真实加载九区、真实使用门、真实清怪/开箱/读碑/乘电梯/打 Boss/存续玩，共 **1303 断言，0 失败**。
  - 覆盖 D 节 1–10：① 入口有向 BFS 九区全可达、20 扇连通门 + 2 扇到达门全部实走、2 扇显式单向语义正确、无孤立区；② 九区边界 = 计划尺寸、`get_room_bounds()`、相机四边限制 = 世界边界、玩家在房内、区域氛围/背景/雾正确；③ 电梯乘行 → top 门 → bot 门到达出速 -650、落点在门上方、**2 秒内不被同门弹回**、井下层落穿不误判坠落、长椅检查点回退、坠落平面 = 区高 + 240；④ 每扇门过渡目标/到达门/坐标容差、过渡期间不叠暂停/剧情/奖励/地图/权柄/商店（按既定大区图口径用门 + 0.22 秒淡入，不做无缝走进）；⑤ 书库 2 箱 2 碑按节点 id 各只发一次、重载/续玩不重复；⑥ 支路两场遭遇逐场锁门（碰撞层 1）/清怪/开门/按节点 id 发奖、重载不重生、清房推进到 7（HUD 分母 8）；⑦ 书库首次发现反馈与地图揭示、捷径门授予/开门/通行/跨存档保持；⑧ Boss 区生成点/门位/入场与阶段文案/权柄池/续玩不二次生成/章末 `_finish(true)` 停在 `_chapter == 1`；⑨ 性能数字；⑩ 第 2 章事件页、Boss 文案、权柄池、章节收口在真实流程中断言。
- 修复的真实缺陷 · 地面（bot）门到达回弹：
  - 症状：从任意 bot 门到达后约 0.7 秒，玩家落地时再次进入同一扇门，被送回上一房间；所有向上纵向连接因此实际变成单向。探针在 `ch2_entry` 复现（修复前 0.8 秒回弹）。
  - 根因：MDS 对 bot 到达把玩家以 `up_exit_speed`（650 px/s）向上抛出，玩家落回时再次触发同门；原有 3 物理帧保护 + 0.35 秒门冷却覆盖不了整个抛物线。
  - 修复：`addons/MetroidvaniaDeveloperSystem/nodes/mds_world_game.gd` 新增 `@export var floor_arrival_grace := 1.2`；`load_room()` 记录到达门，仅 bot 门设置宽限截止；`_on_gate_entered()` 在宽限期内忽略来自该门的触发。横向/top 不变，0 可关；其他章节世界无 bot 门，不受影响。第 1 章无回归。细节见 ADR。说明：既有 ADR 的红线是「不重写 MDS」；本次是验收面内真实缺陷的 23 行追加式修复，不改门/房间/存档格式，`floor_arrival_grace = 0` 可完全关闭，已单独写 ADR 记录取舍。
  - 验证：修复后探针在 `ch2_entry` 停留 3 秒并稳定落地；集成套件用 2 秒窗口断言不回弹，25 段门行走全部走通。
- 性能基线（`fade_time = 0` 测原始构建耗时；正常游戏由 0.22 秒淡入覆盖）：普通区热加载 **5.6–9.2 ms**；Boss 区首次 **61.0 ms**（冷启动）、第二次 **10.2 ms**、套件内热加载 **24–43 ms**（运行波动）；精英区首次 **35.0 ms**；Boss 区关闭动态背景 **11.7 ms**、关闭天气 **9.1 ms**、不生成 Boss **35.9 ms**。未发现需要本程处理的性能缺陷。
- 后续候选（超出本程范围，只记录不施工）：① `ch2_shortcut` 无游戏内获取来源（内容/设计缺口，已列待确认第 11 项）；② 自动生成的 `MDSGate` 没有门扉/提示视觉（表现/UX 缺口）；③ 电梯作者速度 70 px/s，乘行约 19 秒 / 29 秒（节奏/调参，已列待确认第 12 项）；④ 第 2 章新局出生点落在房间标签下方空中后稳定落到台阶（打磨）；⑤ 阿砚同行、敌人专属美术、第 2 章地图标题仍为「档案馆地图」（内容/表现缺口，按任务单不扩大施工）。
- 验证（改动后）：单元 **7873 / 0**；八套既有集成 **665/102/613/207/113/59/391/45** 全 0 失败；新增第 2 章大地图集成 **1303 / 0**；`--import`/`--quit` 退出 0、`ERROR` 0；退出泄漏 **10/10 clean**；像素资产 **36 / 0**。第 1 章 9 个 `MDSChapterRoom`、6 波次、事件房、清房目标 6、Boss 与结束流程未改；第 2 章仍不可达。
- 文档：新增 `docs/memory/sessions/2026-11-04-chapter2-bigmap-acceptance.md`、ADR `docs/memory/decisions/2026-11-04-floor-arrival-grace.md`；更新 `docs/memory/MEMORY.md` 与 `SUPERVISOR_STATUS.md`。临时探针（`probe_ch2_*`）测后删除。
- 未做（按任务单）：第 2 章可达性；第 3 章内容；Boss/敌人/NPC 美术与立绘；新增移动能力；打包/导出/安装器/签名/安卓/触屏。

### 2026-11-04 · 第 35 程（第 2 章 Boss 2 独特机制 + 章节过渡）

- 交接：第 34 程收尾 HEAD `571b36c`；本程在该 HEAD 上施工，完成后才提交。只做第 2 章 Boss「肺钟守卫」独特机制与第 2 章结束语义，未开放第 2 章可达性，未改第 1 章 Boss/战斗框架/敌人美术/NPC 立绘，未新增移动能力，未删旧世界/旧场景。
- 任务 0 · 基线核验（HEAD `571b36c`，Godot 4.7.stable.official.5b4e0cb0f，`~/workspace/tools/godot/bin/Godot_v4.7-stable_linux.x86_64`）：
  - `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0。
  - 单元 **7821 / 0**；八套集成全部 0 失败——结构/可玩性 **651**、第一章 demo **102**、run save **588**、手柄 **207**、UI 提示 **113**、第一章事件 **59**、菜单 A/B **391**、AI 设置 **45**；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与第 34 程收尾逐项一致，无基线漂移。
- 任务 1 · 现状核对与分层（先查后写）：
  - 第 1 章 Boss 走 `CampaignData.chapters[0].boss_scene = ink_archivist_ch1.tscn`（`InkArchivistCh1 extends InkArchivist`）；`game._spawn_boss` 统一负责生成、血条、阶段横幅、权柄三选一、outro/choice 与结束屏。第 2 章此前只有 `boss_script = ink`、数值（360 HP / 14 伤害 / 75 速度）、立绘与入场/阶段文案，没有专属场景或机制。
  - 口径（歧义已记录并锁定）：独特机制放在 **Boss 场景子类** `LungBellGuardian extends InkArchivist`，由第 2 章计划的 `boss_scene` 路由；通用 Boss 流程一律复用，不改 `InkArchivist`、`InkArchivistCh1` 与 `_spawn_boss` 的通用分支。`_spawn_boss` 原有优先级不变（第 1 章战役表 → 第 2 章计划 → 旧脚本兜底），所以第 1 章仍选 `InkArchivistCh1`，计划字段只影响第 2 章。
- 任务 2 · 机制实现（`scripts/bosses/lung_bell_guardian.gd` + `scenes/bosses/lung_bell_guardian.tscn`，`chapter_2_demo.tres` 的 `boss_scene` 指向它）：
  - 呼吸循环：吸气 2.4 s（受到伤害 ×0.5）→ 呼气 1.4 s（受到伤害 ×1.5，并释放扩散气环 560 px / 720 px/s / 0.8× 攻击力）；阶段 2 起呼气额外在玩家位置留下墨池（0.35×、70 px、4 s）；阶段越高节奏越快（0.7× 下限）。sprite tint + 气环给清晰前摇/状态。
  - 钟摆：基础攻击为正反两枚 `HostileBolt`（前方 0.7×、后方 0.75×），读作钟摆横扫；阶段 2 起每第 3 次改为钟鸣环（620 px / 760 px/s / 0.9×）；气弹 `InkBomb`（0.8×、留池）。
  - 钉子：阶段 3 起周期性暴露（暴露 5 s，受到伤害 ×1.5；闭合 7 s，受到伤害 ×0.6；周期 12 s），作为阶段 3 的输出窗口；阶段 1–2 仍按呼吸承伤。死亡清空气环并关闭钉子。
  - **数值口径（歧义已记录）**：剧情圣经/计划只有「钟摆与肺叶」「攻击有清晰前摇」「阿砚给肺钟打过一颗钉子」等定性描述，没有攻击数值。以上数值是本程采用口径，**待试玩校准**，由 `tests/test_ch2_boss.gd` 锁定；后续改数值必须同步改测试并在状态文件登记。
- 任务 3 · 第 2 章结束语义（`scripts/game.gd::_complete_chapter`）：
  - 第 2 章（`_chapter == 1`）章末选择结算后调用现有 `_finish(true)` 停在结束屏，不再 `_start_chapter(2)` 进入未实现的第 3 章；第 1 章分支（`_chapter == 0`：`demo_cleared` + `_finish(true)`）代码与流程一字未改，第 3/4 章保留原有自动续章以维持结构测试覆盖。
  - **界面/结局口径（歧义已记录）**：第 2 章末沿用现有结束屏与结局记录（默认 `unfinished`），不新增「待续」UI、结局 id 或存档键；第 2 章仍不可达，当前只由测试/探针验证。若未来开放第 2 章 demo，需要决定是否改为章节完成屏、避免提前解锁结局画廊。
- 任务 4 · 必要修复（测试暴露的真实缺陷）：大区 `ArenaRoom` 的原点位于可走地面（`BigRoomData` 表面），旧 `_spawn_group`/`_spawn_boss` 固定 +250 px 生成会把第 2 章敌人/Boss 埋到地下。`game.gd` 新增 `_enemy_spawn_y()`：`big_map` 计划生成在 `-ENEMY_FOOT_Y - 2`，第 1/3/4 章仍 250 px；只影响大图分支，第 1 章生成路径与波次不变。
- 任务 5 · 测试与验证（本程末实测）：
  - 新增 `tests/test_ch2_boss.gd`（51 断言）：计划路由/数值/场景类型、吸气承伤、呼气增伤与气环、钟摆双向、气弹留池、阶段 2 钟鸣、阶段 3 钉子窗口与重新暴露、死亡清气环、第 1 章 Boss 无这些方法且场景未变。
  - `tests/integration_playability.gd` 扩到 **665**（+14）：第 1 章 Boss 仍是 `InkArchivistCh1`；第 2 章 6 场波次生成点在地面之上；`ch2_boss` 生成 `LungBellGuardian`、初始吸气、吸气承伤系数、生成点在地面之上、真实呼气生成气环；第 2 章章末选择后停在 `_chapter == 1`、`_finished`、结束屏可见。
  - `tests/integration_run_save.gd` 扩到 **613**（+25）：第 2 章 Boss 击败 → 权柄三选一（断言授予来自第 2 章计划池）→ 存档 → 续玩不二次生成 Boss、权柄/残页/击杀不重复发放、outro/choice 可继续 → 选择后停在第 2 章并清档。
  - `tests/test_ch2_plan.gd` 更新 2 条：第 2 章计划拥有 `boss_scene` 且指向 `lung_bell_guardian.tscn`；第 1 章计划仍指向 `ink_archivist_ch1.tscn`。
  - 全量单元 **7873 / 0**（基线 7821 + 52）；八套集成全部 0 失败、各日志 `ERROR` 0——结构/可玩性 **665**、第一章 demo **102**、run save **613**、手柄 **207**、UI 提示 **113**、第一章事件 **59**、菜单 A/B **391**、AI 设置 **45**。
  - 退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**；`--import`/`--quit` 退出 0、`ERROR` 0；临时探针未创建；工作区干净。
- 本程未做（按任务单）：第 2 章可达性；第 3 章内容；第 1 章 Boss/战斗框架/敌人美术/NPC 立绘改动；新增移动能力；MDS 插件；言灵/权柄/战斗框架；删除旧世界/旧场景；打包/导出/安装器/签名/安卓/触屏。
- 提交：`9f8caad`（Boss 2 场景/机制/计划路由）、`5346b2b`（大图生成高度修复 + 第 2 章结束收口）、`74f6615`（Boss/边界测试）、`<本提交>`（状态、ADR、session、记忆）。仅本地 `supervisor-dev`，不推送、不更新网页版。

### 2026-11-04 · 第 34 程（第 2 章内容数据层第 3 步：事件区真实自动触发）

- 交接：第 33 程收尾 HEAD `22e0a52`；启动时工作区干净、无在途改动、无会话在跑。本程只给第 2 章事件区接真实自动触发，未开放第 2 章可达性、未实现 Boss 2 独特机制/专属攻击、未做章节过渡、未新增移动能力，未改 MDS 插件/言灵/权柄/战斗框架/敌人美术/NPC 立绘，未删旧世界/旧场景。
- 任务 0 · 基线核验（HEAD `22e0a52`，Godot 4.7.stable.official.5b4e0cb0f，`~/workspace/tools/godot/bin/Godot_v4.7-stable_linux.x86_64`）：
  - `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0。
  - 单元 **7819 / 0**；八套集成全部 0 失败——结构/可玩性 **636**、第一章 demo **102**、run save **588**、手柄 **207**、UI 提示 **113**、第一章事件 **59**、菜单 A/B **391**、AI 设置 **45**；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与第 33 程收尾逐项一致，无基线漂移。
- 任务 1 · 触发点核对（先查后写）：
  - 第 1 章事件房 `ch1_05` 走 `MDSChapterRoom`、有主 `Arena`，`_on_mds_room_loaded` 的 `is_primary and _chapter == 0 and room_type == "event"` 命中：进房设目标 → `_open_event_after_transition` 延迟 0.8 s 开页，离开房间会取消；结算按 `ch1_05/event` 一次。
  - 第 2 章 `ch2_event` 只有 `Event`（`ArenaRoom`，`encounter_id = ch2_event/event`）与 `Stele1`，没有主 `Arena`；`is_primary` 永远不成立，且 `_chapter == 0` 把第 2 章排除。计划 `chapter_2_demo.tres` 该区 `type = "event"`、`encounters = ["ch2_event/event"]`。
  - 口径（歧义已记录并锁定）：触发挂在**区域级**（`big_map` + `type == "event"` + 本章有事件数据），不依赖有没有主 `Arena`；第 1 章原 `is_primary` 分支一字未动，两者汇入同一个 `_open_chapter_event`。理由：事件页属于区域（计划 type + 事件节点），不属于某个战斗 Arena；将来区域内没有 Arena 也能触发。
- 任务 2 · 接线（`scripts/game.gd`）：
  - `_on_mds_room_loaded` 在 Arena 循环之后新增区域级事件分支：未结算 → 设目标「事件 · 读或不读」并 `_open_event_after_transition(room_id)`；已结算 → 设目标「事件已经读过」。目标文案沿用第 1 章既有字符串，不写新文案。
  - 页面仍走 `_event_data(room_id)` → `_open_chapter_event(room_id)`：第 2 章用 `Ch2EventData.pick(run_seed, RoomProgress.event_encounter_id(room_id))`，键 = 计划事件节点 id `ch2_event/event`；两项效果与第 32 程一致（读 → 污染 +8 + 解明一个残页词，无词则残页 +6；拿 → 残页 +12）。
  - 结算沿用 `_mark_encounter_cleared(room_id, event_encounter_id(room_id))`，复用 `cleared_encounters` 存档键（不新增存档键/格式），只记一次、计入清房目标 7；未结算离开区域会取消延迟开页（沿用第 1 章规则）。续玩由现有 run save 的 `cleared_encounters` 还原覆盖，重载断言锁定触发查询。
- 任务 3 · 测试与验证（本程末实测）：
  - `tests/integration_playability.gd` 扩到 **651**（+15）：从大图房间加载路径进入 `ch2_event` 自动打开第 2 章页（不再直接调开页函数），文案/选项来自 `Ch2EventData` 且开页不消耗 run RNG；“拿”+12 残页与消息、“读”+8 污染并解明一个残页词（无词则 +6）；节点 `ch2_event/event` 只结算一次并计入进度；结算后重载不重开、不暂停、不重复发奖励；真实 run save 写入 `cleared_encounters` 后清理临时档。
  - `tests/test_ch2_content.gd` 扩到 **510**（+2）：`RoomProgress.event_encounter_id("ch2_event") == "ch2_event/event"` 且计划锚定同一节点，锁定触发键与结算键一致。
  - 全量单元 **7821 / 0**（基线 7819 + 2）；八套集成全部 0 失败、各日志 `ERROR` 0——结构/可玩性 **651**、第一章 demo **102**、run save **588**、手柄 **207**、UI 提示 **113**、第一章事件 **59**、菜单 A/B **391**、AI 设置 **45**。
  - 退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**；`--import`/`--quit` 退出 0、`ERROR` 0；临时探针未创建；工作区干净。
- 本程未做（按任务单）：第 2 章可达性；Boss 2 独特机制/专属攻击；章节过渡；新敌人/敌人美术/NPC 立绘；二段跳/蹬墙跳/攀爬；MDS 插件；言灵/权柄/战斗框架；删除旧世界/旧场景；打包/导出/安装器/签名/安卓/触屏。
- 提交：`f095c78`（`game.gd` 区域级事件触发）、`ec1d2b2`（可玩性集成 + 内容单元断言）、`<本提交>`（状态、ADR、session、记忆）。仅本地 `supervisor-dev`，不推送、不更新网页版。

### 2026-11-04 · 第 33 程（第 2 章内容数据层第 2 步：波次接线）

- 交接：第 32 程收尾 HEAD `40d1d67`；启动时工作区干净、无在途改动、无会话在跑。本程只做第 2 章波次接线，未开放第 2 章可达性、未实现 Boss 2 独特机制、未做事件区真实自动触发、未改波次内容/敌人美术/战斗框架/言灵/权柄/MDS 插件，未新增移动能力，未删旧世界/旧场景。
- 任务 0 · 基线核验（HEAD `40d1d67`，Godot 4.7.stable.official.5b4e0cb0f，`~/workspace/tools/godot/bin/Godot_v4.7-stable_linux.x86_64`）：
  - `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0。
  - 单元 **7733 / 0**；八套集成全部 0 失败、各日志 `ERROR` 0：结构/可玩性 **601**、第一章 demo **102**、run save **588**、手柄 **207**、UI 提示 **113**、第一章事件 **59**、菜单 A/B **391**、AI 设置 **45**；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与第 32 程收尾逐项一致，无基线漂移。
- 任务 1 · 映射核对（先查后写）：
  - 计划 7 个遭遇 = 6 场战斗 + 1 事件（`ch2_event/event`）；事件节点在扁平 `encounter_ids()` 里位于第 5、6 场战斗之间，**按过滤事件后的战斗顺序**对应 `ROOM_WAVES[1]` 六波（该口径第 32 程已校验，本程用测试锁定）。
  - 逐场落位：`ch2_branch_a/Arena` → 第 1 波、`ch2_branch_a/Arena2` → 第 2 波、`ch2_branch_b/Arena` → 第 3 波、`ch2_well/Arena` → 第 4 波、`ch2_well/Arena2` → 第 5 波、`ch2_elite/Arena` → 第 6 波。六波内容原样复用，包含 `ink_bomber`/`blank_man`/`page_swarm` 等既有敌人 id，未改波次表。
  - 第 1 章现状核对：`chapter_1_demo.tres` 的 `wave` 仍是房间级数组；`game.gd` 第 1 章生成路径（计划 wave 前 2 个立即出场、其余 `queue_wave`）与 `ROOM_WAVES[0]` 一字未改。
- 任务 2 · 计划补 `wave` 键：
  - `chapter_2_demo.tres` 的 4 个战斗区补 `"wave"` 字典，键为遭遇节点 id（`region/Node`），共 6 个键；事件区、Boss 区、入口/枢纽/书库不带 `wave`。Boss 区没有 `encounters`，不消耗普通波次。
  - `ChapterPlanData` 新增 `wave_for(room_id, encounter_id)`：字典按节点 id 查；线性计划仍返回房间级数组（第 1 章兼容）。新增 `validate_waves()`（仅大图计划）并接入 `validate()`：键必须锚定本区遭遇、值必须非空敌人数组、每个战斗遭遇必须有一波、事件遭遇不得有波。ADR：`docs/memory/decisions/2026-11-04-chapter2-wave-wiring.md`。
- 任务 3 · `game.gd` 接线：
  - 新增 `_plan_wave(room_id, encounter_id)`；`_on_mds_room_loaded` 新增 `big_map` 分支：未清战斗遭遇按自己的 `wave` 生成并加入 `_rooms`，一区多遭遇逐场锁门/清怪/奖励/进度（沿用第 27 程节点 id 语义）；事件区与 Boss 区不生成普通波次。第 1 章原分支、`ROOM_WAVES`、奖励与进度未改；第 2 章仍不可达，事件区仍无自动触发点。
  - 前 2 个敌人立即出场、其余 `queue_wave` 的既有节奏保持不变（本计划六波均为 2 人，因此每场一次出场）。
- 任务 4 · 测试与验证（本程末实测，Godot 4.7.stable.official.5b4e0cb0f）：
  - 新增 `tests/test_ch2_waves.gd`（**67** 断言）：六场战斗 ↔ `ROOM_WAVES[1]` 按计划顺序一一对应；事件无波、Boss 无普通波；键唯一且锚定本区；`wave_for` 大图/线性行为；缺失/非字典/空波/空敌人 id/非字符串/事件带波/未知节点/Boss 带波等坏表逐项报错；第 1 章计划仍房间级、`validate_waves()` 为 no-op、清房目标 6。
  - `tests/test_ch2_content.gd` 扩到 **508**（+19）：计划波次表有效、6 个 wave 键与六波逐项相等、事件节点无波、Boss 区无 `wave`。
  - `tests/integration_playability.gd` 扩到 **636**（+35）：逐区检查每个战斗 Arena 的生成数量与敌人种类/顺序与计划波次一致、Arena 已登记；事件 Arena 无敌人且不登记；Boss 区无普通波；支路 A 第二场遭遇单独锁门（第一场不重锁）；清完 7 场后重载支路 A，两场均不再生成、也不再登记。
  - 全量单元 **7819 / 0**（基线 7733 + 86）；八套集成全部 0 失败、各日志 `ERROR` 0：结构/可玩性 **636**、第一章 demo **102**、run save **588**、手柄 **207**、UI 提示 **113**、第一章事件 **59**、菜单 A/B **391**、AI 设置 **45**。退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**；`--import`/`--quit` 退出 0、`ERROR` 0；临时探针未创建；工作区干净。
- 本程未做（按任务单）：第 2 章可达性；Boss 2 独特机制/专属攻击；第 2 章事件区真实自动触发；章节过渡；新敌人/敌人美术/NPC 立绘；二段跳/蹬墙跳/攀爬；MDS 插件；言灵/权柄/战斗框架；删除旧世界/旧场景；打包/导出/安装器/签名/安卓/触屏。
- 提交：`a99d29a`（计划 `wave` + `ChapterPlanData` 校验 + `game.gd` 接线）、`23fdf9e`（`test_ch2_waves` + 内容/集成测试）、`<本提交>`（状态、ADR、session、记忆）。仅本地 `supervisor-dev`，不推送、不更新网页版。

### 2026-11-04 · 第 32 程（第 2 章内容数据层第 1 步：事件 + 权柄池 + Boss 文案）

- 交接：第 31 程收尾 HEAD `23a16a7`；启动时工作区干净、无在途改动、无会话在跑。本程只做第 2 章内容数据层第 1 步（事件数据、按章节路由泛化、权柄池、Boss 入场/阶段文案、遭遇/波次校验），未开放第 2 章可达性、未实现 Boss 2 独特机制与专属攻击、未布置新战斗遭遇、未新增移动能力、未改 MDS 插件/言灵/权柄/战斗框架/敌人美术/NPC 立绘，未删除旧世界或旧房间场景。
- 任务 0 · 基线核验（HEAD `23a16a7`，Godot 4.7.stable.official.5b4e0cb0f，`~/workspace/tools/godot/bin/Godot_v4.7-stable_linux.x86_64`）：
  - `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0。
  - 单元 **7244 / 0**；八套集成全部 0 失败、各日志 `ERROR` 0——结构/可玩性 **581**、第一章 demo **101**、run save **588**、手柄 **207**、UI 提示 **113**、第一章事件 **59**、菜单 A/B **391**、AI 设置 **45**；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与第 31 程收尾逐项一致，无基线漂移。
- 任务 1 · 第 2 章事件数据（`scripts/data/ch2_event_data.gd`，新增）：
  - 7 组「呼吸废墟」事件文案（呼气/钟摆/灯芯/钉子/肺叶/死名/余气），全部围绕剧情圣经第 2 章的肺钟、雾、死者名字与开场里的阿砚灯/钉子，不新增设定、不新增关键道具/NPC 弧线。
  - 机制沿用 `Ch1EventData` 的固定两项：读 → 污染 +8 并解明一个残页词（无词可解则残页 +6）；拿 → 残页 +12。常量与 Ch1 同名（`CORRUPTION_COST`/`PAGES_REWARD`/`FALLBACK_PAGES`），未引入新效果类型。
  - 变体按 `hash(run_seed:event_id)` 固定轮换，键为计划事件节点 id `ch2_event/event`；不消耗 run RNG。第 1 章 `Ch1EventData` 一字未改。
- 任务 2 · 事件路由泛化（`scripts/game.gd`）：
  - 新增 `_event_data(room_id)` 按章节查表：第 1 章仍用 `Ch1EventData.pick(run_seed, room_id)` 与原常量（文案、选项、数值全部不变）；第 2 章用 `Ch2EventData.pick(run_seed, RoomProgress.event_encounter_id(room_id))`。
  - `_open_ch1_event`/`_open_ch1_event_after_transition` 泛化为 `_open_chapter_event`/`_open_event_after_transition`；`_grant_event_word(fallback_pages)` 接收本章兜底残页数（第 1 章传原值 6）。
  - 红线：第 2 章事件页在正常流程仍不自动打开（`_on_mds_room_loaded` 的触发条件仍是 `_chapter == 0`）；第 2 章路由只由 `tests/integration_playability.gd` 直接以 `ch2_event` 驱动验证。后续接线点：第 2 章可达时给事件区加真实触发（当前 `ch2_event` 的 `Event` 节点是 `ArenaRoom`，没有 `Arena` 主节点，`_on_mds_room_loaded` 的 `is_primary` 分支不会命中）。
- 任务 3 · 第 2 章权柄池：
  - `chapter_2_demo.tres` 补 `authority_pool = [续命, 改写]`；条件项不写进池，仍由 `AuthorityController.build_pool` 从 `ContentLibrary` 追加：吞噬（本局污染 ≥ 40）、归档（本局记录 ≥ 2），顺序为 ContentLibrary 顺序（archive → devour）。
  - `_grant_chapter_authority` 的守卫由「仅第 1 章」改为「有计划且池非空」；第 1 章池/行为不变。第 2 章授予只在 `integration_playability` 的 Boss 流程（测试显式启动第 2 章）里验证，正常游玩第 2 章仍不可达。
  - 未发明新权柄机制；现有框架外的构想不写入池，不产生不可用选项。
- 任务 4 · Boss 文案数据：
  - `BossEntranceData` 新增 `CH2_LINES`（8 条，肺钟/雾/钟摆/阿砚钉子），`variants(1)` 返回第 2 章表；第 3–4 章仍为空。
  - `BossPhaseData` 签名向后兼容扩展为 `variants(phase, chapter_index = 0)` / `pick(run_seed, phase, chapter_index = 0)`；新增第 2 章阶段 2/3 各 8 条。第 1 章选句键保持原 `"%d:%d"`（不改变现有句子），第 2 章用 `"%d:%d:%d"`；第 3–4 章返回空（不再回落到第 1 章文案）。
  - `game.gd` 的 `_on_boss_phase` 传 `_chapter`。Boss 名/HP 360/伤害 14/速度 75/立绘 `lung_bell_guardian.png`/`boss_script = ink` 均未改（测试锁定）。
- 任务 5 · 遭遇与波次校验：
  - 新增断言：计划 7 个遭遇节点唯一、全部 `region/Node` 锚定（`validate_regions`/`validate_graph` 为空）；6 个战斗遭遇（事件节点 `ch2_event/event` 除外）与 `ROOM_WAVES[1]` 的 6 波按计划顺序一一对应；每波敌人都有场景与 `resources/enemies/*.tres`；五种第 2 章敌人（`breath_hound`/`lung_moth`/`rust_whisperer`/`choir_summoner`/`collapse_husk`）都在波次中出现。
  - 未新增/改动波次，未给计划加 `wave` 键、未布置敌人（按任务单）。**已知缺口（留给内容程）**：`game.gd` 的计划分支读 `plan_room["wave"]`，第 2 章计划区域尚无该键，因此大区 `Arena` 目前不会生成敌人；接线时按「计划顺序 ↔ `ROOM_WAVES[1]` 顺序」落 `wave` 即可，不需要另起波次表。
- 任务 6 · 测试：
  - 新增 `tests/test_ch2_content.gd`（**489** 断言）：事件 7 组文案/键完整/无占位符、`eyebrow` 不与第 1 章重名；`pick` 稳定、按 seed 轮换、按节点 id 变化、不消耗 run RNG；消息格式化；权柄基础池 = 续命/改写、污染 39/40 与记录 1/2 的条件边界、两种条件同时满足的顺序与去重、第 1 章池不变；Boss 入场/阶段第 2 章表非空、唯一、≤24 字、不含 `%`、不与第 1 章重名、可轮换；第 1 章选句键与旧公式一致；第 3–4 章仍静默；Boss 数值/立绘未改；计划 7 遭遇 + 6 波对应 + 清房目标 7。
  - 更新既有测试：`test_boss_entrance_content`（第 2 章不再静默，第 3–4 章静默）、`test_ch2_plan`（基础权柄池 2 项）、`integration_ch1_demo`（第 2 章入场文案存在、第 3–4 章静默）、`integration_ch1_event`（`_grant_event_word` 显式传兜底值）。
  - `integration_playability` 扩到 **601**（+20）：第 2 章事件区不自动打开第 1 章页；显式驱动第 2 章事件页 → 文案/选项/残页奖励/节点结算正确；第 2 章 Boss 入场与阶段 2/3 文案来自第 2 章表；Boss 击败后按计划池开权柄三选一并成功授予，然后进入章末流程。
- 验证（本程末实测，Godot 4.7.stable.official.5b4e0cb0f）：
  - `--headless --import` / `--quit` 退出 0、`ERROR` 0；全量单元 **7733 / 0**（基线 7244 + 489）。
  - 八套集成全部 0 失败、各日志 `ERROR` 0：结构/可玩性 **601**（+20）、第一章 demo **102**（+1）、run save **588**、手柄 **207**、UI 提示 **113**、第一章事件 **59**、菜单 A/B **391**、AI 设置 **45**。
  - 退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**；临时探针未创建；工作区干净。
- 本程未做（按任务单）：第 2 章可达性；Boss 2 独特机制/专属攻击；新战斗遭遇与计划 `wave` 接线；二段跳/蹬墙跳/攀爬；MDS 插件；言灵/权柄/战斗框架；敌人美术/NPC 立绘；删除旧世界/旧场景；打包/导出/安装器/签名/商店/安卓/触屏。
- 提交：`36b4129`（`Ch2EventData` + Boss 文案 + 计划权柄池 + `game.gd` 路由）、`2f93e48`（`test_ch2_content` + 集成/既有测试更新）、`<本提交>`（状态、ADR、session、记忆）。仅本地 `supervisor-dev`，不推送、不更新网页版。

### 2026-11-04 · 第 31 程（第 2 章大地图施工第 4 步后半：真实大区世界与 region 语义）

- 交接：第 30 程收尾 HEAD `b93fc53`；启动时工作区干净、无在途改动。本程只做第 2 章真实大区世界/房间与 `game.gd` 的 region 语义，未写第 2 章事件文本/权柄池/Boss 机制/敌人波次，未改章节可达性（第 2–4 章仍不可达），未新增移动能力，未改 MDS 插件、言灵/权柄/战斗框架或存档格式，未删除旧世界/旧房间场景。
- 任务 0 · 基线核验（HEAD `b93fc53`，Godot 4.7.stable.official.5b4e0cb0f，`~/workspace/tools/godot/bin/Godot_v4.7-stable_linux.x86_64`）：
  - `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0。
  - 单元 **6517 / 0**；八套集成 结构 **392**、第一章 demo **101**、run save **588**、手柄 **207**、UI 提示 **113**、第一章事件 **59**、菜单 A/B **391**、AI 设置 **45**，全部 0 失败、各日志 `ERROR` 0；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与第 30 程逐项一致，无基线漂移。
- 任务 1 · 真实大区世界与房间（独立文件，旧世界保留）：
  1. **9 个 `BigRoomData`**（`resources/rooms/ch2_bigmap/*.tres`）：按计划 2560×1440 / 2560×2160 / 3840×2160；地面贴房间底边（`H-16`，16 px 厚），平台按 80 px 阶梯链，满足第 28 程校验（垂直 ≤80 px、水平边缘 ≤120 px，只有最低面豁免支撑）；复用 `ch1_tiles.tres`，`breathing_ruins.png` 绘画背景（`backdrop_pixel_art = false`）、按区 `backdrop_modulate`、`motes`/`embers` 氛围。
  2. **9 个 `MDSBigRoom` 场景**（`scenes/mds/ch2_bigmap/*.tscn`）：`fall_margin = 240.0`；内容节点按计划 id 命名（`Arena`/`Arena2`、`Chest1/2`、`Stele1/2`）；事件区节点 `Event` 作者 `encounter_id = ch2_event/event`；枢纽商店 `ch2_hub_shop` + 长椅 + 残碑 + 电梯；纵井 2 场 + 1 箱 + 3 单向落台 + 电梯；入口作者到达门 `shortcut_arrival`（TOUCH、无 `to`）。
  3. **独立世界** `scenes/mds/chapter_2_bigmap.mdsworld.json` + `chapter_2_bigmap_world.tscn`：9 区、单矩形、原点 32 px 对齐；`start_room = ch2_entry`；区域 `Breathing Ruins` 带雾 + 萤火、背景与 `boss_background: spore_drift`；20 扇有向门 + 2 扇只到达门；2 扇显式单向（`elite_boss`、带 `requires = ["ch2_shortcut"]` 的 `hub_shortcut_entry`）；侧门在地面上方 90 px、底门在地面线、顶门在上边缘，电梯列避开平台；房间不重叠、双向门相邻、捷径刻意不相邻。
  4. **旧世界保留**：`chapter_2.mdsworld.json`、`chapter_2_world.tscn` 与 9 个 `ch2_*.tscn` 未改、未删，只是不再被 `game.gd` 引用；测试夹具 `tests/fixtures/big_room/ch2_graph.mdsworld.json` 仍为 `fixture: true`、无 `scene_path`、永不加载，并镜像真实世界门位/尺寸。
- 任务 2 · `game.gd` 接计划（region 语义）：
  - 新增 `CHAPTER_PLAN_PATHS`：第 1 章 `chapter_1_demo.tres`、第 2 章 `chapter_2_demo.tres`、第 3/4 章留空（继续 `CampaignData.rooms` + `ROOM_WAVES`）。
  - 第 2 章世界/场景常量切到 `chapter_2_bigmap_world.tscn` / `chapter_2_bigmap.mdsworld.json`；`_start_mds_chapter` 加载计划，新局起始区 = `start_room`（`ch2_entry`），无计划回退 `chN_01`。
  - 坠落平面走第 27 程解析链：计划 `fall_below_bounds`（`size.y + 240`）→ 房间 metadata → 默认 850；纵井/精英/Boss 平面 2400，下层平台 y≈1500–2100 不被误杀。
  - 清房目标 = 计划派生 7（支路 A 2 + 支路 B 1 + 纵井 2 + 精英 1 + 事件 1），HUD 分母 8（含 Boss）；第 1 章仍 6/7。
  - 宝箱/残碑/遭遇按 `region/Node` 节点 id 结算，一区多内容各自独立；事件页仍只属于第 1 章（`_chapter == 0`）。
  - **红线**：第 1 章 9 个 `MDSChapterRoom`、原世界 JSON、波次/进度/结算/章末 `_finish(true)` 未改；第 2 章仍不可达，第 1 章结束不自动进入第 2 章。
- 任务 3 · 测试：
  - 新增 `tests/test_ch2_world.gd`（**727** 断言）：真实世界 ↔ 计划逐区形状/内容/门/坠落/区域；世界图入口 BFS 全可达（含枢纽/隐藏书库/Boss）；20+2 门与 2 扇单向；房间不重叠、双向门相邻、捷径不相邻；9 个场景为 `MDSBigRoom` 且 `BigRoomData` 校验为空、尺寸/瓦片/背景/氛围/坠落余量/底边地面；内容节点与作者事件 id；顶门房间电梯列避开平台；夹具隔离且 `game.gd` 不引用；旧第 2 章 9 个 1280×720 `MDSChapterRoom` 与第 1 章 9 房/计划 6 目标不变；`game.gd` 四个世界/场景/计划槽位与第 1、3、4 章条目不变。
  - `tests/integration_playability.gd` 扩到 **581**（+189）：第 2 章从 `ch2_entry` 开始、坠落 1680、目标 7/分母 8；9 区加载与校验；枢纽商店/长椅/捷径屏障解锁并存档；纵井 y≈2100 下层不掉血；书库两箱两碑按节点结算且重载后保留未领取内容；事件区不打开第 1 章事件页；精英 → Boss 单向；支路 A 两场各自计数、重复 `cleared` 不重复结算；补满 7 场后 Boss → 章末 → 选择 → 第 3 章；第 1 章结束仍不进入第 2 章。
- 验证（本程末实测，Godot 4.7.stable.official.5b4e0cb0f）：
  - `--headless --import` / `--quit` 退出 0、`ERROR` 0；全量单元 **7244 / 0**（基线 6517 + 727）。
  - 八套集成全部 0 失败、各日志 `ERROR` 0：结构/可玩性 **581**（+189）、第一章 demo **101**、run save **588**、手柄 **207**、UI 提示 **113**、第一章事件 **59**、菜单 A/B **391**、AI 设置 **45**。
  - 退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**；临时探针 `tests/probe_ch2map32.gd`、`tests/probe_ch2world32.gd` 用完删除；工作区干净。
- 本程未做（按任务单）：第 2 章事件文本/权柄池/Boss 机制/敌人波次；章节可达性；二段跳/蹬墙跳/攀爬；MDS 插件修改；言灵/权柄/战斗框架；敌人美术/NPC 立绘；删除旧世界/旧场景；打包/导出/安装器/签名/商店/安卓/触屏。
- 提交：`ea68f3a`（真实大区世界 + 9 房间场景）、`767ffaf`（`game.gd` 计划加载/region 语义）、`852606c`（世界/计划单元测试 + 可玩性集成 + 夹具镜像）、`<本提交>`（状态、ADR、session、记忆）。仅本地 `supervisor-dev`，不推送、不更新网页版。

### 2026-11-04 · 第 30 程（第 2 章大地图施工第 4 步前半：第 2 章计划与大区图骨架）

- 交接：第 29 程收尾 HEAD `2560f29`；启动时工作区干净、无在途改动、无会话在跑。本程只做第 2 章计划数据与大区连通图骨架（数据层），未创建/重排第 2 章实际房间场景、未改第 2 章世界 JSON、未写第 2 章事件/权柄/Boss 内容、未改章节可达性、未新增移动能力，未改 MDS 插件本体、言灵/权柄/战斗框架或存档格式。
- 任务 0 · 基线核验（Godot 4.7.stable.official.5b4e0cb0f）：
  - 干净 `2560f29` worktree：`--import` 退出 0、`ERROR` 0；单元 **5861 / 0**，与第 29 程收尾逐项一致。
  - 本工作区：`--headless --import` / `--quit` 退出 0、`ERROR` 0；八套集成 0 失败、各日志 `ERROR` 0——结构 **392**、第一章 demo **101**、run save **588**、手柄 **207**、UI 提示 **113**、第一章事件 **59**、菜单 A/B **391**、AI 设置 **45**；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与第 29 程一致，无基线漂移。
  - 操作注记：Godot 4.7 下用位置参数 `tests/run_tests.gd` 会把脚本当主场景并挂起（无输出、不退出）；正确入口是 `--headless --path . --script res://tests/run_tests.gd`。后续会话按此调用。
- 任务 1 · 第 2 章计划数据（`ChapterPlanData` + 计划资源，未接入 `game.gd`）：
  1. **`ChapterPlanData` 向后兼容扩展**：`big_map` / `start_room` / `doors`；region 条目新增 `size` / `encounters` / `chests` / `steles` / `shortcuts` / `hidden` / `shop` / `rest` / `vertical`。`clear_target()` 对带 `encounters` 的计划按遭遇节点数派生，第 1 章（无该键）仍按房型得 **6**。新增 `validate_regions()` / `validate_graph()`：尺寸为整屏 1280×720 的 1–3 倍、坠落平面低于本区底边、`region/Node` 节点 id 锚定且全区唯一、门位同房唯一、门对唯一、单向显式、捷径必须有 `requires`、图形态（恰一入口/枢纽/Boss、≥2 支路、纵井/精英/事件/隐藏区各至少一、枢纽含休整+商店+残碑+捷径、至少一个环）、入口有向 BFS 必须到达全部大区。
  2. **`resources/chapters/chapter_2_demo.tres`**：9 区——入口 `ch2_entry` → 支路 `ch2_branch_a` / `ch2_branch_b` → 枢纽 `ch2_hub` → 纵井 `ch2_well`（2560×2160）→ 事件 `ch2_event` / 精英 `ch2_elite` → Boss `ch2_boss`；`ch2_vault` 为支路下的隐藏书库（2 箱 2 碑）。尺寸 2560×1440 / 2560×2160 / 3840×2160，均在 1–3 屏内。清房目标派生 **7**（支路 A 2、支路 B 1、纵井 2、精英 1、事件 1）；宝箱 5、残碑 5，全部 `region/Node` 节点 id，一区多内容各自结算。每区 `fall_below_bounds = 240`，坠落平面低于整区底边，纵井下层不会被误杀。11 扇门，其中 2 扇显式单向：`elite_boss`（Boss 区单向进入）与 `hub_shortcut_entry`（枢纽 → 入口，`requires = ["ch2_shortcut"]`）。
  3. **计划暂不加载**：第 2 章现有世界仍是 `ch2_01`…`ch2_boss` 旧 9 小房间，region id 与新图不同；现在接入会把波次/进度指向不存在的房间。等真实大区世界/房间场景落地后再接 `_start_mds_chapter` / `_on_mds_room_loaded`，本程用测试验证计划本身。
- 任务 2 · 大区图骨架与夹具：
  - `tests/fixtures/big_room/ch2_graph.mdsworld.json`：顶层 `fixture: true`、无 `scene_path`、永不加载，明确是测试资产不是章节内容；以 MDS 世界形状镜像 9 个房间矩形/原点/类型/门/内容 id。
  - `tests/test_ch2_plan.gd`（**656** 断言）：计划形状/类型/尺寸/坠落平面/节点 id 唯一与锚定/清房目标 7；图 BFS 全可达（含枢纽/隐藏书库/Boss）、双向/单向门、无孤立区、无重复房对；夹具 ↔ 计划逐项一致、门位在对应边、房间不重叠且双向门相邻、清房目标 = 图上遭遇总数；坏计划（孤立区/坏尺寸/缺坠落平面/缺 encounters/重复宝箱 id/未锚定 id/未知大区/重复门位/重复房对/捷径缺 requires）逐项报错；第 1 章计划仍 9 房、清房目标 6、无图、校验为空。
- 验证（本程末实测，Godot 4.7.stable.official.5b4e0cb0f）：
  - `--headless --import` / `--quit` 退出 0、`ERROR` 0；全量单元 **6517 / 0**（基线 5861 + 656）。
  - 八套集成全部 0 失败、各日志 `ERROR` 0：结构 **392**、第一章 demo **101**、run save **588**、手柄 **207**、UI 提示 **113**、第一章事件 **59**、菜单 A/B **391**、AI 设置 **45**（与第 29 程逐项一致，无回归）。
  - 退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**；临时探针未创建；工作区干净。
- 本程未做（按任务单）：第 2 章实际房间/世界 JSON/事件文本/权柄池/Boss 机制/敌人美术；章节可达性（第 2–4 章仍不可达）；二段跳/蹬墙跳/攀爬；MDS 插件修改；言灵/权柄/战斗框架；打包导出/安装器/签名/安卓/触屏。
- 提交：`9d8cacc`（`ChapterPlanData` 大图字段 + 校验）、`3ba2cc4`（第 2 章计划 + 图夹具 + 单元测试）、`<本提交>`（状态、ADR、session、记忆）。仅本地 `supervisor-dev`，不推送、不更新网页版。

### 2026-11-04 · 第 29 程（第 2 章大地图施工第 3 步：纵向/捷径道具管线）

- 交接：第 28 程收尾 HEAD `ee0c720`；启动时工作区干净、无在途改动。本程只做可复用的关卡道具管线，未创建/调整第 2 章地图、房间、世界 JSON、房间计划、事件、权柄或 Boss 内容，未改章节可达性，未新增移动能力（不加二段跳/蹬墙跳/攀爬），未改 MDS 插件本体、言灵/权柄/战斗框架或存档格式。按 `.supervisor/DECISIONS.md`：第 9 项大区连通图、第 10 项 A 不新增移动能力。
- 任务 0 · 基线核验（HEAD `ee0c720`，Godot 4.7.stable.official.5b4e0cb0f）：
  - `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0。
  - 单元 **5779 / 0**；八套集成 结构 **351**、第一章 demo **101**、run save **561**、手柄 **207**、UI 提示 **113**、第一章事件 **59**、菜单 A/B **391**、AI 设置 **45**，全部 0 失败、日志 `ERROR` 0；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与第 28 程逐项一致，无基线漂移。
- 任务 1 · 纵向/捷径道具管线（新增，第 1 章不迁移）：
  1. **单向落台 `OneWayPlatform`**（`scripts/levels/one_way_platform.gd`，StaticBody2D）：`size` 左上角即行走面；层 1、无掩码；`one_way_collision`（margin 2）上方可站、下方跳跃穿过。站立时按「下 + 跳」，`player.gd` 只做一次薄片形状查询并对该平台开 0.3 s 碰撞例外，玩家落下去；不新增按键、不改 `jump_velocity`/`gravity`；实心地面上「下+跳」仍是普通跳跃（第 1 章手感不变）。`drop_through=false` 可关。
  2. **塌陷平台 `CollapsingPlatform`**（StaticBody2D）：`IDLE → WARNING → FALLING → GONE → IDLE`。站立检测用上方 Area2D（掩码 1、只认 `player` 组）；预警期颜色/裂纹/抖动（`warn_time`），随后关碰撞、视觉下落（`fall_time`）、隐藏并在 `respawn_time` 后复位。`advance(delta)` 公开可确定性驱动。`game.gd` 在坠落回退与玩家死亡时对组内调用 `reset_now()`；不改第 27 程坠落平面解析链（章节计划 → 房间 metadata → 默认 850）。
  3. **移动平台/电梯 `MovingPlatform`**（AnimatableBody2D，`sync_to_physics`）：`travel` 相对作者位置，水平/垂直/斜向；`speed`/`pause_time`/`start_delay`/`ping_pong` 可配；站立玩家由现有 CharacterBody2D 平台逻辑承载，不新增控制器、不改玩家参数。`MDSBigRoom.build()` 用 `set_room_bounds()` 把并集交给子道具，`travel` 越界收紧（`effective_travel`/`travel_clamped`），作者位置本身在并集外时原地不动（`outside_bounds`）；相机限制仍由 MDS 按同一并集设置。
  4. **长椅检查点 `BenchCheckpoint`**（Node2D）：交互半径 96 px、`interact` 触发，`respawn_position()` = 长椅地面锚点 - 16 px（玩家脚底偏移）。`game.gd` 在商店/宝箱/拾取之后、残碑之前检查长椅：更新 `_last_checkpoint`、清零速度、HUD 提示、调用现有 `save_run_now()`。**不新增存档键、不改版本**；run save 仍写 `run/world/mds` 同一结构，旧档安全。第 1 章无长椅，进房设检查点代码未改。
  5. **捷径（条件门）**：世界 JSON 门带 `requires` 时，`MDSBigRoom` 在自动生成 `MDSGate` 的同时生成同名 `MDSGateBarrier`（作者门优先、不重复生成）；开门条件与状态复用 MDS 既有机制并进 MDS 存档，跨房间/跨存档保留。不新增可破坏墙运行时脚本。
- 验证（本程末实测，Godot 4.7.stable.official.5b4e0cb0f）：
  - `--headless --import` / `--quit` 退出 0、`ERROR` 0；单元 **5861 / 0**（基线 5779 + 82）。
  - 八套集成全部 0 失败、各日志 `ERROR` 0：结构 **392**（+41）、第一章 demo **101**、run save **588**（+27）、手柄 **207**、UI 提示 **113**、第一章事件 **59**、菜单 A/B **391**、AI 设置 **45**。
  - 退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**；临时探针未创建；测试夹具 `tests/fixtures/big_room/` 为永久测试资产（非章节内容）；工作区干净。
  - 覆盖：单向落台上落/下+跳下落/下方跳跃穿过/实心地面下+跳仍是跳跃；塌陷平台预警（进度+抖动）/塌落/落地不掉血/复位；垂直电梯与水平渡船承载玩家且不滑落、行程在房间并集内、越界行程截断；条件门生成/需求/解锁/存档；长椅交互更新检查点并写 run save（版本不变）、坠落回退到长椅、坠落时塌陷平台整组复位、续玩回到长椅附近；第 1 章 9 个房间场景仍走 `MDSChapterRoom` 且不含任何新道具。
- 本程未做（按任务单）：第 2 章地图/房间/世界 JSON/房间计划/事件/权柄/Boss/敌人美术；章节可达性；二段跳/蹬墙跳/攀爬；可破坏墙；言灵/权柄/战斗框架；MDS 插件修改；打包导出/安装器/签名/安卓/触屏。第 2–4 章仍不可达，Boss 2–4 机制未做。
- 提交：`e79ff83`（道具脚本 + 单元测试）、`873df50`（game/player/MDS 接线 + 集成测试 + 夹具）、`<本提交>`（状态与记忆）。仅本地 `supervisor-dev`，不推送、不更新网页版。

### 2026-11-04 · 第 28 程（第 2 章大地图施工第 2 步：房间生产管线）

- 交接：第 27 程收尾 HEAD `3db07f0`；启动时工作区干净、无在途改动。本程只做管线，未创建/调整第 2 章地图、房间、世界 JSON、房间计划、事件、权柄或 Boss 内容，未改可达性，未新增移动能力，未改 MDS 插件本体。
- 任务 0 · 基线核验（HEAD `3db07f0`，Godot 4.7.stable.official.5b4e0cb0f）：
  - `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0。
  - 单元 **5706 / 0**；八套集成 结构 **296**、第一章 demo **101**、run save **561**、手柄 **207**、UI 提示 **113**、第一章事件 **59**、菜单 A/B **391**、AI 设置 **45**，全部 0 失败、日志 `ERROR` 0；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与第 27 程逐项一致，无基线漂移。
- 任务 1 · 房间生产管线（新增，第 1 章不迁移）：
  1. **`BigRoomData`（`scripts/levels/big_room_data.gd`，Resource）**：`size` 仅是无 MDS 父节点时的后备；MDS 世界里以房间局部矩形并集为准。`ground` 为 `{x, y, width, height=64}`（多层地面 = 不同 `y` 的地面条目），`platforms` 为 `{x, y, width}`（固定 16 px 厚）。有 `tile_set` 时按 16 px 网格吸附，否则灰盒。可达性校验：越界/坏字段/非正宽高/无下方支撑的悬空平台；每个表面到其攀爬来源面的上升 ≤ **80 px**（现有跳跃顶点约 92.6 px，`jump_velocity=-500`、`gravity=1350`），水平边缘距离 ≤ **120 px**。
  2. **`MDSBigRoom`（`scripts/levels/mds_big_room.gd`，Node2D）**：读取父 `MDSWorldGame` 的当前房间局部矩形并集、区域、天气/动态背景/视差；相机限制仍由 MDS `apply_camera_limits` 按并集设置。地面/平台视觉用 `TileMapLayer`（`collision_enabled=false`），碰撞用每段一个 `StaticBody2D` + `RectangleShape2D`（大房间不产生每格碰撞体）。静态背景按并集宽度平铺（2560 宽 2 列、3840 宽 3 列），图源按 蓝图 → MDS 房间 → 区域 → 世界 `backdrop_image` 解析；像素图 nearest、绘画图 linear。`auto_gates=true` 时按世界 JSON `gates` 生成 `MDSGate`（TOUCH/INTERACT、侧向形状、门提示），同名作者门优先。房间 metadata 写入 `fall_below_bounds = 200`，接第 27 程坠落平面解析链（章节计划仍优先）。
  3. **`BigRoomAmbient`（`scripts/presentation/big_room_ambient.gd`，Node2D）**：`motes` 横漂 / `embers` 上升，只绘制相机窗口与房间并集的交集（外加 64 px 余量），默认取 MDS 区域色；默认关闭，不复制 MDS 天气。
  4. **第 1 章零迁移**：`MDSChapterRoom`、`ch1_layout.tres`、9 个 `ch1_*.tscn` 一字未改；新管线按场景 opt-in，单元测试逐场景断言 9 个第一章房间仍是旧构建器，`WIDTH=1280`、`FLOOR_Y=560` 不变。
- 验证（本程末实测，Godot 4.7.stable.official.5b4e0cb0f）：
  - `--headless --import` / `--quit` 退出 0、`ERROR` 0；单元 **5779 / 0**（基线 5706 + 73）。
  - 八套集成全部 0 失败、日志 `ERROR` 0：结构 **351**（基线 296 + 55）、第一章 demo **101**、run save **561**、手柄 **207**、UI 提示 **113**、第一章事件 **59**、菜单 A/B **391**、AI 设置 **45**。
  - 退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**；临时探针未创建；测试夹具 `tests/fixtures/big_room/` 为永久测试资产（非章节内容）；工作区干净。
  - 全量套件在功能终稿上跑完后，仅把 `_build_backdrop` 的局部变量 `scale` 改名为 `tile_scale`（消除对 `Node2D.scale` 的遮蔽），重跑单元与结构集成仍 **5779 / 0**、**351 / 0**；其余七套不加载该文件，未重跑。
- 本程未做（按任务单）：第 2 章地图/房间/世界 JSON/计划/事件/权柄/Boss/敌人美术、章节可达性、移动能力、移动/塌陷/单向平台、MDS 插件修改。待用户确认第 9/10 项保持开放，管线对「大区图 + 短过渡」与「字面单场景无缝」两种口径都成立（房间仍是 MDS 加载单元），且未新增任何移动能力。
- 提交：`311b843`（管线脚本 + 单元测试）、`eac7b20`（结构集成 + 夹具）、`<本提交>`（状态与记忆）。仅本地 `supervisor-dev`，不推送、不更新网页版。

### 2026-11-04 · 第 27 程（第 2 章大地图施工第 1 步：基础解耦）

- 交接：第 26 程绿基线 `13b4230`；第 27 程首启因 Magpie 网关不通（`ECONNREFUSED`）无产出，本程为原任务单重试。启动时工作区干净、无在途改动。
- 任务 0 · 基线核验（HEAD `13b4230`，Godot 4.7.stable.official.5b4e0cb0f）：
  - `--headless --path . --import` / `--quit` 退出 0、`ERROR` 0。
  - 单元 **5645 / 0**；八套集成 结构 **269**、第一章 demo **81**、run save **541**、手柄 **207**、UI 提示 **113**、第一章事件 **59**、菜单 A/B **391**、AI 设置 **45**，全部 0 失败、各日志 `ERROR` 0；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与第 26 程逐项一致，无基线漂移。
  - 说明：gamepad 起的四套首次运行与本会话的编辑重叠，结果不计；改在 `git worktree` 的干净 `13b4230` 副本重跑（`/tmp/ch27_head_logs`），数字与第 26 程一致后才开始施工。
- 任务 1 · 三项基础解耦（未改第 2 章地图/世界 JSON/可达性，未新增移动能力）：
  1. **坠落平面按房间/区域配置**：`game.gd` 的固定 `fall_y > 850.0` 改为 `> _fall_limit_local`；房间加载时 `_resolve_fall_limit()` 依次读章节计划房间键 `fall_y`（房间局部绝对 y）或 `fall_below_bounds`（房间并集底边以下）→ 房间节点 metadata 同名键 → `ChapterPlanData.DEFAULT_FALL_Y = 850`。第 1 章计划 9 个房间均未配置，仍 850；无计划的第 2–4 章同样 850。断言覆盖默认/两种配置/非法值/优先级，以及第 1 章 850 坠落与伤害（含难度倍率）、配置 2000 时 y=1200 不误杀、y=2001 才回退。
  2. **一次性内容与清场进度按节点 id**：新增 `RoomProgress`（`scripts/core/room_progress.gd`），id 取作者 `content_id`/`encounter_id`，否则 `room_id/节点名`，同房重名用 `#2`/`#3` 唯一化；旧 room-key 记录经 `is_recorded()` 兼容回退。`_cleared_encounters` 取代 `_mds_cleared_rooms`；宝箱/残碑/遭遇分别用 `TreasureChest.content_id`、`MemoryStele.content_id`、`ArenaRoom.encounter_id`。房间加载时收集全部直接子 `ArenaRoom`，逐个接线、禁用 `Enemies` 处理并按键记录；`Arena` 仍是主节点，保留事件/Boss/计划波次/房间级文案。存档新增可选键 `progress.cleared_encounters`、`world.claimed_stele_ids`、`world.opened_chest_ids`；旧键 `cleared_rooms`/`claimed_steles`/`opened_chests` 读入 `_legacy_*` 并原样写回，**不从新进度反推旧键**，旧档不判坏档、不丢档。第 1 章单房单内容与基线一致（`ch1_01/Arena`、`ch1_03/Chest`、`ch1_vault/Chest`、`ch1_vault/Stele`、`ch1_rest/Stele`、`ch1_05/event`）。
  3. **章节清房目标读计划**：`ChapterPlanData.clear_target()` 默认统计 `combat`/`elite`/`event` 房型（第 1 章 = 6），`clear_target_override` 可覆盖；`game.gd` 的上限判断、HUD 分母（目标 + Boss）、奖励种子、改写房号全部改读目标；无计划章节回退 6。第 1 章仍 6 / 7，数值与基线一致。
- 验证（本程末实测，Godot 4.7.stable.official.5b4e0cb0f；提交见下方记录）：
  - `--headless --import` / `--quit` 退出 0、`ERROR` 0；单元 **5706 / 0**（+61）。
  - 八套集成全部 0 失败、各日志 `ERROR` 0：结构 **296**（+27）、第一章 demo **101**（+20）、run save **561**（+20）、手柄 **207**、UI 提示 **113**、第一章事件 **59**、菜单 A/B **391**、AI 设置 **45**。
  - 退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**；临时探针 `tests/probe_fall27.gd` 用完删除；工作区干净。
- 本程未做（按任务单）：第 2 章地图/房间计划/事件/权柄/Boss/世界 JSON、章节可达性、移动能力、移动/塌陷平台、敌人美术；「待用户确认」第 9/10 项保持开放，本步解耦不依赖任一选项。
- 提交：`d01aebc`（数据/存档/单元测试）、`3e6773b`（`game.gd` 接线/集成测试）、`<本提交>`（状态与记忆）。仅本地 `supervisor-dev`，不推送、不更新网页版。

### 2026-11-04 · 第 26 程（第 2 章大地图可行性核查）

- 任务 0 · 基线核验（HEAD `253c18e`，Godot 4.7.stable.official.5b4e0cb0f，本机 `~/workspace/tools/godot/bin/Godot_v4.7-stable_linux.x86_64`）：
  - `--headless --path . --import` 退出 0、`ERROR` 0；`--headless --path . --quit` 退出 0、`ERROR` 0。
  - 单元 `tests/run_tests.gd` **5645 / 0**，`ERROR` 0。
  - 八套集成全部 0 失败且各日志 `ERROR` 0——结构 **269**、第一章 demo **81**、run save **541**、手柄 **207**、UI 提示 **113**、第一章事件 **59**、菜单 A/B **391**、AI 设置 **45**。
  - `tests/check_exit_clean.sh <godot> 10` → **10/10 clean**；demo 像素资产 **36 / 0**。
  - 与第 25 程收尾数字逐项一致，无基线漂移、无回归，可以进入核查。
- 任务 1 · 第 2 章大地图可行性核查（只查不施工）：完整结论写入上方「第 2 章大地图可行性核查」专节，按【已核实】/【推断】/【待施工验证】分列。
  - 读代码/资源：MDS 世界/房间/门/相机/地图/存档运行时（`addons/MetroidvaniaDeveloperSystem/`）、`game.gd` 的房间接线与存档、第 2 章 `chapter_2_world.tscn` / `chapter_2.mdsworld.json` / 9 个 `ch2_*.tscn`、`CampaignData` 第 2 章条目、Boss/敌人/语音/事件/权柄代码路径、旧线性 `biome_breathing.tscn`（已隐藏的 fallback）。
  - 临时探针 `tests/probe_ch2map.gd` + `tests/_probe_ch2map/`（合成大房间/L 形房间/上下门 + 真实第 2 章世界逐房加载）：**53 / 0**。实测 3840×1440 房间加载 1.3–3.1 ms、L 形 2560×2160 并集边界正确且缺口不可行走、top/bot 门向与 bot 出速 -650 正确、无缝跨房 1.6–6.1 ms 且相机限制跟随；真实第 2 章 9 房全部加载，热加载 3.7–8.8 ms（Boss 房约 23 ms，`spore_drift` 动态背景）。探针为测试夹具，测后随本程删除，不留在仓库。
  - 关键结论：MDS 承载力足够，不需要重写；施工面在房间生产管线与 `game.gd` 的“一房一战斗/一房一拾取/固定 6 房进度/850 px 坠落保护”假设。第 2–4 章仍不可达；本程未改任何产品代码、场景、资源或存档格式。

### 2026-11-04 · 第 25 程（T17 任务 2–4）

- 交接：第 24 程收尾时 T17 任务 2（吞噬/归档）留有 10 个已改文件 + 1 个未跟踪 UI 未提交。本程先用 `git status` / `git diff` 逐份核实：数据、控制器、玩家/武器倍率、死亡弹窗与存档兼容均已半成，但 `game.gd` 仍引用未实现的 `_apply_archived_item` / `_refresh_codex_authority`，无法解析。补齐后自洽，未丢弃或回滚任何在途改动。
- 任务 1 · 吞噬/归档（提交 `5f30d14`）：
  - 数据：`AuthorityData` 新增 `unlock_condition` / `unlock_threshold`；归档（本局记录 ≥ 2）、吞噬（污染 ≥ 40）由 `AuthorityController.build_pool` 追加进 Boss 权柄池并按作者顺序去重。
  - 效果：吞噬 `1 + 污染 × 0.006`（上限 1.6）实时作用于近战/远程武器与短语；归档在最终死亡时**先提交死亡并清掉局内检查点**，再弹一次物品选择，武器替换起始武器、遗物进入下一局背包并加污染，两个初始武器不进入候选。
  - 兼容：`RunSave` 的 `archive_used` 与 `Profile` 的 `archived_item` 均为可选键，旧检查点/旧档缺键默认安全，坏类型丢弃；归档弹窗暂停树、吞掉 Start/B、HUD 立即隐藏。
  - 测试：新增 `test_archive_authority`（101）、扩展 `test_weapons` / `test_run_save` / `test_profile_v2`；`integration_ch1_demo` +14、`integration_run_save` +46。
- 任务 2 · 信任分层（提交 `3652a78`）：
  - `TrustData` 从既有 `Profile.npc_trust` 派生 4 档（陌生/熟悉/信任/托付，阈值 0/2/6/12），**不新增存档键**；折扣取 `max(既有祝福, 档位)`，档位 0/5/10/15%，不叠加；阿砚托付每次回 Hub 第一次锻造免费（与 `forge_free` 互斥消耗）；新局按每 NPC 档位加残页（0/1/3/6），与言灵起始页共用 20 页上限。
  - 对话：每 NPC 每档一句态度，`talk_to_npc` 插在问候后；离线 `NPCProfiles.resolve(..., trust)` 在熟悉以上附加同档态度并调暖 mood；AI system prompt 由 Hub 注入当前档位与态度。
  - AI 纪律不变：默认关闭、失败静默回退离线、每 NPC 每次回 Hub 只结算一次、不双叠。
  - 测试：新增 `test_trust_tiers`（111）；`integration_menus` +11、`integration_run_save` +1（起始残页上限 20）。
- 任务 3 · 结局画廊（提交 `d224769`）：
  - `CampaignData.ENDINGS` 统一五个结局（GDD §12.2 顺序：复原/焚毁档案/深渊回响/未完的注脚/记录中断），`ending_for` 只做 id 选择；`EndingGalleryUI` 只读 `Profile.endings` 字符串 id，未解锁为「？？？/尚未记录」占位，旧档未知 id 保留但不展示。
  - 标题页新增「结局画廊」按钮：A 打开、B 关闭、焦点归还按钮，弹窗内方向键/Tab 焦点锁在关闭按钮上，标题暂停时仍可操作。
  - 测试：新增 `test_ending_gallery`（69）；`integration_menus` +8（含焦点锁）。
- 任务 4 · 验证（HEAD `cdcf273`，Godot 4.7.stable.official.5b4e0cb0f）：
  - `--headless --import` 与 `--quit` 退出 0、`ERROR` 0；全量单元 **5645 / 0**；八套集成 **269 / 81 / 541 / 207 / 113 / 59 / 391 / 45**，全部 0 失败、各日志 `ERROR` 0；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。
  - 测试稳健性补丁（`cdcf273`）：`integration_ch1_demo` 的休息室残碑奖励使用全局随机，若 roll 到已拥有遗物会走「残碑已读过」分支（不回记录），旧断言偶发失败。改为按实际分支校验记录数与文案，断言数仍为 81；产品逻辑未改。
  - 本程只本地提交，不 push GitHub、不更新网页版；打包/导出/安装器/签名/Android/触屏均未做。

### 2026-11-04 · 第 24 程（T17）

- 任务 0 · 基线核验（HEAD `4c425a8`，Godot 4.7.stable.official.5b4e0cb0f）：
  - import / quit 退出 0、`ERROR` 0；单元 **5354 / 0**；八套集成 **269 / 67 / 494 / 207 / 113 / 59 / 372 / 45**，全部 0 失败、各日志 `ERROR` 0；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。与第 23 程收尾数字逐项一致，无回归。
  - 首次并行执行时误启动了两份基线脚本，两个 `integration_run_save` 进程争用同一临时存档路径，产生过一批 34 条假失败；确认是我方进程卫生问题（孤儿进程）后清理并串行重跑，干净结果如上。产品代码、测试与存档格式均未改动。
- 任务 1 · 叙事审计（只查不写）：新增上方「叙事审计」小节。核查结论：五名 NPC 都只有静态来历 + 闲聊 + 关键词回应，无个人弧线事件/关键道具/结局收束；闻烬与白榆在 demo 中不可见；第 2–4 章的开场/章末/选项文本、Boss 名与语音、9 房间 MDS 世界均已存在但正常流程不可达，且没有第一章式房间计划与事件内容；五个结局的标题/正文/语音/判定/Profile 记录都已有，但复原与焚毁在 demo 不可达，且正文没有逐 NPC 余味；信任只有原始 float 存档与写入，没有任何分层或读取方。缺口按「本程任务 3/4」与「后续叙事扩展」分开列出，未撰写新剧情正文。

### 2026-11-04 · 第 23 程

- 交接：第 22 程只提交了基线复核（`4c99907`），任务 1 中断且无交接报告；本程以 git diff 与残留文件本身为准逐份核实，未采信任何口头结论。起始 HEAD `4c99907`，工作区含 8 个已改文件、`empty_state_data` 与 4 个未跟踪探针/基准。
- 任务 0 · 残局核实与处置（Godot 4.7.stable.official.5b4e0cb0f）：
  - `probe_focus22` **82/82**：章末完成页/选择页的真实键盘与手柄路径（E/Start 推进、Esc/B 被吞、方向键/D-pad 焦点、Enter/A 确认、结局屏返回焦点）、Hub 训练碑三步与图鉴冻结/解冻、标题设置 Start/Esc 关闭与 AI 子页分层。未发现产品缺陷。
  - `probe_exit22` **55/55**：Hub 档案馆面板打开时退出（升级已持久化、Hub 不写 run 检查点、重启面板关闭且玩家可动）、训练碑中途退出（教学从第 1 步重放、无残留短语/伤害、不误记完成；完成后 `tutorial_done` 持久化且不再重放）、标题设置 + AI 子页退出（Profile 与碎片不变、无检查点/输入捕获）。未发现产品缺陷，未改产品代码。
  - `probe_choice_cost22`：选择项文字入树前赋值 **14.687 ms/项**、入树后 **0.330 ms/项**（两项页约 29 ms → 0.7 ms）。
  - `bench_ui22`（修复后）：Hub 对话打开 0.879 ms、逐句 0.067 ms、120 帧 avg 8.333 ms；档案馆刷新 0.023 ms、开 0.119 ms、帧 8.333 ms；章节完成页 0.262 ms、选择页 0.685 ms、选择页帧 8.325 ms；结局屏构建 0.098 ms、次帧 8.201 ms、帧 8.327 ms。均低于 120 FPS 8.33 ms 单帧预算。
  - `test_empty_state_data` 首跑 **176 / 1**：一条组合空态变体缺少测试要求的「配方会记录在这里」机械提示，且测试对 RefCounted 的 `RunState` 错误调用 `free()`。修正文案、删除 `free()` 后 **178 / 0**。
  - `empty_state_data` 接入核实：`game.gd` 把 `run_seed` 传入 `inventory_ui.bind()`；图鉴从绑定 run 读取种子；四类空态（图鉴词/组合、背包词/遗物）各 8 句，按局种子 + surface id 稳定选取，不读取、不推进 `RunState.rng`，机械含义不变（文案接入真实落地，数字自洽）。
  - 第 22 程 `run_tests.gd` 的守卫无效：解析失败的脚本 `load()` 仍返回 GDScript，`new()` 先抛运行时错误中断 `_initialize`，`test == null` 永不命中。改为 `can_instantiate()` 预检，并用临时坏测试验证：退出 1、报告 `1 failed`、不挂起（坏文件已删除）。
  - 残留处置：探针/基准的断言与结论并入 `integration_menus` / `integration_run_save` / 单元测试后删除，未保留半成品；产品改动按项提交（空态文案、选择页文字排版、标题首帧焦点），测试覆盖单独提交。
  - 基线复核（HEAD `c068b79`）：`--headless --path . --import` 与 `--headless --path . --quit` 退出 0、`ERROR` 0；单元 **5354 / 0**；八套集成 **269 / 67 / 494 / 207 / 113 / 59 / 372 / 45**，全部 0 失败、各日志 `ERROR` 0；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。第 22 程宣称的数字中，run save 445→494、菜单 276→372 为本程新增覆盖；其余与第 21 程收尾一致，无回归。
- 任务 1 · 第 22 程剩余打磨面：
  - 关闭/焦点（章末完成页/选择页、Hub 训练碑、标题设置页）：真实键盘/手柄覆盖 82/82，**无产品缺陷**，未改产品代码；断言并入 `integration_menus`（**276 → 372**）。
  - 稳定性（Hub 档案馆面板、训练碑、标题设置页打开时退出）：55/55，**无产品缺陷**，未改产品代码；断言并入 `integration_run_save`（**445 → 494**）。
  - 性能：先取基线，唯一超预算项是章末选择页文字排版（两项约 29 ms），按第 20 程同一根因修复为入树后赋文字，修复后 0.685 ms；其余路径均在一帧内。未做其它优化、未把开销挪到首次打开页面。
  - 文案：`empty_state_data` 一类已落地，按任务单口径本面视为完成，不另开新类；未重复已做满的类别。
  - 本面结论：**未发现新的产品行为缺陷**。
- 任务 2 · 标题页有局内存档时的首帧焦点（监工拍板）：`title_screen.gd` 在有 `has_run_save()` 时把首帧焦点放在「继续本局」，无存档维持「继续旅程/开始旅程」；按 A 的语义不变（只关闭标题并续玩/进 Hub，不开始新局、不覆盖检查点）。`integration_menus` 用真实键盘方向键与手柄 D-pad 覆盖两种情形的首帧焦点与往返，并从初始焦点用真实 Enter 续玩进入 `ch1_01`；菜单套件 **372 / 0**。待用户确认第 8 项已标记为「已由监工拍板并实现」。
- 任务 3 · 收尾验证（HEAD `341d8d6`，Godot 4.7.stable.official.5b4e0cb0f）：`--headless --path . --import` 与 `--headless --path . --quit` 退出 0、`ERROR` 0；全量单元 **5354 / 0**；八套集成 **269 / 67 / 494 / 207 / 113 / 59 / 372 / 45**，全部 0 失败、各日志 `ERROR` 0；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**；临时探针/基准已删除；工作区干净。**本程完成的例行扫描未发现新的产品行为缺陷**（证据：`probe_focus22` 82/82、`probe_exit22` 55/55、`bench_ui22` 全部路径低于 8.33 ms；扫描中仅发现第 22 程残留的测试/文案问题与本程按拍板实现的焦点改动）。本程提交：`cacaadf` 空态文案、`d8bde5d` 选择页文字排版、`fee1998` 标题首帧焦点、`849913b` 单元测试与 runner 守卫、`52d5c5f` 集成覆盖、`c068b79` 标题双设备断言、`341d8d6` 残局审计与基线，以及本条收尾文档提交。本程不推 GitHub、不更新网页版，里程碑判定由监工按收口规则执行。

### 2026-11-04 · 第 22 程

- 任务 0 · 基线复核（HEAD `30e768e`，Godot 4.7.stable.official.5b4e0cb0f）：
  - 工作区：`git status` 为空；无 `tests/probe_*` / `tests/bench_*` 残留；无未跟踪文件。
  - `--headless --path . --import` 退出 0、`ERROR` 0；`--headless --path . --quit` 退出 0、`ERROR` 0。
  - 单元 `tests/run_tests.gd` **5169 / 0**，`ERROR` 0。
  - 八套集成全部 0 失败且各日志 `ERROR` 0——结构 **269**、第一章 demo **67**、run save **445**、手柄 **207**、UI 提示 **113**、第一章事件 **59**、菜单 A/B **276**、AI 设置 **45**。
  - `tests/check_exit_clean.sh <godot> 10` → **10/10 clean**；demo 像素资产 **36 / 0**。
  - 结论：第 21 程宣称的收尾数字在最终 HEAD `30e768e` 上全部复现，无回归，可以继续。

### 2026-11-04 · 第 21 程

- 任务 0 · 基线复核（HEAD `94c1201`，Godot 4.7.stable.official.5b4e0cb0f）：
  - 工作区：`git status` 为空；无 `tests/probe_*` / `tests/bench_*` 残留；无未跟踪文件。
  - `--headless --path . --import` 退出 0、`ERROR` 0；`--headless --path . --quit` 退出 0、`ERROR` 0。
  - 单元 `tests/run_tests.gd` **4908 / 0**，`ERROR` 0。
  - 八套集成全部 0 失败且各日志 `ERROR` 0——结构 **269**、第一章 demo **56**、run save **388**、手柄 **207**、UI 提示 **113**、第一章事件 **39**、菜单 A/B **251**、AI 设置 **45**。
  - `tests/check_exit_clean.sh <godot> 10` → **10/10 clean**；demo 像素资产 **36 / 0**。
  - 结论：第 20 程宣称的收尾数字在最终 HEAD `94c1201` 上全部复现，无回归，可以继续。
- 任务 1 · 打磨 1（此前未覆盖的关闭/焦点路径：事件房选择页、奖励选择页、残碑读取；临时探针 `tests/probe_focus21.gd` 66 项真实键盘/手柄事件，测后删除）：
  - 事件房选择页：打开即暂停、焦点在第一项；B/Esc/Start 均被吞掉（页面保持、仍暂停、不叠暂停菜单）；十字键上下移动焦点；按 A 选中后页面关闭、解除暂停、焦点不在隐藏控件、玩家可移动、房间标记已清、检查点落盘。真实键盘/手柄双路径均通过。
  - 奖励选择页：真实 `_open_reward()` 路径暂停世界；B/Esc 不能跳过、不叠暂停菜单；十字键/方向键移动焦点；A/Enter 选中后关闭、解除暂停、焦点不落在隐藏卡片、选项清空、HUD「获得：」、检查点落盘、玩家可移动。
  - 残碑读取：无独立页面，交互即认领。走到 110 px 认领半径内按 E：不暂停、无页面、焦点不落在隐藏控件、记录 +1、HUD「记录 +1」、`claimed_steles` 落盘、玩家可继续移动。
  - 结果：66/66 通过，未发现产品缺陷，未改产品代码。
  - 观察（未改）：休息室/书库的残碑位于第 30 行平台下方（平台底 y=496，玩家胶囊高 76、站立头顶 y=484），玩家无法站到残碑所在列；但认领半径 110 px 可从平台边缘覆盖（休息室从左缘 x≈848 即可读到，实测可认领），中文提示正常显示，不构成功能缺陷。若后续调整关卡几何，可考虑把残碑移出平台投影或抬高平台。
  - 断言并入：`tests/integration_ch1_event.gd` 新增 20 项（选择页暂停/焦点/冻结、B/Esc/Start 忽略、十字键焦点、A 选中后解冻/焦点/移动/存档），**39 → 59 / 0**；`tests/integration_ch1_demo.gd` 新增 11 项（休息室残碑可达、提示、无页面暂停、焦点、认领、记录、HUD、玩家移动），**56 → 67 / 0**；`tests/integration_menus.gd` 新增 16 项（真实奖励页暂停、焦点、B/Esc 忽略、方向键焦点、A 选中后解冻/焦点/选项/HUD/物理处理），**251 → 267 / 0**。探针已删除。
- 任务 1 · 打磨 2（此前未覆盖的启动/退出组合；临时探针 `tests/probe_exit21.gd` 60 项，真实 `save_run_on_exit()` + 新场景续玩，测后删除）：
  - 扫描三条路径（未重复第 17–20 程已覆盖的事件/商店/奖励/地图/背包/键位捕获/权柄二选一/结局屏/死亡页/结算延迟/发狂）：
    - 暂停菜单打开时退出：存档保留 `ch1_02` 与当前生命，续玩回到该房、不再暂停、暂停菜单不恢复、玩家可继续物理处理，生命一致。
    - 权柄收尾后章节完成页（「章节完成 · 记忆回收」）打开时退出：`_ending_pending` 使 run 检查点拒绝重写，但此前「Boss 已败 + 权柄已授予」的检查点仍在；续玩回到 `ch1_boss`、不二次生成 Boss、权柄保留、完成页重新打开；关闭完成页后章末选择页正常出现，选完进入结局屏。`demo_cleared` 在退出时保持 false。
    - Hub 对话打开时退出：Hub 没有 `save_run_on_exit` 钩子（真实关窗路径不写 run 检查点），Profile 可读且数值不变；重开 Hub 无对话残留、玩家未冻结、场景不暂停。
    - Hub 商店打开时退出：走真实「与咕噜对话读完 → 商店打开并冻结玩家」路径，买下一件未拥有货品后退出；无 run 检查点，重载 Profile 后碎片扣减与已购货品都保留。
  - 结果：60/60 通过，未发现产品缺陷，未改产品代码、存档格式或退出保存逻辑。
  - 断言并入 `tests/integration_run_save.gd` 新增 57 项（暂停菜单退出/续玩、章节完成页退出/续玩至结局、Hub 对话退出、Hub 商店购买后退出与持久化），**388 → 445 / 0**。探针已删除。
- 任务 1 · 打磨 3（此前未测的性能路径：冷启动到标题、标题进 Hub、Hub 进首房；临时基准 `tests/bench_boot21.gd` 三次 + 分拆基准 `tests/bench_split21.gd` 一次，测后删除；无产品改动）：
  - 方法：每个数字来自新进程 headless（`--script`，不亮主场景）。真实 `hub.tscn` 走 `load → instantiate → add_child`，真实 `TitleScreen` 构建与 `_on_title_started()` 交接，真实 `hub._on_run_requested()` → `change_scene_to_file("res://scenes/main.tscn")`；章节开场故事页出现后用 `_story.close()` 关闭，再等 `_mds_world.current_room == "ch1_01"`。主场景不预加载 `main.tscn`，与真机首次进局一致；120 FPS 单帧预算 **8.33 ms**。
  - 冷启动到标题（3 次）：引擎 tick 到 Hub 首帧 **1625 / 1689 / 2071 ms**（首次含文件缓存冷启）；Hub `load` **585–734 ms**、`instantiate` **5–30 ms**、`_ready` **413–467 ms**、首帧 **28–38 ms**；标题构建 **34–45 ms**、标题交接 `_start()` **10–16 ms**。合计冷启到可操作标题约 **1.7–2.2 s**（headless 开发态，脚本为源码编译；导出包为编译产物，数字会更低）。
  - 标题进 Hub / Hub 进首房：标题交接发生在 Hub 内，没有额外场景切换；Hub → 首房单帧 **2683 / 2819 / 2938 ms**。分拆单跑同一量级：`main.tscn` 加载约 **2.9 s**、`instantiate` **20 ms**、`_ready` **656 ms**，即大头是开发态资源/脚本编译。开场故事页在切换后 **<0.2 ms** 打开，关闭 **0.78–0.85 ms**，关闭到 `ch1_01` 可操作 **316–363 ms**。玩家感知为「开始 → 约 2.7–2.9 s 场景加载 → 开场页 → 关闭后约 0.35 s 进房」。
  - 帧间隔：启动后 120 帧 avg **8.25–8.31 / p95 8.60–8.62 / max 9.29–11.52 ms**；首房 120 帧 avg **8.26–8.31 / p95 8.64–8.71 / max 8.73–10.58 ms**，均贴 120 FPS 预算。切换过程 27–28 帧 avg **11.3–13.5**、p95 8.4、max **101–156 ms**（单帧卡顿来自场景加载），进房后恢复。
  - 结论：**没有可持续复现的局内掉帧**（首房稳定 avg≈8.3 ms）。唯一的超预算是一次性场景加载——Hub→局内约 2.7–2.9 s，其中约 2.9 s 是开发态 `main.tscn` 加载/编译。按任务单口径不做优化，也未把开销挪到首次打开页面（Hub/标题都不预加载 `main.tscn`）。若发行前仍需缩短，方向应是导出包已编译脚本 + 加载过场，而不是把加载塞进标题首开。两个基准均已删除。
- 任务 1 · 打磨 4（一类新的单薄文案：Hub 商店购买失败提示；只改文案与测试）：
  - 现状核查：商店/背包的空/错提示**均未轮换**——Hub 商店只有 3 句固定失败提示（`没有这件货。` / `这件货已经在你的手里了。` / `记忆碎片不足：需要 %d，你只有 %d。`），开场白也是固定 1 句；残页交易所的售罄行是固定「已带走：X」，买不起的行只禁用、无提示；背包/图鉴空态是固定「尚未收集任何词。」「尚未获得遗物。」「空槽位」；`Inventory` 没有容量上限，因此不存在「背包已满」。本程选 Hub 商店失败提示：它是唯一由公开 `ShopUI.buy()` 三个分支集中产出、Hub 内可实际触发的错误文案，也是本轮核查里最薄的一类（3 句、无变体）；背包空态同时被图鉴/背包两个 UI 共用且缺少稳定的局外选取键，留待后续单列一类处理。
  - 内容：新增 `ShopFailData`（`scripts/data/shop_fail_data.gd`）：已拥有 8 句、碎片不足 8 句、查无此货 4 句。已拥有每句保留「这件货已经在你的手里了。」，查无此货保留「没有这件货。」，碎片不足每句保留「记忆碎片不足」前缀与 `{cost}`/`{have}` 两个数字占位符；`format()` 只替换数字，不改变需求/持有数值。`pick(kind, item_id)` 用 `hash("shop_fail:kind:id")` 按固定 id 稳定选取——Hub 没有局内 RNG，不读取也不推进 `run.rng`。
  - 接入：`scripts/hub/shop_ui.gd::buy()` 的三个失败分支改为 `ShopFailData`（成功分支、价格、库存、已拥有判定、碎片扣减全部未动）。
  - 测试：新增 `tests/test_shop_fail_data.gd` **261** 项（三类数量/非空/长度/唯一/固定前缀、碎片不足每句恰好两个占位符且格式化后保留两个数字、同 id 稳定、40 个 id 至少轮换 3 句、三类互不重叠、未知 kind 返回空、连续 pick/format 不推进 `RunState.rng`）；`tests/integration_menus.gd` 新增 **9** 项（真实买不起行按 A 的提示等于该货品的固定文案且保留价格/持有数；已拥有分支被拒绝并给出对应文案；查无此货分支被拒绝并给出对应文案；三类失败都不扣碎片），**267 → 276 / 0**；单元全量 **4908 → 5169 / 0**。未改数值、机制、立绘、存档或 AI。
- 任务 2 · 收尾验证（HEAD `b2502c8`，Godot 4.7.stable.official.5b4e0cb0f）：
  - `--headless --path . --import` 退出 0、`ERROR` 0；`--headless --path . --quit` 退出 0、`ERROR` 0。
  - 单元 `tests/run_tests.gd` **5169 / 0**，`ERROR` 0。
  - 八套集成全部 0 失败且各日志 `ERROR` 0——结构 **269**、第一章 demo **67**、run save **445**、手柄 **207**、UI 提示 **113**、第一章事件 **59**、菜单 A/B **276**、AI 设置 **45**。
  - `tests/check_exit_clean.sh <godot> 10` → **10/10 clean**（`ERROR` 0）；demo 像素资产 **36 / 0**（`ERROR` 0）。
  - 工作区：`git status` 为空；无 `tests/probe_*` / `tests/bench_*`、无临时日志或截图；忽略目录为 `.godot/`、`build/` 与监工/截图产物 `.supervisor/`、`artifacts/`（均不入库）。
  - 本程提交：`cef7131` 基线复核、`4f8f456` 事件/奖励/残碑焦点与关闭覆盖、`a33b37d` 暂停/章节完成/Hub 对话与商店退出覆盖、`f864e2a` 冷启动与首房性能基线、`b2502c8` Hub 商店失败文案变体，以及本条收尾文档提交。
  - 待用户确认第 8 项（标题页有局内存档时的首帧焦点）保持现状未动；无新增待确认项。

### 2026-11-04 · 第 20 程

- 任务 0 · 基线复核（HEAD `d815a5f`，Godot 4.7.stable.official.5b4e0cb0f）：
  - 工作区：`git status` 为空；无 `tests/probe_*` / `tests/bench_*` 残留；无未跟踪文件。
  - `--headless --path . --import` 退出 0、`ERROR` 0；`--headless --path . --quit` 退出 0、`ERROR` 0。
  - 单元 `tests/run_tests.gd` **4685 / 0**，`ERROR` 0。
  - 八套集成全部 0 失败且各日志 `ERROR` 0——结构 **269**、第一章 demo **56**、run save **351**、手柄 **184**、UI 提示 **113**、第一章事件 **39**、菜单 A/B **230**、AI 设置 **45**。
  - `tests/check_exit_clean.sh <godot> 10` → **10/10 clean**；demo 像素资产 **36 / 0**。
  - 结论：第 19 程宣称的收尾数字在最终 HEAD `d815a5f` 上全部复现，无回归，可以继续。
- 任务 1 · 打磨 1（此前未覆盖的关闭/焦点路径；临时探针 `tests/probe_focus20.gd` 71 项 + `tests/probe_title20.gd` 17 项，真实键盘/手柄事件，测后删除）：
  - Hub 首次教学图鉴：键盘 Esc、手柄 B、图鉴键 C、Start 关闭后的焦点落点；连续三轮「C 开 → Esc 关」；再开再关的焦点稳定性；打开前若有可见控件持有焦点，关闭后焦点回到该控件（`_codex_return_focus`），第二次往返仍稳定。
  - 结果：探针 71/71 通过，未发现产品缺陷。关闭后 `gui_get_focus_owner()` 为 null 或可见控件，不会留在隐藏图鉴内；每次打开焦点落在第一个可选词；每次关闭均解除暂停并解冻玩家。
  - 标题「离开档案馆」：探针 17/17 通过，未发现产品缺陷。按钮为直接退出、只有 1 个 pressed 处理函数，不弹二次确认（`_confirm_panel` 始终为空），不关闭标题；Profile 与 run save 在标题可用前已落盘，退出前后均可读且内容不变。按第 18 程口径维持非缺陷，未加确认框，未新增待确认项。
  - 断言并入：`tests/integration_gamepad.gd` 新增 23 项（B/Start/Esc/C 关闭后的焦点落点、三轮再开再关、返回焦点锚点两次往返），**184 → 207 / 0**；`tests/integration_menus.gd` 新增 14 项（离开按钮存在/可见/可聚焦、单一处理函数、不弹确认、不丢 Profile 与 run save），**230 → 244 / 0**。未改产品代码、UI 布局或输入映射；探针已删除。
- 任务 1 · 打磨 2（此前未覆盖的启动/退出组合；临时探针 `tests/probe_exit20.gd`，真实 `save_run_on_exit()` + 新场景续玩，测后删除；发现并修复 1 个真实缺陷）：
  - 扫描 A（死亡结算延迟）：真实 `player.take_damage(999999)` 触发 `_finish(false)`，在 0.65 s 结果延迟内调用 `save_run_on_exit()`（等价关窗），随后结束进程并重启续玩。修复前：`_ending_pending` 使 `save_run_now()` 拒绝写入，但上一份「进房」检查点仍在磁盘（`ch1_01`、生命 120），带残留续玩请求重启会恢复该检查点、玩家满血复活——即死亡动画期间关窗可以取消死亡。修复后：`_finish(false)` 在提交死亡时立即 `RunSave.clear()`，延迟内退出无检查点，重启回到新局（`_resume_data` 为空、不是结局页、玩家存活）；胜利路径仍保留 Boss 已击败检查点，延迟内退出可续玩到结局，不受影响。
  - 修复范围：只改 `scripts/game.gd::_finish()` 一处，仅在 `won == false` 且 `Flow.auto_save` 时清检查点；未改 `run_save.gd`、存档格式、结局判定、奖励或其它 `_ending_pending` 路径（章节完成/权柄收尾）。
  - 扫描 B（污染发狂期间退出）：`corruption=99 + add_corruption(1)` 触发发狂后调用 `save_run_on_exit()`。存档含 `world.frenzy.active=true`、剩余秒数、发狂前生命上限、当前压低的 health/max_health 与污染 100；续玩后 `_frenzy_active`、倒计时、上限与生命值一致，倒计时归零能正常恢复上限并回落污染。未发现缺陷，未改产品代码。
  - 断言并入：`tests/integration_run_save.gd` 新增 35 项（死亡延迟内退出清检查点 + 残留续玩安全开新局；发狂退出/续玩的存档字段、上限、倒计时与恢复），**351 → 386 / 0**。探针已删除。
- 任务 1 · 打磨 3（此前未测的性能路径：拾取物拾取、商店开合；临时基准 `tests/bench_pickup_shop20.gd` + 微探针 `tests/probe_theme20.gd`，测后删除；有产品改动）：
  - 方法：headless 启动真实 `main.tscn`，关闭 `auto_save` 排除存档 I/O、禁用敌人 AI；用真实 `Pickup` 节点逐个拾取 20 个未拥有词（走 `_try_pickup_nearest()`）；进 `ch1_rest` 用 `_try_open_shop()` 打开 3 行商店并做 20 轮开关；基线 120 帧 **8.33 ms**（120 FPS）。不重复第 19 程的商店购买、第 17 程言灵、第 18 程波次/Boss 等已测项。
  - 修复前：**词拾取同步 31.2 ms**（median 30.8 / min 23.2 / max 40.3）——其中隐藏图鉴刷新 15.1 ms、背包刷新 10.9 ms、HUD 0.16 ms；**商店开合** cold **52–58 ms**、warm **50 ms**、close **0.09 ms**。微探针定位根因：把带文字的 Button `add_child` 进树（ENTER_TREE 阶段按尚未继承的主题字体排版）3 个约 **31–37 ms**；先加入空 Button 再赋文字仅 **0.34 ms + 0.02 ms**；Label 与无文字控件均 <0.6 ms。即每次新词卡/商店卡都把排版成本付在插入瞬间。
  - 修复（只改文字赋值时机与商店卡片复用，不改布局、文案、交互或数值）：`codex_ui.gd` / `inventory_ui.gd` 的 `_make_word_card()` 先建空文本卡片，`add_child` 后由新增的 `_fill_word_card_text()` 填字；`run_shop_ui.gd` 的 `_rebuild()` 改为复用 `_pool` 按钮（首次加入空按钮后赋文字、后续只更新文字/禁用/可见性，多余卡片隐藏），买下/开关店逻辑不变。
  - 修复后（同一基准复跑）：**词拾取同步 2.2–2.4 ms**（median 2.1 / max 5.1，低于 8.33 ms 单帧）；图鉴刷新 **0.82 ms**、背包 **0.55–0.59 ms**、HUD 0.12 ms、`_acquire_word` 1.5 ms；**商店 cold 7.6–8.2 ms（约一帧内）、warm 0.22–0.28 ms、close 0.09–0.10 ms**、`_rebuild` 0.03–0.04 ms。未把开销挪到首次打开页面：首次打开仍是唯一需要建卡的时刻，且已从 52–58 ms 降到一帧内。
  - 回归：`tests/test_codex.gd` / `tests/test_ui.gd` 新增 10 项卡片实际文字断言（新卡 glyph/词义/说明/按钮文字，解码后的原地更新）；`tests/test_shop.gd` 新增 10 项（再开复用同一批按钮、文字更新、行数增减时隐藏/恢复）；单元 **4685 → 4705 / 0**。受影响集成复跑：结构 **269**、第一章 demo **56**、run save **386**、手柄 **207**、菜单 **244**，全部 0 失败。基准与微探针已删除。
- 任务 1 · 打磨 4（一类新的单薄文案：结局返回提示；只改文案与测试）：
  - 现状核查：结束屏的返回提示对胜利/失败都只有一句固定「按 <键> 回到最后的档案馆」，设备/改键只换键名。第 19 程做的是复活提示并明确未动结局提示；NPC 闲聊、休整卡、休息室入场白、事件变体、残碑、交易所纸人、污染分档警告、书库发现、Boss 阶段/入场、复活提示均已做满，未重复。
  - 内容：新增 `EndingHintData`（`scripts/data/ending_hint_data.gd`）：胜利 8 句、失败 8 句，每句都保留「按 %s」键位提示与「回到最后的档案馆」目的地，只轮换氛围（合上这一页/名册对齐/灯还亮着/雨声未停/断页翻过去/墨迹没干/灯芯剩一截/别让污染读到等）；每句 ≤24 字、同结局内不重复、两类互不重叠。`pick(run_seed, won)` 用 `hash("%d:%s")` 按局种子 + 胜负稳定选取，不读取或推进 `run.rng`；`format_hint(template, key)` 只替换键名占位符。
  - 接入：`ending_screen.gd` 记录 `_won` 与 `_run_seed`，`_refresh_prompts()` 在显示、设备切换、改键时用当前键名格式化同一句；`show_campaign_ending(..., demo, run_seed := 0)` 新增可选参数，`game.gd` 传入 `run_state.run_seed`；数据为空时回退原固定句。另将 Hint 标签改为延迟查找，允许在 `_ready` 前刷新（测试/工具路径），游戏内行为不变。
  - 测试：新增 `tests/test_ending_hints.gd`（两类各 ≥8 句、非空、长度、唯一、各含「按 %s」与「回到最后的档案馆」、恰好一个占位符、格式化后保留键名与目的地、同种子稳定、40 种子轮换、跨结局不重叠、空模板、不推进 RunState RNG）；`tests/test_ending.gd` 改为真实入树并断言胜负提示匹配种子与键位、刷新后稳定；`integration_menus.gd` 新增 7 项（胜利页提示匹配显式种子、保留键位与目的地；真实死亡页提示匹配本局种子、键盘/手柄切换后提示跟随当前键）；`integration_run_save.gd` 新增 2 项（真实 `_finish(true)` 结局页提示匹配本局种子、保留目的地）。单元 **4705 → 4908 / 0**；菜单 **244 → 251 / 0**；run save **386 → 388 / 0**。未改数值、机制、立绘、存档或 AI。
- 任务 2 · 收尾验证（HEAD `49cd97a`，Godot 4.7.stable.official.5b4e0cb0f）：
  - `--headless --path . --import` 退出 0、`ERROR` 0；`--headless --path . --quit` 退出 0、`ERROR` 0。
  - 单元 `tests/run_tests.gd` **4908 / 0**，`ERROR` 0。
  - 八套集成全部 0 失败且各日志 `ERROR` 0——结构 **269**、第一章 demo **56**、run save **388**、手柄 **207**、UI 提示 **113**、第一章事件 **39**、菜单 A/B **251**、AI 设置 **45**。
  - `tests/check_exit_clean.sh <godot> 10` → **10/10 clean**（`ERROR` 0）；demo 像素资产 **36 / 0**（`ERROR` 0）。
  - 工作区：`git status` 为空；无 `tests/probe_*` / `tests/bench_*`、无临时日志或截图；忽略目录仅 `.supervisor/` 与 `artifacts/`（均为监工/截图产物，不入库）。
  - 本程提交：`cb7f08f` 基线复核、`de37e9b` Hub 图鉴关闭焦点 + 标题离开覆盖、`1dea584` 死亡延迟内退出清检查点、`1210445` 卡片文字延后填充与商店卡片复用、`49cd97a` 结局返回提示变体，以及本条收尾文档提交。
  - 待用户确认第 8 项（标题页有局内存档时的首帧焦点）保持现状未动；无新增待确认项。

### 2026-11-04 · 第 19 程

- 任务 0 · 基线复核（HEAD `9f96914`，Godot 4.7.stable.official.5b4e0cb0f）：
  - 工作区：`git status` 为空；无 `tests/probe_*` / `tests/bench_*` 残留；无未跟踪文件。
  - `--headless --path . --import` 退出 0、`ERROR` 0；`--headless --path . --quit` 退出 0、`ERROR` 0。
  - 单元 `tests/run_tests.gd` **4512 / 0**，`ERROR` 0。
  - 八套集成全部 0 失败且各日志 `ERROR` 0——结构 **269**、第一章 demo **48**、run save **304**、手柄 **184**、UI 提示 **113**、第一章事件 **39**、菜单 A/B **188**、AI 设置 **45**。
  - `tests/check_exit_clean.sh <godot> 10` → **10/10 clean**；demo 像素资产 **36 / 0**。
  - 结论：第 18 程宣称的收尾数字在最终 HEAD `9f96914` 上全部复现，无回归，可以继续。
- 任务 1 · 打磨 1（此前未覆盖的关闭/焦点路径；临时探针 `tests/probe_focus19.gd`，真实键盘/手柄事件，49 项断言）：
  - 扫描范围：死亡结算页（真实 `player.take_damage` 触发 `_finish(false)`，非直接改 `_finished`）的焦点与 Esc/B/Enter；权柄二选一页的 B/Start/Esc/Enter；标题「继续本局」以键盘 Enter 与手柄 A 进入后的首帧焦点。未重复第 15–18 程已覆盖的 Hub 面板、局内覆盖页换页、暂停设置回退、标题新游戏确认与结局屏焦点。
  - 结果：49/49 通过，未发现产品缺陷。死亡页标题为「记录中断」、场景暂停、焦点在返回按钮；Esc/B 均不关闭页面、不弹暂停菜单、焦点保持；Enter/A 返回 Hub 并解除暂停。权柄页 B/Start/Esc 均被吞掉、页面保持打开且场景暂停、不会叠出暂停菜单；Enter/A 选中并解除暂停。标题「继续本局」两种设备都进入存档房间 `ch1_01`；进入后的首帧焦点为 null 或可见控件，未残留 `TitleScreen`，`resume_requested` 已消费、`_resume_restored=true`、场景未暂停。
  - 观察（未改）：标题构建时初始焦点固定在「继续旅程」按钮（`title_screen.gd` 的 `start.grab_focus()`），即使存在局内存档；实测按 A 只关闭标题并进入 Hub，不会立刻开始新局或覆盖检查点，因此本程不按缺陷处理。是否改为有存档时优先聚焦「继续本局」见「待用户确认」。
  - 断言并入：`tests/integration_menus.gd` 新增 42 项（死亡页 Esc/B/Enter 与焦点、权柄页键盘/手柄双轮、标题继续本局键盘与手柄两轮及首帧焦点），**188 → 230 / 0**；`_press_key` 改为同时设置 `keycode` 与 `physical_keycode`（内置 `ui_accept`/`ui_cancel` 按 keycode 匹配），并补 `_free_scene` / `_close_story` 辅助。未改产品代码、UI 布局、输入映射或数值；探针已删除。
- 任务 1 · 打磨 2（此前未覆盖的启动/退出组合；临时探针 `tests/probe_save19.gd`，真实 `save_run_on_exit()` + 新场景续玩，42 项断言）：
  - 扫描三条路径：死亡结算页打开时退出、Boss 入场文案显示期间退出、Hub 首次教学页（含教学图鉴）打开时退出。未重复第 17 程（事件/商店/奖励/地图/背包打开时退出）与第 18 程（键位捕获中、权柄二选一、结局屏、`.bak` 恢复后开模态页）。
  - 结果：42/42 通过，未发现产品缺陷。死亡页退出不写局内存档（`Flow.end_run` 已清检查点且 `_ending_pending` 拒绝写入），但仍保存 Profile 且死亡奖励碎片保留；带残留续玩请求重启会安全开新局、不恢复结局页、不暂停。Boss 入场期间退出会写入 `ch1_boss` 检查点且 `boss_defeated=false`；续玩回到 Boss 房、只生成 1 个存活 Boss、入场可重播、1.6 s 后黑边归零、Boss 仍存活。Hub 教学页没有 `save_run_on_exit`，退出不写局内存档；磁盘 Profile 的 `tutorial_done` 保持 false，重开 Hub 教学重新出现、教学图鉴不恢复、玩家可移动。
  - 断言并入：`tests/integration_run_save.gd` 新增 47 项，**304 → 351 / 0**。未改 `run_save.gd`、存档格式、退出保存逻辑、v1 安全默认或坏档口径；探针已删除。
- 任务 1 · 打磨 3（此前未测的性能路径：敌人死亡/粒子清理与局内商店购买；临时基准 `tests/bench_death_shop19.gd`，测完删除；无产品改动）：
  - 方法：headless 启动 `main.tscn`，进 `ch1_02` 后禁用房间 AI，用 `_spawn_group` 生成 20 只 `ink_hound`，逐只 `take_damage(999999)` 计时（含 `_die`、死亡 FX、`_on_enemy_died` 的计数/掉落判定）；再测 62 个死亡 FX 在场时 60 帧帧间隔，1.2 s 后复查残留。另进 `ch1_rest` 打开商店，对休息项重复购买 20 次计时（`auto_save=false` 排除存档 I/O）。不重复已测的房间切换/存档/提示/续玩/拿词/暂停/地图/言灵/波次/阶段切换。
  - 数字（多次复跑，稳定值）：空场基线 avg **8.20–8.27 ms**（120 FPS）。敌人死亡同步耗时常规 **0.13–0.35 ms**；20 只批量 avg 0.18–0.68 / max 0.57–0.94 ms（不含冷启动尖峰）。多次复跑中有 4 次出现 **3.1–21.0 ms** 的单次尖峰，均落在一批的最前几次击杀；其中一次无武器掉落的运行里前两次击杀也出现 7.6 / 3.1 ms，故与掉落无关，属新进程冷启动/首次分配。62 个死亡 FX 在场时 60 帧 avg **8.10–8.36 ms**（维持 120 FPS），max 8.68–18.5 ms 的偶发单帧；1.2 s 后 FX 残留 **0**。商店购买同步 avg **0.18–0.19 ms**、max **0.36–0.48 ms**。
  - 结论：死亡/粒子清理与商店购买均无持续掉帧或超预算证据；前几次击杀的冷启动单次尖峰不持续、不影响平均帧率，本程不做优化、不把开销挪到首次打开页面。基准已删除。
- 任务 1 · 打磨 4（一类新的单薄文案：死亡/复活提示；只改文案与测试）：
  - 现状核查：两条复活路径各只有一句固定文本——权柄续命「续命生效 · 恢复 50 生命」、不灭档案「不灭档案替你翻回上一页」；死亡结算页文案属于结局正文，本程按任务单二选一，只做复活提示，未动结局提示。已做满的 NPC 闲聊/休整卡/休息室入场白/事件变体/残碑/交易所纸人/污染分档警告/书库发现/Boss 阶段/入场文案未重复。
  - 内容：新增 `DeathHintData`（`scripts/data/death_hint_data.gd`）：权柄续命 8 句（每句保留「续命生效」与「恢复 50 生命」），不灭档案 8 句（每句保留「不灭档案」与「翻回上一页」）；每句 ≤24 字、同类不重复。`pick(run_seed, kind)` 用 `hash("%d:%s")` 按局种子 + 复活类型稳定选取，不读取或推进 `run.rng`；未知类型返回空。
  - 接入：`game.gd::_on_player_died()` 的两条复活路径改读该文案；50/40 生命数值、复活消耗顺序、无敌帧、HUD 权柄状态与死亡判定均不变。
  - 测试：新增 `tests/test_death_hints.gd` 173 项（数量、非空、长度、无占位符、同类唯一、机制文本保留、同种子稳定、40 个种子轮换、未知类型返回空、不推进 RunState RNG）；`integration_ch1_demo.gd` 新增 8 项真实 HUD 断言（权柄复活回 50 生命且文案等于本局种子选中句并含「恢复 50 生命」；遗物复活回 40 生命且文案等于选中句并含「不灭档案」）。单元 **4512 → 4685 / 0**；第一章 demo **48 → 56 / 0**。未改数值、机制、立绘、存档或 AI。
- 任务 2 · 收尾（全部在最终 HEAD 上复跑）：
  - `--headless --path . --import` 退出 0、`ERROR` 0；`--headless --path . --quit` 退出 0、`ERROR` 0。
  - 单元 **4685 / 0**；八套集成全部 0 失败且各日志 `ERROR` 0——结构 **269**、第一章 demo **56**、run save **351**、手柄 **184**、UI 提示 **113**、第一章事件 **39**、菜单 A/B **230**、AI 设置 **45**。
  - `tests/check_exit_clean.sh <godot> 10` → **10/10 clean**；demo 像素资产 **36 / 0**。
  - 工作区：临时探针 `probe_focus19` / `probe_save19` / `probe_title19` 与基准 `bench_death_shop19` 均已删除（结论已并入集成与本日志），`git status` 干净，无未提交源码、测试、探针或基准。
  - 本程提交（旧→新）：`6c746da`（第 18 程基线复核）、`d93fd36`（死亡/权柄/继续本局焦点覆盖）、`6132924`（死亡/Boss 入场/教学退出边界覆盖）、`4f71979`（敌人死亡与商店购买性能记录）、`acc303a`（复活提示文案）、`d84dae0`（Boss 入场黑边断言等待修正），本条收尾文档提交紧随其后。
  - 未完成项：本程任务单范围内无阻塞；「待用户确认」第 8 项（标题页有存档时的首帧焦点）待监工/用户拍板，不影响本程其余工作。第 2–4 章仍按既有决定保留但 demo 不可达；打包/安装器/签名/Windows 实机验证仍属发行阶段。

### 2026-11-04 · 第 18 程

- 任务 0 · 基线复核（HEAD `bf11b3d`，Godot 4.7.stable.official.5b4e0cb0f）：
  - 工作区：`git status` 为空；无 `tests/probe_*` / `tests/bench_*` 残留。
  - `--headless --path . --import` 退出 0、`ERROR` 0；`--headless --path . --quit` 退出 0、`ERROR` 0。
  - 单元 `tests/run_tests.gd` **4436 / 0**；八套集成全部 0 失败——结构 **269**、第一章 demo **45**、run save **244**、手柄 **151**、UI 提示 **113**、第一章事件 **39**、菜单 A/B **180**、AI 设置 **45**，各日志 `ERROR` 0。
  - `tests/check_exit_clean.sh <godot> 10` → **10/10 clean**；demo 像素资产 **36 / 0**。
  - 结论：第 17 程宣称的收尾数字在最终 HEAD `bf11b3d` 上全部复现，无回归，可以继续。
- 任务 1 · 打磨 1（Hub 面板关闭与焦点、标题确认、结局屏焦点；临时探针 `tests/probe_focus18.gd`，真实手柄/键盘事件，74 项）：
  - 扫描：Hub 档案、商店、对话、帮助、言灵面板的 B/Esc/Start 关闭与关闭后焦点去向；标题「新游戏」确认框的 B/Start 取消与焦点回归；结局屏返回按钮焦点与 B/Start 行为。
  - 结果：74/74 通过，未发现产品缺陷。各面板 Start 与 B 均能关闭、解冻玩家，关闭后不存在隐藏焦点（焦点为 null 或可见控件）；标题确认 B/Start 取消后焦点回到「新游戏」按钮；结局屏按钮获得焦点，B 不关闭页面（Start 是手柄的 `restart` 绑定，会按设计返回 Hub）。标题页的「离开档案馆」按钮直接退出、没有二次确认；该操作不丢进度（Profile 与 run save 均已落盘），只有「新游戏（清除进度）」需要确认，本程按非缺陷处理，未改。
  - 断言并入：`integration_gamepad` 新增 33 项（对话/商店/档案/帮助/灵感的 Start 与 B、打开与关闭焦点可见性），**151 → 184 / 0**；`integration_menus` 新增 8 项（结局按钮焦点、结局 B 不弹暂停页、标题确认 Start 取消与焦点回归），**180 → 188 / 0**。未改产品代码、UI 布局、输入映射或数值；探针已删除。
- 任务 1 · 打磨 2（尚未覆盖的退出边界组合；临时探针 `tests/probe_save18.gd`，真实 `save_run_on_exit()` + 新场景续玩，64 项）：
  - 扫描四条路径：键位捕获中退出、权柄二选一打开时退出、结局屏打开时退出、`.bak` 恢复后立刻开模态页。
  - 结果：64/64 通过，未发现产品缺陷。捕获中退出仍写入 `ch1_03` 检查点、重开后续玩不残留 `input_capture_active`；权柄二选一退出后存档记录 `boss_defeated=true` 且权柄未授予，续玩重开必选、不会二次生成 Boss；结局屏退出不写 run 检查点但保存 Profile，残留的续玩请求安全退回新局；`.bak` 恢复后立即开暂停/设置页正常，随后写盘修复主文件且保留备份里的残页数。
  - 断言并入 `tests/integration_run_save.gd` 新增 60 项，**244 → 304 / 0**。未改 `run_save.gd`、存档格式、退出保存逻辑或坏档口径；探针已删除。
- 任务 1 · 打磨 3（此前未测的性能路径：战斗波次生成与 Boss 阶段切换；临时基准 `tests/bench_combat18.gd`，两次复跑，测完删除；无产品改动）：
  - 方法：headless 启动 `main.tscn`，进 `ch1_02` 战斗房建独立 `ArenaRoom` 测首波生成与「清完首波→队列波次回调」的真实路径；另进 `ch1_boss` 测 1→2、2→3 阶段切换与阶段横幅；同步耗时各 20 次，帧间隔取 120 帧墙钟。
  - 数字（两次复跑稳定值）：空场基线 avg **8.34 ms**、p95 8.94–8.99；首波生成 avg **0.46–0.55 ms** / max 0.98；队列波次生成 avg **0.50–0.57 ms** / max 0.78–3.02；有波次在场 120 帧 avg **8.33 ms** / max 9.12。Boss 1→2 avg **0.91–0.98 ms** / max 4.59，2→3 avg **0.80–0.95 ms** / max 4.23（首轮含缓存预热），阶段横幅 avg **0.76–0.79 ms** / max 1.39；阶段切换后 120 帧 avg **8.31–8.33 ms** / max 9.61。
  - 结论：波次生成与阶段切换的同步开销均远低于 8.33 ms 单帧预算，帧率维持 120 FPS；没有可持续复现的掉帧或超预算证据，本程不做优化、不把开销挪到首次打开页面。基准已删除。
- 任务 1 · 打磨 4（一类新的单薄文案：Boss 入场；只改文案与测试）：
  - 现状核查：Boss 入场此前只有音乐、闪白、黑边，没有任何文案；Boss 阶段氛围、NPC 闲聊、休整卡、休息室入场白、事件变体、残碑、交易所纸人、污染分档警告、书库发现等已做满的类别未重复。
  - 内容：新增 `BossEntranceData`（`scripts/data/boss_entrance_data.gd`），第一章 Boss 入场 8 句氛围文案，每句 ≤24 字、无占位符、互不重复；`pick(run_seed, chapter)` 用 `hash("%d:%d")` 按局种子 + 章节稳定选取，不读取或推进 `run.rng`。第 2–4 章继续返回空串（保持原有无文案入场，等其 demo 内容再补）。
  - 接入：`game.gd` 的 `_boss_entrance()` 在原有音乐/闪白/黑边之前显示该句；Boss 血条、目标、阶段横幅与战斗机制不变。
  - 测试：新增 `tests/test_boss_entrance_content.gd` 76 项（数量/非空/长度/无占位符/唯一、稳定选取、40 个种子轮换、未知章节返回空、不推进 RunState RNG）；`integration_ch1_demo.gd` 新增 3 项真实 HUD 断言（入场文案等于本局种子选中句、其他章节保持静默）。单元 **4436 → 4512 / 0**；第一章 demo **45 → 48 / 0**。未改数值、机制、立绘、存档或 AI。
- 任务 2 · 收尾（全部在最终 HEAD 上复跑）：`--headless --path . --import` 退出 0、`ERROR` 0；`--headless --path . --quit` 退出 0、`ERROR` 0；单元 **4512 / 0**；八套集成全部 0 失败且各日志 `ERROR` 0——结构 **269**、第一章 demo **48**、run save **304**、手柄 **184**、UI 提示 **113**、第一章事件 **39**、菜单 A/B **188**、AI 设置 **45**；`tests/check_exit_clean.sh <godot> 10` → **10/10 clean**；demo 像素资产 **36 / 0**。
  - 工作区：临时探针 `probe_focus18` / `probe_save18` 与基准 `bench_combat18` 均已删除（结论已并入集成与本日志）；`git status` 干净，无未提交源码、测试或探针。
  - 本程提交（旧→新）：`ba6903a`（第 17 程基线复核）、`18ee0c6`（Hub 面板关闭焦点覆盖）、`75abe4a`（退出边界覆盖）、`48bbeec`（战斗性能记录）、`3506047`（Boss 入场文案），本条收尾文档提交紧随其后。
  - 未完成项：本程任务单范围内无阻塞、无待用户拍板的新问题；第 2–4 章仍按既有决定保留但 demo 不可达，打包/安装器/签名/Windows 实机验证仍属发行阶段。

### 2026-11-04 · 第 17 程

- 任务 0 · 收拾第 16 程残局并在最终 HEAD 上复核基线：
  - 工作区：`git status` 为空；无第 15/16 程遗留的临时探针或基准（`probe_vault_freeze_16` / `probe_focus16` / `probe_event_leave16` / `bench_map_16` / `probe_pause_settings_14` / `bench_pause_settings_15` 均已在各自提交中删除）。
  - 仓库里另有三份从初始开源版本就存在的 `tests/probe_exit_audio.gd`、`tests/bench_parts.gd`、`tests/bench_spells.gd`，按任务要求先实跑核实：`probe_exit_audio --mode=scene-exit` 10/10 无 ObjectDB/resource 泄漏，退出音频修复结论仍成立（回归已由 `tests/check_exit_clean.sh` 守住）；`bench_parts` / `bench_spells` 在 MDS 迁移后已失效——访问 `scene._rooms[2]` 直接 `Invalid access of index '2' on Array[ArenaRoom]`，且错误后不调用 `quit()` 挂起，旧的压测数字只保留在 `docs/memory/sessions/2026-11-02-spell-v3-lexicon.md`。三份脚本（含 `.uid`）在本程按「不留 probe/bench 残留」删除，未改任何产品代码。
  - 基线复跑（Godot 4.7.stable.official.5b4e0cb0f，`~/workspace/tools/godot/bin/Godot_v4.7-stable_linux.x86_64`，HEAD `a4df6f8`）：`--headless --path . --import` 退出 0、`ERROR` 0；`--headless --path . --quit` 退出 0、`ERROR` 0；单元 `tests/run_tests.gd` **4277 / 0**；八套集成全部 0 失败——结构 **269**、第一章 demo **39**、run save **203**、手柄 **128**、UI 提示 **113**、第一章事件 **39**、菜单 A/B **154**、AI 设置 **45**，各日志 `ERROR` 0；`tests/check_exit_clean.sh <godot> 10` → **10/10 clean**；demo 像素资产 **36 / 0**。
  - 结论：第 16 程宣称的收尾数字在最终 HEAD `a4df6f8` 上全部复现，无回归；上面第 16 程日志里的数字由此确认，而非仅凭其自述。
- 任务 1 · 打磨 1（尚未覆盖的关闭回退与焦点路径：Hub 教程图鉴不响应暂停键、暂停确认框无测试）：
  - 复现（临时探针 `tests/probe_hub17.gd`，真实手柄事件）：Hub 用 D-pad ↑ 打开教程图鉴后按 Start 无反应——图鉴仍可见、`paused=true`、玩家仍冻结；同一时刻设置/对话/商店/档案/帮助/言灵面板都能用 Start 关闭。根因是 `hub.gd` 的图鉴分支只轮询 `codex`/`ui_cancel`，漏了 `pause`。
  - 修复：`scripts/hub/hub.gd` 的图鉴关闭条件补 `Input.is_action_just_pressed("pause")`，与其余 Hub 模态口径一致；B/Esc/C 行为不变，未改页面内容、冻结逻辑或布局。
  - 测试夹具缺陷（一并修复）：`tests/integration_gamepad.gd` 的权柄用例按下 `KEY_P` 后从未释放，导致整段后续测试里 `pause` 动作一直处于按住状态，轮询式 `is_action_just_pressed` 永远不触发；补 `_release_key(KEY_P)`。这是测试卫生问题，不是产品行为。
  - 新增真实手柄/键盘断言 23 项：图鉴 Start 关闭/解除暂停/解冻玩家、Hub 帮助 Start 关闭并解冻、暂停菜单「重新开始」「退出游戏」确认框在 Start 按下时保持打开且不恢复世界、Esc 取消后焦点回到 ResumeButton。`integration_gamepad` **128 → 151 / 0**；探针已删除，未改数值、存档、AI 或立绘。
- 任务 1 · 打磨 2（尚未覆盖的关闭回退与焦点路径：局内覆盖页快捷键与换页）：
  - 先用临时探针 `tests/probe_focus17.gd`（真实键盘事件，34 项断言）扫描：背包（Tab）、图鉴（C）、帮助（H）、设置（F10）各自「同键开→同键关」、开页焦点可见、关页后焦点不落在隐藏控件；背包→图鉴换页隐藏旧页；设置子页帮助被 H 提升后 `HelpUI._open` 与可见性同步；地图除 B/A 外还可用暂停键关闭且不会叠出暂停菜单。34/34 通过，未发现产品缺陷。
  - 断言并入 `tests/integration_menus.gd`（新增 26 项），**154 → 180 / 0**；探针已删除。只加回归覆盖，无产品代码改动，未改 UI 布局、输入映射或数值。
- 任务 1 · 打磨 3（尚未覆盖的存档边界组合：模态页打开时退出再续玩）：
  - 先用临时探针 `tests/probe_save17.gd`（真实 `save_run_on_exit()` + 新场景续玩，28 项断言）扫描五条未覆盖路径：事件页打开时退出、商店页打开（已购）时退出、奖励页打开时退出、地图打开时退出、背包打开时退出。28/28 通过，未发现产品缺陷。
  - 关键行为确认：事件页退出后存档 `room=ch1_05` 且未清房，续玩会重新弹出事件、选择后才清房并结算残页；商店页退出后已购行/残页/缓存保留，续玩不叠出商店页、可再开且已购行禁用；奖励页的 `save_run_now()` 按设计拒绝写入，`save_run_on_exit()` 只落 Profile，续玩回到未清房、重打并重选奖励；地图/背包不持久化，续玩时不恢复页面也不残留暂停。
  - 断言并入 `tests/integration_run_save.gd`（新增 41 项），**203 → 244 / 0**；`_free_scene()` 在进程内续玩前显式清掉 `paused`（真实退出是结束进程；探针若在暂停中释放场景会卡住房门过渡，属测试夹具问题）。未改 `run_save.gd`、存档格式、v1 安全默认或坏档口径。探针已删除。
- 任务 1 · 打磨 4（尚未测的性能路径：言灵施放；临时基准 `tests/bench_spell17.gd`，测完删除；无产品改动）：
  - 目标：选此前未测、玩家会重复使用的重负载路径——五种重型言灵形态的同步施放开销与施放后持续帧步进。不重复第 11–13 程房间切换/存档/提示/续玩/拿词、第 15 程暂停往返、第 16 程档案地图。
  - 方法：headless 启动 `main.tscn`，进 `ch1_02` 战斗房，关掉敌人 `process_mode` 隔离 AI 噪声；预热后每形态 20 次施放计同步耗时；最后一次施放保留，测 240 帧墙钟帧间隔；基线同场景 120 帧。
  - 数字（第二/三次复跑稳定值）：基线 avg **8.33 ms**、p95 8.61、worst 8.78（120 FPS）。同步 `cast()`：导弹 96 发 avg **1.86 ms** / p50 1.77 / max 2.98；流星 24 发 avg 0.47 / max 0.65；领域 avg 0.30 / max 0.39；光束 avg 1.40 / max 1.56；地裂 avg 0.43 / max 0.56。施放后 240 帧：各形态平均始终 **8.33–8.34 ms**（满 120 FPS），p95 10.0–14.3 ms，最差单帧 11.5–21.8 ms（流星落地/爆炸那一下），场上节点 63–87 发弹体 + 1 领域。
  - 结论：同步施放远低于 8.33 ms 单帧预算；平均帧率不受影响，只有重形态落地时偶发单帧尖峰（同场景基线 worst 8.78 ms，说明尖峰来自生成/清理的瞬时分配，未持续）。没有可持续复现的掉帧证据，本程不做优化、不把开销挪到首次打开页面；基准已删除。
- 任务 1 · 打磨 5（一类新的单薄文案：Boss 阶段提示；只改文案与测试）：
  - 现状核查：`_on_boss_phase()` 对每个阶段只显示一句固定「墨骸史官 · 第 N 阶段」，第 2/3 阶段各只有这一句；第 1 阶段没有阶段横幅。第 9–16 程已做满的类别（NPC 闲聊、休整卡、休息室入场白、事件变体、残碑、交易所纸人、污染分档警告、书库发现）未重复。
  - 内容：新增 `BossPhaseData`（`scripts/data/boss_phase_data.gd`），第 2 阶段 8 句「纸页风暴」、第 3 阶段 8 句「封印/镜写」氛围句，共 16 句；每句 ≤24 字、无占位符、同阶段唯一。`pick(run_seed, phase)` 用 `hash("%d:%d")` 按局种子 + 阶段稳定选取，不读取或推进 `run.rng`。
  - 接入：`game.gd` 保留原机械前缀「Boss 名 · 第 N 阶段」，仅在有氛围句时追加「：<句>」；第 1 阶段与其他阶段保持原文案，章节 2–4 的 Boss 代码路径不受影响。
  - 测试：新增 `tests/test_boss_phase_content.gd` 159 项（数量/非空/长度/无占位符/阶段内与跨阶段唯一、同种子稳定、40 个种子轮换、未知阶段返回空、不推进 RunState RNG）；`integration_ch1_demo.gd` 新增 6 项真实 HUD 断言（第 2/3 阶段文案等于本局种子选中句、保留「第 N 阶段」）。单元 **4277 → 4436 / 0**；第一章 demo **39 → 45 / 0**。未改数值、机制、立绘、存档或 AI。
- 任务 2 · 收尾（全部在最终 HEAD 上复跑）：`--headless --path . --import` 退出 0、`ERROR` 0；`--headless --path . --quit` 退出 0、`ERROR` 0；单元 **4436 / 0**；八套集成全部 0 失败且各日志 `ERROR` 0——结构 **269**、第一章 demo **45**、run save **244**、手柄 **151**、UI 提示 **113**、第一章事件 **39**、菜单 A/B **180**、AI 设置 **45**；`tests/check_exit_clean.sh <godot> 10` → **10/10 clean**；demo 像素资产 **36 / 0**。
  - 工作区：临时探针 `probe_focus17` / `probe_save17` / `probe_pause_confirm17` / `probe_hub17` 与基准 `bench_spell17` 均已删除（结论已并入集成/本日志）；`git status` 干净，无未提交源码、测试或探针。
  - 本程提交（旧→新）：`df063ce`（第 16 程基线复核 + 删除失效 probe/bench）、`599c893`（Hub 图鉴 Start 关闭 + 手柄/确认框覆盖）、`218e31f`（局内覆盖页快捷键/换页覆盖）、`6e8ea76`（模态页打开时退出续玩覆盖）、`792f6f4`（言灵施放性能记录）、`cbfdb5a`（Boss 阶段文案），本条收尾文档提交紧随其后。
  - 未完成项：本程任务单范围内无阻塞、无待用户拍板的新问题；第 2–4 章仍按既有决定保留但 demo 不可达，打包/安装器/签名/Windows 实机验证仍属发行阶段。

### 2026-11-04 · 第 16 程

- 交接：第 15 程已完成并提交（HEAD `4decb3e`），工作区干净、无在途改动；本程按任务单只在本地 `supervisor-dev` 分支工作与提交，不 push、不碰 main/远端。
- 任务 1（基线，按任务单要求先于修复执行；Godot 4.7.stable.official.5b4e0cb0f，本机 `~/workspace/tools/godot/bin/Godot_v4.7-stable_linux.x86_64`）：`--headless --path . --import` 退出 0；`--headless --path . --quit` 退出 0（两份日志 `ERROR` 计数 0）；单元 `tests/run_tests.gd` **4198 / 0**；八套集成全部 0 失败——结构 **269**、第一章 demo **22**、run save **176**、手柄 **128**、UI 提示 **113**、第一章事件 **34**、菜单 A/B **128**、AI 设置 **45**；`tests/check_exit_clean.sh <godot> 10` → **10/10 clean**。全部数字与第 15 程收尾完全一致，基线无回归。
- 任务 2 · 用户报告的隐藏书库卡死（本程最优先；先复现后修，未盲改）：
  - 复现（临时探针 `tests/probe_vault_freeze_16.gd`，真实路径）：`main.tscn` 起步 → 加载 `ch1_03` → 把玩家放到书库门 `door1` → 真实 `interact` 按键。房间正常切到 `ch1_vault`（0.2 s 内完成、`changing_room=false`），但随后 2.4 s 采样中玩家坐标恒为 `(3200, 1220)`（书库门落点）、速度恒为 0、生命每 0.6 s 掉 15（120 → 45）；`paused=false`、`_ending_pending=false`、帧与计时器照常推进。即玩家被钉在书库门口无法移动并持续掉血，实机表现就是“卡死”；不是死循环、同步等待或 UI 构建阻塞。
  - 根因：`scripts/game.gd` 的坠落保护 `if player.position.y > 850` 用世界坐标判定。玩家是 `main.tscn` 根节点子节点，`position` 即全局坐标；MDS 世界里只有隐藏书库的房间原点在 `(2560, 720)`（第 2–4 章书库同样在 `y=720`），书库地面在世界 `y≈1264`，于是每帧都判定“掉出房间”：传送回 `_last_checkpoint`（进房门点）、清空速度，并按无敌帧间隔反复扣 15 生命。
  - 修复（只改这一处判定，不改房间、存档、数值或玩法）：MDS 模式下改用房间局部 Y——`player.global_position.y - world.get_origin(current_room).y`；非 MDS 旧线性关卡保持原判据。实测书库内玩家落到地面 `y=1263.99`、生命保持 120、可正常移动；坠落保护仍有效（放到房间下方 900 px 会被拉回房间）。
  - 回归：`tests/integration_ch1_demo.gd` 新增 14 项、真实按键驱动——书库门存在 → 真实 interact 进入 `ch1_vault` → 加载完成/宝箱与残碑构建/HUD 目标为「搜查隐藏书库」→ 等过一个无敌窗口后真实移动（x 前进 >20）且生命不变、站在地面 → 真实 interact 开书库宝箱 → 真实 interact 从书库门返回 `ch1_03` → 返回后可继续移动；另 1 项确认坠落保护仍把玩家拉回房间。**22 → 36 / 0**。探针已删除。
  - 验证：`integration_ch1_demo` 36 / 0；结构集成 269 / 0；run save 176 / 0；全量单元与其余集成在收尾统一复跑。未改任何数值、布局、存档格式或 AI 行为。
- 任务 3 · 打磨 1（尚未覆盖的关闭回退与焦点路径；临时探针 `tests/probe_focus16.gd`，真实手柄/键盘事件）：
  - 扫描范围：第 15 程已覆盖 AI 子页/F10 逐层关闭/换覆盖页之外，本程补设置里的「键位设置」「操作说明」两个子页的打开 → B 关闭 → 焦点回入口，以及从标题页打开设置 → B 关闭后的焦点与 Hub 解冻。
  - 证据（复现 1 项真实缺陷）：设置 → 操作说明（作为设置子页打开）→ 按 H 用帮助快捷键把帮助页提升为独立覆盖页。该切换由 `_toggle_overlay` 用 `show()` 显示帮助页，而 `HelpUI._open` 只在 `open()` 里置真，`close()` 又以 `_open` 为守卫：页面可见但「关闭」按钮和页面自身按键处理全部失效，鼠标点关闭无反应（探针 `help_switch_close_button_works` 失败）。键盘/手柄仍可借游戏层快捷键退出，属可复现但不易察觉的关闭回退缺陷。
  - 修复：`HelpUI` 以可见性为唯一状态源（`visibility_changed` 同步 `_open`），`close()` 守卫改为 `if not visible: return`。只改帮助页生命周期，不改内容、布局、输入映射或玩法。
  - 验证：同一探针 33/33；键位/帮助子页 A 开 B 关、焦点回到各自入口、暂停保持；标题设置 B 关闭后焦点回标题「设置」按钮、Hub 解冻。断言并入 `tests/integration_menus.gd`（新增 26 项：两个子页往返、帮助页 H 重开后的关闭按钮、标题设置往返），**128 → 154 / 0**；探针已删除。
- 任务 3 · 打磨 2（尚未覆盖的存档边界组合：书库内存档 / 续玩）：
  - 场景：在 `ch1_vault` 里开宝箱、读残碑、改生命/墨量/残页/污染后写盘，退出后用主存档续玩。此前所有续玩用例都在主路房间（世界 y=0），书库在世界 y=720，正是上一项坠落判定会误伤的房间，因此同时守护本次修复。
  - 断言：存档文件 `run.room=ch1_vault`，`progress.vaults` / `world.opened_chests` / `world.claimed_steles` 均记录书库；续玩回到书库、数值一致、位置误差 <8 px（水平）/<40 px（垂直）、宝箱保持打开、残碑保持已读（节点已移除）、发现标记还原；等一个无敌窗口生命不变、可移动；从书库门回到 `ch1_03` 正常。
  - 验证：`tests/integration_run_save.gd` **176 → 203 / 0**（新增 27 项）。未改存档格式、v1 安全默认或坏档口径。
- 任务 3 · 打磨 3（一类新的单薄文案：隐藏书库首次发现提示；只改文案与测试）：
  - 现状核查：书库首次进入只有一句固定「发现隐藏书库 · 搜查宝箱与残碑」。第 9–15 程已做满的类别（NPC 闲聊、休整卡、休息室入场白、事件变体、残碑、交易所纸人、污染分档警告）未重复。
  - 内容：新增 `VaultRoomData`，8 句发现文案；每句都保留「发现隐藏书库」开头与「搜查宝箱与残碑」的机制提示，只轮换氛围。`pick(run_seed, room_id)` 用 `hash("%d:%s")` 稳定选取，不读取或推进 `run.rng`；`game.gd` 的首次发现提示改读它。
  - 测试：`tests/test_ch1_content.gd` 新增 79 项（数量 ≥8、逐句非空/开头/机制提示/无占位符/唯一、同种子稳定、40 个种子轮换、按房间变化、不推进 run RNG）；`tests/integration_ch1_demo.gd` 新增 3 项真实进屋断言（HUD 文案等于本局种子选中句、非空、保留「搜查宝箱与残碑」）。单元 **4198 → 4277 / 0**；第一章 demo **36 → 39 / 0**。未改数值、布局、存档、立绘或 AI。
- 任务 3 · 打磨 4（复现并修复：事件页延迟打开会追到下一个房间；稳定性）：
  - 复现（临时探针 `tests/probe_event_leave16.gd`）：直接加载 `ch1_05`，0.15 s 后加载 `ch1_04`（等价于进屋后立刻从左侧门离开，真实操作约 0.4–0.6 s 可做到）。修复前 `load_room("ch1_04")` 直接卡住不再返回：0.8 s 的延迟回调在离开后仍在下一个房间弹出事件页，`StoryOverlay` 暂停整棵树，而房间过渡的淡入 Tween 挂在 `PROCESS_MODE_PAUSABLE` 的 MDS 世界上，永远播不完；故事层（layer 30）又在淡出遮罩（layer 100）之下，玩家看到的是黑屏加无法操作的过渡。
  - 修复：`_open_ch1_event_after_transition` 在计时结束后确认玩家仍在该事件房（`_mds_active` 且 `_mds_world.current_room == room_id`）；已离开则取消本次打开。房间未清，重新进入会再次排队，事件不会丢。
  - 验证：同一探针修复后——离开后 `ch1_04` 过渡完成、事件页未打开、未暂停、`ch1_05` 未标记已清；重新进入 `ch1_05` 1.1 s 后事件页正常打开，选择后标记已清并恢复。断言并入 `tests/integration_ch1_event.gd`（新增 5 项），**34 → 39 / 0**；探针已删除。
- 任务 3 · 打磨 5（尚未测的性能路径：档案地图；临时基准 `tests/bench_map_16.gd`，测完删除；无产品改动）：
  - 目标：选此前未测、玩家会反复用到的地图路径——打开档案地图，以及地图关闭时 MDS 每物理帧仍在做的玩家标记更新。不重复第 11 程房间切换/存档写入/提示刷新、第 12 程续玩启动、第 13 程拿词、第 15 程暂停往返。
  - 方法：headless 启动 `main.tscn`，把第一章 8 个房间全部访问一遍（让地图画满整章），回 `ch1_01`；预热 5 次后测 20 次 `open()` 同步耗时与 open + 一帧耗时；再连续 500 次 `map_view.set_player()` 计隐藏状态下的更新耗时。`auto_save=false` 排除存档 I/O。
  - 数字（n=20 / n=500）：同步 `open()` median **0.391 ms**（avg 0.386 / min 0.350 / max 0.414）；open + 一帧 median **7.957 ms**（7.716–8.089），即恰好一帧 120 FPS 的等待，不是绘制开销；地图隐藏时 `set_player` median **0.0040 ms**（max 0.032）。全部远低于 8.33 ms 单帧预算，没有可测量的问题，本程不改地图代码；基准已删除。

### 2026-11-04 · 第 15 程

- 任务 0 · 收拾第 14 程残局：`git status` 确认自 `374cd53` 起无已提交改动，唯一在途文件为 `tests/probe_pause_settings_14.gd`。实跑该探针（`--headless -s tests/probe_pause_settings_14.gd`）：手柄路径可复现现状——暂停 → 打开设置 → B 关闭设置后 `paused=false`、暂停菜单不可见、`gui_get_focus_owner()=null`，即关闭设置直接恢复游戏且焦点落空；探针 17 项断言 7 项失败（失败项正是本程要改的新口径）。键盘路径在探针自身「打开设置」一步就失败：其 `InputEventKey` 只设 `physical_keycode`，而内置 `ui_accept`/`ui_cancel` 按 `keycode` 匹配，属探针按键构造缺陷，不是产品行为；本程重写键盘事件构造后转成集成断言，探针按任务要求删除。
- 任务 1 · 基线（Godot 4.7.stable.official.5b4e0cb0f，本机 `~/workspace/tools/godot/bin/Godot_v4.7-stable_linux.x86_64`）：`--headless --path . --import` 退出 0；`--headless --path . --quit` 退出 0；单元 `tests/run_tests.gd` **4122 / 0**；八套集成全部 0 失败——结构 **269**、第一章 demo **19**、run save **146**、手柄 **112**、UI 提示 **113**、第一章事件 **34**、菜单 A/B **110**、AI 设置 **45**；`tests/check_exit_clean.sh <godot> 10` → **10/10 clean**。全部数字与第 14 程基线完全一致，基线无回归。
- 任务 2 · 暂停菜单设置回退（按监工 2026-11-04 拍板，`.supervisor/DECISIONS.md`）：
  - 复现（真实手柄/键盘事件，探针 `tests/probe_pause_settings_14.gd`）：暂停 → 打开设置 → 手柄 B 关闭后 `paused=false`、`pause_menu.is_open()=false`、`gui_get_focus_owner()=null`；键盘 Esc 路径同样。即关闭设置直接恢复游戏且焦点落空。探针修正了自身键盘事件构造（内置 `ui_accept`/`ui_cancel` 按 `keycode` 匹配，原探针只设 `physical_keycode`），修正后 19 项断言中 6 项按预期失败，精确复现该现状。
  - 修复范围（只改这一条回退路径）：`scripts/game.gd` 在暂停菜单点开设置时记录「来源页 + 打开前的焦点控件」；`_close_overlay()` 关闭该页时不再解除暂停，而是 `pause_menu.open_pause()` 重新显示暂停菜单，并把焦点还给原控件（原控件失效时保留 `open_pause()` 的 Resume 兜底焦点）。若设置被其他覆盖页替换，来源标记随之清空，避免陈旧状态影响后续打开。设置内部子页（AI/键位/说明）仍由 `SettingsMenu.close_subpage()` 逐层关闭、先回设置页；从标题/Hub/游戏内快捷键直接打开的设置行为未改。未改设置内容、保存逻辑、暂停恢复逻辑、布局与数值。
  - 验证：`tests/integration_gamepad.gd` 新增 16 项真实事件断言——手柄 Start 暂停 → 方向键聚焦设置 → 真实 A 打开 → 真实 B 关闭后暂停菜单可见、`paused=true`、焦点回到 SettingsButton → 再按 B 正常恢复游戏；键盘 P → Enter 打开设置 → Esc 关闭回暂停菜单（焦点恢复）；键盘/手柄混合往返（手柄 A 开、键盘 Esc 关）。旧「关闭设置即恢复游戏」断言已按新口径改写为「回暂停菜单」，并保留后续直接打开设置的子页行为断言。**112 → 128 / 0**。`tests/integration_run_save.gd` 的 3 轮暂停—设置循环改为断言回到暂停菜单后再关闭暂停菜单恢复，**146 → 152 / 0**。全量单元 **4122 / 0**；其余七套集成保持 269 / 19 / 113 / 34 / 110 / 45 全绿；探针已删除。
- 任务 3 · 关闭回退类残留扫描（临时探针 `tests/probe_close_return_15.gd`，真实手柄/键盘事件）：
  - 扫描范围：设置子页（AI/键位/说明）逐层关闭与焦点、设置快捷键与覆盖页快捷键的换页、暂停子页、局内覆盖层（图鉴/背包/设置/说明/地图/商店/剧情/奖励/权柄/结算）。Hub 侧设置/子页由 `hub.gd` 自己的「一次只关一层」轮询处理，既有断言覆盖；暂停菜单原生确认框在第 13 程已核查无法复现焦点丢失，未改。
  - 证据 1（设置子页关闭不恢复焦点 + 引擎报错）：暂停 → 设置 → 真实 A 打开 AI 页 → 真实 B 关闭。修复前 `_subpage_focus` 未回到 AI 按钮，且 `SettingsMenu.close_subpage()` 只认 `close()`，而 `AISettingsUI` 的关闭方法叫 `close_page()`，于是走了 `visible=false` 分支、不 emit `closed`：焦点不恢复，一次性连接残留，第二次打开 AI 页时引擎报 `Signal 'closed' is already connected`。修复：`close_subpage()` 增加 `close_page()` 回退；AI 页正常 emit `closed` 后既恢复焦点也释放连接。只改关闭回退，不改 AI 设置内容/保存。
  - 证据 2（设置键把子页留在屏幕上）：设置子页打开时按设置键 F10，修复前 `settings=false, ai=true, paused=false`——设置页整页关闭、AI 页滞留、游戏恢复且无暂停；修复：`game.gd` 的设置快捷键与 B/Esc、Hub 口径一致，先 `close_subpage()`，没有子页才切换设置页。修复后 `settings=true, ai=false, paused=true`，再按一次才关设置。
  - 证据 3（换覆盖页留下子页）：AI 子页打开时按 C 打开图鉴，修复前 `settings=false, ai=true, codex=true`（两个模态页叠在屏幕上）；修复：`_toggle_overlay` 替换设置页、`_close_overlay` 关闭设置页时统一调用新增的 `SettingsMenu.close_subpages()` 收起子页。修复后 `settings=false, ai=false, codex=true`，关闭图鉴正常恢复游戏。
  - 未复现（不改）：图鉴/背包/说明/地图/商店/剧情/奖励/权柄/结算均为单层覆盖页，关闭即回游戏，没有「打开它的上层页面」可回；替换式换页属既有的单覆盖层设计，其余组合未观察到残留。
  - 验证：修复前探针在 A/B 场景 19 项中 3 项失败（AI 页焦点、F10 后设置不可见、AI 页残留）；C 场景单独临时回退验证为 `settings=false ai=true codex=true`、1 项失败；全部修复后探针 20/20。断言并入 `tests/integration_menus.gd` 后探针删除，**110 → 128 / 0**（新增 18 项，含 AI 子页焦点、F10 逐层关闭、换覆盖页无残留），引擎 `ERROR` 计数 0。未改页面内容、玩法、布局与数值。
- 任务 4 · 长局与边界稳定性（只扩展 `tests/integration_run_save.gd`，不改存档格式、v1 安全默认或坏档口径）：
  - 新回退口径下的正常续玩：长局（ch1_rest、160 上限生命 / 66 当前生命、120 上限墨量 / 44 当前墨量、58 残页、污染 63、xue+dongjie 两词、time_shard+blood_quill 两遗物、ink_axe 武器、已存短语签名、ch1_01/04/06 已清）里连走 3 轮「暂停 → 设置 → 回暂停 → 恢复游戏」后保存、退出、用主存档续玩（非备份恢复），逐项断言房间、生命、墨量、残页、污染、词、遗物、武器、短语、已清房间与位置均与保存前一致。
  - 新增边界（此前未覆盖）：在续玩后的长局里按暂停（`_toggle_pause` 会写一次存档），保持暂停菜单打开直接退出（模拟关窗），重新启动续玩——断言仍回 `ch1_rest`、生命/残页一致、`paused=false`、暂停菜单不恢复、位置与暂停时一致。覆盖「暂停中退出」的存档与模态状态不持久化。
  - 未重复第 12/13 程已有用例：暂停循环本身、恢复后二次续玩与已购行、已选权柄 Boss 收尾、未来版本 + 有效 `.bak` 均保持原断言不动。
  - 验证：`tests/integration_run_save.gd` **152 → 176 / 0**（新增 24 项）；全量单元与其余集成在收尾统一复跑。未改 `run_save.gd` 与 `game.gd`。
- 任务 5 · 性能检查（临时基准 `tests/bench_pause_settings_15.gd`，测完删除；无产品改动）：
  - 目标：选此前未测、玩家会重复遇到的「暂停 → 设置 → 回暂停 → 恢复游戏」菜单往返（也是本程任务 2 改动的路径）。不重复第 11 程房间切换/存档写入/提示刷新、第 12 程「继续本局」启动、第 13 程局内获得新词。
  - 方法：headless 启动 `main.tscn`（ch1_01），`auto_save=false` 以排除存档 I/O；每轮依次 `pause_menu.open_pause()` → `_on_pause_settings()` → `settings_menu.close()`（新回退路径）→ `pause_menu.toggle()`。每步只计同步调用耗时，**不含** `await process_frame`（首版把等待计入，四步都读到 ~8 ms，恰为 120 FPS 一帧，已修正为同步计时）；预热 5 轮后测 40 轮，报 avg/min/max。运行命令：`<godot> --headless --path . -s tests/bench_pause_settings_15.gd`。
  - 数字（40 轮）：`pause_open` avg **0.435 ms**（min 0.360 / max 1.425）；`settings_open_from_pause` avg **0.722 ms**（0.603 / 1.321）；`settings_close_to_pause` avg **0.252 ms**（0.178 / 1.716）；`resume_from_pause` avg **0.401 ms**（0.303 / 2.303）。最大值 2.303 ms，低于 120 FPS 单帧 8.33 ms，且每轮只发生一次，无卡顿风险。
  - 结论：全部低于一帧预算，没有基线数据支撑任何优化，本程不改菜单性能相关代码，也未把开销挪到首次打开页面。基准探针已删除。
- 任务 6 · 纯文案内容填充（只改文案，不碰数值、系统与立绘）：
  - 类别选择：污染分档警告。核查候选后确认这一类仍单薄——4 个分档各只有 1 句固定文本（`RunState.corruption_tier_warning()`），一旦跨档就必然看到同一句；已做满的 Hub NPC 闲聊（11 句/人）、战斗结算休整卡（8 组）、休息室入场白（8 句）、事件房变体（7）、残碑（8）、交易所纸人（5+5）均未重复。
  - 内容：新增 `scripts/data/corruption_warning_data.gd`（`CorruptionWarningData`），分档 1–3 各 4 句引导语 + 原样保留的机制文本（敌人伤害/短语墨耗/冷却百分比一字不改），分档 4 各 4 句失控文案；共 16 句。`RunState.corruption_tier_warning()` 改为调用 `CorruptionWarningData.pick(run_seed, tier)`。
  - 选取规则：`posmod(hash("%d:%d" % [run_seed, tier]), 4)`——按局种子 + 分档稳定，不消耗 `run.rng`，不影响掉落序列与续玩一致性；续玩时 `run_seed` 从存档恢复，看到的是同一句。
  - 测试：新增 `tests/test_corruption_warnings.gd`（76 项）——每档 4 句、非空、档内唯一、分档 1–3 每句都保留全部机制片段、分档 4 都以「污染失控」开头、同 seed 稳定、40 个 seed 至少 3 种、`RunState` 跨档返回与 `pick` 一致、警告选取前后 `rng.state` 不变。`tests/integration_ch1_demo.gd` 新增 3 项真实 HUD 断言（第 1 档提示等于 seed 选中句、非空、含「敌人伤害 +15%」），**19 → 22 / 0**。
  - 验证：全量单元 **4122 → 4198 / 0**（新增 76 项）；未改任何数值、机制、立绘或 UI 布局。
- 收尾验证（第 15 程，全部在最终 HEAD 上复跑）：`--headless --path . --import` 退出 0；`--headless --path . --quit` 退出 0；单元 `tests/run_tests.gd` **4198 / 0**；八套集成全部 0 失败——结构 **269**、第一章 demo **22**、run save **176**、手柄 **128**、UI 提示 **113**、第一章事件 **34**、菜单 A/B **128**、AI 设置 **45**；`tests/check_exit_clean.sh <godot> 10` → **10/10 clean**；demo 像素资产 **36 / 0**；`git status` 干净，无遗留探针/基准脚本。
- 本程提交：`2e1e860`（基线/探针核实）、`d121e70`（暂停菜单设置回退）、`20bd97c`（关闭回退类残留）、`93ac375`（长局续玩边界）、`03a7581`（菜单往返性能记录）、`c13424c`（污染警告文案），以及本条收尾文档提交。

### 2026-11-04 · 第 14 程

- 任务 1 · 基线（Godot 4.7.stable.official.5b4e0cb0f，本机 `~/workspace/tools/godot/bin/Godot_v4.7-stable_linux.x86_64`）：`--headless --path . --import` 退出 0；`--headless --path . --quit` 退出 0（两份日志 `ERROR` 计数 0）；单元 `tests/run_tests.gd` **4122 / 0**；八套集成全部 0 失败——结构 **269**、第一章 demo **19**、run save **146**、手柄 **112**、UI 提示 **113**、第一章事件 **34**、菜单 A/B **110**、AI 设置 **45**；`tests/check_exit_clean.sh <godot> 10` → **10/10 clean**；demo 像素资产 **36 / 0**。全部数字与第 13 程收尾一致，基线无回归。

### 2026-11-04 · 第 13 程

- 交接：第 12 程已完成并提交（HEAD `eb75783`），工作区干净、无在途改动；本程按任务单继续在第一章现有框架内做有证据的打磨，不推翻玩法框架、不改立绘、不改 AI 默认行为、不做发行相关事项。
- 任务 1 · 基线（Godot 4.7.stable.official.5b4e0cb0f，本机 `~/workspace/tools/godot/bin/Godot_v4.7-stable_linux.x86_64`）：`--headless --path . --import` 退出 0；`--headless --path . --quit` 退出 0；单元 `tests/run_tests.gd` **4049 / 0**；八套集成全部 0 失败——结构 **269**、第一章 demo **17**、run save **115**、手柄 **109**、UI 提示 **111**、第一章事件 **31**、菜单 A/B **110**、AI 设置 **45**；`tests/check_exit_clean.sh <godot> 10` → **10/10 clean**；demo 像素资产 **36 / 0**。全部数字与第 12 程收尾一致，基线无回归。
- 任务 2 · 状态缓存残留扫描（临时探针 `tests/probe_state_cache_13.gd`，真实解码路径 + Codex/Inventory 实例）：
  - 扫描范围：全部模态页的打开/关闭提示、世界交互物、HUD、Hub 提示与教程、剧情/事件页、结算/权属页、Codex/Inventory/Archive/Shop/Inspire 的派生状态；上一程已覆盖的设备/改键刷新未重复改动。
  - 证据 1（词条解码后网格不刷新）：探针用 `RunLoot.starting_words` 建 18 词并绑定 Codex 与 Inventory，页面已构建后调用 `RunLoot.decode_owned_word`（即 `ch1_05`「读禁文」的真实路径）。解码成功、Profile 与本局副本都已置为可读，但 Codex 与 Inventory 的对应卡片仍显示「未解码」——因为解码是原地修改 `WordData.decoded`，从不发 `inventory.changed`，而两个网格只在收到该信号时重建；打开页面本身也不会重新构建。修复：`RunLoot.decode_owned_word` 成功后 `run.inventory.changed.emit()`；规则/数值/交互不变。Hub 的陆沉解读同一类问题：`Hub.decode_word()` 只改 Hub 词副本，教程 Codex 自己的 `RunLoot.starting_words` 副本不刷新；修复为同时标记教程副本并发 `_tutorial_run.inventory.changed`。
  - 证据 2（续玩后事件选择页页脚键位过期）：续玩会跳过章节开场剧情页，`StoryOverlay` 的构建默认值「方向键选择，Enter 确认」从未被刷新；手柄玩家续玩到 `ch1_05` 事件页时，实际确认键是 A 却显示 Enter。`open_story()` 会刷新，`open_choice()` 不会。修复：`open_choice()` 同样调用 `_refresh_device_prompts()`。
  - 验证：同一探针在修复前 `codex_after=未解码 / inventory_after=未解码`，修复后两者均变为词义「净化」，7/7 通过；探针转成断言后删除。`tests/test_word_decoding.gd` +2（成功解码恰好发一次 `inventory.changed`、幂等重试不发）；`tests/test_hub_final.gd` +2（教程副本被解码、教程 Codex 卡片显示词义）；`tests/integration_ch1_event.gd` +3（解码后的词在真实 `main.tscn` 的 Codex/Inventory 网格中显示词义），**31 → 34 / 0**；`tests/integration_ui_prompts.gd` +2（真实手柄 A 事件后新建 StoryOverlay 的 `open_choice` 页脚显示「A 确认」），**111 → 113 / 0**；全量单元 **4049 → 4053 / 0**。未改交互、布局、数值、资产与玩法。
- 任务 3 · 焦点边缘真实手柄断言（临时探针 `tests/probe_focus_edges_13.gd`，真实手柄 A 事件驱动；另用 `tests/probe_pause_confirm_focus_13.gd` 核查暂停菜单原生确认框）：
  - 检查范围：新开页面/子页入口焦点（图鉴、背包、商店、档案馆、言灵、AI 设置、地图、奖励、权柄、结算、剧情/事件、暂停）、关闭后回到打开前控件（覆盖层、设置子页、对话、Hub 商店/教程图鉴）、列表重建后的焦点保持（图鉴选词/AI 回复、商店购买、档案馆升级、键位捕获）、禁用/隐藏控件跳过（既有覆盖之外复查）。
  - 证据（复现）：图鉴中手柄先选中一个词（真实 A），随后异步 AI 回复到达 `_on_ai_intent` 会清空选择并重建词表；修复前焦点落在被释放的旧按钮上，`gui_get_focus_owner()` 变为 `null`，手柄 A 从此无响应。修复：`CodexUI._refresh_words()` 在清空网格前记录当前聚焦词的 `word_id`，重建后把焦点还给同一词的新按钮；覆盖选词、AI 回复、`set_discovered` 与 `inventory.changed` 等所有重建路径。只改焦点恢复，不改选词、AI 预览或装备逻辑。
  - 未复现（不改代码）：暂停菜单的原生 `ConfirmationDialog` 在 headless 与 xvfb 下都不会夺走焦点（探针中重开/关闭前后焦点都在「重新开始」），无法用真实事件复现「关闭后失去焦点」，按任务要求不改；`tests/probe_pause_confirm_focus_13.gd` 仅作核查后删除。
  - 验证：同一探针在修复前 `owner=null`（2 项失败），修复后 `owner` 为同一词的新按钮（7/7 通过）。`tests/integration_gamepad.gd` 新增 3 项真实手柄断言（AI 回复重建后焦点仍存在且可见、仍落在同一 `word_id`、再次按真实 A 仍能选词），**109 → 112 / 0**；全量单元 **4053 / 0**。探针已删除。
- 任务 4 · 长局与边界稳定性（只扩展集成测试，不改存档格式、不改 v1 安全默认、不改坏档口径）：
  - 恢复后的二次续玩：在「主文件损坏 → `.bak` 恢复」之后不再直接死亡收尾，而是在恢复出的 `ch1_rest` 摊位上真实购买第一行、记录花费与剩余残页、保存后再次 `resume_requested` 启动。断言第二次续玩仍回 `ch1_rest`、残页与保存值一致、`_shop_cache` 从存档恢复且该行 `bought=true`、重开商店时该行按钮为 disabled、再次调用 `_on_shop_buy(0)` 不会二次扣费。随后才用该场景触发死亡，继续断言主文件与 `.bak` 一起清空。
  - 已选权柄的 Boss 收尾边界（真实启动）：以 `ch1_01` 存档改写出 `ch1_boss` + `boss_defeated=true` + `authority={"id":"revive",...}` 的存档并重启，断言不生成第二个 Boss、`run_state.authority.id` 仍为 `revive`、权柄选择框不重开、直接进入章末剧情与选择，最终到达结局并清空局内存档。
  - 未来版本主文件 + 有效 `.bak`：先写合法主文件、再用 `SAVE_VERSION + 1` 覆盖主文件（`.bak` 保留合法存档），重启后断言不出现「损坏」丢弃提示、`_resume_data` 已应用、落在存档房间，且启动后主文件可读版本回到当前版本（备份被采用/提升），而不是像「无备份的未来版本」那样丢弃。
  - 验证：`tests/integration_run_save.gd` **115 → 146 / 0**（新增 31 项）；全量单元 **4053 / 0**；未改 `run_save.gd`、存档格式或 v1 迁移口径。
- 任务 5 · 性能检查（临时基准 `tests/bench_codex_acquire.gd`，测完删除；有产品改动）：
  - 目标：选本程之前未测、玩家每次拿词都会遇到的「局内获得新词」路径。第一章开局 18 词，长局可到 40+ 词；`_acquire_word` 会发 `Inventory.changed`，隐藏的图鉴与背包都要重建整张词卡网格。
  - 方法：headless 启动真实 `scenes/main.tscn`，关闭开场，等 MDS 首房就绪；先热身 2 词，再用真实 `_acquire_word` 连续获得 24 个未拥有词，**每次采样之间 `await process_frame`**（匹配真实游玩，避免同帧堆积 `queue_free` 污染）。按词数分两段统计（20→32、32→44），并单独计时隐藏图鉴 `_refresh_words`、`_refresh_combos`、图鉴整体 `refresh()`、隐藏背包 `_refresh()`、HUD `_refresh()`，以及图鉴首次/再次打开；n=6–12。
  - 基线（44 词）：获得新词 median **1406.8 ms**（32→44，n=12）/ **950.9 ms**（20→32，n=12）；其中隐藏图鉴词卡重建 **920.3 ms**、组合卡重建 **74.9 ms**；隐藏背包词卡重建 **586.0 ms**；HUD 仅 0.22 ms；图鉴首次打开 1.86 ms。即每次拿词会卡住 1–1.5 秒，且页面隐藏时仍全量重建。
  - 修复（只改刷新方式，不改布局、数据、交互或数值）：`CodexUI` 与 `InventoryUI` 的词卡改为按 `word.id` 缓存、原地增量更新——新词只创建一张卡，已存在的卡只在与渲染值不同时改文本/颜色/样式；换绑另一局时清空重建一次（保证顺序）。`CodexUI._refresh_combos()` 增加组合指纹，只有已发现/持久组合或数值变化时才重建，避免每次拿词白建组合卡。焦点保持逻辑保留，新增卡不再销毁旧按钮。
  - 优化后（同一基准，44 词）：获得新词 median **35.4 ms**（32→44）/ **35.5 ms**（20→32），降低约 **97.5%**；隐藏图鉴整体 refresh **0.67 ms**（词卡 0.61 ms、组合卡 0.03 ms）、隐藏背包 **0.61 ms**、HUD 0.21 ms；图鉴首次打开 1.67 ms，未把开销挪到首次打开。
  - 回归：`tests/test_codex.gd` +3（刷新不重复建卡、卡片实例复用、解码原地更新样式），`tests/test_ui.gd` +3（背包同样三项）；全量单元 **4053 → 4059 / 0**；八套集成全部 0 失败——结构 269、第一章 demo 17、run save 146、手柄 112、UI 提示 113、第一章事件 34、菜单 110、AI 设置 45。基准脚本已删除；未重复测房间切换、存档写入、提示刷新与续玩启动。
- 任务 6 · 纯文案内容填充（单一类别：休息室入场短句；只加文案与显示，不碰数值、系统、立绘或存档格式）：
  - 现状：第 12 程补的是战斗房结算的「休整」卡（`RestOfferData`），休息室本身进屋只有固定的「休整，或继续前进」目标与通用 HUD，没有一句属于这个空间的文字；Hub NPC 闲聊已在第 11 程扩到每人 11 句，本程避开不重复。
  - 内容：新增 `RestRoomData`，8 句休息室入场白（纸人拨灯芯、屋檐滴水、雨声、空白页、半边柜台、褪色门牌、冷炉灰留灯、墙角晾名字）。进屋时用现有 HUD toast 显示一句；同一房间每次启动只问候一次，回头路不重复刷屏。目标、商店、残碑、休整奖励与房间结构未动。
  - 稳定性：`pick(run_seed, room_id)` 用 `hash("%d:%s")` 稳定选取，不读取或推进 `run.rng`；不写入存档，续玩/掉落序列/房间数据均不受影响。
  - 测试：`tests/test_ch1_content.gd` +63（数量 ≥8、逐句非空/无占位符、唯一、同种子稳定、40 个种子轮换、按房间变化、不推进 run RNG）；`tests/integration_ch1_demo.gd` +2（真实进屋后 HUD 文案等于本局种子选中句、非空），**17 → 19 / 0**；全量单元 **4059 → 4122 / 0**。未改 NPC 立绘、数值、系统与剧情顺序。
- 任务 7 · 第 4 章美术素材实际状态核查（只核查；未改资产、未改可达性）：
  - 背景插画：`assets/backgrounds/smiling_theater.png` 实际存在，**1536×864、8-bit RGB、非隔行、1,779,692 bytes**；人工查看确认画面为红帷幕、纸人观众席、断吊灯、巨型书页舞台与聚光灯。概念源图 `assets/concept/environments/smiling_theater_source.png` 也在仓库（1983×793 RGB）。
  - 接入：`scripts/levels/mds_chapter_room.gd` 的 `BACKGROUNDS[3]` 指向该插画，MDS 第四章 9 个房间（`ch4_01`–`06`、`ch4_rest`、`ch4_boss`、`ch4_vault`）均使用；旧线性场景 `scenes/levels/smiling_theater.tscn` 的 `BackgroundArt` 也引用同一文件。`TheaterBackdrop` 在 MDS 与旧场景都设 `generated_art=true`，实际只叠加聚光灯锥、浮尘与远景色调；程序化帷幕/观众席分支是 `generated_art=false` 的旧回退，默认不执行。
  - 配套素材：第四章 7 种敌人 sprite（`mask_enemy`、`seat_husk`→`collapse_husk`、`echo_enemy`、`choir_summoner`、`typo_beast`、`mirror_sniper`、`ink_bomber`）均为 96×96 RGBA；Boss `smiling_archivist.png` 为 256×256 RGBA；配乐 `chapter_theater.ogg`、旁白 `ch4_intro/outro.ogg`、Boss 二/三阶段语音均存在。MDS 世界 `chapter_4.mdsworld.json` 与 9 个 `ch4_*.tscn` 均在。
  - 文档核对：README 第 43 行与 GDD 第 51 行的表述与实物一致（专属插画 + 轻量光效），不是缺美术；`docs/playtest-0.5.0.md` / `0.6.0.md` 里「程序化舞台、待替换插画」是当时的历史记录，保留不改，不作为当前规划依据。`assets/asset-manifest.json` 生成于 0.10（2026-11-02），早于该插画（文件时间 2026-11-03），因此未收录它；这是清单时间差，不是素材缺口。
  - 发现并更正：`scripts/presentation/theater_backdrop.gd` 的类注释仍写「Drawn procedurally because Magpie image credits were exhausted…」，与当前「绘画打底 + 轻量光效」不符，已改为描述实际分支；只改注释，无行为、资产或可达性变化。
  - 验证：`integration_playability` 第四章两项断言（MDS `BackgroundArt` 纹理为 `smiling_theater.png`、`TheaterBackdrop.generated_art=true`）随 **269 / 0** 全绿；未改第 2–4 章 demo 不可达的现状（第一章结局仍直接收束，不进入第二章）。
- 收尾验证（HEAD `5b89644`，本机 Godot 4.7.stable.official.5b4e0cb0f）：`--headless --path . --import` 与 `--headless --path . --quit` 退出 0，两份日志 `ERROR` 计数 0；单元 **4122 / 0**；八套集成 **269 / 19 / 146 / 112 / 113 / 34 / 110 / 45**（结构 / 第一章 demo / run save / 手柄 / UI 提示 / 第一章事件 / 菜单 A/B / AI 设置），全部 0 失败；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。临时探针与基准脚本均已删除；工作区仅本程应提交的源码/测试/文档改动，无 `.godot/`、`build/`、keystore 或截图产物。无阻塞项；第 7 项待用户确认项保持现状未动。
- 本程提交（旧→新）：`32d8de4` 基线记录、`a94e593` 解码/续玩提示刷新、`ef25c58` 图鉴焦点保持、`71b4074` 恢复续玩与 Boss 边界测试、`58d2ce2` 词卡原地更新性能修复、`71195f5` 休息室入场文案、`5b89644` 第四章美术核查、本条状态与记忆收尾文档。

### 2026-11-04 · 第 12 程

- 交接：第 11 程已完成并提交（HEAD `9719dc9`），工作区干净、无在途改动；本程按任务单继续在第一章现有框架内做有证据的打磨，不推翻玩法框架、不改立绘、不改 AI 默认行为、不做发行相关事项。
- 任务 1 · 基线（Godot 4.7.stable.official.5b4e0cb0f，本机 `~/workspace/tools/godot/bin/Godot_v4.7-stable_linux.x86_64`）：`--headless --import` 退出 0；`--headless --quit` 退出 0；单元 `tests/run_tests.gd` **3969 / 0**；八套集成全部 0 失败——结构 **269**、第一章 demo **17**、run save **73**、手柄 **100**、UI 提示 **104**、第一章事件 **31**、菜单 A/B **110**、AI 设置 **45**。全部数字与第 11 程收尾一致，基线无回归。
- 任务 2 · 提示与文案缓存残留扫描（临时探针 `tests/probe_prompt_cache_12.gd`，真实手柄/键盘事件与真实改键驱动）：
  - 扫描范围：全部模态页页脚/关闭提示、世界交互物（拾取、宝箱、残碑、记忆商店、Hub NPC/传送门/训练碑、MDS 门）、HUD 控制条与武器槽、暂停/设置/键位/帮助/剧情/对话/图鉴/背包/地图/交易所/档案馆/结局屏，以及 Hub 左上目标提示与图鉴 AI 状态。上一程已覆盖的提示未重复改动。
  - 证据：探针 **8 项 / 5 失败**，复现两类：① Hub 左上目标提示写在 `hub.tscn` 里，永远是「A/D 移动 · E 交互」，手柄模式或把交互改到 R 后都不刷新；② 图鉴 AI 未配置状态在点击「AI 解读」时把 `settings` 键写死进文案，之后改键或切到手柄（settings 默认 Back）仍显示旧键。
  - 修复 1（Hub 目标提示）：`Hub` 缓存 `Overlay/TopLeft/Margin/VBox/Hint`，监听 `input_device_changed` 与 `keybinds_changed`，按当前设备生成「A / D 移动 · E 交互」或「左摇杆 移动 · Y 交互」；只改提示生成与刷新，不改目标文案、布局或玩法。
  - 验证 1：同一探针 Hub 三项转绿（8 项 / 2 失败，剩余为图鉴 AI 状态）；`tests/integration_ui_prompts.gd` 新增 4 项真实设备/改键断言，**104 → 108 / 0**。
  - 修复 2（图鉴 AI 未配置状态）：`CodexUI` 用 `_ai_config_hint` 标记当前状态是否为「按 <settings 键> 打开设置」提示，状态写入统一走 `_set_ai_status()`；监听 `keybinds_changed` 并在设备切换时重建该提示，AI 结果/普通状态清除标记，不会被误刷新。只改提示生成与刷新。
  - 验证 2：同一探针 **8/8** 通过；`tests/integration_ui_prompts.gd` 再新增 3 项（键盘 F10、改到 K、手柄 Back），**108 → 111 / 0**；全量单元 **3969 / 0**；菜单 **110 / 0**、手柄 **100 / 0**、AI 设置 **45 / 0** 无回归。探针已删除。
- 任务 3 · 焦点边缘真实手柄断言补齐（临时探针 `tests/probe_focus_edges_12.gd`，真实手柄 A/B/Y/D-pad 事件驱动）：
  - 检查范围：新开页面的入口焦点（图鉴、言灵对话、AI 设置、商店、档案馆、地图、奖励/权柄、结算）、关闭后的焦点回归、列表重建后的焦点保持（图鉴选词、商店购买、档案馆升级、键位捕获）、禁用/隐藏控件跳过（`first_pressable_button`、买空后的焦点）、AI 等待期间禁用提交按钮等。
  - 结果：探针 **9/9 通过**，**未复现产品缺陷**——图鉴选词后网格重建仍把焦点放回同一词的「取消选择」按钮；言灵对话的「言灵」提交按钮在 `set_busy(true/false)` 禁用/恢复后焦点仍在可见控件上；关闭言灵页后无隐藏控件残留焦点。
  - 补测（只加断言，不改产品代码）：`tests/integration_gamepad.gd` 新增 9 项真实手柄断言——图鉴选词后焦点保持（游戏内与 Hub 教程各 2 项）、言灵页提交按钮焦点、AI 等待禁用/恢复焦点、B 关闭言灵页、关闭后无隐藏焦点残留。**手柄集成 100 → 109 / 0**；探针已删除。
- 任务 4 · 长局与边界稳定性（只扩展集成测试，不改存档格式、不改 v1 安全默认、不改坏档口径）：
  - 暂停—设置—恢复组合：在长局续玩场景中连续 3 轮「暂停 → 打开设置 → 关闭设置」，断言每轮暂停/恢复状态、设置页可见、暂停页隐藏，且三轮后生命 66、残页 58、房间 `ch1_rest` 均未被扰动；随后照常写入长局存档。
  - 边界存档（真实启动）：用真实 `ch1_01` 存档改写出两张边界存档并重启主场景——① 房间指向 `ch1_boss`、`boss_defeated=false`，断言落在 Boss 房、Boss 被重新生成、`_mds_boss_arena` 已接管；② 房间指向 `ch1_boss`、`boss_defeated=true`、`authority={}`，断言不再生成第二个 Boss，1.6 s 后弹出权柄选择，选完后进入章末剧情与选择，最终到达结局并记录 `last_ending` / `last_victory`，且通关清空局内存档。
  - 坏档补充（真实启动）：主文件与 `.bak` 同时为 `broken` 时，断言只提示一次「局内存档损坏，已丢弃」、新局从 `ch1_01` 开始、`_resume_data` 为空、`.bak` 被清掉；合法结构但 `version` 为未来版本时，按坏档丢弃并同样给出提示、从 `ch1_01` 开始。
  - 验证：`tests/integration_run_save.gd` **73 → 115 / 0**；全量单元 **3969 / 0**；退出泄漏回归 `tests/check_exit_clean.sh <godot> 10` → **10/10 clean**；临时探针 `tests/probe_boundary_save_12.gd` 18/18 通过后删除。未改存档格式与 v1 迁移口径。
- 任务 5 · 性能检查（临时基准 `tests/bench_resume_boot.gd`，测完删除；有产品改动）：
  - 目标：选上一程未测、玩家实际会遇到的「继续本局」启动路径。先构造一张长局 `ch1_rest` 存档（生命 66/160、墨 44/120、残页 58、污染 63、3 词、2 遗物、两房已清），再连续 6 次以 `resume_requested=true` 真实启动 `scenes/main.tscn`，计时 instantiate / add_child / MDS 世界 / 房间就绪；对照组为 Hub、单个 biome、去掉 `game.gd` 的 main、各 UI 子场景单独 add。
  - 基线（n=6）：cold 2069.1 ms，warm median **1996.6** / avg 2005.5 / min 1960.7 / max 2045.6，存档 11,101 bytes；instantiate 约 202–210 ms，add_child 约 1.84–1.91 s，MDS 世界 +10 ms，房间就绪 +110 ms；main-no-script add 约 364–408 ms，Hub add 约 648–724 ms。分阶段计时定位到图鉴在 `_ready` + `bind` + `set_discovered` + `set_persistent_discovered` 中对隐藏页面完整重建 3–4 次，启动期合计约 0.8–1.2 s；背包 `bind` 约 210 ms。
  - 修复：`CodexUI._ready()` 仅在可见时刷新；新增 `bind_state()`，启动/续玩时先挂 run、本局组合与 Profile 组合，再统一刷新一次；`game.gd` 改走 `bind_state()`。行为不变：单独实例仍构建空状态，游戏内可见时仍按原逻辑刷新。只改刷新时机与次数，不改数据、布局或交互。
  - 优化后（n=6，同一基准）：cold 1524.1 ms，warm median **1466.7** / avg 1478.1 / min 1442.8 / max 1551.0；warm median 降低 **529.9 ms（约 26.5%）**。剩余的一次图鉴重建（约 300 ms）未再压缩，避免把开销挪到首次打开。
  - 验证：全量单元 **3969 / 0**；`integration_menus` **110 / 0**、`integration_gamepad` **109 / 0**、`integration_ui_prompts` **111 / 0**、`integration_run_save` **115 / 0**。基准脚本已删除；未重复测上一程的房间切换、存档写入与提示刷新。
- 任务 6 · 纯文案内容填充（单一类别：战斗房结算的「休整」卡文案；只改文案与测试，不碰数值、系统与立绘）：
  - 现状：每间战斗房结算固定出现一张休整卡，标题永远「修补记忆」、描述永远两行；第 11 程已把 Hub NPC 闲聊扩到 11 句，第 10/11 程已扩事件、残碑与交易所纸人，故本程只补这一处尚未轮换的文案。
  - 内容：新增 `RestOfferData`，8 组标题/短句（修补记忆、烘干墨迹、借一页空白、压平折角、给灯添油、念一遍名字、让雨停在窗外、缝住这一页），效果行统一为「恢复 35 生命与 45 墨量。污染降低 12。」；`RunLoot.choices` 按 `run_seed + room_number` 用 `hash` 稳定选取，不读取或推进 `run.rng`，续玩与掉落序列不变；每间房仍只有一张休整卡，数值未动。
  - 测试：`tests/test_ch1_content.gd` 新增 80 项断言——变体数量、标题唯一、效果数字与属性名保留、无占位符、同种子稳定、跨种子轮换、`RestOfferData.pick` 不推进 run RNG、`RunLoot.choices` 的休整卡与选取结果一致。单元 **3969 → 4049 / 0**。
  - 验证：`integration_playability` **269 / 0**、`integration_ch1_demo` **17 / 0**；未改 NPC 立绘、数值、系统与剧情顺序。
- 收尾验证（HEAD `c1fe6b7`，本机 Godot 4.7.stable.official.5b4e0cb0f）：`--headless --import` 与 `--quit` 退出 0；单元 **4049 / 0**；八套集成 **269 / 17 / 115 / 109 / 111 / 31 / 110 / 45**（结构 / 第一章 demo / run save / 手柄 / UI 提示 / 第一章事件 / 菜单 A/B / AI 设置），全部 0 失败；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**；import/quit 日志 `ERROR` 计数 0。临时探针与基准脚本均已删除；工作区仅本程应提交的源码/测试/文档改动，无 `.godot/`、`build/`、keystore 或截图产物。无阻塞项；待用户确认第 7 项保持现状未动。
- 本程提交（旧→新）：`9e38398` 基线记录、`7d1e8e0` Hub 目标提示刷新、`765bc47` 图鉴 AI 提示刷新、`318f20c` 手柄焦点边缘断言、`7df10cb` 长局/边界存档测试、`46a108d` 续玩启动图鉴重建优化、`c1fe6b7` 休整卡文案轮换、本条状态与记忆收尾文档。

### 2026-11-04 · 第 11 程

- 交接：第 10 程已完成并提交（HEAD `438aada` 收尾文档提交），工作区干净、无在途改动；本程继续在第一章现有框架内做有证据的打磨。
- 任务 1 · 基线（Godot 4.7.stable.official.5b4e0cb0f，本机 `~/workspace/tools/godot/bin/Godot_v4.7-stable_linux.x86_64`）：`--headless --import` 退出 0；`--headless --quit` 退出 0；单元 `tests/run_tests.gd` **3959 / 0**；结构集成 **269 / 0**；第一章 demo 集成 **17 / 0**；run save 集成 **35 / 0**；手柄集成 **96 / 0**；UI 提示集成 **90 / 0**；第一章事件集成 **31 / 0**；菜单 A/B 集成 **99 / 0**；AI 设置集成 **45 / 0**；`tests/check_exit_clean.sh <godot> 10` → **10/10 clean**；demo 像素资产 **36 / 0**。全部数字与第 10 程一致，基线无回归。
- 本程提交（旧→新）：`71b61d9` 基线记录。
- 任务 2 · 提示与文案缓存残留扫描（临时探针 `tests/probe_prompt_cache.gd`，真实设备事件与真实改键信号驱动）：
  - 证据：探针 **14 项 / 9 失败**，复现五类：① 设置页在键位子页打开期间改「设置」键后，页脚仍显示「按 F10 或 Esc 关闭」；② 标题二次确认面板页脚永远写死「A 确认 · B 取消」，键盘玩家看到的也是手柄键；③ 图鉴关闭提示写死「C / Esc」，把 `codex` 改到 G 后仍显示 C（此时 C 已不能关闭）；④ 背包关闭提示与页脚写死「Tab / Esc」，把 `inventory` 改到 I 后仍显示 Tab；⑤ Hub 对话末行在打开时写死 `npc_inspire` 键（把键盘言灵改成 U 后开对话，切到手柄仍显示「按 U」）。
  - 修复：`SettingsMenu` 连接 `keybinds_changed` 刷新页脚；`ConfirmPanel` 新增 `_hint` 字段与 `_refresh_hint()`，按当前设备显示「Enter/Esc」或「A/B」并监听 `input_device_changed`；`CodexUI` / `InventoryUI` 的关闭提示改为读取当前 `codex` / `inventory` 绑定（`close_prompt("<当前键> / Esc")`）并监听 `keybinds_changed`；Hub 对话末行改为不含键位的「也可以选「言灵对话」…」，由本来就会随设备/改键刷新的「言灵对话 [键]」按钮承担键位提示，不再缓存旧键。
  - 验证：同一探针 **14/14** 通过；`tests/integration_ui_prompts.gd` 新增 14 项同类断言，**90 → 104 / 0**；全量单元 **3959 / 0**；`integration_menus` **99 / 0**、`integration_gamepad` **96 / 0** 保持全绿；探针已删除。仅改提示生成与刷新，不改交互、布局、数值、资产或玩法。
- 任务 3 · 焦点边缘真实手柄断言补齐（临时探针 `tests/probe_focus_edges.gd`，全部由真实手柄 A/B 事件驱动）：
  - 检查范围：存档/商店买到最后一件可负担物品后焦点是否留在刚禁用的行、空词表图鉴的入口焦点、以及关闭后焦点回归与禁用控件跳过在既有覆盖之外的路径。
  - 结果：探针 **14/14 通过**，**未复现产品缺陷**——档案馆买空碎片后 `_keep_focus_pressable` 会把焦点移出禁用行；Hub 商店买到最后一件后焦点落到下一个可按键（买不起的行仍可按 A 得到「记忆碎片不足」反馈，属既有设计，不改）；空词表图鉴的 `focus_entry` 回退到「返回」，按 A 能发出 `close_requested`。
  - 补测（只加断言，不改产品代码）：`tests/integration_menus.gd` 新增 11 项真实手柄断言（档案馆买空后焦点存在/可按/可见且 A 能关闭；Hub 商店买空后焦点可按、A 给出「记忆碎片不足」反馈）；`tests/integration_gamepad.gd` 新增 4 项（空词表图鉴焦点存在/可按/可见、A 发出关闭）。**menus 99 → 110 / 0**，**gamepad 96 → 100 / 0**；探针已删除。
- 任务 4 · 长局存读与坏档稳定性（只扩展集成测试，不改存档格式、不改 v1 安全默认、不改坏档口径）：
  - 长局往返：在既有 `ch1_03` 续玩场景上继续真实进房 `ch1_04 → ch1_06 → ch1_rest`，写入更完整状态（生命 66/160、墨量 44/120、残页 58、污染 63、新词 `dongjie`、新遗物 `blood_quill`、新武器 `ink_axe`、两个已清房间、短语签名与位置），保存后退出并以 `resume_requested` 重启，断言房间、数值、词/遗物/武器、短语、已清房间与位置全部还原。
  - 备份恢复（真实启动路径）：同一长局状态连续写两次使 `.bak` 与主文件一致，删除主文件后重启，断言从 `.bak` 续玩且主文件被提升回可读；再把主文件写成 `broken` 重启，断言仍从 `.bak` 恢复、不显示「损坏」丢弃提示、主文件再次被提升。
  - 坏档丢弃提示：无备份的损坏主文件与「版本正确但子结构损坏」两种坏档，断言新开一局时 HUD 出现「局内存档损坏，已丢弃；开始新的一局」；死亡同时清除主文件与 `.bak`。
  - 验证：`tests/integration_run_save.gd` **35 → 73 / 0**；全量单元保持（本项未改产品代码）。未改存档格式与 v1 迁移口径。
- 任务 5 · 性能检查（临时基准 `tests/bench_perf.gd`，测完删除；未改任何产品代码）：
  - 方法：headless 启动 `scenes/main.tscn`（关闭章节开场）→ 进入第一章 MDS 世界；以 3 轮 × 6 个真实房间（`ch1_02 → ch1_03 → ch1_04 → ch1_06 → ch1_rest → ch1_01`）共 18 次 `await world.load_room()` + 1 帧计时；再用 `MDSRoomCamera.Transition.CUT` 跑 2 轮同样 12 次，隔离掉过渡动画只测房间构建/拆除；随后连续 20 次 `save_run_now()` 计时；最后在 HUD 与房间提示在线时连续触发 500 次 `input_device_changed` 计时。
  - 数字（本机 Godot 4.7.stable headless，一次代表性运行）：房间切换 **median 450.8 ms / avg 453.8 / min 440.9 / max 511.0**（n=18）；`room_fade_time=0.220 s`、无 `room_camera`，即 450 ms 基本是 `_fade_to` 两次 0.22 s 的刻意过渡；**CUT 构建 median 14.0 ms / avg 13.5 / min 10.3 / max 20.0**（n=12）；存档写入 **median 3.96 ms / avg 4.70 / min 2.39 / max 9.98**（n=20，文件 **10,834 bytes**）；500 次设备切换提示刷新 **136.6 ms（0.273 ms/次）**；headless 冷启动到首房 **4.0–5.9 s**（含调试脚本编译，跨次波动大，不作为发行性能结论）。
  - 结论：房间切换体感耗时来自设计内的 0.44 s 淡入淡出，真实房间构建仅约 14 ms；存档写入约 4 ms；提示刷新约 0.27 ms/次。**没有可测量的性能问题，本程不做优化**；基准脚本已删除，方法与数字留档供下一程避免重复测量。
- 任务 6 · 纯文案内容填充（单一类别：Hub 五名 NPC 常驻闲聊；只改 `.tres` 文案与测试，不碰数值、系统与立绘）：
  - 内容：每名 NPC 从 7 句扩到 11 句，共 +20 句；围绕各自既有设定收束——陆沉（灯油/名册挪位/别把碎片全交出去/名字不能念出声）、阿砚（碎片别进炉/断页剑先认你/刀自己挑主人/炉灰里的名字）、咕噜（要找的东西先看见你/最值钱的是记得/旧货夜里翻身/摊子认得回家的路）、闻烬（情报与沉默都有价/老师失踪那行空白/不写你是怕定稿/笔不是用来写别人）、白榆（桥板在数人/第七个点等先走的人/桥与回头/桥没断说明还有没还完的）。
  - 测试：`tests/test_hub_final.gd` 的最低句数 7 → 11（标签改名 `has_eleven_lines`），新增每名 NPC「speaker 与 display_name 一致」与「文案不含 `%s`/`%d`/`{` 占位符」两项内容断言；原先 `_test_guru` 的推进上限 10 次不足以走完 11 句，改为 20 次（否则商店不打开、玩家不解冻）。单元 **3959 → 3969 / 0**。
  - 验证：八套集成全部 0 失败——结构 269、第一章 demo 17、run save 73、手柄 100、UI 提示 104、第一章事件 31、菜单 110、AI 设置 45；`--headless --import` 退出 0。未改 NPC 立绘、数值、系统与剧情顺序。
- 收尾验证（HEAD `e4ba87f`，本机 Godot 4.7.stable.official.5b4e0cb0f）：`--headless --import` 与 `--quit` 退出 0；单元 **3969 / 0**；八套集成 **269 / 17 / 73 / 100 / 104 / 31 / 110 / 45**（结构 / 第一章 demo / run save / 手柄 / UI 提示 / 第一章事件 / 菜单 A/B / AI 设置），全部 0 失败；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**；全部测试与导入/退出日志 `ERROR` 计数 **0**。临时探针与基准脚本均已删除；工作区仅本程应提交的源码/测试/文档改动，无 `.godot/`、`build/`、keystore 或截图产物。无阻塞项；待用户确认第 7 项保持现状未动。
- 本程提交（旧→新）：`71b61d9` 基线记录、`01c1ec4` 提示缓存刷新、`0b18de9` 焦点边缘断言、`bc5177b` 长局/备份存档测试、`99b7d5a` 性能记录、`e4ba87f` NPC 文案填充、本状态与记忆收尾文档提交。

### 2026-11-04 · 第 10 程

- 任务 1 · 基线（Godot 4.7.stable.official.5b4e0cb0f，本机 `~/workspace/tools/godot/bin/Godot_v4.7-stable_linux.x86_64`）：`--headless --import` 退出 0；`--headless --quit` 退出 0；单元 `tests/run_tests.gd` **3959 / 0**；结构集成 **269 / 0**；run save 集成 **35 / 0**；手柄集成 **96 / 0**；UI 提示集成 **50 / 0**；第一章 demo 集成 **17 / 0**；第一章事件集成 **20 / 0**；菜单 A/B 集成 **89 / 0**；AI 设置集成 **40 / 0**；`tests/check_exit_clean.sh <godot> 10` → **10/10 clean**；demo 像素资产 **36 / 0**。基线无回归。
- 任务 1 附注 · 「输入集成 14 / 0」标签核对：仓库内没有独立的 `integration_input.gd`（`git log --all` 也从未存在过该文件）；输入覆盖由 `integration_ch1_demo.gd` 承担，该套件在第 9 程由 14 增至 17。后续状态文件只记八套实际存在的集成，不再单列重复的「输入集成」。
- 交接：第 9 程已完成并提交（HEAD `c76405c`），工作区干净、无在途改动、无阻塞项；本程继续在第一章现有框架内做有证据的打磨。
- 任务 2 · 候选 1（设备感知提示在新位置仍有遗漏）：
  - 证据：临时探针 `tests/probe_stale_prompts.gd` 在真实设备切换下复现 11 处：① MDS 房间的隐藏书库/捷径门提示在房间加载时写死键位，房间内切手柄后门上的 `MDSGate` 提示与已显示的 Label 仍是「按 E」；② 首次 Hub 教程第 1 步提示写死 C，切换设备后不更新；③ 暂停页脚「按 P 继续」在暂停页打开期间不随设备更新；④ 结束屏「按 R 回到最后的档案馆」与「返回档案馆 [R]」在场景加载时写死；⑤ 剧情/事件页的「继续 [E]」与「方向键选择，Enter 确认」不随设备更新；⑥ 图鉴造句区的「装备到 [Q] / [F]」在设备切换后不更新；⑦ 图鉴 AI 未配置提示写死 F10。
  - 修复：`MDSChapterRoom` 在门 gate 上保存提示后缀，监听 `input_device_changed` 同时刷新 gate prompt 与已显示的 Label；`TutorialFlow` 记录当前步骤并在设备切换时重建当前步骤文案；`PauseMenu` 抽出 `_refresh_footer()` 并监听设备信号；`EndingScreen` 保存 hint/按钮引用并在设备切换时刷新；`StoryOverlay` 保存 hint、刷新「继续 [键]」与「方向键选择，X 确认」；`CodexUI` 用 `prompt_label(&"cast_1"/&"cast_2")` 生成装备按钮并在设备切换时刷新，AI 未配置提示改读 `prompt_label(&"settings")`；`GameFlow.key_label` 对内置 UI 动作（`ui_accept`/`ui_cancel` 只有 keycode、没有 physical_keycode）回退读 keycode，使确认键能显示 Enter 而不是空串。仅改提示与刷新，不改交互、布局、数值或资产。
  - 验证：同一探针 **23/23** 通过；`tests/integration_ui_prompts.gd` 新增 30 项（房间门 prompt/Label、教程三步、暂停页脚、结束屏、剧情页、图鉴装备按钮与 AI 提示，均做键盘→手柄→键盘往返），**80 / 0**；全量单元 **3959 / 0**；探针已删除。
- 任务 3 · 候选 2（AI 设置页手柄入口焦点）：
  - 证据：同一探针在手柄模式下打开 `AISettingsUI`，焦点落在「接口地址」`LineEdit`；手柄无法输入文字，按 A 也没有反应，必须先按方向键才能到「启用 AI 解读」或「保存」。与第 7 程修过的言灵页入口焦点属同类问题。
  - 修复：`AISettingsUI.open()` 按当前设备选入口——手柄聚焦「启用 AI 解读」开关（可按 A 直接切换），键盘/鼠标仍聚焦接口地址输入框；不改表单字段、默认值、保存逻辑或 AI 行为。
  - 验证：`tests/integration_ai_settings.gd` 新增 5 项：键盘打开焦点在接口地址；真实 D-pad 事件切到手柄；手柄打开焦点在启用开关；真实 A 按下切换启用状态；随后恢复键盘/关闭页面。**45 / 0**；全量单元 **3959 / 0**。
- 任务 4 · 候选 3（地图叠在模态页上导致暂停状态错乱）：
  - 证据：键盘玩家打开图鉴（`_overlay=codex`、`paused=true`）后按 M，`game._input` 仍会打开 `MapOverlay`；再按 M 关闭地图时，`MapOverlay.close()` 无条件 `paused=false`，图鉴仍可见但游戏已在底下恢复运行。地图不挂在 `_overlay` 栈上，因此它是唯一能叠在模态页之上的页面。
  - 修复：`game._input` 在地图快捷键分支前增加守卫——已有 `_overlay` 时 M 不打开地图（模态页保持自己的暂停与输入所有权）；地图本身的打开/关闭与暂停逻辑不变。
  - 验证：`tests/integration_menus.gd` 新增 10 项真实键盘/手柄断言：图鉴打开时按 M 地图不打开、暂停保持、图鉴保持；Esc 关闭图鉴并解除暂停；普通游戏中 M 仍可打开/关闭地图且暂停状态正确。**99 / 0**；全量单元 **3959 / 0**。
- 任务 5 · 可选回归（事件房变体在 run save/resume 后保持一致）：
  - 现状：`Ch1EventData.pick` 只依赖 `run_seed + room_id`，`RunSave` 会保存 `seed` 与 `rng_state`，但此前没有集成测试证明「事件页未选时保存 → 续玩 → 同一事件房重开同一变体」。
  - 补测：`tests/integration_ch1_event.gd` 在真实运行中把本局种子固定为非零值，进入 `ch1_05` 记录实际 eyebrow/title/两个按钮文案，`save_run_now()` 后释放场景并以 `resume_requested` 重启；断言续玩保留 seed、回到 `ch1_05`、事件自动重开，且重新 `pick` 的 eyebrow/title/read_label/take_label 与保存前一致；随后沿用续玩场景完成原有的解码/污染/残页断言。
  - 验证：`integration_ch1_event` 由 **20 → 31 / 0**；全量单元 **3959 / 0**。
- 任务 6 · 候选 1 的残留（对话页打开期间切设备）：
  - 证据：临时探针 `tests/probe_dialogue_device.gd` 打开陆沉对话（键盘「继续 [E]」），切到手柄后仍显示「继续 [E]」；`DialogueUI._refresh()` 只在打开与翻页时调用，是任务 2 扫描中的最后一处同类遗漏。
  - 修复：`DialogueUI._ready()` 连接 `Flow.input_device_changed`，打开期间收到设备切换就重跑 `_refresh()`，刷新「继续/结束 [键]」与「言灵对话 [键]」；不改对白、翻页或关闭逻辑。
  - 验证：同一探针 3/3 通过；`integration_ui_prompts` 新增 3 项（键盘「继续 [E]」、言灵按钮键位、切手柄后「继续 [Y]」），**83 / 0**；全量单元 **3959 / 0**；探针已删除。
- 任务 7 · 候选 4（改键后 HUD 与世界提示仍显示旧键）：
  - 证据：临时探针 `tests/probe_keybind_prompts.gd` 复现 4 处：① HUD 控制条写死 J/空格/L/Q/F 等键，把攻击改成 K 后仍显示「J 攻击」；② 手柄跳跃改到 Y 后 HUD 仍显示「A 跳跃」；③ 拾取物提示在交互键改成 R 后仍显示「E 拾取」；④ MDS 房间门提示仍显示「按 E」。根因是这些标签在构建/进入范围时只读一次键位，且 `GameFlow` 改键没有任何变更通知。
  - 修复：`GameFlow` 新增 `keybinds_changed` 信号，在 `set_keybind` / `set_joypad_bind` / `reset_keybinds` / `apply_keybinds` 后发出；HUD 控制条改为逐项读 `prompt_label()` 生成（移动键也读键盘绑定），并监听改键信号刷新控制条与武器槽；拾取物、残碑、记忆商店、Hub NPC/传送门/训练碑、MDS 房间门、暂停页脚、教程、图鉴装备按钮、结束屏均监听同一信号刷新各自提示。仅改提示生成与刷新，不改输入映射、玩法或数值。
  - 验证：同一探针 7/7 通过；`integration_ui_prompts` 新增 7 项（HUD 键盘 J→K、手柄 A→Y、拾取物 E→R、房间门 E→R），**90 / 0**；全量单元 **3959 / 0**；探针已删除。
- 本程收尾（2026-11-04）：
  - 交接说明：第 9 程已完成并提交（HEAD `c76405c`），工作区干净；本程按任务单继续在第一章现有框架内做有证据的打磨，未改玩法框架、立绘、AI 默认行为或发行相关脚本。
  - 完成项：任务 1 基线（含「输入集成 14」标签核对：仓库内无独立 `integration_input.gd`，输入覆盖在 `integration_ch1_demo.gd`）；任务 2 设备感知一次性提示（MDS 房门、教程、暂停页脚、结束屏、剧情页、图鉴装备/AI 提示 7 处）；任务 3 AI 设置页手柄入口焦点；任务 4 地图叠在模态页上的暂停错乱；任务 5 事件房变体 run save/resume 回归；任务 6 对话页打开期间设备切换（任务 2 残留）；任务 7 改键后的缓存键位（HUD、拾取物、残碑、记忆商店、Hub NPC/传送门/训练碑、MDS 房门、暂停、教程、图鉴、结束屏）。
  - 最终验证（收尾提交前 HEAD `5aec325`）：单元 **3959 / 0**；结构集成 **269 / 0**；第一章 demo **17 / 0**；run save **35 / 0**；手柄 **96 / 0**；UI 提示 **90 / 0**；第一章事件 **31 / 0**；菜单 A/B **99 / 0**；AI 设置 **45 / 0**；`--headless --import` 与 `--quit` 退出 0；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。
  - 本程提交（旧→新）：`554b394` 基线、`a6e11c3` 一次性提示设备感知、`57c7cd8` AI 设置手柄入口焦点、`42a8fb0` 地图模态守卫、`a90e278` 事件变体续存、`dd97de5` 对话页设备切换、`5aec325` 改键缓存刷新（本条收尾文档提交随后）。
  - 探针 `probe_stale_prompts` / `probe_dialogue_device` / `probe_keybind_prompts` 均已转成断言并删除；工作区无未提交源码/测试，无阻塞项。
  - 待用户确认第 7 项（暂停菜单打开设置后关闭的去向）保持现状，未改。

### 2026-11-04 · 第 9 程

- 交接：第 8 程启动失败（`.supervisor/session8.log` 只有 `unrecognized_model` 警告，无提交、无状态文件更新），本程是事实上的第 8 程接力，编号按任务单记为第 9 程；第 8 程不计为已完成工作。工作区遗留未提交探针 `tests/probe_close_prompts.gd`，本程第一步已核查处理（见任务 1b）。
- 任务 1 · 基线（Godot 4.7.stable.official.5b4e0cb0f，本机 `~/workspace/tools/godot/bin/Godot_v4.7-stable_linux.x86_64`）：`--headless --import` 通过；`--headless --quit` 退出 0；单元 `tests/run_tests.gd` **3874 / 0**；结构集成 **269 / 0**；输入集成 **14 / 0**；run save 集成 **35 / 0**；手柄集成 **80 / 0**；UI 提示集成 **9 / 0**；第一章事件集成 **20 / 0**；菜单 A/B 集成 **89 / 0**；AI 设置集成 **40 / 0**；`tests/check_exit_clean.sh <godot> 10` → **10/10 clean**。基线无回归。
- 任务 1b · 孤儿探针核查：`tests/probe_close_prompts.gd` 确为候选 A（模态页关闭提示设备感知）所需的探针，检查交易所/档案馆/言灵/图鉴/背包/说明/键位/地图八类页面。
  - 初次运行：交易所、档案馆两处直接复现「手柄下仍写死 Esc」；其余页面跑不到——探针以 `-s` SceneTree 脚本启动时，主脚本在 autoload 注册前编译，`npc.gd`/`codex_ui.gd` 中的 `Flow.*` 直接引用导致依赖脚本编译失败（与第 4 程 Pickup/残碑/宝箱同类问题）。
  - 处理：把探针改为运行期 `load()` 页面脚本（探针自身改动，不改产品行为），使全部页面可复现；结论：探针与候选 A 直接相关、完整可用，已复用为复现证据，转成集成断言后删除（不留未提交文件）。
- 任务 2 · 候选 A（模态页关闭提示写死 Esc）：
  - 证据：探针在真实设备切换下确认八类页面关闭提示不随设备变化：交易所 `离开交易所 [Esc]`、档案馆 `合上档案  [Esc]`、言灵 `离开 [Esc]`、图鉴 `返回 [C / Esc]`、背包 `返回 [Tab / Esc]` 与页脚 `ESC 关闭`、说明 `继续冒险  [Esc]`、键位页 `返回  [Esc]` 与「Esc / Back 取消当前修改」、地图 `按 M 或 Esc 关闭`。手柄实际返回键是 B（`ui_cancel`）。
  - 修复：`GameFlow` 新增 `close_prompt(keyboard_alts := "Esc")`——手柄返回 `ui_cancel` 的绑定标签（B），键盘返回页面自己的快捷键（默认 Esc）；九处模态页（交易所、档案馆、言灵、图鉴、背包、说明、键位、地图、设置）改用该提示，并监听 `input_device_changed` 在页面打开期间实时切换。仅改文案与刷新，不改关闭行为、布局、数值或资产。
  - 验证：同一探针 **17/17** 通过；`tests/integration_ui_prompts.gd` 新增 28 项真实手柄/键盘事件断言（真实按 B/按 Esc 驱动 `Flow` 设备追踪，逐页断言按钮与页脚/提示文本、键盘备选快捷键保留），**37 / 0**；全量单元 **3874 / 0**；其余七套集成保持原数字全绿；探针文件已删除。
- 任务 3 · 候选 B（图鉴/背包的焦点边缘）：
  - 证据：临时探针 `tests/probe_focus_edges.gd`（真实 D-pad/A/B）复现三处：① Hub 内按十字键↑打开图鉴后焦点为 `null`，按 A 毫无反应（教程第 2 步要求选词，手柄玩家卡住）；② 运行内图鉴打开时初始焦点落在「返回」按钮，按 A 直接关页而不是选词；③ 图鉴内有 2 个禁用按钮，原入口逻辑只取 `find_children` 的第一个 Button，不跳过 disabled（禁用控件无法 grab_focus）。关闭图鉴/背包后焦点为 null，但这些场景没有可回归的既有焦点控件，探针确认未留下隐藏控件上的陈旧焦点。
  - 修复：`GameFlow` 新增 `first_pressable_button(root)`（跳过 disabled/不可见）；`CodexUI` 新增 `focus_entry()`（优先第一个词的「选择」按钮，没有词时退回「返回」）；`game.gd::_toggle_overlay` 改用入口焦点并记录打开前焦点、`_close_overlay` 在控件仍有效且可见时恢复；Hub 的教程图鉴打开后调用 `focus_entry()`，关闭时恢复打开前焦点。不改玩法、数值、布局或立绘。
  - 验证：同一探针 **21/21** 通过（Hub 图鉴焦点=首个「选择」，A 选中 1 个词且不关页；运行内图鉴同样；禁用按钮被跳过）；`tests/integration_gamepad.gd` 新增 16 项真实手柄断言（背包/图鉴入口焦点、A 选词不关页、B 关闭、无陈旧焦点、禁用跳过），**96 / 0**；全量单元 **3874 / 0**；其余七套集成保持全绿；探针文件已删除。
- 任务 4 · 候选 C（纯文案填充，不改数值/系统/立绘）：
  - 购买后的纸人反馈：`Ch1ShopData` 新增 5 句 `BUY_LINES` 与 `pick_buy(run_seed, shop_id, row)`（按局种子 + 摊位 + 行号稳定选取，不消耗 run RNG）；`RunShopUI.mark_bought` 增加可选成交台词（缺省仍是「成交。」，保持既有调用兼容）；`game._on_shop_buy` 传入本局本行台词。库存、价格、购买效果不变。
  - 事件房：`Ch1EventData.variants()` 由 5 个增至 7 个（新增「落款」「补页」），机制常量与选项行为不变。
  - 残碑：`MemoryStele.EPITAPHS` 由 6 条增至 8 条，按 `stele_id` 的稳定选取与奖励 roll 不变。
  - NPC 闲聊：5 名 NPC 的 DialogueData 各补 2 句（5 → 7 句），只改对白文本，未触碰任何立绘/职能/数值/AI 提示词。
  - 验证：`test_ch1_content` 新增 78 项（成交台词非空/唯一/稳定/40 seed 轮换/按行号与摊位变化；事件与碑文最小数量提高）；`test_hub_final` 的 NPC 台词下限提高到 7；`integration_ch1_demo` 新增 3 项真实购买断言（走 `_on_shop_buy`，成交提示等于 seed/摊位/行号选中的台词且不是通用「成交。」），**17 / 0**；全量单元 **3952 / 0**；其余七套集成全绿。
- 任务 5 · 额外打磨（残留扫描发现的两处写死键位文案）：
  - 记忆商店提示：`scripts/levels/memory_shop.gd` 的「按 E 用残页换物」既不在 `_ready` 也不在设备切换时刷新，手柄下仍显示 E（第 4 程修过拾取物/宝箱/残碑，遗漏了商店）。修复：解析 `/root/Flow`、在 `_ready` 与 `input_device_changed` 时用 `prompt_label(&"interact")` 刷新；键盘/手柄分别为 E / Y。
  - 掉落词描述：`RunLoot.choices` 生成的词条奖励描述写死「按 C 组合新短语」，手柄玩家看到的是无效键位。改为不含键位的「加入词库，可在语言图鉴里组合新短语。」；不改奖励种类、数量或词池。
  - 验证：`integration_ui_prompts` 新增 3 项（记忆商店提示键盘 E / 手柄 Y / 切回键盘），**40 / 0**；`test_demo_loot` 新增 7 项（真实生成的词奖励描述不含「按 C」且指向语言图鉴；顺带修正夹具里对 `RefCounted` 调用 `free()` 导致 Profile 泄漏的问题），**140 / 0**；全量单元 **3959 / 0** 且退出 0 泄漏。
- 任务 6 · 额外打磨（Hub 世界提示的设备切换）：
  - 证据：Hub 的 NPC 交谈、传送门出发、训练碑试放三处提示只在 `_ready` 读取一次 `Flow.prompt_label()`，Hub 内切换设备后仍显示旧键（第 4 程修过场景内拾取物/宝箱/残碑，Hub 这三处遗漏）；`npc.gd` 还是直接引用 `Flow` 自动加载名，正是第 9 程探针在 `-s` 下编译失败的来源之一。
  - 修复：三处改为从 `/root/Flow` 懒解析 `GameFlow`，监听 `input_device_changed` 刷新提示（`npc.gd`/`portal.gd` 用现有 `prompt_label` 字段，`training_dummy.gd` 把局部 Label 提为 `_prompt` 字段）。不改交互、数值或立绘。
  - 验证：`integration_ui_prompts` 新增 10 项（Hub NPC/传送门/训练碑在键盘 E ↔ 手柄 Y 之间来回切换），**50 / 0**；全量单元 **3959 / 0**；其余七套集成全绿。
- 本程收尾（2026-11-04）：
  - 交接说明：第 8 程启动失败（仅 `.supervisor/session8.log` 的 `unrecognized_model` 警告，无提交、无状态更新），不计为已完成工作；本程为事实上的第 8 程接力，编号第 9 程。孤儿探针 `tests/probe_close_prompts.gd` 已核查、复用并在转成断言后删除，工作区无遗留。
  - 完成项：任务 1 基线；任务 1b 孤儿探针核查；任务 2 候选 A（模态页关闭提示设备感知）；任务 3 候选 B（图鉴/背包入口焦点、禁用跳过、关闭焦点恢复）；任务 4 候选 C（购买后纸人反馈、事件 7 变体、残碑 8 条、NPC 各 7 句）；任务 5/6 额外修复（记忆商店与词奖励文案、Hub NPC/传送门/训练碑提示随设备切换）。
  - 最终验证（收尾提交前 HEAD `4e65028`）：单元 **3959 / 0**；结构集成 **269 / 0**；输入集成 **14 / 0**；run save **35 / 0**；手柄 **96 / 0**；UI 提示 **50 / 0**；第一章 demo **17 / 0**；第一章事件 **20 / 0**；菜单 **89 / 0**；AI 设置 **40 / 0**；`--headless --import` 与 `--quit` 退出 0；退出泄漏 **10/10 clean**；单元测试退出无 ObjectDB/resource 泄漏。
  - 本程提交（旧→新）：`1897364` 基线+探针核查、`01f7ff7` 关闭提示设备感知、`2580fb9` 图鉴入口焦点、`11d5022` 文案填充、`e3b7a31` 残留键位文案、`4e65028` Hub 提示刷新（本条收尾文档提交随后）。
  - 工作区干净；无阻塞项；无在途未提交改动。待用户确认第 7 项保持现状未动。

### 2026-11-04 · 第 7 程

- 任务 1 · 基线（Godot 4.7.stable.official.5b4e0cb0f，本机 `~/workspace/tools/godot/bin/Godot_v4.7-stable_linux.x86_64`）：`--headless --import` 通过；`--headless --quit` 退出 0；单元 `tests/run_tests.gd` **3782 / 0**；结构集成 **267 / 0**；输入集成 **11 / 0**；run save 集成 **35 / 0**；手柄集成 **78 / 0**；UI 提示集成 **9 / 0**；第一章事件集成 **20 / 0**；菜单 A/B 集成 **78 / 0**；AI 设置集成 **40 / 0**；`tests/check_exit_clean.sh` **10/10 clean**。基线无回归。
- 任务 2 · 第 4 章美术素材核查（只核查；未改资产/立绘，未改第 2–4 章可达性）：
  - 背景插画：`assets/backgrounds/smiling_theater.png`，1536×864 RGB，是专属绘画（红帷幕、观众席纸人、断吊灯、巨型书页舞台）；概念源图 `assets/concept/environments/smiling_theater_source.png`（1983×793）也在仓库。
  - 接入情况：MDS 第四章 8 个房间经 `scripts/levels/mds_chapter_room.gd` 的 `BACKGROUNDS[3]` 使用该插画；旧线性场景 `scenes/levels/smiling_theater.tscn` 也以 `BackgroundArt` 引用同一文件。`scripts/presentation/theater_backdrop.gd` 以 `generated_art=true` 运行，只叠加聚光灯、地面光斑与浮尘；早期程序化帷幕/观众席/纸人分支保留但默认不执行。
  - 配套素材：第四章 7 种敌人 sprite（mask_enemy、seat_husk→collapse_husk、echo_enemy、choir_summoner、typo_beast、mirror_sniper、ink_bomber）、Boss `smiling_archivist.png`、配乐 `chapter_theater.ogg`、旁白 `ch4_intro/outro.ogg` 均存在；脚本/场景/资源中的 `res://` 资产引用扫描无缺失（仅格式化字符串与旧字体扩展名）。
  - 缺口说明：第四章没有专属 tileset（`assets/tiles/` 只有 ch1）；第 2–4 章按 `mds_chapter_room.gd` 设计使用绘画背景 + 生成地面，不做像素 tile 处理，这不属于缺美术。
  - **结论**：README 旧记录「第四章舞台为程序化绘制、待替换插画」与 GDD 0.5 节同一说法**已过时**；专属插画早已存在并接入 MDS 与旧场景。后续第 2–4 章应按「内容/玩法可达性」规划，不再按「缺第 4 章美术」规划。已同步更正 README 与 GDD 两处表述。
  - 回归守护：`integration_playability` 的第四章检查新增 2 项（MDS 房间 `BackgroundArt` 纹理为 `smiling_theater.png`、`TheaterBackdrop` 存在且 `generated_art=true`），结构集成 **269 / 0**；顺带给 MDS 生成的剧场节点补 `name = "TheaterBackdrop"` 便于定位（无行为变化）。
- 任务 3 · 打磨项 1（模态页焦点停在禁用按钮，手柄 A 失效）：
  - 证据：临时探针 `tests/probe_shop_focus.gd`（真实手柄事件）复现三处：① 残页交易所第一行买不起时打开，焦点落在 disabled 行，按 A 不购买；② 买下当前行后焦点仍留在刚禁用的行，第二次按 A 无反应；③ 所有行都买不起时焦点仍在 disabled 行，A 无法关闭。`tests/probe_archive_focus.gd` 以 0 碎片打开档案馆升级页，焦点落在 disabled 的「升级」行。
  - 修复：`RunShopUI` 记录关闭按钮；打开时聚焦第一个可购买行，买下后把焦点移到下一个可购买行（没有则关闭按钮），全部买不起时聚焦关闭按钮。`ArchiveUI` 同样记录关闭按钮，打开时聚焦第一个可负担升级行、否则关闭按钮；每次 `_refresh()` 后若当前焦点变成 disabled，自动移到可按键控件。
  - 验证：同一批探针全部通过（混合价格打开即落在可购买行且 A 买下；连按两次 A 买下两行；全买不起时 A 关闭交易所；0 碎片打开档案馆焦点落在「合上档案」）。
  - 回归：`tests/integration_menus.gd` 新增 8 项真实手柄断言（交易所 6 + 档案馆 2），**86 checks / 0**；全量单元 **3782 / 0**。
- 任务 4 · 内容填充 1（残页交易所纸人台词与成交反馈）：
  - 现状：交易所副标题固定一句；买入成功把「成交。」写进红色错误标签，成功看起来像报错。
  - 实现：新增 `scripts/data/ch1_shop_data.gd`（`Ch1ShopData`，5 句纸人开场白），按 `run_seed + shop_id` 稳定选取、不消耗 run RNG；`RunShopUI.open_shop` 增加可选台词参数，`game._open_shop` 传入本局台词；成交提示改为印章金色，错误仍用朱红。数值、库存与购买逻辑未改。
  - 验证：`test_ch1_content` 新增 51 项（数量/非空/唯一/按 seed 稳定/40 个 seed 轮换/按摊位区分）；`integration_ch1_demo` 新增 3 项（真实进 `ch1_rest`，断言实际显示台词与 seed 选中一致）；`integration_menus` 新增 3 项（成交文案与金色、错误仍朱红）；全量单元 **3833 / 0**，`integration_menus` **89 / 0**，`integration_ch1_demo` **14 / 0**。
- 任务 5 · 内容填充 2（NPC 闲聊扩充）：
  - 现状：5 名 NPC 的 DialogueData 各只有 3 句轮换台词，重复交谈很快见底。
  - 实现：陆沉、阿砚、咕噜、闻烬、白榆各补 2 句（共 10 句），只加对白，不改立绘、职能、数值或 AI 提示词。新句沿用各自语气与剧情线索（陆沉的灯芯/名册空白、阿砚的炉火/断页剑缺页、咕噜的旧货/怕孤独、闻烬的老师/断笔、白榆的断桥/最后过桥）。
  - 验证：`test_hub_final` 新增 15 项（每名 NPC 至少 5 句、无空行、无重复），**124 / 0**；全量单元 **3848 / 0**。
- 任务 6 · 内容填充 3（事件房与残碑更多文案）：
  - 实现：`Ch1EventData.variants()` 由 3 个变体增至 5 个（新增「墨汛」「借阅」），机制常量、污染/残页数值与选项行为不变；`MemoryStele.EPITAPHS` 由 4 条增至 6 条，按 `stele_id` 稳定选取与奖励 roll 不变。
  - 验证：`test_ch1_content` 的字段完整性/唯一性/消息模板/40-seed 轮换/碑文稳定与接线断言自动覆盖新文案，并把最小数量提高到 5 个变体、6 条碑文；`integration_ch1_event` **20 / 0** 继续用 seed 选中变体比对实际显示；全量单元 **3874 / 0**。
- 任务 7 · 打磨项 2（手柄打开言灵页时焦点落在无法输入的光标框）：
  - 证据：临时探针 `tests/probe_inspire_pad.gd` 用真实手柄路径打开咕噜的言灵页，焦点为 `LineEdit`；手柄无法输入文字，按 A 也不会提交，玩家必须先猜到按方向键才能到达职能按钮（探针确认按 D-pad 下能到「买一条传闻」等服务按钮，说明只是入口焦点不对）。
  - 修复：`NpcInspireUI.open()` 按当前输入设备选焦点——手柄打开时聚焦第一个可用职能按钮（没有则退回输入框），键盘/鼠标仍聚焦输入框；不改布局、职能、AI 或任何数值。
  - 验证：同一探针中手柄打开后焦点落在职能按钮；`integration_gamepad` 新增 2 项真实手柄断言（Y 打开后焦点是按钮、A 触发一次 `function_requested`），**80 / 0**；全量单元 **3874 / 0**。
- 本程收尾（2026-11-04）：
  - 完成项：任务 1 基线；任务 2 第四章美术核查；任务 3 模态页禁用按钮焦点；任务 4 交易所纸人台词与成交反馈；任务 5 NPC 闲聊；任务 6 事件/残碑文案；任务 7 言灵页手柄入口焦点。
  - 最终验证：单元 **3874 / 0**；结构集成 **269 / 0**；输入集成 **14 / 0**；run save **35 / 0**；手柄 **80 / 0**；UI 提示 **9 / 0**；第一章事件 **20 / 0**；菜单 **89 / 0**；AI 设置 **40 / 0**；`--headless --import` 与 `--quit` 退出 0；退出泄漏 **10/10 clean**；demo 像素资产 **36 / 0**。
  - 本程提交（旧→新）：`2d82b99` 基线记录 + 第四章美术核查、`19ce135` 模态焦点、`eaa6716` 纸人台词、`75f63fd` NPC 闲聊、`8eb34c1` 事件/碑文、`c4701c4` 言灵页焦点、`0e89d69` 第四章美术回归守护（本条收尾文档提交随后）。
  - 工作区干净；无阻塞项；无在途未提交改动。

### 2026-11-04 · 第 6 程

- 任务 1 · 基线（Godot 4.7.stable.official.5b4e0cb0f，本机 `~/workspace/tools/godot/bin/Godot_v4.7-stable_linux.x86_64`）：`--headless --import` 通过；单元 `tests/run_tests.gd` **3670 / 0**；结构集成 **267 / 0**；输入集成 **11 / 0**；run save 集成 **35 / 0**；手柄集成 **78 / 0**；UI 提示集成 **9 / 0**；第一章事件集成 **14 / 0**；`tests/check_exit_clean.sh` **10/10 clean**。基线无回归。
- 任务 2 · 候选 1（其他菜单的真实 A/B 回归）：
  - 证据：临时探针 `tests/probe_menus.gd`（真实手柄事件）复现三处缺陷：① 剧情覆盖层普通页按 B 后仍 `open=true, paused=true`，既不关闭也不解除暂停；② Hub 对话打开后焦点为 null，按 A 不翻页、按 B 不关闭；③ Hub 商店打开后焦点为 null，按 A 不购买。地图、运行内商店、奖励、权柄、结束屏、档案馆在探针中均正常。
  - 修复：`StoryOverlay` 普通页接受 `ui_cancel` 关闭（三选一选择页仍必须选择，B 忽略）；`DialogueUI` 打开时聚焦「继续」按钮并记录/恢复打开前焦点，新增 B/Esc 关闭；`ShopUI` 打开时聚焦第一个可购买行，购买重建列表后按 item id 保留焦点，关闭时恢复打开前焦点。
  - 验证：同一探针 51 项全部通过；新增 `tests/integration_menus.gd` **46 checks / 0**，以真实手柄断言覆盖地图、剧情（含选择页）、运行内商店、奖励、权柄、结束屏、Hub 对话/商店/档案馆的 A/B、暂停状态与焦点；全量单元 **3672 / 0**；既有六套集成保持全绿。
- 任务 2 · 候选 2（Hub 内设置子页实景）：
  - 证据：探针在 Hub 实景走 `_process` + ModalLayer 路径：F10 打开设置后 AI/键位/操作说明均可打开，B 逐层关闭且焦点回到各自入口按钮；未发现产品缺陷（此前只是缺测试）。
  - 补测：`tests/integration_menus.gd` 增加 20 项 Hub 场景真实手柄断言（F10 开设置、玩家冻结；AI 页 A 开/B 关/焦点回归；键位页 A 开、捕获态、B 关并释放捕获、焦点回归；操作说明 A 开/B 关/焦点回归；B 关设置、玩家解冻），合计 **66 checks / 0**。
  - 验证：`integration_menus` 66 / 0；全量单元 3672 / 0。
- 任务 2 · 候选 6（标题「新游戏」二次确认的焦点与 A/B）：
  - 证据：探针在真实标题页按 A 打开原生 `ConfirmationDialog` 后，根视口焦点仍在「新游戏」按钮；按 B 后对话框仍 `visible=true`。原因是原生 Window 在无头/自动化输入下不接收 `Input.parse_input_event`，焦点与取消都不可断言；同时关闭后没有任何焦点回归逻辑。
  - 修复：新增场景内 `ConfirmPanel`（Control，PROCESS_MODE_ALWAYS，确认/取消按钮、B/Esc 取消、A 确认、关闭后把焦点还给打开它的控件）；`TitleScreen` 改用它承载「清除进度」确认，记录「新游戏」按钮作为焦点回归目标。顺带给 `TitleScreen._build` 的初始聚焦加 `is_inside_tree()` 防御，消除离树构建时的引擎报错。
  - 验证：探针变为 A 打开且焦点落在「确认」、B 取消并回到「新游戏」、再 A 打开、A 确认后发出一次 `new_game_requested`、标题隐藏、Profile 重置并重绑 Hub、暂停解除；`tests/integration_menus.gd` 增至 **78 checks / 0**（新增 12 项）；`test_demo_onboarding` 改为验证 `ConfirmPanel` 开关（全量单元 **3672 / 0**）。
- 任务 2 · 候选 3（AI 设置页 provider 切换与保存专项 UI 测试）：
  - 现状核对：设置页 provider 切换会填入对应默认 endpoint/model；保存写入 `AIService.config`；未启用/缺 endpoint/model/Anthropic 缺 key 时 `is_configured()` 为假；`_test()` 在未配置时只改状态文本，不发网络请求。
  - 测试夹具：`AIService` 新增 `config_path`（默认仍为 `CONFIG_PATH`），`load_config()`/`save_config()` 的路径参数缺省时读它，测试指向 `user://test_ai_settings.cfg`，绝不读写真实 `ai_config.cfg`；默认行为不变。
  - 新增 `tests/integration_ai_settings.gd`（**40 checks / 0**）：默认 Ollama 表单；切换 OpenAI/Anthropic/Ollama 的默认 endpoint/model 与选中项；Anthropic 无 key 保存后 `is_configured=false` 且「测试连接」停在本地提示；填写 key 后保存、`AIService.config`、配置文件与重新加载均正确；重开页面回填；成功/失败状态文案；真实手柄 B 关闭并只发一次 `closed`；OpenAI/Ollama 无 key 也可配置。不访问任何真实端点。
  - 验证：新增集成 40 / 0；`--filter=ai` 单元 100 / 0；全量单元 3672 / 0。
- 任务 2 · 候选 4（设置页主音量持久化）：
  - 结论：主音量应与文字大小/震动/闪屏一样跨局保存；此前只写 `AudioServer` 主总线，重启即回到 0 dB，属于缺失而非有意设计。
  - 修复：`Profile` 新增 `master_volume`（默认 1.0，读档钳制 0–1，缺键/坏类型回落默认，写入 `[settings]`）；`GameFlow._ready()` 启动时应用存档音量，`reset_profile()` 保留该设置；`SettingsMenu` 滑块初值取 Profile，拖动时同步 Profile 并在 `auto_save` 时写盘（震动/闪屏的保存也统一走同一守卫，避免测试写真实档案）。
  - 验证：`test_profile_v2` 新增 5 项（v1 默认 1.0、roundtrip 0.42、坏类型默认、越界钳制、加载成功）；`test_hud_accessibility` 新增 3 项（拖动写 Profile、写主总线、启动应用）；全量单元 **3680 / 0**。
- 任务 2 · 候选 5（单元测试日志噪音）：
  - 证据：全量单元测试本身 0 失败，但日志有 6 条引擎 `ERROR`：`test_audio_cleanup` 的 `AudioStreamPlayer.play()` 2 条（Playback 只能在树内）、`test_demo_onboarding` 的暂停菜单 `ConfirmationDialog.popup_centered` 2 条、`test_authority_integration` 的权柄/奖励 UI `grab_focus` 2 条。根因是 `run_tests.gd` 在 `_initialize` 里同步跑测试，此时 root 与 autoload 尚未进入场景树，测试夹具里的播放/弹窗/聚焦调用必然报错。
  - 修复（不动产品在正常树内的行为，只给离树调用加防御）：`AudioManager.play_music/play_sfx` 离树时不调用 `play()`（流与 player 仍按原逻辑创建/清理）；`AuthorityChoiceUI.open`、`RewardChoice.open_choices`、`PauseMenu._ask_confirm` 在树外跳过 `grab_focus`/`popup_centered`。
  - 验证：全量单元连续 3 次 **3680 passed / 0 failed**，每次 `ERROR` 计数 **0**；退出码 0。
- 任务 2 · 候选 7（第一章小幅内容填充）：
  - 事件房：新增 `scripts/data/ch1_event_data.gd`（`Ch1EventData`，3 个文案变体 + 机制常量：污染 8 / 拿残页 12 / 无词兜底 6）。变体按 `run_seed + room_id` 稳定选取，**不消耗 run RNG**，因此不影响掉落序列或续玩；`game._open_ch1_event` 改读变体的 eyebrow/title/body/按钮文案/提示模板与常量，解码、污染和残页数值完全不变。
  - 残碑：`MemoryStele.EPITAPHS` 补 4 条碑文，按 `stele_id` 稳定选取（同一块碑续玩后仍是同一句）；奖励 roll 与种类不变。
  - 验证：新增 `tests/test_ch1_content.gd` **102 项**（变体字段齐全且唯一、按 seed 确定与跨局轮换、3 条消息模板可格式化且显示常量、碑文非空/多变/稳定/与 `_roll_reward` 接线）；`tests/integration_ch1_event.gd` 增至 **20 / 0**，断言实际展示的 eyebrow/title/两个选项 label 与 seed 选中的变体一致；全量单元 **3782 / 0**；六套既有集成、菜单 78 / 0、AI 设置 40 / 0 全部保持绿。
- 任务 2 · 候选 8（`docs/memory/MEMORY.md` 压缩）：
  - 现状：索引 9494 bytes，超过文件头约定的 ≤8 KB（8192）。
  - 处理：把 2026-10-31 / 11-01 / 11-02 / 11-03 / 11-04 的会话条目按日期合并为分组行，每条链接保留一句话钩子；概览、世界与系统、工具、决策、已知问题、调研、待定均保留。顺带把「Windows 按正式发行准备、真实证书是唯一阻塞项」的旧表述改成当前口径：打包/签名/实机验证推迟到很久以后发行阶段，安装器脚本与签名文档留档、不扩展不删除。
  - 新增 `docs/memory/sessions/2026-11-04-supervisor-menus-content.md`，记录本程菜单 A/B、设置测试、音量持久化、日志噪音与文案填充，并在索引「最近阶段」挂链。
  - 验证：`wc -c docs/memory/MEMORY.md` = **7153 bytes**（≤8192）；所有原有链接保留；文档改动不影响测试。
- 收尾 · 全量验证与清理：
  - 删除临时探针 `tests/probe_menus.gd` / `.uid`（未跟踪文件；非游戏资产）。
  - `--headless --path . --import` 退出 0；`--headless --path . --quit` 退出 0。
  - 单元 `tests/run_tests.gd` **3782 passed / 0 failed**；结构集成 **267 / 0**；输入集成 **11 / 0**；run save **35 / 0**；手柄 **78 / 0**；UI 提示 **9 / 0**；第一章事件 **20 / 0**；菜单 A/B **78 / 0**；AI 设置 **40 / 0**。
  - `tests/check_exit_clean.sh <godot> 10` → **10/10 clean**；全部测试日志 `ERROR` 计数 **0**。
  - 工作区：仅本程应提交的源码/测试/文档改动，无残留探针、无 `.godot/`、`build/`、keystore 或截图产物；无在途未提交改动（收尾提交后）。
  - 未发现候选清单之外的额外可复现缺陷；候选 1–8 全部完成。唯一未决仍为「待用户确认」第 7 项（暂停菜单打开设置后关闭的去向），按指示保持现状。

### 2026-11-04 · 第 5 程

- 任务 1 · 基线（Godot 4.7.stable.official.5b4e0cb0f，本机 `~/workspace/tools/godot/bin/Godot_v4.7-stable_linux.x86_64`）：`--headless --import` 通过；单元 `tests/run_tests.gd` **3664 passed / 0 failed**；结构集成 **267 / 0**；输入集成 **11 / 0**；run save 集成 **35 / 0**；手柄集成 **39 / 0**；UI 提示集成 **9 / 0**；第一章事件集成 **14 / 0**；`tests/check_exit_clean.sh` **10/10 clean**。基线无回归，进入候选问题处理。
- 任务 2 · 五个候选问题已用 `tests/probe_next_five.gd`（临时探针）全部复现，证据待逐项修复时记录。
- 任务 2 · 修复 1（权柄二选一与暂停键冲突）：
  - 证据：探针真实打开权柄面板（`paused=true`）后按 P，变为 `paused=false`、面板仍可见、暂停菜单未开——游戏在必选面板下方恢复运行；再按一次才会把暂停菜单叠上来。根因是 `game.gd::_input` 未检查 `_authority_choice`，`pause` 分支直接 `pause_menu.toggle()` 翻转 SceneTree 暂停状态。
  - 修复：`AuthorityChoiceUI` 新增 `is_open()`；`game.gd::_input` 在权柄面板打开时吞掉 `pause` 与 `ui_cancel` 并 `return`；`_toggle_pause()` 增加防御性提前返回，避免其他调用路径再次抢占暂停状态。
  - 验证：同一探针变为「按 P 后 `paused=true`、面板保持、暂停菜单未开」；`integration_gamepad` 新增 7 项真实按键断言（手柄 Start 与键盘 P 均被忽略、选择后恢复），**46 / 0**；`test_authority_integration` 新增 2 项 `is_open()` 断言，全量单元 **3666 / 0**。
- 任务 2 · 修复 2（标题设置关闭后焦点丢失）：
  - 证据：探针把焦点放在标题「设置」按钮后打开设置页，关闭后 `gui_get_focus_owner()` 变为 `null`；标题的键盘/手柄导航从此失效。根因是 `SettingsMenu.close()` 只隐藏自身，未记录打开前的焦点。
  - 修复：`SettingsMenu` 在 `open()` 时记录当时的焦点控件，`close()` 后若该控件仍有效、在树内且可见则恢复焦点；标题、Hub 与暂停菜单共用同一套逻辑。
  - 验证：同一探针变为关闭后焦点回到标题「设置」按钮；`integration_gamepad` 新增 4 项真实场景断言（标题设置打开、设置页焦点、关闭后焦点回归），**50 / 0**；全量单元 **3666 / 0**。
- 任务 2 · 修复 3（设置内 Help/AI 子页未纳入 `_overlay`、B 键无法关闭）：
  - 证据 1（子页栈）：探针从设置打开 AI 页后按 Esc，结果为 `ai_visible=true, settings_visible=false, paused=false`——设置被关掉、游戏恢复，AI 页留在最上层且再也没有归属；Help 页同样由 `_help_ui.closed → _close_overlay` 把设置页一起关掉。
  - 证据 2（手柄 B 根本没映射）：`InputMap.action_get_events("ui_cancel")` 只有 Escape，没有手柄 B；真实手柄 B 按下时 `ui_cancel=false, dodge=true`。Godot 4.7 内置 UI 动作只带键盘与十字键/摇杆，不带 A/B 面键，因此所有「B 关闭」在实机上都不成立（A 确认同样缺失）。
  - 修复：
    - `GameFlow.ensure_actions()` 增加 `UI_JOYPAD_BUTTONS`：`ui_accept ← A`、`ui_cancel ← B`，幂等添加，不随玩法键重绑移除。
    - `SettingsMenu` 新增子页栈：AI/键位/操作说明作为 `_subpages` 记录；`close_subpage()` 先关最上层，`close()` 关闭全部；子页关闭后把焦点还给打开它的按钮；`_unhandled_input` 在非捕获状态下先关子页再关设置。
    - `game.gd` 的 `pause`/`ui_cancel` 分支先尝试 `_close_settings_subpage()`；`_close_overlay` 支持绑定发送者，子页的 `closed` 不会误关仍在上层的设置页。
    - `AISettingsUI` 新增 `closed` 信号、`close_page()` 与 `_unhandled_input`；Help 复用现有 `HelpUI` 并纳入子页栈。
    - Hub 不再轮询 `ui_cancel` 关设置（避免同一按同时关子页和设置），只保留设置键。
  - 验证：探针变为「Esc 关 AI 页 → 设置仍开、保持暂停；再 Esc 才关设置并恢复」；Help 同样；`integration_gamepad` 新增 18 项真实手柄 A/B 断言（B 关闭子页/设置、暂停保持、A/B 映射），**68 / 0**；全量单元 **3666 / 0**。
- 任务 2 · 修复 4（键位页重建后焦点丢失）：
  - 证据：探针打开键位页后焦点在第一行；按一次「跳跃」行触发重新构建，焦点变为 `null`；改键成功再构建一次，焦点仍为 `null`。根因是 `_refresh()` 删除并重建全部行按钮，却从未重新抓取焦点。
  - 修复：`KeybindUI` 新增 `_focus_action()`；开始捕获、成功改键、Back/Esc 取消捕获后都按动作重新抓取新建按钮的焦点；`open()` 同样走该入口。
  - 验证：探针中开始捕获与改键后焦点都落在新的「跳跃」按钮上，`key_label("jump") == "K"`；`integration_gamepad` 新增 4 项断言（行存在、捕获后焦点、改键后焦点、键位生效），**72 / 0**；全量单元 **3666 / 0**。
- 任务 2 · 修复 5（Hub 新游戏后仍绑定旧 Profile）：
  - 证据：按原 `TitleScreen._confirm_new_game()` 顺序（先 `new_game_requested.emit()`，后 `Flow.reset_profile()`）探针得到 `hub_profile_is_flow=false, hub_profile_valid=false`——Hub 把旧 Profile 记在 `hub.profile`，随后该实例被 `reset_profile()` 释放；商店页 `_profile`、教程 codex 的 RunState 与 `_words` 词副本都还指向旧档案（`_tutorial_run` 还被置空）。
  - 修复：
    - `TitleScreen` 抽出 `_start_new_game()`：先清 run save、`reset_profile()`，再发 `new_game_requested`，保证监听者读到的是新 Profile。
    - Hub `_on_new_game_requested()` 改走 `set_profile(Flow.profile)`；`set_profile()` 重建 `_words` 词副本、重绑商店页，并调用新增的 `_rebind_tutorial_run()` 用新 Profile 重建教程 RunState 与 codex 绑定（不再把 `_tutorial_run` 置空）。
  - 验证：探针变为 `hub_profile_is_flow=true, hub_profile_valid=true, shop/_tutorial/codex` 全部指向新档案；`test_demo_onboarding` 新增 4 项顺序断言（信号只发一次、信号内已是新 Profile、旧实例被替换、新档案进度为 0），全量单元 **3670 / 0**；`integration_gamepad` 新增 6 项真实 Hub 场景断言（重绑、有效性、商店、教程 run、codex、实例已替换），**78 / 0**。
- 任务 3 · 额外稳定性修复（五候选之外的发现）：手柄面键从来没有映射到 Godot 内置 UI 动作。
  - 证据：`InputMap.action_get_events("ui_cancel")` 只有 Escape；真实手柄 B 按下时 `ui_cancel=false, dodge=true`，`ui_accept` 同样没有 A。也就是说此前所有「B 返回 / A 确认」在手柄上都不成立，菜单只能靠十字键移动焦点、无法确认。
  - 修复：`GameFlow.ensure_actions()` 幂等补上 `ui_accept ← A`、`ui_cancel ← B`；这是 UI 级绑定，不随玩法键重绑移除（已随修复 3 提交）。
  - 验证：`integration_gamepad` 的动作映射断言之外，再把设置页「AI 言灵设置」按钮改成真实 A 按下驱动，确认焦点按钮被激活且 AI 页打开；**78 / 0**。
- 本程收尾（2026-11-04）：
  - 完成项：任务 1 基线；任务 2 五项候选（权柄面板与暂停键、标题设置焦点、设置子页/覆盖层与手柄 B、键位页焦点、Hub 新游戏 Profile 重绑）；任务 3 额外发现并修复手柄 A/B 未映射到 `ui_accept`/`ui_cancel`。共 7 个修复/测试提交点，逐项更新本文件并单独提交。
  - 最终验证（收尾提交前 HEAD `b38d849`）：单元 **3670 passed / 0 failed**；结构集成 **267 / 0**；输入集成 **11 / 0**；run save 集成 **35 / 0**；手柄集成 **78 / 0**；UI 提示集成 **9 / 0**；第一章事件集成 **14 / 0**；`--headless --import` 通过；`tests/check_exit_clean.sh` **10/10 clean**。探针 `tests/probe_next_five.gd` 已删除，其结论已转成上述自动化断言。
  - 本程提交（旧→新）：`ce50e62` 基线、`12c5984` 权柄暂停、`ec18863` 设置焦点、`33f6e22` 设置子页 + A/B 映射、`a7cf454` 键位页焦点、`9d429f6` Hub Profile 重绑、`4ae4f19` 真实 A 激活补测、`b38d849` 测试 uid（本条收尾提交随后）。
  - 工作区干净；无阻塞项；无在途未提交改动。

### 2026-11-03 · 第 4 程

- 任务 1 · 基线（本机 Godot 4.7.stable）：`--headless --import` 通过；单元 `tests/run_tests.gd` **3519 passed / 0 failed**；结构集成 **267 / 0**；输入集成 **11 / 0**；run save 集成 **27 / 0**；手柄集成 **34 / 0**；`tests/check_exit_clean.sh` **10/10 clean**。基线无回归，可直接进入打磨。
- 任务 2 · 打磨项 1（手柄/输入）：Hub 内手柄 Y 同时映射 `interact` 与 `npc_inspire`，对话中按 Y 会先打开言灵面板、随后同一次按键又触发 `interact` 把对话重新盖回来。
  - 证据：`tests/probe_hub_y.gd` 探针（hub.tscn + 真实手柄事件）复现「inspire open: true / dialogue open after Y: true」；代码路径 `hub.gd:_process` 的 Y 分支未消费按键，继续落到 `interact` 分支。
  - 修复：`_open_active_inspiration()` 返回是否真的打开面板；`_process` 在本帧成功打开面板后直接 `return`，同一次 Y 不再触发交互；`_inspire_key_down` 仍先更新，长按不会重复打开。
  - 验证：同一探针变为「dialogue open after Y: false」；`tests/integration_gamepad.gd` 增加 5 项 Hub 实景检查（对话打开 → Y 打开言灵 → 对话保持关闭），34 → **39 checks / 0 failures**；全量单元 **3519 / 0**。
- 任务 2 · 打磨项 2（提示一致性）：世界内交互提示写死键盘键。
  - 证据：`pickup.gd` 的「E 拾取」与 `treasure_chest.gd` 的 `draw_string("E  开启")` 未随设备切换；`memory_stele.gd` 只在 `_ready` 读一次 `Flow.prompt_label()`，中途接上手柄后仍显示 E。
  - 修复：三处统一读 `Flow.prompt_label(&"interact")`；`Pickup` 与 `MemoryStele` 监听 `Flow.input_device_changed` 即时刷新（拾取物还区分远近文本），`TreasureChest` 每帧绘制时取当前设备提示。
  - 验证：新增 `tests/integration_ui_prompts.gd`（9 checks）：默认键盘 E / 手柄 Y、拾取物远近与设备切换、宝箱、残碑开面板后切换设备；**9 / 0**。全量单元 **3519 / 0**。
  - 回归修复：拾取物/宝箱/残碑直接引用 `Flow` 全局会让 `-s` 集成脚本在 autoload 注册前预编译失败（`integration_playability` 的 `Pickup` 类因此失效）。三处改为在 `_ready` 里从 `/root/Flow` 解析并缓存 `GameFlow`，行为不变；结构集成恢复 **267 / 0**、手柄 **39 / 0**、提示 **9 / 0**。
- 任务 2 · 打磨项 3（稳定性/存档边界）：格式正确但字段类型损坏的存档会让主场景初始化中断。
  - 证据：探针写入 `world: 5`、`progress: "garbage"`、`authority: [1,2]`、`mds: "nope"` 的 RunSave（顶层 version/run/inventory 合法）后启动主场景，出现 `Trying to assign value of type 'String' to a variable of type 'Dictionary'` 与 `Nonexistent function 'get' in base 'int'`，MDS 未初始化；Profile 同类探针在 `unlocked_words = 5` 时于 `StringName()` 处中止，`unlocked_words` 被清空。
  - 修复：
    - `RunSave._has_valid_shape()` 在读取时校验游戏直接消费的容器与字段类型（run 数值/布尔、inventory 数组与条目、progress/world/authority/mds 子结构、MDS visited/areas/position 等）；任一不符即按坏档丢弃，不再半恢复。
    - `RunSave.read()` 在回退到 `.bak` 后把有效备份**提升为主文件**，避免下一次存档把损坏主文件复制成备份、失去唯一可恢复副本。
    - `Profile.load_profile()` 改为逐字段容错：`_as_dictionary/_as_array/_as_int/_as_float/_as_bool/_as_string/_read_names` 对错误类型取安全默认值，不再中途抛错；同样在 `.bak` 回退后提升主文件。
    - `RunSave.write()` / `Profile.save_profile()` 在备份复制或删除主文件失败时中止，不再先删主文件（磁盘错误路径防丢档）。
  - 验证：`test_run_save` 新增 8 种畸形结构 + 最小合法档 + 备份提升用例（**58 / 0**）；`test_profile_v2` 新增畸形字段与提升用例（**71 / 0**）；`integration_run_save` 新增畸形存档真实启动用例（27 → **30 / 0**，确认新开一局且 `_resume_data` 为空）；探针复跑无脚本错误。全量单元 **3568 / 0**。
- 任务 2 · 打磨项 4（性能/物理）：第一章每个房间把地板下方 9 行、平台下方 1 行也画成带碰撞的 tile。
  - 证据：`mds_chapter_room.gd` 原实现把 `floor_row..bottom_row` 全部写入同一个 `TileMapLayer`，`ch1_tiles.tres` 的 4 个 tile 都带 16×16 碰撞；每房约 **800 地面 + 60 平台 = 860 个静态碰撞格**，而玩家只能接触到地面顶行和平台顶行，下方永远不可达。
  - 修复：地面拆成 `Ground`（仅顶行，保留碰撞）与 `GroundFill`（下方 9 行，`collision_enabled = false`）；平台拆成 `Platforms`（表面行）与 `PlatformsFill`（填充行，无碰撞）。视觉不变，每房碰撞格 **860 → 110**（约 -87%），减少静态 broadphase 形状与物理内存。
  - 验证：`test_room_layout` 新增 6 项断言（Ground 80 格 / GroundFill 720 格且无碰撞 / Platforms 30 格 / PlatformsFill 30 格且无碰撞），**23 / 0**；结构集成 **267 / 0**；全量单元 **3568 / 0**。
- 任务 2 · 打磨项 5（稳定性/退出边界）：窗口关闭时只写局内存档，且奖励界面打开时也会写。
  - 证据：`Flow._notification(WM_CLOSE_REQUEST)` 只调用 `game.save_run_on_exit()` → `save_run_now()`；后者没有检查奖励界面。清房时 `_mds_cleared_rooms` 在选项打开前就已置位，退出后重开会出现「房间已清、奖励未选、选项已丢」。同时 Profile 上的词条熟练度/局内解码只随正常结算保存，中途关窗会丢。
  - 修复：`save_run_now()` 在 `_reward_ui.visible` 时返回 false，保留进入房间时的检查点，退出奖励界面只会重打该房而不是永久丢奖励；`save_run_on_exit()` 在 `auto_save` 时先保存 Profile，再尝试写局内存档，保证熟练度/跨局解码不因中途退出丢失。
  - 验证：`integration_run_save` 新增 5 项（奖励界面打开时 `save_run_now` 被拒绝、关闭后可写；`save_run_on_exit` 写出临时 Profile 且熟练度增量保留），30 → **35 / 0**；全量单元 **3664 / 0**。
- 任务 3 · 内容厚度 1（事件房回报）：`ch1_05`“读禁文”写的是“获得一个词”，实际只会发 6 残页。
  - 证据：demo 开局通过 `RunLoot.starting_words()` 直接拥有 6 个已解码词 + 12 个未解码残页词；`_grant_event_word()` 的候选池按“未拥有”过滤，恒为空，每次都走 `add_pages(6)`。GDD §423 与 demo 计划均写明该选项应“解码一个词 +8 污染”。
  - 修复：新增 `RunLoot.owned_undecoded_words()`（本局已拥有但未解码、且属于当前章节词池的词）与 `RunLoot.decode_owned_word()`（写入 Profile 跨局解码，并把本局副本标记为已解码）；事件改为从该池随机解明一个词，选项提示显示可选数量；全部解明后才回退为残页 +6，并在消息里说明。
  - 补强：解码是跨局进度，事件成功后立即 `Flow.save_profile()`（仅 `auto_save` 时），避免解码后中途关窗只留下局内存档。
  - 验证：`test_word_decoding` 新增 10 项断言（12 个候选、Profile/本局副本同时解锁、幂等、共享 `.tres` 不被修改、词池耗尽），**36 / 0**；新增 `tests/integration_ch1_event.gd`（14 checks）：真实进 `ch1_05`、选“读禁文”、确认恰好解明 1 词、本局副本可读、残页不变、污染按倍率 +8、房间标记已清、**解码立即写入 Profile 存档（模拟中途退出后重新加载仍在）**，以及全解明后的残页回退；**14 / 0**。全量单元 **3578 / 0**；结构集成 **267 / 0**。
- 任务 3 · 内容厚度 2（掉落池）：第一章敌人击杀掉落会摇出整部游戏的武器。
  - 证据：`game.gd::_on_enemy_died()` 直接从 `ContentLibrary.WEAPONS`（完整版武器表）抽武器，而奖励、宝箱、商店都走 `RunLoot._weapon_pool(chapter)`（第一章只含 6 把 demo 武器）；demo 内可能捡到未纳入第一章数值/美术验收的武器。
  - 修复：新增 `RunLoot.dropped_weapon(run, profile, chapter)` 作为击杀掉落的唯一入口，复用章节武器池与 `weapon_for_run` 的成长参数；`_on_enemy_died()` 改调它，返回空时跳过掉落。
  - 验证：`test_demo_loot` 新增 47 项断言（40 次采样均返回武器、掉落至少两种、所有 id 属于 `DEMO_WEAPONS`），**133 / 0**；全量单元 **3625 / 0**。
- 任务 4 · 言灵 AI 接入健康检查（只补测试，不改默认行为）：
  - 现状核对：`AIService.DEFAULT_CONFIG.enabled = false`，无内置 key；`is_configured()` 要求 enabled + endpoint + model，Anthropic 额外要求 key；未配置/空句/忙/网络失败/非 2xx/坏 JSON 都只发失败信号，不抛错；Codex 先算离线推演，AI 成功才替换预览，不自动装备；Hub 在 AI 已配置时跳过离线效果，失败时才走离线且每 NPC 每次回 Hub 最多一次（`test_economy_guard` 已覆盖）。
  - 补测 1：`test_ai_optional` 新增 18 项——三个 provider 的默认 endpoint/model、key 传输位置（Ollama 不带 key）、带 key 时 `is_configured` 为真、OpenAI 可无 key、未知 provider 归一为 Ollama。
  - 补测 2：`test_npc_inspiration` 新增 13 项——NPC 请求在 Ollama/OpenAI 路径下同样包含 NPC 身份、模型、正确 endpoint，玩家 `<player_words>` 被转义为全角，Ollama 带 `format: json` 且无 Authorization，OpenAI 带 Bearer。
  - 补测 3：新增 `tests/test_ai_codex.gd`（12 checks）：AI 结果替换离线预览而不是叠加、意图数值只应用一次、不自动装备；旧句子的迟到结果被忽略；失败/本地校验失败都保留原预览并给出提示。
  - 验证：`--filter=ai` **100 / 0**；`--filter=npc` **64 / 0**；全量单元 **3664 / 0**。
  - 缺口（记录，不擅自改默认行为）：自动化不访问真实 Ollama/OpenAI/Anthropic 端点，只验证请求构造、配置门控与响应解析；真实联调仍需本机服务/密钥手工验证。设置页 AI 表单的 provider 切换与保存目前只有代码审查，无专项 UI 测试。
- 本程收尾（2026-11-03）：
  - 完成项：任务 1 基线；任务 2 五项（Hub 手柄 Y 双触发、世界提示随设备切换、坏档拒绝与备份提升、tile 填充层去碰撞、退出保存/奖励边界）；任务 3 两项（事件“读禁文”真正解码并立即持久化、第一章击杀掉落限定 demo 武器池）；任务 4 AI 三 provider 路径与 Codex 回退补测。共 7 个功能/内容/测试提交点，逐项更新本文件并单独提交。
  - 最终验证：单元 **3664 passed / 0 failed**；结构集成 **267 / 0**；输入集成 **11 / 0**；run save 集成 **35 / 0**；手柄集成 **39 / 0**；UI 提示集成 **9 / 0**；第一章事件集成 **14 / 0**；`--headless --import` 通过；`tests/check_exit_clean.sh` **10/10 clean**。
  - 本程提交（旧→新）：`b81ee6b` 基线记录、`d258224` Hub Y、`2c06bc1` 设备提示、`54a961e` 坏档拒绝、`ed72df2` tile 碰撞、`9f17b02` 事件解码、`ef439e1` 掉落池、`c6494ec` AI 补测、`20694e1` 解码即时存档、`3a7104a` 退出保存/奖励边界（本条收尾提交紧随其后）。
  - 剩余优先级与候选见「下一程从这里继续」；无在途未提交改动，无阻塞项。
  - Windows 实机验证、安装器编译/实测、真实代码签名证书、1080p 实机截图已统一改记为**很久以后的发行阶段事项，现阶段不做**。

### 2026-11-03 · 第 3 程

- 任务 1（清单 #4）· v1 `discovered_phrases` 迁移（按 DECISIONS.md 拍板口径）：
  - `Profile` 新增 `legacy_discovered_phrases`，加载时把旧 meanings 字符串（如 `呓·火`）从 `discovered_phrases` 分拣到 legacy 桶，原样保留、去重；保存时写回 `progress/legacy_discovered_phrases`，不再放回 active 键。
  - 新格式判定集中在 `Profile.is_current_phrase_signature()`：`id1,id2|count`、计数与 id 数一致、id 仅小写字母/数字/下划线、拒绝合成野生词 `__*`。`discover_phrase()` 也走同一判定，旧字符串无法再被写入 active 列表。
  - legacy 桶只从存档读取，不再参与分类，因此重复加载/保存幂等；Codex、HUD、标题进度判断等仍只读 `discovered_phrases`。
  - 新增 `test_profile_v2.gd::_test_discovered_phrase_migration`（18 项断言）：纯旧档全部进 legacy；混合档只保留新格式、旧串去重保留；已迁移档二次加载无重复、无重新分类；旧串不可 `discover_phrase`。
  - 更新 `test_flow.gd` 的短语 roundtrip 用例为新签名。
  - 全量单元测试：3519 passed / 0 failed。
- 任务 2 · 构建链路验证（Windows headless 导出）：
  - 命令：`~/workspace/tools/godot/bin/Godot_v4.7-stable_linux.x86_64 --headless --path . --export-release "Windows Desktop" build/windows/changzi-adventure.exe`
  - 结果：成功（`[ DONE ] savepack`），产物 `build/windows/changzi-adventure.exe`，131,767,792 bytes（约 125.7 MiB），`file` 识别为 `PE32+ executable (GUI) x86-64, for MS Windows`；文件尾部有 `GDPC` 魔数，确认 PCK 已嵌入（embed_pck=true），单 exe 即可分发。
  - 模板：`~/.local/share/godot/export_templates/4.7.stable/` 的 `windows_release_x86_64.exe`；未修改任何导出预设。
  - 导出进程自身退出报 973 ObjectDB / 8 resource 泄漏，属编辑器/导出器侧（与上一程 1021/8 同源），游戏运行退出仍为 0 泄漏，不影响产物。
- 任务 3（清单 #12）· 测试夹具退出泄漏清理：
  - 用 `--filter=<file>` 逐文件跑单元测试，定位到 5 个泄漏源：`test_ai_optional.gd`（`hub.profile` 未释放）、`test_ch1_plan.gd`、`test_demo_loot.gd`（`Profile.new()` 未释放）、`test_word_decoding.gd`（`RunLoot.starting_words(Profile.new())` 内联未释放）、`test_spell_v3.gd`（`_test_ai_intent` 里内联创建的 `StubEnemy` 未释放，其 `BurnStatus` 子节点一并泄漏）。
  - 逐处补 `free()`；`test_spell_v3` 改为先保存 `target` 引用再随 `_free(parts + [target])` 释放。
  - 验证：全量单元测试连续 10 次 `3519 passed / 0 failed`，每次退出 0 ObjectDB / 0 resource / 0 RID；单独跑 5 个原泄漏文件也均为 0。
- 任务 4（清单 #9 前置）· 发行准备地基（不花钱、不需用户出面部分）：
  - 新增 `packaging/windows/changzi-adventure.iss`（Inno Setup 6.3+）：per-user 安装、x64、开始菜单/可选桌面快捷方式、卸载项、安装后启动；不删除 `%APPDATA%\Godot\app_userdata\昌子大冒险` 存档；AppId 固定 GUID；版本/发布者/图标与 `project.godot` 对齐；`SignTool` / `SignedUninstaller` 预置为注释，证书到位后启用。
  - 新增 `packaging/windows/README.md`：release 导出 → ISCC 编译 → 产物路径、版本同步、存档位置。
  - 新增 `docs/release/windows-signing.md`：证书类型与唯一用户侧阻塞项、`signtool` SHA-256 + RFC3161 时间戳命令、证书存储与 `.pfx` 两种方式、Inno 自动签名接入（IDE/`/S` 命令行）、`signtool verify` / PowerShell 校验、CI secret 处理与清理、发布检查清单。
  - `.gitignore` 增加 `*.pfx` / `*.p12` / `*.pvk`，防止签名私钥误提交。
  - 未购买证书、未生成自签名证书；安装器默认保持未签名。
  - 验证限制：本机为 Linux，无 Inno Setup / Wine，`.iss` 未实际编译；已核对所有 `Source`/图标/输出路径存在。需在 Windows 构建机执行 `ISCC.exe` 做最终编译验证。
- 本程收尾验证：
  - 单元 `tests/run_tests.gd` 连续 10 次：3519 passed / 0 failed，0 ObjectDB / 0 resource / 0 RID。
  - 结构集成 267 / 0；输入集成 11 / 0；run save 集成 27 / 0；手柄集成 34 / 0。
  - 游戏退出泄漏回归 `tests/check_exit_clean.sh` 10/10 clean。
  - 记忆：新增 `docs/memory/sessions/2026-11-03-migration-build-leaks-signing.md`、ADR `docs/memory/decisions/2026-11-03-v1-phrase-migration.md`，更新 `docs/memory/MEMORY.md`。
- 本程四项任务全部完成，工作区干净。

### 2026-11-03 · 第 2 程（已完成）

- 收尾上一程在途改动：`scripts/game.gd` 移除场景级 `Audio.shutdown()` 的判断成立（场景退出时抢先停止会与音频线程竞态），保留并把注释改为 NOTE；`tests/probe_exit_audio.gd` 原先只是加载 Hub 后退出，不能定位问题，重写为可复现探针（`--mode=scene-exit|shutdown|shutdown-wait|stop-wait`、`--wait=`），并补上音频状态打印。
- 退出泄漏根因（`--verbose` 抓到）：强制退出时正在播放的 `chapter_archive.ogg` 音乐与 `ch1_intro.ogg` 语音，其 `AudioStreamPlaybackOggVorbis` / `OggPacketSequencePlayback` / `AudioStreamOggVorbis` / `OggPacketSequence` 被音频线程引用到引擎清理之后，报 8 ObjectDB + 4 resources。
- 对照实验（各 10 次）：场景直接退出约 3/10 泄漏；先 `shutdown()` 立即退出 5/10；`shutdown()` 后等 3 帧 1/10；只 `stop()` 等 3 帧 0/10；teardown 里 stop + 延时 20/30/50/100ms 分别为 2/1/0/0。结论：先停播、给混音线程结算时间，再释放流即可根治。
- 修复：`AudioManager.shutdown(settle_msec := 0)` 分离「停播 → 结算 → 释放」，`_exit_tree()` 调用 `shutdown(100)`；`game.gd` 不再在场景退出时清理音频。
- 验证：修复后 `res://scenes/main.tscn --quit-after 400` 连续 30 次 0 ObjectDB / 0 resource 泄漏；探针 `scene-exit` 20/20 无泄漏；单元测试 3492 passed / 0 failed。
- 新增 `tests/check_exit_clean.sh` 回归脚本（用法：`tests/check_exit_clean.sh <godot> [runs] [scene]`），本次 10/10 clean；后续可用它守住 0 泄漏。
- 备注：`tests/run_tests.gd` 自身退出仍有 12 ObjectDB / 3 resource / 2 RID 泄漏，均为测试脚本创建后未释放的 Node/GDScript/CharacterBody2D，与音频无关，属测试夹具问题（已记入未完成清单 #12）。
- 清单 #5 存档 v2 `.bak` 恢复：
  - 新增 `test_profile_v2` 覆盖「主文件缺失 + 备份存在」（读到备份内容 11）、「主文件损坏 + 备份存在」（读到备份内容 33）、「两者皆无」（返回 false）。
  - 测试暴露真实缺陷：`ConfigFile.load()` 失败后复用同一实例再加载 `.bak` 也会失败，且 `RunSave.read()` 校验失败会直接 `clear()` 把主文件与备份一起删掉。修复为：每次尝试都用全新 `ConfigFile`；主文件缺失/损坏/版本不符时先尝试 `.bak`，两者都无效才清理。`RunSave` 同步补充「损坏主文件 + 有效备份」测试。
  - 回归：单元 3501 passed / 0 failed；结构集成 267 / 0；输入集成 11 / 0；run save 集成 27 / 0；手柄集成 34 / 0。
- 清单 #6 截图（不需真人部分）：
  - 纯 `--headless` 使用 dummy 渲染器，`root.get_texture().get_image()` 只能得到空白，无法截图；改用 `xvfb-run` + `--rendering-driver opengl3`（Mesa llvmpipe）离屏渲染成功。
  - 新增 `tests/capture_authority_ending.gd`：关闭章节开场叙事 → 打开权柄二选一 → 截图 → 展示章末结束屏 → 截图。产物在 `artifacts/screens/`（gitignore）：`19_authority_choice.png`、`20_ending.png`，1280×720 与 2560×1440 两份均非空、内容正确（权柄面板/「复原」结局）。
  - 权柄面板打开会暂停 SceneTree，暂停状态下离屏渲染不更新帧（截出全黑）；截图前临时 `paused = false` 解决，控件仍保持可见。
  - 1920×1080 在 `stretch/scale_mode=integer` 下实际窗口回落到 1280×720（1.5 倍不是整数），因此 1080p 真实截图仍需人工在实机确认；2560×1440（2 倍）正常。
  - 运行命令：`xvfb-run -a -s "-screen 0 1280x720x24" <godot> --path . --resolution 1280x720 --rendering-driver opengl3 --audio-driver Dummy -s tests/capture_authority_ending.gd -- --out-dir=res://artifacts/screens`。
- 导出链路验证：`~/.local/share/godot/export_templates/4.7.stable/` 存在且含 Windows debug/release x86_64/arm64 模板；执行 `godot --headless --path . --export-debug "Windows Desktop" build/windows/changzi-adventure.exe` 成功（DONE，产出 125.7 MB PE32+ x86-64 + console exe，embedded PCK），构建链路可用。`build/` 已在 gitignore，未提交产物。导出进程自身退出报 1021 ObjectDB / 8 resource 泄漏，属编辑器/导出器侧，与游戏运行无关（游戏运行退出已 0 泄漏）；如后续接 CI 再评估是否需要处理。
- 记忆：新增 `docs/memory/sessions/2026-11-03-exit-leak-save-recovery.md` 并更新 `docs/memory/MEMORY.md` 索引。

## 下一程从这里继续

1. 先跑基线：`--headless --path . --import`、`--headless --path . --quit`、`--headless --path . --script res://tests/run_tests.gd`（预期 **13551 / 0**；第 91 程 +2 条第 4 章计划存在性断言；第 68 程 +5 条档案馆满级断言、第 69 程 +17 条 NPC 职能文案/发放断言、第 70 程 +14 条商店/神铸/遗物卡文案断言、第 72 程 +9 条阿砚问候不扣碎片/不升级断言、第 73 程 +16 条词服务/已拥有货架断言、第 78 程 +59 条四敌专属美术断言、第 80 程路由锁逐条替换数量不变）、十一套集成（`integration_playability` **1,475**（第 97 程 +628：新增全流程 1→4 链路 + 死 Boss 房续玩回归；第 91 程 −40：删除第 4 章旧 9 房结构遍历、改为第 4 章真实链路/交棒断言；第 86 程 +6 条权柄三选一延时窗口内暂停/过场等待断言；第 80 程 −35：删除第 3 章旧 9 房结构遍历；第 70 程 +5 条缝合书页实际数值断言保留）/ `integration_ch1_demo` **109**（第 73 程 +7 条商店已拥有断言）/ `integration_run_save` **677**（第 97 程 +2 条死 Boss 房不重锁回归、存档位置改为真实落点；第 80 程 +7 条第 2 章 → 第 3 章续玩边界断言、第 83 程 +26 条跨章权柄续玩/旧检查点兼容断言、第 88 程 +15 条奖励页等待页面/过场与 `_reward_pending` 挡档断言）/ `integration_gamepad` 207 / `integration_ui_prompts` 113 / `integration_ch1_event` **73**（第 86 程 +14 条事件页与地图/过场互斥断言）/ `integration_menus` **458**（第 76–77 程 +11 条第 2 章可达性断言、第 83 程 +2 条帮助页地图文案断言）/ `integration_ai_settings` 45 / `integration_ch2_bigmap` **2331**（第 78 程 +15 条四敌美术断言、第 80 程 +1 条章末交棒断言）/ `integration_ch3_bigmap` **4364**（第 78 程 +4 条四敌美术复用断言、第 80 程 +2 条路由锁断言）/ `integration_ch4_bigmap` **5133**）、`tests/check_exit_clean.sh <godot> 10`、`tests/check_pixel_assets.py --demo`（**40 / 0**）；确认全绿再动手。注意 Godot 4.7 下不要用位置参数传测试脚本（会挂起），必须用 `--script res://...`。
2. 第 36–45 程已完成并提交：第 2 章大地图验收集成（2209 断言）、bot 门到达宽限（`floor_arrival_grace` 1.2 秒）、九区 22 扇 `GateVisual`、`ch2_entry` 出生 `SpawnPoint`、地图标题按章节区域派生、敌人美术核查（`choir_summoner` 已接线，其余四种缺美术保留回退）；第 39 程完成第 3 章大地图可行性核查（只查不施工，见专节）；第 40 程完成第 3 章计划与图骨架（9 区、6 战斗遭遇 + 1 事件占位 = 清房目标 7、11 门 = 9 双向 + 2 单向、每区坠落平面 240；`content_pending` 只推迟波次表；计划未接入 `game.gd`，见专节）；第 41 程完成第 3 章真实大区世界（9 个 `BigRoomData` + 9 个 `MDSBigRoom` + 独立世界/场景，22 门 = 20 有向 + 2 只到达，入口 `SpawnPoint`，每区坠落 240；世界仍不被 `game.gd` 引用、计划槽仍空，见专节）；第 42 程完成第 3 章内容数据层第 1 步（`Ch3EventData`、计划基础权柄池、Boss 3 入场/阶段文案与遭遇/波次数据校验；计划仍未接入 `game.gd`、仍无 `wave` 表与事件真实触发）；第 43 程完成第 3 章内容数据层第 2 步（计划 6 个战斗遭遇按节点 id 接 `ROOM_WAVES[2]` 六波、事件/Boss 无普通波、清房目标 7、`content_pending` 清零；计划仍未接入 `game.gd`、事件无真实触发、Boss 3 无 `boss_scene`/机制）；第 44 程完成第 3 章内容数据层第 3 步（`ch3_event` 沿用第 34 程通用大图区域触发、进入即开第 3 章事件页、`ch3_event/event` 一次性结算、读/拿沿用第 42 程口径；未新增触发路径、仍未接入 `game.gd`）；第 45 程完成第 3 章 Boss 3 独特机制与计划 `boss_scene` 路由（镜面弹幕 3/5/7 枚、读页封印短语 3.0 s、阶段 3 空白页承伤窗口、计划路由既有 `last_reader.tscn`，数值为暂定口径由 `test_ch3_boss` 锁定；`CHAPTER_PLAN_PATHS[2]` 仍空）。第 46 程完成第 3 章章末收口：`_complete_chapter` 新增 `_chapter == 2` 分支，章末选择后 `_finish(true)` 停章、不再自动进第 4 章（第 1/2/4 章分支未改）；真实大区世界 + 计划走完 Boss 3 击败 → 权柄 → 第 3 章 outro → 章末选择 → 停章，旧线性世界结构遍历同步改为「停在第 3 章」；可玩性集成 732 → **754**，`CHAPTER_PLAN_PATHS[2]` 仍空、第 3 章仍不可达、计划仍未接入 `game.gd`。第 1 章 9 房间/6 波次/事件/清房目标 6/结束流程无回归，第 2 章计划/大区世界/Boss 2/章末收口无回归，第 2–4 章仍不可达；单元 10207/0、九套集成全绿、退出泄漏 10/10、像素 36/0。第 47 程因 Magpie 网关中断夭折（无提交、无文档，只留下未跟踪的验收脚本）。第 48 程接力完成第 3 章大地图系统验收：`tests/integration_ch3_bigmap.gd` **3424 断言 / 0 失败（连续两次）**，覆盖九区连通/边界相机/纵向/过渡/一次性内容/多遭遇/捷径隐藏/Boss 章末/性能/叙事与第 3 章专属（无光海背景平铺、雾雨、`deep_water` Boss 背景、地图标题「无光海地图」）；未发现产品缺陷（4 处验收脚本自身问题已修并补断言），性能基线与逐项结论见 `docs/memory/sessions/2026-11-05-chapter3-bigmap-acceptance.md`；`CHAPTER_PLAN_PATHS[2]` 仍空、旧第 3 章 9 房/17 门世界仍被 `game.gd` 使用、第 3 章仍不可达。第 49 程完成第 3 章大图门视觉专项（22 扇门逐门断言、修复 `ch3_well/top1`/`ch2_well/top1` 舱口标题越界）与敌人美术核查（`ROOM_WAVES[2]` 8 种：5 接线白 tint / 3 缺美术回退并记录），单元 10315/0、第 3 章集成 4235/0、第 2 章集成 2209/0；第 1/2 章无回归，第 3 章仍未接入 `game.gd`、仍不可达。第 50 程完成第 4 章大地图可行性核查（只查不施工）：第 2/3 章大区管线可直接承载；第 4 章现有旧世界 9 房/17 门/单层、6 战斗 + 休整 + 书库 + Boss、文本语音与 Boss 4 脚本/场景/立绘均在；缺口为计划/大区世界/事件/权柄/Boss 文案与第 4 章验收；美术素材已画好并接线、8 种敌人无回退；第 4 章仍不可达，可达性须单独拍板且不能早于第 2/3 章。第 51 程完成第 4 章计划与图骨架（只做数据层）：`chapter_4_demo.tres` 9 区连通图、6 战斗遭遇 + 1 事件占位 = 清房目标 7、3 宝箱/2 残碑、11 门 = 9 双向 + 2 单向、每区坠落 240；`content_pending = true` 只推迟波次表；Boss 门按第 2/3 章先例单向、旧世界可返回行为原样保留；计划未接入 `game.gd`（`CHAPTER_PLAN_PATHS[3]` 仍空）、旧第 4 章世界原样保留、第 4 章仍不可达；真实大区世界/`Ch4EventData`/权柄池/波次/Boss 4 机制与文案均未开始。第 52 程完成第 4 章真实大区世界（只做结构层）：9 个 `BigRoomData` + 9 个 `MDSBigRoom` + 独立世界/场景（22 门 = 20 有向 + 2 只到达、`elite_boss` 单向、`hub_shortcut_entry` 带 `requires` 默认封闭、入口 `SpawnPoint`、每区坠落 240、5 台电梯 + 纵井 3 单向落台 + 枢纽长椅）；区域 `Smiling Theater` 灰烬/光柱 + `blood_moon`、`smiling_theater.png` 静态平铺、`embers` 氛围，无 theater 层；世界仍不被 `game.gd` 引用（`CHAPTER_PLAN_PATHS[3]` 仍空）、旧第 4 章世界原样保留、第 4 章仍不可达；`test_ch4_world` 812 断言、`test_ch4_plan` 目录锁改为存在性（796）；临时探针用真实 MDS 运行时逐区加载 0 失败后删除。第 53 程完成第 4 章内容数据层第 1 步（`Ch4EventData` 7 组事件、计划权柄基础池续命/改写、Boss 4 入场 8 条 + 阶段 2/3 各 8 条；计划仍 `content_pending`/无 `wave` 表/无 `boss_scene`、仍不被 `game.gd` 引用；`test_ch4_content` 613 断言，单元 12545/0，十套集成不变）。第 54 程完成第 4 章内容数据层第 2 步（波次接线，只做数据层）：`chapter_4_demo.tres` 的 4 个战斗区补 `wave` 字典，6 个战斗遭遇按计划顺序逐字接上 `ROOM_WAVES[3]` 六波（`mask_enemy`+`seat_husk` / `choir_summoner`+`page_swarm` / `seat_husk`+`mirror_sniper` / `mask_enemy`+`typo_beast` / `ink_bomber`+`mask_enemy` / `mirror_sniper`+`page_swarm`），事件节点与 Boss 区不占普通波次、清房目标仍 7；`content_pending` 清零、波次表进入正常校验；`test_ch4_content` 641（+28）、`test_ch4_plan` 795（−1）、`test_ch4_world` 813（+1），单元 12573/0，十套集成与基线一致全 0 失败；计划仍未接入 `game.gd`（`CHAPTER_PLAN_PATHS[3]` 仍空）、第 4 章仍不可达。第 56 程完成第 4 章内容数据层第 3 步（事件区真实自动触发验证，只做触发与测试层）：`ch4_event` 沿用第 34 程的通用大图区域分支（`big_map` + 类型 `event` + 本章有事件数据），进入区域即按 `Ch4EventData.pick(run_seed, "ch4_event/event")` 打开第 4 章事件页；拿 → 残页 +12，读 → 污染 +8（倍率/上限 100）+ 解明一个残页词或兜底 +6；结算写 `cleared_encounters["ch4_event/event"]`、清房计数 +1（目标 7、HUD 分母 8），重载不重开/不重复奖励，run save 落盘同一键。未新增第 4 章专属触发路径（`game.gd` 仅注释改为 Chapters 2–4）、未接入 `game.gd`、未改章节路由与章末流程；`test_ch4_content` 642（+1）、可玩性集成 810（+55），单元 12574/0，其余九套集成与基线一致全 0 失败；第 4 章仍不可达。第 57 程完成第 4 章内容数据层第 4 步（Boss 4 机制与 `boss_scene` 路由，只做机制与测试层）：计划 `boss_scene` 指向既有 `smiling_archivist.tscn`，通用 Boss 流程复用；既有机制（阶段 1 纸页波、阶段 2 每第 3 次镜面弹幕、阶段 3 改写/镜面/墨雨/纸页波四拍）与数值 HP 520 / 伤害 18 / 速度 92 / 立绘由 `test_ch4_boss` 78 断言 + 可玩性集成锁定；大图生成高度 -18/250 未改。`test_ch4_plan` 797、`test_ch4_world` 814、`test_ch4_content` 644，可玩性集成 869，单元 12657/0；第 4 章仍不可达，第 4 章大图验收与章末收口未开始。第 58 程完成第 4 章章末收口（只做章末流程与测试层）：`_complete_chapter` 新增显式 `_chapter == 3` → `_finish(true)` 结束战役（与旧 `else` 兜底等价）；真实大区世界走完 Boss 4 → 权柄 → 第 4 章 outro → 章末选择 → 战役结束，章末原文/语音/选项/结局规则由可玩性集成锁定；第 1/2/3 章章末流程未改，可玩性集成 869 → 894，第 4 章仍不可达、第 4 章大图验收未开始。第 59 程完成第 4 章大地图系统验收：接力首次尝试（brief62）因 Magpie 网关中断留下的未跟踪初稿 `tests/integration_ch4_bigmap.gd`，核查发现其 `_run()` 内 `enemy_art`/`enemy_fallback` 重复声明导致 GDScript 解析失败、从未跑通，修复后 4766/0，再按任务单补 5 台电梯逐一测速/行程、7 组事件文案与确定性/RNG、Boss 阶段 3 文案、权柄基础池 + 吞噬/归档条件项、其余四个战斗区实际波次与精灵校验，最终 **4869 断言 / 0 失败（连续两次）**；覆盖九区 BFS 连通、22 门实走（20 连通 + 2 只到达）、单矩形边界/相机、纵向（电梯 80 px/s、顶/底门、单向落台、长椅、坠落平面）、门过渡无叠加模态、3 箱 2 碑一次性、多遭遇逐场结算、捷径屏障默认封闭（仅测试注入 `ch4_shortcut`，无游戏内授予）、Boss 4 生成/权柄/章末结束战役、续玩、性能基线、事件/Boss 文案/权柄池与第 4 章专属表现（`smiling_theater.png` 平铺、灰烬/光柱、`embers`、`blood_moon`、其余区空背景且无 theater 层、地图标题「笑面剧场地图」、8 种敌人全专属精灵无回退）；未发现产品缺陷，改动全在验收脚本，未改任何 `scripts/`/`scenes/`/`resources/`；`CHAPTER_PLAN_PATHS[3]` 仍空、第 4 章仍不可达。
3. 下一程建议先由监工定排期：① 第 2 章是否进入可达性开放/演出打磨（验收已证明连通、纵向、战斗、捷径、Boss、续玩链路可用，门视觉/出生点/地图标题已补齐；开放前需拍板第 11/12/13 项并处理四个第 2 章敌人缺美术）；② 第 3 章真实大区世界（第 41 程，结构层）、内容数据层第 1–3 步（第 42 程事件/权柄/Boss 文案，第 43 程计划 `wave` 接线，第 44 程事件区真实自动触发）、Boss 3 机制/`boss_scene`（第 45 程）、章末收口（第 46 程）、大图验收（第 48 程）、门视觉专项与敌人美术核查（第 49 程）均已完成；第 14（视野压缩）、15（海面母题）、16（`ch3_shortcut` 来源）项未拍板前，相关机制/氛围/捷径授予仍不施工；③ 第 3 章剩余的是可达性开放与第 4 章内容，可达性仍须单独拍板，且第 3 章可达性不能早于第 2 章。第 3 章已知美术缺口仍是 `rust_whisperer`/`lung_moth`/`collapse_husk` 三种敌人无专属贴图（与第 2 章同一清单，按任务单不新绘）。④ 第 50 程完成第 4 章大地图可行性核查（只查不施工，见「第 4 章大地图可行性核查（第 50 程）」专节）：大区管线可直接承载，缺口为计划/大区世界/内容数据/Boss 4 机制/验收套件；第 4 章美术素材已画好并接线、8 种敌人全部专属精灵无回退；施工顺序按「计划/图骨架 → 真实大区世界 → 内容数据层 → Boss 4 机制 → 系统验收」，每步前置依赖见专节；第 4 章可达性仍须单独拍板且不能早于第 2/3 章；第 4 章特有开放问题候选（舞台母题、`ch4_shortcut` 来源、是否加事件区、Boss 4 机制范围、战斗密度）只记录在专节，是否新增「待用户确认」条目由监工定。⑤ 第 51 程完成第 4 章计划与图骨架（只做数据层，见「第 4 章计划与图骨架（第 51 程）」专节）：9 区连通图、6 战斗遭遇 + 1 事件占位 = 清房目标 7、11 门 = 9 双向 + 2 单向、每区坠落 240；`content_pending` 只推迟波次表；计划已落地但未路由（`CHAPTER_PLAN_PATHS[3]` 仍空），旧第 4 章世界仍被游戏使用；下一步按第 50 程 D 节顺序是第 4 章真实大区世界，但施工前需先定舞台母题呈现口径（专节 E），本程不猜；第 4 章可达性仍须单独拍板且不能早于第 2/3 章。⑥ 第 52 程完成第 4 章真实大区世界（结构层，见「第 4 章真实大区世界（第 52 程）」专节）：9 个 `BigRoomData` + 9 个 `MDSBigRoom` + 独立世界/场景（22 门 = 20 有向 + 2 只到达、`elite_boss` 单向、捷径屏障默认封闭、入口出生点、每区坠落 240、电梯/单向落台/长椅骨架）；舞台母题只按既有区域氛围落地（无 theater 层），旧第 4 章世界仍被游戏使用，计划仍不路由；下一步按第 50 程 D 节顺序是第 4 章内容数据层（`Ch4EventData`/波次接线/权柄池/Boss 文案与 `boss_scene`），前置是战斗密度与 Boss 4 机制范围口径（专节 E），未拍板前不施工；第 4 章可达性仍须单独拍板且不能早于第 2/3 章。⑦ 第 53 程完成第 4 章内容数据层第 1 步（只做数据层，见「第 4 章内容数据层第 1 步（第 53 程）」专节）：`Ch4EventData` 7 组笑面剧场事件文案（读/拿沿用第 32 程口径、按 seed + 节点 id 轮换、不耗 run RNG）、计划 `authority_pool = [续命, 改写]`（条件项仍走 `ContentLibrary`）、`BossEntranceData` 8 条入场 + `BossPhaseData` 阶段 2/3 各 8 条（不回落第 1/2/3 章，Boss 4 数值/立绘/`boss_script` 未改）；计划仍 `content_pending = true`、无 `wave` 表、无 `boss_scene`，6 场战斗与 `ROOM_WAVES[3]` 六波只校验顺序、清房目标 7；计划仍未接入 `game.gd`（`CHAPTER_PLAN_PATHS[3]` 仍空）、旧第 4 章世界原样保留、第 4 章仍不可达；`test_ch4_content` 613 断言。下一步按第 50 程 D 节顺序是第 4 章内容数据层第 2 步（计划 `wave` 接线，按计划顺序复用 `ROOM_WAVES[3]`，然后 `content_pending` 清零）与第 3 步事件区真实触发验证（沿用第 34/44 程通用分支），两者都不需要第 50 程专节 E 的开放问题拍板；Boss 4 机制/`boss_scene` 仍等机制范围口径（专节 E）。第 4 章可达性仍须单独拍板且不能早于第 2/3 章。⑧ 第 54 程完成第 4 章内容数据层第 2 步（波次接线，只做数据层，见「第 4 章内容数据层第 2 步（第 54 程）」专节）：`chapter_4_demo.tres` 的 4 个战斗区补 `wave` 字典、6 个战斗遭遇按计划顺序逐字接 `ROOM_WAVES[3]` 六波、事件/Boss 无普通波、清房目标 7、`content_pending` 清零；`test_ch4_content` 641（+28，含独立 `game.gd` 实例经 `_plan_wave()` 读回六波）、`test_ch4_plan` 795（−1）、`test_ch4_world` 813（+1）；计划仍未接入 `game.gd`（`CHAPTER_PLAN_PATHS[3]` 仍空）、第 4 章仍不可达。第 56 程完成第 4 章内容数据层第 3 步（事件区真实自动触发验证，只做触发与测试层，见「第 4 章内容数据层第 3 步（第 56 程）」专节）：`ch4_event` 沿用第 34/44 程通用大图区域分支、进入即开第 4 章事件页、`ch4_event/event` 一次性结算、读/拿沿用第 53 程口径；未新增触发路径、计划仍未接入 `game.gd`、第 4 章仍不可达；`test_ch4_content` 642、可玩性集成 810，单元 12574/0。⑨ 第 57 程完成第 4 章 Boss 4 机制与 `boss_scene` 路由（只做机制与测试层，见「第 4 章 Boss 4 机制与 `boss_scene` 路由（第 57 程）」专节）：计划 `boss_scene` 指向既有 `smiling_archivist.tscn`，阶段映射/镜面弹幕/墨雨/改写/数值/生成高度由 `test_ch4_boss` 与可玩性集成锁定；计划仍不路由（`CHAPTER_PLAN_PATHS[3]` 仍空）、第 4 章仍不可达。下一步是第 4 章章末收口与第 4 章大图验收；Boss 4 机制扩展（删除词/复制武器/舞台机关）仍等第 50 程专节 E 拍板，未拍板前不施工。第 4 章可达性仍须单独拍板且不能早于第 2/3 章。⑩ 第 58 程完成第 4 章章末收口（只做章末流程与测试层，见「第 4 章章末收口（第 58 程）」专节）：`_complete_chapter` 新增显式 `_chapter == 3` 分支 → `_finish(true)` 结束战役（与旧兜底等价）；真实大区世界 + 计划走完 Boss 4 击败 → 权柄 → 第 4 章 outro（4 句原文 / `ch4_outro` 语音）→ 章末选择（重写/焚毁）→ 战役结束，结局按 `ending_for` 并写入 `Profile.endings`；旧线性世界遍历补第 4 章停章断言，可玩性集成 869 → 894；`CHAPTER_PLAN_PATHS[3]` 仍空、第 4 章仍不可达。下一步是第 4 章大图验收；Boss 4 机制扩展仍等第 50 程专节 E 拍板；第 4 章可达性仍须单独拍板且不能早于第 2/3 章。⑪ 第 59 程完成第 4 章大地图系统验收（见「第 4 章大地图系统验收（第 59 程）」专节）：接力 brief62 遗留的 `tests/integration_ch4_bigmap.gd`（修复重复声明解析错误后 4766/0，再补齐任务单缺口至 **4869 断言 / 0 失败、连续两次**），覆盖第 36/48 程 D 节 1–10 项 + 第 4 章专属表现；性能基线已记录（普通区首次 12.1–19.7 ms、热 12.3–16.6 ms、Boss 冷 71.4–79.7 ms / 热 45.6–45.9 ms、关背景 11.6–12.0 ms、关天气 38.0–38.5 ms、不生成 Boss 21.7–22.8 ms、门过渡 236.1–243.8 ms）；未发现产品缺陷、未改产品代码；`CHAPTER_PLAN_PATHS[3]` 仍空、第 4 章仍不可达。下一步是第 4 章可达性开放排期（须单独拍板且不能早于第 2/3 章）与第 2/3 章可达性/演出；Boss 4 机制扩展、舞台母题呈现层、`ch4_shortcut` 授予来源、战斗密度等仍等第 50 程专节 E 拍板，未拍板前不施工。⑫ 第 62 程完成第 4 章大图门视觉专项与敌人美术核查（见「第 4 章大图门视觉专项与敌人美术核查（第 62 程）」专节）：第 52 程 9 区 22 门（20 有向 + 2 仅到达，side 5/5/5/5/2）逐门核验，补「侧门内展」「舱口两轴不越界」「世界文件 20+2/直方图交叉校验」，第 4 章集成 4869 → **5004/0**；`ch4_well/top1` 标题已由第 49 程 `caption_area` 夹到 x=0，无产品缺陷、未改产品代码；地图标题「笑面剧场地图」既有断言复核成立（第 1 章不变）；`ROOM_WAVES[3]` 现算 7 敌全部专属 PNG/白 tint/无回退，`mask_enemy`/`seat_husk` 为复用基础场景的美术变体，第 8 个 `echo_enemy` 只在旧第 4 章房间组；`test_enemy_art` 200 → 298，单元 12755/0，第 2/3 章集成无回归；第 4 章仍不可达。**下一程候选（只记录、本程未修）**：第 60 程样图问题——底部 HUD 遮挡（待确认第 13 项）、1536×864 背景纵向平铺接缝、`boss_background` 被静态背景遮住（与第 15 项相关）、无 `Arena` 的入口/枢纽套用休整文案、纵井电梯贴房间左缘、Boss 脚部被 HUD 压住（同第 13 项）、`breathing_ruins.png` 与第 1 章色调接近；其中与第 13/15 项相关的部分拍板前不施工、不定口径，其余待监工排期。⑬ 第 63 程（施工后进程中断）与第 64 程（接力核验收尾）完成第 60 程样图的两项可修问题（见「第 2–4 章大图样图问题修复（第 63 程）」专节）：① 大区静态背景改为以房间底部为锚、自下而上平铺，奇数行 `flip_v` 镜像，相邻瓦片共用边缘行，1440/2160 高房间的纵向硬接缝消除（`ch4_boss` 顶部黑色舞台地面带、`ch2_boss`/`ch3_boss` 顶部拼接线消失）；② 无 `Arena` 的大图房间只有作者了长椅或商店时才走休整目标与 `RestRoomData` 文案，三章入口改回「继续前进」、不再抽别章休整句（枢纽仍保留休整分支）。9 张样图重拍并核验（尺寸/非空/非黑非白、接缝行行差低于同段中位数），测试 +18/+106/+123/+129 条断言、全 0 失败；`CHAPTER_PLAN_PATHS` / `MDS_WORLD_FILES` / 章节路由/可达性/相机/HUD/电梯/门逻辑未动。第 60 程剩余问题只记录、本程未修：问题 1/6（底部 HUD 遮挡、Boss 脚部被 HUD 压住）对应待确认第 13 项，拍板前不改相机边距/偏移、不改 HUD 面板高度/透明度；问题 3（`boss_background` 被 `z_index=-20` 静态背景遮住）与待确认第 15 项相关且范围更大（三章 Boss 背景都受影响），拍板前不定口径、不改 z 层级；问题 5（纵井电梯贴房间左缘）是作者布局 + 相机夹取的取景限制、不是缺陷，不修、不动电梯位置与相机；问题 7（第 2 章入口背景与第 1 章色调接近）是既有素材，仅记录供监工判断样图代表性，不换图、不改色调。待确认第 11–16 项未碰、未新增条目。⑭ 第 65 程按 brief69 转向叙事审计 E2 第一批（见「NPC 个人事件（第 65 程）」专节）：demo 可见的陆沉/阿砚/咕噜各一个 Hub 个人事件（陆沉·红色文件夹/信任 6、阿砚·再烧一次炉/托付 12、咕噜·不卖的「永」/熟悉 2），触发 = 信任档 + `Profile.demo_cleared`，用现有 `DialogueUI`，读完最后一行才写 `[npc] events`、中途关闭不消耗、零奖励、咕噜事件不跳商店；闻烬/白榆仍不可见、无事件。单元 12960/0（+187）、菜单集成 419/0（+28），其余十套集成与基线一致全 0 失败；第 1 章 9 房间/6 波次/事件/清房目标 6/结束流程、Hub 闲聊与关键词回应、`[npc] trust` 与信任数值、NPC 立绘、经济/锻造/商店数值均未改；第 2–4 章仍不可达。下一程候选：① 结局文本加厚（E3：每个结局补五名 NPC 余味、「笑面史官身份」「最后一页」回收）；② 闻烬/白榆的可见性与个人事件——须先由用户/监工拍板是否在 demo 中可见，未拍板前不设为可见、不写事件；③ 阿砚「叫出真名」完整分支（真名、锤子留在铁砧、第一次走出铁匠铺）与关键道具物品化（红色文件夹/玻璃瓶进背包或收藏）本程只记录缺口，未施工。第 60 程样图问题 1/3/5/6/7 仍未修，与第 13/15 项相关的部分拍板前不施工；第 11–16 项仍开放、未施工。⑮ 第 66 程完成叙事审计 E3（结局文本加厚，见「结局文本加厚（第 66 程）」专节）：`EndingEchoData` 五结局 × 五 NPC 各一句余味（25 句）+ 每结局一段「笑面史官身份 / 最后一页」回收（5 段）；结束屏 `Echoes` 标签与结局画廊已解锁条目展示，未解锁仍按原占位；5 个结局 id/标题/现有两句正文/`ending_for` 判定/`Profile.endings` 记录与存档格式未改，demo 内不可达的复原/焚毁余味由测试层验证。单元 12960 → **13429/0**（+469），十一套集成与基线逐套件一致全 0 失败；第 2–4 章仍不可达、`CHAPTER_PLAN_PATHS` / `MDS_WORLD_FILES` 未动。下一程候选：① 闻烬/白榆可见性与个人事件——待拍板，未拍板前不设可见、不写事件；② 阿砚「叫出真名」完整分支（真名、锤子留在铁砧、第一次走出铁匠铺）与关键道具物品化（红色文件夹/玻璃瓶/断尖笔/手绘地图）——仍只记录缺口；③ 结局余味的配音/插画/独立场景（本程只做文本与展示）；④ 第 60 程样图问题 1/3/5/6/7 仍未修，与第 13/15 项相关的部分拍板前不施工；第 11–16 项仍开放、未施工。⑯ 第 67 程接力收尾第 66 程（E3 结局文本加厚，第 66 程进程死亡后重跑）：独立复核 `EndingEchoData` 文本/结束屏 `Echoes`/画廊已解锁展示/判定与存档不变，未发现实现缺陷、未返工；`--headless --import` / `--quit` 退出 0、`ERROR` 0，单元 **13429/0**、十一套集成 **894 / 102 / 613 / 207 / 113 / 59 / 419 / 45 / 2315 / 4358 / 5133** 全 0 失败（三个大图套件均跑完）、退出泄漏 **10/10 clean**、demo 像素 **36/0**，与第 66 程自称逐项一致；产品/测试/文档按项提交后工作区干净，未开新功能、未改产品行为。下一程候选沿用第 ⑮ 条四项：① 闻烬/白榆可见性与个人事件——待拍板，未拍板前不设可见、不写事件；② 阿砚「叫出真名」完整分支与关键道具物品化——仍只记录缺口；③ 结局余味的配音/插画/独立场景；④ 第 60 程样图问题 1/3/5/6/7 仍未修，与第 13/15 项相关的部分拍板前不施工；第 11–16 项仍开放。⑰ 第 68 程完成全游戏例行扫描（brief72，见「例行扫描（第 68 程）」专节）：六个扫描面逐项核对（关闭回退/焦点/存档边界/性能/文案/回归抽查），基线复核与第 67 程逐项一致（单元 13429/0、十一套集成 894 / 102 / 613 / 207 / 113 / 59 / 419 / 45 / 2315 / 4358 / 5133、退出 10/10、像素 36/0），三个大图套件均跑完。发现并修复 1 项 Hub 产品行为缺陷：档案馆升级已到 demo 上限 Lv.10 时行仍可点、价格照显示，点击返回「记忆碎片不足：需要 X，你只有 Y」（Y > X）的假错误——`ArchiveData.MAX_LEVEL` 单一来源、`Profile` 改读常量、`ArchiveUI` 满级行改「已满级」/「已达上限」并禁用、`_buy` 报满级、陆沉职能描述同步改「demo 上限 10 级」；回归断言单元 13429 → **13434/0**（+5）、菜单集成 419 → **428/0**（+9）。其余五个扫描面未发现新缺陷；第 1 章 9 房间/Hub 冷热加载、门过渡、Boss 帧与第 21/22 程基线同量级（帧间隔贴 120 FPS 预算，门过渡 226.6–240.0 ms，逐房原始构建 5.1–77.4 ms），Hub `load` 偏高与 `main.tscn` 偏低互相抵消、按任务单只记录不优化；隐藏书库与结局余味抽查无回归。下一程候选沿用第 ⑯ 条四项：① 闻烬/白榆可见性与个人事件——待拍板，未拍板前不设可见、不写事件；② 阿砚「叫出真名」完整分支与关键道具物品化——仍只记录缺口；③ 结局余味的配音/插画/独立场景；④ 第 60 程样图问题 1/3/5/6/7 仍未修，与第 13/15 项相关的部分拍板前不施工；第 11–16 项仍开放。本程未新增待拍板项、未推送、未更新网页版。⑱ 第 69 程完成全游戏例行扫描（brief73，见「例行扫描（第 69 程）」专节）：六个扫描面逐项核对（关闭回退/焦点/存档边界/性能/文案/回归抽查），基线复核与第 68 程逐项一致（单元 13434/0、十一套集成 894 / 102 / 613 / 207 / 113 / 59 / 428 / 45 / 2315 / 4358 / 5133、退出 10/10、像素 36/0），三个大图套件均跑完。发现并修复 2 项（3 处）Hub 文案与行为不符：① 陆沉「档案馆升级」开启语仍写「等级没有尽头」（第 68 程漏改的运行时消息），与 `ArchiveData.MAX_LEVEL = 10` 冲突——改为按常量生成「demo 每个方向修到 Lv.%d 为止，档案本身没有尽头」，服务列表句同步读常量；② 闻烬「签一份契约」描述写「本局起始多 1 次奖励重选」，实际发放 10 残页 + 污染 6——描述改为实际效果；③ 闻烬「买情报」描述/消息写「首次攻击/第一击」，实际是 `wenjin damage` +2 永久加到所有武器——两处改为「所有武器的伤害永久 +2」。未改任何数值/存档/上限/成长设计。回归断言：单元 13434 → **13451/0**（+17）、菜单集成 428 → **433/0**（+5）；gamepad 207、run_save 613 复跑 0 失败。性能按第 68 程同口径实测（Hub `load` 905.5–981.5 ms、`main.tscn` 2015.9–2357.9 ms、首房 avg 8.33 ms/p95 8.70–8.72、门过渡 264.0–274.8 ms、逐房构建 4.3–38.6 ms、Boss avg 8.33/p95 8.72–8.84），与第 68/21 程基线同量级，门过渡略高 15% 只记录不优化；隐藏书库、结局余味、档案馆满级行抽查无回归。下一程候选沿用第 ⑯ 条四项：① 闻烬/白榆可见性与个人事件——待拍板，未拍板前不设可见、不写事件；② 阿砚「叫出真名」完整分支与关键道具物品化——仍只记录缺口；③ 结局余味的配音/插画/独立场景；④ 第 60 程样图问题 1/3/5/6/7 仍未修，与第 13/15 项相关的部分拍板前不施工；第 11–16 项仍开放。本程未新增待拍板项、未推送、未更新网页版。⑲ 第 70 程完成全游戏例行扫描（brief74，见「例行扫描（第 70 程）」专节）：六个扫描面逐项核对，基线复核与第 69 程逐项一致（单元 13451/0、十一套集成 894 / 102 / 613 / 207 / 113 / 59 / 433 / 45 / 2315 / 4358 / 5133、退出 10/10、像素 36/0），三个大图套件均跑完。发现并修复 5 项（8 处）文案/常量与行为不符：① 局内商店「缝合书页」写「恢复 45 生命与 30 墨量」，实际 `_apply_reward` 是 35 生命 / 45 墨量 / 污染 −12——卡面改为实际值；② 档案馆买到第 10 级（demo 上限）后仍报「下次需要 X 碎片」——满级提示改报上限；③ 阿砚「神铸」固定报「锻造祝福 +1」且描述写「免费提升」，实际祝福 `FORGE_BONUS_TOTAL_CAP = 3.0` 封顶、代码硬编码 3.0——改共享常量并按实得 0/0.5/1 点如实报数、描述改为「基底直接提升 1 级…（上限 3）」；④ 咕噜货架描述只说「换词」，18 件货含 3 件遗物——补「与遗物」；⑤ 零污染遗物 `clean_ink_lantern` 的奖励卡印「污染 +0」——新增 `_relic_reward_text()` 仅在污染 > 0 时写该行。未改任何数值/存档/上限/成长设计/可达性。回归断言：单元 13451 → **13465/0**（+14）、菜单集成 433 → **445/0**（+12）、可玩性集成 894 → **899/0**（+5）；gamepad 207、run_save 613、ui_prompts 113 复跑 0 失败；收尾完整套件全绿。性能按第 68/69 程同口径实测（Hub 首次 `load` 977.0 ms / `_ready`+首帧 603.4 ms、`main.tscn` 2346.9 / 687.7 ms、首房 avg 8.25–8.33 ms / p95 8.61–8.62、门过渡完整 442.1/449.6 ms（到房间激活 121.8/221.7 ms，与第 68/69 程 226.6–274.8 ms 端点口径不同）、无持续掉帧），与基线同量级、只记录不优化；隐藏书库、结局余味、档案馆满级行、第 69 程三处文案抽查无回归。记录未修：设置页全屏切换不写 Profile（补键会改设置存档形状，任务单未要求），只记录、不新增待拍板项。下一程候选沿用第 ⑯ 条四项：① 闻烬/白榆可见性与个人事件——待拍板，未拍板前不设可见、不写事件；② 阿砚「叫出真名」完整分支与关键道具物品化——仍只记录缺口；③ 结局余味的配音/插画/独立场景；④ 第 60 程样图问题 1/3/5/6/7 仍未修，与第 13/15 项相关的部分拍板前不施工；第 11–16 项仍开放。本程未推送、未更新网页版。⑳ 第 72 程完成全游戏例行扫描（brief76，见「例行扫描（第 72 程）」专节）：第 71 程（brief75）开局即因 Magpie 网关中断夭折（`.supervisor/session75.log` 仅两行、零产出、无提交），本程为全新重跑。六个扫描面逐项核对，基线复核与第 70 程逐项一致（单元 13465/0、十一套集成 899 / 102 / 613 / 207 / 113 / 59 / 445 / 45 / 2315 / 4358 / 5133、退出 10/10、像素 36/0），三个大图套件均跑完。发现并修复 1 项 Hub 产品行为缺陷：跟阿砚打招呼时 `talk_to_npc` 的 `&"ayan"` 分支直接调用 `upgrade_sword_base()`，而它是真正扣碎片、提升断页剑基底的付费操作——探针复现碎片 100 → 90、基底 Lv.0 → Lv.1，碎片不足时每次问候还重复附「记忆碎片不足」；修复为问候只报当前基底等级并指向「言灵对话 → 锻造基底」，不写死价格、不改锻造数值/折扣/信任/存档；未改任何数值/存档/上限/成长设计/可达性。回归断言：单元 13465 → **13474/0**（+9，问候不扣碎片/不升级、提到锻造基底与当前 Lv.、关闭后解冻玩家、显式职能仍按 10 + Lv×10 扣费升级）；menus 445、run_save 613、gamepad 207、ui_prompts 113、playability 899 复跑 0 失败；收尾完整套件全绿。性能按第 68/69/70 程同口径实测（Hub `load` 753.1–905.1 ms / `_ready`+首帧 461.6–556.4 ms、`main.tscn` 2779.9–2921.8 ms、第 1 章逐房冷 3.84–37.39 / 热 3.77–23.06 ms、Boss avg 8.33–8.45 ms / peak 10.27–25.36、门过渡 225.26–225.66 ms），与基线同量级、只记录不优化；隐藏书库、结局余味、档案馆满级行、第 69/70 程文案抽查无回归。记录未修沿用第 70 程：设置页全屏切换不写 Profile；第 60 程问题 1/3/6 与第 13/15 项相关、拍板前不施工，5/7 非缺陷；第 11–16 项仍开放。下一程候选沿用第 ⑯ 条四项：① 闻烬/白榆可见性与个人事件——待拍板，未拍板前不设可见、不写事件；② 阿砚「叫出真名」完整分支与关键道具物品化——仍只记录缺口；③ 结局余味的配音/插画/独立场景；④ 第 60 程样图问题 1/3/5/6/7 仍未修，与第 13/15 项相关的部分拍板前不施工。本程未推送、未更新网页版。㉑ 第 73 程完成全游戏例行扫描（brief77，见「例行扫描（第 73 程）」专节）：基线复核与第 72 程逐项一致（单元 13474/0、十一套集成 899 / 102 / 613 / 207 / 113 / 59 / 445 / 45 / 2315 / 4358 / 5133、退出 10/10、像素 36/0），三个大图套件均跑完。发现并修复 2 项产品行为缺陷：① Hub 词服务无限碎片泵——`Profile.DEFAULT_OWNED` 首次开局即含全部 18 个第 1 章词，`Hub._unlock_random_word()` 兜底每次返 8 碎片，使咕噜「买一条传闻」（收 3）净 +5、陆沉「讲述档案」（收 6）净 +2 且可无限连点落盘；新增 `Hub.unlockable_word_pool()`，池空时拒绝并说明不收费，有词时仍按原价扣 3/6 并解锁，`_unlock_random_word()` 不再支付碎片；单元 13474 → **13490/0**（+16，`test_hub_final::_test_word_services`）。② 局内商店对已拥有的缓存货仍扣残页——货架首次打开时缓存，之后从奖励/宝箱/残碑拿到同一遗物/词再买该行时 `add_relic`/`add_word` 静默拒绝、残页已扣且行可重复点；探针复现残页 100 → 75、遗物数量不变；`game.gd::_shop_offer_owned()` + `RunShopUI.mark_owned()` 已拥有则禁用该行、标签「已拥有」、回话「不收残页」、不扣费；第 1 章 demo 集成 102 → **109/0**（+7）。未改数值/存档/可达性/结局格式；未修记录：暂停确认取消后的 one-shot 连接残留（当前不可见）、`NPC.interact()` 死代码、设置页全屏不持久、第 60 程样图问题 1/3/5/6/7 维持原结论；第 11–16 项仍开放、未碰。下一程候选沿用第 ⑯ 条四项：① 闻烬/白榆可见性与个人事件——待拍板，未拍板前不设可见、不写事件；② 阿砚「叫出真名」完整分支与关键道具物品化——仍只记录缺口；③ 结局余味的配音/插画/独立场景；④ 第 60 程样图问题 1/3/5/6/7 仍未修，与第 13/15 项相关的部分拍板前不施工。本程未推送、未更新网页版。㉒ 第 74 程完成 README 重写（见「README 重写（第 74 程）」专节）：只改仓库根 `README.md`，按「简介 → 当前可玩范围 → 已建成但未开放 → 核心系统 → 操作 → 运行 → 开发状态」重写；删除 0.11.0/0.10.0/0.7.0 三层旧日志、SAPI 旁白宣传、Android 触屏与「依次穿过四章」等与现状不符的说法；数字按仓库实测（词条 95、开局 18、demo 6 武器/6 遗物/6 敌人、内容库 12/9/14、13 法术形态、第一章 9 房间/清房目标 6、5 结局且 demo 可达 3、6 首配乐、155 个脚本 26,849 行、单元 13,490、十一套集成 14,296、第 2/3/4 章大图验收 2,315/4,358/5,133）；brief 中「可收集 50」无仓库依据，未采用；第 2–4 章如实写为已建成未开放。README-only，未改代码/场景/资源/测试；单元 13,490/0、十一套集成与基线一致全 0 失败、退出 10/10、像素 36/0；未推送、未更新网页版、未创建 Release、未宣布里程碑。下一程为 Windows 导出程（按 DECISIONS「再更正」排在 README 程之后、里程碑推送与 Release 之前）：用既有 `export_presets.cfg` Windows 预设从本程 HEAD 导出并打 zip，核验 exe + pck + 体积、记录导出日志与文件清单；Windows 实机首跑不在该程范围。下一程候选沿用第 ⑯ 条四项：① 闻烬/白榆可见性与个人事件——待拍板，未拍板前不设可见、不写事件；② 阿砚「叫出真名」完整分支与关键道具物品化——仍只记录缺口；③ 结局余味的配音/插画/独立场景；④ 第 60 程样图问题 1/3/5/6/7 仍未修，与第 13/15 项相关的部分拍板前不施工；第 11–16 项仍开放。㉓ 第 75 程完成 Windows 导出（见「Windows 导出（第 75 程）」专节）：按用户 2026-11-06 13:42 拍板，从 HEAD `7d11fc2` 用既有 `Windows Desktop` 预设（`embed_pck=true`，未改 `export_presets.cfg`）导出 release exe **132,104,632 bytes**（PE32+ GUI x86-64，SHA-256 `7d4811f4…4242`），内嵌 PCK **22,930,348 bytes** 与独立 `--export-pack` 产物逐字节一致、12 个关键路径齐全、`--main-pack` 无头启动退出 0；打 zip `artifacts/releases/v0.12.0/changzi-adventure-v0.12.0-windows.zip` **59,572,799 bytes**（1 文件、`unzip -t` OK、包内 exe 哈希一致，产物不提交）。基线单元 13,490/0、十一套集成 899…5,133 全 0、退出 10/10、像素 36/0。**Windows 实机首跑待验证**（Linux VM 未跑 exe、未用 wine/虚拟机）；Release tag/zip 为 v0.12.0，但包内 `config/version`/标题屏仍 0.11.0-demo（本程未改产品配置）。下一步由监工执行里程碑快照推送 + 网页更新，再由用户配合 passkey 创建 Release `v0.12.0`（pre-release，标题「v0.12.0 — 第一章 + T17 完整可玩 · 第 2–4 章内容入库（未开放）」）并上传本程 zip；Release notes 须含可玩范围、已建成未开放清单、网页版地址、测试数字与「Windows 实机首跑待验证」。本程未推送、未更新网页版、未创建 Release。㉔ v0.12.0 里程碑已由监工执行完毕（2026-11-06 16:24 巡查程）：网关开局不通（HTTP 000）已重启复查通过；快照推送 243 文件到 main（远程提交 `39c2b8915638d38dc1d5d58086736c556d551b52`，`list_commits` 回读验证，同步记录已追加第 3 条）；网页版同步更新（`redeploy-ok: 7226789`，公网 200）。Release `v0.12.0` 仍待用户本人处理：浏览器登录 github.com + passkey 创建 pre-release 并上传 `artifacts/releases/v0.12.0/changzi-adventure-v0.12.0-windows.zip`，另需他在 Windows 实机上首跑验证 exe（Linux 无法验证）。下一程（brief80 / 第 76 程）由监工定为第 2 章可达性接线第 1 步：先核查接线缺口（`CHAPTER_PLAN_PATHS[1]`、`MDS_WORLD_FILES[1]`、第 1 章章末 `_complete_chapter` 分支、旧第 2 章世界引用），再把第 2 章计划与大区世界接入、打通第 1 章章末选择 → 第 2 章开场，测试层走通 Boss 2 → 权柄 → outro → 章末停章；第 1 章其余流程/清房目标 6/9 房间/6 波次/事件/结局判定不变，第 3/4 章仍不可达；`ch2_shortcut` 保持默认封闭（第 11 项未拍板，不新增授予）、电梯速度不动（第 12 项）、不改相机/HUD（第 13 项）。第 11–16 项仍开放、未施工；闻烬/白榆可见性、阿砚真名分支、关键道具物品化仍只记录缺口。㉕ 第 76–77 程完成第 2 章可达性接线第 1 步（见「第 2 章可达性接线第 1 步（第 76–77 程）」专节）：第 1 章章末选择后 `_complete_chapter` 由 `_finish(true)` 改为 `demo_cleared = true` + `Flow.save_profile()` + `_start_chapter(1)`；章末选项/效果、第 2 章计划/波次/事件/Boss 2 数值、第 1 章内容与存档形状均未改。真实链路走通「第 1 章通关 → 章末选择 → 第 2 章开场（6 句 + `ch2_intro` 语音 + 配乐）→ `ch2_entry` 出生落地 → 真实战斗清 `ch2_branch_a` 两场遭遇 → Boss 2 → 权柄 → outro → 章末选择 → 停章」；第 2 章后不进第 3 章、第 3/4 章仍不可达、`ch2_shortcut` 仍无游戏内授予。断言 playability 899 → **913**、menus 445 → **456**、run_save 613 → **624**，单元 **13,490 / 0**，其余八套集成 109/207/113/59/45/2,315/4,358/5,133 全 0 失败。下一步仍由监工定第 2 章演出打磨/四敌缺美术/第 11–13 项拍板与第 3 章可达性排期；第 14–16 项、闻烬/白榆、阿砚真名、关键道具物品化仍只记录缺口。README/网页版仍写「第 2–4 章不可达」，待更新。㉖ 第 78 程完成第 2 章四敌缺美术接入（见「第 2 章四敌缺美术接入（第 78 程）」专节）：用户提供的 `breath_hound.jpg` 与三拼图 `lung_moth+rust_whisperer+collapse_husk.jpg` 经 flood-fill 去白底（保浅色毛边）、按个体裁切、统一 96×96 缩放、低饱和墨灰调色板对齐、24 色量化 + `#101820` 1 px 轮廓，产出四张 96×96 PNG（各 25 色、二进制 alpha、四角透明、无白边）；`ENEMY_ART` 新增四条、`ENEMY_ART_FALLBACK` 清空，四种敌人全部白 tint 渲染，第 3 章沿用的三种不再回退第 1 章美术。`test_enemy_art` 298 → **357**、第 2 章大图集成 2,315 → **2,330**、第 3 章大图集成 4,358 → **4,362**、像素资产复核 36 → **40 / 0**；单元 **13,490 → 13,549 / 0**，十一套集成 913 / 109 / 624 / 207 / 113 / 59 / 456 / 45 / 2,330 / 4,362 / 5,133 全 0 失败，退出泄漏 10/10、import/quit 0 ERROR；敌人数值/波次/行为、门/电梯/长椅/捷径、章节路由与可达性、存档、NPC 立绘、第 1 章内容均未改；原图两份 JPG 仍在 `.supervisor/art-inbox/`；未推送、未更新网页版、未创建 Release。下一步由监工定：第 2 章演出打磨 / 第 11–13 项拍板 / 第 3 章可达性排期（第 3 章可达性不能早于第 2 章，且须单独拍板）。㉗ 第 80 程完成第 3 章可达性接线第 1 步（见「第 3 章可达性接线第 1 步（第 80 程）」专节）：`game.gd` 四个路由点改指第 3 章大图计划/世界/场景，`_complete_chapter` 的 `_chapter == 1` 由 `_finish(true)` 改为 `_start_chapter(2)`；第 2 章章末选项/效果、第 3 章计划/波次/事件/Boss 3 数值与机制、第 1/2 章内容、存档形状均未改，第 3 章末仍停章、第 4 章仍不可达。真实链路走通第 1 章 → 第 2 章 → 章末选择 → 第 3 章开场（`ch3_intro` + `chapter_sea.ogg`）→ `ch3_entry` 出生落地 → 真实 `ch3_branch_a/Arena` 清房 → `ch3_event` 一次性 → Boss 3 → 权柄 → outro → 章末选择 → 停章；单元 **13,549/0**、playability **878/0**、run_save **631/0**、ch2 **2,331/0**、ch3 **4,364/0**、ch4 **5,133/0**，其余套件不变；退出 10/10、像素 40/0。`ch3_shortcut` 仍无授予（第 16 项）、视野压缩/海面母题未做（第 14/15 项）、电梯/相机/HUD 未动（第 12/13 项）。下一步由监工定：第 2 章演出打磨 / 第 11–13 项拍板 / 第 3 章演出打磨与第 4 章可达性排期（第 4 章须单独拍板）；README「第 2–4 章不可达」待安排更新。㉘ 第 81 程完成 README 口径更新（见「README 口径更新（第 81 程）」专节）：只改仓库根 `README.md`——可玩范围改为第 1–3 章（第 1 章章末 → 第 2 章 → 第 3 章，第 3 章章末进结局屏）、已建成但未开放只剩第 4 章、不可达原因删去「第一章停章」与「第 3 章计划未接入」、结局口径改为 demo 可达 4 个（复原经跨章仁慈 ≥ 2 且污染 < 60 可在第三章末达成；焚毁档案仍不可达）、测试数字更新为单元 13,549 / 十一套集成 14,326（2,331 / 4,364 / 5,133）/ 退出 10/10 / 像素 40/0。游戏代码 / 场景 / 资源 / 测试 / 配置零改动，章节路由与可达性未动，第 11–16 项未碰。下一步：第 2–3 章可达的里程碑推送与网页版更新由监工定；第 4 章可达性仍须单独拍板。㉙ 第 83 程完成全游戏例行扫描（第 1–3 章 + Hub + 各系统，见「例行扫描（第 83 程）」专节）：修复跨章 Boss 检查点续玩吞掉本章权柄三选一（新增 `authority.chapter` 存档键、旧检查点按文件内章节兼容），帮助页「地图（第一章）」改为「地图」；单元 13,549/0、十一套集成 14,354（run_save 657 / menus 458）、退出 10/10、像素 40/0；其余四个扫描面未发现新缺陷，第 4 章仍不可达、第 11–16 项未碰。㉚ 第 84 程完成全游戏例行扫描（第 1–3 章 + Hub + 各系统，见「例行扫描（第 84 程）」专节）：修复 Boss 已死检查点续玩时目标条写死第 1 章 Boss 名（改为按本章 `chapter["boss_name"]` 取名）；integration_run_save 657 → 659、integration_playability 878 → 879，单元 13,549/0、十一套集成 14,357、退出 10/10、像素 40/0；其余五个扫描面未发现新缺陷，第一章收口判定仍留给监工，第 4 章仍不可达、第 11–16 项未碰。本程会话曾在提交前中断，由第 85 程核验在途 diff、跑通基线并补交 fix/test/docs。㉛ 第 85 程完成全游戏例行扫描（第 1–3 章 + Hub + 各系统，见「例行扫描（第 85 程）」专节）：先接力收尾第 84 程（核验在途 diff、复跑基线、补交 fix/test/docs 并补记），再修复权柄三选一打开时 HUD 未隐藏（`_sync_hud_visibility()` 模态列表补 `_authority_choice`）；integration_run_save 659 → 660、integration_playability 879 → 881，单元 13,549/0、十一套集成 14,360、退出 10/10、像素 40/0；其余五个扫描面未发现新缺陷，第一章收口判定仍留给监工，第 4 章仍不可达、第 11–16 项未碰。㉜ 第 86 程完成第 1–3 章可达后的又一次全游戏例行扫描（见「例行扫描（第 86 程）」专节）：修复延时打开的必选页（事件页 0.8 s、权柄三选一 1.2 s）与地图/暂停/背包/商店等页面叠加、以及同一窗口内踏门时在 MDS 淡入淡出层下开页导致黑屏卡住的真实产品行为缺陷（`game.gd` 新增 `_ui_blocks_delayed_page()` 与 `_room_loaded_msec`；事件页读 `changing_room` 取消本次、重进重排；权柄三选一等待过场与 0.175 s 淡入结束）；integration_ch1_event 59 → 73、integration_playability 881 → 887，单元 13,549/0、十一套集成 14,380、退出 10/10、像素 40/0；其余五个扫描面未发现新缺陷，第一章收口判定仍留给监工，第 4 章仍不可达、第 11–16 项未碰。㉝ 第 87 程（brief91）只写完任务 0 基线就中断（`session91.log` 12 行、无扫描/提交/收尾，疑似 Magpie 网关中断；基线数字与第 86 程收尾一致），无产出可接续。㉞ 第 88 程（brief92）为全新重跑，完成第 1–3 章可达后的又一次全游戏例行扫描（见「例行扫描（第 88 程）」专节）：六个扫描面逐项核对，修复 1 项真实产品行为缺陷——房间奖励页不等待其它页面/过场。敌人尸体由 0.35 s 场景计时器释放且暂停时照走，最后一击到真正清房之间开地图/暂停/背包，清房发生在页面背后，`_on_room_cleared` 的延时必选奖励页直接盖上去；地图 `close()` 又无条件恢复世界。`_open_reward()` 改为与事件页/权柄三选一一致的等待（过场结束 + 无其它页面），新增 `_reward_pending` 让等待期间的检查点保持沉默（否则续玩会得到「已清房 + 没拿奖励」），死亡与清房同窗口时不再欠奖励；未改奖励内容/数值/存档形状/章节路由。integration_run_save 660 → 675，单元 13,549/0、十一套集成 14,395（887/109/675/207/113/73/458/45/2,331/4,364/5,133）、退出 10/10、像素 40/0；其余五个扫描面（焦点/存档边界/文案/回归抽查/性能只记录）未发现新缺陷，第一章收口判定仍留给监工，第 4 章仍不可达、第 11–16 项未碰。㉟ 第 89/90 程（brief93/94）基线跑绿后中途中断（当时误记为「启动即死」，第 97 程核对日志更正：两程都记完任务 0 基线才停，零提交、无扫描结论）。第 91 程（brief95）按 `.supervisor/DECISIONS.md` 2026-11-07 09:45 的监工拍板完成**第 4 章可达性接线第 1 步**（见「第 4 章可达性接线第 1 步（第 91 程）」专节）：只改四个路由点——`CHAPTER_PLAN_PATHS[3]` 接 `chapter_4_demo.tres`、`MDS_WORLD_FILES[3]`/`MDS_CHAPTER_SCENES[3]` 改指第 4 章大图世界与场景、`_complete_chapter` 的 `_chapter == 2` 由 `_finish(true)` 改为 `_start_chapter(3)`；第 4 章末 `_finish(true)` 结束战役未改。真实链路走通「第 3 章章末选择 → 第 4 章开场（8 句 + `ch4_intro` + `chapter_theater.ogg`）→ `ch4_entry` 出生落地 → 真实 `ch4_branch_a/Arena` 清房 → `ch4_event` 一次性事件页 → Boss 4 → 权柄 → 第 4 章 outro → 章末选择 → 战役结束 + 结局写入 `Profile.endings`」。第 4 章计划/波次/事件文案/Boss 4 数值与机制、第 1/2/3 章内容、存档形状均未改；`ch4_shortcut` 仍无授予（第 16 项）、舞台母题/机制扩展/战斗密度未动。单元 **13,551/0**（+2）、playability **847/0**（887 → −40）、ch3 4,364/0、ch4 5,133/0，其余套件不变全 0 失败；退出 10/10、像素 40/0。**第 4 章自此可达**，一至四章主流程全线接通。下一程候选（监工排期）：① 全流程 1→4 集成验收（一条从头到尾的真实通关链路断言，含跨章存档/权柄结转与第四章「焚毁档案」结局路径）；② 里程碑推送 + 网页版更新（第 2–4 章接线成果，需监工执行快照推送与 redeploy）；③ 最终验收程（全新会话 AI 自主通关）；④ `README.md` 口径更新（现在仍写「第 4 章不可达」，第 81 程先例是单独一程只改 README）。第 11–16 项仍开放、未施工；闻烬/白榆可见性、阿砚真名分支、关键道具物品化仍只记录缺口；第 60 程样图问题 1/3/5/6/7 维持原结论（与第 13/15 项相关的部分拍板前不施工）。㊱ 第 92 程（brief96）基线跑绿（单元 13,551/0、十一套集成 14,395、退出 10/10、像素 40/0，逐套件与第 91 程一致）并做完缺口分析（既有 `integration_playability` 的四章各走各的 leg、章间交棒只断言「进入下一章 + 开场文本/音乐/语音」，缺一条从新局到结局的连续链路与交棒前后的落盘/读回结转），在动手写链路之前中断，零提交。㊲ 第 93/94/95 程（brief97/98/99）启动即死（`session97/98/99.log` 均只有 `[claude-code:unrecognized_model]`），零产出、无提交。㊳ 第 96 程（brief100，2026-11-07 18:35 用户点名拉起）无声夭折、零提交，只留下未提交的 `tests/probe_chain_boot.gd`（Hub 教学 → `request_run()` → 第 1 章开场的启动探针，单独跑 5/5 通过）。㊴ 第 97 程（brief101，全新重跑）**完成全流程 1→4 集成验收**（见「全流程 1→4 集成验收（第 97 程）」专节）：先核查并删除第 96 程遗留探针（同一路线已被链路前段覆盖），再在 `integration_playability` 新增 `_test_full_campaign_chain()`——一条局从新局 → Hub 教学 → 第 1 章 9 房（清房 6）→ 章末选择 → 第 2 章大图（7 场 + 事件一次性）→ 第 3 章大图 → 第 4 章大图 → 焚毁结局，再从真实 Boss 4 检查点续玩走「重写名册」拿复原结局；每处交棒断言路由三槽、开场文本逐句/语音/配乐、`SpawnPoint` 落地、清房目标与 HUD 分母、坠落平面，以及上一章的 `cleared_encounters`/权柄 `authority.chapter`/章末选择效果从磁盘 run save 读回一致。修复 1 项真实产品缺陷：Boss 已死检查点续玩会重新锁上死掉 Boss 的房间（重放入场音效、把「已经倒下」目标条改写回击杀命令），`_update_room_locks()` 在 `_boss_defeated` 时跳过 Boss 房，并用真实存档位置做反向验证（回退修复复现 2 条失败）。核实第 81 程 README 口径「复原可在第三章末达成」已过期：`ending_for` 无章节参数、判定只在战役结束，README 四处待更新（单独一程）。收尾单元 **13,551/0**、十一套集成 **14,985**（1,475 / 109 / 677 / 207 / 113 / 73 / 458 / 45 / 2,331 / 4,364 / 5,133）全 0 失败、退出 10/10、像素 40/0。下一步候选（监工排期）：① 里程碑推送 + 网页版更新（第 2–4 章接线 + 全流程验收成果，由监工执行）；② README 口径更新单独一程；③ 最终验收程（全新会话 AI 自主通关，按 DECISIONS 排期）。㊵ 第 99 程（brief103，第 98 程被判「启动即死」后的全新重跑——实际第 98 程未死，见本程专节）只做仓库根 `README.md` 的口径更新（见「README 口径更新（第 99 程）」专节）：可玩范围改为第 1–4 章、第 4 章并入「当前可玩范围」并删掉整个「已建成但未开放」节、五个结局全部可达且写明「判定只看战役结束（第四章末）」与 burned → abyss → restored → unfinished 优先级、测试数字改为单元 **13,551** / 十一套集成 **14,985**、开发状态末条改为第 1–4 章均已接入；保留仍然属实的「第 2–4 章捷径屏障无游戏内授予来源」，未虚构来源；另按仓库实况改正三处旧口径（第二至四章武器/遗物走完整内容库 12/9，不再是 demo 的 6/6；NPC 个人事件闸门是第 1 章交棒时置位的 `demo_cleared`，写「打通第一章」；第 4 章 9 个房间全部用剧场插画，写「全章背景」）。游戏代码/场景/资源/测试/配置、章节路由与可达性、存档形状、版本号、第 11–16 项均未碰。基线逐项复现：导入/退出 0；单元 13,551/0；十一套集成 1,475 / 109 / 677 / 207 / 113 / 73 / 458 / 45 / 2,331 / 4,364 / 5,133（合计 14,985）全 0 失败；退出 10/10；像素 40/0。下一步候选（监工排期）：① **GitHub 推送待用户推图后补推**——第 78 程的四张第 2 章敌人 PNG 是二进制，连接器快照推不了，须用户本人从他自己的 git 推上 `main`，之后监工再补推其余文本改动（网页版已更新到 `34bcdd7`）；② **最终验收程**（全新会话 AI 自主通关，按 `.supervisor/DECISIONS.md` 排期，排在推送补推之后）；③ 最终验收程之后的只读复查程启用一次 ultracode（用户 2026-11-07 18:35 拍板）。第 11–16 项仍开放、未施工；闻烬/白榆可见性、阿砚真名分支、关键道具物品化仍只记录缺口；第 60 程样图问题 1/3/5/6/7 维持原结论（与第 13/15 项相关的部分拍板前不施工）。本程未推送、未更新网页版、未创建 Release。
4. **待用户确认**：第 1–10 项已拍板；第 11 项（`ch2_shortcut` 获取来源）、第 12 项（电梯作者速度 70 px/s 的节奏取舍）、第 13 项（大区底部相机取景/HUD 遮挡）、第 14 项（第 3 章视野压缩机制口径）、第 15 项（第 3 章大图海面母题）、第 16 项（第 3 章 `ch3_shortcut` 来源）仍开放，在拍板前不施工、不猜测；第 40 程未新增待拍板项，第 41 程未新增待拍板项，第 42 程未新增待拍板项，第 43 程未新增待拍板项，第 44 程未新增待拍板项，第 45 程未新增待拍板项，第 46 程未新增待拍板项，第 47/48 程未新增待拍板项，第 49 程未新增待拍板项（舱口标题越界属第 37 程「边上标题内收」决定的实现缺口，已在同一表现层修复，不涉及待确认口径）。第 50 程只做第 4 章大地图可行性核查，未新增待拍板项；第 4 章特有的开放问题候选只记在专节，是否新增「待用户确认」条目由监工在验收时定。第 51 程只做第 4 章计划与图骨架，未新增待拍板项；第 50 程专节 E 的舞台母题/`ch4_shortcut` 来源/事件区/Boss 4 机制范围/战斗密度/`mask_enemy`/`seat_husk` 独立数值仍未拍板、未施工、未猜测，第 11–16 项也未碰。第 52 程只做第 4 章真实大区世界结构层，未新增待拍板项；第 50 程专节 E 的开放问题候选仍只记录、不编号，第 11–16 项也未碰。第 53 程只做第 4 章内容数据层第 1 步（`Ch4EventData`/权柄池/Boss 文案，计划仍不路由、世界仍不被 `game.gd` 引用、未做波次接线/事件触发/Boss 4 机制/可达性），未新增待拍板项；第 50 程专节 E 的舞台母题/`ch4_shortcut` 来源/事件区/Boss 4 机制范围/战斗密度/`mask_enemy`/`seat_husk` 独立数值仍只记录、未拍板、未施工，第 11–16 项也未碰。第 54 程只做第 4 章波次接线（计划 `wave` + `content_pending` 清零；计划仍不路由、世界仍不被 `game.gd` 引用、未做事件触发/Boss 4 机制/可达性），未新增待拍板项；第 50 程专节 E 的开放问题候选仍只记录、不编号，第 11–16 项也未碰。第 56 程只做第 4 章事件区真实自动触发验证（沿用第 34/44 程通用分支、测试层驱动；计划仍不路由、世界仍不被 `game.gd` 引用、未做 Boss 4 机制/`boss_scene`、第 4 章大图验收与可达性），未新增待拍板项；第 50 程专节 E 的开放问题候选仍只记录、不编号，第 11–16 项也未碰。第 57 程只做第 4 章 Boss 4 机制与 `boss_scene` 路由（计划指向既有 `smiling_archivist.tscn`、既有机制与数值由测试锁定；计划仍不路由、世界仍不被 `game.gd` 引用，未改章节路由/章末流程，未做机制扩展/第 4 章大图验收/可达性），未新增待拍板项；第 50 程专节 E 的开放问题候选（含 Boss 4 机制扩展范围）仍只记录、不编号，第 11–16 项也未碰。第 58 程只做第 4 章章末收口（章末流程与测试层；计划仍不路由、世界仍不被 `game.gd` 引用，未改可达性/章节路由/Boss 4 机制/数值/波次/事件/章末文本，未新编剧情、未新设选项），未新增待拍板项；第 50 程专节 E 的开放问题候选（含 Boss 4 机制扩展范围）仍只记录、不编号，第 11–16 项也未碰。第 59 程只做第 4 章大地图系统验收（只跑/补验收脚本并记录，未改产品代码；计划仍不路由、世界仍不被 `game.gd` 引用，未改可达性/章节路由/门视觉/地图标题/敌人美术/战斗密度/电梯速度/相机/HUD，未新增 `ch4_shortcut` 授予），未新增待拍板项；第 50 程专节 E 的开放问题候选（含 Boss 4 机制扩展范围、舞台母题呈现层、`ch4_shortcut` 来源、战斗密度、`mask_enemy`/`seat_husk` 独立数值）仍只记录、不编号，第 11–16 项也未碰。第 35 程的两个歧义（Boss 数值、第 2 章末界面/结局记录）已按采用口径记录并用测试锁定，不是开放项。第 66 程只做结局文本加厚（只新增余味文本数据与结束屏/画廊展示读取；未改 5 个 id/标题/现有正文/`ending_for` 判定/`Profile.endings` 记录与存档格式/画廊解锁规则，未改可达性），未新增待拍板项；第 11–16 项仍未碰、未施工。第 68 程只做例行扫描与 1 项 Hub 档案馆满级提示修复（未改上限数值/价格曲线/存档格式/成长设计/可达性），未新增待拍板项；第 11–16 项仍未碰、未施工。第 69 程只做例行扫描与 2 项（3 处）Hub 文案改正（陆沉档案馆开启语按 demo 上限常量生成、闻烬契约/情报描述改为实际发放；未改数值/存档/上限/成长设计/可达性），未新增待拍板项；第 11–16 项仍未碰、未施工。第 70 程只做例行扫描与 5 项（8 处）文案/常量修正（局内商店缝合书页数值、档案馆满级提示、神铸祝福按实得报数、咕噜货架描述补遗物、零污染遗物卡去掉「污染 +0」；未改数值/存档/上限/成长设计/可达性），未新增待拍板项；第 11–16 项仍未碰、未施工。第 71 程开局即因 Magpie 网关中断夭折（零产出、无提交、无待拍板项）；第 72 程只做例行扫描与 1 项 Hub 阿砚问候扣碎片修复（问候改为非交易性说明并指向「言灵对话 → 锻造基底」；未改锻造数值/折扣/信任/存档/可达性），未新增待拍板项；第 11–16 项仍未碰、未施工。第 73 程只做例行扫描与 2 项产品行为缺陷修复（Hub 词服务无限碎片泵、局内商店对已拥有缓存货扣残页不发货；未改数值/存档/上限/可达性），未新增待拍板项；第 11–16 项仍未碰、未施工。第 74 程只重写 `README.md`（未改游戏代码/场景/资源/测试、未改章节可达性、未推送/未更新网页版/未创建 Release），未新增待拍板项；第 11–16 项仍未碰、未施工。第 79 程（brief83，第 3 章可达性接线）在启动时因 `[claude-code:unrecognized_model]` 死亡（零产出、无提交）；第 80 程（brief84）为接力全新重跑，只做第 3 章可达性接线第 1 步（`CHAPTER_PLAN_PATHS[2]`/`MDS_WORLD_FILES[2]`/`MDS_CHAPTER_SCENES[2]` 与 `_complete_chapter` 的 `_chapter == 1` 分支），未新增待拍板项；第 11–16 项仍未碰、未施工。后续若出现需要用户拍板的新问题，只记入「待用户确认」。第 81 程只更新仓库根 `README.md` 的口径（未改游戏代码/场景/资源/测试/配置、未改章节路由与可达性），未新增待拍板项；第 11–16 项仍未碰、未施工。第 86 程只做例行扫描与两处延时必选页产品行为修复（未改内容/数值/存档形状/章节路由与可达性），未新增待拍板项；第 11–16 项仍未碰、未施工。第 87 程只写完任务 0 基线即中断（零扫描产出、无提交、无待拍板项）；第 88 程为全新重跑，只做例行扫描与 1 项奖励页等待修复（`_open_reward()` 等待页面/过场 + `_reward_pending` 挡档；未改奖励内容/数值/存档形状/章节路由与可达性），未新增待拍板项；第 11–16 项仍未碰、未施工。第 89/90 程（brief93/94）启动即死（零产出、无提交、未做扫描、无结论、无待拍板项）。第 91 程（brief95）按 `.supervisor/DECISIONS.md` 2026-11-07 09:45 的监工拍板只做第 4 章可达性接线第 1 步（四个路由点 + `_complete_chapter` 的第 3 章交棒分支；未改第 4 章计划/波次/事件/Boss 4 数值与机制、未改第 1/2/3 章内容、未改存档形状、未新增 `ch4_shortcut` 授予、未动舞台母题/机制扩展/战斗密度/电梯/相机/HUD），未新增待拍板项；第 11–16 项仍未碰、未施工。
5. **很久以后的发行阶段事项，现阶段不做**：Windows 实机验证、安装器编译/安装卸载实测、真实代码签名证书、1080p 实机截图。第 3 程的安装器脚本与签名文档原地保留，不扩展、不删除、不做编译验证。
6. 后续内容方向按 DECISIONS.md：T17（吞噬/归档权柄、信任分层、结局画廊）已完成；Boss 2 已完成（第 35 程），Boss 3 的独特机制与计划 `boss_scene` 路由已完成（第 45 程；数值为暂定口径），第 3 章章末收口已完成（第 46 程），第 3 章仍未接入 `game.gd`；Boss 4 的 `boss_scene` 路由与既有机制锁定已完成（第 57 程：计划指向 `smiling_archivist.tscn`，镜面弹幕/纸页波/墨雨/改写与数值由 `test_ch4_boss` + 可玩性集成锁定；入场/阶段文案第 53 程已编写；机制扩展仍待第 50 程专节 E 拍板）；第 4 章章末收口已完成（第 58 程：显式 `_chapter == 3` → `_finish(true)` 结束战役，Boss 4 → 权柄 → 第 4 章 outro → 章末选择 → 战役结束；机制扩展仍未做，第 4 章大图验收已完成（第 59 程：`tests/integration_ch4_bigmap.gd` 4869 断言 0 失败、连续两次，覆盖连通/门/边界/纵向/过渡/一次性/多遭遇/捷径/Boss/续玩/性能/叙事 + 第 4 章专属表现；未发现产品缺陷、未改产品代码；计划仍未接入 `game.gd`、第 4 章仍不可达））；第 4 章已于第 91 程接入主流程，第 1–4 章全部可达；封闭试玩与安卓/触屏不排期。

7. 第 60 程完成第 2–4 章样图截图（只截图，见「样图截图（第 60 程）」专节）：新增 `tests/capture_bigmap_chapters.gd`（xvfb + OpenGL 离屏渲染；真实主场景 + 临时挂载计划/大区世界），产出 9 张 1280×720 PNG 存 `artifacts/screens/ch2|ch3|ch4/`（不提交）：`ch2_entry_panorama` / `ch2_well_shaft` / `ch2_boss_lung_bell`、`ch3_entry_panorama` / `ch3_well_shaft` / `ch3_boss_last_reader`、`ch4_entry_theater` / `ch4_well_backstage` / `ch4_boss_smiling_archivist`。9 张全部通过尺寸/非空/非黑非白核验；基线不变（单元 12657/0、十一套集成 894/102/613/207/113/59/391/45/2209/4235/4869 全 0 失败）。产品代码/场景/资源零改动，`CHAPTER_PLAN_PATHS` / `MDS_WORLD_FILES` / 章节路由/可达性未动，第 2/3/4 章仍不可达；截图发现的问题（底部 HUD 遮挡、背景纵向接缝、`boss_background` 被静态背景遮挡、入口休整文案、电梯贴边、Boss 脚部被 HUD 压住、第 2 章入口背景色调）只记录、本程未修，待确认第 11–16 项未碰、未新增条目。下一程仍由监工定排期：第 2 章可达性/演出、第 3 章可达性（不能早于第 2 章）、第 4 章可达性须单独拍板；第 11–16 项拍板前不施工。

8. **㊶ 第 101 程（例行扫描 + 三处修复）**：先收尾第 100 程中断留下的 revive 存档修复
   （`world.relic_revive_used`，提交 `93bb2b8`），再跑完整基线（单元 13,559 / 集成 15,003 /
   退出 10/10 / 像素 40-0），然后六面扫描。本程共 4 个提交：`93bb2b8` 存档修复、
   `fb41db8` 暂停确认取消后仍武装（取消「返回档案馆」再确认「重新开始」会同时执行两个
   动作，玩家被送回 Hub 且本局作废——第 73 程记「当前不可见」，实测可见）、
   `55231c7` 死亡横幅把遗物叫成「不灭档案」（资源名与背包/奖励/货架/GDD 都是「不朽档案」）、
   `e988541` 档案馆页关页不还焦点（Hub 轮询按键，当前玩家不可见，按一致性补齐）。
   收尾基线：单元 **13,575 / 0**、十一套集成 **15,009**
   （1,475 / 109 / 695 / 212 / 113 / 73 / 459 / 45 / 2,331 / 4,364 / 5,133）全 0 失败、
   退出 10/10、像素 40/0。**下一步候选**：① GitHub 文本补推由监工执行——四张第 2 章敌人
   PNG 已由用户经网页端推上 `main`（远程 `90a1960`，父提交 `39c2b89`），推送不再被二进制
   挡住，只等树干净、测试全绿、无会话在跑时补推文本改动并更新网页版；② 最终验收程（全新
   会话 AI 自主通关）按 DECISIONS 排在推送补推之后，模型档位仍用 Flash；③ 第 11–16 项
   （`ch2_shortcut`/`ch3_shortcut`/`ch4_shortcut` 来源、电梯节奏、大区底部相机/HUD 遮挡、
   第 3 章视野压缩、海面母题）仍开放，拍板前不施工；④ 闻烬/白榆可见性与个人事件、阿砚
   「叫出真名」完整分支、关键道具物品化仍只记录缺口。

### 2026-11-03 · 第 1 程

- 阅读 CLAUDE.md / HANDOFF.md / README.md / ASSETS.md / GDD 相关章节 / Chapter 1 demo 实施计划 / 记忆索引。
- 解压本机 Godot 4.7.stable（`~/workspace/tools/godot/bin/`），完成 `--headless --import`。
- 基线验证：单元 3413 绿、结构集成 267 绿、输入集成 11 绿。
- 建立 `supervisor-dev` 本地分支；写本状态文件并提交。
- 实现 T16 局内 run save/resume：
  - 新增 `scripts/core/run_save.gd`：原子写 + `.bak` 恢复、版本/结构校验、坏档自动删除、词/短语完整序列化（含野生词与 AI 合成结果）。
  - `game.gd`：进房、奖励选择、事件、商店买卖/关闭、残碑、宝箱、Boss 死亡、权柄选择、暂停、失焦、窗口关闭时保存；死亡/通关/返回 Hub/重开时清除。
  - 标题新增「继续本局」入口；`GameFlow` 增加 `run_save_path` / `resume_requested` / 窗口关闭先保存再退出。
  - 续玩恢复：章节/房间/位置、生命/墨量/污染/残页、击杀/仁慈/记录、词/武器/遗物/两条短语/权柄使用状态、已清房间/书库/残碑/宝箱/商店库存/发狂计时；Boss 已死时直接续接权柄/章末流程，避免重复刷 Boss。
  - 新增 `tests/test_run_save.gd`（36 项）与 `tests/integration_run_save.gd`（27 项），全部通过。
  - 回归：单元 3449 passed / 0 failed；结构集成 267 / 0；输入集成 11 / 0；主场景 headless 启动无脚本错误（仅剩已知音频退出泄漏）。
- 实现 T15 手柄 + 焦点导航：
  - `GameFlow`：新增 `DEFAULT_JOYPAD_BUTTONS` / `JOYPAD_AXES`，默认布局为左摇杆移动、A 跳、X 攻击、B 翻滚、Y 交互/言灵、LB/RB 换武器、LT/RT 短语、十字键打开造句/背包/地图/说明、Start 暂停、Back 设置；启动时安装、可被 Profile 覆盖。
  - 键盘重绑仅替换 `InputEventKey`，手柄重绑仅替换 `InputEventJoypadButton`，互不覆盖；方向键与 Esc 作为移动/暂停的第二键保留。
  - `Profile` 新增 `joybinds` 持久化（v2 向后兼容，缺省为空）。
  - `KeybindUI` 支持手柄按键捕获、显示键盘/手柄双标签、Back 取消、打开即抓焦点；捕获期间 `Flow.input_capture_active` 阻止游戏/Hub 误响应。
  - 暂停菜单新增「设置」按钮与 `settings_requested` 信号；设置页、键位页打开即抓焦点；游戏内 `ui_cancel` 可关闭覆盖页，暂停时手柄方向键只做焦点导航。
  - 设备感知提示：HUD 控制条/武器槽随最后输入设备切换；帮助、对话、剧情、地图、教程、Hub、残碑、房门、结束屏等提示读取 `Flow.prompt_label()`。
  - 新增 `tests/test_gamepad.gd`（43 项）与 `tests/integration_gamepad.gd`（34 项），覆盖映射、轴、重绑互不覆盖、Profile 持久化、真实摇杆移动/跳跃、Start 暂停/恢复、暂停焦点、设置入口、键位页焦点。
  - 回归：单元 3492 passed / 0 failed；结构集成 267 / 0；输入集成 11 / 0；run save 集成 27 / 0；`--headless --import` 通过。
