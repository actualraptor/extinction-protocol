extends SceneTree
const E=preload("res://scripts/expedition.gd")
const Slam=preload("res://scripts/kael_slam.gd")
const Combat=preload("res://scripts/combat_engine.gd")
const Ground=preload("res://scripts/kael_ground_fracture.gd")
var checks=0
var failures=0
func check(ok,msg):
 checks+=1
 if not ok:failures+=1;printerr("FAIL / ",msg)
func _initialize():
 for id in ["club","earthshaker"]:
  var g=E.new();g.setup(1,"expedition",{},116)
  g.weapons={id:{"level":10,"evolved":true,"timer":99999,"casts":0}};g.enemies.clear()
  var e=g.spawn_enemy(false,g.pos+Vector2(60,0));e.hp=1e12;e.boss=true;g.build_grid()
  var s=g.Rules.stats(g,id);s.repeat=8;s.cooldown=.12
  var stamps=[]
  g.effect.connect(func(k,p,c,r):if k.begins_with("kael_"):stamps.append({"kind":k,"p":p,"size":r}))
  Slam.start(g,id,Vector2.RIGHT,s)
  for i in range(18):g.time+=1.0/120;Combat.update(g,1.0/120)
  var before=e.hp
  for i in range(240):g.time+=1.0/120;Combat.update(g,1.0/120)
  check(e.hp<before,"Repeated damage continues / "+id)
  check(stamps.size()==1,"Only main hit stamps despite eight repeats and aftershock / "+id)
  var original=stamps[0].p
  g.pos+=Vector2(400,100);Slam.impact(g,id,Vector2.RIGHT,s,false)
  check(stamps[-1].p!=original and stamps[0].p==original,"New slam follows movement, old stamp stays / "+id)
  var shape=Ground.geometry(stamps[0])
  check(shape==Ground.geometry(stamps[0]),"Stamp geometry stable / "+id)
  check(stamps.all(func(f):return f.kind.begins_with("kael_crater_")),"No animated front or debris / "+id)
  g.echoes.clear();g.kael_attack.clear();g.enemies.clear();g.weapons.clear();g.boss=null
  for n in ["sound","effect","banner","choice_requested","ended","discovered_content","voice_event"]:
   for c in g.get_signal_connection_list(n):g.disconnect(n,c.callable)
 for radius in [115.0,320.0,1800.0]:
  var stamp={"kind":"kael_crater_dirt_0_4_900_2_123","size":radius}
  var shape=Ground.geometry(stamp);var extent=0.0
  for point in shape:extent=maxf(extent,point.length())
  check(is_equal_approx(extent,radius),"Cracks reach actual damage radius")
  check(shape.size()<=640,"Screen-sized cracks keep bounded geometry")
 var g=E.new();g.setup(1,"expedition",{},116);g.passives.clear();g.buff_stacks.clear()
 for luck in [0.0,.1,.84,2.0,5.0]:
  g.permanent_luck=luck
  var odds=g.Relics.odds(g,false)
  check(is_equal_approx(odds.reduce(func(a,b):return a+b,0.0),100),"Odds sum to 100")
  check(is_equal_approx(odds[0],40.0/rarity_total(luck)*100),"Luck uses original rarity curve")
  check(is_equal_approx(odds[5],.3*pow(1+luck,5)/rarity_total(luck)*100),"Artifact uses original rarity curve")
 print("KAEL STAMPS AND LUCK / ",checks," checks / ",failures," failures")
 quit(1 if failures else 0)

func rarity_total(luck):
 var sum=0.0
 for tier in range(6):sum+=[40.0,30.0,18.0,9.0,2.7,0.3][tier]*pow(1+luck,tier)
 return sum
