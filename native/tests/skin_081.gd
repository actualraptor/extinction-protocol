extends SceneTree
var game
var failures=0
var checks=0
func _initialize():call_deferred("run")
func check(ok,msg):
	checks+=1
	if not ok:failures+=1;print("FAIL / ",msg)
func all_controls(node,kind):
	var out=[]
	for c in node.get_children():
		if is_instance_of(c,kind):out.append(c)
		out.append_array(all_controls(c,kind))
	return out
func capture(name):
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+"-081.png")
func button_bounds():
	for b in all_controls(game.menu_root,Button):
		if not b.visible:continue
		var font=b.get_theme_font("font");var fs=b.get_theme_font_size("font_size");var interior=b.size-b.get_theme_stylebox("normal").get_minimum_size()
		for line in b.text.split("\n"):check(font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x<=interior.x+1,"Button width / "+line)
		check(font.get_height(fs)*b.text.split("\n").size()<=interior.y+1,"Button height / "+b.text)
func run():
	game=preload("res://scenes/main.tscn").instantiate();game.progress_path="res://build/skin081-save.json";root.add_child(game)
	await create_timer(.3).timeout
	game.chosen_mode="safari";game.start_run();game.paused=true
	game.sim.weapons={"lightning":{"level":9,"evolved":false},"frost":{"level":9,"evolved":false},"fire":{"level":9,"evolved":false},"thorns":{"level":9,"evolved":false},"mortar":{"level":9,"evolved":false}}
	var opts=[]
	for id in game.C.WEAPONS:opts.append({"type":"weapon","id":id})
	for id in game.C.PASSIVES:opts.append({"type":"passive","id":id})
	for id in game.C.AUGMENTS:opts.append({"type":"augment","id":id})
	for start in range(0,opts.size(),3):
		game.upgrade_menu(opts.slice(start,start+3),false)
		await process_frame;await process_frame;await process_frame
		for p in all_controls(game.menu_root,PanelContainer):
			check(p.size.y<=536,"Upgrade card fits allocated height / "+str(start)+" / actual "+str(p.size.y))
			for c in all_controls(p,Control):check(p.get_global_rect().grow(1).encloses(c.get_global_rect()),"Upgrade contents inside panel / "+str(start))
		button_bounds()
	game.research_menu();await process_frame;await process_frame;await process_frame;button_bounds();await capture("archive")
	game.discovery_menu();await process_frame;await process_frame;await process_frame;button_bounds();await capture("discoveries")
	game.characters();await process_frame;await process_frame;await process_frame;button_bounds();await capture("characters")
	root.size=Vector2i(3440,1440);await create_timer(.2).timeout
	game.upgrade_menu([{"type":"weapon","id":"thorns"},{"type":"weapon","id":"lightning"},{"type":"passive","id":"crit"}],false)
	await create_timer(.7).timeout;button_bounds();await capture("wide-upgrade")
	root.size=Vector2i(1024,640);await create_timer(.2).timeout;await capture("small-upgrade")
	game.release_run();print("SKIN 081 / ",checks," checks / ",failures," failures");quit(1 if failures else 0)
