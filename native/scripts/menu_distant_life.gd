extends Control
var clock=0.0
func _process(dt):clock=fmod(clock+dt,24.0);queue_redraw()
func _draw():
 var atlas=preload("res://scripts/dinosaur_art.gd")
 for i in range(3):
  var phase=clock*TAU/24+i*.6
  var p=Vector2(size.x*(.72+sin(phase)*.085)+i*18,size.y*(.61+i*.012))
  var width=46.0+i*7
  draw_set_transform(p,0,Vector2(1 if cos(phase)>0 else -1,1))
  draw_texture_rect_region(atlas.SHEET,Rect2(-width/2,-width*.75,width,width*.75),atlas.region(0,int(clock*8+i)%4),Color(.10,.14,.17,.62))
 draw_set_transform(Vector2.ZERO)
