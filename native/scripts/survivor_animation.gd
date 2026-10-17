extends RefCounted

const SHEETS = [preload("res://assets/mara-walk.png"),preload("res://assets/kael-walk.png"),preload("res://assets/vesper-walk-v2.png"),preload("res://assets/iona-walk.png"),preload("res://assets/orin-walk.png")]
var regions = []
const TFK_SHEETS=[preload("res://assets/tfk-mathie-walk-v1.png"),preload("res://assets/tfk-johan-walk-v1.png")]
const TFK_ATTACK_SHEETS=[preload("res://assets/tfk-mathie-phone-v1.png"),preload("res://assets/tfk-johan-react-v1.png")]
var tfk_attacks=JSON.parse_string(FileAccess.get_file_as_string("res://assets/tfk-attack-regions.json"))
var tfk_attack_scales=[]
var tfk_regions=[]
var tfk_scales=[]
var scales = []
var direction = Vector2.DOWN
var phase = 0.0
var moving = false
var last_pos = Vector2.ZERO
var last_time = -1.0
var run = null

func _init():
	for character in tfk_attacks:
		var tallest=1.0
		for frame in character:tallest=maxf(tallest,frame.region[3])
		tfk_attack_scales.append(58.0/tallest)
	for character in JSON.parse_string(FileAccess.get_file_as_string("res://assets/tfk-walk-regions.json")):
		var frames=[];var tallest=1.0
		for bounds in character:
			frames.append(Rect2(bounds[0],bounds[1],bounds[2],bounds[3]));tallest=maxf(tallest,bounds[3])
		tfk_regions.append(frames);tfk_scales.append(58.0/tallest)
	# Alpha-indexed rectangles keep irregular painted sheet spacing from
	# clipping heads or leaking a neighboring frame into the walk cycle.
	var indexed = JSON.parse_string(FileAccess.get_file_as_string("res://assets/walk-regions.json"))
	for character in indexed:
		var frames = []
		var tallest = 1.0
		for bounds in character:
			frames.append(Rect2(bounds[0],bounds[1],bounds[2],bounds[3]))
			tallest = maxf(tallest,bounds[3])
		regions.append(frames)
		scales.append(68.0/tallest)

func update(s):
	if run != s:
		run = s
		direction = Vector2.DOWN
		phase = 0.0
		moving = false
		last_pos = s.pos
		last_time = s.time
		return
	if s.time == last_time: return # Pause/upgrade screens freeze the pose.
	var displacement = s.pos-last_pos
	var distance = displacement.length()
	moving = distance>0.05 and distance<100
	if moving:
		direction = displacement.normalized()
		var stride=preload("res://scripts/torr_animation.gd").walk.stride/4.0 if s.C.HEROES[s.hero].get("voice_key","")=="torr" else 24.0
		phase = fmod(phase+distance/stride,4.0)
	else:
		if s.C.HEROES[s.hero].get("voice_key","")!="torr":phase = 1.0
	last_pos = s.pos
	last_time = s.time

func frame_row():
	if absf(direction.x)>absf(direction.y)*0.85: return 1
	return 2 if direction.y<0 else 0

func frame_index(): return frame_row()*4+(int(phase)%4 if moving else 1)

func tfk_frame(s,host):
	var shift=0.0 if s.tfk_state.get("empowered",0.0)>0 else host*.5
	return frame_row()*4+((int(phase+shift)%4) if moving else 1)

func tfk_attack_frame(s):
	var remaining=s.tfk_state.get("phone_pose_until",0)-s.time
	if remaining<=0:return -1
	return frame_row()*4+clampi(int((.5-remaining)*8+.00001),0,3)

