class_name Game
extends Node2D
## The simulation: a port of the prototype's STATE / FORCES / CHARACTERS / EXPLOSIONS /
## FIRING / SIM STEP sections. Rendering lives in view.gd, UI in hud.gd.
##
## Tick order (matches Matter's step()): Godot flushes contact signals (-> hit()),
## then calls _physics_process (our step: queue, AI, end checks, then the
## "beforeUpdate" forces), then steps the physics server.
## Kills, damage and body removal never happen inside a contact callback: hit() only
## sets flags and defers work with later(), exactly like the prototype.

signal hud_changed
signal ended(won: bool)          # the moment the level is decided
signal show_result               # after the slow-mo delay (UI shows the card)
signal player_hurt(dmg: int)      # prototype: hpChip 'shake' + sfx('hurt') + musicDuck()

const SETTLE_TICKS := 30

var rng := RandomNumberGenerator.new()   # physics-affecting randomness (seeded per level)
var frng := RandomNumberGenerator.new()  # cosmetic randomness
var world: Node2D
var builder: LevelBuilder
var level_idx := 0
var L := {}
var state := "menu"     # menu | settle | play | won | lost
var settling := false
var settle_left := 0
var sim := 0

var bodies := []        # every live GBody
var statics := []
var enemies := []
var projectiles := []
var bullets := []
var rags := []
var queue := []
var portals := []
var particles := []
var decals := []

var player: GBody
var ammo := {"grenade": 0, "rocket": 0}
var weapon := "grenade"
var aim := {"dx": 0.8, "dy": -0.6, "pow": 0.55, "active": false}
var shots := 0
var last_shot := -9999
var last_move := 0
var shake := 0.0
var slow_until := 0
var recoil := 0.0
var flash_a := 0.0
var hurt_a := 0.0
var lose_why := "ammo"
var _los_q: PhysicsRayQueryParameters2D


func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	add_child(world)
	frng.randomize()
	Debug.game = self


func _exit_tree() -> void:
	if is_instance_valid(player) and not player.is_inside_tree():
		player.free()


func rnd(a: float, b: float) -> float:
	return rng.randf_range(a, b)


func frnd(a: float, b: float) -> float:
	return frng.randf_range(a, b)


# ---------------- level lifecycle ----------------

func level_count() -> int:
	return Levels.LEVELS.size()


func start_level(i: int, data: Dictionary = {}) -> void:
	for c in world.get_children():
		world.remove_child(c)
		c.queue_free()
	bodies.clear(); statics.clear(); enemies.clear(); projectiles.clear(); bullets.clear(); rags.clear()
	queue.clear(); portals.clear(); particles.clear(); decals.clear()
	if is_instance_valid(player) and not player.is_inside_tree():
		player.free()
	player = null
	level_idx = i
	L = data if not data.is_empty() else Levels.LEVELS[i]
	rng.seed = 1000 + i
	sim = 0; shots = 0; last_shot = -9999; last_move = 0; shake = 0.0; slow_until = 0
	recoil = 0.0; flash_a = 0.0; hurt_a = 0.0; lose_why = "ammo"
	Engine.time_scale = 1.0
	builder = LevelBuilder.new(self)
	builder.run(L.build)
	builder._static(Vector2(-300, 1560), Vector2(600, 2000), "ground")   # solid ground behind the player
	var pp: Array = L.get("player", [100, 560])
	player = builder.make_char(pp[0], pp[1], "player")
	player.p.merge({"hp": 100, "hit_cd": 0, "flash": 0, "cause": "", "dmg_at": -999})
	# The soldier braces himself: he can be shoved or blown away, but never tips over by himself.
	# == Matter Body.setInertia(player, Infinity). This is the fix for "dying for no reason". Keep it.
	player.lock_rotation = true
	add_body(player)
	var pi := 0
	for pd in L.get("portals", []):
		var mv = pd.get("move", null)
		var a := {"pair": pi, "x0": pd.a[0], "y0": pd.a[1], "x": pd.a[0], "y": pd.a[1], "mv": mv if mv and mv.end == "a" else null, "partner": portals.size() + 1}
		var b := {"pair": pi, "x0": pd.b[0], "y0": pd.b[1], "x": pd.b[0], "y": pd.b[1], "mv": mv if mv and mv.end == "b" else null, "partner": portals.size()}
		portals.append(a); portals.append(b)
		pi += 1
	ammo = {"grenade": 0, "rocket": 0}
	ammo.merge(L.ammo, true)
	weapon = "grenade" if ammo.grenade > 0 else "rocket"
	aim = {"dx": 0.8, "dy": -0.6, "pow": 0.55, "active": false}
	state = "settle"
	settling = true
	settle_left = SETTLE_TICKS
	hud_changed.emit()


func add_body(b: GBody) -> void:
	world.add_child(b)
	bodies.append(b)


func add_static(s: GStatic) -> void:
	world.add_child(s)
	statics.append(s)


func in_world(b) -> bool:
	return is_instance_valid(b) and not b.removed


