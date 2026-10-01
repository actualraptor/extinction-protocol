extends RefCounted
const SHEET = preload("res://assets/hostile-fx-06.png")

static func piece(canvas,index,p,dimensions,angle = 0.0,alpha = 1.0):
	var cell = Vector2(SHEET.get_size())/Vector2(3,2)
	var source = Rect2(Vector2(index%3,floori(float(index)/3))*cell+Vector2.ONE*5,cell-Vector2.ONE*10)
	canvas.draw_set_transform(p,angle)
	canvas.draw_texture_rect_region(SHEET,Rect2(-dimensions/2,dimensions),source,Color(1,1,1,alpha))
	canvas.draw_set_transform(Vector2.ZERO)

static func hazard(canvas,h,p,clock):
	var charging = h.wait>0
	var progress = clampf(1-h.wait/maxf(0.01,h.warning),0,1)
	var pulse = 0.65+sin(clock*14)*0.12
	var color = Color("ffb95e") if charging else Color("ffedd2")
	if h.kind=="line":
		var dir = Vector2.from_angle(h.angle)
		var side = dir.orthogonal()*h.radius
		var end = p+dir*1000
		# Edge lines show the exact damaging footprint; painted lava gives it substance.
		canvas.draw_colored_polygon(PackedVector2Array([p+side,end+side,end-side,p-side]),Color(0.55,0.10,0.03,0.13 if charging else 0.25))
		for i in range(4): piece(canvas,0,p+dir*(125+i*250),Vector2(285,h.radius*2.4),h.angle,(0.18+progress*0.32) if charging else 0.95)
		canvas.draw_line(p+side,end+side,Color(color,pulse if charging else 0.85),2,true)
		canvas.draw_line(p-side,end-side,Color(color,pulse if charging else 0.85),2,true)
	elif h.kind=="ring":
		piece(canvas,2,p,Vector2.ONE*h.radius*2.5,clock*0.025,0.25+progress*0.25 if charging else 0.9)
		canvas.draw_arc(p,h.radius,0,TAU,80,Color(0.8,0.2,0.04,0.12 if charging else 0.4),40,true)
		for r in [h.radius-20,h.radius+20]: canvas.draw_arc(p,r,0,TAU,80,Color(color,pulse),2,true)
	else:
		piece(canvas,5 if charging else 1,p,Vector2.ONE*h.radius*2.65,clock*0.08 if charging else 0,0.5+progress*0.35 if charging else 1)
		canvas.draw_circle(p,h.radius,Color(0.6,0.12,0.02,0.1 if charging else 0.28))
		canvas.draw_arc(p,h.radius,0,TAU,64,Color(color,0.85),2,true)
		if charging: canvas.draw_arc(p,h.radius-5,-PI/2,-PI/2+TAU*progress,64,Color("ffe7a7"),3,true)
