class_name LevelBuilder
extends RefCounted
## Replays a level's builder ops (prototype makeBuilder()) with the same coordinates,
## and owns the body factories (addBlock, makeChar). The only place that creates level bodies.

var game: Node
var rng: RandomNumberGenerator


func _init(g: Node) -> void:
	game = g
	rng = g.rng


func run(ops: Array) -> void:
	var refs := {}
	for op in ops:
		var a: Array = op
		match a[0]:
			"ground": ground(a[1], a[2], a[3])
			"plat": plat(a[1], a[2], a[3], a[4] if a.size() > 4 else 34.0)
			"wall": wall(a[1], a[2], a[3], a[4])
			"pad": pad(a[1], a[2], a[3], a[4])
			"slope": slope(a[1], a[2], a[3], a[4], a[5] if a.size() > 5 else 40.0)
			"block":
				var b := block(a[1], a[2], a[3], a[4], a[5])
				if a.size() > 6:
					refs[a[6]] = b
			"enemy": enemy(a[1], a[2], a[3] if a.size() > 3 else {})
			"boulder":
				var b := boulder(a[1], a[2], a[3])
				if a.size() > 4:
					refs[a[4]] = b
			"hang", "tether": game.tricks.rope(null, Vector2(a[1][0], a[1][1]), refs[a[2]], Vector2(a[3][0], a[3][1]), 0.95 if a[0] == "hang" else 0.6, 0.05 if a[0] == "hang" else 0.1)
			"balloon": game.tricks.balloon(a[1], a[2], refs[a[3]], Vector2(a[4][0], a[4][1]), a[5])
			"bridge": game.tricks.bridge(a[1], a[2], a[3], a[4], a[5])
			"barrel": barrel(a[1], a[2])
			_: push_error("LevelBuilder: op '%s' is not ported yet (stage 2)" % a[0])


# ---------------- statics ----------------

func cracks(x0: float, y0: float, w: float, h: float, n: int, clip: Rect2) -> Array:
	var out := []
	for i in n:
		var x := x0 + rng.randf() * w
		var y := y0 + rng.randf() * h
		var ang := rng.randf() * TAU
		var pts := PackedVector2Array([Vector2(x, y)])
		var k := 3 + rng.randi_range(0, 2)
		for j in k:
			ang += rng.randf_range(-1.1, 1.1)
			var l := rng.randf_range(7, 20)
			x += cos(ang) * l
			y += sin(ang) * l
			pts.append(Vector2(clampf(x, clip.position.x + 2, clip.end.x - 2), clampf(y, clip.position.y + 3, clip.end.y - 2)))
		out.append(pts)
	return out


func _static(center: Vector2, size: Vector2, kind: String, friction := 0.9, bounce := 0.0, angle := 0.0) -> GStatic:
	var s := GStatic.new()
	s.kind = kind
	s.size = size
	s.position = center
	s.rotation = angle
	s.collision_layer = C.L_STATIC
	s.collision_mask = 0
	var m := PhysicsMaterial.new()
	m.friction = friction
	m.bounce = bounce
	s.physics_material_override = m
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = size
	cs.shape = sh
	s.add_child(cs)
	var h := size * 0.5
	for c in [Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)]:
		s.poly.append(center + c.rotated(angle))
	game.add_static(s)
	return s


func ground(x1: float, x2: float, top: float) -> void:
	var s := _static(Vector2((x1 + x2) / 2, top + 1000), Vector2(x2 - x1, 2000), "ground")
	s.cracks = cracks(x1, top + 8, x2 - x1, 360, roundi((x2 - x1) * 360 / 5000), Rect2(x1, top, x2 - x1, 2000))


func plat(x1: float, x2: float, top: float, th := 34.0) -> void:
	var s := _static(Vector2((x1 + x2) / 2, top + th / 2), Vector2(x2 - x1, th), "plat")
	s.cracks = cracks(x1, top + 4, x2 - x1, th - 6, roundi((x2 - x1) / 25), Rect2(x1, top, x2 - x1, th))


func wall(x1: float, y1: float, x2: float, y2: float) -> void:
	var s := _static(Vector2((x1 + x2) / 2, (y1 + y2) / 2), Vector2(x2 - x1, y2 - y1), "plat")
	s.cracks = cracks(x1, y1 + 4, x2 - x1, y2 - y1 - 4, roundi((x2 - x1) * (y2 - y1) / 1500), Rect2(x1, y1, x2 - x1, y2 - y1))


