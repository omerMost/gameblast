class_name TestUtil
extends RefCounted
## Shared helpers for the headless tests.

static func boot(host: Node) -> Node:
	Save.enabled = false
	var main = load("res://scenes/main.tscn").instantiate()
	host.add_child(main)
	await host.get_tree().process_frame
	main.hud.hide_overlay()
	return main


## Fire one shot and wait until the world settles (or the level ends). Returns false if it couldn't fire.
static func shoot(g: Game, dx: float, dy: float, p: float, w: String) -> bool:
	var waited := 0
	while not g.can_fire() and g.state == "play" and waited < 400:
		await Debug.step(1)
		waited += 1
	if g.ammo.get(w, 0) <= 0:
		w = "grenade" if w == "rocket" else "rocket"
	Debug.set_aim(dx, dy, p, w)
	if not Debug.fire():
		return false
	await settle(g)
	return true


static func settle(g: Game, max_ticks := 600) -> void:
	var t := 0
	while t < max_ticks:
		await Debug.step(1)
		t += 1
		if g.state != "play":
			return
		if g.projectiles.is_empty() and g.queue.is_empty() and g.sim - g.last_move > 30:
			return


static func deaths() -> Array:
	var out := []
	for e in Debug.events:
		if e.kind == "player_died":
			out.append(e)
	return out
