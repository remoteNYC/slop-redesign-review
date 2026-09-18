extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var arena := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(arena)
	var player := arena.get_node("Player") as TraversalPlayer
	for i in 30:
		await physics_frame
	Input.action_press("move_forward")
	for i in 180:
		await physics_frame
		if player.global_position.z < 0.5:
			break
	print("EDGE ", player.global_position, " velocity=", player.velocity)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	Input.parse_input_event(press)
	await physics_frame
	await physics_frame
	print("ATTACH ", player.global_position, " anchor=", player.tether_anchor, " length=", player.rope_length)
	if player.tether_anchor == null:
		push_error("First beam cannot be attached from takeoff")
		quit(1)
		return
	var released := false
	var landed := false
	var peak_tension := 0.0
	for i in 300:
		await physics_frame
		peak_tension = maxf(peak_tension, player.tether_tension)
		if i % 20 == 0:
			print("SWING %03d " % i, player.global_position, " v=", player.velocity, " tension=", player.tether_tension)
		if not released and player.global_position.z < -12.5 and player.velocity.y > 2.0 and player.velocity.z < -4.0:
			var release := InputEventMouseButton.new()
			release.button_index = MOUSE_BUTTON_RIGHT
			release.pressed = false
			Input.parse_input_event(release)
			Input.action_release("move_forward")
			released = true
		if released and player.is_on_floor() and player.global_position.z < -22.5 and player.global_position.y > -2.0:
			landed = true
			break
	print("END ", player.global_position, " released=", released, " landed=", landed)
	if not landed or peak_tension < 5.0:
		push_error("First rigid swing did not reach landing")
		quit(1)
		return
	player.respawn()
	for i in 30:
		await physics_frame
	Input.action_press("move_forward")
	for i in 180:
		await physics_frame
		if player.global_position.z < 0.5:
			break
	Input.action_press("jump")
	await physics_frame
	await physics_frame
	Input.action_release("jump")
	var jumped_across := false
	for i in 240:
		await physics_frame
		if player.is_on_floor() and player.global_position.z < -22.5 and player.global_position.y > -2.0:
			jumped_across = true
			break
		if player.is_on_floor() and player.global_position.y < -5.0:
			break
	if jumped_across:
		push_error("Basic jump bypasses the first tether gap")
		quit(1)
		return
	print("FIRST_SWING_OK: tether release reaches the landing; basic jump falls to recovery")
	arena.free()
	quit(0)
