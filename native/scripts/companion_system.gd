extends RefCounted

const LIMIT = 64
const TEMP_LIMIT = 16
const Contact=preload("res://scripts/army_collision.gd")
const EARTH_SHARDS=preload("res://assets/colossus-earth-shards.png")
var collision=Contact.new()
var raised_by_ability = {}
var strongest = {}
var deadliest = {}
var total_losses = 0
var units = []
var ground_ruptures = []
var pending = []
var souls = 0.0
var next_threshold = 25.0
var threshold_index = 0
var serial = 0
var empowerment = 0.0
var empowerment_until = 0.0
var momentum = 0.0
var last_kill = -10.0
var stationary = 0.0
var proc_ready = 0.0
var heal_ready = 0.0
var reform = []
var fallen_remnant={}
var fallen_queue=[]
var remnant_souls=0.0
const REMNANT_SOUL_COST=2000.0
var first_summon = false
var losses = []
var owner_angle=PI/2
var cloak_angle=PI/2
var command_until=0.0
var command_direction=Vector2.DOWN
var trail=[]
var trail_ready=0.0
var pose=0
var previous_pose=0
var pose_blend=1.0
var pose_ready=0.0
var attack_audio_ready=0.0
var attack_audio_roles={}

func rank(g,n): return g.buff_power("p%02d"%n)
func permanent(g,id):return clampi(int(g.research_ranks.get(id,0)),0,5) if g.mode=="expedition" and preload("res://scripts/content_extension.gd").is_profile(g) else 0
func relic(g,n): return g.Relics.strength(g,"r%02d"%n) if "r%02d"%n in g.relics else 0.0
func role(g,id): return g.C.WEAPONS[id].get("role","")
static func reanimate_profile(level,evolved,mods={}):return {"kills":maxi(4,12-int(level/2)-int(mods.get("reanimate_kills",0))),"count":(2 if evolved else 1)+int(mods.get("reanimate_count",0)),"lifetime":(18.0 if evolved else 12.0)*(1+mods.get("reanimate_lifetime",0))}
func owned(g,r):
	for id in g.weapons:
		if role(g,id)==r: return id
	return ""
func capacity(g,id):
	var r = role(g,id)
	var w = g.weapons[id]
	var extra=int(g.Rules.modifiers(g,id).get("summon_capacity",0))
	match r:
		"warrior": return mini(36,4+int(w.level>=5)+(8 if w.evolved else 0)+int(rank(g,5))*2+roundi(relic(g,0)*2)+mini(5,int(souls/100)) * int(rank(g,1)>0)+extra)
		"guard": return 2+int(w.level>=5)+(2 if w.evolved else 0)+extra
		"archer": return 3+int(w.level>=5)+(3 if w.evolved else 0)+extra
		"wraith": return 2+int(w.level>=5)+(2 if w.evolved else 0)+extra
		"colossus": return 1
	return 0

func summon(g,id,temporary=0.0):
	if id=="" or not g.C.WEAPONS.has(id) or (not g.weapons.has(id) and temporary<=0) or units.size()>=LIMIT: return false
	var r = role(g,id)
	if r not in ["warrior","guard","archer","wraith","colossus"]: return false
	if r=="colossus" and units.any(func(u):return u.role=="colossus" and u.hp>0):return false
	var same=0; var temps=0
	for u in units:
		if u.temporary>0: temps+=1
		elif u.source==id: same+=1
	if temporary>0 and temps>=TEMP_LIMIT: return false
	if temporary<=0 and same>=capacity(g,id): return false
	serial+=1
	raised_by_ability[id]=int(raised_by_ability.get(id,0))+1
	var w=g.weapons.get(id,{"level":1,"evolved":false})
	var champion=r=="guard" or (r=="warrior" and w.level>=9 and serial%(3 if w.evolved else 5)==0)
	var health=(170 if champion else 90)*(1+w.level*.12)*(1+g.buff_power("armor")*.05)
	if r=="colossus": health=600*(1+w.level*.15)
	health*=1+permanent(g,"summon_health")*.06
	var p=g.terrain.open_position(g.pos+Vector2.from_angle(serial*2.4)*70)
	units.append({"uid":serial,"name":preload("res://scripts/summon_names.gd").generate(g.rng.seed,serial,r),"damage_dealt":0.0,"kills":0,"p":p,"hp":float(health),"max_hp":float(health),"source":id,"role":r,"champion":champion,"temporary":temporary,"expires":g.time+temporary,"attack":.25,"search":0.0,"target":null,"flash":0.0,"angle":serial*2.4})
	if not first_summon:
		first_summon=true
		g.voice_event.emit("first_summon")
	if r=="colossus":g.voice_event.emit("colossus_summoned")
	g.effect.emit("ring",p,Color("8dc7b5"),25)
	return true

func stats(g,id):
	if g.weapons.has(id):
		var result=g.Rules.stats(g,id).duplicate()
		result.power*=1+permanent(g,"summon_power")*.04
		return result
	return {"power":g.C.WEAPONS[id].damage*g.damage_scale(id)*(1+permanent(g,"summon_power")*.04),"count":1,"radius":100*g.area_scale()}

