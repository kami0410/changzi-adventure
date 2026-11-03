# 像素资产生产进度（2026-11-02）

## 0.10.0 玩家逐帧动作

- 新增 16 帧玩家动作：跑步 4 帧（112×96 画布）、跳跃/下落 3 帧、近战 3 帧（160×96 画布，容纳短剑）、施法 2 帧、受击/踉跄 2 帧、闪避 2 帧；源图在 `assets/concept/anim/`，成品在 `assets/sprites/player/frames/`。
- 管线：Magpie 透明底生成多帧横条 → `tools/slice_anim_sheet.py` 按 alpha 间隙切片 → 同一缩放（按高度统一）、同一调色板（24 色）、1 px 墨色描边、脚底基线。跑步 12 fps，攻击/施法/闪避按动作进度切帧。
- `ActorMotion` 现在按每帧不透明区域重新锚定脚底与水平中心，影子宽度固定为 idle 纹理宽度，避免挥剑时影子被拉宽；残影按纹理单独计算脚底偏移并按朝向翻转。
- 已知瑕疵：生成帧的衣摆与剑刃边缘仍有少量抗锯齿噪点；受击/倒地只用两帧，正式发行前可补中间帧或手工修边。仍需在 Android 实机确认 120 FPS 下的可读性。

## 0.7.0 敌人与 NPC 补充

- 新增 4 张敌人 96×96：墨囊投手、合唱召引者、镜面狙手、残页群；新增 2 张 NPC 96×96：闻烬、白榆。
- 新敌人用 Magpie 生成、`rembg u2net`/黑底阈值抠图、Pillow 缩放与 alpha 检查；源图在 `assets/concept/enemies/`，模型在 `tools/models/rembg/u2net/`（不提交）。
- 已知瑕疵：部分生成图边缘仍有轻微背景残留，正式发行前需要手工修边；NPC 立绘来自内部参考图的风格化裁切，对外发布前确认肖像授权。
- `ActorMotion` 升级为程序化骨骼动画（头/躯干/双腿、弹簧压缩、尾/翼二次运动）；`CombatFX`/`SpellVFX` 重做。仍不是独立逐帧图集。

## 0.5.0 第四章舞台

- 第四章「笑面剧场」目前使用程序化舞台：`TheaterBackdrop` 绘制红帷幕、包厢、观众席、纸人、聚光灯、断吊灯、脚灯，底图用档案馆纹理调红。
- **没有生成新的专属插画**：Magpie 图像额度到 15:39 UTC+8 才恢复，本轮未生成。额度恢复后应补：剧场背景 1536×864、最后的读者 256×256、剧场敌人 2 张 96×96，并替换 `theater_backdrop` 的临时绘制。
- 最后的读者暂时复用 `echo_enemy.png` 放大 2.2 倍并调青绿；这是可玩的变体，不是最终立绘。

## 0.4.0 动作与音频补充

- 动作层：翻滚 4 段残影、施法残影与 cast 姿态、相机前瞻、ScreenFX 命中/阶段闪屏、Boss 登场 letterbox、近战命中顿帧。仍不是独立手绘逐帧图集。
- 音频：`assets/audio/music/` 五首 OGG 循环；`assets/audio/voice/zh_cn/` 18 段中文旁白；生成脚本在 `tools/`。详见 `docs/audio/README.md`。
- 配音为 SAPI Huihui 原型，正式商用需替换；不要把它当作最终配音资产。

## 0.3.0 品牌与第三章资产

- `assets/branding/icon_512.png`（512×512）及多尺寸 PNG/ICO：破碎书页 + 青色史官之眼 + 朱红封印；已接入项目图标、Windows ICO、Android 192/432 启动图标。
- `assets/backgrounds/lightless_sea.png`（1536×864）：无光海夜海、断钟、漂流档案与月食；第三章背景。
- `assets/sprites/bosses/smiling_archivist.png`（256×256，透明）：笑面史官全身像，底边对齐；第三章最终 Boss。
- 生成源保留在 `assets/concept/branding/`、`assets/concept/environments/`、`assets/concept/characters/`；规范化脚本为 `tools/normalize_brand_assets.py`。
- 生成工具：Magpie MCP `codex/gpt-image-2`；规范化 Pillow。图标与笑面史官已按游戏尺寸目视检查；无光海已在实际游戏画面中检查。
- 词库扩到 36 个；新增词仍使用项目统一 glyph + 词性 + 标签 + 组件的资源格式，没有引入新的素材许可。

