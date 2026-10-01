extends Control
const Icons = preload("res://scripts/atlas_icons.gd")
var game
func text_at(value,p,width,font_size=18,color="d2dfe3"):
	var label = game.label(self,value,font_size,color)
	label.position=p
	label.clip_text=true
	label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	label.size=Vector2(width,26)
	label.tooltip_text=value
	return label
func panel(rect):
	var p = Panel.new()
	p.position=rect.position
	p.size=rect.size
	p.add_theme_stylebox_override("panel",game.box(Color("101e29"),Color("344651"),8))
	add_child(p)
func table(title,x,rows):
	panel(Rect2(x,116,400,237))
	text_at(title,Vector2(x+18,128),360,19,"e1bf86")
	for i in range(rows.size()):
		text_at(rows[i][0],Vector2(x+18,166+i*28),230,17,"9eb5c2")
		var val = text_at(rows[i][1],Vector2(x+239,166+i*28),140,17,"eef0df")
		val.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
func icon(id,kind,p,caption,dimension=38):
	var t = TextureRect.new()
	t.texture=Icons.get_icon(id,kind)
	t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.position=p
	t.size=Vector2.ONE*dimension
	t.tooltip_text=caption
	t.mouse_filter=Control.MOUSE_FILTER_STOP
	add_child(t)
func _ready():
	var g = game.sim
	var mods=g.Relics.modifiers(g)
	text_at("BACKPACK",Vector2(100,43),650,32,"f0d9ad")
	text_at(g.trait_text(),Vector2(100,85),1200,17,"9eb5c2")
	table("ATTACK",100,[
		["Crit chance (tiers)","%.1f%%"%(g.crit_chance()*100)],
		["Global damage","×%.2f"%(g.base_damage*(1+g.rank_of("damage")*0.14)*(1+mods.get("damage",0)))],
		["Bonus attack speed","+%.0f%%"%((g.rank_of("haste")*0.1+mods.get("haste",0))*100)],
		["Extra projectiles",str(g.rank_of("count")+int(mods.get("count",0))+g.research_ranks.get("projectiles",0)+(mini(3,g.level/10) if g.hero==0 else 0))],
		["Area bonus","+%.0f%%"%((g.area_scale()-1)*100)],
		["Recent total DPS","%.0f"%total_dps(g)]])
	table("DEFENSE",520,[
		["Health","%s / %s"%[ceili(maxf(0,g.hp)),int(g.max_hp)]],
		["Armor","%.0f"%g.armor],
		["Barrier","%.0f"%g.shield],
		["Regeneration","%.2f HP/s"%(g.rank_of("regen")*0.35+g.research_ranks.get("recovery",0)*0.15)],
		["Incoming damage","×%.2f"%(1+mods.get("incoming",0))],
		["Revives remaining",str(g.revives)]])
	table("UTILITY",940,[
		["Movement speed","%.0f"%g.speed()],
		["XP pickup radius",str(95+g.rank_of("pickup")*35+g.research_ranks.get("magnet",0)*12)],
		["XP multiplier","×%.2f"%((1+g.research_ranks.get("growth",0)*0.03)*(1+g.rank_of("pickup")*0.08)*(1+mods.get("xp",0))*(2 if g.buffs.get("surge",0)>0 else 1))],
		["Luck bonus","+%.0f%%"%((g.rank_of("luck")*0.1+g.permanent_luck)*100)],
		["Rerolls",str(g.rerolls)],
		["Amber",str(g.amber)]])
	panel(Rect2(100,370,820,297))
	text_at("WEAPONS / %s OF 5"%g.weapons.size(),Vector2(118,384),350,19,"e1bf86")
	text_at("POWER      COOLDOWN      RECENT DPS",Vector2(570,386),335,15,"9eb5c2")
	var row=0
	for id in g.weapons:
		var d=g.C.WEAPONS[id]
		var w=g.weapons[id]
		var stats=preload("res://scripts/combat_rules.gd").stats(g,id)
		var title=d.evolution if w.evolved else d.name
		var caption="%s / Rank %s\n%s\nDamage: %s | Average DPS: %.0f\nCount: %s | Radius: %.0f"%[title,w.level,d.desc,int(g.damage_by_weapon.get(id,0)),g.ledger.average(id,g.time),stats.count,stats.radius]
		icon(id,"weapon",Vector2(118,420+row*47),caption)
		text_at(title,Vector2(164,424+row*47),390,17).tooltip_text=caption
		text_at("%.0f"%stats.power,Vector2(574,424+row*47),80,17)
		text_at("%.2fs"%stats.cooldown,Vector2(674,424+row*47),90,17)
		text_at("%.0f"%g.ledger.recent(id,g.time),Vector2(806,424+row*47),95,17)
		row+=1
	panel(Rect2(940,370,400,297))
	text_at("RELICS / %s OF 8"%g.relics.size(),Vector2(958,384),360,19,"e1bf86")
	for i in range(g.relics.size()):
		var id=g.relics[i]
		var d=g.C.RELICS[id]
		var p=Vector2(965+(i%4)*92,427+floori(i/4.0)*110)
		icon(id,"relic",p,d.name+" / "+d.rarity+"\n"+d.desc,60)
		var name_label = text_at(d.name,p+Vector2(-6,63),86,12,g.Relics.tier_color(d.rarity))
		name_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		name_label.size=Vector2(86,39)
	panel(Rect2(100,685,1240,126))
	text_at("PASSIVES & AUGMENTS / %s OF 8 TYPES / HOVER FOR DETAILS"%g.buff_slots_used(),Vector2(118,697),900,17,"e1bf86")
	var index=0
	for collection in [g.passives,g.augments]:
		for id in collection:
			var d=g.C.PASSIVES[id] if g.C.PASSIVES.has(id) else g.C.AUGMENTS[id]
			var p=Vector2(118+(index%25)*48,731+floori(index/25.0)*43)
			icon(id,"passive",p,"%s / Rank %s\n%s"%[d.name,collection[id],d.desc],35)
			text_at(str(collection[id]),p+Vector2(26,22),20,12,"ffe9b6")
			index+=1
	var back=game.button(self,"B / ESC — Return to expedition",game.resume,true)
	back.position=Vector2(100,828)
	back.size=Vector2(1240,48)
func total_dps(g):
	var value=0.0
	for id in g.damage_by_weapon: value+=g.ledger.recent(id,g.time)
	return value


