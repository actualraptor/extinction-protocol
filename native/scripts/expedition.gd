extends RefCounted

const C = preload("res://scripts/catalog.gd")
const Rules = preload("res://scripts/combat_rules.gd")
const BossEncounters = preload("res://scripts/boss_encounters.gd")
const BossResistance = preload("res://scripts/boss_resistance.gd")
const BuffRewards = preload("res://scripts/buff_rewards.gd")
var halloween = false
var banishes=1
var banished={}
signal voice_event(event)
signal rite_requested(defeated)
var rite_pending=false
const Combat = preload("res://scripts/combat_engine.gd")
const Pickups = preload("res://scripts/world_pickups.gd")
const Relics = preload("res://scripts/relic_system.gd")
const Bestiary = preload("res://scripts/bestiary.gd")
const Evolutions = preload("res://scripts/evolutions.gd")
const Discoveries = preload("res://scripts/discoveries.gd")
const Maps = preload("res://scripts/expedition_maps.gd")
const StageDefinition = preload("res://scripts/stage_definition.gd")
const StageObjects = preload("res://scripts/stage_objects.gd")
var stage = StageDefinition.stage("cradle")
var stage_objects = []
var collected_stage_objects = {}
var spawn_view = Vector2(1440,900)
var map_id = "cradle"
var campaign_bosses = 0
var charge_ready = 0.0
var research_ranks = {}
var revives = 0
var permanent_luck = 0.0
var daily_plan = {}
var daily_loop = 0
var daily_reward_rng = RandomNumberGenerator.new()
var breakable_clock = 0.0
var breakable_cells = {}
const Daily = preload("res://scripts/daily_challenge.gd")
const Breakables = preload("res://scripts/breakables.gd")
var ledger = preload("res://scripts/combat_ledger.gd").new()
var content_profile = {}
var companions = null
const Extension = preload("res://scripts/content_extension.gd")
var discovered = []
var landmarks = []
var explored = [{},{},{}]
var map_cell = Vector2i(99999,99999)
var waypoint = null
var elite_chest_ready = 0.0
var blood_ready = 0.0
var boundary_ready = 0.0
signal discovered_content(id)
var crowd = preload("res://scripts/crowd.gd").new()
var terrain = preload("res://scripts/terrain_map.gd").new()
var director = preload("res://scripts/horde_director.gd").new()
var augments = {}
var modifier_cache = {}
var buffs = {}
var pickups = []
var pickup_cooldown = 0.0
var shield = 0.0
var echoes = []
var volleys = []
var zones = []
var relic_state = {}
var proc_queue = []
var proc_depth = 0
signal effect(kind, pos, color, size)
signal sound(id)
signal banner(title, subtitle)
signal choice_requested(options, relic)
signal ended(won)

var rng = RandomNumberGenerator.new()
var hero = 0
var mode = "expedition"
var active = true
var choosing = false
var won = false
var finale_defeated = false
var time = 0.0
var pos = Vector2.ZERO
var facing = 1.0
var velocity = Vector2.ZERO
var hp = 110.0
var max_hp = 110.0
var armor = 0.0
var level = 1
var xp = 0.0
var xp_goal = 10.0
var kills = 0
var hits = 0
var score = 0
var amber = 0
var streak = 0
var best_streak = 0
var combo_time = 0.0
var invul = 0.0
var depth = 0
var weapons = {}
var passives = {}
var buff_stacks = {}
var kael_attack = {}
var starter_attack = {}
var relics = []
var relic_stacks = {}
var enemies = []
var shots = []
var gems = []
var gem_recycle_cursor = 0
var hazards = []
var strikes = []
var cache_pos = Vector2(430,40)
var shrine_pos = Vector2(-560,-140)
var shrine_progress = 0.0
var shrine_done = false
var cache_timer = 0.0
var spawn_budget = 0.0
var next_elite = 45.0
var next_boss = 300.0
var next_uid = 0
var grid = {}
var boss = null
var boss_stage = 0
var boss_time = 0.0
var boss_pattern = 0
var boss_timer = 0.0
var core_time = 0.0
var phase = 1
var anchors = []
var event_log = []
var samples = []
var sample_time = 0.0
var damage_total = 0.0
var damage_by_weapon = {}
var relic_timers = {"storm":0.0,"clock":0.0,"magnet":0.0,"boots":0.0}
var base_damage = 1.0
var fortune = 1.0
var peak_enemies = 0
var enemy_frame = 0
var options = []
var option_is_relic = false
const BACKPACK_SLOTS = 5
const BUFF_SLOTS = 8
const RELIC_SLOTS = 8
const RIFT_CHARGE_SECONDS = 6.0
const PORTAL_CHARGE_SECONDS = 0.325
var hostile_shots = []
var relic_chests = []
var rerolls = 3
var reroll_exclude = []
var boss_corpses=[]
var portal = null
var linger = 0.0
var portal_charge = 0.0
var transition_time = 0.0
var ground_attack_ready = 0.0
var brood_queue = []
var encounter_epoch = 0
var extinction_timeout = false
var death_reason = "The ecosystem won."

func setup(character, run_mode, research = {}, seed_value = 0, selected_map = "cradle"):
	Extension.install(C)
	starter_attack.clear()
	map_id = selected_map if Maps.DATA.has(selected_map) else "cradle"
	terrain.layout = Maps.DATA[map_id].layout
	hero = character
	mode = run_mode
	research_ranks = research.duplicate(true) if mode=="expedition" else {}
	revives = int(research_ranks.get("revive",0))
	rerolls = 3+int(research_ranks.get("reroll",0))
	permanent_luck = research_ranks.get("luck",0)*0.01+research_ranks.get("fortune",0)*0.05
	if mode=="daily":
		daily_plan=Daily.plan(seed_value)
		daily_reward_rng.seed=seed_value ^ 819273
		hero=daily_plan.hero
		map_id=daily_plan.map
		terrain.layout=Maps.DATA[map_id].layout
	if seed_value == 0: rng.randomize()
	else: rng.seed = seed_value
	terrain.seed_value = int(rng.seed)%2147483647
	collected_stage_objects.clear()
	stage = StageDefinition.stage(map_id)
	terrain.configure(stage,depth)
	pos = terrain.open_position(stage.spawn)
	StageObjects.setup(self)
	permanent_luck += stage.modifiers.get("luck",0.0)
	cache_pos = terrain.open_position(cache_pos)
	shrine_pos = terrain.open_position(shrine_pos)
	if Extension.is_profile(self): companions = preload("res://scripts/companion_system.gd").new()
	var data = C.HEROES[hero]
	max_hp = data.hp + (research.get("vitality",0)*10 if mode == "expedition" else 0)
	hp = max_hp
	armor = data.armor+research_ranks.get("armor",0)
	base_damage = 1.0 + (research.get("power",0)*0.03 if mode == "expedition" else 0)
	fortune = 1.0+research_ranks.get("fortune",0)*0.05+research_ranks.get("greed",0)*0.05
	weapons[data.weapon] = {"level":1,"evolved":false,"timer":0.1}
	log_event("start",{"hero":data.name,"seed":rng.seed,"mode":mode})
	if mode == "safari":
		time = 900
		depth = 2
		level = 40
		for id in (["u00","u01","u02","u03","u09"] if companions!=null else [data.weapon,"fire","lightning","orbital","mortar","frost"]):
			if weapons.size()>=BACKPACK_SLOTS: break
			weapons[id] = {"level":10,"evolved":true,"timer":0.1}
		passives = {"damage":5,"haste":4,"count":2,"area":3,"speed":2,"crit":4,"armor":3}
		max_hp += 36
		hp = max_hp
		armor += 6
		relics = ["frost","clock","glass"]
		spawn_boss(3)

func log_event(type, data = {}):
	if event_log.size() < 3000:
		var entry = data.duplicate()
		entry["at"] = snappedf(time,0.01)
		entry["type"] = type
		event_log.append(entry)

func rank_of(id): return passives.get(id,0)
func buff_power(id): return BuffRewards.power(self,id)
func content_allowed(category,id):
	if not Extension.allowed(self,category,id):return false
	if companions!=null:return true
	return mode=="daily" or content_profile.is_empty() or Discoveries.allowed(content_profile,category,id)
func configure_content(profile):
	content_profile = profile.duplicate(true)
	content_profile.hero = hero
	discovered = profile.get("discoveries",[]).duplicate()
	landmarks = Discoveries.landmarks(self)