func remove_body(b) -> void:
	if not is_instance_valid(b) or b.removed:
		return
	b.removed = true
	bodies.erase(b); projectiles.erase(b); bullets.erase(b); rags.erase(b); enemies.erase(b)
	if b.get_parent():
		b.get_parent().remove_child(b)
	if b != player:   # the dead player's data (hp, cause) is still read by the lose card; freed in start_level
		b.queue_free()


func later(steps: int, fn: Callable) -> void:
	queue.append({"at": sim + steps, "fn": fn})


func alive_count() -> int:
	var n := 0
	for e in enemies:
		if e.p.alive:
			n += 1
	return n


func total_ammo() -> int:
	return ammo.get("grenade", 0) + ammo.get("rocket", 0)


# ---------------- SIM STEP ----------------

func _physics_process(_dt: float) -> void:
	if state == "menu" or player == null:
		return
	if settling:
		settle_left -= 1
		if settle_left <= 0:
			settling = false
			for b in bodies:
				b.linear_velocity = Vector2.ZERO
				b.angular_velocity = 0.0
			queue.clear()
			state = "play"
		_before_update()
		return
	sim += 1
	_update_world_tricks()
	for pr in projectiles.duplicate():
		if pr.p.get("ng", 0) and sim >= pr.p.ng:
			if is_instance_valid(player):
				pr.remove_collision_exception_with(player)
			pr.p.ng = 0
		if pr.kind == "grenade" and sim >= pr.p.fuse:
			explode(pr.global_position, C.R_GREN, C.P_GREN, pr, "self")
			continue
		if pr.kind == "rocket" and not pr.p.done:
			var a: float = pr.linear_velocity.angle()
			var tail: Vector2 = pr.global_position - Vector2.from_angle(a) * 16
			particles.append({"t": "fire", "x": tail.x, "y": tail.y, "vx": frnd(-20, 20), "vy": frnd(-20, 20), "r": frnd(4, 6), "life": 0.0, "max": 0.18})
			if sim % 2 == 0:
				particles.append({"t": "smoke", "x": tail.x, "y": tail.y, "vx": frnd(-15, 15), "vy": frnd(-30, 0), "r": frnd(4, 7), "life": 0.0, "max": frnd(0.5, 0.9)})
			if sim - pr.p.born > 500:
				remove_body(pr)
				continue
		var pp: Vector2 = pr.global_position
		if pp.y > 1600 or pp.x < -600 or pp.x > 2200:
			remove_body(pr)
	for bl in bullets.duplicate():
		var bp: Vector2 = bl.global_position
		if sim - bl.p.born > 150 or bp.y > 1600 or bp.x < -400 or bp.x > 2000:
			remove_body(bl)
	if not queue.is_empty():
		var due := []
		var rest := []
		for q in queue:
			(due if q.at <= sim else rest).append(q)
		queue = rest
		for q in due:
			q.fn.call()
	for e in enemies:
		if not e.p.alive or not in_world(e):
			continue
		if absf(C.norm_a(e.rotation)) > 0.95 or e.global_position.y > 1400 or e.global_position.y < -700:
			kill(e, Vector2.ZERO, false)
	if player.p.alive and player.global_position.y > 1300:
		if sim - player.p.dmg_at > 240:
			player.p.cause = "fall"
		kill_player(Vector2.ZERO, false)
	_update_enemies()
	_update_rag_bleeding()
	var moving := false
	for b in bodies.duplicate():
		if b.linear_velocity.length() / C.STEP > 0.35:
			moving = true
		if b.global_position.y > 2600:
			remove_body(b)
	if moving:
		last_move = sim
	_check_end()
	_before_update()


## Matter 'beforeUpdate': forces for the coming physics step, and cache pre-step
## velocities so hit() can measure impact speed like Matter's collisionStart does.
func _before_update() -> void:
	for e in enemies:
		if not e.p.alive or not in_world(e):
			continue
		var a := C.norm_a(e.rotation)
		var w: float = e.angular_velocity / C.STEP
		if absf(a) < 0.45 and absf(w) < 0.1:
			e.angular_velocity = (w * 0.75 - a * 0.03) * C.STEP
	for b in bodies:
		b.prev_v = b.linear_velocity


func _check_end() -> void:
	if state != "play":
		return
	if alive_count() == 0:
		state = "won"
		slow_until = Time.get_ticks_msec() + 1100
		ended.emit(true)
		get_tree().create_timer(1.7, true, false, true).timeout.connect(_result_if.bind("won"))
	elif total_ammo() == 0 and projectiles.is_empty() and queue.is_empty() and sim - last_shot > 90 \
			and (sim - last_move > 45 or sim - last_shot > 600):
		state = "lost"
		lose_why = "ammo"
		ended.emit(false)
		get_tree().create_timer(0.5, true, false, true).timeout.connect(_result_if.bind("lost"))


func _result_if(s: String) -> void:
	if state != s:
		return
	if s == "won":
		Save.record_win(level_idx, stars_for(shots), level_count())
	show_result.emit()


func stars_for(n: int) -> int:
	var par: int = L.par
	return 3 if n <= par else (2 if n <= par + 1 else 1)


