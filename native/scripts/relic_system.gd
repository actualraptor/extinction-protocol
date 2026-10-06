extends RefCounted
const Rules = preload("res://scripts/combat_rules.gd")
const TIERS = ["COMMON","UNCOMMON","RARE","EPIC","LEGENDARY","ARTIFACT"]
const COLORS = ["ddd9d2","58d77b","58a8ff","bb79ff","ffad47","f6d879"]
const WEIGHTS = [40.0,30.0,18.0,9.0,2.7,0.3]
const STACK_LIMIT = 10
const FACTORS = [0.35,0.5,0.75,1.0,1.35,2.0]
const RANK_GAINS = [1,1,2,2,3,4]
const GROWTH = [0.05,0.075,0.10,0.15,0.20,0.30]
static var definitions_cache={}

static func tiers(g,id):
	# Legacy inventories remain valid: their first copy keeps its old strength.
	return g.relic_stacks.get(id,["LEGACY"] if id in g.relics else [])

static func candidates(g):
	return g.C.RELICS.keys().filter(func(id):return (id in g.relics or g.relics.size()<g.RELIC_SLOTS) and tiers(g,id).size()<g.C.RELICS[id].get("max_copies",STACK_LIMIT) and g.content_allowed("relics",id) and Rules.eligible(g.weapons,g.C.WEAPONS,g.C.RELICS[id].get("filter",{})))

static func roll_tier(g):
	var distribution=odds(g)
	g.relic_state.chest_odds=distribution.duplicate()
	var ticket=g.rng.randf()*100
	var selected=5
	for tier in range(6):
		ticket-=distribution[tier]
		if ticket<=0:selected=tier;break
	g.relic_state.dry_chests=0 if selected>=2 else g.relic_state.get("dry_chests",0)+1
	return TIERS[selected]

static func reward(id,tier,source="chest"):
	return {"type":"relic","id":id,"rarity":tier,"quantity":1,"source":source,"effects":effects(id,tier)}

static func roll_reward(g):
	var pool=candidates(g)
	if pool.is_empty():return {}
	var tier=roll_tier(g)
	pool=pool.filter(func(id):return (not g.C.RELICS[id].get("artifact_only",false) or (tier=="ARTIFACT" and id not in g.relics)) and TIERS.find(tier)>=TIERS.find(g.C.RELICS[id].get("min_tier","COMMON")))
	if pool.is_empty():return {}
	var total_weight=0.0
	for id in pool:total_weight+=g.C.RELICS[id].get("roll_weight",1.0)
	var ticket=g.rng.randf()*total_weight
	for id in pool:
		ticket-=g.C.RELICS[id].get("roll_weight",1.0)
		if ticket<=0:return reward(id,tier)
	return reward(pool.back(),tier)

static func effects(id,tier):
	if definitions_cache[id].get("fixed_power",false):return {"mods":{},"acquire":{},"power":1.0}
	if tier=="LEGACY":
		var legacy=definitions_cache[id]
		return {"mods":legacy.get("mods",{}).duplicate(true),"acquire":legacy.get("acquire",{}).duplicate(true),"power":1.0}
	var n=maxi(0,TIERS.find(tier));var f=FACTORS[n]
	# Explicit tables make integer rewards and timers meaningful at every tier.
	if id=="crown":return {"mods":{"score":GROWTH[n],"xp":GROWTH[n],"enemy_health":GROWTH[n]}}
	if id=="lens":return {"mods":{"xp":GROWTH[n]}}
	if id=="wrap":return {"acquire":{"health":[10,15,20,30,40,60][n]}}
	if id=="shell":return {"acquire":{"health":[15,20,30,40,55,75][n],"armor":[1,1,2,2,3,4][n]}}
	if id=="prism":return {"mods":{"count":[1,1,1,2,2,3][n]}}
	var special={
		"clock":{"guard_cooldown":[40,35,30,25,20,15][n]},
		"magnet":{"vacuum_interval":[30,26,22,18,15,12][n]},
		"boots":{"movement_burst":[6,5.5,5,4,3.5,3][n]},
		"blood":{"heal_every":30,"heal":[2,3,4,6,8,12][n]},
		"storm":{"critical_chain":[0.15,0.20,0.25,0.35,0.45,0.60][n],"critical_chain_cooldown":0.6},
		"ember":{"burst_every":18,"burst_damage":[25,35,45,60,80,120][n]}}
	if special.has(id):return {"mods":special[id]}
	var d=definitions_cache[id]
	var result={"mods":{},"acquire":{},"power":f}
	for key in d.get("mods",{}):result.mods[key]=d.mods[key]*f
	for key in d.get("acquire",{}):result.acquire[key]=roundi(d.acquire[key]*f)
	return result

