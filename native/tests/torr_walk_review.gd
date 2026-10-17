extends SceneTree
const Exp=preload("res://scripts/expedition.gd")
const Art=preload("res://scripts/torr_animation.gd")
const SpriteAnimation=preload("res://scripts/survivor_animation.gd")
var checks=0
var failures=0
class Display extends Node2D:
 var g
 var clock=0.0
 func _draw():
  draw_rect(Rect2(0,0,1280,800),Color("343e35"))
  var font=ThemeDB.fallback_font
  draw_string(font,Vector2(20,30),"Torr — independent front / rear walk poses; moving throws below",HORIZONTAL_ALIGNMENT_LEFT,-1,20)
  for row in 2:
   for i in 8:
    var at=Vector2(80+i*150,180+row*190)
    draw_circle(at,20,Color(0,0,0,.25))
    Art.draw(self,g,at,Color.WHITE,i*.5,true,Vector2(1,-1).normalized() if row else Vector2(1,1).normalized())
    draw_string(font,at+Vector2(-20,35),str(i),HORIZONTAL_ALIGNMENT_LEFT,-1,18)
  for i in 6:
   g.starter_attack={"id":"mjolnir","start":g.time-Art.PHASES[i],"duration":1.0,"aim":Vector2.RIGHT,"hit":i>=4,"visual_until":0.0,"carry_until":0.0,"stats":{}}
   Art.draw(self,g,Vector2(100+i*190,620),Color.WHITE,fmod(clock*4+i*.5,4),true,Vector2.RIGHT)
  g.starter_attack.clear()
 func _process(dt):clock+=dt;queue_redraw()
func check(ok,message):
 checks+=1
 if not ok:failures+=1;printerr("FAIL / ",message)
func _initialize():call_deferred("run")
func run():
 var phases=[]
 for fps in [30,144]:
  var g=Exp.new();g.setup(7,"expedition",{},42)
  var animation=SpriteAnimation.new();animation.update(g)
  for frame in fps:
   g.pos+=Vector2(144.0/fps,0);g.time+=1.0/fps;animation.update(g)
  phases.append(animation.phase)
  var phase=animation.phase;g.time+=1.0/fps;animation.update(g)
  check(not animation.moving and is_equal_approx(animation.phase,phase),"Stopping preserves stride for next movement")
  g.pos+=Vector2(-10,0);g.time+=1.0/fps;animation.update(g)
  check(animation.moving and animation.direction.x<0,"Turning retains authored cycle")
 check(absf(wrapf(phases[0]-phases[1],-2,2))<.001,"Equal travelled distance has equal phase at 30 and 144 FPS")
 var g=Exp.new();g.setup(7,"expedition",{},42);g.time=1
 var display=Display.new();display.g=g;root.add_child(display)
 await process_frame;await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png("res://build/torr-walk-review.png")==OK,"Rendered authored walking and moving throws")
 await create_timer(3).timeout
 print("TORR WALK / ",checks," checks / ",failures," failures")
 quit(1 if failures else 0)
