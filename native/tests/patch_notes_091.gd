extends SceneTree
var game
func _initialize():call_deferred("run")
func run():
 game=preload("res://scenes/main.tscn").instantiate();game.progress_path="res://build/notes091-profile.json";root.add_child(game)
 await create_timer(.3).timeout
 root.size=Vector2i(1440,1500);root.content_scale_size=Vector2i(1440,1500)
 game.set_process(false);game.clear_menu();game.menu_root.position=Vector2.ZERO
 game.shade(.97)
 var crest=game.UIArt.plate(game.menu_root,2,Rect2(120,0,1200,650))
 var cover=ColorRect.new();cover.color=Color("090f0d");cover.position=Vector2(0,175);cover.size=Vector2(1440,1325);game.menu_root.add_child(cover)
 var title=game.label(game.menu_root,"EXTINCTION PROTOCOL",39,"eddbb5");title.position=Vector2(80,190)
 var version=game.label(game.menu_root,"0.9.1  /  COMMIT TO THE BUILD",23,"c3a16b");version.position=Vector2(80,251)
 var grid=GridContainer.new();grid.columns=2;grid.position=Vector2(75,323);grid.size=Vector2(1290,1010);grid.add_theme_constant_override("h_separation",26);grid.add_theme_constant_override("v_separation",26);game.menu_root.add_child(grid)
 for entry in game.PatchNotes.ENTRIES:
  var panel=PanelContainer.new();panel.custom_minimum_size=Vector2(632,325);panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.add_theme_stylebox_override("panel",game.UIArt.button_style());grid.add_child(panel)
  var col=VBoxContainer.new();col.add_theme_constant_override("separation",14);panel.add_child(col)
  game.Icons.control(col,entry.icon,entry.get("category","weapon"),62)
  var heading=game.label(col,entry.title,24,"dec28d");heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  var body=game.label(col,entry.body,21,"c9c9b9");body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 game.label(game.menu_root,"GUNS. ANCIENT FURY. FORBIDDEN MAGIC.",16,"aa9162").position=Vector2(80,1405)
 await create_timer(.3).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://../dist/Extinction-Protocol-0.9.1-Patch-Notes.png")
 for p in grid.get_children():
  assert(p.size.y<=330,"Patch note card grew beyond safe row")
 print("PATCH NOTES 0.9.1 / full six-section native artwork PNG rendered")
 game.queue_free();await process_frame;quit()