func cast(g,id,s):
	var r=role(g,id)
	var mods=g.Rules.modifiers(g,id)
	if r=="boss" and mods.get("remnant_rally",0)>0:
		for u in units:
			if u.hp<=0 or not u.get("boss_form",false) or g.time<u.get("rally_ready",0):continue
			u.hp=minf(u.max_hp,u.hp+u.max_hp*mods.remnant_rally);u.rally_ready=g.time+8
			g.effect.emit("ring",u.p,Color("8dc7b5"),90)
		return
	var is_summon=r in ["warrior","guard","archer","wraith","colossus"]
	if is_summon:
		if units.size()>=LIMIT:return
		var occupied=units.filter(func(u):return u.source==id and u.temporary<=0 and u.hp>0).size()
		if occupied>=capacity(g,id):return
		if r=="colossus" and units.any(func(u):return u.role=="colossus" and u.hp>0):return
	if r=="soul" and souls<3:return
	if is_summon or r in ["spear","soul"]:
		var focus=g.weapon_target(id)
		if not is_summon and focus==null:return
		command_until=g.time+.55
		command_direction=g.velocity.normalized() if g.velocity.length_squared()>1 else Vector2.from_angle(owner_angle)
		if focus!=null:command_direction=(focus.p-g.pos).normalized()
	if r in ["warrior","guard","archer","wraith","colossus"]:
		var count=1+int(rank(g,10))+mini(3,int(g.buff_power("count")))
		for j in range(count):
			if not summon(g,id): break
		return
	if r=="spear" or r=="soul":
		if r=="soul" and souls<3: return
		var target=g.weapon_target(id)
		if target==null: return
		var origin=g.pos
		for j in range(mini(8,s.count)):
			g.shoot(id,origin,(target.p-origin).normalized().rotated((j-(s.count-1)*.5)*.12),s.power,s.velocity,s.lifetime,8+int(mods.get("pierce",0)) if r=="spear" else 1)
		return
	if r=="chill":
		var centers=[g.pos]
		for u in units: centers.append(u.p)
		var seen={}
		for p in centers:
			for e in g.nearby(p,minf(160,s.radius)*(1+mods.get("chill_reach",0))):
				if seen.has(e.uid): continue
				seen[e.uid]=true
				e.slow=maxf(e.slow,1.5+mods.get("chill_duration",0))
				if not e.boss and not e.anchor and not e.get("boss_prop",false):e.frozen=maxf(e.get("frozen",0),mods.get("chill_freeze",0))
				e.dread=minf(.5,e.get("dread",0.0)+.03+mods.get("dread_gain",0))
				g.hit(e,s.power,id,false,false)

