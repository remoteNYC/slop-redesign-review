extends CharacterBody2D

signal died
signal rebounded(at: Vector2)
signal jumped(at: Vector2)
signal dashed(at: Vector2)
signal dash_connected(at: Vector2)

const RUN_SPEED := 165.0
const GROUND_ACCEL := 1250.0
const AIR_ACCEL := 850.0
const GROUND_FRICTION := 1450.0
const AIR_FRICTION := 360.0
const GRAVITY := 680.0
const JUMP_SPEED := -240.0
const REBOUND_SPEED := -290.0
const COYOTE_TIME := 0.12
const JUMP_BUFFER := 0.13
const STRIKE_BUFFER := 0.10
const ATTACK_DURATION := 0.32
const DASH_SPEED := 310.0
const DASH_DURATION := 0.16

var active := true
var attack_time := 0.0
var coyote_time := 0.0
var jump_buffer_time := 0.0
var strike_buffer_time := 0.0
var jump_cut_available := false
var facing := 1
var run_clock := 0.0
var dash_enabled := true
var dash_ready := true
var dash_time := 0.0
var dash_direction := Vector2.RIGHT
var dash_aim_direction := Vector2.ZERO
var kinetic_contact_grace := 0.0

var strike_shape := RectangleShape2D.new()
var dash_shape := RectangleShape2D.new()

func _ready() -> void:
	name = "Player"
	add_to_group("player")
	process_mode = Node.PROCESS_MODE_PAUSABLE
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 2.0
	platform_floor_layers = 1
	var body := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(12, 18)
	body.shape = shape
	add_child(body)
	strike_shape.size = Vector2(20, 20)
	dash_shape.size = Vector2(18, 18)

func _physics_process(delta: float) -> void:
	if not active:
		return
	attack_time = maxf(0.0, attack_time - delta)
	kinetic_contact_grace = maxf(0.0, kinetic_contact_grace - delta)
	jump_buffer_time = maxf(0.0, jump_buffer_time - delta)
	strike_buffer_time = maxf(0.0, strike_buffer_time - delta)

	if is_on_floor():
		coyote_time = COYOTE_TIME
		attack_time = 0.0
		jump_cut_available = false
		dash_ready = dash_enabled
	else:
		coyote_time = maxf(0.0, coyote_time - delta)

	if Input.is_action_just_pressed("jump"):
		jump_buffer_time = JUMP_BUFFER
	if Input.is_action_just_pressed("attack"):
		strike_buffer_time = STRIKE_BUFFER

	dash_aim_direction = Input.get_vector("move_left", "move_right", "aim_up", "aim_down")
	if dash_enabled and dash_ready and Input.is_action_just_pressed("dash"):
		var requested_direction := dash_aim_direction.normalized()
		if requested_direction.is_zero_approx():
			requested_direction = Vector2(facing, 0.0)
		_begin_dash(requested_direction)

	if dash_time > 0.0:
		_update_dash(delta)
		queue_redraw()
		return

	var direction := Input.get_axis("move_left", "move_right")
	if absf(direction) > 0.05:
		velocity.x = move_toward(velocity.x, direction * RUN_SPEED, (GROUND_ACCEL if is_on_floor() else AIR_ACCEL) * delta)
		facing = 1 if direction > 0.0 else -1
	else:
		velocity.x = move_toward(velocity.x, 0.0, (GROUND_FRICTION if is_on_floor() else AIR_FRICTION) * delta)

	if jump_buffer_time > 0.0 and coyote_time > 0.0 and attack_time <= 0.0:
		velocity.y = JUMP_SPEED
		jump_cut_available = true
		jump_buffer_time = 0.0
		coyote_time = 0.0
		jumped.emit(global_position)

	if Input.is_action_just_released("jump") and jump_cut_available and velocity.y < -80.0:
		velocity.y *= 0.55
		jump_cut_available = false

	if strike_buffer_time > 0.0 and not is_on_floor() and attack_time <= 0.0:
		attack_time = ATTACK_DURATION
		strike_buffer_time = 0.0
		jump_cut_available = false
		velocity.y = maxf(velocity.y, 195.0)

	velocity.y = minf(velocity.y + GRAVITY * delta, 420.0)
	move_and_slide()
	if attack_time > 0.0:
		_check_strike()
	if absf(velocity.x) > 10.0 and is_on_floor():
		run_clock += delta * 18.0
	queue_redraw()

func _begin_dash(direction: Vector2) -> void:
	dash_direction = direction
	dash_time = DASH_DURATION
	dash_ready = false
	attack_time = 0.0
	strike_buffer_time = 0.0
	jump_buffer_time = 0.0
	jump_cut_available = false
	coyote_time = 0.0
	velocity = dash_direction * DASH_SPEED
	if absf(dash_direction.x) > 0.1:
		facing = 1 if dash_direction.x > 0.0 else -1
	dashed.emit(global_position)

