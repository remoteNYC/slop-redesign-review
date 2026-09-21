extends SceneTree

var failures: Array[String] = []
var reached_far_stop := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game := (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	game._start_run()
	game._set_checkpoint(2)
	game.carriage_advanced = true
	game.carriage.reset_kinetic(Vector2(2030, 166), 130.0)
	game.counter_ram.reset_kinetic(Vector2(2160, 172), "idle", 0.0)
	game.player.reset_at(Vector2(2112, 141))
	game.carriage.stop_rebounded.connect(func(side: int, _incoming: float, _outgoing: float) -> void:
		if side == 1:
			reached_far_stop = true
	)
	await physics_frame
	Input.action_press("move_right")
	Input.action_press("aim_down")
	Input.action_press("dash")
	for _frame in 12:
		await physics_frame
	Input.action_release("dash")
	Input.action_release("aim_down")
	Input.action_release("move_right")
	_check(game.counter_ram.velocity_x > 100.0, "an aimed player dash redirects the opposing ram to the right")
	_check(game.mode == "play" and game.player.active, "the successful dash separates the player safely")
	game.player.active = false
	for _frame in 480:
		await physics_frame
		if game.exit_deployed:
			break
	_check(game.exit_deployed, "redirecting the ram produces a useful carriage return")
	_check(reached_far_stop, "the redirected ram lets the carriage reach the far rail stop")

	game._start_run()
	game._set_checkpoint(2)
	game.carriage_advanced = true
	game.carriage.reset_kinetic(Vector2(2100, 166), 0.0)
	game.counter_ram.reset_kinetic(Vector2(2395, 172), "recover", 0.0)
	game.player.reset_at(Vector2(2162, 173))
	await physics_frame
	Input.action_press("move_left")
	Input.action_press("dash")
	for _frame in 12:
		await physics_frame
	Input.action_release("dash")
	Input.action_release("move_left")
	_check(game.carriage.velocity_x < -100.0, "the player can reverse a stalled advanced carriage directly")
	_check(game.exit_deployed and game.checkpoint_phase == 3, "the deliberate correction opens the same return exit")
	_check(game.mode == "play" and game.player.active, "the direct carriage clash leaves the player alive")

	game.mode = "complete"
	game.sfx.stop_all()
	await create_timer(0.1).timeout
	game.free()
	await process_frame
	if failures.is_empty():
		print("ALTERNATE PASS: counter-ram bypass and direct carriage correction both create useful returns")
		quit(0)
	else:
		for failure in failures:
			printerr("ALTERNATE FAIL: ", failure)
		quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
