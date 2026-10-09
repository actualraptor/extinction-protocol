extends SceneTree

func _initialize():
	call_deferred("run")

func run():
	var main=load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.audio.enabled=false
	main.audio.music_enabled=false
	main.progress_path="res://build/performance-profile.json"
	main.start_run()
	main.sim.spawn_boss(3 if "--performance-meteor" in OS.get_cmdline_user_args() else 1 if "--triceratops-rig-test" in OS.get_cmdline_user_args() else 2)
	main.sim.invul=9999
	if "--performance-horde" in OS.get_cmdline_user_args():
		for index in range(400):
			main.sim.spawn_enemy(false,main.sim.pos+Vector2.from_angle(index*2.39996)*(100+index%12*30),0,false)
	var samples=[]
	var previous=Time.get_ticks_usec()
	var started=previous
	while Time.get_ticks_usec()-started<20000000:
		await process_frame
		var now=Time.get_ticks_usec()
		if now-started>5000000:samples.append((now-previous)/1000.0)
		previous=now
	samples.sort()
	var sum_ms=0.0
	for value in samples:sum_ms+=value
	print("PERFORMANCE ",JSON.stringify({"frames":samples.size(),"mean_ms":sum_ms/max(1,samples.size()),"p95_ms":samples[int(samples.size()*.95)],"render_objects":Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),"render_primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)}))
	quit()
