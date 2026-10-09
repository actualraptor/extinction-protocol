extends RefCounted
## Display values come from combat rules, without granting a reward or consuming RNG.
static func number(value):
	for unit in [[1000000000.0,"B"],[1000000.0,"M"],[10000.0,"k"]]:
		if absf(value)>=unit[0]:return ("%.2f"%(value/(1000.0 if unit[1]=="k" else unit[0]))).trim_suffix("0").trim_suffix("0").trim_suffix(".")+unit[1]
	return str(roundi(value)) if is_equal_approx(value,round(value)) else "%.1f"%value
static func stat_number(value,key):
	return ("%.3fs"%value if value<.1 else "%.2fs"%value) if key=="cooldown" else number(value)
static func badge(g,o):
	if o.type=="evolution":return "EVOLVE"
	if o.type=="fusion":return "UNION"
	if o.type=="relic":return "RELIC"
	if o.type=="supplies":return "SUPPLIES"
	var old=g.weapons.get(o.id,{}).get("level",0) if o.type=="weapon" else g.rank_of(o.id) if o.type=="passive" else g.augments.get(o.id,0)
	return "NEW" if old==0 else "RANK %s → %s"%[old,old+o.get("rank_gain",1)]
static func weapon_stats(g,o):
	var original=g.weapons;var cache=g.modifier_cache
	var source=g.Evolutions.UNIONS[o.id].base if o.type=="fusion" else o.id
	var before=g.Rules.stats(g,source).duplicate() if original.has(source) else {}
	g.weapons=original.duplicate(true);g.modifier_cache={}
	if o.type=="fusion":
		for part in g.Evolutions.UNIONS[o.id].parts:g.weapons.erase(part)
	var next=g.weapons.get(o.id,{"level":0,"evolved":false,"timer":0.0})
	next.level=10 if o.type=="fusion" else mini(10,next.level+o.get("rank_gain",1)) if o.type=="weapon" else next.level
	next.evolved=o.type in ["evolution","fusion"] or next.evolved
	g.weapons[o.id]=next
	var after=g.Rules.stats(g,o.id).duplicate()
	g.weapons=original;g.modifier_cache=cache
	return [before,after]
static func transition(g,o):
	if o.type=="evolution":return g.C.WEAPONS[o.id].name+" → "+g.C.WEAPONS[o.id].evolution
	if o.type=="fusion":return " + ".join(g.Evolutions.UNIONS[o.id].parts.map(func(id):return g.C.WEAPONS[id].name))+" → "+g.C.WEAPONS[o.id].name
	return ""
static func effective(g,id,stats,rank,evolved):
	var s=stats.duplicate();var d=g.C.WEAPONS[id]
	if rank==10 and d.delivery!="companion":s.power*=1.2
	if evolved and d.delivery=="melee" and "SWEEP" in d.tags:s.arc=TAU
	if preload("res://scripts/kael_slam.gd").applies(g,id):s.arc=TAU
	if preload("res://scripts/kael_slam.gd").applies(g,id):s.repeat=mini(8,s.repeat)
	if d.delivery=="projectile" and ("EXPLOSION" in d.tags or "RICOCHET" in d.tags):s.pierce=1
	if d.delivery=="projectile":
		s.bounce+=d.get("bounce",0)+(2 if id in ["ricochet","glacier"] and evolved else 0)
		s.homing+=d.get("projectile_homing",0.0)
		if id=="return":s.pierce=8+int(g.Rules.modifiers(g,id).get("pierce",0))
	if d.delivery=="ground":
		s.count=mini(4 if id=="thunderstorm" else 8,s.count)
		if id=="thunderstorm":s.duration+=2.0
	if d.delivery=="shield":s.shield*=1.7 if evolved else 1.0
	if d.delivery=="utility":s.duration=2+s.duration+rank*.15+(2 if evolved else 0)
	if d.delivery=="companion" and g.companions!=null:
		s.cooldown/=1+g.companions.rank(g,9)*.15+g.companions.relic(g,5)*g.companions.stationary*.025
		if d.get("role","") in ["spear","soul"]:s.count=mini(8,s.count)
		if d.get("role","")=="chill":s.radius=minf(160,s.radius)
	return s
