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
	root.get_texture().get_image().save_png("res://build/"+name+"-stone.png")
func button_bounds():
	for b in all_controls(game.menu_root,Button):
		if not b.visible:continue
		var font=b.get_theme_font("font");var fs=b.get_theme_font_size("font_size");var interior=b.size-b.get_theme_stylebox("normal").get_minimum_size()
		for line in b.text.split("\n"):check(font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x<=interior.x+1,"Button width / "+line)
		check(font.get_height(fs)*b.text.split("\n").size()<=interior.y+1,"Button height / "+b.text)
func run():
	game=preload("res://scenes/main.tscn").instantiate();game.progress_path="res://build/stone-save.json";root.add_child(game)
	await create_timer(.3).timeout
	game.chosen_mode="safari";game.start_run();game.paused=true
	game.sim.weapons={"lightning":{"level":9,"evolved":false},"frost":{"level":9,"evolved":false},"fire":{"level":9,"evolved":false},"thorns":{"level":9,"evolved":false},"mortar":{"level":9,"evolved":false}}
	game.sim.passives.clear();game.sim.augments.clear();game.sim.buff_stacks.clear()
	var opts=[]
	for id in game.C.WEAPONS:opts.append({"type":"weapon","id":id})
	for id in game.C.PASSIVES:opts.append({"type":"passive","id":id})
	for id in game.C.AUGMENTS:opts.append({"type":"augment","id":id})
	for i in range(opts.size()):opts[i]=game.sim.BuffRewards.decorate(game.sim,opts[i],"ARTIFACT")
	for start in range(0,opts.size(),3):
		game.upgrade_menu(opts.slice(start,start+3),false)
		await process_frame;await process_frame;await process_frame
		for p in all_controls(game.menu_root,PanelContainer):
			check(p.size.y<=571,"Upgrade card fits allocated height / "+str(start)+" / actual "+str(p.size.y))
			for c in all_controls(p,Control):check(p.get_global_rect().grow(1).encloses(c.get_global_rect()),"Upgrade contents inside panel / "+str(start))
			check(absf(p.size.x / p.size.y - 2.0 / 3.0)<0.001,"Premium frame keeps 2:3 proportions")
			for c in all_controls(p,Label):
				var measured=c.get_theme_font("font").get_multiline_string_size(c.text,HORIZONTAL_ALIGNMENT_LEFT,c.size.x,c.get_theme_font_size("font_size"))
				check(measured.y<=c.size.y+2,"Every offer text fits / "+c.text)
		button_bounds()
	game.research_menu();await process_frame;await process_frame;await process_frame;button_bounds();await capture("archive")
	game.discovery_menu();await process_frame;await process_frame;await process_frame;button_bounds();await capture("discoveries")
	game.characters();await process_frame;await process_frame;await process_frame;button_bounds();await capture("characters")
	root.size=Vector2i(3440,1440);await create_timer(.2).timeout
	game.upgrade_menu([{"type":"weapon","id":"thorns","rarity":"UNCOMMON"},{"type":"weapon","id":"lightning","rarity":"EPIC"},{"type":"passive","id":"crit","rarity":"ARTIFACT"}].map(func(o):return game.sim.BuffRewards.decorate(game.sim,o,o.rarity)),false)
	await create_timer(.7).timeout;button_bounds();await capture("wide-upgrade")
	root.size=Vector2i(1024,640);await create_timer(.2).timeout;await capture("small-upgrade")
	for resolution in [Vector2i(1024,640),Vector2i(1280,720),Vector2i(3440,1440)]:
		root.size=resolution
		var offers=[]
		for id in ["velocity","conductor","ward"]:offers.append(game.sim.BuffRewards.decorate(game.sim,{"type":"augment","id":id},"ARTIFACT"))
		game.upgrade_menu(offers,false);await create_timer(.6).timeout
		for p in all_controls(game.menu_root,PanelContainer):
			check(p.size.y<=571,"Artifact augment height")
			for c in all_controls(p,Label):
				var f=c.get_theme_font("font");var fs=c.get_theme_font_size("font_size")
				var needed=f.get_multiline_string_size(c.text,HORIZONTAL_ALIGNMENT_LEFT,c.size.x,fs)
				check(needed.y<=c.size.y+2,"Artifact description text fits / "+c.text)
		var texts=all_controls(game.menu_root,Label).map(func(l):return l.text)
		check(texts.any(func(t):return "+90.0% projectile speed" in t),"Artifact actual velocity bonus visible")
		check(texts.any(func(t):return "+54.0 barrier health" in t),"Artifact actual ward bonus visible")
		button_bounds();await capture("artifact-augments-"+str(resolution.x))
	root.size=Vector2i(1280,720)
	for group in [["COMMON","UNCOMMON","RARE"],["EPIC","LEGENDARY","ARTIFACT"]]:
		var tier_offers=[]
		for rarity in group:tier_offers.append(game.sim.BuffRewards.decorate(game.sim,{"type":"passive","id":"crit"},rarity))
		game.upgrade_menu(tier_offers,false);await create_timer(.6).timeout;button_bounds();await capture("rarity-"+group[0])
		for width in [1024,3440]:
			root.size=Vector2i(width,640 if width==1024 else 1440)
			await create_timer(.15).timeout;button_bounds();await capture("rarity-"+group[0]+"-"+str(width))
		root.size=Vector2i(1280,720)
	check(not "Weapon" in game.UpgradeCopy.tags(game.sim,{"type":"weapon","id":"club"}),"Taxonomy Weapon hidden")
	check("Frost" in game.UpgradeCopy.tags(game.sim,{"type":"weapon","id":"frost"}),"Boostable Frost retained")
	game.audio.shutdown()
	game.survivor_voice.stop()
	game.release_run()
	game.queue_free()
	await create_timer(.3).timeout
	await process_frame
	print("STONE CARDS / ",checks," checks / ",failures," failures")
	quit(1 if failures else 0)






