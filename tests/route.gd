extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game := (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	game._start_game()
	await _climb(game, Vector2(210, 471), 270.0, 405.0, "first ledge")
	await _climb(game, Vector2(984, 396), 1030.0, 330.0, "second ledge")
	await _climb(game, Vector2(1680, 321), 1725.0, 260.0, "bell ledge")
	paused = false
	game.free()
	if failures.is_empty():
		print("ROUTE PASS: all three rebound climbs work with the starting abilities")
		quit(0)
	else:
		for failure in failures:
			printerr("ROUTE FAIL: ", failure)
		quit(1)

func _climb(game: Node, start: Vector2, edge_x: float, top_y: float, label: String) -> void:
	game.player.reset_at(start)
	await create_timer(0.08).timeout
	Input.action_press("jump")
	await create_timer(0.22).timeout
	Input.action_press("attack")
	Input.action_press("move_right")
	await create_timer(0.54).timeout
	Input.action_release("jump")
	Input.action_release("attack")
	Input.action_release("move_right")
	await create_timer(0.08).timeout
	if not (game.player.global_position.x >= edge_x and game.player.global_position.y <= top_y - 7.0):
		failures.append("%s: ended at %s, velocity %s" % [label, game.player.global_position, game.player.velocity])
