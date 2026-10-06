extends SceneTree
# Local publicity fixture. Never touches the player's profile or hidden content.
var game
var shot = -1
var frame = 0
var ready_to_record = false
var lengths = [120,120,120,120,90,90]
var heroes = [0,2,1,0,2,1]
var builds = [
 ["revolver","shotgun","orbital"],
 ["lightning","frost","fire"],
 ["club","orbital","aegis"],
 ["revolver","fire","mortar","frost"],
 ["lightning","orbital","aegis","frost"],
 ["club","shotgun","fire","orbital"]]
func _initialize():call_deferred("begin")
func begin():
 root.size=Vector2i(1920,1080)
 game=preload("res://scripts/main.gd").new()
 game.progress_path="res://build/trailer-review/isolated-profile.json"
 root.add_child(game)
 await process_frame
 for child in game.layer.get_children():
  if child.get_script()==preload("res://scripts/opening_story.gd"):child.queue_free()
 game.save_data.unlocks=["mara","vesper"]
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
  print("TRAILER CAPTURE COMPLETE: six public builds, ordinary combat, no bosses")
  quit();return
 game.selected=heroes[shot];game.selected_map="cradle"
 game.chosen_mode="expedition";game.start_run();game.paused=true
 game.survivor_voice.enabled=false;game.survivor_voice.stop()
 var g=game.sim
 for sig in ["choice_requested","banner","voice_event","discovered_content","effect","sound"]:disconnect_all(g,sig)
 g.rng.seed=81300+shot
 g.time=175.0;g.level=24;g.weapons.clear()
 for id in builds[shot]:g.weapons[id]={"level":5,"evolved":false,"timer":.1}
 for id in ["armor","regen","speed","count"]:
  g.options=[{"type":"passive","id":id,"rank_gain":4}];g.choosing=true;g.choose(0)
 # Warm a normal director encounter, with actual attacks and movement.
 for tick in range(900):
  if g.choosing:g.choose(0)
  g.tick(1.0/30,Vector2(cos(tick*.012+shot),sin(tick*.012+shot)))
  if not g.active:push_error("Capture build died during warmup");quit(1);return
 g.hp=g.max_hp
 game.world.effects.clear();game.world.particles.clear();game.world.numbers.clear()
 game.world.crit_bursts.clear();game.world.camera_pos=g.pos;game.world.camera_run=g
 g.effect.connect(game.world.fx)
 g.sound.connect(func(id):game.audio.play(id))
 game.toast_time=0
 print("TRAILER SHOT %s: hero %s, enemies %s, time %s"%[shot,heroes[shot],g.enemies.size(),g.time])
func _process(_dt):
 if not ready_to_record or shot>=heroes.size():return false
 var g=game.sim
 if g.choosing:g.choose(0)
 g.tick(1.0/30,Vector2(cos(frame*.018+shot),sin(frame*.018+shot)))
 assert(g.boss==null and g.portal==null and g.depth==0 and g.hero in [0,1,2])
 if not g.active:push_error("Capture ended unexpectedly");quit(1)
 if frame==lengths[shot]/2:capture.call_deferred(shot)
 frame+=1
 if frame>=lengths[shot]:next_shot()
 return false
func capture(index):
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/trailer-review/gameplay-%s.png"%index)
