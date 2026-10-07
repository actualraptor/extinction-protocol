extends SceneTree
# Local publicity fixture. Never touches the player's profile or hidden content.
var game
var shot = -1
var frame = 0
var ready_to_record = false
var lengths = [180,120,120,120]
var heroes = [1,2,0,1]
var builds = [[],
 ["lightning","frost","fire","thunderstorm","orbital"],
 ["revolver","shotgun","mortar","ricochet","fire"],
 ["club","earthshaker","orbital","fire","thunderstorm"]]
func _initialize():call_deferred("begin")
func begin():
 root.size=Vector2i(1920,1080)
 game=preload("res://scripts/main.gd").new()
 game.progress_path="res://build/epic-trailer-review/isolated-profile.json"
 root.add_child(game)
 await process_frame
 for child in game.layer.get_children():
  if child.get_script()==preload("res://scripts/opening_story.gd"):child.queue_free()
 game.save_data.unlocks=["mara","vesper","map_frost","map_observatory"]
 game.save_data.settings.hud_skin=-1
 game.save_data.settings.sound=true
 game.save_data.settings.music=false
 game.save_data.settings.voice_volume=0.0
 game.apply_settings()
 game.survivor_voice.enabled=false
 next_shot()
 ready_to_record=true
func disconnect_all(source,signal_name):
 for connection in source.get_signal_connection_list(signal_name):
  source.disconnect(signal_name,connection.callable)
func next_shot():
 shot+=1;frame=0
 if shot>=heroes.size():
  print("TRAILER CAPTURE COMPLETE: stampede plus three max-rank public builds, ordinary combat, no bosses")
  quit();return
 game.selected=heroes[shot];game.selected_map=["cradle","observatory","frostbreak","cradle"][shot]
 game.chosen_mode="expedition";game.start_run();game.paused=true
 game.survivor_voice.enabled=false;game.survivor_voice.stop()
 var g=game.sim
 assert(g.hero==heroes[shot] and g.map_id==["cradle","observatory","frostbreak","cradle"][shot])
 for sig in ["choice_requested","banner","voice_event","discovered_content","effect","sound"]:disconnect_all(g,sig)
 g.rng.seed=81300+shot
 g.time=150.001 if shot==0 else 200.0;g.level=50;g.weapons.clear()
 for id in builds[shot]:g.weapons[id]={"level":10,"evolved":true,"timer":.1}
 for id in ["armor","regen","haste","count","area"]:
  g.options=[{"type":"passive","id":id,"rank_gain":5}];g.choosing=true;g.choose(0)
 g.enemies.clear()
 if shot==0:
  g.director.update(g,.001);g.director.flow_direction=Vector2.RIGHT;g.director.flow_origin=g.pos
  for i in range(24):
   var e=g.spawn_enemy(false,g.pos+Vector2(g.rng.randf_range(-300,350),g.rng.randf_range(-130,130)),0,false)
 else:
  for i in range(350):g.spawn_enemy(false,g.pos+Vector2.from_angle(g.rng.randf()*TAU)*g.rng.randf_range(110,720),-1,false)
  for tick in range(40):
   g.tick(1.0/30,Vector2.RIGHT)
   for j in range(5):g.spawn_enemy(false,g.pos+Vector2.from_angle(g.rng.randf()*TAU)*g.rng.randf_range(260,660),-1,false)
  if not g.active:push_error("Capture build died during warmup");quit(1);return
 g.hp=g.max_hp
 game.world.effects.clear();game.world.particles.clear();game.world.numbers.clear()
 game.world.crit_bursts.clear();game.world.camera_pos=g.pos;game.world.camera_run=g
 g.effect.connect(game.world.fx)
 g.sound.connect(func(id):game.audio.play(id))
 game.toast_time=0
 for e in g.enemies:assert(not e.boss and not e.get("boss_prop",false))
 print("TRAILER SHOT %s: hero %s, enemies %s, time %s"%[shot,heroes[shot],g.enemies.size(),g.time])
func _process(_dt):
 if not ready_to_record or shot>=heroes.size():return false
 var g=game.sim
 if g.choosing:g.choose(0)
 if shot>0:
  for j in range(5):g.spawn_enemy(false,g.pos+Vector2.from_angle(g.rng.randf()*TAU)*g.rng.randf_range(260,660),-1,false)
 g.tick(1.0/30,Vector2.ZERO if shot==0 else Vector2(cos(frame*.018+shot),sin(frame*.018+shot)))
 assert(g.boss==null and g.portal==null and g.depth==0 and g.hero in [0,1,2])
 if not g.active:push_error("Capture ended unexpectedly");quit(1)
 if frame==lengths[shot]/2:capture.call_deferred(shot)
 frame+=1
 if frame>=lengths[shot]:next_shot()
 return false
func capture(index):
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/epic-trailer-review/showcase-%s.png"%index)
