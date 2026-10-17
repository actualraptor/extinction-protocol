extends RefCounted
const Content = preload("res://scripts/god_content.gd")
const Dinos = preload("res://scripts/dinosaur_attacks.gd")

static func branch(g,id,milestone): return g.weapons[id].get("branches",{}).get(str(milestone),"")
static func active(g): return Content.god_hero(g.C.HEROES[g.hero])
static func reset(g): g.god_state={"phase":0.0,"turns":0,"reserve":0,"discharge_ready":0.0,"events":[],"effects":[]}
static func clear(g):
 g.god_state.clear()
 g.shots=g.shots.filter(func(shot):return "GOD" not in g.C.WEAPONS.get(shot.id,{}).get("tags",[]))
static func visual(g,kind,id,p,aim,radius,duration):
 if g.god_state.effects.size()<64:g.god_state.effects.append({"kind":kind,"id":id,"p":p,"aim":aim,"radius":radius,"life":duration,"duration":duration})
static func later(g,id,kind,p,aim,s,delay):
 if g.god_state.events.size()<96:g.god_state.events.append({"id":id,"kind":kind,"p":p,"aim":aim,"stats":s.duplicate(),"wait":delay})
static func thunder(g,id,p,power,radius):
 g.blast(p,radius,power,id)
 if g.strikes.size()<180:g.strikes.append({"a":p+Vector2(-25,-190),"b":p,"life":.23,"wait":0.0})
 g.sound.emit("thunder_hit")
static func charge(g,id,amount=1):
 if not active(g):return
 g.god_state.reserve=mini(8,g.god_state.reserve+amount)
 if g.god_state.reserve<8 or g.time<g.god_state.discharge_ready:return
 g.voice_event.emit("stormload")
 # Cloudbreaker may spend a full reserve; otherwise one shared cooldown bounds discharges.
 if g.weapons.keys().any(func(key):return g.C.WEAPONS[key].get("god_kind","")=="gauntlet"):return
 g.god_state.reserve=0
 g.god_state.discharge_ready=g.time+2.0
 var target=g.nearest(g.pos,420)
 if target!=null:thunder(g,id,target.p,g.Rules.stats(g,id).power*1.6,80*g.area_scale())
