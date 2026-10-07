extends Node
# Private audition build; every test uses an isolated progression file.
const MAPS=["cradle","frostbreak","observatory"]
const BOSSES=[["thorn","basalt"],["hunt","aurora"],["warden","bloom"]]
var game
var current_map="cradle"
var current_stage=0
var immortal=true
var caption

func _ready():
	game.save_data.unlocks=["map_frost","map_observatory"]
	game.save_data.settings.halloween=false
	game.save_data.settings.opening_0120_seen=true
	game.apply_settings()
	show_selector()
	if "--verify-soundtrack-package" in OS.get_cmdline_user_args():call_deferred("verify")

func show_selector():
	game.main_menu();game.clear_menu();game.shade(.9)
	game.page="soundtrack-selector"
	var title=game.label(game.menu_root,"SOUNDTRACK PLAY TEST",36,"f2d299")
	title.position=Vector2(145,100)
	var help=game.label(game.menu_root,"Choose a map or boss. Separate save; every encounter is available.\nF1: selector / F2: restart / F3: invulnerability / F4: toggle sound effects",20,"c5d5d9")
	help.position=Vector2(145,155)
	for index in range(3):
		var map_id=MAPS[index]
		var column=game.column(game.menu_root,Vector2(145+index*390,260),Vector2(365,370),22)
		game.label(column,game.Maps.DATA[map_id].name,22,"f2d299")
		game.button(column,"REGULAR MAP MUSIC",func():launch(map_id,0))
		for stage in [1,2]:
			var boss_id=BOSSES[index][stage-1]
			var name=preload("res://scripts/boss_identity.gd").short_name(boss_id)
			game.button(column,name,func():launch(map_id,stage))
	var footer=game.column(game.menu_root,Vector2(145,590),Vector2(1145,220),15)
	game.button(footer,"THE EXTINCTION ENGINE / FULL 3:30 ORCHESTRAL SCORE",func():launch("cradle",3))
	game.button(footer,"OFFICIAL MAIN MENU / HEAR MENU THEME",func():game.main_menu())
	game.label(footer,"In a boss test: F5 defeats boss / Meteor: F6 jumps to 1:00 remaining, F7 to 0:15 remaining",18,"b5cdd1")

func launch(map_id:String,stage:int):
	current_map=map_id;current_stage=stage
	for player in game.audio.music_players:
		player.stop();player.stream_paused=false;player.volume_db=-80
	game.audio.meteor_started=false
	game.selected=1;game.chosen_mode="expedition";game.selected_map=map_id
	game.start_run()
	var g=game.sim
	g.choice_requested.disconnect(game.present_upgrade)
	g.choice_requested.connect(func(_options,_chest):call_deferred("auto_upgrade",g))
	g.hp=2000;g.max_hp=2000;g.level=12;g.base_damage=1.0
	g.weapons={"club":{"level":6,"evolved":false,"timer":0.0,"casts":0},"lightning":{"level":4,"evolved":false,"timer":0.3,"casts":0},"frost":{"level":4,"evolved":false,"timer":0.6,"casts":0}}
	g.next_boss=1000000.0
	if stage>0:
		g.enemies.clear();g.boss=null;g.anchors.clear()
		g.spawn_boss(stage)
		if stage<3:g.boss.hp*=8;g.boss.max_hp=g.boss.hp
		g.build_grid()
	game.audio.biome=g.depth;game.audio.map_index=game.Maps.DATA[map_id].music
	game.audio.set_encounter("meteor" if stage==3 else BOSSES[MAPS.find(map_id)][stage-1] if stage>0 else "",0,false)
	game.clear_menu()
	caption=game.label(game.menu_root,"",17,"e7e0c6")
	caption.position=Vector2(25,200);caption.size=Vector2(1250,80)
	update_caption()

func auto_upgrade(run):
	if game.sim==run and run.choosing and not run.options.is_empty():game.finish_upgrade(0)

func update_caption():
	if not is_instance_valid(caption):return
	caption.text="SOUNDTRACK TEST / %s / %s\nF1 selector · F2 restart · F3 invulnerability %s · F4 SFX %s · F5 defeat boss\nMeteor: F6 final minute · F7 final 15 seconds"%[game.Maps.DATA[current_map].name,"REGULAR MAP" if current_stage==0 else game.Maps.boss_name(current_map,current_stage),"ON" if immortal else "OFF","ON" if game.audio.enabled else "OFF"]

func _unhandled_input(event):
	if not event is InputEventKey or not event.pressed or event.echo:return
	match event.keycode:
		KEY_F1:show_selector()
		KEY_F2:launch(current_map,current_stage)
		KEY_F3:immortal=not immortal;update_caption()
		KEY_F4:
			game.save_data.settings.sound=not game.save_data.settings.sound
			game.apply_settings();update_caption()
		KEY_F5:
			if game.sim!=null and game.sim.boss!=null:game.sim.kill(game.sim.boss)
		KEY_F6:seek_meteor(150)
		KEY_F7:seek_meteor(195)
		_:return
	game.get_viewport().set_input_as_handled()

func seek_meteor(seconds:float):
	if game.sim==null or game.sim.boss==null or game.sim.boss_stage!=3:return
	game.sim.boss_time=seconds
	game.audio.encounter_time=seconds
	game.audio.music_players[10].seek(seconds)
	game.audio.meteor_started=true

func _process(_dt):
	if game.sim!=null and immortal:
		game.sim.invul=1.0;game.sim.hp=game.sim.max_hp

func verify():
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		game.get_viewport().get_texture().get_image().save_png(OS.get_executable_path().get_base_dir().path_join("soundtrack-selector-preview.png"))
	for index in range(3):
		for stage in [0,1,2]:
			launch(MAPS[index],stage)
			await get_tree().create_timer(.15).timeout
			var expected=1+index if stage==0 else 4+index*2+stage-1
			assert(game.sim.map_id==MAPS[index] and game.audio.selected_music_index()==expected)
			assert(game.audio.music_players[expected].playing)
			print("PASS packaged selection / ",MAPS[index]," / stage ",stage)
	launch("cradle",3)
	await get_tree().create_timer(.2).timeout
	assert(not game.audio.music_players[10].stream.loop and game.audio.music_players[10].playing)
	seek_meteor(150)
	await get_tree().create_timer(.1).timeout
	assert(absf(game.audio.music_players[10].get_playback_position()-game.sim.boss_time)<.4)
	game.paused=true
	await get_tree().create_timer(.15).timeout
	var frozen=game.sim.boss_time
	await get_tree().create_timer(.15).timeout
	assert(game.sim.boss_time==frozen and game.audio.music_players[10].stream_paused)
	game.paused=false;seek_meteor(195)
	await get_tree().create_timer(.15).timeout
	assert(not game.audio.music_players[10].stream_paused)
	game.sim.kill(game.sim.boss)
	await get_tree().create_timer(.15).timeout
	assert(game.audio.selected_music_index()!=10)
	show_selector()
	await get_tree().create_timer(.15).timeout
	assert(game.audio.selected_music_index()==0)
	print("PASS packaged meteor / sync, pause, resume, early victory and selector return")
	game.audio.shutdown();game.survivor_voice.stop();game.release_run()
	await get_tree().create_timer(.25).timeout
	game.get_tree().quit()
