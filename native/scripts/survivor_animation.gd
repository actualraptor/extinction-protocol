extends RefCounted

const SHEETS = [preload("res://assets/mara-walk.png"),preload("res://assets/kael-walk.png"),preload("res://assets/vesper-walk.png"),preload("res://assets/iona-walk.png"),preload("res://assets/orin-walk.png")]
var regions = []
var scales = []
var direction = Vector2.DOWN
var phase = 0.0
var moving = false
var last_pos = Vector2.ZERO
var last_time = -1.0
var run = null

func _init():
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
		phase = fmod(phase+distance/24.0,4.0)
	else:
		phase = 1.0
	last_pos = s.pos
	last_time = s.time

func frame_row():
	if absf(direction.x)>absf(direction.y)*0.85: return 1
	return 2 if direction.y<0 else 0

func frame_index(): return frame_row()*4+(int(phase)%4 if moving else 1)

func draw(target,s,p,tint):
	var region = regions[s.hero][frame_index()]
	var dimensions = region.size*scales[s.hero]
	var flip = -1.0 if frame_row()==1 and direction.x<0 else 1.0
	var bounce = -sin(phase*PI)*0.8 if moving else sin(s.time*2.6)*0.5
	var lean = direction.x*0.025 if moving else 0.0
	target.draw_set_transform(p+Vector2(0,8+bounce),lean,Vector2(flip,1))
	target.draw_texture_rect_region(SHEETS[s.hero],Rect2(Vector2(-dimensions.x*0.5,-dimensions.y),dimensions),region,tint)
	target.draw_set_transform(Vector2.ZERO)
