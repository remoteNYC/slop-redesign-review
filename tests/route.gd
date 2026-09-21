extends SceneTree

var failures: Array[String] = []
var rebound_count := 0
var dash_hit_count := 0
var saw_gate := false
var rode_carriage := false
var saw_return := false
var jump_latch := 0
var dash_latch := 0
var attack_latch := 0
var restart_latch := 0
var exit_bounce_started := false
var exit_bounce_rebounds := 0
var carriage_relaunch_delay := 0
var carriage_relaunch_stage := 0
var observed_attempts := 1
var air_catch_delay := 0
var final_retry_delay := 0
var final_retry_done := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game := (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	game._start_run()
	game.player.rebounded.connect(func(_at: Vector2) -> void: rebound_count += 1)
	game.player.dash_connected.connect(func(_at: Vector2) -> void: dash_hit_count += 1)
	game.player.dashed.connect(func(at: Vector2) -> void: print("ROUTE DASH START ", at))
	game.carriage.ram_impact.connect(func(ram_speed: float, cart_speed: float) -> void: print("ROUTE IMPACT ram=", ram_speed, " cart=", cart_speed))
	game.carriage.directly_dashed.connect(func(player_speed: float, cart_speed: float) -> void: print("ROUTE CART DASH player=", player_speed, " cart=", cart_speed))

	for frame in 1500:
		_release_latched_inputs()
		if game.attempts != observed_attempts:
			observed_attempts = game.attempts
			carriage_relaunch_delay = 0
			carriage_relaunch_stage = 0
			air_catch_delay = 0
		if frame % 120 == 0 and game.mode == "play":
			print("ROUTE TRACE ", frame, " phase=", game.checkpoint_phase, " try=", game.attempts, " relaunch=", carriage_relaunch_stage, "/", carriage_relaunch_delay, " p=", game.player.global_position, " v=", game.player.velocity, " floor=", game.player.is_on_floor(), " dash=", game.player.dash_ready, "/", Input.is_action_pressed("dash"), "/", dash_latch, " cart=", game.carriage.global_position.x, "/", game.carriage.velocity_x, " ram=", game.counter_ram.global_position.x, "/", game.counter_ram.velocity_x)
		if game.mode == "complete":
			break
		if game.mode != "play":
			await physics_frame
			continue

		var p: CharacterBody2D = game.player
		var cart: AnimatableBody2D = game.carriage
		var riding := p.is_on_floor() and p.global_position.y < 150.0 and absf(p.global_position.x - cart.global_position.x) < 40.0
		rode_carriage = rode_carriage or (riding and absf(cart.velocity_x) > 25.0)
		saw_gate = saw_gate or game.checkpoint_phase >= 1
		saw_return = saw_return or game.exit_deployed

		if game.checkpoint_phase == 0:
			if rebound_count == 0:
				_align(p.global_position.x, 220.0)
				if p.is_on_floor():
					_tap("jump", 12)
				elif absf(p.global_position.x - 220.0) < 30.0 and p.global_position.y < 164.0:
					_tap("attack")
			elif p.global_position.x < 370.0:
				_hold_right()
			elif p.global_position.x < 505.0:
				if p.global_position.y > 150.0:
					_align(p.global_position.x, 472.0)
					if p.is_on_floor():
						_tap("jump", 12)
					elif absf(p.global_position.x - 472.0) < 28.0 and p.global_position.y < 173.0:
						_tap("attack")
					await physics_frame
					continue
				_hold_right()
				if p.is_on_floor() and p.global_position.y < 135.0:
					_tap("jump", 12)
				elif p.global_position.x > 395.0 and p.global_position.y < 122.0 and p.dash_ready:
					_tap("dash")
			else:
				_hold_right()
				var ram_dx: float = game.launch_ram.global_position.x - p.global_position.x
				if p.dash_ready and ram_dx > 18.0 and ram_dx < 76.0:
					_tap("dash")
				elif ram_dx > 0.0 and ram_dx < 95.0 and p.is_on_floor():
					_tap("jump", 12)
		elif game.checkpoint_phase == 1:
			exit_bounce_started = false
			var cart_dx: float = cart.global_position.x - p.global_position.x
			var launch_incoming := game.launch_ram.velocity_x > 30.0 and game.launch_ram.global_position.x < cart.global_position.x - 42.0
			if absf(cart.velocity_x) < 20.0 and launch_incoming:
				_align(p.global_position.x, 1085.0)
			elif absf(cart.velocity_x) < 20.0:
				if carriage_relaunch_stage == 0 and cart_dx < 50.0:
					_hold_left()
				elif carriage_relaunch_stage == 0:
					carriage_relaunch_stage = 1
					Input.action_release("move_left")
					Input.action_release("move_right")
				elif carriage_relaunch_stage == 1:
					carriage_relaunch_delay += 1
					Input.action_release("move_left")
					Input.action_release("move_right")
					if carriage_relaunch_delay == 3:
						carriage_relaunch_stage = 2
					_hold_right()
					if p.dash_ready:
						_tap("dash")
			elif riding:
				_align(p.global_position.x, cart.global_position.x)
			else:
				_hold_right()
				if p.is_on_floor() and p.global_position.x > 1080.0 and absf(cart_dx) >= 65.0:
					_tap("jump", 12)
				elif p.dash_ready and cart_dx > 45.0 and cart_dx < 160.0:
					air_catch_delay += 1
					if air_catch_delay == 3:
						Input.action_press("aim_up")
						_tap("dash")
				elif absf(cart.velocity_x) >= 20.0 and p.global_position.y < 145.0 and absf(cart_dx) < 35.0:
					_align(p.global_position.x, cart.global_position.x)
		elif game.checkpoint_phase == 2:
			exit_bounce_started = false
			var counter_dx: float = game.counter_ram.global_position.x - p.global_position.x
			if counter_dx > 15.0 and counter_dx < 92.0 and p.dash_ready:
				_hold_right()
				Input.action_press("aim_down")
				_tap("dash")
			elif riding:
				_align(p.global_position.x, cart.global_position.x)
			elif p.global_position.x < 2075.0:
				_hold_right()
				if p.is_on_floor():
					_tap("jump", 14)
			else:
				_align(p.global_position.x, 2130.0)
		else:
			if not final_retry_done:
				Input.action_release("move_left")
				Input.action_release("move_right")
				final_retry_delay += 1
				if final_retry_delay == 5:
					_tap("restart")
					final_retry_done = true
			elif riding and not exit_bounce_started and cart.velocity_x < -20.0 and cart.global_position.x <= 1690.0:
				exit_bounce_started = true
				exit_bounce_rebounds = rebound_count
				_hold_left()
				_tap("jump", 12)
			elif not riding and not exit_bounce_started:
				var return_cart_dx: float = cart.global_position.x - p.global_position.x
				if cart.velocity_x < -20.0 and return_cart_dx > 0.0 and return_cart_dx < 125.0:
					_align(p.global_position.x, cart.global_position.x)
					if p.is_on_floor():
						_tap("jump", 12)
				elif cart.velocity_x < -20.0 and return_cart_dx < -190.0:
					_tap("restart")
				else:
					_align(p.global_position.x, 2194.0)
			elif exit_bounce_started and rebound_count <= exit_bounce_rebounds:
				_align(p.global_position.x, cart.global_position.x)
				if p.global_position.y < 136.0:
					_tap("attack")
			elif exit_bounce_started:
				_align(p.global_position.x, game.EXIT_CENTER.x)
				if p.dash_ready and p.global_position.x > game.EXIT_CENTER.x + 72.0 and p.global_position.y < 108.0:
					_hold_left()
					_tap("dash")

		await physics_frame
	_release_all()
	_check(rebound_count >= 1, "the safe clock pad teaches a real downward-strike rebound")
	_check(dash_hit_count >= 1, "the learned dash can redirect the launch ram")
	_check(saw_gate, "the redirected ram opens the shutter")
	_check(rode_carriage, "the launched carriage can be caught and ridden")
	_check(saw_return, "redirecting the opposing ram opens the far shutter and deploys the exit")
	_check(game.mode == "complete", "the input-only route reaches the exit (mode %s, phase %d, player %s, cart %.1f/%+.1f, rebounds %d)" % [
		game.mode,
		game.checkpoint_phase,
		game.player.global_position,
		game.carriage.global_position.x,
		game.carriage.velocity_x,
		rebound_count,
	])
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
		print("ROUTE PASS: rebound, recoverable dash, ram-carriage cascade, threat-to-tool counter, and return exit")
		quit(0)
	else:
		for failure in failures:
			printerr("ROUTE FAIL: ", failure)
		quit(1)

func _hold_right() -> void:
	Input.action_press("move_right")
	Input.action_release("move_left")

func _hold_left() -> void:
	Input.action_press("move_left")
	Input.action_release("move_right")

func _align(player_x: float, target_x: float) -> void:
	if player_x < target_x - 5.0:
		_hold_right()
	elif player_x > target_x + 5.0:
		_hold_left()
	else:
		Input.action_release("move_left")
		Input.action_release("move_right")

func _tap(action: String, frames: int = 1) -> void:
	if Input.is_action_pressed(action):
		return
	Input.action_press(action)
	match action:
		"jump": jump_latch = frames
		"dash": dash_latch = frames
		"attack": attack_latch = frames
		"restart": restart_latch = frames

func _release_latched_inputs() -> void:
	jump_latch = maxi(0, jump_latch - 1)
	dash_latch = maxi(0, dash_latch - 1)
	attack_latch = maxi(0, attack_latch - 1)
	restart_latch = maxi(0, restart_latch - 1)
	if jump_latch == 0:
		Input.action_release("jump")
	if dash_latch == 0:
		Input.action_release("dash")
	if attack_latch == 0:
		Input.action_release("attack")
	if restart_latch == 0:
		Input.action_release("restart")
	Input.action_release("aim_down")
	Input.action_release("aim_up")

func _release_all() -> void:
	for action in ["move_left", "move_right", "jump", "attack", "dash", "aim_up", "aim_down", "restart"]:
		Input.action_release(action)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
