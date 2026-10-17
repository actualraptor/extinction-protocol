extends SceneTree
const C=preload("res://scripts/catalog.gd")
const Exp=preload("res://scripts/expedition.gd")
const God=preload("res://scripts/god_system.gd")
const Content=preload("res://scripts/god_content.gd")
const Paths=preload("res://scripts/weapon_paths.gd")
var checks=0
var failures=0
var torr=7
func check(ok,message):
 checks+=1
 if not ok:failures+=1;printerr("FAIL / ",message)
func _initialize():call_deferred("run")
func fresh(index=-1):
 var g=Exp.new()
 g.setup(torr if index<0 else index,"expedition",{},171017)
 g.enemies.clear()
 return g
func prey(g,offset=Vector2(140,0)):
 var e=g.spawn_enemy(false,g.pos+offset,0,false)
 e.p=g.pos+offset;e.hp=1000000.0;e.max_hp=e.hp;e.speed=0
 return e
func step(g,duration,fps=30):
 for tick in roundi(duration*fps):
  g.time+=1.0/fps
  g.build_grid()
  g.Combat.update(g,1.0/fps)
  g.update_shots(1.0/fps)
func equip(g,id,rank=10,first="",last=""):
 g.weapons={id:{"level":rank,"evolved":false,"timer":0.0,"branches":{}}}
 if first!="":g.weapons[id].branches["5"]=first
 if last!="":g.weapons[id].branches["10"]=last
 g.shots.clear();g.starter_attack.clear();g.modifier_cache.clear();God.reset(g)
