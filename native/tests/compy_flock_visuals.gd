extends SceneTree
const OUT="D:/Utveckling CODEX/Dummy test/native/build/"
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(1920,1080);root.content_scale_size=root.size
 var game=preload("res://scripts/main.gd").new();game.progress_path=OUT+"compy-flock-profile.json";root.add_child(game)
 await process_frame
 for child in game.layer.get_children():
  if child.get_script()==preload("res://scripts/opening_story.gd"):child.queue_free()
 game.save_data.settings.sound=false;game.save_data.settings.music=false;game.apply_settings()
 game.selected=1;game.chosen_mode="expedition";game.start_run();game.paused=true
 var g=game.sim;g.weapons.clear();g.enemies.clear();g.invul=1000;g.time=g.director.EVENTS[0].at+.001;g.landmarks.clear()
 for i in range(240):
  g.director.update(g,1.0/60);g.stampede_push_left=105.0/60;g.update_enemies(1.0/60);g.time+=1.0/60
 var flock=g.enemies.filter(func(e):return e.kind==4)
 assert(flock.size()>=230)
 var forward=g.director.flow_direction;var lateral=forward.orthogonal();var centre=g.director.flow_origin
 var lo=INF;var hi=-INF;var fast=0.0;var slow=INF
 for e in flock:
  var lane=(e.p-centre).dot(lateral);lo=minf(lo,lane);hi=maxf(hi,lane)
  fast=maxf(fast,e.speed);slow=minf(slow,e.speed)
  assert(e.size*4*e.visual_scale>=110)
 assert(hi-lo<285 and fast/slow<1.06,"Flock must stay narrow with matched travel speeds")
 # Preserve the actual spawned spacing while centering the flock for review.
 var centroid=Vector2.ZERO
 for e in flock:centroid+=e.p/flock.size()
 for e in flock:e.p+=centre-centroid
 for frame in range(30):
  g.stampede_push_left=105.0/60;g.update_enemies(1.0/60);await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(OUT+"compy-flock-current.png")
 print("COMPY FLOCK: ",flock.size()," visible-size animals; lane width ",hi-lo,"; bounded speed spread; event formation rendered")
 game.sim=null;quit()
