extends Node
## Diagnostic (needs a window): save screenshots of a level mid-aim and mid-blast.
## godot --path . res://tests/shot.tscn -- --level=2 --out=/tmp/x

func _ready() -> void:
	var main = await TestUtil.boot(self)
	main.set_process_unhandled_input(false)   # keep the real mouse from moving the aim
	var g: Game = Debug.game
	var lvl := 2
	var out := "user://shot"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--level="): lvl = int(a.split("=")[1])
		if a.begins_with("--out="): out = a.split("=")[1]
	await Debug.start_level(lvl - 1)
	main.hud.set_hint(g.L.get("hint", ""))
	var am := OS.get_environment("BR_AIM").split(",") if OS.get_environment("BR_AIM") != "" else PackedStringArray(["37", "0.7", "grenade"])
	var ang := deg_to_rad(float(am[0]))
	Debug.set_aim(cos(ang), -sin(ang), float(am[1]), am[2])
	g.aim.active = true
	main.drag = {"x0": 300.0, "y0": 400.0, "x": 220.0, "y": 460.0}
	await Debug.step(5)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "_aim.png")
	main.drag = null
	Debug.fire()
	await Debug.step(int(OS.get_environment("BR_TICKS")) if OS.get_environment("BR_TICKS") != "" else 48)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "_blast.png")
	get_tree().quit(0)
