extends Node
var g: Game
var failures := []
func expect(ok: bool, message: String) -> void:
	print("BOSS ",message,": ","PASS" if ok else "FAIL")
	if not ok: failures.append(message)
func fixture(opts: Dictionary, x := 650.0, y := 650.0) -> Dictionary:
	return {"name":"Boss test","view":[0,100,1000,650],"ammo":{"grenade":5,"rocket":5},"par":1,"alert_at":99999,"build":[["ground",0,1000,650],["enemy",x,y,opts]],"player":[100,650]}
func move(body: GBody, pos: Vector2) -> void:
	body.global_position=pos
	PhysicsServer2D.body_set_state(body.get_rid(),PhysicsServer2D.BODY_STATE_TRANSFORM,Transform2D(body.rotation,pos))
	body.linear_velocity=Vector2.ZERO
func _ready() -> void:
	await TestUtil.boot(self)
	g=Debug.game
	await Debug.start_level(30)
	var titan: GBody=g.enemies[0]
	expect(titan.parts.size()==5 and titan.mass>20 and titan.inertia>100000,"titan compound and inertia multiplier")
	await Debug.step(300)
	expect(g.player.p.hp==100 and titan.p.alive and titan.position.x<800,"titan introduction survives300 and chases after alert60")
	await Debug.start_level(32)
	var dragon: GBody=g.enemies[0]
	expect(dragon.parts.size()==3 and dragon.loc.has("mouth"),"dragon body and mouth anchors")
	await Debug.step(300)
	expect(dragon.p.alive and g.player.p.hp==90 and g.player.p.cause=="fire" and dragon.position.distance_to(Vector2(dragon.p.hx,dragon.p.hy))<100,"dragon introduction hover300 and source fire damage90HP")
	await Debug.start_level(0,fixture({"titan":true},650,350))
	titan=g.enemies[0]
	titan.gravity_scale=0
	titan.linear_velocity=Vector2.ZERO
	var armored: float = 32*0.12*C.STEP/titan.mass
	g.explode(titan.wpt(titan.loc.head),110,32,null,"self")
	await Debug.step(1)
	expect(absf(titan.linear_velocity.length()-armored)<1.0,"titan armor applies0.12 impulse multiplier")
	expect(titan.p.alive,"head blast cannot kill armored titan")
	g.explode(titan.wpt(titan.loc.core)+Vector2(-39,0),110,32,null,"self")
	expect(not titan.p.alive,"blast within40px core kills titan")
	await Debug.start_level(0,fixture({"titan":true}))
	titan=g.enemies[0]
	titan.prev_v=Vector2(0,30)*C.STEP
	g.hit(titan,g.statics[0])
	expect(not titan.p.dying,"titan body impact cannot enqueue normal death")
	titan.rotation=1.1
	await Debug.step(1)
	expect(titan.p.alive,"titan ignores ordinary topple death")
	await Debug.start_level(0,fixture({"titan":true},190))
	titan=g.enemies[0]
	g.L.alert_at=0
	await Debug.step(16)
	expect(g.player.p.hp==100,"titan16tick smash is deferred")
	await Debug.step(1)
	expect(g.player.p.hp==62 and g.player.p.cause=="titan","titan smash causes38HP at tick17")
	await Debug.start_level(0,fixture({"dragon":true},650,330))
	dragon=g.enemies[0]
	g.explode(dragon.wpt(dragon.loc.mouth),125,30,null,"barrel")
	expect(dragon.p.alive,"closed mouth rejects blast")
	dragon.p.mouth_open=true
	g.explode(dragon.wpt(dragon.loc.mouth)+Vector2(-31,0),125,30,null,"barrel")
	expect(not dragon.p.alive,"source permits any blast within32px open mouth")
	await Debug.start_level(0,fixture({"dragon":true},650,330))
	dragon=g.enemies[0]
	g.L.alert_at=0; dragon.p.next=1
	await Debug.step(1)
	expect(dragon.p.breath=="charge","dragon enters charge on alert")
	await Debug.step(64)
	expect(dragon.p.breath=="charge","dragon charge lasts65ticks")
	await Debug.step(1)
	expect(dragon.p.breath=="fire","dragon begins fire after65ticks")
	await Debug.step(9)
	expect(g.bosses.flames.size()==3,"dragon emits flame every3ticks")
	var fl: GBody=g.bosses.flames[-1]
	expect(is_equal_approx(fl.gravity_scale,0.15) and fl.collision_mask==0 and fl.get_child(-1) is Area2D,"flame gravity0.15 and sensor avoids physical shove")
	await Debug.step(61)
	expect(dragon.p.breath=="idle" and dragon.p.next>g.sim,"dragon fire lasts70ticks and schedules150to209cooldown")
	await Debug.start_level(0,fixture({"dragon":true},650,330))
	dragon=g.enemies[0]
	dragon.p.breath="charge"; dragon.p.bt=g.sim
	Debug.set_aim(1,-0.3,0.7,"grenade")
	expect(Debug.fire(),"gulp uses real launcher grenade")
	move(g.projectiles[0],dragon.wpt(dragon.loc.mouth))
	await Debug.step(1)
	var gulp_tick: int=g.sim
	expect(dragon.p.breath=="gulp" and g.projectiles.is_empty(),"open mouth consumes grenade within30px")
	await Debug.step(39)
	expect(dragon.p.alive,"gulp remains alive39ticks")
	await Debug.step(1)
	expect(not g.in_world(dragon) and g.sim-gulp_tick==40,"gulp kills after40ticks")
	await Debug.start_level(0,fixture({"dragon":true},650,330))
	var portal_data := fixture({"dragon":true},650,330)
	portal_data.portals=[{"a":[400,300],"b":[800,200]}]
	await Debug.start_level(0,portal_data)
	fl=g.bosses.spawn_flame(Vector2(400,300),Vector2(4,-2))
	await Debug.step(1)
	expect(fl.position.distance_to(Vector2(800,200))<10 and fl.p.in_p==1 and fl.linear_velocity.x>200,"flame traverses portals with velocity preserved")
	await Debug.start_level(0,fixture({"dragon":true},650,330))
	var hp: int=g.player.p.hp
	var player_pos := g.player.wpt(g.player.loc.torso)
	fl=g.bosses.spawn_flame(player_pos,Vector2.ZERO)
	await Debug.step(3)
	expect(g.player.p.hp==hp-5 and g.player.p.cause=="fire" and not g.in_world(fl),"real sensor flame causes5HP deferred damage")
	g.bosses.spawn_flame(g.player.wpt(g.player.loc.torso),Vector2.ZERO)
	await Debug.step(3)
	expect(g.player.p.hp==hp-5,"fire cooldown suppresses hits for9ticks")
	await Debug.step(7)
	g.bosses.spawn_flame(g.player.wpt(g.player.loc.torso),Vector2.ZERO)
	await Debug.step(3)
	expect(g.player.p.hp==hp-10,"fire cooldown releases after9ticks")
	fl=g.bosses.spawn_flame(Vector2(500,100),Vector2.ZERO)
	g.remove_body(fl)
	expect(not g.bosses.flames.has(fl),"removal cleans missile tracking")
	for shot in [[30,1,0.7,"rocket"],[32,64,0.7,"grenade"]]:
		await Debug.start_level(shot[0])
		var angle := deg_to_rad(shot[1])
		Debug.set_aim(cos(angle),-sin(angle),shot[2],shot[3])
		expect(Debug.fire(),"introduction%d real shot"%[shot[0]+1])
		await Debug.step(250)
		expect(g.state=="won" and g.shots==1 and g.player.p.hp==100,"introduction%d clears within original par1"%[shot[0]+1])
	print("BOSS RESULT: ","PASS" if failures.is_empty() else "FAIL "+str(failures))
	await TestUtil.finish(self,0 if failures.is_empty() else 1)
