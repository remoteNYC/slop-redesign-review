extends Node2D

const LevelScene = preload("res://scripts/level.gd")
const PlayerScene = preload("res://scripts/player.gd")
const EffectsScene = preload("res://scripts/effects.gd")
const SfxScene = preload("res://scripts/sfx.gd")

const START_POSITION := Vector2(48, 470)

var level: Node2D
var player: CharacterBody2D
var effects: Node2D
var sfx: Node
var camera: Camera2D
var mode := "title"
var checkpoint := START_POSITION
var checkpoint_index := 0
var elapsed := 0.0

var hud_label: Label
var help_label: Label
var overlay: ColorRect
var overlay_title: Label
var overlay_body: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_inputs()
	sfx = SfxScene.new()
	add_child(sfx)
	_create_level()
	player = PlayerScene.new()
	player.position = START_POSITION
	player.health_changed.connect(_on_health_changed)
	player.died.connect(_on_player_died)
	player.rebounded.connect(_on_rebounded)
	player.jumped.connect(func(_point: Vector2) -> void: sfx.play("jump"))
	add_child(player)
	camera = Camera2D.new()
	camera.position = Vector2(0, -12)
	camera.limit_left = 0
	camera.limit_right = int(level.WORLD_WIDTH)
	camera.limit_top = 160
	camera.limit_bottom = 530
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	player.add_child(camera)
	camera.make_current()
	effects = EffectsScene.new()
	add_child(effects)
	_create_ui()
	_show_overlay("CLOCKWORK ASCENT", "A tower of teeth and time.\n\nRun, jump, and strike downward to rise.\n\nENTER / SPACE / GAMEPAD A  TO BEGIN")
	get_tree().paused = true

func _process(delta: float) -> void:
	if mode == "play":
		elapsed += delta
		if Input.is_action_just_pressed("pause"):
			mode = "paused"
			get_tree().paused = true
			_show_overlay("PAUSED", "ESC / START  TO RESUME\nR  TO RETRY FROM CHECKPOINT")
		elif Input.is_action_just_pressed("restart"):
			_retry_checkpoint()
	elif mode == "title":
		if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept"):
			_start_game()
	elif mode == "paused":
		if Input.is_action_just_pressed("pause"):
			mode = "play"
			get_tree().paused = false
			overlay.hide()
		elif Input.is_action_just_pressed("restart"):
			get_tree().paused = false
			_retry_checkpoint()
	elif mode == "won":
		if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("restart"):
			_new_run()
	if mode == "play" and player.global_position.y > 565.0:
		player.kill()
	_update_hud()

func _start_game() -> void:
	mode = "play"
	get_tree().paused = false
	overlay.hide()
	player.reset_at(START_POSITION)

func _new_run() -> void:
	checkpoint = START_POSITION
	checkpoint_index = 0
	elapsed = 0.0
	get_tree().paused = false
	player.reset_at(START_POSITION)
	_rebuild_level()
	camera.reset_smoothing()
	mode = "play"
	overlay.hide()

func _retry_checkpoint() -> void:
	if mode == "dead":
		return
	mode = "dead"
	get_tree().paused = false
	overlay.hide()
	player.kill()

func _on_player_died() -> void:
	if mode == "won" or mode == "title":
		return
	mode = "dead"
	effects.burst(player.global_position, Color("e9876c"), 15)
	sfx.play("death")
	get_tree().create_timer(0.45).timeout.connect(_finish_respawn)

func _finish_respawn() -> void:
	if mode != "dead":
		return
	player.reset_at(checkpoint)
	_rebuild_level()
	camera.reset_smoothing()
	mode = "play"

func _create_level() -> void:
	level = LevelScene.new()
	add_child(level)
	move_child(level, 0)
	level.player_touched_enemy.connect(_on_player_touched_enemy)
	level.lethal_hazard.connect(_on_lethal_hazard)
	level.checkpoint_reached.connect(_on_checkpoint_reached)
	level.stage_finished.connect(_on_stage_finished)
	level.enemy_defeated.connect(_on_enemy_defeated)
	level.device_activated.connect(_on_device_activated)
	level.set_active_checkpoint(checkpoint_index)

