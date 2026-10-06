extends Node
func _ready() -> void:
	var main = await TestUtil.boot(self,OS.get_environment("BR_SCREEN")!="")
	var g: Game=Debug.game
	var ok := g.available_levels().size()==40
	Save.prog={"unlocked":1,"stars":{},"blood":true,"music":false}
	for i in 40:
		ok=ok and g.next_level(i)==(i+1 if i<39 else -1)
		Save.record_win(i,3,g.level_count(),g.next_level(i))
		ok=ok and Save.prog.unlocked==mini(40,i+2) and Save.stars(i)==3
	await Debug.start_level(2) # Both weapons, original ammo.
	main.hud.refresh()
	for w in ["grenade", "rocket"]:
		ok = ok and main.hud.w_btns[w].icon != null
		main.hud.w_btns[w].pressed.emit()
		ok = ok and g.weapon == w
	var style = main.hud.w_btns.rocket.get_theme_stylebox("normal")
	main.hud.refresh()
	ok = ok and main.hud.w_btns.rocket.get_theme_stylebox("normal") == style
	main.hud.show_levels()
	await get_tree().process_frame
	await get_tree().process_frame
	var box: Control=main.hud.card
	var viewport: Vector2=get_viewport().get_visible_rect().size
	ok=ok and box.global_position.y>=0 and box.global_position.y+box.size.y<=viewport.y
	print("PROGRESSION forty consecutive unlocks and visible level grid: ","PASS" if ok else "FAIL"," card=",box.get_global_rect()," viewport=",viewport)
	if OS.get_environment("BR_SCREEN")!="":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OS.get_environment("BR_SCREEN"))
	print("PROGRESSION RESULT: ","PASS" if ok else "FAIL")
	await TestUtil.finish(self,0 if ok else 1)
