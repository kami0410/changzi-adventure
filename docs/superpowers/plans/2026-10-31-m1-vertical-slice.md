# 昌子大冒险 M1 垂直切片 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 `games/changzi-adventure` 交付一个 15–20 分钟可玩的 M1 垂直切片：1 个 Hub、2 个生态区、1 个 Boss，语言/构筑/横版战斗闭环，Windows 与 Android 可导出。

**Architecture:** Godot 4.7.2 + GDScript，2D/GL Compatibility。内容用自定义 `Resource`（词/短语/武器/遗物/敌人/掉落表）数据驱动；运行时由 `RunState` + `Inventory` + `LanguageSystem` 组合；场景按 player/enemies/levels/ui/hub/bosses 拆分；测试用 `SceneTree` 无头 runner，不引第三方测试框架。

**Tech Stack:** Godot 4.7.2 stable、GDScript、Godot Resource、TileMapLayer、CharacterBody2D、AudioServer。

**Spec:** `games/changzi-adventure/docs/GDD.md`

## Global Constraints

- 引擎固定 `tools/godot/Godot_v4.7.2-stable_win64_console.exe`；标准版，GDScript，不用 C#/.NET。
- 2D + GL Compatibility；原生 1280×720；角色 96×96、Boss 256×256、tile 32×32（M1 允许占位几何体）。
- 美术风格：高精度像素；M1 用占位色块/简单 sprite 验证玩法，不追求最终美术。
- 数据驱动：词、短语、武器、遗物、敌人、掉落表全部用 `Resource`；场景里不硬编码内容数值。
- 随机：每局使用 `RandomNumberGenerator` + run seed；不用全局 `randi()` 决定内容。
- 信号用过去式（`died`、`health_changed`）；脚本尽量静态类型。
- 测试命令（每次先 import）：
  ```bash
  tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path games/changzi-adventure --import
  tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path games/changzi-adventure --script res://tests/run_tests.gd
  ```
- 每个 Task 结束必须提交；不提交 `.godot/`、`build/`、`*.keystore`。
- 不直接修改第三方技能文件。
- 内容目标：6 武器、8 短语、12 词 + 8 遗物、5 普通敌人 + 1 精英、1 Boss、2 生态区、1 Hub、3 个可交互 NPC。

## Review Focus

- 语言组合：0/1 个词、重复词、未知词、已解码/未解码混用时的返回值。
- 污染阈值：25/50/75/100 的边界与信号只触发一次。
- 种子确定性：同一 seed + 同一 biome 必须生成同一房间序列。
- 暂停：`process_mode` 与输入在暂停时是否仍然可控；恢复后不重复触发。
- 存档：profile 保存/读取 roundtrip，版本字段缺失时的回退。
- 投射物：高速投射物是否穿透（M1 用 Area2D + 手动扫掠或合理速度上限）。
- UI：1280×720 与 Android 宽高比下 HUD/背包不重叠、不裁切。
- 导出：Android ETC2/ASTC 已开启；APK 包名与 targetSdk 正确。

---

## v0.2 决策修订（2026-10-31）

> 以 `docs/GDD-v0.2-decisions.md` 为准；以下覆盖旧任务描述。

- **Task 2**：`WordData` 增加 `grammar_role: GrammarRole`、`power: int`、`components: Dictionary[StringName, float]`；新增运行时 `ResolvedPhrase`。`PhraseData` 只保留为示例/图鉴配方。
- **Task 3**：`LanguageSystem` 改为 `PhraseResolver`；自由造句，2–3 个词，按句式/标签/components 解析；0/1 词、重复词、角色不匹配、未知词、冲突标签都要有明确结果。
- **Task 8**：`LevelGenerator` 改为 `BiomeAssembler`；连续 chunk 拼接，不是节点地图；seed 控制 chunk 顺序/敌人/掉落/商店。
- **Task 9/10**：新增 `SentenceForgeUI`（造句台）；Codex 显示已发现组合与未知词。
- **Task 11**：完整 Hub + 基底升级；陆沉/阿砚/咕噜三个功能 NPC；织录者/守钟人占位。
- **Task 13**：`Profile` 增加 `weapon_base_levels`、`unlocked_patterns`、`discovered_phrases`。
- **Task 14**：12 词（4 NOUN / 4 VERB / 4 MODIFIER）、8 条示例短语；加自由组合矩阵测试。
- **美术**：全员完整动画由 `docs/superpowers/plans/2026-10-31-pixel-art-production.md` 跟踪；代码先用占位 `SpriteFrames`。
- **其他**：第一区精英后 4 选 1 权柄；Boss 用墨骸史官，笑面史官只做过场；Android M1 只验收构建 + 启动。

