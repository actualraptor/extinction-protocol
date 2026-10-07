extends SceneTree
const OUT="D:/Utveckling CODEX/Dummy test/native/build/epic-trailer-review/"
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1920,1080)
	var game=preload("res://scripts/main.gd").new();game.progress_path=OUT+"logo-test-profile.json";root.add_child(game)
	await process_frame
	for child in game.layer.get_children():
		if child.get_script()==preload("res://scripts/opening_story.gd"):child.queue_free()
	game.main_menu()
	for frame in range(3):await process_frame
	assert(game.menu_root.find_children("*","TextureRect",true,false).any(func(node):return node.texture==preload("res://scripts/official_brand.gd").LOGO))
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"official-logo-menu.png")
	var story=preload("res://scripts/opening_story.gd").new();story.external_clock=true;game.layer.add_child(story)
	await process_frame
	story.clock=61.8;story.update_frame()
	for frame in range(3):await process_frame
	assert(story.title.texture==preload("res://scripts/official_brand.gd").LOGO)
	assert(story.title.position.y+story.title.size.y<=story.stage.size.y)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"official-logo-intro.png")
	game.queue_free();await process_frame
	print("OFFICIAL BRAND: menu and final intro title share the approved logo; title stays inside cinematic bounds")
	quit()
