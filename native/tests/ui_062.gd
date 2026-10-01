extends SceneTree
var game
var failures=0
func _initialize(): call_deferred("run")
func check(ok,message):
	print("PASS / " if ok else "FAIL / ",message)
	if not ok: failures+=1
func capture(name):
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+"-062.png")
func no_scroll(node):
	if node is ScrollContainer: return false
	for child in node.get_children():
		if not no_scroll(child): return false
	return true
func run():
	game=preload("res://scenes/main.tscn").instantiate()
	game.progress_path="res://build/ui-062-save.json"
	root.add_child(game)
	await create_timer(0.2).timeout
	game.chosen_mode="safari"
	game.start_run()
	game.paused=true
	game.sim.invul=999
	game.sim.relics=["blood","storm","lens","wrap","coil","boots","magnet","flint"]
	for id in game.C.PASSIVES: game.sim.passives[id]=4
	for id in game.C.AUGMENTS: game.sim.augments[id]=3
	for x in range(-7,8):
		for y in range(-5,6): game.sim.explored[game.sim.depth][Vector2i(x,y)]=true
	game.sim.buffs={"frenzy":10,"immune":4,"freeze":6,"surge":12}
	game.toast_time=0
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,true)
	for resolution in [Vector2i(960,600),Vector2i(1920,1080),Vector2i(3440,1440)]:
		DisplayServer.window_set_size(resolution)
		await create_timer(0.35).timeout
		game.resume()
		game.paused=true
		await capture("hud-"+str(resolution.x))
		check(game.weapons_hud.entries.size()==game.sim.weapons.size(),"Weapon bar only contains weapons / "+str(resolution.x))
		check(game.buffs_hud.entries.size()>30,"Buff grid includes temporary effects and upgrades / "+str(resolution.x))
		check(game.buffs_hud.position.x>root.get_visible_rect().size.x/2,"Buffs anchored right / "+str(resolution.x))
		check(game.boss_label.position.y+game.boss_label.get_minimum_size().y*game.boss_label.scale.y<game.boss_bar.position.y+game.boss_bar.size.y*0.485*game.boss_bar.scale.y,"Boss text above health trough / "+str(resolution.x))
		game.ledger_menu()
		await capture("backpack-"+str(resolution.x))
		check(no_scroll(game.menu_root),"Backpack has no scrolling / "+str(resolution.x))
		var panel=game.menu_root.get_child(game.menu_root.get_child_count()-1)
		var icons=0
		var close_buttons=0
		for child in panel.get_children():
			if child is TextureRect: icons+=1
			if child is Button: close_buttons+=1
		check(icons==game.sim.weapons.size()+game.sim.relics.size()+game.sim.passives.size()+game.sim.augments.size() and close_buttons==1,"Full backpack equipment and close control rendered / "+str(resolution.x))
		game.map_menu()
		await capture("map-"+str(resolution.x))
	if root.get_visible_rect().size.x>2000: check(true,"Ultrawide expands gameplay viewport")
	else: check(false,"Ultrawide expands gameplay viewport")
	game.queue_free()
	game=null
	await process_frame
	await process_frame
	await process_frame
	print("UI 062 / ",failures," failures")
	quit(failures)
