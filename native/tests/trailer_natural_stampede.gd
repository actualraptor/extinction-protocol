extends SceneTree
var game
var frame=0
var ready=false
func _initialize():call_deferred("begin")
func pick(g):
 if not g.choosing:return
 var best=0;var score=-INF
 for i in range(g.options.size()):
  var o=g.options[i];var value=0.0
  if o.type=="weapon":value=30 if o.id in ["club","fire","orbital","frost","shotgun"] else 10
  elif o.type=="passive":value=20 if o.id in ["pickup","area","armor","regen","haste","count"] else 5
  elif o.type=="evolution":value=50
  if value>score:score=value;best=i
 g.choose(best)
func movement(g):
 var move=Vector2(cos(g.time*1.8),sin(g.time*1.8))*.4
 var target=null;var distance=450.0*450.0
 for gem in g.gems:
  var d=gem.p.distance_squared_to(g.pos)
  if d<distance:distance=d;target=gem.p
 if target!=null:move=(target-g.pos).normalized()
 for e in g.enemies:
  if e.dead:continue
  var gap=g.pos-e.p;var d=gap.length()
  if d<110 and d>1:move+=gap/d*(1-d/110)*2.0
 return move.normalized()
func begin():
 root.size=Vector2i(1920,1080)
 game=preload("res://scripts/main.gd").new()
 game.progress_path="res://build/epic-trailer-review/stampede-natural-profile.json"
 root.add_child(game)
 await process_frame
 for child in game.layer.get_children():
  if child.get_script()==preload("res://scripts/opening_story.gd"):child.queue_free()
 game.save_data.settings.sound=true;game.save_data.settings.music=false;game.save_data.settings.voice_volume=0.0;game.apply_settings()
 game.selected=1;game.selected_map="cradle";game.chosen_mode="expedition";game.start_run();game.paused=true
 game.survivor_voice.enabled=false;game.survivor_voice.stop()
 var g=game.sim;g.rng.seed=94587
 for sig in ["choice_requested","banner","voice_event","discovered_content","effect","sound"]:
  for c in g.get_signal_connection_list(sig):g.disconnect(sig,c.callable)
 # Play from the normal run start: no injected enemies, loadout, ranks, HP or clock.
 var safety=0
 while g.time<147:
  pick(g);g.tick(1.0/30,movement(g));safety+=1
  if not g.active or safety>9000:print("FAILED AT ",g.time," hp ",g.hp," level ",g.level," weapons ",g.weapons);push_error("Natural run failed before stampede");quit(1);return
 assert(g.level>1 and g.weapons.size()>=2)
 print("NATURAL RUN: time=",g.time," level=",g.level," score=",g.score," weapons=",g.weapons," hp=",g.hp," enemies=",g.enemies.size())
 game.world.camera_pos=g.pos;game.world.camera_run=g
 game.world.effects.clear();game.world.particles.clear();game.world.numbers.clear()
 g.effect.connect(game.world.fx);g.sound.connect(func(id):game.audio.play(id))
 ready=true
func _process(_dt):
 if not ready:return false
 var g=game.sim;pick(g);g.tick(1.0/30,Vector2.ZERO if g.time>=150 and g.time<156 else movement(g))
 assert(g.boss==null and g.portal==null and g.hero==1 and g.depth==0)
 if not g.active:push_error("Natural capture died");quit(1);return false
 if frame in [120,180,240]:capture.call_deferred(frame)
 frame+=1
 if frame>=360:print("NATURAL STAMPEDE COMPLETE: ",g.time," hp=",g.hp," score=",g.score);quit()
 return false
func capture(i):
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/epic-trailer-review/natural-stampede-%s.png"%i)