### Task 1: 项目骨架与无头测试 runner

**Files:**
- Create: `games/changzi-adventure/tests/run_tests.gd`
- Create: `games/changzi-adventure/tests/test_smoke.gd`
- Copy/adapt from `templates/game_project/`:
  - `project.godot`、`export_presets.cfg`、`icon.svg`、`icon.svg.import`
  - `scenes/main.tscn`、`scenes/player/player.tscn`、`scenes/enemies/dummy_enemy.tscn`、`scenes/ui/hud.tscn`
  - `scripts/game.gd`、`scripts/player.gd`、`scripts/dummy_enemy.gd`、`scripts/hud.gd`
  - `CLAUDE.md`
- Create dirs: `scripts/{core,combat,data,enemies,levels,language,ui,hub,bosses,audio}`、`assets/{sprites,audio,fonts,concept}`、`resources/{words,phrases,weapons,relics,enemies,dialogue,bosses}`

**Interfaces:**
- Consumes: none.
- Produces: `tests/run_tests.gd` runner; test scripts implement `func run(t: Callable) -> void`，`t.call(actual, expected, label)` 断言。
- Produces: `project.godot` 输入动作 `move_left/right/up/down`、`jump`、`attack`、`dodge`、`pause`、`interact`、`restart`。

- [ ] **Step 1: 复制模板并替换占位符**

只复制 Godot 工程文件，不覆盖已有的 `README.md`、`docs/GDD.md`、`docs/memory/`、`assets/references/`、`assets/concept/`。把 `project.godot` 的 `config/name` 改为 `昌子大冒险`，把 `export_presets.cfg` 的 `__GAME_SLUG__` 改为 `changzi-adventure`、`__PACKAGE_SLUG__` 改为 `changzi_adventure`、`__GAME_NAME__` 改为 `昌子大冒险`，`CLAUDE.md` 同样替换。

- [ ] **Step 2: 写测试 runner 与 smoke test**

`tests/run_tests.gd`：

```gdscript
extends SceneTree

var passed := 0
var failed := 0
var _check := Callable()

const TESTS := [
    preload("res://tests/test_smoke.gd"),
]

func _initialize() -> void:
    _check = func(actual, expected, label): _assert_eq(actual, expected, label)
    for script in TESTS:
        var test = script.new()
        test.run(_check)
    print("Results: %d passed, %d failed" % [passed, failed])
    quit(1 if failed > 0 else 0)

func _assert_eq(actual, expected, label: String) -> void:
    if actual == expected:
        passed += 1
    else:
        failed += 1
        push_error("FAIL %s: expected %s, got %s" % [label, expected, actual])
```

`tests/test_smoke.gd`：

```gdscript
extends RefCounted

func run(t: Callable) -> void:
    t.call(1 + 1, 2, "smoke_math")
```

- [ ] **Step 3: 运行 import 与测试**

```bash
tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path games/changzi-adventure --import
tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path games/changzi-adventure --script res://tests/run_tests.gd
```

Expected: `Results: 1 passed, 0 failed`，退出码 0。

- [ ] **Step 4: 提交**

