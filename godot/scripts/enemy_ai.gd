class_name EnemyAI
extends RefCounted
## Stage-2 enemy behaviour and missiles, translated from prototype solveLob/updateEnemies.
var game: Game
var arrows := []
var nades := []
var stuck := []

func _init(g: Game) -> void:
	game = g

func reset() -> void:
	arrows.clear()
	nades.clear()
	stuck.clear()

## Matter updates velocity (gravity) before position. Return the first viable speed.
func solve_lob(S: Vector2, T: Vector2, speeds: Array, prefer_high: bool) -> Dictionary:
	var dir_x := signf(T.x - S.x)
	if dir_x == 0:
		dir_x = -1
	for speed in speeds:
		var low := {}
		var high := {}
		for degrees in range(-20, 83, 2):
			var a := deg_to_rad(degrees)
			var pos := S
			var v := Vector2(cos(a) * speed * dir_x, -sin(a) * speed)
			var best := INF
			for tick in 240:
				v += game.tricks.acceleration(pos)
				v.y += C.GS
				pos += v
				best = minf(best, pos.distance_to(T))
				if pos.y > T.y + 60 and v.y > 0:
					break
			var candidate := {"a": Vector2(cos(a) * dir_x, -sin(a)).angle(), "miss": best, "degrees": degrees, "speed": speed}
			if degrees < 38:
				if low.is_empty() or best < low.miss:
					low = candidate
			elif high.is_empty() or best < high.miss:
				high = candidate
		for candidate in [high, low] if prefer_high else [low, high]:
			if not candidate.is_empty() and candidate.miss < 26:
				return candidate
	return {}

func update_archer(e: GBody, alert: bool, target: Vector2) -> void:
	var pl := e.p
	var S := game.enemy_shoulder(e)
	var want: float = pl.lob if pl.lob else (game.player_head() - S).angle()
	pl.aim_a += C.norm_a(want - pl.aim_a) * 0.12
	if not alert:
		return
	if pl.next == 0:
		pl.next = game.sim + game.rng.randi_range(50, 119)
		pl.alert_at = game.sim
		game.sound_requested.emit("alert", 1.0)
	if absf(C.norm_a(e.rotation)) > 0.4 or game.sim < pl.next:
		return
	pl.next = game.sim + game.rng.randi_range(150, 219)
	var sol := solve_lob(S, target, [13, 15, 17, 19], game.los_blocked(S, target))
	if sol.is_empty():
		return
	pl.lob = sol.a
	pl.draw = game.sim
	game.later(18, release_arrow.bind(e, sol))

func release_arrow(e: GBody, sol: Dictionary) -> void:
	if not game.in_world(e) or not e.p.alive or game.state != "play":
		return
	var a: float = sol.a + game.rnd(-0.025, 0.025)
	var dir := Vector2.from_angle(a)
	spawn_arrow(game.enemy_shoulder(e) + dir * 22, dir * sol.speed)
	game.sound_requested.emit("bow", 1.0)
	e.p.lob = 0.0
	Debug.log_event("arrow_fired", {"draw_ticks": game.sim - e.p.draw, "speed": sol.speed})

func spawn_arrow(pos: Vector2, velocity: Vector2) -> GBody:
	var arrow := game.builder._body("arrow", pos)
	arrow.add_rect(Vector2.ZERO, Vector2(26, 3))
	arrow.mass = 26 * 3 * 0.004
	arrow.set_phys(0.1, 0.0)
	arrow.set_air(0.0)
	arrow.lock_rotation = true
	arrow.rotation = velocity.angle()
	arrow.collision_layer = C.L_MISSILE
	arrow.collision_mask = C.M_MISSILE
	arrow.continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	arrow.can_sleep = false
	arrow.p = {"born": game.sim, "done": false}
	arrow.watch_contacts()
	game.add_body(arrow)
	arrow.linear_velocity = velocity * C.STEP
	arrow.prev_v = arrow.linear_velocity
	arrows.append(arrow)
	return arrow