func _process(dt: float) -> void:
	var now := Time.get_ticks_msec()
	var ts := 0.35 if now < slow_until else 1.0
	if Engine.time_scale != ts and state != "settle":
		Engine.time_scale = ts
	_update_particles(dt * ts)
	shake *= pow(0.004, dt)
	if shake < 0.2:
		shake = 0.0
	recoil = maxf(0.0, recoil - dt * 5)
	flash_a = maxf(0.0, flash_a - dt * 2.5)
	var floor_a := 0.35 if player and not player.p.alive else 0.0
	hurt_a = maxf(floor_a, hurt_a - dt * 1.2)


# ---------------- collisions (Matter collisionStart -> hit) ----------------

func on_contact(a: GBody, other: Node) -> void:
	hit(a, other)


func _kind(n) -> String:
	if n is GBody or n is GStatic:
		return n.kind
	return ""


func _vel(n) -> Vector2:
	return n.prev_v if n is GBody else Vector2.ZERO


func _mass(n) -> float:
	return n.mass if n is GBody else INF


func hit(A: GBody, B: Node) -> void:
	if A.removed or not is_instance_valid(B):
		return
	var k := A.kind
	if k == "rocket":
		if not A.p.done:
			A.p.done = true
			later(0, _rocket_hit.bind(A))
		return
	if k == "bullet":
		if not A.p.done:
			A.p.done = true
			later(0, missile_hit.bind(A, B, false))
		return
	if settling:
		return
	var bk := _kind(B)
	if bk == "bullet":
		return
	var rv := (A.prev_v - _vel(B)).length() / C.STEP
	var b_static := B is StaticBody2D
	if k == "grenade":
		return
	if k == "enemy" and A.p.alive and not A.p.dying:
		var deadly := false
		var ratio := minf(_mass(B) / A.mass, 4.0)
		if b_static:
			deadly = rv > 7.5
		else:
			deadly = rv * ratio > 6.5 and not (bk == "rag" and rv < 9) and bk != "enemy"
		if deadly:
			A.p.dying = true
			later(0, kill.bind(A, _vel(B) * 0.4 / C.STEP, rv * ratio > 16))
	if k == "player" and A.p.alive and sim > A.p.hit_cd and bk != "enemy":
		var dmg := 0.0
		if b_static:
			if rv > 9:
				dmg = (rv - 7) * 8
		elif _mass(B) > A.mass * 0.4:
			var s := rv * minf(_mass(B) / A.mass, 4.0)
			if s > 6:
				dmg = (s - 5) * 6
		if dmg > 0:
			A.p.hit_cd = sim + 12
			later(0, damage_player.bind(dmg, (_vel(B) - A.prev_v) / C.STEP, null, "fall" if b_static else "crush"))
	if k == "barrel" and not A.p.triggered and rv > 7:
		trigger(A)


func _rocket_hit(r: GBody) -> void:
	if not in_world(r):
		return
	explode(r.global_position, C.R_ROCK, C.P_ROCK, r, "self")


func trigger(b: GBody) -> void:
	b.p.triggered = true
	later(7, _barrel_go.bind(b))


func _barrel_go(b: GBody) -> void:
	if in_world(b):
		explode(b.global_position, C.R_BAR, C.P_BAR, b, "barrel")


# ---------------- CHARACTERS ----------------

func char_colors(e: GBody) -> Array:
	if e.kind == "player":
		return [Color("#3b6cff"), Color("#2a4fd0"), Color("#8fb0ff")]
	return [Color("#f06a3b"), Color("#c24a20"), Color("#ffa27a")]


## Matter makeRagdoll(): swap a character for 6 jointed parts (or loose gibs).
## ev is in Matter px/step.
func make_ragdoll(e: GBody, ev: Vector2, gib: bool, S := 1.0) -> Vector2:
	var a := e.rotation
	var T := e.wpt(e.loc.ref)
	var col := char_colors(e)
	var v: Vector2 = e.linear_velocity / C.STEP + ev
	if v.length() > 22:
		v = v.normalized() * 22
	var w0: float = e.angular_velocity / C.STEP
	if not is_finite(w0):
		w0 = 0.0
	remove_body(e)
	var bleed_to := sim + (110 if gib else 40)
	var P := func(lx: float, ly: float) -> Vector2: return T + Vector2(lx * S, ly * S).rotated(a)
	var parts := []
	var torso := _rag_part("torso", P.call(0, -3), Vector2(22, 34) * S, a, col, bleed_to, S)
	var head := _rag_part("head", P.call(0, -33), Vector2(26, 26) * S, a, col, bleed_to, S)
	parts.append(torso); parts.append(head)
	var joints := [[head, P.call(0, -20)]]
	for d in [[-13, -3, 8, 22, -13, -14], [13, -3, 8, 22, 13, -14], [-6, 20, 9, 16, -6, 12], [6, 20, 9, 16, 6, 12]]:
		var limb := _rag_part("limb", P.call(d[0], d[1]), Vector2(d[2], d[3]) * S, a, col, bleed_to, S)
		parts.append(limb)
		joints.append([limb, P.call(d[4], d[5])])
	for i in parts.size():
		for j in range(i + 1, parts.size()):
			parts[i].add_collision_exception_with(parts[j])
	for pt in parts:
		add_body(pt)
		rags.append(pt)
	if not gib:
		for jd in joints:
			var j := PinJoint2D.new()
			j.position = jd[1]
			world.add_child(j)
			j.node_a = j.get_path_to(torso)
			j.node_b = j.get_path_to(jd[0])
	for pt in parts:
		var s := Vector2(rnd(-1, 1), rnd(-1, 1))
		if gib:
			var dd: Vector2 = pt.global_position - T
			var dl := dd.length() if dd.length() > 0 else 1.0
			s = Vector2(dd.x / dl * rnd(3, 7) + rnd(-2, 2), dd.y / dl * rnd(3, 7) - rnd(1, 4))
		pt.linear_velocity = (v + s) * C.STEP
		pt.angular_velocity = (w0 + rnd(-0.15, 0.15) * (3.0 if gib else 1.0)) * C.STEP
	var dl2 := v.length() if v.length() > 0 else 1.0
	blood_burst(T.x, T.y - 8, v.x / dl2, v.y / dl2, 55 if gib else 22, 1.6 if gib else 1.0, col)
	if gib:
		particles.append({"t": "ring", "x": T.x, "y": T.y, "vx": 0.0, "vy": 0.0, "r": 45.0, "life": 0.0, "max": 0.25, "c": Color("#c21a2a") if Save.prog.blood else Color.WHITE})
	return T