```bash
git -C games/changzi-adventure add .
git -C games/changzi-adventure commit -m "chore: scaffold Changzi adventure Godot project and test runner" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 2: 核心数据 Resource

**Files:**
- Create: `scripts/data/word_data.gd`、`phrase_data.gd`、`weapon_data.gd`、`relic_data.gd`、`enemy_data.gd`、`drop_entry.gd`、`drop_table.gd`
- Test: `tests/test_data.gd`
- Modify: `tests/run_tests.gd` 的 `TESTS` 加 `preload("res://tests/test_data.gd")`

**Interfaces:**
- `WordData`：`id: StringName`、`glyph: String`、`phoneme: String`、`meaning: String`、`tags: Array[StringName]`、`corruption: int`、`decoded: bool`、`description: String`
- `PhraseData`：`id`、`display_name`、`word_ids: Array[StringName]`、`tags`、`ink_cost: int`、`cooldown: float`、`effect_id: StringName`、`description`
- `WeaponData`：`enum Kind { MELEE, RANGED }`；`id`、`display_name`、`kind: Kind`、`damage: int`、`attack_cooldown: float`、`range: float`、`projectile_speed: float`、`word_slots: int = 2`、`tags`
- `RelicData`：`id`、`display_name`、`tags`、`corruption: int`、`description`、`effect_id`
- `EnemyData`：`id`、`display_name`、`max_health: int`、`speed: float`、`contact_damage: int`、`behavior: StringName`、`loot_table: DropTable`
- `DropEntry`：`id: StringName`、`weight: float`
- `DropTable.roll(rng: RandomNumberGenerator) -> StringName`

- [ ] **Step 1: 写失败测试**

`tests/test_data.gd`：

```gdscript
extends RefCounted

func run(t: Callable) -> void:
    var word := WordData.new()
    word.id = &"gr"
    word.tags = [&"life"]
    t.call(word.tags.has(&"life"), true, "word_tags")

    var phrase := PhraseData.new()
    phrase.word_ids = [&"grguan", &"gr"]
    t.call(phrase.word_ids.size(), 2, "phrase_word_count")

    var weapon := WeaponData.new()
    t.call(weapon.word_slots, 2, "weapon_default_slots")
    t.call(weapon.kind, WeaponData.Kind.MELEE, "weapon_default_kind")

    var table := DropTable.new()
    var entry := DropEntry.new()
    entry.id = &"word_gr"
    entry.weight = 1.0
    table.entries = [entry]
    var rng := RandomNumberGenerator.new()
    rng.seed = 42
    t.call(table.roll(rng), &"word_gr", "drop_table_single")
```

- [ ] **Step 2: 运行测试确认失败**

Run: test command.
Expected: FAIL，`WordData` 等类型未定义。

- [ ] **Step 3: 实现 Resource 类**

按 Interfaces 定义 `class_name` 与 `@export` 字段。`DropTable.roll` 用权重累加 + `rng.randf()`；空表返回 `&""`。

- [ ] **Step 4: 运行测试确认通过**

Expected: `Results: N passed, 0 failed`。

- [ ] **Step 5: 提交**

```bash
git -C games/changzi-adventure add scripts/data tests/test_data.gd tests/run_tests.gd
git -C games/changzi-adventure commit -m "feat: add core data resources" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 3: LanguageSystem（解码与组合）

**Files:**
- Create: `scripts/language/language_system.gd`
- Test: `tests/test_language.gd`
- Modify: `tests/run_tests.gd` 加 test_language

**Interfaces:**
- `class_name LanguageSystem extends RefCounted`
- `var decoded: Dictionary[StringName, bool]`
- `func decode(word: WordData) -> void`
- `func is_decoded(id: StringName) -> bool`
- `func display_name(word: WordData) -> String`
- `func combine(words: Array[WordData]) -> PhraseData`：2–3 个词，按排序后的 `word_ids` 匹配已注册配方；0/1 个词、重复词、未知词返回 `null`。
- `func register_recipe(phrase: PhraseData) -> void`

