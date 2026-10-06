extends Node
## Player damage, death causes and the death screen (prototype damagePlayer / killPlayer / showLose).
## For every cause in C.CAUSES: damage goes through the real Game.damage_player(), hp drops by the
## rounded amount, death sets the cause, and the lose card shows that cause's title AND tip.
## Also: rounding / <1 ignored, the "fall" cause doesn't overwrite recent damage (120 ticks), off-map
## death (y > 1300) is "fall" unless damaged in the last 240 ticks, real explode() deaths (self-blast,
## barrel, enemy multiplier), the HP bar/chip react, and no death is ever causeless.

var g: Game
var hud: Hud
var main
var fails := []


func check(ok: bool, what: String) -> void:
	if not ok:
		fails.append(what)


func fresh(i := 0) -> void:
	await Debug.start_level(i)
	hud.hide_overlay()
	hud.result_title = ""
	hud.result_text = ""


## Wait for the result card (kill_player -> 1.5 s slow-mo timer -> show_result).
func wait_card() -> bool:
	for t in 400:
		if hud.blocking() and hud.result_title != "":
			return true
		await Debug.step(1)
	return false


func _ready() -> void:
	main = await TestUtil.boot(self)
	g = Debug.game
	hud = main.hud

	# 1) every cause: partial damage, then a lethal hit, then the card
	for cause in C.CAUSES:
		await fresh()
		var shakes := hud.hp_shakes
		g.damage_player(12.6, Vector2(1, 0), null, cause)          # rounds to 13
		check(g.player.p.hp == 87, "%s: hp after 12.6 dmg = %d, want 87" % [cause, g.player.p.hp])
		check(g.player.p.cause == cause, "%s: cause after damage = '%s'" % [cause, g.player.p.cause])
		check(is_equal_approx(hud.hp_bar.size.x, 74 * 0.87), "%s: hp bar width %.1f" % [cause, hud.hp_bar.size.x])
		check(hud.hp_shakes == shakes + 1, "%s: hp chip didn't shake" % cause)
		check(g.sim < g.player.p.flash, "%s: no hurt flash" % cause)
		check(g.hurt_a > 0.25, "%s: no hurt vignette (%.2f)" % [cause, g.hurt_a])
		await Debug.step(130)   # past the 120-tick window so even "fall" sets the cause
		g.damage_player(200, Vector2(0, -1), null, cause)
		check(not g.player.p.alive and g.player.p.hp == 0, "%s: lethal hit didn't kill (hp %d)" % [cause, g.player.p.hp])
		check(g.state == "lost" and g.lose_why == "ko", "%s: state %s / %s" % [cause, g.state, g.lose_why])
		check(g.player.p.cause == cause, "%s: death cause '%s'" % [cause, g.player.p.cause])
		var shown := await wait_card()
		check(shown, "%s: no result card" % cause)
		check(hud.result_title == C.CAUSES[cause][0], "%s: card title '%s'" % [cause, hud.result_title])
		check(hud.result_text == C.CAUSES[cause][1], "%s: card tip '%s'" % [cause, hud.result_text])
		print("  %-6s -> \"%s\" / \"%s\"" % [cause, hud.result_title, hud.result_text])

	# 2) rounding, <1 ignored, empty cause -> crush, dead/menu players take no damage
	await fresh()
	g.damage_player(0.4, Vector2.RIGHT, null, "self")
	check(g.player.p.hp == 100 and g.player.p.cause == "", "dmg 0.4 should be ignored (hp %d cause '%s')" % [g.player.p.hp, g.player.p.cause])
	g.damage_player(10, Vector2.RIGHT, null, "")
	check(g.player.p.hp == 90 and g.player.p.cause == "crush", "empty cause -> crush (got '%s')" % g.player.p.cause)

	# 3) "fall" right after other damage keeps the earlier cause (prototype: 120 ticks)
	await fresh()
	g.damage_player(20, Vector2.RIGHT, null, "bullet")
	await Debug.step(30)
	g.damage_player(20, Vector2.DOWN, null, "fall")
	check(g.player.p.cause == "bullet" and g.player.p.hp == 60, "fall within 120 ticks overwrote cause: '%s' hp %d" % [g.player.p.cause, g.player.p.hp])
	g.damage_player(100, Vector2.DOWN, null, "fall")
	check(g.player.p.cause == "bullet", "fatal fall within 120 ticks: cause '%s', want bullet" % g.player.p.cause)

	# 4) off-map: no recent damage -> "fall", "You fell" card
	await fresh()
	await Debug.step(250)
	g.player.global_position = Vector2(g.player.global_position.x, 1400)
	await Debug.step(3)
	check(not g.player.p.alive and g.player.p.cause == "fall" and g.lose_why == "ko", "off-map: alive %s cause '%s'" % [g.player.p.alive, g.player.p.cause])
	await wait_card()
	check(hud.result_title == C.CAUSES.fall[0] and hud.result_text == C.CAUSES.fall[1], "off-map card '%s' / '%s'" % [hud.result_title, hud.result_text])
	print("  off-map (no damage) -> cause %s, \"%s\"" % [g.player.p.cause, hud.result_title])
	#    off-map within 240 ticks of damage keeps that cause
	await fresh()
	g.damage_player(15, Vector2.RIGHT, null, "barrel")
	await Debug.step(100)
	g.player.global_position = Vector2(g.player.global_position.x, 1400)
	await Debug.step(3)
	check(not g.player.p.alive and g.player.p.cause == "barrel", "off-map after damage: cause '%s', want barrel" % g.player.p.cause)
	await wait_card()
	check(hud.result_title == C.CAUSES.barrel[0], "off-map-after-damage card '%s'" % hud.result_title)
	print("  off-map (damaged 100 ticks before by barrel) -> cause %s, \"%s\"" % [g.player.p.cause, hud.result_title])

	# 5) real explode(): self vs enemy multiplier (1.9 vs 1.3) at the same spot, barrel cause
	var dm := {}
	for cause in ["self", "enemy", "barrel"]:
		await fresh()
		var pp: Vector2 = g.player.global_position + Vector2(70, -10)
		g.explode(pp, C.R_GREN, C.P_GREN, null, cause)
		var ev := []
		for e in Debug.events:
			if e.kind == "damage":
				ev.append(e)
		check(ev.size() == 1 and ev[0].cause == cause, "explode(%s): damage events %s" % [cause, ev])
		if ev.size() == 1:
			dm[cause] = ev[0].dmg
			check(g.player.p.hp == 100 - ev[0].dmg and g.player.p.cause == cause, "explode(%s): hp %d cause %s" % [cause, g.player.p.hp, g.player.p.cause])
	if dm.has("self") and dm.has("enemy"):
		check(absf(dm.self / 1.9 - dm.enemy / 1.3) <= 1.0, "self/enemy multiplier off: %s" % [dm])
	print("  explode at +70px: dmg %s" % [dm])

	# 6) real-sim death: two rockets into your own feet (level 3) -> "self", card shows it
	await fresh(2)
	var a := deg_to_rad(-80)
	await TestUtil.shoot(g, cos(a), -sin(a), 0.5, "rocket")
	await TestUtil.shoot(g, cos(a), -sin(a), 0.5, "rocket")
	await Debug.step(30)
	var dd := TestUtil.deaths()
	check(dd.size() == 1 and dd[0].cause == "self", "self-blast death: %s" % [dd])
	await wait_card()
	check(hud.result_title == C.CAUSES.self[0] and hud.result_text == C.CAUSES.self[1], "self-blast card '%s' / '%s'" % [hud.result_title, hud.result_text])
	print("  real self-blast: deaths %s, card \"%s\"" % [dd, hud.result_title])

	# 7) the out-of-ammo card is not a cause card
	await fresh()
	g.lose_why = "ammo"
	g.state = "lost"
	hud.show_result()
	check(hud.result_title == "Out of ammo", "ammo card title '%s'" % hud.result_title)

	# no causeless deaths anywhere above (checked on every logged death)
	var causeless := 0
	for e in Debug.events:
		if e.kind == "player_died" and not C.CAUSES.has(e.cause):
			causeless += 1
	check(causeless == 0, "causeless deaths: %d" % causeless)

	print("DEATH %d causes checked, %d failures" % [C.CAUSES.size(), fails.size()])
	for f in fails:
		print("  FAIL ", f)
	print("DEATH RESULT: ", "PASS" if fails.is_empty() else "FAIL")
	await TestUtil.finish(self, 0 if fails.is_empty() else 1)
