extends RefCounted
## Union-only delivery hooks retain the result ID for damage, kills and status credit.
static func after_aura(g,id,s,casts):
 if id!="solar_procession" or casts%4!=0:return
 for i in mini(12,s.count+4):
  g.shoot(id,g.pos,Vector2.from_angle(i*TAU/mini(12,s.count+4)),s.power*1.4,s.velocity,s.lifetime,s.pierce)
 g.effect.emit("ring",g.pos,Color("ffe4a0"),s.radius*1.8)
static func prepare_shot(g,shot):
 if shot==null:return
 if shot.id=="polar_crown":
  var count=g.shots.filter(func(other):return other.id==shot.id).size()
  shot.orbit_left=.55;shot.orbit_angle=(count-1)*TAU/maxi(1,g.Rules.stats(g,shot.id).count);shot.orbit_radius=70*g.area_scale()
 if shot.id=="prismatic_ouroboros":shot.pierce=2;shot.return_pierce=8
static func orbit(g,shot,dt):
 if shot.get("orbit_left",0)<=0:return false
 shot.orbit_left-=dt;shot.orbit_angle+=dt*5
 shot.p=g.pos+Vector2.from_angle(shot.orbit_angle)*shot.orbit_radius
 shot.old=shot.p;shot.v=Vector2.from_angle(shot.orbit_angle)*shot.v.length()
 if g.active and g.time>=g.relic_state.get("polar_pulse",0):
  g.relic_state.polar_pulse=g.time+.2
  g.blast(g.pos,g.Rules.stats(g,shot.id).radius,shot.damage*.18,shot.id)
 return true
static func turn(g,shot):
 if shot.id!="prismatic_ouroboros" or shot.get("union_secondary",false):return
 var aim=(g.pos-shot.p).normalized()
 for side in [-1,0,1]:
  if g.volleys.size()>=80:break
  g.volleys.append({"wait":.01,"id":shot.id,"origin":shot.p,"dir":aim.rotated(side*.4),"power":shot.damage*.45,"velocity":620.0,"life":.35,"pierce":2,"union_secondary":true})
static func projectile_hit(g,shot,e):
 if not g.active:return
 if shot.id=="funeral_procession" and g.zones.size()<24:
  var radius=175*g.area_scale()*(1+g.Rules.modifiers(g,shot.id).get("radius",0))
  g.zones.append({"p":e.p,"radius":radius,"id":shot.id,"damage":shot.damage*.65,"wait":0.0,"life":.55,"duration":.55,"age":0.0,"wave":true,"struck":{e.uid:true}})
 if shot.id=="tempest_anchor" and g.zones.size()<24 and g.time>=e.get("tempest_ready",0):
  e.tempest_ready=g.time+1.0
  var s=g.Rules.stats(g,shot.id)
  var duration=minf(4,1.5+s.duration)
  g.zones.append({"p":e.p,"radius":s.radius,"id":shot.id,"damage":shot.damage*.3,"wait":.45,"life":duration,"duration":duration,"interval":.5,"age":0.0,"tick":0.0,"pulse":0,"storm":true})
static func wave(g,zone,dt):
 var old=zone.radius*zone.age/zone.duration
 zone.age=minf(zone.duration,zone.age+dt);zone.life-=dt
 var radius=zone.radius*zone.age/zone.duration
 for e in g.nearby(zone.p,radius):
  if e.uid in zone.struck or e.p.distance_to(zone.p)+e.size<old:continue
  zone.struck[e.uid]=true;g.hit(e,zone.damage,zone.id)
  if not g.active:return
  if not e.boss and not e.anchor and not g.rooted(e):e.p=g.terrain.move(e.p,(e.p-zone.p).normalized()*25)
static func beam_pulse(g,b):
 var pulse=mini(ceili(b.life/.6),floori(b.age/.6))
 var terminal=b.age>=b.life-.000001
 if terminal:pulse=ceili(b.life/.6)+1
 if pulse<=b.union_pulse:return
 b.union_pulse=pulse
 if not b.target.dead:
  var center=g.pos+(b.target.p-g.pos).limit_length(b.stats.range)
  g.effect.emit("ring",center,Color("cbb7ff"),80)
  if terminal:g.blast(center,85*g.area_scale(),b.stats.power*.65,b.id)
  else:
   for e in g.nearby(center,80*g.area_scale()):
    if not e.boss and not e.anchor:e.slow=maxf(e.slow,1.0)
static func on_kill(g,e):
 if not g.weapons.has("plague_furnace") or e.get("poison_source","")!="plague_furnace" or e.get("poison_time",0)<=0:return
 # The existing proc queue prevents death-burst recursion and bounds work per tick.
 if g.proc_depth==0 and g.proc_queue.size()<32 and g.time>=g.relic_state.get("plague_ready",0):
  g.relic_state.plague_ready=g.time+.12
  g.proc_queue.append({"p":e.p,"id":"plague_furnace","damage":minf(350,g.Rules.stats(g,"plague_furnace").power*.4)})
