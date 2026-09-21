extends Node2D

const PlayerScene = preload("res://scripts/player.gd")
const RamScene = preload("res://scripts/enemy.gd")
const CarriageScene = preload("res://scripts/moving_platform.gd")
const DeviceScene = preload("res://scripts/rebound_device.gd")
const GateScene = preload("res://scripts/kinetic_gate.gd")
const EffectsScene = preload("res://scripts/effects.gd")
const SfxScene = preload("res://scripts/sfx.gd")

const WORLD_WIDTH := 2720.0
const START_POSITION := Vector2(48, 173)
const CHECKPOINT_ONE := Vector2(1120, 173)
const CHECKPOINT_TWO := Vector2(1864, 173)
const CHECKPOINT_THREE := Vector2(2194, 132)
const CARRIAGE_START := Vector2(1168, 166)
const CARRIAGE_RAIL_LEFT := 1136.0
const CARRIAGE_RAIL_RIGHT := 2580.0
const LAUNCH_RAM_START := Vector2(830, 172)
const COUNTER_RAM_START := Vector2(2160, 172)
const ENTRY_GATE_POSITION := Vector2(1040, 126)
const RETURN_GATE_POSITION := Vector2(2460, 126)
const EXIT_CENTER := Vector2(1600, 88)

var player: CharacterBody2D
var launch_ram: Area2D
var counter_ram: Area2D
var carriage: AnimatableBody2D
var gate: StaticBody2D
var return_gate: StaticBody2D
var camera: Camera2D
var effects: Node2D
var sfx: Node

var blocks: Array[Rect2] = []
var spike_rects: Array[Rect2] = []
var checkpoint_phase := 0
var carriage_advanced := false
var exit_deployed := false
var return_gate_was_opened := false
var mode := "title"
var attempts := 1
var elapsed := 0.0
var reset_ticket := 0

var exit_body: StaticBody2D
var exit_collision: CollisionShape2D
var goal_area: Area2D
var hud_label: Label
var help_label: Label
var overlay: ColorRect
var overlay_title: Label
var overlay_body: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_inputs()
	_build_level()
	sfx = SfxScene.new()
	add_child(sfx)
	effects = EffectsScene.new()
	add_child(effects)
	_create_actors()
	_create_ui()
	_reset_world()
	_open_title()

func _physics_process(delta: float) -> void:
	if mode == "play":
		elapsed += delta
		if is_instance_valid(carriage) and carriage.position.x >= 1840.0:
			carriage_advanced = true
		if checkpoint_phase < 2 and player.global_position.x >= 1835.0:
			_set_checkpoint(2)
		if player.global_position.y > 228.0:
			player.kill()
		if Input.is_action_just_pressed("restart"):
			player.kill()
		elif Input.is_action_just_pressed("pause"):
			mode = "paused"
			get_tree().paused = true
			_show_overlay("PAUSED", "ESC / START  RESUME\nR  RETRY CHECKPOINT")
	elif mode == "title":
		if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept"):
			_start_run()
	elif mode == "paused":
		if Input.is_action_just_pressed("pause"):
			mode = "play"
			get_tree().paused = false
			overlay.hide()
		elif Input.is_action_just_pressed("restart"):
			get_tree().paused = false
			mode = "play"
			player.kill()
	elif mode == "complete" and (Input.is_action_just_pressed("restart") or Input.is_action_just_pressed("jump")):
		_start_run()

	if is_instance_valid(camera) and is_instance_valid(player):
		camera.position.x = move_toward(camera.position.x, float(player.facing) * 38.0, 150.0 * delta)
	_update_hud()
	queue_redraw()

func _start_run() -> void:
	checkpoint_phase = 0
	attempts = 1
	elapsed = 0.0
	mode = "play"
	get_tree().paused = false
	overlay.hide()
	_reset_world()

