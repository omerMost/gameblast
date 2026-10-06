class_name View
extends Node2D
## World renderer (prototype DRAWING section). Draws in world coordinates under the Camera2D.
## Render only: never changes physics.

var game: Game
var font: Font
var drag_active := false   # set by main while the player is aiming


func _ready() -> void:
	font = load("res://assets/fonts/lilita-one-latin.woff2") if ResourceLoader.exists("res://assets/fonts/lilita-one-latin.woff2") else ThemeDB.fallback_font
	z_index = 10


func _process(_dt: float) -> void:
	queue_redraw()


static func rr(x: float, y: float, w: float, h: float, r: float) -> PackedVector2Array:
	r = minf(r, minf(w, h) / 2)
	var pts := PackedVector2Array()
	var cs := [Vector2(x + w - r, y + r), Vector2(x + w - r, y + h - r), Vector2(x + r, y + h - r), Vector2(x + r, y + r)]
	for i in 4:
		for k in 5:
			var a := -PI / 2 + (i + k / 4.0) * PI / 2
			pts.append(cs[i] + Vector2(cos(a), sin(a)) * r)
	return pts


func _fill_outline(pts: PackedVector2Array, fill: Color, line: Color, lw: float) -> void:
	draw_colored_polygon(pts, fill)
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, line, lw, true)


func _draw() -> void:
	if game == null or game.player == null:
		return
	var t := Time.get_ticks_msec() / 1000.0
	for e in game.portals:
		_draw_portal(e, t)
	for s in game.statics:
		_draw_static(s)
	_draw_decals()
	for b in game.bodies:
		match b.kind:
			"block": _draw_block(b)
			"boulder": _draw_boulder(b)
			"barrel": _draw_barrel(b)
			"rag": _draw_rag(b)
	for b in game.bodies:
		match b.kind:
			"enemy": _draw_enemy(b)
			"grenade": _draw_grenade(b)
			"rocket": _draw_rocket(b)
			"bullet": _draw_bullet(b)
	_draw_player()
	_draw_particles()
	if drag_active and game.aim.active and game.can_fire():
		var r0 := 4.5 / maxf(0.2, get_viewport().get_camera_2d().zoom.x if get_viewport().get_camera_2d() else 1.0)
		var i := 0
		for p in game.predict():
			if not p.gap:
				var rad := maxf(r0 * 0.45, r0 * (1 - i * 0.012))
				draw_circle(p.pos, rad, Color("#7dffa2") if p.w else Color(1, 1, 1, 0.95))
				draw_arc(p.pos, rad, 0, TAU, 12, Color(42 / 255.0, 33 / 255.0, 64 / 255.0, 0.55), 1.5 * r0 / 4.5)
			i += 1


func _draw_static(s: GStatic) -> void:
	if s.kind == "pad":
		draw_set_transform(s.position, s.rotation)
		var h := s.size / 2
		_fill_outline(rr(-h.x, -h.y, s.size.x, s.size.y, 6), Color("#ff5a6e"), Color("#b8243a"), 3)
		draw_set_transform(Vector2.ZERO)
		return
	var sky: bool = game.L.get("theme", "desert") == "sky"
	var c0 := Color("#e4bd77") if sky else Color("#ecc27a")
	var c1 := Color("#b98a45") if sky else Color("#c99348")
	var top := minf(s.poly[0].y, s.poly[1].y)
	var cols := PackedColorArray()
	for v in s.poly:
		cols.append(c0.lerp(c1, clampf((v.y - top) / 320.0, 0, 1)))
	draw_polygon(s.poly, cols)
	var crc := Color(95 / 255.0, 60 / 255.0, 20 / 255.0, 0.45) if sky else Color(120 / 255.0, 80 / 255.0, 30 / 255.0, 0.22)
	for c in s.cracks:
		draw_polyline(c, crc, 1.6 if sky else 1.2, true)
	var closed := s.poly.duplicate()
	closed.append(s.poly[0])
	draw_polyline(closed, Color(120 / 255.0, 78 / 255.0, 28 / 255.0, 0.45), 2, true)
	draw_line(s.poly[0] + Vector2(0, 2), s.poly[1] + Vector2(0, 2), Color("#f8dc9e"), 6, true)


