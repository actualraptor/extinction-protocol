extends RefCounted
static func affected(g,o):
	if o.type=="weapon": return [o.id] if g.weapons.has(o.id) else []
	if o.type not in ["passive","augment"]: return []
	if o.type=="passive" and o.id in ["health","speed","pickup","regen","luck"]: return []
	if o.type=="passive" and o.id=="armor": return g.weapons.keys().filter(func(id):return "RETALIATION" in g.C.WEAPONS[id].tags)
	var d=g.C.AUGMENTS[o.id] if o.type=="augment" else g.C.PASSIVES[o.id]
	var result=[]
	for id in g.weapons:
		if o.type=="passive" and o.id in ["damage","crit"] and g.C.WEAPONS[id].delivery in ["shield","utility"]: continue
		if g.Rules.matches(g.C.WEAPONS[id].tags,d.get("filter",{})): result.append(id)
	return result
static func description(g,o):
	var d=g.C.WEAPONS[o.id] if o.type=="weapon" else g.C.AUGMENTS[o.id] if o.type=="augment" else g.C.PASSIVES[o.id]
	if o.type=="weapon":
		var rank=g.weapons[o.id].level+1 if g.weapons.has(o.id) else 1
		return (d.desc if rank==1 else g.Rules.rank_text(d,rank))+"\nRank %s / 10"%rank
	if o.type=="passive" and o.id=="crit":
		var raw=g.C.HEROES[g.hero].crit+g.rank_of("crit")*0.07+g.research_ranks.get("critical",0)*0.02
		return "+%.1f%% crit chance.\n%.1f%% to %.1f%%"%[(g.crit_curve(raw+0.07)-g.crit_chance())*100,g.crit_chance()*100,g.crit_curve(raw+0.07)*100]
	return d.desc
