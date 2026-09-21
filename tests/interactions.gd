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
	_check(not game.exit_deployed, "an accidental reversal is recoverable but does not solve the far shutter")

	game.counter_ram.reset_kinetic(Vector2(2410, 172), "coast", 170.0)
	game.counter_ram.contact_cooldown = 0.0
	for _frame in 28:
		await physics_frame
	_check(game.return_gate.is_open, "redirecting the opposing ram opens the far shutter")
	_check(game.exit_deployed and game.checkpoint_phase == 3, "the useful ram impact deploys the return exit and records the learned state")

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
		print("INTERACTIONS PASS: rebound, dash transfer, shutter cascade, counter reversal, exact spikes, and contact grace")
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
