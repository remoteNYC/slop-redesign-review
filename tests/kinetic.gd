extends SceneTree

const RamScript = preload("res://scripts/enemy.gd")
const CarriageScript = preload("res://scripts/moving_platform.gd")
const GateScript = preload("res://scripts/kinetic_gate.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var ram = RamScript.new()
	ram.configure_kinetic_ram(Vector2.ZERO, -200.0, 200.0)
	ram.velocity_x = -170.0
	ram.receive_kinetic_strike(165.0)
	_check(ram.velocity_x > 100.0, "an opposite moving strike cleanly reverses a charging ram")
	ram.velocity_x = 80.0
	ram.receive_kinetic_dash(310.0)
	_check(ram.velocity_x > 220.0, "a same-direction dash accelerates the ram to its readable fast band")

	var carriage = CarriageScript.new()
	carriage.configure_kinetic(Vector2(200, 166), 180.0, 400.0)
	carriage.velocity_x = 105.0
	var returned_speed: float = carriage.receive_kinetic_impact(-170.0)
	_check(carriage.velocity_x < -80.0, "a head-on ram reverses the carriage")
	_check(returned_speed > 30.0, "the ram receives a visible return impulse instead of disappearing")

	var first = CarriageScript.new()
	var second = CarriageScript.new()
	first.configure_kinetic(Vector2(200, 166), 180.0, 400.0)
	second.configure_kinetic(Vector2(200, 166), 180.0, 400.0)
	first.velocity_x = 80.0
	second.velocity_x = 80.0
	for _step in 240:
		first._physics_process(1.0 / 120.0)
		second._physics_process(1.0 / 120.0)
	_check(is_equal_approx(first.position.x, second.position.x) and is_equal_approx(first.velocity_x, second.velocity_x), "carriage coast and friction remain deterministic")

	var gate = GateScript.new()
	gate.configure(Vector2.ZERO)
	gate._ready()
	var weak_return: float = gate.receive_kinetic_impact(80.0)
	_check(not gate.is_open and weak_return < 0.0, "a weak gate impact visibly rebounds instead of silently succeeding")
	var strong_return: float = gate.receive_kinetic_impact(170.0)
	_check(gate.is_open and strong_return > 140.0, "a charge-speed impact opens the gate and preserves useful motion")

	ram.free()
	carriage.free()
	first.free()
	second.free()
	gate.free()
	if failures.is_empty():
		print("KINETIC PASS: readable transfer bands, reversal, return impulse, deterministic coast, and shutter threshold")
		quit(0)
	else:
		for failure in failures:
			printerr("KINETIC FAIL: ", failure)
		quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