static func update(g,dt):
 if not active(g):return
 if g.god_state.is_empty():reset(g)
 var pending=g.god_state.events
 g.god_state.events=[]
 for event in pending:
  if not g.weapons.has(event.id):continue
  event.wait-=dt
  if event.wait>0:g.god_state.events.append(event);continue
  match event.kind:
   "thunder":thunder(g,event.id,event.p,event.stats.power,event.stats.radius)
   "cut":cut(g,event.id,event.p,event.aim,event.stats)
   "front":front(g,event.id,event.aim,event.stats)
   "wave":wave(g,event.id,event.stats)
   "sweep":sweep(g,event.id,event.p,event.aim,event.stats)
   "cast":cast(g,event.id,event.stats,false)
   "burst":g.blast(event.p,event.stats.radius,event.stats.power,event.id);g.sound.emit("impact_frost")
  if not g.active:return
 var effects=g.god_state.effects
 for fx in effects:
  if fx.kind in ["sweep","line","wave"] and g.weapons.has(fx.id):
   var before=clampf(1-fx.life/fx.duration,0,1)
   var after=clampf(before+dt/fx.duration,0,1)
   var first=fx.p+fx.aim*fx.radius*(before*2-1)
   var last=fx.p+fx.aim*fx.radius*(after*2-1)
   for enemy in g.nearby(fx.p,fx.radius+fx.width):
    if enemy.dead or enemy.uid in fx.hit:continue
    var touches=Geometry2D.get_closest_point_to_segment(enemy.p,first,last).distance_to(enemy.p)<=enemy.size+fx.width
    if fx.kind=="line":touches=Geometry2D.get_closest_point_to_segment(enemy.p,fx.p-fx.aim*fx.radius,fx.p+fx.aim*fx.radius).distance_to(enemy.p)<=enemy.size+fx.width
    if fx.kind=="wave":touches=enemy.p.distance_to(fx.p)<=fx.radius*after+enemy.size and enemy.p.distance_to(fx.p)+enemy.size>=fx.radius*before
    if enemy.boss and g.boss_stage<3:
     if fx.kind=="wave":touches=Dinos.body_distance(enemy,fx.p)<=fx.radius*after
     else:touches=Dinos.segment_hits(enemy,fx.p-fx.aim*fx.radius if fx.kind=="line" else first,fx.p+fx.aim*fx.radius if fx.kind=="line" else last,fx.width)
    if not touches:continue
    fx.hit[enemy.uid]=true
    g.hit(enemy,fx.power,fx.id)
    if not g.active:return
    if fx.kind=="wave":
     enemy.god_mark_until=g.time+5.0
     enemy.god_mark_power=fx.power*(3.0 if branch(g,fx.id,10)=="call" else 1.8)
     if branch(g,fx.id,10)=="grip" and not enemy.boss and not enemy.anchor:enemy.slow=maxf(enemy.slow,2.0)
  fx.life-=dt
 g.god_state.effects=effects.filter(func(fx):return fx.life>0 and g.weapons.has(fx.id))
 for id in g.weapons:
  if g.C.WEAPONS[id].get("god_kind","")!="hammer":continue
  if branch(g,id,5)!="orbit":continue
  var s=g.Rules.stats(g,id)
  var population=[]
  for shot in g.shots:
   if shot.id==id and shot.get("god_hammer",false) and shot.life>0:population.append(shot)
  for i in population.size():
   var shot=population[i]
   if i>=s.count:shot.life=0;continue
   if not shot.get("orbit",false):shot.orbit=true;shot.angle=(shot.p-g.pos).angle();shot.radius=shot.p.distance_to(g.pos);shot.hit.clear()
  var angular=TAU*.38*(s.velocity/480.0)*(g.C.WEAPONS[id].cooldown/s.cooldown)
  var old=g.god_state.phase
  g.god_state.phase+=angular*dt
  var turns=floori(g.god_state.phase/TAU)-floori(old/TAU)
  if turns>0 and not population.is_empty():
   charge(g,id,mini(2,turns))
   if branch(g,id,10)=="thunder" and g.time>=g.god_state.get("hammerfall_ready",0):
    g.god_state.hammerfall_ready=g.time+1.0
    var target=g.nearest(g.pos,450)
    if target!=null:thunder(g,id,target.p,s.power,65*g.area_scale())
  var slot=0
  for shot in population:
   if shot.life<=0:continue
   shot.goal_angle=g.god_state.phase+slot*TAU/mini(s.count,population.size())
   slot+=1
