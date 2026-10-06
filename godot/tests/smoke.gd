extends Node
## Each ported level must stay stable with no input for 300 ticks:
## nobody dies; source-alerted attacks and mobile enemies remain bounded.
## Measure actual displacement speed: constrained bodies carry pre-integration
## gravity/lift velocity even when their attachment points stay stationary.

func _ready() -> void:
	var main = await TestUtil.boot(self)
	var g: Game = Debug.game
	var fails := []
	for i in g.available_levels():
		await Debug.start_level(i)
		var n0 := Debug.alive()
		var expected: int = g.L.build.filter(func(op): return op[0]=="enemy").size()
		var start := {}
		for b in g.bodies:
			if b.kind in ["bullet","arrow","nade","flame"]: continue
			start[b] = b.global_position
		await Debug.step(299)
		var previous := {}
		for b in g.bodies:
			if b.kind in ["bullet","arrow","nade","flame"]: continue
			previous[b] = b.global_position
		await Debug.step(1)
		var drift := 0.0
		var who := ""
		for b in g.bodies:
			if b.kind in ["bullet","arrow","nade","flame"]: continue
			if start.has(b):
				var d: float = b.global_position.distance_to(start[b])
				if d > drift:
					drift = d
					who = b.kind
		var fast := 0.0
		for b in g.bodies:
			if b.kind in ["bullet","arrow","nade","flame"]: continue
			if previous.has(b):
				fast = maxf(fast, b.global_position.distance_to(previous[b]) * C.STEP)
		var hp_expected: int = {28:78,32:90,34:73,38:84}.get(i,100)
		var mobile := g.enemies.any(func(e): return e.p.get("knight",false) or e.p.get("jet",false) or e.p.get("titan",false) or e.p.get("dragon",false))
		var ok: bool = n0==expected and Debug.alive()==n0 and g.player.p.alive and g.player.lock_rotation and g.player.p.hp==hp_expected and g.state=="play" and g.shots==0
		ok = ok and ((drift < 800 and fast < 900) if mobile else (drift < 4 and fast < 5))
		for body in g.bodies:
			ok=ok and is_finite(body.global_position.x) and is_finite(body.global_position.y) and is_finite(body.linear_velocity.x) and is_finite(body.linear_velocity.y)
		for death in TestUtil.deaths(): ok=false
		if hp_expected<100: ok=ok and C.CAUSES.has(g.player.p.cause)
		print("SMOKE level %d %-14s enemies %d->%d hp %d state %s max_drift %.2fpx (%s) max_speed %.2fpx/s  %s" % [i + 1, g.L.name, n0, Debug.alive(), g.player.p.hp, Debug.state(), drift, who, fast, "ok" if ok else "FAIL"])
		if not ok:
			fails.append(i + 1)
	print("SMOKE RESULT: ", "PASS" if fails.is_empty() else "FAIL levels %s" % [fails])
	await TestUtil.finish(self, 0 if fails.is_empty() else 1)
