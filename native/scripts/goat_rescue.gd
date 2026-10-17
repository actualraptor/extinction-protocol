extends RefCounted
const ID="torr"
const RADIUS=220.0
const PHASES=["THE SCENT OF BLOOD","THE PACK CLOSES","THE HORNED HUNT","THE LAST FIFTEEN HEARTBEATS"]
static func running(g):return g.goat_trial.get("state","")=="defending"
static func busy(g):return running(g) or (g.goat_trial.get("state","")=="saved" and g.time-g.goat_trial.finished_at<16)
static func setup(g):
 if not g.goat_trial.is_empty():return
 if g.mode!="expedition" or g.depth!=0 or ID in g.content_profile.get("unlocks",[]):return
 # Use the authored first route, so all maps get a reachable site without changing terrain.
 var route=g.stage.routes[0].normalized() if not g.stage.get("routes",[]).is_empty() else Vector2.RIGHT
 var center=g.terrain.open_position(g.stage.spawn+route*1300)
 for i in 20:
  var candidate=g.stage.spawn+route*(1100+i*35)
  if g.terrain.walkable(candidate,110) and g.terrain.kind(g.terrain.cell(candidate))==0:
   center=candidate;break
 var goats=[]
 for i in 2:
  var at=g.terrain.open_position(center+Vector2(-58 if i==0 else 58,0))
  goats.append({"p":at,"hp":20.0,"flash":0.0})
 g.goat_trial={"state":"waiting","p":center,"goats":goats,"seen":false,"age":0.0,"phase":-1,"budget":0.0,"final":0.0,"away":0.0,"attacks":[],"count":0}
static func begin(g):
 var t=g.goat_trial
 if t.is_empty() or t.state!="waiting" or not g.active or g.choosing:return false
 if g.pos.distance_to(t.p)>150 or g.boss!=null or g.spawn_respite>0:return false
 t.state="defending"
 g.director.current={}
 g.banner.emit("THE THUNDERER'S DEBT","Tend both goats inside the circle. Kill marked hunters before their bite lands.")
 g.sound.emit("boss");g.log_event("goat-rescue-start",{"map":g.map_id})
 return true
static func end(g,state,reason):
 var t=g.goat_trial
 if t.is_empty() or t.state in ["saved","failed"]:return
 var started=t.state=="defending"
 t.state=state;t.attacks.clear();t.finished_at=g.time
 if not started:return
 # Released hunters use ordinary AI; no lingering attacks or objective references.
 for e in g.enemies:
  if e.get("goat_hunter",false):e.goat_hunter=false;e.nav_timer=0.0
 g.log_event("goat-rescue-"+state,{"reason":reason,"elapsed":t.age})
 if state=="saved":
  if ID not in g.discovered:g.discovered.append(ID)
  g.amber+=75;g.hp=minf(g.max_hp,g.hp+g.max_hp*.2)
  g.sound.emit("torr_rumble")
  g.banner.emit("THE AIR HOLDS ITS BREATH","Something answers from above. +75 amber.")
  g.discovered_content.emit(ID)
 else:g.banner.emit("THE STORM CARRIES THEM AWAY",reason+" / Try again in another expedition.")