## 0.2.0 引擎接入更新

2026-11-01 已加入 `ActorMotion` 分层程序动作（腿部交替、待机、跳落地、翻滚、攻击、受击、死亡），`CombatFX` 战斗反馈，流动墨门与 `LivingBackdrop` 远景视差/中景/纸页/尘埃/薄雾。角色比例与碰撞已重新匹配，地面移至屏幕 y=560 为 HUD 留出空间；主角约 110 像素高。

已实际渲染检查 Hub、战斗、清房奖励、背包、造句与 Boss；1280×720 为主分辨率，造句界面额外验证 960×540、1600×900、1600×720。原 PNG 仍为单帧素材，不应把程序动作记为独立手绘逐帧图集。下文是最初静态资产生产的历史记录。

## 范围与结论

- 目标：为 M1 垂直切片交付可替换几何占位的**静态**像素资产：主角、Boss、6 个敌人、3 个 Hub NPC、6 个武器图标、2 张背景。
- 本次**不包含**逐帧动画、`SpriteFrames`、VFX 或代码/场景接入；主线程负责把静态 sprite 接到 `Sprite2D` / `SpriteFrames`。
- 共 19 张图，全部通过尺寸与 alpha 技术检查，并逐张目视检查；无空图、无严重跑偏。
- 生成工具：Magpie MCP（`mcp__magpie-image__generate_image`），模型 `codex/gpt-image-2`。
- 规范化：Pillow 12.3.0；LANCZOS 缩放、按 alpha 裁边、自适应调色板量化、角色底边中心对齐、图标居中、背景 cover 裁切。
- 来源与许可：项目内部生成资产，无第三方图库素材；NPC 的真人参考仅用于内部风格化设计，对外发布前需确认肖像使用授权。

## 技术规格

| 类别 | 尺寸 | 画布/锚点 | alpha |
|---|---|---|---|
| 主角 idle | 96×96 | 脚底中心 | RGBA，透明背景 |
| 敌人 ×6 | 96×96 | 脚底中心（飞行单位建议场景内加悬浮偏移） | RGBA，透明背景 |
| Boss 墨骸史官 | 256×256 | 脚底中心 | RGBA，透明背景 |
| NPC ×3 | 96×96 | 脚底中心 | RGBA，透明背景 |
| 武器图标 ×6 | 64×64 | 居中，内容区 56×56 | RGBA，透明背景 |
| 背景 ×2 | 1536×864 | 全画幅 | RGB，不透明 |

- 调色：午夜蓝、病态青、骨白、干血红、黑墨；咕噜保留概念图中的赭黄作为有意例外。
- 视角：角色统一 3/4 侧视、面朝右、完整身体；Boss 为 3/4 侧视全身。
- 轮廓光：统一从右上来的青色冷光；缩到游戏尺寸后以剪影和大色块为主要识别点。
- 建议 Godot 导入：Filter `Nearest`、关闭 Mipmaps、保持原始尺寸；角色 pivot 脚底中心。

## 资产清单与逐张记录

> 所有图片均由 Magpie / `codex/gpt-image-2` 生成；日期为生成日（2026-10-31 或 2026-11-01）。
> “参考”为生成时输入的源参考；许可/用途均为“项目内部生成资产，无第三方素材，M1 静态占位替换用”。

