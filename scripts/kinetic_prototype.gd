extends Node2D

const PlayerScene = preload("res://scripts/player.gd")
const EnemyScene = preload("res://scripts/enemy.gd")
const PlatformScene = preload("res://scripts/moving_platform.gd")
const EffectsScene = preload("res://scripts/effects.gd")
const SfxScene = preload("res://scripts/sfx.gd")

const WORLD_WIDTH := 1360.0
const START_POSITION := Vector2(48, 173)
const RAM_START := Vector2(92, 172)
const COUNTER_RAM_START := Vector2(690, 172)
const CARRIAGE_START := Vector2(216, 166)
const RAIL_LEFT := 216.0
const RAIL_RIGHT := 1176.0
const RAM_LEFT := 42.0
const RAM_RIGHT := 560.0
const COUNTER_RAM_LEFT := 480.0
const COUNTER_RAM_RIGHT := 1190.0

var player: CharacterBody2D
var ram: Area2D
var counter_ram: Area2D
var rams: Array[Area2D] = []
var carriage: AnimatableBody2D
var camera: Camera2D
var effects: Node2D
var sfx: Node
var blocks: Array[Rect2] = []
var spike_rects: Array[Rect2] = []
var mode := "play"
var attempts := 1
var last_event := "Launch the ram, then catch the carriage while both are moving."
var reset_ticket := 0

var debug_label: Label
var help_label: Label
var result_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_inputs()
	_build_level()
	_create_actors()
	_create_ui()
	reset_encounter()

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		attempts += 1
		reset_encounter()
	if mode == "play" and player.global_position.y > 230.0:
		player.kill()
	_update_debug()
	queue_redraw()

func _build_level() -> void:
	# Four islands divide the hazards without dividing the ongoing physical state.
	_add_block(Rect2(0, 182, 180, 34))
	_add_block(Rect2(400, 182, 190, 34))
	_add_block(Rect2(650, 182, 180, 34))
	_add_block(Rect2(830, 182, 160, 34))
	_add_block(Rect2(1220, 182, 140, 34))
	_add_block(Rect2(995, 112, 150, 12), true)
	_add_block(Rect2(-16, 0, 16, 216))
	_add_block(Rect2(WORLD_WIDTH, 0, 16, 216))
	_add_spikes(Rect2(180, 182, 220, 34))
	_add_spikes(Rect2(590, 182, 60, 34))
	_add_spikes(Rect2(990, 182, 230, 34))
	_add_goal(Vector2(1070, 89))

func _create_actors() -> void:
	carriage = PlatformScene.new()
	carriage.name = "RelayCarriage"
	carriage.configure_kinetic(CARRIAGE_START, RAIL_LEFT, RAIL_RIGHT)
	carriage.kinetic_friction = 3.0
	carriage.ram_impact.connect(_on_ram_hit_carriage)
	carriage.directly_struck.connect(_on_carriage_struck)
	carriage.stop_rebounded.connect(_on_carriage_stop)
	add_child(carriage)

	ram = _create_ram("LaunchRam", RAM_START, RAM_LEFT, RAM_RIGHT, "LAUNCH")
	counter_ram = _create_ram("CounterRam", COUNTER_RAM_START, COUNTER_RAM_LEFT, COUNTER_RAM_RIGHT, "COUNTER")

	player = PlayerScene.new()
	player.position = START_POSITION
	player.died.connect(_on_player_died)
	player.rebounded.connect(_on_player_rebounded)
	player.jumped.connect(func(_point: Vector2) -> void: sfx.play("jump"))
	add_child(player)

	camera = Camera2D.new()
	camera.position = Vector2(0, -65)
	camera.limit_left = 0
	camera.limit_right = int(WORLD_WIDTH)
	camera.limit_top = 0
	camera.limit_bottom = 216
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	player.add_child(camera)

	effects = EffectsScene.new()
	add_child(effects)
	sfx = SfxScene.new()
	add_child(sfx)

func _create_ram(node_name: String, at: Vector2, left: float, right: float, label: String) -> Area2D:
	var actor := EnemyScene.new() as Area2D
	actor.name = node_name
	actor.configure_kinetic_ram(at, left, right)
	actor.touched_player.connect(_on_ram_touched_player)
	actor.kinetic_struck.connect(func(player_speed: float, ram_speed: float) -> void:
		_on_ram_struck(label, actor, player_speed, ram_speed)
	)
	actor.carriage_hit.connect(func(_ram_speed: float, _carriage_speed: float) -> void: sfx.play("hit"))
	add_child(actor)
	rams.append(actor)
	return actor

