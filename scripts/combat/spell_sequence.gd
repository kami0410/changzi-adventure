class_name SpellSequence
extends Node

## Runs spell callbacks after short delays (multi-pulse casts). Outside the
## scene tree — headless unit tests — everything runs immediately so results
## stay deterministic.

var _queue: Array[Dictionary] = []
var _time := 0.0


static func schedule(host: Node, delay: float, callback: Callable) -> void:
	if not callback.is_valid():
		return
	if delay <= 0.0 or host == null or not is_instance_valid(host) or not host.is_inside_tree():
		callback.call()
		return
	var sequence := host.get_node_or_null("SpellSequence") as SpellSequence
	if sequence == null:
		sequence = SpellSequence.new()
		sequence.name = "SpellSequence"
		sequence.process_mode = Node.PROCESS_MODE_PAUSABLE
		host.add_child(sequence)
	sequence._queue.append({"at": sequence._time + delay, "call": callback})


func _physics_process(delta: float) -> void:
	_time += delta
	var index := 0
	while index < _queue.size():
		var entry: Dictionary = _queue[index]
		if float(entry["at"]) <= _time:
			_queue.remove_at(index)
			var callback: Callable = entry["call"]
			if callback.is_valid():
				callback.call()
		else:
			index += 1


func pending() -> int:
	return _queue.size()


func clear() -> void:
	_queue.clear()
