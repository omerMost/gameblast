extends Node
## Replay verified winning inputs through the real game. Sweep remains a search diagnostic.
const SOLUTIONS := {
	0: [[-5, 0.9, "grenade"]],
	1: [[5, 1.0, "grenade"]],
	2: [[45, 0.5, "grenade"], [5, 0.6, "rocket"]],
	3: [[20, 0.6, "grenade"]],
	4: [[25, 0.5, "grenade"]],
	18: [[15, 1.0, "grenade"], [5, 0.5, "grenade"]],
	19: [[5, 0.9, "grenade"], [25, 0.7, "grenade"]],
	20: [[75, 0.8, "grenade"]],
	21: [[10, 1.0, "grenade"]],
	22: [[45, 0.6, "grenade"], [45, 0.6, "grenade"]],
	24: [[25, 0.5, "rocket"], [25, 0.5, "rocket"]],
	23: [[5, 1.0, "grenade"], [-15, 0.5, "grenade"]],
	30: [[1, 0.7, "rocket"]],
	32: [[64, 0.7, "grenade"]],
}

func _ready() -> void:
	await TestUtil.boot(self)
	var g: Game = Debug.game
	var solutions: Dictionary = SOLUTIONS.duplicate()
	var new_indices := []
	for path in ["res://tests/stage3_early.gd","res://tests/stage3_mixed.gd","res://tests/stage3_monsters.gd"]:
		var fixture = load(path)
		for number in fixture.SHOTS:
			solutions[int(number)-1] = fixture.SHOTS[number]
			new_indices.append(int(number)-1)
	var failures := []
	var cleared := 0
	var only := -1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="): only = int(arg.split("=")[1]) - 1
	for i in Levels.LEVELS.size():
		if only >= 0 and only != i: continue
		if Levels.LEVELS[i] == null:
			continue
		if not solutions.has(i):
			failures.append("L%d has no bot solution" % (i + 1))
			continue
		await Debug.start_level(i)
		var fired := true
		for shot in solutions[i]:
			if g.state != "play":
				break
			if shot.size()>3: await Debug.step(int(shot[3]))
			var angle := deg_to_rad(float(shot[0]))
			if i < 5:
				fired = await TestUtil.shoot(g, cos(angle), -sin(angle), shot[1], shot[2]) and fired
			else:
				fired = await TestUtil.shoot_active(g, cos(angle), -sin(angle), shot[1], shot[2]) and fired
		await TestUtil.settle(g)
		await Debug.step(3)
		var ok: bool = fired and g.state == "won" and g.player.p.alive and g.shots <= int(g.L.ammo.get("grenade", 0)) + int(g.L.ammo.get("rocket", 0))
		for death in TestUtil.deaths():
			if not C.CAUSES.has(death.cause):
				ok = false
		if not ok:
			# ADR 0006: chaotic physics can vary with simulation history. Search a
			# replacement using the same real inputs/ammo, never change the world.
			var search = load("res://tests/knight.gd" if i == 19 else ("res://tests/jet.gd" if i == 24 else ("res://tests/content_search.gd" if i in new_indices else "res://tests/sweep.gd"))).new()
			search.g = g
			var replacement: Dictionary = await search.solve(true) if i in [19,24] else await search.solve(i)
			print("BOT replacement level %d %s" % [i + 1, replacement])
			ok = replacement.win and g.player.p.alive
			for death in TestUtil.deaths() if i in [19,24] or i in new_indices else search.death_log:
				if not C.CAUSES.has(death.cause): ok = false
			search.free()
		print("BOT level %d %s %s shots=%d par=%d" % [i + 1, g.L.name, "WIN" if ok else "FAIL", g.shots, g.L.par])
		if ok:
			cleared += 1
		else:
			failures.append("L%d %s, remaining %d, shots %d" % [i + 1, g.state, g.alive_count(), g.shots])
	for failure in failures:
		print("FAIL ", failure)
	print("BOT cleared=%d failures=%d" % [cleared, failures.size()])
	print("BOT RESULT: ", "PASS" if failures.is_empty() else "FAIL")
	await TestUtil.finish(self, 0 if failures.is_empty() else 1)
