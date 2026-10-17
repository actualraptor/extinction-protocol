extends Control
signal completed
signal sound_cue(id)
const BEATS=[
	["De tre rösterna", "En portal öppnas. På andra sidan: en övergiven förhistorisk studio."],
	["Mathie & Johan", "Världen går under. Avsnittet fortsätter."],
	["Jimmy / telefonen", "Okej, tänk dig följande scenario..."],
	["Johannes / mixerbordet", "Det där klipper vi bort."],
	["Dörrarna slås upp", "[Ett dinosaurievrål skakar studion.]"],
	["Johan", "Jaha, då kör vi väl."],
	["HEMLIG KARAKTÄR UPPLÅST", "TFK: MATHIE & JOHAN\nDE SISTA PROGRAMLEDARNA"]]
var clock=0.0
var finished=false
var caption:Label
var heading:Label
var last_beat=-1
const SEATED=preload("res://assets/tfk-studio-seated-v1.png")
var regions=JSON.parse_string(FileAccess.get_file_as_string("res://assets/tfk-studio-seated-regions.json"))
var cameo_regions=JSON.parse_string(FileAccess.get_file_as_string("res://assets/tfk-cameo-regions.json"))
func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	heading=Label.new();heading.position=Vector2(100,80);heading.size=Vector2(1240,65);heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;heading.add_theme_font_size_override("font_size",34);add_child(heading)
	caption=Label.new();caption.position=Vector2(160,600);caption.size=Vector2(1120,100);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;caption.add_theme_font_size_override("font_size",25);add_child(caption)
	var notice=Label.new();notice.text="TFK / STILISERAD HYLLNING · ORIGINALTEXT · TEXTAD SCEN";notice.position=Vector2(100,740);add_child(notice)
	var skip=Button.new();skip.text="Fortsätt";skip.position=Vector2(1170,730);skip.size=Vector2(160,50);skip.pressed.connect(finish);add_child(skip)
	update_beat()
func _process(dt):
	clock+=dt;update_beat();queue_redraw()
	if clock>=BEATS.size()*3.0:finish()
func update_beat():
	var index=mini(BEATS.size()-1,int(clock/3))
	if index!=last_beat:
		if index==4:sound_cue.emit("dino_basalt_roar")
		last_beat=index
	var beat=BEATS[index]
	heading.text=beat[0];caption.text=beat[1]
	caption.visible=not index in [2,3,5]
	heading.visible=not index in [2,3,5]
func _draw():
	var beat=mini(BEATS.size()-1,int(clock/3))
	draw_rect(Rect2(0,0,1440,900),Color("11101b"))
	draw_rect(Rect2(190,190,1060,370),Color("292334"))
	for x in range(210,1230,80):
		draw_rect(Rect2(x,210,50,125),Color("181721"))
		for y in range(222,330,18):draw_line(Vector2(x+5,y),Vector2(x+45,y),Color("49404d"),2)
	draw_rect(Rect2(190,470,1060,90),Color("34291f"))
	for x in range(210,1250,100):draw_line(Vector2(x,470),Vector2(x-35,560),Color("534131"),2)
	for host in [0,1]:
		var b=regions[host];var region=Rect2(b[0],b[1],b[2],b[3])
		var dimensions=region.size*(240.0/region.size.y)
		var at=Vector2(550 if host==0 else 850,500)
		draw_texture_rect_region(SEATED,Rect2(at-Vector2(dimensions.x*.5,dimensions.y),dimensions),region)
	draw_rect(Rect2(440,390,540,55),Color("84603e"))
	draw_rect(Rect2(450,445,520,14),Color("392819"))
	for x in [550,850]:
		draw_line(Vector2(x+45,380),Vector2(x+45,330),Color("d4b574"),5)
		draw_circle(Vector2(x+45,324),10,Color("b8a69a"))
	if beat>=2:
		draw_rect(Rect2(667,385,70,30),Color("241c30"))
		draw_arc(Vector2(702,387),26,PI,TAU,20,Color("c9a3ff"),10)
		draw_arc(Vector2(702,370),40+sin(clock*7)*5,PI,TAU,20,Color("c9a3ff"),2)
	if beat>=3:
		var b=cameo_regions[1];var region=Rect2(b[0],b[1],b[2],b[3])
		var dimensions=region.size*(140.0/region.size.y)
		draw_texture_rect_region(preload("res://assets/tfk-cameos-v1.png"),Rect2(Vector2(300,455)-Vector2(dimensions.x*.5,dimensions.y),dimensions),region)
		draw_rect(Rect2(220,400,150,70),Color("57545e"))
		for x in range(235,360,18):
			draw_line(Vector2(x,418),Vector2(x,455),Color("211c2c"),3)
			draw_circle(Vector2(x,430+sin(x)*10),3,Color("83ddff"))
	draw_rect(Rect2(1030,225,200,245),Color("08070d"))
	if beat<4:
		for x in [1030,1130]:
			draw_rect(Rect2(x,225,96,245),Color("574132"))
			draw_rect(Rect2(x+8,236,80,223),Color("39291f"),false,3)
	else:
		draw_texture_rect_region(preload("res://scripts/dinosaur_boss_art.gd").SHEET,Rect2(985,275,265,199),Rect2(1536,768,512,384),Color("d4b392"))
		var opening=clampf((clock-12.0)/.45,0,1)
		var eased=1-pow(1-opening,3)
		# Door leaves swing outward, then settle at the doorway edges.
		for side in [-1,1]:
			var hinge=Vector2(1030 if side<0 else 1230,225)
			var width=96*(1-eased*.86)
			var leaf=Rect2(hinge+Vector2(-width if side>0 else 0,0),Vector2(width,245))
			draw_rect(leaf,Color("574132"))
			draw_rect(leaf,Color("a17a50"),false,2)
		if opening<1:
			for i in range(8):
				var center=Vector2(1130,455)+Vector2.from_angle(i*PI/7+PI)*opening*95
				draw_circle(center,5+opening*8,Color(.64,.5,.34,(1-opening)*.5))
	if beat in [2,3,5]:
		var head=Vector2(702,360) if beat==2 else Vector2(300,300) if beat==3 else Vector2(850,250)
		preload("res://scripts/tfk_speech.gd").draw(self,preload("res://scripts/ui_art.gd").body_font(),BEATS[beat][1],head,22,Color("f4eadb"),330)
func finish():
	if finished:return
	finished=true;completed.emit();queue_free()
