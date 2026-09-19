extends Node2D

const PlayerScene = preload("res://scripts/player.gd")
const EnemyScene = preload("res://scripts/enemy.gd")
const PlatformScene = preload("res://scripts/moving_platform.gd")
const EffectsScene = preload("res://scripts/effects.gd")
const SfxScene = preload("res://scripts/sfx.gd")

const START_POSITION := Vector2(40, 173)
const RAM_START := Vector2(86, 172)
const CARRIAGE_START := Vector2(176, 166)
const RAIL_LEFT := 176.0
const RAIL_RIGHT := 280.0
const RAM_LEFT := 42.0
const RAM_RIGHT := 304.0

var player: CharacterBody2D
var ram: Area2D
var carriage: AnimatableBody2D
var effects: Node2D
var sfx: Node
var blocks: Array[Rect2] = []
var spike_rect := Rect2(144, 182, 171, 34)
var mode := "play"
var attempts := 1
var last_event := "Bait the ram, then choose the speed of your stomp."
var reset_ticket := 0

var debug_label: Label
var help_label: Label
var result_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_inputs()
	_build_room()
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

func _build_room() -> void:
	_add_block(Rect2(0, 182, 315, 34))
	_add_block(Rect2(315, 132, 69, 84))
	_add_block(Rect2(-16, 0, 16, 216))
	_add_block(Rect2(384, 0, 16, 216))
	_add_spikes(spike_rect)
	_add_goal(Vector2(352, 110))

func _create_actors() -> void:
	carriage = PlatformScene.new()
	carriage.configure_kinetic(CARRIAGE_START, RAIL_LEFT, RAIL_RIGHT)
	carriage.ram_impact.connect(_on_ram_hit_carriage)
	carriage.directly_struck.connect(_on_carriage_struck)
	carriage.stop_rebounded.connect(_on_carriage_stop)
	add_child(carriage)

	ram = EnemyScene.new()
	ram.configure_kinetic_ram(RAM_START, RAM_LEFT, RAM_RIGHT)
	ram.touched_player.connect(_on_ram_touched_player)
	ram.kinetic_struck.connect(_on_ram_struck)
	ram.carriage_hit.connect(func(_ram_speed: float, _carriage_speed: float) -> void: sfx.play("hit"))
	add_child(ram)

	player = PlayerScene.new()
	player.position = START_POSITION
	player.died.connect(_on_player_died)
	player.rebounded.connect(_on_player_rebounded)
	player.jumped.connect(func(_point: Vector2) -> void: sfx.play("jump"))
	add_child(player)

	effects = EffectsScene.new()
	add_child(effects)
	sfx = SfxScene.new()
	add_child(sfx)

func reset_encounter() -> void:
	reset_ticket += 1
	mode = "play"
	if is_instance_valid(carriage):
		carriage.reset_kinetic()
	if is_instance_valid(ram):
		ram.reset_kinetic()
	if is_instance_valid(player):
		player.reset_at(START_POSITION)
	last_event = "Bait the ram, then choose the speed of your stomp."
	if result_label != null:
		result_label.text = ""
	queue_redraw()

func _on_player_died() -> void:
	if mode != "play":
		return
	mode = "dead"
	attempts += 1
	last_event = "Death. The room will reset to the same state."
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

func _on_ram_struck(player_speed: float, ram_speed: float) -> void:
	last_event = "RAM STRIKE  player %+.0f  -> ram %+.0f" % [player_speed, ram_speed]
	effects.burst(ram.global_position, Color("fff1ac"), 8)

func _on_ram_hit_carriage(ram_speed: float, carriage_speed: float) -> void:
	last_event = "RAM IMPACT  ram %+.0f  -> carriage %+.0f" % [ram_speed, carriage_speed]
	effects.burst(carriage.global_position, Color("a9f4dd"), 10)

func _on_carriage_struck(player_speed: float, carriage_speed: float) -> void:
	last_event = "CARRIAGE CORRECTION  player %+.0f  -> carriage %+.0f" % [player_speed, carriage_speed]
	effects.burst(carriage.global_position + Vector2(0, -16), Color("fff1ac"), 7)

func _on_carriage_stop(side: int, incoming_speed: float, outgoing_speed: float) -> void:
	last_event = "%s STOP  carriage %+.0f  -> %+.0f" % ["RIGHT" if side > 0 else "LEFT", incoming_speed, outgoing_speed]
	sfx.play("hit")

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
			result_label.text = "EXIT REACHED\nR  RESET THE EXPERIMENT"
			sfx.play("win")
	)
	add_child(goal)

func _create_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	debug_label = _label(Vector2(7, 5), Vector2(370, 30), 9, Color("f5dfa8"))
	canvas.add_child(debug_label)
	help_label = _label(Vector2(7, 196), Vector2(370, 16), 8, Color("b6c4bf"))
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
	if debug_label == null or not is_instance_valid(ram) or not is_instance_valid(carriage):
		return
	debug_label.text = "DEBUG  RAM x%3.0f v%+4.0f   CART x%3.0f v%+4.0f   TRY %d\n%s" % [
		ram.position.x,
		ram.velocity_x,
		carriage.position.x,
		carriage.velocity_x,
		attempts,
		last_event,
	]

func _draw() -> void:
	draw_rect(Rect2(0, 0, 384, 216), Color("111c2a"))
	draw_rect(Rect2(0, 145, 384, 71), Color("182737"))
	for rect in blocks:
		draw_rect(rect, Color("283b47"))
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4)), Color("c3935f"))
	for x in range(int(spike_rect.position.x), int(spike_rect.end.x), 8):
		var points := PackedVector2Array([
			Vector2(x, spike_rect.position.y + 8),
			Vector2(x + 4, spike_rect.position.y),
			Vector2(x + 8, spike_rect.position.y + 8),
		])
		draw_colored_polygon(points, Color("ef9569"))
	draw_line(Vector2(RAIL_LEFT - 32, 180), Vector2(RAIL_RIGHT + 32, 180), Color("657b83"), 2.0)
	draw_rect(Rect2(RAIL_LEFT - 36, 154, 4, 28), Color("e5b873"))
	draw_rect(Rect2(RAIL_RIGHT + 32, 154, 4, 28), Color("e5b873"))
	draw_rect(Rect2(344, 95, 16, 4), Color("fff1ac"))
	draw_rect(Rect2(350, 99, 4, 20), Color("dba866"))
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
