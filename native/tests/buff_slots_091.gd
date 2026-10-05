extends SceneTree
const E=preload("res://scripts/expedition.gd")
var checks=0
var failures=0
func check(ok,message):
 checks+=1
 if not ok: failures+=1;printerr("FAIL / ",message)
func _initialize():
 for mode in ["expedition","daily"]:
  var g=E.new();g.setup(2,mode,{},934)
  g.passives={"damage":1,"haste":1,"crit":1,"armor":1}
  g.augments={"conductor":1,"fork":1,"sorcery":1,"winterbite":1}
  check(g.buff_slots_used()==8,"Shared passive/augment capacity")
  for option in g.upgrade_pool():
   if option.type in ["passive","augment"]:check(g.passives.has(option.id) or g.augments.has(option.id),"No ninth buff offered")
  g.options=[{"type":"passive","id":"count"}];g.choosing=true;g.choose(0)
  check(not g.passives.has("count"),"Stale reward cannot exceed cap")
  g.options=[{"type":"augment","id":"linger"}];g.choosing=true;g.choose(0)
  check(not g.augments.has("linger"),"Stale augment cannot exceed cap")
  g.options=[{"type":"passive","id":"damage"}];g.choose(0)
  check(g.rank_of("damage")==2,"Owned buff still improves at cap")
  for id in g.passives:g.passives[id]=g.C.PASSIVES[id].max
  for id in g.augments:g.augments[id]=g.C.AUGMENTS[id].max
  g.weapons={}
  for id in ["lightning","frost","fire","revolver","club"]:g.weapons[id]={"level":10,"evolved":true,"timer":1.0}
  check(g.upgrade_pool().is_empty(),"Maxed build has no new rewards")
  g.open_choices(false)
  check(g.choosing and g.options[0].type=="supplies","Maxed build receives visible supply reward")
  var amber=g.amber;g.choose(0)
  check(g.amber==amber+25,"Supplies pay amber")
  g.relics=["flint","wrap","coil","lens","blood","shell","glass","magnet"]
  var original=g.relics.duplicate()
  # Remove mergeable weapons so the chest uses normal relic/refinement logic.
  g.weapons={"lightning":{"level":10,"evolved":true,"timer":1.0}}
  for i in range(20):
   g.open_choices(true)
   check(g.options[0].type!="relic" or g.options[0].id in original,"Full satchel improves owned relics without replacing")
   g.choose(0)
   check(g.relics==original,"Selected relics preserved")
 print("BUFF SLOTS / ",checks," checks / ",failures," failures")
 quit(1 if failures else 0)
