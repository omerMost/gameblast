class_name View
extends Node2D
## World renderer (prototype DRAWING section). Draws in world coordinates under the Camera2D.
## Render only: never changes physics.

var game: Game
var font: Font
var draw_cpu_ms := 0.0
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


static func hp_fill_polygon(hb: Vector2, hp: float) -> PackedVector2Array:
	return rr(hb.x - 21, hb.y - 3, 42 * hp, 6, 3)


func _fill_outline(pts: PackedVector2Array, fill: Color, line: Color, lw: float) -> void:
	draw_colored_polygon(pts, fill)
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, line, lw, true)


func _draw() -> void:
	if game == null or game.player == null:
		return
	var draw_start := Time.get_ticks_usec()
	var t := Time.get_ticks_msec() / 1000.0
	for e in game.portals:
		_draw_portal(e, t)
	for s in game.statics:
		_draw_static(s)
	game.tricks.draw(self)
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
			"grenade", "nade": _draw_grenade(b)
			"rocket": _draw_rocket(b)
			"bullet": _draw_bullet(b)
			"flame": _draw_flame(b)
			"arrow": _draw_arrow(b.global_position, b.linear_velocity.angle(), 22)
	for entry in game.enemy_ai.stuck:
		var pose: Dictionary = game.enemy_ai.stuck_pose(entry)
		if not pose.is_empty():
			_draw_arrow(pose.pos, pose.a, 28)
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

	draw_cpu_ms = (Time.get_ticks_usec() - draw_start) / 1000.0


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


## Canvas clips decals to non-pad statics. Intersect each ellipse in world space
## so blood and scorch never float beyond platform edges.
func decal_polygons(center: Vector2, radius: Vector2, angle: float) -> Array:
	var ellipse := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32
		ellipse.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y).rotated(angle))
	var clipped := []
	for body in game.statics:
		if body.kind != "pad":
			clipped.append_array(Geometry2D.intersect_polygons(ellipse, body.poly))
	return clipped


func valid_decal_polygons(center: Vector2, radius: Vector2, angle: float) -> Array:
	# Validate once with clipping; neither the stain nor its platform moves.
	return decal_polygons(center, radius, angle).filter(func(polygon):
		return not Geometry2D.triangulate_polygon(polygon).is_empty())


func decal_mesh(center: Vector2, radius: Vector2, angle: float) -> ArrayMesh:
	var vertices := PackedVector2Array()
	var indices := PackedInt32Array()
	for polygon in decal_polygons(center, radius, angle):
		var triangles := Geometry2D.triangulate_polygon(polygon)
		if triangles.is_empty():
			continue
		var offset := vertices.size()
		vertices.append_array(polygon)
		for index in triangles:
			indices.append(index + offset)
	var mesh := ArrayMesh.new()
	if not indices.is_empty():
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_INDEX] = indices
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, Mesh.ARRAY_FLAG_USE_2D_VERTICES)
	return mesh


func _draw_decal_ellipse(center: Vector2, radius: Vector2, angle: float, color: Color, cache: Dictionary, key: String) -> void:
	# Decals and static platforms do not move within a level. Clip once, then reuse
	# the polygons; repeated geometry intersections made headless bot searches slow.
	if not cache.has(key):
		cache[key] = decal_mesh(center, radius, angle)
	var mesh: ArrayMesh = cache[key]
	if mesh.get_surface_count() > 0:
		draw_mesh(mesh, null, Transform2D.IDENTITY, color)