static func apply(g,o):
	var id=o.id
	if id not in g.C.RELICS or tiers(g,id).size()>=g.C.RELICS[id].get("max_copies",STACK_LIMIT) or (id not in g.relics and g.relics.size()>=g.RELIC_SLOTS):return false
	var copies=tiers(g,id).duplicate()
	if id not in g.relics:g.relics.append(id)
	var tier=o.get("rarity","LEGACY")
	copies.append(tier);g.relic_stacks[id]=copies
	var gain=o.get("effects",effects(id,tier)).get("acquire",{})
	g.max_hp+=gain.get("health",0);g.hp=minf(g.max_hp,g.hp+gain.get("health",0));g.armor+=gain.get("armor",0)
	g.relic_state.revision=g.relic_state.get("revision",0)+1
	g.modifier_cache.clear()
	return true

static func remove(g,id):
	if id=="garden":g.relic_state.erase("aura_growth")
	for tier in tiers(g,id):
		var gain=effects(id,tier).get("acquire",{})
		g.max_hp-=gain.get("health",0);g.armor-=gain.get("armor",0)
	g.hp=minf(g.hp,g.max_hp);g.relics.erase(id);g.relic_stacks.erase(id)
	g.relic_state.revision=g.relic_state.get("revision",0)+1;g.modifier_cache.clear()

static func strength(g,id):
	var power=0.0
	for tier in tiers(g,id):power+=1.0 if tier=="LEGACY" else FACTORS[maxi(0,TIERS.find(tier))]
	return minf(3.0,power)

static func description(o):
	var d=definitions_cache[o.id]
	var e=o.get("effects",effects(o.id,o.get("rarity",d.rarity)))
	var parts=[]
	var names={"damage":"damage","incoming":"damage taken","xp":"XP gained","score":"score","enemy_health":"future horde health (not bosses)","haste":"attack speed","chilled_damage":"damage to chilled prey","fork":"chain fork chance","low_health_haste":"attack speed below 35% HP","momentum_damage":"damage per second moving (8s max)","boss_damage":"damage per boss killed","critical_chain":"critical arc damage"}
	for key in e.get("mods",{}):
		var value=e.mods[key]
		if names.has(key):parts.append("+%.1f%% %s"%[value*100,names[key]])
		elif key=="count":parts.append("+%s projectile / chain / strike"%int(value))
		elif key in ["guard_cooldown","vacuum_interval","movement_burst"]:parts.append({"guard_cooldown":"Blocks one hit every %.1fs","vacuum_interval":"Vacuum nearby XP every %.1fs","movement_burst":"Explosive wake after %.1fs moving"}[key]%value)
		elif key=="heal":parts.append("Heal %.1f every 30 kills (2s cooldown)"%value)
		elif key=="burst_damage":parts.append("%.1f fire burst every 18 kills"%value)
		elif key=="boss_health":parts.append("+%.1f HP per boss killed"%value)
	for key in e.get("acquire",{}):parts.append("+%.1f %s"%[e.acquire[key],"maximum HP and healing" if key=="health" else key])
	if parts.is_empty():
		var power=e.get("power",1.0)
		if o.id=="volley":parts.append("Every fifth projectile cast: +%s shots"%maxi(1,roundi(5*power)))
		elif o.id=="cyclone":parts.append("Full-circle melee every %s casts"%maxi(2,roundi(3/power)))
		elif o.id in ["shatter","wildfire"]:parts.append("Status kills burst for %.1f%% prey HP (350 damage cap). No recursive bursts."%(minf(1.0,0.65*power)*100))
		elif o.id=="reaper":parts.append("Critical kills reduce cooldowns by %.2fs (0.3s trigger cooldown)"%minf(.3,.15*power))
		elif o.id=="garden":parts.append("Aura kills grow radius up to +%.1f%%"%(minf(.65,.65*power)*100))
		else:parts.append(d.desc)
	return ". ".join(parts)+"."

