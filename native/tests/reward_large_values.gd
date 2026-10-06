extends SceneTree
var failures=0
var checks=0
func _initialize():call_deferred("run")
func run():
	var game=preload("res://scenes/main.tscn").instantiate();game.progress_path="res://build/large-card-profile.json";root.add_child(game)
	await create_timer(.2).timeout
	game.chosen_mode="safari";game.start_run();game.paused=true
	var g=game.sim;g.hero=1;g.passives={"damage":10000,"area":1000,"crit":1000};g.armor=1000000
	g.weapons={"club":{"level":9,"evolved":false},"thorns":{"level":9,"evolved":false}}
	g.modifier_cache.clear()
	for resolution in [Vector2i(1024,640),Vector2i(1920,1080),Vector2i(3440,1440)]:
		root.size=resolution
		game.upgrade_menu([{ "type":"weapon","id":"club","rarity":"ARTIFACT","rank_gain":1},{"type":"weapon","id":"thorns","rarity":"ARTIFACT","rank_gain":1},{"type":"passive","id":"crit","rarity":"ARTIFACT","stat_gain":3.0}],false)
		await process_frame;await process_frame
		for p in game.menu_root.get_children().filter(func(n):return n is HBoxContainer)[0].get_children():
			for e in p.regions:
				if not e.node is Label:continue
				var n=e.node;var allotted=e.area.size*p.size;var fs=n.get_theme_font_size("font_size");var font=n.get_theme_font("font")
				var width=allotted.x if n.autowrap_mode!=TextServer.AUTOWRAP_OFF else -1
				var need=font.get_multiline_string_size(n.text,HORIZONTAL_ALIGNMENT_LEFT,width,fs)
				checks+=1
				if need.x>allotted.x+1 or n.size.y>allotted.y+1:failures+=1;printerr("Large value does not fit / ",n.text)
	print("LARGE CARD VALUES / ",checks," checks / ",failures," failures")
	game.audio.shutdown();game.survivor_voice.stop();game.release_run();game.queue_free();await process_frame;quit(1 if failures else 0)
