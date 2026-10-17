extends SceneTree
const Trial=preload("res://scripts/goat_rescue.gd")
const God=preload("res://scripts/god_content.gd")
var game
var capture_dir="res://build/goat-review"
var checks=0
var failures=0
func check(ok,why):
 checks+=1
 if not ok:failures+=1;printerr("FAIL / ",why)
func _initialize():call_deferred("run")
func capture(name):
 await process_frame
 await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png(capture_dir.path_join(name+".png"))==OK,"Captured "+name)
func run():
 create_timer(180).timeout.connect(func():printerr("FAIL / rescue render timeout");quit(1))
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--goat-capture-dir="):capture_dir=arg.trim_prefix("--goat-capture-dir=")
 capture_dir=ProjectSettings.globalize_path(capture_dir)
 DirAccess.make_dir_recursive_absolute(capture_dir)
 game=preload("res://scenes/main.tscn").instantiate();game.progress_path=capture_dir.path_join("rescue-profile.json");root.add_child(game)
 await process_frame
 for child in game.layer.get_children():
  if child.get_script()!=null and child.get_script().resource_path=="res://scripts/opening_story.gd":child.queue_free()
 game.audio.enabled=false;game.audio.music_enabled=false;game.world.shake_enabled=false
 game.save_data.unlocks.erase("torr");game.save_data.discoveries.erase("torr")
 game.characters();await capture("locked-roster")
 check(not game.Discoveries.hero_open(game.save_data,God.install(game.C)),"Actual menu profile starts locked")
 game.selected=God.install(game.C);game.chosen_mode="safari";game.start_run();game.paused=true
 check(game.sim.hero==1,"Locked Torr cannot bypass through safari")
 game.selected=1;game.chosen_mode="expedition";game.start_run();game.paused=true
 var g=game.sim
 g.rng.seed=171017;g.terrain.seed_value=171017;g.terrain.configure(g.stage,g.depth)
 g.goat_trial={};g.configure_content(game.save_data)
 g.pos=g.goat_trial.p+Vector2(0,100);g.enemies.clear();g.xp_goal=1e9;g.halloween=false;g.cache_timer=999;g.shrine_done=true
 g.time=180
 g.level=18;g.weapons={"club":{"level":10,"evolved":false,"timer":0.0,"branches":{"5":"broad","10":"echo"}},"fire":{"level":7,"evolved":false,"timer":0.0},"lightning":{"level":7,"evolved":false,"timer":0.0},"frost":{"level":5,"evolved":false,"timer":0.0}}
 g.passives={"damage":3,"haste":3,"area":2,"count":1,"armor":2};g.modifier_cache.clear()
 Trial.update(g,0)
 await capture("wounded-pair")
 check(g.goat_trial.state=="waiting","Finding goats does not auto-start the fight")
 var input=InputEventKey.new();input.keycode=KEY_E;input.pressed=true
 game.paused=false;game._input(input);game.paused=true
 check(Trial.running(g),"Actual E interaction begins the encounter")
 var max_enemies=0;var captured={}
 for frame in 4800:
  # A modest circling bot uses an earned mid-run build; no invulnerability or free healing.
  var offset=g.pos-(g.goat_trial.p+Vector2(0,80))
  var direction=offset.orthogonal().normalized() if offset.length()>50 else Vector2.RIGHT
  if offset.length()>115:direction-=offset.normalized()*.8
  g.tick(1.0/30,direction)
  if g.choosing:g.choose(0)
  max_enemies=maxi(max_enemies,g.enemies.size())
  if frame%3==0:await process_frame
  if g.goat_trial.phase>=1 and not captured.has("pressure"):
   captured.pressure=true;await capture("rising-pressure")
  if g.goat_trial.final>1 and not captured.has("final"):
   captured.final=true;await capture("final-stand")
  if not Trial.running(g):break
 await capture("outcome")
 print("GOAT FIGHT / state ",g.goat_trial.state," / elapsed ",g.goat_trial.age," / player HP ",g.hp," / goats ",g.goat_trial.goats," / peak ",max_enemies," / kills ",g.kills)
 check(g.goat_trial.state=="saved","A real combat build can win the complete rescue")
 if g.goat_trial.state!="saved":
  game.audio.shutdown();game.survivor_voice.stop();game.release_run();quit(1);return
 check(max_enemies>=20,"Representative rendered encounter includes an actual horde")
 check(game.Discoveries.hero_open(game.save_data,God.install(game.C)),"Actual completion handler unlocks Torr")
 var saved=preload("res://scripts/profile_store.gd").load_profile(game.progress_path)
 check(not saved.blocked and game.Discoveries.hero_open(saved.data,God.install(game.C)),"Actual completion persists the unlock to disk")
 var film="--goat-film" in OS.get_cmdline_user_args()
 if film:DirAccess.make_dir_recursive_absolute(capture_dir.path_join("film"))
 for frame in 480:
  g.tick(1.0/30,Vector2.ZERO)
  if g.choosing:g.choose(0)
  if frame%2==0:
   await process_frame
   if film:
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(capture_dir.path_join("film/%04d.png"%int(frame/2)))
  if frame in [24,37,84,221,424,479]:await capture("arrival-"+str(frame))
 check(g.goat_trial.get("arrival_hit",false) and g.goat_trial.get("departed",false),"Torr lands and departs once on the simulation clock")
 var actual_end=g.goat_trial.finished_at
 game.world.reduced_effects=true;game.world.shake=0
 game.world.fx("torr_slam",g.goat_trial.p,Color.WHITE,480)
 check(game.world.shake==0,"Reduced effects suppress impact camera shake")
 g.goat_trial.finished_at=g.time-1.25
 await capture("arrival-reduced")
 g.goat_trial.finished_at=actual_end
 game.characters();await capture("unlocked-roster")
 game.audio.shutdown();game.survivor_voice.stop();game.release_run();game.queue_free();game=null
 await create_timer(.2).timeout
 print("GOAT RENDERED / ",checks," checks / ",failures," failures")
 quit(1 if failures else 0)