static func update(g,dt):
 if g.goat_trial.is_empty() or not g.active or g.choosing:return
 var t=g.goat_trial
 var distance=g.pos.distance_to(t.p)
 if t.state=="saved":
  var elapsed=g.time-t.finished_at
  if elapsed>=1.2 and not t.get("arrival_hit",false):
   t.arrival_hit=true;g.sound.emit("thunder_hit");g.sound.emit("torr_rumble")
   g.effect.emit("torr_slam",t.p,Color("bdeaff"),480)
   for enemy in g.enemies:
    if enemy.dead or enemy.boss or enemy.anchor or enemy.get("breakable",false) or enemy.p.distance_to(t.p)>480:continue
    enemy.p=g.terrain.move(enemy.p,(enemy.p-t.p).normalized()*240,enemy.size)
    enemy.slow=maxf(enemy.slow,3.0)
   g.log_event("torr-arrival",{"map":g.map_id})
  if elapsed>=14 and not t.get("departed",false):
   t.departed=true;g.sound.emit("thunder_hit");g.sound.emit("torr_rumble")
   g.banner.emit("A DEBT WRITTEN IN THUNDER","TORR STORMBUK is ready in Survivors.")
  return
 if t.state=="waiting" and not t.seen and distance<700:
  t.seen=true;g.banner.emit("A WOUNDED PAIR","Two great horned goats lie nearby. Approach, then press E to tend them.")
 if not running(g):return
 if t.goats.any(func(goat):return goat.hp<=0):end(g,"failed","The hunters overwhelmed a wounded goat");return
 t.age+=dt
 t.away=t.away+dt if distance>900 else 0.0
 if t.away>=8:end(g,"failed","You abandoned their side");return
 if t.age>=165:end(g,"failed","Their strength gave out before the rescue was complete");return
 for goat in t.goats:
  goat.flash=maxf(0,goat.flash-dt)
  if distance<=RADIUS:goat.hp=minf(100,goat.hp+.85*dt)
 var phase=3 if t.age>=90 else mini(2,int(t.age/30))
 if phase!=t.phase:
  t.phase=phase
  g.banner.emit(PHASES[phase],"Final stand: keep both goats healed for 15 seconds" if phase==3 else "Pressure rises / stay close to heal, step out to survive")
  g.sound.emit("boss")
 # Telegraphs belong to living attackers; killing one cancels its strike.
 for attack in t.attacks:
  if attack.enemy.get("frozen",0)>0 or g.buffs.get("freeze",0)>0:continue
  attack.wait-=dt
  if attack.wait>0 or attack.enemy.dead:continue
  var goat=t.goats[attack.goat]
  if attack.enemy.p.distance_to(goat.p)<attack.enemy.size+50:
   goat.hp=maxf(0,goat.hp-(4+t.phase*1.5));goat.flash=.25
   g.effect.emit("impact",goat.p,Color("f08f72"),28);g.sound.emit("impact_metal")
 t.attacks=t.attacks.filter(func(a):return a.wait>0 and not a.enemy.dead)
 if t.goats.any(func(goat):return goat.hp<=0):end(g,"failed","The hunters overwhelmed a wounded goat");return
 var both_full=t.goats.all(func(goat):return goat.hp>=100)
 if t.age>=90 and both_full:t.final+=dt
 elif t.final>0:t.final=maxf(0,t.final-dt)
 if t.final>=15:end(g,"saved","Both goats healed and final stand survived");return
 t.budget=minf(8,t.budget+dt*(2.4+t.phase*2.4))
 var living=0
 for e in g.enemies:
  if not e.dead and e.get("goat_hunter",false):living+=1
 while t.budget>=1:
  t.budget-=1
  if living>=110 or g.enemies.size()>=g.director.cap(g):continue
  spawn(g);living+=1
static func spawn(g):
 var t=g.goat_trial
 var pool=g.Maps.pool(g.map_id,g.depth,g.time).filter(func(k):return g.Bestiary.DATA[k].role in ["chase","armor"])
 if pool.is_empty():pool=[0]
 var kind=pool[g.rng.randi_range(0,pool.size()-1)]
 t.count+=1
 # Visible approach from outside the camera; never place a hunter on the goats.
 var at=g.spawn_position(float(t.count%4)*PI*.5+g.rng.randf_range(-.25,.25))
 var e=g.spawn_enemy(false,at,kind,false)
 var hunter=t.count%3!=0
 e.event_spawn=true;e.goat_hunter=hunter;e.goat_index=t.count%2
 e.hp*=.85+t.phase*.45;e.max_hp=e.hp;e.speed*=1.05+t.phase*.08
 if t.phase>=2 and t.count%15==0:
  e.elite=true;e.hp*=3;e.max_hp=e.hp;e.size*=1.25
 e.goat_ready=g.time+2
static func hunter_update(g,e,dt):
 if not e.get("goat_hunter",false) or not running(g):return false
 var t=g.goat_trial
 var goat=t.goats[e.goat_index]
 # Bodyguarding matters: hunters engage a nearby player instead of walking through them.
 var target=g.pos if e.p.distance_to(g.pos)<85 else goat.p
 var delta=target-e.p
 var slow=.48 if e.slow>0 or g.buffs.get("slow",0)>0 else 1.0
 var move=g.terrain.direction(e.p,target,e.uid)
 var before=e.p
 var winding=t.attacks.any(func(a):return a.enemy.uid==e.uid)
 if not winding and delta.length()>e.size+22:e.p=g.crowd.move(g,e,move*e.speed*slow*dt,dt)
 e.motion=(e.p-before).normalized();e.anim_attack=winding
 if target==g.pos:
  if delta.length()<e.size+15:g.hurt(16+g.depth*8,"Bodyguarding the wounded goats")
 elif delta.length()<e.size+42 and not winding and g.time>=e.goat_ready:
  var pending=0
  for attack in t.attacks:
   if attack.goat==e.goat_index:pending+=1
  if pending<2:
   t.attacks.append({"enemy":e,"goat":e.goat_index,"wait":1.25})
   e.goat_ready=g.time+3.5
 return true
static func status(g):
 var t=g.goat_trial
 if t.is_empty():return ""
 if t.state=="waiting" and t.seen:return "WOUNDED GOATS · "+str(roundi(g.pos.distance_to(t.p)))+"m · E nearby to begin"
 if not running(g):return ""
 if t.away>0:return "RETURN TO THE GOATS · "+str(ceili(8-t.away))+"s"
 var heal="TENDING" if g.pos.distance_to(t.p)<=RADIUS else "STEP INTO THE CIRCLE TO HEAL"
 return "GOATS %s / %s%% · %s"%[roundi(t.goats[0].hp),roundi(t.goats[1].hp),"FINAL "+str(ceili(15-t.final))+"s" if t.final>0 else heal]
