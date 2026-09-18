extends AnimatableBody2D

var home := Vector2.ZERO
var travel := 0.0
var clock := 0.0

func configure(at: Vector2, distance: float) -> void:
	position = at
	home = at
	travel = distance

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(68, 9)
	collision.shape = shape
	add_child(collision)

func _physics_process(delta: float) -> void:
	clock += delta
	position.x = home.x + (sin(clock * 0.85 - PI / 2.0) + 1.0) * 0.5 * travel
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-35, -5, 70, 10), Color("172636"))
	draw_rect(Rect2(-33, -4, 66, 5), Color("a67853"))
	draw_rect(Rect2(-30, -5, 60, 2), Color("e5b873"))
	for x in [-25, 0, 25]:
		draw_rect(Rect2(x - 1, 1, 3, 3), Color("d8b47b"))
