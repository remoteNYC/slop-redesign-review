extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game := (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	_check(game.mode == "title" and paused, "the game opens on its title screen")
	_check(InputMap.has_action("dash") and InputMap.has_action("attack") and InputMap.has_action("restart"), "the permanent move set is registered")

	game._start_run()
	await physics_frame
	await physics_frame
	_check(game.mode == "play" and not paused, "a run starts immediately")
	_check(game.player.global_position.distance_to(game.START_POSITION) < 3.0, "the player starts at the visible entrance")
	_check(game.player.dash_ready, "dash starts ready")

	Input.action_press("move_right")
	for _frame in 8:
		await physics_frame
	_check(game.player.velocity.x > 120.0, "run acceleration reaches a useful speed quickly")
	Input.action_press("jump")
	for _frame in 4:
		await physics_frame
	Input.action_release("jump")
	Input.action_release("move_right")
	_check(game.player.velocity.y < 0.0, "jump responds while moving")

	game.player.kill()
	await create_timer(0.36).timeout
	_check(game.mode == "play" and game.player.global_position.distance_to(game.START_POSITION) < 4.0, "death returns to the entrance in under half a second")

	game.gate.receive_kinetic_impact(170.0)
	await physics_frame
	_check(game.gate.is_open and game.checkpoint_phase == 1, "a strong kinetic hit opens and checkpoints the shutter")
	game.player.kill()
	await create_timer(0.36).timeout
	_check(game.mode == "play" and game.player.global_position.distance_to(game.CHECKPOINT_ONE) < 5.0, "the shutter checkpoint restores the player on the recoverable carriage state (player %s, cart %s)" % [game.player.global_position, game.carriage.global_position])
	_check(game.gate.is_open, "checkpoint retry preserves the solved shutter")

	game._set_checkpoint(2)
	game.carriage_advanced = true
	game.carriage.reset_kinetic(Vector2(2105, 166), 105.0)
	game.carriage.receive_kinetic_impact(-170.0)
	await physics_frame
	game.player.kill()
	await create_timer(0.36).timeout
	_check(game.checkpoint_phase == 3 and game.exit_deployed, "the reversal checkpoint preserves the solved threat-to-tool interaction")
	_check(game.carriage.global_position.distance_to(Vector2(2194, 166)) < 35.0, "final retry restores the returning carriage beside the player (cart %s, player %s)" % [game.carriage.global_position, game.player.global_position])
	_check(game.player.global_position.distance_to(game.CHECKPOINT_THREE) < 8.0, "final retry begins directly above the returning carriage")

	game._deploy_exit()
	await physics_frame
	game.player.global_position = Vector2(game.EXIT_CENTER.x, 62)
	game.player.velocity = Vector2.ZERO
	await physics_frame
	await physics_frame
	_check(game.mode == "complete", "the deployed bell completes the run")

	_release_all()
	paused = false
	game.sfx.stop_all()
	await create_timer(0.1).timeout
	game.free()
	await process_frame
	if failures.is_empty():
		print("SMOKE PASS: title, controls, movement, quick retry, checkpoint state, and completion")
		quit(0)
	else:
		for failure in failures:
			printerr("SMOKE FAIL: ", failure)
		quit(1)

func _release_all() -> void:
	for action in ["move_left", "move_right", "jump", "attack", "dash", "aim_up", "aim_down"]:
		Input.action_release(action)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
