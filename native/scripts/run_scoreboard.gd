extends RefCounted
const Art=preload("res://scripts/ui_art.gd")
const Icons=preload("res://scripts/atlas_icons.gd")
static var metric_font:FontVariation
static func numeral_font():
	if metric_font==null:
		metric_font=FontVariation.new();metric_font.base_font=Art.TITLE_FONT
		metric_font.variation_opentype={2003265652:500.0};metric_font.fallbacks=[Art.body_font()]
	return metric_font
static func ability_icon(parent,id,rect:Rect2):
	var icon=TextureRect.new();icon.texture=Icons.get_icon(id) if Icons.has_icon(id) else Icons.get_icon("supplies","supplies")
	icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position=rect.position;icon.size=rect.size
	icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;icon.set_meta("ability_id",id);parent.add_child(icon);icon.size=rect.size
static func text(parent,value,rect:Rect2,size_value=18,color="dfd2b4"):
	var label=Label.new();label.text=str(value);label.position=rect.position;label.size=rect.size
	label.add_theme_font_override("font",Art.body_font())
	label.add_theme_color_override("font_color",Color(color))
	label.clip_text=true;label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	# Label's initial text minimum can enlarge a rect before clipping is enabled.
	# Establish the intended bounds after configuring it, then fit to those bounds.
	label.tooltip_text=str(value);parent.add_child(label);label.size=rect.size
	Art.fit_label(label,size_value,12)
	return label
static func amount(value)->String:
	if absf(float(value))>=1000000000:return "%.2f B"%(float(value)/1000000000)
	if absf(float(value))>=1000000:return "%.2f M"%(float(value)/1000000)
	if absf(float(value))>=10000:return "%.1f K"%(float(value)/1000)
	return str(int(value))
static func metric_amount(value)->String:
	var number=int(value)
	return str(number).insert(1," ") if number>=1000 and number<10000 else amount(value)
static func bar(parent,rect:Rect2,fraction,color):
	var base=ColorRect.new();base.color=Color("343536");base.position=rect.position;base.size=rect.size;base.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(base)
	var fill=ColorRect.new();fill.color=Color(color);fill.size=Vector2(rect.size.x*clampf(fraction,0,1),rect.size.y);fill.mouse_filter=Control.MOUSE_FILTER_IGNORE;base.add_child(fill)
	return base
static func heading(parent,value,rect,size_value=26):
	var label=text(parent,value,rect,size_value,"dfc48b");label.add_theme_font_override("font",Art.heading_font());Art.fit_label(label,size_value,14)
	return label
static func leader(parent,record,title,x,game,width=715):
	heading(parent,title,Rect2(x+260,704,width-295,36),25)
	if record.is_empty():text(parent,"No credited attacks yet",Rect2(x+245,757,width-280,28),22);return
	ability_icon(parent,record.get("source",""),Rect2(x+22,709,180,100))
	var name_value=record.get("name",game.C.WEAPONS.get(record.get("source",""),{"name":"Ability"}).name)
	text(parent,name_value,Rect2(x+245,751,width-280,29),22,"e7e2d5")
	var detail="%s kills · %s damage"%[record.kills,amount(record.damage)] if record.has("kills") else "%s damage · %s casts"%[amount(record.damage),amount(record.get("casts",0))]
	text(parent,detail,Rect2(x+245,781,width-280,27),22,"8ed4c1")
static func panel(parent,source:Rect2,rect:Rect2,left=100,top=65,right=24,bottom=20):
	var texture=AtlasTexture.new();texture.atlas=preload("res://assets/scoreboard-concept-template.png");texture.region=source
	var image=NinePatchRect.new();image.texture=texture;image.position=rect.position;image.size=rect.size;image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	for pair in [[SIDE_LEFT,left],[SIDE_TOP,top],[SIDE_RIGHT,right],[SIDE_BOTTOM,bottom]]:image.set_patch_margin(pair[0],pair[1])
	parent.add_child(image)
static func title_clearance(parent,x,width):
	var patch=TextureRect.new();var texture=AtlasTexture.new();texture.atlas=preload("res://assets/scoreboard-concept-template.png");texture.region=Rect2(162,376,270,35)
	patch.texture=texture;patch.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;patch.position=Vector2(x+87,375);patch.size=Vector2(width-116,39);patch.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(patch)
