extends RefCounted
## Non-meteor bosses: committed windup/action/recovery sequences in ground space.
const IDS = {"cradle":["thorn","basalt"],"frostbreak":["hunt","aurora"],"observatory":["warden","bloom"]}
const COLORS = {"thorn":"a9d96a","basalt":"ff9d57","hunt":"a4eaff","aurora":"c0a0ff","warden":"f9da86","bloom":"b2ea80"}
static func setup(g):
 var b=g.boss
 b.identity=IDS[g.map_id][g.boss_stage-1]
 b.action="recover";b.action_left=2.2;b.action_length=2.2;b.aim=Vector2.DOWN
 b.origin=b.p;b.target=b.p;b.pose=0.0;b.lift=0.0;b.fade=1.0;b.exposed=0.0;b.attack_index=0;b.props=[]
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
 h.theme=theme;h.reason=g.Maps.boss_name(g.map_id,g.boss_stage)
 h.merge(extra,true)
static func shot(g,p,direction,speed,theme,damage):
 if g.hostile_shots.size()>=48:return
 g.hostile_shots.append({"p":p,"v":direction*speed,"life":4.2,"damage":damage,"theme":theme,"reason":g.Maps.boss_name(g.map_id,g.boss_stage)})
static func pod(g,p,kind,life):
 var b=g.boss
 if b.props.filter(func(e):return not e.dead).size()>=6:return
 var e=g.spawn_enemy(false,p,16 if kind=="lens" else 17)
 e.boss_prop=true;e.prop_kind=kind;e.prop_life=life;e.owner=b.uid;e.speed=0.0;e.elite=false
 e.hp=(200+g.level*16)*(1.2 if g.phase==2 else 1.0);e.max_hp=e.hp;e.size=22.0
 b.props.append(e)
static func lob(g,p,theme,damage):
 if g.hostile_shots.size()>=48:return
 var duration=1.15
 g.hostile_shots.append({"p":g.boss.p,"start":g.boss.p,"target":p,"v":Vector2.ZERO,"life":duration,"flight":duration,"theme":theme,"arc":true,"damage":damage,"reason":g.Maps.boss_name(g.map_id,g.boss_stage)})
 hazard(g,"circle",p,0,48,duration,0.1,0,theme,{"marker_only":true})
static func update(g,dt):
 var b=g.boss
 var color=Color(COLORS[b.identity])
 b.pose=0.0;b.lift=0.0;b.fade=1.0;b.exposed=maxf(0,b.exposed-dt)
 if b.reform>0:
  b.pose=sin(b.reform*12)*0.04
  return
 for e in b.props:
  if e.dead:continue
  e.prop_life-=dt
  if e.prop_life<=0:
   e.dead=true
   if e.prop_kind=="growth":
    for j in range(2):
     if g.enemies.size()<g.director.cap(g):
      var child=g.spawn_enemy(false,e.p+Vector2.from_angle(j*PI)*35,4)
      child.event_spawn=true
    g.effect.emit("blast_miasma",e.p,color,65)
 b.props=b.props.filter(func(e):return not e.dead)
 b.action_left-=dt
 var progress=clampf(1-b.action_left/maxf(0.01,b.action_length),0,1)
 match b.action:
  "windup":
   b.pose=sin(progress*PI)*0.12;b.lift=-progress*8
   if b.action_left<=0:execute(g)
  "charge":
   b.p=b.origin.lerp(b.target,progress)
   b.pose=sin(progress*PI)*0.08
   if b.p.distance_to(g.pos)<b.size+16:g.hurt(34,"Gored by the Thorn Crown")
   if b.action_left<=0:
    g.effect.emit("blast_club",b.p,color,145);g.sound.emit("club")
    if g.phase==2:hazard(g,"cone",b.p,b.aim.angle(),170,0.65,0.22,30,"thorn",{"arc":2.7})
    begin(g,"recover",1.8)
  "pounce":
   b.p=b.origin.lerp(b.target,progress);b.lift=sin(progress*PI)*90
   if b.action_left<=0:
    hazard(g,"circle",b.p,0,95,0.12,0.3,32,"hunt")
    g.sound.emit("impact_frost");begin(g,"recover",1.7)
  "vanish":
   b.fade=1-progress
   if b.action_left<=0:
    b.p=b.target;begin(g,"reappear",0.65)
  "reappear":
   b.fade=progress;b.pose=sin(progress*PI)*0.08
   if b.action_left<=0:
    for j in range(7):shot(g,b.p,Vector2.from_angle(b.aim.angle()+(j-3)*0.24),175,"aurora",26)
    begin(g,"recover",1.6)
  "breath":
   b.pose=sin(progress*TAU*2)*0.03
   if b.action_left<=0:begin(g,"recover",1.8)
  "recover":
   b.lift=sin(progress*PI)*2
   if b.action_left<=0:prepare(g)