func update(g,dt):
	update_ground_ruptures(g,dt)
	update_owner(g,dt)
	stationary=minf(8,stationary+dt) if g.velocity.length_squared()<1 else 0.0
	if g.time-last_kill>4: momentum=0.0
	var survivors=[]
	losses=losses.filter(func(at):return g.time-at<10)
	var army_size=units.size()
	for u in units:
		u.flash=maxf(0,u.flash-dt)
		if u.hp<=0 or (u.temporary>0 and g.time>=u.expires):
			if u.hp<=0:
				if u.get("boss_form",false):
					var lost={"identity":u.identity,"p":g.pos}
					if fallen_remnant.is_empty():fallen_remnant=lost;remnant_souls=0.0
					else:fallen_queue.append(lost)
				total_losses+=1
				losses.append(g.time)
				if relic(g,6)>0 and pending.size()<24: pending.append({"p":u.p,"damage":45*relic(g,6),"id":u.source})
				if u.temporary<=0 and not u.get("boss_form",false) and reform.size()<LIMIT: reform.append({"id":u.source,"at":g.time+(1.5 if g.weapons.get(u.source,{}).get("evolved",false) else 3.0)})
			continue
		survivors.append(u)
		if u.role=="wraith":
			update_wraith(g,u,dt)
			continue
		if u.p.distance_squared_to(g.pos)>650*650:
			u.p=g.terrain.open_position(g.pos+Vector2.from_angle(u.angle)*70)
			u.target=null
		u.search-=dt
		if u.search<=0:
			u.search=.2+float(u.uid%4)*.025
			u.target=null;var best=INF
			for e in g.nearby(u.p,360):
				if e.dead: continue
				var dist=u.p.distance_squared_to(e.p)
				if u.role=="colossus":dist*=heavy_target_weight(e)
				if dist<best: best=dist;u.target=e
		var target=u.target
		if target!=null and not u.has("swing") and absf(target.p.x-u.p.x)>4:u.draw_facing=-1.0 if target.p.x<u.p.x else 1.0
		if target!=null and target.dead: target=null
		var speed=(220.0 if u.identity=="hunt" else 155.0) if u.get("boss_form",false) else 180.0 if u.champion else 245.0
		if u.role=="colossus": speed=135
		var range_value=base_reach(u)
		var old_position=u.p
		if u.get("boss_form",false) and update_remnant_skill(g,u,target,dt):continue
		if target!=null:range_value=maxf(range_value,Contact.radius(u)+Contact.enemy_radius(target)+8)
		var destination=g.pos+Vector2.from_angle(u.angle)*90
		if target!=null: destination=target.p
		if u.role=="wraith":
			var orbit=g.pos+Vector2.from_angle(g.time*1.8+u.angle)*110
			destination=target.p if u.attack<.5 and target!=null else orbit
		var target_distance=Contact.engagement_distance(target,u.p) if target!=null else u.p.distance_to(destination)
		speed=pursuit_speed(g,u,target,target_distance,range_value,speed)
		if not u.has("swing") and (target_distance>range_value or u.role=="wraith"):
			u.p=g.terrain.move(u.p,(destination-u.p).normalized()*speed*dt)
		var wanted=u.p;u.p=old_position
		u.p=Contact.move_minion(g,u,wanted)
		u.moving=u.p.distance_squared_to(old_position)>.01
		u.walk_phase=fmod(u.get("walk_phase",0.0)+u.p.distance_to(old_position)/24.0,4.0)
		var banner=relic(g,3) if u.p.distance_squared_to(g.pos)<300*300 else 0.0
		if target!=null and Contact.engagement_distance(target,u.p)<Contact.radius(u)+Contact.enemy_radius(target)+10 and g.time>=u.get("hurt_at",0):
			u.hp-=maxf(2,9+g.depth*4-(5 if u.champion else 0)-banner*3)
			u.hurt_at=g.time+.8;u.flash=.15
		animate_attack(g,u,dt)
		u.attack-=dt
		if target==null or u.attack>0 or u.has("swing") or Contact.engagement_distance(target,u.p)>range_value: continue
		var s=stats(g,u.source)
		var haste=1+rank(g,6)*.2+banner*.15+(empowerment if g.time<empowerment_until else 0)
		haste*=(1+permanent(g,"summon_haste")*.04)*(1+g.Rules.modifiers(g,u.source).get("unit_haste",0))
		var cadence=1.25 if u.get("boss_form",false) and u.identity=="hunt" else 1.6 if u.get("boss_form",false) else 1.7 if u.role=="colossus" else .95
		u.attack=maxf(.15,cadence/((1+g.buff_power("haste")*.1)*haste))
		var power=s.power*(1.8 if u.champion else 1.0)*(1+momentum*.025+(rank(g,3)*.2 if u.p.distance_squared_to(g.pos)<300*300 else 0)+banner*.15+relic(g,5)*stationary*.025)
		if u.champion: power*=1+relic(g,0)*.35
		if g.time<empowerment_until: power*=1.5
		u.swing={"elapsed":0.0,"duration":minf(.7 if u.role=="colossus" else .5,u.attack*.8),"hit":false,"target":target,"power":power,"stats":s,"aim":(target.p-u.p).normalized()}

	units=survivors
	if losses.size()>=maxi(3,ceili(army_size*.35)):
		g.voice_event.emit("army_losses")
		losses.clear()
	var waiting=[]
	for r in reform:
		if g.time>=r.at:
			if summon(g,r.id):g.voice_event.emit("resurrection")
		else: waiting.append(r)
	reform=waiting
	if g.time>=proc_ready:
		proc_ready=g.time+.15
		var budget=mini(4,pending.size())
		for j in range(budget):
			var event=pending.pop_front()
			if event.has("summon"):
				if summon(g,event.summon,event.get("lifetime",12.0)):g.voice_event.emit("resurrection")
			else:
				var radius=event.get("radius",100*g.area_scale())
				g.blast(event.p,radius,event.damage,event.id)
				if not g.active:return
				var duration=g.Rules.modifiers(g,event.id).get("corpse_field",0)
				if duration>0 and g.zones.size()<24:g.zones.append({"p":event.p,"radius":radius,"id":event.id,"damage":event.damage*.35,"wait":0.0,"milestone_field":true,"life":duration,"duration":duration,"age":0.0,"tick":0.0})

func base_reach(u)->float:
	# A ground rupture lets the heavy ally commit before crowd bodies pin it in melee.
	return 100.0 if u.get("boss_form",false) else 230.0 if u.role=="archer" else 160.0 if u.role=="colossus" else 48.0

static func heavy_target_weight(e)->float:
	# A slow heavy ally should commit to tougher nearby prey, while a much
	# closer ordinary creature still takes precedence over a distant elite.
	if e.boss:return .2
	if e.elite:return .35
	return .65 if e.get("role","")=="armor" else 1.0

func pursuit_speed(g,u,target,distance,reach,base_speed):
	# Warriors close the gap briefly; normal terrain and body collision still apply.
	if u.role!="warrior" or u.get("boss_form",false):return base_speed
	if target==null or target.dead or u.has("swing") or distance<=reach:
		u.erase("pursuit_until")
		return base_speed
	if g.time>=u.get("pursuit_ready",0.0) and distance>reach+60 and distance<360:
		u.pursuit_until=g.time+.35
		u.pursuit_ready=g.time+2.5
	return base_speed*1.6 if g.time<u.get("pursuit_until",0.0) else base_speed

