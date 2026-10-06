extends Node
## Diagnostic: after one shot, print every enemy's fate. --level=N --shot=deg,pow,weapon

func _ready() -> void:
	await TestUtil.boot(self)
	var g: Game = Debug.game
	var lvl := 2
	var shot := ["10", "0.7", "rocket"]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--level="): lvl = int(a.split("=")[1])
		if a.begins_with("--shot="): shot = a.split("=")[1].split(",")
	await Debug.start_level(lvl - 1)
	var es := g.enemies.duplicate()
	var ang := deg_to_rad(float(shot[0]))
	Debug.set_aim(cos(ang), -sin(ang), float(shot[1]), shot[2])
	Debug.fire()
	for t in 360:
		await Debug.step(1)
		if t % 20 == 0 or (t > 55 and t < 100):
			var s := []
			for e in es:
				if g.in_world(e):
					s.append("%s rot=%.2f v=%s" % [e.global_position.round(), e.rotation, (e.linear_velocity / 60).round()])
				else:
					s.append("dead")
			var mv := 0
			for b in g.bodies:
				if b.linear_velocity.length() / 60 > 0.35: mv += 1
			print("t=%d moving=%d last_move=%d %s" % [g.sim, mv, g.last_move, s])
	for e in Debug.events:
		if e.kind == "enemy_killed":
			print(e)
	get_tree().quit(0)
