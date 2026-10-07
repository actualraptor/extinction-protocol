extends RefCounted
## Committed physical attacks extend the existing encounter state machine.
const IDS={"cradle":["thorn","basalt"],"frostbreak":["hunt","aurora"],"observatory":["warden","bloom"]}
const COLORS={"thorn":"a9d96a","basalt":"ff9d57","hunt":"a4eaff","aurora":"c0a0ff","warden":"f9da86","bloom":"b2ea80"}
const Attacks=preload("res://scripts/dinosaur_attacks.gd")
static func setup(g):
 var b=g.boss
 b.identity=IDS[g.map_id][g.boss_stage-1]
 b.action="intro";b.action_left=3.0;b.action_length=3.0;b.aim=(g.pos-b.p).normalized()
 b.motion=b.aim;b.origin=b.p-b.aim*120;b.target=b.p;b.p=b.origin
 b.pose=0.0;b.lift=0.0;b.fade=1.0;b.exposed=0.0;b.attack_index=0;b.props=[]
 b.move="";b.attack_angle=b.aim.angle();b.contact_done=false;b.step_clock=0.0;b.intro_roared=false
 g.invul=maxf(g.invul,3.2)
static func begin(g,action,duration):
 var b=g.boss
 b.action=action;b.action_left=duration;b.action_length=duration;b.origin=b.p
 b.aim=(g.pos-b.p).normalized();b.target=g.pos
 if b.aim.length_squared()<0.01:b.aim=Vector2.DOWN
 g.log_event("boss-action",{"boss":b.identity,"action":action,"phase":g.phase})
static func hazard(g,kind,p,angle,radius,warning,life,damage,theme,extra={}):
 var previous=g.hazards.size()
 g.add_hazard(kind,p,angle,radius,warning,life,damage)
 if g.hazards.size()==previous:return
 var h=g.hazards[-1]
 h.theme=theme;h.reason=g.Maps.boss_name(g.map_id,g.boss_stage);h.merge(extra,true)
static func cue(g,category):
 g.sound.emit("dino_"+g.boss.identity+"_"+category)
 if category=="roar":g.effect.emit("dino_roar",g.boss.p,Color(COLORS[g.boss.identity]),120)
 if category=="step" and g.boss.identity in ["basalt","bloom"]:g.effect.emit("dino_step",g.boss.p,Color(COLORS[g.boss.identity]),35)
static func impact(g):
 var b=g.boss
 var s=Attacks.shape(b.move)
 b.contact_done=true
 if Attacks.hits(b,g.pos):
  g.hurt(s.damage,g.Maps.boss_name(g.map_id,g.boss_stage)+" / "+b.move)
  g.pos=g.terrain.move(g.pos,(g.pos-b.p).normalized()*70,15)
 g.effect.emit("blast_club",b.p,Color(COLORS[b.identity]),s.radius*.7);cue(g,"impact")
 if b.move in ["APEX ROAR","PACK CALL"]:
  cue(g,"roar")
  for e in g.enemies:
   if e.dead or e.boss or e.anchor or e.p.distance_squared_to(b.p)>420*420:continue
   if b.identity=="aurora":e.enraged_until=g.time+5.0
   else:e.p=g.terrain.move(e.p,(e.p-b.p).normalized()*80,10)
  if b.move=="PACK CALL":
   var alive=g.enemies.filter(func(e):return e.get("boss_minion",false) and not e.dead).size()
   for j in range(mini(3,maxi(0,6-alive))):
    if g.enemies.size()>=g.director.cap(g):break
    var e=g.spawn_enemy(false,b.p+Vector2.from_angle(j*TAU/3)*190,14 if j%2==0 else 18)
    e.event_spawn=true;e.boss_minion=true;e.hp*=.6;e.max_hp=e.hp