func animate_attack(g,u,dt):
	if not u.has("swing"):return
	var swing=u.swing
	swing.elapsed+=dt
	if not swing.hit and swing.elapsed>=swing.duration*.45:
		swing.hit=true
		var victim=swing.target
		if u.role=="colossus" and not u.get("boss_form",false):
			colossus_slam(g,u,swing)
			if swing.elapsed>=swing.duration:u.erase("swing")
			return
		if victim==null or victim.dead:
			victim=replacement_melee_target(g,u,swing)
		if victim!=null and not victim.dead:
			if u.get("boss_form",false):
				remnant_impact(g,u,victim,swing.power)
			elif u.role=="archer":
				attack_sound(g,u)
				for j in range(mini(6,swing.stats.count)):
					var origin=u.p+Vector2(24*u.get("draw_facing",1.0),-34)
					var projectile=g.shoot(u.source,origin,(victim.p-origin).normalized().rotated((j-(swing.stats.count-1)*.5)*.08),swing.power,600,1.2,2+int(g.Rules.modifiers(g,u.source).get("pierce",0)))
					if projectile!=null:projectile.companion=u
			elif Contact.engagement_distance(victim,u.p)<=100+victim.size:
				attack_sound(g,u)
				var cleave=u.champion or u.role in ["wraith","colossus"] or g.weapons.get(u.source,{}).get("level",1)>=3
				if cleave:
					var count=0
					for e in g.nearby(victim.p,minf(180,swing.stats.radius*(1.3 if u.role=="colossus" else .55))):
						strike(g,u,e,swing.power);count+=1
						if count>=24:break
				else:strike(g,u,victim,swing.power)
	if swing.elapsed>=swing.duration:u.erase("swing")

func colossus_slam(g,u,swing):
	attack_sound(g,u)
	var impact:Vector2=g.terrain.move(u.p,swing.aim*64.0)
	var radius:float=minf(180,swing.stats.radius*1.3)*(1+g.Rules.modifiers(g,u.source).get("colossus_area",0))
	var struck={}
	for e in g.nearby(impact,radius+100):
		if e.dead or Contact.engagement_distance(e,impact)>radius:continue
		strike(g,u,e,swing.power);struck[e.uid]=true
		if not g.active:return
		if struck.size()>=24:break
	g.effect.emit("impact",impact,Color("a8b79a"),32)
	# One shared hit list: enemies struck by the mace cannot take the same attack twice.
	var mods=g.Rules.modifiers(g,u.source)
	for side in 1+mini(2,int(mods.get("rupture_fan",0))):
		if ground_ruptures.size()>=32:break
		ground_ruptures.append({"p":impact,"origin":impact,"aim":swing.aim.rotated(0 if side==0 else -.32 if side==1 else .32),"age":0.0,"distance":0.0,"length":clampf(240*g.area_scale()*(1+mods.get("rupture_length",0)),180,360),"width":clampf(radius*.5,24,52),"unit":u,"power":swing.power*.65,"struck":struck,"stopped":false})

func update_ground_ruptures(g,dt):
	var alive=[]
	for wave in ground_ruptures:
		wave.age+=dt
		if wave.age>1.0:continue
		alive.append(wave)
		if wave.stopped:continue
		var previous:Vector2=wave.p
		var travel:float=minf(480*dt,wave.length-wave.distance)
		# Advance along the locked line; ordinary body movement would slide it sideways at walls.
		var steps:int=maxi(1,ceili(travel/8))
		var step:Vector2=wave.aim*travel/steps
		for j in range(steps):
			if not g.terrain.walkable(wave.p+step):wave.stopped=true;break
			wave.p+=step
		wave.distance+=previous.distance_to(wave.p)
		if previous.distance_to(wave.p)<travel*.75 or wave.distance>=wave.length-.1:wave.stopped=true
		for e in g.nearby((previous+wave.p)*.5,wave.width+travel*.5+100):
			if e.dead or wave.struck.has(e.uid):continue
			var closest=Geometry2D.get_closest_point_to_segment(e.p,previous,wave.p)
			if Contact.engagement_distance(e,closest)>wave.width:continue
			wave.struck[e.uid]=true
			strike(g,wave.unit,e,wave.power)
	ground_ruptures=alive

func replacement_melee_target(g,u,swing):
	# A ranged ally may finish the target during windup. Keep the same forward swing.
	if u.role not in ["warrior","guard","colossus"] or u.get("boss_form",false):return null
	var best=null;var distance=INF
	for e in g.nearby(u.p,200):
		if e.dead or Contact.engagement_distance(e,u.p)>100+e.size:continue
		var delta=e.p-u.p
		if delta.normalized().dot(swing.aim)<.5:continue
		if delta.length_squared()<distance:best=e;distance=delta.length_squared()
	return best