func _rag_part(shape: String, pos: Vector2, size: Vector2, a: float, col: Array, bleed: int, S: float) -> GBody:
	var b := builder._body("rag", pos)
	b.rotation = a
	if shape == "head":
		b.add_circle(Vector2.ZERO, 13 * S)
		b.mass = PI * 169 * S * S * 0.0012
	else:
		b.add_rect(Vector2.ZERO, size)
		b.mass = size.x * size.y * 0.0012
	b.matter_inertia([b.mass])
	b.set_phys(0.8, 0.1)
	b.set_air(0.012)
	b.p = {"shape": shape, "w": size.x, "h": size.y, "col": col, "bleed": bleed, "r": 13 * S}
	return b


func kill(e: GBody, ev: Vector2, gib: bool) -> void:
	if not e.p.alive:
		return
	e.p.alive = false
	Debug.log_event("enemy_killed", {"ev": ev, "gib": gib, "rot": e.rotation, "y": e.global_position.y})
	if in_world(e):
		make_ragdoll(e, ev, gib)
	hud_changed.emit()


func damage_player(dmg: float, dir: Vector2, at, cause: String) -> void:
	if not player.p.alive or (state != "play" and state != "won"):
		return
	var d := roundi(dmg)
	if d < 1:
		return
	player.p.hp = maxi(0, player.p.hp - d)
	if cause != "fall" or sim - player.p.dmg_at > 120:
		player.p.cause = cause if cause != "" else "crush"
	player.p.dmg_at = sim
	player.p.flash = sim + 8
	hurt_a = minf(0.75, hurt_a + 0.25 + d / 120.0)
	var T: Vector2 = at if at != null else player.wpt(player.loc.torso)
	var dl := dir.length() if dir.length() > 0 else 1.0
	blood_burst(T.x, T.y, dir.x / dl, dir.y / dl, 6 + d / 3, 1.0, char_colors(player))
	particles.append({"t": "text", "x": T.x, "y": T.y - 40, "vx": frnd(-20, 20), "vy": -90.0, "life": 0.0, "max": 0.9, "text": "-%d" % d, "c": Color("#ff3b4e")})
	Debug.log_event("damage", {"dmg": d, "cause": cause, "hp": player.p.hp})
	player_hurt.emit(d)
	if player.p.hp <= 0:
		kill_player(dir / dl * 6, d > 45)
	hud_changed.emit()


func kill_player(ev: Vector2, gib: bool) -> void:
	if not player.p.alive:
		return
	player.p.alive = false
	player.p.hp = 0
	Debug.log_event("player_died", {"cause": player.p.cause})
	make_ragdoll(player, ev, gib)
	hurt_a = 0.8
	if state == "play":
		state = "lost"
		lose_why = "ko"
		slow_until = Time.get_ticks_msec() + 900
		ended.emit(false)
		get_tree().create_timer(1.5, true, false, true).timeout.connect(_result_if.bind("lost"))
	hud_changed.emit()


# ---------------- EXPLOSIONS ----------------

