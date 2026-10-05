extends Control
var game
var buffs_only = false
const Icons = preload("res://scripts/atlas_icons.gd")
var entries = []
func _process(_dt):
	entries.clear()
	if game.sim==null: return
	var g = game.sim
	if not buffs_only:
		for id in g.weapons:
			var w = g.weapons[id]
			var d = g.C.WEAPONS[id]
			entries.append({"id":id,"kind":"weapon","text":(d.evolution if w.evolved else d.name)+" / Rank %s\n"%w.level+d.get("desc",""),"count":str(w.level)})
	else:
		for id in g.buffs:
			if g.buffs[id]<=0: continue
			var icon = {"frenzy":"haste","freeze":"winterbite","immune":"ward","surge":"pickup"}.get(id,"luck")
			entries.append({"id":icon,"kind":"passive","text":g.Pickups.DEFINITIONS.get(id,{"name":id,"desc":""}).name+"\n"+g.Pickups.DEFINITIONS.get(id,{"desc":""}).desc,"count":"%ss"%ceili(g.buffs[id])})
		for id in g.relics:
			var d = g.Relics.inventory_data(g,id)
			entries.append({"id":id,"kind":"relic","text":d.name+" / "+d.rarity+"\n"+d.desc,"count":str(g.Relics.tiers(g,id).size())})
		for collection in [g.passives,g.augments]:
			for id in collection:
				var d = g.BuffRewards.inventory(g,id)
				entries.append({"id":id,"kind":"passive","text":d.name+" / "+d.rarity+" / Rank %s\n"%collection[id]+d.desc,"count":str(collection[id])})
	queue_redraw()
func item_rect(i):
	return Rect2(Vector2((7-i%8)*45 if buffs_only else 8+i*45,floori(i/8.0)*45 if buffs_only else 20),Vector2(40,40))
func _get_tooltip(at):
	for i in range(entries.size()):
		if item_rect(i).has_point(at): return entries[i].text
	return ""
func _draw():
	var art=preload("res://scripts/ui_art.gd")
	for i in range(entries.size()):
		var e = entries[i]
		var rect = item_rect(i)
		draw_rect(rect,Color(0.03,0.07,0.10,0.78))
		var frame=art.button_style()
		for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:frame.set_texture_margin(side,8)
		draw_style_box(frame,rect)
		draw_texture_rect(Icons.get_icon(e.id,e.kind),rect.grow(-3),false)
		if e.count!="":
			draw_string(preload("res://scripts/ui_art.gd").body_font(),rect.position+Vector2(23,37),e.count,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("fff0d4"))