func run():
 preload("res://scripts/content_extension.gd").install(C)
 preload("res://scripts/tfk_content.gd").install(C)
 torr=Content.install(C)
 check(C.HEROES[0].name=="MARA VOSS" and C.HEROES[1].name=="KAEL" and C.HEROES[5].get("profile","")=="07","Stable existing hero IDs")
 check(Content.install(C)==torr and C.HEROES[torr].weapon=="mjolnir","Idempotent Torr registration")
 for index in range(torr):
  var g=fresh(index)
  for id in Content.WEAPONS:
   check(not g.content_allowed("weapons",id),"Ordinary survivor excludes "+id)
   check(g.shoot(id,g.pos,Vector2.RIGHT,10,300,1,1)==null,"Cannot inject a divine projectile")
  check(g.upgrade_pool().all(func(o):return o.type!="weapon" or "GOD" not in C.WEAPONS[o.id].tags),"Ordinary draft contains no God weapon")
  g.options=[{"type":"weapon","id":"mjolnir"}];g.choosing=true
  g.choose(0)
  check(not g.weapons.has("mjolnir") and g.choosing,"Illegal God grant is rejected without consuming reward")
 var g=fresh()
 check("VOLLEY" in g.trait_text() and "HAMMERS" not in g.trait_text(),"Returning attacks show volley size rather than an orbit capacity")
 check(Content.allowed({"weapon_set":"god"},C.WEAPONS.mjolnir),"Future God character shares equipment family")
 check(not Content.allowed({"weapon_set":"god"},C.WEAPONS.club),"God family rejects mortal equipment")
 check(g.upgrade_pool().filter(func(o):return o.type=="weapon").size()==8,"Full eight-weapon God draft")
 for id in C.WEAPONS:
  if "GOD" not in C.WEAPONS[id].tags:check(not g.content_allowed("weapons",id),"Torr excludes mortal weapon "+id)
 g.options=[{"type":"weapon","id":"club"}];g.choosing=true;g.choose(0)
 check(not g.weapons.has("club") and g.choosing,"Mortal grant rejected without lost reward")
 check(g.upgrade_pool().any(func(o):return o.type=="passive"),"Normal passives remain eligible")
 for pair in [[1,"cloudbreaker"],[torr,"club"]]:
  var forged=fresh(pair[0]);equip(forged,pair[1],1);prey(forged,Vector2(70,0));step(forged,1)
  check(forged.damage_total==0 and forged.ledger.casts.is_empty(),"Invalid loaded equipment cannot attack")
 for id in Content.WEAPONS:
  for first in Content.choices(id,5):
   for last in Content.choices(id,10,{"branches":{"5":first.id}}):
    var sim=fresh()
    equip(sim,id,10)
    check(Paths.choose(id,sim.weapons[id],5,first.id),"Rank-5 choice "+id+" / "+first.id)
    check(Paths.choose(id,sim.weapons[id],10,last.id),"Rank-10 choice "+id+" / "+last.id)
    for offset in [Vector2(80,0),Vector2(120,15),Vector2(160,-15),Vector2(190,40)]:prey(sim,offset)
    step(sim,5)
    check(sim.damage_by_weapon.get(id,0)>0,"Real damage from "+id+" / "+first.id+" / "+last.id)
    check(sim.god_state.events.size()<=96 and sim.god_state.effects.size()<=64 and sim.shots.size()<=240,"Bounded runtime queues")
 var orbit=fresh()
 equip(orbit,"mjolnir",5,"orbit")
 step(orbit,4)
 var wanted=orbit.Rules.stats(orbit,"mjolnir").count
 check(orbit.shots.size()==wanted,"Setup launches exactly effective projectile count")
 check("HAMMERS" in orbit.trait_text() and "VOLLEY" not in orbit.trait_text(),"Orbit HUD shows current and desired capacity")
 var casts=orbit.ledger.casts.get("mjolnir",0)
 step(orbit,5)
 check(orbit.shots.size()==wanted and orbit.starter_attack.is_empty() and orbit.ledger.casts.get("mjolnir",0)==casts,"Permanent orbit never expires or rethrows")
 check(not orbit.upgrade_pool().any(func(o):return o.type=="augment" and o.id in ["homing","pierce","bounce"]),"Orbit-only build does not draft unusable impact augments")
 orbit.weapons.gungnir={"level":1,"evolved":false,"timer":999}
 check(orbit.upgrade_pool().any(func(o):return o.type=="augment" and o.id=="homing"),"Tracking remains available for a compatible spear")
 orbit.weapons.erase("gungnir")
 orbit.passives["count"]=1;orbit.modifier_cache.clear();step(orbit,2)
 check(orbit.shots.size()==wanted+1 and orbit.ledger.casts.mjolnir==casts+1,"One extra projectile means one visible additional throw")
 orbit.passives.erase("count");orbit.modifier_cache.clear();step(orbit,1)
 check(orbit.shots.size()==wanted,"Count reduction retires only excess hammers")
 orbit.pos+=Vector2(140,60);step(orbit,1)
 check(orbit.shots.all(func(s):return s.p.distance_to(orbit.pos)<orbit.Rules.stats(orbit,"mjolnir").radius*1.5),"Orbit translates with current owner position")
 var old_radius=orbit.shots[0].radius
 orbit.passives["area"]=5;orbit.modifier_cache.clear();step(orbit,2)
 check(orbit.shots[0].radius>old_radius*1.3,"Area/range expands the sustained ring")
 orbit.passives["count"]=99;orbit.modifier_cache.clear();step(orbit,9)
 check(orbit.shots.size()==12,"Projectile safety cap is respected")
 check(orbit.shots.all(func(s):return s.hit.is_empty()),"Persistent orbit does not accumulate an unbounded hit-history array")
 orbit.finish(false)
 check(orbit.shots.is_empty() and orbit.god_state.is_empty(),"Run death removes divine persistent actors")
 for fps in [30,144]:
  var chain=fresh();equip(chain,"mjolnir",5,"bounce");chain.weapons.mjolnir.timer=999
  var first=prey(chain,Vector2(90,0))
  var second=prey(chain,Vector2(190,60))
  var third=prey(chain,Vector2(270,-40))
  chain.build_grid()
  var chain_stats=chain.Rules.stats(chain,"mjolnir");chain_stats.count=1
  God.release(chain,{"id":"mjolnir","stats":chain_stats,"aim":Vector2.RIGHT})
  var hammer=chain.shots[0];hammer.p=chain.pos;hammer.v=Vector2.RIGHT*chain_stats.velocity
  var linked=false
  for tick in fps:
   if hammer.get("chain_target")==second:
    linked=true;second.p.y+=150.0/fps
   chain.time+=1.0/fps;chain.build_grid();chain.update_shots(1.0/fps)
   if hammer.returning:break
  check(linked and first.hp<first.max_hp and second.hp<second.max_hp and third.hp<third.max_hp,"Ricochet follows moving targets through three enemies at "+str(fps)+" FPS")
  check(hammer.returning and hammer.budget==0,"Chain spends exactly two bounces then returns")
 var rescue=fresh();equip(rescue,"mjolnir",5,"bounce");rescue.weapons.mjolnir.timer=999
 var opener=prey(rescue,Vector2(90,0));var doomed=prey(rescue,Vector2(180,30));var backup=prey(rescue,Vector2(260,-30))
 rescue.build_grid();var rescue_stats=rescue.Rules.stats(rescue,"mjolnir");rescue_stats.count=1
 God.release(rescue,{"id":"mjolnir","stats":rescue_stats,"aim":Vector2.RIGHT})
 var redirected=rescue.shots[0];redirected.p=rescue.pos;redirected.v=Vector2.RIGHT*rescue_stats.velocity
 for tick in 30:
  rescue.time+=1.0/30;rescue.build_grid();rescue.update_shots(1.0/30)
  if redirected.get("chain_target")==doomed:break
 check(redirected.get("chain_target")==doomed,"Chain commits to its next enemy after impact")
 doomed.dead=true
 rescue.time+=1.0/30;rescue.build_grid();rescue.update_shots(1.0/30)
 check(redirected.get("chain_target")==backup,"A dead chain target is replaced without spending another bounce")
 backup.dead=true
 rescue.time+=1.0/30;rescue.build_grid();rescue.update_shots(1.0/30)
 check(redirected.returning,"A chain with no live next target returns safely")
 var isolated=fresh()
 equip(isolated,"mjolnir",10,"bounce","oath")
 isolated.weapons.mjolnir.timer=999
 var enemy=prey(isolated,Vector2(250,0));isolated.build_grid()
 var stats=isolated.Rules.stats(isolated,"mjolnir");stats.count=1
 isolated.Combat.Starter.start(isolated,"mjolnir",Vector2.RIGHT,stats)
 step(isolated,5)
 var limit=2+floori((2+int((10-5)/2)+stats.bounce)*.5)
 check(isolated.weapons.mjolnir.get("god_contacts",0)>0 and isolated.weapons.mjolnir.god_contacts<=limit,"Isolated repeat budget plus one normal return remains bounded")
 var counts=[]
 var phases=[]
 for fps in [30,144]:
  var sim=fresh();equip(sim,"mjolnir",5,"orbit");step(sim,5,fps)
  counts.append(sim.shots.size());phases.append(sim.god_state.phase)
 check(counts[0]==counts[1] and abs(phases[0]-phases[1])<.001,"Orbit count and angular progression agree at 30 and 144 FPS")
 var mark=fresh();var victim=prey(mark)
 victim.god_mark_until=mark.time+5;victim.god_mark_power=77
 check(God.mark_bonus(mark,victim,"winter_sun","impact")==0 and victim.god_mark_until>mark.time,"Melee half of a hybrid cannot consume projectile mark")
 check(God.mark_bonus(mark,victim,"mjolnir","projectile")==77 and God.mark_bonus(mark,victim,"mjolnir","projectile")==0,"Horn mark pays off exactly once")
 var spear=fresh();equip(spear,"gungnir",10,"hunt","recall");prey(spear,Vector2(250,0));spear.build_grid()
 God.cast(spear,"gungnir",spear.Rules.stats(spear,"gungnir"));spear.weapons.gungnir.timer=999
 step(spear,.5)
 check(spear.shots.any(func(s):return s.returning),"Hunting spear's recall upgrade produces a real returning pass")
 var bow=fresh();equip(bow,"winter_claim",10,"volley","freeze")
 var quarry=prey(bow,Vector2(300,0));bow.build_grid();God.cast(bow,"winter_claim",bow.Rules.stats(bow,"winter_claim"));bow.weapons.winter_claim.timer=999
 prey(bow,Vector2(0,80));step(bow,.15)
 check(not bow.shots.is_empty() and bow.shots.all(func(s):return s.target!=null and s.target.uid==quarry.uid),"Quarry arrows retain their marked target despite a closer distraction")
 var sword=fresh();equip(sword,"summer_edge",10,"long","return");prey(sword,Vector2(150,0));sword.build_grid()
 God.cast(sword,"summer_edge",sword.Rules.stats(sword,"summer_edge"));sword.weapons.summer_edge.timer=999;step(sword,.8)
 check(sword.god_state.effects.any(func(fx):return fx.kind=="sweep"),"Freyr's returning sword is another moving sweep")
 var union=fresh();equip(union,"winter_sun",10);prey(union,Vector2(160,0));union.build_grid()
 God.cast(union,"winter_sun",union.Rules.stats(union,"winter_sun"))
 check(not union.shots.is_empty() and union.shots.all(func(s):return s.homing>=4 and s.get("locked_target")!=null),"Winter Sun releases actual pursuing frost arrows")
 for id in Content.UNIONS:
  var sim=fresh();sim.weapons.clear()
  for part in Content.UNIONS[id].parts:sim.weapons[part]={"level":10,"evolved":false,"timer":0.0}
  check(sim.Evolutions.ready(sim).any(func(o):return o.id==id),"Divine combination is offered from its actual ingredients")
  sim.options=[{"type":"fusion","id":id}];sim.choosing=true;sim.choose(0)
  check(sim.weapons.has(id) and Content.UNIONS[id].parts.all(func(part):return not sim.weapons.has(part)),"Fusion consumes two ingredients and grants one tagged result")
  for part in Content.UNIONS[id].parts:check(sim.ledger.retired.has(part),"Ingredient damage credit is retained")
  for offset in [Vector2(80,0),Vector2(130,0),Vector2(180,0)]:prey(sim,offset)
  sim.choosing=false;step(sim,5)
  check(sim.damage_by_weapon.get(id,0)>0,"Combined weapon deals credited damage independently")
 print("GOD WEAPONS / ",checks," checks / ",failures," failures")
 quit(1 if failures else 0)