func update_arrows() -> void:
	for arrow in arrows.duplicate():
		if game.sim - arrow.p.born > 300 or arrow.global_position.y > 1600:
			game.remove_body(arrow)

func stick_arrow(body: Node, pos: Vector2, angle: float) -> void:
	game.sound_requested.emit("thunk", 1.0)
	var tip := pos + Vector2.from_angle(angle) * 8
	if body is StaticBody2D:
		stuck.append({"pos": tip, "a": angle})
	else:
		stuck.append({"body": weakref(body), "local": (tip - body.global_position).rotated(-body.rotation), "a": angle - body.rotation})
	if stuck.size() > 60:
		stuck.pop_front()

func stuck_pose(entry: Dictionary) -> Dictionary:
	if not entry.has("body"):
		return entry
	var body = entry.body.get_ref()
	if not game.in_world(body):
		return {}
	return {"pos": body.global_position + entry.local.rotated(body.rotation), "a": entry.a + body.rotation}

## Exact prototype groundAt point query, including other enemies as footholds.
func ground_at(pos: Vector2, self_body: GBody) -> bool:
	var q := PhysicsPointQueryParameters2D.new()
	q.position = pos
	q.collision_mask = C.L_STATIC | C.L_SOLID | C.L_ENEMY
	q.exclude = [self_body.get_rid()]
	return not game.get_world_2d().direct_space_state.intersect_point(q, 32).is_empty()

func update_knight(e: GBody) -> void:
	if absf(C.norm_a(e.rotation)) > 0.5: return
	var pl := e.p
	var foot := e.wpt(e.loc.feet)
	var delta := game.player.global_position - e.global_position
	var dir := signf(delta.x)
	if dir == 0: dir = -1
	var grounded := ground_at(foot + Vector2(-10,7), e) or ground_at(foot + Vector2(10,7), e) or ground_at(foot + Vector2(0,7), e)
	if absf(delta.x) < 58 and absf(delta.y) < 70:
		if game.sim > pl.get("swing_cd", 0):
			pl.swing_cd = game.sim + 55
			pl.swing = game.sim
			game.sound_requested.emit("swing", 1.0)
			game.later(9, sword_hit.bind(e, dir))
		if grounded: e.linear_velocity.x *= 0.7
		return
	if not grounded: return
	var vx := e.linear_velocity.x / C.STEP
	vx += (dir * 2.1 - vx) * 0.25
	e.linear_velocity.x = vx * C.STEP
	pl.stuck = pl.get("stuck", 0) + 1 if absf(vx) < 0.7 else 0
	if game.sim > pl.get("jump_cd", 0):
		var fx := foot.x + dir * 30
		var wall := ground_at(Vector2(fx,foot.y - 22),e) or ground_at(Vector2(fx,foot.y - 50),e)
		var gap := true
		for d in range(6,81,12):
			if ground_at(Vector2(fx,foot.y + d),e):
				gap = false
				break
		if wall or gap or pl.stuck > 25 or (delta.y < -40 and absf(delta.x) < 170):
			pl.stuck = 0
			e.linear_velocity = Vector2(dir * (4.3 if gap else 2.7), -8.8) * C.STEP
			pl.jump_cd = game.sim + 45
			game.sound_requested.emit("jump", 1.0)
			Debug.log_event("knight_jump", {"gap":gap})

func sword_hit(e: GBody, dir: float) -> void:
	if not game.in_world(e) or not e.p.alive or not game.player.p.alive: return
	if game.player.global_position.distance_to(e.global_position) < 75:
		game.damage_player(20, Vector2(dir * 4,-2), null, "sword")
		game.player.apply_central_impulse(Vector2(dir * 0.006,-0.003) * C.FORCE_IMPULSE)
		game.sound_requested.emit("clang", 1.0)
		Debug.log_event("sword_hit", {"delay":game.sim - e.p.swing})

