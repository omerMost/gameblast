class_name BossAI
extends RefCounted
## Prototype monster AI. Flame sensors use Area2D so contact cannot shove solids.
var game: Game
var flames := []
func _init(g: Game) -> void: game = g
func reset() -> void: flames.clear()
func label(p: Vector2, text: String, color: Color) -> void:
	game.particles.append({"t":"text","x":p.x,"y":p.y,"vx":0.0,"vy":-70.0,"life":0.0,"max":1.2,"text":text,"c":color})
func blast_weakpoint(e: GBody, pos: Vector2, dv: Vector2) -> bool:
	var point: Vector2 = e.wpt(e.loc.core if e.p.titan else e.loc.mouth)
	if pos.distance_to(point) < (40 if e.p.titan else 32) and (e.p.titan or e.p.get("mouth_open",false)):
		kill_boss(e,dv)
		return true
	return false
func kill_boss(e: GBody, dv := Vector2.ZERO) -> void:
	if not game.in_world(e) or not e.p.alive: return
	var titan: bool = e.p.titan
	var c := e.wpt(e.loc.core if titan else e.loc.body)
	var h := e.wpt(e.loc.head)
	e.p.alive = false
	game.make_ragdoll(e,Vector2(dv.x*0.3,-3) if titan else Vector2(0,-2),true,2.2 if titan else 1.9)
	game.fx_explosion(c,120 if titan else 150,40 if titan else 45)
	if not titan: game.fx_explosion(h,90,30)
	game.shake = minf(24,game.shake+18)
	game.flash_a = maxf(game.flash_a,0.3 if titan else 0.35)
	label(c+Vector2(0,-90) if titan else h+Vector2(0,-50),"CORE HIT!" if titan else "BOOM!",Color("#ffb347"))
	game.sound_requested.emit("boom",1.2 if titan else 1.3)
	game.sound_requested.emit("roar",1.0)
	game.hud_changed.emit()
	Debug.log_event("boss_killed", {"titan":titan})
func before_update(e: GBody) -> bool:
	var a := C.norm_a(e.rotation)
	var w := e.angular_velocity/C.STEP
	if e.p.titan:
		if absf(a)<1.3: e.angular_velocity=(w*0.7-a*0.1)*C.STEP
		return true
	if not e.p.dragon: return false
	var calm := 0.35 if e.p.breath != "idle" else 1.0
	var t: float = game.sim/60.0+e.p.ph
	var target := Vector2(e.p.hx+sin(t*0.45)*70*calm,e.p.hy+sin(t*0.9)*26*calm+sin(game.sim*0.18)*3)
	var acc := ((target-e.global_position)*0.0016-e.linear_velocity/C.STEP*0.06).limit_length(0.35)
	if absf(a)<0.9:
		e.apply_central_impulse(e.mass*(acc-Vector2(0,C.GS))*C.STEP)
		e.angular_velocity=(w*0.8-a*0.05)*C.STEP
	return true
func ground_at(pos: Vector2, e: GBody) -> bool:
	var q := PhysicsPointQueryParameters2D.new()
	q.position=pos
	q.collision_mask=C.L_STATIC|C.L_SOLID|C.L_ENEMY
	q.exclude=[e.get_rid()]
	return not game.get_world_2d().direct_space_state.intersect_point(q,1).is_empty()
func update(e: GBody) -> void:
	if e.p.titan: update_titan(e)
	else: update_dragon(e)
func update_titan(e: GBody) -> void:
	if absf(C.norm_a(e.rotation))>0.6: return
	var pl := e.p
	var foot := e.wpt(e.loc.feet)
	var pf := game.player.wpt(game.player.loc.feet)
	var dx := pf.x-foot.x
	var dy := pf.y-foot.y
	var dir := signf(dx) if dx != 0 else -1.0
	var grounded := ground_at(foot+Vector2(-28,9),e) or ground_at(foot+Vector2(28,9),e) or ground_at(foot+Vector2(0,9),e)
	if absf(dx)<100 and absf(dy)<70:
		if game.sim>pl.get("swing_cd",0):
			pl.swing_cd=game.sim+80
			pl.swing=game.sim
			game.sound_requested.emit("swing",1.0)
			game.later_body(16,e,smash,[dir])
		if grounded: e.linear_velocity.x *= 0.7
		return
	if not grounded: return
	e.linear_velocity.x += (dir*1.5*C.STEP-e.linear_velocity.x)*0.2
	pl.step_t=pl.get("step_t",0)+1
	if pl.step_t%32==0:
		game.shake=maxf(game.shake,3.5)
		game.sound_requested.emit("stomp",1.0)
		smoke(foot,4,25,50,40,5,6,10)
	pl.stuck=pl.get("stuck",0)+1 if absf(e.linear_velocity.x/C.STEP)<0.5 else 0
	if game.sim>pl.get("jump_cd",0):
		var fx := foot.x+dir*44
		var wx := foot.x+dir*85
		var wall := ground_at(Vector2(wx,foot.y-25),e) or ground_at(Vector2(wx,foot.y-60),e) or ground_at(Vector2(fx,foot.y-25),e)
		var gap := true
		for d in range(6,91,12):
			if ground_at(Vector2(fx,foot.y+d),e): gap=false; break
		if wall or gap or pl.stuck>30:
			pl.stuck=0
			e.linear_velocity=Vector2(dir*(4.6 if gap else 3.4),-10.8)*C.STEP
			pl.jump_cd=game.sim+60
			game.sound_requested.emit("jump",1.0)
