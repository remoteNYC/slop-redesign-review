extends Node2D

## A fixed point. Its beam is a greybox stand-in for a roof support or branch.
var targeted := false
var attached := false

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var timber := Color("303735")
	var metal := Color("a38b67")
	var highlight := Color("e2bb82") if targeted or attached else Color("b8aaa0")
	draw_line(Vector2(-45, -23), Vector2(45, -23), timber, 11.0, true)
	draw_line(Vector2(-25, -15), Vector2(25, -15), Color("56605b"), 3.0, true)
	draw_line(Vector2(0, -18), Vector2.ZERO, metal, 4.0, true)
	if targeted or attached:
		draw_arc(Vector2.ZERO, 19.0, 0.0, TAU, 30, highlight.darkened(0.25), 3.0, true)
	draw_circle(Vector2.ZERO, 11.0, timber)
	draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 20, highlight, 3.0, true)
	draw_circle(Vector2.ZERO, 3.0, highlight)
