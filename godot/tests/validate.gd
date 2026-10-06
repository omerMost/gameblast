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
		check(op_errors(ops).is_empty(), label + " invalid builder ops: " + str(op_errors(ops)))
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
	check(not op_errors([["unknown", 1, 2, 3]]).is_empty(), "validator rejects unknown builder")
	check(not op_errors([["block", 1, 2, -1, 4, "wood"]]).is_empty(), "validator rejects negative dimensions")
	check(not op_errors([["balloon", 1, 2, "missing", [0, 0], 5]]).is_empty(), "validator rejects dangling body reference")
	check(count >= 5, "missing stage-1 levels")
	check(C.STEP == 60.0 and C.R_GREN == 125.0 and C.P_GREN == 30.0 and C.R_ROCK == 110.0 and C.P_ROCK == 32.0, "physics specification changed")
	for failure in failures:
		print("FAIL ", failure)
	print("VALIDATE %d levels, %d assertions" % [count, assertions])
	print("VALIDATE RESULT: ", "PASS" if failures.is_empty() else "FAIL")
	await TestUtil.finish(self, 0 if failures.is_empty() else 1)


func op_errors(ops) -> Array:
	var errors := []
	var references := {}
	var arity := {"ground": 4, "plat": 4, "wall": 5, "pad": 5, "slope": 5,
		"block": 6, "enemy": 3, "boulder": 4, "barrel": 3,
		"hang": 4, "tether": 4, "balloon": 6, "bridge": 6}
	if not ops is Array:
		return ["build must be an array"]
	for op in ops:
		if not op is Array or op.is_empty() or not op[0] is String:
			errors.append("malformed operation")
			continue
		var kind: String = op[0]
		if not arity.has(kind) or op.size() < arity[kind]:
			errors.append("unknown or incomplete " + kind)
			continue
		if kind in ["hang", "tether"]:
			if not references.has(op[2]) or not pair_ok(op[1]) or not pair_ok(op[3]):
				errors.append(kind + " invalid anchor/body attachment")
			continue
		if kind == "balloon":
			if not references.has(op[3]) or not pair_ok(op[4]) or not number_ok(op[5]) or op[5] <= 0:
				errors.append("invalid balloon attachment/lift")
			if not number_ok(op[1]) or not number_ok(op[2]): errors.append("invalid balloon position")
			continue
		var numeric_end: int = 5 if kind == "block" else 3 if kind == "enemy" else 4 if kind == "boulder" else op.size()
		for n in range(1, numeric_end):
			if not number_ok(op[n]): errors.append(kind + " nonfinite coordinate")
		if kind == "block":
			if not number_ok(op[3]) or not number_ok(op[4]) or op[3] <= 0 or op[4] <= 0 or not C.MAT.has(op[5]): errors.append("invalid block size/material")
			if op.size() > 6: references[op[6]] = true
		if kind == "boulder":
			if not number_ok(op[3]) or op[3] <= 0: errors.append("invalid boulder radius")
			if op.size() > 4: references[op[4]] = true
		if kind in ["wall", "pad"] and (op[3] <= op[1] or op[4] <= op[2]): errors.append("invalid " + kind + " rectangle")
		if kind == "bridge" and (not op[5] is int or op[5] < 1 or op[3] <= op[1]): errors.append("invalid bridge geometry")
	return errors

func number_ok(value) -> bool:
	return (value is int or value is float) and is_finite(float(value))

func pair_ok(value) -> bool:
	return value is Array and value.size() == 2 and number_ok(value[0]) and number_ok(value[1])
