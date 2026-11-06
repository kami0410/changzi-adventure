# 第 2–4 章样图截图（第 60 程，只截图）

> 日期：2026-11-06 · 分支 `supervisor-dev` · 对应状态文件「样图截图（第 60 程）」专节
> 范围：按监工 2026-11-06 决定（`.supervisor/DECISIONS.md`「样图截图」）给第 2、3、4 章各产出 3 张代表性画面，1280×720。只截图、只记录；不改任何游戏内容、不开放可达性、不修截图里发现的问题。

## 结论

- 新增 `tests/capture_bigmap_chapters.gd`（xvfb + OpenGL 离屏渲染；真实主场景 + 临时挂载对应章节计划与大区世界，与 `integration_ch2/3/4_bigmap.gd` 的验收挂载方式一致）。
- 产出 9 张 PNG，存 `artifacts/screens/ch2/`、`artifacts/screens/ch3/`、`artifacts/screens/ch4/`（`artifacts/` 已在 `.gitignore`，PNG 不提交）。
- 9 张全部通过尺寸/非空/非黑非白核验：`1280×720`、像素均值 28.5–46.5、暗像素（亮度 < 4）≤ 1.3%、白像素（> 250）0%。
- 产品代码（`scripts/`、`scenes/`、`resources/`）零改动；`CHAPTER_PLAN_PATHS[2]/[3]` 仍空、`MDS_WORLD_FILES[2]/[3]` 仍指旧世界、第 2/3/4 章仍不可达。
- 截图里发现的问题只记录在本文与状态文件，本程不修。

## 方法

- **渲染**：`xvfb-run -a godot --path . --resolution 1280x720 --rendering-driver opengl3 --audio-driver Dummy -s tests/capture_bigmap_chapters.gd -- --out-dir=res://artifacts/screens`。纯 `--headless` 是 dummy 渲染器，截不到图；沿用 `tests/capture_authority_ending.gd` 的离屏渲染先例。
- **挂载**：第 2–4 章仍不可达，计划也未接入 `game.gd`。截图脚本实例化真实 `scenes/main.tscn`，等第 1 章世界加载后，用验收测试同样的手法临时挂上对应章节的 `ChapterPlanData` + `chapter_N_bigmap_world.tscn`，拍完不写回任何产品默认值（`CHAPTER_PLAN_PATHS` / `MDS_WORLD_FILES` / 章节路由均未动）。
- **取景**：只做三件事——把玩家放到作者地面/平台上的取景点、`Camera2D.reset_smoothing()`、必要时等电梯升到画面内；没有改数值、没有加作弊开关、没有改游戏逻辑。Boss 房间由真实 `_on_mds_room_loaded` 生成 Boss，玩家进入 `Arena` 触发范围后由真实 `_update_room_locks()` 触发入场，等 2.6 秒拍战斗中的一帧。
- **截图脚本随本程提交**；PNG 留在 `artifacts/screens/`，按约定不提交。

## 文件清单与取景

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

## 核验结果

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

## 截图中发现的问题（只记录，本程不修）

