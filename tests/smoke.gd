extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/game.tscn") as PackedScene
	var game := scene.instantiate()
	root.add_child(game)
	await process_frame
	_check(game.mode == "title", "title opens")
	_check(InputMap.has_action("attack") and InputMap.has_action("jump"), "controls registered")
	game._start_game()
	await physics_frame
	_check(game.mode == "play", "game starts")
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
	_check(game.mode == "won", "bell finishes the stage (mode %s, pos %s)" % [game.mode, game.player.global_position])
	Input.action_press("restart")
	await create_timer(0.15).timeout
	Input.action_release("restart")
	_check(game.mode == "play" and not game.overlay.visible, "one restart press starts a new run (mode %s)" % game.mode)
	_check(game.player.global_position.distance_to(Vector2(48, 470)) < 12.0, "new run begins at the entrance")
	await create_timer(0.5).timeout
	paused = false
	game.free()
	if failures.is_empty():
		print("SMOKE PASS: start, jump, rebound, checkpoint, respawn, finish, one-press restart")
		quit(0)
	else:
		for failure in failures:
			printerr("SMOKE FAIL: ", failure)
		quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
