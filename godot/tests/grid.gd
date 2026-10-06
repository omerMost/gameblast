extends Node
## Diagnostic: one shot per cell over an aim grid, for every level, printed as JSON lines
## ("GRID {...}"). Run the same grid in the prototype (__dbg) to compare feel numerically.

const ANGLES := [0, 10, 20, 30, 40, 50, 60, 70]
const POWS := [0.3, 0.5, 0.7, 0.9]


func _ready() -> void:
	await TestUtil.boot(self)
	var g: Game = Debug.game
	for i in g.level_count():
		for w in ["grenade", "rocket"]:
			if Levels.LEVELS[i].ammo.get(w, 0) <= 0:
				continue
			for a in ANGLES:
				for p in POWS:
					await Debug.start_level(i)
					var r := deg_to_rad(a)
					await TestUtil.shoot(g, cos(r), -sin(r), p, w)
					await Debug.step(2)
					print("GRID ", JSON.stringify({"l": i + 1, "w": w, "a": a, "p": p, "alive": g.alive_count(), "hp": g.player.p.hp}))
	get_tree().quit(0)
