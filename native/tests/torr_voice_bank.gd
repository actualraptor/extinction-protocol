extends SceneTree
const V=preload("res://scripts/survivor_voice.gd")
const C=preload("res://scripts/catalog.gd")
var checks=0
var failures=0
func check(ok,message):
	checks+=1
	if not ok:failures+=1;printerr("FAIL: ",message)
func _initialize():call_deferred("run")
func run():
	preload("res://scripts/content_extension.gd").install(C)
	var voice=V.new();voice.seed_value=171026;root.add_child(voice)
	# Exercise future catalog registration without adding an unfinished hero to menus.
	var index=C.HEROES.size()
	C.HEROES.append({"name":"TORR STORMBUK","voice_key":"torr"})
	voice.set_hero(index)
	check(voice.hero_key=="torr","Catalog voice key routes to Torr")
	check(voice.bank.size()==11,"All eleven Torr event banks loaded")
	var total=0
	for event in voice.hero_registry.torr:
		check(voice.bank[event].size()==voice.hero_registry.torr[event],"All supplied variants load")
		for clip in voice.bank[event]:
			total+=1
			check(clip.get_length()>.1 and clip.resource_path.contains("/torr/"),"Torr clip loaded with positive duration")
		var last=-1
		for i in range(20):
			var pick=voice.pick_variant(event)
			check(pick>=0 and pick<voice.bank[event].size() and pick!=last,"Event randomization avoids immediate repeat")
			last=pick
	check(total==33,"33 randomized recordings")
	check(voice.bank.hurt.size()==3,"Three supplied hurt variants supported")
	for event in ["orbit_started","orbit_added","stormload","final_evolution"]:
		voice.reset_run();check(voice.eligible(event,1000),"Torr-specific event eligible")
		voice.last_attempt[event]=1000
		check(not voice.eligible(event,1000.1),"Special-event attempts respect cooldown")
	voice.reset_run()
	check(voice.play_event("boss_spawn",true),"Actual silent playback starts")
	await process_frame
	check(voice.player.playing,"Godot player is decoding Torr audio")
	check(voice.play_event("boss_killed",true) and voice.pending=="boss_killed","Boss kill queues")
	check(voice.play_event("death",true) and voice.pending=="","Death interrupts and clears queue")
	voice.reset_run();voice.enabled=false
	check(not voice.play_event("chosen",true),"Voice mute respected")
	voice.enabled=true;voice.set_hero(0)
	check(voice.hero_key=="voss" and voice.current_event.is_empty(),"Switching hero resets speech")
	for event in ["orbit_started","orbit_added","stormload","final_evolution"]:
		check(not voice.eligible(event,1000),"Torr event cannot leak to another survivor")
	check(not voice.eligible("first_summon",1000),"Army event remains profile gated")
	voice.hero_key="07"
	check(voice.eligible("first_summon",1000),"Existing army event remains supported")
	for name in ["torr_story_mortal_1","torr_story_mortal_2","torr_story_mortal_3","narrator_torr_mortal_1","narrator_torr_mortal_2","narrator_torr_mortal_3"]:
		var clip=load("res://assets/audio/torr-story/"+name+".mp3")
		check(clip!=null and clip.get_length()>.1,"Fixed story cue imports")
	for name in ["haft_creak","haft_break","wood_debris","godforge_chime","distant_thunder"]:
		var clip=load("res://assets/audio/torr-story/torr_"+name+".wav")
		check(clip!=null and clip.get_length()>.1,"Story foley imports")
	C.HEROES.remove_at(index)
	voice.stop();voice.bank.clear();voice.free();voice=null
	await create_timer(.3).timeout
	await process_frame
	print("TORR AUDIO / ",checks," checks / ",failures," failures; 33 randomized barks, six fixed cues, five effects")
	quit(1 if failures else 0)