static func cast(g,id,s,echoes=true):
 if not active(g):return false
 var d=g.C.WEAPONS[id]
 var target=g.weapon_target(id)
 var aim=(target.p-g.pos).normalized() if target!=null else Vector2(g.facing,0)
 match d.god_kind:
  "hammer":
   if not g.starter_attack.is_empty():return false
   if branch(g,id,5)=="orbit":
    var count=0
    for shot in g.shots:
     if shot.id==id and shot.get("god_hammer",false) and shot.life>0:count+=1
    if count>=s.count:return false
   elif target==null:return false
   g.Combat.Starter.start(g,id,aim,s)
  "spear":
   if target==null:return false
   for j in s.count:
    var direction=aim.rotated((j-(s.count-1)*.5)*.1)
    if branch(g,id,5)=="anchor":
     var center=g.pos+direction*s.range*.55
     var fx={"kind":"line","id":id,"p":center,"aim":direction,"radius":s.range*.5,"width":13*g.area_scale(),"power":s.power,"hit":{},"life":1.6,"duration":1.6}
     if g.god_state.effects.size()<64:g.god_state.effects.append(fx)
     if branch(g,id,10)=="recall":later(g,id,"cut",center,direction,s,.8)
    else:
     var shot=g.shoot(id,g.pos,direction,s.power,s.velocity,s.lifetime,s.pierce)
     if shot!=null:
      if branch(g,id,5)=="hunt":shot.locked_target=target
      if branch(g,id,10)=="recall":shot.return_after=.45
  "gauntlet":
   var empowered=g.god_state.reserve>=8 and g.time>=g.god_state.discharge_ready
   if empowered:
    if branch(g,id,10)!="reserve":g.god_state.reserve=0
    g.god_state.discharge_ready=g.time+2.0
    s=s.duplicate();s.power*=1.8
   front(g,id,aim,s)
   if branch(g,id,5)=="double":
    var second=s.duplicate();second.front_arc=.75
    later(g,id,"front",g.pos,aim,second,.22)
   if branch(g,id,10)=="aftershock":later(g,id,"thunder",g.pos+aim*s.radius,aim,s,.5)
  "rebuke":
   if target==null:return false
   var count=mini(9,s.count)
   var prey=g.nearby(g.pos,s.range)
   prey.sort_custom(func(a,b):return a.p.distance_squared_to(g.pos)<b.p.distance_squared_to(g.pos))
   for j in count:
    var p=prey[j%prey.size()].p if not prey.is_empty() else target.p
    var stats=s.duplicate()
    if j==count-1 and branch(g,id,10)=="converge":stats.power*=1.8;stats.radius*=1.5
    var delay=(.25 if branch(g,id,5)=="fast" else .65)+j*.14
    visual(g,"warning",id,p,Vector2.ZERO,stats.radius,delay)
    later(g,id,"thunder",p,aim,stats,delay)
    if branch(g,id,10)=="echo":stats.power*=.5;later(g,id,"thunder",p,aim,stats,delay+.45)
  "sword":
   if target==null:return false
   var center=g.pos+(target.p-g.pos).limit_length(s.range)
   sweep(g,id,center,aim.orthogonal(),s)
   if branch(g,id,5)=="twin":sweep(g,id,center,-aim.orthogonal(),s)
   if branch(g,id,10)=="return":later(g,id,"sweep",center,-aim.orthogonal(),s,.6)
   if branch(g,id,10)=="sun":later(g,id,"thunder",center,aim,s,.65)
   if d.get("god_combo","")=="frost":
    for j in mini(8,s.count+2):
     var shot=g.shoot(id,center,aim.rotated((j-(s.count+1)*.5)*.15),s.power*.5,s.velocity,s.lifetime,2)
     if shot!=null:shot.locked_target=target;shot.homing=maxf(4.0,shot.homing)
  "bow":
   if target==null:return false
   target.god_quarry_until=g.time+3.0
   for j in s.count:
    var shot=g.shoot(id,g.pos,aim.rotated((j-(s.count-1)*.5)*.13),s.power,s.velocity,s.lifetime,s.pierce)
    if shot!=null:shot.target=target;shot.locked_target=target;shot.seek=.2
   if branch(g,id,5)=="quarry":g.hit(target,s.power*.65,id)
   if branch(g,id,10)=="shatter":later(g,id,"burst",target.p,aim,s,.55)
  "horn":
   wave(g,id,s)
   if branch(g,id,5)=="echo":later(g,id,"wave",g.pos,aim,s,.65)
   if d.get("god_combo","")=="cross":
    var count=0
    for enemy in g.nearby(g.pos,s.radius):
     later(g,id,"cut",enemy.p,Vector2.RIGHT.rotated(.6),s,.55)
     later(g,id,"cut",enemy.p,Vector2.RIGHT.rotated(-.6),s,.75)
     count+=1
     if count>=3:break
  "cross":
   if target==null:return false
   var center=g.pos+(target.p-g.pos).limit_length(s.range)
   cut(g,id,center,aim.rotated(.65),s)
   later(g,id,"cut",center,aim.rotated(-.65),s,.15 if branch(g,id,5)=="swift" else .4)
   var finish=s.duplicate();finish.radius=s.radius*.3;finish.power*=1.5
   later(g,id,"thunder",center,aim,finish,.42 if branch(g,id,5)=="swift" else .7)
   if branch(g,id,10)=="cross":later(g,id,"thunder",center,aim,finish,.95)
   if branch(g,id,10)=="three":later(g,id,"cut",center,aim,s,.85)
 if echoes and "MELEE" in d.tags:
  for i in mini(8,s.repeat):later(g,id,"cast",g.pos,aim,s,.18*(i+1))
 if d.god_kind!="hammer":g.sound.emit("impact_metal" if d.god_kind in ["spear","sword","cross"] else "thunder_hit")
 return true