| 文件 | 用途 | 尺寸 | prompt 摘要 | 源参考 | 日期 | 模型 | 许可/用途 |
|---|---|---|---|---|---|---|---|
| `assets/sprites/player/player_idle.png` | 主角昌子 idle 静态 sprite | 96x96 | 3/4 侧视全身：黑色高领长衣与干血红内衬、圆眼镜、手持发青光的打开书册；厚像素、大色块、右上青色轮廓光、透明背景。 | `assets/concept/style-tests/changzi_pixel.png` | 2026-10-31 | gpt-image-2 | 内部生成，无第三方素材 |
| `assets/sprites/bosses/ink_archivist.png` | Boss 墨骸史官静态 sprite | 256x256 | 3/4 侧视全身：黑墨与骨白构成的枯瘦史官，书脊王冠、单眼骨面具、巨型羽毛笔手臂、锁链巨册、破损长袍；256 剪影有压迫感。 | `assets/sprites/player/player_idle.png`<br>`assets/concept/style-tests/changzi_pixel.png` | 2026-10-31 | gpt-image-2 | 内部生成，无第三方素材 |
| `assets/sprites/enemies/ink_hound.png` | 普通敌人 墨犬 | 96x96 | 3/4 侧视四足墨犬：书脊状脊骨、纸耳、双青色眼光、笔尖爪、滴墨长舌；低伏冲锋姿态。 | `assets/sprites/player/player_idle.png` | 2026-10-31 | gpt-image-2 | 内部生成，无第三方素材 |
| `assets/sprites/enemies/scribe_bug.png` | 远程敌人 抄写虫 | 96x96 | 3/4 侧视甲虫：墨水罐腹部、羽毛笔腿、纸翼、单只大青眼、卷轴口器。 | `assets/sprites/player/player_idle.png` | 2026-10-31 | gpt-image-2 | 内部生成，无第三方素材 |
| `assets/sprites/enemies/blank_man.png` | 冲锋敌人 空白人 | 96x96 | 3/4 侧视无面人：骨白纸西装、头部撕裂空洞、过长手臂与多指、前倾冲锋。 | `assets/sprites/player/player_idle.png` | 2026-11-01 | gpt-image-2 | 内部生成，无第三方素材 |
| `assets/sprites/enemies/hanging_scribe.png` | 飞行敌人 悬吊书吏 | 96x96 | 3/4 侧视飞行敌人：红链悬吊的无腿书吏、骨面具、青色提灯、羽毛笔手指、飘散纸页。 | `assets/sprites/player/player_idle.png` | 2026-11-01 | gpt-image-2 | 内部生成，无第三方素材 |
| `assets/sprites/enemies/echo_enemy.png` | 精英敌人 失忆回声 | 96x96 | 3/4 侧视悬浮回声体：玩家轮廓、碎裂镜面头、青色裂纹、重影手臂、体内纸页与墨片。 | `assets/sprites/player/player_idle.png` | 2026-11-01 | gpt-image-2 | 内部生成，无第三方素材 |
| `assets/sprites/enemies/typo_beast.png` | 精英敌人 错字兽 | 96x96 | 3/4 侧视巨兽：骨白畸形字符堆叠成体、多只青眼、纸牙、墨触须、爪状前肢。 | `assets/sprites/player/player_idle.png` | 2026-11-01 | gpt-image-2 | 内部生成，无第三方素材 |
| `assets/backgrounds/ink_archive.png` | 背景 墨雨档案馆 | 1536x864 | 横版侧视废墟哥特档案馆内景：无尽书架、漂浮书页、青色月光彩窗、红色长幡、积水地面、远处日食；中景留空。 | 无（纯文本 prompt） | 2026-11-01 | gpt-image-2 | 内部生成，无第三方素材 |
| `assets/backgrounds/breathing_ruins.png` | 背景 呼吸废墟 | 1536x864 | 横版侧视外部废墟档案城：断裂柱廊、有机呼吸墙体、墨触须、骨白雕像与碎柱、青色地雾、干血红日食。 | 无（纯文本 prompt） | 2026-11-01 | gpt-image-2 | 内部生成，无第三方素材 |
| `assets/sprites/npcs/luchen.png` | Hub NPC 陆沉 | 96x96 | 3/4 侧视全身：年长瘦削档案教授、圆眼镜、灰黑后梳发、深蓝学者长衣、红色文件夹、疲惫威严。 | `assets/concept/characters/luchen_pixel.png`<br>`assets/sprites/player/player_idle.png` | 2026-11-01 | gpt-image-2 | 内部生成，无第三方素材 |
| `assets/sprites/npcs/ayan.png` | Hub NPC 阿砚 | 96x96 | 3/4 侧视全身：年轻冷峻守夜人、短刺发、深色制服与破损长衣、腰间钥匙、青色提灯长矛。 | `assets/concept/characters/ayan_pixel.png`<br>`assets/sprites/player/player_idle.png` | 2026-11-01 | gpt-image-2 | 内部生成，无第三方素材 |
| `assets/sprites/npcs/gulu.png` | Hub NPC 咕噜 | 96x96 | 3/4 侧视全身：圆润赭黄拾荒生物、单只大绿眼、破旧深蓝披风、腰间发光词片玻璃罐、怀抱裂纹罐。 | `assets/concept/characters/gulu_pixel.png`<br>`assets/sprites/player/player_idle.png` | 2026-11-01 | gpt-image-2 | 内部生成，无第三方素材 |
| `assets/sprites/weapons/broken_page_sword.png` | 近战武器图标 断页剑 | 64x64 | 3/4 斜构图：骨白撕纸剑身、黑色墨迹、羽毛笔剑柄、红色缠绳、书脊护手。 | 无（纯文本 prompt） | 2026-11-01 | gpt-image-2 | 内部生成，无第三方素材 |
| `assets/sprites/weapons/ink_axe.png` | 近战武器图标 墨斧 | 64x64 | 3/4 斜构图：黑墨石宽斧、青色刃口、书脊长柄、红布与锁链缠绕。 | 无（纯文本 prompt） | 2026-11-01 | gpt-image-2 | 内部生成，无第三方素材 |
| `assets/sprites/weapons/chain_blade.png` | 近战武器图标 链刃 | 64x64 | 3/4 蛇形斜构图：三节骨白弯刃由血红锁链连接、书脊柄、青色符文。 | 无（纯文本 prompt） | 2026-11-01 | gpt-image-2 | 内部生成，无第三方素材 |
| `assets/sprites/weapons/ink_bolt_gun.png` | 远程武器图标 墨弹枪 | 64x64 | 3/4 斜构图：黑铁手炮、墨水罐炮口、青色符文、红色皮柄、枪口凝聚墨弹。 | 无（纯文本 prompt） | 2026-11-01 | gpt-image-2 | 内部生成，无第三方素材 |
| `assets/sprites/weapons/talisman_gun.png` | 远程武器图标 符枪 | 64x64 | 3/4 斜构图：长管仪式手枪、骨白符纸包裹、青色符文、红色流苏、黄铜配件、枪口青烟。 | 无（纯文本 prompt） | 2026-11-01 | gpt-image-2 | 内部生成，无第三方素材 |
| `assets/sprites/weapons/page_shuriken.png` | 远程武器图标 书页飞刃 | 64x64 | 俯视四角折纸手里剑：骨白纸刃、黑色墨迹、青色刃缘、中心红绳。 | 无（纯文本 prompt） | 2026-11-01 | gpt-image-2 | 内部生成，无第三方素材 |