func _draw_decals() -> void:
	for d in game.decals:
		var center := Vector2(d.x, d.y)
		if d.t == "scorch":
			_draw_decal_ellipse(center, Vector2.ONE * d.r, 0, Color(0.16, 0.1, 0.05, 0.28), d, "clip_outer")
			_draw_decal_ellipse(center, Vector2.ONE * d.r * 0.55, 0, Color(0.1, 0.06, 0.03, 0.25), d, "clip_inner")
		elif Save.prog.blood:
			var color := Color(150 / 255.0, 10 / 255.0, 24 / 255.0, 0.88)
			_draw_decal_ellipse(center, Vector2(d.r * d.sx, d.r * 0.75), d.get("a", 0.0), color, d, "clip_blood")
			var dot_index := 0
			for dot in d.get("dots", []):
				_draw_decal_ellipse(center + Vector2(dot[0], dot[1]), Vector2.ONE * dot[2], 0, color, d, "clip_dot%d" % dot_index)
				dot_index += 1


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
	if b.p.get("look", "") == "shield":
		draw_colored_polygon(rr(-4,-23,8,46,3),Color("#8a5a2b"))
		draw_rect(Rect2(-4,-23,8,46),Color("#c9ced8"),false,2)
		draw_circle(Vector2.ZERO,3.5,Color("#c9ced8"))
		draw_set_transform(Vector2.ZERO)
		return
	if b.p.get("look", "") == "sword":
		draw_rect(Rect2(-2,-18,4,36),Color("#dfe4ec"))
		draw_line(Vector2(-6,10),Vector2(6,10),Color("#c9a227"),3)
		draw_set_transform(Vector2.ZERO)
		return
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
	if e.p.titan or e.p.dragon:
		_draw_boss(e)
		return
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
	elif pl.get("jet",false):
		draw_rect(Rect2(Lc.extra-Vector2(6,12),Vector2(12,24)),Color("#687787"))
		draw_rect(Rect2(Lc.extra+Vector2(-5,11),Vector2(10,5)),Color("#3d4250"))
		draw_rect(Rect2(Lc.extra+Vector2(-7,-6),Vector2(14,4)),Color("#e0452e"))
		draw_arc(Hd+Vector2(0,-2),14.5,PI,TAU,16,Color("#3d4a2a"),7)
		draw_rect(Rect2(Hd+Vector2(-14,-3),Vector2(12,5)),Color("#9fe3ff"))
	elif pl.get("knight", false):
		draw_colored_polygon(rr(T.x-12,T.y-20,24,40,10), Color("#b9c0cc"))
		draw_rect(Rect2(Lc.extra-Vector2(4,23),Vector2(8,46)),Color("#8a93a3"))
		draw_circle(Hd,14,Color("#8a93a3"))
		var swing: float = (game.sim-pl.get("swing",-100))/14.0 if game.sim-pl.get("swing",-100)<14 else -1.0
		var angle := -2.3 if swing < 0 else -2.3 + sin(swing * PI) * -1.9 + swing * 0.2
		var hand := T + Vector2(6,-10)
		draw_line(hand,hand+Vector2(0,14).rotated(angle),col[1],7)
		draw_line(hand+Vector2(0,16).rotated(angle),hand+Vector2(0,50).rotated(angle),Color("#dfe4ec"),4)
	elif pl.archer:
		draw_rect(Rect2(T.x + 6, T.y - 18, 8, 26), Color("#7a5530"))
	else:
		# bazooka-less grunt: rifle held across the body
		draw_line(T + Vector2(9, -1), T + Vector2(-30, -9), Color("#2c2833"), 4)
		draw_line(T + Vector2(11, 0), T + Vector2(3, 1), Color("#2c2833"), 7)
		draw_line(T + Vector2(4, -12), T + Vector2(-12, -5), col[1], 7)
	draw_set_transform(Vector2.ZERO)
	if pl.shooter or pl.archer or pl.get("jet",false):
		var S := game.enemy_shoulder(e)
		var a: float = pl.aim_a
		var flip := -1.0 if absf(C.norm_a(a)) > PI / 2 else 1.0
		draw_set_transform(S, a, Vector2(1, flip))
		if pl.archer:
			var pull: float = (game.sim - pl.draw) / 18.0 * 10 if pl.draw and game.sim - pl.draw < 18 else 0.0
			draw_arc(Vector2(8, 0), 22, -1.2, 1.2, 20, Color("#6b4b2a"), 3.5, true)
			draw_polyline(PackedVector2Array([Vector2(8 + 22 * cos(-1.2), 22 * sin(-1.2)), Vector2(8 - pull, 0), Vector2(8 + 22 * cos(1.2), 22 * sin(1.2))]), Color("#eeeeee"), 1)
			if pull:
				draw_line(Vector2(8 - pull, 0), Vector2(36 - pull, 0), Color("#7a5530"), 2)
			draw_line(Vector2(-4, 0), Vector2(16, 0), col[1], 7)
		elif pl.get("jet",false):
			draw_line(Vector2(-4,0),Vector2(16,0),col[1],7)
			if pl.lob: draw_circle(Vector2(20,0),6,Color("#4f9a3a"))
		else:
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


