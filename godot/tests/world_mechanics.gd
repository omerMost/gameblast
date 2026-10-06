extends Node
var g: Game
var failures := []
func expect(ok: bool, message: String) -> void:
	print("WORLD ", message, ": ", "PASS" if ok else "FAIL")
	if not ok:
		failures.append(message)
func data(ops: Array, extra := {}) -> Dictionary:
	var d := {"name":"Mechanics", "view":[0,0,1000,800], "ammo":{"rocket":10,"grenade":10}, "par":1, "alert_at":99999, "build": [["ground",0,190,560],["ground",800,1000,650],["enemy",900,650]] + ops}
	d.merge(extra)
	return d
func _ready() -> void:
	await TestUtil.boot(self)
	g = Debug.game
	await Debug.start_level(0, data([["boulder",300,550,34,"stone"],["hang",[300,300],"stone",[0,-34]]]))
	var r: Dictionary = g.tricks.ropes[0]
	await Debug.step(120)
	var p := g.tricks.ends(r)
	expect(absf(p[0].distance_to(p[1]) - r.length) < 1, "hanging stone retains length under gravity")
	Debug.set_aim(cos(deg_to_rad(25)), -sin(deg_to_rad(25)), 1, "rocket")
	expect(Debug.fire(), "rope test launches a real rocket")
	await Debug.step(30)
	expect(r.cut, "swept projectile cuts rope")
	var before: float = r.b.global_position.y
	await Debug.step(60)
	expect(r.b.global_position.y > before + 30, "cut load falls")
	await Debug.start_level(21)
	await Debug.step(120)
	expect(g.alive_count() == 3 and g.tricks.balloons.size() == 3, "balloon raft remains occupied before shots")
	var bl: GBody = g.tricks.balloons[0]
	var y: float = bl.global_position.y
	g.tricks.cut(bl.p.rope)
	await Debug.step(30)
	expect(bl.global_position.y < y - 30, "detached balloon rises from lift")
	g.explode(bl.global_position, C.R_GREN, C.P_GREN, null, "self")
	await Debug.step(2)
	expect(not g.in_world(bl), "blast pops balloon with deferred removal")
	await Debug.start_level(0, data([["bridge",250,400,650,400,8]]))
	await Debug.step(120)
	expect(g.tricks.ropes.size() == 9 and g.tricks.ropes.all(func(link): return not link.cut), "bridge retains connected planks")
	var link: Dictionary = g.tricks.ropes[4]
	var ends := g.tricks.ends(link)
	expect(ends[0].distance_to(ends[1]) < 6, "bridge attachment lengths remain bounded")
	g.explode((ends[0] + ends[1]) / 2, C.R_GREN, C.P_GREN, null, "self")
	expect(link.cut, "blast breaks bridge links")
	await Debug.start_level(0, data([["pad",350,380,372,650]]))
	Debug.set_aim(1,0,0.6,"grenade")
	Debug.fire()
	var grenade: GBody = g.projectiles[0]
	var impact := 0.0
	var rebound := 0.0
	for i in 40:
		if not g.in_world(grenade):
			break
		if grenade.linear_velocity.x > 0:
			impact = grenade.linear_velocity.x
		else:
			rebound = -grenade.linear_velocity.x
			break
		await Debug.step(1)
	expect(impact > 100 and absf(rebound / impact - 1) < 0.1, "pad reflects real grenade with Matter restitution one")
	await Debug.start_level(0, data([], {"wells":[[450,360,0.2]]}))
	expect(g.tricks.acceleration(Vector2(350,360)).is_equal_approx(Vector2(0.2,0)), "well inverse-square acceleration")
	expect(g.tricks.acceleration(Vector2(449,360)).is_equal_approx(Vector2(0.7,0)), "well acceleration cap")
	Debug.set_aim(1,-0.25,0.4,"rocket")
	var curved := g.predict()
	var saved := g.tricks.wells.duplicate()
	g.tricks.wells.clear()
	var straight := g.predict()
	g.tricks.wells = saved
	expect(curved.size() > 10 and straight.size() > 10 and curved[10].pos.distance_to(straight[10].pos) > 3, "preview curves around well")
	Debug.fire()
	var rocket: GBody = g.projectiles[0]
	await Debug.step(33)
	expect(rocket.global_position.distance_to(curved[10].pos) < 15, "curved preview tracks real rocket")
	var body := g.builder.boulder(450,394,34)
	await Debug.step(2)
	expect(not g.in_world(body), "well swallows body at core")
	expect(g.player.p.hp == 100 and g.player.lock_rotation, "well preserves braced player")
	var next: int = g.available_levels()[5]
	Save.prog.unlocked = 1
	Save.record_win(4,3,g.level_count(),g.next_level(4))
	expect(Save.prog.unlocked == next + 1 and g.next_level(4) == next, "progression skips unported slots")
	print("WORLD RESULT: ", "PASS" if failures.is_empty() else "FAIL " + str(failures))
	await TestUtil.finish(self, 0 if failures.is_empty() else 1)
