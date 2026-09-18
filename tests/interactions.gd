extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game := (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	game._start_game()
	await create_timer(0.8).timeout
	var walker: Area2D
	for child in game.level.get_children():
		if child is Area2D and child.get("kind") == "walker":
			walker = child
			break
	_check(walker != null, "walker exists")
	if walker != null:
		game.player.global_position = walker.global_position
		game.player.velocity = Vector2.ZERO
		await create_timer(0.07).timeout
		_check(game.player.health == 2, "enemy body contact costs one health")
		await create_timer(0.2).timeout
		game.player.global_position = walker.global_position + Vector2(0, -20)
		game.player.velocity = Vector2(0, 35)
		Input.action_press("attack")
		await create_timer(0.07).timeout
		Input.action_release("attack")
		_check(not is_instance_valid(walker), "downward attack defeats walker (attack %.2f, hurt %.2f, pos %s)" % [game.player.attack_time, game.player.hurt_lock, game.player.global_position])
		_check(game.player.velocity.y < -150.0, "enemy hit rebounds player (velocity %s)" % game.player.velocity)
	game.player.global_position = Vector2(660, 515)
	game.player.velocity = Vector2.ZERO
	await create_timer(0.07).timeout
	_check(game.mode == "dead", "pit spikes are lethal")
	await create_timer(0.6).timeout
	_check(game.mode == "play", "hazard death respawns quickly (mode %s, pos %s)" % [game.mode, game.player.global_position])
	var platform: AnimatableBody2D
	for child in game.level.get_children():
		if child is AnimatableBody2D:
			platform = child
			break
	_check(platform != null, "moving platform exists")
	if platform != null:
		game.player.reset_at(platform.global_position + Vector2(0, -14))
		await create_timer(0.1).timeout
		var player_x: float = game.player.global_position.x
		var platform_x: float = platform.global_position.x
		await create_timer(0.18).timeout
		var delta_player: float = game.player.global_position.x - player_x
		if is_instance_valid(platform):
			var delta_platform: float = platform.global_position.x - platform_x
			_check(absf(delta_player - delta_platform) < 7.0, "platform carries player (player %.1f, platform %.1f)" % [delta_player, delta_platform])
		else:
			failures.append("platform was rebuilt after player fell")
	var crusher: Area2D
	for child in game.level.get_children():
		if child is Area2D and child.has_signal("crushed_player"):
			crusher = child
			break
	_check(crusher != null, "crusher exists")
	if crusher != null:
		game.player.reset_at(Vector2(958, 396))
		crusher.clock = 0.7
		await create_timer(0.14).timeout
		_check(game.mode == "dead", "timed crusher is lethal when it drops")
		await create_timer(0.52).timeout
	paused = false
	game.free()
	if failures.is_empty():
		print("INTERACTIONS PASS: enemy damage, defeat, spikes, respawn, moving platform, crusher")
		quit(0)
	else:
		for failure in failures:
			printerr("INTERACTIONS FAIL: ", failure)
		quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
