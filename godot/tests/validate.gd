extends Node
## Validate playable level data before building the physics world.
var failures := []
var assertions := 0

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures.append(message)

func _ready() -> void:
	var count := 0
	for i in Levels.LEVELS.size():
		var level = Levels.LEVELS[i]
		if level == null:
			continue
		count += 1
		check(level is Dictionary, "L%d must be a dictionary" % (i + 1))
		if not level is Dictionary:
			continue
		var label := "L%d" % (i + 1)
		check(level.get("name", "") is String and not str(level.get("name", "")).is_empty(), label + " missing name")
		var view = level.get("view", [])
		check(view is Array and view.size() == 4, label + " view must have 4 numbers")
		if view is Array and view.size() == 4:
			for n in view:
				check((n is int or n is float) and is_finite(float(n)), label + " nonfinite view")
			check(view[2] > 0 and view[3] > 0, label + " view must have positive dimensions")
		var ammo = level.get("ammo", {})
		check(ammo is Dictionary and not ammo.is_empty(), label + " missing ammo")
		var total := 0
		if ammo is Dictionary:
			for weapon in ammo:
				check(weapon in ["grenade", "rocket"], label + " unsupported weapon " + str(weapon))
				check(ammo[weapon] is int and ammo[weapon] >= 0, label + " ammo must be nonnegative integers")
				total += int(ammo[weapon])
		check(level.get("par", 0) is int and level.get("par", 0) > 0 and level.get("par", 0) <= total, label + " invalid par/ammo")
		var ops = level.get("build", [])
		check(ops is Array and not ops.is_empty(), label + " missing build ops")
		var enemies := 0
		if ops is Array:
			for op in ops:
				check(op is Array and op.size() > 0 and op[0] is String, label + " malformed op")
				if not op is Array or op.is_empty():
					continue
				if op[0] == "enemy":
					enemies += 1
				if op[0] == "block" and op.size() >= 6:
					check(op[3] > 0 and op[4] > 0 and C.MAT.has(op[5]), label + " invalid block geometry/material")
				if op[0] == "ground" and op.size() >= 4:
					check(op[2] > op[1], label + " reversed ground")
		check(enemies > 0, label + " no enemy targets")
		for pair in level.get("portals", []):
			check(pair.has("a") and pair.has("b") and pair.a.size() == 2 and pair.b.size() == 2, label + " invalid portal pair")
		print("VALIDATE %s %s" % [label, level.get("name", "")])
	check(count >= 5, "missing stage-1 levels")
	check(C.STEP == 60.0 and C.R_GREN == 125.0 and C.P_GREN == 30.0 and C.R_ROCK == 110.0 and C.P_ROCK == 32.0, "physics specification changed")
	for failure in failures:
		print("FAIL ", failure)
	print("VALIDATE %d levels, %d assertions" % [count, assertions])
	print("VALIDATE RESULT: ", "PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)
