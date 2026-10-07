extends SceneTree
func _initialize():call_deferred("check")
func check():
	var scene=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child(scene)
	await process_frame
	scene.discovery_menu()
	await process_frame
	var archive=scene.menu_root.get_child(scene.menu_root.get_child_count()-1)
	for category in ["All","Survivors","Equipment","Maps","Relics","Combinations"]:
		archive.category=category;archive.build()
		await process_frame
	archive.category="All";archive.build()
	await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/discovery-grid-preview.png")
	print("DISCOVERY GRID: all six categories rendered successfully")
	quit()