- [ ] **Step 1: 写失败测试**

覆盖：未解码时 `display_name` 返回 glyph；`decode` 后返回 meaning；`combine([grguan, gr])` 返回对应 PhraseData；1 个词返回 null；重复词返回 null；未注册组合返回 null。

- [ ] **Step 2: 运行确认失败**
- [ ] **Step 3: 实现 LanguageSystem**

配方 key 用排序后的 `id` 拼接，例如 `"gr|grguan"`。`display_name` 未解码返回 `word.glyph`，已解码返回 `word.meaning`。

- [ ] **Step 4: 运行确认通过**
- [ ] **Step 5: 提交**

---

### Task 4: RunState 与 Inventory

**Files:**
- Create: `scripts/core/run_state.gd`、`scripts/core/inventory.gd`
- Test: `tests/test_run_state.gd`
- Modify: `tests/run_tests.gd`

**Interfaces:**
- `RunState extends RefCounted`：`signal corruption_changed(value: int)`、`signal ink_changed(value: int)`、`signal health_changed(current: int, maximum: int)`；`seed: int`、`rng: RandomNumberGenerator`、`health/max_health/ink/max_ink/corruption`、`inventory: Inventory`；`func reset_for_new_run(seed: int) -> void`、`func add_corruption(amount: int) -> void`、`func spend_ink(amount: int) -> bool`。
- `Inventory extends RefCounted`：`signal changed`；`weapons: Array[WeaponData]`（2 槽）、`phrases: Array[PhraseData]`（2 槽）、`relics: Array[RelicData]`、`words: Array[WordData]`；`func equip_weapon(slot: int, weapon: WeaponData) -> bool`、`func equip_phrase(slot: int, phrase: PhraseData) -> bool`、`func add_relic(relic: RelicData) -> bool`、`func add_word(word: WordData) -> void`、`func total_corruption() -> int`。

- [ ] **Step 1: 写失败测试**

覆盖：新 run seed 123 → health 100/ink 100/corruption 0；`add_corruption(25)` 发一次 `corruption_changed(25)`；`spend_ink(120)` 返回 false；`equip_weapon(0, w)` 返回 true 且 `weapons[0] == w`；`equip_weapon(2, w)` 返回 false；`add_relic` 后 `total_corruption()` 增加。
- [ ] **Step 2: 运行确认失败**
- [ ] **Step 3: 实现 RunState/Inventory**
- [ ] **Step 4: 运行确认通过**
- [ ] **Step 5: 提交**

---

### Task 5: Damageable 与 Player 控制器

**Files:**
- Create: `scripts/combat/damageable.gd`、`scripts/player/player.gd`
- Modify: `scenes/player/player.tscn`（替换模板玩家）
- Test: `tests/test_combat.gd`
- Modify: `tests/run_tests.gd`

**Interfaces:**
- `Damageable extends Node`：`signal health_changed(current: int, maximum: int)`、`signal died`；`max_health: int = 10`、`health: int`；`func take_damage(amount: int) -> void`、`func heal(amount: int) -> void`。
- `Player extends CharacterBody2D`：`signal health_changed(current: int, maximum: int)`、`signal died`；`move_speed: float = 260.0`、`jump_velocity: float = -420.0`、`dodge_speed: float = 520.0`、`dodge_duration: float = 0.18`、`max_health: int = 100`、`health: int`、`is_dodging: bool`；`func take_damage(amount: int) -> void`、`func heal(amount: int) -> void`、`func start_dodge() -> void`。

- [ ] **Step 1: 写失败测试**

`Damageable`：10 → take 3 → 7；heal 5 → 10；take 20 → 0 且 `died` 只发一次。`Player.start_dodge()` 后 `is_dodging == true`，`dodge_duration` 后恢复 false（用 timer/await 测试）。
- [ ] **Step 2: 运行确认失败**
- [ ] **Step 3: 实现 Damageable 与 Player**