func _update_dash(delta: float) -> void:
	dash_time = maxf(0.0, dash_time - delta)
	velocity = dash_direction * DASH_SPEED
	move_and_slide()
	if _check_dash_impact():
		return
	if get_slide_collision_count() > 0:
		dash_time = 0.0
		velocity *= 0.35
	elif dash_time <= 0.0:
		velocity *= 0.78

func _check_dash_impact() -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = dash_shape
	query.transform = Transform2D(0.0, global_position + dash_direction * 5.0)
	query.collision_mask = 16
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [get_rid()]
	for result in get_world_2d().direct_space_state.intersect_shape(query, 8):
		var target: Object = result["collider"]
		if not target.has_method("receive_kinetic_dash"):
			continue
		if not target.receive_kinetic_dash(velocity.x):
			continue
		dash_time = 0.0
		dash_ready = true
		kinetic_contact_grace = 0.16
		velocity = Vector2(-dash_direction.x * 72.0, -105.0)
		jump_cut_available = false
		dash_connected.emit(target.global_position)
		return true
	return false

func _check_strike() -> void:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = strike_shape
	query.transform = Transform2D(0.0, global_position + Vector2(0.0, 14.0))
	query.collision_mask = 16
	query.collide_with_areas = true
	query.collide_with_bodies = true
	for result in get_world_2d().direct_space_state.intersect_shape(query, 8):
		var target: Object = result["collider"]
		var connected := false
		if target.has_method("receive_kinetic_strike"):
			connected = target.receive_kinetic_strike(velocity.x)
		elif target.has_method("receive_strike"):
			connected = target.receive_strike()
		if not connected:
			continue
		var surface_velocity := 0.0
		if target.has_method("get_rebound_velocity_x"):
			surface_velocity = float(target.get_rebound_velocity_x())
		attack_time = 0.0
		kinetic_contact_grace = 0.12
		velocity.y = REBOUND_SPEED
		velocity.x = clampf(velocity.x + surface_velocity * 0.55, -245.0, 245.0)
		dash_ready = true
		jump_cut_available = false
		coyote_time = 0.0
		rebounded.emit(global_position + Vector2(0.0, 10.0))
		return

func kill() -> void:
	if not active:
		return
	active = false
	velocity = Vector2.ZERO
	dash_time = 0.0
	attack_time = 0.0
	jump_cut_available = false
	died.emit()

func reset_at(at: Vector2) -> void:
	global_position = at
	velocity = Vector2.ZERO
	active = true
	attack_time = 0.0
	dash_time = 0.0
	dash_ready = dash_enabled
	dash_direction = Vector2.RIGHT
	dash_aim_direction = Vector2.ZERO
	coyote_time = 0.0
	jump_buffer_time = 0.0
	strike_buffer_time = 0.0
	jump_cut_available = false
	kinetic_contact_grace = 0.18
	queue_redraw()

func is_striking() -> bool:
	return active and attack_time > 0.0 and velocity.y >= 0.0

func is_dashing() -> bool:
	return active and dash_time > 0.0

func is_kinetic_safe() -> bool:
	return active and kinetic_contact_grace > 0.0

func _draw() -> void:
	if not active:
		return
	var stride := 1 if absf(velocity.x) > 25.0 and is_on_floor() and sin(run_clock) > 0.0 else 0
	var scarf := Color("e45d54")
	var coat := Color("416d83")
	var brass := Color("edc27a")
	var ink := Color("162230")
	draw_rect(Rect2(-3 - facing * 3, -2, 5, 3), scarf)
	draw_rect(Rect2(-4, -1, 8, 7), coat)
	draw_rect(Rect2(-4, -9, 8, 7), brass)
	draw_rect(Rect2(-3, -8, 6, 4), ink)
	draw_rect(Rect2(1 if facing > 0 else -2, -7, 1, 1), Color("fff4d7"))
	draw_rect(Rect2(-4, 6, 3, 3 - stride), ink)
	draw_rect(Rect2(1, 6 + stride, 3, 3 - stride), ink)
	if attack_time > 0.0:
		draw_rect(Rect2(-2, 8, 4, 10), Color("fff1aa"))
		draw_rect(Rect2(-4, 14, 8, 3), Color("f29662"))
	if dash_time > 0.0:
		draw_line(-dash_direction * 5.0, -dash_direction * 25.0, Color("a9f4dd"), 3.0)
		draw_circle(-dash_direction * 12.0, 2.0, Color("fff1ac"))
	elif dash_ready:
		draw_rect(Rect2(-2, -13, 4, 2), Color("a9f4dd"))
