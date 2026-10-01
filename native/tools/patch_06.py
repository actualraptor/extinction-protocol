from pathlib import Path
root = Path(__file__).resolve().parents[1]
p = root / 'scripts/expedition.gd'
s = p.read_text(encoding='utf-8')
start = s.index('func open_choices(relic):')
end = s.index('\nfunc reroll_choices():',start)
s = s[:start]+'''func upgrade_pool(owned_only = false):
	var pool = []
	for id in C.WEAPONS:
		if C.WEAPONS[id].get("fusion",false) or Evolutions.consumed(self,id): continue
		if weapons.has(id):
			if weapons[id].level<Rules.MAX_RANK: pool.append({"type":"weapon","id":id})
		elif not owned_only and content_allowed("weapons",id) and weapons.size()<BACKPACK_SLOTS and Rules.can_add_weapon(weapons,C.WEAPONS,id): pool.append({"type":"weapon","id":id})
	for id in C.PASSIVES:
		if rank_of(id)<C.PASSIVES[id].max and Rules.eligible(weapons,C.WEAPONS,C.PASSIVES[id].filter): pool.append({"type":"passive","id":id})
	for id in C.AUGMENTS:
		if content_allowed("augments",id) and augments.get(id,0)<C.AUGMENTS[id].max and Rules.eligible(weapons,C.WEAPONS,C.AUGMENTS[id].filter): pool.append({"type":"augment","id":id})
	return pool

func open_choices(relic):
	if choosing or not active: return
	options = []
	option_is_relic = relic
	if relic:
		var transformations = Evolutions.ready(self)
		if not transformations.is_empty():
			options = [transformations[rng.randi_range(0,transformations.size()-1)]]
		else:
			var reward = Relics.roll(self)
			var rarity = C.RELICS[reward].rarity if reward!="" else "COMMON"
			if reward!="" and relics.size()<8:
				options = [{"type":"relic","id":reward}]
			elif reward!="":
				var weakest = relics[0]
				for id in relics:
					if Relics.TIERS.find(C.RELICS[id].rarity)<Relics.TIERS.find(C.RELICS[weakest].rarity): weakest = id
				if Relics.TIERS.find(rarity)>Relics.TIERS.find(C.RELICS[weakest].rarity):
					options = [{"type":"relic","id":reward,"replace":weakest}]
			if options.is_empty():
				var improvements = upgrade_pool(true)
				var reward_option = {"type":"supplies","id":"supplies"} if improvements.is_empty() else improvements[rng.randi_range(0,improvements.size()-1)].duplicate()
				reward_option.rarity = rarity
				reward_option.refinement = true
				options = [reward_option]
	else:
		var pool = upgrade_pool()
		var fresh = pool.filter(func(o):return o not in reroll_exclude)
		if fresh.size()>=3: pool = fresh
		reroll_exclude.clear()
		var owned = pool.filter(func(o):return o.type=="weapon" and weapons.has(o.id))
		if not owned.is_empty():
			var offer = owned[rng.randi_range(0,owned.size()-1)]
			options.append(offer)
			pool.erase(offer)
		while options.size()<3 and not pool.is_empty():
			var i = rng.randi_range(0,pool.size()-1)
			options.append(pool[i])
			pool.remove_at(i)
	if options.is_empty():
		hp = minf(max_hp,hp+20)
		amber += 10
		return
	choosing = true
	effect.emit("level",pos,Color("b4d6ff"),350)
	sound.emit("loot" if relic else "level")
	choice_requested.emit(options,relic)
''' + s[end:]
s = s.replace('\t\t"relic":\n\t\t\trelics.append(o.id)', '''		"supplies":
			amber += 25
			hp = minf(max_hp,hp+15)
		"relic":
			if o.has("replace"):
				var old = C.RELICS[o.replace].get("acquire",{})
				max_hp -= old.get("health",0)
				hp = minf(hp,max_hp)
				armor -= old.get("armor",0)
				relics.erase(o.replace)
			relic_state.mods_key = -1
			relics.append(o.id)''')
p.write_text(s,encoding='utf-8')
p = root/'scripts/relic_system.gd'
s = p.read_text(encoding='utf-8').replace('id not in g.relics and Rules.eligible','id not in g.relics and g.content_allowed("relics",id) and Rules.eligible')
p.write_text(s,encoding='utf-8')
