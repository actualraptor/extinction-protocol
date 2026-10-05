extends SceneTree
const E=preload("res://scripts/expedition.gd")
class ForcedCrit:
 extends E
 var tier=0
 func crit_chance():return float(tier)
var failures=0
var checks=0
func check(ok,msg):
 checks+=1
 if not ok:failures+=1;printerr("FAIL / ",msg)
func _initialize():
 var g=ForcedCrit.new();g.setup(1,"expedition",{},117);g.enemies.clear()
 var numbers=[]
 g.effect.connect(func(kind,p,color,value):if kind.begins_with("crit_number_"):numbers.append({"kind":kind,"value":value}))
 for tier in range(5):
  g.tier=tier
  var e=g.spawn_enemy(false,g.pos+Vector2(50,0),0,false);e.hp=1e8;e.max_hp=e.hp
  var dealt=g.hit(e,100,"revolver",true,false)
  check(is_equal_approx(dealt,100*pow(1.9,tier)),"Actual damage multiplies every crit tier / "+str(tier))
  check(e.last_crit_tier==tier,"Displayed tier matches applied tier")
  if tier>0:check(numbers[-1].kind=="crit_number_%s"%tier and is_equal_approx(numbers[-1].value,dealt),"Number and damage match")
 g.tier=2
 var e=g.spawn_enemy(false,g.pos+Vector2(50,0),0,false);e.hp=50;e.max_hp=50
 var before=g.damage_total;var dealt=g.hit(e,100,"revolver",true,false)
 check(dealt==50 and is_equal_approx(g.damage_total-before,50),"Overkill excluded from damage ledger")
 check(is_equal_approx(numbers[-1].value,361),"Double crit shows full hit even against low HP")
 for n in ["sound","effect","banner","choice_requested","ended","discovered_content","voice_event"]:
  for c in g.get_signal_connection_list(n):g.disconnect(n,c.callable)
 print("MULTIPLICATIVE CRIT / ",checks," checks / ",failures," failures")
 quit(1 if failures else 0)
