class_name Warmup
extends RefCounted

## Background preloading (1.1). Godot loads a script, scene, texture or sound
## the first time something refers to it, on the main thread. On a phone that
## is a visible stall the first time a spell is cast, an enemy type appears or
## an effect plays. Warmup asks the engine to load all of that on worker
## threads right after boot and keeps a reference to each resource, so the
## later "first use" is a cache hit.
##
## Flow starts it and polls it every frame. Nothing ever waits for it: 1.1.0
## blocked on the unfinished loads when the player left the Hub, and the main
## thread deadlocked against a worker that was loading the run scene (the game
## froze on the way into a level). Two rules since 1.1.1:
##   - only plain data (textures, sounds) goes to worker threads; scripts,
##     scenes and resources load on the main thread, a few milliseconds a frame;
##   - the main thread never calls a blocking wait on a worker's load.

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
## Loaded on worker threads. Everything else in EXTENSIONS loads on the main
## thread within MAIN_BUDGET_MSEC a frame.
const THREADED: Array[String] = ["png", "wav", "ogg"]
## Not warmed: the run scene and its script pull in most of the game in one
## load, which would be a long stall in the Hub. They load at the door.
const SKIP_FILES: Array[String] = ["res://scenes/main.tscn", "res://scripts/game.gd"]
## Requests handed to the loader per frame, so boot itself never stalls.
const REQUESTS_PER_FRAME := 12
const MAIN_BUDGET_MSEC := 3

static var _held: Dictionary = {}
static var _queue: Array[String] = []
static var _main_queue: Array[String] = []
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
	var deadline := Time.get_ticks_msec() + MAIN_BUDGET_MSEC
	while not _main_queue.is_empty() and Time.get_ticks_msec() < deadline:
		var path: String = _main_queue.pop_back()
		if not _held.has(path):
			_held[path] = load(path)
	return is_done()


static func is_done() -> bool:
	return _started and _queue.is_empty() and _main_queue.is_empty() and _loading.is_empty()


## Share of the work done, 0–1, for a loading hint.
static func progress() -> float:
	var total := _held.size() + _queue.size() + _main_queue.size() + _loading.size()
	return 1.0 if total == 0 else float(_held.size()) / float(total)


## Number of loads still on worker threads.
static func pending_threaded() -> int:
	return _loading.size()


## Drops every held reference (engine exit), so nothing outlives the servers.
static func release() -> void:
	_queue.clear()
	_main_queue.clear()
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
		elif EXTENSIONS.has(entry.get_extension()) and not SKIP_FILES.has(dir + entry):
			if THREADED.has(entry.get_extension()):
				_queue.append(dir + entry)
			else:
				_main_queue.append(dir + entry)
