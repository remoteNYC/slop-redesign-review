extends AnimatableBody2D

signal ram_impact(ram_speed: float, carriage_speed: float)
signal directly_struck(player_speed: float, carriage_speed: float)
signal directly_dashed(player_speed: float, carriage_speed: float)
signal stop_rebounded(side: int, incoming_speed: float, outgoing_speed: float)
signal direction_reversed(at: Vector2, speed: float)

const SIZE := Vector2(64, 32)
const MAX_SPEED := 190.0
const RAM_TRANSFER := 0.72
const RETENTION_ON_RAM_HIT := 0.35
const RAM_REBOUND := 0.18
const STRIKE_TRANSFER := 0.30
const STRIKE_RETENTION := 0.72
const DASH_TRANSFER := 0.55
const DASH_RETENTION := 0.45
const STOP_RESTITUTION := 0.68

var rail_left := 0.0
var rail_right := 0.0
var velocity_x := 0.0
var spawn_position := Vector2.ZERO
var kinetic_friction := 7.0
var flash := 0.0
var reset_generation := 0

func configure_kinetic(at: Vector2, left_stop: float, right_stop: float) -> void:
	position = at
	spawn_position = at
	rail_left = left_stop
	rail_right = right_stop

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("kinetic_carriage")
	add_to_group("kinetic_receivers")
	collision_layer = 17
	collision_mask = 0
	sync_to_physics = false
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = SIZE
	collision.shape = shape
	add_child(collision)

func _physics_process(delta: float) -> void:
	flash = maxf(0.0, flash - delta)
	position.x += velocity_x * delta
	if position.x < rail_left:
		var incoming_left := velocity_x
		position.x = rail_left
		velocity_x = absf(velocity_x) * STOP_RESTITUTION
		stop_rebounded.emit(-1, incoming_left, velocity_x)
	elif position.x > rail_right:
		var incoming_right := velocity_x
		position.x = rail_right
		velocity_x = -absf(velocity_x) * STOP_RESTITUTION
		stop_rebounded.emit(1, incoming_right, velocity_x)
		if incoming_right > 20.0:
			direction_reversed.emit(global_position, velocity_x)
	velocity_x = move_toward(velocity_x, 0.0, kinetic_friction * delta)
	if absf(velocity_x) < 0.5:
		velocity_x = 0.0
	queue_redraw()

func receive_kinetic_impact(ram_velocity: float) -> float:
	var previous_velocity := velocity_x
	velocity_x = clampf(previous_velocity * RETENTION_ON_RAM_HIT + ram_velocity * RAM_TRANSFER, -MAX_SPEED, MAX_SPEED)
	flash = 0.16
	ram_impact.emit(ram_velocity, velocity_x)
	if previous_velocity > 20.0 and velocity_x < -20.0:
		direction_reversed.emit(global_position, velocity_x)
	return clampf(-ram_velocity * RAM_REBOUND + previous_velocity * 0.12, -MAX_SPEED, MAX_SPEED)

func receive_kinetic_strike(player_velocity_x: float) -> bool:
	var previous_velocity := velocity_x
	velocity_x = clampf(velocity_x * STRIKE_RETENTION + player_velocity_x * STRIKE_TRANSFER, -MAX_SPEED, MAX_SPEED)
	flash = 0.14
	directly_struck.emit(player_velocity_x, velocity_x)
	if previous_velocity > 20.0 and velocity_x < -20.0:
		direction_reversed.emit(global_position, velocity_x)
	return true

func receive_kinetic_dash(player_velocity_x: float) -> bool:
	var previous_velocity := velocity_x
	velocity_x = clampf(velocity_x * DASH_RETENTION + player_velocity_x * DASH_TRANSFER, -MAX_SPEED, MAX_SPEED)
	flash = 0.18
	directly_dashed.emit(player_velocity_x, velocity_x)
	if previous_velocity > 20.0 and velocity_x < -20.0:
		direction_reversed.emit(global_position, velocity_x)
	return true

func get_rebound_velocity_x() -> float:
	return velocity_x

func accepts_kinetic_impact() -> bool:
	return true

func reset_kinetic(at: Vector2, initial_velocity: float = 0.0) -> void:
	reset_generation += 1
	var generation := reset_generation
	set_physics_process(false)
	sync_to_physics = false
	position = at
	if is_inside_tree():
		PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0.0, at))
	velocity_x = initial_velocity
	flash = 0.0
	queue_redraw()
	if is_inside_tree():
		call_deferred("_finish_reset", at, initial_velocity, generation)
	else:
		set_physics_process(true)

func _finish_reset(at: Vector2, initial_velocity: float, generation: int) -> void:
	if generation != reset_generation:
		return
	position = at
	PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0.0, at))
	velocity_x = initial_velocity
	reset_physics_interpolation()
	set_physics_process(true)

func kinetic_half_width() -> float:
	return SIZE.x * 0.5

func _draw() -> void:
	var edge := Color("fff1b8") if flash > 0.0 else Color("e5b873")
	draw_rect(Rect2(-32, -16, 64, 32), Color("172636"))
	draw_rect(Rect2(-30, -14, 60, 7), Color("a67853"))
	draw_rect(Rect2(-28, -15, 56, 3), edge)
	draw_rect(Rect2(-27, -5, 54, 14), Color("304551"))
	for x in [-24, 0, 24]:
		draw_circle(Vector2(x, 11), 4.0, Color("162230"))
		draw_circle(Vector2(x, 11), 2.0, Color("d8b47b"))
	if absf(velocity_x) > 8.0:
		var direction := signf(velocity_x)
		var arrow_length := clampf(absf(velocity_x) * 0.18, 12.0, 34.0)
		draw_line(Vector2(-direction * 4.0, -8), Vector2(-direction * arrow_length, -8), Color("a9f4dd"), 2.0)
