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
 if b.move=="CRUSHING BITE" and ("--painted-rig-test" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework")):g.sound.emit("trex_bite")
 if Attacks.hits(b,g.pos):
  g.hurt(s.damage,g.Maps.boss_name(g.map_id,g.boss_stage)+" / "+b.move)
  g.pos=g.terrain.move(g.pos,(g.pos-b.p).normalized()*70,15)
 if b.identity=="thorn" and ("--triceratops-rig-test" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework")):
  var contact=b.p if b.move=="EARTH STOMP" else b.p+Vector2.from_angle(b.attack_angle)*95
  g.effect.emit("dino_earth_impact",contact,Color("a08e68"),s.radius if b.move=="EARTH STOMP" else 65.0)
 elif b.identity=="basalt" and ("--painted-foot-plant" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework")):
  # Physical jaws and tail strikes should not flash like a magical club.
  # Roar and stomp already have their own travelling pressure/ground effects.
  if b.move in ["CRUSHING BITE","TAIL SWEEP"]:
   var contact=b.p+Vector2.from_angle(b.attack_angle)*(100.0 if b.move=="CRUSHING BITE" else 125.0)
   g.effect.emit("dino_earth_impact",contact,Color("a08e68"),45.0 if b.move=="CRUSHING BITE" else 70.0)
 elif b.move!="SEISMIC STOMP":g.effect.emit("blast_club",b.p,Color(COLORS[b.identity]),s.radius*.7)
 cue(g,"impact")
 if ("--painted-foot-plant" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework")) and b.identity=="basalt":
  if b.move=="TAIL SWEEP":
   hazard(g,"gust",b.p,b.attack_angle,210.0,0.0,1.15,14.0,"basalt",{"physical":true,"arc":2.7,"travel_speed":380.0,"thickness":42.0,"max_life":1.15,"hit_player":false,"source_uid":b.uid})
  elif b.move=="APEX ROAR":
   hazard(g,"gust",b.p,0.0,100.0,0.0,1.65,22.0,"basalt",{"physical":true,"arc":TAU,"travel_speed":340.0,"thickness":36.0,"max_life":1.65,"hit_player":false,"soundwave":true,"push":45.0,"source_uid":b.uid})
  elif b.move=="SEISMIC STOMP":
   g.sound.emit("dino_basalt_step");g.effect.emit("dino_step",b.p,Color.WHITE,70)
   for i in range(3):
    hazard(g,"circle",b.p+b.aim*(180+i*140),b.attack_angle,85-i*13,.18+i*.27,.48,[28,20,12][i],"basalt",{"physical":true,"seismic":true,"wave":i,"max_life":.48,"source_uid":b.uid})
 if b.move in ["APEX ROAR","PACK CALL"]:
  if not (b.move=="APEX ROAR" and ("--painted-foot-plant" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework"))):cue(g,"roar")
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
    b.intro_roared=true;cue(g,"roar")
    var physical_intro=(b.identity=="basalt" and ("--painted-foot-plant" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework"))) or (b.identity=="thorn" and ("--triceratops-rig-test" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework")))
    g.effect.emit("dino_earth_impact" if physical_intro else "blast_club",b.p,Color("a08e68") if physical_intro else Color(COLORS[b.identity]),150)
   if b.action_left<=0:begin(g,"recover",.8)
  "windup":
   b.pose=sin(progress*PI)*.055;b.lift=-progress*4
   if b.action_left<=0:execute(g)
  "charge","pounce":
   var old=b.p
   b.p=b.origin.lerp(b.target,smoothstep(0,1,progress));b.motion=b.aim
   if b.action=="charge" and b.identity in ["thorn","basalt"]:
    var authored=b.p
    var prior=clampf(progress-dt/maxf(.01,b.action_length),0,1)
    var travel=authored-b.origin.lerp(b.target,smoothstep(0,1,prior))
    var half=70.0 if b.identity=="thorn" else 90.0
    var steps=maxi(1,ceili(travel.length()/12.0))
    b.p=old
    for step_index in range(steps):
     var next=g.terrain.move(b.p,travel/steps,43)
     if not g.terrain.walkable(next+b.aim*half,43) or not g.terrain.walkable(next-b.aim*half,43):break
     b.p=next
    if travel.length()>1 and b.p.distance_to(old)<travel.length()*.5:
     # A blocked charge spends its momentum instead of teleporting through
     # terrain or accumulating a larger displacement on the next frame.
     b.action_left=0
   b.lift=sin(progress*PI)*65 if b.action=="pounce" else 0
   if b.action=="charge" and not b.contact_done:
    if Attacks.segment_hits(b,g.pos+(b.p-old),g.pos,15):
     b.contact_done=true;g.hurt(Attacks.shape(b.move).damage,g.Maps.boss_name(g.map_id,g.boss_stage)+" / "+b.move)
     g.pos=g.terrain.move(g.pos,b.aim*95,15);cue(g,"impact")
   if b.identity=="hunt" and progress>.3 and b.get("trail_clock",0)<=0:
    b.trail_clock=.2;hazard(g,"circle",b.p,0,32,.4,1.3,12,"hunt",{"physical":true})
   b.trail_clock=maxf(0,b.get("trail_clock",0)-dt)
   if b.action_left<=0:
    if b.action=="pounce":impact(g)
    else:
     cue(g,"impact")
     if b.identity=="thorn" and ("--triceratops-rig-test" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework")):g.effect.emit("dino_earth_impact",b.p+b.aim*95,Color("a08e68"),65)
     else:g.effect.emit("blast_club",b.p,Color(COLORS[b.identity]),90)
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
   # Tactical movement owns spacing, including backing away from overlap.
   # Do not hide those retreat steps just because the player is close.
   b.motion=b.aim
   if b.action_left<=0:prepare(g)
 var animated_contacts=(b.identity=="basalt" and ("--painted-foot-plant" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework"))) or (b.identity=="thorn" and ("--triceratops-rig-test" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework")))
 if b.action in ["intro","charge","recover"] and b.motion.length_squared()>.01 and not animated_contacts:
  b.step_clock-=dt
  if b.step_clock<=0:
   b.step_clock=.52 if b.identity=="basalt" else .7;cue(g,"step")
static func prepare(g):
 var b=g.boss
 var moves=Attacks.MOVES[b.identity].duplicate()
 if b.identity=="basalt" and ("--painted-foot-plant" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework")):moves.append("SEISMIC STOMP")
 var next_move=moves[b.attack_index%moves.size()]
 var terrain_rig=(b.identity=="basalt" and ("--painted-foot-plant" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework"))) or (b.identity=="thorn" and ("--triceratops-rig-test" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework")))
 if terrain_rig:
  var half=70.0 if b.identity=="thorn" else 90.0
  var heading=b.get("rig_heading",b.aim.angle())
  if not Attacks.attack_turn_clear(g.terrain,b.p,half,heading,g.pos,next_move):
   var stance=Attacks.attack_stance(g.terrain,b.p,heading,half,g.pos,next_move)
   begin(g,"recover",.25)
   if stance.distance_to(b.p)>1:b.attack_stance=stance
   else:b.erase("attack_stance")
   return
  b.erase("attack_stance")
 b.attack_index+=1
 b.move=moves[(b.attack_index-1)%moves.size()]
 var windup=(1.1 if b.identity in ["thorn","hunt"] else 1.35)*(.82 if g.phase==2 else 1.0)
 var targeted_rig=(b.identity=="basalt" and ("--painted-foot-plant" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework"))) or (b.identity=="thorn" and ("--triceratops-rig-test" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework")))
 var desired=(g.pos-b.p).normalized()
 if desired.length_squared()<.01:desired=Vector2.RIGHT
 if targeted_rig:
  var turn=absf(wrapf(desired.angle()-b.get("rig_heading",desired.angle()),-PI,PI))
  b.rig_turn_time=turn/(1.6 if b.identity=="thorn" else 6.0 if b.move=="TAIL SWEEP" else 1.2)
  windup+=b.rig_turn_time
  if b.move=="TAIL SWEEP":windup=.65+ b.rig_turn_time
 begin(g,"windup",windup)
 if targeted_rig:b.aim=desired
 b.motion=b.aim;b.attack_angle=b.aim.angle();b.contact_done=false;b.second_contact=false
 if b.move=="TAIL SWEEP" and not targeted_rig:b.attack_angle+=PI
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
 if b.move=="TAIL SWEEP" and ("--painted-rig-test" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework")):g.sound.emit("trex_tail_swoosh")
 if b.move=="APEX ROAR" and ("--painted-foot-plant" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework")):cue(g,"roar")
 cue(g,"attack")
static func prop_destroyed(g,e):
 g.effect.emit("blast_club",e.p,Color.WHITE,65);g.sound.emit("breakable");g.add_gem(e.p,8)
static func pod(_g,_p,_kind,_life):pass