func smash(e: GBody, dir: float) -> void:
	if not game.in_world(e) or not e.p.alive or not game.player.p.alive: return
	var f := e.wpt(e.loc.feet)
	var p := game.player.wpt(game.player.loc.feet)
	if absf(p.x-f.x)<125 and absf(p.y-f.y)<90:
		game.damage_player(38,Vector2(dir*6,-4),null,"titan")
		if game.in_world(game.player): game.player.apply_central_impulse(Vector2(dir*0.012,-0.006)*C.FORCE_IMPULSE)
		game.shake=minf(22,game.shake+12)
		game.sound_requested.emit("smash",1.0)
		Debug.log_event("titan_smash",{"delay":game.sim-e.p.swing})
	smoke(f+Vector2(dir*60,-4),10,0,90,80,10,8,14)
func update_dragon(e: GBody) -> void:
	var pl := e.p
	if pl.breath=="gulp": return
	if pl.next==0:
		pl.next=game.sim+game.rng.randi_range(50,119)
		pl.alert_at=game.sim
		game.sound_requested.emit("alert",1.0)
	if pl.breath=="idle" and game.sim>=pl.next:
		pl.breath="charge"; pl.bt=game.sim
		game.sound_requested.emit("roar",1.0)
	elif pl.breath=="charge" and game.sim-pl.bt>=65:
		pl.breath="fire"; pl.bt=game.sim
		var m := e.wpt(e.loc.mouth)
		var target := game.player.wpt(game.player.loc.torso)
		var sol := game.enemy_ai.solve_lob(m,target,[11,13,15],false,C.GS*0.15)
		pl.fa=sol.a if not sol.is_empty() else (target-m).angle()
		pl.fs=sol.speed if not sol.is_empty() else 12
	elif pl.breath=="fire":
		if (game.sim-pl.bt)%3==0:
			var dir := Vector2.from_angle(pl.fa+game.rnd(-0.07,0.07))
			spawn_flame(e.wpt(e.loc.mouth)+dir*10,dir*pl.fs+Vector2(game.rnd(-0.5,0.5),game.rnd(-0.5,0.5)))
			if (game.sim-pl.bt)%12==0: game.sound_requested.emit("fire",1.0)
		if game.sim-pl.bt>=70: pl.breath="idle"; pl.next=game.sim+game.rng.randi_range(150,209)
func spawn_flame(pos: Vector2, velocity: Vector2) -> GBody:
	var fl := game.builder._body("flame",pos)
	fl.add_circle(Vector2.ZERO,7)
	fl.mass=PI*49*0.001
	fl.matter_inertia([fl.mass])
	fl.gravity_scale=0.15
	fl.collision_layer=0; fl.collision_mask=0
	fl.p={"born":game.sim,"done":false,"in_p":-1}
	var sensor := Area2D.new()
	sensor.collision_layer=C.L_MISSILE
	sensor.collision_mask=C.M_MISSILE
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new(); circle.radius=7
	shape.shape=circle; sensor.add_child(shape); fl.add_child(sensor)
	sensor.body_entered.connect(func(other: Node): game.on_contact(fl,other))
	game.add_body(fl)
	fl.linear_velocity=velocity*C.STEP; fl.prev_v=fl.linear_velocity
	flames.append(fl)
	Debug.log_event("flame",{"born":game.sim})
	return fl
func contact_flame(fl: GBody, other: Node) -> void:
	if game.settling or fl.p.done: return
	var kind := game._kind(other)
	if kind=="player" or other is StaticBody2D or kind in ["block","boulder","barrel"]:
		fl.p.done=true
		game.later_body(0,fl,flame_hit,[other])
func flame_hit(fl: GBody, other) -> void:
	if not game.in_world(fl): return
	var p := fl.global_position
	var v := fl.linear_velocity/C.STEP
	game.remove_body(fl)
	if not is_instance_valid(other): return
	if game._kind(other)=="player" and other.p.alive and game.sim>=other.p.get("fire_cd",0):
		other.p.fire_cd=game.sim+9
		game.damage_player(5,v,p,"fire")
	elif game._kind(other)=="barrel" and not other.p.triggered: game.trigger(other)
func update_missiles_and_gulp() -> void:
	for fl in flames.duplicate():
		if game.sim-fl.p.born>75 or fl.global_position.y>1600: game.remove_body(fl)
	for e in game.enemies.duplicate():
		if not e.p.alive or not e.p.dragon: continue
		e.p.mouth_open=e.p.breath in ["charge","fire"]
		if not e.p.mouth_open: continue
		var mouth: Vector2 = e.wpt(e.loc.mouth)
		for pr in game.projectiles.duplicate():
			if pr.kind=="grenade" and pr.global_position.distance_to(mouth)<30:
				game.remove_body(pr)
				e.p.breath="gulp"; e.p.mouth_open=false; e.p.gulp=game.sim
				label(mouth+Vector2(0,-40),"GULP!",Color.WHITE)
				game.sound_requested.emit("gulp",1.0)
				game.later_body(40,e,kill_boss)
				Debug.log_event("gulp",{"sim":game.sim})
				break

func smoke(pos: Vector2, count: int, spread: float, speed: float, up: float, low: float, small: float, large: float) -> void:
	for i in count:
		game.particles.append({"t":"smoke","x":pos.x+game.frnd(-spread,spread),"y":pos.y,"vx":game.frnd(-speed,speed),"vy":game.frnd(-up,-low),"r":game.frnd(small,large),"life":0.0,"max":game.frnd(0.5,0.9),"drag":2.0})