func _draw_arrow(pos: Vector2, angle: float, length: float) -> void:
	draw_set_transform(pos, angle)
	draw_line(Vector2(-length, 0), Vector2.ZERO, Color("#7a5530"), 2)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -3), Vector2(7, 0), Vector2(0, 3)]), Color("#9aa3b5"))
	draw_colored_polygon(PackedVector2Array([Vector2(-length, 0), Vector2(-length - 5, -4), Vector2(-length + 5, 0), Vector2(-length - 5, 4)]), Color("#e8e2d4"))
	draw_set_transform(Vector2.ZERO)


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
	var enemy := b.kind == "nade"
	if enemy:
		var ring := game.enemy_ai.telegraph(b)
		for d in range(0,360,12):
			draw_arc(ring.center,ring.radius,deg_to_rad(d),deg_to_rad(d+6),3,Color(1,0.235,0.235,ring.alpha),3)
	draw_set_transform(b.global_position, b.rotation)
	var left: int = b.p.fuse - game.sim
	if left < 50 and int(game.sim / 5.0) % 2:
		draw_circle(Vector2.ZERO, 15, Color(1, 70 / 255.0, 40 / 255.0, 0.45))
	draw_rect(Rect2(-3, -13, 6, 5), Color("#7a7f8c"))
	_head(Vector2.ZERO, 9, Color("#9aa0aa") if enemy else Color("#8fd16f"), Color("#4a4f5a") if enemy else Color("#3f7f2c"))
	var lc := Color("#2e323a") if enemy else Color("#2f6323")
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
		draw_colored_polygon(hp_fill_polygon(hb, hp), hc)


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


