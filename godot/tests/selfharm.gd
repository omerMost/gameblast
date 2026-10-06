extends Node
## The player must never die (or get hurt) without a cause.
## Fires shots that land on or near the player on every level, then checks:
##  - every death has a cause, and the cause matches what happened;
##  - "fall"/"crush" damage only happens within 3 s of an explosion (no physics-glitch damage:
##    that was the old "dying for no reason" bug).

const SHOTS := [
	[90, 0.45, "grenade"], [95, 0.6, "grenade"], [80, 0.3, "grenade"], [-60, 0.3, "grenade"],
	[-45, 0.2, "rocket"], [-80, 0.5, "rocket"], [60, 0.2, "grenade"], [0, 0.0, "rocket"],
]


func _ready() -> void:
	await TestUtil.boot(self)
	var g: Game = Debug.game
	var fails := []
	var deaths := 0
	var hurt := 0
	var causes := {}
	for i in g.level_count():
		for s in SHOTS:
			await Debug.start_level(i)
			var a := deg_to_rad(s[0])
			await TestUtil.shoot(g, cos(a), -sin(a), s[1], s[2])
			await Debug.step(120)
			var dl := []
			for e in Debug.events:
				if e.kind == "damage":
					dl.append("%s:%d" % [e.cause, e.dmg])
			print("  L%d %s hp=%d %s" % [i + 1, s, g.player.p.hp, ",".join(dl)])
			var last_boom := -100000
			for e in Debug.events:
				if e.kind == "explode":
					last_boom = e.sim
				elif e.kind == "damage":
					hurt += 1
					causes[e.cause] = causes.get(e.cause, 0) + 1
					if e.cause in ["fall", "crush"] and e.sim - last_boom > 180:
						fails.append("level %d shot %s: %s damage %d with no explosion nearby" % [i + 1, s, e.cause, e.dmg])
				elif e.kind == "player_died":
					deaths += 1
					if e.cause == "":
						fails.append("level %d shot %s: causeless death" % [i + 1, s])
	# a forced death: two rockets into the ground at your feet (level 3) must kill you, with cause "self"
	await Debug.start_level(2)
	var a2 := deg_to_rad(-80)
	await TestUtil.shoot(g, cos(a2), -sin(a2), 0.5, "rocket")
	await TestUtil.shoot(g, cos(a2), -sin(a2), 0.5, "rocket")
	await Debug.step(200)
	var dd := TestUtil.deaths()
	print("SELFHARM forced death: player alive %s, deaths %s" % [g.player.p.alive, dd])
	if dd.size() != 1 or dd[0].cause != "self":
		fails.append("forced self-blast death missing or wrong cause: %s" % [dd])
	deaths += dd.size()
	print("SELFHARM %d shots: %d damage events by cause %s, %d deaths" % [g.level_count() * SHOTS.size(), hurt, causes, deaths])
	for f in fails:
		print("  ", f)
	print("SELFHARM RESULT: ", "PASS" if fails.is_empty() and hurt > 0 else "FAIL")
	get_tree().quit(0 if fails.is_empty() and hurt > 0 else 1)
