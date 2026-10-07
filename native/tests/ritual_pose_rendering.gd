extends SceneTree
const OUT="D:/Utveckling CODEX/Dummy test/native/build/"
const R=preload("res://scripts/remnant_system.gd")
const A=preload("res://scripts/rite_animation.gd")
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(1920,1080);root.content_scale_size=root.size
 var game=preload("res://scripts/main.gd").new();game.progress_path=OUT+"ritual-render-profile.json";root.add_child(game)
 await process_frame
 for child in game.layer.get_children():
  if child.get_script()==preload("res://scripts/opening_story.gd"):child.queue_free()
 game.save_data.settings.sound=false;game.save_data.settings.music=false;game.apply_settings()
 game.selected=5;game.chosen_mode="safari";game.start_run();game.paused=true;game.clear_menu()
 game.save_data.settings[preload("res://scripts/first_rite.gd").SEEN_FLAG]=true
 game.sim.choice_requested.disconnect(game.present_upgrade)
 for variant in range(6):
  var g=game.sim;game.world.effects.clear()
  g.enemies.clear();g.boss=null;g.boss_corpses.clear();g.portal=null;g.hazards.clear();g.weapons.clear()
  g.companions.units.clear();g.companions.pending.clear();g.companions.reform.clear()
  g.boss_stage=0;g.active=true;g.choosing=false
  g.spawn_boss(variant%2+1)
  var b=g.boss;b.identity=R.IDENTITIES[variant];b.p=g.pos+Vector2(0,-150)
  R.leave(g,b);g.enemies.clear();g.boss=null
  var c=g.boss_corpses[0];g.pos=c.marker;game.world.camera_run=null
  var art=R.corpse_art(c.identity)
  for row in range(3):
   for col in range(3):
    var part=A.fragment(art,col,row,3,3,"verified-"+c.identity+str(row*3+col))
    assert(part.get_image().get_width()>0)
  for seconds in [0.0,.4,1.0,2.0,3.5,5.5,9.0,16.0,17.8]:
   c.raising=true;c.ritual=seconds;g.time=seconds
   await process_frame;await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(OUT+"ritual-pose-"+c.identity+"-"+str(seconds)+".png")
  c.ritual=R.RITUAL-.01;R.update(g,.02)
  assert(c.consumed and g.companions.units.size()==1)
 game.sim=null;game.queue_free();await process_frame
 print("RITUAL POSES: six complete transformations rendered; standalone body fragments valid; six allies raised")
 quit()