## The single source of blast impulses, damage and barrel chains (prototype explode()).
## Mass-aware falloff impulse, occluded (x0.35) by statics and stone blocks.
func explode(p: Vector2, R: float, power: float, src, cause: String) -> void:
	if src != null and in_world(src):
		remove_body(src)
	Debug.log_event("explode", {"x": p.x, "y": p.y, "power": power, "cause": cause})
	fx_explosion(p, R, power)
	shake = minf(20, shake + power * 0.45)
	if power >= C.P_BAR:
		flash_a = maxf(flash_a, 0.35)
	var space := get_world_2d().direct_space_state
	for b in bodies.duplicate():
		if not in_world(b):
			continue
		var k: String = b.kind
		var bb: Rect2 = b.aabb()
		var c := Vector2(clampf(p.x, bb.position.x, bb.end.x), clampf(p.y, bb.position.y, bb.end.y))
		var d := c.distance_to(p)
		if d > R:
			continue
		var f := 1.0 - d / R
		var dir: Vector2 = b.global_position - p
		var dl := dir.length() if dir.length() > 0 else 1.0
		dir = Vector2(dir.x / dl, dir.y / dl - 0.35)
		dir = dir.normalized() if dir.length() > 0 else Vector2.UP
		if d > 4:
			var q := PhysicsRayQueryParameters2D.create(p, b.global_position, C.L_STATIC | C.L_BLOCKER, [b.get_rid()])
			if not space.intersect_ray(q).is_empty():
				f *= 0.35
		var J := minf(power * f, 20 * b.mass)
		var dv: Vector2 = dir * J / b.mass   # Matter px/step
		if k == "enemy":
			if b.p.alive and f > 0.18:
				kill(b, dv, f > 0.62)
				continue
		elif k == "player":
			if b.p.alive and f > 0.05:
				var dmg := power * f * (1.3 if cause == "enemy" else 1.9)
				var dying: bool = player.p.hp - dmg <= 0
				damage_player(dmg, dv, null, cause if cause != "" else "self")
				if dying:
					continue
		elif k == "barrel":
			if not b.p.triggered and f > 0.1:
				trigger(b)
		elif k == "block":
			if power * f > b.p.hp:
				shatter(b, dv)
				continue
		elif k == "rag" and f > 0.4:
			b.p.bleed = maxi(b.p.bleed, sim + 30)
		if in_world(b):
			b.apply_impulse(dir * J * C.STEP, c - b.global_position)


## Fracture: a block breaks into a 2x2 / 2x1 grid of weaker blocks (prototype shatter()).
func shatter(b: GBody, dv: Vector2) -> void:
	var w: float = b.p.w
	var h: float = b.p.h
	var mat: String = b.p.mat
	var m: Dictionary = C.MAT[mat]
	var pos := b.global_position
	var ang := b.rotation
	var v0: Vector2 = b.linear_velocity / C.STEP
	remove_body(b)
	var col: Color = Color("#d9f3ff") if mat == "ice" else m.fill
	for i in 12:
		particles.append({"t": "chunk", "x": pos.x + frnd(-w / 3, w / 3), "y": pos.y + frnd(-h / 3, h / 3), "vx": dv.x * 40 + frnd(-220, 220), "vy": dv.y * 40 + frnd(-380, -50), "s": frnd(3, 7), "c": col, "g": 1300.0, "life": 0.0, "max": frnd(0.6, 1.1), "spin": frnd(-12, 12)})
	if mat == "wood":
		for i in 6:
			particles.append({"t": "splinter", "x": pos.x, "y": pos.y, "vx": dv.x * 50 + frnd(-260, 260), "vy": dv.y * 50 + frnd(-400, -80), "s": frnd(8, 14), "c": m.dark, "g": 1300.0, "life": 0.0, "max": frnd(0.6, 1.0), "spin": frnd(-15, 15)})
	var cols := 2 if w >= 34 else 1
	var rows := 2 if h >= 34 else 1
	if cols * rows == 1:
		return
	var vm := dv.length()
	var sc := 18.0 / vm if vm > 18 else 1.0
	var pw := w / cols
	var ph := h / rows
	for i in cols:
		for j in rows:
			var r := Vector2(-w / 2 + pw * (i + 0.5), -h / 2 + ph * (j + 0.5)).rotated(ang)
			var nb := builder.add_block(pos.x + r.x, pos.y + r.y, pw - 1.5, ph - 1.5, mat, ang)
			nb.p.hp = m.hp * 0.6
			nb.linear_velocity = (v0 + dv * sc * 0.8 + Vector2(rnd(-1.5, 1.5), rnd(-1.5, 1))) * C.STEP
			nb.angular_velocity = rnd(-0.2, 0.2) * C.STEP


func missile_hit(ms: GBody, B, shield: bool) -> void:
	bullets.erase(ms)
	if not in_world(ms):
		return
	var v: Vector2 = ms.prev_v
	var dir := v.normalized() if v.length() > 0 else Vector2.RIGHT
	var p := ms.global_position
	remove_body(ms)
	if not is_instance_valid(B):
		return
	var k := _kind(B)
	var is_arrow := ms.kind == "arrow"   # arrows (stage 2 archers) share this path: 22 dmg, cause "arrow"
	if k == "player" and B.p.alive:
		damage_player(22 if is_arrow else 16, dir * 3, p, "arrow" if is_arrow else "bullet")
		if in_world(B):
			B.apply_impulse(dir * 0.004 * C.FORCE_IMPULSE, p - B.global_position)
		return
	if k == "enemy" and B.p.alive and not shield:
		kill(B, dir * 4, false)
		return
	if k == "rag":
		blood_burst(p.x, p.y, dir.x, dir.y, 6, 0.8, B.p.col)
		return
	if k == "barrel" and not B.p.triggered:
		trigger(B)
	for i in 7:
		var a := atan2(-dir.y, -dir.x) + frnd(-1, 1)
		var s := frnd(150, 400)
		particles.append({"t": "spark", "x": p.x, "y": p.y, "vx": cos(a) * s, "vy": sin(a) * s, "g": 900.0, "life": 0.0, "max": frnd(0.15, 0.35)})
	particles.append({"t": "puff", "x": p.x, "y": p.y, "vx": 0.0, "vy": -20.0, "r": 5.0, "life": 0.0, "max": 0.3})