static func inventory_data(g,id):
	var copies=tiers(g,id);var d=g.C.RELICS[id].duplicate(true)
	var best=0;var lines=[];var counts={}
	for tier in copies:
		best=maxi(best,TIERS.find(g.C.RELICS[id].rarity if tier=="LEGACY" else tier))
		counts[tier]=counts.get(tier,0)+1
	for tier in counts:lines.append(("Original" if tier=="LEGACY" else tier)+" ×%s: "%counts[tier]+description(reward(id,tier)))
	d.rarity=TIERS[best];d.name+=" ×%s"%copies.size()
	d.desc="\n".join(lines)+"\nCopies %s / %s. Additive bonuses; proc strength caps at 3×. Max +4 count, +85%% fork, +150%% critical arc / low-HP haste. Timers stop at 10s guard, 6s vacuum, 1.5s wake."%[copies.size(),STACK_LIMIT]
	return d

static func tier_color(rarity): return COLORS[maxi(0,TIERS.find(rarity))]

static func roll(g):
	return roll_reward(g).get("id","")

static func odds(g,include_pity=true):
	var total = 0.0
	var pity = include_pity and g.relic_state.get("dry_chests",0)>=4
	var weights = [0.0,0.0,0.0,0.0,0.0,0.0]
	var luck = maxf(0,g.buff_power("luck")*0.1+g.permanent_luck)
	# Original rarity-weighted Luck curve, before additive roll bonuses.
	for tier in range(6):
		if not pity or tier>=2:
			weights[tier]=WEIGHTS[tier]*pow(1+luck,tier)
			total+=weights[tier]
	for tier in range(6):
		weights[tier] = weights[tier]*100/total if total>0 else 0.0
	return weights

