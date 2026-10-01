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
 root.get_texture().get_image().save_png("res://../dist/Extinction-Protocol-0.9.0-Patch-Notes.png")
 for i in range(game.PatchNotes.releases().size()):
  game.patch_notes(i)
  await process_frame
  await process_frame
  assert(game.page=="patch_notes")
 game.main_menu()
 await create_timer(0.3).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/news-menu-086.png")
 print("PATCH NOTES / opened and returned to menu")
 quit()