func pad(x1: float, y1: float, x2: float, y2: float) -> void:
	_static(Vector2((x1 + x2) / 2, (y1 + y2) / 2), Vector2(x2 - x1, y2 - y1), "pad", 0.2, 1.0)


func slope(x1: float, y1: float, x2: float, y2: float, th := 40.0) -> void:
	var d := Vector2(x2 - x1, y2 - y1)
	var l := d.length()
	var n := Vector2(-d.y / l, d.x / l)
	_static(Vector2((x1 + x2) / 2, (y1 + y2) / 2) + n * th / 2, Vector2(l, th), "plat", 0.9, 0.0, atan2(d.y, d.x))


# ---------------- dynamic bodies ----------------

func _body(kind: String, pos: Vector2) -> GBody:
	var b := GBody.new()
	b.kind = kind
	b.game = game
	b.position = pos
	b.collision_layer = C.L_BODY
	b.collision_mask = C.M_BODY
	b.center_of_mass_mode = RigidBody2D.CENTER_OF_MASS_MODE_CUSTOM
	b.center_of_mass = Vector2.ZERO
	b.set_air(0.01)
	b.watch_contacts()
	return b


## prototype addBlock(): a material block centred at (x, y).
func add_block(x: float, y: float, w: float, h: float, mat: String, angle := 0.0) -> GBody:
	var m: Dictionary = C.MAT[mat]
	var b := _body("block", Vector2(x, y))
	b.rotation = angle
	b.add_rect(Vector2.ZERO, Vector2(w, h))
	b.mass = w * h * m.density
	b.matter_inertia([b.mass])
	b.set_phys(m.friction, m.rest)
	b.collision_layer = C.L_BODY | C.L_SOLID | (C.L_BLOCKER if mat == "stone" else 0)
	b.p = {"mat": mat, "w": w, "h": h, "hp": m.hp}
	if mat == "sand":
		b.p.cr = cracks(-w / 2, -h / 2, w, h, maxi(1, roundi(w * h / 900)), Rect2(-w / 2, -h / 2, w, h))
	game.add_body(b)
	return b


func block(cx: float, bottom: float, w: float, h: float, mat: String) -> GBody:
	return add_block(cx, bottom - h / 2, w, h, mat)


func boulder(cx: float, bottom: float, r: float) -> GBody:
	var b := _body("boulder", Vector2(cx, bottom - r))
	b.add_circle(Vector2.ZERO, r)
	b.mass = PI * r * r * 0.0022
	b.matter_inertia([b.mass])
	b.set_phys(0.9, 0.05)
	b.set_air(0.001)
	b.collision_layer = C.L_BODY | C.L_SOLID
	b.p = {"r": r}
	game.add_body(b)
	return b


func barrel(cx: float, bottom: float) -> GBody:
	var b := _body("barrel", Vector2(cx, bottom - 21))
	b.add_rect(Vector2.ZERO, Vector2(30, 42))
	b.mass = 30 * 42 * 0.0012
	b.matter_inertia([b.mass])
	b.set_phys(0.6, 0.0)
	b.collision_layer = C.L_BODY | C.L_SOLID
	b.p = {"triggered": false}
	b.watch_contacts()
	game.add_body(b)
	return b


