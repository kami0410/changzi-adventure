"""Generate the 0.8 lexicon expansion for Changzi Adventure.

Writes one WordData .tres per new word into resources/words/, registers every
word file in scripts/data/content_library.gd (exports cannot scan folders),
and checks that every glyph/meaning/description character exists in the
Ark Pixel font so nothing renders as tofu.

Run from the game folder:  python tools/generate_words.py [--check]
--check only reports; it writes nothing.
"""

from __future__ import annotations

import pathlib
import re
import sys

GAME = pathlib.Path(__file__).resolve().parents[1]
WORDS_DIR = GAME / "resources" / "words"
LIBRARY = GAME / "scripts" / "data" / "content_library.gd"
FONT = GAME / "assets" / "fonts" / "ark-pixel-12px-monospaced-zh_hans.ttf"

NOUN, VERB, MODIFIER = 0, 1, 2

# id, glyph, meaning, role, tags, power, corruption, components, description
WORDS = [
    # --- nouns: the concepts the AI and players reach for first ---
    ("yue", "☽", "月", NOUN, ["moon", "light"], 2, 0,
     {"slow": 0.15, "heal": 1.0, "duration": 1.0},
     "白榆说，月亮是唯一一盏不需要被记住也会亮的灯。"),
    ("men", "⛩", "门", NOUN, ["door", "space"], 2, 0,
     {"pull": 1.0, "slow": 0.1},
     "门的那一边没有房间，只有一页还没写完的纸。"),
    ("yu", "⇶", "羽", NOUN, ["feather", "wind"], 2, 0,
     {"damage": 1.0, "projectiles": 3.0, "homing": 0.6, "move_speed": 0.1},
     "鸦群掠过档案馆时落下的羽，每一根都记得回去的路。"),
    ("gu", "☥", "骨", NOUN, ["bone", "earth"], 2, 1,
     {"damage": 2.0, "knockback": 1.0, "shield": 1.0},
     "墨骸史官把自己的骨头当作书脊，一节一节缝进封面。"),
    ("xin", "♥", "心", NOUN, ["heart", "life"], 2, 0,
     {"heal": 3.0, "shield": 1.0},
     "咕噜说，心是唯一不能二手转卖的东西。"),
    ("yanjing", "◎", "眼", NOUN, ["eye", "sight"], 2, 0,
     {"damage": 2.0, "pierce": 1.0},
     "最后的读者用它读完了所有结局，再把它合上。"),
    ("guan", "♔", "冠", NOUN, ["crown", "authority"], 3, 1,
     {"damage": 2.0, "shield": 2.0, "duration": 1.0},
     "笑面史官的冠冕，是用一千次谢幕的掌声压成的。"),
    ("hua", "⚘", "花", NOUN, ["flower", "life"], 2, 0,
     {"heal": 2.0, "area": 0.3},
     "墨雨落过的地方，第二天会开一种不记得名字的花。"),
    ("shan", "▲", "山", NOUN, ["earth", "scale"], 3, 0,
     {"damage": 2.0, "area": 0.5, "knockback": 1.5},
     "阿砚说，山是这个世界最早的一块铁砧。"),
    ("shui", "♒", "水", NOUN, ["water", "life"], 2, 0,
     {"damage": 1.0, "heal": 1.0, "lifesteal": 0.1},
     "水记得每一个溺水的人，再把他们还给岸。"),
    ("chao", "◒", "潮", NOUN, ["water", "moon"], 2, 1,
     {"slow": 0.2, "damage": 1.0, "duration": 1.0, "knockback": 0.8},
     "无光海没有倒影，但潮水每晚都替死者翻一次身。"),
    ("zhenming", "※", "真名", NOUN, ["name", "authority"], 3, 1,
     {"damage": 3.0, "pierce": 2.0},
     "叫出一个人的真名，等于把他从所有别的名字里抽出来。"),
    ("mo", "◆", "墨", NOUN, ["ink", "archive"], 2, 0,
     {"damage": 1.0, "ink_gain": 5.0},
     "墨是被删掉的记忆，落回人间时还是温的。"),
    ("zi", "§", "字", NOUN, ["word", "archive"], 2, 0,
     {"damage": 1.0, "projectiles": 3.0},
     "陆沉说，一个字被写下来，就会自己去找读它的人。"),
    ("kong", "□", "空", NOUN, ["space"], 2, 0,
     {"area": 0.6, "slow": 0.15, "pull": 1.0},
     "白榆的地图上所有没画的地方，加起来就是空。"),
    ("zhixu", "☰", "秩序", NOUN, ["order", "authority"], 3, 0,
     {"damage": 2.0, "stun": 0.4, "duration": 1.0},
     "档案馆的第一条规矩：每一页都必须有页码。"),
    ("hundun", "☯", "混沌", NOUN, ["chaos", "abyss"], 3, 2,
     {"damage": 3.0, "corruption_gain": 2.0, "area": 0.4},
     "所有被撕掉的页堆在一起，就不再有前后。"),
    ("zhong", "♫", "钟", NOUN, ["sound", "order"], 2, 1,
     {"damage": 1.0, "stun": 0.5, "slow": 0.15},
     "肺钟每响一次，城里就少一口气。"),
    ("deng", "☼", "灯", NOUN, ["light", "holy"], 2, 0,
     {"damage": 1.0, "heal": 1.0, "shield": 1.0},
     "阿砚每晚拧亮的那盏灯，是守夜人唯一的工钱。"),
    ("ye", "¶", "页", NOUN, ["archive", "memory"], 2, 0,
     {"shield": 2.0, "heal": 1.0},
     "名册被撕走三页以后，每一页纸都开始学着保护自己。"),
    ("shuang", "▽", "霜", NOUN, ["ice", "scale"], 2, 0,
     {"slow": 0.2, "damage": 2.0, "stun": 0.2},
     "无光海结冰的那一夜，每张脸都被冻在了别人的倒影里。"),
    ("ya", "♠", "鸦", NOUN, ["shadow", "feather"], 2, 1,
     {"damage": 1.0, "projectiles": 4.0, "homing": 0.8, "corruption_gain": 1.0},
     "档案馆屋檐下住着一群鸦，它们只吃被划掉的名字。"),
    # --- verbs: the new mechanics, each one visible in combat ---
    ("zhuilie", "⇢", "追猎", VERB, ["movement", "eye"], 2, 0,
     {"damage": 1.0, "homing": 1.0, "projectiles": 2.0},
     "咕噜卖过一句咒语：说出它的人，猎物会自己转身。"),
    ("guanchuan", "↠", "贯穿", VERB, ["sight"], 2, 0,
     {"damage": 2.0, "pierce": 2.0},
     "闻烬的笔尖曾经一口气划穿七份档案。"),
    ("baolie", "☸", "爆裂", VERB, ["flame", "chaos"], 3, 1,
     {"damage": 2.0, "explosion": 1.2},
     "被压得太死的句子，总有一天会自己炸开。"),
    ("dingshen", "⚓", "定身", VERB, ["silence", "time"], 2, 0,
     {"stun": 0.8, "slow": 0.1},
     "陆沉教昌子的第一句咒：念到第三个字，对方就忘了怎么动。"),
    ("tansuo", "◍", "坍缩", VERB, ["space", "time"], 3, 1,
     {"pull": 1.5, "slow": 0.15, "damage": 1.0},
     "白榆说，走不完的路最后都会坍成一个点。"),
    ("zhentui", "⇉", "震退", VERB, ["earth", "sound"], 2, 0,
     {"damage": 1.0, "knockback": 2.5},
     "阿砚的铁锤落在砧上，整条街的灰都会往后退一步。"),
    ("lianhuan", "⇄", "连环", VERB, ["multi"], 2, 0,
     {"damage": 1.0, "pulses": 1.0},
     "一句话说两遍，世界就会以为它是真的。"),
    ("suolian", "⛓", "锁链", VERB, ["thunder", "order"], 3, 0,
     {"damage": 1.0, "chain": 3.0, "stun": 0.3},
     "名册的每一页都用锁链扣着，扣得最牢的是空白页。"),
    ("zhuiluo", "☄", "坠落", VERB, ["star", "final"], 3, 0,
     {"damage": 3.0, "explosion": 0.8},
     "每一颗星坠落之前，都要先被谁从天空里划掉。"),
    ("liekai", "↯", "裂开", VERB, ["earth", "abyss"], 2, 1,
     {"damage": 2.0, "knockback": 1.0, "corruption_gain": 1.0},
     "地面裂开的声音，和书脊裂开的声音一模一样。"),
    ("shouwang", "☖", "守望", VERB, ["shield", "archive"], 2, 0,
     {"shield": 4.0, "heal": 1.0},
     "守夜人不需要被记住，只需要一直醒着。"),
    ("qiyue", "✉", "契约", VERB, ["blood", "order"], 2, 1,
     {"damage": 2.0, "lifesteal": 0.15, "stun": 0.2},
     "闻烬签过的每一份契约，最后一行都写着她自己的名字。"),
    ("chongxie", "↺", "重写", VERB, ["reverse", "archive"], 2, 1,
     {"damage": 2.0, "slow": 0.2},
     "改写记录比杀人更彻底。闻烬说这句话时没有笑。"),
    # --- modifiers ---
    ("wanqian", "〓", "万千", MODIFIER, ["multi", "scale"], 3, 0,
     {"damage": 1.0, "projectiles": 4.0},
     "咕噜的口头禅：一个不够，就再要一万个。"),
    ("buxi", "⌛", "不息", MODIFIER, ["time", "life", "flame"], 2, 0,
     {"duration": 2.0, "heal": 1.0, "burn": 2.0},
     "肺钟停下以后，城里的炉火第一次学会了不必呼吸也能烧。"),
    ("ruili", "⚔", "锐利", MODIFIER, ["first"], 2, 0,
     {"damage": 3.0},
     "阿砚磨刀从不用水，他用的是名字。"),
    ("kuangluan", "☈", "狂乱", MODIFIER, ["chaos", "movement"], 2, 2,
     {"damage": 2.0, "move_speed": 0.2, "corruption_gain": 2.0},
     "读到超出容量的句子时，人会先笑，后来开始跑。"),
    ("kongbai", "▢", "空白", MODIFIER, ["nameless", "void"], 2, 1,
     {"damage": 2.0, "corruption_gain": 1.0, "stun": 0.3},
     "空白人没有脸，他们的脸都被写进了别人的档案。"),
    ("mingliang", "☀", "明亮", MODIFIER, ["light", "holy"], 2, 0,
     {"damage": 1.0, "pierce": 1.0, "heal": 1.0},
     "最后的读者说，光不是照亮，是把影子钉在地上。"),
    ("yuangu", "♄", "远古", MODIFIER, ["first", "memory"], 2, 0,
     {"damage": 2.0, "duration": 1.0},
     "比档案馆更早的东西没有人记得，所以它什么都记得。"),
]


