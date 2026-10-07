extends SceneTree
const R=preload("res://scripts/remnant_system.gd")
const OUT="D:/Utveckling CODEX/Dummy test/native/build/"
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1920,1080);root.content_scale_size=root.size
	var game=preload("res://scripts/main.gd").new();game.progress_path=OUT+"ground-mobs-profile.json";root.add_child(game)
	await process_frame
	for child in game.layer.get_children():
		if child.get_script()==preload("res://scripts/opening_story.gd"):child.queue_free()
	game.selected=5;game.chosen_mode="safari";game.start_run();game.paused=true;game.clear_menu()
	var g=game.sim;g.enemies.clear();g.weapons.clear();g.invul=1000;g.landmarks.clear();g.portal=null
	g.spawn_boss(1);g.boss.p=g.pos+Vector2(0,-150);R.leave(g,g.boss);g.boss=null;g.enemies.clear()
	var corpse=g.boss_corpses[0];corpse.raising=true;corpse.ritual=4;corpse.stain_time=4
	for n in range(14):g.spawn_enemy(false,corpse.p+Vector2.from_angle(n*2.399)*120,0,false)
	for frame in range(3):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"ritual-ground-mobs-active.png")
	corpse.consumed=true;corpse.ritual=R.RITUAL;corpse.stain_time=R.RITUAL;R.update(g,60)
	assert(corpse.stain_time==R.RITUAL and corpse.consumed)
	var decoration=game.world.get_children().filter(func(node):return node.get_script()==preload("res://scripts/ritual_ground.gd"))[0]
	assert(decoration.z_index==-1 and decoration is Node2D and not decoration is CollisionObject2D)
	var initial=g.enemies[0].p
	for frame in range(45):g.update_enemies(1.0/60);await process_frame
	assert(g.enemies[0].p.distance_to(initial)>1)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"ritual-ground-mobs-settled.png")
	game.sim=null;game.queue_free();await process_frame
	print("RITUAL GROUND: persistent after completion and 60 seconds; mobs move across decorations; separate layer below actors")
	quit()
