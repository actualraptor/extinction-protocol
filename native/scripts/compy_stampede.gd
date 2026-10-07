extends RefCounted
## Lightweight dictionaries share the ordinary combat grid and MultiMesh renderer.
const KIND=4
const CONTACT_DAMAGE=7.0
const PUSH_SPEED=105.0
const ENEMY_PUSH_SPEED=160.0
static func prepare(g,dt):
 # One spatial lookup per simulation frame, shared by the entire flock.
 g.stampede_contacts.clear()
 if not g.enemies.any(func(other):return not other.dead and other.get("role","")=="stampede"):return
 for other in g.enemies:
  if other.dead or other.boss or other.anchor or other.get("breakable",false) or other.get("boss_prop",false) or other.get("role","")=="stampede":continue
  var key=g.crowd.cell(other.p)
  if not g.stampede_contacts.has(key):g.stampede_contacts[key]=[]
  g.stampede_contacts[key].append(other)
  other.stampede_push_left=ENEMY_PUSH_SPEED*dt
static func push_enemies(g,e,old,dt):
 var key=g.crowd.cell(e.p)
 var budget=24
 for offset in [Vector2i.ZERO,Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN,Vector2i(-1,-1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(1,1)]:
  var bucket=g.stampede_contacts.get(key+offset,[])
  for other in bucket:
   if budget<=0:return
   budget-=1
   if other.stampede_push_left<=0:continue
   var near=Geometry2D.get_closest_point_to_segment(other.p,old,e.p)
   if near.distance_squared_to(other.p)>pow(e.size+g.crowd.radius(other),2):continue
   var lateral=e.flow.orthogonal()
   var side=1.0 if (other.p-near).dot(lateral)>=0 else -1.0
   var shove=(e.flow+lateral*side*.65).normalized()
   var amount=minf(ENEMY_PUSH_SPEED*dt,other.stampede_push_left)
   other.p=other.p+shove*amount if g.crowd.airborne(other) else g.terrain.move(other.p,shove*amount,10)
   other.stampede_push_left-=amount
   other.erase("crowd_normals")
static func configure(g,e,direction):
 e.flow=direction.normalized();e.flow_start=e.p;e.flow_age=0.0
 e.flow_distance=maxf(g.spawn_view.x,g.spawn_view.y)+700
 e.flow_lifetime=e.flow_distance/e.speed+4.0
 e.hp=3.0;e.max_hp=3.0;e.elite=false;e.mutated=false;e.size=14.0
 e.visual_scale=2.0;e.visual_tint=Color(1.22,1.16,1.04)
 e.event_spawn=true;e.motion=e.flow
static func update(g,e,dt):
 e.flow_age+=dt
 var direction=e.flow
 var weave=sin(e.flow_age*3.1+e.uid*2.399)*.16
 var movement=(direction+direction.orthogonal()*weave)*e.speed*dt*(.48 if e.slow>0 else 1.0)
 var old=e.p
 e.p=g.terrain.move(old,movement,5)
 e.motion=direction
 push_enemies(g,e,old,dt)
 if Geometry2D.get_closest_point_to_segment(g.pos,old,e.p).distance_squared_to(g.pos)<pow(e.size+15,2):
  g.hurt(CONTACT_DAMAGE+g.depth*2,"Caught in the Compy stampede")
  # Push is independent of the shared damage invulnerability timer and bounded
  # across all contacts in this simulation frame; animals never recoil or stop.
  var push=minf(PUSH_SPEED*dt,g.stampede_push_left)
  if push>0:
   g.pos=g.terrain.move(g.pos,direction*push,14)
   g.stampede_push_left-=push
 if (e.p-e.flow_start).dot(direction)>e.flow_distance or e.flow_age>e.flow_lifetime or not g.terrain.bounds.grow(100).has_point(e.p):
  e.dead=true
