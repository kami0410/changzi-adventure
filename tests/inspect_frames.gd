extends SceneTree

## Prints the texture size and opaque bounds of every player frame. Run headless
## after re-slicing the animation sheets to confirm alpha and grounding.
func _initialize() -> void:
	var paths: Array[String] = []
	for action in ["run", "jump", "attack", "cast", "hurt", "dodge"]:
		var count := {"run": 4, "jump": 3, "attack": 3, "cast": 2, "hurt": 2, "dodge": 2}[action] as int
		for index in count:
			paths.append("res://assets/sprites/player/frames/%s_%d.png" % [action, index])
	paths.append("res://assets/sprites/player/player_idle.png")
	for path in paths:
		var texture := load(path) as Texture2D
		print(path, " tex=", texture, " size=", texture.get_size() if texture else "null")
		if texture != null:
			var image := texture.get_image()
			print("  image=", image, " empty=", image.is_empty() if image else "null", " rect=", PixelSprite.opaque_rect(texture))
	quit()
