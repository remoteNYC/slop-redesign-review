extends Node3D
class_name TetherAnchor

signal rang(anchor: TetherAnchor, intensity: float)

enum Kind { RIGID, ELASTIC, RESONANT }

@export var anchor_label := "ANCHOR"
@export var kind: Kind = Kind.RIGID
@export_group("Shared Response")
@export var mass := 4.0
@export var damping := 0.55
@export_group("Elastic Bamboo")
@export var elastic_stiffness := 32.0
@export var max_deflection := 3.0
@export_range(0.0, 1.0, 0.01) var release_energy_transfer := 0.55
@export var creak_energy_threshold := 4.0
@export_group("Resonant Bell")
@export var ring_force_threshold := 26.0
@export var ring_angular_speed_threshold := 0.75
@export var ring_cooldown := 1.4

@onready var attachment: Node3D = $Attachment
@onready var stem: MeshInstance3D = get_node_or_null("Stem") as MeshInstance3D
@onready var leaves: Node3D = get_node_or_null("Attachment/Leaves") as Node3D
@onready var effect_audio: AudioStreamPlayer3D = get_node_or_null("EffectAudio") as AudioStreamPlayer3D

var target_indicator: MeshInstance3D
var _rest_local := Vector3.ZERO
var _point_velocity := Vector3.ZERO
var _pending_force := Vector3.ZERO
var _ring_cooldown_remaining := 0.0
var _creak_cooldown_remaining := 0.0
var _last_force := 0.0


func _ready() -> void:
	add_to_group("tether_anchors")
	if kind == Kind.RESONANT:
		add_to_group("resonant_anchors")
	_rest_local = attachment.position
	var indicator_mesh := SphereMesh.new()
	indicator_mesh.radius = 1.35
	indicator_mesh.height = 2.7
	var indicator_material := StandardMaterial3D.new()
	indicator_material.albedo_color = Color(0.68, 0.73, 0.68, 0.16)
	indicator_material.emission_enabled = true
	indicator_material.emission = Color(0.14, 0.19, 0.17)
	indicator_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	indicator_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	target_indicator = MeshInstance3D.new()
	target_indicator.mesh = indicator_mesh
	target_indicator.material_override = indicator_material
	target_indicator.visible = false
	attachment.add_child(target_indicator)


func set_targeted(targeted: bool) -> void:
	if target_indicator != null:
		target_indicator.visible = targeted


func attach_position() -> Vector3:
	return attachment.global_position


func attach_velocity() -> Vector3:
	return _point_velocity


func angular_speed() -> float:
	if kind != Kind.RESONANT:
		return 0.0
	return _point_velocity.length() / maxf(_rest_local.length(), 0.1)


func stored_energy() -> float:
	if kind != Kind.ELASTIC:
		return 0.0
	var displacement := attachment.global_position - to_global(_rest_local)
	return 0.5 * elastic_stiffness * displacement.length_squared()


func receive_tension(force: Vector3) -> void:
	if kind == Kind.RIGID:
		return
	_pending_force += force
	_last_force = force.length()
	if kind == Kind.RESONANT and _last_force >= ring_force_threshold and angular_speed() >= ring_angular_speed_threshold:
		_ring(_last_force)


func receive_impulse(impulse: Vector3) -> void:
	if kind == Kind.RIGID:
		return
	if kind == Kind.RESONANT:
		var radial := (attachment.global_position - global_position).normalized()
		impulse = impulse.slide(radial)
	_point_velocity += impulse / maxf(mass, 0.1)
	if kind == Kind.RESONANT and impulse.length() >= ring_force_threshold * 0.25:
		_ring(impulse.length() * 4.0)


func elastic_release_velocity(rope_outward: Vector3, player_mass: float) -> Vector3:
	if kind != Kind.ELASTIC:
		return Vector3.ZERO
	var displacement := attachment.global_position - to_global(_rest_local)
	var rebound := (-displacement * elastic_stiffness).slide(rope_outward)
	var energy := stored_energy()
	if rebound.length_squared() < 0.01 or energy < 0.05:
		return Vector3.ZERO
	var launch_speed := sqrt(2.0 * energy / maxf(player_mass, 0.1)) * release_energy_transfer
	var delta_velocity := rebound.normalized() * launch_speed
	_point_velocity -= delta_velocity * player_mass / maxf(mass, 0.1)
	return delta_velocity