static func rows(g,o):
	var out=[]
	if o.type in ["weapon","fusion","evolution"]:
		var pair=weapon_stats(g,o);var d=g.C.WEAPONS[o.id]
		var source=g.Evolutions.UNIONS[o.id].base if o.type=="fusion" else o.id
		var current=g.weapons.get(source,{"level":0,"evolved":false})
		var rank=10 if o.type=="fusion" else mini(10,current.level+o.get("rank_gain",1)) if o.type=="weapon" else current.level
		if not pair[0].is_empty():pair[0]=effective(g,source,pair[0],current.level,current.evolved)
		pair[1]=effective(g,o.id,pair[1],rank,o.type in ["evolution","fusion"] or current.evolved)
		var keys=["power","cooldown","count","pierce","velocity","lifetime","homing","bounce"]
		if d.delivery=="beam":keys=["power","cooldown","range","width","duration","count"]
		if d.delivery=="chain":keys=["power","cooldown","count","range","falloff","fork","rechain"]
		if d.delivery=="melee":keys=["power","cooldown","radius","arc","repeat"]
		if d.delivery in ["aura","ground","thorns","orbital"]:keys=["power","cooldown","radius","count","duration"]
		if d.delivery=="shield":keys=["shield","cooldown"]
		if d.delivery=="utility":keys=["cooldown","duration"]
		if d.delivery=="companion":
			keys=["power","cooldown","count"] if d.get("role","") in ["spear","soul"] else ["power","cooldown","radius"] if d.get("role","")=="chill" else ["power"] if d.get("role","")=="corpse" else [] if d.get("role","") in ["banner","reanimate"] else ["power","cooldown"]
		var names={"power":"Base hit damage" if d.delivery=="companion" else "Hit damage","cooldown":"Summon interval" if d.delivery=="companion" else "Cooldown","count":"Targets" if d.delivery=="chain" else "Projectiles" if d.delivery=="projectile" else "Blades" if d.delivery=="orbital" else "Strikes","radius":"Radius","shield":"Barrier","pierce":"Pierce","velocity":"Shot speed","lifetime":"Shot lifetime","homing":"Tracking","bounce":"Bounces","range":"Chain range","falloff":"Damage retained","fork":"Fork chance","rechain":"Revisit chance","arc":"Sweep angle","repeat":"Echo strikes","duration":"Duration" if d.delivery=="utility" or o.id=="thunderstorm" else "Ground linger"}
		if d.delivery=="beam":names.merge({"power":"Damage / second","range":"Beam length","width":"Beam width","duration":"Firing duration","count":"Beams","cooldown":"Recharge"},true)
		if d.delivery=="companion" and d.get("role","") not in ["warrior","guard","archer","wraith","colossus"]:names.cooldown="Cooldown"
		for key in keys:
			if pair[0].is_empty() and key in ["velocity","lifetime","falloff","homing","bounce","fork","rechain","arc","repeat"]:continue
			if pair[0].has(key) and is_equal_approx(pair[0][key],pair[1][key]):continue
			if pair[0].is_empty() and is_zero_approx(pair[1][key]):continue
			# Counts unused by the delivery must not masquerade as extra attacks.
			if key=="count" and d.delivery in ["aura","thorns"]:continue
			out.append({"name":names[key],"before":display(pair[0][key],key) if pair[0].has(key) else "—","after":display(pair[1][key],key)})
		if d.get("role","")=="reanimate":
			var rite=preload("res://scripts/companion_system.gd")
			var old_rite=rite.reanimate_profile(current.level,current.evolved)
			var next_rite=rite.reanimate_profile(rank,o.type=="evolution" or current.evolved)
			for key in ["kills","count","lifetime"]:
				out.append({"name":{"kills":"Kills per raise","count":"Warriors per raise","lifetime":"Raised lifetime"}[key],"before":number(old_rite[key])+("s" if key=="lifetime" else "") if current.level>0 else "—","after":number(next_rite[key])+("s" if key=="lifetime" else "")})
		if d.delivery=="companion" and g.companions!=null and d.get("role","") in ["warrior","guard","archer","wraith","colossus"]:
			var original=g.weapons;var before=g.companions.capacity(g,o.id) if original.has(o.id) else 0
			g.weapons=original.duplicate(true);g.weapons[o.id]={"level":rank,"evolved":o.type in ["evolution","fusion"] or current.evolved}
			var after=g.companions.capacity(g,o.id);g.weapons=original
			if before!=after:out.append({"name":"Unit capacity","before":str(before),"after":str(after)})
	elif o.type=="augment":
		var names={"power":"Damage bonus","radius":"Radius bonus","haste":"Haste bonus","velocity":"Shot speed bonus","lifetime":"Lifetime bonus","pierce":"Extra pierce","homing":"Tracking","bounce":"Extra bounces","arc":"Extra sweep angle","repeat":"Extra echo strikes","range":"Chain range bonus","falloff":"Retention bonus","fork":"Fork chance bonus","rechain":"Revisit chance bonus","duration":"Extra duration","shield":"Barrier bonus","status":"Status bonus"}
		for key in g.C.AUGMENTS[o.id].stats:
			if key in ["arc","repeat","pierce","bounce","falloff","fork","rechain"]:
				var actual=augment_effect(g,o,key)
				if not actual.is_empty():out.append(actual)
				continue
			var multiplier=100 if key in ["power","radius","haste","velocity","lifetime","range","falloff","fork","rechain"] else 1
			var suffix="%" if multiplier==100 else "s" if key=="duration" else ""
			var base=g.C.AUGMENTS[o.id].stats[key]
			out.append({"name":names[key],"before":number(base*g.buff_power(o.id)*multiplier)+suffix,"after":number(base*(g.buff_power(o.id)+o.get("stat_gain",1))*multiplier)+suffix})
	elif o.type=="passive" and g.C.PASSIVES[o.id].get("profile","")=="":
		var gain=o.get("stat_gain",1);var power=g.buff_power(o.id)
		var names={"damage":"Damage bonus","haste":"Attack speed","area":"Radius bonus","speed":"Move speed","luck":"Luck bonus","crit":"Critical chance","count":"Extra count","regen":"Health / second","armor":"Armor","pickup":"Pickup radius"}
		var base=g.BuffRewards.BASE[o.id];var percent=o.id in ["damage","haste","area","speed","luck","crit"]
		var old=base*power;var next=base*(power+gain)
		if o.id=="crit":
			var raw=g.C.HEROES[g.hero].crit+power*.07+g.research_ranks.get("critical",0)*.02
			old=g.crit_curve(raw);next=g.crit_curve(raw+gain*.07)
		if o.id=="armor":old=g.armor;next=old+2*gain
		if o.id=="pickup":old=95+old+g.research_ranks.get("magnet",0)*12;next=old+35*gain
		out.append({"name":names[o.id],"before":number(old*(100 if percent else 1))+("%" if percent else ""),"after":number(next*(100 if percent else 1))+("%" if percent else "")})
		if o.id=="regen":out[0].before="%.2f"%old;out[0].after="%.2f"%next
		if o.id=="armor":out.append({"name":"Maximum health","before":number(g.max_hp),"after":number(g.max_hp+roundi(12*gain))})
		if o.id=="pickup":out.append({"name":"XP bonus","before":number(power*8)+"%","after":number((power+gain)*8)+"%"})
	elif o.type=="relic":out=relic_rows(g,o)
	elif o.type=="passive":out=profile_rows(g,o)
	elif o.type=="supplies":
		out=[{"name":"Amber","before":number(g.amber),"after":number(g.amber+o.get("amber_gain",25))},{"name":"Health","before":number(g.hp),"after":number(minf(g.max_hp,g.hp+o.get("heal_gain",15)))}]
	return out
