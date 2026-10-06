extends RefCounted
const Preview=preload("res://scripts/reward_preview.gd")
const Icons=preload("res://scripts/atlas_icons.gd")
const Art=preload("res://scripts/ui_art.gd")
static func label(parent,value,size=20,color="e8dfcc",center=false):
	var n=Label.new();n.text=value;n.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	n.add_theme_font_override("font",preload("res://assets/fonts/Alegreya.ttf"));n.add_theme_font_size_override("font_size",size)
	n.add_theme_color_override("font_color",Color(color));n.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	if center:n.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(n);return n
static func build(g,o,accept):
	var panel=PanelContainer.new();panel.position=Vector2(210,25);panel.size=Vector2(1020,850)
	var skin=StyleBoxTexture.new();skin.texture=preload("res://assets/cards-modular/evolution-window.png")
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:
		skin.set_texture_margin(side,100);skin.set_content_margin(side,190 if side==SIDE_TOP else 150 if side==SIDE_BOTTOM else 150)
	panel.add_theme_stylebox_override("panel",skin)
	var stack=VBoxContainer.new();stack.add_theme_constant_override("separation",12);panel.add_child(stack)
	label(stack,"LEGENDARY UNION" if o.type=="fusion" else "LEGENDARY EVOLUTION",22,"e5bd69",true)
	var title=g.C.WEAPONS[o.id].name if o.type=="fusion" else g.C.WEAPONS[o.id].evolution
	var exclusive=g.C.WEAPONS[o.id].get("profile","")=="07"
	var name=label(stack,title.to_upper(),36,"fff0c7",true);name.add_theme_font_override("font",Art.heading_font())
	label(stack,Preview.transition(g,o),18,"b7aa91",true)
	var line=HSeparator.new();stack.add_child(line)
	var body=HBoxContainer.new();body.add_theme_constant_override("separation",28);body.size_flags_vertical=Control.SIZE_EXPAND_FILL;stack.add_child(body)
	var portrait=Control.new();portrait.custom_minimum_size=Vector2(220,200);body.add_child(portrait)
	var halo=TextureRect.new();halo.texture=load("res://assets/cards-modular/legendary-medallion.tres");halo.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;halo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	halo.position=Vector2(0,0);halo.size=Vector2(260,270);portrait.add_child(halo)
	halo.size=Vector2(220,200)
	# The icon already has its own frame: avoid stacked top/bottom ornaments.
	halo.visible=false
	var icon=Icons.control(portrait,o.id,"weapon",1);icon.texture=preload("res://scripts/stone_card.gd").centered(icon.texture);icon.position=Vector2(35,30);icon.size=Vector2(150,150)
	var info=VBoxContainer.new();info.size_flags_horizontal=Control.SIZE_EXPAND_FILL;info.add_theme_constant_override("separation",16);body.add_child(info)
	var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;info.add_child(scroll)
	var grid=GridContainer.new();grid.columns=4;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_theme_constant_override("h_separation",14);grid.add_theme_constant_override("v_separation",10);scroll.add_child(grid)
	for heading in ["STAT","CURRENT","","EVOLVED"]:label(grid,heading,15,"d8b56b")
	for row in Preview.rows(g,o):
		label(grid,row.name,18);label(grid,row.before,18,"c0b9ab");label(grid,"→",18,"b99552");label(grid,row.after,19,"adecc2")
	var detail_margin=MarginContainer.new();detail_margin.add_theme_constant_override("margin_left",24);detail_margin.add_theme_constant_override("margin_right",24);stack.add_child(detail_margin)
	var detail=label(detail_margin,Preview.copy(g,o),20,"ded8c7",true);detail.custom_minimum_size.y=70
	var take=Button.new();take.text="CLAIM EVOLUTION";take.custom_minimum_size.y=54;take.add_theme_font_override("font",Art.heading_font());take.add_theme_font_size_override("font_size",23);take.pressed.connect(accept);stack.add_child(take)
	for state in ["normal","hover","pressed","focus"]:take.add_theme_stylebox_override(state,Art.button_style(state,true))
	return panel