def tres(word: tuple) -> str:
    wid, glyph, meaning, role, tags, power, corruption, components, description = word
    tag_text = ", ".join(f'&"{tag}"' for tag in tags)
    comp_lines = ",\n".join(f'&"{key}": {float(value)}' for key, value in components.items())
    return (
        '[gd_resource type="Resource" script_class="WordData" format=3]\n\n'
        '[ext_resource type="Script" path="res://scripts/data/word_data.gd" id="1_w"]\n\n'
        "[resource]\n"
        'script = ExtResource("1_w")\n'
        f'id = &"{wid}"\n'
        f'glyph = "{glyph}"\n'
        f'phoneme = "{wid}"\n'
        f'meaning = "{meaning}"\n'
        f"grammar_role = {role}\n"
        f"tags = Array[StringName]([{tag_text}])\n"
        f"power = {power}\n"
        f"corruption = {corruption}\n"
        "decoded = true\n"
        "components = Dictionary[StringName, float]({\n"
        f"{comp_lines}\n"
        "})\n"
        f'description = "{description}"\n'
    )


def font_missing(texts: list[str]) -> set[str]:
    try:
        from fontTools.ttLib import TTFont
    except ImportError:
        print("fontTools not installed; skipping glyph coverage check")
        return set()
    cmap = TTFont(str(FONT)).getBestCmap()
    return {ch for text in texts for ch in text if not ch.isspace() and ord(ch) not in cmap}


