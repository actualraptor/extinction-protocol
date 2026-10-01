extends SceneTree
var game
var failures=0
var checks=0
func _initialize():call_deferred("run")
func check(ok,msg):
 checks+=1
 if not ok:failures+=1;print("FAIL / ",msg)
func inspect(node,context):
 for c in node.get_children():
  if c is Button and c.is_visible_in_tree():
   var f=c.get_theme_font("font");var sz=c.get_theme_font_size("font_size");var interior=c.size-c.get_theme_stylebox("normal").get_minimum_size()
   var needed=f.get_multiline_string_size(c.text,HORIZONTAL_ALIGNMENT_LEFT,-1,sz)
   check(needed.x<=interior.x+2 and needed.y<=interior.y+2,context+" button text: "+c.text.left(60))
  if c is Label and c.is_visible_in_tree():
   var font=c.get_theme_font("font");var fs=c.get_theme_font_size("font_size")
   var need=font.get_multiline_string_size(c.text,HORIZONTAL_ALIGNMENT_LEFT,c.size.x,fs) if c.autowrap_mode!=TextServer.AUTOWRAP_OFF else font.get_multiline_string_size(c.text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs)
   check(c.clip_text or need.x<=c.size.x+2,context+" text width: "+c.text.left(70))
   check(need.y<=c.size.y+3,context+" text height: "+c.text.left(70)+str([need,c.size]))
  if c is Control and c.is_visible_in_tree() and not c is ColorRect and not c is ScrollBar:
   var inside_scroll=false;var p=c.get_parent()
   while p!=game.menu_root and p!=null:
    if p is ScrollContainer:inside_scroll=true
    p=p.get_parent()
   if not inside_scroll:check(Rect2(Vector2.ZERO,root.get_visible_rect().size).grow(2).encloses(c.get_global_rect()),context+" screen: "+c.get_class()+" "+(c.text.left(60) if c is Label or c is Button else str(c.get_global_rect())))
  inspect(c,context)
func run():
 game=preload("res://scenes/main.tscn").instantiate();game.progress_path="res://build/layout-private-save.json";root.add_child(game)
 await create_timer(.3).timeout
 for res in [Vector2i(1024,640),Vector2i(1280,720),Vector2i(3440,1440)]:
  root.size=res
  for method in ["main_menu","characters","maps_menu","research_menu","discovery_menu","manual","settings","daily_menu","daily_records_menu","patch_notes"]:
   game.call(method);await create_timer(.12).timeout
   inspect(game.menu_root,str(res)+" "+method)
   if "--screens" in OS.get_cmdline_user_args() and method in ["characters","research_menu","patch_notes"]:
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://build/private-ui-"+str(res.x)+"-"+method+".png")
 game.chosen_mode="safari";game.start_run();game.paused=true
 for method in ["ledger_menu","summary"]:
  game.call(method);await create_timer(.12).timeout;inspect(game.menu_root,method)
 for res in [Vector2i(1024,640),Vector2i(1280,720),Vector2i(1920,1080),Vector2i(3440,1440)]:
  root.size=res
  game.clear_menu();game.page="run";game.sim.active=true;game.sim.score=999999999;game.sim.amber=999999;game.sim.time=35999;game.sim.mode="daily";game.sim.daily_loop=99
  for factor in [.65,1.0,1.35]:
   game.save_data.settings.hud_scale=factor
   await create_timer(.08).timeout
   for c in [game.timer_label,game.biome_label,game.score_label,game.loadout_label]:
    var need=c.get_theme_font("font").get_multiline_string_size(c.text,HORIZONTAL_ALIGNMENT_LEFT,-1,c.get_theme_font_size("font_size"))
    check(need.x<=c.size.x+2 and need.y<=c.size.y+2,"HUD stress actual text "+c.text)
    check(root.get_visible_rect().encloses(c.get_global_rect()),"HUD stress screen bounds")
 game.release_run();await process_frame;game.queue_free();await process_frame;print("PRIVATE UI / ",checks," checks / ",failures," failures");quit(1 if failures else 0)




