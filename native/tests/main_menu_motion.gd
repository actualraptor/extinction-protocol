extends SceneTree
var frame=0
var game
func _initialize():call_deferred("begin")
func begin():
 root.size=Vector2i(1920,1080)
 game=preload("res://scripts/main.gd").new();game.progress_path="res://build/main-menu-review/motion-profile.json";root.add_child(game)
 await process_frame
 for child in game.layer.get_children():
  if child.get_script()==preload("res://scripts/opening_story.gd"):child.queue_free()
 game.save_data.settings.sound=false;game.save_data.settings.music=false;game.apply_settings();game.main_menu()
func _process(_dt):
 frame+=1
 if frame==300:quit()
 return false
