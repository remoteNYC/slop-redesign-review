extends CharacterBody3D
class_name TraversalPlayer

signal tether_attached(anchor: TetherAnchor)
signal tether_released(anchor: TetherAnchor, release_speed: float)

@export_group("References")
@export var camera_path: NodePath = ^"../FollowCamera"

@export_group("Ground Movement")
@export var move_speed := 9.0
@export var ground_acceleration := 32.0
@export var ground_deceleration := 38.0
@export var max_slope_degrees := 46.0
@export var ground_snap_distance := 0.35

@export_group("Air Movement")
@export var air_control_acceleration := 8.0
@export var air_speed_limit := 10.0
@export var gravity_multiplier := 1.0

@export_group("Jump")
@export var jump_speed := 9.5
@export var coyote_time := 0.14
@export var jump_buffer_time := 0.16

@export_group("Dash")
@export var dash_impulse := 13.0
@export var dash_duration := 0.18
@export var dash_cooldown := 0.85
@export var dash_gravity_multiplier := 0.25

@export_group("Tether")
@export var tether_max_range := 25.0
@export var tether_aim_cone_degrees := 48.0
@export_flags_3d_physics var tether_visibility_mask := 1
@export var tether_reconnect_delay := 0.12
@export var tether_length_slack := 0.0
@export var min_tether_length := 2.0
@export var player_tether_mass := 1.0
@export_range(0.0, 1.0, 0.01) var anchor_impulse_transfer := 0.85
@export var swing_control_acceleration := 3.5
@export var max_swing_speed := 35.0

@export_group("Feedback")
@export var wind_full_angular_speed := 2.4
@export var rope_full_tension := 45.0
@export var trail_max_points := 16
@export var visual_turn_speed := 10.0
@export var max_tension_lean_degrees := 20.0
@export var landing_compression := 0.16
@export var visual_recovery_speed := 2.0

@export_group("Recovery")
@export var respawn_height := -22.0
@export var spawn_position := Vector3(0.0, 2.0, 11.0)

var dash_cooldown_remaining := 0.0
var tether_anchor: TetherAnchor
var rope_length := 0.0
var tether_tension := 0.0
var swing_angular_speed := 0.0
var targeted_anchor: TetherAnchor

var _camera: ThirdPersonCamera
var _gravity := 0.0
var _coyote_remaining := 0.0
var _jump_buffer_remaining := 0.0
var _dash_remaining := 0.0
var _reconnect_remaining := 0.0
var _line_mesh: ImmediateMesh
var _line_material: StandardMaterial3D
var _trail_mesh: ImmediateMesh
var _trail_material: StandardMaterial3D
var _trail_points: Array[Vector3] = []
var _visual_stretch := 0.0
var _release_trail_strength := 0.0
@onready var _rope_visual: MeshInstance3D = $RopeVisual
@onready var _trail_visual: MeshInstance3D = $RibbonTrail
@onready var _wind_motes: CPUParticles3D = $WindMotes
@onready var _visual_root: Node3D = $VisualRoot
@onready var _attach_audio: AudioStreamPlayer3D = $AttachAudio
@onready var _release_audio: AudioStreamPlayer3D = $ReleaseAudio
@onready var _wind_audio: AudioStreamPlayer = $WindAudio


func _ready() -> void:
	add_to_group("player")
	_camera = get_node_or_null(camera_path) as ThirdPersonCamera
	if _camera == null:
		push_error("TraversalPlayer camera_path does not point to ThirdPersonCamera")
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	floor_max_angle = deg_to_rad(max_slope_degrees)
	floor_snap_length = ground_snap_distance
	floor_stop_on_slope = true
	floor_constant_speed = true
	_build_debug_line()
	_build_trail()
	var wind_stream := _wind_audio.stream.duplicate() as AudioStreamWAV
	wind_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_wind_audio.stream = wind_stream
	_wind_audio.volume_db = -80.0
	_wind_audio.play()


