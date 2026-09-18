extends Node2D

var particles: Array[Dictionary] = []

func burst(at: Vector2, color: Color, count: int = 8) -> void:
	for i in count:
		var angle := TAU * float(i) / float(count) + randf_range(-0.18, 0.18)
		var speed := randf_range(28.0, 75.0)
		particles.append({"position": at, "velocity": Vector2(cos(angle), sin(angle)) * speed, "life": 0.38, "color": color})
	queue_redraw()

func _process(delta: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var p := particles[i]
		p["life"] -= delta
		if p["life"] <= 0.0:
			particles.remove_at(i)
		else:
			p["position"] += p["velocity"] * delta
			p["velocity"].y += 120.0 * delta
			particles[i] = p
	queue_redraw()

func _draw() -> void:
	for p in particles:
		var size := 2.0 if p["life"] > 0.18 else 1.0
		draw_rect(Rect2(p["position"] - Vector2.ONE * size * 0.5, Vector2.ONE * size), p["color"])