func _physics_process(delta: float) -> void:
	_ring_cooldown_remaining = maxf(0.0, _ring_cooldown_remaining - delta)
	_creak_cooldown_remaining = maxf(0.0, _creak_cooldown_remaining - delta)
	if kind == Kind.RIGID:
		return

	var old_point := attachment.global_position
	var point := old_point
	if kind == Kind.ELASTIC:
		var rest := to_global(_rest_local)
		var displacement := point - rest
		var acceleration := (-displacement * elastic_stiffness - _point_velocity * damping + _pending_force) / maxf(mass, 0.1)
		_point_velocity += acceleration * delta
		point += _point_velocity * delta
		var offset := point - rest
		if offset.length() > max_deflection:
			point = rest + offset.normalized() * max_deflection
	else:
		var pivot := global_position
		var hanger_length := maxf(_rest_local.length(), 0.1)
		var gravity := float(ProjectSettings.get_setting("physics/3d/default_gravity"))
		_point_velocity += (Vector3.DOWN * gravity + _pending_force / maxf(mass, 0.1)) * delta
		_point_velocity *= exp(-damping * delta)
		point += _point_velocity * delta
		var radial := (point - pivot).normalized()
		point = pivot + radial * hanger_length

	_point_velocity = (point - old_point) / delta
	attachment.global_position = point
	if kind == Kind.RESONANT:
		var hang_direction := (point - global_position) / maxf(_rest_local.length(), 0.1)
		attachment.rotation.z = clampf(hang_direction.x * 0.45, -0.4, 0.4)
		attachment.rotation.x = clampf(-hang_direction.z * 0.45, -0.4, 0.4)
	_pending_force = Vector3.ZERO
	_update_stem()
	_update_feedback()
	if kind == Kind.RESONANT and angular_speed() >= ring_angular_speed_threshold and _last_force >= ring_force_threshold:
		_ring(maxf(_last_force, angular_speed() * mass * 2.0))
	_last_force = 0.0


func _ring(strength: float) -> void:
	if _ring_cooldown_remaining > 0.0:
		return
	_ring_cooldown_remaining = ring_cooldown
	var intensity := clampf(strength / maxf(ring_force_threshold, 0.1), 0.0, 2.0)
	if effect_audio != null:
		effect_audio.pitch_scale = clampf(0.75 + angular_speed() * 0.18 + intensity * 0.08, 0.75, 1.5)
		effect_audio.volume_db = linear_to_db(clampf(intensity * 0.5, 0.08, 1.0))
		effect_audio.play()
	rang.emit(self, intensity)


func _update_stem() -> void:
	if stem == null:
		return
	var endpoint := to_local(attachment.global_position)
	if endpoint.length() < 0.01:
		return
	stem.position = endpoint * 0.5
	stem.quaternion = Quaternion(Vector3.UP, endpoint.normalized())
	stem.scale.y = endpoint.length() / maxf(_rest_local.length(), 0.1)


func _update_feedback() -> void:
	if kind != Kind.ELASTIC:
		return
	var energy := stored_energy()
	if leaves != null:
		var bend := attachment.global_position - to_global(_rest_local)
		leaves.rotation.z = clampf(bend.x * 0.16, -0.45, 0.45)
		leaves.rotation.x = clampf(-bend.z * 0.16, -0.45, 0.45)
	if effect_audio != null and energy >= creak_energy_threshold and _creak_cooldown_remaining <= 0.0:
		_creak_cooldown_remaining = 0.35
		effect_audio.pitch_scale = clampf(0.75 + energy * 0.012, 0.75, 1.35)
		effect_audio.volume_db = linear_to_db(clampf(energy / 55.0, 0.06, 0.75))
		effect_audio.play()
