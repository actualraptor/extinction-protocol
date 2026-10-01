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
func click(control):
	var p=control.get_global_rect().get_center()
	var event=InputEventMouseButton.new();event.position=p;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true
	root.push_input(event,true);await process_frame
	event=InputEventMouseButton.new();event.position=p;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=false
	root.push_input(event,true);await process_frame
func run():
	game=preload("res://scenes/main.tscn").instantiate();game.progress_path="res://build/ui08-save.json"
	var f=FileAccess.open(game.progress_path,FileAccess.WRITE);f.store_string(JSON.stringify({"version":1,"runs":0,"amber":10000,"records":[]}));f.close();root.add_child(game)
	await create_timer(0.5).timeout
	game.research_menu();await capture("archive")
	var back
	for c in game.menu_root.get_children():
		if c is Button and c.text=="Main menu":back=c
	check(back!=null and back.get_global_rect().end.y<=root.get_visible_rect().size.y,"Archive footer fits")
	await click(back);check(game.page=="menu","Archive main-menu button accepts mouse input")
	game.daily_menu();await capture("daily")
	game.chosen_mode="expedition";game.selected=1;game.start_run();game.paused=true
	game.sim.weapons={"lightning":{"level":4,"evolved":false,"timer":0.1},"thorns":{"level":3,"evolved":false,"timer":0.1},"fire":{"level":2,"evolved":false,"timer":0.1}}
	game.sim.options=[{"type":"passive","id":"area"},{"type":"augment","id":"conductor"},{"type":"passive","id":"armor"}];game.sim.choosing=true
	game.upgrade_menu(game.sim.options,false);await create_timer(0.6).timeout;await capture("upgrade")
	game.sim.choosing=false;game.clear_menu();game.page="playing";game.sim.spawn_boss(1)
	game.save_data.settings.hud_scale=0.65;game.update_hud_scale();var small=game.score_plate.get_global_rect().size;await capture("hud-small")
	game.save_data.settings.hud_scale=1.35;game.update_hud_scale();var large=game.score_plate.get_global_rect().size;await capture("hud-large")
	check(large.x>small.x*1.8,"HUD preference visibly changes scale")
	check(game.boss_label.get_global_rect().position.y>game.score_plate.get_global_rect().end.y,"Boss heading does not overlap score plate")
	game.save_data.settings.hud_scale=1.0;game.update_hud_scale()
	game.sim.level=30;game.ledger_menu();await capture("backpack")
	game.sim.damage_by_weapon={"thorns":23000,"lightning":19000,"fire":7000};game.sim.damage_total=49000;game.sim.kills=1250;game.sim.score=97321;game.sim.time=310
	game.summary();await capture("summary")
	game.research_menu();game.buy("revive");check(game.save_data.research.get("revive",0)==1,"New research purchase persists")
	game.load_progress();check(game.save_data.research.get("revive",0)==1,"Purchased research reloads")
	print("UI 08 / failures ",failures);quit(1 if failures else 0)
