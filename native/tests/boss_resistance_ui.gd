extends SceneTree
const DR=preload("res://scripts/boss_resistance.gd")
var failures=0
var checks=0
func _initialize():call_deferred("run")
func run():
 var game=preload("res://scenes/main.tscn").instantiate();game.progress_path="res://build/boss-dr-ui-isolated.json";root.add_child(game)
 await create_timer(.3).timeout
 game.start_run();game.paused=true
 for stage in [1,2,3]:
  game.sim.enemies.clear();game.sim.anchors.clear();game.sim.spawn_boss(stage);game.sim.boss_time=4
  for exposed in [false,true]:
   if exposed:
    game.sim.boss.exposed=2
    if stage==3:game.sim.anchors.clear();game.sim.core_time=12
   game._process(0)
   await create_timer(.05).timeout
   var bar=game.boss_bar;var font=preload("res://scripts/ui_art.gd").body_font()
   checks+=1
   if font.get_string_size(bar.resistance_text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x>bar.size.x*.667:
    failures+=1;printerr("Resistance caption clips / ",bar.resistance_text)
   checks+=1
   if bar.resistance_text!=DR.caption(game.sim,game.sim.boss):failures+=1
   if DisplayServer.get_name()!="headless":
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://build/boss-dr-%s-%s.png"%[stage,int(exposed)])
 game.release_run();game.queue_free();await process_frame;print("BOSS DR UI / %s checks / %s failures"%[checks,failures]);quit(1 if failures else 0)



