extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level = (load("res://scenes/kinetic_prototype.tscn") as PackedScene).instantiate()
	root.add_child(level)
	await physics_frame
	await physics_frame
	var launch_hit := false
	var carriage_hit := false
	var counter_hit := false
	var rode_moving_carriage := false
	var used_return := false
	var jump_latch := false
	var chase_jump := false
	Input.action_press("move_right")
	Input.action_press("jump")

	for _frame in 900:
		if jump_latch:
			Input.action_release("jump")
			jump_latch = false
		if chase_jump and level.player.velocity.y > 20.0:
			Input.action_release("jump")
			chase_jump = false
		if Input.is_action_pressed("attack") and (level.player.velocity.y < -200.0 or level.player.is_on_floor()):
			Input.action_release("attack")

		if not launch_hit:
			if level.ram.state == "windup" and level.player.position.x > 96.0:
				Input.action_release("move_right")
			if level.ram.state == "coast" and level.player.position.x - level.ram.position.x < 34.0 and level.player.position.y < 166.0:
				Input.action_press("attack")
			if level.player.velocity.y < -250.0 and level.ram.velocity_x > 40.0:
				launch_hit = true
				Input.action_press("move_right")
		else:
			_align_over(level.player.position.x, level.carriage.position.x)
			var riding_carriage: bool = level.player.is_on_floor() and level.player.position.y < 150.0
			if riding_carriage and absf(level.carriage.velocity_x) > 20.0:
				rode_moving_carriage = true
			if riding_carriage and not carriage_hit:
				Input.action_press("jump")
				jump_latch = true
			elif not riding_carriage and not carriage_hit and level.player.velocity.y > -20.0 and level.player.position.y < 132.0:
				Input.action_press("attack")
			if "MID-AIR CORRECTION" in level.last_event and level.player.velocity.y < -250.0:
				carriage_hit = true

			if carriage_hit and not counter_hit:
				var counter_dx: float = level.counter_ram.position.x - level.player.position.x
				if level.counter_ram.state in ["windup", "coast"] and counter_dx > -8.0:
					Input.action_press("move_right")
					Input.action_release("move_left")
				if level.counter_ram.state == "windup" and counter_dx < 86.0 and riding_carriage:
					Input.action_press("jump")
					jump_latch = true
				if level.counter_ram.state in ["windup", "coast"] and absf(counter_dx) < 50.0 and level.player.position.y < 166.0 and not riding_carriage:
					Input.action_press("move_right")
					Input.action_press("attack")
				if "COUNTER REDIRECT" in level.last_event:
					counter_hit = true

			if counter_hit and level.carriage.position.x > 1010.0 and level.carriage.velocity_x < -8.0:
				used_return = true
				Input.action_press("move_left")
				Input.action_release("move_right")
				if riding_carriage:
					Input.action_press("jump")
					chase_jump = true
			elif counter_hit and level.player.is_on_floor() and level.player.position.y > 160.0 and level.player.position.x > 630.0 and level.player.position.x < 1000.0:
				Input.action_press("move_right")
				Input.action_press("jump")
				chase_jump = true

		await physics_frame
		if level.mode != "play":
			break

	_release_inputs()
	_check(launch_hit, "the launch ram can be redirected during its charge")
	_check(carriage_hit, "the moving carriage accepts a mid-air correction")
	_check(rode_moving_carriage, "the player intercepts and rides the moving carriage")
	_check(counter_hit, "the opposing ram can be redirected from the moving encounter")
	_check(used_return, "a leftward carriage return becomes the route to the gantry")
	_check(level.mode == "complete", "the continuous launch, counter, and return route reaches the exit (mode %s, player %s, carriage %.1f/%.1f, event %s)" % [level.mode, level.player.position, level.carriage.position.x, level.carriage.velocity_x, level.last_event])

	level.mode = "complete"
	level.player.active = false
	for actor in level.rams:
		actor.set_physics_process(false)
	level.carriage.set_physics_process(false)
	await create_timer(0.2).timeout
	level.free()
	await process_frame
	if failures.is_empty():
		print("KINETIC ROUTE PASS: moving catch, correction, counter-ram redirect, chase recovery, and useful return")
		quit(0)
	else:
		for failure in failures:
			printerr("KINETIC ROUTE FAIL: ", failure)
		quit(1)

func _align_over(player_x: float, target_x: float) -> void:
	if player_x < target_x - 5.0:
		Input.action_press("move_right")
		Input.action_release("move_left")
	elif player_x > target_x + 5.0:
		Input.action_press("move_left")
		Input.action_release("move_right")
	else:
		Input.action_release("move_left")
		Input.action_release("move_right")

func _release_inputs() -> void:
	for action in ["move_left", "move_right", "jump", "attack"]:
		Input.action_release(action)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
