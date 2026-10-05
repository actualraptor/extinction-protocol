extends RefCounted
## Gameplay owns timing. Six painted whole-body poses, anchored at the feet.
const RELEASE_PROGRESS = 0.62
const PHASES = [0.0,0.12,0.30,0.50,0.62,0.80]
static var metadata = {}
static var textures = {}

static func data():
	if metadata.is_empty(): metadata=JSON.parse_string(FileAccess.get_file_as_string("res://assets/hero-attacks-0111/frames.json"))
	return metadata

static func supports(hero: int):
	return hero==0 or hero==2

static func emission_offset(hero: int,halloween=false,flip=false):
	if not supports(hero):return Vector2.ZERO
	var spec=data().heroes[str(hero)]
	var frame=spec.variants["halloween" if halloween else "normal"][4]
	var offset=(Vector2(frame.emission[0],frame.emission[1])-Vector2(frame.anchor[0],frame.anchor[1]))*spec.pixel_scale
	if flip:offset.x=-offset.x
	return offset+Vector2(0,8)

static func frame_index(progress: float):
	var index=0
	for i in range(PHASES.size()):
		if progress>=PHASES[i]: index=i
	return index

static func pose(hero: int,progress: float,halloween=false):
	if not supports(hero): return {}
	var spec=data().heroes[str(hero)]
	var index=frame_index(clampf(progress,0,1))
	var frame=spec.variants["halloween" if halloween else "normal"][index]
	if not textures.has(frame.file): textures[frame.file]=load(frame.file)
	return {"texture":textures[frame.file],"anchor":Vector2(frame.anchor[0],frame.anchor[1]),"scale":spec.pixel_scale,"name":frame.pose,"index":index}

static func draw_pose(target,p: Vector2,hero: int,progress: float,halloween=false,flip=false,tint=Color.WHITE):
	var frame=pose(hero,progress,halloween)
	if frame.is_empty(): return
	target.draw_set_transform(p+Vector2(0,8),0,Vector2(-1 if flip else 1,1))
	target.draw_texture_rect(frame.texture,Rect2(-frame.anchor*frame.scale,frame.texture.get_size()*frame.scale),false,tint)
	target.draw_set_transform(Vector2.ZERO)
