extends RefCounted
## Real painted poses. Gameplay owns attack timing; this module never delays hits.
const IMPACT_PROGRESS = 0.62
const PHASES = [0.0,0.12,0.30,0.50,0.62,0.80]
static var metadata = {}
static var textures = {}

static func data():
	if metadata.is_empty(): metadata=JSON.parse_string(FileAccess.get_file_as_string("res://assets/kael-slam-0111/frames.json"))
	return metadata

static func frame_index(progress: float):
	var index=0
	for i in range(PHASES.size()):
		if progress>=PHASES[i]: index=i
	return index

static func pose(progress: float,halloween=false):
	var frame=data().variants["halloween" if halloween else "normal"][frame_index(clampf(progress,0,1))]
	if not textures.has(frame.file): textures[frame.file]=load(frame.file)
	return {"texture":textures[frame.file],"anchor":Vector2(frame.anchor[0],frame.anchor[1]),"scale":data().pixel_scale,"name":frame.pose,"index":frame_index(progress)}

static func draw_pose(target,p: Vector2,progress: float,halloween=false,flip=false,tint=Color.WHITE):
	var frame=pose(progress,halloween)
	var dimensions=frame.texture.get_size()*frame.scale
	# Match the existing survivor renderer's foot-plane offset. The club/head
	# can extend above/below the standing body without changing character scale.
	target.draw_set_transform(p+Vector2(0,8),0,Vector2(-1 if flip else 1,1))
	target.draw_texture_rect(frame.texture,Rect2(-frame.anchor*frame.scale,dimensions),false,tint)
	target.draw_set_transform(Vector2.ZERO)

static func impact_point(p: Vector2,flip=false):
	var offset=data().impact_offset
	return p+Vector2((-1 if flip else 1)*offset[0],8+offset[1])
