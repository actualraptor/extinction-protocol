extends RefCounted
## Tags describe behavior; filters are shared by offers, modifiers and relics.
const MAX_RANK = 10
const EVOLUTION_RANK = 10

static func matches(tags, filter):
	for tag in filter.get("all",[]):
		if tag not in tags: return false
	for tag in filter.get("none",[]):
		if tag in tags: return false
	if filter.get("any",[]).is_empty(): return true
	for tag in filter.any:
		if tag in tags: return true
	return false

static func eligible(weapons, definitions, filter):
	if filter.is_empty(): return true
	for id in weapons:
		if matches(definitions[id].tags,filter): return true
	return false

static func can_add_weapon(weapons,definitions,id):
	if weapons.has(id): return true
	if definitions[id].delivery=="aura":
		for owned in weapons:
			if definitions[owned].delivery=="aura": return false
	return true

static func weapon_data(base):
	var out = base.duplicate(true)
	var tags = {
		"revolver":["WEAPON","PROJECTILE","PHYSICAL","CRITICAL"],
		"club":["WEAPON","MELEE","SWEEP","PHYSICAL","AREA","KNOCKBACK"],
		"frost":["SPELL","OFFENSIVE","PROJECTILE","ICE","FREEZE","CROWD_CONTROL","AREA"],
		"fire":["SPELL","OFFENSIVE","PROJECTILE","FIRE","AREA","EXPLOSION","DOT"],
		"lightning":["SPELL","OFFENSIVE","CHAIN","LIGHTNING","CRITICAL"],
		"shotgun":["WEAPON","PROJECTILE","PHYSICAL","CRITICAL"],
		"orbital":["SPELL","OFFENSIVE","ORBITAL","ARCANE","AREA"],
		"mortar":["WEAPON","GROUND_EFFECT","EXPLOSION","FIRE","AREA"]}
	for id in out:
		out[id].tags = tags[id]
		out[id].delivery = "projectile"
		out[id].icon = ["revolver","club","frost","fire","lightning","shotgun","orbital","mortar"].find(id)
	out.club.merge({"delivery":"melee","radius":115.0,"arc":3.6},true)
	out.lightning.merge({"delivery":"chain","count":3,"range":240.0},true)
	out.orbital.merge({"delivery":"orbital","count":3,"radius":105.0},true)
	out.mortar.merge({"delivery":"ground","radius":130.0},true)
	out.shotgun.merge({"count":6,"velocity":380.0,"lifetime":0.8},true)
	out.revolver.velocity = 680.0
	out.frost.evolved_homing = 2.0
	out.fire.impact_radius = 75.0
	var extra = {
		"spear":["Epoch Lance","Long thrusts pierce a column. High ranks launch shockwaves.","ffd597",46.0,1.1,"THE FIRST SUN","armor",["WEAPON","MELEE","THRUST","PHYSICAL","AREA","KNOCKBACK"],"melee",170.0,1],
		"pyre":["Walking Pyre","A living corona burns everything nearby.","ff9a5c",14.0,0.7,"SOL INVICTUS","damage",["SPELL","OFFENSIVE","AURA","FIRE","DOT","AREA"],"aura",100.0,3],
		"winter":["Stillwinter","Cold pulses slow packs; repeated exposure freezes them.","83e6ff",9.0,0.85,"THE SILENT AGE","area",["SPELL","OFFENSIVE","AURA","ICE","FREEZE","CROWD_CONTROL","AREA"],"aura",125.0,2],
		"miasma":["Black Bloom","A toxic halo stacks poison on nearby enemies.","9ae682",10.0,0.7,"EDEN'S REVENGE","regen",["SPELL","OFFENSIVE","AURA","POISON","DOT","AREA"],"aura",115.0,6],
		"dread":["Ancestor Choir","Spectral pulses drive nearby creatures backwards.","b6a6ff",18.0,1.6,"THE DEAD MARCH","speed",["SPELL","OFFENSIVE","AURA","ARCANE","KNOCKBACK","CROWD_CONTROL","AREA"],"aura",130.0,6],
		"aegis":["Prism Aegis","Recharges a barrier that absorbs damage. High ranks retaliate.","8cdfff",0.0,12.0,"UNBROKEN","armor",["SPELL","DEFENSIVE","ARCANE"],"shield",0.0,2],
		"stasis":["Borrowed Seconds","Periodically slows the ecosystem. High ranks stop it briefly.","c7a7ff",0.0,18.0,"OUTSIDE TIME","haste",["SPELL","UTILITY","CROWD_CONTROL","ARCANE"],"utility",0.0,4]}
	for id in extra:
		var a = extra[id]
		out[id] = {"name":a[0],"desc":a[1],"color":a[2],"damage":a[3],"cooldown":a[4],"evolution":a[5],"requires":a[6],"tags":a[7],"delivery":a[8],"radius":a[9],"icon":a[10]}
	out.spear.arc = 0.55
	out.thunderstorm = {"name":"Thunderstorm","desc":"Calls a two-second storm field. Lightning pounds the marked ground four times.","color":"a3caff","damage":18.0,"cooldown":4.8,"evolution":"HEAVEN'S END","requires":"haste","tags":["SPELL","OFFENSIVE","GROUND_EFFECT","LIGHTNING","AREA"],"delivery":"ground","radius":110.0,"duration":2.0,"icon":4}
	for id in ["pyre","winter","miasma","dread","aegis","stasis"]:
		out[id].pickup_icon = {"pyre":3,"winter":0,"miasma":1,"dread":6,"aegis":5,"stasis":0}[id]
	out.thorns={"name":"Ironbriar","desc":"Thorn bursts. Retaliates when hit. Armor adds damage.","color":"9feeab","damage":25.0,"cooldown":2.4,"evolution":"BRAMBLE CROWN","evolution_desc":"Wider, stronger thorn bursts and retaliation.","requires":"armor","tags":["WEAPON","PHYSICAL","AREA","DEFENSIVE","RETALIATION","KNOCKBACK","CRITICAL"],"delivery":"thorns","radius":115.0,"icon":3}
	out = preload("res://scripts/evolutions.gd").enrich(out)
	out.bastion.tags.append("DEFENSIVE")
	out.ricochet = {"name":"Prism Skipper","desc":"Crystal bolts ricochet between different enemies. Each bounce keeps 85% damage.","color":"81ffd4","damage":24.0,"cooldown":1.05,"count":1,"velocity":570.0,"lifetime":1.6,"bounce":2,"falloff":0.85,"evolution":"PRISM CASCADE","evolution_desc":"Four ricochets per crystal and faster, wider volleys.","requires":"crit","tags":["SPELL","OFFENSIVE","PROJECTILE","ARCANE","CRITICAL"],"delivery":"projectile","icon":3}
	out["return"] = {"name":"Sun Chaser","desc":"Thrown crescents carve outward, then return to you for a second hit.","color":"ffb869","damage":32.0,"cooldown":1.65,"count":1,"velocity":440.0,"lifetime":2.2,"return_after":0.6,"evolution":"SECOND DAWN","evolution_desc":"Wider returning crescents with more blades and a stronger second pass.","requires":"speed","tags":["WEAPON","PROJECTILE","PHYSICAL","AREA","CRITICAL"],"delivery":"projectile","icon":3}
	out.ricochet.tags.append("RICOCHET")
	out["return"].tags.append("RETURNING")
	out.harpoon = {"name":"Fossil Harpoon","desc":"Heavy penetrating fossil lances pin and shove prey backward.","color":"94efe3","damage":48.0,"cooldown":1.3,"count":1,"velocity":680.0,"lifetime":1.3,"evolution":"LEVIATHAN'S ANSWER","requires":"count","tags":["WEAPON","PROJECTILE","PHYSICAL","KNOCKBACK","CRITICAL"],"delivery":"projectile","icon":3,"base_pierce":3}
	out.lantern = {"name":"Hollow Lantern","desc":"Slow seeking spirits burst into a small spectral blast on impact.","color":"c49bff","damage":34.0,"cooldown":1.7,"count":2,"velocity":260.0,"lifetime":2.6,"projectile_homing":4.0,"impact_radius":60.0,"evolution":"CHOIR OF THE LOST","requires":"haste","tags":["SPELL","PROJECTILE","ARCANE","EXPLOSION","AREA","CRITICAL"],"delivery":"projectile","icon":4}
	out.glacier = {"name":"Glacier Wheel","desc":"Frozen chakrams ricochet between separate enemies, building toward a freeze.","color":"a1ecff","damage":24.0,"cooldown":1.1,"count":1,"velocity":430.0,"lifetime":1.6,"bounce":3,"falloff":0.82,"evolution":"POLAR NIGHT","requires":"area","tags":["SPELL","PROJECTILE","ICE","FREEZE","AREA","RICOCHET","CRITICAL"],"delivery":"projectile","icon":3}
	out.sunbow = {"name":"Helios Repeater","desc":"Rapid narrow sun bolts pierce creatures and ignite them.","color":"fff0a1","damage":18.0,"cooldown":0.48,"count":1,"velocity":850.0,"lifetime":0.9,"evolution":"DAYBREAK ENGINE","requires":"damage","tags":["WEAPON","PROJECTILE","FIRE","DOT","CRITICAL"],"delivery":"projectile","icon":4,"base_pierce":2}
	for fresh in ["harpoon","lantern","glacier","sunbow"]:
		out[fresh].projectile_interval=0.055
		if "SPELL" in out[fresh].tags: out[fresh].tags.append("OFFENSIVE")
		out[fresh].targeting="nearest"
		out[fresh].evolution_desc="Greater power, faster attacks and additional projectiles with the weapon's signature behavior."
	for id in out:
		out[id].targeting = out[id].get("targeting","nearest")
		out[id].projectile_interval = 0.035 if out[id].delivery=="projectile" else 0.0
		out[id].max_active = 60 if out[id].delivery=="projectile" else 24
		out[id].terrain_blocks = id in ["revolver","shotgun","lastword","ricochet"]
		out[id].boss_hit_interval = {"orbital":0.4,"bastion":0.4,"mortar":0.65,"supernova":0.1,"thunderstorm":0.2}.get(id,0.0)
	return out

