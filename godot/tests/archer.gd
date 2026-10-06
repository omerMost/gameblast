extends Node
var g: Game
var fails := []
const EMPTY := {"name": "Arrow contacts", "view": [0, 240, 960, 480], "ammo": {"grenade": 3, "rocket": 2}, "par": 3, "alert_at": 99999, "build": [["ground", 0, 1000, 560], ["enemy", 850, 560, {"archer": true}]]}

func check(ok: bool, what: String) -> void:
	if not ok:
		fails.append(what)

func fresh(data := EMPTY) -> void:
	await Debug.start_level(18, data)
	for enemy in g.enemies:
		enemy.p.next = 99999

func _ready() -> void:
	await TestUtil.boot(self)
	g = Debug.game
	await fresh()
	# Real rigid body arc: gravity bends velocity, arrow faces flight, enemies are excluded.
	var ar := g.enemy_ai.spawn_arrow(Vector2(450, 250), Vector2(4, -3))
	await Debug.step(20)
	check(g.in_world(ar) and ar.linear_velocity.y > -180 + 250, "arrow follows gravity arc")
	check(ar.lock_rotation and ar.continuous_cd == RigidBody2D.CCD_MODE_CAST_SHAPE, "arrow uses fixed inertia and CCD")
	check(ar.collision_mask & C.L_ENEMY == 0, "enemy arrows exclude friendly bodies")
	# Drive a projectile through actual player collision/deferred damage, then to lethal cause.
	await fresh()
	var hp: int = g.player.p.hp
	ar = g.enemy_ai.spawn_arrow(g.player.wpt(g.player.loc.torso) + Vector2(90, -3), Vector2(-13, 0))
	await Debug.step(15)
	check(g.player.p.hp == hp - 22 and g.player.p.cause == "arrow", "real arrow contact deals22 with arrow cause")
	check(g.enemy_ai.arrows.is_empty() and g.enemy_ai.stuck.size() == 1, "real player hit removes missile and sticks arrow")
	if not g.enemy_ai.stuck.is_empty():
		var entry = g.enemy_ai.stuck[0]
		var before: Dictionary = g.enemy_ai.stuck_pose(entry)
		g.player.global_position += Vector2(10, 0)
		var after: Dictionary = g.enemy_ai.stuck_pose(entry)
		check(is_equal_approx(after.pos.x - before.pos.x, 10), "embedded arrow follows host body")
	g.player.p.hp = 22
	ar = g.enemy_ai.spawn_arrow(g.player.wpt(g.player.loc.torso) + Vector2(90, -3), Vector2(-13, 0))
	await Debug.step(15)
	check(not g.player.p.alive and g.player.p.cause == "arrow", "lethal real arrow keeps death cause")
	# Static and barrel contacts: arrows stick, never arm barrels (unlike bullets).
	await fresh()
	var barrel: GBody = g.builder.barrel(350, 560)
	ar = g.enemy_ai.spawn_arrow(Vector2(280, 540), Vector2(13, 0))
	await Debug.step(12)
	check(not barrel.p.triggered and g.enemy_ai.stuck.size() == 1, "arrow embeds in barrel without triggering it")
	ar = g.enemy_ai.spawn_arrow(Vector2(550, 470), Vector2(0, 13))
	await Debug.step(12)
	check(g.enemy_ai.stuck.size() == 2 and not g.enemy_ai.stuck[-1].has("body"), "arrow sticks in static terrain")
	for i in 70:
		g.enemy_ai.stick_arrow(g.statics[0], Vector2(i, 560), 0)
	check(g.enemy_ai.stuck.size() == 60, "stuck arrow budget60")
	# Expiry and level cleanup.
	ar = g.enemy_ai.spawn_arrow(Vector2(500, 200), Vector2.ZERO)
	ar.p.born = g.sim - 301
	await Debug.step(2)
	check(not g.in_world(ar), "arrows expire after300 ticks")
	await fresh()
	check(g.enemy_ai.stuck.is_empty() and g.enemy_ai.arrows.is_empty(), "new level clears arrows and embedded visuals")
	# Ballistic search prefers a high arc over cover, then draws18 ticks before release.
	var low := g.enemy_ai.solve_lob(Vector2(780, 500), Vector2(100, 530), [13, 15, 17, 19], false)
	var high := g.enemy_ai.solve_lob(Vector2(780, 500), Vector2(100, 530), [13, 15, 17, 19], true)
	check(not low.is_empty() and not high.is_empty() and low.degrees < 38 and high.degrees >= 38, "lob solver selects low/high cover arcs")
	await Debug.start_level(18, ArcherLevel.DATA)
	await Debug.step(300)
	check(g.player.p.alive and g.alive_count() == 3, "prototype level19 stable300 ticks")
	for t in 400:
		await Debug.step(1)
		var fired := false
		for ev in Debug.events:
			if ev.kind == "arrow_fired":
				check(ev.draw_ticks == 18 and ev.speed in [13, 15, 17, 19], "real AI18-tick draw and prototype speed")
				fired = true
		if fired:
			break
	var did_fire := false
	for ev in Debug.events:
		if ev.kind == "arrow_fired": did_fire = true
	check(did_fire, "prototype archers fire at player")
	var known := [[15, 1.0, "grenade"], [5, 0.5, "grenade"]]
	var result: Dictionary
	if "--search" in OS.get_cmdline_user_args():
		result = await solve_level()
	else:
		result = await run_shots(known)
		result.seq = known
		if not result.win:
			known = [[15, 0.9, "grenade"], [5, 0.5, "grenade"]]
			result = await run_shots(known)
			result.seq = known
	check(result.win and result.seq.size() <= 5, "level19 clearable within original ammo: %s" % result)
	print("ARCHER level19: ", result)
	for failure in fails:
		print("  FAIL ", failure)
	print("ARCHER RESULT: ", "PASS" if fails.is_empty() else "FAIL")
	await TestUtil.finish(self, 0 if fails.is_empty() else 1)

func run_shots(seq: Array) -> Dictionary:
	await Debug.start_level(18, ArcherLevel.DATA)
	for shot in seq:
		if g.state != "play": break
		var a := deg_to_rad(shot[0])
		await TestUtil.shoot_active(g, cos(a), -sin(a), shot[1], shot[2])
	if g.state == "play": await TestUtil.settle(g, 180)
	if g.state == "play" and g.alive_count() == 0: await Debug.step(2)
	return {"win": g.state == "won", "alive": g.alive_count(), "player": g.player.p.alive}

func solve_level() -> Dictionary:
	var seq := []
	var tried := 0
	for step in 5:
		var best := []
		var best_alive := 999
		var ammo: Dictionary = ArcherLevel.DATA.ammo.duplicate()
		for shot in seq: ammo[shot[2]] -= 1
		for weapon in ["grenade", "rocket"]:
			if ammo[weapon] <= 0: continue
			for angle in [5, 15, 25, 35, 45, 55, 65, 75]:
				for power in [0.5, 0.7, 0.9, 1.0]:
					var candidate: Array = seq + [[angle, power, weapon]]
					var r := await run_shots(candidate)
					tried += 1
					if r.win: return {"win": true, "seq": candidate, "tried": tried}
					if r.player and r.alive < best_alive:
						best_alive = r.alive
						best = candidate
		if best.is_empty(): break
		seq = best
	return {"win": false, "seq": seq, "tried": tried}