# ---------------- ENEMIES ----------------

func enemy_shoulder(e: GBody) -> Vector2:
	return e.wpt(e.loc.torso + Vector2(0, -8))


func player_head() -> Vector2:
	return player.wpt(player.loc.torso + Vector2(0, -14))


func alerted() -> bool:
	return shots > 0 or sim > L.get("alert_at", 240)


func los_blocked(a: Vector2, b: Vector2) -> bool:
	var q := PhysicsRayQueryParameters2D.create(a, b, C.L_STATIC | C.L_SOLID)
	return not get_world_2d().direct_space_state.intersect_ray(q).is_empty()


func _update_enemies() -> void:
	if not player.p.alive or state != "play":
		return
	var alert := alerted()
	var H2 := player_head()
	for e in enemies.duplicate():
		if not e.p.alive or not in_world(e):
			continue
		var pl: Dictionary = e.p
		var S := enemy_shoulder(e)
		if pl.shooter:
			pl.aim_a += C.norm_a((H2 - S).angle() - pl.aim_a) * 0.12
		if not alert:
			continue
		if pl.next == 0 and pl.shooter:
			pl.next = sim + rng.randi_range(50, 119)
			pl.alert_at = sim
		if absf(C.norm_a(e.rotation)) > 0.4 or sim < pl.next:
			continue
		if pl.shooter:
			pl.next = sim + rng.randi_range(120, 189)
			if los_blocked(S, H2):
				continue
			var a: float = pl.aim_a + rnd(-0.035, 0.035)
			var dir := Vector2.from_angle(a)
			var m := S + dir * 36
			_spawn_bullet(m, dir * 17)
			pl.mflash = sim + 4
			particles.append({"t": "fire", "x": m.x, "y": m.y, "vx": dir.x * 60, "vy": dir.y * 60, "r": 6.0, "life": 0.0, "max": 0.1})
			particles.append({"t": "smoke", "x": m.x, "y": m.y, "vx": dir.x * 30, "vy": -20.0, "r": 5.0, "life": 0.0, "max": 0.5})


func _spawn_bullet(pos: Vector2, v: Vector2) -> void:
	var bl := builder._body("bullet", pos)
	bl.add_circle(Vector2.ZERO, 3)
	bl.mass = PI * 9 * 0.006
	bl.set_phys(0.1, 0.0)
	bl.set_air(0.0)
	bl.gravity_scale = 0.0          # prototype cancels gravity on bullets
	bl.collision_layer = C.L_MISSILE
	bl.collision_mask = C.M_MISSILE
	bl.continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	bl.can_sleep = false
	bl.p = {"born": sim, "done": false}
	bl.watch_contacts()
	add_body(bl)
	bl.linear_velocity = v * C.STEP
	bl.prev_v = bl.linear_velocity
	bullets.append(bl)


# ---------------- PORTALS ----------------

func in_portal(e: Dictionary, p: Vector2) -> bool:
	var dx: float = (p.x - e.x) / 24.0
	var dy: float = (p.y - e.y) / 36.0
	return dx * dx + dy * dy < 1


func portal_at(p: Vector2) -> int:
	for i in portals.size():
		if in_portal(portals[i], p):
			return i
	return -1


func _update_world_tricks() -> void:
	var t := sim * C.DT / 1000.0
	for e in portals:
		if e.mv:
			e.y = e.y0 + sin(t * e.mv.spd) * e.mv.amp
	if portals.is_empty():
		return
	for b in projectiles + bullets:
		if not in_world(b):
			continue
		var i := portal_at(b.global_position)
		if i >= 0 and i != b.p.get("in_p", -1):
			var o: Dictionary = portals[portals[i].partner]
			var v: Vector2 = b.linear_velocity
			var to := Vector2(o.x, o.y)
			PhysicsServer2D.body_set_state(b.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(b.rotation, to))
			b.global_position = to
			b.linear_velocity = v
			b.p.in_p = portals[i].partner
			fx_portal(portals[i]); fx_portal(o)
		elif i < 0:
			b.p.in_p = -1


# ---------------- FIRING ----------------

func can_fire() -> bool:
	return state == "play" and player != null and player.p.alive and projectiles.is_empty() and ammo.get(weapon, 0) > 0


func shoulder() -> Vector2:
	return player.wpt(player.loc.torso + Vector2(2, -4))


func tip_pos() -> Vector2:
	return shoulder() + Vector2(aim.dx, aim.dy) * 44


## Launch velocity in Matter px/step.
func launch_vel() -> Vector2:
	var sp: float = 9 + 5 * aim.pow if weapon == "rocket" else 4 + 16 * aim.pow
	return Vector2(aim.dx, aim.dy) * sp


