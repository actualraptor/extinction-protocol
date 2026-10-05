extends Node2D
var world
var dust_stamp
func _ready():
 use_parent_material=false
 material=null
 var gradient=Gradient.new()
 gradient.set_color(0,Color(1,1,1,.3))
 gradient.set_color(1,Color(1,1,1,0))
 dust_stamp=GradientTexture2D.new()
 dust_stamp.gradient=gradient;dust_stamp.width=48;dust_stamp.height=48
 dust_stamp.fill=GradientTexture2D.FILL_RADIAL
 dust_stamp.fill_from=Vector2(.5,.5);dust_stamp.fill_to=Vector2(1,.5)
func _process(_dt):queue_redraw()
func _draw():
 if world==null or world.sim==null:return
 for e in world.effects:
  if e.kind.begins_with("kael_slam_") or e.kind.begins_with("kael_crater_"):
   render(self,e,world.screen(e.p),1.0-e.life/e.max)


# Fixed segment counts keep rapid slams cheap and visually consistent.
static func render(canvas,e,p,progress):
 var material_name=e.kind.get_slice("_",2)
 var band=int(e.kind.get_slice("_",3))
 var strong=int(e.kind.get_slice("_",4))==4
 var glow=int(e.kind.get_slice("_",6))
 var width=e.size/float(band+1)
 var fade=pow(1.0-clampf(progress,0,1),.7)
 var color=Color("779eae") if material_name=="ice" else Color("77634a") if material_name=="dirt" else Color("777c82")
 var highlight=Color("bce8ec") if material_name=="ice" else color.lightened(.3)
 var glint=Color("9de9f4") if material_name=="ice" else Color("d2a568")
 var fresh=pow(1.0-progress,1.5 if glow>0 else 3)
 if glow>0:glint=Color("70dcff") if material_name=="ice" else Color("ffb348") if glow==1 else Color("ffd575")
 var segments=18 if strong else 14
 var front=e.size-width*.35*(1-progress)
 if e.kind.begins_with("kael_crater_"):
  var crater=PackedVector2Array()
  for i in range(12):
   var angle=i*TAU/12
   crater.append(p+Vector2.from_angle(angle)*front*(.85+.12*sin(i*7.3)))
  canvas.draw_colored_polygon(crater,Color(.025,.027,.022,fade*.6))
  crater.append(crater[0])
  canvas.draw_polyline(crater,Color(color,fade*.38),1.2,true)
  if glow>0:
   canvas.draw_polyline(crater,Color(glint,fresh*.18),8+glow*3,true)
   canvas.draw_polyline(crater,Color(glint,fresh*.9),2+glow,true)
  return
 for j in range(segments):
  var angle=j*TAU/segments+band*.17
  var dir=Vector2.from_angle(angle)
  var tangent=dir.orthogonal()
  var seed=sin(j*19.71+band*7.13)
  var at=p+dir*(front+seed*width*.13)
  var span=front*TAU/segments*.37
  var line=PackedVector2Array([at-tangent*span-dir*4,at-tangent*span*.4+dir*(4+seed*5),at+tangent*span*.2-dir*3,at+tangent*span+dir*5])
  canvas.draw_polyline(line,Color(.025,.025,.022,fade*.42),1.7 if strong else 1.3,true)
  if glow>0:
   canvas.draw_polyline(line,Color(glint,fresh*.12),10+glow*5,true)
   canvas.draw_polyline(line,Color(glint,fresh*.32),5+glow*2,true)
  canvas.draw_polyline(line,Color(glint,fresh*.95),1.5+glow,true)
  if glow==2:canvas.draw_polyline(line,Color("e5faff" if material_name=="ice" else "fff3c9",fresh*.9),1.2,true)
  var inner=p+dir*maxf(4,front-width*.8)
  var crack=PackedVector2Array([inner,inner.lerp(at,.38)+tangent*seed*9,inner.lerp(at,.68)-tangent*6,at])
  canvas.draw_polyline(crack,Color(.025,.025,.02,fade*.38),1.2,true)
  if glow>0:
   canvas.draw_polyline(crack,Color(glint,fresh*.16),7+glow*2,true)
   canvas.draw_polyline(crack,Color(glint,fresh*.8),1+glow*.6,true)
  canvas.draw_line(crack[2],crack[2]+dir*width*.18+tangent*12,Color(glint,fresh*.45),.8,true)
  if j%2==0:
   var lift=sin(progress*PI)*(20 if strong else 14)
   var center=at+dir*progress*8+Vector2(0,-lift)
   var w=minf(17,span*.65)*(.7+absf(seed)*.4)
   var slab=PackedVector2Array([center-tangent*w,center-tangent*w*.6-dir*9,center+tangent*w*.65-dir*6,center+tangent*w+dir*5,center+dir*8])
   var drop=Vector2(0,4+absf(seed)*4)
   var shadow=PackedVector2Array()
   for v in slab:shadow.append(v+Vector2(0,lift+5))
   canvas.draw_colored_polygon(shadow,Color(0,0,0,fade*.15))
   var side=PackedVector2Array([slab[0],slab[4],slab[3],slab[3]+drop,slab[4]+drop,slab[0]+drop])
   canvas.draw_colored_polygon(Geometry2D.convex_hull(side),Color(color.darkened(.65),fade*.85))
   canvas.draw_colored_polygon(slab,Color(color.lightened(seed*.12),fade*.85))
   canvas.draw_colored_polygon(PackedVector2Array([slab[0],slab[1],center,slab[4]]),Color(color.darkened(.24),fade*.6))
   canvas.draw_line(slab[1],slab[2],Color(highlight,fade*.6),1,true)
   canvas.draw_line(slab[3],slab[4],Color(color.darkened(.55),fade*.6),1,true)
   var dust_size=Vector2(38,21)*(1+progress*1.3)
   canvas.draw_texture_rect(canvas.dust_stamp,Rect2(at+dir*progress*15-dust_size*.5,dust_size),false,Color(color.lightened(.3),fade*.7))