func attack_sound(g,u):
	# One sound per completed strike/volley, never per cleaved enemy.
	if u.p.distance_squared_to(g.pos)>900*900:return
	var id={"warrior":"unit_blade","guard":"unit_guard","archer":"unit_bow","wraith":"unit_wraith","colossus":"unit_heavy","boss":"unit_heavy"}.get(u.role,"unit_blade")
	if g.time<attack_audio_roles.get(id,-1):return
	if id!="unit_heavy" and g.time<attack_audio_ready:return
	attack_audio_ready=g.time+.09
	attack_audio_roles[id]=g.time+(.3 if id=="unit_heavy" else .15)
	g.sound.emit(id)

func strike(g,u,e,power):
	e.unit_hit=true
	if rank(g,8)>0 and e.get("role","")=="armor":power*=1.25
	var dealt=g.hit(e,power,u.source)
	credit(u,dealt,e.dead)
	if not e.boss and not e.anchor and not e.dead:
		e.p=g.terrain.move(e.p,(e.p-u.p).normalized()*(12+rank(g,8)*15))

func on_kill(g,e):
	if e.anchor: return
	var gain=(5 if (e.elite or e.boss) and rank(g,2)>0 else 1)*(1+rank(g,0)*.2+relic(g,1)*.35)
	if not fallen_remnant.is_empty():
		remnant_souls+=gain
		if remnant_souls>=REMNANT_SOUL_COST:
			fallen_remnant.p=g.pos
			if raise_remnant(g,fallen_remnant):
				fallen_remnant=fallen_queue.pop_front() if not fallen_queue.is_empty() else {};remnant_souls=0
				g.voice_event.emit("resurrection")
		return
	souls+=gain
	while souls>=next_threshold:
		match threshold_index%4:
			0: summon(g,owned(g,"warrior"),15)
			1:
				for u in units:u.hp=minf(u.max_hp,u.hp+u.max_hp*.5)
			2:
				empowerment=.4;empowerment_until=g.time+8
				g.voice_event.emit("army_empowered")
			3:
				var id=owned(g,"colossus")
				if id=="": id="u09"
				summon(g,id,15)
		threshold_index+=1
		next_threshold=float(int(threshold_index/4)*250+[25,50,100,250][threshold_index%4])
	var base=owned(g,"warrior")
	if e.get("unit_hit",false):momentum=minf(20,momentum+rank(g,7));last_kill=g.time
	if pending.size()>=24:return
	var near=false
	for u in units:
		if u.p.distance_squared_to(e.p)<300*300:near=true;break
	var ce=owned(g,"corpse")
	if ce!="" and near and g.rng.randf()<minf(.75,.15+g.weapons[ce].level*.015+g.Rules.modifiers(g,ce).get("corpse_chance",0)):
		pending.append({"p":e.p,"radius":100*g.area_scale()*(1+g.Rules.modifiers(g,ce).get("radius",0)),"damage":g.Rules.stats(g,ce).power+minf(300,e.max_hp*.08),"id":ce})
	var r=owned(g,"reanimate")
	if r!="":
		var rite=reanimate_profile(g.weapons[r].level,g.weapons[r].evolved,g.Rules.modifiers(g,r))
		if g.kills%rite.kills==0:
			for j in range(rite.count):
				if pending.size()<24:pending.append({"summon":base,"lifetime":rite.lifetime})
	var probability=(.08 if base!="" and g.weapons[base].level>=7 else 0.0)+rank(g,11)*.06+relic(g,7)*.1
	if near and (e.get("unit_hit",false) or relic(g,7)>0) and g.rng.randf()<minf(.4,probability):pending.append({"summon":base})
	if relic(g,2)>0 and g.kills%40==0:
		for other in g.nearby(g.pos,500):
			if not other.dead and not other.boss and not other.elite and not other.anchor and not other.get("breakable",false):
				g.hit(other,other.hp*2,"r02",false,false);break

func absorb(g,amount):
	var nearby=[]
	for u in units:
		if u.hp>0 and u.p.distance_squared_to(g.pos)<300*300:nearby.append(u)
	var guards=nearby.filter(func(u):return u.role=="guard" and g.Rules.modifiers(g,u.source).get("guard_share",0)>0)
	if not guards.is_empty():
		var shared=amount*minf(.35,g.Rules.modifiers(g,guards[0].source).guard_share)
		for guard in guards:guard.hp-=shared/guards.size()
		amount-=shared
	if not nearby.is_empty() and rank(g,12)>0:
		var share=amount*.2
		for u in nearby:u.hp-=share/nearby.size()
		amount-=share
	if amount>=g.hp and nearby.size()>=3 and relic(g,4)>0 and g.time>=heal_ready:
		heal_ready=g.time+90
		for i in range(3):nearby[i].hp=0
		g.hp=g.max_hp*.4;g.invul=2
		g.voice_event.emit("fatal_prevented")
		return 0.0
	return amount

func armor_bonus(g):return minf(8,units.size()*.3*rank(g,4))