func fire() -> bool:
	if not can_fire():
		return false
	var t := tip_pos()
	var v := launch_vel()
	var b: GBody
	if weapon == "grenade":
		b = builder._body("grenade", t)
		b.add_circle(Vector2.ZERO, 9)
		b.mass = PI * 81 * 0.004
		b.matter_inertia([b.mass])
		# Prototype restitution is 0.45, but Matter's solver loses energy: measured bounce
		# ratios on flat ground are 0.36-0.44. Godot applies 0.45 exactly, so use 0.40 to match the feel.
		b.set_phys(0.5, 0.40)
		b.set_air(0.0)
		b.p = {"fuse": sim + 140, "ng": sim + 15}
	else:
		b = builder._body("rocket", t)
		b.add_rect(Vector2.ZERO, Vector2(30, 10))
		b.mass = 30 * 10 * 0.003
		b.rotation = v.angle()
		b.lock_rotation = true          # Matter: infinite inertia
		b.gravity_scale = 0.2           # Matter: upward force of 0.8 g every step
		b.set_air(0.0)
		b.p = {"born": sim, "ng": sim + 15, "done": false}
	b.collision_layer = C.L_PROJ
	b.collision_mask = C.M_PROJ
	b.continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	b.can_sleep = false
	b.watch_contacts()
	add_body(b)
	b.add_collision_exception_with(player)
	b.linear_velocity = v * C.STEP
	b.prev_v = b.linear_velocity
	if weapon == "grenade":
		b.angular_velocity = 0.15 * C.STEP
	b.p.in_p = portal_at(t)
	projectiles.append(b)
	ammo[weapon] -= 1
	shots += 1
	last_shot = sim
	recoil = 1.0
	for i in 6:
		particles.append({"t": "smoke", "x": t.x, "y": t.y, "vx": aim.dx * 60 + frnd(-40, 40), "vy": aim.dy * 60 + frnd(-40, 40), "r": frnd(5, 9), "life": 0.0, "max": frnd(0.4, 0.7), "drag": 2.0})
	particles.append({"t": "fire", "x": t.x, "y": t.y, "vx": aim.dx * 80, "vy": aim.dy * 80, "r": 10.0, "life": 0.0, "max": 0.12})
	if ammo[weapon] == 0:
		var o := "rocket" if weapon == "grenade" else "grenade"
		if ammo.get(o, 0) > 0:
			weapon = o
	hud_changed.emit()
	return true


## Trajectory preview: same integration as the physics engine, follows portals.
func predict() -> Array:
	var pts := []
	var t := tip_pos()
	var v := launch_vel()
	var g := C.GS * 0.2 if weapon == "rocket" else C.GS
	var x := t.x
	var y := t.y
	var vx := v.x
	var vy := v.y
	var inp := portal_at(t)
	var warps := 0
	var space := get_world_2d().direct_space_state
	var q := PhysicsPointQueryParameters2D.new()
	q.collision_mask = C.L_STATIC | C.L_BODY | C.L_ENEMY
	q.exclude = [player.get_rid()]
	for i in 190:
		vy += g
		x += vx
		y += vy
		var e := portal_at(Vector2(x, y)) if not portals.is_empty() else -1
		if e >= 0 and e != inp and warps < 4:
			var o: Dictionary = portals[portals[e].partner]
			x = o.x
			y = o.y
			inp = portals[e].partner
			warps += 1
			pts.append({"pos": Vector2(x, y), "w": warps, "gap": true})
		elif e < 0:
			inp = -1
		if i % 3 == 2:
			pts.append({"pos": Vector2(x, y), "w": warps, "gap": false})
		if y > 1500:
			break
		q.position = Vector2(x, y)
		if not space.intersect_point(q, 1).is_empty():
			break
	return pts


# ---------------- FX (cosmetic only, never touches physics) ----------------

## Prototype: moving ragdoll parts bleed every third physics tick until bleed expires.
func _update_rag_bleeding() -> void:
	if sim % 3 != 0:
		return
	for r in rags:
		if r.p.bleed <= sim or not in_world(r):
			continue
		var v: Vector2 = r.linear_velocity / C.STEP
		if v.length() < 0.3 and randf() < 0.6:
			continue
		blood(r.global_position.x, r.global_position.y, v.x * 40 + frnd(-50, 50), v.y * 40 + frnd(-80, 10), frnd(1.8, 3.2), r.p.col)


func blood(x: float, y: float, vx: float, vy: float, r: float, col: Array) -> void:
	if Save.prog.blood:
		particles.append({"t": "blood", "x": x, "y": y, "vx": vx, "vy": vy, "r": r, "g": 1400.0, "life": 0.0, "max": 2.2})
	else:
		particles.append({"t": "chunk", "x": x, "y": y, "vx": vx, "vy": vy, "s": r * 1.6, "c": col[0] if col else Color.WHITE, "g": 1300.0, "life": 0.0, "max": 0.8, "spin": frnd(-10, 10)})