func reset_encounter() -> void:
	reset_ticket += 1
	mode = "play"
	if is_instance_valid(carriage):
		carriage.reset_kinetic()
	for actor in rams:
		if is_instance_valid(actor):
			actor.reset_kinetic()
	if is_instance_valid(ram):
		ram.cooldown = 0.05
	if is_instance_valid(player):
		player.reset_at(START_POSITION)
	if is_instance_valid(camera):
		camera.reset_smoothing()
	last_event = "Launch the ram, then catch the carriage while both are moving."
	if result_label != null:
		result_label.text = ""
	queue_redraw()

func _on_player_died() -> void:
	if mode != "play":
		return
	mode = "dead"
	attempts += 1
	last_event = "The relay resets quickly; momentum mistakes on an island do not."
	effects.burst(player.global_position, Color("e9876c"), 12)
	sfx.play("death")
	var ticket := reset_ticket
	await get_tree().create_timer(0.38).timeout
	if mode == "dead" and ticket == reset_ticket:
		reset_encounter()

func _on_ram_touched_player(_source: Vector2) -> void:
	if mode == "play":
		player.kill()

func _on_player_rebounded(at: Vector2) -> void:
	effects.burst(at, Color("f6d68c"), 8)
	sfx.play("bounce")

func _on_ram_struck(label: String, actor: Area2D, player_speed: float, ram_speed: float) -> void:
	last_event = "%s REDIRECT  player %+.0f  -> ram %+.0f" % [label, player_speed, ram_speed]
	effects.burst(actor.global_position, Color("fff1ac"), 8)

func _on_ram_hit_carriage(ram_speed: float, carriage_speed: float) -> void:
	last_event = "IMPACT  ram %+.0f  -> carriage %+.0f" % [ram_speed, carriage_speed]
	effects.burst(carriage.global_position, Color("a9f4dd"), 10)

func _on_carriage_struck(player_speed: float, carriage_speed: float) -> void:
	last_event = "MID-AIR CORRECTION  player %+.0f  -> carriage %+.0f" % [player_speed, carriage_speed]
	effects.burst(carriage.global_position + Vector2(0, -16), Color("fff1ac"), 7)

func _on_carriage_stop(side: int, incoming_speed: float, outgoing_speed: float) -> void:
	last_event = "%s REBOUND  carriage %+.0f  -> %+.0f" % ["FAR" if side > 0 else "START", incoming_speed, outgoing_speed]
	sfx.play("hit")

func _add_block(rect: Rect2, one_way: bool = false) -> void:
	blocks.append(rect)
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	collision.one_way_collision = one_way
	if one_way:
		collision.one_way_collision_margin = 3.0
	body.add_child(collision)
	add_child(body)

func _add_spikes(rect: Rect2) -> void:
	spike_rects.append(rect)
	var area := Area2D.new()
	area.position = rect.get_center() + Vector2(0, -4)
	area.collision_layer = 0
	area.collision_mask = 2
	area.monitoring = true
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size + Vector2(0, 8)
	collision.shape = shape
	area.add_child(collision)
	area.body_entered.connect(func(body: Node2D) -> void:
		if body.is_in_group("player") and mode == "play":
			player.kill()
	)
	add_child(area)

func _add_goal(at: Vector2) -> void:
	var goal := Area2D.new()
	goal.position = at
	goal.collision_layer = 0
	goal.collision_mask = 2
	goal.monitoring = true
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(44, 44)
	collision.shape = shape
	goal.add_child(collision)
	goal.body_entered.connect(func(body: Node2D) -> void:
		if body.is_in_group("player") and mode == "play":
			mode = "complete"
			player.active = false
			player.velocity = Vector2.ZERO
			result_label.text = "RELAY COMPLETE\nR  RUN IT AGAIN"
			sfx.play("win")
	)
	add_child(goal)

