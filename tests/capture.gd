extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game := (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	game._start_game()
	await create_timer(0.12).timeout
	if not _save("/tmp/slop_stage_start.png"):
		quit(1)
		return
	game.player.global_position = Vector2(720, 395)
	game.camera.reset_smoothing()
	await create_timer(0.12).timeout
	_save("/tmp/slop_stage_middle.png")
	game.player.global_position = Vector2(1640, 320)
	game.camera.reset_smoothing()
	await create_timer(0.12).timeout
	_save("/tmp/slop_stage_end.png")
	game.unlocked_level = 2
	game._start_second_stage()
	await create_timer(0.12).timeout
	_save("/tmp/slop_dash_start.png")
	game.player.global_position = Vector2(1250, 300)
	game.camera.reset_smoothing()
	await create_timer(0.12).timeout
	_save("/tmp/slop_dash_middle.png")
	game.player.global_position = Vector2(2050, 245)
	game.camera.reset_smoothing()
	await create_timer(0.12).timeout
	_save("/tmp/slop_dash_end.png")
	await create_timer(0.3).timeout
	paused = false
	game.free()
	quit()

func _save(path: String) -> bool:
	var image := root.get_texture().get_image()
	if image == null:
		printerr("Viewport capture is unavailable with the current rendering driver")
		return false
	return image.save_png(path) == OK