func update_exploration():
	var cell = Vector2i(floor(pos.x/160),floor(pos.y/160))
	if cell!=map_cell:
		map_cell = cell
		for x in range(-2,3):
			for y in range(-2,3):
				if x*x+y*y<=6: explored[depth][cell+Vector2i(x,y)] = true
	for marker in landmarks:
		if not marker.found and pos.distance_squared_to(marker.p)<65*65:
			marker.found = true
			discovered.append(marker.id)
			amber += 20
			Discoveries.field_reward(self,marker.id)
			banner.emit("DISCOVERY / "+marker.name,"UNLOCKED / AVAILABLE IN FUTURE RUNS" if Discoveries.ENTRIES[marker.id].cost==0 else "RECORDED IN THE ARCHIVE / UNLOCK WITH AMBER BETWEEN RUNS")
			sound.emit("loot")
			effect.emit("evolve",marker.p,Color("83ddff"),220)
			log_event("discovery",{"id":marker.id})
			discovered_content.emit(marker.id)
func area_scale(): return 1.0 + buff_power("area")*0.12
func speed(): return stage.modifiers.get("player_speed",1.0)*C.HEROES[hero].speed*(1+buff_power("speed")*0.08)*(1+minf(0.15,(level-1)*0.005) if hero==3 else 1.0)
func trait_text():
	if companions!=null:return "SOULS / %s · UNDEAD / %s · NEXT / %s"%[int(companions.souls),companions.units.size(),int(companions.next_threshold)]
	match hero:
		0: return "GUNSLINGER / +%s projectiles (one per 10 levels; max 3)"%mini(3,level/10)
		1: return "FIRST HUNTER / +%s%% physical damage (1%% per level; max 50%%)"%mini(50,level-1)
		2: return "RIFTWALKER / +%s%% spell damage (1%% per level; max 40%%)"%mini(40,level-1)
		3: return "POLAR HUNTER / +%.1f%% movement (0.5%% per level; max 15%%)"%minf(15,(level-1)*0.5)
	return "ASTRONOMER / +%.1f%% arcane attack speed (0.5%% per level; max 20%%)"%minf(20,(level-1)*0.5)
static func crit_curve(raw):
	# Original chance curve: full value through 100%, then 65%, 40%, 25%.
	raw = maxf(0.0,raw)
	return minf(raw,1.0) + clampf(raw-1.0,0.0,1.0)*.65 + clampf(raw-2.0,0.0,2.0)*.40 + maxf(raw-4.0,0.0)*.25
func crit_chance(): return crit_curve(C.HEROES[hero].crit+buff_power("crit")*0.07+research_ranks.get("critical",0)*0.02)
func roll_crit_tier(chance): return floori(chance)+int(rng.randf()<fposmod(chance,1.0))
static func crit_color(tier):
	if tier<=0:return Color.WHITE
	if tier<=4:return Color(["ffe564","ff963f","f06bdf","69eaff"][tier-1])
	return Color.from_hsv(fposmod((tier-5)*.137+.13,1.0),.45,1.0)
func damage_scale(id):
	var tags = C.WEAPONS.get(id,{}).get("tags",[])
	var growth=1.0+minf(0.5,(level-1)*0.01) if hero==1 and "PHYSICAL" in tags else 1.0+minf(0.4,(level-1)*0.01) if hero==2 and "SPELL" in tags else 1.0
	return growth*base_damage*(1+buff_power("damage")*0.14)*(1+Relics.modifiers(self).get("damage",0))*(1.2 if (hero==2 and "SPELL" in tags) or (hero==3 and "ICE" in tags) or (hero==4 and "ARCANE" in tags) else 1.0)*(1+relic_state.get("momentum",0.0)*Relics.modifiers(self).get("momentum_damage",0))
func effective_damage(amount, health): return minf(maxf(amount,0),maxf(health,0))
func rooted(e): return not e.boss and not e.anchor and (e.get("frozen",0)>0 or buffs.get("freeze",0)>0)
func linger_pressure(): return maxf(0.0,linger-20.0) if portal!=null else 0.0
func linger_health(): return pow(2.0,minf(30.0,linger_pressure()/25.0))
func linger_damage(): return 1.0+linger_pressure()/25.0
func elite_interval(): return maxf(8.0,(45-depth*7)*stage.modifiers.get("elite_interval",1.0)/(1.0+linger_pressure()/20.0))
func threat(): return (1+time/210.0)*(1+depth*0.25)*linger_health()*pow(2.0,minf(daily_loop,25))

func tick(dt, direction):
	if not active or choosing: return
	if transition_time>0:
		transition_time = maxf(0,transition_time-dt)
		return
	time += dt
	if portal!=null:
		var old_pressure = linger_pressure()
		linger += dt
		if old_pressure<=0 and linger_pressure()>0:
			banner.emit("THE WORLD CLOSES IN", "Enemy health doubles every 25 seconds. Take the rift.")
		if linger_pressure()>0:
			next_elite=minf(next_elite,time+elite_interval())
		portal_charge = portal_charge+dt if pos.distance_to(portal)<48 and linger>2 else 0.0
		if portal_charge>=PORTAL_CHARGE_SECONDS:
			enter_portal()
			return
	Pickups.update(self,dt)
	terrain.update(dt,pos)
	velocity = direction.limit_length()*speed()
	if terrain.kind(terrain.cell(pos))==2: velocity *= 0.65
	pos = terrain.move(pos,velocity*dt)
	update_exploration()
	Breakables.update(self,dt)
	if terrain.kind(terrain.cell(pos))==3: hurt(10,"Crossed an unstable lava vent")
	if not active: return
	if absf(direction.x)>0.05: facing = signf(direction.x)
	invul = maxf(0,invul-dt)
	combo_time = maxf(0,combo_time-dt)
	if combo_time == 0: streak = 0
	hp = minf(max_hp,hp+(buff_power("regen")*0.35+research_ranks.get("recovery",0)*0.15)*dt)
	for key in relic_timers: relic_timers[key] = maxf(0,relic_timers[key]-dt)
	director.update(self,dt)
	var spawn_rate = 2.4+time/18.0 if time<120 else 3+time/14.0+depth*5
	spawn_rate *= lerpf(0.65,1.0,clampf(time/120.0,0.0,1.0))
	spawn_rate *= stage.modifiers.get("density",1.0)*(1+minf(5,linger_pressure()/12.0))
	spawn_budget = minf(12,spawn_budget+dt*spawn_rate*(0.4 if boss != null else 1.0))
	while spawn_budget >= 1:
		spawn_budget -= 1
		if enemies.size()<director.cap(self): spawn_enemy()
	if time >= next_elite:
		next_elite = time+elite_interval()
		if enemies.size()<director.cap(self): spawn_enemy(true)
	if boss == null and portal==null and time >= next_boss and boss_stage < 3:
		spawn_boss(boss_stage+1)
	update_enemies(dt)
	if not active or choosing: return
	build_grid()
	Relics.update(self,dt)
	if not active or choosing: return
	if companions!=null:companions.update(self,dt)
	preload("res://scripts/remnant_system.gd").update(self,dt)
	if not active:return
	update_weapons(dt)
	if not active or choosing: return
	update_shots(dt)
	if not active or choosing: return
	update_hostile_shots(dt)
	if not active or choosing: return
	update_hazards(dt)
	if not active or choosing: return
	update_boss(dt)
	if not active or choosing: return
	if companions!=null:
		# Reconcile after knockbacks, summoned movement and boss actions too.
		companions.collision.build(companions.units)
		for enemy in enemies:
			if not enemy.dead and not enemy.anchor and not enemy.get("breakable",false):
				enemy.p=companions.collision.block_enemy(enemy,enemy.p,enemy.p)
	update_gems(dt)
	update_objectives(dt)
	peak_enemies = maxi(peak_enemies,enemies.size())
	cache_timer = maxf(0,cache_timer-dt)
	sample_time -= dt
	if sample_time <= 0:
		sample_time = 2
		if samples.size()<1000: samples.append({"at":snappedf(time,0.1),"hp":snappedf(hp,0.1),"level":level,"kills":kills,"enemies":enemies.size(),"x":roundf(pos.x),"y":roundf(pos.y)})
	if xp >= xp_goal and active and not choosing and mode != "safari":
		xp -= xp_goal
		level += 1
		voice_event.emit("level_up")
		xp_goal = 9+pow(level,1.45)*4.8
		open_choices(false)

func spawn_position(angle):
	var half = spawn_view*0.5+Vector2(110,135)
	for attempt in range(16):
		var direction = Vector2.from_angle(angle+attempt*0.63)
		var distance = minf(half.x/maxf(0.001,absf(direction.x)),half.y/maxf(0.001,absf(direction.y)))+rng.randf_range(35,120)
		var candidate = pos+direction*distance
		if terrain.bounds.grow(-128).has_point(candidate):
			var safe = terrain.open_position(candidate)
			if absf(safe.x-pos.x)>spawn_view.x/2+70 or absf(safe.y-pos.y)>spawn_view.y/2+90: return safe
	return terrain.open_position(pos+Vector2(0,half.y+100))

