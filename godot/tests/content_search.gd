class_name ContentSearch
extends Node
## Diagnostic search/replay uses original ammo and the real launcher only.
var g: Game
var tried := 0
var solutions := {}
var failures := []
func _ready() -> void:
	var numbers := []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="): numbers.append(int(arg.split("=")[1]))
	if numbers.is_empty():
		print("Usage: content_search.tscn -- --level=N")
		get_tree().quit(2)
	else: await check_levels(numbers)
const ANGLES := [5,15,25,35,45,55,65,75,-5,-15,0,10,20,30,40,50,60,64,70,80]
const POWERS := [0.5,0.7,0.9,1.0,0.3,0.4,0.6,0.8,0.2]
func run_shots(i: int, seq: Array) -> Dictionary:
	await Debug.start_level(i)
	var valid := true
	for shot in seq:
		if g.state != "play": break
		if shot.size() > 3: await Debug.step(int(shot[3]))
		if g.ammo.get(shot[2],0) <= 0: valid=false; break
		var a := deg_to_rad(float(shot[0]))
		valid = await TestUtil.shoot_active(g,cos(a),-sin(a),float(shot[1]),shot[2]) and valid
	if g.state == "play": await TestUtil.settle(g,180)
	for d in TestUtil.deaths():
		if not C.CAUSES.has(d.cause): valid=false
	return {"win":valid and g.state=="won" and g.player.p.alive,"alive":g.alive_count(),"hp":g.player.p.hp,"player":g.player.p.alive,"seq":seq,"shots":g.shots}
func solve(i: int, angles := ANGLES, powers := POWERS, waits := [0]) -> Dictionary:
	var level: Dictionary = Levels.LEVELS[i]
	var total: int = int(level.ammo.get("grenade",0))+int(level.ammo.get("rocket",0))
	var seq := []
	for step in total:
		var best := {}
		var ammo: Dictionary = level.ammo.duplicate()
		for shot in seq: ammo[shot[2]]-=1
		for weapon in ["grenade","rocket"]:
			if ammo.get(weapon,0)<=0: continue
			for angle in angles:
				for power in powers:
					for wait_ticks in waits:
						var shot := [angle,power,weapon]
						if wait_ticks>0: shot.append(wait_ticks)
						var r := await run_shots(i,seq+[shot])
						tried+=1
						if r.win: return r
						if r.player and (best.is_empty() or r.alive<best.alive or (r.alive==best.alive and r.hp>best.hp)): best=r
		if best.is_empty(): break
		seq=best.seq
		print("SEARCH progress L",i+1," alive=",best.alive," seq=",seq," tried=",tried)
	return {"win":false,"seq":seq}
func check_levels(numbers: Array) -> void:
	await TestUtil.boot(self)
	g=Debug.game
	for number in numbers:
		tried=0
		var result := await solve(number-1)
		print("CONTENT L",number," ",JSON.stringify(result)," tried=",tried)
		if result.win: solutions[str(number)]=result.seq
		else: failures.append(number)
	print("CONTENT SOLUTIONS ",JSON.stringify(solutions))
	print("CONTENT RESULT: ","PASS" if failures.is_empty() else "FAIL "+str(failures))
	await TestUtil.finish(self,0 if failures.is_empty() else 1)
