extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var arena := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(arena)
	var player := arena.get_node("Player") as TraversalPlayer
	var bamboo := arena.get_node("ElasticBamboo") as TetherAnchor
	for i in 3:
		await physics_frame
	var rest := bamboo.attach_position()
	player.global_position = Vector3(4, 2.05, -50)
	player.velocity = Vector3(0, 0, -8)
	player.tether_anchor = bamboo
	player.rope_length = player.global_position.distance_to(bamboo.attach_position())
	var low_energy := 0.0
	for i in 45:
		await physics_frame
		low_energy = maxf(low_energy, bamboo.stored_energy())
	bamboo.attachment.global_position = rest
	bamboo._point_velocity = Vector3.ZERO
	bamboo._pending_force = Vector3.ZERO
	player.global_position = Vector3(4, 2.05, -50)
	player.velocity = Vector3(0, 0, -16)
	player.tether_anchor = bamboo
	player.rope_length = player.global_position.distance_to(bamboo.attach_position())
	var high_energy := 0.0
	for i in 45:
		await physics_frame
		high_energy = maxf(high_energy, bamboo.stored_energy())
	print("BAMBOO_ENTRY: 8 m/s -> %.2f J, 16 m/s -> %.2f J" % [low_energy, high_energy])
	if low_energy < 1.0 or high_energy < low_energy * 1.5:
		push_error("Faster player entry did not store more bamboo energy")
		quit(1)
		return
	bamboo.effect_audio.stop()
	arena.free()
	quit(0)