func _rebuild_level() -> void:
	level.free()
	_create_level()

func _on_player_touched_enemy(source: Vector2) -> void:
	if mode == "play":
		player.take_damage(source)

func _on_lethal_hazard() -> void:
	if mode == "play":
		player.kill()

func _on_checkpoint_reached(at: Vector2, index: int) -> void:
	if mode != "play" or index <= checkpoint_index:
		return
	checkpoint = at
	checkpoint_index = index
	sfx.play("checkpoint")
	effects.burst(at + Vector2(0, -16), Color("a2f0cf"), 14)

func _on_stage_finished() -> void:
	if mode != "play":
		return
	mode = "won"
	sfx.play("win")
	effects.burst(player.global_position, Color("fff1ac"), 22)
	get_tree().paused = true
	_show_overlay("TOWER CLEARED", "THE BELL RINGS AGAIN\n\nTIME  %02d:%02d\n\nENTER / SPACE  TO PLAY AGAIN" % [int(elapsed / 60.0), int(elapsed) % 60])

func _on_enemy_defeated(at: Vector2) -> void:
	effects.burst(at, Color("e9b96f"), 12)
	sfx.play("hit")

func _on_device_activated(at: Vector2) -> void:
	effects.burst(at, Color("fff1ac"), 8)

func _on_rebounded(at: Vector2) -> void:
	effects.burst(at, Color("f6d68c"), 9)
	sfx.play("bounce")

func _on_health_changed(value: int) -> void:
	if value < 3 and value > 0:
		effects.burst(player.global_position, Color("e9876c"), 8)
		sfx.play("hit")
	_update_hud()

func _create_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	hud_label = _label(Vector2(10, 8), Vector2(365, 17), 10, Color("f5dfa8"))
	canvas.add_child(hud_label)
	help_label = _label(Vector2(9, 195), Vector2(366, 15), 8, Color("b6c4bf"))
	help_label.text = "A/D MOVE   SPACE JUMP   J / X DOWN STRIKE   ESC PAUSE   R RETRY"
	canvas.add_child(help_label)
	overlay = ColorRect.new()
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(384, 216)
	overlay.color = Color(0.055, 0.1, 0.14, 0.91)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(overlay)
	overlay_title = _label(Vector2(22, 49), Vector2(340, 29), 21, Color("f1c883"))
	overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay.add_child(overlay_title)
	overlay_body = _label(Vector2(25, 93), Vector2(334, 100), 10, Color("d1d9cb"))
	overlay_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay.add_child(overlay_body)
	_update_hud()

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
	hud_label.text = "HP %d/3     CLOCKWORK TOWER     %02d:%02d" % [player.health, int(elapsed / 60.0), int(elapsed) % 60]

func _setup_inputs() -> void:
	_add_action("move_left", 0.2)
	_add_action("move_right", 0.2)
	_add_action("jump")
	_add_action("attack")
	_add_action("pause")
	_add_action("restart")
	_add_key("move_left", KEY_A)
	_add_key("move_left", KEY_LEFT)
	_add_key("move_right", KEY_D)
	_add_key("move_right", KEY_RIGHT)
	_add_key("jump", KEY_SPACE)
	_add_key("attack", KEY_J)
	_add_key("attack", KEY_X)
	_add_key("pause", KEY_ESCAPE)
	_add_key("restart", KEY_R)
	_add_pad_button("move_left", 13)
	_add_pad_button("move_right", 14)
	_add_pad_axis("move_left", 0, -1.0)
	_add_pad_axis("move_right", 0, 1.0)
	_add_pad_button("jump", 0)
	_add_pad_button("attack", 2)
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