Player 用 `Input.get_axis`、`Input.is_action_just_pressed("jump")`、`move_and_slide`；翻滚给 i-frames；场景用占位 `Polygon2D`。
- [ ] **Step 4: 运行测试 + 手动运行主场景**

手动确认移动/跳跃/翻滚无报错。
- [ ] **Step 5: 提交**

---

### Task 6: 武器、攻击与投射物

**Files:**
- Create: `scripts/combat/weapon.gd`、`melee_weapon.gd`、`ranged_weapon.gd`、`projectile.gd`
- Create: `scenes/combat/hitbox.tscn`、`scenes/combat/projectile.tscn`
- Create: `resources/weapons/` 6 个 `.tres`
- Test: `tests/test_weapons.gd`
- Modify: `tests/run_tests.gd`

**Interfaces:**
- `Weapon extends Node2D`：`signal hit(target: Node)`；`data: WeaponData`、`cooldown_left: float`；`func can_attack() -> bool`、`func try_attack() -> bool`、`func apply_hit(target: Node) -> void`。
- `MeleeWeapon`/`RangedWeapon` 继承 Weapon。
- `Projectile extends Area2D`：`speed: float`、`damage: int`、`direction: Vector2`；命中后 `queue_free()`。

- [ ] **Step 1: 写失败测试**

覆盖：武器初始可攻击；`try_attack()` 后 `can_attack()` false；冷却推进后 true；`apply_hit` 对带 `take_damage` 的节点造成伤害；6 个武器资源可加载且 `word_slots >= 0`。
- [ ] **Step 2: 运行确认失败**
- [ ] **Step 3: 实现 Weapon/Melee/Ranged/Projectile + 6 个资源**
- [ ] **Step 4: 运行确认通过 + 手动场景测试**
- [ ] **Step 5: 提交**

---

### Task 7: 敌人与 AI

**Files:**
- Create: `scripts/enemies/enemy.gd`、`melee_enemy.gd`、`ranged_enemy.gd`、`charger_enemy.gd`、`flyer_enemy.gd`、`elite_enemy.gd`
- Create: `scenes/enemies/` 5 个普通敌人 + 1 精英场景
- Create: `resources/enemies/` 6 个 `.tres`
- Test: `tests/test_enemies.gd`
- Modify: `tests/run_tests.gd`

**Interfaces:**
- `Enemy extends CharacterBody2D`：`signal died(enemy: Enemy)`；`data: EnemyData`、`health: int`、`state: StringName`、`target: Node2D`；`func take_damage(amount: int) -> void`、`func set_target(target: Node2D) -> void`、`func change_state(next: StringName) -> void`。
- 状态：`idle`、`chase`、`attack`、`dead`；M1 用简单距离阈值，不引入行为树。

- [ ] **Step 1: 写失败测试**

覆盖：take_damage 减血、0 血发 died；`set_target` 在 aggro 范围内从 idle → chase；6 个敌人资源可加载。
- [ ] **Step 2: 运行确认失败**
- [ ] **Step 3: 实现 Enemy + 子类 + 资源**
- [ ] **Step 4: 运行确认通过 + 手动场景测试**
- [ ] **Step 5: 提交**

---

### Task 8: 房间与关卡生成

**Files:**
- Create: `scripts/levels/room.gd`、`scripts/levels/level_generator.gd`
- Create: `scenes/levels/room.tscn`、`scenes/levels/biome_1.tscn`、`scenes/levels/biome_2.tscn`
- Create: `resources/tilesets/placeholder.tres`
- Test: `tests/test_level_gen.gd`
- Modify: `tests/run_tests.gd`

**Interfaces:**
- `LevelGenerator extends RefCounted`：`func generate(seed: int, biome: StringName, room_count: int) -> Array[StringName]`。
- `Room extends Node2D`：`signal cleared`；`room_id: StringName`、`door_targets: Dictionary`；`func spawn_enemies(enemy_ids: Array[StringName]) -> void`、`func is_cleared() -> bool`。