static func front(g,id,aim,s):
 var arc=s.get("front_arc",minf(PI,1.65 if branch(g,id,5)=="wide" else 1.2)+g.Rules.modifiers(g,id).get("arc",0)*.5)
 visual(g,"front",id,g.pos,aim,s.radius,.3)
 if not g.god_state.effects.is_empty() and g.god_state.effects.back().kind=="front":g.god_state.effects.back().arc=arc
 var count=0
 for enemy in g.nearby(g.pos,s.radius):
  var delta=enemy.p-g.pos
  if absf(aim.angle_to(delta))>arc:continue
  g.hit(enemy,s.power,id)
  if not g.active:return
  if not enemy.boss and not enemy.anchor and not g.rooted(enemy):enemy.p=g.terrain.move(enemy.p,delta.normalized()*45)
  if g.C.WEAPONS[id].get("god_combo","")=="rebuke" and count<9:
   var verdict=s.duplicate();verdict.radius*=.4;verdict.power*=.65
   later(g,id,"thunder",enemy.p,aim,verdict,.65);visual(g,"warning",id,enemy.p,aim,verdict.radius,.65);count+=1
static func cut(g,id,p,aim,s):
 visual(g,"cut",id,p,aim,s.radius,.22)
 for enemy in g.nearby(p,s.radius+20):
  var touches=Geometry2D.get_closest_point_to_segment(enemy.p,p-aim*s.radius,p+aim*s.radius).distance_to(enemy.p)<=enemy.size+17*g.area_scale()
  if enemy.boss and g.boss_stage<3:touches=Dinos.segment_hits(enemy,p-aim*s.radius,p+aim*s.radius,17*g.area_scale())
  if touches:g.hit(enemy,s.power,id)
  if not g.active:return
static func sweep(g,id,p,aim,s):
 if g.god_state.effects.size()<64:g.god_state.effects.append({"kind":"sweep","id":id,"p":p,"aim":aim,"radius":s.radius*1.5,"width":22*g.area_scale(),"power":s.power,"hit":{},"life":.55,"duration":.55})
static func wave(g,id,s):
 if g.god_state.effects.size()<64:g.god_state.effects.append({"kind":"wave","id":id,"p":g.pos,"aim":Vector2.RIGHT,"radius":s.radius,"width":12.0,"power":s.power,"hit":{},"life":.65,"duration":.65})
static func mark_bonus(g,enemy,id,channel):
 var tags=g.C.WEAPONS.get(id,{}).get("tags",[])
 if channel!="projectile" or "GOD" not in tags or "PROJECTILE" not in tags or enemy.get("god_mark_until",0)<=g.time:return 0.0
 enemy.god_mark_until=0.0
 return enemy.get("god_mark_power",0.0)
