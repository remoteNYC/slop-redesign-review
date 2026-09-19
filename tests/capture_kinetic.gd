extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/kinetic_prototype.tscn") as PackedScene
	var prototype = scene.instantiate()
	root.add_child(prototype)
	await process_frame
	prototype.player.invulnerable_time = 0.0
	await create_timer(0.2).timeout
	if not _save("/tmp/kinetic_relay_start.png"):
		printerr("KINETIC CAPTURE FAIL")
		quit(1)
		return
	prototype.carriage.set_physics_process(false)
	prototype.carriage.sync_to_physics = false
	prototype.carriage.position = Vector2(630, 166)
	prototype.carriage.velocity_x = 90.0
	prototype.counter_ram.position = Vector2(690, 172)
	prototype.counter_ram.state = "windup"
	prototype.counter_ram.state_time = 0.3
	prototype.player.global_position = Vector2(625, 140)
	prototype.camera.reset_smoothing()
	await create_timer(0.12).timeout
	if not _save("/tmp/kinetic_relay_counter.png"):
		quit(1)
		return
	prototype.carriage.position = Vector2(1070, 166)
	prototype.carriage.velocity_x = -45.0
	prototype.counter_ram.position = Vector2(1125, 172)
	prototype.counter_ram.state = "recover"
	prototype.counter_ram.state_time = 0.3
	prototype.player.global_position = Vector2(1070, 140)
	prototype.camera.reset_smoothing()
	await create_timer(0.12).timeout
	if not _save("/tmp/kinetic_relay_return.png"):
		quit(1)
		return
	print("KINETIC CAPTURE PASS: start, counter, and return")
	prototype.free()
	await process_frame
	quit(0)

func _save(path: String) -> bool:
	var image := root.get_texture().get_image()
	return image != null and image.save_png(path) == OK