## 尺寸与 alpha 检查结果

所有 sprite 均为 RGBA，四角 alpha 为 0；背景为 RGB 不透明。透明像素占比高是角色剪影外的正常空白。

| 文件 | 实测尺寸 | 透明像素 | 全不透明像素 | 半透明像素（边缘/辉光） |
|---|---|---|---|---|
| `assets/sprites/player/player_idle.png` | 96x96 | 64.2% | 30.2% | 5.6% |
| `assets/sprites/bosses/ink_archivist.png` | 256x256 | 38.4% | 56.4% | 5.2% |
| `assets/sprites/enemies/ink_hound.png` | 96x96 | 61.1% | 29.8% | 9.1% |
| `assets/sprites/enemies/scribe_bug.png` | 96x96 | 52.3% | 41.1% | 6.6% |
| `assets/sprites/enemies/blank_man.png` | 96x96 | 60.6% | 28.7% | 10.7% |
| `assets/sprites/enemies/hanging_scribe.png` | 96x96 | 62.6% | 28.6% | 8.7% |
| `assets/sprites/enemies/echo_enemy.png` | 96x96 | 60.1% | 26.0% | 13.9% |
| `assets/sprites/enemies/typo_beast.png` | 96x96 | 41.2% | 48.7% | 10.2% |
| `assets/backgrounds/ink_archive.png` | 1536x864 | — | 100%（RGB） | — |
| `assets/backgrounds/breathing_ruins.png` | 1536x864 | — | 100%（RGB） | — |
| `assets/sprites/npcs/luchen.png` | 96x96 | 72.0% | 22.9% | 5.1% |
| `assets/sprites/npcs/ayan.png` | 96x96 | 66.2% | 26.2% | 7.6% |
| `assets/sprites/npcs/gulu.png` | 96x96 | 43.7% | 49.7% | 6.6% |
| `assets/sprites/weapons/broken_page_sword.png` | 64x64 | 83.4% | 9.9% | 6.7% |
| `assets/sprites/weapons/ink_axe.png` | 64x64 | 73.3% | 19.4% | 7.3% |
| `assets/sprites/weapons/chain_blade.png` | 64x64 | 86.0% | 5.1% | 9.0% |
| `assets/sprites/weapons/ink_bolt_gun.png` | 64x64 | 77.0% | 18.3% | 4.7% |
| `assets/sprites/weapons/talisman_gun.png` | 64x64 | 74.4% | 16.7% | 9.0% |
| `assets/sprites/weapons/page_shuriken.png` | 64x64 | 74.2% | 19.6% | 6.2% |

## 视觉检查

