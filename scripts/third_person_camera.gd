extends Camera3D
class_name ThirdPersonCamera

@export_group("Target")
@export var target_path: NodePath = ^"../Player"
@export var focus_height := 1.3
@export var distance := 6.0

@export_group("Feel")
@export var follow_smoothing := 10.0
@export var mouse_sensitivity := 0.0025
@export var initial_pitch_degrees := -14.0
@export var min_pitch_degrees := -65.0
@export var max_pitch_degrees := 55.0
@export var base_fov := 70.0
@export var swing_fov_gain := 5.0
@export var fov_full_angular_speed := 2.4
@export var fov_smoothing := 6.0
@export var speed_fov_gain := 2.0
@export var speed_for_full_response := 18.0
@export var look_ahead_distance := 0.9
@export var landing_recovery_smoothing := 16.0

@export_group("Collision")
@export var collision_margin := 0.3
@export_flags_3d_physics var camera_collision_mask := 1

var yaw := 0.0
var pitch := 0.0
var _target: Node3D
var _smooth_focus := Vector3.ZERO


func _ready() -> void:
	_target = get_node_or_null(target_path) as Node3D
	if _target == null:
		push_error("ThirdPersonCamera target_path does not point to a Node3D")
		return
	pitch = deg_to_rad(initial_pitch_degrees)
	fov = base_fov
	_smooth_focus = _target.global_position + Vector3.UP * focus_height
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_update_transform(0.0, true)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clampf(
			pitch - event.relative.y * mouse_sensitivity,
			deg_to_rad(min_pitch_degrees),
			deg_to_rad(max_pitch_degrees)
		)
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if _target != null:
		_update_transform(delta, false)
		var player := _target as TraversalPlayer
		var angular_speed := player.swing_angular_speed if player != null else 0.0
		var horizontal_speed := player.horizontal_speed() if player != null else 0.0
		var desired_fov := base_fov + swing_fov_gain * clampf(angular_speed / maxf(fov_full_angular_speed, 0.1), 0.0, 1.0)
		desired_fov += speed_fov_gain * clampf(horizontal_speed / maxf(speed_for_full_response, 0.1), 0.0, 1.0)
		fov = lerpf(fov, desired_fov, 1.0 - exp(-fov_smoothing * delta))


func _update_transform(delta: float, immediate: bool) -> void:
	var desired_focus := _target.global_position + Vector3.UP * focus_height
	var player := _target as TraversalPlayer
	if player != null:
		var planar_velocity := Vector3(player.velocity.x, 0.0, player.velocity.z)
		if planar_velocity.length_squared() > 0.1:
			desired_focus += planar_velocity.normalized() * look_ahead_distance * clampf(planar_velocity.length() / maxf(speed_for_full_response, 0.1), 0.0, 1.0)
	if immediate:
		_smooth_focus = desired_focus
	else:
		var smoothing := landing_recovery_smoothing if player != null and player.is_on_floor() else follow_smoothing
		_smooth_focus = _smooth_focus.lerp(desired_focus, 1.0 - exp(-smoothing * delta))

	var orbit := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)
	var desired_position := _smooth_focus + orbit * Vector3(0.0, 0.0, distance)
	var query := PhysicsRayQueryParameters3D.create(_smooth_focus, desired_position, camera_collision_mask)
	query.exclude = [_target.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var to_hit: Vector3 = hit.position - _smooth_focus
		desired_position = _smooth_focus + to_hit.normalized() * maxf(0.5, to_hit.length() - collision_margin)

	global_position = desired_position
	look_at(_smooth_focus, Vector3.UP)


func planar_forward() -> Vector3:
	var result := -global_basis.z
	result.y = 0.0
	return result.normalized()


func planar_right() -> Vector3:
	var result := global_basis.x
	result.y = 0.0
	return result.normalized()