func tfk_offset(s,host):
	var offset=Vector2(-18 if host==0 else 18,0 if host==0 else 5)
	if s.tfk_state.get("separate_until",0)>s.time:
		var age=clampf(s.time-s.tfk_state.get("separate_started",s.time),0,1)
		offset.x*=1+1.5*sin(age*PI)
	var left=s.tfk_state.get("pose_until",0)-s.time
	var active_host=s.tfk_state.get("pose_host","mathie")==("mathie" if host==0 else "johan")
	if left>0 and tfk_attack_frame(s)<0:
		offset.y-=sin(clampf(left/.35,0,1)*PI)*(6 if active_host else 2)
	if s.tfk_state.get("empowered",0.0)>0:offset.y-=sin(s.time*10)*2
	return offset

func draw(target,s,p,tint):
	if s.C.HEROES[s.hero].get("voice_key","")=="torr":
		preload("res://scripts/torr_animation.gd").draw(target,s,p,tint,phase,moving,direction)
		return
	if preload("res://scripts/tfk_content.gd").active(s):
		# Stylized homage faces; one actor retains two independent visual phases.
		for host in [0,1]:
			var attack=tfk_attack_frame(s)
			if attack>=0:
				draw_tfk_attack(target,p+tfk_offset(s,host),host,attack,s,tint)
				continue
			var frame=tfk_frame(s,host)
			var region=tfk_regions[host][frame]
			var dimensions=region.size*tfk_scales[host]
			var offset=tfk_offset(s,host)
			var flip=-1.0 if frame_row()==1 and direction.x<0 else 1.0
			var host_tint=tint.lerp(Color("ffd76c"),.25) if s.tfk_state.get("empowered",0.0)>0 else tint
			target.draw_texture_rect_region(TFK_SHEETS[host],Rect2(p+offset-Vector2(dimensions.x*.5,dimensions.y-14),Vector2(dimensions.x*flip,dimensions.y)),region,host_tint)
		return
	if s.companions!=null:
		s.companions.draw_owner(target,p,s,tint)
		return
	if not s.starter_attack.is_empty() and s.weapons.has(s.starter_attack.id):
		preload("res://scripts/hero_attack_animation.gd").draw_pose(target,p,s.hero,preload("res://scripts/starter_attack.gd").progress(s),s.halloween,s.starter_attack.aim.x<0,tint,phase,moving)
		return
	if s.hero==1 and not s.kael_attack.is_empty():
		preload("res://scripts/kael_attack_animation.gd").draw_pose(target,p,preload("res://scripts/kael_slam.gd").progress(s),s.halloween,s.kael_attack.aim.x<0,tint,phase,moving)
		return
	var region = regions[s.hero][frame_index()]
	var dimensions = region.size*scales[s.hero]
	var flip = -1.0 if frame_row()==1 and direction.x<0 else 1.0
	var bounce = -sin(phase*PI)*0.8 if moving else sin(s.time*2.6)*0.5
	var lean = direction.x*0.025 if moving else 0.0
	target.draw_set_transform(p+Vector2(0,8+bounce),lean,Vector2(flip,1))
	target.draw_texture_rect_region(SHEETS[s.hero],Rect2(Vector2(-dimensions.x*0.5,-dimensions.y),dimensions),region,tint)
	if s.halloween:
		preload("res://scripts/seasonal_theme.gd").draw_survivor(target,s.hero,frame_row(),dimensions,tint)
	target.draw_set_transform(Vector2.ZERO)

func draw_tfk_attack(target,at,host,frame,s,tint):
	var data=tfk_attacks[host][frame];var b=data.region
	var region=Rect2(b[0],b[1],b[2],b[3])
	var scale=tfk_attack_scales[host]
	var anchor=Vector2(data.anchor[0],data.anchor[1])*scale
	var flip=-1.0 if frame_row()==1 and direction.x<0 else 1.0
	var color=tint.lerp(Color("ffd76c"),.25) if s.tfk_state.get("empowered",0.0)>0 else tint
	target.draw_set_transform(at+Vector2(0,14),0,Vector2(flip,1))
	target.draw_texture_rect_region(TFK_ATTACK_SHEETS[host],Rect2(-anchor,region.size*scale),region,color)
	target.draw_set_transform(Vector2.ZERO)