func _open_title() -> void:
	mode = "title"
	get_tree().paused = true
	_show_overlay("CLOCKWORK RELAY", "THE MACHINE REMEMBERS MOMENTUM\n\nSPACE / GAMEPAD A  BEGIN")

func _build_level() -> void:
	_add_block(Rect2(0, 182, 260, 34))
	_add_block(Rect2(260, 130, 150, 86))
	_add_block(Rect2(410, 205, 90, 11))
	_add_block(Rect2(500, 130, 200, 12), true)
	_add_block(Rect2(700, 182, 340, 34))
	_add_block(Rect2(1054, 182, 306, 34))
	_add_block(Rect2(1840, 182, 112, 34))
	_add_block(Rect2(2070, 182, 180, 34))
	_add_block(Rect2(2474, 182, 246, 34))
	_add_block(Rect2(-16, 0, 16, 216))
	_add_block(Rect2(WORLD_WIDTH, 0, 16, 216))
	_add_spikes(Rect2(1040, 182, 14, 34))
	_add_spikes(Rect2(1360, 182, 480, 34))
	_add_spikes(Rect2(1952, 182, 118, 34))
	_add_spikes(Rect2(2250, 182, 224, 34))
	_add_device(Vector2(220, 174))
	_add_device(Vector2(472, 185))
	_create_exit()

func _create_actors() -> void:
	gate = GateScene.new()
	gate.name = "EntryShutter"
	gate.configure(ENTRY_GATE_POSITION, 112.0, 120.0)
	gate.opened.connect(_on_gate_opened)
	add_child(gate)

	return_gate = GateScene.new()
	return_gate.name = "ReturnShutter"
	return_gate.configure(RETURN_GATE_POSITION, 112.0, 120.0)
	return_gate.opened.connect(_on_return_gate_opened)
	add_child(return_gate)

	carriage = CarriageScene.new()
	carriage.name = "RelayCarriage"
	carriage.configure_kinetic(CARRIAGE_START, CARRIAGE_RAIL_LEFT, CARRIAGE_RAIL_RIGHT)
	carriage.ram_impact.connect(_on_ram_hit_carriage)
	carriage.directly_struck.connect(_on_carriage_struck)
	carriage.directly_dashed.connect(_on_carriage_dashed)
	carriage.stop_rebounded.connect(_on_carriage_stop)
	carriage.direction_reversed.connect(_on_carriage_reversed)
	add_child(carriage)

	launch_ram = _create_ram("LaunchRam", LAUNCH_RAM_START, 735.0, 1220.0, 1)
	counter_ram = _create_ram("CounterRam", COUNTER_RAM_START, 1965.0, 2510.0, -1)
	counter_ram.trigger_range = 190.0

	player = PlayerScene.new()
	player.position = START_POSITION
	player.died.connect(_on_player_died)
	player.rebounded.connect(_on_player_rebounded)
	player.jumped.connect(func(_point: Vector2) -> void: sfx.play("jump"))
	player.dashed.connect(_on_player_dashed)
	player.dash_connected.connect(_on_dash_connected)
	add_child(player)

	camera = Camera2D.new()
	camera.position = Vector2(24, -65)
	camera.limit_left = 0
	camera.limit_right = int(WORLD_WIDTH)
	camera.limit_top = 0
	camera.limit_bottom = 216
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 9.0
	player.add_child(camera)
	camera.make_current()

func _create_ram(node_name: String, at: Vector2, left: float, right: float, initial_facing: int) -> Area2D:
	var actor := RamScene.new() as Area2D
	actor.name = node_name
	actor.configure_kinetic_ram(at, left, right, initial_facing)
	actor.touched_player.connect(_on_ram_touched_player)
	actor.kinetic_struck.connect(func(_player_speed: float, _ram_speed: float) -> void:
		effects.burst(actor.global_position, Color("fff1ac"), 8)
		sfx.play("bounce")
	)
	actor.kinetic_dashed.connect(func(_player_speed: float, _ram_speed: float) -> void:
		effects.burst(actor.global_position, Color("a9f4dd"), 10)
		sfx.play("hit")
	)
	add_child(actor)
	return actor