func spawn_enemy(elite = false, at = null, kind_override = -1, announce = true):
	var angle = rng.randf()*TAU
	var p = spawn_position(angle) if at == null else at
	var composition = Maps.pool(map_id,depth,time)
	var kind = composition[rng.randi_range(0,composition.size()-1)] if kind_override<0 else kind_override
	if Bestiary.DATA[kind].role=="charge":
		var chargers=0
		for creature in enemies:
			if not creature.dead and creature.get("role","")=="charge": chargers+=1
			if chargers>=5+depth: break
		if chargers>=5+depth:
			var alternatives=composition.filter(func(k):return Bestiary.DATA[k].role!="charge")
			if not alternatives.is_empty(): kind=alternatives[rng.randi_range(0,alternatives.size()-1)]
	var species = Bestiary.DATA[kind]
	if species.role not in ["fly","phase"]: p = terrain.open_position(p)
	var health = species.hp*stage.modifiers.get("enemy_health",1.0)*threat()*(7 if elite else 1)*(1+Relics.modifiers(self).get("enemy_health",0))
	var mutated = time>420 and rng.randf()<0.13
	if mutated: health *= 2.2
	next_uid += 1
	var e = {"uid":next_uid,"p":p,"hp":health,"max_hp":health,"kind":kind,"role":species.role,"elite":elite,"mutated":mutated,"boss":false,"anchor":false,"size":species.size*(1.7 if elite else 1.0)*(1.25 if mutated else 1.0),"speed":species.speed*stage.modifiers.get("enemy_speed",1.0)*(1+minf(time/2000,0.6))*(1+minf(1.0,linger_pressure()/80.0)),"flash":0.0,"slow":0.0,"burn":0.0,"burn_tick":0.0,"attack":rng.randf_range(3,8),"dead":false}
	enemies.append(e)
	if elite and announce: banner.emit("MUTATION DETECTED","An apex hunter enters the field")
	return e

func update_enemies(dt):
	if companions!=null:companions.collision.build(companions.units)
	enemy_frame += 1
	crowd.build(enemies)
	for e in enemies:
		if e.dead or e.get("breakable",false): continue
		if not e.boss and not e.anchor and not e.get("encounter_guard",false) and e.p.distance_squared_to(pos)>pow(maxf(2400,spawn_view.length()*0.9),2):
			e.dead = true
			continue
		var step = dt
		# Under extreme population pressure, stagger ordinary creature AI at
		# 15 Hz. Player, attacks, bosses and contact rendering retain 30 Hz.
		if not e.boss and not e.anchor and not e.elite and (enemies.size()>1000 or e.p.distance_squared_to(pos)>650*650):
			if (e.uid+enemy_frame)%2==0: continue
			step *= 2
		e.frozen = maxf(0,e.get("frozen",0.0)-step)
		e.flash = maxf(0,e.flash-step)
		e.slow = maxf(0,e.slow-step)
		e.burn = maxf(0,e.burn-step)
		e.poison_time = maxf(0,e.get("poison_time",0.0)-step)
		if e.poison_time>0:
			e.poison_tick = e.get("poison_tick",0.0)-step
			if e.poison_tick<=0:
				e.poison_tick = 0.5
				hit(e,e.get("poison",1.0)*e.get("poison_damage",5.0),e.get("poison_source","miasma"),false,false)
		else: e.poison = 0.0
		if e.burn>0:
			e.burn_tick -= step
			if e.burn_tick <= 0:
				e.burn_tick = 0.5
				hit(e,e.get("burn_damage",8.0),e.get("burn_source","fire"),false,false)
		if e.dead or e.anchor or e.get("boss_prop",false): continue
		if not e.boss and (buffs.get("freeze",0)>0 or e.frozen>0): continue
		var delta = pos-e.p
		var move = delta.normalized()
		if not e.boss:
			var slow_scale = 0.48 if e.slow>0 or buffs.get("slow",0)>0 else 1.0
			var role = e.get("role","chase")
			if e.get("spit_wait",0)>0:
				e.spit_wait -= step
				if e.spit_wait<=0 and boss==null and hostile_shots.size()<60:
					hostile_shots.append({"p":e.p,"v":e.spit_dir*270,"life":3.0,"damage":12+depth*5})
					sound.emit("venom_spit")
				continue
			if role=="charge":
				e.attack -= step
				if e.get("charge_wait",0)>0:
					e.charge_wait -= step
					if e.charge_wait<=0: e.charge_time = 0.7
					continue
				if e.get("charge_time",0)>0:
					e.charge_time -= step
					e.p = crowd.move(self,e,e.charge_dir*390*step,step)
					if e.p.distance_to(pos)<e.size+15: hurt(22+depth*7,"Tuskbreaker charge")
					continue
				if e.attack<=0 and delta.length()<430 and time>=charge_ready:
					charge_ready=time+maxf(0.75,1.15-depth*0.15)
					e.attack = 7.0
					e.charge_wait = 0.9
					e.charge_dir = move
					continue
			if role in ["fly","phase"]:
				move = move.rotated(sin(time*2+e.uid)*0.5)
				e.p = crowd.move(self,e,move*e.speed*slow_scale*step,step)
			else:
				e.nav_timer = e.get("nav_timer",0.0)-step
				if e.nav_timer<=0:
					e.nav_timer = 0.15+float(e.uid%5)*0.012
					e.nav = terrain.direction(e.p,pos,e.uid)
				move = e.get("nav",move)
				if role=="spit" and delta.length()<250: move *= -0.25
				var ground = terrain.kind(terrain.cell(e.p))
				e.p = crowd.move(self,e,move*e.speed*slow_scale*(0.65 if ground==2 else 1.0)*step,step)
				if ground==3:
					e.hp -= e.max_hp*0.08*step
					if e.hp<=0: kill(e)
			if role in ["spit","slam"] or e.elite:
				e.attack -= step
				# Shared cooldown leaves actual breathing room regardless of
				# how many casters spawned. Telegraphs never chase the player.
				if e.attack<=0 and delta.length()<520 and time>=ground_attack_ready and boss==null:
					ground_attack_ready = time+(4.0 if depth==1 else 3.0)
					e.attack = 8.0
					if role=="spit":
						e.spit_wait = 0.65
						e.spit_dir = (pos-e.p).normalized()
					else: add_hazard("circle",pos if role!="slam" else e.p,0,42 if role!="slam" else 85,1.65,0.3,12+depth*5)
		if e.boss and boss_stage<3 and e.get("action","recover")=="recover" and e.get("reform",0)<=0:
			# Recovery is a mobile pursuit, while committed tells stay anchored.
			var speeds={"thorn":76.0,"basalt":58.0,"hunt":112.0,"aurora":88.0,"warden":66.0,"bloom":52.0}
			if delta.length()>e.size+45:
				var chase=terrain.direction(e.p,pos,e.uid)
				var start=e.p
				e.p=terrain.move(e.p,chase*speeds.get(e.get("identity","thorn"),76.0)*(1.12 if phase==2 else 1.0)*step,32)
				if companions!=null:e.p=companions.collision.block_enemy(e,start,e.p)
				e.aim=chase
			delta=pos-e.p
		# Boss contact hurts the player, but never shoves the boss.
		if delta.length()<e.size+15:
			hurt(16+depth*8+(18 if e.elite else 0),"Overwhelmed by the horde")
			if not e.boss and not e.anchor and not e.get("boss_prop",false):
				if e.kind==2: e.p -= move*15
				else: e.p = terrain.move(e.p,-move*15,10)
	enemies = enemies.filter(func(e): return not e.dead)
	var hatchlings = brood_queue
	brood_queue = []
	for p in hatchlings:
		if enemies.size()<director.cap(self):
			var child = spawn_enemy(false,p,4)
			child.hp *= 0.4
			child.max_hp = child.hp
			child.size = 11

func update_hostile_shots(dt):
	for shot in hostile_shots:
		shot.life -= dt
		if shot.get("arc",false):
			shot.p = shot.start.lerp(shot.target,clampf(1-shot.life/shot.flight,0,1))
			if shot.life<=0:
				BossEncounters.hazard(self,"circle",shot.target,0,55,0.1,0.25,shot.damage,shot.theme)
				if shot.theme=="bloom" and boss!=null: BossEncounters.pod(self,shot.target,"growth",7.0)
				sound.emit("impact_fire" if shot.theme=="basalt" else "miasma")
			continue
		var scale_value = 0.0 if buffs.get("freeze",0)>0 else 0.48 if buffs.get("slow",0)>0 else 1.0
		var travel = shot.v*dt*scale_value
		# Swept substeps provide wall cover and prevent tunnelling on slow frames.
		var steps = maxi(1,ceili(travel.length()/12))
		for i in range(steps):
			var old = shot.p
			shot.p += travel/steps
			if not terrain.walkable(shot.p,7):
				shot.life = 0
				break
			if Geometry2D.get_closest_point_to_segment(pos,old,shot.p).distance_squared_to(pos)<21*21:
				hurt(shot.damage,shot.get("reason","Struck by venom spit"))
				shot.life = 0
				break
	hostile_shots = hostile_shots.filter(func(s):return s.life>0)