func _physics_process(delta: float) -> void:
	if _camera == null:
		return
	if Input.is_action_just_pressed("restart") or global_position.y < respawn_height:
		respawn()
		return

	dash_cooldown_remaining = maxf(0.0, dash_cooldown_remaining - delta)
	_dash_remaining = maxf(0.0, _dash_remaining - delta)
	_reconnect_remaining = maxf(0.0, _reconnect_remaining - delta)
	var was_grounded := is_on_floor()
	if was_grounded:
		_coyote_remaining = coyote_time
	else:
		_coyote_remaining = maxf(0.0, _coyote_remaining - delta)

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_remaining = jump_buffer_time
	else:
		_jump_buffer_remaining = maxf(0.0, _jump_buffer_remaining - delta)

	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var move_direction := (_camera.planar_right() * input_vector.x + _camera.planar_forward() * -input_vector.y).normalized()
	_refresh_tether_target()

	if Input.is_action_just_released("tether") and tether_anchor != null:
		_detach_tether()
	if Input.is_action_just_pressed("tether") and tether_anchor == null and _reconnect_remaining <= 0.0:
		_try_attach_tether()

	if Input.is_action_just_pressed("dash") and dash_cooldown_remaining <= 0.0:
		_start_dash(move_direction)

	if tether_anchor != null:
		floor_snap_length = 0.0
		_apply_swing_forces(move_direction, delta)
	else:
		tether_tension = 0.0
		swing_angular_speed = 0.0
		floor_snap_length = ground_snap_distance
		_apply_normal_movement(move_direction, was_grounded, delta)

	var landing_speed := maxf(0.0, -velocity.y)
	move_and_slide()
	if tether_anchor != null:
		_enforce_rope_constraint()
	if not was_grounded and is_on_floor():
		_visual_stretch = -minf(landing_compression, landing_speed * landing_compression / 14.0)


func _apply_normal_movement(direction: Vector3, grounded: bool, delta: float) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	if grounded:
		var desired := direction * move_speed
		var acceleration := ground_acceleration if direction.length_squared() > 0.0 else ground_deceleration
		horizontal = horizontal.move_toward(desired, acceleration * delta)
		if velocity.y <= 0.0:
			velocity.y = -0.1
	else:
		if direction.length_squared() > 0.0 and horizontal.dot(direction) < air_speed_limit:
			horizontal += direction * air_control_acceleration * delta
		var gravity_scale := dash_gravity_multiplier if _dash_remaining > 0.0 else gravity_multiplier
		velocity.y -= _gravity * gravity_scale * delta

	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if _jump_buffer_remaining > 0.0 and _coyote_remaining > 0.0:
		velocity.y = jump_speed
		_coyote_remaining = 0.0
		_jump_buffer_remaining = 0.0
		floor_snap_length = 0.0


func _start_dash(direction: Vector3) -> void:
	if direction.length_squared() == 0.0:
		direction = _camera.planar_forward()
	velocity += direction * dash_impulse
	dash_cooldown_remaining = dash_cooldown
	_dash_remaining = dash_duration


func _try_attach_tether() -> void:
	var best := _find_best_tether_anchor()
	if best != null:
		tether_anchor = best
		rope_length = maxf(min_tether_length, global_position.distance_to(best.attach_position()) + maxf(0.0, tether_length_slack))
		_coyote_remaining = 0.0
		_jump_buffer_remaining = 0.0
		_visual_stretch = 0.04 + minf(0.06, velocity.length() * 0.003)
		_attach_audio.volume_db = linear_to_db(clampf(horizontal_speed() / 18.0, 0.12, 0.9))
		_attach_audio.play()
		tether_attached.emit(best)
		_refresh_tether_target()