func draw(target,g,screen_pos):
	for u in units:
		var p=screen_pos.call(u.p)
		if not Rect2(Vector2(-100,-100),target.get_viewport_rect().size+Vector2(200,200)).has_point(p):continue
		var scale_value=2.0 if u.role=="colossus" else 1.25 if u.champion else 1.0
		if u.get("boss_form",false):
			var progress=clampf(u.swing.elapsed/u.swing.duration,0,1) if u.has("swing") else 0.0
			if not target.has_method("draw_rig_unit") or not target.draw_rig_unit(u,p):
				preload("res://scripts/remnant_rig.gd").draw(target,p,u.identity,u.get("walk_phase",0),progress,u.get("draw_facing",1)<0)
			target.draw_rect(Rect2(p+Vector2(-25,12),Vector2(50,3)),Color("26342b"))
			target.draw_rect(Rect2(p+Vector2(-25,12),Vector2(50*maxf(0,u.hp/u.max_hp),3)),Color("87cfa6"))
			continue
		if u.role=="warrior" and target.has_method("draw_rig_unit") and target.draw_rig_unit(u,p):continue
		var index=5 if u.role=="colossus" else 4 if u.role=="wraith" else 3 if u.role=="archer" else 2 if u.champion else 1
		var frame=int(u.get("walk_phase",0.0)) if u.get("moving",false) else 0
		if u.has("swing"):
			var progress=clampf(u.swing.elapsed/u.swing.duration,0,1)
			frame=4 if progress<.2 else 5 if progress<.45 else 6 if progress<.7 else 7
		target.draw_set_transform(p,0,Vector2(u.get("draw_facing",1.0),1)*scale_value)
		var texture=preload("res://scripts/content_extension.gd").unit_pose(index-1,frame)
		if texture!=null:
			var tint=Color(.48,1.0,.66,.5) if u.role=="wraith" else Color.WHITE if u.flash>0 else Color(.9,.93,.9)
			target.draw_texture_rect(texture,preload("res://scripts/content_extension.gd").unit_layout(index-1,frame),false,tint)

		if u.hp<u.max_hp:
			target.draw_rect(Rect2(-12,6,24,2),Color("253433"));target.draw_rect(Rect2(-12,6,24*u.hp/u.max_hp,2),Color("80c3a6"))
		target.draw_set_transform(Vector2.ZERO)

func update_owner(g,dt):
	var wanted=g.velocity.normalized() if g.velocity.length_squared()>25 else command_direction if g.time<command_until else Vector2.from_angle(owner_angle)
	owner_angle=lerp_angle(owner_angle,wanted.angle(),1-exp(-dt*14))
	cloak_angle=lerp_angle(cloak_angle,owner_angle,1-exp(-dt*5))
	var facing_angle=PI/2-pose*PI/4
	# Hysteresis prevents small input fluctuations from toggling neighboring poses.
	if absf(angle_difference(facing_angle,owner_angle))>PI/8+.12 and g.time>=pose_ready:
		pose=posmod(roundi((PI/2-owner_angle)/(PI/4)),8)
		pose_ready=g.time+.09

	trail=trail.filter(func(wisp):return g.time-wisp.at<.8)
	if g.time>=trail_ready:
		trail_ready=g.time+.07
		trail.append({"p":g.pos,"at":g.time})
		if trail.size()>12:trail.pop_front()

func draw_owner(target,p,g,tint):
	if preload("res://scripts/rite_animation.gd").caster(target,p,g,tint):return
	var moving=g.velocity.length_squared()>1
	var surge=clampf((command_until-g.time)/.55,0,1)
	var lift=-4-sin(g.time*2.3)*1.5
	for j in range(trail.size()):
		var wisp=trail[j]
		var age=clampf((g.time-wisp.at)/.8,0,1)
		var offset=wisp.p-g.pos
		target.draw_set_transform(p+offset+Vector2(sin(g.time*3+j)*3,-7-age*9),0,Vector2(1.4,.6))
		target.draw_circle(Vector2.ZERO,10+age*8,Color(.015,.02,.026,(1-age)*.09))
	target.draw_set_transform(p+Vector2(0,3),0,Vector2(1,.35))
	target.draw_circle(Vector2.ZERO,23,Color(.015,.025,.025,.3))
	if surge>0:target.draw_arc(Vector2.ZERO,24+surge*5,0,TAU,20,Color(.45,.78,.67,surge*.3),1.5)
	target.draw_set_transform(Vector2.ZERO)
	var lag=angle_difference(owner_angle,cloak_angle)
	var lean=clampf(g.velocity.x/300,-1,1)*.025+lag*.035
	var texture=preload("res://scripts/content_extension.gd").owner_pose(pose)
	if texture!=null:
		target.draw_set_transform(p+Vector2(0,lift),lean,Vector2.ONE)
		target.draw_texture_rect(texture,Rect2(-38,-68,76,76),false,tint)
		target.draw_set_transform(Vector2.ZERO)

