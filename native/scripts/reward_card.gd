extends RefCounted
const Card=preload("res://scripts/stone_card.gd")
const Preview=preload("res://scripts/reward_preview.gd")
const Icons=preload("res://scripts/atlas_icons.gd")
const Copy=preload("res://scripts/upgrade_copy.gd")
static func text(card,parent,value,rect,fs=18,color="e7dfcc",center=false,heading=false):
	var label=Label.new();label.text=value;label.clip_text=true
	var font=FontVariation.new();font.base_font=Card.BODY;font.variation_opentype={"wght":650 if heading else 550};font.opentype_features={"lnum":1,"tnum":1}
	label.add_theme_font_override("font",font);label.add_theme_color_override("font_color",Color(color))
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	if center:label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label);card.place(label,rect,fs);return label
static func build(g,o,index,accept,relic=false):
	var card=Card.new();card.custom_minimum_size=Vector2(380,570);card.size_flags_horizontal=Control.SIZE_FILL
	var evolved=o.type in ["evolution","fusion"]
	var rows=Preview.rows(g,o)
	var detail=Preview.copy(g,o)
	var compact=rows.size()>=4 and detail!=""
	var shift=.080 if compact else 0.0
	var data=g.C.RELICS[o.id] if o.type=="relic" else g.C.PASSIVES[o.id] if o.type=="passive" else g.C.AUGMENTS[o.id] if o.type=="augment" else {"name":"Amber Supplies"} if o.type=="supplies" else g.C.WEAPONS[o.id]
	card.rarity="EVOLUTION" if evolved else o.get("rarity",data.get("rarity","COMMON"))
	card.variant=data.get("profile","")
	if card.rarity=="":card.rarity="COMMON"
	var v=Control.new();v.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(v)
	text(card,v,"WEAPON UNION" if o.type=="fusion" else card.rarity,Rect2(.15,.103 if card.variant!="" else .086,.70,.035),18,card.COLORS.get(card.rarity,"e3d2ae"),true,true)
	if not evolved:text(card,v,Preview.badge(g,o),Rect2(.20,.140 if card.variant!="" else .123,.60,.035),14,"dfc68e",true)
	card.component(v,"medallion",Rect2(.34,.155 if compact else .165,.32,.115 if compact else .190))
	var icon=Icons.control(v,"lens" if o.type=="supplies" else o.id,"relic" if o.type=="supplies" else o.type,1)
	icon.texture=Card.centered(icon.texture);card.place(icon,Rect2(.384,.173 if compact else .194,.232,.080 if compact else .132))
	card.component(v,"title",Rect2(.066,.352-shift,.868,.080))
	var title=data.evolution if o.type=="evolution" else data.name
	var name=text(card,v,title.to_upper(),Rect2(.13,.363-shift,.74,.055),27,"efe1bc",true,true)
	name.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var category=Preview.transition(g,o) if evolved else Copy.tags(g,o)
	if category=="":category="Relic" if o.type=="relic" else "Supplies" if o.type=="supplies" else "Survivor bonus"
	if o.has("replace"):category="Replaces "+g.C.RELICS[o.replace].name
	text(card,v,category,Rect2(.12,.436-shift,.76,.031),16,"dfc68e",true)
	var panel_top=.478-shift
	var panel_end=.803
	var detail_font=FontVariation.new();detail_font.base_font=Card.BODY;detail_font.variation_opentype={"wght":550}
	var effect_height=(panel_end-panel_top if rows.is_empty() else (detail_font.get_multiline_string_size(detail,HORIZONTAL_ALIGNMENT_LEFT,380*.74,14).y+16)/570.0) if detail!="" else 0.0
	# New behaviour has its own framed section, independent of the stat table.
	if detail!="":
		var desc_top=panel_end-effect_height
		card.component(v,"panel",Rect2(.075,desc_top,.85,effect_height))
		var desc=text(card,v,detail,Rect2(.13,desc_top+.012,.74,effect_height-.024),14,"ded8c7",true)
		desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		panel_end=desc_top-.012
	if not rows.is_empty():
		card.component(v,"panel",Rect2(.075,panel_top,.85,panel_end-panel_top))
		text(card,v,"STAT",Rect2(.145,panel_top+.020,.34,.034),15,"dfc68e")
		text(card,v,"NOW",Rect2(.50,panel_top+.020,.17,.034),15,"dfc68e",true)
		text(card,v,"EVOLVED" if evolved else "NEXT",Rect2(.72,panel_top+.020,.14,.034),15,"a9eab3",true)
		var step=minf(.055,(panel_end-panel_top-.090)/rows.size())
		var start=panel_top+.060
		for j in range(rows.size()):
			var stat=rows[j];var y=start+j*step
			text(card,v,stat.name,Rect2(.145,y,.350,step),20)
			var old=text(card,v,stat.before,Rect2(.50,y,.17,step),20,"c9bfaa");old.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
			text(card,v,"→",Rect2(.672,y,.046,step),16,"c7a76b",true)
			var next=text(card,v,stat.after,Rect2(.724,y,.136,step),21,"eda997" if stat.get("worse",false) else "a9eab3");next.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		card.tooltip_text="\n".join(rows.map(func(stat):return stat.name+": "+stat.before+" → "+stat.after))
	var take=Button.new();take.text="TAKE";take.custom_minimum_size=Vector2.ZERO;take.pressed.connect(accept);v.add_child(take)
	take.add_theme_font_override("font",preload("res://scripts/ui_art.gd").heading_font());take.add_theme_font_size_override("font_size",27)
	card.place(take,Rect2(.15,.838,.70,.047));card.action(take,"take")
	if not relic and g.mode!="daily" and g.banishes>0 and o.type in ["weapon","augment","passive"]:
		var banish=Button.new();banish.text="BANISH";banish.custom_minimum_size=Vector2.ZERO;v.add_child(banish)
		banish.add_theme_font_override("font",preload("res://scripts/ui_art.gd").heading_font());banish.add_theme_font_size_override("font_size",16)
		banish.pressed.connect(func():g.banish_choice(index))
		card.place(banish,Rect2(.245,.929,.51,.032));card.action(banish,"banish")
	elif o.has("replace"):
		var keep=Button.new();keep.text="KEEP CURRENT";keep.custom_minimum_size=Vector2.ZERO;v.add_child(keep)
		keep.add_theme_font_override("font",preload("res://scripts/ui_art.gd").heading_font());keep.add_theme_font_size_override("font_size",13)
		keep.pressed.connect(func():g.options[index]={"type":"supplies","id":"supplies","salvaged":o.id};accept.call())
		card.place(keep,Rect2(.245,.929,.51,.032));card.action(keep,"banish")
	return card
