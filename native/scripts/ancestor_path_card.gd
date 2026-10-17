extends RefCounted
const Card=preload("res://scripts/stone_card.gd")
const Text=preload("res://scripts/reward_card.gd")
const Rupture=preload("res://scripts/ancestor_rupture.gd")
static func build(g,o,index,accept):
	var card=Card.new();card.rarity="LEGENDARY";card.custom_minimum_size=Vector2(380,570)
	var v=Control.new();v.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(v)
	Text.text(card,v,"CHOOSE YOUR PATH",Rect2(.15,.086,.7,.035),18,"ffc780",true,true)
	Text.text(card,v,"RANK 5 / ANCESTOR'S WRATH",Rect2(.12,.125,.76,.035),15,"dfc68e",true)
	card.component(v,"medallion",Rect2(.34,.165,.32,.19))
	var icon=TextureRect.new();icon.texture=preload("res://scripts/atlas_icons.gd").get_icon("club");icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;v.add_child(icon);card.place(icon,Rect2(.38,.19,.24,.14))
	card.component(v,"title",Rect2(.066,.352,.868,.08))
	Text.text(card,v,o.name.to_upper(),Rect2(.10,.363,.80,.055),26,"efe1bc",true,true)
	Text.text(card,v,"PERMANENT FOR THIS RUN",Rect2(.12,.436,.76,.031),15,"dfc68e",true)
	card.component(v,"panel",Rect2(.075,.478,.85,.325))
	var desc=Text.text(card,v,o.desc,Rect2(.14,.50,.72,.13),20,"e7dfcc",true);desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var shape=Rupture.profile(g.Rules.stats(g,o.id),o.branch)
	var summary="FORWARD + BACKWARD\nFull damage in both directions" if o.branch=="both" else "WIDER FORWARD RUPTURE\n65% more width · 20% more reach"
	var stats=Text.text(card,v,summary,Rect2(.14,.66,.72,.10),18,"dfc68e",true);stats.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	card.set_meta("rupture_shape",shape)
	var button=Button.new();button.text="TAKE / %s"%(index+1);button.pressed.connect(accept);v.add_child(button);card.place(button,Rect2(.15,.838,.7,.047),27);card.action(button,"take")
	return card