## prototype makeChar(): one rigid body with feet / (hips) / torso / head parts.
## The node origin is the Matter centre of mass, so loc offsets match the prototype.
func make_char(x: float, bot: float, type: String) -> GBody:
	var defs := []   # [t, world_pos, size_or_r, density]
	defs.append(["rect", Vector2(x, bot - 4), Vector2(30, 8), 0.004, "feet"])
	if type == "player":
		defs.append(["rect", Vector2(x, bot - 17), Vector2(20, 18), 0.001, "hips"])
		defs.append(["rect", Vector2(x, bot - 42), Vector2(26, 32), 0.001, "torso"])
		defs.append(["circle", Vector2(x, bot - 70), 13.0, 0.001, "head"])
	else:
		defs.append(["rect", Vector2(x, bot - 28), Vector2(24, 40), 0.001, "torso"])
		defs.append(["circle", Vector2(x, bot - 61), 13.0, 0.001, "head"])
	if type == "knight":
		defs.append(["rect", Vector2(x - 20, bot - 34), Vector2(8, 46), 0.002, "extra"])
	if type == "jet":
		defs.append(["rect", Vector2(x+17,bot-32), Vector2(12,24),0.002,"extra"])
	var mass := 0.0
	var com := Vector2.ZERO
	for d in defs:
		var m: float = (d[2].x * d[2].y if d[0] == "rect" else PI * d[2] * d[2]) * d[3]
		d.append(m)
		mass += m
		com += d[1] * m
	com /= mass
	var b := _body("player" if type == "player" else "enemy", com)
	b.loc = {}
	for d in defs:
		var lp: Vector2 = d[1] - com
		if d[0] == "rect":
			b.add_rect(lp, d[2])
		else:
			b.add_circle(lp, d[2])
		b.loc[d[4]] = lp
	b.loc["ref"] = Vector2(x, bot - 28) - com
	b.mass = mass
	var pm := []
	for d in defs:
		pm.append(d[5])
	b.matter_inertia(pm)
	b.set_phys(0.9, 0.0)
	b.can_sleep = false
	b.p = {"alive": true}
	b.watch_contacts()
	return b


func enemy(x: float, bottom: float, o: Dictionary) -> GBody:
	var e := make_boss(x, bottom, o.get("titan", false)) if o.get("titan", false) or o.get("dragon", false) else make_char(x, bottom, "knight" if o.get("knight", false) else ("jet" if o.get("jet",false) else "enemy"))
	e.collision_layer = C.L_ENEMY
	e.collision_mask = C.M_ENEMY
	e.p.merge({"titan": o.get("titan", false), "dragon": o.get("dragon", false), "shooter": o.get("shooter", false), "archer": o.get("archer", false), "lob": 0.0, "draw": 0, "aim_a": PI, "next": 0, "alert_at": 0, "mflash": 0, "dying": false})
	e.p.knight = o.get("knight", false)
	if e.p.knight:
		e.inertia *= 4
	e.p.jet = o.get("jet",false)
	if e.p.jet:
		e.p.merge({"hx":e.global_position.x,"hy":e.global_position.y,"ph":game.rnd(0,6)})
	if e.p.dragon:
		e.p.merge({"hx": e.position.x, "hy": e.position.y, "ph": rng.randf() * 6, "breath": "idle", "bt": 0, "mouth_open": false})
	game.add_body(e)
	game.enemies.append(e)
	return e


## Exact prototype compound shapes; centre and inertia are mass weighted.
func make_boss(x: float, y: float, titan: bool) -> GBody:
	var defs := [
		["rect", Vector2(x,y-6), Vector2(64,12), 0.006,"feet"],
		["rect", Vector2(x,y-40), Vector2(40,56), 0.002,"legs"],
		["rect", Vector2(x,y-104), Vector2(66,74), 0.002,"torso"],
		["circle", Vector2(x,y-158), 19.0, 0.0015,"head"],
		["circle", Vector2(x-30,y-100), 13.0, 0.002,"core"]] if titan else [
		["rect",Vector2(x,y),Vector2(92,38),0.0012,"body"],
		["circle",Vector2(x-74,y-30),18.0,0.0012,"head"],
		["rect",Vector2(x+70,y+6),Vector2(52,12),0.0008,"tail"]]
	var mass := 0.0
	var com := Vector2.ZERO
	var masses := []
	for d in defs:
		var m: float = (d[2].x*d[2].y if d[0] == "rect" else PI*d[2]*d[2])*d[3]
		mass += m
		com += d[1]*m
		masses.append(m)
	com /= mass
	var e := _body("enemy",com)
	for d in defs:
		var lp: Vector2 = d[1]-com
		if d[0] == "rect": e.add_rect(lp,d[2])
		else: e.add_circle(lp,d[2])
		e.loc[d[4]] = lp
	e.loc.ref = Vector2(x,y-62)-com if titan else e.loc.body
	if not titan:
		e.loc.torso = e.loc.body
		e.loc.mouth = e.loc.head + Vector2(-20,6)
	e.mass = mass
	e.matter_inertia(masses)
	e.inertia *= 10 if titan else 6
	e.set_phys(0.35 if titan else 0.5, 0 if titan else 0.1)
	e.can_sleep = false
	e.p = {"alive":true}
	return e