static func definitions(base):
	var out = base.duplicate(true)
	for id in out:
		out[id].tags = ["RELIC"]
		out[id].rarity = "RARE"
		out[id].icon = 6
	var extra = {
		"volley":["Fifth Gospel","Every fifth projectile attack fires five additional shots.",["PROJECTILE"],4],
		"branch":["Forked Prophecy","Chains gain a 30% chance to fork into another target.",["CHAIN"],6],
		"cyclone":["Threefold Violence","Every third melee attack strikes in a full circle.",["MELEE"],4],
		"shatter":["Heart of the Ice Age","Frozen enemies explode on death, spreading cold.",["ICE"],0],
		"wildfire":["The Last Forest","Burning enemies explode on death, spreading fire.",["FIRE"],3],
		"garden":["Grave Garden","Kills inside an aura grow its radius, up to +65%.",["AURA"],1],
		"reaper":["Borrowed Tomorrow","Critical kills reduce every active cooldown by 0.15s.",["CRITICAL"],0],
		"laststand":["Refusal","Below 35% health, attack 50% faster.",[],2],
		"momentum":["Never Look Back","Continuous movement builds up to 40% damage in eight seconds.",[],4],
		"apex":["Crown of the Unbroken","Each boss killed grants +15% damage and +20 health this run.",[],5]}
	for id in extra:
		var a = extra[id]
		out[id] = {"name":a[0],"desc":a[1],"tags":["RELIC"]+a[2],"filter":{"any":a[2]},"rarity":"LEGENDARY","color":"efd09b","icon":a[3]}
	out.shatter.hook = {"event":"kill","status":"frozen","op":"burst","effect":"frost"}
	out.wildfire.hook = {"event":"kill","status":"burn","op":"burst","effect":"fire"}
	out.reaper.hook = {"event":"kill","critical":true,"op":"cooldown"}
	out.reaper.hook.cooldown = 0.3
	out.reaper.desc = "Critical kills reduce all cooldowns by 0.15s. 0.3s trigger cooldown."
	out.garden.hook = {"event":"kill","op":"growth"}
	out.volley.cast = {"filter":{"all":["PROJECTILE"]},"every":5,"count":5}
	out.cyclone.cast = {"filter":{"all":["MELEE"]},"every":3,"circle":true}
	out.branch.mods = {"fork":0.3}
	out.laststand.mods = {"low_health_haste":0.5}
	out.momentum.mods = {"momentum_damage":0.05}
	out.apex.mods = {"boss_damage":0.15,"boss_health":20}
	out.glass.mods = {"damage":0.3,"incoming":0.2}
	out.crown.mods = {"score":0.2,"xp":0.2,"enemy_health":0.15}
	out.frost.mods = {"chilled_damage":0.25}
	out.clock.mods = {"guard_cooldown":25.0}
	out.storm.mods = {"critical_chain":0.35,"critical_chain_cooldown":0.6}
	out.magnet.mods = {"vacuum_interval":18.0}
	out.boots.mods = {"movement_burst":4.0}
	out.blood.mods = {"heal_every":30,"heal":4}
	out.ember.mods = {"burst_every":18,"burst_damage":60}
	out.shell.acquire = {"health":35,"armor":2}
	out.frost.tags.append("ICE")
	out.frost.filter = {"any":["ICE"]}
	out.ember.tags.append("FIRE")
	out.storm.tags.append("CRITICAL")
	out.storm.filter = {"any":["CRITICAL"]}
	var icons = {"ember":3,"storm":6,"blood":2,"glass":5,"clock":0,"magnet":1,"frost":0,"boots":4,"crown":5,"shell":5}
	for id in icons: out[id].icon = icons[id]
	var additions = {
		"flint":{"name":"Hunter's Flint","desc":"All damage +10%.","mods":{"damage":0.1},"icon":4},
		"wrap":{"name":"Mammoth Wrap","desc":"Gain 20 maximum health and heal 20.","acquire":{"health":20},"icon":2},
		"coil":{"name":"Quickening Coil","desc":"All attacks recharge 12% faster.","mods":{"haste":0.12},"icon":6},
		"lens":{"name":"Amber Lens","desc":"Earn 15% more experience.","mods":{"xp":0.15},"icon":6},
		"prism":{"name":"Prism of Plenty","desc":"An extra projectile, chain target, orbiting blade or bombardment.","mods":{"count":1},"filter":{"any":["PROJECTILE","CHAIN","ORBITAL","GROUND_EFFECT"]},"icon":5},
		"chronicle":{"name":"The Unwritten Era","desc":"Defy the ending: +45% damage, +20% attack speed and +40 maximum health.","mods":{"damage":0.45,"haste":0.2},"acquire":{"health":40},"icon":0}}
	for id in additions:
		out[id] = additions[id]
		out[id].tags = ["RELIC"]
	var tiers = {"COMMON":["flint","wrap"],"UNCOMMON":["coil","lens","blood","shell"],"RARE":["glass","magnet","boots","frost","crown","momentum"],"EPIC":["ember","storm","clock","branch","cyclone","garden","laststand"],"LEGENDARY":["volley","shatter","wildfire","reaper","apex","prism"],"ARTIFACT":["chronicle"]}
	for tier in tiers:
		for id in tiers[tier]:
			out[id].rarity = tier
			out[id].color = tier_color(tier)
	out.frost.desc = "Chilled or frozen enemies take 25% more damage."
	definitions_cache=out
	return out

