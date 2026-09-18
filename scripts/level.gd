extends Node2D

signal player_touched_enemy(source: Vector2)
signal lethal_hazard
signal checkpoint_reached(at: Vector2, index: int)
signal stage_finished
signal enemy_defeated(at: Vector2)
signal device_activated(at: Vector2)

const EnemyScene = preload("res://scripts/enemy.gd")
const DeviceScene = preload("res://scripts/rebound_device.gd")
const PlatformScene = preload("res://scripts/moving_platform.gd")
const CrusherScene = preload("res://scripts/crusher.gd")

const WORLD_WIDTH := 1950.0
const WORLD_BOTTOM := 560.0

var blocks: Array[Rect2] = []
var spikes: Array[Rect2] = []
var active_checkpoint := 0
var clock := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_build_stage()

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func _build_stage() -> void:
	_add_block(Rect2(0, 480, 440, 80))
	_add_block(Rect2(270, 405, 190, 16))
	_add_block(Rect2(422, 405, 38, 75))
	_add_block(Rect2(460, 405, 175, 155))
	_add_block(Rect2(710, 405, 320, 155))
	_add_block(Rect2(1030, 330, 40, 75))
	_add_block(Rect2(1070, 330, 180, 16))
	_add_block(Rect2(1435, 330, 290, 230))
	_add_block(Rect2(1725, 260, 40, 70))
	_add_block(Rect2(1765, 260, 170, 16))
	_add_block(Rect2(-28, 180, 28, 380))
	_add_block(Rect2(1935, 180, 28, 380))
	_add_spikes(Rect2(635, 500, 75, 60))
	_add_spikes(Rect2(755, 397, 40, 8))
	_add_spikes(Rect2(1250, 500, 185, 60))
	_add_spikes(Rect2(1520, 322, 35, 8))
	_add_device(Vector2(210, 450))
	_add_device(Vector2(984, 375))
	_add_device(Vector2(1680, 301))
	_add_enemy("walker", Vector2(535, 397), 485.0, 603.0)
	_add_enemy("drone", Vector2(670, 381), 640.0, 700.0)
	_add_enemy("sentry", Vector2(855, 394), 805.0, 928.0)
	_add_enemy("drone", Vector2(1350, 297), 1300.0, 1410.0)
	_add_enemy("walker", Vector2(1635, 322), 1615.0, 1655.0)
	_add_enemy("sentry", Vector2(1820, 249), 1785.0, 1870.0)
	_add_crusher(Vector2(958, 340), 0.0)
	_add_crusher(Vector2(1590, 265), 1.0)
	var platform := PlatformScene.new()
	platform.configure(Vector2(1285, 333), 140.0)
	add_child(platform)
	_add_checkpoint(0, Vector2(735, 388), Vector2(735, 395))
	_add_checkpoint(1, Vector2(1460, 313), Vector2(1460, 320))
	_add_goal(Vector2(1904, 239))

func _add_block(rect: Rect2) -> void:
	blocks.append(rect)
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _add_spikes(rect: Rect2) -> void:
	spikes.append(rect)
	var area := Area2D.new()
	area.position = rect.get_center()
	area.collision_layer = 0
	area.collision_mask = 2
	area.monitoring = true
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	area.add_child(collision)
	area.body_entered.connect(_on_hazard_body.bind(rect))
	add_child(area)

func _add_enemy(enemy_kind: String, at: Vector2, left: float, right: float) -> void:
	var enemy := EnemyScene.new()
	enemy.configure(enemy_kind, at, left, right)
	enemy.touched_player.connect(func(source: Vector2) -> void: player_touched_enemy.emit(source))
	enemy.defeated.connect(func(point: Vector2) -> void: enemy_defeated.emit(point))
	add_child(enemy)

func _add_device(at: Vector2) -> void:
	var device := DeviceScene.new()
	device.position = at
	device.activated.connect(func(point: Vector2) -> void: device_activated.emit(point))
	add_child(device)

func _add_crusher(at: Vector2, phase: float) -> void:
	var crusher := CrusherScene.new()
	crusher.configure(at, phase)
	crusher.crushed_player.connect(func() -> void: lethal_hazard.emit())
	add_child(crusher)

func _add_checkpoint(index: int, at: Vector2, respawn: Vector2) -> void:
	var area := Area2D.new()
	area.position = at
	area.collision_layer = 0
	area.collision_mask = 2
	area.monitoring = true
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(22, 34)
	collision.shape = shape
	area.add_child(collision)
	area.body_entered.connect(_on_checkpoint_body.bind(index, respawn))
	add_child(area)

func _add_goal(at: Vector2) -> void:
	var area := Area2D.new()
	area.position = at
	area.collision_layer = 0
	area.collision_mask = 2
	area.monitoring = true
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(26, 42)
	collision.shape = shape
	area.add_child(collision)
	area.body_entered.connect(_on_goal_body.bind(at))
	add_child(area)

func _on_hazard_body(body: Node2D, rect: Rect2) -> void:
	var contact_rect := Rect2(rect.position - Vector2(6, 9), rect.size + Vector2(12, 18))
	if body.is_in_group("player") and contact_rect.has_point(body.global_position):
		lethal_hazard.emit()

func _on_checkpoint_body(body: Node2D, index: int, respawn: Vector2) -> void:
	if body.is_in_group("player") and index + 1 > active_checkpoint:
		active_checkpoint = index + 1
		checkpoint_reached.emit(respawn, active_checkpoint)
		queue_redraw()

