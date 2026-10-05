extends SceneTree
var game
var checks=0
var failures=0
func check(ok,msg):
	checks+=1
	if not ok:failures+=1;printerr("FAIL / ",msg)
func _initialize():call_deferred("run")
func shot(name):
	await create_timer(.8).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/fortune-"+name+".png")
func run():
	game=preload("res://scenes/main.tscn").instantiate()
	game.progress_path="res://build/fortune-visual-profile.json"
	root.add_child(game);await create_timer(.3).timeout
	game.save_data.unlocks=game.Discoveries.ENTRIES.keys()
	game.save_data.settings.halloween=true
	for res in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(3440,1440)]:
		root.size=res;game.characters();await shot("characters-"+str(res.x))
		var row=game.menu_root.get_children().filter(func(n):return n is HBoxContainer)[0]
		var bottom=-1.0
		for card in row.get_children():
			var button=card.get_child(0).get_children().filter(func(n):return n is Button)[0]
			var y=button.get_global_rect().end.y
			if bottom>=0:check(absf(y-bottom)<1,"Character buttons share baseline")
			bottom=y
		game.selected=1;game.start_run();game.paused=true;game.sim.enemies.clear()
		game.map_menu();await shot("map-local-"+str(res.x))
		check(not game.hud_root.visible and not game.toast_panel.visible,"Map owns footer and excludes run banner")
		var map=game.menu_root.get_child(0);map.toggle_overview();await shot("map-overview-"+str(res.x))
		check(map.rect.end.y<map.size.y-86*map.ui_scale-12,"Map reserves bottom instruction area / %s %s"%[map.rect,map.size])
		game.clear_menu();game.page="play";game.paused=true
		game.sim.options=[game.sim.Relics.reward("crown","LEGENDARY")];game.sim.choosing=true
		game.present_upgrade(game.sim.options,true)
		var reel=game.menu_root.get_child(0);reel.elapsed=3.4;reel.landed=true
		await shot("crown-"+str(res.x))
		check(reel.reward_data.desc.contains("20.0%") and reel.reward_data.rarity=="LEGENDARY","Reel describes actual tier payload")
		game.sim.choosing=false;game.clear_menu();game.page="play"
		game.sim.options=[{"type":"weapon","id":"club"},{"type":"passive","id":"armor"},{"type":"augment","id":"reach"}]
		game.sim.choosing=true;game.upgrade_menu(game.sim.options,false);await shot("upgrade-"+str(res.x))
		game.release_run()
	root.size=Vector2i(1280,720);game.save_data.settings.halloween=false;game.characters();await shot("characters-original")
	check(game.texture(1).resource_path!=game.texture(2).resource_path or game.texture(1) is AtlasTexture,"Original portraits restored")
	game.save_data.settings.halloween=true;game.main_menu();await shot("menu")
	game.patch_notes();await shot("notes")
	game.save_data.unlocks=["kael"];game.characters();await shot("characters-locked")
	var locked_row=game.menu_root.get_children().filter(func(n):return n is HBoxContainer)[0]
	for card in locked_row.get_children():
		var button=card.get_child(0).get_children().filter(func(n):return n is Button)[0]
		check(card.get_global_rect().encloses(button.get_global_rect()),"Locked character button fits its card")
	game.audio.shutdown();game.survivor_voice.stop();game.release_run();game.queue_free()
	await create_timer(.15).timeout
	print("FORTUNE VISUAL / ",checks," checks / ",failures," failures")
	quit(1 if failures else 0)