static func prepare(g):
 var b=g.boss
 b.attack_index+=1
 begin(g,"windup",1.15 if b.identity in ["thorn","hunt"] else 1.4)
 var aim=b.aim.angle()
 match b.identity:
  "thorn":
   if b.attack_index%2==1:
    b.target=g.terrain.open_position(b.p+b.aim*minf(520,b.p.distance_to(g.pos)+110))
    hazard(g,"line",b.p,aim,42,b.action_length,0.1,0,"thorn",{"length":b.p.distance_to(b.target),"marker_only":true})
    g.banner.emit("HORN CHARGE","DIRECTION LOCKED / STEP ASIDE")
   else:g.banner.emit("THORN FAN","FIND A GAP BETWEEN THE GROWTHS")
  "basalt":g.banner.emit("BASALT FRACTURE" if b.attack_index%2==1 else "ROCKFALL","WATCH THE CRACKS" if b.attack_index%2==1 else "LEAVE THE LANDING MARKERS")
  "hunt":
   if b.attack_index%3!=0:
    b.target=g.terrain.open_position(g.pos+g.velocity*0.25)
    hazard(g,"circle",b.target,0,95,b.action_length+0.65,0.1,0,"hunt",{"marker_only":true})
    g.banner.emit("THE PALE HUNT","POUNCE LOCKED / MOVE OUT")
   else:g.banner.emit("PACK CALL","A SMALL HUNTING PACK APPROACHES")
  "aurora":
   if b.attack_index%2==1:
    b.target=g.terrain.open_position(g.pos+Vector2.from_angle(aim+1.8)*260)
    hazard(g,"circle",b.target,0,65,1.8,0.1,0,"aurora",{"marker_only":true})
    g.banner.emit("VEIL STEP","WATCH THE REAPPEARANCE")
   else:
    hazard(g,"cone",b.p,aim,420,b.action_length,1.2,28,"aurora",{"arc":1.25})
    g.banner.emit("AURORA BREATH","MOVE AROUND ITS FLANK")
  "warden":
   for j in range(3):pod(g,b.p+Vector2.from_angle(aim+j*TAU/3)*170,"lens",12)
   for e in b.props:
    hazard(g,"line",e.p,(g.pos-e.p).angle(),25,b.action_length+0.65,0.4,30,"warden",{"source_uid":e.uid,"length":700.0})
   g.banner.emit("LENS ARRAY","BREAK A LENS TO CANCEL ITS BEAM")
  "bloom":g.banner.emit("SPORE SEEDING" if b.attack_index%2==1 else "SPORE BLOOM","BREAK THE PODS BEFORE THEY HATCH" if b.attack_index%2==1 else "THREAD THE SLOW PROJECTILES")
static func execute(g):
 var b=g.boss
 var aim=b.aim.angle()
 match b.identity:
  "thorn":
   if b.attack_index%2==1:
    var target=b.target
    begin(g,"charge",0.8);b.target=target;g.sound.emit("spear");return
   for j in range(5):
    var p=b.p+Vector2.from_angle(aim+(j-2)*0.55)*(210+abs(j-2)*35)
    hazard(g,"circle",p,0,48,0.8+j*0.1,1.5,24,"thorn")
   g.sound.emit("thorns")
  "basalt":
   if b.attack_index%2==1:
    hazard(g,"circle",b.p,0,135,0.3,0.25,30,"basalt")
    for j in range(3):hazard(g,"line",b.p,aim+(j-1)*0.9,24,0.7+j*0.2,0.35,30,"basalt",{"length":520.0})
    g.sound.emit("club")
   else:
    for j in range(3 if g.phase==2 else 2):lob(g,g.pos+Vector2.from_angle(j*TAU/3)*115,"basalt",30)
    g.sound.emit("mortar")
  "hunt":
   if b.attack_index%3!=0:
    var target=b.target
    begin(g,"pounce",0.65);b.target=target;g.sound.emit("harpoon");return
   for j in range(mini(3 if g.phase==1 else 4,maxi(0,6-g.enemies.filter(func(e):return e.get("boss_minion",false) and not e.dead).size()))):
    var e=g.spawn_enemy(false,b.p+Vector2.from_angle(j*TAU/4)*190,14)
    e.event_spawn=true;e.boss_minion=true;e.attack=4.0;e.hp*=0.6;e.max_hp=e.hp
   g.sound.emit("boss")
  "aurora":
   if b.attack_index%2==1:
    var target=b.target
    begin(g,"vanish",0.4);b.target=target;g.sound.emit("stasis");return
   begin(g,"breath",1.2);g.sound.emit("frost");return
  "warden":g.sound.emit("lightning")
  "bloom":
   if b.attack_index%2==1:
    for j in range(3):lob(g,g.pos+Vector2.from_angle(aim+j*TAU/3)*180,"bloom",24)
    g.sound.emit("miasma")
   else:
    for j in range(12):shot(g,b.p,Vector2.from_angle(aim+j*TAU/12),145,"bloom",23)
    g.sound.emit("venom_spit")
 begin(g,"recover",2.2 if b.identity in ["basalt","warden","bloom"] else 1.7)
static func prop_destroyed(g,e):
 g.effect.emit("blast_orbital" if e.prop_kind=="lens" else "blast_miasma",e.p,Color(COLORS[g.boss.identity]) if g.boss!=null else Color.WHITE,80)
 g.sound.emit("impact_metal" if e.prop_kind=="lens" else "breakable")
 if g.boss!=null and e.owner==g.boss.uid:
  g.boss.exposed=2.5
 g.add_gem(e.p,8)
