extends RefCounted


func run(t: Callable) -> void:
	var dialogue := DialogueData.new()
	dialogue.lines = ["a", "b"]
	t.call(dialogue.line_at(0), "a", "dialogue_0")
	t.call(dialogue.line_at(2), "a", "dialogue_wrap")
	t.call(dialogue.line_at(-1), "b", "dialogue_negative")
	var empty := DialogueData.new()
	t.call(empty.line_at(0), "", "dialogue_empty")

	var npc := NPC.new()
	npc.dialogue = dialogue
	var interactions := [0]
	npc.interacted.connect(func(_npc): interactions[0] += 1)
	t.call(npc.interact(), "a", "npc_first")
	t.call(npc.interact(), "b", "npc_second")
	t.call(npc.interact(), "a", "npc_wrap")
	t.call(interactions[0], 3, "npc_signal")

	var profile := Profile.new()
	profile.memory_fragments = 50
	var shop := Shop.new()
	shop.stock.append({"id": &"xidi", "cost": 20, "kind": &"word"})
	t.call(shop.buy(&"xidi", profile), true, "shop_buy")
	t.call(profile.memory_fragments, 30, "shop_cost")
	t.call(profile.is_word_unlocked(&"xidi"), true, "shop_unlock")
	t.call(shop.buy(&"missing", profile), false, "shop_missing")
	profile.memory_fragments = 0
	t.call(shop.buy(&"xidi", profile), false, "shop_insufficient")

	var hub := Hub.new()
	var luchen := NPC.new()
	luchen.npc_id = &"luchen"
	hub.add_child(luchen)
	t.call(hub.get_npc(&"luchen"), luchen, "hub_get_npc")
	t.call(hub.get_npc(&"missing"), null, "hub_missing")

	npc.free()
	hub.free()
	profile.free()