func cell(p): return Vector2i(floori(p.x/96),floori(p.y/96))
func build_grid():
	grid.clear()
	for e in enemies:
		if e.dead: continue
		var key = cell(e.p)
		if not grid.has(key): grid[key] = []
		grid[key].append(e)
func nearby(p, radius):
	var out = []
	var a = cell(p-Vector2.ONE*(radius+125))
	var b = cell(p+Vector2.ONE*(radius+125))
	for x in range(a.x,b.x+1):
		for y in range(a.y,b.y+1):
			for e in grid.get(Vector2i(x,y),[]):
				if not e.dead and e.p.distance_squared_to(p)<pow(radius+e.size,2): out.append(e)
	return out
func nearest(p, radius = 680.0, excluded = []):
	var best = null
	var prop = null
	var prop_distance = radius*radius
	var d = radius*radius
	for e in nearby(p,radius):
		if e.uid in excluded: continue
		var dist = e.p.distance_squared_to(p)
		if e.get("breakable",false):
			if dist<prop_distance: prop=e;prop_distance=dist
			continue
		if dist<d:
			d = dist
			best = e
	return best if best!=null else prop

func weapon_target(id):
	var d = C.WEAPONS[id]
	var method = d.get("targeting","nearest")
	if method=="nearest" and not d.get("terrain_blocks",false): return nearest(pos)
	var candidates = nearby(pos,680)
	var hostiles = candidates.filter(func(e):return not e.get("breakable",false))
	if not hostiles.is_empty(): candidates=hostiles
	candidates.sort_custom(func(a,b): return a.hp>b.hp if method=="strongest" else a.hp<b.hp if method=="weakest" else a.p.distance_squared_to(pos)<b.p.distance_squared_to(pos))
	if method=="random" and not candidates.is_empty(): return candidates[rng.randi_range(0,candidates.size()-1)]
	var checked = 0
	for e in candidates:
		if not d.get("terrain_blocks",false) or terrain.line_clear(pos,e.p): return e
		checked += 1
		if checked>=8: break
	return null

func update_weapons(dt):
	Combat.update(self,dt)

func shoot(id,p,dir,damage,speed_value,life,pierce):
	if shots.size()>=240: return
	var d = C.WEAPONS[id]
	var active_count = 0
	for shot in shots:
		if shot.id==id: active_count += 1
	if active_count>=d.get("max_active",60): return
	# Aim and collision share ground-space coordinates. A fixed upward spawn
	# offset made horizontal/downward shots pass beside their chosen target.
	if id in ["revolver","shotgun","lastword"]: effect.emit("muzzle",p,Color("ffe4a0"),dir.angle())
	var m = Rules.modifiers(self,id)
	var evolved = weapons.get(id,{}).get("evolved",false)
	var homing = m.get("homing",0.0)+d.get("projectile_homing",0.0)+(d.get("evolved_homing",0.0) if evolved else 0.0)
	var penetration = 8+int(m.get("pierce",0)) if id=="return" else pierce
	shots.append({"id":id,"p":p,"old":p,"v":dir*speed_value,"damage":damage,"life":life,"pierce":penetration,"return_pierce":penetration,"return_power":1.25 if evolved else 1.0,"hit":[],"homing":homing,"bounce":int(m.get("bounce",0))+d.get("bounce",0)+(2 if id in ["ricochet","glacier"] and evolved else 0),"seek":0.0,"target":null,"age":0.0,"returning":false})

	return shots.back()

func update_shots(dt):
	var impact_budget = 16
	for shot in shots:
		shot.life -= dt
		shot.old = shot.p
		shot.age = shot.get("age",0.0)+dt
		if C.WEAPONS[shot.id].has("return_after") and shot.age>=C.WEAPONS[shot.id].return_after:
			if not shot.get("returning",false):
				shot.returning = true
				shot.hit.clear()
				shot.pierce = shot.return_pierce
				shot.damage *= shot.return_power
			shot.v = (pos-shot.p).normalized()*maxf(560,speed()*1.6)
			if shot.p.distance_to(pos)<24: shot.life = 0
		if shot.homing>0 and not shot.get("returning",false):
			shot.seek -= dt
			if shot.seek<=0:
				shot.seek = 0.15
				shot.target = nearest(shot.p,220,shot.hit)
			if shot.target!=null and not shot.target.dead:
				shot.v = shot.v.lerp((shot.target.p-shot.p).normalized()*shot.v.length(),minf(1,dt*shot.homing))
		shot.p += shot.v*dt
		if C.WEAPONS[shot.id].get("terrain_blocks",false) and not terrain.line_clear(shot.old,shot.p):
			shot.life = 0
			continue
		var width = 9*area_scale() if "AREA" in C.WEAPONS[shot.id].tags else 9
		var travel = shot.p-shot.old
		var candidates = nearby((shot.p+shot.old)*0.5,travel.length()*0.5+width)
		candidates.sort_custom(func(a,b):return a.p.distance_squared_to(shot.old)<b.p.distance_squared_to(shot.old))
		for e in candidates:
			if e.uid in shot.hit: continue
			var closest = Geometry2D.get_closest_point_to_segment(e.p,shot.old,shot.p)
			if closest.distance_squared_to(e.p)>pow(width+e.size,2): continue
			shot.hit.append(e.uid)
			if impact_budget>0:
				impact_budget -= 1
				effect.emit("impact_"+shot.id,e.p,Color(C.WEAPONS[shot.id].color),32)
				sound.emit("impact_frost" if shot.id=="frost" else "impact_fire" if shot.id=="fire" else "impact_metal")
			if C.WEAPONS[shot.id].has("impact_radius"):
				blast(shot.p,C.WEAPONS[shot.id].impact_radius*area_scale()*(1.35 if weapons.get(shot.id,{}).get("evolved",false) else 1.0),shot.damage,shot.id)
				shot.life = 0
			else:
				var dealt=hit(e,shot.damage,shot.id)
				if companions!=null and shot.has("companion"):companions.credit(shot.companion,dealt,e.dead)
				if shot.id=="harpoon" and not e.boss and not e.anchor and not rooted(e): e.p=terrain.move(e.p,shot.v.normalized()*35)
			shot.pierce -= 1
			if shot.pierce<=0:
				shot.life = 0
				if shot.bounce>0:
					for other in nearby(shot.p,220):
						if other.uid not in shot.hit:
							shot.v = (other.p-shot.p).normalized()*shot.v.length()
							shot.bounce -= 1
							shot.damage *= C.WEAPONS[shot.id].get("falloff",1.0)
							shot.pierce = 1
							shot.life = 0.7
							shot.p = closest
							break
				# A ricochet starts a new segment next tick; it cannot also hit
				# targets along the remainder of its old direction.
				break
			if shot.life<=0: break
	shots = shots.filter(func(s): return s.life>0)

func blast(p,radius,damage,id,hit_channel = "impact"):
	var tags = C.WEAPONS.get(id,{}).get("tags",[])
	var visual = "frost" if "ICE" in tags else "lightning" if "LIGHTNING" in tags else "orbital" if "ARCANE" in tags else "fire" if "FIRE" in tags else id
	effect.emit("blast_"+visual,p,Color(C.WEAPONS.get(id,{"color":"ffad68"}).color),radius)
	for e in nearby(p,radius):
		hit(e,damage,id,true,true,hit_channel)
		if not e.boss and not e.anchor and not e.get("boss_prop",false) and not rooted(e) and "KNOCKBACK" in tags: e.p = terrain.move(e.p,(e.p-p).normalized()*35)

