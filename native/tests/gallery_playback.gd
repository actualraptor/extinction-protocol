extends SceneTree
const OUT="D:/Utveckling CODEX/Dummy test/native/build/"
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1920,1080);root.content_scale_size=root.size
	var game=preload("res://scripts/main.gd").new();game.progress_path=OUT+"gallery-test-profile.json";root.add_child(game)
	await process_frame
	for child in game.layer.get_children():
		if child.get_script()==preload("res://scripts/opening_story.gd"):child.queue_free()
	await process_frame
	game.main_menu();game.save_data.campaign.erase("route_07");game.save_data.settings.erase("rite_07_seen");game.save_data.settings.erase("extinction_cinematic_seen")
	game.settings();await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"gallery-new-player.png")
	game.replay_cinematic("reveal");assert(game.page!="cinematic-gallery")
	game.save_data.campaign.route_07=true;game.save_data.settings.rite_07_seen=true;game.save_data.settings.extinction_cinematic_seen=true
	game.settings()
	await process_frame;await process_frame
	for child in game.menu_root.get_children():
		if child is ScrollContainer:child.scroll_vertical=10000
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"gallery-unlocked.png")
	var before=game.save_data.duplicate(true)
	for id in ["intro","reveal","thorn","hunt","warden","extinction"]:
		game.replay_cinematic(id);assert(game.page=="cinematic-gallery")
		await create_timer(.2).timeout
		if id=="extinction":await create_timer(5.3).timeout
		else:
			for child in game.layer.get_children():
				if child.has_method("finish") and child.get_script() in [preload("res://scripts/opening_story.gd"),preload("res://scripts/sequence_player.gd"),preload("res://scripts/first_rite_player.gd")]:child.finish()
		await process_frame
		assert(game.page!="cinematic-gallery")
		assert(game.save_data==before)
	game.audio.shutdown();game.queue_free();await process_frame
	print("GALLERY PLAYBACK: six unlocked replays return to Settings without changing progression; locked reveal rejected")
	quit()
