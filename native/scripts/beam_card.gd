extends RefCounted
const Card=preload("res://scripts/stone_card.gd")
const Text=preload("res://scripts/reward_card.gd")
static func build(g,o,index,accept):
	var card=Card.new();card.rarity="LEGENDARY";card.custom_minimum_size=Vector2(380,570)
	var v=Control.new();v.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(v)
	Text.text(card,v,"CHOOSE YOUR PATH",Rect2(.15,.086,.7,.035),18,"ffc780",true,true)
	Text.text(card,v,"RANK %s / %s"%[o.milestone,g.C.WEAPONS[o.id].name],Rect2(.15,.125,.7,.035),15,"dfc68e",true)
	card.component(v,"medallion",Rect2(.34,.165,.32,.19))
	var icon=preload("res://scripts/beam_icon.gd").new();icon.flame=o.id=="flametorch";icon.branch=o.branch;v.add_child(icon);card.place(icon,Rect2(.38,.19,.24,.14))
	card.component(v,"title",Rect2(.066,.352,.868,.08))
	Text.text(card,v,o.name.to_upper(),Rect2(.13,.363,.74,.055),27,"efe1bc",true,true)
	Text.text(card,v,"PERMANENT FOR THIS RUN",Rect2(.12,.436,.76,.031),15,"dfc68e",true)
	card.component(v,"panel",Rect2(.075,.478,.85,.325))
	var desc=Text.text(card,v,o.desc,Rect2(.14,.50,.72,.09),21,"e7dfcc",true);desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var before=g.Rules.stats(g,o.id)
	var copy=g.weapons[o.id].duplicate(true)
	preload("res://scripts/beam_prototype.gd").choose(o.id,copy,o.milestone,o.branch)
	var original=g.weapons[o.id];g.weapons[o.id]=copy
	var after=g.Rules.stats(g,o.id);g.weapons[o.id]=original
	if original.level==10:before.power*=1.2;after.power*=1.2
	var key={"reach":"range","sustain":"duration","split":"count","power":"power"}[o.branch]
	var name={"reach":"LENGTH","sustain":"DURATION","split":"BEAMS","power":"DAMAGE / SEC"}[o.branch]
	Text.text(card,v,name,Rect2(.15,.63,.7,.04),17,"dfc68e",true)
	Text.text(card,v,"%s  →  %s"%[preload("res://scripts/reward_preview.gd").number(before[key]),preload("res://scripts/reward_preview.gd").number(after[key])],Rect2(.15,.68,.7,.06),27,"fff0c9",true)
	var button=Button.new();button.text="TAKE / %s"%(index+1);button.pressed.connect(accept);v.add_child(button);card.place(button,Rect2(.15,.838,.7,.047),27);card.action(button,"take")
	return card