func hit(e, amount, id, can_crit = true, apply_status = true, hit_channel = "impact"):
	if not active or e.dead: return 0.0
	if e.boss and boss_stage==2 and e.get("reform",0)>0: return 0.0
	# One large target must not take every overlapping orbital/mortar pulse.
	var interval = C.WEAPONS.get(id,{}).get("boss_hit_interval",0.0)
	if e.boss and interval>0:
		if not e.has("pulse_times"): e.pulse_times = {}
		# Low-power lingering/status ticks cannot consume a shell's impact slot.
		# Overlapping fields still share one bounded repeat allowance per weapon.
		var pulse_key = id
		if id in ["mortar","supernova"]:
			pulse_key += ":"+(hit_channel if apply_status else "status")
		if time-e.pulse_times.get(pulse_key,-100.0)<interval: return 0.0
		e.pulse_times[pulse_key] = time
	var crit_tier = roll_crit_tier(crit_chance()) if can_crit else 0
	var critical = crit_tier>0
	if critical: amount *= pow(1.9,crit_tier)
	if e.slow>0: amount *= 1+Relics.modifiers(self).get("chilled_damage",0)
	if e.boss and boss_stage == 3:
		if boss_time<3 or boss.get("reform",0)>0: return 0.0
	var damage_tags = C.WEAPONS.get(id,{}).get("tags",[])
	if not e.boss and not e.anchor:
		if e.get("role","")=="armor" and "PHYSICAL" in damage_tags: amount *= 0.8
		for tag in Bestiary.DATA[e.kind].get("resists",{}):
			if tag in damage_tags: amount *= Bestiary.DATA[e.kind].resists[tag]
	if companions!=null:
		amount*=1+e.get("dread",0.0)
		e.unit_hit=id.begins_with("u")
	var hit_damage=maxf(0,amount*BossResistance.multiplier(self,e))
	var dealt = effective_damage(hit_damage,e.hp)
	if e.boss and boss_stage==2 and phase==1:
		dealt = minf(dealt,maxf(0,e.hp-e.max_hp*0.5))
	if e.boss and boss_stage == 3 and phase<3:
		var gate = e.max_hp*(0.67 if phase==1 else 0.34)
		dealt = minf(dealt,maxf(0,e.hp-gate))
	e.hp -= dealt
	damage_total += dealt
	damage_by_weapon[id] = damage_by_weapon.get(id,0.0)+dealt
	ledger.record(id,dealt,time)
	e.flash = 0.1
	if id=="lightning" and (e.uid%3==0 or e.boss): effect.emit("impact_lightning",e.p,Color(C.WEAPONS[id].color),45)
	var tags = C.WEAPONS.get(id,{}).get("tags",[])
	if id=="whiteout" and apply_status and proc_depth==0 and e.get("frozen",0)>0 and time>=relic_state.get("whiteout_next",0):
		e.frozen = 0
		relic_state.whiteout_next = time+0.25
		if proc_queue.size()<32: proc_queue.append({"p":e.p,"id":id,"damage":minf(450,amount*0.5)})
		effect.emit("blast_frost",e.p,Color("d9faff"),95)
		sound.emit("impact_frost")
	if apply_status and "ICE" in tags:
		e.slow = 2.5
		e.chill = e.get("chill",0.0)+Rules.modifiers(self,id).get("status",0.0)+1+(1 if weapons.get(id,{}).get("evolved",false) else 0)
		if e.chill>=3:
			e.frozen = (1.8 if weapons.get(id,{}).get("evolved",false) else 1.2) if not e.boss and not e.anchor else 0.0
			e.chill = 0
	if apply_status and "FIRE" in tags:
		if e.get("frozen",0)>0 and time>=e.get("thermal_next",0.0) and time>=relic_state.get("thermal_next",0.0):
			e.frozen = 0.0
			e.thermal_next = time+1.0
			relic_state.thermal_next = time+0.15
			if proc_depth==0 and proc_queue.size()<32:
				proc_queue.append({"p":e.p,"id":"fire","damage":minf(300,amount*0.65)})
			effect.emit("thermal",e.p,Color("b9eeff"),90)
			sound.emit("thermal")
		if e.burn<=0: e.burn_tick = float(e.uid%30)/60.0
		e.burn = 3.0+Rules.modifiers(self,id).get("status",0.0)+(2 if weapons.get(id,{}).get("evolved",false) else 0)
		e.burn_damage = maxf(e.get("burn_damage",0.0),amount*0.12)
		e.burn_source = id
	if apply_status and "POISON" in tags:
		if e.get("poison_time",0.0)<=0: e.poison_tick = float(e.uid%30)/60.0
		e.poison = minf(6,e.get("poison",0.0)+1)
		e.poison_time = 4.0+Rules.modifiers(self,id).get("status",0.0)+(2 if weapons.get(id,{}).get("evolved",false) else 0)
		e.poison_damage = amount*0.1
		e.poison_source = id
	e.last_critical = critical
	e.last_crit_tier = crit_tier
	if critical and Relics.modifiers(self).has("critical_chain") and relic_timers.storm<=0:
		relic_timers.storm = Relics.modifiers(self).critical_chain_cooldown
		for other in nearby(e.p,180):
			if other.uid != e.uid:
				strikes.append({"a":e.p,"b":other.p,"life":0.2,"color":Color("caadff")})
				hit(other,amount*Relics.modifiers(self).critical_chain,"relic",false)
				break
	if e.elite or e.boss or critical:
		effect.emit("crit_number_%s"%crit_tier if critical else "number",e.p,crit_color(crit_tier) if critical else Color.WHITE,dealt if e.boss else hit_damage)
		if critical: effect.emit("crit",e.p,crit_color(crit_tier),crit_tier)
	if e.hp<=0: kill(e)
	elif e.boss and boss_stage==2 and phase==1 and e.hp<=e.max_hp*0.5+0.1:
		phase = 2
		boss.reform = 1.8
		boss_timer = 0
		var phase_names={"basalt":["THE CARAPACE BREAKS","MOLTEN FISSURES / MORE FALLING ROCKS"],"aurora":["THE VEIL THINS","WATCH THE BREATH / FLANK THE SPECTER"],"bloom":["THE BLOOM AWAKENS","BREAK THE PODS / DENY THE BROOD"]}
		var announcement=phase_names.get(boss.get("identity",""),["THE HUNT INTENSIFIES","WATCH THE NEXT WINDUP"])
		banner.emit(announcement[0],announcement[1])
		effect.emit("evolve",boss.p,Color(BossEncounters.COLORS.get(boss.get("identity",""),"ffb078")),250)
		BossEncounters.begin(self,"recover",2.2)
		sound.emit("boss")
		log_event("boss-phase",{"stage":2,"phase":2,"hp":e.hp})
	elif e.boss and boss_stage == 3 and phase<3 and e.hp<=e.max_hp*(0.67 if phase==1 else 0.34)+0.1:
		phase += 1
		boss.reform = 2.5
		make_anchors()
		banner.emit("PHASE %s / %s"%[phase,"CRUST RUPTURE" if phase==2 else "THE LAST LIGHT"],"Break the anchors. Expose the core.")
		log_event("boss-phase",{"phase":phase,"hp":e.hp})
	return dealt

func kill(e):
	if not active or e.dead: return
	e.dead = true
	if e.get("boss_prop",false):
		BossEncounters.prop_destroyed(self,e)
		return
	if e.get("breakable",false):
		Breakables.destroy(self,e)
		return
	Relics.on_kill(self,e)
	kills += 1
	if companions!=null:companions.on_kill(self,e)
	streak += 1
	best_streak = maxi(streak,best_streak)
	combo_time = 4
	score += int((150 if e.elite else 10)*minf(5,1+streak/20.0)*(1+Relics.modifiers(self).get("score",0)))
	if kills%10==0: amber += 1
	effect.emit("sparks",e.p,Color("ffbc79") if e.elite else Color("9fbc9a"),12 if e.elite else 4)
	if e.anchor:
		anchors.erase(e)
		if anchors.is_empty() and boss != null:
			core_time = 12
			banner.emit("CORE EXPOSED","12 SECONDS / GIVE IT EVERYTHING")
			sound.emit("evolve")
		return
	add_gem(e.p,(25 if e.elite else 1+depth*0.3)*(1.3 if e.get("event_spawn",false) else 1.0))
	if not e.boss: Pickups.drop(self,e.p,false,e.elite)
	var mods = Relics.modifiers(self)
	if mods.has("heal_every") and kills%int(mods.heal_every)==0 and time>=blood_ready:
		hp = minf(max_hp,hp+mods.heal)
		blood_ready = time+2.0
	if mods.has("burst_every") and kills%int(mods.burst_every)==0 and hazards.size()<120:
		hazards.append({"kind":"friendly","p":e.p,"angle":0.0,"radius":120.0,"wait":0.12,"warning":0.12,"life":0.15,"damage":mods.burst_damage*damage_scale("fire"),"id":"fire","fired":false})
	if e.elite:
		amber += 8
		if not e.boss and not e.anchor and relic_chests.size()<4:
			# Scheduled mini-bosses retain guaranteed loot. Invasion mutations
			# share a cooldown and an explicit chance instead of flooding the map.
			if not e.get("event_spawn",false) or (time>=elite_chest_ready and rng.randf()<0.12):
				relic_chests.append(terrain.open_position(e.p))
				if e.get("event_spawn",false): elite_chest_ready = time+35
	if e.boss:
		preload("res://scripts/remnant_system.gd").leave(self,e)
		# One sweep of existing XP. This does not start a timed magnet.
		for gem in gems: gem.magnet=true
		voice_event.emit("boss_killed")
		encounter_epoch += 1
		hostile_shots.clear()
		brood_queue.clear()
		proc_queue.clear()
		campaign_bosses += 1
		rerolls = mini(5+int(research_ranks.get("reroll",0)),rerolls+1)
		log_event("boss-defeated",{"stage":boss_stage,"fight_time":boss_time})
		boss = null
		anchors.clear()
		amber += 75
		score += 10000
		if boss_stage == 3 and mode!="daily":
			finale_defeated = true
			update_gems(1000000.0)
			finish(true)
			return
		hazards.clear()
		enemies=enemies.filter(func(other):return other.get("encounter_guard",false) and not other.dead)
		grid.clear()
		portal = preload("res://scripts/remnant_system.gd").portal_position(self,boss_corpses.back())
		linger = 0.0
		portal_charge = 0.0
		hp = minf(max_hp,hp+max_hp*0.3)
		banner.emit("A WAY THROUGH","COLLECT YOUR SPOILS / ENTER THE RIFT WHEN READY")
		rite_requested.emit(e)
		if rite_pending:return
		open_choices(true)
	elif e.get("role","")=="brood" and brood_queue.size()<24:
		for j in range(3): brood_queue.append(e.p+Vector2.from_angle(j*TAU/3)*24)

