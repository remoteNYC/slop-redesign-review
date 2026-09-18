extends Node2D

const PUPPET_SCRIPT := preload("res://scripts/wind_puppet.gd")
const ANCHOR_SCRIPT := preload("res://scripts/thread_anchor.gd")
const ATTACH_SFX := preload("res://assets/audio/attach.wav")
const RELEASE_SFX := preload("res://assets/audio/release.wav")
const LAND_SFX := preload("res://assets/audio/land.wav")

# Intentionally authored for five questions: easy attach, timed release, chain,
# recovery, and an optional high line. Rectangles are temporary collision roofs.
var platforms: Array[Rect2] = [
	Rect2(0, 620, 320, 80),
	Rect2(320, 930, 660, 80),
	Rect2(650, 590, 320, 80),
	Rect2(970, 930, 520, 80),
	Rect2(1090, 545, 260, 80),
	Rect2(1420, 650, 420, 80),
	Rect2(1490, 450, 190, 70),
	Rect2(1490, 930, 1000, 80),
	Rect2(1890, 590, 510, 80)
]
var anchor_points := [
	Vector2(415, 270), Vector2(905, 260), Vector2(1180, 250),
	Vector2(1440, 180), Vector2(1720, 300), Vector2(2020, 270)
]
var anchors: Array[Node2D] = []
var player
var title_label: Label
var help_label: Label
var stats_label: Label
var finish_label: Label
var attach_audio: AudioStreamPlayer
var release_audio: AudioStreamPlayer
var land_audio: AudioStreamPlayer

func _ready() -> void:
	for point in anchor_points:
		var anchor := ANCHOR_SCRIPT.new() as Node2D
		anchor.position = point
		add_child(anchor)
		anchors.append(anchor)
	player = PUPPET_SCRIPT.new()
	player.name = "WindPuppet"
	player.arena = self
	player.anchors = anchors
	player.platforms = platforms
	add_child(player)
	player.finished.connect(_on_finished)
	attach_audio = _sound_player(ATTACH_SFX)
	release_audio = _sound_player(RELEASE_SFX)
	land_audio = _sound_player(LAND_SFX)
	player.attached.connect(_on_attached)
	player.released.connect(_on_released)
	player.landed.connect(_on_landed)
	var camera := Camera2D.new()
	camera.position = Vector2(90, -55)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.limit_left = 0
	camera.limit_right = 2500
	camera.limit_top = 0
	camera.limit_bottom = 1070
	player.add_child(camera)
	camera.make_current()
	_make_hud()
	queue_redraw()

func _sound_player(sound: AudioStream) -> AudioStreamPlayer:
	var output := AudioStreamPlayer.new()
	output.stream = sound
	output.volume_db = -11.0
	add_child(output)
	return output

func _on_attached(_anchor: Node2D) -> void:
	attach_audio.play()

func _on_released(speed: float) -> void:
	release_audio.volume_db = clampf(-17.0 + speed / 90.0, -17.0, -6.0)
	release_audio.pitch_scale = clampf(0.85 + speed / 1800.0, 0.85, 1.4)
	release_audio.play()

func _on_landed(speed: float) -> void:
	land_audio.volume_db = clampf(-20.0 + speed / 55.0, -20.0, -5.0)
	land_audio.play()

func _make_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	var plaque := ColorRect.new()
	plaque.position = Vector2(18, 16)
	plaque.size = Vector2(385, 145)
	plaque.color = Color(0.11, 0.16, 0.16, 0.72)
	plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(plaque)
	title_label = Label.new()
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.position = Vector2(30, 20)
	title_label.add_theme_font_size_override("font_size", 23)
	title_label.add_theme_color_override("font_color", Color("f0e6d4"))
	title_label.text = "WIND EFFIGY  /  PLAYGROUND"
	hud.add_child(title_label)
	help_label = Label.new()
	help_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	help_label.position = Vector2(30, 58)
	help_label.add_theme_font_size_override("font_size", 18)
	help_label.add_theme_color_override("font_color", Color("f0e6d4"))
	hud.add_child(help_label)
	stats_label = Label.new()
	stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_label.position = Vector2(30, 686)
	stats_label.add_theme_font_size_override("font_size", 17)
	stats_label.add_theme_color_override("font_color", Color("f0e6d4"))
	hud.add_child(stats_label)
	finish_label = Label.new()
	finish_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	finish_label.position = Vector2(440, 180)
	finish_label.add_theme_font_size_override("font_size", 29)
	finish_label.add_theme_color_override("font_color", Color("f6dab0"))
	hud.add_child(finish_label)

