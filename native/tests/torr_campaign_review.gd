extends SceneTree
const Exp=preload("res://scripts/expedition.gd")
const Budget=preload("res://tests/torr_balance_review.gd")
var results=[]
func _initialize():call_deferred("run")
func run():
 var helper=Budget.new()
 for route in ["throw","orbit","unions"]:
  for immune in [true,false]:
   var g=Exp.new();g.setup(7,"expedition",{},171017)
   helper.loadout(g,route,"EPIC")
   if not immune:
    g.passives.erase("speed");g.passives.erase("area");g.buff_stacks.erase("speed");g.buff_stacks.erase("area")
    for id in ["armor","regen"]:
     g.options=[g.BuffRewards.decorate(g,{"type":"passive","id":id},"EPIC",g.C.PASSIVES[id].max)];g.choosing=true;g.choose(0)
    g.choosing=false;g.options=[];g.hp=g.max_hp
   g.time=900;g.depth=2;g.terrain.configure(g.stage,g.depth);g.spawn_boss(3)
   g.pos=g.boss.p+Vector2(220,100)
   var phases=[1];var openings=0;var was_open=false
   for tick in 230*30:
    if not g.active:break
    if immune:g.invul=1
    var target=g.anchors[0].p+Vector2(0,85) if not g.anchors.is_empty() else g.boss.p+Vector2(0,275 if route=="orbit" else 170)
    var move=(target-g.pos).limit_length(1) if immune else movement(g,target)
    g.tick(1.0/30,move)
    if not phases.has(g.phase):phases.append(g.phase)
    if g.anchors.is_empty() and not was_open:openings+=1
    was_open=g.anchors.is_empty()
    if tick%180==0:await process_frame
   var row={"route":route,"immune":immune,"won":g.won,"active":g.active,"seconds":g.boss_time,"remaining":g.boss.hp if g.boss!=null else 0,"hp":g.hp,"phases":phases,"openings":openings,"damage":g.damage_total,"credit":g.damage_by_weapon}
   results.append(row);print("TORR CAMPAIGN / ",JSON.stringify(row))
 helper.free()
 var f=FileAccess.open("res://build/torr-campaign-review.json",FileAccess.WRITE);f.store_string(JSON.stringify(results,"  "));f.close()
 quit()

static func movement(g,target):
 var best=Vector2.ZERO;var best_score=INF
 for index in 25:
  var direction=Vector2.ZERO if index==24 else Vector2.from_angle(index*TAU/24)
  var score=0.0
  for future in [.15,.4,.75,1.1]:
   var p=g.terrain.move(g.pos,direction*g.speed()*future)
   score+=p.distance_to(target)*.05
   if p.distance_to(g.boss.p)<145:score+=3000
   if preload("res://scripts/meteor_fire_front.gd").burning(p,g.boss.p,g.boss_time+future):score+=5000
   for hazard in g.hazards:
    if hazard.get("marker_only",false) or hazard.kind=="friendly":continue
    if hazard.wait>future+.2 or hazard.life+maxf(0,hazard.wait)<future:continue
    var h=hazard.duplicate()
    if h.kind=="gust":h.radius+=h.travel_speed*maxf(0,future-h.wait)
    h.radius+=18
    if g.hazard_contains(h,p):score+=hazard.damage*40/(.2+future)
  if score<best_score:best_score=score;best=direction
 return best
