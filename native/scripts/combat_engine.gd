extends RefCounted
const Rules = preload("res://scripts/combat_rules.gd")
const Chain = preload("res://scripts/chain_system.gd")

static func update(g,dt):
	var pending = g.volleys
	g.volleys = []
	for volley in pending:
		volley.wait -= dt
		if volley.wait<=0:
			if g.weapons.has(volley.id): g.shoot(volley.id,g.pos,volley.dir,volley.power,volley.velocity,volley.life,volley.pierce)
		else: g.volleys.append(volley)
	if g.weapons.has("bastion"):
		g.relic_state.bastion_cd = g.relic_state.get("bastion_cd",0.0)-dt
		if g.relic_state.bastion_cd<=0:
			g.relic_state.bastion_cd = 8.0/(1+Rules.modifiers(g,"bastion").get("haste",0))
			g.shield = maxf(g.shield,110+Rules.modifiers(g,"bastion").get("shield",0))
			g.effect.emit("ring",g.pos,Color("8affdf"),140)
	for id in g.weapons:
		var w = g.weapons[id]
		w.timer -= dt
		if w.timer>0: continue
		var d = g.C.WEAPONS[id]
		var target = g.weapon_target(id)
		if target==null and d.delivery not in ["aura","shield","utility","orbital","thorns"]: continue
		var s = Rules.stats(g,id)
		if w.level==10: s.power *= 1.2
		w.timer = s.cooldown
		w.casts = w.get("casts",0)+1
		g.ledger.cast(id,g.time)
		g.Relics.on_cast(g,d,w.casts,s)
		g.sound.emit(id)
		var aim = (target.p-g.pos).normalized() if target!=null else Vector2(g.facing,0)
		if d.has("secondary") and target!=null:
			var extra = d.secondary
			for j in range(extra.count):
				g.shoot(id,g.pos,aim.rotated((j-(extra.count-1)*0.5)*0.14),s.power*extra.power,extra.velocity,extra.lifetime,extra.pierce)
		match d.delivery:
			"thorns":
				g.blast(g.pos,s.radius,s.power,id)
			"projectile":
				var count = s.count
				for j in range(mini(24,count)):
					# Detonating rounds spend their impact immediately; ricochet may
					# then redirect them. They do not receive piercing augments.
					var spread = 0.0 if j==0 else ceilf(j/2.0)*0.13*(1 if j%2==1 else -1)
					var pierce = 1 if "EXPLOSION" in d.tags or "RICOCHET" in d.tags else s.pierce
					if j==0: g.shoot(id,g.pos,aim.rotated(spread),s.power,s.velocity,s.lifetime,pierce)
					elif g.volleys.size()<80: g.volleys.append({"wait":j*d.projectile_interval,"id":id,"dir":aim.rotated(spread),"power":s.power,"velocity":s.velocity,"life":s.lifetime,"pierce":pierce})
			"melee":
				if w.evolved and "SWEEP" in d.tags: s.arc = TAU
				melee(g,id,g.pos,aim,s)
				for i in range(s.repeat):
					g.echoes.append({"wait":0.16*(i+1),"id":id,"aim":aim.rotated(PI if i%2==1 and "SWEEP" in d.tags else 0),"stats":s.duplicate()})
				if w.level>=7:
					g.shoot(id,g.pos,aim,s.power*0.55,520,0.6,8)
			"chain":
				Chain.cast(g,g.pos,s.power,id,s.count,s.range,s.falloff,s.fork,s.rechain)
			"orbital":
				for j in range(s.count):
					g.blast(g.pos+Vector2.from_angle(g.time*2.3+j*TAU/s.count)*s.radius,40*g.area_scale(),s.power,id)
			"ground":
				if id=="thunderstorm":
					for j in range(mini(s.count,4)):
						if g.zones.size()>=24: break
						var center = target.p+Vector2.from_angle(j*TAU/mini(s.count,4))*j*s.radius*0.8
						g.zones.append({"p":center,"radius":s.radius,"id":id,"damage":s.power,"wait":0.2,"life":2.0+s.duration,"duration":2.0+s.duration,"interval":0.25 if w.evolved else 0.5,"age":0.0,"tick":0.0,"pulse":0})
					continue
				for j in range(mini(s.count,8)):
					var p = target.p+Vector2.from_angle(g.rng.randf()*TAU)*j*65
					g.hazards.append({"kind":"friendly","p":p,"launch":g.pos,"flight":0.75+j*0.12,"angle":0.0,"radius":s.radius,"wait":0.75+j*0.12,"warning":0.75,"life":0.2,"damage":s.power,"id":id,"fired":false})
					# Each crater ignites when its own shell lands, including staggered volleys.
					if s.duration>0 and g.zones.size()<24: g.zones.append({"p":p,"radius":s.radius,"id":id,"damage":s.power*0.22,"wait":0.75+j*0.12,"life":s.duration,"duration":s.duration,"age":0.0,"tick":0.0,"scorched":true})
			"aura":
				var burst = w.level>=7 and w.casts%4==0
				g.blast(g.pos,s.radius*(1.8 if burst else 1),s.power*(2 if burst else 1),id)
			"shield":
				g.shield = maxf(g.shield,s.shield*(1.7 if w.evolved else 1.0))
				g.effect.emit("ring",g.pos,Color(d.color),100)
			"utility":
				g.buffs["freeze" if w.level>=7 else "slow"] = 2+s.duration+w.level*0.15+(2 if w.evolved else 0)
				g.effect.emit("level",g.pos,Color(d.color),350)
	for echo in g.echoes:
		echo.wait -= dt
		if echo.wait<=0: melee(g,echo.id,g.pos,echo.aim,echo.stats)
	g.echoes = g.echoes.filter(func(e):return e.wait>0)
	for zone in g.zones:
		var active_step = maxf(0.0,dt-maxf(0.0,zone.wait))
		zone.wait -= dt
		if zone.wait>0: continue
		if zone.id=="thunderstorm":
			# Schedule at 0 / .5 / 1 / 1.5 seconds, without an expiry explosion.
			var active_dt = minf(dt,zone.life)
			zone.age += active_dt
			while zone.pulse*zone.interval<zone.age and zone.pulse*zone.interval<zone.duration-0.00001:
				zone.pulse += 1
				g.blast(zone.p,zone.radius,zone.damage,zone.id,"field")
				g.sound.emit("thunder_hit")
				for j in range(3):
					var landing = zone.p+Vector2.from_angle(zone.pulse*2.4+j*TAU/3)*zone.radius*(0.15 if j==0 else 0.6)
					if g.strikes.size()<180: g.strikes.append({"a":landing+Vector2(-35,-200),"b":landing,"life":0.24,"wait":j*0.035})
			zone.life -= dt
			continue
		var active_dt = minf(active_step,zone.life)
		var duration = zone.get("duration",zone.life+zone.get("age",0.0))
		zone.age = zone.get("age",0.0)+active_dt
		zone.life -= active_dt
		zone.pulse = zone.get("pulse",0)
		while zone.pulse*0.6<zone.age and zone.pulse*0.6<duration-0.00001:
			zone.pulse += 1
			g.blast(zone.p,zone.radius,zone.damage,zone.id,"field")
		# Supernova explicitly promises an eruption; ordinary craters simply cool.
		if zone.life<=0 and zone.id=="supernova": g.blast(zone.p,zone.radius*1.2,zone.damage*3,zone.id)
	g.zones = g.zones.filter(func(z):return z.life>0)
	for strike in g.strikes:
		if strike.get("wait",0)>0:
			strike.wait -= dt
			if strike.wait<=0 and strike.get("chain",false): g.sound.emit("chain_tick")
		else: strike.life -= dt
	g.strikes = g.strikes.filter(func(s):return s.life>0)

static func melee(g,id,p,aim,s):
	if id=="spear":
		g.strikes.append({"a":p,"b":p+aim*s.radius,"life":0.22,"kind":"spear"})
	else: g.effect.emit("blast_club",p,Color(g.C.WEAPONS[id].color),s.radius)
	for e in g.nearby(p,s.radius):
		var delta = e.p-p
		if delta.length()>s.radius+e.size: continue
		if s.arc<TAU and absf(aim.angle_to(delta))>s.arc*0.5: continue
		g.hit(e,s.power,id)
		if not e.boss and not e.anchor and not g.rooted(e): e.p = g.terrain.move(e.p,delta.normalized()*45)
