extends SceneTree
const E=preload("res://scripts/expedition.gd")
const Slam=preload("res://scripts/kael_slam.gd")
const Ground=preload("res://scripts/kael_ground_fracture.gd")
var checks=0
var failures=0
func check(ok,msg):
 checks+=1
 if not ok:failures+=1;printerr("FAIL / ",msg)
func _initialize():
 for variant in ["ancestor","worldbreaker","earthshaker"]:
  var id="earthshaker" if variant=="earthshaker" else "club"
  var g=E.new();g.setup(1,"expedition",{},117)
  g.weapons={id:{"level":10,"evolved":variant!="ancestor","timer":99999,"casts":0}}
  g.passives.clear();g.buff_stacks.clear();g.enemies.clear()
  var previous=g.Rules.stats(g,id).radius
  for rank in range(5):
   g.options=[g.BuffRewards.decorate(g,{"type":"passive","id":"area"},"ARTIFACT")]
   g.choosing=true;g.choose(0)
   var radius=g.Rules.stats(g,id).radius
   check(radius>previous,"Actual Area reward increases radius / "+variant)
   previous=radius
  var s=g.Rules.stats(g,id)
  check(s.radius>300,"Normal stats exceed former cap / "+variant)
  var victim=g.spawn_enemy(false,g.pos+Vector2(s.radius*.85,0));victim.hp=1e12;victim.boss=true;g.build_grid()
  var stamps=[]
  g.effect.connect(func(k,p,c,r):if k.begins_with("kael_crater"):stamps.append({"kind":k,"p":p,"size":r}))
  Slam.impact(g,id,Vector2.RIGHT,s,false)
  for tick in range(120):g.time+=1.0/120;preload("res://scripts/combat_engine.gd").update(g,1.0/120)
  check(victim.hp<1e12,"Actual slam damages beyond former cap / "+variant)
  check(stamps.size()==1 and is_equal_approx(stamps[0].size,s.radius),"Stamp matches actual damage radius / "+variant)
  var extent=0.0
  for point in Ground.geometry(stamps[0]):extent=maxf(extent,point.length())
  check(is_equal_approx(extent,s.radius),"Crack extent matches uncapped radius / "+variant)
  check(Ground.geometry(stamps[0]).size()<=640,"Geometry remains bounded / "+variant)
  g.echoes.clear();g.kael_attack.clear();g.weapons.clear();g.enemies.clear();g.boss=null
 var g=E.new();g.setup(2,"expedition",{},117)
 g.weapons={"club":{"level":10,"evolved":true,"timer":99999}}
 g.passives.area=5;g.buff_stacks.area=[{"stat_gain":100.0,"rank_gain":5}]
 check(g.Rules.stats(g,"club").radius<=300,"Other heroes retain existing cap")
 print("KAEL UNCAPPED AREA / ",checks," checks / ",failures," failures")
 quit(1 if failures else 0)

