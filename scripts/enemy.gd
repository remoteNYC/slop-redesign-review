extends Area2D

signal touched_player(source: Vector2)
signal defeated(at: Vector2)

var kind := "walker"
var left_bound := 0.0
var right_bound := 0.0
var home := Vector2.ZERO
var facing := 1
var health := 1
var alive := true
var clock := 0.0
var flash := 0.0
var state := "patrol"
var state_time := 0.0
var cooldown := 0.3

func configure(enemy_kind: String, at: Vector2, patrol_left: float, patrol_right: float) -> void:
	kind = enemy_kind
	position = at
	home = at
	left_bound = patrol_left
	right_bound = patrol_right
	health = 2 if kind == "sentry" else 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	collision_layer = 16
	collision_mask = 2
	monitoring = true
	monitorable = true
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	match kind:
		"drone": shape.size = Vector2(18, 12)
		"sentry": shape.size = Vector2(20, 20)
		_: shape.size = Vector2(16, 13)
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if not alive:
		return
	clock += delta
	flash = maxf(0.0, flash - delta)
	match kind:
		"walker":
			position.x += facing * 33.0 * delta
			if position.x >= right_bound:
				position.x = right_bound
				facing = -1
			elif position.x <= left_bound:
				position.x = left_bound
				facing = 1
		"drone":
			position.x = home.x + sin(clock * 1.7) * (right_bound - left_bound) * 0.5
			position.y = home.y + sin(clock * 2.4) * 6.0
		"sentry":
			_update_sentry(delta)
	queue_redraw()

func _update_sentry(delta: float) -> void:
	state_time = maxf(0.0, state_time - delta)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	match state:
		"patrol":
			position.x += facing * 22.0 * delta
			if position.x >= right_bound or position.x <= left_bound:
				position.x = clampf(position.x, left_bound, right_bound)
				facing *= -1
			cooldown = maxf(0.0, cooldown - delta)
			if player != null and cooldown <= 0.0 and absf(player.global_position.x - global_position.x) < 120.0 and absf(player.global_position.y - global_position.y) < 40.0:
				facing = 1 if player.global_position.x > global_position.x else -1
				state = "windup"
				state_time = 0.55
		"windup":
			if state_time <= 0.0:
				state = "charge"
				state_time = 0.5
		"charge":
			position.x += facing * 155.0 * delta
			if position.x <= left_bound or position.x >= right_bound or state_time <= 0.0:
				position.x = clampf(position.x, left_bound, right_bound)
				state = "recover"
				state_time = 0.75
		"recover":
			if state_time <= 0.0:
				state = "patrol"
				cooldown = 0.55

func receive_strike() -> bool:
	if not alive:
		return false
	health -= 1
	flash = 0.14
	if health <= 0:
		alive = false
		collision_layer = 0
		monitoring = false
		defeated.emit(global_position)
		queue_free()
	elif kind == "sentry":
		state = "recover"
		state_time = 0.8
	return true

func _on_body_entered(body: Node2D) -> void:
	if not alive or not body.is_in_group("player"):
		return
	var reach := Vector2(15, 16) if kind != "sentry" else Vector2(16, 19)
	if absf(body.global_position.x - global_position.x) > reach.x or absf(body.global_position.y - global_position.y) > reach.y:
		return
	if body.has_method("is_striking") and body.is_striking() and body.global_position.y < global_position.y:
		return
	touched_player.emit(global_position)

func _draw() -> void:
	var ink := Color("162230")
	var steel := Color("658c94")
	var brass := Color("d4a65e")
	var eye := Color("f4dd8d")
	if flash > 0.0:
		steel = Color("fff1b8")
		brass = Color("fff1b8")
	match kind:
		"walker":
			draw_rect(Rect2(-8, -5, 16, 9), ink)
			draw_rect(Rect2(-6, -6, 12, 8), brass)
			draw_rect(Rect2(-4, -8, 8, 3), steel)
			draw_rect(Rect2(2 * facing, -3, 2, 2), eye)
			draw_rect(Rect2(-6, 4, 3, 3), ink)
			draw_rect(Rect2(3, 4, 3, 3), ink)
		"drone":
			draw_rect(Rect2(-9, -4, 18, 8), ink)
			draw_rect(Rect2(-7, -3, 14, 6), steel)
			draw_rect(Rect2(-3, -2, 6, 4), eye)
			draw_rect(Rect2(-11, -6, 5, 2), brass)
			draw_rect(Rect2(6, -6, 5, 2), brass)
			draw_rect(Rect2(-12, -8 + int(sin(clock * 18.0)), 7, 1), Color("9ac6c7"))
			draw_rect(Rect2(5, -8 - int(sin(clock * 18.0)), 7, 1), Color("9ac6c7"))
		"sentry":
			draw_rect(Rect2(-10, -10, 20, 20), ink)
			draw_rect(Rect2(-8, -9, 16, 16), steel)
			draw_rect(Rect2(-7, 5, 14, 3), brass)
			draw_rect(Rect2(-2 + facing * 3, -5, 3, 3), Color("f46e5a") if state == "windup" else eye)
			draw_rect(Rect2(-7, -12, 14, 3), brass)
			if state == "windup":
				draw_rect(Rect2(-12 if facing < 0 else 8, -3, 4, 6), Color("f46e5a"))
