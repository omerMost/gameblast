extends Node
## Headless test hooks. Mirrors the prototype's window.__dbg:
##   start_level(i), set_aim(dx, dy, pow, weapon), fire(), step(n), alive(), state()
## step() and start_level() are coroutines: `await Debug.step(60)`.

var game: Node = null     # set by Game._ready()
var events := []          # damage / death log, for "no causeless deaths" checks


func log_event(kind: String, data: Dictionary) -> void:
	var e := data.duplicate()
	e.kind = kind
	e.sim = game.sim if game else 0
	events.append(e)


func start_level(i: int, data: Dictionary = {}) -> void:
	events.clear()
	game.start_level(i, data)
	while game.state == "settle":
		await get_tree().physics_frame


func set_aim(dx: float, dy: float, p: float, w: String) -> void:
	var l := Vector2(dx, dy).length()
	game.aim.dx = dx / l
	game.aim.dy = dy / l
	game.aim.pow = p
	game.weapon = w


func fire() -> bool:
	return game.fire()


func step(n := 1) -> void:
	for i in n:
		await get_tree().physics_frame


func alive() -> int:
	return game.alive_count()


func state() -> String:
	return game.state


func predict() -> Array:
	return game.predict()
