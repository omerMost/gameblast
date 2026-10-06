extends Node
## Each ported level must stay stable with no input for 300 ticks:
## nobody dies, the player keeps full HP, nothing keeps drifting.
## Measure actual displacement speed: constrained bodies carry pre-integration
## gravity/lift velocity even when their attachment points stay stationary.

func _ready() -> void:
	var main = await TestUtil.boot(self)
	var g: Game = Debug.game
	var fails := []
	for i in g.available_levels():
		await Debug.start_level(i)
		var n0 := Debug.alive()
		var start := {}
		for b in g.bodies:
			start[b] = b.global_position
		await Debug.step(299)
		var previous := {}
		for b in g.bodies:
			previous[b] = b.global_position
		await Debug.step(1)
		var drift := 0.0
		var who := ""
		for b in g.bodies:
			if start.has(b):
				var d: float = b.global_position.distance_to(start[b])
				if d > drift:
					drift = d
					who = b.kind
		var fast := 0.0
		for b in g.bodies:
			if previous.has(b):
				fast = maxf(fast, b.global_position.distance_to(previous[b]) * C.STEP)
		var ok: bool = Debug.alive() == n0 and g.player.p.alive and g.player.p.hp == 100 and Debug.state() == "play" and drift < 4.0 and fast < 5.0
		print("SMOKE level %d %-14s enemies %d->%d hp %d state %s max_drift %.2fpx (%s) max_speed %.2fpx/s  %s" % [i + 1, g.L.name, n0, Debug.alive(), g.player.p.hp, Debug.state(), drift, who, fast, "ok" if ok else "FAIL"])
		if not ok:
			fails.append(i + 1)
	print("SMOKE RESULT: ", "PASS" if fails.is_empty() else "FAIL levels %s" % [fails])
	await TestUtil.finish(self, 0 if fails.is_empty() else 1)
