extends SceneTree
var checks=0
var failures=0
func check(ok,message):
 checks+=1
 if not ok:failures+=1;printerr("FAIL / ",message)
func _initialize():call_deferred("run")
func run():
 var parent=Control.new()
 root.add_child(parent)
 var button=Button.new();button.text="ENTER THE RIFT";parent.add_child(button)
 var background=preload("res://scripts/seasonal_menu.gd").create(parent)
 await process_frame
 check(parent.get_child(0)==background,"Seasonal background below controls")
 check(background.mouse_filter==Control.MOUSE_FILTER_IGNORE,"Decoration does not intercept clicks")
 var art=background.get_node("PaintedHauntedJungle")
 check(art.texture!=null,"Generated project-local background loads")
 check(art.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_COVERED,"Backdrop fills without letterboxing")
 check(art.material is ShaderMaterial,"Animated ambience attached")
 for resolution in [Vector2(1280,720),Vector2(1920,1080),Vector2(3440,1440)]:
  parent.size=resolution
  await process_frame
  check(background.size==resolution,"Background follows screen size")
  check(art.size==resolution,"Texture follows screen size")
 if "--screens" in OS.get_cmdline_user_args():
  root.size=Vector2i(1440,900);parent.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://build/seasonal-menu-background.png")
 print("SEASONAL MENU / %s checks / %s failures"%[checks,failures]);quit(1 if failures else 0)
