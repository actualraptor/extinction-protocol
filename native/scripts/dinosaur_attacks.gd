extends RefCounted
## Shared physical hit geometry; encounter state owns timing and commitment.
const MOVES={
 "thorn":["HORN CHARGE","HORN SWEEP","EARTH STOMP"],
 "basalt":["PREDATORY RUSH","CRUSHING BITE","TAIL SWEEP","APEX ROAR"],
 "hunt":["FLANK POUNCE","CREST FEINT","FROZEN TRAIL"],
 "aurora":["FEATHERED RUSH","PACK CALL","APEX ROAR"],
 "warden":["CLAW FAN","CROSS SLASH","CLAW DRAG"],
 "bloom":["BODY RUSH","JAW SWEEP","TAIL SWEEP"]}
static func shape(move):
 match move:
  "APEX ROAR":
   if "--painted-foot-plant" in OS.get_cmdline_user_args() or OS.has_feature("boss_rework"):return {"kind":"circle","radius":155.0,"length":0.0,"arc":0.0,"damage":20.0,"duration":4.5}
   return {"kind":"circle","radius":155.0,"length":0.0,"arc":0.0,"damage":20.0,"duration":.9}
  "SEISMIC STOMP":return {"kind":"circle","radius":95.0,"length":0.0,"arc":0.0,"damage":32.0,"duration":1.0}
  "HORN CHARGE","PREDATORY RUSH","FEATHERED RUSH","BODY RUSH":return {"kind":"line","radius":43.0,"length":430.0,"arc":0.0,"damage":34.0,"duration":0.8}
  "FLANK POUNCE","CREST FEINT","FROZEN TRAIL":return {"kind":"circle","radius":85.0,"length":0.0,"arc":0.0,"damage":30.0,"duration":0.7}
  "CRUSHING BITE":return {"kind":"cone","radius":220.0,"length":0.0,"arc":0.8,"damage":42.0,"duration":0.65}
  "TAIL SWEEP":return {"kind":"cone","radius":210.0,"length":0.0,"arc":2.7,"damage":29.0,"duration":0.85}
  "HORN SWEEP","JAW SWEEP":return {"kind":"cone","radius":160.0,"length":0.0,"arc":2.1,"damage":32.0,"duration":0.7}
  "CLAW FAN","CROSS SLASH","CLAW DRAG":return {"kind":"cone","radius":210.0,"length":0.0,"arc":2.3,"damage":31.0,"duration":1.0}
  _:return {"kind":"circle","radius":155.0,"length":0.0,"arc":0.0,"damage":20.0,"duration":0.9}
static func hits(b,point):
 var s=shape(b.move)
 var delta=point-b.p
 if s.kind=="cone":return delta.length()<s.radius and absf(wrapf(delta.angle()-b.attack_angle,-PI,PI))<s.arc/2
 return delta.length()<s.radius
static func body_contains(b,point):
 return body_distance(b,point)<15
static func ground_body_clear(terrain,position,heading,half):
 var axis=Vector2.from_angle(heading)*half
 for fraction in [-1.0,-.5,0.0,.5,1.0]:
  if not terrain.walkable(position+axis*fraction,43):return false
 return true