func drop_weapons(e: GBody, torso: Vector2, v: Vector2, angle: float) -> void:
	var sh := game.builder.add_block(e.wpt(e.loc.extra).x,e.wpt(e.loc.extra).y,8,46,"wood",angle)
	sh.p.look = "shield"
	sh.linear_velocity = (v + Vector2(game.rnd(-2,2), -game.rnd(1,3))) * C.STEP
	sh.angular_velocity = game.rnd(-0.2,0.2) * C.STEP
	var sw := game.builder.add_block(torso.x + 14,torso.y - 10,4,36,"stone",angle + 0.5)
	sw.p.look = "sword"
	sw.p.hp = 1e9
	sw.linear_velocity = (v + Vector2(game.rnd(-3,3), -game.rnd(2,5))) * C.STEP
	sw.angular_velocity = game.rnd(-0.4,0.4) * C.STEP

func hover(e: GBody) -> void:
	var a := C.norm_a(e.rotation)
	if absf(a) >= 0.9: return
	var t: float = game.sim / 60.0 + e.p.ph
	var target := Vector2(e.p.hx+sin(t*0.7)*40,e.p.hy+sin(t*1.3)*14)
	var accel := (target-e.global_position)*0.0016-e.linear_velocity/C.STEP*0.06
	if accel.length()>0.35: accel=accel.normalized()*0.35
	e.apply_central_impulse(accel*e.mass*C.STEP+Vector2(0,-e.mass*0.001*C.FORCE_IMPULSE))
	e.angular_velocity=(e.angular_velocity/C.STEP*0.8-a*0.05)*C.STEP

func update_jet(e: GBody, alert: bool, target: Vector2) -> void:
	var pl := e.p
	var S := game.enemy_shoulder(e)
	var want: float = pl.lob if pl.lob else (game.player_head()-S).angle()
	pl.aim_a+=C.norm_a(want-pl.aim_a)*0.12
	if not alert: return
	if pl.next==0:
		pl.next=game.sim+game.rng.randi_range(50,119)
		pl.alert_at=game.sim
		game.sound_requested.emit("alert",1.0)
	if absf(C.norm_a(e.rotation))>0.4 or game.sim<pl.next: return
	pl.next=game.sim+game.rng.randi_range(220,299)
	var sol := solve_lob(S,target,[9,11,13,15],false)
	if sol.is_empty(): return
	pl.lob=sol.a
	pl.toss=game.sim
	game.later(10,release_nade.bind(e,sol))

func release_nade(e: GBody, sol: Dictionary) -> void:
	if not game.in_world(e) or not e.p.alive or game.state!="play": return
	var dir := Vector2.from_angle(sol.a+game.rnd(-0.09,0.09))
	spawn_nade(game.enemy_shoulder(e)+dir*24,dir*sol.speed)
	e.p.lob=0.0
	game.sound_requested.emit("toss",1.0)
	Debug.log_event("nade_toss",{"delay":game.sim-e.p.toss,"speed":sol.speed})

func spawn_nade(pos: Vector2, velocity: Vector2) -> GBody:
	var b := game.builder._body("nade",pos)
	b.add_circle(Vector2.ZERO,8)
	b.mass=PI*64*0.004
	b.matter_inertia([b.mass])
	b.set_phys(0.5,0.4)
	b.set_air(0)
	b.collision_layer=C.L_MISSILE
	b.collision_mask=C.M_MISSILE
	b.continuous_cd=RigidBody2D.CCD_MODE_CAST_SHAPE
	b.p={"fuse":game.sim+110}
	b.watch_contacts()
	game.add_body(b)
	b.linear_velocity=velocity*C.STEP
	b.angular_velocity=0.2*C.STEP
	nades.append(b)
	return b

func update_nades() -> void:
	for b in nades.duplicate():
		if game.sim>=b.p.fuse: game.explode(b.global_position,C.R_GREN,C.P_GREN,b,"enemy")
		elif b.global_position.y>1600: game.remove_body(b)

## Prototype telegraph follows the grenade position, radius93.75, alpha.25→.70.
func telegraph(b: GBody) -> Dictionary:
	return {"center":b.global_position,"radius":C.R_GREN*0.75,"alpha":0.25+0.45*(1.0-(b.p.fuse-game.sim)/110.0)}
