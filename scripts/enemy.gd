extends Area2D

signal touched_player(source: Vector2)
signal kinetic_struck(player_speed: float, ram_speed: float)
signal kinetic_dashed(player_speed: float, ram_speed: float)
signal kinetic_impact(source_speed: float, resulting_speed: float)
signal wall_rebounded(side: int, incoming_speed: float, outgoing_speed: float)

const STRIKE_RETENTION := 0.30
const STRIKE_TRANSFER := 1.00
const DASH_RETENTION := 0.20
const DASH_TRANSFER := 0.75
const MAX_SPEED := 230.0
const CHARGE_SPEED := 170.0
const COAST_FRICTION := 14.0
const IDLE_FRICTION := 100.0
const WINDUP_TIME := 0.65
const TRIGGER_RANGE := 108.0
const WALL_RESTITUTION := 0.42

var left_bound := 0.0
var right_bound := 0.0
var facing := 1
var state := "idle"
var state_time := 0.0
var cooldown := 0.25
var velocity_x := 0.0
var spawn_position := Vector2.ZERO
var spawn_facing := 1
var contact_cooldown := 0.0
var flash := 0.0
var enabled := true
var trigger_range := TRIGGER_RANGE

func configure_kinetic_ram(at: Vector2, movement_left: float, movement_right: float, initial_facing: int = 1) -> void:
	position = at
	spawn_position = at
	left_bound = movement_left
	right_bound = movement_right
	facing = initial_facing
	spawn_facing = initial_facing

func _ready() -> void:
	name = "ClockworkRam" if name.is_empty() else name
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("kinetic_rams")
	collision_layer = 16
	collision_mask = 2
	monitoring = true
	monitorable = true
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 20)
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	flash = maxf(0.0, flash - delta)
	contact_cooldown = maxf(0.0, contact_cooldown - delta)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	match state:
		"idle":
			velocity_x = move_toward(velocity_x, 0.0, IDLE_FRICTION * delta)
			cooldown = maxf(0.0, cooldown - delta)
			if player != null and cooldown <= 0.0 and absf(player.global_position.x - global_position.x) <= trigger_range and absf(player.global_position.y - global_position.y) < 72.0:
				state = "windup"
				state_time = WINDUP_TIME
		"windup":
			velocity_x = move_toward(velocity_x, 0.0, IDLE_FRICTION * delta)
			state_time = maxf(0.0, state_time - delta)
			if player != null and not is_zero_approx(player.global_position.x - global_position.x):
				facing = 1 if player.global_position.x > global_position.x else -1
			if state_time <= 0.0:
				velocity_x = facing * CHARGE_SPEED
				state = "coast"
		"coast":
			velocity_x = move_toward(velocity_x, 0.0, COAST_FRICTION * delta)
			if absf(velocity_x) < 12.0:
				state = "recover"
				state_time = 0.30
		"recover":
			velocity_x = move_toward(velocity_x, 0.0, IDLE_FRICTION * delta)
			state_time = maxf(0.0, state_time - delta)
			if state_time <= 0.0:
				state = "idle"
				cooldown = 0.22

	position.x += velocity_x * delta
	if position.x < left_bound:
		var incoming_left := velocity_x
		position.x = left_bound
		velocity_x = absf(velocity_x) * WALL_RESTITUTION
		state = "recover"
		state_time = 0.25
		wall_rebounded.emit(-1, incoming_left, velocity_x)
	elif position.x > right_bound:
		var incoming_right := velocity_x
		position.x = right_bound
		velocity_x = -absf(velocity_x) * WALL_RESTITUTION
		state = "recover"
		state_time = 0.25
		wall_rebounded.emit(1, incoming_right, velocity_x)

	_check_kinetic_receiver()
	queue_redraw()

