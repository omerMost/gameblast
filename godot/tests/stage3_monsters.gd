extends ContentSearch
## Recorded real-input clears. BR_SEARCH=1 regenerates; BR_LEVEL selects one.
const SHOTS := {
34:[[0,0.7,"rocket"],[75,0.9,"grenade"]],
35:[[15,0.5,"rocket"],[35,0.9,"grenade"]],
36:[[0,0.5,"grenade"],[35,1.0,"grenade"],[25,0.9,"grenade"]],
37:[[0,0.5,"grenade"],[0,0.5,"grenade"],[75,0.9,"grenade"]],
38:[[15,0.9,"grenade"],[5,0.5,"rocket"]],
39:[[0,0.9,"grenade"],[35,0.7,"grenade"]],
40:[[15,0.7,"rocket"],[35,1.0,"grenade"],[0,0.5,"rocket"]]
}
func _ready() -> void:
	await TestUtil.boot(self)
	g=Debug.game
	var wanted := OS.get_environment("BR_LEVEL").to_int()
	for number in ([wanted] if wanted else [34,35,36,37,38,39,40]):
		tried=0
		var result: Dictionary
		if OS.get_environment("BR_SEARCH") == "1" or not SHOTS.has(number):
			result = await solve(number-1,[0,5,15,25,35,45,55,65,75],[0.5,0.7,0.9,1.0])
		else: result = await run_shots(number-1,SHOTS[number])
		for event in Debug.events:
			if event.kind in ["damage","player_died"] and not C.CAUSES.has(event.cause): result.win=false
		for weapon in g.ammo:
			if g.ammo[weapon]<0: result.win=false
		if g.shots>int(g.L.ammo.get("grenade",0))+int(g.L.ammo.get("rocket",0)): result.win=false
		print("CONTENT L",number," ",JSON.stringify(result)," tried=",tried)
		if result.win: solutions[str(number)]=result.seq
		else: failures.append(number)
	print("CONTENT SOLUTIONS ",JSON.stringify(solutions))
	print("CONTENT RESULT: ","PASS" if failures.is_empty() else "FAIL "+str(failures))
	await TestUtil.finish(self,0 if failures.is_empty() else 1)