func _create_exit() -> void:
	exit_body = StaticBody2D.new()
	exit_body.position = EXIT_CENTER
	exit_body.collision_layer = 1
	exit_body.collision_mask = 0
	exit_collision = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(110, 10)
	exit_collision.shape = shape
	exit_collision.one_way_collision = true
	exit_collision.one_way_collision_margin = 4.0
	exit_collision.disabled = true
	exit_body.add_child(exit_collision)
	add_child(exit_body)

	goal_area = Area2D.new()
	goal_area.position = Vector2(EXIT_CENTER.x, 62)
	goal_area.collision_layer = 0
	goal_area.collision_mask = 2
	goal_area.monitoring = false
	var goal_collision := CollisionShape2D.new()
	var goal_shape := RectangleShape2D.new()
	goal_shape.size = Vector2(34, 40)
	goal_collision.shape = goal_shape
	goal_area.add_child(goal_collision)
	goal_area.body_entered.connect(_on_goal_body)
	add_child(goal_area)

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
		collision.one_way_collision_margin = 4.0
	body.add_child(collision)
	add_child(body)

func _add_spikes(rect: Rect2) -> void:
	spike_rects.append(rect)
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
	area.body_entered.connect(func(body: Node2D) -> void:
		if body.is_in_group("player") and mode == "play":
			player.kill()
	)
	add_child(area)

func _add_device(at: Vector2) -> void:
	var device := DeviceScene.new()
	device.position = at
	device.activated.connect(func(point: Vector2) -> void:
		effects.burst(point, Color("fff1ac"), 8)
		sfx.play("bounce")
	)
	add_child(device)

func _on_gate_opened() -> void:
	if checkpoint_phase < 1:
		_set_checkpoint(1)
	effects.burst(gate.global_position, Color("a2f0cf"), 16)
	sfx.play("checkpoint")

func _on_return_gate_opened() -> void:
	return_gate_was_opened = true
	if checkpoint_phase < 3:
		_set_checkpoint(3)
	_deploy_exit()
	effects.burst(return_gate.global_position, Color("a2f0cf"), 18)
	sfx.play("checkpoint")

func _set_checkpoint(phase: int) -> void:
	if phase <= checkpoint_phase:
		return
	checkpoint_phase = phase
	var point := CHECKPOINT_ONE
	if phase == 2:
		point = CHECKPOINT_TWO
	elif phase >= 3:
		point = CHECKPOINT_THREE
	effects.burst(point + Vector2(0, -18), Color("a2f0cf"), 12)
	sfx.play("checkpoint")

func _on_carriage_reversed(at: Vector2, _speed: float) -> void:
	if carriage_advanced:
		effects.burst(at, Color("a9f4dd"), 8)

func _deploy_exit() -> void:
	if exit_deployed:
		return
	exit_deployed = true
	exit_collision.set_deferred("disabled", false)
	goal_area.set_deferred("monitoring", true)
	effects.burst(EXIT_CENTER, Color("a9f4dd"), 18)
	sfx.play("checkpoint")

func _on_ram_hit_carriage(_ram_speed: float, _carriage_speed: float) -> void:
	effects.burst(carriage.global_position, Color("a9f4dd"), 10)
	sfx.play("hit")

func _on_carriage_struck(_player_speed: float, _carriage_speed: float) -> void:
	effects.burst(carriage.global_position + Vector2(0, -15), Color("fff1ac"), 7)

func _on_carriage_dashed(_player_speed: float, _carriage_speed: float) -> void:
	effects.burst(carriage.global_position, Color("a9f4dd"), 9)
	sfx.play("hit")

func _on_carriage_stop(_side: int, _incoming_speed: float, _outgoing_speed: float) -> void:
	sfx.play("hit")

