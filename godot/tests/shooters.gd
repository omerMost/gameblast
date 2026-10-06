extends Node
## Shooter enemies (line-of-sight bullets) using level 8 "Return fire" from the prototype
## as a fixture (it is not part of the stage-1 level list).

const RETURN_FIRE := {"name": "Return fire", "view": [0, 300, 860, 420], "ammo": {"grenade": 3, "rocket": 2}, "par": 2,
	"build": [
		["ground", 0, 190, 560], ["ground", 190, 900, 650],
		["block", 560, 650, 26, 40, "wood"], ["block", 680, 650, 26, 40, "wood"],
		["enemy", 610, 650, {"shooter": true}], ["enemy", 730, 650, {"shooter": true}], ["enemy", 800, 650],
	]}

const WALLED := {"name": "Walled", "view": [0, 300, 860, 420], "ammo": {"grenade": 1}, "par": 1,
	"build": [
		["ground", 0, 190, 560], ["ground", 190, 900, 650],
		["block", 560, 650, 30, 160, "stone"],
		["enemy", 640, 650, {"shooter": true}],
	]}


func _ready() -> void:
	await TestUtil.boot(self)
	var g: Game = Debug.game
	var fails := []
	# 1) shooters open fire after the alert delay and the bullets hurt the player with cause "bullet"
	await Debug.start_level(7, RETURN_FIRE)
	await Debug.step(900)
	var hits := 0
	for e in Debug.events:
		if e.kind == "damage" and e.cause == "bullet":
			hits += 1
	var d := TestUtil.deaths()
	print("SHOOTERS idle 900 ticks: bullet hits %d, player alive %s hp %d, deaths %s" % [hits, g.player.p.alive, g.player.p.hp, d])
	if hits == 0:
		fails.append("no bullet hits")
	for x in d:
		if x.cause == "":
			fails.append("causeless death")
	# 2) a stone wall blocks line of sight: no shots get through
	await Debug.start_level(7, WALLED)
	await Debug.step(900)
	var through := 0
	for e in Debug.events:
		if e.kind == "damage":
			through += 1
	print("SHOOTERS behind stone wall: damage events %d (want 0)" % through)
	if through != 0:
		fails.append("shot through wall")
	print("SHOOTERS RESULT: ", "PASS" if fails.is_empty() else "FAIL %s" % [fails])
	await TestUtil.finish(self, 0 if fails.is_empty() else 1)
