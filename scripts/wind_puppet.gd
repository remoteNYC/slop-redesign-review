extends Node2D

signal attached(anchor: Node2D)
signal released(speed: float)
signal landed(speed: float)
signal recovered
signal finished(time_seconds: float)

const PUPPET_TEXTURE := preload("res://assets/sprites/wind_puppet.png")
const RADIUS := 17.0
const TARGET_AIM_RADIUS := 82.0

# Same thread rule in every variant. Only numbers change.
const PROFILES := {
	"A": {"name": "Weight / control", "gravity": 1550.0, "ground_accel": 1800.0, "run_speed": 310.0, "air_accel": 360.0, "swing_drive": 190.0, "jump_speed": 500.0, "range": 420.0, "speed_cap": 900.0},
	"B": {"name": "Quick / responsive", "gravity": 1400.0, "ground_accel": 2400.0, "run_speed": 385.0, "air_accel": 530.0, "swing_drive": 260.0, "jump_speed": 535.0, "range": 440.0, "speed_cap": 1030.0},
	"C": {"name": "Flow / momentum", "gravity": 1320.0, "ground_accel": 1650.0, "run_speed": 410.0, "air_accel": 300.0, "swing_drive": 145.0, "jump_speed": 545.0, "range": 465.0, "speed_cap": 1150.0}
}

var arena: Node2D
var anchors: Array[Node2D] = []
var platforms: Array[Rect2] = []
var profile_key := "B"
var profile: Dictionary = PROFILES["B"]
var velocity := Vector2.ZERO
var tether_anchor: Node2D
var rope_length := 0.0
var rope_tension := 0.0
var on_floor := false
var coyote_time := 0.0
var jump_buffer := 0.0
var recovery_time := 0.0
var landing_flash := 0.0
var checkpoint := Vector2(120, 580)
var checkpoint_index := 0
var attachments := 0
var releases := 0
var recoveries := 0
var elapsed := 0.0
var completed := false
var facing := 1
var sprite: Sprite2D

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = PUPPET_TEXTURE
	sprite.position = Vector2(0, -18)
	add_child(sprite)
	position = checkpoint
	queue_redraw()

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("profile_a"):
		set_profile("A")
	if Input.is_action_just_pressed("profile_b"):
		set_profile("B")
	if Input.is_action_just_pressed("profile_c"):
		set_profile("C")
	if Input.is_action_just_pressed("restart"):
		if Input.is_key_pressed(KEY_SHIFT):
			reset_run()
		else:
			respawn()
	step_physics(delta, Input.get_axis("move_left", "move_right"), Input.is_action_just_pressed("jump"), Input.is_action_pressed("tether"), get_global_mouse_position())

func set_profile(key: String) -> void:
	if PROFILES.has(key):
		profile_key = key
		profile = PROFILES[key]

func find_target(aim_world: Vector2) -> Node2D:
	var closest: Node2D
	var aim_distance := TARGET_AIM_RADIUS
	for anchor in anchors:
		if global_position.distance_to(anchor.global_position) > profile["range"]:
			continue
		var distance := aim_world.distance_to(anchor.global_position)
		if distance < aim_distance:
			closest = anchor
			aim_distance = distance
	return closest

func attach_to(anchor: Node2D) -> bool:
	if anchor == null or global_position.distance_to(anchor.global_position) > profile["range"]:
		return false
	tether_anchor = anchor
	rope_length = maxf(70.0, global_position.distance_to(anchor.global_position))
	attachments += 1
	attached.emit(anchor)
	return true

func release_thread() -> void:
	if tether_anchor == null:
		return
	tether_anchor = null
	rope_tension = 0.0
	releases += 1
	released.emit(velocity.length())

func respawn() -> void:
	tether_anchor = null
	rope_tension = 0.0
	global_position = checkpoint
	velocity = Vector2.ZERO
	on_floor = false
	coyote_time = 0.0
	jump_buffer = 0.0
	recovery_time = 0.0
	completed = false
	recoveries += 1
	recovered.emit()

func reset_run() -> void:
	checkpoint = Vector2(120, 580)
	checkpoint_index = 0
	attachments = 0
	releases = 0
	recoveries = -1 # respawn increments the count.
	elapsed = 0.0
	completed = false
	respawn()

