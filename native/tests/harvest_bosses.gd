extends SceneTree
const Expedition=preload("res://scripts/expedition.gd")
const Bosses=preload("res://scripts/boss_encounters.gd")
var checks=0
var failures=0
func check(ok,message):
 checks+=1
 if not ok:failures+=1;printerr("FAIL / ",message)
func _initialize():
 for map_id in ["cradle","frostbreak","observatory"]:
  for stage in [1,2]:
   var g=Expedition.new()
   g.setup(1,"expedition",{},123,map_id)
   g.weapons.clear();g.spawn_boss(stage)
   var b=g.boss
   check(b.identity==Bosses.IDS[map_id][stage-1],"Unique boss identity")
   var identities={};var actions={}
   for i in range(800):
    g.invul=1;g.update_boss(0.05);g.update_hazards(0.05);g.update_hostile_shots(0.05)
    identities[b.identity]=true;actions[b.action]=true
   check(b.attack_index>=5,"Several attack cycles / "+b.identity)
   check(actions.has("windup") and actions.has("recover"),"Anticipation and recovery / "+b.identity)
   check(g.hostile_shots.size()<=48 and b.props.size()<=6,"Bounded attacks / "+b.identity)
   if b.identity=="thorn":check(actions.has("charge"),"Thorn Crown charges")
   if b.identity=="hunt":check(actions.has("pounce"),"Pale Hunt pounces")
   if b.identity=="aurora":check(actions.has("vanish") and actions.has("breath"),"Aurora relocates and breathes")
   if b.identity in ["warden","bloom"]:
    Bosses.pod(g,g.pos,"lens" if b.identity=="warden" else "growth",10)
    var prop=b.props[-1]
    Bosses.hazard(g,"line",prop.p,0,25,1,1,30,b.identity,{"source_uid":prop.uid,"length":700})
    g.kill(prop);g.update_hazards(0.05)
    check(not g.hazards.any(func(h):return h.get("source_uid",-1)==prop.uid),"Destroyed prop cancels owned attack")
    check(b.exposed>0,"Breaking props opens damage window")
   Bosses.prepare(g)
   var locked=b.aim;var locked_target=b.target
   g.pos+=Vector2(500,500);g.update_boss(0.1)
   check(b.aim==locked and b.target==locked_target,"Windup does not chase player / "+b.identity)
   var point=b.p
   g.hit(b,1,"club",true)
   check(b.p==point,"Boss cannot be pushed")
   g.kill(b)
   check(g.boss==null and g.hostile_shots.is_empty() and g.hazards.is_empty(),"Defeat clears hostile attacks")
   check(g.portal!=null and g.choosing,"Boss rewards and portal remain")
 var g=Expedition.new();g.setup(1,"expedition",{},42);g.spawn_boss(3)
 check(g.anchors.size()==3,"Meteor keeps orbital anchors")
 g.boss_timer=0;g.update_boss(0.1)
 check(not g.hazards.is_empty(),"Meteor keeps original attacks")
 var h={"kind":"cone","p":Vector2.ZERO,"angle":0,"radius":100,"arc":PI/2}
 check(g.hazard_contains(h,Vector2(50,0)) and not g.hazard_contains(h,Vector2(0,50)),"Cone damage matches visible angle")
 print("HARVEST BOSSES / ",checks," checks / ",failures," failures")
 quit(1 if failures else 0)
