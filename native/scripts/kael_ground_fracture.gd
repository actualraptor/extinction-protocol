extends Node2D
## Ground-anchored crack stamps. Geometry is built once, never follows the hero.
var world
func _ready():
 use_parent_material=false
 material=null
func _process(_dt):queue_redraw()
func _draw():
 if world==null or world.sim==null:return
 for e in world.effects:
  if e.kind.begins_with("kael_slam_") or e.kind.begins_with("kael_crater_"):
   draw_set_transform(world.screen(e.p))
   render(self,e,Vector2.ZERO,1.0-e.life/e.max)
 draw_set_transform(Vector2.ZERO)
static func geometry(e):
 var points=PackedVector2Array()
 var rng=RandomNumberGenerator.new()
 rng.seed=int(e.kind.get_slice("_",7))+int(e.size)*31
 var phase=rng.randf()*TAU
 # Connected, angular fractures with short forks; no repeated wavy strokes.
 for j in range(8):
  var dir=Vector2.from_angle(j*TAU/8+phase)
  var tangent=dir.orthogonal()
  var previous=dir*e.size*.025
  for step in range(1,10):
   var reach=float(step)/9
   var point=dir*e.size*reach
   if step<9:point+=tangent*rng.randf_range(-1,1)*minf(30,e.size*.065)
   points.append_array(PackedVector2Array([previous,point]))
   if step in [3,5,7]:
    var fork=(point-previous).normalized().rotated(rng.randf_range(.65,1.3)*(1 if rng.randf()<.5 else -1))
    var length=minf(48,e.size*.15)*rng.randf_range(.5,1)
    var elbow=point+fork*length*.55
    var tip=elbow+fork.rotated(rng.randf_range(-.5,.5))*length*.45
    points.append_array(PackedVector2Array([point,elbow,elbow,tip]))
   previous=point
 for i in range(points.size()):
  if points[i].length()>e.size:points[i]=points[i].normalized()*e.size
 return points
static func render(canvas,e,_p,progress):
 if not e.has("cracks"):e.cracks=geometry(e)
 if not e.has("rim"):
  var rim=PackedVector2Array();var radius=clampf(e.size*.10,12,24)
  for i in range(16):
   var angle=i*TAU/16
   rim.append(Vector2(cos(angle),sin(angle)*.68)*radius*(.9+.07*sin(i*7.1)))
  e.rim=rim
 var glow=int(e.kind.get_slice("_",6))
 var fade=clampf((1-progress)*2,0,1)
 var ice=e.kind.get_slice("_",2)=="ice"
 var rim_color=Color("768995") if ice else Color("73644b")
 canvas.draw_colored_polygon(e.rim,Color(.02,.025,.026,fade*.65))
 var outline=e.rim.duplicate();outline.append(outline[0])
 canvas.draw_polyline(outline,Color(rim_color,fade*.65),2,false)
 var tint=Color("edbb3c") if glow==1 else Color("ef4829") if glow==2 else Color("5d5140")
 canvas.draw_multiline(e.cracks,Color(.025,.02,.015,fade*.8),2.5,false)
 if glow>0:
  canvas.draw_multiline(e.cracks,Color(tint,fade*.12),3.5 if glow==1 else 4,false)
  canvas.draw_multiline(e.cracks,Color(tint,fade*.65),.7 if glow==1 else .9,false)
 else:canvas.draw_multiline(e.cracks,Color(tint,fade*.6),.9,false)
