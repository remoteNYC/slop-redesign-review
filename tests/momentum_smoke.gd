extends SceneTree

const REQUIRED_ACTIONS := [
	"move_forward", "move_back", "move_left", "move_right",
	"jump", "dash", "tether", "restart",
]

var _ring_intensity := 0.0


func _initialize() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	for action in REQUIRED_ACTIONS:
		if not InputMap.has_action(action) or InputMap.action_get_events(action).is_empty():
			_fail("Missing input action: %s" % action)
			return
	var tether_event := InputMap.action_get_events("tether")[0] as InputEventMouseButton
	if tether_event == null or tether_event.button_index != MOUSE_BUTTON_RIGHT:
		_fail("Tether must use right mouse")
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("Main scene could not load")
		return
	var arena := packed.instantiate()
	root.add_child(arena)
	var player := arena.get_node("Player") as TraversalPlayer
	var rigid := arena.get_node("RigidFirst") as TetherAnchor
	var bamboo := arena.get_node("ElasticBamboo") as TetherAnchor
	var bell := arena.get_node("ShrineBell") as TetherAnchor
	if player == null or rigid == null or bamboo == null or bell == null:
		_fail("A required mechanic node is missing")
		return
	if get_nodes_in_group("tether_anchors").size() != 6:
		_fail("Expected six test anchors")
		return
	if rigid.kind != TetherAnchor.Kind.RIGID or bamboo.kind != TetherAnchor.Kind.ELASTIC or bell.kind != TetherAnchor.Kind.RESONANT:
		_fail("Anchor types are incorrect")
		return

	for i in 45:
		await physics_frame
	if not player.is_on_floor():
		_fail("Player did not settle on start terrace")
		return
	if player.targeted_anchor != rigid or not rigid.target_indicator.visible:
		_fail("First anchor is not indicated as the current target")
		return
	var wall := StaticBody3D.new()
	var wall_shape := CollisionShape3D.new()
	var blocker := BoxShape3D.new()
	blocker.size = Vector3(4, 6, 1)
	wall_shape.shape = blocker
	wall.add_child(wall_shape)
	wall.position = Vector3(0, 5, 6)
	arena.add_child(wall)
	await physics_frame
	if player._find_best_tether_anchor() == rigid:
		_fail("Target assist selected an anchor behind a wall")
		return
	wall.free()
	await physics_frame

	var rigid_start := rigid.attach_position()
	rigid.receive_tension(Vector3(100, 20, 0))
	rigid.receive_impulse(Vector3(40, 0, 0))
	await physics_frame
	if rigid.attach_position().distance_to(rigid_start) > 0.001:
		_fail("Rigid anchor moved")
		return

	player.global_position = rigid_start + Vector3(0, -6, 0)
	player.velocity = Vector3(10, 0, 0)
	player.tether_anchor = rigid
	player.rope_length = 6.0
	player._apply_swing_forces(Vector3.ZERO, 1.0 / 60.0)
	var tension := player.tether_tension
	player._detach_tether()
	if tension <= 0.0 or player.velocity.x < 9.5 or absf(player.velocity.y) > 0.5:
		_fail("Rigid release did not retain tangent speed")
		return

	var rest := bamboo.attach_position()
	for i in 60:
		bamboo.receive_tension(Vector3(45, 0, 0))
		await physics_frame
	var low_energy := bamboo.stored_energy()
	var low_boost := bamboo.elastic_release_velocity(Vector3.DOWN, 1.0).length()
	bamboo.attachment.global_position = rest
	bamboo._point_velocity = Vector3.ZERO
	for i in 60:
		bamboo.receive_tension(Vector3(95, 0, 0))
		await physics_frame
	var high_energy := bamboo.stored_energy()
	var high_boost := bamboo.elastic_release_velocity(Vector3.DOWN, 1.0).length()
	if low_energy <= 0.5 or high_energy <= low_energy * 1.5 or high_boost <= low_boost * 1.2:
		_fail("Bamboo bend or release does not scale with force")
		return

	bell.rang.connect(_on_bell_rang)
	var bell_start := bell.attach_position()
	bell.receive_impulse(Vector3(25, 0, 0))
	if bell.angular_speed() <= 0.5 or _ring_intensity <= 0.0:
		_fail("Bell did not transfer impulse into motion and resonance")
		return
	await physics_frame
	if bell.attach_position().distance_to(bell_start) <= 0.001:
		_fail("Bell did not move after impulse")
		return
	for i in 180:
		await physics_frame
	if absf(bell.attach_position().distance_to(bell.global_position) - 3.0) > 0.02:
		_fail("Bell escaped its pendulum constraint")
		return

	print("MOMENTUM_SMOKE_OK: inputs, scene, rigid tangent, force-scaled bamboo, moving resonant bell")
	bell.effect_audio.stop()
	arena.free()
	quit(0)


func _on_bell_rang(_anchor: TetherAnchor, intensity: float) -> void:
	_ring_intensity = intensity


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
