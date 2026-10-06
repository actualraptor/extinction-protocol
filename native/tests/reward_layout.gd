extends SceneTree
const Preview=preload("res://scripts/reward_preview.gd")
var game
var checks=0
var failures=0
func check(ok,message):
	checks+=1
	if not ok:failures+=1;printerr("FAIL / ",message)
func _initialize():call_deferred("run")
func run():
	game=preload("res://scenes/main.tscn").instantiate();game.progress_path="res://build/layout-profile.json";root.add_child(game)
	await create_timer(.2).timeout
	game.chosen_mode="safari";game.start_run();game.paused=true
	var g=game.sim
	g.hero=5;g.companions=preload("res://scripts/companion_system.gd").new()
	g.weapons={"club":{"level":4,"evolved":false,"timer":0.0},"revolver":{"level":9,"evolved":false,"timer":0.0},"lightning":{"level":1,"evolved":false,"timer":0.0},"mortar":{"level":1,"evolved":false,"timer":0.0},"frost":{"level":1,"evolved":false,"timer":0.0}}
	g.passives={"crit":8,"armor":3,"luck":2};g.buff_stacks.clear();g.modifier_cache.clear()
	var offers=[]
	for id in g.C.WEAPONS:
		offers.append({"type":"weapon","id":id,"rank_gain":1,"stat_gain":1.0})
	for id in g.C.PASSIVES:
		offers.append({"type":"passive","id":id,"rank_gain":1,"stat_gain":3.0})
	for id in g.C.AUGMENTS:offers.append({"type":"augment","id":id,"rank_gain":1,"stat_gain":3.0})
	for id in g.Relics.candidates(g):offers.append(g.Relics.reward(id,"ARTIFACT"))
	for id in g.Evolutions.UNIONS:offers.append({"type":"fusion","id":id})
	for id in g.weapons:offers.append({"type":"evolution","id":id})
	offers.append({"type":"supplies","id":"supplies"})
	for resolution in [Vector2i(1024,640),Vector2i(1920,1080),Vector2i(3440,1440)]:
		root.size=resolution
		for tier in g.Relics.TIERS:
			for start in range(0,offers.size(),3):
				var batch=offers.slice(start,start+3).duplicate(true)
				for o in batch:o.rarity=tier
				var rng_state=g.rng.state;var weapons=g.weapons.duplicate(true)
				game.upgrade_menu(batch,false);await process_frame;await process_frame
				check(g.rng.state==rng_state and g.weapons==weapons,"Preview never mutates combat or RNG")
				var panels=game.menu_root.get_children().filter(func(n):return n is HBoxContainer)[0].get_children()
				for panel in panels:
					check(root.get_visible_rect().encloses(panel.get_global_rect()),"Card fits viewport")
					for entry in panel.regions:
						var n=entry.node
						check(Rect2(Vector2.ZERO,panel.size).encloses(n.get_rect()),"Element stays inside card")
						if n is Label:
							var allocated=entry.area.size*panel.size
							check(n.size.x<=allocated.x+1 and n.size.y<=allocated.y+1,"Text respects allocated slot / "+n.text)
							var font=n.get_theme_font("font");var fs=n.get_theme_font_size("font_size")
							var width=n.size.x if n.autowrap_mode!=TextServer.AUTOWRAP_OFF else -1
							var need=font.get_multiline_string_size(n.text,HORIZONTAL_ALIGNMENT_LEFT,width,fs)
							check(need.x<=n.size.x+1 and need.y<=n.size.y+1,"Text fits / "+batch[panels.find(panel)].id+" / "+n.text)
					var labels=panel.regions.filter(func(e):return e.node is Label)
					for a in range(labels.size()):
						for b in range(a+1,labels.size()):
							check(not labels[a].node.get_rect().grow(-.5).intersects(labels[b].node.get_rect().grow(-.5)),"Text slots never overlap / "+batch[panels.find(panel)].id+" / "+labels[a].node.text+" / "+labels[b].node.text)
					if "--screens" in OS.get_cmdline_user_args() and resolution.x==1920 and start==0:
						panel.hovered_action="take";panel.feedback()
				if "--screens" in OS.get_cmdline_user_args() and resolution.x==1920 and start==0:
					await create_timer(.6).timeout
					await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://build/cards-"+tier.to_lower()+".png")
	print("REWARD LAYOUT / ",checks," checks / ",failures," failures")
	game.audio.shutdown();game.survivor_voice.stop();game.release_run();game.queue_free();await process_frame;quit(1 if failures else 0)
