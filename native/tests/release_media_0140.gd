extends SceneTree
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1920,1080);root.content_scale_size=Vector2i(1440,900)
	var game=preload("res://scripts/main.gd").new();game.progress_path="res://build/release-0.14.0-validation/public-profile.json";root.add_child(game)
	await process_frame
	game.save_data.settings.sound=false;game.save_data.settings.music=false;game.apply_settings()
	game.main_menu()
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/release-0.14.0-validation/menu.png")
	game.discovery_menu()
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/release-0.14.0-validation/discoveries.png")
	game.selected=1;game.selected_map="cradle";game.chosen_mode="expedition";game.start_run();game.paused=true
	var g=game.sim;g.enemies.clear();g.landmarks.clear();g.invul=1000;g.spawn_boss(1);g.boss.p=g.pos+Vector2(100,-140)
	for i in range(50):g.tick(1.0/60,Vector2.ZERO)
	game.clear_menu()
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/release-0.14.0-validation/boss.png")
	game.release_run();game.hud_root.hide();game.clear_menu();game.set_process(false)
	root.size=Vector2i(1440,1500);root.content_scale_size=root.size;game.menu_root.position=Vector2.ZERO
	game.shade(.97)
	game.UIArt.plate(game.menu_root,2,Rect2(120,0,1200,650))
	var cover=ColorRect.new();cover.color=Color("090f0d");cover.position=Vector2(0,175);cover.size=Vector2(1440,1325);game.menu_root.add_child(cover)
	game.label(game.menu_root,"EXTINCTION PROTOCOL",39,"eddbb5").position=Vector2(80,190)
	game.label(game.menu_root,"0.14.0 / A WORLD REBORN",25,"c3a16b").position=Vector2(80,253)
	var grid=GridContainer.new();grid.columns=2;grid.position=Vector2(75,330);grid.size=Vector2(1290,950);grid.add_theme_constant_override("h_separation",26);grid.add_theme_constant_override("v_separation",30);game.menu_root.add_child(grid)
	for entry in game.PatchNotes.ENTRIES:
		var panel=PanelContainer.new();panel.custom_minimum_size=Vector2(632,425);panel.add_theme_stylebox_override("panel",game.UIArt.button_style());grid.add_child(panel)
		var col=VBoxContainer.new();col.add_theme_constant_override("separation",18);panel.add_child(col)
		game.Icons.control(col,entry.icon,entry.category,72)
		game.label(col,entry.title,24,"dec28d").autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		game.label(col,entry.body,23,"c9c9b9").autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	game.label(game.menu_root,"GUNS. ANCIENT FURY. FORBIDDEN MAGIC.",18,"aa9162").position=Vector2(80,1405)
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/release-0.14.0-validation/Extinction-Protocol-0.14.0-Patch-Notes.png")
	game.queue_free();await process_frame;quit()