func credit(unit,damage,killed=false):
	if damage<=0:return
	unit.damage_dealt=float(unit.get("damage_dealt",0))+damage
	unit.kills=int(unit.get("kills",0))+int(killed)
	if unit.damage_dealt>float(strongest.get("damage",0)) or strongest.get("uid",-1)==unit.uid:
		strongest={"uid":unit.uid,"name":unit.get("name","Unnamed summon"),"source":unit.source,"role":unit.role,"champion":unit.get("champion",false),"damage":unit.damage_dealt,"kills":unit.kills,"identity":unit.get("identity","")}

	if unit.kills>int(deadliest.get("kills",0)) or deadliest.get("uid",-1)==unit.uid:
		deadliest={"uid":unit.uid,"name":unit.get("name","Unnamed summon"),"source":unit.source,"role":unit.role,"damage":unit.damage_dealt,"kills":unit.kills,"identity":unit.get("identity","")}

func army_report():
	var total=0
	for count in raised_by_ability.values():total+=count
	return {"total_summoned":total,"summoned_by_ability":raised_by_ability.duplicate(),"losses":total_losses,"strongest_summon":strongest.duplicate(),"deadliest_summon":deadliest.duplicate()}

func raise_remnant(g,c):
	if units.size()>=LIMIT or units.any(func(u):return u.hp>0 and u.get("boss_form",false) and u.identity==c.identity):return false
	serial+=1
	var health={"thorn":900.0,"basalt":1300.0,"hunt":650.0,"aurora":800.0,"warden":1100.0,"bloom":1000.0}.get(c.identity,900.0)*(1+g.buff_power("armor")*.05)
	health*=1+permanent(g,"summon_health")*.06
	units.append({"uid":serial,"name":preload("res://scripts/summon_names.gd").generate(g.rng.seed,serial,"boss"),"source":"u10","role":"boss","boss_form":true,"identity":c.identity,"p":c.p,"hp":health,"max_hp":health,"champion":true,"temporary":0.0,"expires":0.0,"attack":.5,"search":0.0,"target":null,"flash":0.0,"angle":0.0,"damage_dealt":0.0,"kills":0})
	raised_by_ability["u10"]=int(raised_by_ability.get("u10",0))+1
	return true

func update_wraith(g,u,dt):
	var mods=g.Rules.modifiers(g,u.source)
	u.erase("swing")
	var state=u.get("flight","orbit")
	var destination=g.pos+Vector2.from_angle(g.time*1.8+u.angle)*110
	if state=="orbit":
		u.attack-=dt
		if u.attack<=0:
			var victim=null;var best=360.0*360
			for e in g.nearby(u.p,360):
				if not e.dead and not e.get("breakable",false) and u.p.distance_squared_to(e.p)<best:
					best=u.p.distance_squared_to(e.p);victim=e
			if victim!=null:
				u.flight="outbound";u.flight_end=victim.p+(victim.p-u.p).normalized()*90;u.flight_hits={};u.flight_until=g.time+1.8
	elif state=="outbound":
		destination=u.flight_end
	else:destination=g.pos
	var previous=u.p
	u.p=u.p.move_toward(destination,(390 if state!="orbit" else 245)*(1+mods.get("wraith_speed",0))*dt)
	u.moving=true;u.walk_phase=fmod(u.get("walk_phase",0.0)+dt*3,4)
	u.draw_facing=-1.0 if destination.x<u.p.x else 1.0
	if state=="outbound" or (state=="return" and mods.get("wraith_return",0)>0):
		for e in g.nearby(previous,previous.distance_to(u.p)+70):
			if e.dead or u.flight_hits.has(e.uid):continue
			if Geometry2D.get_closest_point_to_segment(e.p,previous,u.p).distance_to(e.p)>Contact.enemy_radius(e)+18:continue
			u.flight_hits[e.uid]=true
			strike(g,u,e,stats(g,u.source).power)
			attack_sound(g,u)
	if state=="outbound" and (u.p.distance_to(destination)<8 or g.time>=u.flight_until):
		u.flight="return";u.flight_hits={}
	elif state=="return" and u.p.distance_to(g.pos)<24:
		u.flight="orbit";u.attack=maxf(.15,.95/((1+g.buff_power("haste")*.1+rank(g,6)*.2)*(1+permanent(g,"summon_haste")*.04)))

func update_remnant_skill(g,u,victim,dt):
	if u.has("charge_end"):
		var old=u.p
		u.p=g.terrain.move(u.p,(u.charge_end-u.p).normalized()*460*dt)
		if g.boss!=null and g.boss.get("immovable",false):
			u.p=Contact.move(old,u.p,[{"p":g.boss.anchor_p,"radius":Contact.radius(u)+Contact.enemy_radius(g.boss),"seed":u.uid}])
		for e in g.nearby(old,old.distance_to(u.p)+110):
			if e.dead or u.charge_hits.has(e.uid):continue
			if Geometry2D.get_closest_point_to_segment(e.p,old,u.p).distance_to(e.p)>Contact.enemy_radius(e)+60:continue
			u.charge_hits[e.uid]=true;strike(g,u,e,stats(g,u.source).power*1.6)
		u.moving=true;u.walk_phase=fmod(u.get("walk_phase",0.0)+dt*12,4)
		if g.time>=u.charge_until or u.p.distance_to(u.charge_end)<18:u.erase("charge_end")
		return true
	if victim==null or g.time<u.get("skill_ready",0):return false
	u.skill_ready=g.time+7/(1+g.Rules.modifiers(g,u.source).get("remnant_skill_haste",0))
	match u.identity:
		"thorn","hunt":
			u.charge_end=victim.p+(victim.p-u.p).normalized()*100;u.charge_until=g.time+1.2;u.charge_hits={};attack_sound(g,u)
		"basalt","warden":
			g.effect.emit("ring",u.p,Color("96c9b4"),220)
			for e in g.nearby(u.p,220):
				if not e.dead and (e.p-u.p).normalized().dot((victim.p-u.p).normalized())>.15:
					strike(g,u,e,stats(g,u.source).power*1.4);e.slow=maxf(e.slow,1.5)
		"aurora","bloom":
			for e in g.nearby(victim.p,150):
				if not e.dead:strike(g,u,e,stats(g,u.source).power*.8);e.slow=maxf(e.slow,2.0)
			g.effect.emit("ring",victim.p,Color("8bbfd1") if u.identity=="aurora" else Color("8fc79c"),150)
	if u.identity not in ["thorn","hunt"]:
		u.swing={"elapsed":0.0,"duration":.65,"hit":true,"target":victim,"power":0.0,"stats":stats(g,u.source),"aim":(victim.p-u.p).normalized()}
	return false

