extends RefCounted
# Small articulated bone rigs. Movement and attacks share stable joint geometry.
const BONE=Color("d8cdb0")
const SHADE=Color("655e50")
static var sheets={}
static var poses={}
static var layouts=[]
const IDS=["thorn","basalt","hunt","aurora","warden","bloom"]
static func atlas_pose(id,frame):
	var key=id+str(frame)
	if poses.has(key):return poses[key]
	if not sheets.has(id):
		var path="res://payload/remains/%02d.dat"%(IDS.find(id)+1)
		if not FileAccess.file_exists(path):return null
		var im=Image.new()
		if im.load_png_from_buffer(FileAccess.get_file_as_bytes(path))!=OK:return null
		sheets[id]=ImageTexture.create_from_image(im)
	var sheet=sheets[id]
	if layouts.is_empty():layouts=JSON.parse_string(FileAccess.get_file_as_string("res://payload/remains/layout.dat"))
	var bounds=layouts[IDS.find(id)][frame]
	var pose=AtlasTexture.new();pose.atlas=sheet
	pose.region=Rect2(bounds[0],bounds[1],bounds[2],bounds[3])
	poses[key]=pose
	return pose
static func bone(c,a,b,width=5.0,tint=Color.WHITE):
	c.draw_line(a+Vector2(1,2),b+Vector2(1,2),SHADE*tint,width+3,true)
	c.draw_line(a,b,BONE*tint,width,true)
	c.draw_circle(a,width*.5,BONE*tint);c.draw_circle(b,width*.5,BONE*tint)
static func draw(c,p,id,walk,attack,flip,tint=Color.WHITE):
	var frame=int(walk)%4
	if attack>0:frame=4 if attack<.2 else 5 if attack<.45 else 6 if attack<.7 else 7
	var art=atlas_pose(id,frame)
	if art!=null:
		var index=IDS.find(id)
		var factor=(135.0 if id=="basalt" else 105.0)/layouts[index][0][3]
		var cell_width=sheets[id].get_width()/4.0
		var bounds=layouts[index][frame]
		var left=(bounds[0]-(frame%4+.5)*cell_width)*factor
		var size=Vector2(bounds[2],bounds[3])*factor
		c.draw_set_transform(p,0,Vector2(-1 if flip else 1,1))
		c.draw_texture_rect(art,Rect2(Vector2(left,-size.y),size),false,tint)
		c.draw_set_transform(Vector2.ZERO)
		return
	var heavy=id in ["basalt","warden"]
	var size=1.3 if heavy else 1.0
	var swing=sin(clampf(attack,0,1)*PI)
	var step=sin(walk*TAU/4)*10
	c.draw_set_transform(p,0,Vector2(1,.35));c.draw_circle(Vector2.ZERO,52*size,Color(0,0,0,.4));c.draw_set_transform(Vector2.ZERO)
	c.draw_set_transform(p+Vector2(swing*9,-absf(step)*.15-swing*8),0,Vector2(-size if flip else size,size))
	var pelvis=Vector2(-24,-37);var chest=Vector2(10,-60)
	if id=="bloom":
		# Rootlike articulated vertebral legs carry a broad rib cage.
		for side in [-1,1]:
			for j in range(3):
				var base=Vector2(side*14,-50+j*10)
				var elbow=Vector2(side*(35+j*9),-28+j*4+step*side*.3)
				var tip=Vector2(side*(58+j*10),3+step*side*.4-swing*24)
				bone(c,base,elbow,4,tint);bone(c,elbow,tip,3,tint)
	else:
		for side in [-1,1]:
			var hip=pelvis+Vector2(side*6,0)
			var knee=Vector2(-25+step*side,-20)
			var foot=Vector2(-30-step*side,0)
			bone(c,hip,knee,7 if heavy else 5,tint);bone(c,knee,foot,5,tint)
			bone(c,foot,foot+Vector2(16,0),4,tint)
	bone(c,pelvis,chest,8 if heavy else 6,tint)
	# Paired ribs attach to the actual animated spine.
	for j in range(6):
		var at=pelvis.lerp(chest,float(j)/6)
		c.draw_arc(at,12+j*.9,-.4,PI+.5,12,BONE*tint,3,true)
	var neck=chest+Vector2(10,-15)
	var skull=neck+Vector2(14+swing*10,-7)
	bone(c,chest,neck,6,tint);bone(c,neck,skull,5,tint)
	c.draw_style_box(skull_style(tint),Rect2(skull-Vector2(5,12),Vector2(32,22)))
	c.draw_circle(skull+Vector2(10,-4),5,Color("171e1a")*tint)
	c.draw_circle(skull+Vector2(10,-4),2.5,Color("84dfb1")*tint)
	bone(c,skull+Vector2(3,8),skull+Vector2(28,8+swing*8),3,tint)
	for j in range(5):bone(c,skull+Vector2(8+j*4,5),skull+Vector2(8+j*4,11),1.5,tint)
	# The same forelimbs seen at rest wind up and strike.
	for side in [-1,1]:
		var elbow=chest+Vector2(12+side*7,19-swing*30)
		var claw=elbow+Vector2(13+swing*35,14-swing*18)
		bone(c,chest,elbow,5,tint);bone(c,elbow,claw,4,tint)
		for j in range(3):bone(c,claw,claw+Vector2(9+j*3,3+j*3),2,tint)
	var tail=pelvis
	for j in range(6):
		var end=tail+Vector2(-12,-2+sin(walk+j*.5)*2)
		bone(c,tail,end,maxf(2,5-j*.5),tint);tail=end
	match id:
		"thorn":
			for j in range(6):bone(c,pelvis.lerp(neck,j/6.0),pelvis.lerp(neck,j/6.0)+Vector2(-10,-20-j*2),3,tint)
		"basalt":
			for j in range(4):bone(c,Vector2(-22+j*10,-50),Vector2(-27+j*10,-76),8,tint)
		"hunt":
			bone(c,skull+Vector2(22,0),skull+Vector2(30,20),3,tint)
		"aurora":
			for side in [-1,1]:
				bone(c,chest,chest+Vector2(side*38,-35-swing*20),4,tint)
				bone(c,chest+Vector2(side*38,-35-swing*20),chest+Vector2(side*55,-12),3,tint)
		"warden":
			var grip=chest+Vector2(34+swing*35,12)
			bone(c,grip-Vector2(0,45),grip+Vector2(0,35),4,tint)
			bone(c,grip-Vector2(0,45),grip+Vector2(12,-58),3,tint)
		"bloom":
			for j in range(5):bone(c,skull+Vector2(3+j*5,-8),skull+Vector2(-15+j*12,-35),3,tint)
	c.draw_set_transform(Vector2.ZERO)
static func skull_style(tint):
	var style=StyleBoxFlat.new();style.bg_color=BONE*tint;style.border_color=SHADE*tint
	style.set_border_width_all(2);style.set_corner_radius_all(5);return style
