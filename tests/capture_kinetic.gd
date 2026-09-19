extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/kinetic_prototype.tscn") as PackedScene
	var prototype = scene.instantiate()
	root.add_child(prototype)
	await process_frame
	prototype.player.invulnerable_time = 0.0
	await create_timer(0.05).timeout
	var image := root.get_texture().get_image()
	if image == null or image.save_png("/tmp/kinetic_prototype.png") != OK:
		printerr("KINETIC CAPTURE FAIL")
		quit(1)
		return
	print("KINETIC CAPTURE PASS: /tmp/kinetic_prototype.png")
	prototype.free()
	await process_frame
	quit(0)
