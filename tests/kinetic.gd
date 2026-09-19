extends SceneTree

const RamScript = preload("res://scripts/enemy.gd")
const CarriageScript = preload("res://scripts/moving_platform.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_strike_transfer()
	_test_playthrough_states()
	_test_deterministic_damping()
	await _test_room_strikes_collision_and_reset()
	if failures.is_empty():
		print("KINETIC PASS: weak, medium, strong, reversal, stop rebound, recovery, collision, and reset")
		quit(0)
	else:
		for failure in failures:
			printerr("KINETIC FAIL: ", failure)
		quit(1)

func _test_strike_transfer() -> void:
	var weak := _ram_speed_after_strike(0.0)
	var medium := _ram_speed_after_strike(60.0)
	var strong := _ram_speed_after_strike(150.0)
	var opposite := _ram_speed_after_strike(-150.0)
	_check(is_equal_approx(weak, 60.0), "near-vertical strike damps a 150 ram charge to 60 (found %.2f)" % weak)
	_check(is_equal_approx(medium, 126.0), "medium strike produces a distinct 126 ram speed (found %.2f)" % medium)
	_check(is_equal_approx(strong, 225.0), "strong strike produces a distinct 225 ram speed (found %.2f)" % strong)
	_check(opposite < 0.0 and is_equal_approx(opposite, -105.0), "opposite strike reverses the ram (found %.2f)" % opposite)
	_check(strong - medium > 70.0 and medium - weak > 60.0, "weak, medium, and strong bands remain clearly separated")

func _test_playthrough_states() -> void:
	var weak_carriage = _new_carriage()
	weak_carriage.receive_ram_impact(_ram_speed_after_strike(0.0))
	_settle(weak_carriage)
	_check(weak_carriage.position.x > 190.0 and weak_carriage.position.x < 200.0, "B undershoot stops near the left side (x %.2f)" % weak_carriage.position.x)

	var medium_carriage = _new_carriage()
	medium_carriage.receive_ram_impact(_ram_speed_after_strike(60.0))
	_settle(medium_carriage)
	_check(medium_carriage.position.x > 248.0 and medium_carriage.position.x < 264.0, "C controlled push settles in the useful jump window (x %.2f)" % medium_carriage.position.x)

	var strong_carriage = _new_carriage()
	var stop_trace := {"hits": 0, "speed": 0.0}
	strong_carriage.stop_rebounded.connect(func(side: int, _incoming: float, outgoing: float) -> void:
		if side > 0:
			stop_trace["hits"] = int(stop_trace["hits"]) + 1
			stop_trace["speed"] = outgoing
	)
	strong_carriage.receive_ram_impact(_ram_speed_after_strike(150.0))
	for _step in 600:
		strong_carriage.advance_kinetic(1.0 / 120.0)
		if int(stop_trace["hits"]) > 0:
			break
	_check(int(stop_trace["hits"]) == 1, "A strong push reaches the far stop")
	_check(float(stop_trace["speed"]) < -50.0, "A far stop returns substantial leftward speed (%.2f)" % float(stop_trace["speed"]))

	var speed_before_recovery: float = strong_carriage.velocity_x
	strong_carriage.receive_kinetic_strike(155.0)
	_check(absf(strong_carriage.velocity_x) < absf(speed_before_recovery), "D opposite carriage strike brakes the rebound (%.2f -> %.2f)" % [speed_before_recovery, strong_carriage.velocity_x])
	_settle(strong_carriage)
	_check(strong_carriage.position.x > 265.0, "D corrected carriage remains in a recoverable exit position (x %.2f)" % strong_carriage.position.x)
	weak_carriage.free()
	medium_carriage.free()
	strong_carriage.free()

func _test_deterministic_damping() -> void:
	var first = _new_carriage()
	var second = _new_carriage()
	first.velocity_x = 73.0
	second.velocity_x = 73.0
	for _step in 240:
		first.advance_kinetic(1.0 / 120.0)
		second.advance_kinetic(1.0 / 120.0)
	_check(is_equal_approx(first.position.x, second.position.x) and is_equal_approx(first.velocity_x, second.velocity_x), "carriage damping is deterministic")
	first.free()
	second.free()

func _test_room_strikes_collision_and_reset() -> void:
	var scene := load("res://scenes/kinetic_prototype.tscn") as PackedScene
	var prototype = scene.instantiate()
	root.add_child(prototype)
	await physics_frame
	await physics_frame
	Input.action_press("move_right")
	for _frame in 4:
		await physics_frame
	Input.action_release("move_right")
	var medium_input_speed: float = prototype.player.velocity.x
	prototype.reset_encounter()
	await process_frame
	Input.action_press("move_right")
	for _frame in 14:
		await physics_frame
	Input.action_release("move_right")
	var strong_input_speed: float = prototype.player.velocity.x
	_check(medium_input_speed > 45.0 and medium_input_speed < 90.0, "a short directional press reproducibly creates a medium-speed band (%.2f)" % medium_input_speed)
	_check(strong_input_speed > 145.0, "a held direction reproducibly reaches the strong-speed band (%.2f)" % strong_input_speed)

	prototype.reset_encounter()
	await process_frame
	prototype.ram.state = "coast"
	prototype.ram.velocity_x = 150.0
	prototype.player.global_position = prototype.ram.global_position + Vector2(0, -28)
	prototype.player.velocity = Vector2(60, 0)
	await physics_frame
	Input.action_press("attack")
	await physics_frame
	await physics_frame
	Input.action_release("attack")
	_check(prototype.player.velocity.y < -180.0, "real downward strike rebounds from the kinetic ram")
	_check(prototype.ram.velocity_x > 90.0 and prototype.ram.velocity_x < 145.0, "real medium-speed strike changes ram momentum (%.2f)" % prototype.ram.velocity_x)

	prototype.reset_encounter()
	await process_frame
	prototype.ram.state = "recover"
	prototype.ram.state_time = 10.0
	prototype.player.global_position = prototype.carriage.global_position + Vector2(0, -34)
	prototype.player.velocity = Vector2(155, 0)
	await physics_frame
	Input.action_press("attack")
	await physics_frame
	await physics_frame
	Input.action_release("attack")
	_check(prototype.player.velocity.y < -180.0, "real downward strike rebounds from the carriage")
	_check(prototype.carriage.velocity_x > 25.0 and prototype.carriage.velocity_x < 40.0, "direct carriage strike makes a smaller correction (%.2f)" % prototype.carriage.velocity_x)

	prototype.reset_encounter()
	await process_frame
	prototype.player.active = false
	prototype.ram.position = Vector2(prototype.carriage.position.x - 43.0, prototype.ram.position.y)
	prototype.ram.velocity_x = 120.0
	prototype.ram.state = "coast"
	prototype.carriage.velocity_x = 0.0
	await physics_frame
	await physics_frame
	_check(prototype.carriage.velocity_x > 60.0, "physical ram/carriage contact transfers current velocity (carriage %.2f)" % prototype.carriage.velocity_x)
	_check(prototype.ram.velocity_x < 0.0, "ram remains and rebounds after carriage contact (ram %.2f)" % prototype.ram.velocity_x)
	prototype.carriage.position.x = 245.0
	prototype.carriage.velocity_x = -31.0
	prototype.ram.position.x = 250.0
	prototype.ram.velocity_x = 90.0
	prototype.reset_encounter()
	_check(prototype.carriage.position.distance_to(prototype.CARRIAGE_START) < 2.0 and absf(prototype.carriage.velocity_x) < 1.0, "reset restores carriage position and velocity")
	_check(prototype.ram.position == prototype.RAM_START and is_zero_approx(prototype.ram.velocity_x), "reset restores ram position and velocity")
	_check(prototype.player.position == prototype.START_POSITION and prototype.player.active, "reset restores the player")

	prototype.carriage.position.x = 256.0
	prototype.ram.position.x = prototype.RAM_LEFT
	prototype.ram.state = "recover"
	prototype.ram.state_time = 10.0
	prototype.player.reset_at(Vector2(276, 140))
	await create_timer(0.1).timeout
	Input.action_press("move_right")
	Input.action_press("jump")
	await create_timer(0.32).timeout
	Input.action_release("jump")
	await create_timer(0.38).timeout
	Input.action_release("move_right")
	_check(prototype.mode == "complete", "a carriage in the controlled window makes the upper-right exit reachable (mode %s, player %s, velocity %s)" % [prototype.mode, prototype.player.position, prototype.player.velocity])
	prototype.mode = "complete"
	prototype.player.active = false
	await create_timer(0.5).timeout
	prototype.free()
	await process_frame

func _ram_speed_after_strike(player_speed: float) -> float:
	var ram = RamScript.new()
	ram.configure_kinetic_ram(Vector2.ZERO, -100.0, 100.0)
	ram.velocity_x = 150.0
	ram.receive_kinetic_strike(player_speed)
	var result: float = ram.velocity_x
	ram.free()
	return result

func _new_carriage():
	var carriage = CarriageScript.new()
	carriage.configure_kinetic(Vector2(176, 166), 176.0, 280.0)
	return carriage

func _settle(carriage) -> void:
	for _step in 2400:
		carriage.advance_kinetic(1.0 / 120.0)
		if is_zero_approx(carriage.velocity_x):
			return

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
