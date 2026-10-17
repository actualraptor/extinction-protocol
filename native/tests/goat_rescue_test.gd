extends SceneTree
const Trial=preload("res://scripts/goat_rescue.gd")
const Exp=preload("res://scripts/expedition.gd")
const Store=preload("res://scripts/profile_store.gd")
var checks=0
var failures=0
func check(ok,why):
 checks+=1
 if not ok:failures+=1;printerr("FAIL / ",why)
func _initialize():call_deferred("run")
func fixture(map="cradle",seed_value=171017):
 var g=Exp.new();g.setup(1,"expedition",{},seed_value,map);g.configure_content(Store.migrate(Store.defaults()))
 g.enemies.clear();g.pos=g.goat_trial.p;g.xp_goal=1e9
 return g
func advance(g,seconds,fps=30):
 for tick in roundi(seconds*fps):g.time+=1.0/fps;Trial.update(g,1.0/fps)
func run():
 for map in Exp.Maps.DATA:
  for seed_value in [1,171017,999999]:
   var site=fixture(map,seed_value)
   check(site.goat_trial.state=="waiting" and site.goat_trial.goats.size()==2,"Goats placed on "+map)
   check(site.terrain.line_clear(site.stage.spawn,site.goat_trial.p),"Site reachable along authored map route")
   check(site.goat_trial.goats.all(func(goat):return site.terrain.walkable(goat.p,22) and site.terrain.kind(site.terrain.cell(goat.p))==0),"Both goats on safe ground")
 var g=fixture()
 var torr=preload("res://scripts/god_content.gd").install(g.C)
 var profile=Store.migrate(Store.defaults())
 check(not g.Discoveries.hero_open(profile,torr),"Torr starts locked")
 check(not g.Discoveries.purchase(profile,"torr"),"Archive cannot purchase an undiscovered rescue")
 g.discovered_content.connect(func(id):
  if id not in profile.discoveries:profile.discoveries.append(id)
  if id not in profile.unlocks:profile.unlocks.append(id))
 check(Trial.begin(g) and not Trial.begin(g),"Manual opt-in can only start once")
 g.pos+=Vector2(400,0);advance(g,3)
 check(g.goat_trial.goats[0].hp==20,"Healing pauses outside the tending circle")
 g.pos=g.goat_trial.p;advance(g,30)
 check(g.goat_trial.goats[0].hp>45 and g.goat_trial.phase==1,"Near player heals over time and pressure escalates")
 var enemies=g.enemies.size();advance(g,65)
 check(g.goat_trial.phase==3 and g.enemies.size()>=enemies and g.enemies.size()<=g.director.cap(g),"Late pressure escalates but respects population cap")
 check(not g.Discoveries.hero_open(profile,torr),"Health recovery alone does not unlock before the final stand")
 advance(g,20)
 check(g.goat_trial.state=="saved" and g.Discoveries.hero_open(profile,torr),"Completing both goats and final stand grants Torr")
 var amber=g.amber;Trial.end(g,"saved","");advance(g,3)
 check(g.amber==amber and profile.unlocks.count("torr")==1,"Completion and its rewards are exactly once")
 check(g.goat_trial.get("arrival_hit",false),"Earned rescue triggers the in-world hammer landing")
 var landings=g.event_log.filter(func(e):return e.type=="torr-arrival").size()
 advance(g,15)
 check(g.goat_trial.get("departed",false) and not Trial.busy(g),"Torr collects the goats and releases normal spawning")
 check(landings==1 and g.event_log.filter(func(e):return e.type=="torr-arrival").size()==1,"Landing effects cannot retrigger")
 var path="res://build/goat-test-profile.json"
 profile["unrelated_future_field"]={"keep":17}
 check(Store.save_profile(path,profile)=="","Unlock saves transactionally")
 var loaded=Store.load_profile(path)
 check(not loaded.blocked and g.Discoveries.hero_open(loaded.data,torr) and loaded.data.unrelated_future_field.keep==17,"Unlock survives actual disk reload without losing unrelated fields")
 var completed=Exp.new();completed.setup(1,"expedition",{},44);completed.configure_content(loaded.data)
 check(completed.goat_trial.is_empty(),"Already unlocked profile does not respawn the trial")
 for mode in ["safari","daily"]:
  var other=Exp.new();other.setup(1,mode,{},44);other.configure_content(Store.migrate(Store.defaults()))
  check(other.goat_trial.is_empty(),"No progression trial in "+mode)
 var damage=fixture();Trial.begin(damage)
 var hunter=damage.spawn_enemy(false,damage.goat_trial.goats[0].p+Vector2(35,0),0,false)
 hunter.goat_hunter=true;hunter.goat_index=0;hunter.goat_ready=0.0
 damage.pos=damage.goat_trial.p+Vector2(200,0);damage.crowd.build(damage.enemies)
 Trial.hunter_update(damage,hunter,.01)
 check(damage.goat_trial.attacks.size()==1 and damage.goat_trial.goats[0].hp==20,"Hunters telegraph before objective damage")
 var before=damage.goat_trial.goats[0].hp;advance(damage,.7)
 check(damage.goat_trial.goats[0].hp>=before,"Windup gives player time to interrupt")
 hunter.dead=true;advance(damage,.7)
 check(damage.goat_trial.attacks.is_empty() and damage.goat_trial.goats[0].hp>before,"Killing a hunter cancels its pending bite")
 hunter=damage.spawn_enemy(false,damage.goat_trial.goats[0].p,0,false);hunter.goat_hunter=true;hunter.goat_index=0;hunter.goat_ready=0.0
 damage.crowd.build(damage.enemies);Trial.hunter_update(damage,hunter,.01)
 before=damage.goat_trial.goats[0].hp;advance(damage,1.3)
 check(damage.goat_trial.goats[0].hp<before,"Unstopped hunter wounds the goat after its tell")
 var last_bite=fixture();Trial.begin(last_bite);last_bite.goat_trial.age=100;last_bite.goat_trial.final=14.99
 for goat in last_bite.goat_trial.goats:goat.hp=100
 var attacker=last_bite.spawn_enemy(false,last_bite.goat_trial.goats[0].p,0,false)
 last_bite.goat_trial.attacks=[{"enemy":attacker,"goat":0,"wait":.01}]
 advance(last_bite,.1)
 check(last_bite.goat_trial.state=="defending" and last_bite.goat_trial.final<14.99,"A bite on the final tick resolves before granting the rescue")
 var fail=fixture();Trial.begin(fail);fail.goat_trial.goats[1].hp=0;advance(fail,.1)
 check(fail.goat_trial.state=="failed" and fail.active and "torr" not in fail.discovered,"Goat loss fails only the rescue, without an unlock")
 var abandoned=fixture();Trial.begin(abandoned);abandoned.pos+=Vector2(1000,0);advance(abandoned,8.2)
 check(abandoned.goat_trial.state=="failed" and abandoned.goat_trial.attacks.is_empty(),"Abandonment cleans pending attacks")
 var timed=fixture();Trial.begin(timed);timed.goat_trial.age=165;advance(timed,.1)
 check(timed.goat_trial.state=="failed","The ordeal cannot be stalled for endless farming")
 var schedule=fixture();schedule.time=299;schedule.next_boss=300;schedule.pos=schedule.goat_trial.p;Trial.begin(schedule)
 var due=schedule.next_boss;var shifted=schedule.director.respite_shift;schedule.tick(.5,Vector2.ZERO)
 check(schedule.boss==null and schedule.next_boss==due+.5 and schedule.director.respite_shift==shifted+.5,"Normal boss and horde schedules defer during rescue")
 var age=schedule.goat_trial.age;schedule.choosing=true;schedule.tick(.5,Vector2.ZERO)
 check(schedule.goat_trial.age==age,"Reward choices pause the rescue with the simulation")
 schedule.choosing=false;schedule.finish(false)
 check(schedule.goat_trial.state=="failed" and schedule.goat_trial.attacks.is_empty(),"Player death ends the rescue")
 var rift=fixture();rift.portal=rift.pos;rift.linger=26
 check(Trial.begin(rift),"Rescue remains available after a boss has opened the rift")
 rift.tick(.5,Vector2.ZERO)
 check(rift.depth==0 and rift.portal_charge==0 and rift.linger==26,"An existing rift cannot teleport or escalate pressure during the rescue")
 var retry=fixture();check(Trial.begin(retry),"A failed profile can try again next expedition")
 var times=[]
 for fps in [30,144]:
  var sim=fixture();Trial.begin(sim)
  advance(sim,112,fps);times.append(sim.goat_trial.finished_at)
 check(absf(times[0]-times[1])<.08,"Healing and final stand agree at 30 and 144 FPS")
 var audio=preload("res://scripts/sound.gd").new();audio.music_enabled=false;root.add_child(audio)
 audio.play("torr_rumble")
 for i in 60:audio.last_played.clear();audio.play("impact_metal")
 check(audio.torr_thunder.playing,"Combat sound bursts cannot steal Torr's thunder channel")
 audio.encounter_paused=true;audio._process(0)
 check(audio.torr_thunder.stream_paused,"Thunder follows the existing encounter pause state")
 audio.enabled=false;audio._process(0)
 check(not audio.torr_thunder.playing,"Disabling SFX stops the long thunder tail")
 audio.shutdown()
 await create_timer(.15).timeout
 audio.free()
 await process_frame
 print("GOAT RESCUE / ",checks," checks / ",failures," failures")
 quit(1 if failures else 0)
