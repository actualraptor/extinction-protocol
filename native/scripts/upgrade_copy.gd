extends RefCounted
static func affected(g,o):
	if o.type in ["weapon","evolution"]: return [o.id] if g.weapons.has(o.id) else []
	if o.type=="fusion":return g.Evolutions.UNIONS[o.id].parts
	if o.type not in ["passive","augment","relic"]: return []
	if o.type=="passive" and o.id in ["health","speed","pickup","regen","luck"]: return []
	if o.type=="passive" and o.id=="armor": return g.weapons.keys().filter(func(id):return "RETALIATION" in g.C.WEAPONS[id].tags)
	var d=g.C.AUGMENTS[o.id] if o.type=="augment" else g.C.RELICS[o.id] if o.type=="relic" else g.C.PASSIVES[o.id]
	if o.type=="relic" and d.get("filter",{}).is_empty():return []
	var result=[]
	for id in g.weapons:
		if o.type=="passive" and o.id in ["damage","crit"] and g.C.WEAPONS[id].delivery in ["shield","utility"]: continue
		if g.Rules.matches(g.C.WEAPONS[id].tags,d.get("filter",{})): result.append(id)
	return result
static func description(g,o):
	if o.type=="relic":return g.Relics.description(o)
	if o.type=="supplies": return "+%s amber. Restore %s health. Your build is fully upgraded."%[o.get("amber_gain",25),o.get("heal_gain",15)]
	return g.BuffRewards.description(g,o)

static func tags(g,o):
	var d=g.C.WEAPONS.get(o.id,{}) if o.type in ["weapon","fusion","evolution"] else g.C.AUGMENTS.get(o.id,{}) if o.type=="augment" else g.C.PASSIVES.get(o.id,{})
	# Elements and delivery filters take priority; WEAPON is only taxonomy.
	var names={"ICE":"Frost","FIRE":"Fire","POISON":"Poison","ARCANE":"Arcane","PHYSICAL":"Physical","PROJECTILE":"Projectile","CHAIN":"Chain","MELEE":"Melee","ORBITAL":"Orbiting","AURA":"Aura","GROUND_EFFECT":"Ground","RETALIATION":"Thorns","AREA":"Area","SPELL":"Spell","DEFENSIVE":"Defense","UTILITY":"Utility"}
	var present=d.get("tags",[]).duplicate()
	if o.type=="augment":
		for tag in d.get("filter",{}).get("all",[]):
			if tag not in present:present.append(tag)
	var result=[]
	for tag in names:
		if tag in present:result.append(names[tag])
	return " · ".join(result.slice(0,4))
