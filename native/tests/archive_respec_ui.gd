extends SceneTree
var checks=0
var fails=0
func check(ok,text):
 checks+=1
 if not ok:fails+=1;printerr("FAIL / ",text)
func _initialize():call_deferred("run")
func inspect(node):
 if node is Button and node.visible:
  var font=node.get_theme_font("font");var fs=node.get_theme_font_size("font_size")
  var inset=node.get_theme_stylebox("normal").get_minimum_size()
  var w=node.size.x-inset.x-8-(54 if node.icon!=null else 0)
  for line in node.text.split("\n"):check(font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x<=w+2,"Button text width / "+line)
  check(font.get_height(fs)*node.text.split("\n").size()<=node.size.y-inset.y+2,"Button text height / "+node.text)
 for child in node.get_children():inspect(child)
func run():
 var game=preload("res://scenes/main.tscn").instantiate();game.progress_path="res://build/archive-ui-isolated.json";root.add_child(game)
 await create_timer(.3).timeout
 game.save_data.amber=999999
 for resolution in [Vector2i(1024,640),Vector2i(3440,1440)]:
  DisplayServer.window_set_size(resolution)
  await create_timer(.1).timeout
  for screen in ["research","discoveries","refund"]:
   if screen=="research":game.research_menu()
   elif screen=="discoveries":game.discovery_menu()
   else:game.archive_refund_menu(false)
   await create_timer(.2).timeout
   inspect(game.menu_root)
   if screen=="research":
    var icons=0
    for child in game.menu_root.get_children():
     if child is GridContainer:
      for button in child.get_children():
       check(button.icon!=null,"Research painted icon")
       check((game.menu_root.get_global_transform().affine_inverse()*button.get_global_rect().end).y<780,"Research grid clears footer")
       icons+=1
    check(icons==game.C.RESEARCH.size(),"Every research upgrade covered")
   if DisplayServer.get_name()!="headless":
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://build/archive-%s-%s.png"%[screen,resolution.x])
 game.release_run();print("ARCHIVE UI / %s checks / %s failures"%[checks,fails]);quit(1 if fails else 0)

