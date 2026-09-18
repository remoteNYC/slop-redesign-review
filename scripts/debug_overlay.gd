extends Label

@export var player_path: NodePath = ^"../../../Player"

var _player: TraversalPlayer


func _ready() -> void:
	_player = get_node_or_null(player_path) as TraversalPlayer
	if _player == null:
		push_error("DebugOverlay player_path does not point to TraversalPlayer")
	add_theme_font_size_override("font_size", 19)
	add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.95))
	add_theme_constant_override("shadow_offset_x", 2)
	add_theme_constant_override("shadow_offset_y", 2)


func _process(_delta: float) -> void:
	if _player == null:
		return
	var dash_state := "READY" if _player.dash_cooldown_remaining <= 0.0 else "%.2fs" % _player.dash_cooldown_remaining
	var tether_state := "FREE"
	if _player.tether_anchor != null:
		tether_state = "%s (%.1fm)" % [_player.tether_anchor.anchor_label, _player.rope_length]
	var material_state := ""
	if _player.tether_anchor != null:
		match _player.tether_anchor.kind:
			TetherAnchor.Kind.ELASTIC:
				material_state = "  Stored: %.1f J" % _player.tether_anchor.stored_energy()
			TetherAnchor.Kind.RESONANT:
				material_state = "  Bell: %.2f rad/s" % _player.tether_anchor.angular_speed()
	text = """MOMENTUM LAB / GREYBOX
WASD move   Mouse orbit   Space jump   Shift dash
Hold Right Mouse tether   Release to launch   R respawn   Esc mouse

Speed: %.1f m/s   Vertical: %+.1f m/s
Grounded: %s   Dash: %s   Tether: %s
Tension: %.1f N   Swing: %.2f rad/s%s

Try: rigid -> bamboo -> bell, then invent another chain.""" % [
		_player.horizontal_speed(),
		_player.velocity.y,
		"YES" if _player.is_on_floor() else "NO",
		dash_state,
		tether_state,
		_player.tether_tension,
		_player.swing_angular_speed,
		material_state,
	]
