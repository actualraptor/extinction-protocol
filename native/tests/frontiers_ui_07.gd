extends SceneTree
var game
var failures=0
func _initialize(): call_deferred("run")
func check(ok,message):
	if not ok:failures+=1
	print("PASS / " if ok else "FAIL / ",message)
func capture(name):
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+"-07.png")
func run():
	game=preload("res://scenes/main.tscn").instantiate()
	game.progress_path="res://build/frontiers-ui-save.json"
	var f=FileAccess.open(game.progress_path,FileAccess.WRITE)
	f.store_string(JSON.stringify({"version":1,"runs":0,"amber":0,"records":[]}));f.close()
	root.add_child(game)
	await create_timer(0.4).timeout
	check(game.audio.music_players.size()==11,"Nine combat cues plus menu streams loaded")
	game.characters()
	await capture("survivors")
	game.maps_menu()
	await capture("maps-locked")
	game.discovery_menu()
	await capture("objectives")
	game.start_run()
	game.sim.kills=250
	game.flush_campaign(true)
	check("map_frost" in game.save_data.unlocks,"Kill milestone persists immediately")
	game.flush_campaign(true)
	check(game.save_data.campaign.kills==250,"Repeated flush does not count kills twice")
	game.sim.campaign_bosses=1
	game.flush_campaign(true)
	check("map_observatory" in game.save_data.unlocks,"Boss milestone persisted")
	for entry in ["iona","orin"]:
		game.selected_map="frostbreak" if entry=="iona" else "observatory"
		game.start_run()
		var landmark=game.sim.landmarks.filter(func(m):return m.id==entry)[0]
		game.sim.pos=landmark.p
		game.sim.update_exploration()
		check(entry in game.save_data.unlocks,"Free discovery recruits "+entry)
	game.characters()
	await capture("survivors-unlocked")
	game.maps_menu()
	await capture("maps-unlocked")
	for map in ["frostbreak","observatory"]:
		game.selected=3 if map=="frostbreak" else 4
		game.selected_map=map
		game.start_run()
		game.sim.invul=999
		game.sim.next_boss=9999
		game.sim.weapons={"harpoon":{"level":6,"evolved":false,"timer":0},"lantern":{"level":6,"evolved":false,"timer":0},"glacier":{"level":6,"evolved":false,"timer":0},"sunbow":{"level":6,"evolved":false,"timer":0}}
		for depth in range(3):
			game.sim.depth=depth
			game.sim.level=40
			game.sim.xp_goal=99999
			game.sim.time=depth*300+120
			for i in range(20):
				var enemy=game.sim.spawn_enemy(false,Vector2.from_angle(i*TAU/20)*300,14+(i%2) if map=="frostbreak" else 16+(i%2),false)
				enemy.hp=5000
			await create_timer(0.7).timeout
			game.paused=true
			await capture(map+"-"+str(depth))
			check(game.audio.map_index==(1 if map=="frostbreak" else 2) and game.audio.biome==depth,"Music routing / %s / %s"%[map,depth])
			game.paused=false
	game.paused=true
	game.ledger_menu()
	await capture("new-weapons")
	game.load_progress()
	check(game.save_data.campaign.kills>=250 and "orin" in game.save_data.unlocks,"Progress reload retains milestones and discoveries")
	game.queue_free();game=null
	await process_frame
	await process_frame
	await process_frame
	print("FRONTIERS UI / ",failures," failures")
	quit(failures)
