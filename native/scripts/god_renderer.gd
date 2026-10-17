extends Node2D
const Icons=preload("res://scripts/atlas_icons.gd")
var world
func _process(_dt):queue_redraw()
func weapon(id,at,angle,dimension):
 var icon=Icons.get_icon(id)
 if icon==null:return
 draw_set_transform(at,angle)
 draw_texture_rect(icon,Rect2(Vector2.ONE*-dimension*.5,Vector2.ONE*dimension),false)
 draw_set_transform(Vector2.ZERO)
func _draw():
 if world==null or world.sim==null:return
 var g=world.sim
 if g.god_state.is_empty() or g.C.HEROES[g.hero].get("weapon_set","")!="god":return
 for enemy in g.enemies:
  if enemy.dead:continue
  if enemy.get("god_quarry_until",0)>g.time:
   draw_arc(world.screen(enemy.p),enemy.size+7,0,TAU,24,Color("b8f0ff"),1.5,true)
  elif enemy.get("god_mark_until",0)>g.time:
   draw_arc(world.screen(enemy.p),enemy.size+5,0,TAU,24,Color("d7b66c"),1.5,true)
 for shot in g.shots:
  var d=g.C.WEAPONS[shot.id]
  if "GOD" not in d.tags or shot.life<=0:continue
  var at=world.screen(shot.p)
  if shot.get("god_hammer",false):
   draw_circle(at+Vector2(0,7),9,Color(0,0,0,.28))
   weapon("mjolnir",at-Vector2(0,7),g.time*10,38*minf(1.4,g.area_scale()))
  elif d.god_kind=="spear" or shot.get("god_aux",false):weapon("gungnir",at,shot.v.angle()+PI*.25,52)
  else:
   var direction=shot.v.normalized()
   draw_line(at-direction*20,at+direction*8,Color("c9f7ff"),3,true)
   draw_line(at+direction*8,at-direction*3+direction.orthogonal()*6,Color("f0fcff"),2,true)
   draw_line(at+direction*8,at-direction*3-direction.orthogonal()*6,Color("f0fcff"),2,true)
 for fx in g.god_state.effects:
  var p=world.screen(fx.p)
  var progress=clampf(1-fx.life/fx.duration,0,1)
  var color=Color(g.C.WEAPONS[fx.id].color,1-progress*.6)
  match fx.kind:
   "warning":
    draw_arc(p,fx.radius,0,TAU,48,Color(color,.3+.35*progress),1.5,true)
    draw_arc(p,fx.radius*.55,0,TAU*progress,32,Color(color,.6),2,true)
   "cut","line":
    var a=p-fx.aim*fx.radius
    var b=p+fx.aim*fx.radius
    draw_line(a,b,Color(color,.25),8,true)
    draw_line(a,b,color,2.5,true)
    if fx.kind=="line":weapon("gungnir",b,fx.aim.angle()+PI*.25,42)
   "sweep":
    var at=p+fx.aim*fx.radius*(progress*2-1)
    draw_arc(at,22,progress*TAU,progress*TAU+PI,20,Color(color,.5),2,true)
    weapon("summer_edge",at,fx.aim.angle()+PI*.25+sin(progress*PI)*.7,54)
   "wave":
    draw_arc(p,fx.radius*progress,0,TAU,64,color,3,true)
    draw_arc(p,maxf(0,fx.radius*progress-9),0,TAU,64,Color(color,.22),2,true)
   "front":
    var arc=fx.get("arc",1.2)
    draw_arc(p,fx.radius*progress,fx.aim.angle()-arc,fx.aim.angle()+arc,32,color,5,true)
    for j in 5:
     var aim=fx.aim.rotated((j-2)*arc*.4)
     draw_line(p+aim*fx.radius*progress*.7,p+aim*fx.radius*progress,color,2,true)
