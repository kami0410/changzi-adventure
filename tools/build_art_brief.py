"""Builds docs/art/昌子大冒险-美术需求清单.pdf: every art asset the game wants
drawn by an outside artist, with specs, references and bilingual prompts.

Run tools/build_art_brief_refs.py first (reference sheets), then:
    python tools/build_art_brief.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image as PILImage
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (Image, KeepTogether, PageBreak, Paragraph, SimpleDocTemplate, Spacer, Table,
                                TableStyle)

ROOT = Path(__file__).resolve().parents[1]
REFS = ROOT / "docs" / "art" / "refs"
OUT = ROOT / "docs" / "art" / "昌子大冒险-美术需求清单.pdf"

pdfmetrics.registerFont(TTFont("YaHei", "C:/Windows/Fonts/msyh.ttc", subfontIndex=0))
pdfmetrics.registerFont(TTFont("YaHeiBold", "C:/Windows/Fonts/msyhbd.ttc", subfontIndex=0))

INK = colors.HexColor("#1b2230")
TEAL = colors.HexColor("#1f7a74")
BLOOD = colors.HexColor("#93222a")
PAPER = colors.HexColor("#f4efe4")
MUTED = colors.HexColor("#5a6270")

S = {
    "title": ParagraphStyle("title", fontName="YaHeiBold", fontSize=26, leading=34, textColor=INK, alignment=TA_CENTER),
    "subtitle": ParagraphStyle("subtitle", fontName="YaHei", fontSize=12, leading=18, textColor=MUTED, alignment=TA_CENTER),
    "h1": ParagraphStyle("h1", fontName="YaHeiBold", fontSize=17, leading=24, textColor=BLOOD, spaceBefore=6, spaceAfter=8),
    "h2": ParagraphStyle("h2", fontName="YaHeiBold", fontSize=13, leading=19, textColor=INK, spaceBefore=10, spaceAfter=4),
    "body": ParagraphStyle("body", fontName="YaHei", fontSize=9.5, leading=15, textColor=INK),
    "small": ParagraphStyle("small", fontName="YaHei", fontSize=8.5, leading=13, textColor=MUTED),
    "prompt": ParagraphStyle("prompt", fontName="YaHei", fontSize=8.5, leading=13, textColor=colors.HexColor("#21333a"),
                             backColor=colors.HexColor("#e7f1ef"), borderPadding=5, leftIndent=4, rightIndent=4),
    "prompt_en": ParagraphStyle("prompt_en", fontName="YaHei", fontSize=8, leading=12, textColor=colors.HexColor("#3a3328"),
                                backColor=colors.HexColor("#f2ece0"), borderPadding=5, leftIndent=4, rightIndent=4),
    "cell": ParagraphStyle("cell", fontName="YaHei", fontSize=8.5, leading=12, textColor=INK),
    "cellb": ParagraphStyle("cellb", fontName="YaHeiBold", fontSize=8.5, leading=12, textColor=INK),
}

STYLE_CN = ("暗黑哥特 + 克苏鲁式污染的像素画，2D 横版动作 Roguelite。母题：禁忌档案馆、撕碎的书页、墨水、会呼吸的肋骨石、"
            "无光的深海、在笑的剧场。配色角色：午夜蓝阴影（#141c2c–#23324a）、病态青轮廓光（#8fe8dc）、骨白（#e8dcc4）、"
            "干血红（#93222a）、墨黑描边（#0b0f14），污染用紫黑 / 墨绿点缀。手点像素、边缘清晰、1 px 深色外描边、"
            "右上方冷色轮廓光；不要抗锯齿软边，不要大面积平滑渐变。")
STYLE_EN = ("Dark gothic, Cthulhu-touched pixel art for a 2D side-scrolling action roguelite. Motifs: forbidden archive, "
            "torn manuscript pages, ink, breathing ribbed stone, a lightless sea, a smiling theater. Palette roles: midnight "
            "blue shadows (#141c2c-#23324a), sickly teal rim light (#8fe8dc), bone white (#e8dcc4), dried blood red "
            "(#93222a), ink-black outline (#0b0f14), corruption accents in purple-black and green-black. Hand-placed "
            "pixels, crisp edges, 1 px dark outline, cool rim light from the upper right; no anti-aliased soft edges, "
            "no smooth airbrushed gradients.")


def para(text, style="body"):
    return Paragraph(text, S[style])


def ref(name, width_mm=170):
    path = REFS / name
    w, h = PILImage.open(path).size
    width = width_mm * mm
    return Image(str(path), width=width, height=width * h / w)


def spec_table(rows):
    data = [[para(k, "cellb"), para(v, "cell")] for k, v in rows]
    t = Table(data, colWidths=[30 * mm, 140 * mm])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (0, -1), colors.HexColor("#ece6da")),
        ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#c9c0ae")),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("TOPPADDING", (0, 0), (-1, -1), 3), ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
    ]))
    return t


def item(code, name, priority, rows, cn, en, refs=()):
    block = [para(f"{code}　{name}　<font color='#93222a'>[{priority}]</font>", "h2"), spec_table(rows), Spacer(1, 4),
             para("<b>提示词（中文）</b>", "small"), Spacer(1, 5), para(cn, "prompt"), Spacer(1, 8),
             para("<b>Prompt (English)</b>", "small"), Spacer(1, 5), para(en, "prompt_en"), Spacer(1, 6)]
    if refs:
        block.append(para("参考图：" + "、".join(refs), "small"))
    block.append(Spacer(1, 8))
    return KeepTogether(block)


def creature(code, name, en_name, chapter, size, behaviour, look_cn, look_en, priority="P0"):
    rows = [
        ("用途", f"新怪物「{name}」（{chapter}），行为：{behaviour}。替换现在借用的素材库小生物占位图。"),
        ("规格", f"{size}，透明底 PNG，像素 1×；每个动作导出为一条横向序列帧（帧间无间隔），脚底/最低点贴画布底边。"),
        ("帧数", "待机 4 · 移动 4 · 攻击前摇 2 · 攻击 3 · 受击 1 · 死亡 5（共 19 帧，可分 6 张横条）"),
        ("命名", f"enemy_{en_name}_idle.png / _move / _windup / _attack / _hurt / _death"),
    ]
    cn = f"{STYLE_CN} 侧视角色序列帧，角色朝右。{look_cn} 透明背景，单个角色居中，脚底贴底边。"
    en = f"{STYLE_EN} Side-view sprite sheet, character facing right. {look_en} Transparent background, one character, feet on the bottom edge."
    return item(code, f"{name}（{en_name}）", priority, rows, cn, en, ["图 R2 现有敌人", "图 R7 当前占位"])


def build():
    doc = SimpleDocTemplate(str(OUT), pagesize=A4, leftMargin=20 * mm, rightMargin=20 * mm,
                            topMargin=18 * mm, bottomMargin=16 * mm, title="昌子大冒险 美术需求清单",
                            author="GameCreateStudio")
    st = []
    # ---------------------------------------------------------------- cover
    st += [Spacer(1, 40 * mm), para("昌子大冒险", "title"), Spacer(1, 4), para("美术需求清单 · 参考图与提示词", "subtitle"),
           Spacer(1, 2), para("版本 v1 · 2026-11-08 · 对应游戏 0.15", "subtitle"), Spacer(1, 18 * mm)]
    st.append(para(
        "这份清单写给负责绘制的人：每一项都写明了用途、尺寸、帧数、命名和中英文提示词，并附游戏实际截图作风格参考。"
        "画好后按「命名」一栏的文件名放进项目的 <b>art_inbox/</b> 文件夹，我会负责规范化（调色板、透明度、描边、"
        "脚底对齐）并接入游戏。优先级：<b>P0</b> 最影响观感，请先画；<b>P1</b> 明显加分；<b>P2</b> 锦上添花。"))
    st.append(Spacer(1, 6))
    st.append(para(
        "目前这些位置用的是程序化生成或素材库借用的占位图：第 2–4 章区域背景、6 种新怪物、地面道具、翻滚动作。"
        "替换后游戏的完成度会提升一个档次。"))
    st.append(PageBreak())

    # ---------------------------------------------------------------- global spec
    st.append(para("一、统一美术规范（每一项都适用）", "h1"))
    st.append(spec_table([
        ("视角", "2D 横版侧视。角色默认朝右（游戏里镜像得到朝左）。"),
        ("像素密度", "1 个美术像素 = 1 个屏幕像素（游戏内 1280×720）。只允许整数倍缩放，不要画「高清再缩小」的伪像素。"),
        ("尺寸", "主角/普通怪 96×96 画布；精英/大型 128×128；Boss 256×256；道具 64×64；地块 16×16；背景 1536×864（纵井 1536×2160）。"),
        ("透明", "角色/道具/中景：透明底 PNG，alpha 只能是 0 或 255（无半透明羽化）。发光效果游戏里用代码叠加，不要画进图里。"),
        ("描边与光", "1 px 墨黑外描边 #0b0f14；右上方病态青轮廓光 #8fe8dc；角色内部 16–32 色，Boss ≤ 40 色。"),
        ("脚底", "角色最低的不透明像素行贴住画布底边，水平居中。"),
        ("配色", "午夜蓝 / 病态青 / 骨白 / 干血红 / 墨黑为主；各章主色：第1章 墨蓝档案、第2章 青灰苔石 + 锈红血脉、第3章 深海青黑 + 生物荧光、第4章 暗红丝绒 + 旧金。"),
        ("格式", "PNG（sRGB）。动画用横向序列帧（同尺寸帧首尾相接）或每帧一张并按 _00、_01 编号。"),
        ("禁止", "文字、水印、签名、UI 边框、参考图里的 UI；照片质感；模糊/涂抹；画面外被裁切的肢体。"),
    ]))
    st.append(Spacer(1, 8))
    st.append(para("<b>通用风格提示词（每条提示词前都可以加上）</b>", "small"))
    st.append(Spacer(1, 5))
    st.append(para(STYLE_CN, "prompt"))
    st.append(Spacer(1, 8))
    st.append(para(STYLE_EN, "prompt_en"))
    st.append(Spacer(1, 10))
    st.append(para("图 R1 主角昌子现有动作帧（风格与比例基准）", "h2"))
    st.append(ref("r1_player.png"))
    st.append(para("图 R2 现有普通敌人（新怪物要与之同一画风与精度）", "h2"))
    st.append(ref("r2_enemies.png", 150))
    st.append(PageBreak())
    st.append(para("图 R3 现有 Boss", "h2"))
    st.append(ref("r3_bosses.png", 150))
    st.append(para("图 R4 第 1 章像素背景：远景 + 透明中景（第 2–4 章背景的目标质量与分层方式）", "h2"))
    st.append(ref("r4_ch1_pixel_bg.png"))
    st.append(para("图 R5 第 2–4 章现状截图（背景是从旧插画程序化派生的占位，需要重画）", "h2"))
    st.append(ref("r5_current.png"))
    st.append(PageBreak())

    # ---------------------------------------------------------------- A player
    st.append(para("二、主角动作", "h1"))
    st.append(item("A1", "昌子 · 翻滚", "P0", [
        ("用途", "新加入的翻滚（带无敌帧，可从弹幕下钻过）。现在用跳跃蜷身帧旋转代替，需要正式动作。"),
        ("规格", "96×96 每帧，透明底，横条 8 帧（768×96），脚底贴底边。"),
        ("帧数", "8 帧：起滚下蹲 1 · 前扑团身 1 · 团身翻滚 4（每帧转 90°，风衣卷起）· 落地半蹲 1 · 起身 1。整段 0.36 秒。"),
        ("命名", "player_roll.png"),
    ], f"{STYLE_CN} 主角昌子（黑发戴眼镜的年轻史官，黑红长风衣，左手抱一本发光的书）的翻滚动画横向序列帧 8 帧：下蹲、前扑、"
       "团身翻滚 4 帧（身体蜷成球，风衣下摆卷起成弧）、落地半蹲、起身。朝右，透明背景。",
       f"{STYLE_EN} 8-frame horizontal sprite strip of the hero Changzi (young archivist, black hair, glasses, long black-and-"
       "red coat, a glowing book held in the left hand) doing a combat roll: crouch, dive, four tucked rolling frames "
       "(body curled into a ball, coat hem swirling into an arc), landing crouch, stand up. Facing right, transparent background.",
       ["图 R1"]))
    st.append(item("A2", "昌子 · 空中冲刺", "P1", [
        ("用途", "空中按翻滚触发的水平冲刺。"),
        ("规格", "96×96 每帧，透明底，3 帧横条。"),
        ("帧数", "前倾起冲 1 · 冲刺中（身体水平、风衣拉直）1 · 收势 1"),
        ("命名", "player_airdash.png"),
    ], f"{STYLE_CN} 主角昌子空中水平冲刺 3 帧：身体前倾几乎水平，风衣向后拉成一条直线，书页从书中飞出。朝右，透明背景。",
       f"{STYLE_EN} 3-frame strip of the hero dashing horizontally in mid-air: body leaning almost flat, coat stretched "
       "straight behind, pages flying from the book. Facing right, transparent background.", ["图 R1"]))
    st.append(item("A3", "昌子 · 终结重击", "P1", [
        ("用途", "三连击第三段 / 翻滚接重击。现在复用普通攻击帧。"),
        ("规格", "160×160 每帧（武器挥动空间），透明底，5 帧横条，脚底贴底边。"),
        ("帧数", "蓄力上举 1 · 下劈 2（拖出墨迹残影）· 着地停顿 1 · 收势 1"),
        ("命名", "player_finisher.png"),
    ], f"{STYLE_CN} 主角昌子双手握断页剑的终结重击 5 帧：高举蓄力、向前下方猛劈（剑身拖出墨色残影）、剑尖砸地停顿、收势。朝右，透明背景。",
       f"{STYLE_EN} 5-frame strip of the hero's finishing heavy strike with a broken-page sword held in both hands: raise "
       "and charge, a downward forward cleave (ink-colored afterimage trailing the blade), blade hitting the ground, recover. "
       "Facing right, transparent background.", ["图 R1"]))
    st.append(PageBreak())

    # ---------------------------------------------------------------- B creatures
    st.append(para("三、新怪物（替换占位）", "h1"))
    st.append(para("0.15 新增 6 种怪物，玩法已经做好，现在临时借用素材库里的小生物动画（图 R7，画风偏可爱，"
                   "与本作调性不符）。请按下面的设定重画。另附 4 种期望新增的怪物（P1）。"))
    st.append(Spacer(1, 4))
    st.append(ref("r7_creatures_placeholder.png", 150))
    st.append(para("图 R7 当前占位：血瞳、焚颅、墨火、渊母、噬名蛇、回声蝠（从上到下）", "small"))
    st.append(Spacer(1, 6))
    st.append(creature("B1", "血瞳", "watcher_eye", "第1、3章", "96×96", "悬浮在玩家斜上方保持距离，发射慢速追踪泪弹",
                       "一颗布满血丝的巨大眼球，瞳孔是墨黑的漩涡，下方垂着三条神经触须，眼白泛着病态的骨白，边缘渗血。",
                       "A huge bloodshot floating eyeball, its pupil a swirling ink-black vortex, three nerve tendrils hanging "
                       "below, sickly bone-white sclera with bleeding edges."))
    st.append(creature("B2", "焚颅", "skull_lantern", "第2、4章", "96×96", "在空中盘旋后俯冲撞击，会喷出火羽",
                       "一颗燃烧的人类头骨，头顶裂开冒出青白色的冷焰，眼眶里是两点金色的火，下颌挂着烧焦的书页。",
                       "A burning human skull with a cracked crown pouring cold teal-white flame, two golden embers in "
                       "the sockets, scorched book pages hanging from the jaw."))
    st.append(creature("B3", "墨火", "ink_wisp", "第1、2章", "64×64", "飘浮的鬼火，锁定后加速扑来，贴身闪烁后自爆",
                       "一团青色鬼火，核心是一滴墨，外焰由碎裂的字母组成，没有脸，尾焰拖长。",
                       "A teal will-o'-wisp whose core is a single drop of ink, outer flame made of shattered letters, "
                       "no face, a long trailing tail."))
    st.append(creature("B4", "渊母", "abyss_jelly", "第3章", "96×128", "缓慢漂浮，触须收拢蓄力后放出一圈电脉冲",
                       "一只深海水母，伞盖半透明但用实色像素表现，里面封着一页发光的书页，触须末端是细小的手。",
                       "A deep-sea jellyfish, its bell rendered in solid pixels suggesting translucency, a glowing book page "
                       "sealed inside, tentacles ending in tiny hands."))
    st.append(creature("B5", "噬名蛇", "name_snake", "第2、3、4章", "128×64", "贴地快速蜿蜒，蓄力后低身突进（玩家可跳过）",
                       "一条暗红色长蛇，鳞片是一枚枚刻着名字的小铭牌，口中吐出的信子是一行墨字，身体贴地很低。",
                       "A long dark-red serpent whose scales are tiny name plates, its forked tongue a line of ink "
                       "writing, body kept very low to the ground."))
    st.append(creature("B6", "回声蝠", "echo_bat", "第3、4章", "96×64", "成群绕飞，连续短促俯冲",
                       "一只蝙蝠，翼膜由泛黄的乐谱纸拼成，脸只有一张张开的嘴，嘴里有一圈小牙，紫黑色。",
                       "A bat whose wing membranes are stitched yellowed sheet-music pages, the face is only an open "
                       "mouth ringed with small teeth, purple-black palette."))
    st.append(PageBreak())
    st.append(para("期望新增的怪物（P1）", "h2"))
    st.append(creature("B7", "书脊蜈蚣", "spine_centipede", "第1章", "128×64", "沿地面与墙爬行，卷成环冲撞",
                       "由一节节书脊拼成的蜈蚣，每一节的书名都被墨水涂黑，腿是折断的羽毛笔。",
                       "A centipede built from book spines, every title blacked out with ink, legs made of snapped quill pens.", "P1"))
    st.append(creature("B8", "锈钟铃兵", "rust_bellman", "第2章", "96×96", "持铃近战，摇铃时周围敌人加速",
                       "一个头部是锈蚀铜钟的佝偻士兵，钟里传出呼吸雾气，手持一根挂满小铃的长杖。",
                       "A hunched soldier whose head is a rusted bronze bell breathing out mist, holding a staff hung with small bells.", "P1"))
    st.append(creature("B9", "溺亡抄写员", "drowned_scribe", "第3章", "96×96", "远程投掷湿透的书页，书页落地变成减速水洼",
                       "一个浑身湿透、皮肤青白的抄写员，长袍滴水，头发里缠着海藻，手里捧着一摞泡烂的稿纸。",
                       "A drowned scribe with pale teal skin, robe dripping, kelp tangled in the hair, holding a stack of soaked papers.", "P1"))
    st.append(creature("B10", "提线笑偶", "string_puppet", "第4章", "96×128", "被看不见的线吊着跳跃，落地时四周弹出笑脸面具",
                       "一个被丝线吊着的木偶，脸是固定的大笑面具，关节是旧金色的铰链，衣服是剧场红丝绒。",
                       "A marionette hung from unseen strings, its face a fixed grinning mask, old-gold hinge joints, "
                       "theater red velvet clothes.", "P1"))
    st.append(PageBreak())

    # ---------------------------------------------------------------- C backgrounds
    st.append(para("四、第 2–4 章区域背景（最影响观感）", "h1"))
    st.append(para("现在每个区域的背景是把旧插画裁切、调色得到的占位（图 R5）。请按第 1 章的方式（图 R4）画像素背景，"
                   "每张分两层：<b>远景</b>（不透明，1536×864；纵井 1536×2160）+ <b>中景</b>（透明 PNG，同尺寸，"
                   "只画下方约 60% 的建筑/剪影，上方透明）。远景要比游戏前景暗、饱和度低，给角色留出可读性。"
                   "画面底部 15% 会被地面挡住，不要放重要内容。左右边缘要能无缝横向平铺。"))
    st.append(Spacer(1, 6))
    bg_specs = [
        ("C1", "第2章 呼吸废墟 · 入口与支路", "ch2_ruins_far / ch2_ruins_mid",
         "会呼吸的哥特废墟外景：倒塌的拱廊和书塔，石柱像肋骨一样起伏，暗红血管与黑色触须爬满青灰苔石，远处一轮被红晕包围的黑月，空中飘着撕碎的书页。",
         "A breathing gothic ruin exterior: collapsed arcades and book towers, pillars rising and falling like ribs, dark red veins "
         "and black tendrils over grey-green mossy stone, a black moon in a red halo far away, torn pages drifting in the air."),
        ("C2", "第2章 呼吸废墟 · 枢纽与书库", "ch2_vault_far / ch2_vault_mid",
         "巨大肋骨穹顶下的书库内部：拱顶由弯曲的骨肋构成，书架嵌在肉质的墙里，烛光昏黄，地面积着薄薄一层呼吸雾。",
         "Interior of an archive under a giant ribcage dome: vaults made of curved bone ribs, bookshelves embedded in fleshy walls, "
         "dim yellow candlelight, a thin layer of breathing mist on the floor."),
        ("C3", "第2章 呼吸废墟 · 纵井（竖版 1536×2160）", "ch2_well_far / ch2_well_mid",
         "向上无尽延伸的竖井：两侧是层层叠叠的破书架和断裂的楼梯，井壁有节律地起伏，最上方隐没在黑暗里，井底有积水倒影。",
         "An endless vertical shaft: stacked broken bookshelves and snapped staircases on both sides, walls swelling in a slow "
         "rhythm, the top fading into darkness, a puddle reflection at the bottom."),
        ("C4", "第2章 呼吸废墟 · Boss「肺钟守卫」大厅", "ch2_boss_far / ch2_boss_mid",
         "一座巨大的铜钟悬在大厅中央，钟体像肺一样一张一缩，四周的立柱上挂满铃铛，地面裂开渗出红光。",
         "A colossal bronze bell hanging in the middle of a hall, expanding and contracting like a lung, pillars hung with bells, "
         "the floor cracked and leaking red light."),
        ("C5", "第3章 无光海 · 入口海岸", "ch3_shore_far / ch3_shore_mid",
         "漆黑的海面与倒悬的城市剪影，一座破碎的巨型钟表半沉在海中，天上是被白色日冕包围的黑日，细雨。",
         "A pitch-black sea with inverted city silhouettes, a shattered giant clock half sunk in the water, a black sun ringed by a "
         "white corona, thin rain."),
        ("C6", "第3章 无光海 · 沉没图书馆", "ch3_library_far / ch3_library_mid",
         "完全沉在水下的哥特图书馆：书页像鱼群一样游动，彩窗透下青色光柱，书架上长满珊瑚和藤壶，生物荧光点点。",
         "A gothic library fully underwater: pages swimming like schools of fish, teal light shafts through stained glass, coral and "
         "barnacles on the shelves, specks of bioluminescence."),
        ("C7", "第3章 无光海 · 深渊竖井（竖版）", "ch3_well_far / ch3_well_mid",
         "向下沉没的竖井，越往上越亮，越往下越黑；井壁是被海水腐蚀的石柱和铁链，悬着发光的水母。",
         "A sinking vertical shaft, brighter at the top and blacker below, walls of sea-eaten stone pillars and chains, glowing "
         "jellyfish hanging in the water."),
        ("C8", "第3章 无光海 · Boss「最后的读者」", "ch3_boss_far / ch3_boss_mid",
         "海底深处一张巨大的阅读桌，桌上摊开一本比城市还大的书，书页翻动掀起暗流，黑日在海面上方透下一圈光。",
         "A giant reading desk at the bottom of the sea, a book larger than a city lying open on it, turning pages stirring dark "
         "currents, the black sun casting a ring of light from above the surface."),
        ("C9", "第4章 笑面剧场 · 舞台", "ch4_stage_far / ch4_stage_mid",
         "破败的剧院舞台：撕裂的红丝绒幕布、巨大的吊灯、舞台中央一本摊开的书，观众席上坐着一排排纸人。",
         "A decaying theater stage: torn red velvet curtains, a huge chandelier, an open book at center stage, rows of paper people "
         "seated in the audience."),
        ("C10", "第4章 笑面剧场 · 观众席与包厢", "ch4_seats_far / ch4_seats_mid",
         "层层叠叠的包厢与观众席，每个座位上都戴着同一张笑脸面具，金色雕花栏杆生锈，光从舞台方向打来。",
         "Tiered boxes and seats, every seat wearing the same grinning mask, rusted gold carved railings, light coming from the stage."),
        ("C11", "第4章 笑面剧场 · 后台吊杆（竖版）", "ch4_fly_far / ch4_fly_mid",
         "剧场后台的吊杆区：密密麻麻的绳索、沙袋、木制走道和布景板，从上方的黑暗里垂下，偶有一束舞台光漏进来。",
         "The fly loft behind the stage: dense ropes, sandbags, wooden catwalks and painted flats hanging from darkness above, an "
         "occasional stage light leaking in."),
        ("C12", "第4章 笑面剧场 · Boss「笑面史官」", "ch4_boss_far / ch4_boss_mid",
         "剧场最深处的镜面大厅：无数面镜子映出同一张笑脸，地面是血红的地毯，正中一张写字台上堆满名册。",
         "A hall of mirrors deep in the theater: countless mirrors reflecting the same smiling face, a blood-red carpet, a writing "
         "desk piled with registers at the center."),
    ]
    for code, name, files, cn, en in bg_specs:
        tall = "竖版" in name
        size = "1536×2160" if tall else "1536×864"
        st.append(item(code, name, "P0", [
            ("规格", f"远景 {size} 不透明 PNG + 中景 {size} 透明 PNG（只画下方约 60%）；左右可无缝平铺。"),
            ("命名", files.replace(" / ", ".png / ") + ".png"),
        ], f"{STYLE_CN} 2D 横版游戏背景，平视侧面构图，{cn} 远景偏暗、低饱和，中间区域留给玩法，底部 15% 不放重要内容，左右可无缝平铺。",
           f"{STYLE_EN} 2D side-scroller background, flat side-on composition. {en} Far layer dark and desaturated, keep the center "
           "readable for gameplay, nothing important in the bottom 15%, tileable left and right.", ["图 R4", "图 R5"]))
    st.append(PageBreak())

    # ---------------------------------------------------------------- D tiles & props
    st.append(para("五、地块、道具与机关", "h1"))
    st.append(ref("r6_tiles.png", 150))
    st.append(para("图 R6 当前程序化地块（布局沿用，请按同样的格子位置重画）", "small"))
    st.append(item("D1", "四章地块图集", "P1", [
        ("规格", "每章一张 64×32 PNG（4 列 × 2 行，每格 16×16）。"),
        ("布局", "第 1 行：地面顶 · 地面填充 · 平台顶 · 平台下垂饰（透明）；第 2 行：地面顶变体 · 深层填充（更暗）· 平台顶变体 · 垂饰变体。"),
        ("要求", "地面填充/平台顶左右必须无缝拼接；第 1 章 墨蓝石砖 + 金边，第 2 章 苔石 + 锈红血脉，第 3 章 湿板岩 + 藻 + 泡沫，第 4 章 木地板 + 红丝绒边 + 金线。"),
        ("命名", "tiles_ch1.png … tiles_ch4.png"),
    ], f"{STYLE_CN} 16×16 像素地块图集，4 列 2 行，可无缝横向拼接：地面顶、地面填充、平台顶、平台下方垂挂装饰（透明底）及各自变体。",
       f"{STYLE_EN} 16x16 pixel terrain tileset, 4 columns x 2 rows, seamless horizontally: ground top, ground fill, platform top, "
       "hanging under-platform decoration (transparent) and variants.", ["图 R6"]))
    st.append(ref("r8_props_placeholder.png", 120))
    st.append(para("图 R8 当前占位道具（从上到下第 1–4 章）", "small"))
    st.append(item("D2", "地面道具（每章 8 个）", "P1", [
        ("规格", "64×64 透明 PNG，底边贴地；每章 8 个，可拼一张 512×64 横条。"),
        ("内容", "第1章：书堆、烛台、倒塌书架、羽毛笔架、墨水瓶、石像、卷轴筒、档案柜。第2章：碎石、断柱、血管陶罐、肋骨、钟、苔藓石、骨堆、残碑。"
                 "第3章：珊瑚、藤壶岩、海藻、发光海葵、灯笼、沉船木板、锚、贝壳堆。第4章：脚灯、红椅、面具架、沙袋、绳圈、纸偶、布景板、化妆镜。"),
        ("命名", "props_ch1.png … props_ch4.png"),
    ], f"{STYLE_CN} 一组 8 个横版游戏地面装饰道具，每个 64×64，底边贴地，透明底，侧视。",
       f"{STYLE_EN} A set of 8 side-view floor props for a 2D platformer, 64x64 each, bottom-aligned, transparent background.",
       ["图 R8"]))
    st.append(item("D3", "召唤电梯与呼叫面板", "P1", [
        ("用途", "第 2–4 章的召唤式电梯（现在是代码画的线框）。"),
        ("规格", "轿厢 160×64（平台面在底部 16 px）；呼叫面板 32×72，两种状态（待机红灯 / 运行金灯）；井道导轨 16×64 可纵向平铺。"),
        ("命名", "lift_car.png / lift_panel_idle.png / lift_panel_active.png / lift_rail.png"),
    ], f"{STYLE_CN} 哥特档案馆风格的老式铁笼电梯轿厢（侧视），铁栅栏、黄铜装饰、地板边缘有警示条纹；以及一个立在地上的黄铜呼叫面板，顶部一盏信号灯。透明底。",
       f"{STYLE_EN} An old wrought-iron cage elevator car in a gothic archive style (side view), iron grille, brass trims, hazard "
       "stripes on the floor edge; plus a brass call panel standing on the floor with a signal lamp on top. Transparent background."))
    st.append(PageBreak())

    # ---------------------------------------------------------------- E UI
    st.append(para("六、界面与图标", "h1"))
    st.append(ref("r9_hud.png", 150))
    st.append(para("图 R9 当前战斗 HUD", "small"))
    st.append(item("E1", "标题画面主视觉", "P2", [
        ("规格", "1920×1080 像素画（可 2× 放大后 960×540 绘制），左侧留空给菜单。"),
        ("命名", "title_keyart.png"),
    ], f"{STYLE_CN} 游戏标题主视觉：昌子背对镜头站在倒塌的档案馆尽头，书页像暴风雪一样卷向天空中一只巨大的眼睛，画面左侧大片暗部留给菜单。",
       f"{STYLE_EN} Title key art: Changzi standing with his back to the viewer at the end of a collapsed archive, pages swirling "
       "like a blizzard toward a giant eye in the sky, a large dark area on the left left free for the menu.", ["图 R1"]))
    st.append(item("E2", "遭遇变数图标", "P2", [
        ("用途", "战斗词缀提示：精英、迅潮、群潮。"),
        ("规格", "32×32 透明 PNG ×3，1 px 描边。"),
        ("命名", "affix_elite.png / affix_swift.png / affix_horde.png"),
    ], f"{STYLE_CN} 三个 32×32 像素图标：金色王冠裂开的眼（精英）、青色疾风羽毛（迅潮）、一群黑色小手（群潮）。透明底。",
       f"{STYLE_EN} Three 32x32 pixel icons: a cracked golden crown with an eye (elite), a teal gust feather (swift), a cluster of "
       "small black hands (horde). Transparent background."))
    st.append(Spacer(1, 10))
    st.append(para("七、交付方式", "h1"))
    st.append(para("1. 文件按每项「命名」保存，放进项目根目录下的 <b>art_inbox/</b>（没有就新建）。<br/>"
                   "2. 能给分层源文件（.aseprite / .psd）更好，一并放进去。<br/>"
                   "3. 不确定的地方按「统一美术规范」处理即可；尺寸、帧数可以按画面需要略调，告诉我实际值就行。<br/>"
                   "4. 交付后我会做规范化（调色板、二值透明、描边、脚底对齐）、接入游戏并截图确认。"))
    doc.build(st)
    print("wrote", OUT)


if __name__ == "__main__":
    build()