func _on_player_rebounded(at: Vector2) -> void:
	effects.burst(at, Color("f6d68c"), 8)
	sfx.play("bounce")

func _on_player_dashed(at: Vector2) -> void:
	effects.burst(at, Color("a9f4dd"), 6)
	sfx.play("dash")

func _on_dash_connected(at: Vector2) -> void:
	effects.burst(at, Color("a9f4dd"), 10)

func _on_ram_touched_player(_source: Vector2) -> void:
	if mode == "play":
		player.kill()

func _on_player_died() -> void:
	if mode != "play":
		return
	mode = "dead"
	attempts += 1
	reset_ticket += 1
	var ticket := reset_ticket
	effects.burst(player.global_position, Color("e9876c"), 14)
	sfx.play("death")
	await get_tree().create_timer(0.28).timeout
	if mode == "dead" and ticket == reset_ticket:
		mode = "play"
		_reset_world()

func _on_goal_body(body: Node2D) -> void:
	if mode != "play" or not body.is_in_group("player"):
		return
	mode = "complete"
	player.active = false
	player.velocity = Vector2.ZERO
	sfx.play("win")
	effects.burst(player.global_position, Color("fff1ac"), 24)
	_show_overlay("RELAY COMPLETE", "%02d:%02d   %d ATTEMPTS\n\nR / SPACE  RUN AGAIN" % [int(elapsed / 60.0), int(elapsed) % 60, attempts])

func _reset_world() -> void:
	reset_ticket += 1
	exit_deployed = checkpoint_phase >= 3
	return_gate_was_opened = checkpoint_phase >= 3
	carriage_advanced = checkpoint_phase >= 2
	exit_collision.set_deferred("disabled", not exit_deployed)
	goal_area.set_deferred("monitoring", exit_deployed)
	gate.set_open(checkpoint_phase >= 1)
	return_gate.set_open(checkpoint_phase >= 3)
	counter_ram.reset_kinetic(COUNTER_RAM_START)

	match checkpoint_phase:
		0:
			launch_ram.reset_kinetic(LAUNCH_RAM_START)
			carriage.reset_kinetic(CARRIAGE_START, 0.0)
			player.reset_at(START_POSITION)
		1:
			launch_ram.reset_kinetic(Vector2(780, 172), "idle", 0.0)
			launch_ram.cooldown = 0.8
			carriage.reset_kinetic(Vector2(1175, 166), 0.0)
			player.reset_at(CHECKPOINT_ONE)
		2:
			launch_ram.reset_kinetic(Vector2(780, 172), "idle", 0.0)
			launch_ram.cooldown = 2.0
			carriage.reset_kinetic(Vector2(1805, 166), 72.0)
			player.reset_at(CHECKPOINT_TWO)
		_:
			launch_ram.reset_kinetic(Vector2(780, 172), "idle", 0.0)
			launch_ram.cooldown = 2.0
			counter_ram.reset_kinetic(Vector2(2395, 172), "recover", 0.0)
			counter_ram.state_time = 1.2
			carriage.reset_kinetic(Vector2(2194, 166), -78.0)
			player.reset_at(CHECKPOINT_THREE)
	if is_instance_valid(camera):
		camera.reset_smoothing()
	queue_redraw()

func _create_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	hud_label = _label(Vector2(8, 6), Vector2(368, 16), 9, Color("f5dfa8"))
	canvas.add_child(hud_label)
	help_label = _label(Vector2(7, 198), Vector2(372, 14), 8, Color("b6c4bf"))
	help_label.text = "A/D MOVE   SPACE JUMP   K/C DASH   J/X DOWN STRIKE   R RETRY"
	canvas.add_child(help_label)
	overlay = ColorRect.new()
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(384, 216)
	overlay.color = Color(0.055, 0.1, 0.14, 0.92)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(overlay)
	overlay_title = _label(Vector2(20, 52), Vector2(344, 28), 20, Color("f1c883"))
	overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay.add_child(overlay_title)
	overlay_body = _label(Vector2(24, 92), Vector2(336, 78), 10, Color("d1d9cb"))
	overlay_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay.add_child(overlay_body)

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