func enter_portal():
	if not active or choosing or portal==null or boss!=null: return
	preload("res://scripts/remnant_system.gd").clear(self)
	if mode=="daily" and boss_stage==3:
		daily_loop+=1;boss_stage=0;depth=0
		explored = [{},{},{}]
		breakable_cells.clear()
		collected_stage_objects.clear()
		var maps=Maps.DATA.keys();maps.sort()
		map_id=maps[(maps.find(map_id)+1)%maps.size()];terrain.layout=Maps.DATA[map_id].layout
	else:depth = mini(2,depth+1)
	portal = null
	linger = 0.0
	portal_charge = 0.0
	encounter_epoch += 1
	proc_queue.clear()
	transition_time = 1.25
	next_boss = time+300.0 if mode=="daily" else maxf((depth+1)*300.0,time+45.0)
	ground_attack_ready = time+8
	enemies.clear()
	grid.clear()
	hazards.clear()
	shots.clear()
	hostile_shots.clear()
	zones.clear()
	strikes.clear()
	echoes.clear()
	kael_attack.clear()
	starter_attack.clear()
	volleys.clear()
	gems.clear()
	pickups.clear()
	brood_queue.clear()
	relic_chests.clear()
	shrine_done = false
	shrine_progress = 0
	terrain.arena = Vector2.INF
	terrain.seed_value += 101
	terrain.cached.clear()
	terrain.clearance.clear()
	terrain.flow.clear()
	terrain.goal = Vector2i(99999,99999)
	terrain.refresh = 0
	stage = StageDefinition.stage(map_id)
	terrain.configure(stage,depth)
	permanent_luck = research_ranks.get("luck",0)*0.01+research_ranks.get("fortune",0)*0.05+stage.modifiers.get("luck",0.0)
	pos = terrain.open_position(stage.spawn)
	StageObjects.setup(self)
	shrine_pos = terrain.open_position(pos+Vector2(-450,-250))
	cache_pos = terrain.open_position(pos+Vector2(480,180))
	cache_timer = 0
	map_cell = Vector2i(99999,99999)
	waypoint = null
	landmarks = Discoveries.landmarks(self)
	invul = 2.0
	effect.emit("evolve",pos,Color("83ddff"),650)
	sound.emit("stasis")
	banner.emit(Maps.biome(map_id,depth).name,"RIFT CROSSED / NEW ECOSYSTEM")
	log_event("portal",{"depth":depth})

func add_gem(p,value):
	if gems.size()<800:
		gems.append({"p":p,"value":value,"magnet":buffs.get("magnet",0)>0})
		return
	# Preserve a fresh drop at the kill location. Compact two older distant
	# gems instead of silently sending new XP to an arbitrary off-screen gem.
	var donor = -1
	var receiver = -1
	var farthest = -1.0
	for sample in range(12):
		var index = (gem_recycle_cursor+sample)%gems.size()
		if gems[index].magnet: continue
		var distance = gems[index].p.distance_squared_to(pos)
		if distance>farthest:
			receiver = donor if donor>=0 else receiver
			donor = index
			farthest = distance
		elif receiver<0: receiver = index
	gem_recycle_cursor = (gem_recycle_cursor+12)%gems.size()
	if donor<0 or receiver<0:
		# A global magnet is already bringing the whole cap into the player.
		gems[0].value += value
		return
	gems[receiver].value += gems[donor].value
	gems[donor] = {"p":p,"value":value,"magnet":buffs.get("magnet",0)>0}
func update_gems(dt):
	var radius = 95+buff_power("pickup")*35+research_ranks.get("magnet",0)*12
	var collectors={}
	if companions!=null:
		for ally in companions.units:
			if ally.hp<=0:continue
			var key=Vector2i(floori(ally.p.x/radius),floori(ally.p.y/radius))
			if not collectors.has(key):collectors[key]=[]
			collectors[key].append(ally.p)
	for gem in gems:
		var distance = gem.p.distance_to(pos)
		if distance<radius or buffs.get("magnet",0)>0: gem.magnet = true
		if not gem.magnet and not collectors.is_empty():
			var cell=Vector2i(floori(gem.p.x/radius),floori(gem.p.y/radius))
			for y in range(-1,2):
				for x in range(-1,2):
					for collector in collectors.get(cell+Vector2i(x,y),[]):
						if collector.distance_squared_to(gem.p)<radius*radius:gem.magnet=true;break
		if gem.magnet: gem.p = gem.p.move_toward(pos,(420+distance*3)*dt)
		if gem.p.distance_to(pos)<20:
			xp += gem.value*stage.modifiers.get("xp",1.0)*(1+research_ranks.get("growth",0)*0.03)*(1+buff_power("pickup")*0.08)*(1+Relics.modifiers(self).get("xp",0))*(2 if buffs.get("surge",0)>0 else 1)
			gem.value = 0
	gems = gems.filter(func(g): return g.value>0)

func hurt(amount, reason, piercing = false):
	if invul>0 or buffs.get("immune",0)>0 or not active: return
	if not piercing and time>=relic_state.get("thorns_ready",0.0):
		for id in weapons:
			if C.WEAPONS[id].delivery!="thorns": continue
			var stats=Rules.stats(self,id)
			relic_state.thorns_ready=time+maxf(0.65,stats.cooldown*0.4)
			blast(pos,stats.radius,stats.power*(1.15 if id=="thornking" else 0.8),id)
			sound.emit("thorns")
			break
	if not piercing: amount *= linger_damage()*(1+daily_loop*0.5)
	if shield>0:
		var absorbed = minf(shield,amount)
		shield -= absorbed
		amount -= absorbed
		if shield<=0:
			for id in weapons:
				if C.WEAPONS[id].delivery=="shield" and weapons[id].level>=7: blast(pos,200,180*damage_scale(id),id)
		if amount<=0:
			invul = 0.3
			return
	if Relics.modifiers(self).has("guard_cooldown") and relic_timers.clock<=0:
		relic_timers.clock = Relics.modifiers(self).guard_cooldown
		invul = 0.6
		effect.emit("ring",pos,Color("c7c1ff"),100)
		return
	amount = maxf(4,amount-(0 if piercing else armor+(companions.armor_bonus(self) if companions!=null else 0)))*(1+Relics.modifiers(self).get("incoming",0))
	if companions!=null:amount=companions.absorb(self,amount)
	if amount<=0:return
	hp -= amount
	hits += 1
	streak = 0
	invul = 0.7
	log_event("hit",{"damage":amount,"hp":hp,"source":reason})
	effect.emit("hurt",pos,Color("ff626e"),amount)
	sound.emit("hit")
	if hp>0:voice_event.emit("hurt")
	if hp<=0 and revives>0:
		revives-=1
		hp=max_hp*0.5
		invul=3.0
		buffs.immune=3.0
		effect.emit("evolve",pos,Color("ffe8a2"),380)
		sound.emit("evolve")
		banner.emit("EXTINCTION REFUSED","50% HEALTH / THREE SECONDS OF IMMUNITY")
		log_event("revive",{})
		return
	if hp<=0:
		death_reason = reason
		finish(false)

