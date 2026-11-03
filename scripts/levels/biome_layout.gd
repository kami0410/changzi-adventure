class_name BiomeLayout
extends RefCounted

## 连续横版生态区的拼接结果。
## chunks 是玩家从左到右经过的手工 chunk 序列，boss_chunk 固定在末尾。
## branch_index 指向序列中带可选分支的 chunk（索引始终落在 chunks 范围内）。

var chunks: Array[StringName] = []
var branch_index: int = 0
var boss_chunk: StringName = &""
