extends CharacterBody2D

signal health_changed(value: int)
signal died
signal rebounded(at: Vector2)
signal jumped(at: Vector2)

const RUN_SPEED := 155.0
const GROUND_ACCEL := 1050.0
const AIR_ACCEL := 760.0
const GROUND_FRICTION := 1100.0
const AIR_FRICTION := 420.0
const GRAVITY := 650.0
const JUMP_SPEED := -235.0
const REBOUND_SPEED := -285.0
const COYOTE_TIME := 0.11
const JUMP_BUFFER := 0.12
const ATTACK_DURATION := 0.27

var health := 3
var active := true
var invulnerable_time := 0.0
var attack_time := 0.0
var coyote_time := 0.0
var jump_buffer_time := 0.0
var jump_cut_available := false
var hurt_lock := 0.0
var facing := 1
var run_clock := 0.0
var strike_shape := RectangleShape2D.new()

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
	strike_shape.size = Vector2(12, 12)

func _physics_process(delta: float) -> void:
	if not active:
		return
	invulnerable_time = maxf(0.0, invulnerable_time - delta)
	hurt_lock = maxf(0.0, hurt_lock - delta)
	attack_time = maxf(0.0, attack_time - delta)
	jump_buffer_time = maxf(0.0, jump_buffer_time - delta)
	if is_on_floor():
		coyote_time = COYOTE_TIME
		attack_time = 0.0
		jump_cut_available = false
	else:
		coyote_time = maxf(0.0, coyote_time - delta)
	if Input.is_action_just_pressed("jump"):
		jump_buffer_time = JUMP_BUFFER
	var direction := Input.get_axis("move_left", "move_right")
	if hurt_lock <= 0.0:
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
	if Input.is_action_just_released("jump"):
		if jump_cut_available and velocity.y < -80.0 and attack_time <= 0.0:
			velocity.y *= 0.55
		jump_cut_available = false
	if Input.is_action_just_pressed("attack") and not is_on_floor() and attack_time <= 0.0 and hurt_lock <= 0.0:
		attack_time = ATTACK_DURATION
		jump_cut_available = false
		velocity.y = maxf(velocity.y, 170.0)
	velocity.y = minf(velocity.y + GRAVITY * delta, 390.0)
	move_and_slide()
	if attack_time > 0.0:
		_check_strike()
	if absf(velocity.x) > 10.0 and is_on_floor():
		run_clock += delta * 18.0
	queue_redraw()

func _check_strike() -> void:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = strike_shape
	query.transform = Transform2D(0.0, global_position + Vector2(0.0, 14.0))
	query.collision_mask = 16
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for result in get_world_2d().direct_space_state.intersect_shape(query, 8):
		var target: Object = result["collider"]
		if target.has_method("receive_strike") and target.receive_strike():
			attack_time = 0.0
			velocity.y = REBOUND_SPEED
			jump_cut_available = false
			coyote_time = 0.0
			rebounded.emit(global_position + Vector2(0.0, 10.0))
			return

func take_damage(source: Vector2) -> void:
	if not active or invulnerable_time > 0.0:
		return
	health -= 1
	health_changed.emit(health)
	attack_time = 0.0
	jump_cut_available = false
	if health <= 0:
		kill()
		return
	invulnerable_time = 0.95
	hurt_lock = 0.16
	velocity = Vector2(95.0 if global_position.x >= source.x else -95.0, -145.0)
	queue_redraw()

func kill() -> void:
	if not active:
		return
	active = false
	velocity = Vector2.ZERO
	jump_cut_available = false
	died.emit()

func reset_at(at: Vector2) -> void:
	global_position = at
	velocity = Vector2.ZERO
	health = 3
	active = true
	invulnerable_time = 0.7
	attack_time = 0.0
	coyote_time = 0.0
	jump_buffer_time = 0.0
	jump_cut_available = false
	hurt_lock = 0.0
	health_changed.emit(health)
	queue_redraw()

func is_striking() -> bool:
	return active and attack_time > 0.0 and velocity.y >= 0.0

func _draw() -> void:
	if not active:
		return
	if invulnerable_time > 0.0 and int(invulnerable_time * 14.0) % 2 == 0:
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