static func passive_data(base):
	var out = base.duplicate(true)
	for id in out:
		out[id].tags = ["PASSIVE"]
		out[id].filter = {}
		out[id].icon = {"damage":4,"haste":4,"area":3,"count":5,"crit":6,"armor":5,"speed":4,"pickup":1,"regen":2,"luck":6}[id]
	out.area.filter = {"any":["AREA"]}
	out.area.desc = "+12% attack area."
	out.count.filter = {"any":["PROJECTILE","CHAIN","ORBITAL","GROUND_EFFECT"]}
	out.count.desc = "+1 projectile, chain target, blade or bombardment"
	return out

const AUGMENTS = {
	"spines":{"name":"Hardened Spines","desc":"+25% thorn damage. +15% thorn area.","tags":["PASSIVE","RETALIATION"],"filter":{"all":["RETALIATION"]},"stats":{"power":0.25,"radius":0.15},"max":3},
	"retribution":{"name":"Quick Retort","desc":"Thorn bursts attack 15% faster.","tags":["PASSIVE","RETALIATION"],"filter":{"all":["RETALIATION"]},"stats":{"haste":0.15},"max":3},
	"velocity":{"name":"Rail Accelerator","desc":"Projectiles travel 30% faster and 20% farther.","tags":["PASSIVE","PROJECTILE"],"filter":{"all":["PROJECTILE"]},"stats":{"velocity":0.3,"lifetime":0.2},"max":3},
	"pierce":{"name":"Through and Through","desc":"Piercing projectiles pass through one more enemy.","tags":["PASSIVE","PROJECTILE"],"filter":{"all":["PROJECTILE"],"none":["EXPLOSION","RICOCHET"]},"stats":{"pierce":1},"max":3},
	"homing":{"name":"Predator Rounds","desc":"Projectiles bend toward prey; each rank improves tracking.","tags":["PASSIVE","PROJECTILE"],"filter":{"all":["PROJECTILE"]},"stats":{"homing":2.5},"max":3},
	"bounce":{"name":"Second Opinion","desc":"Spent projectiles ricochet toward another target.","tags":["PASSIVE","PROJECTILE"],"filter":{"all":["PROJECTILE"]},"stats":{"bounce":1},"max":2},
	"reach":{"name":"Giant's Reach","desc":"Melee range +25%; sweeps gain a wider arc.","tags":["PASSIVE","MELEE"],"filter":{"all":["MELEE"]},"stats":{"radius":0.25,"arc":0.4},"max":3},
	"echo":{"name":"Violent Echo","desc":"Melee attacks repeat after a short delay.","tags":["PASSIVE","MELEE"],"filter":{"all":["MELEE"]},"stats":{"repeat":1},"max":2},
	"conductor":{"name":"Long Conductor","desc":"Chains reach 30% farther and lose less damage per jump.","tags":["PASSIVE","CHAIN"],"filter":{"all":["CHAIN"]},"stats":{"range":0.3,"falloff":0.06},"max":3},
	"fork":{"name":"Branching Fate","desc":"Chain hits can fork; later ranks can revisit a target once.","tags":["PASSIVE","CHAIN"],"filter":{"all":["CHAIN"]},"stats":{"fork":0.22,"rechain":0.12},"max":3},
	"pulse":{"name":"Heart of the Storm","desc":"Auras pulse 20% faster and reach 18% farther.","tags":["PASSIVE","AURA"],"filter":{"all":["AURA"]},"stats":{"haste":0.2,"radius":0.18},"max":4},
	"linger":{"name":"Scorched Earth","desc":"Bombardments leave a damaging zone; +1.5 seconds per rank.","tags":["PASSIVE","GROUND_EFFECT"],"filter":{"all":["GROUND_EFFECT"]},"stats":{"duration":1.5},"max":3},
	"ward":{"name":"Refraction","desc":"Barriers absorb 18 more damage and recharge 20% faster.","tags":["PASSIVE","DEFENSIVE"],"filter":{"all":["DEFENSIVE"],"none":["RETALIATION"]},"stats":{"shield":18.0,"haste":0.2},"max":4},
	"eternity":{"name":"Stolen Eternity","desc":"Utility effects last one second longer and recharge 15% faster.","tags":["PASSIVE","UTILITY"],"filter":{"all":["UTILITY"]},"stats":{"duration":1.0,"haste":0.15},"max":3},
	"sorcery":{"name":"Rift Amplifier","desc":"Offensive spells gain 25% damage.","tags":["PASSIVE","SPELL"],"filter":{"all":["SPELL","OFFENSIVE"]},"stats":{"power":0.25},"max":4},
	"winterbite":{"name":"Brittle World","desc":"Ice effects freeze sooner and last longer.","tags":["PASSIVE","ICE"],"filter":{"all":["ICE"]},"stats":{"status":0.5},"max":3},
	"combustion":{"name":"Unquenched","desc":"Fire and poison deal 25% more damage and linger longer.","tags":["PASSIVE","DOT"],"filter":{"all":["DOT"]},"stats":{"power":0.25,"status":0.6},"max":3}
}

