class_name WorldMechanics
extends RefCounted
## Prototype PORTALS/ROPES/WELLS and buoyancy. Distance constraints use the same
## local attachment points, mass weighting, stiffness and damping as Matter.
var game: Game
var ropes := []
var balloons := []
var wells := []

func _init(g: Game) -> void:
	game = g

func reset(data: Dictionary) -> void:
	ropes.clear(); balloons.clear(); wells.clear()
	for w in data.get("wells", []):
		wells.append({"pos": Vector2(w[0], w[1]), "strength": w[2], "radius": 240.0})

func ends(r: Dictionary) -> Array:
	return [r.a.wpt(r.pa) if r.a != null else r.pa, r.b.wpt(r.pb)]

func rope(a, pa: Vector2, b: GBody, pb: Vector2, stiffness: float, damping: float, kind := "rope", length := -1.0) -> Dictionary:
	var r := {"a": a, "pa": pa, "b": b, "pb": pb, "stiffness": stiffness, "damping": damping, "kind": kind, "cut": false}
	var p := ends(r)
	r.length = p[0].distance_to(p[1]) if length < 0 else length
	ropes.append(r)
	return r

func cut(r: Dictionary) -> void:
	if r.cut:
		return
	r.fa = ends(r)[0]; r.fb = ends(r)[1]; r.at = game.sim
	r.cut = true
	Debug.log_event("rope_cut", {"kind": r.kind})
	if game.has_signal("sound_requested"):
		game.emit_signal("sound_requested", "snap", 1.0)

func removed(b: GBody) -> void:
	balloons.erase(b)
	for r in ropes:
		if not r.cut and (r.a == b or r.b == b):
			cut(r)

func balloon(x: float, y: float, body: GBody, local: Vector2, lift: float) -> GBody:
	var b := game.builder._body("balloon", Vector2(x, y))
	b.add_circle(Vector2.ZERO, 22)
	b.mass = PI * 22 * 22 * 0.0003
	b.matter_inertia([b.mass])
	b.set_air(0.04); b.set_phys(0.0, 0.3)
	b.collision_layer = C.L_BALLOON
	b.collision_mask = (C.M_BODY & ~C.L_MISSILE) | C.L_BALLOON
	var cols := [Color("#ff5a6e"), Color("#ffc93c"), Color("#4fb8ff"), Color("#b07cff"), Color("#5ee08a")]
	b.p = {"lift": lift, "col": cols[balloons.size() % cols.size()]}
	b.watch_contacts()
	game.add_body(b); balloons.append(b)
	b.p.rope = rope(b, Vector2(0, 22), body, local, 0.9, 0.05)
	return b

func bridge(x1: float, y1: float, x2: float, y2: float, n: int) -> void:
	var length := (x2 - x1) / n
	var planks := []
	for i in n:
		var b := game.builder.add_block(x1 + length * (i + 0.5), y1 + (y2 - y1) * (i + 0.5) / n + 5, length - 3, 10, "wood")
		b.p.plank = true
		planks.append(b)
	rope(null, Vector2(x1, y1 + 5), planks[0], Vector2(-length / 2 + 1.5, 0), 0.9, 0, "link", 2)
	for i in n - 1:
		rope(planks[i], Vector2(length / 2 - 1.5, 0), planks[i + 1], Vector2(-length / 2 + 1.5, 0), 0.9, 0, "link", 3)
	rope(null, Vector2(x2, y2 + 5), planks[-1], Vector2(length / 2 - 1.5, 0), 0.9, 0, "link", 2)

func pop(b: GBody) -> void:
	if not game.in_world(b):
		return
	var pos := b.global_position
	for i in 14:
		var v := Vector2.from_angle(game.frnd(0, TAU)) * game.frnd(80, 260)
		game.particles.append({"t": "chunk", "x": pos.x, "y": pos.y, "vx": v.x, "vy": v.y, "s": game.frnd(3, 6), "c": b.p.col, "g": 600.0, "life": 0.0, "max": game.frnd(0.5, 0.9), "spin": game.frnd(-10, 10), "drag": 2.0})
	Debug.log_event("balloon_pop", {})
	if game.has_signal("sound_requested"):
		game.emit_signal("sound_requested", "balloon", 1.0)
	game.remove_body(b)

func contact(a: GBody, b: Node) -> void:
	if b is GStatic and b.kind == "pad":
		var offset: Vector2 = a.global_position - b.global_position
		var normal := Vector2(signf(offset.x), 0) if absf(offset.x / b.size.x) > absf(offset.y / b.size.y) else Vector2(0, signf(offset.y))
		if a.prev_v.dot(normal) < 0:
			game.later(0, _bounce.bind(a, normal, -a.prev_v.dot(normal)))
	if a.kind == "balloon" and not game.settling and ((a.prev_v - game._vel(b)).length() / C.STEP > 3 or game._kind(b) in ["grenade", "bullet", "arrow", "nade", "rocket"]):
		game.later(0, pop.bind(a))

func _bounce(b: GBody, normal: Vector2, speed: float) -> void:
	if game.in_world(b):
		# Godot adds both materials' restitution; Matter uses max(a,b).
		# Replace only the rebound normal component, after contact processing.
		b.linear_velocity += normal * (speed - b.linear_velocity.dot(normal))

func blast(pos: Vector2, radius: float) -> void:
	for r in ropes:
		if not r.cut:
			var p := ends(r)
			if C.seg_dist(pos, p[0], p[1]) < radius * 0.4:
				cut(r)