func _create_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	debug_label = _label(Vector2(7, 5), Vector2(370, 34), 8, Color("f5dfa8"))
	canvas.add_child(debug_label)
	help_label = _label(Vector2(7, 198), Vector2(370, 14), 8, Color("b6c4bf"))
	help_label.text = "A/D MOVE   SPACE JUMP   J/X DOWN STRIKE   R RESET"
	canvas.add_child(help_label)
	result_label = _label(Vector2(65, 68), Vector2(254, 55), 15, Color("fff1ac"))
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	canvas.add_child(result_label)

func _label(at: Vector2, dimensions: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.size = dimensions
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color("162230"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label

func _update_debug() -> void:
	if debug_label == null or not is_instance_valid(ram) or not is_instance_valid(counter_ram) or not is_instance_valid(carriage):
		return
	debug_label.text = "A x%4.0f v%+4.0f   CART x%4.0f v%+4.0f   B x%4.0f v%+4.0f\n%s" % [
		ram.position.x,
		ram.velocity_x,
		carriage.position.x,
		carriage.velocity_x,
		counter_ram.position.x,
		counter_ram.velocity_x,
		last_event,
	]

func _draw() -> void:
	draw_rect(Rect2(0, 0, WORLD_WIDTH, 216), Color("111c2a"))
	draw_rect(Rect2(0, 40, 440, 176), Color("182737"))
	draw_rect(Rect2(440, 40, 390, 176), Color("172533"))
	draw_rect(Rect2(830, 40, 530, 176), Color("182737"))
	for rect in blocks:
		draw_rect(rect, Color("283b47"))
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4)), Color("c3935f"))
	for rect in spike_rects:
		for x in range(int(rect.position.x), int(rect.end.x), 8):
			var points := PackedVector2Array([
				Vector2(x, rect.position.y + 8),
				Vector2(x + 4, rect.position.y),
				Vector2(x + 8, rect.position.y + 8),
			])
			draw_colored_polygon(points, Color("ef9569"))
	draw_line(Vector2(RAIL_LEFT - 32, 180), Vector2(RAIL_RIGHT + 32, 180), Color("657b83"), 2.0)
	draw_rect(Rect2(RAIL_LEFT - 36, 154, 4, 28), Color("e5b873"))
	draw_rect(Rect2(RAIL_RIGHT + 32, 154, 4, 28), Color("e5b873"))
	draw_string(ThemeDB.fallback_font, Vector2(42, 62), "I  LAUNCH + CATCH", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("9ac6c7"))
	draw_string(ThemeDB.fallback_font, Vector2(526, 62), "II  OPPOSING RAM", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("9ac6c7"))
	draw_string(ThemeDB.fallback_font, Vector2(976, 62), "III  USE THE RETURN", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("9ac6c7"))
	draw_rect(Rect2(1062, 65, 16, 4), Color("fff1ac"))
	draw_rect(Rect2(1068, 69, 4, 20), Color("dba866"))
	if is_instance_valid(carriage) and absf(carriage.velocity_x) > 1.0:
		draw_line(carriage.position, carriage.position + Vector2(clampf(carriage.velocity_x * 0.22, -34.0, 34.0), 0), Color("a9f4dd"), 2.0)

func _setup_inputs() -> void:
	_add_action("move_left", 0.2)
	_add_action("move_right", 0.2)
	_add_action("aim_up", 0.2)
	_add_action("aim_down", 0.2)
	_add_action("jump")
	_add_action("attack")
	_add_action("dash")
	_add_action("restart")
	_add_key("move_left", KEY_A)
	_add_key("move_left", KEY_LEFT)
	_add_key("move_right", KEY_D)
	_add_key("move_right", KEY_RIGHT)
	_add_key("jump", KEY_SPACE)
	_add_key("attack", KEY_J)
	_add_key("attack", KEY_X)
	_add_key("restart", KEY_R)
	_add_pad_button("move_left", 13)
	_add_pad_button("move_right", 14)
	_add_pad_axis("move_left", 0, -1.0)
	_add_pad_axis("move_right", 0, 1.0)
	_add_pad_button("jump", 0)
	_add_pad_button("attack", 2)
	_add_pad_button("restart", 3)

func _add_action(action: String, deadzone: float = 0.5) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, deadzone)

func _add_key(action: String, keycode: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)

func _add_pad_button(action: String, button: int) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)

func _add_pad_axis(action: String, axis: int, axis_value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	InputMap.action_add_event(action, event)
