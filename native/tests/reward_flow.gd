extends SceneTree
const Reel=preload("res://scripts/relic_reel.gd")
var game
var failures=0
var checks=0
func _initialize():call_deferred("run")
func check(ok,why):
	checks+=1
	if not ok:failures+=1;printerr("FAIL / ",why)
func find_buttons(node):
	var out=[]
	for n in node.get_children():
		if n is Button:out.append(n)
		out.append_array(find_buttons(n))
	return out
func run():
	game=preload("res://scenes/main.tscn").instantiate();game.progress_path="res://build/reward-flow-profile.json";root.add_child(game);await create_timer(.2).timeout
	game.chosen_mode="safari";game.start_run();game.paused=true
	var g=game.sim
	g.passives.clear();g.augments.clear();g.buff_stacks.clear()
	for offer in [g.Relics.reward("shell","RARE"),{"type":"supplies","id":"supplies","rarity":"COMMON"},{"type":"passive","id":"damage","rarity":"EPIC","stat_gain":1.8,"rank_gain":1,"refinement":true}]:
		g.options=[offer];g.choosing=true;game.present_upgrade(g.options,true)
		var reel=game.menu_root.get_children().filter(func(n):return n is Reel)[0]
		reel._process(reel.duration+.4);await process_frame
		check(game.page=="relic-spin" and not reel.card_followup,"Ordinary chest stays on reel with no reward card")
		var event=InputEventKey.new();event.keycode=KEY_ENTER;event.pressed=true;reel._unhandled_key_input(event)
		check(not g.choosing and game.page=="playing","Ordinary reward accepted directly")
	for id in ["club","u00"]:
		g.hero=5 if id=="u00" else 1;g.companions=preload("res://scripts/companion_system.gd").new() if id=="u00" else null;g.weapons={id:{"level":10,"evolved":false,"timer":0.0}}
		g.options=[{"type":"evolution","id":id}];g.choosing=true;game.present_upgrade(g.options,true);await process_frame
		check(game.page=="upgrade" and find_buttons(game.menu_root).any(func(b):return b.text=="CLAIM EVOLUTION"),"Evolution opens dedicated reveal")
		find_buttons(game.menu_root).filter(func(b):return b.text=="CLAIM EVOLUTION")[0].pressed.emit()
		check(g.weapons[id].evolved,"Reveal accepts actual transformation")
	g.options=[{"type":"supplies","id":"supplies"}];g.choosing=true;game.page="playing"
	game.present_upgrade(g.options,false);await process_frame
	check(not g.choosing and game.page=="playing","Single level-up offer accepts without stopping gameplay")
	print("REWARD FLOW / ",checks," checks / ",failures," failures")
	game.audio.shutdown();game.survivor_voice.stop();game.release_run();game.queue_free();await process_frame;quit(1 if failures else 0)
