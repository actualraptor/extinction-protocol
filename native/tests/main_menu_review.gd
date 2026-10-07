extends SceneTree
var game
var frame=0
func _initialize():call_deferred("begin")
func begin():
 root.size=Vector2i(1920,1080)
 game=preload("res://scripts/main.gd").new();game.progress_path="res://build/main-menu-review/isolated-profile.json";root.add_child(game)
 await process_frame
 for child in game.layer.get_children():
  if child.get_script()==preload("res://scripts/opening_story.gd"):child.queue_free()
 game.save_data.settings.sound=false;game.save_data.settings.music=false;game.apply_settings();game.main_menu()
 for label in ["Permanent upgrades","Discoveries","Field manual","Settings","Daily challenge","Patch notes"]:
  for i in range(3):await process_frame
  var buttons=game.menu_root.find_children("*","Button",true,false)
  var matched=buttons.filter(func(b):return b.text==label)
  assert(matched.size()==1);matched[0].pressed.emit()
  assert(not game.menu_root.is_ancestor_of(matched[0]),"Menu action must replace main menu controls")
  game.main_menu()
 for dimensions in [Vector2i(1280,800),Vector2i(1920,1080),Vector2i(2560,1440)]:
  root.size=dimensions
  for i in range(4):await process_frame
  for b in game.menu_root.find_children("*","Button",true,false):
   var r=b.get_global_rect()
   assert(r.position.x>=0 and r.position.y>=0 and r.end.x<=game.get_viewport_rect().size.x+1 and r.end.y<=game.get_viewport_rect().size.y+1,"Menu buttons must remain in viewport")
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://build/main-menu-review/menu-%sx%s.png"%[dimensions.x,dimensions.y])
 print("MAIN MENU: navigation callbacks and 1280/1920/2560 layouts passed")
 quit()
