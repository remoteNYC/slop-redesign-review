extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var prototype = (load("res://scenes/kinetic_prototype.tscn") as PackedScene).instantiate()
	root.add_child(prototype)
	await physics_frame
	await physics_frame

	Input.action_press("move_right")
	Input.action_press("jump")
	for frame in 40:
		await physics_frame
		if frame == 15:
			Input.action_release("jump")
		if prototype.player.position.x >= 101.0:
			break
	Input.action_release("move_right")
	Input.action_release("jump")
	Input.action_press("move_left")
	for _frame in 7:
		await physics_frame
	Input.action_release("move_left")

	for _frame in 80:
		await physics_frame
		if prototype.player.is_on_floor():
			break
	_check(prototype.mode == "play" and prototype.player.position.x > prototype.ram.position.x, "player can bait from the ram's right side")

	for _frame in 90:
		await physics_frame
		if prototype.ram.state == "windup" and prototype.ram.state_time <= 0.16:
			break
	Input.action_press("jump")
	for _frame in 10:
		await physics_frame
	Input.action_release("jump")
	for _frame in 40:
		await physics_frame
		if prototype.ram.state == "coast":
			break
	Input.action_press("move_right")
	for _frame in 4:
		await physics_frame
	Input.action_press("attack")
	for _frame in 5:
		await physics_frame
	Input.action_release("attack")
	var rebounded: bool = prototype.player.velocity.y < -170.0
	_check(rebounded, "timed medium strike rebounds from the charging ram (player %s, ram x %.1f v %.1f)" % [prototype.player.position, prototype.ram.position.x, prototype.ram.velocity_x])

	for _frame in 80:
		await physics_frame
		if prototype.carriage.velocity_x > 1.0:
			break
	_check(prototype.carriage.velocity_x > 40.0, "the struck ram reaches and moves the carriage (v %.1f)" % prototype.carriage.velocity_x)

	var landed_on_carriage := false
	for _frame in 100:
		await physics_frame
		if prototype.mode != "play":
			break
		if prototype.player.position.x > prototype.carriage.position.x + 10.0:
			Input.action_release("move_right")
			Input.action_press("move_left")
		elif prototype.player.position.x < prototype.carriage.position.x - 10.0:
			Input.action_release("move_left")
			Input.action_press("move_right")
		if prototype.player.is_on_floor() and absf(prototype.player.position.y - 141.0) < 3.0:
			landed_on_carriage = true
			break
	Input.action_release("move_right")
	Input.action_release("move_left")
	_check(landed_on_carriage, "the rebound can land on the moving carriage (player %s, cart %s)" % [prototype.player.position, prototype.carriage.position])

	if landed_on_carriage:
		for _frame in 60:
			await physics_frame
			if prototype.carriage.position.x >= 238.0 or prototype.mode != "play":
				break
		Input.action_press("move_right")
		for _frame in 24:
			await physics_frame
			if prototype.player.position.x >= prototype.carriage.position.x + 20.0:
				break
		Input.action_press("jump")
		for _frame in 24:
			await physics_frame
		Input.action_release("jump")
		for _frame in 32:
			await physics_frame
		Input.action_release("move_right")
	_check(prototype.mode == "complete", "controlled interaction reaches the exit (mode %s, player %s, cart x %.1f, ram %s v %.1f, event %s)" % [prototype.mode, prototype.player.position, prototype.carriage.position.x, prototype.ram.position, prototype.ram.velocity_x, prototype.last_event])

	_release_inputs()
	prototype.mode = "complete"
	prototype.player.active = false
	prototype.ram.set_physics_process(false)
	prototype.carriage.set_physics_process(false)
	await create_timer(0.5).timeout
	prototype.free()
	await process_frame
	if failures.is_empty():
		print("KINETIC ROUTE PASS: bait, medium strike, ram impact, moving landing, ride, and exit")
		quit(0)
	else:
		for failure in failures:
			printerr("KINETIC ROUTE FAIL: ", failure)
		quit(1)

func _release_inputs() -> void:
	for action in ["move_left", "move_right", "jump", "attack"]:
		Input.action_release(action)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
