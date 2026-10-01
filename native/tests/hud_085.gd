extends SceneTree
var game
var failures=0
var checks=0
func _initialize():call_deferred("run")
func check(ok,msg):
	checks+=1
	if not ok:failures+=1;print("FAIL / ",msg)
func capture(name):
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+"-082.png")
func run():
	game=preload("res://scenes/main.tscn").instantiate();game.progress_path="res://build/hud082-save.json";root.add_child(game)
	await create_timer(.3).timeout
	game.chosen_mode="daily";game.start_run();game.paused=true;game.sim.time=47;game.sim.level=4;game.sim.xp=12;game.sim.xp_goal=73
	for resolution in [Vector2i(1024,640),Vector2i(1280,800),Vector2i(1920,1080),Vector2i(3440,1440)]:
		root.size=resolution
		for scale_value in [0.65,1.0,1.35]:
			game.save_data.settings.hud_scale=scale_value
			await create_timer(.08).timeout
			var timer=game.timer_label.get_global_rect();var biome=game.biome_label.get_global_rect();var panel=game.timer_plate.get_global_rect()
			check(panel.encloses(timer) and panel.encloses(biome),"Timer text fits frame / "+str(resolution)+str(scale_value))
			check(Rect2(Vector2(108,58)*scale_value,Vector2(390,68)*scale_value).encloses(timer) and Rect2(Vector2(108,58)*scale_value,Vector2(390,68)*scale_value).encloses(biome),"Text inside illustrated inset")
			check(not timer.intersects(biome),"Timer and biome never overlap")
			var body=game.biome_label
			check(body.get_theme_font("font").get_height(body.get_theme_font_size("font_size"))*2<=body.size.y+1,"Both biome lines fit vertically")
			check(game.xp_bar.get_global_rect().encloses(game.weapons_hud.get_global_rect()) and game.weapons_hud.get_global_rect().end.y<game.xp_bar.position.y+78*scale_value,"Weapons fit dock above XP track")
			check(root.get_visible_rect().encloses(game.loadout_label.get_global_rect()),"Backpack readout fits viewport")
			if scale_value==1.0:await capture("hud-"+str(resolution.x))
	root.size=Vector2i(1280,800);game.save_data.settings.hud_scale=1.0
	game.daily_menu();await capture("daily-menu")
	game.save_data.daily_records=[{"date":Time.get_date_string_from_system(true),"seconds":1684,"kills":15234,"score":456700,"bosses":5,"circuit":2,"seed":game.sim.daily_plan.seed,"ruleset":"0.8.2"}]
	game.persist();game.save_data.daily_records=[];game.load_progress()
	check(game.save_data.daily_records.size()==1 and game.save_data.daily_records[0].kills==15234,"Daily kills/time records survive reload")
	game.daily_records_menu();await capture("daily-leaderboard")
	game.release_run();print("HUD DAILY 082 / ",checks," checks / ",failures," failures");quit(1 if failures else 0)