func _check_kinetic_receiver() -> void:
	if contact_cooldown > 0.0 or absf(velocity_x) < 8.0:
		return
	var best_receiver: Node2D
	var best_distance := INF
	var travel_direction := signf(velocity_x)
	for node in get_tree().get_nodes_in_group("kinetic_receivers"):
		var receiver := node as Node2D
		if receiver == null or receiver == self:
			continue
		if receiver.has_method("accepts_kinetic_impact") and not receiver.accepts_kinetic_impact():
			continue
		if absf(receiver.global_position.y - global_position.y) > 46.0:
			continue
		var offset := receiver.global_position.x - global_position.x
		if signf(offset) != travel_direction:
			continue
		var contact_distance := 20.0
		if receiver.has_method("kinetic_half_width"):
			contact_distance = 10.0 + float(receiver.kinetic_half_width())
		var gap := absf(offset) - contact_distance
		if gap <= 3.5 and absf(offset) < best_distance:
			best_receiver = receiver
			best_distance = absf(offset)
	if best_receiver == null:
		return
	var direction := signf(best_receiver.global_position.x - global_position.x)
	var spacing := 20.0
	if best_receiver.has_method("kinetic_half_width"):
		spacing = 10.0 + float(best_receiver.kinetic_half_width())
	global_position.x = best_receiver.global_position.x - direction * spacing
	var incoming := velocity_x
	velocity_x = float(best_receiver.receive_kinetic_impact(incoming))
	contact_cooldown = 0.10
	state = "coast" if absf(velocity_x) >= 12.0 else "recover"
	state_time = 0.25
	kinetic_impact.emit(incoming, velocity_x)

func receive_kinetic_strike(player_velocity_x: float) -> bool:
	velocity_x = clampf(velocity_x * STRIKE_RETENTION + player_velocity_x * STRIKE_TRANSFER, -MAX_SPEED, MAX_SPEED)
	if absf(velocity_x) < 28.0:
		velocity_x = 28.0 * (facing if is_zero_approx(player_velocity_x) else signf(player_velocity_x))
	facing = 1 if velocity_x >= 0.0 else -1
	flash = 0.15
	state = "coast"
	state_time = 0.0
	contact_cooldown = 0.06
	kinetic_struck.emit(player_velocity_x, velocity_x)
	return true

func receive_kinetic_dash(player_velocity_x: float) -> bool:
	velocity_x = clampf(velocity_x * DASH_RETENTION + player_velocity_x * DASH_TRANSFER, -MAX_SPEED, MAX_SPEED)
	facing = 1 if velocity_x >= 0.0 else -1
	flash = 0.18
	state = "coast"
	state_time = 0.0
	contact_cooldown = 0.06
	kinetic_dashed.emit(player_velocity_x, velocity_x)
	return true

func get_rebound_velocity_x() -> float:
	return velocity_x

func reset_kinetic(at: Vector2 = spawn_position, initial_state: String = "idle", initial_velocity: float = 0.0) -> void:
	position = at
	velocity_x = initial_velocity
	facing = spawn_facing if is_zero_approx(initial_velocity) else (1 if initial_velocity > 0.0 else -1)
	state = initial_state
	state_time = 0.25
	cooldown = 0.25
	contact_cooldown = 0.0
	flash = 0.0
	enabled = true
	monitoring = true
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if not enabled or not body.is_in_group("player"):
		return
	if body.has_method("is_dashing") and body.is_dashing():
		return
	if body.has_method("is_kinetic_safe") and body.is_kinetic_safe():
		return
	if body.has_method("is_striking") and body.is_striking() and body.global_position.y < global_position.y:
		return
	touched_player.emit(global_position)

func _draw() -> void:
	if not enabled:
		return
	var ink := Color("162230")
	var steel := Color("fff1b8") if flash > 0.0 else Color("658c94")
	var brass := Color("fff1b8") if flash > 0.0 else Color("d4a65e")
	var eye := Color("f46e5a") if state == "windup" else Color("f4dd8d")
	draw_rect(Rect2(-10, -10, 20, 20), ink)
	draw_rect(Rect2(-8, -9, 16, 16), steel)
	draw_rect(Rect2(-7, 5, 14, 3), brass)
	draw_rect(Rect2(-2 + facing * 3, -5, 3, 3), eye)
	draw_rect(Rect2(-7, -12, 14, 3), brass)
	if state == "windup":
		var pulse := 2 + int((WINDUP_TIME - state_time) * 8.0) % 3
		draw_line(Vector2(12 * facing, -7), Vector2((12 + pulse * 3) * facing, -7), Color("f46e5a"), 2.0)
		draw_line(Vector2(12 * facing, 0), Vector2((12 + pulse * 3) * facing, 0), Color("f46e5a"), 2.0)
	elif absf(velocity_x) > 18.0:
		var arrow_length := clampf(absf(velocity_x) * 0.14, 12.0, 30.0)
		draw_line(Vector2(-facing * 10, 0), Vector2(-facing * arrow_length, 0), Color("a9f4dd"), 2.0)
