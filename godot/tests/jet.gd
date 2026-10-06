extends Node
var g: Game
var fails := []
const FLAT := {"name":"Jet test","view":[0,200,960,500],"ammo":{"grenade":3,"rocket":3},"par":3,"alert_at":99999,"build":[["ground",0,1000,560],["enemy",650,350,{"jet":true}]]}
func check(ok: bool, msg: String) -> void:
	if not ok: fails.append(msg)
func fresh() -> GBody:
	await Debug.start_level(24,FLAT)
	return g.enemies[0]
func _ready() -> void:
	await TestUtil.boot(self)
	g=Debug.game
	var e: GBody=await fresh()
	check(e.parts.size()==4 and e.parts[-1].size==Vector2(12,24) and is_equal_approx(e.mass,3.026929158),"compound pack dimensions mass")
	var initial := e.global_position
	await Debug.step(300)
	check(e.global_position.distance_to(initial)<70 and e.p.alive,"real hover bounded300ticks")
	check(g.player.lock_rotation,"player rotation locked")
	# Actual airborne missile, precise fuse and enemy-cause explosion.
	e=await fresh()
	var nade := g.enemy_ai.spawn_nade(Vector2(450,250),Vector2(3,-2))
	check(nade.p.fuse==g.sim+110 and is_equal_approx(nade.angular_velocity,12),"nade110tick fuse and source spin")
	check(nade.collision_mask==C.M_MISSILE and nade.inertia>0 and is_equal_approx(nade.physics_material_override.bounce,0.4),"nade enemy mask inertia restitution")
	var ring := g.enemy_ai.telegraph(nade)
	check(ring.radius==93.75 and is_equal_approx(ring.alpha,0.25),"source telegraph radius initial alpha")
	await Debug.step(109)
	check(g.in_world(nade) and g.enemy_ai.nades.size()==1,"nade survives109ticks")
	check(nade.linear_velocity.y>-120 and is_equal_approx(g.enemy_ai.telegraph(nade).alpha,0.25+0.45*109/110.0),"real gravity and telegraph countdown")
	await Debug.step(1)
	check(not g.in_world(nade) and g.enemy_ai.nades.is_empty(),"nade explodes on110 and cleans helper list")
	var exploded := false
	for ev in Debug.events:
		if ev.kind=="explode" and ev.cause=="enemy" and ev.power==30: exploded=true
	check(exploded,"nade routes blast through Game with enemy cause power30")
	e=await fresh()
	nade=g.enemy_ai.spawn_nade(g.player.global_position,Vector2.ZERO)
	nade.p.fuse=g.sim+1
	await Debug.step(1)
	check(g.player.p.hp==61 and g.player.p.cause=="enemy","real enemy nade deals39blastdamage atfullfalloff")
	# Source fuel explosion waits14 ticks, radius80 power20, uses dead body's velocity.
	e=await fresh()
	var origin := e.wpt(e.loc.ref)
	e.linear_velocity=Vector2(120,0)
	g.kill(e,Vector2.ZERO,false)
	await Debug.step(13)
	check(Debug.events.filter(func(ev): return ev.kind=="explode").is_empty(),"tank no blast before14")
	await Debug.step(1)
	var tank := {}
	for ev in Debug.events:
		if ev.kind=="explode": tank=ev
	check(not tank.is_empty() and tank.power==20 and tank.cause=="enemy" and absf(tank.x-origin.x-28)<0.01,"tank14tick prediction explosion")
	# Actual AI lob release with source10tick toss windup and220..299 cooldown.
	e=await fresh()
	e.p.next=g.sim+1
	await Debug.step(1)
	g.enemy_ai.update_jet(e,true,g.player.wpt(g.player.loc.torso))
	check(e.p.next>=g.sim+220 and e.p.next<=g.sim+299,"jet220..299 shot cooldown")
	await Debug.step(9)
	check(g.enemy_ai.nades.is_empty(),"toss waits10ticks")
	await Debug.step(1)
	check(g.enemy_ai.nades.size()==1,"actual AI releases after10ticks")
	for ev in Debug.events:
		if ev.kind=="nade_toss": check(ev.delay==10 and ev.speed in [9,11,13,15],"source speed10tick release")
	await Debug.start_level(24)
	await Debug.step(300)
	check(g.alive_count()==3 and g.player.p.hp==100,"source level25 idle survives300")
	var result := await solve("--search" in OS.get_cmdline_user_args())
	check(result.win,"originalammo level25 real shots win")
	print("JET solution: ",result)
	for f in fails: print("  FAIL ",f)
	print("JET RESULT: ","PASS" if fails.is_empty() else "FAIL")
	await TestUtil.finish(self,0 if fails.is_empty() else 1)
func run_shots(seq: Array) -> Dictionary:
	await Debug.start_level(24)
	for shot in seq:
		if g.state!="play": break
		var a := deg_to_rad(float(shot[0]))
		await TestUtil.shoot_active(g,cos(a),-sin(a),shot[1],shot[2])
	if g.state=="play": await TestUtil.settle(g,180)
	return {"win":g.state=="won","alive":g.alive_count(),"player":g.player.p.alive,"seq":seq}
func solve(force_search := false) -> Dictionary:
	if not force_search: return await run_shots([[25,0.5,"rocket"],[25,0.5,"rocket"]])
	var seq := []
	for step in 6:
		var best := {}
		var ammo: Dictionary = JetLevel.DATA.ammo.duplicate()
		for shot in seq: ammo[shot[2]]-=1
		for weapon in ["rocket","grenade"]:
			if ammo[weapon]<=0: continue
			for angle in [5,15,25,35,45,55,65,75]:
				for power in [0.5,0.7,0.9,1.0]:
					var r := await run_shots(seq+[[angle,power,weapon]])
					if r.win: return r
					if r.player and (best.is_empty() or r.alive<best.alive): best=r
		if best.is_empty(): break
		seq=best.seq
	return {"win":false,"seq":seq}
