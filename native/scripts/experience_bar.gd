extends Control

var displayed = 0.0
var target = 0.0
var level = -1
var caption = ""
var pulse = 0.0
const Art=preload("res://scripts/ui_art.gd")

func set_progress(xp,goal,new_level,dt):
	var fraction = clampf(float(xp)/maxf(1,goal),0,1)
	if new_level!=level:
		displayed = fraction
		pulse = 1.0 if level>=0 else 0.0
	elif fraction>target:
		pulse = 0.7
	target = fraction
	level = new_level
	displayed = lerpf(displayed,target,1-exp(-dt*12))
	pulse = maxf(0,pulse-dt*2)
	caption = "LEVEL %s   •   %s / %s XP"%[level,int(xp),int(goal)]
	queue_redraw()

func _draw():
	# A single enclosing fossil frame owns the entire bottom HUD.
	var bounds=Rect2(Vector2.ZERO,size)
	draw_style_box(Art.button_style(),bounds)
	var track=Rect2(22,78,size.x-44,16)
	draw_rect(track.grow(2),Color("947542"))
	draw_rect(track,Color("071529"))
	var filled=track.size.x*displayed
	for y in range(16):
		var c=Color("65d4ff").lerp(Color("164cb1"),float(y)/16.0)
		draw_line(track.position+Vector2(0,y),track.position+Vector2(filled,y),c,1)
	for i in range(1,20):
		var x=track.position.x+track.size.x*i/20.0
		draw_line(Vector2(x,78),Vector2(x,94),Color(0.02,0.06,0.12,0.55),1)
	if filled>0:draw_line(Vector2(22+filled,78),Vector2(22+filled,94),Color(0.7,0.95,1,0.8),2)
	for x in [282.0,size.x-320]:
		draw_line(Vector2(x,20),Vector2(x,65),Color("75603d"),1)
	var font=Art.heading_font()
	var fs=17
	var text_width=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
	var origin=Vector2((size.x-text_width)/2,43)
	draw_string(font,origin,caption,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,Color("f2dba7"))
	var sub="EXPEDITION PROGRESS"
	var w=Art.body_font().get_string_size(sub,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
	draw_string(Art.body_font(),Vector2((size.x-w)/2,61),sub,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("a59678"))
	if pulse>0:draw_rect(track,Color(0.4,0.75,1,pulse*0.5),false,1)
