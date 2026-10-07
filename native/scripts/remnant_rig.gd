extends RefCounted
# Small articulated bone rigs. Movement and attacks share stable joint geometry.
const BONE=Color("d8cdb0")
const SHADE=Color("655e50")
static var sheets={}
static var poses={}
static var individual_poses={}
static var layouts=[]
const IDS=["thorn","basalt","hunt","aurora","warden","bloom"]
static func atlas_pose(id,frame):
	var raw=raw_pose(id,frame)
	var key=id+str(frame)
	if individual_poses.has(key):return individual_poses[key]
	var bound="res://assets/minions-individual-runtime/%s-%s.png"%[id,frame]
	if ResourceLoader.exists(bound):
		individual_poses[key]=load(bound)
		return individual_poses[key]
	return raw
static func raw_pose(id,frame):
	var key=id+str(frame)
	if poses.has(key):return poses[key]
	if not sheets.has(id):
		var path="res://payload/dinosaurs/%02d.dat"%(IDS.find(id)+1)
		if not FileAccess.file_exists(path):return null
		var im=Image.new()
		if im.load_png_from_buffer(FileAccess.get_file_as_bytes(path))!=OK:return null
		sheets[id]=ImageTexture.create_from_image(im)
	var sheet=sheets[id]
	if layouts.is_empty():layouts=JSON.parse_string(FileAccess.get_file_as_string("res://payload/dinosaurs/layout.dat"))
	var bounds=layouts[IDS.find(id)][frame]
	# Cinematic zoom samples a standalone image, never neighbouring atlas cells.
	var pose=ImageTexture.create_from_image(sheet.get_image().get_region(Rect2i(bounds[0],bounds[1],bounds[2],bounds[3])))
	poses[key]=pose
	return pose
static func bone(c,a,b,width=5.0,tint=Color.WHITE):
	c.draw_line(a+Vector2(1,2),b+Vector2(1,2),SHADE*tint,width+3,true)
	c.draw_line(a,b,BONE*tint,width,true)
	c.draw_circle(a,width*.5,BONE*tint);c.draw_circle(b,width*.5,BONE*tint)
static func draw(c,p,id,walk,attack,flip,tint=Color.WHITE):
	var frame=1+int(walk)%2 if walk>0 else 0
	if attack>0:frame=4 if attack<.35 else 5 if attack<.75 else 0
	var art=atlas_pose(id,frame)
	if art==null:return
	var index=IDS.find(id)
	var factor=height(id)/layouts[index][0][3]
	var cell_width=sheets[id].get_width()/4.0
	var bounds=layouts[index][frame]
	var left=(bounds[0]-(frame%4+.5)*cell_width)*factor
	var size=Vector2(bounds[2],bounds[3])*factor
	c.draw_set_transform(p,0,Vector2(-1 if flip else 1,1))
	c.draw_texture_rect(art,Rect2(Vector2(left,-size.y),size),false,tint)
	c.draw_set_transform(Vector2.ZERO)

static func height(id):return {"thorn":105.0,"basalt":155.0,"hunt":110.0,"aurora":135.0,"warden":150.0,"bloom":125.0}.get(id,105.0)
