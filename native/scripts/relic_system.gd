extends RefCounted
const Rules = preload("res://scripts/combat_rules.gd")
const TIERS = ["COMMON","UNCOMMON","RARE","EPIC","LEGENDARY","ARTIFACT"]
const COLORS = ["ddd9d2","58d77b","58a8ff","bb79ff","ffad47","f6d879"]
const WEIGHTS = [40.0,30.0,18.0,9.0,2.7,0.3]

static func tier_color(rarity): return COLORS[maxi(0,TIERS.find(rarity))]

static func roll(g):
	var distribution = odds(g)
	g.relic_state.chest_odds = distribution.duplicate()
	var ticket = g.rng.randf()*100
	var selected = 0
	for tier in range(6):
		if distribution[tier]<=0: continue
		selected = tier
		ticket -= distribution[tier]
		if ticket<=0: break
	var candidates = []
	for id in g.C.RELICS:
		var d = g.C.RELICS[id]
		if TIERS.find(d.rarity)==selected and id not in g.relics and g.content_allowed("relics",id) and Rules.eligible(g.weapons,g.C.WEAPONS,d.get("filter",{})): candidates.append(id)
	if candidates.is_empty(): return ""
	g.relic_state.dry_chests = 0 if selected>=2 else g.relic_state.get("dry_chests",0)+1
	return candidates[g.rng.randi_range(0,candidates.size()-1)]

static func odds(g):
	var buckets = [[],[],[],[],[],[]]
	for id in g.C.RELICS:
		var d = g.C.RELICS[id]
		if id not in g.relics and g.content_allowed("relics",id) and Rules.eligible(g.weapons,g.C.WEAPONS,d.get("filter",{})):
			buckets[TIERS.find(d.rarity)].append(id)
	var total = 0.0
	var pity = g.relic_state.get("dry_chests",0)>=4
	var weights = [0.0,0.0,0.0,0.0,0.0,0.0]
	var luck = g.rank_of("luck")*0.1+g.permanent_luck
	for tier in range(6):
		if not buckets[tier].is_empty() and (not pity or tier>=2):
			weights[tier] = WEIGHTS[tier]*pow(1+luck,tier)
			total += weights[tier]
	if total<=0:
		for tier in range(6):
			if not buckets[tier].is_empty():
				weights[tier] = WEIGHTS[tier]*pow(1+luck,tier)
				total += weights[tier]
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
	return out

static func modifiers(g):
	# Relics are unique and append-only for a run. Avoid hashing the entire
	# inventory for each of the many thousands of hits in a horde.
	var key = g.relics.size()
	if g.relic_state.get("mods_key",-1)==key: return g.relic_state.mods
	var out = {}
	for id in g.relics:
		for stat in g.C.RELICS[id].get("mods",{}): out[stat] = out.get(stat,0.0)+g.C.RELICS[id].mods[stat]
	g.relic_state.mods_key = key
	g.relic_state.mods = out
	return out

static func on_cast(g,definition,cast_number,stats):
	for id in g.relics:
		var rule = g.C.RELICS[id].get("cast",{})
		if rule.is_empty() or cast_number%int(rule.every)!=0 or not Rules.matches(definition.tags,rule.filter): continue
		stats.count += rule.get("count",0)
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
				if g.proc_depth==0 and g.proc_queue.size()<32: g.proc_queue.append({"p":e.p,"id":hook.effect,"damage":minf(350,e.max_hp*0.65)})
			"cooldown":
				for w in g.weapons.values(): w.timer = maxf(0,w.timer-0.15)
			"growth":
				for weapon in g.weapons:
					if "AURA" in g.C.WEAPONS[weapon].tags and g.pos.distance_to(e.p)<Rules.stats(g,weapon).radius:
						g.relic_state.aura_growth = minf(0.65,g.relic_state.get("aura_growth",0.0)+0.002)
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