func _draw_decals() -> void:
	for d in game.decals:
		if d.t == "scorch":
			draw_circle(Vector2(d.x, d.y), d.r, Color(0.16, 0.1, 0.05, 0.28))
			draw_circle(Vector2(d.x, d.y), d.r * 0.55, Color(0.1, 0.06, 0.03, 0.25))
		elif Save.prog.blood:
			draw_set_transform(Vector2(d.x, d.y), 0, Vector2(d.sx, 1))
			draw_circle(Vector2.ZERO, d.r, Color(0.6, 0.05, 0.1, 0.8))
			draw_set_transform(Vector2.ZERO)


func _draw_portal(e: Dictionary, t: float) -> void:
	var c: Array = [Color("#3ff0cf"), Color("#0a8f78"), Color("#063d34")] if e.pair % 2 else [Color("#5dff8a"), Color("#12a845"), Color("#073b1b")]
	var p := Vector2(e.x, e.y)
	draw_circle(p, 60, Color(c[0], 0.18))
	draw_set_transform(p, 0, Vector2(22.0 / 34.0, 1))
	draw_circle(Vector2.ZERO, 34, c[2])
	draw_circle(Vector2.ZERO, 24, c[1])
	draw_circle(Vector2.ZERO, 9, Color("#eafff0"))
	for k in 3:
		var a0 := t * (2.5 + k) + k * 2
		draw_arc(Vector2.ZERO, 25 - k * 6, a0, a0 + 3.6, 16, Color.WHITE if k == 1 else c[0], 1.5 if k == 1 else 3)
	draw_arc(Vector2.ZERO, 36, 0, TAU, 40, c[0], 5)
	draw_set_transform(Vector2.ZERO)
	for i in 6:
		var a := t * 1.8 + i * PI / 3
		draw_circle(p + Vector2(cos(a) * 28, sin(a) * 41), 2.2, Color("#eafff0"))


func _draw_block(b: GBody) -> void:
	var w: float = b.p.w
	var h: float = b.p.h
	var m: Dictionary = C.MAT[b.p.mat]
	draw_set_transform(b.global_position, b.rotation)
	var pts := rr(-w / 2, -h / 2, w, h, minf(4, minf(w / 4, h / 4)))
	draw_colored_polygon(pts, m.fill)
	draw_rect(Rect2(-w / 2, -h / 2, w, minf(4, h / 3)), Color(m.light, 0.65))
	match b.p.mat:
		"wood":
			var lc := Color(120 / 255.0, 65 / 255.0, 25 / 255.0, 0.35)
			if w >= h:
				for k in [0.38, 0.7]:
					draw_line(Vector2(-w / 2 + 3, -h / 2 + h * k), Vector2(w / 2 - 3, -h / 2 + h * k), lc, 1.2)
			else:
				for k in [0.35, 0.68]:
					draw_line(Vector2(-w / 2 + w * k, -h / 2 + 3), Vector2(-w / 2 + w * k, h / 2 - 3), lc, 1.2)
		"stone":
			var y := -h / 2 + 22
			while y < h / 2:
				draw_line(Vector2(-w / 2, y), Vector2(w / 2, y), Color(70 / 255.0, 78 / 255.0, 90 / 255.0, 0.35), 1.4)
				y += 22
		"ice":
			var s := minf(h, w) * 0.6
			draw_line(Vector2(-w / 2 + 4, -h / 2 + s), Vector2(-w / 2 + s, -h / 2 + 4), Color(1, 1, 1, 0.9), 2.5)
		"sand":
			for c in b.p.get("cr", []):
				draw_polyline(c, Color(95 / 255.0, 60 / 255.0, 20 / 255.0, 0.4), 1.3)
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, m.dark, 2, true)
	draw_set_transform(Vector2.ZERO)


