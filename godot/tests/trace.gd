extends Node
## Diagnostic: trace one shot. tests/run.sh trace 60 -- --level=1 --shot=95,0.6,grenade [--every=10]

func _ready() -> void:
	await TestUtil.boot(self)
	var g: Game = Debug.game
	var lvl := 1
	var shot := ["0", "0.5", "grenade"]
	var every := 10
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--level="): lvl = int(a.split("=")[1])
		if a.begins_with("--shot="): shot = a.split("=")[1].split(",")
		if a.begins_with("--every="): every = int(a.split("=")[1])
	await Debug.start_level(lvl - 1)
	var ang := deg_to_rad(float(shot[0]))
	Debug.set_aim(cos(ang), -sin(ang), float(shot[1]), shot[2])
	print("player at %s tip %s" % [g.player.global_position, g.tip_pos()])
	Debug.fire()
	var pr = g.projectiles[0]
	for t in 400:
		if t % every == 0 or not g.in_world(pr):
			if g.in_world(pr):
				print("t=%d proj %s v=%s" % [g.sim, pr.global_position.round(), (pr.linear_velocity / 60).snapped(Vector2(0.01, 0.01))])
			else:
				print("t=%d proj gone; player hp %d alive %s pos %s" % [g.sim, g.player.p.hp, g.player.p.alive, g.player.global_position.round() if g.in_world(g.player) else Vector2.ZERO])
				break
		await Debug.step(1)
	for e in Debug.events:
		print("  event ", e)
	get_tree().quit(0)
