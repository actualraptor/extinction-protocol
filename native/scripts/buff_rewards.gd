extends RefCounted
## Acquisition quality is separate from rank and slot ownership.
const FACTORS=[1.0,1.2,1.5,1.8,2.2,3.0]
const COUNTS=[1,1,1,2,2,3]
const BASE={"damage":.14,"haste":.10,"area":.12,"count":1.0,"crit":.07,"armor":2.0,"speed":.08,"pickup":35.0,"regen":.35,"luck":.10}
static func roll(g):
	var ticket=g.rng.randf()*100
	var odds=g.Relics.odds(g,false)
	for i in range(6):
		ticket-=odds[i]
		if ticket<=0:return g.Relics.TIERS[i]
	return "ARTIFACT"
static func decorate(g,offer,tier="",rank_gain=0,source="level"):
	var o=offer.duplicate(true)
	if o.type not in ["weapon","passive","augment"]:return o
	o.rarity=roll(g) if tier=="" else tier
	var index=maxi(0,g.Relics.TIERS.find(o.rarity))
	var current=g.weapons.get(o.id,{}).get("level",0) if o.type=="weapon" else g.rank_of(o.id) if o.type=="passive" else g.augments.get(o.id,0)
	var cap=10 if o.type=="weapon" else g.C.PASSIVES[o.id].max if o.type=="passive" else g.C.AUGMENTS[o.id].max
	o.rank_gain=mini(cap-current,(g.Relics.RANK_GAINS[index] if o.type=="weapon" else 1) if rank_gain==0 else rank_gain)
	var discrete=o.id=="count" if o.type=="passive" else g.C.AUGMENTS[o.id].stats.has("repeat") or g.C.AUGMENTS[o.id].stats.has("bounce") or g.C.AUGMENTS[o.id].stats.has("pierce") if o.type=="augment" else false
	o.stat_gain=float(COUNTS[index] if discrete else FACTORS[index])*o.rank_gain
	o.quantity=1;o.source=source;o.effects={"ranks":o.rank_gain,"stat_gain":o.stat_gain}
	if o.type=="passive" and o.id=="armor":o.effects.merge({"armor":2*o.stat_gain,"health":roundi(12*o.stat_gain)})
	return o
static func power(g,id):
	var rank=g.passives.get(id,g.augments.get(id,0))
	if rank==0:return 0.0
	var result=float(rank)
	for copy in g.buff_stacks.get(id,[]):result+=copy.stat_gain-copy.rank_gain
	return result
static func grant(g,o,actual_ranks):
	if actual_ranks<=0:return
	var data=o.duplicate(true)
	data.rank_gain=actual_ranks
	data.stat_gain=o.get("stat_gain",float(actual_ranks))*actual_ranks/maxf(1,o.get("rank_gain",actual_ranks))
	if not g.buff_stacks.has(o.id):g.buff_stacks[o.id]=[]
	g.buff_stacks[o.id].append(data)
static func description(g,o):
	if o.type=="passive" and g.C.PASSIVES[o.id].get("profile","")!="":return g.C.PASSIVES[o.id].desc
	var gain=o.get("stat_gain",float(o.get("rank_gain",1)))
	if o.type=="weapon":
		var current=g.weapons.get(o.id,{}).get("level",0)
		var rank=mini(10,current+o.get("rank_gain",1))
		return (g.C.WEAPONS[o.id].desc if current==0 else g.Rules.rank_text(g.C.WEAPONS[o.id],rank))+"\nRank %s to %s / 10"%[current,rank]
	if o.type=="augment":
		var names={"power":"damage","radius":"area","haste":"attack speed","velocity":"projectile speed","lifetime":"projectile lifetime","pierce":"piercing targets","homing":"tracking","bounce":"bounces","arc":"sweep angle","repeat":"echo strikes","range":"chain range","falloff":"chain damage retained","fork":"fork chance","rechain":"revisit chance","duration":"duration","shield":"barrier health","status":"status strength"}
		var pieces=[]
		for stat in g.C.AUGMENTS[o.id].stats:
			var value=g.C.AUGMENTS[o.id].stats[stat]*gain
			pieces.append(("+%.1f%% %s"%[value*100,names[stat]]) if stat in ["power","radius","haste","velocity","lifetime","range","falloff","fork","rechain"] else ("+%.1fs %s"%[value,names[stat]]) if stat=="duration" else "+%.1f %s"%[value,names[stat]])
		return "\n".join(pieces)
	match o.id:
		"armor":return "+%.1f armor\n+%s maximum health and healing"%[2*gain,roundi(12*gain)]
		"pickup":return "+%.0f pickup radius\n+%.1f%% XP gained"%[35*gain,8*gain]
		"regen":return "+%.2f health / second"%(.35*gain)
		"count":return "+%s projectile / chain / strike"%int(gain)
		"crit":
			var raw=g.C.HEROES[g.hero].crit+power(g,"crit")*.07+g.research_ranks.get("critical",0)*.02
			return "+%.1f%% critical chance\n%.1f%% to %.1f%% total"%[gain*7,g.crit_curve(raw)*100,g.crit_curve(raw+gain*.07)*100]
	var names={"damage":"damage","haste":"attack speed","area":"area radius","speed":"movement speed","luck":"Luck"}
	return "+%.1f%% %s"%[BASE[o.id]*gain*100,names.get(o.id,o.id)]
static func inventory(g,id):
	var kind="passive" if g.C.PASSIVES.has(id) else "augment"
	var d=(g.C.PASSIVES[id] if kind=="passive" else g.C.AUGMENTS[id]).duplicate(true)
	var best=0
	for copy in g.buff_stacks.get(id,[]):best=maxi(best,g.Relics.TIERS.find(copy.get("rarity","COMMON")))
	d.rarity=g.Relics.TIERS[best]
	d.desc=description(g,{"type":kind,"id":id,"stat_gain":power(g,id)})+"\nRank %s / %s. Tier bonuses add together."%[g.passives.get(id,g.augments.get(id,0)),d.max]
	if id=="crit":d.desc="+%.1f%% critical chance from Deadeye\nCurrent critical chance: %.1f%%\nRank %s / %s. Tier bonuses add together."%[power(g,id)*7,g.crit_chance()*100,g.rank_of(id),d.max]
	return d