func _draw_boulder(b: GBody) -> void:
	var r: float = b.p.r
	draw_set_transform(b.global_position, b.rotation)
	draw_circle(Vector2.ZERO, r, Color("#5a6082"))
	draw_circle(Vector2(-r * 0.12, -r * 0.14), r * 0.8, Color("#8f96b6"))
	draw_circle(Vector2(-r * 0.35, -r * 0.4), r * 0.25, Color("#dde1f3"))
	draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color("#474c69"), 2)
	draw_polyline(PackedVector2Array([Vector2(-r * 0.15, -r * 0.85), Vector2(0, -r * 0.45), Vector2(-r * 0.2, -r * 0.15), Vector2(r * 0.05, r * 0.1)]), Color(50 / 255.0, 55 / 255.0, 80 / 255.0, 0.55), 2)
	draw_set_transform(Vector2.ZERO)


func _draw_barrel(b: GBody) -> void:
	draw_set_transform(b.global_position, b.rotation)
	if b.p.triggered:
		draw_circle(Vector2.ZERO, 30, Color(1, 200 / 255.0, 60 / 255.0, 0.45))
	var pts := rr(-15, -21, 30, 42, 6)
	draw_colored_polygon(pts, Color("#e0452e"))
	draw_rect(Rect2(-15, -14, 30, 4), Color("#a52b18"))
	draw_rect(Rect2(-15, 10, 30, 4), Color("#a52b18"))
	draw_rect(Rect2(-11, -19, 5, 38), Color(1, 1, 1, 0.25))
	var star := PackedVector2Array()
	for i in 16:
		var a := i * PI / 8
		var r2 := 3.0 if i % 2 else 8.0
		star.append(Vector2(cos(a) * r2 + 3, sin(a) * r2 - 1))
	draw_colored_polygon(star, Color("#ffd23f"))
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, Color("#8e2414"), 2, true)
	draw_set_transform(Vector2.ZERO)


func _head(pos: Vector2, r: float, c1: Color, c2: Color) -> void:
	draw_circle(pos, r, c2)
	draw_circle(pos + Vector2(-r * 0.2, -r * 0.22), r * 0.6, c2.lerp(c1, 0.6))


func _draw_enemy(e: GBody) -> void:
	var pl := e.p
	var Lc := e.loc
	var T: Vector2 = Lc.torso
	var Hd: Vector2 = Lc.head
	var F: Vector2 = Lc.feet
	var col := game.char_colors(e)
	draw_set_transform(e.global_position, e.rotation)
	draw_line(T + Vector2(-6, 14), F + Vector2(-7, 0), col[1], 9)
	draw_line(T + Vector2(6, 14), F + Vector2(7, 0), col[1], 9)
	draw_colored_polygon(rr(T.x - 12, T.y - 20, 24, 40, 10), col[0])
	_head(Hd, 13, col[2], col[0])
	if pl.shooter:
		draw_circle(Hd + Vector2(0, -2), 14.5, Color("#3d4a2a"))
		draw_circle(Hd + Vector2(0, 3), 12.5, col[0])
		draw_rect(Rect2(Hd.x - 16, Hd.y - 3, 32, 4), Color("#3d4a2a"))
	else:
		# bazooka-less grunt: rifle held across the body
		draw_line(T + Vector2(9, -1), T + Vector2(-30, -9), Color("#2c2833"), 4)
		draw_line(T + Vector2(11, 0), T + Vector2(3, 1), Color("#2c2833"), 7)
		draw_line(T + Vector2(4, -12), T + Vector2(-12, -5), col[1], 7)
	draw_set_transform(Vector2.ZERO)
	if pl.shooter:
		var S := game.enemy_shoulder(e)
		var a: float = pl.aim_a
		var flip := -1.0 if absf(C.norm_a(a)) > PI / 2 else 1.0
		draw_set_transform(S, a, Vector2(1, flip))
		draw_line(Vector2(-8, 2), Vector2(32, 0), Color("#2c2833"), 4)
		draw_line(Vector2(-10, 3), Vector2(0, 4), Color("#2c2833"), 7)
		draw_line(Vector2(-4, -3), Vector2(12, 2), col[1], 7)
		if game.sim < pl.mflash:
			draw_colored_polygon(PackedVector2Array([Vector2(32, -6), Vector2(48, 0), Vector2(32, 6)]), Color("#ffe27a"))
		draw_set_transform(Vector2.ZERO)
	if pl.alert_at and game.sim - pl.alert_at < 70:
		var Hw := e.wpt(Hd + Vector2(0, -30))
		draw_colored_polygon(rr(Hw.x - 9, Hw.y - 14, 18, 24, 6), Color("#ff3b4e"))
		draw_string(font, Hw + Vector2(-9, 6), "!", HORIZONTAL_ALIGNMENT_CENTER, 18, 20, Color.WHITE)


