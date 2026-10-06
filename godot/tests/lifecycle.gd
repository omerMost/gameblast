extends Node
func _ready() -> void:
	await TestUtil.boot(self)
	var g: Game = Debug.game
	await Debug.start_level(18)
	var e: GBody=g.enemies[0]
	e.p.next=-1
	g.enemy_ai.update_archer(e,true,g.player.wpt(g.player.loc.torso))
	var queued := not g.queue.is_empty()
	g.remove_body(e)
	await get_tree().process_frame
	await get_tree().process_frame
	await Debug.step(20)
	var ok := queued and not is_instance_valid(e) and g.enemy_ai.arrows.is_empty()
	print("LIFECYCLE removed archer cancels delayed release: ","PASS" if ok else "FAIL")
	await Debug.start_level(2)
	g.ammo.grenade=0
	g.weapon="grenade"
	var start: int=g.sim
	var fired := await TestUtil.shoot_active(g,1,0,0.5,"rocket")
	ok=ok and fired and g.last_shot-start<60
	print("LIFECYCLE exhausted weapon switches before readiness: ","PASS" if fired and g.last_shot-start<60 else "FAIL")
	print("LIFECYCLE RESULT: ","PASS" if ok else "FAIL")
	await TestUtil.finish(self,0 if ok else 1)
