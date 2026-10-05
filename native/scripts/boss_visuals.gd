extends RefCounted
const Icons=preload("res://scripts/atlas_icons.gd")
const Hostile=preload("res://scripts/hostile_fx.gd")
const Bosses=preload("res://scripts/boss_encounters.gd")
static func draw(canvas,world):
 var g=world.sim
 if g.boss==null or g.boss_stage==3:return
 var b=g.boss
 var color=Color(Bosses.COLORS[b.identity])
 var progress=clampf(1-b.action_left/maxf(0.01,b.action_length),0,1)
 var p=world.screen(b.p)
 if b.action=="windup":
  canvas.draw_texture_rect(Icons.get_icon(b.identity,"boss",g.halloween),Rect2(p-Vector2(30,b.size*2+65),Vector2(60,60)),false,Color(color,0.5+progress*0.5))
 if b.action in ["charge","pounce"]:
  for j in range(5):
   var trail=b.p-b.aim*(j+1)*30
   Hostile.piece(canvas,4,world.screen(trail),Vector2(75,38),b.aim.angle(),(1-float(j)/5)*0.45)
 if b.identity=="aurora":
  for side in [-1,1]:
   Hostile.piece(canvas,3,p+Vector2(side*80,-45),Vector2(100,65),world.clock*side,0.24)
 if b.identity=="basalt" and g.phase==2:
  for j in range(3):Hostile.piece(canvas,1,p+Vector2.from_angle(j*TAU/3+world.clock)*b.size*0.6,Vector2(55,55),world.clock,0.6)
 for e in b.props:
  if e.dead:continue
  var at=world.screen(e.p)
  var icon="orbital" if e.prop_kind=="lens" else "miasma"
  var pulse=1+sin(world.clock*5+e.uid)*0.07
  canvas.draw_texture_rect(Icons.get_icon(icon,"weapon"),Rect2(at-Vector2(28,50)*pulse,Vector2(56,56)*pulse),false,Color(1.7,1.7,1.7) if e.flash>0 else Color.WHITE)
  canvas.draw_line(at+Vector2(-24,14),at+Vector2(24,14),Color("182a27"),5)
  canvas.draw_line(at+Vector2(-24,14),at+Vector2(-24+48*e.hp/e.max_hp,14),color,3)
 for shot in g.hostile_shots:
  if not shot.has("theme"):continue
  var at=world.screen(shot.p)
  var icon={"basalt":"mortar","bloom":"miasma","aurora":"stasis"}.get(shot.theme,"frost")
  if shot.get("arc",false):
   var flight=clampf(1-shot.life/shot.flight,0,1)
   canvas.draw_set_transform(at,0,Vector2(1,0.35))
   canvas.draw_circle(Vector2.ZERO,17,Color(0,0,0,0.4))
   canvas.draw_set_transform(Vector2.ZERO)
   at.y-=sin(flight*PI)*135
  canvas.draw_set_transform(at,world.clock*3)
  canvas.draw_texture_rect(Icons.get_icon(icon,"weapon"),Rect2(Vector2(-19,-19),Vector2(38,38)),false)
  canvas.draw_set_transform(Vector2.ZERO)
