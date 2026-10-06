extends ContentSearch
const NUMBERS := [26,27,28,29,30,32]
const SHOTS := {26:[[20,0.9,"grenade"],[5,0.9,"grenade"]],27:[[75,1.0,"grenade"]],28:[[5,0.7,"grenade"]],29:[[15,1.0,"grenade"],[15,0.7,"grenade"]],30:[[55,0.7,"grenade"],[5,0.5,"grenade"],[75,0.8,"grenade"]],32:[[5,1.0,"grenade"]]}
func _ready() -> void:
	if "--bridge" in OS.get_cmdline_user_args(): await bridge()
	elif "--idle" in OS.get_cmdline_user_args(): await idle()
	else:
		await TestUtil.boot(self)
		g=Debug.game
		var known := SHOTS
		for n in NUMBERS:
			var r: Dictionary
			if known.has(n):
				r=await run_shots(n-1,known[n])
				if not r.win: r=await solve(n-1)
			else: r=await solve(n-1)
			print("CONTENT L",n," ",JSON.stringify(r))
			if r.win: solutions[str(n)]=r.seq
			else: failures.append(n)
		print("CONTENT SOLUTIONS ",JSON.stringify(solutions))
		print("CONTENT RESULT: ","PASS" if failures.is_empty() else "FAIL "+str(failures))
		await TestUtil.finish(self,0 if failures.is_empty() else 1)
func idle() -> void:
	await TestUtil.boot(self)
	g=Debug.game
	for n in NUMBERS:
		await Debug.start_level(n-1)
		var alive0 := g.alive_count()
		var poses := {}
		for b in g.bodies: poses[b]=b.global_position
		await Debug.step(300)
		var max_d := 0.0
		var max_speed := 0.0
		for b in g.bodies:
			if poses.has(b): max_d=maxf(max_d,b.global_position.distance_to(poses[b]))
			max_speed=maxf(max_speed,b.linear_velocity.length())
		print("MIXED IDLE L",n," alive=",alive0,"->",g.alive_count()," hp=",g.player.p.hp," player=",g.player.p.alive," cause=",g.player.p.get("cause","")," state=",g.state," drift=",max_d," speed=",max_speed," deaths=",TestUtil.deaths())
	await TestUtil.finish(self,0)

func bridge() -> void:
	await TestUtil.boot(self)
	g=Debug.game
	var r := await run_shots(28,[[65,0.8,"grenade"],[5,0.9,"grenade"]])
	print("BRIDGE preferred ",JSON.stringify(r))
	if not r.win:
		r=await solve(28,[5,15,25,35,45,55,65,75],[0.5,0.7,0.9,1.0])
	print("BRIDGE RESULT ",JSON.stringify(r))
	await TestUtil.finish(self,0 if r.win else 1)