func step_physics(delta: float, axis: float, jump_pressed: bool, tether_held: bool, aim_world: Vector2) -> void:
	if delta <= 0.0:
		return
	elapsed += delta
	landing_flash = maxf(0.0, landing_flash - delta * 4.0)
	if absf(axis) > 0.05:
		facing = 1 if axis > 0.0 else -1
	if on_floor:
		coyote_time = 0.11
	else:
		coyote_time = maxf(0.0, coyote_time - delta)
	jump_buffer = 0.13 if jump_pressed else maxf(0.0, jump_buffer - delta)
	if jump_buffer > 0.0 and coyote_time > 0.0:
		velocity.y = -profile["jump_speed"]
		on_floor = false
		coyote_time = 0.0
		jump_buffer = 0.0
	if tether_held:
		if tether_anchor == null:
			attach_to(find_target(aim_world))
	else:
		release_thread()

	if on_floor and tether_anchor == null:
		velocity.x = move_toward(velocity.x, axis * profile["run_speed"], profile["ground_accel"] * delta)
	elif tether_anchor != null:
		var radial := global_position - tether_anchor.global_position
		var tangent := Vector2(-radial.y, radial.x).normalized()
		velocity += Vector2(axis, 0.0).project(tangent) * profile["swing_drive"] * delta
	elif absf(axis) > 0.05:
		velocity.x += axis * profile["air_accel"] * delta

	velocity.y += profile["gravity"] * delta
	velocity = velocity.limit_length(profile["speed_cap"])
	var previous := global_position
	var next_position := previous + velocity * delta
	var impact_speed := velocity.y
	on_floor = false
	for platform in platforms:
		var previous_bottom := previous.y + RADIUS
		var next_bottom := next_position.y + RADIUS
		if velocity.y >= 0.0 and previous_bottom <= platform.position.y + 5.0 and next_bottom >= platform.position.y and next_position.x + RADIUS > platform.position.x and next_position.x - RADIUS < platform.end.x:
			next_position.y = platform.position.y - RADIUS
			velocity.y = 0.0
			on_floor = true
			if impact_speed > 170.0:
				landing_flash = minf(1.0, impact_speed / 850.0)
				landed.emit(impact_speed)
			break

	rope_tension = 0.0
	if tether_anchor != null:
		var offset := next_position - tether_anchor.global_position
		if offset.length() > rope_length:
			var normal := offset.normalized()
			next_position = tether_anchor.global_position + normal * rope_length
			var outward_speed := velocity.dot(normal)
			if outward_speed > 0.0:
				velocity -= normal * outward_speed
				rope_tension = outward_speed
			if on_floor and next_position.y + RADIUS < previous.y + RADIUS - 2.0:
				on_floor = false
	global_position = next_position

	if global_position.x > 850.0 and checkpoint_index < 1 and global_position.y < 760.0:
		checkpoint_index = 1
		checkpoint = Vector2(730, 555)
	if global_position.x > 1510.0 and checkpoint_index < 2 and global_position.y < 760.0:
		checkpoint_index = 2
		checkpoint = Vector2(1480, 615)
	if global_position.y > 850.0:
		recovery_time += delta
		if recovery_time > 0.75:
			respawn()
	else:
		recovery_time = 0.0
	if global_position.x >= 2250.0 and global_position.y < 700.0 and not completed:
		completed = true
		finished.emit(elapsed)

	# Motion feedback uses actual velocity and tether state.
	sprite.flip_h = facing < 0
	sprite.rotation = clampf(velocity.x / 2600.0, -0.24, 0.24)
	sprite.scale = Vector2(1.0 + landing_flash * 0.12, 1.0 - landing_flash * 0.12)
	queue_redraw()

func _draw() -> void:
	if tether_anchor != null:
		var end := to_local(tether_anchor.global_position)
		var taut := global_position.distance_to(tether_anchor.global_position) >= rope_length - 5.0
		draw_line(Vector2(-5, -25), end, Color("ad4e3d") if taut else Color("8f655f"), 3.2 if taut else 2.2, true)
		draw_circle(end, 4.0, Color("e6c28e"))
	var trail := clampf(velocity.length() / 850.0, 0.0, 1.0)
	if trail > 0.12:
		draw_line(Vector2(-facing * 12, -24), Vector2(-facing * (24.0 + trail * 25.0), -27 - velocity.y * 0.012), Color(0.69, 0.31, 0.25, trail * 0.7), 3.0, true)