static func modifiers(g,id):
	if g.modifier_cache.has(id): return g.modifier_cache[id]
	var out = {}
	for key in g.augments:
		var d = AUGMENTS[key]
		if not matches(g.C.WEAPONS[id].tags,d.filter): continue
		for stat in d.stats: out[stat] = out.get(stat,0.0)+d.stats[stat]*g.augments[key]
	g.modifier_cache[id] = out
	return out

static func stats(g,id):
	var d = g.C.WEAPONS[id]
	var w = g.weapons[id]
	var m = modifiers(g,id)
	var rank = w.level
	var evo = w.evolved
	var milestones = int(rank>=5)+int(rank>=10 if id=="lightning" else rank>=9)
	var count = d.get("count",1)+g.rank_of("count")+milestones+(2 if evo else 0)
	if d.delivery=="chain": count+=g.research_ranks.get("chains",0)
	elif d.delivery=="projectile": count+=g.research_ranks.get("projectiles",0)+(mini(3,g.level/10) if g.hero==0 else 0)
	var radius = d.get("radius",100.0)*g.area_scale()*(1+m.get("radius",0)+rank*0.025)
	if "AURA" in d.tags: radius *= 1+minf(0.65,g.relic_state.get("aura_growth",0.0))
	var haste = 1+g.rank_of("haste")*0.1+m.get("haste",0)+rank*0.018
	if g.hero==4 and "ARCANE" in d.tags: haste+=minf(0.2,(g.level-1)*0.005)
	var relic_mods = g.Relics.modifiers(g)
	haste += relic_mods.get("haste",0)
	if d.delivery in ["projectile","chain","orbital","ground"]: count += int(relic_mods.get("count",0))
	if g.buffs.get("frenzy",0)>0: haste *= 1.65
	if g.hp<g.max_hp*0.35: haste *= 1+relic_mods.get("low_health_haste",0)
	var result = {"power":(d.damage+(minf(g.armor,25)*4 if "RETALIATION" in d.tags else 0))*(1+(rank-1)*0.30)*(1+m.get("power",0))*g.damage_scale(id)*(1.85 if evo else 1.0),"cooldown":d.cooldown/haste*(0.8 if evo else 1.0),"count":count,"radius":radius,"arc":minf(TAU,d.get("arc",TAU)+m.get("arc",0)+(0.45 if rank>=5 else 0)),"repeat":int(m.get("repeat",0))+int(rank>=7),"pierce":d.get("base_pierce",1)+int(rank>=5)+int(rank>=9)+int(m.get("pierce",0))+(2 if evo else 0),"velocity":d.get("velocity",460.0)*(1+m.get("velocity",0)),"lifetime":d.get("lifetime",1.5)*(1+m.get("lifetime",0)),"homing":m.get("homing",0),"bounce":int(m.get("bounce",0)),"range":d.get("range",240.0)*(1+m.get("range",0)),"falloff":minf(1,0.85+m.get("falloff",0)),"fork":minf(0.85,m.get("fork",0)+(0.3 if rank>=7 else 0)+relic_mods.get("fork",0)),"rechain":m.get("rechain",0),"duration":m.get("duration",0),"shield":25+rank*5+m.get("shield",0),"status":1+m.get("status",0)}

	if evo:
		if "AREA" in d.tags: result.radius *= 1.2
		if "ICE" in d.tags: result.status += 1.0
		if id=="frost": result.homing += 2.0
		if d.delivery=="chain":
			result.range *= 1.2
			result.fork = minf(0.85,result.fork+0.2)
			result.falloff = minf(1,result.falloff+0.08)
		if id=="mortar": result.duration += 2.0
		if id=="thunderstorm": result.duration += 1.0
	if id=="supernova": result.duration += 2.4
	# Independent multiplicative bonuses have ceilings; milestones still
	# change behavior without making every endgame build cover the screen.
	result.count = mini(12,result.count)
	result.radius = minf(300,result.radius)
	result.range = minf(470,result.range)
	result.cooldown = maxf(d.cooldown*0.3,result.cooldown)
	result.duration = minf(5,result.duration)
	return result

static func rank_text(d,rank):
	var behavior = d.delivery
	if behavior=="thorns": return "Stronger thorn bursts. Armor adds +4 base damage per point (up to 25)."
	if behavior=="shield": return "More barrier strength and faster recharge." if rank<7 else "Stronger barrier; breaking it retaliates."
	if behavior=="utility": return "Faster recharge and longer duration." if rank<7 else "Time fractures freeze lesser enemies."
	if rank==10: return "+20% power. Chest evolution ready."+ (" +1 chain target." if d.name=="Stormbinder" else "")
	if rank==5 and d.name=="Stormbinder": return "+1 chain target. More damage."
	if rank==9 and behavior=="projectile": return "Extra explosive projectile." if "EXPLOSION" in d.tags else "Extra projectile + pierce."
	if rank==7:
		return {"melee":"Echo strike + forward shockwave.","chain":"Lightning begins to fork.","aura":"Every fourth pulse erupts at twice its radius.","shield":"Barrier break unleashes retaliation.","utility":"Time effects now freeze lesser enemies."}.get(behavior,"Greater coverage and attack power.")
	if rank==5: return "Expanded coverage, extra strikes and greater power."
	return "More power, faster attacks, greater reach."
