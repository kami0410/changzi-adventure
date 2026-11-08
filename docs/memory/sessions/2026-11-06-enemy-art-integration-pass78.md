# 第 78 程 · 第 2 章四敌缺美术接入（brief82）

> 目标：把监工提供的四张第 2 章敌人原图处理成 demo 像素规范，接入
> `ENEMY_ART`，清空第 2 章最后的美术回退缺口。只做去背/裁切/像素化/调色板
> 对齐，不新绘、不拼凑；不改 NPC 立绘、背景图、第 4 章美术与任何数值/存档/
> 可达性。第 3/4 章仍不可达，`ch2_shortcut` 仍无授予。

## 原图与验收口径

- `.supervisor/art-inbox/breath_hound.jpg`：1320×660 白底，浅色毛边贴白底，
  去背时需保留被白毛包围的封闭区域。
- `.supervisor/art-inbox/lung_moth+rust_whisperer+collapse_husk.jpg`：1320×445
  三联图，左→右 = lung_moth / rust_whisperer / collapse_husk，先按单体育裁切。
- 监工口径：后三张比 breath_hound 更细、更偏绘画；须统一像素颗粒度并与
  breath_hound 及既有敌人调色板对齐；不得直接使用原图。
- 两份原图全程只读，未删除/覆盖（`.supervisor/art-inbox/` 时间戳保持
  10:35 / 10:39）。

## 处理经过（不入库的临时脚本）

- 去背：从图像四边泛洪填充近白像素（`dist = 255 - min(RGB)`，容差 18），
  而不是全局阈值——浅色毛边与封闭白区因此不会被误删。处理完检查 0 个
  不透明近白（>235）像素。
- 单体裁切：三联图按 (20,0,540,H)、(555,0,910,H)、(930,0,1270,H) 裁出三体。
- 统一像素化：LANCZOS 缩放到 94 px 画布内适配（左右各留 1 px 透明边），
  中位切分量化 24 色 + 1 个 `#101820` 描边色 = **25 色**（既有敌人 24–28），
  无抖动、丢弃碎色簇，最后加 1 px 描边、底边对齐放入 96×96。
- 调色板对齐：HSV 去饱和/压明度（breath_hound 1.0/0.92、lung_moth 1.0/0.94、
  rust_whisperer 0.9/0.90、collapse_husk 0.85/0.90），保留猎犬的绿色吐息与
  蛾的暗红翅脉，同时压进游戏的低饱和墨灰基调。
- 产物（均 96×96、25 色、alpha 0/255、四角透明、最底行不透明、1 px 边距）：

  | 文件 | 不透明包围盒 | 颜色 |
  | --- | --- | --- |
  | `breath_hound.png` | (1,44)–(94,95) 92×50 | 25 |
  | `lung_moth.png` | (1,23)–(94,95) 92×71 | 25 |
  | `rust_whisperer.png` | (14,6)–(80,95) 67×88 | 25 |
  | `collapse_husk.png` | (13,6)–(81,95) 69×88 | 25 |

- `.import` 沿用敌人贴图口径：`compress/mode=0`、`mipmaps/generate=false`。

## 接入经过

- `scripts/game.gd`：四个 id 加入 `ENEMY_ART`（preload 各自 PNG）；
  `ENEMY_ART_FALLBACK` 置空（保留表与 `ENEMY_FALLBACK_TINT`，供未来无美术敌人
  显式回退）。`_spawn_group()` 未改：空表使四敌自然走 `Color.WHITE`。
- 第 2 章 `ROOM_WAVES[1]` 五敌现已全部专属美术；第 3 章复用的
  `rust_whisperer`/`lung_moth`/`collapse_husk` 同步由回退转为专属 + 白 tint。
  第 1/4 章美术、`ENEMY_SCENES`、`PixelSprite` 落地逻辑均未动。

## 验收

- 单元 `tests/run_tests.gd`：**13,549 / 0**（13,490 → +59；`test_enemy_art`
  298 → 357）。
- 十一套集成逐套件：playability **913**、ch1 demo **109**、run save **624**、
  gamepad **207**、ui prompts **113**、ch1 event **59**、menus **456**、
  ai settings **45**、ch2 bigmap **2,330**（2,315 → +15）、ch3 bigmap
  **4,362**（4,358 → +4）、ch4 bigmap **5,133**，全 0 失败。
- `python tests/check_pixel_assets.py --demo`：**40 assets / 0 failure**
  （36 → 40，四张新图入 demo 集合）。
- `--headless --import` 与 `--quit`：exit 0、0 `ERROR`；
  `bash tests/check_exit_clean.sh 10`：**10/10 clean**。
- 运行时探针确认四敌在真实大图遭遇中 `sprite_visual.texture` 指向各自 PNG、
  `modulate = (1,1,1,1)`、整数缩放；探针与临时处理脚本测后删除。

## 提交

- `c2d1569` feat: give the four chapter 2 enemies their own paintings
  （四张 PNG + `.import` + `game.gd` 接线）
- `b67d1ea` test: lock the four new enemy sprites in the art audits
  （`test_enemy_art`、第 2/3 章大图集成、`check_pixel_assets.py`）
- docs 提交见 `git log`（本文件 + `SUPERVISOR_STATUS.md` + `MEMORY.md`）。

## 未改项

- 未推送、未更新网页版、未创建 Release；未新绘/拼凑任何美术；NPC 立绘、
  背景图、第 4 章美术未动。
- 第 2 章数值/波次/事件/Boss 2、第 1/3/4 章内容、存档格式、章节路由与
  可达性未动；`ch2_shortcut` 仍无授予；电梯/相机/HUD 未动；第 11–16 项未碰。
