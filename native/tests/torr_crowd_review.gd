extends SceneTree
var game
func _initialize():call_deferred("run")
func run():
 var out="res://build"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--torr-capture-dir="):out=arg.trim_prefix("--torr-capture-dir=")
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
 game=preload("res://scenes/main.tscn").instantiate();game.progress_path=out.path_join("torr-crowd-private.json");root.add_child(game)
 await process_frame
 for child in game.layer.get_children():
  if child.get_script()!=null and child.get_script().resource_path=="res://scripts/opening_story.gd":child.queue_free()
 game.save_data.settings.sound=false;game.save_data.settings.music=false
 game.audio.enabled=false;game.audio.music_enabled=false;game.audio.shutdown();game.survivor_voice.enabled=false;game.survivor_voice.stop()
 if "torr" not in game.save_data.unlocks:game.save_data.unlocks.append("torr")
 game.selected=7;game.chosen_mode="expedition";game.start_run();game.paused=true
 var g=game.sim;var helper=load(get_script().resource_path.get_base_dir().path_join("torr_balance_review.gd")).new();helper.loadout(g,"orbit","EPIC");helper.free()
 g.invul=99999;g.halloween=false
 for i in 400:
  var e=g.spawn_enemy(false,g.pos+Vector2.from_angle(i*2.39996)*(100+i%15*25),i%19,false)
  e.hp=1e8;e.max_hp=e.hp
 var results=[]
 for cap in [30,144]:
  Engine.max_fps=cap
  var samples=[];var simulations=[];var started=Time.get_ticks_usec();var previous=started;var accumulator=0.0
  while (Time.get_ticks_usec()-started)/1e6<9:
   await process_frame
   var now=Time.get_ticks_usec();var dt=(now-previous)/1e6;previous=now;accumulator+=minf(dt,.1)
   if now-started>2000000:samples.append(dt*1000)
   for step in 2:
    if accumulator<1.0/30:break
    var simulation_started=Time.get_ticks_usec()
    g.tick(1.0/30,Vector2.RIGHT.rotated(g.time*.6));accumulator-=1.0/30
    simulations.append((Time.get_ticks_usec()-simulation_started)/1000.0)
   if g.choosing:g.choose(0)
  samples.sort()
  var row={"fps_cap":cap,"enemies":g.enemies.size(),"mean_ms":samples.reduce(func(total,value):return total+value,0.0)/maxi(1,samples.size()),"p95_ms":samples[int(samples.size()*.95)],"simulation_mean_ms":simulations.reduce(func(total,value):return total+value,0.0)/maxi(1,simulations.size()),"shots":g.shots.size(),"effects":g.god_state.effects.size(),"cpu":OS.get_processor_name(),"gpu":RenderingServer.get_video_adapter_name()}
  results.append(row);print("TORR CROWD / ",JSON.stringify(row))
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(out.path_join("torr-crowd-"+str(cap)+".png"))
 var f=FileAccess.open(out.path_join("torr-crowd-results.json"),FileAccess.WRITE);f.store_string(JSON.stringify(results,"  "));f.close()
 game.audio.shutdown();game.survivor_voice.stop();game.queue_free();game=null
 await create_timer(.3).timeout;quit()
