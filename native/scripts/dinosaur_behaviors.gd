extends RefCounted
static func flyby(g,e,dt,slow):
 e.pass_time=maxf(0,e.get("pass_time",0.0)-dt)
 if e.pass_time<=0:
  e.pass_dir=(g.pos-e.p).normalized()
  e.pass_time=2.1
 var old=e.p
 e.p+=e.pass_dir*e.speed*1.35*slow*dt
 e.motion=e.pass_dir
 e.anim_attack=e.p.distance_squared_to(g.pos)<160*160
 if e.pass_time<.1 and e.p.distance_squared_to(g.pos)<180*180:e.pass_time=.6
 if Geometry2D.get_closest_point_to_segment(g.pos,old,e.p).distance_squared_to(g.pos)<pow(e.size+15,2):g.hurt(12+g.depth*5,"Struck during a "+g.Bestiary.DATA[e.kind].name+" attack pass")
static func ambush(g,e,dt,slow):
 e.stalk_time=maxf(0,e.get("stalk_time",2.4)-dt)
 var toward=(g.pos-e.p).normalized()
 if e.stalk_time<=0:
  e.stalk_time=3.4;e.ambush_dir=toward;e.ambush_time=.75
 e.ambush_time=maxf(0,e.get("ambush_time",0.0)-dt)
 var direction=e.get("ambush_dir",toward) if e.ambush_time>0 else toward.rotated(.75 if e.uid%2==0 else -.75)
 var old=e.p
 e.p=g.crowd.move(g,e,direction*e.speed*slow*dt*(1.8 if e.ambush_time>0 else .7),dt)
 e.motion=(e.p-old).normalized();e.anim_attack=e.ambush_time>0