def register_all(check_only: bool) -> list[str]:
    source = LIBRARY.read_text(encoding="utf-8")
    block = re.search(r"const WORDS: Array\[Resource\] = \[\n(.*?)\n\]", source, re.S)
    if block is None:
        raise SystemExit("WORDS block not found in content_library.gd")
    listed = re.findall(r'res://resources/words/([a-z0-9_]+)\.tres', block.group(1))
    on_disk = sorted(path.stem for path in WORDS_DIR.glob("*.tres"))
    missing = [wid for wid in on_disk if wid not in listed]
    if missing and not check_only:
        extra = "".join(f'\n\tpreload("res://resources/words/{wid}.tres"),' for wid in missing)
        updated = source[: block.end(1)] + extra + source[block.end(1):]
        LIBRARY.write_text(updated, encoding="utf-8", newline="\n")
    return missing


def main() -> None:
    check_only = "--check" in sys.argv
    ids = [word[0] for word in WORDS]
    duplicates = {wid for wid in ids if ids.count(wid) > 1}
    if duplicates:
        raise SystemExit(f"duplicate ids: {sorted(duplicates)}")
    texts = [w[1] for w in WORDS] + [w[2] for w in WORDS] + [w[8] for w in WORDS]
    missing_glyphs = font_missing(texts)
    if missing_glyphs:
        print("characters missing from the pixel font:", "".join(sorted(missing_glyphs)))
    written = 0
    for word in WORDS:
        path = WORDS_DIR / f"{word[0]}.tres"
        content = tres(word)
        if path.exists() and path.read_text(encoding="utf-8") == content:
            continue
        if not check_only:
            path.write_text(content, encoding="utf-8", newline="\n")
        written += 1
    registered = register_all(check_only)
    total = len(list(WORDS_DIR.glob("*.tres")))
    verb = "would write" if check_only else "wrote"
    print(f"{verb} {written} word files; registered {len(registered)} new; {total} words on disk")


if __name__ == "__main__":
    main()