static func augment_effect(g,o,key):
	var original=g.augments;var stacks=g.buff_stacks;var cache=g.modifier_cache
	var before=[];var after=[]
	var eligible=[]
	for id in g.weapons:
		if g.Rules.matches(g.C.WEAPONS[id].tags,g.C.AUGMENTS[o.id].filter):
			eligible.append(id)
			before.append(effective(g,id,g.Rules.stats(g,id),g.weapons[id].level,g.weapons[id].evolved)[key])
	if eligible.is_empty():return {}
	g.augments=original.duplicate();g.buff_stacks=stacks.duplicate(true);g.modifier_cache={}
	var gain=mini(g.C.AUGMENTS[o.id].max-g.augments.get(o.id,0),o.get("rank_gain",1))
	g.augments[o.id]=g.augments.get(o.id,0)+gain;g.BuffRewards.grant(g,o,gain)
	for id in eligible:after.append(effective(g,id,g.Rules.stats(g,id),g.weapons[id].level,g.weapons[id].evolved)[key])
	g.augments=original;g.buff_stacks=stacks;g.modifier_cache=cache
	var caption={"arc":"Sweep angle","repeat":"Echo strikes","pierce":"Pierce","bounce":"Bounces","falloff":"Damage retained","fork":"Fork chance","rechain":"Revisit chance"}[key]
	return {"name":caption,"before":span(before,key),"after":span(after,key)}
