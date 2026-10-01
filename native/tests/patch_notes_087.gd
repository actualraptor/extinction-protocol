extends SceneTree
var game
func _initialize():call_deferred("run")
func run():
 game=preload("res://scenes/main.tscn").instantiate();game.progress_path="res://build/notes086-save.json";root.add_child(game)
 await create_timer(0.4).timeout
 root.size=Vector2i(1440,900)
 game.patch_notes()
 await create_timer(0.4).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://../dist/Extinction-Protocol-0.8.7-Patch-Notes.png")
 game.main_menu()
 await create_timer(0.3).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/news-menu-086.png")
 print("PATCH NOTES / opened and returned to menu")
 quit()
