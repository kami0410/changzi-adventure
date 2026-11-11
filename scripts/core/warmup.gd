class_name Warmup
extends RefCounted

## Background preloading (1.1). Godot loads a script, scene, texture or sound
## the first time something refers to it, on the main thread. On a phone that
## is a visible stall the first time a spell is cast, an enemy type appears or
## an effect plays. Warmup asks the engine to load all of that on worker
## threads right after boot and keeps a reference to each resource, so the
## later "first use" is a cache hit.
##
## Flow starts it and polls it every frame; nothing waits for it. A scene that
## wants everything ready (the run scene) can call [method finish].

## Folders walked recursively. Music and voice stay out: they are long streams
## that are loaded when played.
const ROOTS: Array[String] = [
	"res://scripts/",
	"res://scenes/",
	"res://assets/vfx/",
	"res://assets/audio/",
	"res://assets/sprites/",
]
const SKIP_DIRS: Array[String] = ["res://assets/audio/music/", "res://assets/audio/voice/"]
const EXTENSIONS: Array[String] = ["gd", "tscn", "png", "wav", "ogg", "tres", "gdshader"]
## Requests handed to the loader per frame, so boot itself never stalls.
const REQUESTS_PER_FRAME := 12

static var _held: Dictionary = {}
static var _queue: Array[String] = []
static var _loading: Array[String] = []
static var _started := false


static func start() -> void:
	if _started:
		return
	_started = true
	for root in ROOTS:
		_collect(root)


## Advances the warmup. Returns true once everything is loaded.
static func poll() -> bool:
	if not _started:
		return false
	var index := _loading.size() - 1
	while index >= 0:
		var path := _loading[index]
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			_held[path] = ResourceLoader.load_threaded_get(path)
			_loading.remove_at(index)
		elif status != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			_loading.remove_at(index)
		index -= 1
	var budget := REQUESTS_PER_FRAME
	while budget > 0 and not _queue.is_empty():
		var path: String = _queue.pop_back()
		if _held.has(path):
			continue
		if ResourceLoader.has_cached(path):
			_held[path] = load(path)
			continue
		if ResourceLoader.load_threaded_request(path) == OK:
			_loading.append(path)
			budget -= 1
	return is_done()


static func is_done() -> bool:
	return _started and _queue.is_empty() and _loading.is_empty()


## Share of the work done, 0–1, for a loading hint.
static func progress() -> float:
	var total := _held.size() + _queue.size() + _loading.size()
	return 1.0 if total == 0 else float(_held.size()) / float(total)


## Blocks until everything is loaded. Used behind a fade, never mid-play.
static func finish() -> void:
	if not _started:
		return
	while not _queue.is_empty():
		var path: String = _queue.pop_back()
		if not _held.has(path):
			_held[path] = load(path)
	for path in _loading:
		_held[path] = ResourceLoader.load_threaded_get(path)
	_loading.clear()


## Drops every held reference (engine exit), so nothing outlives the servers.
static func release() -> void:
	_queue.clear()
	_loading.clear()
	_held.clear()


static func held_count() -> int:
	return _held.size()


static func _collect(dir: String) -> void:
	if SKIP_DIRS.has(dir):
		return
	for entry in ResourceLoader.list_directory(dir):
		if entry.ends_with("/"):
			_collect(dir + entry)
		elif EXTENSIONS.has(entry.get_extension()):
			_queue.append(dir + entry)
