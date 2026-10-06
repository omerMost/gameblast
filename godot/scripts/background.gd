class_name Background
extends Control
## Screen-space sky, sun, drifting clouds and dunes (prototype drawBG()).

var game: Game
var hy := 600.0      # screen y of world y=640 (set by main each frame)
var clouds := []
var _theme := ""
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.randomize()


func _gen(theme: String) -> void:
	_theme = theme
	clouds.clear()
	var n := 9 if theme == "sky" else 4
	for i in n:
		clouds.append({"x": _rng.randf(), "y": _rng.randf_range(0.08, 0.95) if theme == "sky" else _rng.randf_range(0.06, 0.3),
			"s": _rng.randf_range(0.7, 1.6), "v": _rng.randf_range(0.004, 0.012)})


func _process(dt: float) -> void:
	size = get_viewport_rect().size   # a Control under a CanvasLayer doesn't get the viewport size on its own
	var th: String = game.L.get("theme", "desert") if game and not game.L.is_empty() else "desert"
	if th != _theme:
		_gen(th)
	for c in clouds:
		c.x += c.v * dt
		if c.x > 1.15:
			c.x = -0.15
	queue_redraw()


func _cloud(x: float, y: float, s: float) -> void:
	var c := Color(1, 1, 1, 0.92)
	for o in [[-30, 6, 22], [0, -6, 30], [32, 4, 24], [12, 10, 26], [-14, 12, 20]]:
		draw_circle(Vector2(x + o[0] * s, y + o[1] * s), o[2] * s, c)


func _vgrad(stops: Array, W: float, H: float) -> void:
	for i in stops.size() - 1:
		var y0: float = stops[i][0] * H
		var y1: float = stops[i + 1][0] * H
		draw_polygon(PackedVector2Array([Vector2(0, y0), Vector2(W, y0), Vector2(W, y1), Vector2(0, y1)]),
			PackedColorArray([stops[i][1], stops[i][1], stops[i + 1][1], stops[i + 1][1]]))


func _draw() -> void:
	var W := size.x
	var H := size.y
	var sky := _theme == "sky"
	if sky:
		_vgrad([[0, Color("#5c9be0")], [0.55, Color("#a9cff0")], [1, Color("#e8f2fb")]], W, H)
	else:
		_vgrad([[0, Color("#74cbe2")], [0.62, Color("#bfe9ee")], [1, Color("#f6e9c9")]], W, H)
	var sun := Vector2(W * 0.82, H * 0.14)
	draw_circle(sun, 90, Color(1, 244 / 255.0, 190 / 255.0, 0.18))
	draw_circle(sun, 50, Color(1, 244 / 255.0, 190 / 255.0, 0.35))
	draw_circle(sun, 24, Color(1, 250 / 255.0, 215 / 255.0, 0.95))
	for c in clouds:
		_cloud(c.x * W, c.y * H, c.s * (1.3 if sky else 0.9))
	if sky:
		for i in 9:
			var x := fmod(i * 0.13 + 0.02, 1.0) * W * 1.1 - 20
			_cloud(x, hy + 40 + (i % 3) * 28, 1.6 + (i % 2) * 0.5)
	else:
		for layer in [[Color("#efd9a6"), 40.0, 22.0, 0.006, 1.0, 10.0, 0.019], [Color("#e9cd92"), 12.0, 14.0, 0.009, 3.0, 6.0, 0.03]]:
			var pts := PackedVector2Array([Vector2(0, H)])
			var x := 0.0
			while x <= W + 20:
				pts.append(Vector2(x, hy - layer[1] - layer[2] * sin(x * layer[3] + layer[4]) - layer[5] * sin(x * layer[6])))
				x += 20
			pts.append(Vector2(W + 20, H))
			draw_colored_polygon(pts, layer[0])