static func update(g,dt):
 var b=g.boss
 b.pose=0.0;b.lift=0.0;b.fade=1.0;b.exposed=maxf(0,b.exposed-dt)
 if b.reform>0:
  b.pose=sin(b.reform*12)*.035
  return
 b.action_left-=dt
 var progress=clampf(1-b.action_left/maxf(.01,b.action_length),0,1)
 match b.action:
  "intro":
   b.p=b.origin.lerp(b.target,smoothstep(0,.7,progress));b.motion=b.aim
   for e in g.enemies:
    if e.boss or e.anchor or e.dead or e.p.distance_squared_to(b.p)>300*300:continue
    e.p=g.terrain.move(e.p,(e.p-b.p).normalized()*100*dt,10)
   if progress>.65 and not b.intro_roared:
    b.intro_roared=true;cue(g,"roar");g.effect.emit("blast_club",b.p,Color(COLORS[b.identity]),150)
   if b.action_left<=0:begin(g,"recover",.8)
  "windup":
   b.pose=sin(progress*PI)*.055;b.lift=-progress*4
   if b.action_left<=0:execute(g)
  "charge","pounce":
   var old=b.p
   b.p=b.origin.lerp(b.target,smoothstep(0,1,progress));b.motion=b.aim
   b.lift=sin(progress*PI)*65 if b.action=="pounce" else 0
   if b.action=="charge" and not b.contact_done:
    if Geometry2D.get_closest_point_to_segment(g.pos,old,b.p).distance_to(g.pos)<Attacks.shape(b.move).radius+15:
     b.contact_done=true;g.hurt(Attacks.shape(b.move).damage,g.Maps.boss_name(g.map_id,g.boss_stage)+" / "+b.move)
     g.pos=g.terrain.move(g.pos,b.aim*95,15);cue(g,"impact")
   if b.identity=="hunt" and progress>.3 and b.get("trail_clock",0)<=0:
    b.trail_clock=.2;hazard(g,"circle",b.p,0,32,.4,1.3,12,"hunt",{"physical":true})
   b.trail_clock=maxf(0,b.get("trail_clock",0)-dt)
   if b.action_left<=0:
    if b.action=="pounce":impact(g)
    else:cue(g,"impact");g.effect.emit("blast_club",b.p,Color(COLORS[b.identity]),90)
    begin(g,"recover",1.3 if g.phase==2 else 1.9)
  "strike":
   b.pose=sin(progress*TAU)*.08
   if progress>=.45 and not b.contact_done:impact(g)
   if b.move=="CROSS SLASH" and progress>=.74 and not b.get("second_contact",false):
    b.second_contact=true;b.attack_angle+=.45;impact(g)
   if b.move=="CLAW DRAG":
    b.p=g.terrain.move(b.p,b.motion*55*dt,32)
    if b.get("trail_clock",0)<=0:
     b.trail_clock=.3;hazard(g,"line",b.p,b.attack_angle,16,.55,1.6,16,"warden",{"length":110.0,"physical":true})
    b.trail_clock=maxf(0,b.get("trail_clock",0)-dt)
   if b.action_left<=0:begin(g,"recover",1.2 if g.phase==2 else 2.0)
  "recover":
   b.motion=Vector2.ZERO if b.p.distance_to(g.pos)<b.size+45 else b.aim
   if b.action_left<=0:prepare(g)
 if b.action in ["intro","charge","recover"] and b.motion.length_squared()>.01:
  b.step_clock-=dt
  if b.step_clock<=0:
   b.step_clock=.52 if b.identity=="basalt" else .7;cue(g,"step")
static func prepare(g):
 var b=g.boss
 b.attack_index+=1
 var moves=Attacks.MOVES[b.identity]
 b.move=moves[(b.attack_index-1)%moves.size()]
 begin(g,"windup",(1.1 if b.identity in ["thorn","hunt"] else 1.35)*(.82 if g.phase==2 else 1.0))
 b.motion=b.aim;b.attack_angle=b.aim.angle();b.contact_done=false;b.second_contact=false
 if b.move=="TAIL SWEEP":b.attack_angle+=PI
 var s=Attacks.shape(b.move)
 if s.kind=="line":
  var distance=540.0 if b.identity=="thorn" else 320.0
  b.target=g.terrain.open_position(b.p+b.aim*minf(distance,b.p.distance_to(g.pos)+100))
  hazard(g,"line",b.p,b.attack_angle,s.radius,b.action_length,.08,0,b.identity,{"length":b.p.distance_to(b.target),"marker_only":true,"physical":true})
 elif b.identity=="hunt":
  b.target=g.terrain.open_position(g.pos+g.velocity*.2)
  if b.move=="CREST FEINT":b.target=g.terrain.open_position(g.pos+b.aim.orthogonal()*120)
  hazard(g,"circle",b.target,0,s.radius,b.action_length+s.duration,.08,0,b.identity,{"marker_only":true,"physical":true})
 else:
  hazard(g,s.kind,b.p,b.attack_angle,s.radius,b.action_length+s.duration*.45,.15,0,b.identity,{"arc":s.arc,"marker_only":true,"physical":true})
 g.banner.emit(b.move,"DIRECTION LOCKED / STEP ASIDE" if s.kind=="line" else "WATCH THE LANDING" if b.identity=="hunt" else "LEAVE THE MARKED ATTACK AREA")
 cue(g,"windup")
static func execute(g):
 var b=g.boss
 var target=b.target;var direction=b.aim;var angle=b.attack_angle
 var s=Attacks.shape(b.move)
 begin(g,"charge" if s.kind=="line" else "pounce" if b.identity=="hunt" else "strike",s.duration)
 b.target=target;b.aim=direction;b.motion=direction;b.attack_angle=angle;b.contact_done=false
 cue(g,"attack")
static func prop_destroyed(g,e):
 g.effect.emit("blast_club",e.p,Color.WHITE,65);g.sound.emit("breakable");g.add_gem(e.p,8)
static func pod(_g,_p,_kind,_life):pass
