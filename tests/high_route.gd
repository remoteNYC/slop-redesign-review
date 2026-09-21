extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game := (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	game._start_run()
	game._set_checkpoint(2)
	game.carriage.reset_kinetic(Vector2(1900, 166), 72.0)
	game.player.reset_at(Vector2(1900, 141))
	var ram_reversed_cart := [false]
	var rebound_count := [0]
	var strike_delay := int(OS.get_environment("HIGH_STRIKE_DELAY")) if OS.has_environment("HIGH_STRIKE_DELAY") else 2
	var dash_gap := float(OS.get_environment("HIGH_DASH_GAP")) if OS.has_environment("HIGH_DASH_GAP") else 65.0
	game.carriage.ram_impact.connect(func(ram_speed: float, carriage_speed: float) -> void:
		if ram_speed < -20.0 and carriage_speed < -20.0:
			ram_reversed_cart[0] = true
	)
	game.player.rebounded.connect(func(_at: Vector2) -> void: rebound_count[0] += 1)
	await physics_frame
	Input.action_press("jump")
	for _frame in strike_delay:
		await physics_frame
	Input.action_release("jump")
	Input.action_press("attack")
	await physics_frame
	Input.action_release("attack")
	Input.action_press("move_right")
	for _frame in 65:
		await physics_frame
	Input.action_release("move_right")
	_check(rebound_count[0] >= 1, "the carriage gives a real rebound toward the upper route")
	_check(game.player.global_position.y < 105.0 and game.player.is_on_floor(), "the carriage rebound reaches the upper deck")
	_check(game.counter_ram.state != "windup", "the upper deck allows observation without prematurely triggering the opposing ram")
	Input.action_press("move_right")
	for _frame in 100:
		await physics_frame
		if game.player.global_position.x >= 2240.0:
			break
	Input.action_release("move_right")
	for _frame in 48:
		await physics_frame
	_check(game.mode == "play" and game.player.is_on_floor() and game.player.global_position.x > game.counter_ram.global_position.x, "the upper approach has a safe landing behind the ram")
	if OS.has_environment("HIGH_CAPTURE"):
		root.get_texture().get_image().save_png("/tmp/clockwork_upper_route.png")
	var dashed_ram := false
	for _frame in 180:
		var ram_dx: float = game.player.global_position.x - game.counter_ram.global_position.x
		if not dashed_ram and ram_dx < dash_gap and game.counter_ram.velocity_x > 100.0:
			Input.action_press("move_left")
			Input.action_press("dash")
			dashed_ram = true
		await physics_frame
		if dashed_ram:
			Input.action_release("dash")
			Input.action_release("move_left")
		if game.exit_deployed or game.mode != "play":
			break
	_check(dashed_ram, "the player can meet the baited ram from behind with a leftward dash")
	_check(ram_reversed_cart[0] and game.exit_deployed, "the redirected ram reverses the carriage and opens the return route")
	_check(game.mode == "play" and game.player.active, "the flank and counter dash leave the player alive")

	game._start_run()
	game._set_checkpoint(2)
	game.carriage.reset_kinetic(Vector2(1900, 166), 72.0)
	game.player.reset_at(Vector2(1900, 141))
	await physics_frame
	Input.action_press("jump")
	Input.action_press("move_right")
	for _frame in 12:
		await physics_frame
	Input.action_release("jump")
	for _frame in 65:
		await physics_frame
	Input.action_release("move_right")
	_check(game.mode == "play" and game.player.active, "missing the optional upper rebound has a recoverable landing")
	_check(game.player.global_position.x >= 1840.0, "the missed upper route does not reset progress or trap the player")
	game.mode = "complete"
	game.sfx.stop_all()
	await create_timer(0.1).timeout
	game.free()
	await process_frame
	if failures.is_empty():
		print("HIGH ROUTE PASS")
		quit(0)
	else:
		for failure in failures:
			printerr("HIGH ROUTE FAIL: ", failure)
		quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
