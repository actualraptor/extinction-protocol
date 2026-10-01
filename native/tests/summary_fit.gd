extends SceneTree
var game
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok,message):
 checks+=1
 if not ok:failures+=1;print("FAIL / ",message)
func run():
 game=preload("res://scenes/main.tscn").instantiate();game.progress_path="res://build/summary-fit-profile.json";root.add_child(game)
 await create_timer(.2).timeout
 game.chosen_mode="safari";game.start_run();game.paused=true
 game.sim.damage_by_weapon={"lightning":987654321,"frost":654321987,"fire":456789123,"thorns":234567891,"mortar":123456789};game.sim.damage_total=2456790111
 game.sim.score=999999999;game.sim.kills=999999;game.sim.best_streak=999999;game.sim.amber=999999
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(3440,1440)]:
  root.size=resolution
  for factor in [.65,1.0,1.35]:
   game.save_data.settings.hud_scale=factor;game.summary();await create_timer(.1).timeout
   var content=game.menu_root.get_node("SummaryContent")
   check(not game.hud_root.visible,"Gameplay HUD stays hidden on scoreboard")
   check(root.get_visible_rect().encloses(content.get_global_rect()),"Content fits screen")
   for child in content.get_children():
    if child is Control:check(content.get_global_rect().encloses(child.get_global_rect()),"Safe art inset / "+str(child.name))
    if child is Label:
     var need=child.get_theme_font("font").get_multiline_string_size(child.text,HORIZONTAL_ALIGNMENT_LEFT,-1,child.get_theme_font_size("font_size"))
     check(need.x<=child.size.x+1 and need.y<=child.size.y+1,"Text fits / "+child.text)
   if factor==1.0 and "--screens" in OS.get_cmdline_user_args():
    await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://build/summary-fit-"+str(resolution.x)+".png")
 game.release_run();game.queue_free();await process_frame
 print("SUMMARY SAFE INSET / ",checks," checks / ",failures," failures");quit(1 if failures else 0)
