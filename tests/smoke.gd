extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/game.tscn") as PackedScene
	var game := scene.instantiate()
	root.add_child(game)
	await process_frame
	game.unlocked_level = 1
	game.selected_level = 1
	game._open_level_select("CLOCKWORK ASCENT")
	_check(game.mode == "level_select", "level select opens")
	_check(InputMap.has_action("attack") and InputMap.has_action("jump") and InputMap.has_action("aim_up"), "controls registered")
	Input.action_press("move_right")
	await process_frame
	Input.action_release("move_right")
	_check(game.selected_level == 1, "locked level cannot be selected")
	Input.action_press("ui_accept")
	await create_timer(0.06).timeout
	Input.action_release("ui_accept")
	_check(game.mode == "play" and game.stage_number == 1, "selected first level starts")
	_check(game.player.health == 3, "player starts with three health")
	Input.action_press("jump")
	await create_timer(0.07).timeout
	_check(game.player.velocity.y < 0.0, "jump launches upward (velocity %s, y %s, floor %s, coyote %s, buffer %s)" % [game.player.velocity.y, game.player.global_position.y, game.player.is_on_floor(), game.player.coyote_time, game.player.jump_buffer_time])
	Input.action_release("jump")
	game.player.global_position = Vector2(210, 425)
	game.player.velocity = Vector2(0, 40)
	Input.action_press("attack")
	await physics_frame
	await physics_frame
	_check(game.player.velocity.y < -180.0, "device strike rebounds player")
	Input.action_release("attack")
	game.player.global_position = Vector2(735, 395)
	game.player.velocity = Vector2.ZERO
	await physics_frame
	await physics_frame
	_check(game.checkpoint_index == 1, "checkpoint activates")
	game.player.kill()
	await create_timer(0.55).timeout
	_check(game.mode == "play", "death returns to play")
	_check(game.player.global_position.distance_to(Vector2(735, 395)) < 12.0, "respawn uses checkpoint")
	game.player.global_position = Vector2(1460, 320)
	game.player.velocity = Vector2.ZERO
	await create_timer(0.06).timeout
	_check(game.checkpoint_index == 2, "upper checkpoint activates")
	game.player.kill()
	await create_timer(0.55).timeout
	_check(game.mode == "play" and game.player.global_position.distance_to(Vector2(1460, 320)) < 12.0, "upper checkpoint respawn is safe")
	game.player.global_position = Vector2(1904, 251)
	game.player.velocity = Vector2.ZERO
	await physics_frame
	await physics_frame
	await physics_frame
	_check(game.mode == "level_select" and game.unlocked_level == 2 and game.selected_level == 2, "first bell unlocks and selects level two")
	_check(game.completed_levels & 1 and "LEVEL 1   FOUNDRY  [CLEARED]" in game.overlay_body.text, "completed level is marked as cleared")
	var progress := ConfigFile.new()
	_check(progress.load(game.PROGRESS_PATH) == OK and int(progress.get_value("progress", "unlocked_level", 1)) == 2, "level unlock is saved")
	Input.action_press("ui_accept")
	await create_timer(0.08).timeout
	Input.action_release("ui_accept")
	_check(game.mode == "play" and game.stage_number == 2 and game.player.dash_enabled, "level two starts with dash unlocked")
	game.player.global_position = game.level.goal_marker + Vector2(0, 12)
	game.player.velocity = Vector2.ZERO
	await create_timer(0.1).timeout
	_check(game.mode == "level_select" and game.selected_level == 2 and game.completed_levels & 2, "second bell returns to level select and marks level two cleared")
	Input.action_release("move_left")
	await process_frame
	Input.action_press("move_left")
	await create_timer(0.06).timeout
	Input.action_release("move_left")
	_check(game.selected_level == 1, "completed first level can be selected again")
	await process_frame
	Input.action_press("ui_accept")
	await create_timer(0.08).timeout
	Input.action_release("ui_accept")
	_check(game.mode == "play" and game.stage_number == 1 and not game.player.dash_enabled, "level select replays level one")
	_check(game.player.global_position.distance_to(Vector2(48, 470)) < 12.0, "replayed level begins at the entrance")
	await create_timer(0.5).timeout
	paused = false
	game.free()
	if failures.is_empty():
		print("SMOKE PASS: level select, unlock save, both stages, and replay")
		quit(0)
	else:
		for failure in failures:
			printerr("SMOKE FAIL: ", failure)
		quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