func draw_auras(target,g,screen_pos):
	for wave in ground_ruptures:
		var side:Vector2=wave.aim.orthogonal()
		for j in range(16):
			var distance:float=j*24.0
			if distance>wave.distance:break
			var age:float=wave.age-distance/480.0
			var fade:float=clampf(1-age/.55,0,1)
			if fade<=0:continue
			var center:Vector2=screen_pos.call(wave.origin+wave.aim*distance)
			var width:float=wave.width*(.65+.25*sin(j*2.3))
			# Dust, shadow and a broken seam stay on the ground; lifted stones carry the motion.
			target.draw_set_transform(center,0,Vector2(1,.32))
			target.draw_circle(Vector2.ZERO,width+10,Color(.40,.36,.25,fade*.18))
			target.draw_set_transform(Vector2.ZERO)
			var seam=PackedVector2Array([center-side*width,center-side*width*.4+wave.aim*4,center+side*width*.2-wave.aim*3,center+side*width])
			target.draw_polyline(seam,Color(.08,.09,.07,fade*.8),3,true)
			target.draw_polyline(seam,Color(.52,.67,.42,fade*.35),1,true)
			for k in range(3):
				var at:Vector2=center+side*(k-1)*width*.65
				var lift:float=sin(clampf(age/.36,0,1)*PI)*(25+6*sin(j*1.7+k))
				target.draw_set_transform(at,0,Vector2(1,.3))
				target.draw_circle(Vector2.ZERO,10,Color(.06,.07,.04,fade*.5))
				target.draw_set_transform(Vector2.ZERO)
				var index:int=posmod(j*5+k*3,6)
				var cell:Vector2=Vector2(EARTH_SHARDS.get_size())/Vector2(3,2)
				var source=Rect2(Vector2(index%3,index/3)*cell,cell)
				var size_value:float=32+8*sin(j*2.3+k)
				target.draw_texture_rect_region(EARTH_SHARDS,Rect2(at+Vector2(-size_value*.5,4-size_value-lift),Vector2.ONE*size_value),source,Color(.78,.81,.72,fade))
	for id in g.weapons:
		var d=g.C.WEAPONS[id]
		if d.get("role","") not in ["chill","banner"] and d.delivery!="aura":continue
		var radius=minf(160,stats(g,id).radius)*(1+g.Rules.modifiers(g,id).get("chill_reach",0)) if d.get("role","")=="chill" else stats(g,id).radius
		var center=screen_pos.call(g.pos)
		var tone=Color("78cbb9") if d.get("role","")=="chill" else Color("a093c7")
		target.draw_arc(center,radius,0,TAU,64,Color(tone,.17),1.5,true)
		for j in range(10):
			var angle=g.time*.18+j*TAU/10
			var at=center+Vector2.from_angle(angle)*radius*(.88+sin(g.time+j)*.04)
			target.draw_arc(at,5,angle,angle+PI,8,Color(tone,.3),1.2,true)

func remnant_impact(g,u,victim,power):
	var area=1+g.Rules.modifiers(g,u.source).get("remnant_area",0)
	attack_sound(g,u)
	match u.identity:

		"aurora":
			var count=0
			for e in g.nearby(victim.p,180*area):
				if e.dead:continue
				strike(g,u,e,power*.65);count+=1
				g.effect.emit("blast_club",e.p,Color("8bbfd1"),22)
				if count>=3:break
		_:
			if u.p.distance_to(victim.p)>170+victim.size:return
			var radius=(180.0 if u.identity=="basalt" else 120.0 if u.identity=="bloom" else 90.0)*area
			var hit_count=0
			for e in g.nearby(victim.p,radius*g.area_scale()):
				if e.dead:continue
				strike(g,u,e,power*(1.3 if u.identity=="basalt" else 1));hit_count+=1
				if hit_count>=48:break
			g.effect.emit("ring",victim.p,Color("9bccae"),radius)

