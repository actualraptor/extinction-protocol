extends SceneTree
const Exp=preload("res://scripts/expedition.gd")
const Trial=preload("res://scripts/goat_rescue.gd")
const Store=preload("res://scripts/profile_store.gd")
var failures=0
func _initialize():call_deferred("run")
func encounter(map,prepared):
 var g=Exp.new();g.setup(1,"expedition",{},171017,map);g.configure_content(Store.migrate(Store.defaults()))
 g.pos=g.goat_trial.p+Vector2(0,100);g.xp_goal=1e9;g.cache_timer=999;g.shrine_done=true
 if prepared:
  g.time=180;g.level=18
  g.weapons={"club":{"level":10,"evolved":false,"timer":0.0,"branches":{"5":"broad","10":"echo"}},"fire":{"level":7,"evolved":false,"timer":0.0},"lightning":{"level":7,"evolved":false,"timer":0.0},"frost":{"level":5,"evolved":false,"timer":0.0}}
  g.passives={"damage":3,"haste":3,"area":2,"count":1,"armor":2};g.modifier_cache.clear()
 Trial.begin(g)
 for frame in 5100:
  var offset=g.pos-(g.goat_trial.p+Vector2(0,80))
  var direction=offset.orthogonal().normalized() if offset.length()>50 else Vector2.RIGHT
  if offset.length()>115:direction-=offset.normalized()*.8
  g.tick(1.0/30,direction)
  if not Trial.running(g):break
 print("GOAT ENCOUNTER / ",map," / prepared ",prepared," / ",g.goat_trial.state," / ",g.goat_trial.age,"s / HP ",g.hp," / kills ",g.kills)
 return g
func run():
 for map in Exp.Maps.DATA:
  var g=encounter(map,true)
  if g.goat_trial.state!="saved":failures+=1;printerr("FAIL / Prepared Kael build must have a viable rescue on ",map)
 var weak=encounter("cradle",false)
 if weak.goat_trial.state!="failed" or "torr" in weak.discovered:failures+=1;printerr("FAIL / An unprepared starting build should not trivialize the ordeal")
 print("GOAT ENCOUNTERS / 4 complete fights / ",failures," failures")
 quit(1 if failures else 0)