- [ ] **Step 1: 写失败测试**

覆盖：同 seed + 同 biome 生成同一数组；不同 seed 生成不同数组；数组长度 = room_count；所有 id 属于该 biome 的池。
- [ ] **Step 2: 运行确认失败**
- [ ] **Step 3: 实现 LevelGenerator/Room + 2 个占位 biome 场景**
- [ ] **Step 4: 运行确认通过 + 手动走门**
- [ ] **Step 5: 提交**

---

### Task 9: HUD、背包与暂停

**Files:**
- Create: `scripts/ui/hud.gd`、`scripts/ui/inventory_ui.gd`、`scripts/ui/pause_menu.gd`
- Create: `scenes/ui/hud.tscn`、`scenes/ui/inventory_ui.tscn`、`scenes/ui/pause_menu.tscn`
- Test: `tests/test_ui.gd`
- Modify: `tests/run_tests.gd`

**Interfaces:**
- `HUD extends CanvasLayer`：`func bind_run_state(run: RunState) -> void`、`func show_message(text: String) -> void`。
- `InventoryUI extends Control`：`func bind(inventory: Inventory) -> void`、`func equip_weapon(slot: int, weapon: WeaponData) -> bool`。
- `PauseMenu extends CanvasLayer`：`func toggle() -> void`。

- [ ] **Step 1: 写失败测试**

覆盖：HUD 绑定后 HP/墨量/污染标签随信号更新；InventoryUI.equip_weapon 调用 Inventory；PauseMenu.toggle 切换 `get_tree().paused`。
- [ ] **Step 2: 运行确认失败**
- [ ] **Step 3: 实现 UI 场景与脚本**
- [ ] **Step 4: 运行确认通过 + 手动检查 1280×720**
- [ ] **Step 5: 提交**

---

### Task 10: 语言图鉴 UI

**Files:**
- Create: `scripts/ui/codex_ui.gd`、`scenes/ui/codex.tscn`
- Test: `tests/test_codex.gd`
- Modify: `tests/run_tests.gd`

**Interfaces:**
- `CodexUI extends Control`：`func bind(language: LanguageSystem, run: RunState) -> void`、`func refresh() -> void`。

- [ ] **Step 1: 写失败测试**

覆盖：未解码词显示 glyph；解码后显示 meaning；已发现配方出现在列表；配方数量与注册数一致。
- [ ] **Step 2: 运行确认失败**
- [ ] **Step 3: 实现 CodexUI**
- [ ] **Step 4: 运行确认通过 + 手动检查**
- [ ] **Step 5: 提交**

---

### Task 11: Hub、NPC、对话与商店

**Files:**
- Create: `scripts/hub/hub.gd`、`scripts/hub/npc.gd`、`scripts/hub/dialogue_data.gd`、`scripts/hub/shop.gd`
- Create: `scenes/hub/hub.tscn`、`scenes/hub/npc.tscn`、`scenes/ui/dialogue_ui.tscn`
- Create: `resources/dialogue/` 3 个 `.tres`（陆沉/阿砚/咕噜）
- Test: `tests/test_hub.gd`
- Modify: `tests/run_tests.gd`

**Interfaces:**
- `NPC extends Area2D`：`signal interacted(npc: NPC)`；`npc_id: StringName`、`dialogue: DialogueData`；`func interact() -> void`。
- `DialogueData extends Resource`：`lines: Array[String]`；`func line_at(index: int) -> String`。
- `Shop`：`func buy(item_id: StringName, profile: Profile) -> bool`。
- 3 个 NPC：陆沉（解码词）、阿砚（升级武器）、咕噜（买词）。

- [ ] **Step 1: 写失败测试**

覆盖：对话索引前进/回绕；商店购买扣记忆碎片；碎片不足返回 false；陆沉解码后 `LanguageSystem.is_decoded` 为 true。
- [ ] **Step 2: 运行确认失败**
- [ ] **Step 3: 实现 Hub/NPC/Dialogue/Shop + 3 个 NPC 场景**
- [ ] **Step 4: 运行确认通过 + 手动对话/购买**
- [ ] **Step 5: 提交**

