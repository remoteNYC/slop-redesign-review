extends StaticBody2D

signal opened

const DEFAULT_OPEN_SPEED := 120.0

var gate_height := 112.0
var open_speed := DEFAULT_OPEN_SPEED
var is_open := false
var flash := 0.0
var collision: CollisionShape2D

func configure(at: Vector2, height: float = 112.0, required_speed: float = DEFAULT_OPEN_SPEED) -> void:
	position = at
	gate_height = height
	open_speed = required_speed

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("kinetic_receivers")
	collision_layer = 1
	collision_mask = 0
	collision = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(14, gate_height)
	collision.shape = shape
	add_child(collision)

func _process(delta: float) -> void:
	flash = maxf(0.0, flash - delta)
	queue_redraw()

func receive_kinetic_impact(source_velocity: float) -> float:
	if is_open:
		return source_velocity
	if absf(source_velocity) < open_speed:
		flash = 0.22
		return -source_velocity * 0.28
	set_open(true)
	opened.emit()
	return source_velocity * 0.86

func accepts_kinetic_impact() -> bool:
	return not is_open

func kinetic_half_width() -> float:
	return 7.0

func set_open(value: bool) -> void:
	is_open = value
	if collision != null:
		collision.set_deferred("disabled", is_open)
	queue_redraw()

func _draw() -> void:
	var brass := Color("fff1b8") if flash > 0.0 else Color("d4a65e")
	if is_open:
		draw_rect(Rect2(-7, -gate_height * 0.5, 14, 7), Color("304551"))
		draw_rect(Rect2(-7, gate_height * 0.5 - 7, 14, 7), Color("304551"))
		draw_circle(Vector2(0, -gate_height * 0.5 + 12), 3.0, Color("a2f0cf"))
		return
	draw_rect(Rect2(-7, -gate_height * 0.5, 14, gate_height), Color("172636"))
	for y in range(int(-gate_height * 0.5) + 5, int(gate_height * 0.5) - 4, 12):
		draw_rect(Rect2(-5, y, 10, 6), Color("526b75"))
	draw_rect(Rect2(-8, -7, 16, 14), brass)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-4, -3),
		Vector2(2, -3),
		Vector2(2, -7),
		Vector2(7, 0),
		Vector2(2, 7),
		Vector2(2, 3),
		Vector2(-4, 3),
	]), Color("162230"))