func acceleration(pos: Vector2) -> Vector2:
	var out := Vector2.ZERO
	for w in wells:
		var d: Vector2 = w.pos - pos
		var length := d.length()
		if length >= 1 and length <= w.radius:
			out += d / length * minf(0.7, w.strength * pow(100 / length, 2))
	return out

func swallowed(pos: Vector2) -> bool:
	for w in wells:
		if pos.distance_to(w.pos) < 16:
			return true
	return false

func update() -> void:
	for b in game.projectiles:
		var pos: Vector2 = b.global_position
		var prev: Vector2 = b.p.get("rope_prev", pos)
		for r in ropes:
			if r.cut or r.kind == "link":
				continue
			var p := ends(r)
			if C.seg_dist(pos, p[0], p[1]) < 6 or Geometry2D.segment_intersects_segment(prev, pos, p[0], p[1]) != null:
				cut(r)
		b.p.rope_prev = pos
	for b in game.bodies.duplicate():
		if b == game.player:
			continue
		if swallowed(b.global_position):
			if b.kind == "enemy":
				b.p.alive = false
				game.hud_changed.emit()
			Debug.log_event("well_swallow", {"kind": b.kind})
			game.remove_body(b)
		elif b.kind == "balloon" and b.global_position.y < -900:
			game.remove_body(b)

func _move(b: GBody, delta: Vector2, angle: float) -> void:
	var pos := b.global_position + delta
	var rot := b.rotation + angle
	PhysicsServer2D.body_set_state(b.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(rot, pos))
	b.global_position = pos
	b.rotation = rot
	b.sleeping = false

func before_update() -> void:
	# Position and velocity constraint Jacobians include each attachment's angular
	# lever arm. Mass/inertia weighting avoids pulling an off-centre raft sideways.
	for iteration in 8:
		for r in ropes:
			if r.cut:
				continue
			var p := ends(r)
			var d: Vector2 = p[1] - p[0]
			var length := d.length()
			if length < 0.001:
				continue
			var n := d / length
			var ia: float = 1 / r.a.mass if r.a != null else 0.0
			var ib: float = 1 / r.b.mass
			var ja: float = 1 / r.a.inertia if r.a != null and not r.a.lock_rotation else 0.0
			var jb: float = 1 / r.b.inertia if not r.b.lock_rotation else 0.0
			var ra: Vector2 = r.pa.rotated(r.a.rotation) if r.a != null else Vector2.ZERO
			var rb: Vector2 = r.pb.rotated(r.b.rotation)
			var ca := ra.cross(n)
			var cb := rb.cross(n)
			var mass: float = ia + ib + ca * ca * ja + cb * cb * jb
			var correction: float = (length - r.length) * r.stiffness / mass
			if r.a != null:
				_move(r.a, n * correction * ia, ca * correction * ja)
			_move(r.b, -n * correction * ib, -cb * correction * jb)
			var va: Vector2 = r.a.linear_velocity + Vector2(-ra.y, ra.x) * r.a.angular_velocity if r.a != null else Vector2.ZERO
			var vb: Vector2 = r.b.linear_velocity + Vector2(-rb.y, rb.x) * r.b.angular_velocity
			var impulse: float = (vb - va).dot(n) / mass * (r.stiffness + r.damping * (1 - r.stiffness))
			if r.a != null:
				r.a.linear_velocity += n * impulse * ia
				r.a.angular_velocity += ca * impulse * ja
			r.b.linear_velocity -= n * impulse * ib
			r.b.angular_velocity -= cb * impulse * jb

	# Apply after resolving constraints: assigning velocities above must not replace
	# newly buffered impulses in Godot's physics server.
	for b in balloons:
		b.linear_velocity += Vector2(0, -b.p.lift * 0.001 * C.FORCE_IMPULSE / b.mass)
	for b in game.bodies:
		if b != game.player:
			var acc := acceleration(b.global_position)
			if acc != Vector2.ZERO:
				b.linear_velocity += acc * C.STEP

func draw(view: Node2D) -> void:
	for w in wells:
		view.draw_circle(w.pos, 34, Color("#6e468f"))
		view.draw_arc(w.pos, 46, game.sim * 0.04, game.sim * 0.04 + TAU * 0.8, 40, Color("#e8a7ff"), 4, true)
		view.draw_circle(w.pos, 16, Color("#21182d"))
	for r in ropes:
		if r.cut:
			if r.kind != "rope" or game.sim - r.at > 40:
				continue
			var col := Color("#8a6a40"); col.a = 1 - (game.sim - r.at) / 40.0
			var mid: Vector2 = (r.fa + r.fb) / 2 + Vector2(0, (game.sim - r.at) * 0.8)
			view.draw_line(r.fa, mid + Vector2(-5, 0), col, 2.5, true)
			view.draw_line(r.fb, mid + Vector2(5, 0), col, 2.5, true)
		else:
			var p := ends(r)
			view.draw_line(p[0], p[1], Color("#8a6a40"), 3 if r.kind == "link" else 2.5, true)
	for b in balloons:
		var p: Vector2 = b.global_position
		view.draw_circle(p, 22, b.p.col)
		view.draw_arc(p, 22, 0, TAU, 32, Color("#463549"), 2, true)
		view.draw_circle(p + Vector2(-7, -8), 5, Color(1, 1, 1, 0.45))
