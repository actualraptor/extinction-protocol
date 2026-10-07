extends SceneTree
const OUT="D:/Utveckling CODEX/Dummy test/native/build/"
func _initialize():call_deferred("run")
func capture(name):
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(OUT+"individual-world-"+name+".png")
func run():
 root.size=Vector2i(1920,1080);root.content_scale_size=Vector2i(1920,1080)
 var game=preload("res://scripts/main.gd").new()
 game.progress_path=OUT+"individual-world-test-profile.json";root.add_child(game)
 await process_frame
 for child in game.layer.get_children():
  if child.get_script()==preload("res://scripts/opening_story.gd"):child.queue_free()
 game.save_data.settings.sound=false;game.save_data.settings.music=false;game.apply_settings()
 game.selected=5;game.chosen_mode="safari";game.start_run();game.paused=true
 game.save_data.settings[preload("res://scripts/first_rite.gd").SEEN_FLAG]=true
 game.sim.choice_requested.disconnect(game.present_upgrade);game.clear_menu()
 for variant in range(6):
  var g=game.sim
  game.world.effects.clear()
  g.enemies.clear();g.boss=null;g.boss_corpses.clear();g.portal=null;g.hazards.clear();g.weapons.clear();g.shots.clear()
  g.companions.units.clear();g.companions.pending.clear();g.companions.reform.clear()
  g.map_id=["cradle","frostbreak","observatory"][variant/2];g.depth=0;g.time=0;g.boss_stage=0;g.active=true;g.choosing=false
  g.stage=preload("res://scripts/stage_definition.gd").stage(g.map_id)
  g.terrain.arena=Vector2.INF;g.terrain.cached.clear();g.terrain.clearance.clear();g.terrain.flow.clear();g.terrain.configure(g.stage,0)
  g.pos=g.terrain.open_position(g.stage.spawn+Vector2(500,300));game.world.camera_run=null
  g.spawn_boss(variant%2+1);var b=g.boss;b.p=g.terrain.open_position(g.pos+Vector2(0,-150));b.aim=Vector2.RIGHT;b.motion=Vector2.RIGHT
  var identity=b.identity
  for action in ["intro","windup","strike"]:
   b.action=action;b.action_left=.5;b.action_length=1.0
   b.render_frame=preload("res://scripts/dinosaur_boss_art.gd").frame(b,g.time);b.render_previous=b.render_frame;b.render_changed=-1.0
   await capture(identity+"-"+action)
  b.move="TAIL SWEEP" if identity in ["basalt","bloom"] else "CROSS SLASH" if identity=="warden" else "HORN SWEEP" if identity=="thorn" else "CREST FEINT" if identity=="hunt" else "PACK CALL"
  b.action="strike";b.render_frame=preload("res://scripts/dinosaur_boss_art.gd").frame(b,g.time);b.render_previous=b.render_frame;b.render_changed=-1.0
  await capture(identity+"-secondary")
  b.motion=Vector2.LEFT;b.aim=Vector2.LEFT
  await capture(identity+"-left")
  g.boss_time=5;g.kill(b);g.choosing=false;game.clear_menu()
  check_corpse(g,identity)
  await capture(identity+"-corpse")
 game.sim=null;game.queue_free();await process_frame
 print("INDIVIDUAL WORLD ART: six bosses and their painted corpses rendered")
 quit()
func check_corpse(g,identity):
 assert(g.boss_corpses.size()==1 and g.boss_corpses[0].identity==identity)
