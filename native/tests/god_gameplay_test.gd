extends SceneTree
const Content=preload("res://scripts/god_content.gd")
const God=preload("res://scripts/god_system.gd")
var failures=0
var checks=0
var game
var capture_dir=""
func check(ok,message):
 checks+=1
 if not ok:failures+=1;printerr("FAIL / ",message)
func _initialize():call_deferred("run")
func capture(name):
 await process_frame
 await RenderingServer.frame_post_draw
 var path=capture_dir.path_join("torr-"+name+".png")
 check(root.get_texture().get_image().save_png(path)==OK,"Capture "+name)
func fixture(first="bounce",last="oath",ids=["mjolnir"]):
 if "torr" not in game.save_data.unlocks:game.save_data.unlocks.append("torr")
 game.release_run();game.selected=Content.install(game.C);game.chosen_mode="expedition";game.start_run();game.paused=true
 var g=game.sim
 g.weapons.clear();g.enemies.clear();g.spawn_respite=99999;g.invul=99999;g.xp_goal=1e9;g.halloween=false
 for id in ids:g.weapons[id]={"level":10,"evolved":false,"timer":0.0,"branches":{"5":first,"10":last} if id=="mjolnir" else {}}
 for i in 54:
  var e=g.spawn_enemy(false,g.pos+Vector2.from_angle(i*TAU/54)*(110+i%5*28),i%8,false)
  e.hp=100000;e.max_hp=e.hp
 g.build_grid()
 return g
func run():
 create_timer(90).timeout.connect(func():printerr("FAIL / rendered Torr review timeout");quit(1))
 capture_dir="res://build" if OS.has_feature("editor") else OS.get_executable_path().get_base_dir().path_join("verification")
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--torr-capture-dir="):capture_dir=arg.trim_prefix("--torr-capture-dir=")
 DirAccess.make_dir_recursive_absolute(capture_dir)
 game=preload("res://scenes/main.tscn").instantiate()
 game.progress_path=capture_dir.path_join("torr-render-profile.json")
 root.add_child(game)
 await process_frame
 for child in game.layer.get_children():
  if child.get_script()!=null and child.get_script().resource_path=="res://scripts/opening_story.gd":child.queue_free()
 game.audio.enabled=false;game.audio.music_enabled=false;game.world.shake_enabled=false
 game.characters()
 await capture("selection")
 check(game.C.HEROES[Content.install(game.C)].name=="TORR STORMBUK","Torr is in actual selectable catalog")
 var g=fixture()
 for frame in 120:
  g.tick(1.0/30,Vector2.RIGHT if frame>40 else Vector2.ZERO)
  await process_frame
  if frame in [8,12,35,85]:await capture("throw-"+str(frame))
 check(g.hero==Content.install(game.C) and g.damage_by_weapon.get("mjolnir",0)>0,"Actual moving Torr throws deal damage")
 check(game.survivor_voice.hero_key=="torr","Actual Torr voice bank selected")
 g=fixture("bounce","thunder")
 g.enemies.clear();g.weapons.mjolnir.level=5;g.weapons.mjolnir.timer=999
 for offset in [Vector2(90,0),Vector2(190,60),Vector2(270,-40)]:
  var e=g.spawn_enemy(false,g.pos+offset,0,false);e.p=g.pos+offset;e.hp=100000;e.max_hp=e.hp
 g.build_grid()
 var stats=g.Rules.stats(g,"mjolnir");stats.count=1
 God.release(g,{"id":"mjolnir","stats":stats,"aim":Vector2.RIGHT})
 var hammer=g.shots[0];hammer.p=g.pos;hammer.v=Vector2.RIGHT*stats.velocity
 for frame in 30:
  if hammer.get("chain_target")!=null:hammer.chain_target.p.y+=5
  g.time+=1.0/30;g.build_grid();g.update_shots(1.0/30)
  await process_frame
  if frame in [9,16]:await capture("ricochet-"+str(frame))
 check(g.weapons.mjolnir.get("god_contacts",0)>=3,"Rendered hammer chains through moving enemies")
 g=fixture("orbit","thunder",["mjolnir","gungnir","cloudbreaker","worldwake","ninefold"])
 for frame in 180:
  g.tick(1.0/30,Vector2.RIGHT.rotated(frame*.02) if frame>70 else Vector2.ZERO)
  await process_frame
  if frame in [65,135,175]:await capture("orbit-"+str(frame))
 check(g.shots.filter(func(s):return s.get("god_hammer",false)).size()==g.Rules.stats(g,"mjolnir").count,"Rendered full-arsenal orbit has exact hammer capacity")
 for id in g.weapons:check(g.damage_by_weapon.get(id,0)>0,"Arsenal damage in rendered encounter: "+id)
 g=fixture("bounce","oath",["summer_edge","winter_claim","oathsplitter"])
 for frame in 100:
  g.tick(1.0/30,Vector2.LEFT if frame>50 else Vector2.ZERO)
  await process_frame
  if frame in [15,65,90]:await capture("divine-"+str(frame))
 for id in g.weapons:check(g.damage_by_weapon.get(id,0)>0,"Other divine weapon renders and deals damage: "+id)
 g.choosing=true;g.options=[]
 for id in ["mjolnir","worldwake","gungnir"]:g.options.append(g.BuffRewards.decorate(g,{"type":"weapon","id":id},"RARE"))
 game.upgrade_menu(g.options,false)
 await create_timer(.9).timeout
 await capture("god-drafts")
 check(g.options.all(func(o):return "GOD" in g.C.WEAPONS[o.id].tags),"Actual reward cards all use tagged divine weapons")
 game.audio.shutdown();game.survivor_voice.stop();game.release_run();game.queue_free();game=null
 await create_timer(.5).timeout
 print("TORR RENDERED / ",checks," checks / ",failures," failures")
 quit(1 if failures else 0)
