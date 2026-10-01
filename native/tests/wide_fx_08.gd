extends SceneTree
var game
var failures=0
func _initialize():call_deferred("run")
func check(ok,msg):
	if not ok:failures+=1
	print("PASS / " if ok else "FAIL / ",msg)
func capture(id):
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+id+"-08.png")
func run():
	game=preload("res://scenes/main.tscn").instantiate();game.progress_path="res://build/wide08-save.json"
	var f=FileAccess.open(game.progress_path,FileAccess.WRITE);f.store_string(JSON.stringify({"version":1,"runs":1,"amber":0,"records":[],"unlocks":["kael","mara","iona","orin","ironbriar","map_frost","map_observatory"]}));f.close();root.add_child(game)
	await create_timer(0.3).timeout
	game.characters();await capture("characters")
	game.selected=1;game.chosen_mode="expedition";game.start_run();game.paused=true
	game.sim.weapons={"thorns":{"level":10,"evolved":true,"timer":0.0},"mortar":{"level":3,"evolved":false,"timer":0.0}}
	game.sim.Breakables.update(game.sim,1)
	var prop=game.sim.spawn_enemy(false,Vector2(-140,20),4,false);prop.breakable=true;prop.prop_art=1;prop.role="prop";prop.size=20
	var enemy=game.sim.spawn_enemy(false,Vector2(220,80),0,false);enemy.hp=100000;game.sim.build_grid();game.sim.update_weapons(.1)
	for h in game.sim.hazards:
		if h.has("launch"):h.wait=h.flight*0.5
	await capture("mortar-flight")
	game.sim.spawn_boss(2);game.sim.boss.hp=45123
	for i in range(50):game.sim.spawn_enemy(false,game.sim.boss.p+Vector2.from_angle(i*2.4)*25,4,false)
	game.sim.passives.crit=60
	game.sim.hit(enemy,100,"thorns",true,false)
	await capture("boss-critical")
	check(game.boss_bar.health==45123 and game.boss_bar.maximum==90000,"Boss bar exposes current and maximum HP")
	root.size=Vector2i(3440,1440);await create_timer(.25).timeout
	game.save_data.settings.hud_scale=1.0;game.update_hud_scale();await capture("ultrawide-hud")
	var bounds=root.get_visible_rect()
	check(bounds.encloses(game.score_plate.get_global_rect()),"Ultrawide score plate inside viewport")
	check(bounds.encloses(game.weapons_hud.get_global_rect()),"Ultrawide weapons inside viewport")
	game.research_menu();await capture("ultrawide-archive")
	for c in game.menu_root.get_children():
		if c is Button:check(bounds.encloses(c.get_global_rect()),"Ultrawide archive footer / "+c.text)
	game.summary();await capture("ultrawide-summary")
	game.release_run()
	print("WIDE FX 08 / failures ",failures);quit(1 if failures else 0)