static func span(values,key):
	var lo=values.min();var hi=values.max()
	return display(lo,key) if is_equal_approx(lo,hi) else display(lo,key)+"–"+display(hi,key)
static func display(value,key):
	if key in ["fork","rechain","falloff"]:return number(value*100)+"%"
	if key=="arc":return number(rad_to_deg(value))+"°"
	if key in ["duration","lifetime"]:return "%.2fs"%value
	return stat_number(value,key)
static func relic_rows(g,o):
	var rows=[];var original_relics=g.relics;var original_stacks=g.relic_stacks;var original_state=g.relic_state;var cache=g.modifier_cache
	var original_hp=g.hp;var original_max=g.max_hp;var original_armor=g.armor
	g.relics=original_relics.duplicate();g.relic_stacks=original_stacks.duplicate(true);g.relic_state=original_state.duplicate(true);g.modifier_cache={}
	var before=g.Relics.modifiers(g).duplicate()
	if o.has("replace"):g.Relics.remove(g,o.replace)
	var accepted=g.Relics.apply(g,o)
	var after=g.Relics.modifiers(g).duplicate()
	var names={"damage":"Damage bonus","haste":"Attack speed","xp":"XP gained","score":"Score bonus","enemy_health":"Horde health","incoming":"Damage taken","count":"Extra count","fork":"Fork chance","chilled_damage":"Vs chilled prey","low_health_haste":"Low-HP haste","guard_cooldown":"Hit block interval","vacuum_interval":"XP vacuum interval","movement_burst":"Moving burst delay","heal":"Heal / 30 kills","burst_damage":"Burst / 18 kills","critical_chain":"Critical arc power","momentum_damage":"Moving damage / s","boss_damage":"Damage / boss kill","boss_health":"Health / boss kill"}
	var percents=["damage","haste","xp","score","enemy_health","incoming","fork","chilled_damage","low_health_haste","critical_chain","momentum_damage","boss_damage"]
	if accepted:
		for key in names:
			if is_equal_approx(before.get(key,0),after.get(key,0)):continue
			var suffix="%" if key in percents else "s" if key in ["guard_cooldown","vacuum_interval","movement_burst"] else ""
			var scale=100 if key in percents else 1
			rows.append({"name":names[key],"before":number(before.get(key,0)*scale)+suffix,"after":number(after.get(key,0)*scale)+suffix,"worse":key in ["incoming","enemy_health"] and after.get(key,0)>before.get(key,0)})
		for metric in [["Maximum health",original_max,g.max_hp],["Armor",original_armor,g.armor],["Health",original_hp,g.hp]]:
			if metric[1]!=metric[2]:rows.append({"name":metric[0],"before":number(metric[1]),"after":number(metric[2])})
	g.relics=original_relics;g.relic_stacks=original_stacks;g.relic_state=original_state;g.modifier_cache=cache;g.hp=original_hp;g.max_hp=original_max;g.armor=original_armor
	return rows
static func profile_rows(g,o):
	var p=g.buff_power(o.id);var n=p+o.get("stat_gain",1);var rows=[]
	var metrics=[]
	match o.id:
		"p00":metrics=[["Soul bonus",p*20,n*20,"%"]]
		"p01":metrics=[["Warriors / 100 souls",int(p>0),int(n>0),""],["Soul capacity cap",5*int(p>0),5*int(n>0),""]]
		"p02":metrics=[["Elite soul yield",5 if p>0 else 1,5 if n>0 else 1,"×"]]
		"p03":metrics=[["Nearby ally damage",p*20,n*20,"%"]]
		"p04":metrics=[["Armor / ally",p*.3,n*.3,""],["Armor limit",8*int(p>0),8*int(n>0),""]]
		"p05":
			var warrior=g.companions.owned(g,"warrior") if g.companions!=null else ""
			if warrior=="":metrics=[["Extra warrior cap",mini(32,int(p)*2),mini(32,int(n)*2),""]]
			else:
				var before=g.companions.capacity(g,warrior)
				metrics=[["Warrior capacity",before,mini(36,before+(int(n)-int(p))*2),""]]
		"p06":metrics=[["Ally attack speed",p*20,n*20,"%"]]
		"p07":metrics=[["Momentum / kill",p,n,""],["Max damage bonus",50*int(p>0),50*int(n>0),"%"]]
		"p08":metrics=[["Vs armored prey",25*int(p>0),25*int(n>0),"%"],["Extra knockback",p*15,n*15,""]]
		"p09":metrics=[["Summon haste",p*15,n*15,"%"]]
		"p10":metrics=[["Extra units / cast",int(p),int(n),""]]
		"p11":
			var base=g.companions.owned(g,"warrior") if g.companions!=null else ""
			var chance=(.08 if base!="" and g.weapons[base].level>=7 else 0.0)+(g.companions.relic(g,7)*.1 if g.companions!=null else 0.0)
			metrics=[["Temporary raise chance",minf(.4,chance+p*.06)*100,minf(.4,chance+n*.06)*100,"%"]]
		"p12":metrics=[["Damage shared",20*int(p>0),20*int(n>0),"%"]]
	for m in metrics:
		if m[1]!=m[2]:rows.append({"name":m[0],"before":number(m[1])+m[3],"after":number(m[2])+m[3]})
	return rows