func _show_overlay(title: String, body: String) -> void:
	overlay_title.text = title
	overlay_body.text = body
	overlay.show()

func _update_hud() -> void:
	if hud_label == null or player == null:
		return
	var checkpoint_text: String = ["ENTRY", "SHUTTER", "COUNTER", "RETURN"][checkpoint_phase]
	hud_label.text = "%02d:%02d   TRY %d   %s   %s" % [
		int(elapsed / 60.0),
		int(elapsed) % 60,
		attempts,
		checkpoint_text,
		"DASH READY" if player.dash_ready else "DASH SPENT",
	]

func _draw() -> void:
	_draw_background()
	for rect in blocks:
		_draw_block(rect)
	for rect in spike_rects:
		_draw_spikes(rect)
	_draw_rail()
	_draw_checkpoint(Vector2(1122, 176), checkpoint_phase >= 1)
	_draw_checkpoint(Vector2(1864, 176), checkpoint_phase >= 2)
	_draw_checkpoint(Vector2(2194, 176), checkpoint_phase >= 3)
	_draw_exit()
	_draw_affordances()

func _draw_background() -> void:
	draw_rect(Rect2(0, 0, WORLD_WIDTH, 216), Color("111c2a"))
	for x in range(0, int(WORLD_WIDTH), 256):
		draw_rect(Rect2(x + 26, 28, 38, 188), Color("182737"))
		draw_rect(Rect2(x + 70, 28, 4, 188), Color("304150"))
		_draw_gear(Vector2(x + 170, 72), 24, Color("273d48"))
	for y in [42, 104, 166]:
		draw_rect(Rect2(0, y, WORLD_WIDTH, 2), Color("263847"))

func _draw_gear(center: Vector2, radius: int, color: Color) -> void:
	draw_arc(center, radius, 0.0, TAU, 24, color, 4.0)
	draw_circle(center, radius * 0.38, Color("1a2b3b"))
	draw_circle(center, radius * 0.12, color)

func _draw_block(rect: Rect2) -> void:
	draw_rect(rect, Color("283b47"))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4)), Color("c3935f"))
	draw_rect(Rect2(rect.position + Vector2(0, 4), Vector2(rect.size.x, 3)), Color("6d6d60"))
	for x in range(int(rect.position.x) + 8, int(rect.end.x) - 4, 16):
		draw_rect(Rect2(x, rect.position.y + 1, 2, 2), Color("f0ca84"))

func _draw_spikes(rect: Rect2) -> void:
	draw_rect(Rect2(rect.position.x, rect.position.y + 7, rect.size.x, rect.size.y - 7), Color("743f41"))
	for x in range(int(rect.position.x), int(rect.end.x), 8):
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, rect.position.y + 8),
			Vector2(x + 4, rect.position.y),
			Vector2(x + 8, rect.position.y + 8),
		]), Color("ef9569"))

func _draw_rail() -> void:
	draw_line(Vector2(CARRIAGE_RAIL_LEFT - 30, 180), Vector2(CARRIAGE_RAIL_RIGHT + 38, 180), Color("657b83"), 2.0)
	for x in range(int(CARRIAGE_RAIL_LEFT - 18), int(CARRIAGE_RAIL_RIGHT + 32), 28):
		draw_rect(Rect2(x, 178, 10, 3), Color("304551"))
	draw_rect(Rect2(CARRIAGE_RAIL_LEFT - 5, 151, 5, 31), Color("e5b873"))
	draw_rect(Rect2(CARRIAGE_RAIL_RIGHT + 32, 151, 5, 31), Color("e5b873"))

