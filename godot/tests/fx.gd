extends Node
## Blood toggle through the actual title UI and real damage/death, cosmetic integration and budgets.
var g: Game
var fails := []

func check(ok: bool, what: String) -> void:
	if not ok:
		fails.append(what)

func counts() -> Dictionary:
	var out := {}
	for p in g.particles:
		out[p.t] = out.get(p.t, 0) + 1
	return out

func _ready() -> void:
	var main = await TestUtil.boot(self)
	g = Debug.game
	var original: bool = Save.prog.blood
	Save.prog.blood = true
	main.hud.show_title()
	var toggle: Button
	for child in main.hud.card_box.find_children("*", "Button", true, false):
		if child is Button and child.text.begins_with("Blood:"):
			toggle = child
	check(toggle != null, "title has a blood toggle")
	if toggle:
		toggle.pressed.emit()
		check(not Save.prog.blood and toggle.text == "Blood: off", "title toggle disables blood and updates its label")
		toggle.pressed.emit()
		check(Save.prog.blood and toggle.text == "Blood: on", "title toggle enables blood and updates its label")

	for enabled in [true, false]:
		await Debug.start_level(0)
		main.hud.hide_overlay()
		Save.prog.blood = enabled
		g.particles.clear()
		g.damage_player(30, Vector2.RIGHT, null, "bullet")
		var c := counts()
		check(g.player.p.hp == 70, "toggle leaves damage unchanged")
		check(c.get("text", 0) == 1, "damage text is retained")
		check(c.get("blood", 0) == (16 if enabled else 0), "damage blood count: %s" % c)
		check(c.get("mist", 0) == (4 if enabled else 0), "damage mist count: %s" % c)
		check(c.get("chunk", 0) == (0 if enabled else 16), "blood-off has coloured debris: %s" % c)
		if not enabled:
			for p in g.particles:
				if p.t == "chunk":
					check(p.c == g.char_colors(g.player)[0] and p.max == 0.8 and p.g == 1300, "fallback colour/lifetime/gravity")
		g.particles.clear()
		g.kill_player(Vector2.RIGHT * 5, true)
		c = counts()
		check(g.rags.size() == 6, "death still produces six physical ragdoll parts")
		check(c.get("blood", 0) == (55 if enabled else 0), "gib blood count")
		check(c.get("chunk", 0) == (0 if enabled else 55), "gib fallback count")
		check(g.particles[-1].c == (Color("#c21a2a") if enabled else Color.WHITE), "gib ring honours blood preference")
		g.particles.clear()
		g.sim = (g.sim / 3 as int) * 3
		for rag in g.rags:
			rag.linear_velocity = Vector2(60, 0)
		g._update_rag_bleeding()
		check(g.particles.size() == 6 and counts().get("blood" if enabled else "chunk", 0) == 6, "moving ragdolls bleed every third tick")
		g.particles.clear()
		g.sim += 1
		g._update_rag_bleeding()
		check(g.particles.is_empty(), "rag bleeding skips other ticks")
		g.sim += 120
		g.sim -= g.sim % 3
		g._update_rag_bleeding()
		check(g.particles.is_empty(), "expired rag bleeding stops")

	await Debug.start_level(0)
	main.hud.hide_overlay()
	g.set_process(false) # advance particle time explicitly for deterministic integration checks
	Save.prog.blood = true
	g.particles.clear()
	g.decals.clear()
	var ground = g.statics[0]
	var contact: Vector2 = Vector2.ZERO
	for point in ground.poly:
		contact += point
	contact /= ground.poly.size()
	g.blood(contact.x, contact.y, 100, 20, 3, [])
	g._update_particles(0.001)
	check(g.particles.is_empty() and g.decals.size() == 1, "blood hitting static becomes a decal")
	if not g.decals.is_empty():
		var d = g.decals[0]
		check(d.t == "blood" and d.r >= 3.9 and d.r <= 7.8 and d.dots.size() == 2, "decal size and satellite drops")
		check(is_equal_approx(d.a, atan2(21.4, 100) * 0.15), "decal aligns to impact velocity")
	var edge: Vector2 = (ground.poly[0] + ground.poly[1]) / 2
	var clipped: Array = main.view.decal_polygons(edge, Vector2(20, 10), 0.2)
	check(not clipped.is_empty(), "decal crossing platform edge is clipped")
	for polygon in clipped:
		for point in polygon:
			check(Geometry2D.is_point_in_polygon(point, ground.poly), "clipped decal stays on ground")
	check(main.view.decal_polygons(Vector2(-10000, -10000), Vector2.ONE * 10, 0).is_empty(), "decal outside statics is invisible")
	Save.prog.blood = false
	g.blood(contact.x, contact.y, 100, 20, 3, [])
	g._update_particles(0.001)
	check(g.decals.size() == 1 and counts().get("chunk", 0) == 1, "blood-off debris never stains")

	g.particles.clear()
	g.decals.clear()
	g.fx_explosion(contact - Vector2(0, 14), 100, 40)
	check(counts() == {"flash": 1, "ring": 1, "fire": 16, "smoke": 16, "spark": 14, "chunk": 12, "ember": 5}, "explosion particle recipe remains enabled with blood off")
	check(g.decals.size() == 1 and g.decals[0].t == "scorch", "blood-off keeps scorch decals")
	g._update_particles(3.0)
	check(g.particles.is_empty(), "all explosion FX expire")
	g.particles.append({"t": "chunk", "x": 0.0, "y": 0.0, "vx": 10.0, "vy": 20.0, "g": 100.0, "drag": 2.0, "spin": 4.0, "life": 0.0, "max": 2.0})
	g._update_particles(0.1)
	var p = g.particles[0]
	check(is_equal_approx(p.x, 1) and is_equal_approx(p.y, 2) and is_equal_approx(p.vx, 8) and is_equal_approx(p.vy, 24) and is_equal_approx(p.a, 0.4), "particle position/gravity/drag/spin integration")
	g.particles.clear()
	for i in 950:
		g.particles.append({"t": "puff", "x": float(i), "y": 0.0, "vx": 0.0, "vy": 0.0, "life": 0.0, "max": 2.0})
	g._update_particles(0)
	check(g.particles.size() == 900 and g.particles[0].x == 50, "particle budget keeps newest 900")
	g.decals.clear()
	for i in 300:
		g.add_decal({"t": "scorch", "x": i})
	check(g.decals.size() == 260 and g.decals[0].x == 40, "decal budget keeps newest 260")
	# The renderer must preserve the actual width below the former six-pixel minimum.
	var points := View.hp_fill_polygon(Vector2.ZERO, 0.01)
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	check(is_equal_approx(bounds.size.x, 0.42), "1 HP overhead fill is 0.42px")
	g.set_process(true)
	await Debug.start_level(0)
	check(g.particles.is_empty() and g.decals.is_empty(), "new level clears FX and decals")
	check(g.player.lock_rotation, "player rotation remains locked")
	Save.prog.blood = original
	for failure in fails:
		print("  FAIL ", failure)
	print("FX RESULT: ", "PASS" if fails.is_empty() else "FAIL")
	await TestUtil.finish(self, 0 if fails.is_empty() else 1)