static func release(g,a):
 var id=a.id
 var s=a.stats
 var orbit=branch(g,id,5)=="orbit"
 var population=0
 for shot in g.shots:
  if shot.id==id and shot.get("god_hammer",false) and shot.life>0:population+=1
 var amount=1 if orbit else s.count
 if orbit and population>=s.count:return
 var origin=g.Combat.Starter.emission(g,a.aim)
 var trajectory=g.Combat.Starter.release_aim(g,id,origin,a.aim)
 for j in amount:
  var shot=g.shoot(id,origin,trajectory.rotated((j-(amount-1)*.5)*.13),s.power,s.velocity,s.lifetime,1 if branch(g,id,5)=="bounce" else s.pierce)
  if shot==null:continue
  var budget=(2+int((g.weapons[id].level-5)/2) if branch(g,id,5)=="bounce" else 0)+s.bounce
  shot.merge({"god_hammer":true,"orbit":orbit,"angle":(origin-g.pos).angle(),"radius":origin.distance_to(g.pos),"goal_angle":g.god_state.phase,"budget":maxi(0,budget),"original_budget":maxi(0,budget),"repeats":{},"next_hit":{},"prune_at":g.time+1.0,"repeat_wait":0.0,"repeat_uid":-1,"outward_until":g.time+maxf(.6,s.range/s.velocity)*(s.lifetime/g.C.WEAPONS[id].get("lifetime",4.0)),"life":1000000.0 if orbit else 6.0},true)
 if orbit:g.voice_event.emit("orbit_started" if population==0 else "orbit_added")
static func returning(g,shot):
 if shot.returning:return
 shot.returning=true;shot.hit.clear();shot.next_hit.clear();shot.repeat_uid=-1;shot.return_hits=0;shot.chain_target=null