func _draw_checkpoint(at: Vector2, active_checkpoint: bool) -> void:
	var color := Color("a2f0cf") if active_checkpoint else Color("657b7d")
	draw_rect(Rect2(at.x - 2, at.y - 19, 4, 19), Color("a47b55"))
	draw_circle(at + Vector2(0, -21), 4.0, color)

func _draw_exit() -> void:
	if exit_deployed:
		draw_rect(Rect2(EXIT_CENTER.x - 55, 83, 110, 10), Color("283b47"))
		draw_rect(Rect2(EXIT_CENTER.x - 55, 83, 110, 3), Color("a9f4dd"))
		draw_line(Vector2(EXIT_CENTER.x + 55, 83), Vector2(EXIT_CENTER.x + 80, 55), Color("657b83"), 2.0)
		_draw_goal(Vector2(EXIT_CENTER.x, 80))
	else:
		draw_rect(Rect2(EXIT_CENTER.x + 47, 38, 8, 50), Color("304551"))
		draw_rect(Rect2(EXIT_CENTER.x + 44, 38, 14, 5), Color("657b83"))
		for y in range(48, 84, 10):
			draw_rect(Rect2(EXIT_CENTER.x + 45, y, 12, 3), Color("526b75"))

func _draw_goal(at: Vector2) -> void:
	draw_rect(Rect2(at.x - 2, at.y - 36, 4, 38), Color("a47b55"))
	draw_rect(Rect2(at.x - 10, at.y - 26, 20, 4), Color("e4b77c"))
	draw_rect(Rect2(at.x - 7, at.y - 22, 14, 13), Color("dba866"))
	draw_rect(Rect2(at.x - 3, at.y - 9, 6, 3), Color("fff1ac"))

func _draw_affordances() -> void:
	for y in [150, 143, 136]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(211, y),
			Vector2(229, y),
			Vector2(220, y + 7),
		]), Color("d4a65e", 0.65))
	draw_line(Vector2(382, 92), Vector2(558, 92), Color("a9f4dd", 0.55), 2.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(558, 92),
		Vector2(547, 86),
		Vector2(547, 98),
	]), Color("a9f4dd", 0.65))
	draw_line(Vector2(1034, 52), Vector2(EXIT_CENTER.x, 52), Color("526b75"), 2.0)
	draw_line(Vector2(EXIT_CENTER.x, 52), Vector2(2454, 52), Color("526b75"), 2.0)

func _setup_inputs() -> void:
	_add_action("move_left", 0.2)
	_add_action("move_right", 0.2)
	_add_action("aim_up", 0.2)
	_add_action("aim_down", 0.2)
	_add_action("jump")
	_add_action("attack")
	_add_action("dash")
	_add_action("pause")
	_add_action("restart")
	_add_key("move_left", KEY_A)
	_add_key("move_left", KEY_LEFT)
	_add_key("move_right", KEY_D)
	_add_key("move_right", KEY_RIGHT)
	_add_key("aim_up", KEY_W)
	_add_key("aim_up", KEY_UP)
	_add_key("aim_down", KEY_S)
	_add_key("aim_down", KEY_DOWN)
	_add_key("jump", KEY_SPACE)
	_add_key("attack", KEY_J)
	_add_key("attack", KEY_X)
	_add_key("dash", KEY_K)
	_add_key("dash", KEY_C)
	_add_key("pause", KEY_ESCAPE)
	_add_key("restart", KEY_R)
	_add_pad_button("move_left", 13)
	_add_pad_button("move_right", 14)
	_add_pad_button("aim_up", 11)
	_add_pad_button("aim_down", 12)
	_add_pad_axis("move_left", 0, -1.0)
	_add_pad_axis("move_right", 0, 1.0)
	_add_pad_axis("aim_up", 1, -1.0)
	_add_pad_axis("aim_down", 1, 1.0)
	_add_pad_button("jump", 0)
	_add_pad_button("attack", 2)
	_add_pad_button("dash", 1)
	_add_pad_button("pause", 6)
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
