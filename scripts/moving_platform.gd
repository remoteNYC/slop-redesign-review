extends AnimatableBody2D

signal ram_impact(ram_speed: float, carriage_speed: float)
signal directly_struck(player_speed: float, carriage_speed: float)
signal stop_rebounded(side: int, incoming_speed: float, outgoing_speed: float)

const KINETIC_SIZE := Vector2(64, 32)
const KINETIC_FRICTION := 30.0
const KINETIC_MAX_SPEED := 150.0
const RAM_TRANSFER := 0.55
const CARRIAGE_RETENTION_ON_RAM_HIT := 0.70
const RAM_REBOUND := 0.28
const CARRIAGE_TO_RAM_RETURN := 0.15
const PLAYER_TRANSFER := 0.22
const CARRIAGE_RETENTION_ON_STRIKE := 0.85
const STOP_RESTITUTION := 0.62

var home := Vector2.ZERO
var travel := 0.0
var clock := 0.0
var kinetic_mode := false
var rail_left := 0.0
var rail_right := 0.0
var velocity_x := 0.0
var spawn_position := Vector2.ZERO

func configure(at: Vector2, distance: float) -> void:
	position = at
	home = at
	travel = distance
	spawn_position = at

func configure_kinetic(at: Vector2, left_stop: float, right_stop: float) -> void:
	kinetic_mode = true
	position = at
	home = at
	spawn_position = at
	rail_left = left_stop
	rail_right = right_stop
	velocity_x = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	collision_layer = 17 if kinetic_mode else 1
	collision_mask = 0
	sync_to_physics = true
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = KINETIC_SIZE if kinetic_mode else Vector2(68, 9)
	collision.shape = shape
	add_child(collision)
	if kinetic_mode:
		add_to_group("kinetic_carriage")

func _physics_process(delta: float) -> void:
	if kinetic_mode:
		advance_kinetic(delta)
		queue_redraw()
		return
	clock += delta
	position.x = home.x + (sin(clock * 0.85 - PI / 2.0) + 1.0) * 0.5 * travel
	queue_redraw()

func advance_kinetic(delta: float) -> void:
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
	velocity_x = move_toward(velocity_x, 0.0, KINETIC_FRICTION * delta)
	if absf(velocity_x) < 0.5:
		velocity_x = 0.0

func receive_ram_impact(ram_velocity: float) -> float:
	var previous_velocity := velocity_x
	velocity_x = clampf(
		previous_velocity * CARRIAGE_RETENTION_ON_RAM_HIT + ram_velocity * RAM_TRANSFER,
		-KINETIC_MAX_SPEED,
		KINETIC_MAX_SPEED
	)
	ram_impact.emit(ram_velocity, velocity_x)
	return clampf(
		-ram_velocity * RAM_REBOUND + previous_velocity * CARRIAGE_TO_RAM_RETURN,
		-KINETIC_MAX_SPEED,
		KINETIC_MAX_SPEED
	)

func receive_kinetic_strike(player_velocity_x: float) -> bool:
	if not kinetic_mode:
		return false
	velocity_x = clampf(
		velocity_x * CARRIAGE_RETENTION_ON_STRIKE + player_velocity_x * PLAYER_TRANSFER,
		-KINETIC_MAX_SPEED,
		KINETIC_MAX_SPEED
	)
	directly_struck.emit(player_velocity_x, velocity_x)
	return true

func reset_kinetic() -> void:
	set_physics_process(false)
	position = spawn_position
	velocity_x = 0.0
	queue_redraw()
	if is_inside_tree():
		call_deferred("_finish_kinetic_reset")
	else:
		set_physics_process(true)

func _finish_kinetic_reset() -> void:
	position = spawn_position
	velocity_x = 0.0
	set_physics_process(true)

func kinetic_half_width() -> float:
	return KINETIC_SIZE.x * 0.5

func _draw() -> void:
	if kinetic_mode:
		draw_rect(Rect2(-32, -16, 64, 32), Color("172636"))
		draw_rect(Rect2(-30, -14, 60, 7), Color("a67853"))
		draw_rect(Rect2(-28, -15, 56, 3), Color("e5b873"))
		draw_rect(Rect2(-27, -5, 54, 14), Color("304551"))
		for x in [-24, 0, 24]:
			draw_circle(Vector2(x, 11), 4.0, Color("162230"))
			draw_circle(Vector2(x, 11), 2.0, Color("d8b47b"))
		return
	draw_rect(Rect2(-35, -5, 70, 10), Color("172636"))
	draw_rect(Rect2(-33, -4, 66, 5), Color("a67853"))
	draw_rect(Rect2(-30, -5, 60, 2), Color("e5b873"))
	for x in [-25, 0, 25]:
		draw_rect(Rect2(x - 1, 1, 3, 3), Color("d8b47b"))
