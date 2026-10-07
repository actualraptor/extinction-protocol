extends SceneTree
const OUT="D:/Utveckling CODEX/Dummy test/native/build/"
var game
func _initialize():call_deferred("run")
func run():
 game=preload("res://scripts/main.gd").new();game.progress_path=OUT+"dinosaur-fixture-profile.json";root.add_child(game)
 await process_frame
 for child in game.layer.get_children():
  if child.get_script()==preload("res://scripts/opening_story.gd"):child.queue_free()
 root.size=Vector2i(1920,1080)
 root.content_scale_size=Vector2i(1920,1080)
 game.save_data.settings.sound=false;game.save_data.settings.music=false;game.apply_settings()
 game.selected=1;game.chosen_mode="expedition"
 for map in ["cradle","frostbreak","observatory"]:
  game.selected_map=map;game.start_run();game.paused=true;var g=game.sim
  g.weapons.clear();g.enemies.clear();g.invul=100;g.landmarks.clear()
  var pool=g.Maps.DATA[map].pools[2]
  for j in range(45):
   var e=g.spawn_enemy(false,g.pos+Vector2.from_angle(j*2.399)*(180+(j%5)*65),pool[j%pool.size()]);e.motion=(g.pos-e.p).normalized()
  for frame in range(12):await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(OUT+"dinosaur-%s-roster.png"%map)
  for stage in [1,2]:
   g.spawn_boss(stage);g.boss.p=g.pos+Vector2(250,95);g.boss.action="recover";g.boss.action_left=2
   for frame in range(12):await process_frame
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(OUT+"dinosaur-%s-boss-%s.png"%[map,stage])
   g.enemies.erase(g.boss);g.boss=null
 game.selected_map="cradle";game.start_run();game.paused=true;var g=game.sim
 g.weapons.clear();g.enemies.clear();g.invul=100;g.landmarks.clear()
 var flow=preload("res://scripts/compy_stampede.gd")
 for i in range(2200):
  var e=g.spawn_enemy(false,g.pos+Vector2(g.rng.randf_range(-650,650),g.rng.randf_range(-340,340)),4);flow.configure(g,e,Vector2.RIGHT)
 var samples=[]
 for frame in range(120):
  var started=Time.get_ticks_usec();g.update_enemies(1.0/60);samples.append((Time.get_ticks_usec()-started)/1000.0)
  await process_frame
 samples.sort();print("2200 Compys CPU update ms / median=",samples[60]," / p95=",samples[114])
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(OUT+"dinosaur-stampede-2200.png")
 print("Dinosaur GPU fixtures: 3 rosters, 6 bosses, 2200 batched Compys; isolated profile")
 game.sim=null;quit()