static func copy(g,o):
	if o.type in ["weapon","evolution","fusion"]:
		var d=g.C.WEAPONS[o.id]
		if d.get("role","")=="reanimate":return "Each trigger now raises two temporary warriors lasting 18 seconds, instead of one lasting 12 seconds." if o.type=="evolution" else "Kills raise temporary warriors nearby. Even ranks reduce the kills required; odd ranks leave this trigger unchanged."
		if o.type=="evolution" and d.delivery=="companion":
			return {"warrior":"Your legion grows. Every third warrior becomes a champion, and fallen warriors reform sooner.","guard":"More elite guards can fight beside you, with stronger strikes and faster reinforcement.","archer":"A larger archer cohort fires stronger volleys and replenishes faster.","wraith":"More wraiths haunt the battlefield, dealing stronger spectral strikes.","colossus":"Your colossus strikes harder and can be summoned sooner."}.get(d.get("role",""),d.get("evolution_desc",d.desc))
		if o.type=="weapon" and g.weapons.has(o.id):
			var old=g.weapons[o.id].level;var next=mini(10,old+o.get("rank_gain",1))
			if old<7 and next>=7:
				if preload("res://scripts/kael_slam.gd").applies(g,o.id):return "Adds an echo slam and a weaker aftershock."
				return {"melee":"Adds an echo strike and a forward shockwave.","chain":"Chains can now fork into extra arcs.","aura":"Every fourth pulse erupts with twice the damage and 1.8× radius.","shield":"Breaking the barrier now triggers retaliation.","utility":"Time fractures now freeze lesser enemies."}.get(d.delivery,"")
			if d.delivery=="companion" and d.get("role","")=="warrior" and old<9 and next>=9:return "Every fifth warrior is raised as a champion."
		if preload("res://scripts/kael_slam.gd").applies(g,o.id) and o.type in ["evolution","fusion"]:return "Grounded circular slams with echo strikes and aftershocks."
		return d.get("evolution_desc",d.desc) if o.type=="evolution" else d.desc if not g.weapons.has(o.id) or o.type=="fusion" else ""
	if o.type=="augment":return "" if o.id not in ["homing","bounce","linger","winterbite"] else {"homing":"Shots bend toward nearby prey.","bounce":"Spent shots seek another target.","linger":"Bombardments leave a damaging ground zone.","winterbite":"Ice freezes sooner and holds prey longer."}[o.id]
	if o.type=="passive" and g.C.PASSIVES[o.id].get("profile","")=="":return ""
	if o.type=="passive":return {"p01":"Collected souls increase warrior capacity.","p02":"Bonus applies to elite and boss souls.","p03":"Applies to allies within 300 units.","p04":"Armor scales with your active army.","p07":"Undead kills build damage; resets after 4s without a kill.","p08":"Minion strikes shove prey farther.","p11":"Undead kills can raise temporary warriors.","p12":"Nearby allies absorb part of incoming damage."}.get(o.id,"")
	if o.type=="supplies":return ""
	if o.type=="relic" and not rows(g,o).is_empty():return "" if o.id not in ["clock","magnet","boots","blood","ember","storm","momentum","apex","laststand"] else {"clock":"Periodically blocks one incoming hit.","magnet":"Periodically draws nearby XP to you.","boots":"Moving continuously triggers an explosive wake.","blood":"Heals every 30 kills; 2s cooldown.","ember":"Releases a fire burst every 18 kills.","storm":"Critical hits can trigger an arc; 0.6s cooldown.","momentum":"Moving builds damage for up to 8 seconds.","apex":"Defeating bosses grants lasting damage and health.","laststand":"Attack-speed bonus applies below 35% health."}[o.id]
	return preload("res://scripts/upgrade_copy.gd").description(g,o)