func _process(_delta: float) -> void:
	var hovered = player.find_target(get_global_mouse_position())
	for anchor in anchors:
		anchor.targeted = anchor == hovered
		anchor.attached = anchor == player.tether_anchor
	var section := "First swing: cross the gap"
	if player.global_position.x > 700.0:
		section = "Chain two beams, or use lower roofs"
	if player.global_position.x > 1370.0:
		section = "High line: faster / lower roof: safer"
	help_label.text = section + "\nA/D move   SPACE jump   Aim + hold LMB\nRelease to fly   R retry   Shift+R start\n1 / 2 / 3 feel variants"
	stats_label.text = "FEEL %s  %s      Speed %d      Tension %d      Attaches %d / Releases %d / Retries %d      %.1fs" % [player.profile_key, player.profile["name"], int(player.velocity.length()), int(player.rope_tension), player.attachments, player.releases, player.recoveries, player.elapsed]
	if not player.completed:
		finish_label.text = ""

func _on_finished(time_seconds: float) -> void:
	finish_label.text = "PLAYGROUND END\n%.1f seconds\nTry a different route or feel variant.\nR returns to your last roof." % time_seconds

func _draw() -> void:
	# Placeholder depth values from the reference analysis, not extracted textures.
	draw_rect(Rect2(-500, -500, 3500, 1900), Color("b9c9c8"))
	draw_colored_polygon(PackedVector2Array([Vector2(-200, 475), Vector2(160, 240), Vector2(340, 390), Vector2(630, 180), Vector2(940, 420), Vector2(1310, 170), Vector2(1710, 410), Vector2(2050, 190), Vector2(2700, 430), Vector2(2700, 1100), Vector2(-200, 1100)]), Color("9cafad"))
	draw_colored_polygon(PackedVector2Array([Vector2(-200, 575), Vector2(180, 370), Vector2(470, 525), Vector2(830, 330), Vector2(1190, 505), Vector2(1580, 345), Vector2(1930, 510), Vector2(2250, 370), Vector2(2700, 520), Vector2(2700, 1100), Vector2(-200, 1100)]), Color("748f90"))
	for i in range(14):
		var bx := float(i * 210 - 70)
		var height := float(80 + (i * 47) % 100)
		draw_rect(Rect2(bx, 565 - height, 125, height + 240), Color("7c9290"))
		draw_colored_polygon(PackedVector2Array([Vector2(bx - 12, 565 - height), Vector2(bx + 62, 530 - height), Vector2(bx + 137, 565 - height)]), Color("657e7e"))
	# Playable roofs are the strongest silhouettes. Plaster underneath is a hint of
	# the later village kit, while the top line remains unmistakable collision.
	for i in range(platforms.size()):
		var roof := platforms[i]
		var recovery := i == 1 or i == 3 or i == 7
		var plaster := Color("748780") if recovery else Color("c7c5b2")
		var timber := Color("3b4743") if recovery else Color("273332")
		draw_rect(Rect2(roof.position.x + 10, roof.position.y + 12, roof.size.x - 20, maxf(roof.size.y, 230.0)), plaster)
		draw_rect(Rect2(roof.position.x - 12, roof.position.y - 12, roof.size.x + 24, 25), timber)
		draw_line(Vector2(roof.position.x - 12, roof.position.y - 13), Vector2(roof.end.x + 12, roof.position.y - 13), Color("82938b") if recovery else Color("98a8a0"), 4.0)
		for j in range(1, int(roof.size.x / 92.0)):
			var xx := roof.position.x + j * 92.0
			draw_line(Vector2(xx, roof.position.y + 14), Vector2(xx, roof.position.y + 200), timber, 5.0)
	# The shortcut and finish read from a distance without a reward loop.
	draw_line(Vector2(1520, 407), Vector2(1640, 407), Color("e0c18d"), 3.0)
	draw_line(Vector2(2250, 580), Vector2(2250, 415), Color("302f2b"), 7.0)
	draw_colored_polygon(PackedVector2Array([Vector2(2250, 415), Vector2(2320, 440), Vector2(2250, 470)]), Color("a55642"))
