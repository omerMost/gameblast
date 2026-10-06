extends Node
## Replay shot sequences discovered by the independent greedy sweep bot.
## No direct kills, position edits, extra ammunition or damage overrides.
const SOLUTIONS := {
	20: [[75,0.8,"grenade"]],
	21: [[10,1.0,"grenade"]],
	22: [[45,0.6,"grenade"],[45,0.6,"grenade"]],
	23: [[5,1.0,"grenade"],[-15,0.5,"grenade"]],
}
func _ready() -> void:
	await TestUtil.boot(self)
	var g: Game = Debug.game
	var failures := []
	for i in SOLUTIONS:
		await Debug.start_level(i)
		for shot in SOLUTIONS[i]:
			var angle := deg_to_rad(shot[0])
			await TestUtil.shoot(g, cos(angle), -sin(angle), shot[1], shot[2])
		var ok: bool = g.state == "won" and g.player.p.alive and g.shots == SOLUTIONS[i].size()
		print("WORLD SOLUTION level ", i + 1, " ", g.L.name, " shots=", g.shots, " hp=", g.player.p.hp, " ", "PASS" if ok else "FAIL")
		if not ok:
			failures.append(i + 1)
	print("WORLD SOLUTIONS RESULT: ", "PASS" if failures.is_empty() else "FAIL " + str(failures))
	get_tree().quit(0 if failures.is_empty() else 1)
