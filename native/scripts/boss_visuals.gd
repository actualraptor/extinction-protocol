extends RefCounted
## Physical dust, claw arcs and phase posture; no unrelated spell props.
static func draw(c,w):
 var g=w.sim
 if g.boss==null or g.boss_stage==3:return
 var b=g.boss;var p=w.screen(b.p)
 var t=clampf(1-b.action_left/maxf(.01,b.action_length),0,1)
 var color=Color(preload("res://scripts/boss_encounters.gd").COLORS[b.identity])
 if b.action in ["charge","intro"]:
  for i in range(5):
   var at=w.screen(b.p-b.motion*(i+1)*19)+Vector2(sin(w.clock*7+i)*15,8)
   c.draw_circle(at,8+i*2,Color(color,.13*(1-float(i)/5)))
 if b.action=="strike" and b.move in ["CLAW FAN","CROSS SLASH","CLAW DRAG","TAIL SWEEP","HORN SWEEP","JAW SWEEP"]:
  var shape=preload("res://scripts/dinosaur_attacks.gd").shape(b.move)
  var alpha=sin(t*PI)*.65
  for i in range(3 if b.identity=="warden" else 1):
   c.draw_arc(p,shape.radius*(.65+i*.1),b.attack_angle-shape.arc/2,b.attack_angle-shape.arc/2+shape.arc*t,24,Color(color,alpha),3,true)
 if g.phase==2:
  c.draw_arc(p+Vector2(0,-12),b.size*.7,0,TAU,36,Color(color,.12),2,true)
