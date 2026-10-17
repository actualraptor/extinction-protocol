extends RefCounted
const Paths=preload("res://scripts/weapon_paths.gd")
const Card=preload("res://scripts/stone_card.gd")
const Text=preload("res://scripts/reward_card.gd")
static func build(g,o,index,accept):
	if o.id=="club" and o.milestone==5:return preload("res://scripts/ancestor_path_card.gd").build(g,o,index,accept)
	if not o.id.begins_with("tfk_") and Paths.STANDARD_CHOICES.has(Paths.UNION_BASES.get(o.id,o.id)):return standard(g,o,index,accept)
	if o.id=="club":return preload("res://scripts/ancestor_path_card.gd").build(g,o,index,accept)
	if Paths.BEAMS.CHOICES.has(Paths.UNION_BASES.get(o.id,o.id)):
		return preload("res://scripts/beam_card.gd").build(g,o,index,accept)
	var card=Card.new();card.rarity="LEGENDARY";card.custom_minimum_size=Vector2(380,570)
	var v=Control.new();v.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(v)
	Text.text(card,v,"VÄLJ MODIFIERING",Rect2(.15,.086,.7,.04),18,"ffc780",true,true)
	var weapon_name=g.C.WEAPONS.get(o.id,{}).get("name",o.id)
	var weapon=Text.text(card,v,"RANG %s / %s"%[o.milestone,weapon_name],Rect2(.13,.135,.74,.12),20,"dfc68e",true)
	weapon.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	# Keep long Swedish names above the ornament, with room for two lines.
	card.component(v,"title",Rect2(.066,.418,.868,.025))
	var title=Text.text(card,v,o.name,Rect2(.13,.28,.74,.135),26,"efe1bc",true,true)
	title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	Text.text(card,v,"GÄLLER DENNA RUNDA",Rect2(.12,.45,.76,.035),15,"dfc68e",true)
	card.component(v,"panel",Rect2(.075,.50,.85,.28))
	var desc=Text.text(card,v,o.desc,Rect2(.14,.52,.72,.24),21,"e7dfcc",true)
	desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var button=Button.new();button.text="VÄLJ / %s"%(index+1);button.pressed.connect(accept);v.add_child(button)
	card.place(button,Rect2(.15,.838,.7,.047),27);card.action(button,"take")
	return card

static func standard(g,o,index,accept):
	var card=Card.new();card.rarity="LEGENDARY";card.custom_minimum_size=Vector2(380,570)
	var content=Control.new();content.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(content)
	Text.text(card,content,"CHOOSE YOUR PATH",Rect2(.15,.086,.7,.035),18,"ffc780",true,true)
	Text.text(card,content,"RANK %s / %s"%[o.milestone,g.C.WEAPONS[o.id].name],Rect2(.12,.125,.76,.035),15,"dfc68e",true)
	card.component(content,"medallion",Rect2(.34,.165,.32,.19))
	var icon=preload("res://scripts/atlas_icons.gd").control(content,o.id,"weapon",1)
	card.place(icon,Rect2(.38,.19,.24,.14))
	card.component(content,"title",Rect2(.066,.352,.868,.08))
	Text.text(card,content,o.name.to_upper(),Rect2(.20,.363,.60,.055),26,"efe1bc",true,true)
	Text.text(card,content,"PERMANENT FOR THIS RUN",Rect2(.12,.436,.76,.031),15,"dfc68e",true)
	card.component(content,"panel",Rect2(.075,.478,.85,.325))
	var desc=Text.text(card,content,o.desc,Rect2(.14,.51,.72,.23),22,"e7dfcc",true)
	desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var button=Button.new();button.text="CHOOSE / %s"%(index+1);button.pressed.connect(accept);content.add_child(button)
	card.place(button,Rect2(.15,.838,.7,.047),27);card.action(button,"take")
	return card
