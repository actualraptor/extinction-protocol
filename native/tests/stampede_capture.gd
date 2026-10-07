extends SceneTree
var game
var frame=0
var ready=false
var initial_player
var targets=[]
var initial_targets=[]
func _initialize():call_deferred("begin")
func begin():
 root.size=Vector2i(1280,800)
 game=preload("res://scripts/main.gd").new()
 game.progress_path="res://build/stampede-review/isolated-profile.json"
 root.add_child(game)
 await process_frame
 for child in game.layer.get_children():
  if child.get_script()==preload("res://scripts/opening_story.gd"):child.queue_free()
 game.save_data.settings.music=false;game.save_data.settings.sound=false;game.apply_settings()
 game.selected=1;game.selected_map="cradle";game.chosen_mode="expedition";game.start_run();game.paused=true
 var g=game.sim
 g.weapons.clear();g.enemies.clear();g.landmarks.clear();g.time=preload("res://scripts/horde_director.gd").EVENTS[0].at+0.001;g.rng.seed=32011
 g.pos=g.terrain.open_position(Vector2.ZERO);initial_player=g.pos
 g.director.update(g,.001);g.director.flow_direction=Vector2.RIGHT;g.director.flow_origin=g.pos
 for i in range(8):
  var e=g.spawn_enemy(false,g.pos+Vector2(-180+i*48,65 if i%2==0 else -65),0,false)
  e.speed=0;e.attack=100;e.hp=1000;targets.append(e);initial_targets.append(e.p)
 game.world.camera_pos=g.pos;game.world.camera_run=g
 ready=true
func _process(_dt):
 if not ready:return false
 var g=game.sim
 g.time+=1.0/30;g.invul=maxf(0,g.invul-1.0/30)
 g.director.update(g,1.0/30);g.update_enemies(1.0/30)
 game.world.camera_pos=initial_player
 frame+=1
 if frame==170:
  capture.call_deferred()
 if frame>=300:
  var largest=0.0
  for i in range(targets.size()):largest=maxf(largest,targets[i].p.distance_to(initial_targets[i]))
  print("STAMPEDE REVIEW: player displaced=",g.pos.distance_to(initial_player)," enemy maximum displacement=",largest," hp=",g.hp," remaining compys=",g.enemies.filter(func(e):return e.kind==4 and not e.dead).size())
  assert(g.hp>0,"Stampede must be survivable without weapons")
  if not OS.get_cmdline_user_args().has("--baseline"):
   assert(largest>150,"Ordinary enemies must be displaced by the passing stampede")
   assert(g.pos.distance_to(initial_player)>30,"Player must be pushed even during damage invulnerability")
   assert(g.enemies.filter(func(e):return e.kind==4 and not e.dead).is_empty(),"Flock must keep moving and leave the encounter")
  quit()
 return false
func capture():
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/stampede-review/latest.png")
