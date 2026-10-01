extends SceneTree
const E=preload("res://scripts/expedition.gd")
var checks=0
var failures=0
func check(ok,description):
 checks+=1
 if not ok:failures+=1;printerr("FAIL / ",description)
func game():
 var g=E.new();g.setup(2,"expedition",{},731);return g
func _initialize():
 for id in E.Evolutions.UNIONS:
  var parts=E.Evolutions.UNIONS[id].parts
  for ranks in [[1,10],[9,10],[10,1],[10,9],[9,9],[10,10]]:
   var g=game();g.weapons.clear()
   for i in range(2):g.weapons[parts[i]]={"level":ranks[i],"evolved":false,"timer":0.0}
   var offer={"type":"fusion","id":id}
   check((offer in g.Evolutions.ready(g))==(ranks==[10,10]),"Both rank10 required / %s / %s"%[id,ranks])
   g.open_choices(true)
   if ranks==[10,10]:
    check(g.options[0]==offer,"Chest offers qualified union / "+id)
    g.choose(0)
    check(g.weapons.size()==1 and g.weapons.has(id),"Union consumes exactly both components / "+id)
   else:
    check(g.options.all(func(o):return o.type!="fusion"),"No premature chest union / "+id)
   check("both weapons rank 10" in g.Evolutions.hint(parts[0],g.C.WEAPONS),"Union help states both ranks / "+id)
 for reverse in [false,true]:
  var g=game();g.hp=1
  g.add_gem(Vector2(800,0),50)
  var magnet={"id":"magnet","p":g.pos,"life":60.0,"magnet":false}
  var heal={"id":"heal","p":Vector2(500,0),"life":60.0,"magnet":true}
  var amber={"id":"amber","p":Vector2(700,0),"life":60.0,"magnet":false}
  g.pickups=[magnet,heal,amber] if not reverse else [amber,heal,magnet]
  g.relic_chests=[Vector2(800,0)]
  g.Pickups.update(g,.1)
  for i in range(10):g.Pickups.update(g,.1);g.update_gems(.1)
  check(g.xp==50 and g.gems.is_empty(),"Gravity well gathers all XP")
  check(g.pickups.size()==2 and heal.p==Vector2(500,0) and amber.p==Vector2(700,0),"Health and amber stay put regardless of iteration order or stale attraction flags")
  check(g.hp==1 and g.amber==0 and g.relic_chests==[Vector2(800,0)],"Magnet cannot remotely consume heals amber or relic boxes")
  g.pos=heal.p;g.Pickups.update(g,.1)
  check(g.hp>1 and g.pickups.size()==1,"Walking onto heal still collects it")
  g.pos=amber.p;g.Pickups.update(g,.1)
  check(g.amber==8 and g.pickups.is_empty(),"Walking onto amber still collects it")
 print("UNIONS AND XP MAGNET / %s checks / %s failures"%[checks,failures]);quit(1 if failures else 0)
