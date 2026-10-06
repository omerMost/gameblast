extends Node
var g: Game
var fails := []
const FLAT := {"name":"Knight contact", "view":[0,270,980,450], "ammo":{"grenade":4,"rocket":2}, "par":2,"alert_at":99999,"build":[["ground",0,1000,560],["enemy",650,560,{"knight":true}]]}
func check(ok: bool, msg: String) -> void:
	if not ok: fails.append(msg)
func fresh() -> GBody:
	await Debug.start_level(19,FLAT)
	return g.enemies[0]
func _ready() -> void:
	await TestUtil.boot(self)
	g = Debug.game
	var e: GBody = await fresh()
	check(e.parts.size()==4 and e.loc.has("extra") and is_equal_approx(e.mass,3.186929158),"compound shield mass")
	var expected_inertia := 16.0 * ((0.96*(30*30+8*8)+0.96*(24*24+40*40)+0.736*(8*8+46*46))/12.0 + (PI*169*0.001)*169/2.0)
	check(is_equal_approx(e.inertia, expected_inertia),"compound Matter inertia with knight4multiplier")
	check(g.player.lock_rotation,"player stays upright")
	var pos := e.global_position
	g.explode(pos+Vector2(-45,0),110,32,null,"self")
	await Debug.step(5)
	check(e.p.alive and e.linear_velocity.length()>0,"front shield survives real blast and receives reduced impulse")
	e = await fresh()
	g.explode(e.global_position+Vector2(45,0),110,32,null,"self")
	await Debug.step(2)
	check(not g.in_world(e),"rear blast bypasses shield")
	e = await fresh()
	g.explode(e.global_position+Vector2(0,-60),110,32,null,"self")
	await Debug.step(2)
	check(not g.in_world(e),"overhead blast bypasses front shield")
	var shield: GBody
	var sword: GBody
	for body in g.bodies:
		if body.p.get("look","")=="shield": shield=body
		if body.p.get("look","")=="sword": sword=body
	check(shield!=null and sword!=null,"death drops real sword and shield")
	if sword!=null:
		check(sword.parts[0].size==Vector2(4,36) and sword.p.hp==1e9 and sword.inertia>0,"sword dimensions durability inertia")
		var before := sword.global_position
		await Debug.step(8)
		check(sword.global_position.distance_to(before)>1,"dropped sword participates in physics")
	# Actual physics run approaches the player, then jumps the raised player's ledge.
	await Debug.start_level(19)
	await Debug.step(300)
	check(g.alive_count()==2 and g.player.p.alive and g.player.p.hp==100,"level20 moving knights survive bounded300tick idle")
	check(g.enemies[0].global_position.x<800,"knights run toward player")
	var jumped := false
	for ev in Debug.events:
		if ev.kind=="knight_jump": jumped=true
	check(jumped,"knights jump real obstacle")
	# The raised player triggers the source ledge climb velocity and45tick cooldown.
	e = await fresh()
	e.global_position.x = g.player.global_position.x + 120
	g.player.global_position.y -= 70
	await Debug.step(1)
	g.enemy_ai.update_knight(e)
	check(e.linear_velocity==Vector2(-2.7,-8.8)*C.STEP and e.p.get("jump_cd",0)==g.sim+45,"ledge climb source velocity/cooldown")
	# Place on same ground within sword reach; verify delayed hit and cooldown.
	var melee: Dictionary = FLAT.duplicate(true)
	melee.build[1][1] = 145
	await Debug.start_level(19,melee)
	e = g.enemies[0]
	await Debug.step(1)
	g.enemy_ai.update_knight(e)
	await Debug.step(8)
	check(g.player.p.hp==100,"sword waits9ticks")
	await Debug.step(1)
	check(g.player.p.hp==80 and g.player.p.cause=="sword","sword20damage with cause after9ticks")
	g.enemy_ai.update_knight(e)
	await Debug.step(20)
	check(g.player.p.hp==80,"swing55tick cooldown")
	var result := await solve()
	check(result.win,"level20 real shots clear within original ammo")
	print("KNIGHT solution: ",result)
	for f in fails: print("  FAIL ",f)
	print("KNIGHT RESULT: ","PASS" if fails.is_empty() else "FAIL")
	await TestUtil.finish(self,0 if fails.is_empty() else 1)
func run_shots(seq: Array) -> Dictionary:
	await Debug.start_level(19)
	for shot in seq:
		if g.state!="play": break
		var a := deg_to_rad(float(shot[0]))
		await TestUtil.shoot_active(g,cos(a),-sin(a),shot[1],shot[2])
	if g.state=="play": await TestUtil.settle(g,180)
	return {"win":g.state=="won","alive":g.alive_count(),"player":g.player.p.alive,"seq":seq}
func solve(force_search := false) -> Dictionary:
	if not force_search and not "--search" in OS.get_cmdline_user_args(): return await run_shots([[5,0.9,"grenade"],[25,0.7,"grenade"]])
	var seq := []
	for step in 6:
		var best := {}
		var ammo: Dictionary = KnightLevel.DATA.ammo.duplicate()
		for shot in seq: ammo[shot[2]]-=1
		for weapon in ["grenade","rocket"]:
			if ammo[weapon]<=0: continue
			for angle in [5,15,25,35,45,55,65,75]:
				for power in [0.5,0.7,0.9,1.0]:
					var r := await run_shots(seq+[[angle,power,weapon]])
					if r.win: return r
					if r.player and (best.is_empty() or r.alive<best.alive): best=r
		if best.is_empty(): break
		seq=best.seq
	return {"win":false,"seq":seq}