func blood_burst(x: float, y: float, dx: float, dy: float, n: int, power: float, col: Array) -> void:
	for i in n:
		var s := frnd(80, 330) * power
		blood(x + frnd(-5, 5), y + frnd(-5, 5), dx * s + frnd(-140, 140) * power, dy * s - frnd(60, 260) * power, frnd(2, 4.6), col)
	if Save.prog.blood:
		for i in 4:
			particles.append({"t": "mist", "x": x, "y": y, "vx": dx * frnd(20, 80) + frnd(-30, 30), "vy": dy * frnd(20, 80) + frnd(-40, 0), "r": frnd(8, 14), "life": 0.0, "max": frnd(0.3, 0.5), "drag": 3.0})


func add_decal(d: Dictionary) -> void:
	decals.append(d)
	if decals.size() > 260:
		decals = decals.slice(decals.size() - 260)


func point_in_static(p: Vector2) -> bool:
	for s in statics:
		if s.kind != "pad" and Geometry2D.is_point_in_polygon(p, s.poly):
			return true
	return false


func fx_explosion(p: Vector2, R: float, _power: float) -> void:
	particles.append({"t": "flash", "x": p.x, "y": p.y, "vx": 0.0, "vy": 0.0, "r": R * 0.55, "life": 0.0, "max": 0.16})
	particles.append({"t": "ring", "x": p.x, "y": p.y, "vx": 0.0, "vy": 0.0, "r": R, "life": 0.0, "max": 0.32})
	for i in 16:
		var a := frnd(0, TAU); var s := frnd(60, 280)
		particles.append({"t": "fire", "x": p.x, "y": p.y, "vx": cos(a) * s, "vy": sin(a) * s - 60, "r": frnd(9, 21), "life": 0.0, "max": frnd(0.3, 0.6), "drag": 3.0})
	for i in 16:
		var a := frnd(0, TAU); var s := frnd(30, 150)
		particles.append({"t": "smoke", "x": p.x + frnd(-15, 15), "y": p.y + frnd(-15, 15), "vx": cos(a) * s, "vy": sin(a) * s - 70, "r": frnd(12, 26), "life": 0.0, "max": frnd(1, 1.8), "drag": 1.5})
	for i in 14:
		var a := frnd(0, TAU); var s := frnd(250, 620)
		particles.append({"t": "spark", "x": p.x, "y": p.y, "vx": cos(a) * s, "vy": sin(a) * s - 100, "g": 900.0, "life": 0.0, "max": frnd(0.25, 0.6)})
	var cc := Color("#c99a52") if L.get("theme", "desert") == "sky" else Color("#d9a85c")
	for i in 12:
		particles.append({"t": "chunk", "x": p.x, "y": p.y, "vx": frnd(-340, 340), "vy": frnd(-560, -150), "s": frnd(3, 7), "c": cc, "g": 1300.0, "life": 0.0, "max": frnd(0.7, 1.3), "spin": frnd(-12, 12)})
	for i in 5:
		particles.append({"t": "ember", "x": p.x + frnd(-20, 20), "y": p.y + frnd(-20, 20), "vx": frnd(-40, 40), "vy": frnd(-140, -60), "r": frnd(1.5, 3), "life": 0.0, "max": frnd(1, 1.8)})
	for off in [Vector2(0, 14), Vector2(0, R * 0.22), Vector2(-12, 10), Vector2(12, 10)]:
		var q: Vector2 = p + off
		if point_in_static(q):
			add_decal({"t": "scorch", "x": p.x, "y": q.y - 4, "r": R * frnd(0.38, 0.5)})
			break


func fx_portal(e: Dictionary) -> void:
	var c := Color("#3ff0cf") if e.pair % 2 else Color("#5dff8a")
	for i in 16:
		var a := frnd(0, TAU); var s := frnd(80, 240)
		particles.append({"t": "glow", "x": e.x, "y": e.y, "vx": cos(a) * s, "vy": sin(a) * s * 1.4, "r": frnd(2, 4), "c": c, "life": 0.0, "max": frnd(0.3, 0.6), "drag": 3.0})
	particles.append({"t": "ring", "x": e.x, "y": e.y, "vx": 0.0, "vy": 0.0, "r": 55.0, "life": 0.0, "max": 0.3, "c": c})


func _update_particles(dt: float) -> void:
	if particles.is_empty():
		return
	var keep := []
	for p in particles:
		p.life += dt
		p.x += p.vx * dt
		p.y += p.vy * dt
		if p.has("g"):
			p.vy += p.g * dt
		if p.has("drag"):
			var d := maxf(0.0, 1.0 - p.drag * dt)
			p.vx *= d
			p.vy *= d
		if p.has("spin"):
			p.a = p.get("a", 0.0) + p.spin * dt
		if p.t == "blood" and point_in_static(Vector2(p.x, p.y)):
			add_decal({"t": "blood", "x": p.x, "y": p.y, "r": p.r * frnd(1.3, 2.6), "sx": 1 + minf(1.5, absf(p.vx) / 300), "a": atan2(p.vy, p.vx) * 0.15, "dots": [[frnd(-8, 8), frnd(-3, 3), frnd(0.8, 2)], [frnd(-10, 10), frnd(-3, 3), frnd(0.6, 1.6)]]})
			p.life = p.max
		if p.life < p.max:
			keep.append(p)
	particles = keep
	if particles.size() > 900:
		particles = particles.slice(particles.size() - 900)