func add_hazard(kind,p,angle,radius,warning,life,damage):
	if hazards.size()>100: return
	hazards.append({"kind":kind,"p":p,"angle":angle,"radius":radius,"wait":warning,"warning":warning,"life":life,"damage":damage,"fired":false})

func hazard_contains(h,p):
	var d = p-h.p
	match h.kind:
		"line":
			var rotated = d.rotated(-h.angle)
			return rotated.x>0 and rotated.x<h.get("length",1000.0) and absf(rotated.y)<h.radius
		"cone": return d.length()<h.radius and absf(Vector2.from_angle(h.angle).angle_to(d))<h.get("arc",1.25)*0.5
		"ring": return absf(d.length()-h.radius)<20
		_: return d.length()<h.radius

func update_hazards(dt):
	# Effects created by a kill are deferred until the next frame.
	var epoch = encounter_epoch
	var pending = hazards
	hazards = []
	for h in pending:
		if h.has("source_uid") and not enemies.any(func(e):return e.uid==h.source_uid and not e.dead): continue
		h.wait -= dt
		if h.wait<=0:
			if not h.fired:
				h.fired = true
				effect.emit("blast_frost" if h.get("theme","") in ["hunt","aurora"] else "blast_miasma" if h.get("theme","")=="bloom" else "blast_orbital" if h.get("theme","")=="warden" else "blast_club" if h.get("theme","")=="thorn" else "impact",h.p,Color(BossEncounters.COLORS.get(h.get("theme",""),"ff9b68")),h.radius)
				if h.kind == "friendly":
					blast(h.p,h.radius,h.damage,h.id)
					sound.emit("impact_fire")
				elif not h.get("marker_only",false): sound.emit("impact_frost" if h.get("theme","") in ["hunt","aurora"] else "miasma" if h.get("theme","")=="bloom" else "lightning" if h.get("theme","")=="warden" else "club")
			h.life -= dt
			if h.kind != "friendly" and not h.get("marker_only",false) and hazard_contains(h,pos): hurt(h.damage,h.get("reason","Caught in an extinction strike"))
		# A killing impact may finish the encounter and clear its attacks.
		if not active or epoch!=encounter_epoch: return
		if h.life>0: hazards.append(h)

func spawn_boss(stage):
	boss_stage = stage
	boss_time = 0
	boss_timer = 3.5
	boss_pattern = 0
	phase = 1
	core_time = 0
	var p = pos+Vector2(0,-230)
	terrain.arena = p
	terrain.refresh = 0
	next_uid += 1
	var health = [90000.0,900000.0,20000000.0][stage-1]*pow(2.0,minf(daily_loop,25))
	boss = {"uid":next_uid,"p":p,"hp":health,"max_hp":health,"kind":8 if stage==3 else 11 if stage==2 else 1,"elite":false,"mutated":false,"boss":true,"anchor":false,"size":110.0 if stage==3 else 65.0,"speed":30.0,"flash":0.0,"slow":0.0,"burn":0.0,"burn_tick":0.0,"attack":0.0,"dead":false,"reform":0.0}
	if stage==3:boss.immovable=true;boss.anchor_p=p
	if stage<3 and map_id!="cradle": boss.kind=([14,15] if map_id=="frostbreak" else [16,17])[stage-1]
	enemies.append(boss)
	if stage==3: make_anchors()
	else: BossEncounters.setup(self)
	banner.emit(Maps.boss_name(map_id,stage),"APEX ENCOUNTER" if stage<3 else "BREAK THE ORBITAL ANCHORS / EXPOSE THE CORE")
	sound.emit("boss")
	voice_event.emit("boss_spawn")
	log_event("boss-arrived",{"stage":stage})

func make_anchors():
	for a in anchors: a.dead = true
	anchors.clear()
	for i in range(3):
		next_uid += 1
		var p = boss.p+Vector2.from_angle(i*TAU/3+PI/2)*245
		var health = 3000.0+phase*750
		var e = {"uid":next_uid,"p":p,"hp":health,"max_hp":health,"kind":8,"elite":false,"mutated":false,"boss":false,"anchor":true,"size":34.0,"speed":0.0,"flash":0.0,"slow":0.0,"burn":0.0,"burn_tick":0.0,"attack":0.0,"dead":false}
		anchors.append(e)
		enemies.append(e)
	core_time = 0

func update_boss(dt):
	if boss == null: return
	if boss.get("immovable",false):boss.p=boss.anchor_p
	boss_time += dt
	if buffs.get("freeze",0)>0 or buffs.get("slow",0)>0: dt *= 0.7
	boss.reform = maxf(0,boss.reform-dt)
	if boss_stage<3:
		phase = 2 if boss.hp <= boss.max_hp*0.5 else 1
		var origin=boss.p
		BossEncounters.update(self,dt)
		if companions!=null and boss!=null and boss.get("lift",0)<10:
			boss.p=companions.collision.block_enemy(boss,origin,boss.p)
		return
	else:
		if anchors.is_empty():
			core_time -= dt
			if core_time <= 0:
				make_anchors()
				banner.emit("THE CRUST REFORMS","Destroy the anchors for another damage window")
		if boss_time >= 210:
			extinction_timeout = true
			death_reason = "Extinction completed. The core outlasted your build."
			finish(false)
			return
		if pos.distance_to(boss.p)>720 and time>=boundary_ready:
			boundary_ready = time+1.0
			hurt(max_hp*0.18+10,"Outside the collapsing arena",true)
			banner.emit("RETURN TO THE ARENA","THE COLLAPSE BYPASSES ARMOR")
		if boss_time-dt<150 and boss_time>=150: banner.emit("EXTINCTION IMMINENT","60 SECONDS / THE SKY IS COLLAPSING")
	boss_timer -= dt
	if boss_timer>0 or (boss.reform>0 and boss_stage==3): return
	boss_timer = (3.3 if phase==1 else 2.65 if phase==2 else 2.15)*(0.68 if boss_time>150 else 1.0)
	var damage = 28+boss_stage*14+phase*6
	var aim = (pos-boss.p).angle()
	match boss_pattern%3:
		0:
			var safe = boss_pattern*0.71
			for j in range(8):
				if j in [0,1]: continue
				add_hazard("line",boss.p,safe+j*TAU/8,35,1.35,0.55,damage)
			banner.emit("CORONAL FLARE","READ THE LANES / MOVE INTO THE GAP")
		1:
			for j in range(5+phase*2):
				var p = pos+velocity*0.3 if j==0 else boss.p+Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(100,620)
				add_hazard("circle",p,0,62+phase*6,1.1+j*0.08,0.5,damage)
			banner.emit("HEAVEN FALLS","LEAVE THE IMPACT MARKERS")
		2:
			for j in range(4): add_hazard("ring",boss.p,0,120+j*120,1.0+j*0.4,0.35,damage)
			banner.emit("SEISMIC COLLAPSE","CROSS BETWEEN THE PULSES")
	if phase>=2: add_hazard("circle",pos-velocity*0.2,0,85,1.4,1.4,damage)
	boss_pattern += 1
	log_event("boss-pattern",{"stage":boss_stage,"pattern":boss_pattern})

func update_objectives(dt):
	if not active or choosing: return
	if mode!="safari": StageObjects.update(self)
	if not active or choosing: return
	for chest in relic_chests:
		if chest.distance_squared_to(pos)<38*38:
			relic_chests.erase(chest)
			open_choices(true)
			return
	if mode == "safari" or boss_stage == 3: return
	if cache_timer<=0 and pos.distance_to(cache_pos)<48:
		cache_timer = 55
		Pickups.drop(self,pos,true)
		cache_pos = terrain.open_position(pos+Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(650,900))
		amber += 10
		open_choices(true)
		return
	if not shrine_done:
		if pos.distance_to(shrine_pos)<105:
			shrine_progress += dt
			spawn_budget += dt*5
			if shrine_progress>=RIFT_CHARGE_SECONDS:
				shrine_done = true
				amber += 20
				hp = minf(max_hp,hp+25)
				open_choices(true)
		else: shrine_progress = maxf(0,shrine_progress-dt*0.5)

func buff_slots_used(): return passives.size()+augments.size()

func can_take_buff(id):
	return passives.has(id) or augments.has(id) or buff_slots_used()<BUFF_SLOTS