func _draw_rag(b: GBody) -> void:
	var col: Array = b.p.col
	draw_set_transform(b.global_position, b.rotation)
	if b.p.shape == "head":
		_head(Vector2.ZERO, b.p.r, col[2], col[0])
	else:
		var w: float = b.p.w
		var h: float = b.p.h
		var th := minf(w, h)
		var c: Color = col[0] if b.p.shape == "torso" else col[1]
		if h >= w:
			draw_line(Vector2(0, -h / 2 + th / 2), Vector2(0, h / 2 - th / 2), c, th)
			draw_circle(Vector2(0, -h / 2 + th / 2), th / 2, c)
			draw_circle(Vector2(0, h / 2 - th / 2), th / 2, c)
		else:
			draw_line(Vector2(-w / 2 + th / 2, 0), Vector2(w / 2 - th / 2, 0), c, th)
		if Save.prog.blood and b.p.bleed > game.sim - 600:
			draw_circle(Vector2(0, -h / 2 + th / 2), th * 0.32, Color("#a3101f"))
	draw_set_transform(Vector2.ZERO)


func _draw_grenade(b: GBody) -> void:
	draw_set_transform(b.global_position, b.rotation)
	var left: int = b.p.fuse - game.sim
	if left < 50 and int(game.sim / 5.0) % 2:
		draw_circle(Vector2.ZERO, 15, Color(1, 70 / 255.0, 40 / 255.0, 0.45))
	draw_rect(Rect2(-3, -13, 6, 5), Color("#7a7f8c"))
	_head(Vector2.ZERO, 9, Color("#8fd16f"), Color("#3f7f2c"))
	var lc := Color("#2f6323")
	draw_line(Vector2(-8, -2), Vector2(8, -2), lc, 1.2)
	draw_line(Vector2(-8, 3), Vector2(8, 3), lc, 1.2)
	draw_line(Vector2(0, -9), Vector2(0, 9), lc, 1.2)
	draw_set_transform(Vector2.ZERO)


func _draw_rocket(b: GBody) -> void:
	var a: float = b.linear_velocity.angle()
	draw_set_transform(b.global_position, a)
	var fin := Color("#2f4d1d")
	draw_colored_polygon(PackedVector2Array([Vector2(-15, -5), Vector2(-20, -10), Vector2(-9, -5)]), fin)
	draw_colored_polygon(PackedVector2Array([Vector2(-15, 5), Vector2(-20, 10), Vector2(-9, 5)]), fin)
	draw_colored_polygon(rr(-15, -5, 30, 10, 4), Color("#5a8c40"))
	draw_colored_polygon(PackedVector2Array([Vector2(14, -5), Vector2(22, 0), Vector2(14, 5)]), Color("#e2402b"))
	draw_set_transform(Vector2.ZERO)


func _draw_bullet(b: GBody) -> void:
	var v: Vector2 = b.linear_velocity / C.STEP
	var p := b.global_position
	draw_line(p - v * 1.6, p, Color(1, 226 / 255.0, 122 / 255.0, 0.35), 7)
	draw_line(p - v * 1.1, p, Color("#fff3b0"), 3)


