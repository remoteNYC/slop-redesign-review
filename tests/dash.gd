extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for action in ["move_left", "move_right", "aim_up", "aim_down", "jump", "attack", "dash"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	var arena := Node2D.new()
	root.add_child(arena)
	var player := (load("res://scripts/player.gd") as GDScript).new() as CharacterBody2D
	player.position = Vector2(100, 100)
	arena.add_child(player)
	await physics_frame

	var start_x := player.position.x
	Input.action_press("dash")
	for _frame in 10:
		await physics_frame
	Input.action_release("dash")
	_check(player.position.x - start_x > 42.0, "neutral dash follows the facing direction with useful distance")
	_check(not player.dash_ready, "an air dash is spent until a shared refresh condition")

	var floor := StaticBody2D.new()
	floor.position = Vector2(200, 180)
	var floor_collision := CollisionShape2D.new()
	var floor_shape := RectangleShape2D.new()
	floor_shape.size = Vector2(220, 20)
	floor_collision.shape = floor_shape
	floor.add_child(floor_collision)
	arena.add_child(floor)
	player.reset_at(Vector2(200, 160))
	for _frame in 5:
		await physics_frame
	_check(player.is_on_floor() and player.dash_ready, "landing refreshes dash")

	Input.action_press("aim_up")
	Input.action_press("dash")
	for _frame in 5:
		await physics_frame
	Input.action_release("dash")
	Input.action_release("aim_up")
	_check(player.velocity.y < -250.0 and absf(player.velocity.x) < 5.0, "vertical aim produces a true vertical dash")

	var ram := (load("res://scripts/enemy.gd") as GDScript).new() as Area2D
	ram.configure_kinetic_ram(Vector2(280, 160), 240.0, 330.0)
	ram.state = "recover"
	ram.state_time = 2.0
	arena.add_child(ram)
	player.reset_at(Vector2(230, 160))
	await physics_frame
	Input.action_press("move_right")
	Input.action_press("dash")
	for _frame in 12:
		await physics_frame
	Input.action_release("dash")
	Input.action_release("move_right")
	_check(ram.velocity_x > 150.0, "horizontal dash transfers its direction into a ram")
	_check(player.dash_ready and player.velocity.y < 0.0, "kinetic contact refreshes dash and separates the player safely")

	var carriage := (load("res://scripts/moving_platform.gd") as GDScript).new() as AnimatableBody2D
	carriage.configure_kinetic(Vector2(410, 160), 380.0, 520.0)
	arena.add_child(carriage)
	player.reset_at(Vector2(362, 160))
	await physics_frame
	Input.action_press("move_right")
	Input.action_press("dash")
	for _frame in 5:
		await physics_frame
	Input.action_release("dash")
	Input.action_release("move_right")
	_check(carriage.velocity_x > 120.0, "the same dash can relaunch a stalled carriage")

	_release_all()
	arena.free()
	await process_frame
	if failures.is_empty():
		print("DASH PASS: free direction, distance, landing refresh, and kinetic transfer")
		quit(0)
	else:
		for failure in failures:
			printerr("DASH FAIL: ", failure)
		quit(1)

func _release_all() -> void:
	for action in ["move_left", "move_right", "jump", "attack", "dash", "aim_up", "aim_down"]:
		Input.action_release(action)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
