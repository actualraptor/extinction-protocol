extends SceneTree
var game
var corpse
var frame=0
var ready=false
func _initialize():call_deferred("begin")
func begin():
	root.size=Vector2i(1280,800);root.content_scale_size=root.size
	game=preload("res://scripts/main.gd").new()
	game.progress_path="res://build/parchment-ritual-review/isolated-profile.json"
	root.add_child(game);await process_frame
	for child in game.layer.get_children():
		if child.get_script()==preload("res://scripts/opening_story.gd"):child.queue_free()
	game.save_data.settings.sound=true;game.save_data.settings.music=false;game.apply_settings()
	game.selected=5;game.chosen_mode="safari";game.start_run();game.paused=true;game.clear_menu()
	var g=game.sim
	g.enemies.clear();g.weapons.clear();g.landmarks.clear();g.portal=null;g.hazards.clear();g.invul=1000
	g.pos=g.terrain.open_position(Vector2(2200,1700))
	g.spawn_boss(1);g.boss.p=g.pos+Vector2(0,-150)
	preload("res://scripts/remnant_system.gd").leave(g,g.boss)
	g.boss=null;g.enemies.clear();g.terrain.stage["landmarks"]=[];corpse=g.boss_corpses[0]
	g.pos=corpse.marker
	for i in range(8):g.spawn_enemy(false,corpse.p+Vector2.from_angle(i*TAU/8)*320,0,false)
	game.world.camera_pos=corpse.p+Vector2(0,30);game.world.camera_run=g;game.world.set_process(false)
	corpse.raising=true;ready=true
func _process(_dt):
	if not ready:return false
	frame+=1
	var raw=maxf(0,(frame-30)/30.0)
	var snap=preload("res://scripts/rite_animation.gd").split_time(0)
	var clock=raw-clampf(raw-snap,0,.075)
	if raw>=snap and raw-1.0/30<snap:
		game.world.fx("rite_snap",corpse.p,Color("bfffd9"),corpse.size*3.2)
		game.sim.sound.emit("rite_crunch")
	corpse.ritual=minf(preload("res://scripts/rite_animation.gd").DURATION-.02,clock);corpse.stain_time=corpse.ritual
	game.sim.time=clock;game.sim.landmarks.clear();game.sim.update_enemies(1.0/30)
	game.world._process(1.0/30)
	game.world.camera_pos=corpse.p+Vector2(0,30)
	game.world.queue_redraw()
	if frame==180:snapshot.call_deferred()
	if frame==600:
		print("PARCHMENT PREVIEW: full ritual with live enemies rendered")
		quit()
	return false
func snapshot():
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/parchment-ritual-review/ritual-preview.png")
