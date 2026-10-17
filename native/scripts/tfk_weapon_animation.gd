extends RefCounted
## Dedicated, simulation-clock animations. The damage systems remain shared.
const LIMIT=96
static func cue(g,id,p,radius=80.0,end=Vector2.INF):
	var visuals=g.tfk_state.get("weapon_visuals",[])
	if visuals.size()>=LIMIT:visuals.pop_front()
	visuals.append({"id":id,"p":p,"end":end,"radius":radius,"at":g.time,"duration":.7})
	g.tfk_state.weapon_visuals=visuals
static func draw(target,world,g):
	var icons=preload("res://scripts/atlas_icons.gd")
	for v in g.tfk_state.get("weapon_visuals",[]):
		var t=clampf((g.time-v.at)/v.duration,0,1)
		var p=world.screen(v.p);var c=Color(g.C.WEAPONS[v.id].color,1-t)
		if v.end!=Vector2.INF:
			var end=world.screen(v.end);var delta=end-p
			var points=PackedVector2Array()
			for i in range(25):
				var u=i/24.0
				var amplitude=7.0 if v.id=="tfk_phone" else 3.0
				points.append(p+delta*u+delta.normalized().orthogonal()*sin(u*TAU*4-t*TAU*3)*amplitude*sin(u*PI))
			target.draw_polyline(points,c,3,true)
			for i in range(3):target.draw_circle(p+delta*fmod(t*2+i/3.0,1),3+i,c)
			continue
		var radius=v.radius*(.15+.85*sin(t*PI*.5))
		match v.id:
			"tfk_backpack","tfk_meltdown":
				for i in range(12):
					var ray=Vector2.from_angle(i*TAU/12+t*.6)
					target.draw_line(p+ray*radius*.7,p+ray*radius,c,4,true)
					target.draw_arc(p,radius,i*TAU/12,i*TAU/12+.18,8,c,3,true)
			"tfk_list","tfk_broadcast":
				for i in range(5):
					var ray=Vector2.from_angle(i*TAU/5-PI*.5)
					target.draw_line(p+ray*radius*.2,p+ray*radius,c,3,true)
					target.draw_circle(p+ray*radius,5,c)
			"tfk_mac":
				for i in range(4):
					var ray=Vector2.from_angle(i*TAU/4+t*.3)
					var elbow=p+ray*radius*.6
					target.draw_polyline(PackedVector2Array([p,elbow,elbow+ray.orthogonal()*20,elbow+ray.orthogonal()*20+ray*radius*.4]),c,3,true)
			"tfk_scenario","tfk_disaster":
				for i in range(6):
					var at=p+Vector2.from_angle(i*TAU/6+t)*radius
					target.draw_arc(at,8+t*12,0,TAU,12,c,2,true)
			_:
				target.draw_arc(p,radius,-PI*t,PI+PI*t,36,c,3,true)
		var scale=1+sin(t*PI)*.35
		target.draw_set_transform(p+Vector2(0,-25-t*25),sin(t*TAU)*.1,Vector2.ONE*scale)
		target.draw_texture_rect(icons.get_icon(v.id),Rect2(-18,-18,36,36),false,Color(1,1,1,1-t))
		target.draw_set_transform(Vector2.ZERO)