1. **底部 HUD 遮挡（对应待确认第 13 项）**：所有 9 张的底部武器卡/控制条都盖住画面最下方约 80 px。Boss 三张里 Boss 与玩家的脚部被武器卡压住；入口三张里底部舱口的「前往 <区名>」标题也被武器卡盖住一部分。玩家在 Boss 取景中的屏幕 y≈612，脚正好落在卡片上缘。第 13 项原本记录的是第 2 章底部取景/HUD 遮挡，本程确认同样影响第 3、4 章。
2. **背景纵向平铺接缝**：大区背景图是 1536×864 的静态图，按房间高度纵向平铺。1440 高的入口区在屏幕 y≈144 有一条较浅的接缝；2160 高的纵井/Boss 区接缝更明显——尤其 `ch4_boss` 顶部约 290 px 是 `smiling_theater.png` 底部的黑色舞台地面，下一条瓦片从吊灯顶部重新开始，形成一条硬接缝；`ch2_boss`/`ch3_boss` 顶部同样能看到「上一条瓦片底部 + 下一条瓦片顶部」的拼接线。不是本程改动。
3. **`boss_background` 被静态背景挡住**：世界 JSON 的 `areas[...].boss_background` 已写 `spore_drift`（第 2 章）、`deep_water`（第 3 章）、`blood_moon`（第 4 章），但 `MDSBigRoom` 的静态背景 `z_index = -20` 在 MDS 动画背景 `z_index = -110` 之前，铺满房间的静态图把动画 Boss 背景完全遮住。三张 Boss 图里看不到 `deep_water`/`blood_moon` 的动画层；第 3 章的「海面」来自 `lightless_sea.png` 静态图，而不是 `deep_water`。与待确认第 15 项（第 3 章海面母题）相关，但范围更大（三章 Boss 背景都受影响），本程只记录。
4. **入口/枢纽区套用休整文案**：`ch2_entry`/`ch3_entry`/`ch4_entry` 这类没有 `Arena` 的大图房间会走「非书库 → 休整」分支，显示 `RestRoomData` 的一条通用文案并把目标设为「休整，或继续前进」。截图里分别是「墨迹未干的名字在墙角晾着。」「纸人把灯芯拨亮，等你开口。」「屋檐滴水，挑上的旧货都醒着。」；第 3 章入口出现「纸人」字样，读起来更像第 4 章剧场/档案馆的意象。属于内容路由观察，本程不改。
5. **电梯贴房间左缘**：纵井的电梯作者位置在房间 x=0..160，相机又被房间左边界夹住，所以纵井三张里电梯只以画面最左侧一条横线出现（能看出是电梯，但不醒目）。这是作者布局 + 相机夹取的取景限制，不是缺陷。
6. **Boss 取景**：Boss 生成在 `Arena` 局部 (110,-18)，玩家放在右侧平台后 Boss 从画面左中向玩家走来；2.6 秒那一帧能同时看到 Boss、玩家、Boss 血条和入场句，但 Boss 脚部仍在底部 HUD 后面（同第 1 条）。第 2 章那张 Boss 正好在攻击预警中，弹道可见；第 3、4 章 Boss 也各自带自身血条/预警。
7. **第 2 章入口背景与第 1 章色调接近**：`breathing_ruins.png` 是红月废墟，和第 1 章档案馆的既有背景色调相近；这是既有素材，不是本程改动，仅记录给监工判断样图代表性时参考。

## 本程未做

- 未改任何 `scripts/`、`scenes/`、`resources/` 产品代码/场景/数据；未开放第 2/3/4 章可达性；未把章节计划接入 `game.gd`；未改 `CHAPTER_PLAN_PATHS` / `MDS_WORLD_FILES` / 章节路由。
- 未修截图里发现的问题（HUD 遮挡、背景接缝、Boss 背景遮挡、入口休整文案、电梯贴边、Boss 取景）——只记录。
- 未做第 4 章门视觉专项、第 4 章地图标题改动、第 4 章敌人美术核查/接线、Boss 4 机制扩展、舞台母题呈现层、`ch4_shortcut` 授予、战斗密度、`mask_enemy`/`seat_husk` 独立数值、阿砚同行。
- 未碰待确认第 11–16 项（捷径来源、电梯节奏、相机/HUD、第 3 章视野压缩/海面母题/捷径来源）；第 50 程专节 E 的开放问题只记录现状，未编号、未拍板、未施工。
- 未新增移动能力、未改 NPC 立绘、未改 MDS 插件本体、未新绘/拼凑任何敌人/场景美术。
- 未做打包导出、安装器、代码签名、提交上架、安卓/触屏。

## 提交

- `4cc62fa` `test: capture chapter 2-4 sample frames`：`tests/capture_bigmap_chapters.gd` + `tests/capture_bigmap_chapters.gd.uid`（2 文件）。
- 状态文件 `SUPERVISOR_STATUS.md` 新增「样图截图（第 60 程）」专节与本程日志、更新「未完成」第 10 项与「下一程」；`docs/memory/MEMORY.md` 补索引；本文为 session 记录（文档随本程收尾提交）。
- 截图 PNG 存 `artifacts/screens/ch2|ch3|ch4/`，按约定不提交（`artifacts/` 已被 `.gitignore` 忽略）。
