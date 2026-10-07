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
static func body_distance(b,point):
 var direction=b.get("motion",b.get("aim",Vector2.RIGHT)).normalized()
 if direction.length_squared()<.01:direction=b.get("aim",Vector2.RIGHT)
 var local=point-b.p
 var half_length={"thorn":70.0,"basalt":90.0,"hunt":52.0,"aurora":76.0,"warden":55.0,"bloom":95.0}.get(b.get("identity","thorn"),65.0)
 var radius=37.0 if b.get("identity","")=="warden" else 43.0
 var along=clampf(local.dot(direction),-half_length,half_length)
 return (local-direction*along).length()-radius
static func segment_hits(b,start,end,width):
 var dir=b.get("aim",Vector2.RIGHT).normalized()
 var half={"thorn":70.0,"basalt":90.0,"hunt":52.0,"aurora":76.0,"warden":55.0,"bloom":95.0}.get(b.get("identity","thorn"),65.0)
 var a=b.p-dir*half;var z=b.p+dir*half
 if Geometry2D.segment_intersects_segment(start,end,a,z)!=null:return true
 var distance=minf(Geometry2D.get_closest_point_to_segment(a,start,end).distance_to(a),Geometry2D.get_closest_point_to_segment(z,start,end).distance_to(z))
 distance=minf(distance,minf(Geometry2D.get_closest_point_to_segment(start,a,z).distance_to(start),Geometry2D.get_closest_point_to_segment(end,a,z).distance_to(end)))
 return distance<width+(37 if b.get("identity","")=="warden" else 43)
