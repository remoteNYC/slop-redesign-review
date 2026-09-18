extends Area2D

signal activated(at: Vector2)

var glow := 0.0
var clock := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	collision_layer = 16
	collision_mask = 0
	monitorable = true
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 9)
	collision.shape = shape
	add_child(collision)

func _process(delta: float) -> void:
	clock += delta
	glow = maxf(0.0, glow - delta)
	queue_redraw()

func receive_strike() -> bool:
	glow = 0.3
	activated.emit(global_position)
	return true

func _draw() -> void:
	var light := Color("fff1ac") if glow > 0.0 else Color("e9b96f")
	draw_rect(Rect2(-11, -5, 22, 10), Color("162230"))
	draw_rect(Rect2(-9, -4, 18, 7), Color("8b614c"))
	draw_rect(Rect2(-7, -3, 14, 3), light)
	draw_rect(Rect2(-3, -7, 6, 2), Color("fff1ac"))
	draw_rect(Rect2(-13, 0, 4, 3), Color("b47b53"))
	draw_rect(Rect2(9, 0, 4, 3), Color("b47b53"))
	if int(clock * 4.0) % 2 == 0:
		draw_rect(Rect2(-1, -9, 2, 2), Color("fff1ac"))
