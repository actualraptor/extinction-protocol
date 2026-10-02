extends SceneTree
var game
func _initialize():call_deferred("run")
func capture(name):
 await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://build/"+name+"-092.png")
func run():
 game=preload("res://scenes/main.tscn").instantiate();game.progress_path="res://build/stage-visual-profile.json";root.add_child(game);await create_timer(.3).timeout
 root.size=Vector2i(1280,800)
 for id in ["cradle","frostbreak","observatory"]:
  game.selected_map=id;game.chosen_mode="expedition";game.start_run();game.paused=true;game.map_menu();game.paused=true;await create_timer(.2).timeout
  var atlas=game.menu_root.get_child(0)
  for item in game.sim.stage_objects:
   assert(atlas.rect.has_point(atlas.map_point(item.p)))
   var click=InputEventMouseButton.new();click.pressed=true;click.button_index=MOUSE_BUTTON_LEFT;click.position=atlas.map_point(item.p);atlas._gui_input(click);assert(game.sim.waypoint==item.p)
  await capture("atlas-"+id)
  game.resume();game.paused=true;game.sim.pos=game.sim.stage_objects[0].p+Vector2(0,130);game.world.camera_pos=game.sim.pos;await create_timer(.2).timeout;await capture("route-"+id)
 game.selected=2;game.selected_map="cradle";game.start_run();game.paused=true
 for direction in [Vector2.DOWN,Vector2.RIGHT,Vector2.UP]:
  game.sim.time+=1;game.sim.pos+=direction*20
  game.world.camera_pos=game.sim.pos;await create_timer(.12).timeout;await capture("vesper-"+str(direction))
 game.characters();await create_timer(.2).timeout;await capture("vesper-portrait")
 print("STAGE VISUAL / all map objectives project and pin; three routes and Vesper facings rendered")
 game.release_run();quit()
