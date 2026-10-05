extends SceneTree
var game
func _initialize():call_deferred("run")
func capture(name):
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/harvest-"+name+".png")
func run():
 game=preload("res://scenes/main.tscn").instantiate()
 game.progress_path="res://build/harvest-visual-profile.json"
 root.add_child(game);await create_timer(.3).timeout
 game.save_data.unlocks=game.Discoveries.ENTRIES.keys()
 game.save_data.discoveries=game.Discoveries.ENTRIES.keys()
 root.size=Vector2i(1280,800)
 game.save_data.settings.halloween=true
 for hero in [1,2]:
  game.selected=hero;game.chosen_mode="expedition";game.start_run();game.paused=true
  game.sim.enemies.clear()
  game.sim.stage_objects.clear();game.sim.landmarks.clear();game.sim.cache_timer=999;game.sim.shrine_done=true
  game.world.camera_pos=game.sim.pos
  await create_timer(.2).timeout
  await capture("survivor-"+str(hero))
 for map_id in ["cradle","frostbreak","observatory"]:
  for stage in [1,2]:
   game.selected_map=map_id;game.start_run();game.paused=true
   assert(game.sim.map_id==map_id)
   game.sim.enemies.clear();game.sim.spawn_boss(stage)
   game.sim.BossEncounters.prepare(game.sim)
   game.world.camera_pos=game.sim.pos
   await create_timer(.15).timeout
   await capture(map_id+"-"+str(stage))
 for resolution in [Vector2i(1280,720),Vector2i(3440,1440)]:
  root.size=resolution
  game.sim.choosing=false;game.sim.open_choices(false)
  await create_timer(.45).timeout
  await capture("upgrades-"+str(resolution.x))
 game.settings();await create_timer(.2).timeout;await capture("settings")
 game.maps_menu();await create_timer(.2).timeout;await capture("maps")
 game.main_menu();await create_timer(.3).timeout;await capture("main-menu")
 game.release_run();game.queue_free();await process_frame
 print("HARVEST VISUAL / survivor, six boss windups, upgrade layouts and settings rendered")
 quit()