func upgrade_pool(owned_only = false):
	var pool = []
	for id in C.WEAPONS:
		if C.WEAPONS[id].get("fusion",false) or Evolutions.consumed(self,id): continue
		if weapons.has(id):
			if weapons[id].level<Rules.MAX_RANK: pool.append({"type":"weapon","id":id})
		elif not owned_only and content_allowed("weapons",id) and weapons.size()<BACKPACK_SLOTS and Rules.can_add_weapon(weapons,C.WEAPONS,id): pool.append({"type":"weapon","id":id})
	for id in C.PASSIVES:
		if content_allowed("passives",id) and can_take_buff(id) and rank_of(id)<C.PASSIVES[id].max and Rules.eligible(weapons,C.WEAPONS,C.PASSIVES[id].filter): pool.append({"type":"passive","id":id})
	for id in C.AUGMENTS:
		if can_take_buff(id) and content_allowed("augments",id) and augments.get(id,0)<C.AUGMENTS[id].max and Rules.eligible(weapons,C.WEAPONS,C.AUGMENTS[id].filter): pool.append({"type":"augment","id":id})
	return pool.filter(func(o):return not banished.has(o.type+":"+o.id))

func open_choices(relic):
	if choosing or not active: return
	var encounter_rng=rng
	if mode=="daily":rng=daily_reward_rng
	options = []
	option_is_relic = relic
	if relic:
		var transformations = Evolutions.ready(self)
		if not transformations.is_empty():
			options = [transformations[rng.randi_range(0,transformations.size()-1)]]
		else:
			var reward = Relics.roll_reward(self)
			if not reward.is_empty():options=[reward]
			if options.is_empty():
				var rarity=Relics.roll_tier(self)
				var improvements = upgrade_pool(true)
				var reward_option = {"type":"supplies","id":"supplies"} if improvements.is_empty() else improvements[rng.randi_range(0,improvements.size()-1)].duplicate()
				reward_option.rarity = rarity
				reward_option.refinement = true
				reward_option.rank_gain=Relics.RANK_GAINS[maxi(0,Relics.TIERS.find(rarity))]
				if reward_option.type!="supplies":
					var max_rank=10 if reward_option.type=="weapon" else C.PASSIVES[reward_option.id].max if reward_option.type=="passive" else C.AUGMENTS[reward_option.id].max
					var current_rank=weapons[reward_option.id].level if reward_option.type=="weapon" else rank_of(reward_option.id) if reward_option.type=="passive" else augments.get(reward_option.id,0)
					reward_option.rank_gain=mini(reward_option.rank_gain,max_rank-current_rank)
				if reward_option.type=="supplies":
					reward_option.amber_gain=[25,35,50,75,100,150][maxi(0,Relics.TIERS.find(rarity))]
					reward_option.heal_gain=[15,20,25,35,45,60][maxi(0,Relics.TIERS.find(rarity))]
				reward_option.source="chest"
				reward_option.quantity=1
				reward_option.effects={"ranks":reward_option.rank_gain} if reward_option.type!="supplies" else {"amber":reward_option.amber_gain,"heal":reward_option.heal_gain}
				if reward_option.type!="supplies":reward_option=BuffRewards.decorate(self,reward_option,rarity,reward_option.rank_gain,"chest")
				options = [reward_option]
	else:
		var pool = upgrade_pool()
		var fresh = pool.filter(func(o):return not reroll_exclude.any(func(old):return old.type==o.type and old.id==o.id))
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
	if not relic:
		for i in range(options.size()):options[i]=BuffRewards.decorate(self,options[i])
	if options.is_empty():
		options = [{"type":"supplies","id":"supplies"}]
	choosing = true
	effect.emit("level",pos,Color("b4d6ff"),350)
	sound.emit("loot" if relic else "level")
	if mode=="daily":
		var index=rng.randi_range(0,options.size()-1)
		var selected_option=options[index].duplicate(true)
		log_event("daily-roll",{"offered":options.duplicate(true),"index":index})
		if selected_option.has("replace") and rng.randf()<0.5:
			options[index]={"type":"supplies","id":"supplies"};selected_option=options[index]
		var offered=options.duplicate(true)
		selected_option["daily_offered"]=offered
		options=[selected_option]
		rng=encounter_rng
		choice_requested.emit(options,relic)
		return
	rng=encounter_rng
	choice_requested.emit(options,relic)

func reroll_choices():
	if mode=="daily" or not choosing or option_is_relic or rerolls<=0: return false
	rerolls -= 1
	reroll_exclude = options.duplicate(true)
	choosing = false
	open_choices(false)
	return true

func banish_choice(index):
	if mode=="daily" or not choosing or option_is_relic or banishes<=0 or index<0 or index>=options.size():return false
	var option=options[index]
	if option.type not in ["weapon","passive","augment"]:return false
	banished[option.type+":"+option.id]=true
	banishes-=1
	log_event("banish",{"type":option.type,"id":option.id})
	choosing=false
	open_choices(false)
	return true

func choose(index):
	if not choosing or index<0 or index>=options.size(): return
	var o = options[index]
	match o.type:
		"fusion":
			for part in Evolutions.UNIONS[o.id].parts:
				ledger.retired[part] = time
				weapons.erase(part)
			weapons[o.id] = {"level":10,"evolved":true,"timer":0.1}
			effect.emit("evolve",pos,Color(C.WEAPONS[o.id].color),550)
			sound.emit("evolve")
			banner.emit(C.WEAPONS[o.id].name,"WEAPON UNION / ONE BACKPACK SLOT FREED")
		"augment":
			if not can_take_buff(o.id) or augments.get(o.id,0)>=C.AUGMENTS[o.id].max: return
			var gain=mini(C.AUGMENTS[o.id].max-augments.get(o.id,0),o.get("rank_gain",1))
			augments[o.id] = augments.get(o.id,0)+gain
			BuffRewards.grant(self,o,gain)
		"weapon":
			if weapons.has(o.id): weapons[o.id].level = mini(10,weapons[o.id].level+o.get("rank_gain",1))
			elif weapons.size()<BACKPACK_SLOTS and Rules.can_add_weapon(weapons,C.WEAPONS,o.id): weapons[o.id] = {"level":mini(10,o.get("rank_gain",1)),"evolved":false,"timer":0.1}
			else: return
		"evolution":
			weapons[o.id].evolved = true
			if companions!=null:voice_event.emit("final_evolution")
			effect.emit("evolve",pos,Color("ffe2af"),450)
			sound.emit("evolve")
			banner.emit(C.WEAPONS[o.id].evolution,"LEGENDARY EVOLUTION / LET THEM COME")
		"passive":
			if not can_take_buff(o.id) or rank_of(o.id)>=C.PASSIVES[o.id].max: return
			var gain=mini(C.PASSIVES[o.id].max-rank_of(o.id),o.get("rank_gain",1))
			passives[o.id] = rank_of(o.id)+gain
			BuffRewards.grant(self,o,gain)
			if o.id == "armor":
				var strength=o.get("stat_gain",float(gain))*gain/maxf(1,o.get("rank_gain",gain))
				armor += 2*strength
				max_hp += roundi(12*strength)
				hp += roundi(12*strength)
		"supplies":
			amber += o.get("amber_gain",25)
			hp = minf(max_hp,hp+o.get("heal_gain",15))
		"relic":
			if o.has("replace"):
				Relics.remove(self,o.replace)
			if not Relics.apply(self,o):
				amber+=25
	log_event("upgrade",o)
	modifier_cache.clear()
	choosing = false
	invul = maxf(invul,0.65)
	# Short protection does not stack into permanent invulnerability.
	effect.emit("ring",pos,Color("ffe2ad"),200)
	for e in nearby(pos,180):
		if not e.boss and not e.anchor and not e.get("boss_prop",false) and not rooted(e): e.p = terrain.move(e.p,(e.p-pos).normalized()*80)

func finish(victory):
	if not active: return
	kael_attack.clear()
	starter_attack.clear()
	active = false
	encounter_epoch += 1
	won = victory
	if victory:
		score += 40000
		amber += 150
		effect.emit("victory",pos,Color("ffcd8e"),800)
		sound.emit("evolve")
	log_event("finish",{"victory":victory,"reason":death_reason,"score":score})
	ended.emit(victory)

func report():
	var result={"version":"native-0.13.0","halloween":halloween,"daily_loop":daily_loop,"daily_seed":daily_plan.get("seed",0),"map":map_id,"augments":augments,"hero":C.HEROES[hero].name,"mode":mode,"time":time,"won":won,"kills":kills,"hits":hits,"score":score,"best_streak":best_streak,"damage":damage_total,"damage_by_weapon":damage_by_weapon,"casts":ledger.casts,"discoveries":discovered,"weapons":weapons,"passives":passives,"relics":relics,"relic_stacks":relic_stacks.duplicate(true),"buff_stacks":buff_stacks.duplicate(true),"reward_schema":3,"events":event_log,"samples":samples}
	if companions!=null:result.army=companions.army_report()
	return result
