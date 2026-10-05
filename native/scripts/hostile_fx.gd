extends RefCounted
const SHEET = preload("res://assets/hostile-fx-06.png")

static func piece(canvas,index,p,dimensions,angle = 0.0,alpha = 1.0):
	var cell = Vector2(SHEET.get_size())/Vector2(3,2)
	var source = Rect2(Vector2(index%3,floori(float(index)/3))*cell+Vector2.ONE*5,cell-Vector2.ONE*10)
	canvas.draw_set_transform(p,angle)
	canvas.draw_texture_rect_region(SHEET,Rect2(-dimensions/2,dimensions),source,Color(1,1,1,alpha))
	canvas.draw_set_transform(Vector2.ZERO)

static func hazard(canvas,h,p,clock):
	if h.has("theme"):
		themed_hazard(canvas,h,p,clock)
		return
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

static func themed_hazard(canvas,h,p,clock):
	var colors={"thorn":"a9d96a","basalt":"ff9d57","hunt":"a4eaff","aurora":"c0a0ff","warden":"f9da86","bloom":"b2ea80"}
	var color=Color(colors.get(h.theme,"ffffff"))
	var charging=h.wait>0
	var progress=clampf(1-h.wait/maxf(0.01,h.warning),0,1)
	var alpha=0.25+progress*0.45 if charging else 0.95
	var icon={"thorn":"thorns","basalt":"mortar","hunt":"frost","aurora":"stasis","warden":"orbital","bloom":"miasma"}.get(h.theme,"fire")
	var texture=preload("res://scripts/atlas_icons.gd").get_icon(icon,"weapon")
	if h.kind=="line":
		var dir=Vector2.from_angle(h.angle)
		var side=dir.orthogonal()*h.radius
		var length=h.get("length",1000.0)
		var end=p+dir*length
		canvas.draw_colored_polygon(PackedVector2Array([p+side,end+side,end-side,p-side]),Color(color,0.1 if charging else 0.25))
		canvas.draw_line(p+side,end+side,Color(color,0.85),2,true)
		canvas.draw_line(p-side,end-side,Color(color,0.85),2,true)
		for j in range(maxi(1,int(length/75))):
			var at=p+dir*(j+0.5)*75
			canvas.draw_set_transform(at,h.angle+PI/2)
			canvas.draw_texture_rect(texture,Rect2(Vector2(-h.radius,-38),Vector2(h.radius*2,76)),false,Color(color,alpha))
		canvas.draw_set_transform(Vector2.ZERO)
	elif h.kind=="cone":
		var points=PackedVector2Array([p])
		for j in range(33):points.append(p+Vector2.from_angle(h.angle-h.arc/2+h.arc*j/32)*h.radius)
		canvas.draw_colored_polygon(points,Color(color,0.12 if charging else 0.32))
		canvas.draw_polyline(points,Color(color,0.75),2,true)
		for j in range(5):
			var at=p+Vector2.from_angle(h.angle-h.arc*0.4+h.arc*j/5)*h.radius*0.65
			canvas.draw_texture_rect(texture,Rect2(at-Vector2(45,45),Vector2(90,90)),false,Color(color,alpha))
	else:
		canvas.draw_arc(p,h.radius,0,TAU,48,Color(color,0.8),2,true)
		if charging:canvas.draw_arc(p,h.radius-5,-PI/2,-PI/2+TAU*progress,48,color,3,true)
		canvas.draw_texture_rect(texture,Rect2(p-Vector2.ONE*h.radius,Vector2.ONE*h.radius*2),false,Color(color,alpha))
