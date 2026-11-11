class_name Perf
extends RefCounted

## Graphics quality (1.1). One switch that the per-frame visual code reads so
## a phone does less drawing work than a desktop. Flow configures it from the
## profile setting; "auto" means smooth on mobile and full on desktop.

const AUTO := 0
const FULL := 1
const SMOOTH := 2
## Smooth plus a 720p internal resolution: the GPU fills a quarter of the
## pixels of a 1440p phone screen. Text is a little softer.
const FASTEST := 3
const LABELS: Array[String] = ["画质：自动", "画质：完整", "画质：流畅", "画质：极速（降低分辨率）"]

## True when effects should be thinned out and ambience redrawn at half rate.
static var low := false
## Live one-shot combat effects drawn at once; later ones are skipped.
static var fx_cap := 72
## Ambient motes / dust multiplier.
static var ambient_scale := 1.0
static var mode := AUTO


static func configure(setting: int) -> void:
	mode = clampi(setting, AUTO, FASTEST)
	low = mode >= SMOOTH or (mode == AUTO and OS.has_feature("mobile"))
	fx_cap = 28 if low else 72
	ambient_scale = 0.5 if low else 1.0


## True on the frames where half-rate visuals should redraw.
static func ambient_frame() -> bool:
	return not low or Engine.get_process_frames() % 2 == 0
