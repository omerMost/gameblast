extends Node
## Wires the game together: background, Game (+View), Camera2D fitted to the level's
## `view` rect, HUD, and the drag-back aiming gesture (prototype LOOP / INPUT / layout()).

var game: Game
var view: View
var cam: Camera2D
var hud: Hud
var bg: Background
var audio: RangerAudio
var perf_last_usec := 0
var perf_time := 0.0
var perf_frames := 0
var perf_worst_ms := 0.0
var drag = null   # {x0, y0, x, y} in viewport (virtual) pixels while aiming


func _ready() -> void:
	if OS.get_name() == "Android":
		Engine.max_fps = 60 # Match physics; avoid redrawing twice per tick on 120 Hz phones.
	var bl := CanvasLayer.new()
	bl.layer = -1
	add_child(bl)
	bg = Background.new()
	bl.add_child(bg)

	game = Game.new()
	game.name = "Game"
	add_child(game)
	bg.game = game
	view = View.new()
	view.game = game
	game.add_child(view)

	cam = Camera2D.new()
	add_child(cam)
	cam.make_current()

	hud = Hud.new()
	hud.main = self
	hud.game = game
	add_child(hud)
	game.hud_changed.connect(hud.refresh)
	game.show_result.connect(hud.show_result)
	game.player_hurt.connect(hud.hurt)

	audio = RangerAudio.new()
	audio.game = game
	add_child(audio)
	game.sound_requested.connect(audio.sfx)
	game.player_hurt.connect(audio.hurt)
	game.show_result.connect(audio.result)

	game.start_level(0)
	hud.show_title()


func play() -> void:
	var index := 0
	for i in game.available_levels():
		if i < int(Save.prog.unlocked):
			index = i
	start(index)


func start(i: int) -> void:
	audio.start_music()
	drag = null
	game.start_level(i)
	hud.hide_overlay()
	hud.set_hint(game.L.get("hint", ""))
	hud.refresh()


func restart() -> void:
	start(game.level_idx)


func open_levels() -> void:
	audio.start_music()
	drag = null
	hud.show_levels()


func _process(_dt: float) -> void:
	if OS.get_name() == "Android" and OS.is_debug_build():
		var now := Time.get_ticks_usec()
		var elapsed := (now - perf_last_usec) / 1000000.0 if perf_last_usec > 0 else 0.0
		perf_last_usec = now
		if elapsed > 1.0: # Resume after backgrounding; begin a fresh active sample.
			perf_time = 0.0
			perf_frames = 0
			perf_worst_ms = 0.0
			elapsed = 0.0
		perf_time += elapsed # Wall time, unaffected by intentional win slow-motion.
		perf_frames += 1
		perf_worst_ms = maxf(perf_worst_ms, elapsed * 1000)
		if perf_time >= 5.0:
			print("BR_PERF fps=%.1f worst_frame_ms=%.1f bodies=%d particles=%d decals=%d draw_cpu_ms=%.2f level=%d state=%s" % [perf_frames / perf_time, perf_worst_ms, game.bodies.size(), game.particles.size(), game.decals.size(), view.draw_cpu_ms, game.level_idx + 1, game.state])
			perf_time = 0.0
			perf_frames = 0
			perf_worst_ms = 0.0
	_layout()
	view.drag_active = drag != null


## prototype layout(): fit the level's view rect between the HUD bars.
func _layout() -> void:
	if game.L.is_empty():
		return
	var vs := get_viewport().get_visible_rect().size
	var W := vs.x
	var H := vs.y
	var v: Array = game.L.view
	var top := hud.top_h
	var aw := W - 12
	var ah := maxf(120, H - top - hud.bot_h - 8)
	var s := minf(aw / v[2], ah / v[3])
	var ox: float = (W - v[2] * s) / 2 - v[0] * s
	var oy: float = top + (ah - v[3] * s) / 2 - v[1] * s + 4
	cam.zoom = Vector2(s, s)
	cam.position = Vector2((W / 2 - ox) / s, (H / 2 - oy) / s)
	cam.offset = Vector2(randf() - 0.5, randf() - 0.5) * game.shake / s
	bg.hy = oy + 640 * s


func _upd_aim() -> void:
	var vs := get_viewport().get_visible_rect().size
	var d := Vector2(drag.x0 - drag.x, drag.y0 - drag.y)
	var l := d.length()
	if l < 12:
		game.aim.active = false
		return
	game.aim.dx = d.x / l
	game.aim.dy = d.y / l
	game.aim.pow = minf(1.0, l / (minf(vs.x, vs.y) * 0.32))
	game.aim.active = true


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		if ev.pressed:
			if game.state != "play" or hud.blocking():
				return
			drag = {"x0": ev.position.x, "y0": ev.position.y, "x": ev.position.x, "y": ev.position.y}
		elif drag != null:
			if game.aim.active:
				game.fire()
				hud.set_hint("")
			drag = null
			game.aim.active = false
	elif ev is InputEventMouseMotion and drag != null:
		drag.x = ev.position.x
		drag.y = ev.position.y
		_upd_aim()
	elif ev is InputEventKey and ev.pressed and ev.keycode == KEY_R and not hud.blocking():
		restart()