---

### Task 12: Boss 墨骸史官

**Files:**
- Create: `scripts/bosses/ink_archivist.gd`
- Create: `scenes/bosses/ink_archivist.tscn`、`scenes/levels/boss_room.tscn`
- Create: `resources/bosses/ink_archivist.tres`
- Test: `tests/test_boss.gd`
- Modify: `tests/run_tests.gd`

**Interfaces:**
- `InkArchivist extends Enemy`：`signal phase_changed(phase: int)`；`phase: int`；`func check_phase() -> void`；三阶段：100–67%、66–34%、33–0%。
- 攻击：`page_wave`、`ink_rain`、`rewrite`（临时禁用玩家一个短语槽）。

- [ ] **Step 1: 写失败测试**

覆盖：HP 67% 进入 phase 2，34% 进入 phase 3，阶段信号只发一次；死亡发 died；`rewrite` 调用后目标槽位短暂禁用。
- [ ] **Step 2: 运行确认失败**
- [ ] **Step 3: 实现 Boss + Boss 房间**
- [ ] **Step 4: 运行确认通过 + 手动打一场**
- [ ] **Step 5: 提交**

---

### Task 13: GameFlow 与 Profile 存档

**Files:**
- Create: `scripts/core/game_flow.gd`、`scripts/core/profile.gd`
- Test: `tests/test_flow.gd`
- Modify: `project.godot` 加 autoload `GameFlow`、`Profile`
- Modify: `tests/run_tests.gd`

**Interfaces:**
- `GameFlow extends Node`：`func start_run(seed: int = 0) -> RunState`、`func end_run(victory: bool) -> void`、`func return_to_hub() -> void`。
- `Profile extends Node`：`memory_fragments: int`、`unlocked_words: Array[StringName]`；`func save(path: String = "user://profile.cfg") -> void`、`func load(path: String = "user://profile.cfg") -> void`。

- [ ] **Step 1: 写失败测试**

覆盖：Profile save/load roundtrip（临时 `user://test_profile.cfg`）；缺失版本字段时回退默认值；`start_run` 重置 health/ink/corruption；`end_run(true)` 增加记忆碎片。
- [ ] **Step 2: 运行确认失败**
- [ ] **Step 3: 实现 GameFlow/Profile**
- [ ] **Step 4: 运行确认通过 + 手动 Hub→Run→Boss→Hub**
- [ ] **Step 5: 提交**

---

### Task 14: 内容填充与校验

**Files:**
- Create: `resources/words/` 12 个 `.tres`
- Create: `resources/relics/` 8 个 `.tres`
- Create: `resources/phrases/` 8 个 `.tres`
- Create: `resources/weapons/` 补齐 6 个
- Create: `resources/enemies/` 补齐 5 + 1 精英
- Test: `tests/test_content.gd`
- Modify: `tests/run_tests.gd`

**Interfaces:**
- 内容计数：12 words + 8 relics = 20；8 phrases；6 weapons（3 melee/3 ranged）；5 enemies + 1 elite；1 boss。

- [ ] **Step 1: 写失败测试**

覆盖：所有资源可加载；短语的 `word_ids` 都存在于 12 个词中；武器 `word_slots >= 0`；敌人 `loot_table` 非空；计数达到目标；Boss 资源存在。
- [ ] **Step 2: 运行确认失败**
- [ ] **Step 3: 填 12 词/8 遗物/8 短语/6 武器/5+1 敌人**
- [ ] **Step 4: 运行确认通过**
- [ ] **Step 5: 提交**

---

### Task 15: 音频、命中反馈与基础手感