- 逐张打开检查：主角、Boss、6 敌人、3 NPC、6 武器、2 背景均非空图，主体完整，无裁切或严重跑偏。
- 主角：96 尺寸下书册青光、圆眼镜与高领长衣可辨；两版候选中选用剪影更简洁的一版。
- Boss：256 下书脊王冠、骨面具、羽毛笔臂与巨册均清楚，具有压迫感。
- 敌人：墨犬/抄写虫/空白人/悬吊书吏/失忆回声/错字兽的剪影区分明显；失忆回声刻意复用主角轮廓。
- NPC：陆沉、阿砚、咕噜的身份与概念图一致；咕噜的赭黄色是有意保留的识别色。
- 武器：6 个 64×64 图标均可读出核心造型；链刃细节最细，建议 HUD 不小于 32px 显示。
- 背景：两张 1536×864 构图均保留下方可行走区域，无角色、无 UI、无文字。

## 失败 / 降级项

1. **未生成逐帧动画**：按要求只交付静态 sprite；`SpriteFrames`、idle/run/attack 等动画需后续逐帧制作或由主线程先用单帧占位。
2. **Magpie 透明背景含低 alpha 黑膜**：生成结果在背景区域带有 alpha 1–4 的黑色像素，直接导入会形成极淡的暗矩形。已用 Pillow 将 alpha<16 且 RGB≤8 的像素置为 0；不是“提示词说透明”就算通过，特此记录。
3. **未做引擎内验证**：本代理只做了 Pillow 尺寸/alpha 检查与静态目视检查；实际 96/256 在游戏镜头、背景和动画中的可读性仍需主线程在 Godot 中确认。
4. **缩放与量化损失**：源图约 1254×1254，缩到 96/256/64 后部分细节会变成噪点或丢失；当前是静态占位/草稿级最终帧，不是像素级逐帧精修。建议后续用 Pixelorama/Aseprite 清理边缘、统一调色板、重绘关键帧。
5. **背景是单层平图**：没有拆分视差层、前景遮挡或可拼接的无缝边缘；若要做多轴视差，需要后续切层/补边。
6. **NPC 真人参考**：陆沉、阿砚、咕噜基于内部照片概念图风格化；对外发布前确认肖像授权，最终游戏使用原创风格化形象。
7. **透明度边缘**：保留了约 5–14% 的半透明像素用于青色辉光/抗锯齿边缘；若要求严格二值 alpha 的像素画，需要进一步阈值化或手工清理。

## 主线程接入建议

1. 导入 PNG 后设置 Filter `Nearest`、关闭 Mipmaps；不要开启会导致边缘发虚的压缩。
2. 角色/敌人/NPC 的 pivot 使用脚底中心；`Sprite2D.offset` 可按 `height/2` 调整，Boss 同理。
3. 飞行单位（悬吊书吏、失忆回声）目前仍按底边中心对齐，需要在场景中给正/负 Y 偏移表现悬浮。
4. 武器图标按 64×64 原尺寸导入；HUD 可用 32×32 最近邻缩放。
5. 背景按 1536×864 导入；若视口为 1280×720，可按比例裁切或缩放，保持 16:9。
6. 资源替换后运行一次无头导入/场景测试，确认 Godot 图像导入设置与 alpha 正常。

## 复现与来源

- 逐张 prompt 摘要、参考图、模型、日期、授权说明、SHA256 与实测 alpha 数据已写入 `assets/asset-manifest.json`。
- 生成工具：Magpie MCP；模型：`codex/gpt-image-2`；规范化：Pillow 12.3.0。
- 资产仅用于《昌子大冒险》M1 内部开发，不包含第三方图库或外部授权素材。

## 0.11.0-demo 像素统一（2026-11-03）

- demo 可见资产全部过 `python tests/check_pixel_assets.py --demo`（0 failures）：玩家 16 帧、6 敌人、墨骸史官、两层 1280×720 档案馆背景、3 张 192×256 NPC 卡片、16×16 地块、商店/残碑/宝箱/门/训练碑道具、透明底 Logo。
- NPC 卡片从原 800×1000 立绘直接裁半身并量化，保持原脸；不再使用动漫立绘与真人参考进入 demo。
- 旧的 1536×864 绘画背景与 800×1000 立绘保留给第 2–4 章/完整版，demo 场景不引用。
- 背景/立绘为 32 色；角色/敌人/Boss ≤32 色；地块 6 色；道具 5–7 色。
- 平台/地面改为 TileMapLayer；不再有 ColorRect 纯色平台或不可见地面。
