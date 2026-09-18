extends SceneTree

var failures: Array[String] = []
var rebound_count := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for action in ["jump", "attack", "move_left", "move_right"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	var arena := Node2D.new()
	root.add_child(arena)
	var device := (load("res://scripts/rebound_device.gd") as GDScript).new() as Area2D
	device.position = Vector2(100, 100)
	arena.add_child(device)
	var player := (load("res://scripts/player.gd") as GDScript).new() as CharacterBody2D
	player.position = Vector2(100, 76)
	player.rebounded.connect(func(_at: Vector2) -> void: rebound_count += 1)
	arena.add_child(player)
	await physics_frame
	Input.action_press("jump")
	Input.action_press("attack")
	await create_timer(0.05).timeout
	_check(rebound_count == 1, "strike on a device directly below rebounds once")
	var speed_before_release := player.velocity.y
	Input.action_release("jump")
	await create_timer(0.035).timeout
	_check(player.velocity.y < speed_before_release + 55.0, "releasing jump just after a rebound preserves launch speed (before %.1f, after %.1f)" % [speed_before_release, player.velocity.y])
	Input.action_release("attack")
	var floor_body := StaticBody2D.new()
	floor_body.position = Vector2(200, 210)
	var floor_collision := CollisionShape2D.new()
	var floor_shape := RectangleShape2D.new()
	floor_shape.size = Vector2(100, 20)
	floor_collision.shape = floor_shape
	floor_body.add_child(floor_collision)
	arena.add_child(floor_body)
	player.reset_at(Vector2(200, 191))
	await create_timer(0.05).timeout
	Input.action_press("jump")
	await create_timer(0.035).timeout
	var jump_speed_before_release := player.velocity.y
	_check(jump_speed_before_release < -150.0, "ordinary jump launches upward")
	Input.action_release("jump")
	await create_timer(0.035).timeout
	_check(player.velocity.y > jump_speed_before_release + 70.0, "releasing jump still shortens an ordinary jump")
	paused = false
	arena.free()
	if failures.is_empty():
		print("REBOUND PASS: immediate hit keeps its launch speed; ordinary jumps retain variable height")
		quit(0)
	else:
		for failure in failures:
			printerr("REBOUND FAIL: ", failure)
		quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