func _find_best_tether_anchor() -> TetherAnchor:
	var best: TetherAnchor
	var best_score := -INF
	var camera_forward := -_camera.global_basis.z
	var min_dot := cos(deg_to_rad(tether_aim_cone_degrees))
	for node in get_tree().get_nodes_in_group("tether_anchors"):
		var candidate := node as TetherAnchor
		if candidate == null:
			continue
		var offset := candidate.attach_position() - global_position
		var distance_to_anchor := offset.length()
		if distance_to_anchor > tether_max_range or distance_to_anchor < 1.0:
			continue
		var aim_direction := (candidate.attach_position() - _camera.global_position).normalized()
		var aim_dot := camera_forward.dot(aim_direction)
		if aim_dot < min_dot:
			continue
		var ray := PhysicsRayQueryParameters3D.create(_camera.global_position, candidate.attach_position(), tether_visibility_mask)
		ray.exclude = [get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty() and (hit.position as Vector3).distance_to(candidate.attach_position()) > 0.8:
			continue
		var score := aim_dot * 60.0 - distance_to_anchor * 0.35
		if score > best_score:
			best_score = score
			best = candidate
	return best


func _refresh_tether_target() -> void:
	var next_target: TetherAnchor
	if tether_anchor == null and _reconnect_remaining <= 0.0:
		next_target = _find_best_tether_anchor()
	if next_target == targeted_anchor:
		return
	if targeted_anchor != null:
		targeted_anchor.set_targeted(false)
	targeted_anchor = next_target
	if targeted_anchor != null:
		targeted_anchor.set_targeted(true)


func _detach_tether() -> void:
	# A taut rope removes radial movement, while the tangent and the moving
	# anchor's own velocity carry into free flight.
	var released_anchor := tether_anchor
	if global_position.distance_to(released_anchor.attach_position()) >= rope_length - 0.2:
		var outward := (global_position - released_anchor.attach_position()).normalized()
		var anchor_velocity := released_anchor.attach_velocity()
		velocity = anchor_velocity + (velocity - anchor_velocity).slide(outward)
		velocity += released_anchor.elastic_release_velocity(outward, player_tether_mass)
	var release_speed := velocity.length()
	_visual_stretch = 0.04 + minf(0.11, release_speed * 0.004)
	_release_trail_strength = clampf(release_speed / 20.0, 0.0, 1.0)
	tether_anchor = null
	rope_length = 0.0
	tether_tension = 0.0
	swing_angular_speed = 0.0
	_reconnect_remaining = tether_reconnect_delay
	_release_audio.volume_db = linear_to_db(clampf(release_speed / 27.0, 0.12, 1.0))
	_release_audio.pitch_scale = clampf(0.85 + release_speed * 0.012, 0.85, 1.3)
	_release_audio.play()
	tether_released.emit(released_anchor, release_speed)


func _apply_swing_forces(direction: Vector3, delta: float) -> void:
	var anchor_point := tether_anchor.attach_position()
	var outward := (global_position - anchor_point).normalized()
	var anchor_velocity := tether_anchor.attach_velocity()
	velocity.y -= _gravity * gravity_multiplier * delta
	if direction.length_squared() > 0.0:
		var tangent_input := direction.slide(outward).normalized()
		velocity += tangent_input * swing_control_acceleration * delta
	tether_tension = 0.0
	if global_position.distance_to(anchor_point) >= rope_length - 0.05:
		var relative_velocity := velocity - anchor_velocity
		var radial_speed := relative_velocity.dot(outward)
		if radial_speed > 0.0:
			tether_anchor.receive_impulse(outward * radial_speed * player_tether_mass * anchor_impulse_transfer)
			velocity -= outward * radial_speed
		var tangent_speed := relative_velocity.slide(outward).length()
		swing_angular_speed = tangent_speed / maxf(rope_length, 0.1)
		var gravity_tension := Vector3.DOWN.dot(outward) * _gravity * gravity_multiplier
		tether_tension = maxf(0.0, gravity_tension + tangent_speed * tangent_speed / maxf(rope_length, 0.1)) * player_tether_mass
		tether_anchor.receive_tension(outward * tether_tension)
	else:
		swing_angular_speed = 0.0
	if velocity.length() > max_swing_speed:
		velocity = velocity.normalized() * max_swing_speed


func _enforce_rope_constraint() -> void:
	var anchor_point := tether_anchor.attach_position()
	var offset := global_position - anchor_point
	var length := offset.length()
	if length <= rope_length or length <= 0.001:
		return
	var outward := offset / length
	global_position = anchor_point + outward * rope_length
	var outward_speed := (velocity - tether_anchor.attach_velocity()).dot(outward)
	if outward_speed > 0.0:
		velocity -= outward * outward_speed


func respawn() -> void:
	tether_anchor = null
	rope_length = 0.0
	tether_tension = 0.0
	swing_angular_speed = 0.0
	velocity = Vector3.ZERO
	global_position = spawn_position
	_coyote_remaining = 0.0
	_jump_buffer_remaining = 0.0
	_dash_remaining = 0.0
	dash_cooldown_remaining = 0.0
	_visual_stretch = 0.0
	_release_trail_strength = 0.0


func horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


func _build_debug_line() -> void:
	_line_mesh = ImmediateMesh.new()
	_line_material = StandardMaterial3D.new()
	_line_material.albedo_color = Color(0.58, 0.18, 0.16)
	_line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_line_material.vertex_color_use_as_albedo = true
	_line_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_rope_visual.mesh = _line_mesh


func _build_trail() -> void:
	_trail_mesh = ImmediateMesh.new()
	_trail_material = StandardMaterial3D.new()
	_trail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trail_material.vertex_color_use_as_albedo = true
	_trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_trail_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_trail_visual.mesh = _trail_mesh


func _process(delta: float) -> void:
	if _line_mesh == null:
		return
	_line_mesh.clear_surfaces()
	if tether_anchor != null:
		var start := global_position + Vector3.UP * 1.2
		var end := tether_anchor.attach_position()
		var slack := maxf(0.0, rope_length - start.distance_to(end))
		var tautness := clampf(tether_tension / maxf(rope_full_tension, 0.1), 0.0, 1.0)
		var sag := minf(2.5, slack * 0.45 + (1.0 - tautness) * 0.3)
		var rope_direction := (end - start).normalized()
		var rope_width := lerpf(0.11, 0.045, tautness)
		_line_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _line_material)
		for i in 9:
			var portion := float(i) / 8.0
			var point := start.lerp(end, portion)
			point.y -= sag * 4.0 * portion * (1.0 - portion)
			var side := rope_direction.cross((_camera.global_position - point).normalized()).normalized()
			if side.length_squared() < 0.01:
				side = rope_direction.cross(Vector3.UP).normalized()
			_line_mesh.surface_set_color(Color(0.42 + tautness * 0.33, 0.13 + tautness * 0.06, 0.13, 1.0))
			_line_mesh.surface_add_vertex(to_local(point - side * rope_width * 0.5))
			_line_mesh.surface_add_vertex(to_local(point + side * rope_width * 0.5))
		_line_mesh.surface_end()

	var wind_amount := clampf(swing_angular_speed / maxf(wind_full_angular_speed, 0.1), 0.0, 1.0)
	_wind_audio.volume_db = lerpf(-48.0, -12.0, wind_amount)
	_wind_audio.pitch_scale = lerpf(0.7, 1.4, wind_amount)
	_wind_motes.emitting = wind_amount > 0.25
	_wind_motes.speed_scale = lerpf(0.6, 1.6, wind_amount)
	_wind_motes.color = Color(0.7, 0.75, 0.72, wind_amount * 0.55)
	var lean := -clampf(tether_tension / maxf(rope_full_tension, 0.1), 0.0, 1.0) * deg_to_rad(max_tension_lean_degrees)
	_visual_root.rotation.x = lerpf(_visual_root.rotation.x, lean, 1.0 - exp(-visual_turn_speed * delta))
	var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)
	if horizontal_velocity.length_squared() > 0.5:
		var facing := atan2(-horizontal_velocity.x, -horizontal_velocity.z)
		_visual_root.rotation.y = lerp_angle(_visual_root.rotation.y, facing, 1.0 - exp(-visual_turn_speed * delta))
	_visual_stretch = move_toward(_visual_stretch, 0.0, visual_recovery_speed * delta)
	_visual_root.scale = Vector3(1.0 - _visual_stretch * 0.3, 1.0 + _visual_stretch, 1.0 - _visual_stretch * 0.3)
	_release_trail_strength = move_toward(_release_trail_strength, 0.0, delta * 2.7)
	_update_trail(maxf(wind_amount, _release_trail_strength))


func _update_trail(wind_amount: float) -> void:
	_trail_points.push_front(global_position + Vector3.UP * 0.9)
	while _trail_points.size() > trail_max_points:
		_trail_points.pop_back()
	_trail_mesh.clear_surfaces()
	var visible_points := mini(_trail_points.size(), int(lerpf(2.0, float(trail_max_points), wind_amount)))
	if visible_points < 2:
		return
	var trail_width := lerpf(0.03, 0.23, wind_amount)
	_trail_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _trail_material)
	for i in visible_points:
		var fade := 1.0 - float(i) / float(visible_points)
		var point := _trail_points[i]
		var next_point := _trail_points[mini(i + 1, _trail_points.size() - 1)]
		var tangent := (point - next_point).normalized()
		var side := tangent.cross((_camera.global_position - point).normalized()).normalized()
		if side.length_squared() < 0.01:
			side = _camera.global_basis.x
		_trail_mesh.surface_set_color(Color(0.46, 0.14, 0.13, fade * wind_amount * 0.75))
		_trail_mesh.surface_add_vertex(to_local(point - side * trail_width * fade * 0.5))
		_trail_mesh.surface_add_vertex(to_local(point + side * trail_width * fade * 0.5))
	_trail_mesh.surface_end()