static func update_shot(g,shot,dt):
 if not shot.get("god_hammer",false):return false
 if not g.weapons.has(shot.id) or not active(g):shot.life=0;return true
 var s=g.Rules.stats(g,shot.id)
 var was=shot.p
 shot.old=was
 if shot.orbit and branch(g,shot.id,5)!="orbit":returning(g,shot);shot.orbit=false;shot.life=4.0
 if shot.orbit:
  shot.angle=lerp_angle(shot.angle,shot.goal_angle,1-exp(-dt*12))
  var radius=s.radius*(s.range/g.C.WEAPONS[shot.id].range)*(s.lifetime/g.C.WEAPONS[shot.id].get("lifetime",4.0))
  if branch(g,shot.id,10)=="oath":radius*=1+.25*sin(g.god_state.phase*.5)
  shot.radius=lerpf(shot.radius,radius,1-exp(-dt*7))
  shot.p=g.pos+Vector2.from_angle(shot.angle)*shot.radius
 else:
  shot.life-=dt
  if not shot.returning and (g.time>=shot.outward_until or shot.life<2):returning(g,shot)
  if shot.returning:
   shot.v=(g.pos-shot.p).normalized()*maxf(maxf(650,s.velocity*1.35),g.speed()*1.7)
   if shot.p.distance_to(g.pos)<maxf(22,shot.v.length()*dt):
    shot.life=0;g.god_state.catch_until=g.time+.16;charge(g,shot.id)
    if branch(g,shot.id,10)=="thunder" and g.time>=g.god_state.get("hammerfall_ready",0):
     g.god_state.hammerfall_ready=g.time+1.0
     var prey=g.nearest(g.pos,420)
     if prey!=null:thunder(g,shot.id,prey.p,s.power,65*g.area_scale())
    return true
  elif shot.get("chain_target")!=null:
   if shot.chain_target.dead:
    shot.chain_target=g.nearest(shot.p,220,shot.hit)
    if shot.chain_target==null:returning(g,shot);return true
   shot.v=(shot.chain_target.p-shot.p).normalized()*s.velocity
   shot.outward_until=g.time+.8
  elif shot.homing>0 and shot.repeat_uid<0:
   shot.seek-=dt
   if shot.seek<=0:shot.seek=.15;shot.target=g.nearest(shot.p,250,shot.hit)
   if shot.target!=null and not shot.target.dead:shot.v=shot.v.lerp((shot.target.p-shot.p).normalized()*shot.v.length(),minf(1,dt*shot.homing))
  if shot.repeat_uid>=0:
   shot.repeat_wait=maxf(0,shot.repeat_wait-dt)
   if shot.repeat_wait<=0:
    if shot.target==null or shot.target.dead:returning(g,shot)
    else:shot.v=(shot.target.p-shot.p).normalized()*s.velocity
  var movement=shot.v*dt
  if shot.get("chain_target")!=null:movement=movement.limit_length(shot.p.distance_to(shot.chain_target.p))
  shot.p+=movement
 if g.time>=shot.prune_at:
  shot.prune_at=g.time+1.0
  for uid in shot.next_hit.keys():
   if shot.next_hit[uid]<=g.time:shot.next_hit.erase(uid)
 if shot.repeat_wait>0:return true
 if shot.returning and shot.get("return_hits",0)>=s.pierce:return true
 var width=13*g.area_scale()
 var middle=(was+shot.p)*.5
 var candidates=g.nearby(middle,was.distance_to(shot.p)*.5+width)
 if not shot.orbit:candidates.sort_custom(func(a,b):return a.p.distance_squared_to(was)<b.p.distance_squared_to(was))
 for enemy in candidates:
  if enemy.dead or shot.next_hit.get(enemy.uid,0)>g.time:continue
  if shot.get("chain_target")!=null and enemy.uid!=shot.chain_target.uid:continue
  if not shot.orbit and enemy.uid in shot.hit and enemy.uid!=shot.repeat_uid:continue
  var touches=Geometry2D.get_closest_point_to_segment(enemy.p,was,shot.p).distance_to(enemy.p)<=enemy.size+width
  if enemy.boss and g.boss_stage<3:touches=Dinos.segment_hits(enemy,was,shot.p,width)
  if not touches:continue
  shot.next_hit[enemy.uid]=g.time+.35
  if enemy.uid==shot.repeat_uid:shot.repeats[enemy.uid]=shot.repeats.get(enemy.uid,0)+1
  shot.repeat_uid=-1
  shot.chain_target=null
  if not shot.orbit:shot.hit.append(enemy.uid)
  g.hit(enemy,s.power,shot.id,true,true,"projectile")
  if not g.active:return true
  var weapon=g.weapons[shot.id]
  weapon.god_contacts=weapon.get("god_contacts",0)+1
  if g.C.WEAPONS[shot.id].get("god_combo","")=="spear" and weapon.god_contacts%3==0:
   var prey=g.nearest(enemy.p,400,[enemy.uid])
   var direction=(prey.p-enemy.p).normalized() if prey!=null else shot.v.normalized()
   var spear=g.shoot(shot.id,enemy.p,direction,s.power*.65,760,1.0,4)
   if spear!=null:spear.god_aux=true
  if shot.orbit:continue
  if shot.returning:
   shot.return_hits=shot.get("return_hits",0)+1
   if shot.return_hits>=s.pierce:break
   continue
  shot.pierce-=1
  if shot.pierce>0:continue
  if shot.budget>0:
   var next=g.nearest(shot.p,220,shot.hit)
   if next!=null:
    shot.budget-=1;shot.pierce=1;shot.chain_target=next;shot.v=(next.p-shot.p).normalized()*s.velocity;shot.outward_until=g.time+.8
    break
   if not enemy.dead and branch(g,shot.id,10)=="oath" and shot.repeats.get(enemy.uid,0)<floori(shot.original_budget*.5):
    shot.budget-=1;shot.pierce=1;shot.repeat_uid=enemy.uid;shot.repeat_wait=.2;shot.target=enemy
    shot.v=Vector2.from_angle(shot.v.angle()+PI*.6)*minf(s.velocity,400.0)
    shot.outward_until=g.time+1.0
    break
  returning(g,shot)
  break
 return true