func _on_goal_body(body: Node2D, at: Vector2) -> void:
	if body.is_in_group("player") and absf(body.global_position.x - at.x) <= 19.0 and absf(body.global_position.y - at.y) <= 30.0:
		stage_finished.emit()

func set_active_checkpoint(index: int) -> void:
	active_checkpoint = index
	queue_redraw()

func _draw() -> void:
	_draw_background()
	for rect in blocks:
		_draw_block(rect)
	for rect in spikes:
		_draw_spikes(rect)
	_draw_checkpoint(Vector2(735, 388), active_checkpoint >= 1)
	_draw_checkpoint(Vector2(1460, 313), active_checkpoint >= 2)
	_draw_goal(Vector2(1904, 239))
	draw_string(ThemeDB.fallback_font, Vector2(160, 415), "J / X  DOWN STRIKE", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("f0d49c"))

func _draw_background() -> void:
	draw_rect(Rect2(0, 145, WORLD_WIDTH, 415), Color("111c2a"))
	for x in range(0, int(WORLD_WIDTH), 256):
		draw_rect(Rect2(x + 24, 165, 40, 395), Color("182737"))
		draw_rect(Rect2(x + 68, 165, 5, 395), Color("304150"))
		draw_rect(Rect2(x + 210, 165, 10, 395), Color("263747"))
	for x in range(0, int(WORLD_WIDTH), 384):
		_draw_gear(Vector2(x + 320, 265), 41, Color("273d48"))
		_draw_gear(Vector2(x + 165, 365), 22, Color("233846"))
	for y in [190, 285, 380, 475]:
		draw_rect(Rect2(0, y, WORLD_WIDTH, 3), Color("263847"))
	for x in range(0, int(WORLD_WIDTH), 64):
		draw_rect(Rect2(x + 6, 184, 2, 2), Color("58717a"))
	_draw_pipe(Vector2(68, 430), Vector2(68, 268))
	_draw_pipe(Vector2(1105, 405), Vector2(1105, 233))
	_draw_pipe(Vector2(1760, 326), Vector2(1760, 196))

func _draw_gear(center: Vector2, radius: int, color: Color) -> void:
	draw_arc(center, radius, 0.0, TAU, 36, color, 5.0, false)
	draw_circle(center, float(radius) * 0.45, Color("1a2b3b"))
	draw_circle(center, float(radius) * 0.16, color)
	for i in 12:
		var angle := TAU * float(i) / 12.0
		var tooth := center + Vector2(cos(angle), sin(angle)) * float(radius)
		draw_rect(Rect2(tooth.x - 3, tooth.y - 3, 6, 6), color)

func _draw_pipe(start: Vector2, end: Vector2) -> void:
	draw_line(start, end, Color("415864"), 5.0, false)
	draw_rect(Rect2(end.x - 5, end.y, 10, 5), Color("a47b55"))
	draw_rect(Rect2(start.x - 5, start.y - 5, 10, 5), Color("a47b55"))

func _draw_block(rect: Rect2) -> void:
	draw_rect(rect, Color("283b47"))
	draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 4), Color("c3935f"))
	draw_rect(Rect2(rect.position.x, rect.position.y + 4, rect.size.x, 3), Color("6d6d60"))
	for x in range(int(rect.position.x) + 8, int(rect.end.x) - 4, 16):
		draw_rect(Rect2(x, rect.position.y + 1, 2, 2), Color("f0ca84"))
	for y in range(int(rect.position.y) + 16, int(rect.end.y), 16):
		draw_rect(Rect2(rect.position.x, y, rect.size.x, 1), Color("344c56"))
		var offset := 0 if int(y / 16) % 2 == 0 else 8
		for x in range(int(rect.position.x) + offset, int(rect.end.x), 16):
			draw_rect(Rect2(x, y - 15, 1, 15), Color("344c56"))

func _draw_spikes(rect: Rect2) -> void:
	draw_rect(Rect2(rect.position.x, rect.position.y + 6, rect.size.x, maxf(2.0, rect.size.y - 6.0)), Color("743f41"))
	for x in range(int(rect.position.x), int(rect.end.x), 8):
		var points := PackedVector2Array([Vector2(x, rect.position.y + 8), Vector2(x + 4, rect.position.y), Vector2(x + 8, rect.position.y + 8)])
		draw_colored_polygon(points, Color("ef9569"))

func _draw_checkpoint(at: Vector2, active: bool) -> void:
	var glow := Color("a2f0cf") if active else Color("9e8d6c")
	draw_rect(Rect2(at.x - 2, at.y - 20, 4, 24), Color("d7ac70"))
	draw_rect(Rect2(at.x - 7, at.y - 21, 14, 5), Color("263846"))
	draw_rect(Rect2(at.x - 5, at.y - 20, 10, 3), glow)
	if active:
		draw_rect(Rect2(at.x - 3, at.y - 25 - int(sin(clock * 4.0) * 2.0), 6, 3), glow)

func _draw_goal(at: Vector2) -> void:
	draw_rect(Rect2(at.x - 2, at.y - 39, 4, 42), Color("a47b55"))
	draw_rect(Rect2(at.x - 11, at.y - 28, 22, 4), Color("e4b77c"))
	draw_rect(Rect2(at.x - 8, at.y - 24, 16, 15), Color("dba866"))
	draw_rect(Rect2(at.x - 5, at.y - 9, 10, 3), Color("f4d795"))
	draw_rect(Rect2(at.x - 2, at.y - 6, 4, 3), Color("f5e4ba"))
	if int(clock * 3.0) % 2 == 0:
		draw_rect(Rect2(at.x - 1, at.y - 35, 2, 2), Color("fff1ac"))