**Files:**
- Create: `default_bus_layout.tres`（Master/Music/SFX/UI）
- Create: `scripts/audio/audio_manager.gd`（autoload）
- Create: `scripts/combat/hit_stop.gd`
- Create: `scenes/vfx/hit_particles.tscn`
- Test: `tests/test_audio.gd`
- Modify: `project.godot` 加 autoload `AudioManager`
- Modify: `tests/run_tests.gd`

**Interfaces:**
- `AudioManager extends Node`：`func play_sfx(id: StringName) -> void`、`func set_music_layer(layer: int) -> void`。
- `HitStop`：`func freeze(duration: float, time_scale: float = 0.05) -> void`，结束后恢复 `Engine.time_scale = 1.0`。

- [ ] **Step 1: 写失败测试**

覆盖：`AudioServer.get_bus_index("Music") >= 0`、`"SFX"`、`"UI"`；HitStop 冻结后恢复；AudioManager 播放未知 id 不崩溃。
- [ ] **Step 2: 运行确认失败**
- [ ] **Step 3: 实现音频总线/管理器/命中反馈**
- [ ] **Step 4: 运行确认通过 + 手动手感检查**
- [ ] **Step 5: 提交**

---

### Task 16: 双平台导出、文档与记忆更新

**Files:**
- Modify: `README.md`、`docs/GDD.md`（状态从 v0.1 改为 M1 已实现）
- Create: `docs/memory/sessions/2026-10-31-m1-vertical-slice.md`
- Modify: `docs/memory/MEMORY.md` 索引
- Test: 导出产物

- [ ] **Step 1: 无头检查与测试**

```bash
powershell -ExecutionPolicy Bypass -File scripts/check_game.ps1 -Game changzi-adventure
powershell -ExecutionPolicy Bypass -File scripts/export_game.ps1 -Game changzi-adventure -Platform All
```

Expected: 检查通过；`build/windows/changzi-adventure.exe` 与 `build/android/changzi-adventure.apk` 存在。

- [ ] **Step 2: 校验 APK**

```bash
"D:/Android/Sdk/build-tools/36.0.0/aapt.exe" dump badging games/changzi-adventure/build/android/changzi-adventure.apk | head -5
```

Expected: `package: name='com.gamecreatestudio.changzi_adventure'`、`targetSdkVersion:'36'`。

- [ ] **Step 3: 启动 Windows build**

```bash
./games/changzi-adventure/build/windows/changzi-adventure.exe --headless --quit-after 240
```

Expected: 退出码 0，无 `SCRIPT ERROR`。

- [ ] **Step 4: 更新文档与记忆**

写 M1 session 总结；更新 GDD 状态；更新 README 的 M1 内容；更新记忆索引。

- [ ] **Step 5: 提交**

```bash
git -C games/changzi-adventure add .
git -C games/changzi-adventure commit -m "feat: complete M1 vertical slice" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

## Self-Review

- **Spec coverage:** GDD §6 核心循环（Task 13）、§7 语言（Task 2/3/10）、§8 战斗（Task 5/6/7/12）、§9 道具（Task 2/4/14）、§10 单局/Hub（Task 8/11/13）、§11 生态区（Task 8）、§12 叙事（Task 11/12/16）、§13 美术（Task 1/16）、§14 音频（Task 15）、§15 UI（Task 9/10）、§16 技术约束（Global Constraints/Task 1/16）、§17 范围（Task 14）、§18 非目标（Global Constraints）、§19 里程碑（本计划 = M1）。
- **Task right-sizing:** 每个 Task 有独立可测交付物；测试先失败再实现。
- **Type consistency:** `RunState`、`Inventory`、`LanguageSystem`、`WeaponData`、`EnemyData` 的字段与后续 Task 引用一致。
- **Review Focus coverage:** 语言边界（Task 3）、污染边界（Task 4）、种子（Task 8）、暂停（Task 9）、存档（Task 13）、投射物（Task 6）、UI（Task 9）、导出（Task 16）。
- **Proportion:** 计划约 400 行，GDD 约 350 行；以接口/测试为主，没有替实现者写完整函数体。
