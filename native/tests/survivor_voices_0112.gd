extends SceneTree
var checks=0
var failures=0
func check(ok,msg):
	checks+=1
	if not ok:failures+=1;printerr("FAIL / ",msg)
func _initialize():call_deferred("run")
func run():
	var voice=preload("res://scripts/survivor_voice.gd").new();voice.seed_value=2026;root.add_child(voice)
	for hero in [0,1,2]:
		voice.set_hero(hero)
		var key=voice.HERO_KEYS[hero]
		check(voice.bank.size()==7,"Seven event banks / "+key)
		for event in voice.hero_registry[key]:
			check(voice.bank[event].size()==voice.hero_registry[key][event],"All variants imported / "+key+event)
			for clip in voice.bank[event]:
				check(clip.get_length()>.1 and clip.resource_path.get_file().begins_with(key+"_"+event+"_"),"Correct hero/event file / "+clip.resource_path)
			var last=-1
			for i in range(20):
				var selected=voice.pick_variant(event)
				check(selected>=0 and selected<voice.bank[event].size() and selected!=last,"No repeating variants / "+key+event)
				last=selected
		check(voice.play_event("boss_spawn",true),"Boss spawn plays")
		check(voice.play_event("boss_killed",true) and voice.pending=="boss_killed","Boss kill queues")
		check(voice.play_event("death",true) and voice.current_event=="death" and voice.pending=="","Death interrupts")
		voice.reset_run();voice.last_event.hurt=voice.now()
		check(not voice.play_event("hurt"),"Hurt respects cooldown")
		voice.last_event.level_up=voice.now();check(not voice.play_event("level_up"),"Levels respect cooldown")
		voice.enabled=false;check(not voice.play_event("chosen",true),"Mute respected");voice.enabled=true
	for hero in [3,4]:
		voice.set_hero(hero);check(voice.bank.is_empty() and not voice.play_event("chosen",true),"Unrecorded heroes stay silent")
	voice.set_hero(0);voice.play_event("chosen",true);voice.set_hero(2)
	check(voice.player.stream==null and voice.current_event=="" and voice.pending=="","Switch clears old hero speech")
	voice.stop();voice.bank.clear();voice.free();voice=null
	await create_timer(.3).timeout
	print("SURVIVOR VOICES / ",checks," checks / ",failures," failures");quit(1 if failures else 0)
