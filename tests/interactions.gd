extends SceneTree

var failures: Array[String] = []
var rebounds := 0
var dash_hits := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game := (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	game._start_run()
	game.player.rebounded.connect(func(_at: Vector2) -> void: rebounds += 1)
	game.player.dash_connected.connect(func(_at: Vector2) -> void: dash_hits += 1)

	game.player.reset_at(Vector2(220, 148))
	game.player.velocity = Vector2(80, 0)
	await physics_frame
	Input.action_press("attack")
	for _frame in 4:
		await physics_frame
	Input.action_release("attack")
	_check(rebounds == 1 and game.player.velocity.y < -220.0, "the safe clock pad gives a consistent full rebound")

	game.launch_ram.reset_kinetic(Vector2(810, 172), "recover", 0.0)
	game.launch_ram.state_time = 2.0
	game.player.reset_at(Vector2(755, 172))
	Input.action_press("move_right")
	Input.action_press("dash")
	for _frame in 14:
		await physics_frame
	Input.action_release("dash")
	Input.action_release("move_right")
	_check(dash_hits == 1, "a free dash connects with the ram")
	_check(game.launch_ram.velocity_x > 150.0, "dash direction becomes readable ram momentum")
	_check(game.mode == "play" and game.player.active, "a confirmed kinetic dash cannot become a deferred contact death")

	game._start_run()
	game.player.active = false
	game.launch_ram.position = Vector2(1010, 172)
	game.launch_ram.velocity_x = 170.0
	game.launch_ram.state = "coast"
	for _frame in 100:
		await physics_frame
	_check(game.gate.is_open, "the charging ram opens the shutter through the shared impact rule")
	_check(game.carriage.velocity_x > 70.0, "the same ram continues through the shutter and launches the carriage")

	game.carriage.reset_kinetic(Vector2(2105, 166), 105.0)
	game.carriage_advanced = true
	game.counter_ram.reset_kinetic(Vector2(2160, 172), "coast", -170.0)
	game.counter_ram.contact_cooldown = 0.0
	await process_frame
	for _frame in 18:
		await physics_frame
	_check(game.carriage.velocity_x < -35.0, "the opposing ram reliably reverses a rightward carriage")
	_check(game.exit_deployed and game.checkpoint_phase == 3, "the opposing ram turns danger into the return that opens the exit")

	game._start_run()
	game.player.active = false
	game._set_checkpoint(2)
	game.carriage_advanced = true
	game.carriage.reset_kinetic(Vector2(2570, 166), 105.0)
	for _frame in 20:
		await physics_frame
	_check(game.carriage.velocity_x < -35.0, "the far rail stop also returns the carriage")
	_check(game.exit_deployed and game.checkpoint_phase == 3, "the far rail return opens the same exit and checkpoint")

	game._start_run()
	game.player.active = false
	game.gate.set_open(true)
	game.carriage.reset_kinetic(Vector2(1210, 166), -55.0)
	game.launch_ram.reset_kinetic(Vector2(1150, 172), "coast", 170.0)
	for _frame in 15:
		await physics_frame
	_check(game.carriage.velocity_x > 60.0, "the returning carriage can be rescued by the original launch ram")

	game._start_run()
	game.launch_ram.reset_kinetic(Vector2(830, 172), "idle", 0.0)
	game.launch_ram.cooldown = 0.0
	game.player.reset_at(Vector2(790, 173))
	for _frame in 3:
		await physics_frame
	_check(game.launch_ram.state == "windup" and game.launch_ram.facing == -1, "the ram shows its chosen charge direction")
	game.player.reset_at(Vector2(870, 173))
	for _frame in 10:
		await physics_frame
	_check(game.launch_ram.facing == -1, "crossing behind a winding ram does not make it turn at the last moment")

	game._start_run()
	game.player.reset_at(Vector2(472, 160))
	for _frame in 32:
		await physics_frame
	_check(game.mode == "play" and game.player.is_on_floor() and game.player.global_position.y > 190.0, "a missed upper dash lands in the recovery pocket")
	var pocket_rebounds := rebounds
	Input.action_press("jump")
	for _frame in 8:
		await physics_frame
	Input.action_release("jump")
	Input.action_press("attack")
	for _frame in 8:
		await physics_frame
	Input.action_release("attack")
	_check(rebounds > pocket_rebounds and game.player.velocity.y < -180.0, "the recovery pad launches the player out of the pocket")

	game._start_run()
	game.mode = "play"
	game.player.reset_at(Vector2(1400, 172))
	await physics_frame
	_check(game.mode == "play", "the center of the visible spike tips is not reached early")
	game.player.global_position.y = 178.0
	await physics_frame
	await physics_frame
	_check(game.mode == "dead", "crossing the visible spike line is lethal")

	_release_all()
	game.mode = "complete"
	game.player.active = false
	game.launch_ram.set_physics_process(false)
	game.counter_ram.set_physics_process(false)
	game.carriage.set_physics_process(false)
	game.sfx.stop_all()
	await create_timer(0.1).timeout
	game.free()
	await process_frame
	if failures.is_empty():
		print("INTERACTIONS PASS: rebound, dash transfer, shutter cascade, two returns, ram rescue, baitable windup, and exact spikes")
		quit(0)
	else:
		for failure in failures:
			printerr("INTERACTIONS FAIL: ", failure)
		quit(1)

func _release_all() -> void:
	for action in ["move_left", "move_right", "jump", "attack", "dash", "aim_up", "aim_down"]:
		Input.action_release(action)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