func _draw_boss(e: GBody) -> void:
	var pl := e.p
	var col := game.char_colors(e)
	var h: Vector2 = e.loc.head
	var b: Vector2 = e.loc.torso
	var t := float(game.sim)
	draw_set_transform(e.global_position,e.rotation)
	if pl.titan:
		var f: Vector2 = e.loc.feet
		var c: Vector2 = e.loc.core
		var run := sin(e.position.x*0.07)*14 if absf(e.linear_velocity.x/C.STEP)>0.4 else 0.0
		draw_line(b+Vector2(-14,30),f+Vector2(-16+run,-8),col[1],20,true)
		draw_line(b+Vector2(14,30),f+Vector2(16-run,-8),col[1],20,true)
		draw_rect(Rect2(f+Vector2(-34+run,-10),Vector2(30,14)),Color("#3d3a4f"))
		draw_rect(Rect2(f+Vector2(4-run,-10),Vector2(30,14)),Color("#3d3a4f"))
		draw_line(b+Vector2(26,-26),b+Vector2(34,20),col[1],18,true)
		draw_rect(Rect2(b-Vector2(33,37),Vector2(66,74)),col[0])
		draw_rect(Rect2(b+Vector2(-30,-34),Vector2(60,16)),col[1])
		draw_rect(Rect2(b+Vector2(-28,20),Vector2(56,12)),col[1])
		draw_circle(c,30,Color(1,0.55,0.15,(0.6+0.4*sin(t*0.2))*0.25))
		draw_circle(c,15,Color("#5a3a10")); draw_circle(c,13,Color("#ffb347")); draw_circle(c,6,Color("#fff3c4"))
		draw_circle(h,19,col[2])
		draw_rect(Rect2(h+Vector2(-20,-6),Vector2(22,9)),Color("#3d3a4f"))
		for x in [-13,-5]: draw_circle(h+Vector2(x,-2),2.5,Color("#ff4040"))
		var sw: float = (game.sim-pl.get("swing",-999))/22.0
		var raise := sin(minf(1,sw*1.3)*PI) if sw>=0 and sw<1 else 0.0
		var start := b+Vector2(-22,-26)
		var arm := Vector2(0,54).rotated(0.25-raise*2.6)
		draw_line(start,start+arm,col[0],18,true); draw_circle(start+arm,13,Color("#3d3a4f"))
	else:
		var mouth: Vector2 = e.loc.mouth
		var tail: Vector2 = e.loc.tail
		var open := minf(1,(game.sim-pl.bt)/20.0) if pl.breath=="charge" else (1.0 if pl.breath=="fire" else 0.0)
		var flap := sin(t*0.18+pl.ph)
		for dx in [18,-2]:
			# Canvas tolerates crossing wing vertices at low flap; Godot needs triangles.
			var wing := [b+Vector2(dx-20,-12),b+Vector2(dx+5,-60-flap*38),b+Vector2(dx+55,-48-flap*44),b+Vector2(dx+40,-14)]
			var color := Color("#24652e") if dx==18 else Color("#3b9147")
			for tri in [[0,1,2],[0,2,3]]:
				draw_colored_polygon(PackedVector2Array([wing[tri[0]],wing[tri[1]],wing[tri[2]]]),color)
		draw_line(b+Vector2(35,0),tail+Vector2(38,-10),col[1],14,true)
		draw_colored_polygon(PackedVector2Array([tail+Vector2(34,-16),tail+Vector2(52,-16),tail+Vector2(40,-2)]),col[1])
		draw_set_transform(e.global_position,e.rotation,Vector2(1,0.44))
		draw_circle(Vector2(b.x,b.y/0.44),50,Color("#ff7a5a") if pl.breath=="gulp" and game.sim%8<4 else col[0])
		draw_set_transform(e.global_position,e.rotation)
		draw_line(b+Vector2(-30,-8),h+Vector2(8,4),col[0],16,true)
		draw_circle(h,18,col[0])
		if open>0: draw_circle(mouth,34,Color(1,0.5,0.1,open*0.3))
		draw_colored_polygon(PackedVector2Array([h+Vector2(-6,-10),h+Vector2(-34,-4-open*6),h+Vector2(-33,3-open*4),h+Vector2(-6,4)]),col[0])
		var jaw := h+Vector2(2,5)
		draw_line(jaw,jaw+Vector2(-32,5).rotated(open*0.55),col[1],9,true)
		for i in 3: draw_circle(jaw+Vector2(-26+i*8,0).rotated(open*0.55),2,Color.WHITE)
		if open>0: draw_circle(mouth+Vector2(4,0),6*open,Color("#3a0a0a"))
		draw_circle(h+Vector2(-4,-5),4,Color("#ffd23f")); draw_line(h+Vector2(-4,-8),h+Vector2(-4,-2),Color.BLACK,2)
		draw_colored_polygon(PackedVector2Array([h+Vector2(6,-12),h+Vector2(20,-24),h+Vector2(12,-9)]),Color("#e8e2d4"))
	draw_set_transform(Vector2.ZERO)
func _draw_flame(fl: GBody) -> void:
	var age: float = (game.sim-fl.p.born)/75.0
	var r := 7+age*14
	var alpha := maxf(0,1-age*0.9)
	draw_circle(fl.global_position,r*1.3,Color(0.89,0.33,0.16,alpha*0.55))
	draw_circle(fl.global_position,r,Color(1,0.67,0.23,alpha))
	draw_circle(fl.global_position-Vector2.ONE,r*0.5,Color(1,0.95,0.63,alpha))
