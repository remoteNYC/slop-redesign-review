extends SceneTree

var failures: Array[String] = []
var dash_hits := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game := (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	game._start_game()
	game.unlocked_level = 2
	game._start_second_stage()
	game.player.dash_connected.connect(func(_at: Vector2) -> void: dash_hits += 1)
	await physics_frame
	_check(InputMap.has_action("dash") and game.player.dash_enabled, "level two unlocks dash")
	game.player.reset_at(Vector2(50, 470))
	Input.action_press("dash")
	await physics_frame
	Input.action_release("dash")
	await physics_frame
	_check(game.player.dash_ready, "no target does not spend dash")
	game.player.reset_at(Vector2(250, 470))
	game.player.velocity = Vector2(120, -70)
	for x in [355, 480, 605, 735]:
		await _dash_to(game, x)
	await _brake_and_land()
	_check(game.mode == "play" and game.player.global_position.x > 830.0 and game.player.health == 3 and game.checkpoint_index == 1, "first chain crosses the spike pit and lands at its checkpoint")
	game.player.reset_at(Vector2(1050, 321))
	for x in [1130, 1260, 1395, 1535]:
		await _dash_to(game, x)
	await _brake_and_land()
	_check(game.mode == "play" and game.player.global_position.x > 1615.0 and game.player.health == 3 and game.checkpoint_index == 2, "second chain reaches the upper checkpoint")
	game.player.reset_at(Vector2(1825, 271))
	for x in [1905, 2030, 2150]:
		await _dash_to(game, x)
	await _brake_and_land()
	_check(game.mode == "play" and game.player.global_position.x > 2210.0 and game.player.health == 3 and game.checkpoint_index == 3, "third chain reaches the bell platform (mode %s, pos %s, checkpoint %d)" % [game.mode, game.player.global_position, game.checkpoint_index])
	await create_timer(0.3).timeout
	paused = false
	game.free()
	await process_frame
	if failures.is_empty():
		print("DASH PASS: nearest target, momentum, recharge, and three enemy chains")
		quit(0)
	else:
		for failure in failures:
			printerr("DASH FAIL: ", failure)
		quit(1)

func _dash_to(game: Node, expected_x: int) -> void:
	var target := game.player._nearest_dash_target() as Area2D
	_check(target != null and absf(target.global_position.x - expected_x) < 1.0, "nearest relay should be at x=%d (found %s)" % [expected_x, target.global_position if target != null else "none"])
	var before := dash_hits
	Input.action_press("dash")
	for i in 32:
		await physics_frame
		if dash_hits > before:
			break
	Input.action_release("dash")
	await physics_frame
	_check(dash_hits == before + 1, "dash reaches relay at x=%d (position %s)" % [expected_x, game.player.global_position])
	_check(game.player.dash_ready, "relay at x=%d refreshes dash" % expected_x)
	_check(game.player.velocity.x > 250.0, "relay at x=%d preserves forward momentum (velocity %s)" % [expected_x, game.player.velocity])
	_check(game.mode == "play", "dash across x=%d remains playable" % expected_x)

func _brake_and_land() -> void:
	Input.action_press("move_left")
	await create_timer(0.6).timeout
	Input.action_release("move_left")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