func _draw_player() -> void:
	var pl := game.player
	if not pl.p.alive or not game.in_world(pl):
		return
	var Lc := pl.loc
	var T: Vector2 = Lc.torso
	var Hd: Vector2 = Lc.head
	var F: Vector2 = Lc.feet
	var ang := atan2(game.aim.dy, game.aim.dx)
	var S := game.shoulder()
	var fl: bool = game.sim < pl.p.flash
	var B := Color.WHITE if fl else Color("#3b6cff")
	var BD := Color("#ffd0d0") if fl else Color("#2a4fd0")
	draw_set_transform(pl.global_position, 0)
	draw_line(T + Vector2(-6, 12), F + Vector2(-9, 2), BD, 10)
	draw_line(T + Vector2(6, 12), F + Vector2(9, 2), BD, 10)
	draw_colored_polygon(rr(T.x - 13, T.y - 16, 26, 32, 11), B)
	_head(Hd, 13, Color("#8fb0ff"), B)
	draw_set_transform(Vector2.ZERO)
	draw_set_transform(S, ang)
	var rc: float = -game.recoil * 7
	var tube := rr(-18 + rc, -7, 58, 14, 5)
	_fill_outline(tube, Color("#5a8c40"), Color("#2f4d1d"), 2)
	draw_rect(Rect2(36 + rc, -9, 7, 18), Color("#2f4d1d"))
	draw_rect(Rect2(-20 + rc, -8, 5, 16), Color("#2f4d1d"))
	draw_rect(Rect2(4 + rc, 6, 6, 8), Color("#2f4d1d"))
	draw_set_transform(Vector2.ZERO)
	var hnd := Vector2(10 + rc, 6).rotated(ang)
	var sh := pl.wpt(T + Vector2(3, -10))
	draw_line(sh, S + hnd, BD, 8)
	var hp: float = pl.p.hp / 100.0
	var hb := pl.wpt(Hd + Vector2(0, -24))
	draw_colored_polygon(rr(hb.x - 22, hb.y - 4, 44, 8, 4), Color(42 / 255.0, 33 / 255.0, 64 / 255.0, 0.55))
	if hp > 0:
		var hc := Color("#3fc46a") if hp > 0.5 else (Color("#ffb020") if hp > 0.25 else Color("#ff3b4e"))
		draw_colored_polygon(rr(hb.x - 21, hb.y - 3, maxf(6, 42 * hp), 6, 3), hc)


func _draw_particles() -> void:
	for p in game.particles:
		var k: float = p.life / p.max
		var pos := Vector2(p.x, p.y)
		match p.t:
			"flash": draw_circle(pos, p.r * (0.6 + k * 0.6), Color(1, 246 / 255.0, 200 / 255.0, 1 - k))
			"ring": draw_arc(pos, maxf(0.5, p.r * k), 0, TAU, 32, Color(p.get("c", Color.WHITE), (1 - k) * 0.8), 7 * (1 - k) + 1)
			"fire":
				var c := Color("#fff2a0") if k < 0.3 else (Color("#ffab3b") if k < 0.6 else Color("#e2552a"))
				draw_circle(pos, p.r * (1 + k * 0.8), Color(c, 1 - k))
			"smoke": draw_circle(pos, p.r * (1 + k * 1.5), Color(Color("#6d655a") if k < 0.15 else Color("#a49d90"), (1 - k) * 0.55))
			"puff": draw_circle(pos, p.r * (1 + k), Color(1, 1, 1, 1 - k))
			"chunk", "splinter":
				draw_set_transform(pos, p.get("a", 0.0))
				var cc: Color = p.c
				cc.a *= 1 - k * k
				if p.t == "splinter":
					draw_rect(Rect2(-p.s / 2, -1.5, p.s, 3), cc)
				else:
					draw_rect(Rect2(-p.s / 2, -p.s / 2, p.s, p.s), cc)
				draw_set_transform(Vector2.ZERO)
			"spark": draw_line(pos, pos - Vector2(p.vx, p.vy) * 0.03, Color(Color("#fff5c0") if k < 0.5 else Color("#ffae3b"), 1 - k), 2.5)
			"ember": draw_circle(pos, p.r, Color(Color("#ff9a2e"), (1 - k) * (0.6 + 0.4 * sin(p.life * 30))))
			"blood": draw_circle(pos, p.r, Color("#b3121f"))
			"mist": draw_circle(pos, p.r * (1 + k), Color(Color("#c4202f"), (1 - k) * 0.45))
			"glow": draw_circle(pos, p.r, Color(p.c, 1 - k))
			"text":
				var a := 1.0 if k < 0.7 else (1 - k) / 0.3
				draw_string_outline(font, pos + Vector2(-60, 0), p.text, HORIZONTAL_ALIGNMENT_CENTER, 120, 34, 6, Color(Color("#2a2140"), a))
				draw_string(font, pos + Vector2(-60, 0), p.text, HORIZONTAL_ALIGNMENT_CENTER, 120, 34, Color(p.c, a))