static func modifiers(g):
	# Stable IDs plus a revision invalidate cached totals on stacks and removal.
	var key = [g.relics.hash(),g.relic_state.get("revision",0)].hash()
	if g.relic_state.get("mods_key",-1)==key: return g.relic_state.mods
	var out = {}
	for id in g.relics:
		for tier in tiers(g,id):
			var mods=effects(id,tier).get("mods",{})
			for stat in mods:
				if stat in ["heal_every","burst_every","critical_chain_cooldown"]:out[stat]=mods[stat]
				elif stat in ["guard_cooldown","vacuum_interval","movement_burst"]:out[stat]=minf(out.get(stat,INF),mods[stat])
				else:out[stat]=out.get(stat,0.0)+mods[stat]
		var duplicates=maxi(0,tiers(g,id).size()-1)
		for stat in ["guard_cooldown","vacuum_interval","movement_burst"]:
			if g.C.RELICS[id].get("mods",{}).has(stat):out[stat]=maxf({"guard_cooldown":10.0,"vacuum_interval":6.0,"movement_burst":1.5}[stat],out[stat]/(1+duplicates*.12))
	for stat in {"count":4.0,"fork":0.85,"critical_chain":1.5,"low_health_haste":1.5,"boss_damage":0.45,"boss_health":60.0,"heal":30.0,"burst_damage":350.0}:
		if out.has(stat):out[stat]=minf(out[stat],{"count":4.0,"fork":0.85,"critical_chain":1.5,"low_health_haste":1.5,"boss_damage":0.45,"boss_health":60.0,"heal":30.0,"burst_damage":350.0}[stat])
	g.relic_state.mods_key = key
	g.relic_state.mods = out
	return out

static func on_cast(g,definition,cast_number,stats):
	for id in g.relics:
		var rule = g.C.RELICS[id].get("cast",{})
		var power=strength(g,id)
		var every=maxi(2,roundi(3/maxf(.35,power))) if id=="cyclone" else int(rule.get("every",1))
		if rule.is_empty() or cast_number%every!=0 or not Rules.matches(definition.tags,rule.filter): continue
		stats.count = mini(12,stats.count+maxi(1,roundi(rule.get("count",0)*power))) if rule.has("count") else stats.count
		if rule.get("circle",false): stats.arc = TAU

static func on_kill(g,e):
	# Proc kills cannot recursively schedule further proc explosions.
	for id in g.relics:
		var hook = g.C.RELICS[id].get("hook",{})
		if hook.get("event","")!="kill": continue
		if hook.has("status") and e.get(hook.status,0)<=0: continue
		if hook.get("critical",false) and not e.get("last_critical",false): continue
		if hook.has("cooldown"):
			if g.time<g.relic_state.get("next_"+id,0.0): continue
			g.relic_state["next_"+id] = g.time+hook.cooldown
		match hook.op:
			"burst":
				if g.proc_depth==0 and g.proc_queue.size()<32: g.proc_queue.append({"p":e.p,"id":hook.effect,"damage":minf(350,e.max_hp*minf(1.0,0.65*strength(g,id)))})
			"cooldown":
				for w in g.weapons.values(): w.timer = maxf(0,w.timer-minf(.3,.15*strength(g,id)))
			"growth":
				for weapon in g.weapons:
					if "AURA" in g.C.WEAPONS[weapon].tags and g.pos.distance_to(e.p)<Rules.stats(g,weapon).radius:
						g.relic_state.aura_growth = minf(minf(.65,.65*strength(g,id)),g.relic_state.get("aura_growth",0.0)+0.002*strength(g,id))
						break
	var mods = modifiers(g)
	if e.boss:
		g.base_damage += mods.get("boss_damage",0)
		g.max_hp += mods.get("boss_health",0)
		g.hp += mods.get("boss_health",0)

static func update(g,dt):
	var mods = modifiers(g)
	if mods.has("momentum_damage"):
		g.relic_state.momentum = minf(8,g.relic_state.get("momentum",0.0)+dt) if g.velocity.length()>50 else 0.0
	if mods.has("vacuum_interval") and g.relic_timers.magnet<=0:
		g.relic_timers.magnet = mods.vacuum_interval
		for gem in g.gems:
			if gem.p.distance_squared_to(g.pos)<640000: gem.magnet = true
		g.effect.emit("ring",g.pos,Color("83ffd7"),400)
	if mods.has("movement_burst"):
		g.relic_state.move_time = g.relic_state.get("move_time",0.0)+dt if g.velocity.length()>50 else 0.0
		if g.relic_state.move_time>=mods.movement_burst:
			g.relic_state.move_time = 0.0
			g.blast(g.pos,110,90*g.damage_scale("fire"),"fire")
	var queue = g.proc_queue
	g.proc_queue = []
	g.proc_depth = 1
	for proc in queue: g.blast(proc.p,110*g.area_scale(),proc.damage,proc.id)
	g.proc_depth = 0
