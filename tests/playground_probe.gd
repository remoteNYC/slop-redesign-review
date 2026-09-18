extends SceneTree

const DT := 1.0 / 60.0
var arena
var puppet

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = load("res://scenes/main.tscn").instantiate()
	root.add_child(arena)
	puppet = arena.player
	puppet.set_physics_process(false)
	# The probe advances many physics frames synchronously; do not queue audio.
	puppet.attached.disconnect(arena._on_attached)
	puppet.released.disconnect(arena._on_released)
	puppet.landed.disconnect(arena._on_landed)
	puppet.set_profile("B")
	var first = arena.anchors[0]
	var early := _release_sample(first, 16)
	var late := _release_sample(first, 38)
	var timing_difference := early.distance_to(late)
	print("release velocities: early=", early, " late=", late, " difference=", timing_difference)
	if timing_difference < 90.0:
		push_error("Release timing had too little effect on trajectory")
		_finish(1)
		return
	var first_successes := _count_landing_windows(Vector2(120, 580), first, 13, 20, 650.0, 970.0, 573.0)
	var second_successes := _count_landing_windows(Vector2(730, 555), arena.anchors[1], 10, 18, 1090.0, 1350.0, 528.0)
	var final_successes := _count_landing_windows(Vector2(1480, 615), arena.anchors[4], 10, 18, 1890.0, 2400.0, 573.0)
	print("landing windows: first=", first_successes, " second=", second_successes, " final=", final_successes)
	if first_successes == 0 or second_successes == 0 or final_successes == 0:
		push_error("At least one required landing has no tested release window")
		_finish(1)
		return
	if not _chain_probe(arena.anchors[1], arena.anchors[2]):
		push_error("Two-anchor chain could not be performed")
		_finish(1)
		return
	print("PASS: stable constraint, timing effect, three landings, two-anchor chain")
	_finish(0)

func _finish(code: int) -> void:
	arena.free()
	arena = null
	puppet = null
	quit(code)

func _reset_state(point: Vector2, initial_velocity: Vector2) -> void:
	puppet.release_thread()
	puppet.global_position = point
	puppet.velocity = initial_velocity
	puppet.on_floor = false
	puppet.coyote_time = 0.0
	puppet.jump_buffer = 0.0
	puppet.recovery_time = 0.0
	puppet.checkpoint = Vector2(120, 580)
	puppet.checkpoint_index = 0

func _release_sample(anchor: Node2D, frames: int) -> Vector2:
	_reset_state(anchor.global_position + Vector2(-180, 100), Vector2(410, -80))
	if not puppet.attach_to(anchor):
		return Vector2.ZERO
	for i in range(frames):
		puppet.step_physics(DT, 1.0, false, true, anchor.global_position)
		if puppet.global_position.distance_to(anchor.global_position) > puppet.rope_length + 0.2:
			push_error("Rope length exceeded at frame %d" % i)
			_finish(1)
			return Vector2.ZERO
	var at_release: Vector2 = puppet.velocity
	puppet.release_thread()
	return at_release

func _count_landing_windows(start: Vector2, anchor: Node2D, jump_frame: int, run_frames: int, min_x: float, max_x: float, center_y: float) -> int:
	var count := 0
	for release_frame in range(10, 130, 3):
		if _landing_trial(start, anchor, jump_frame, run_frames, release_frame, min_x, max_x, center_y):
			count += 1
	return count

func _landing_trial(start: Vector2, anchor: Node2D, jump_frame: int, run_frames: int, release_frame: int, min_x: float, max_x: float, center_y: float) -> bool:
	_reset_state(start, Vector2.ZERO)
	for i in range(run_frames):
		puppet.step_physics(DT, 1.0, i == jump_frame, false, anchor.global_position)
	for i in range(release_frame):
		puppet.step_physics(DT, 1.0, false, true, anchor.global_position)
	if puppet.tether_anchor == null:
		return false
	puppet.step_physics(DT, 1.0, false, false, anchor.global_position)
	for i in range(110):
		puppet.step_physics(DT, 1.0, false, false, anchor.global_position)
		if puppet.on_floor and puppet.global_position.x >= min_x and puppet.global_position.x <= max_x and absf(puppet.global_position.y - center_y) < 3.0:
			return true
	return false

func _chain_probe(second: Node2D, third: Node2D) -> bool:
	_reset_state(second.global_position + Vector2(-170, 170), Vector2(500, -80))
	if not puppet.attach_to(second):
		return false
	for i in range(20):
		puppet.step_physics(DT, 1.0, false, true, second.global_position)
	puppet.release_thread()
	for i in range(18):
		puppet.step_physics(DT, 1.0, false, false, third.global_position)
	return puppet.attach_to(third) and not puppet.on_floor
