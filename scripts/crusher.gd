extends Area2D

signal crushed_player

var high := Vector2.ZERO
var drop_distance := 42.0
var clock := 0.0

func configure(at: Vector2, phase: float = 0.0) -> void:
	position = at
	high = at
	clock = phase

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(28, 38)
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	clock += delta
	var phase := fmod(clock, 2.7)
	var amount := 0.0
	if phase >= 0.55 and phase < 0.75:
		amount = (phase - 0.55) / 0.2
	elif phase >= 0.75 and phase < 1.45:
		amount = 1.0
	elif phase >= 1.45 and phase < 1.75:
		amount = 1.0 - (phase - 1.45) / 0.3
	position.y = high.y + amount * drop_distance
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and absf(body.global_position.x - global_position.x) < 20.0 and absf(body.global_position.y - global_position.y) < 28.0:
		crushed_player.emit()

func _draw() -> void:
	var warning := fmod(clock, 2.7) >= 0.35 and fmod(clock, 2.7) < 0.75
	var stripe := Color("ff775e") if warning else Color("d9b16a")
	draw_rect(Rect2(-12, -22, 24, 5), Color("4b6371"))
	draw_rect(Rect2(-14, -18, 28, 32), Color("172636"))
	draw_rect(Rect2(-11, -16, 22, 25), Color("617b83"))
	draw_rect(Rect2(-9, -14, 18, 4), stripe)
	draw_rect(Rect2(-9, 5, 18, 3), Color("304551"))
	for x in [-10, -3, 4]:
		var points := PackedVector2Array([Vector2(x, 13), Vector2(x + 6, 13), Vector2(x + 3, 21)])
		draw_colored_polygon(points, Color("e8c27f"))
