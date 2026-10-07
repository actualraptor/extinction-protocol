extends RefCounted
const SHEET=preload("res://assets/dinosaurs/regular-atlas.png")
const CELL=Vector2(256,192)
static func region(kind,frame):return Rect2(Vector2(frame*256,kind*192),CELL)
static func frame(e,clock,frozen=false):
 if e.get("dead",false):return 5
 if e.get("charge_wait",0)>0 or e.get("spit_wait",0)>0:return 4
 if e.get("anim_attack",false) or e.get("charge_time",0)>0:return 5
 if frozen or e.get("frozen",0)>0:return 0
 if e.get("motion",Vector2.ZERO).length_squared()<.01:return 0
 return int(clock*8+e.uid%4)%4
static func draw(canvas,e,p,clock,tint=Color.WHITE,frozen=false):
 var width=e.size*4.0*e.get("visual_scale",1.0)
 var motion=e.get("motion",Vector2.RIGHT)
 var facing=-1.0 if motion.x<-.01 else 1.0
 canvas.draw_set_transform(p,0,Vector2(facing,1))
 canvas.draw_texture_rect_region(SHEET,Rect2(-width*.5,-width*.72,width,width*.75),region(e.kind,frame(e,clock,frozen)),tint*e.get("visual_tint",Color.WHITE))
 canvas.draw_set_transform(Vector2.ZERO)
