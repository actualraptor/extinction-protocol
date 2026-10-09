extends SceneTree
func _initialize():call_deferred("run")
func run():
	var main=load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.audio.enabled=false;main.audio.music_enabled=false
	main.progress_path="res://build/boss-model-sequence-profile.json"
	main.selected=1;main.start_run();main.sim.invul=99999
	main.world.rig_bosses=true
	var layer=null
	for child in main.world.get_children():
		if child.get_script()==load("res://scripts/readability.gd"):layer=child
	assert(layer!=null)
	var previous=null
	for stage in [1,2,1,2]:
		main.sim.spawn_boss(stage)
		await process_frame
		await process_frame
		var expected="triceratops-painted-rig.glb" if stage==1 else "trex-painted-articulated.glb"
		assert(layer.boss_model.source.ends_with(expected))
		assert(layer.boss_model.force_triceratops==(stage==1))
		assert(layer.boss_model_identity==("thorn" if stage==1 else "basalt"))
		if is_instance_valid(previous):assert(previous!=layer.boss_model)
		previous=layer.boss_model
		print("MODEL_SEQUENCE / stage ",stage," / ",layer.boss_model.source)
		if "--capture-model-sequence" in OS.get_cmdline_user_args():
			for frame in range(30):await process_frame
			await RenderingServer.frame_post_draw
			var output=OS.get_environment("EP_BOSS_CAPTURE_DIR")
			assert(not output.is_empty())
			assert(root.get_texture().get_image().save_png(output.path_join("boss-stage-%s.png"%stage))==OK)
	main.release_run()
	main.queue_free()
	await process_frame
	print("BOSS_MODEL_SEQUENCE_PASS: Triceratops -> T-rex -> Triceratops -> T-rex")
	quit()
