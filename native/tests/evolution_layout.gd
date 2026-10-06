extends SceneTree
var game
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok,why):
	checks+=1
	if not ok:failures+=1;printerr("FAIL / ",why)
func labels(node):
	var out=[]
	for child in node.get_children():
		if child is Label:out.append(child)
		out.append_array(labels(child))
	return out
func visible_rect(node):
	var rect=node.get_global_rect();var parent=node.get_parent()
	while parent!=null:
		if parent is ScrollContainer:rect=rect.intersection(parent.get_global_rect())
		parent=parent.get_parent()
	return rect
func run():
	game=preload("res://scenes/main.tscn").instantiate();game.progress_path="res://build/evolution-layout-profile.json";root.add_child(game);await create_timer(.2).timeout
	game.chosen_mode="safari";game.start_run();game.paused=true
	var g=game.sim;g.companions=preload("res://scripts/companion_system.gd").new()
	for resolution in [Vector2i(1024,640),Vector2i(1920,1080),Vector2i(3440,1440)]:
		root.size=resolution
		for id in g.C.WEAPONS:
			if not g.C.WEAPONS[id].has("evolution"):continue
			g.hero=5 if g.C.WEAPONS[id].get("profile","")=="07" else 1
			g.weapons={id:{"level":10,"evolved":false,"timer":0.0}};g.modifier_cache.clear()
			var o={"type":"fusion" if g.Evolutions.UNIONS.has(id) else "evolution","id":id}
			if o.type=="fusion":
				g.weapons={}
				for part in g.Evolutions.UNIONS[id].parts:g.weapons[part]={"level":10,"evolved":false,"timer":0.0}
			game.evolution_menu([o]);await process_frame;await process_frame;await process_frame
			var panel=game.menu_root.get_children().filter(func(n):return n is PanelContainer)[0]
			check(root.get_visible_rect().encloses(panel.get_global_rect()),"Reveal fits viewport / "+id)
			var texts=labels(panel)
			for text in texts:
				var rect=visible_rect(text)
				check(not rect.has_area() or panel.get_global_rect().encloses(rect),"Visible text stays inside reveal / "+id+" / "+text.text)
				check(not text.clip_text,"Description is never truncated / "+id)
			for a in range(texts.size()):
				for b in range(a+1,texts.size()):
					var ra=visible_rect(texts[a]);var rb=visible_rect(texts[b])
					check(not ra.has_area() or not rb.has_area() or not ra.grow(-.5).intersects(rb.grow(-.5)),"Reveal text slots do not overlap / "+id+" / "+texts[a].text+" / "+texts[b].text)
			if "--screens" in OS.get_cmdline_user_args() and resolution.x==1920 and id in ["club","u00","whiteout"]:
				await create_timer(.45).timeout;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://build/reveal-"+id+".png")
	if "--screens" in OS.get_cmdline_user_args():
		root.size=Vector2i(1920,1080);g.hero=5;g.weapons={"u00":{"level":4,"evolved":false,"timer":0.0}}
		for start in [0,3]:
			var offers=[]
			for i in range(3):offers.append(g.BuffRewards.decorate(g,{"type":"weapon","id":["u00","u02","u03"][i]},g.Relics.TIERS[start+i]))
			game.upgrade_menu(offers,false);await create_timer(.6).timeout;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://build/variant-07-"+str(start)+".png")
	print("EVOLUTION LAYOUT / ",checks," checks / ",failures," failures")
	game.audio.shutdown();game.survivor_voice.stop();game.release_run();game.queue_free();await process_frame;quit(1 if failures else 0)
