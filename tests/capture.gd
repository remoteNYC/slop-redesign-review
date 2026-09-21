extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game := (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	game._start_run()
	await create_timer(0.15).timeout
	if not _save("/tmp/clockwork_entry.png"):
		printerr("CAPTURE FAIL")
		quit(1)
		return

	game.gate.set_open(true)
	game.checkpoint_phase = 1
	game.player.reset_at(Vector2(1045, 141))
	game.carriage.position = Vector2(1070, 166)
	game.carriage.velocity_x = 75.0
	game.camera.reset_smoothing()
	await create_timer(0.12).timeout
	if not _save("/tmp/clockwork_carriage.png"):
		quit(1)
		return

	game.carriage_advanced = true
	game._deploy_exit()
	game.carriage.position = Vector2(1175, 166)
	game.carriage.velocity_x = -90.0
	game.player.reset_at(Vector2(1175, 141))
	game.camera.reset_smoothing()
	await create_timer(0.12).timeout
	if not _save("/tmp/clockwork_return.png"):
		quit(1)
		return

	print("CAPTURE PASS: entry, carriage recovery, and return exit")
	game.mode = "complete"
	game.player.active = false
	game.free()
	await process_frame
	quit(0)

func _save(path: String) -> bool:
	var image := root.get_texture().get_image()
	return image != null and image.save_png(path) == OK
