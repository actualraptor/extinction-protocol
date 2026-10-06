extends PanelContainer
## Independent artwork components; no text is painted into the textures.
const COLORS={"COMMON":"d4d1c2","UNCOMMON":"9bde93","RARE":"9bccff","EPIC":"d5b0fa","LEGENDARY":"ffc780","ARTIFACT":"fff0b2","EVOLUTION":"ffc780"}
const BODY=preload("res://assets/fonts/Alegreya.ttf")
var rarity="COMMON"
var variant=""
var frame_art:Texture2D
var regions=[]
var hovered_action=""
var pressed_action=""
var glows={}
var pieces={}
static var centered_icons={}
func _ready():
	add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	mouse_filter=Control.MOUSE_FILTER_PASS
	frame_art=texture("frame")
	var frame_shader=ShaderMaterial.new();frame_shader.shader=preload("res://shaders/card_frame.gdshader");material=frame_shader
	resized.connect(layout_regions)
func texture(part):
	var tier="legendary" if rarity=="EVOLUTION" else rarity.to_lower()
	if part=="frame" and variant!="":return load("res://assets/cards-modular/%s-%s-frame.tres"%[variant,tier])
	return load("res://assets/cards-modular/%s-%s.tres"%[tier,part])
func component(parent,part,area):
	var node=NinePatchRect.new() if part=="panel" else TextureRect.new()
	node.texture=texture(part);node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	if node is NinePatchRect:
		node.patch_margin_left=18;node.patch_margin_right=18;node.patch_margin_top=18;node.patch_margin_bottom=18
	else:node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	parent.add_child(node);place(node,area);pieces[part]=node
	return node
func place(control,area,font_size=0):
	regions.append({"node":control,"area":area,"font_size":font_size})
	call_deferred("layout_regions")
func layout_regions():
	if material!=null:material.set_shader_parameter("frame_size",size)
	for entry in regions:
		var c=entry.node;var area=entry.area
		var target_size=area.size*size
		c.position=area.position*size
		if entry.font_size>0 and c is Label:
			var font=c.get_theme_font("font");var fs=entry.font_size
			var width=target_size.x if c.autowrap_mode!=TextServer.AUTOWRAP_OFF else -1
			while fs>12:
				var measured=font.get_multiline_string_size(c.text,HORIZONTAL_ALIGNMENT_LEFT,width,fs)
				c.add_theme_font_size_override("font_size",fs)
				if measured.x<=target_size.x and measured.y<=target_size.y and c.get_minimum_size().y<=target_size.y:break
				fs-=1
			c.add_theme_font_size_override("font_size",fs)
		c.size=target_size
func _draw():
	if frame_art==null:frame_art=texture("frame")
	draw_texture_rect(frame_art,Rect2(Vector2.ZERO,size),false)
func feedback():
	for id in glows:
		glows[id].modulate=Color(1.25,1.20,1.10) if hovered_action==id else Color.WHITE
		if pressed_action==id:glows[id].modulate=Color(.75,.72,.65)
func action(button,id):
	var node=component(button.get_parent(),"button",Rect2(.09,.817,.82,.093) if id=="take" else Rect2(.20,.920,.60,.050))
	button.get_parent().move_child(node,button.get_index());glows[id]=node
	button.mouse_entered.connect(func():hovered_action=id;feedback())
	button.mouse_exited.connect(func():hovered_action="";feedback())
	button.focus_entered.connect(func():hovered_action=id;feedback())
	button.focus_exited.connect(func():hovered_action="";feedback())
	button.button_down.connect(func():pressed_action=id;feedback())
	button.button_up.connect(func():pressed_action="";feedback())
	button.add_theme_color_override("font_hover_color",Color("fff0c9"))
	button.add_theme_color_override("font_pressed_color",Color("c7a76b"))
	button.add_theme_color_override("font_outline_color",Color("13100d"))
	button.add_theme_constant_override("outline_size",2)
	for state in ["normal","hover","pressed","disabled","focus"]:button.add_theme_stylebox_override(state,action_style())
static func action_style(_hover=false):
	var style=StyleBoxEmpty.new()
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:style.set_content_margin(side,0)
	return style
static func centered(texture):
	if texture==null:return null
	var key=texture.get_rid().get_id()
	if centered_icons.has(key):return centered_icons[key]
	var image=texture.get_image()
	var bounds=image.get_used_rect()
	var lo=Vector2i(image.get_width(),image.get_height());var hi=Vector2i.ZERO
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x,y).a<.12:continue
			lo=lo.min(Vector2i(x,y));hi=hi.max(Vector2i(x+1,y+1))
	if hi.x>lo.x and hi.y>lo.y:bounds=Rect2i(lo,hi-lo)
	var atlas=AtlasTexture.new();atlas.atlas=texture;atlas.region=Rect2(bounds);atlas.filter_clip=true
	centered_icons[key]=atlas;return atlas
