extends Node
## For each ported level, search (greedily, shot by shot) for a sequence of shots that
## clears it within the level's ammo. Also checks every player death has a cause.
## Usage: godot --headless --path godot res://tests/sweep.tscn [-- --level=N]

const ANGLES := [-15, -5, 0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80]
const POWS := [0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]

var g: Game
var death_log := []


func _ready() -> void:
	var main = await TestUtil.boot(self)
	g = Debug.game
	var only := -1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--level="):
			only = int(a.split("=")[1]) - 1
	var fails := []
	var t0 := Time.get_ticks_msec()
	for i in g.available_levels():
		if only >= 0 and i != only:
			continue
		var res: Dictionary = await solve(i)
		print("SWEEP level %d %-14s %s shots=%s par=%d ammo=%s tried=%d" % [i + 1, g.L.name, "WIN " if res.win else "FAIL", res.seq, g.L.par, g.L.ammo, res.tried])
		if not res.win:
			fails.append(i + 1)
	var causeless := 0
	var causes := {}
	for d in death_log:
		causes[d.cause] = causes.get(d.cause, 0) + 1
		if d.cause == "":
			causeless += 1
	print("SWEEP player deaths during search: %d, by cause %s, causeless %d" % [death_log.size(), causes, causeless])
	print("SWEEP time %.1fs" % ((Time.get_ticks_msec() - t0) / 1000.0))
	var ok := fails.is_empty() and causeless == 0
	print("SWEEP RESULT: ", "PASS" if ok else "FAIL levels %s causeless %d" % [fails, causeless])
	get_tree().quit(0 if ok else 1)


## Replay a shot list from a fresh level. Returns the outcome.
func run(i: int, seq: Array) -> Dictionary:
	await Debug.start_level(i)
	for s in seq:
		if g.state != "play":
			break
		var a := deg_to_rad(s[0])
		await TestUtil.shoot(g, cos(a), -sin(a), s[1], s[2])
	if g.state == "play" and g.alive_count() == 0:
		await Debug.step(2)
	for d in TestUtil.deaths():
		var e: Dictionary = d.duplicate()
		e.level = i + 1
		e.seq = seq
		death_log.append(e)
	return {"alive": g.alive_count(), "state": g.state, "player": g.player.p.alive}


func solve(i: int) -> Dictionary:
	var L: Dictionary = Levels.LEVELS[i]
	var total: int = L.ammo.get("grenade", 0) + L.ammo.get("rocket", 0)
	var seq := []
	var tried := 0
	for k in total:
		var best = null
		var best_alive := 999
		var ammo_left: Dictionary = L.ammo.duplicate()
		for s in seq:
			ammo_left[s[2]] -= 1
		for w in ["grenade", "rocket"]:
			if ammo_left.get(w, 0) <= 0:
				continue
			for ang in ANGLES:
				for p in POWS:
					var cand := seq + [[ang, p, w]]
					var r := await run(i, cand)
					tried += 1
					if r.state == "won":
						return {"win": true, "seq": cand, "tried": tried}
					if r.player and r.alive < best_alive:
						best_alive = r.alive
						best = cand
		if best == null:
			break
		seq = best
	return {"win": false, "seq": seq, "tried": tried}