static func action(parent,caption,rect,callback):
	var button=Button.new();button.text=caption;button.position=rect.position;button.size=rect.size
	button.add_theme_font_override("font",Art.heading_font())
	var font_size=24
	while font_size>14 and Art.heading_font().get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>rect.size.x-140:font_size-=1
	button.add_theme_font_size_override("font_size",font_size)
	button.add_theme_color_override("font_color",Color("e7d6af"))
	for state in ["normal","hover","pressed","focus"]:
		var style=StyleBoxFlat.new();style.bg_color=Color(1,.82,.4,.10) if state=="hover" else Color(0,0,0,.22) if state=="pressed" else Color.TRANSPARENT
		style.content_margin_left=120;style.content_margin_right=14
		if state=="focus":style.border_color=Color("f8da95");style.set_border_width_all(2)
		button.add_theme_stylebox_override(state,style)
	button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND;button.pressed.connect(callback);parent.add_child(button);button.size=rect.size
static func build(game,content):
	var sim=game.sim;var width=content.size.x;var half=(width-160)/2;var right=68+half+24
	var background=TextureRect.new();background.texture=preload("res://assets/scoreboard-world-backdrop.png");background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;background.size=content.size;background.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(background)
	var crest=TextureRect.new();var crest_texture=AtlasTexture.new();crest_texture.atlas=preload("res://assets/scoreboard-world-backdrop.png");crest_texture.region=Rect2(0,0,1586,235)
	var crest_scale=minf(1,width/1586)
	crest.texture=crest_texture;crest.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;crest.position=Vector2(width-1586*crest_scale,0);crest.size=Vector2(1586,235)*crest_scale;crest.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(crest)
	var crest_material=ShaderMaterial.new();crest_material.shader=preload("res://shaders/scoreboard_crest.gdshader");crest.material=crest_material
	heading(content,"EXTINCTION DENIED" if sim.won else "EXPEDITION COMPLETE",Rect2(77,57,clampf(width-800,430,710),95),58)
	text(content,"%s · %02d:%02d · %s"%[game.C.HEROES[sim.hero].name,int(sim.time)/60,int(sim.time)%60,game.Maps.DATA[sim.map_id].name],Rect2(130,158,640,32),25)
	if not sim.won:text(content,sim.death_reason,Rect2(130,192,640,29),23,"d7bfa0")
	var metrics=[["SCORE",sim.score],["KILLS",sim.kills],["AMBER",0 if sim.mode=="safari" else int(sim.amber*sim.fortune)],["BEST STREAK",sim.best_streak],["PEAK HORDE",sim.peak_enemies],["HITS TAKEN",sim.hits]]
	var sources=[Rect2(68,257,249,90),Rect2(331,257,225,90),Rect2(570,257,216,90),Rect2(798,257,228,90),Rect2(1042,257,235,90),Rect2(1292,257,224,90)]
	var tile=(width-196)/6
	for i in metrics.size():
		var x=68+i*(tile+12);panel(content,sources[i],Rect2(x,257,tile,90),92,14,12,14)
		var caption_value=metrics[i][0].replace(" ","\n") if tile<220 else metrics[i][0]
		var caption=heading(content,caption_value,Rect2(x+92,261,tile-108,44),14 if tile<220 else 19)
		caption.text_overrun_behavior=TextServer.OVERRUN_NO_TRIMMING
		var narrow=tile<220
		var value=text(content,metric_amount(metrics[i][1]),Rect2(x+92,305 if narrow else 292,tile-108,37 if narrow else 50),28 if narrow else 38,"edc88c" if i in [0,2] else "f2ecdd")
		value.add_theme_font_override("font",numeral_font());Art.fit_label(value,28 if narrow else 38,18)
		value.tooltip_text=str(metrics[i][1]);value.set_meta("score_metric",metrics[i][0])
	panel(content,Rect2(61,363,726,318),Rect2(68,363,half,318));panel(content,Rect2(804,363,725,318),Rect2(right,363,half,318))
	title_clearance(content,68,half);title_clearance(content,right,half)
	heading(content,"DAMAGE CONTRIBUTION",Rect2(155,376,half-120,36),27)
	var ids=sim.damage_by_weapon.keys();ids.sort_custom(func(a,b):return sim.damage_by_weapon[a]>sim.damage_by_weapon[b])
	var name_width=half*.27
	for i in mini(5,ids.size()):
		var id=ids[i];var damage=sim.damage_by_weapon[id];var y=440+i*43
		ability_icon(content,id,Rect2(89,y,38,38));text(content,game.C.WEAPONS.get(id,{"name":"Relics"}).name,Rect2(151,y+3,name_width,31),22,"e7e2d5")
		bar(content,Rect2(166+name_width,y+13,half-name_width-295,15),damage/maxf(1,sim.damage_total),"499f8a" if i==0 else "939a9e")
		var value=text(content,amount(damage),Rect2(68+half-188,y+3,87,31),22,"e7e2d5");value.tooltip_text=str(int(damage))
		text(content,"%.1f%%"%(damage/maxf(1,sim.damage_total)*100),Rect2(68+half-92,y+3,65,31),22,"8ed4c1")
	if ids.is_empty():text(content,"No damage recorded",Rect2(100,450,half-60,40),22)
	var army_present=sim.companions!=null and preload("res://scripts/content_extension.gd").is_profile(sim)
	heading(content,"YOUR ARMY" if army_present else "MOST USED ABILITIES",Rect2(right+88,376,half-120,36),27)
	panel(content,Rect2(68,696,715,123),Rect2(68,696,half,123),235,48,22,18)
	panel(content,Rect2(805,696,714,123),Rect2(right,696,half,123),235,48,22,18)
	if army_present:
		var army=sim.companions.army_report();var roster_width=half*.47
		var vignette=TextureRect.new();vignette.texture=preload("res://assets/scoreboard-army-vignette.png");vignette.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;vignette.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vignette.position=Vector2(right+half*.52,416);vignette.size=Vector2(half*.44,252);vignette.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(vignette)
		text(content,"%s raised · %s lost"%[army.total_summoned,army.losses],Rect2(right+88,430,half-130,30),24,"8ed4c1")
		var army_bar=bar(content,Rect2(right+30,469,roster_width-6,15),float(army.total_summoned-army.losses)/maxf(1,army.total_summoned),"499f8a");army_bar.color=Color("9e493b")
		var scroll=ScrollContainer.new();scroll.position=Vector2(right+30,494);scroll.size=Vector2(roster_width,167);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.follow_focus=true;content.add_child(scroll)
		var rows=VBoxContainer.new();rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;rows.add_theme_constant_override("separation",0);scroll.add_child(rows)
		var raised=army.summoned_by_ability.keys();raised.sort()
		for id in raised:
			var row=Control.new();row.custom_minimum_size=Vector2(roster_width-20,38);rows.add_child(row)
			ability_icon(row,id,Rect2(0,0,34,34));text(row,game.C.WEAPONS.get(id,{"name":id}).name,Rect2(55,2,roster_width-125,32),22,"e7e2d5")
			text(row,str(army.summoned_by_ability[id]),Rect2(roster_width-62,2,42,32),22)
		leader(content,army.strongest_summon,"MOST DAMAGE",68,game,half);leader(content,army.get("deadliest_summon",{}),"MOST KILLS",right,game,half)
	else:
		var used=sim.ledger.casts.keys();used.sort_custom(func(a,b):return sim.ledger.casts[a]>sim.ledger.casts[b] if sim.ledger.casts[a]!=sim.ledger.casts[b] else a<b)
		for i in mini(5,used.size()):
			var id=used[i];var y=440+i*43
			ability_icon(content,id,Rect2(right+30,y,38,38));text(content,game.C.WEAPONS.get(id,{"name":id}).name,Rect2(right+90,y+3,half-305,31),22,"e7e2d5")
			text(content,"%s casts"%amount(sim.ledger.casts[id]),Rect2(right+half-245,y+3,170,31),22,"8ed4c1")
		if used.is_empty():text(content,"No abilities cast yet",Rect2(right+88,450,half-130,40),22)
		var damage_record={} if ids.is_empty() else {"source":ids[0],"damage":sim.damage_by_weapon[ids[0]],"casts":sim.ledger.casts.get(ids[0],0)}
		var kills=sim.ledger.kills.keys();kills.sort_custom(func(a,b):return sim.ledger.kills[a]>sim.ledger.kills[b] if sim.ledger.kills[a]!=sim.ledger.kills[b] else a<b)
		var kill_record={} if kills.is_empty() else {"source":kills[0],"damage":sim.damage_by_weapon.get(kills[0],0),"kills":sim.ledger.kills[kills[0]]}
		leader(content,damage_record,"MOST DAMAGE",68,game,half);leader(content,kill_record,"MOST KILLS",right,game,half)
	var button_width=(width-160)/4
	var buttons=[Rect2(40,850,403,90),Rect2(450,850,344,90),Rect2(806,850,335,90),Rect2(1165,850,363,90)]
	var captions=["RUN IT BACK","Today's build" if sim.mode=="daily" else "Change survivor","Leaderboard" if sim.mode=="daily" else "Run report","Main menu"]
	var callbacks=[game.start_run,game.daily_menu if sim.mode=="daily" else game.characters,game.daily_records_menu if sim.mode=="daily" else func():game.export_report(true),game.main_menu]
	for i in 4:
		var x=68+i*(button_width+8);panel(content,buttons[i],Rect2(x,850,button_width,90),110,26,44,26)
		action(content,captions[i],Rect2(x+15,865,button_width-30,65),callbacks[i])