static func move_ground_body(terrain,origin,travel,old_heading,wanted_heading,half):
 var position=origin;var heading=old_heading
 var slide_direction=Vector2.ZERO
 var turn=wrapf(wanted_heading-old_heading,-PI,PI)
 var steps=maxi(1,maxi(ceili(travel.length()/12.0),ceili(absf(turn)*half/12.0)))
 for index in range(steps):
  var next_heading=old_heading+turn*float(index+1)/steps
  var displacement=travel/steps if slide_direction==Vector2.ZERO else slide_direction*travel.length()/steps
  var desired=terrain.move(position,displacement,43)
  var translation_blocked=displacement.length_squared()>.0001 and desired.distance_squared_to(position)<=.0001
  if not translation_blocked and ground_body_clear(terrain,desired,next_heading,half):
   position=desired;heading=next_heading;continue
  # Keep a blocked yaw from sweeping the torso through stone. Try grounded
  # translation with the previous yaw, then sidestep out of the obstruction.
  # terrain.move can return the unchanged origin at a wall. That is not a
  # successful slide: permit the lateral escape below instead of stalling.
  if desired.distance_squared_to(position)>.0001 and ground_body_clear(terrain,desired,heading,half):position=desired;continue
  var side=Vector2.from_angle(heading).orthogonal()
  for direction in [side,-side,-Vector2.from_angle(heading)]:
   # A direction that fits one substep can dead-end on the next, causing
   # opposite sidesteps to cancel. Check the whole frame's clearance first.
   var ahead=position+direction*maxf(24.0,travel.length())
   if not ground_body_clear(terrain,ahead,heading,half):continue
   var alternate=terrain.move(position,direction*travel.length()/steps,43)
   if ground_body_clear(terrain,alternate,heading,half):
    position=alternate;slide_direction=direction;break
 return {"p":position,"heading":heading}
static func attack_turn_clear(terrain,position,half,heading=0.0,target=Vector2.INF,move=""):
 # Allow for interpolated render position and between-sample turn motion.
 var clearance_half=half+8.0
 var desired=heading+TAU if target==Vector2.INF else (target-position).angle()
 var turn=TAU if target==Vector2.INF else wrapf(desired-heading,-PI,PI)
 var steps=maxi(1,ceili(absf(turn)*half/8))
 for index in range(steps+1):
  if not ground_body_clear(terrain,position,heading+turn*float(index)/steps,clearance_half):return false
 if move=="TAIL SWEEP":
  steps=ceili(PI*half/8)
  for index in range(steps+1):
   if not ground_body_clear(terrain,position,desired-PI*float(index)/steps,clearance_half):return false
 return true
static func attack_stance(terrain,position,heading,half,target=Vector2.INF,move=""):
 if attack_turn_clear(terrain,position,half,heading,target,move):return position
 for distance in [48.0,96.0,144.0,192.0,240.0]:
  for index in range(16):
   var travel=Vector2.from_angle(index*TAU/16)*distance
   var candidate=position+travel
   if not attack_turn_clear(terrain,candidate,half,heading,target,move):continue
   var reachable=true
   for step in range(1,ceili(distance/12)+1):
    if not ground_body_clear(terrain,position+travel*minf(1,step*12/distance),heading,half):reachable=false;break
   if reachable:return candidate
 return position
static func body_distance(b,point):
 var direction=b.get("motion",b.get("aim",Vector2.RIGHT)).normalized()
 if direction.length_squared()<.01:direction=b.get("aim",Vector2.RIGHT)
 if b.has("rig_heading"):direction=Vector2.from_angle(b.rig_heading)
 var local=point-b.p
 var half_length={"thorn":70.0,"basalt":90.0,"hunt":52.0,"aurora":76.0,"warden":55.0,"bloom":95.0}.get(b.get("identity","thorn"),65.0)
 var radius=37.0 if b.get("identity","")=="warden" else 43.0
 var along=clampf(local.dot(direction),-half_length,half_length)
 return (local-direction*along).length()-radius
static func segment_hits(b,start,end,width):
 var dir=b.get("aim",Vector2.RIGHT).normalized()
 if b.has("rig_heading"):dir=Vector2.from_angle(b.rig_heading)
 var half={"thorn":70.0,"basalt":90.0,"hunt":52.0,"aurora":76.0,"warden":55.0,"bloom":95.0}.get(b.get("identity","thorn"),65.0)
 var a=b.p-dir*half;var z=b.p+dir*half
 if Geometry2D.segment_intersects_segment(start,end,a,z)!=null:return true
 var distance=minf(Geometry2D.get_closest_point_to_segment(a,start,end).distance_to(a),Geometry2D.get_closest_point_to_segment(z,start,end).distance_to(z))
 distance=minf(distance,minf(Geometry2D.get_closest_point_to_segment(start,a,z).distance_to(start),Geometry2D.get_closest_point_to_segment(end,a,z).distance_to(end)))
 return distance<width+(37 if b.get("identity","")=="warden" else 43)
