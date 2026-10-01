extends RefCounted
const ATLAS=preload("res://assets/ui-plates-08.png")
static func texture(index):
	var a=AtlasTexture.new();a.atlas=ATLAS
	a.region=[Rect2(20,108,736,170),Rect2(784,108,746,170),Rect2(14,282,744,594),Rect2(777,360,752,516)][index]
	return a
static func plate(parent,index,rect):
	var p=TextureRect.new();p.texture=texture(index);p.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;p.stretch_mode=TextureRect.STRETCH_SCALE;p.position=rect.position;p.size=rect.size;p.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(p);return p
const BODY_FONT=preload("res://assets/fonts/SourceSans3.ttf")
const TITLE_FONT=preload("res://assets/fonts/Cinzel.ttf")
static var body_variant: FontVariation
static var title_variant: FontVariation
static func body_font():
	if body_variant==null:
		body_variant=FontVariation.new();body_variant.base_font=BODY_FONT;body_variant.variation_opentype={2003265652:550.0}
	return body_variant
static func heading_font():
	if title_variant==null:
		title_variant=FontVariation.new();title_variant.base_font=TITLE_FONT;title_variant.variation_opentype={2003265652:600.0};title_variant.fallbacks=[body_font()]
	return title_variant
static func button_style(state="normal",primary=false):
	var t=AtlasTexture.new();t.atlas=ATLAS;t.region=Rect2(87,150,592,105)
	var s=StyleBoxTexture.new();s.texture=t
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:
		s.set_texture_margin(side,26 if side in [SIDE_LEFT,SIDE_RIGHT] else 14)
		s.set_content_margin(side,34 if side in [SIDE_LEFT,SIDE_RIGHT] else 12)
	s.modulate_color=Color("fff0c9") if primary else Color("c5c8c4")
	if state=="hover":s.modulate_color=Color(1.3,1.18,0.95)
	elif state=="pressed":s.modulate_color=Color("af9465")
	elif state=="disabled":s.modulate_color=Color("787b7d")
	return s
static func style(index=3):
	var s=StyleBoxTexture.new();s.texture=texture(index)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		s.set_texture_margin(side,110)
		s.set_content_margin(side,62 if side in [SIDE_LEFT,SIDE_RIGHT] else 88 if side==SIDE_TOP else 122)
	return s

static func wrap_copy(text,font,font_size,width):
	var lines=[];var line=""
	for word in text.split(" "):
		var candidate=word if line=="" else line+" "+word
		if line!="" and font.get_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>width:
			lines.append(line);line=word
		else:line=candidate
	lines.append(line)
	return "\n".join(lines)

static func inset_button_style(state="normal"):
	var t=AtlasTexture.new();t.atlas=ATLAS;t.region=Rect2(180,170,420,62)
	var s=StyleBoxTexture.new();s.texture=t
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:
		s.set_content_margin(side,18 if side in [SIDE_LEFT,SIDE_RIGHT] else 12)
	s.modulate_color=Color(1.5,1.3,1.0) if state=="hover" else Color("8e795d") if state=="pressed" else Color.WHITE
	return s


static func fit_label(control,preferred,minimum=12):
	var font=control.get_theme_font("font")
	var chosen=preferred
	while chosen>minimum:
		var measured=font.get_multiline_string_size(control.text,HORIZONTAL_ALIGNMENT_LEFT,-1,chosen)
		if measured.x<=control.size.x-2 and measured.y<=control.size.y:break
		chosen-=1
	control.add_theme_font_size_override("font_size",chosen)
