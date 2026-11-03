class_name BiomeAssembler
extends RefCounted

## 用 run seed 组装一条连续横版生态区。
## chunk 内部由手工场景实现；这里只决定 chunk 的顺序与分支位置，
## 因此同一个 seed + biome 会得到完全相同的 BiomeLayout。

const DEFAULT_BIOME: StringName = &"ink_archive"

const BIOME_DATA: Dictionary = {
	&"ink_archive": {
		&"entrance": &"ink_archive_gate",
		&"combat": [
			&"ink_archive_stacks",
			&"ink_archive_reading_hall",
			&"ink_archive_ink_pool",
			&"ink_archive_broken_index",
		],
		&"rest": &"ink_archive_rest_nook",
		&"boss": &"ink_archive_boss",
	},
	&"breathing_ruins": {
		&"entrance": &"breathing_ruins_outskirts",
		&"combat": [
			&"breathing_ruins_collapsed_street",
			&"breathing_ruins_lung_hall",
			&"breathing_ruins_hanging_bridge",
			&"breathing_ruins_sunken_plaza",
		],
		&"rest": &"breathing_ruins_camp",
		&"boss": &"breathing_ruins_boss",
	},
}


## 生成连续 chunk 序列。chunk_count 至少为 1；1 个 chunk 时只有 Boss 房。
func generate(seed: int, biome: StringName, chunk_count: int) -> BiomeLayout:
	var layout := BiomeLayout.new()
	var count := maxi(chunk_count, 1)
	var data := _get_biome_data(biome)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var boss_chunk := StringName(data[&"boss"])
	if count == 1:
		layout.chunks = [boss_chunk]
		layout.branch_index = 0
		layout.boss_chunk = boss_chunk
		return layout

	var chunks: Array[StringName] = [StringName(data[&"entrance"])]
	var interior_count := count - 2
	var combat_pool: Array = data[&"combat"]
	var rest_index := -1
	if interior_count > 0:
		rest_index = rng.randi_range(0, interior_count - 1)

	var previous := chunks[0]
	for index in interior_count:
		var chunk: StringName
		if index == rest_index:
			chunk = StringName(data[&"rest"])
		else:
			chunk = _pick_combat_chunk(rng, combat_pool, previous)
		chunks.append(chunk)
		previous = chunk

	chunks.append(boss_chunk)
	layout.chunks = chunks

	# 分支不能落在 Boss 房上；两个 chunk 的极短区域则退化为入口处的分支。
	if count == 2:
		layout.branch_index = 0
	else:
		layout.branch_index = rng.randi_range(1, count - 2)
	layout.boss_chunk = boss_chunk
	return layout


func _pick_combat_chunk(
	rng: RandomNumberGenerator, pool: Array, previous: StringName
) -> StringName:
	if pool.is_empty():
		return previous
	var index := rng.randi_range(0, pool.size() - 1)
	if pool.size() > 1 and StringName(pool[index]) == previous:
		index = (index + 1) % pool.size()
	return StringName(pool[index])


func _get_biome_data(biome: StringName) -> Dictionary:
	if BIOME_DATA.has(biome):
		return BIOME_DATA[biome]
	push_error(
		"BiomeAssembler: unknown biome '%s', falling back to '%s'"
		% [biome, DEFAULT_BIOME]
	)
	return BIOME_DATA[DEFAULT_BIOME]
