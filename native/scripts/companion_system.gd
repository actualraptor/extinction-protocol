extends RefCounted

const LIMIT = 64
const TEMP_LIMIT = 16
var raised_by_ability = {}
var strongest = {}
var total_losses = 0
var units = []
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
func relic(g,n): return g.Relics.strength(g,"r%02d"%n) if "r%02d"%n in g.relics else 0.0
func role(g,id): return g.C.WEAPONS[id].get("role","")
func owned(g,r):
	for id in g.weapons:
		if role(g,id)==r: return id
	return ""
func capacity(g,id):
	var r = role(g,id)
	var w = g.weapons[id]
	match r:
		"warrior": return mini(36,4+int(w.level>=5)+(8 if w.evolved else 0)+int(rank(g,5))*2+roundi(relic(g,0)*2)+mini(5,int(souls/100)) * int(rank(g,1)>0))
		"guard": return 2+int(w.level>=5)+(2 if w.evolved else 0)
		"archer": return 3+int(w.level>=5)+(3 if w.evolved else 0)
		"wraith": return 2+int(w.level>=5)+(2 if w.evolved else 0)
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
	var p=g.terrain.open_position(g.pos+Vector2.from_angle(serial*2.4)*70)
	units.append({"uid":serial,"damage_dealt":0.0,"kills":0,"p":p,"hp":float(health),"max_hp":float(health),"source":id,"role":r,"champion":champion,"temporary":temporary,"expires":g.time+temporary,"attack":.25,"search":0.0,"target":null,"flash":0.0,"angle":serial*2.4})
	if not first_summon:
		first_summon=true
		g.voice_event.emit("first_summon")
	if r=="colossus":g.voice_event.emit("colossus_summoned")
	g.effect.emit("ring",p,Color("8dc7b5"),25)
	return true

func stats(g,id):
	if g.weapons.has(id):return g.Rules.stats(g,id)
	return {"power":g.C.WEAPONS[id].damage*g.damage_scale(id),"count":1,"radius":100*g.area_scale()}

func cast(g,id,s):
	var r=role(g,id)
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
		if r=="spear":
			for u in units:
				if u.champion: origin=u.p; break
		for j in range(mini(8,s.count)):
			g.shoot(id,origin,(target.p-origin).normalized().rotated((j-(s.count-1)*.5)*.12),s.power,s.velocity,s.lifetime,8 if r=="spear" else 1)
		return
	if r=="chill":
		var centers=[g.pos]
		for u in units: centers.append(u.p)
		var seen={}
		for p in centers:
			for e in g.nearby(p,minf(160,s.radius)):
				if seen.has(e.uid): continue
				seen[e.uid]=true
				e.slow=maxf(e.slow,1.5)
				e.dread=minf(.5,e.get("dread",0.0)+.03)
				g.hit(e,s.power,id,false,false)

func update(g,dt):
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
				total_losses+=1
				losses.append(g.time)
				if relic(g,6)>0 and pending.size()<24: pending.append({"p":u.p,"damage":45*relic(g,6),"id":u.source})
				if u.temporary<=0 and reform.size()<LIMIT: reform.append({"id":u.source,"at":g.time+(1.5 if g.weapons.get(u.source,{}).get("evolved",false) else 3.0)})
			continue
		survivors.append(u)
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
				if dist<best: best=dist;u.target=e
		var target=u.target
		if target!=null and not u.has("swing") and absf(target.p.x-u.p.x)>4:u.draw_facing=-1.0 if target.p.x<u.p.x else 1.0
		if target!=null and target.dead: target=null
		var speed=180.0 if u.champion else 245.0
		if u.role=="colossus": speed=135
		var range_value=230.0 if u.role=="archer" else 70.0 if u.role=="colossus" else 48.0
		var old_position=u.p
		var destination=g.pos+Vector2.from_angle(u.angle)*90
		if target!=null: destination=target.p
		if u.role=="wraith":
			var orbit=g.pos+Vector2.from_angle(g.time*1.8+u.angle)*110
			destination=target.p if u.attack<.5 and target!=null else orbit
		if not u.has("swing") and (u.p.distance_squared_to(destination)>range_value*range_value or u.role=="wraith"):
			u.p=g.terrain.move(u.p,(destination-u.p).normalized()*speed*dt)
		u.moving=u.p.distance_squared_to(old_position)>.01
		u.walk_phase=fmod(u.get("walk_phase",0.0)+u.p.distance_to(old_position)/24.0,4.0)
		var banner=relic(g,3) if u.p.distance_squared_to(g.pos)<300*300 else 0.0
		if target!=null and u.p.distance_squared_to(target.p)<pow(28+target.size,2) and g.time>=u.get("hurt_at",0):
			u.hp-=maxf(2,9+g.depth*4-(5 if u.champion else 0)-banner*3)
			u.hurt_at=g.time+.8;u.flash=.15
		animate_attack(g,u,dt)
		u.attack-=dt
		if target==null or u.attack>0 or u.has("swing") or u.p.distance_squared_to(target.p)>range_value*range_value: continue
		var s=stats(g,u.source)
		var haste=1+rank(g,6)*.2+banner*.15+(empowerment if g.time<empowerment_until else 0)
		u.attack=maxf(.15,(1.7 if u.role=="colossus" else .95)/((1+g.buff_power("haste")*.1)*haste))
		var power=s.power*(1.8 if u.champion else 1.0)*(1+momentum*.025+(rank(g,3)*.2 if u.p.distance_squared_to(g.pos)<300*300 else 0)+banner*.15+relic(g,5)*stationary*.025)
		if u.champion: power*=1+relic(g,0)*.35
		if g.time<empowerment_until: power*=1.5
		u.swing={"elapsed":0.0,"duration":minf(.5,u.attack*.8),"hit":false,"target":target,"power":power,"stats":s,"aim":(target.p-u.p).normalized()}

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
				if summon(g,event.summon,12):g.voice_event.emit("resurrection")
			else: g.blast(event.p,100*g.area_scale(),event.damage,event.id)

func animate_attack(g,u,dt):
	if not u.has("swing"):return
	var swing=u.swing
	swing.elapsed+=dt
	if not swing.hit and swing.elapsed>=swing.duration*.45:
		swing.hit=true
		var victim=swing.target
		if victim!=null and not victim.dead:
			if u.role=="archer":
				attack_sound(g,u)
				for j in range(mini(6,swing.stats.count)):
					var projectile=g.shoot(u.source,u.p,(victim.p-u.p).normalized().rotated((j-(swing.stats.count-1)*.5)*.08),swing.power,600,1.2,2)
					if projectile!=null:projectile.companion=u
			elif u.p.distance_to(victim.p)<=100+victim.size:
				attack_sound(g,u)
				var cleave=u.champion or u.role in ["wraith","colossus"] or g.weapons.get(u.source,{}).get("level",1)>=3
				if cleave:
					var count=0
					for e in g.nearby(victim.p,minf(180,swing.stats.radius*(1.3 if u.role=="colossus" else .55))):
						strike(g,u,e,swing.power);count+=1
						if count>=24:break
				else:strike(g,u,victim,swing.power)
	if swing.elapsed>=swing.duration:u.erase("swing")

func attack_sound(g,u):
	# One sound per completed strike/volley, never per cleaved enemy.
	if u.p.distance_squared_to(g.pos)>900*900:return
	var id={"warrior":"unit_blade","guard":"unit_guard","archer":"unit_bow","wraith":"unit_wraith","colossus":"unit_heavy"}.get(u.role,"unit_blade")
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
	if ce!="" and near and g.rng.randf()<.15+g.weapons[ce].level*.015:
		pending.append({"p":e.p,"damage":g.Rules.stats(g,ce).power+minf(300,e.max_hp*.08),"id":ce})
	var r=owned(g,"reanimate")
	if r!="" and g.kills%maxi(4,12-g.weapons[r].level/2)==0: pending.append({"summon":base})
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
		var index=5 if u.role=="colossus" else 4 if u.role=="wraith" else 3 if u.role=="archer" else 2 if u.champion else 1
		var frame=int(u.get("walk_phase",0.0)) if u.get("moving",false) else 0
		if u.has("swing"):
			var progress=clampf(u.swing.elapsed/u.swing.duration,0,1)
			frame=4 if progress<.2 else 5 if progress<.45 else 6 if progress<.7 else 7
		target.draw_set_transform(p,0,Vector2(u.get("draw_facing",1.0),1)*scale_value)
		var texture=preload("res://scripts/content_extension.gd").unit_pose(index-1,frame)
		if texture!=null:target.draw_texture_rect(texture,preload("res://scripts/content_extension.gd").unit_layout(index-1,frame),false,Color.WHITE if u.flash>0 else Color(.9,.93,.9))

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
		strongest={"uid":unit.uid,"source":unit.source,"role":unit.role,"champion":unit.get("champion",false),"damage":unit.damage_dealt,"kills":unit.kills}

func army_report():
	var total=0
	for count in raised_by_ability.values():total+=count
	return {"total_summoned":total,"summoned_by_ability":raised_by_ability.duplicate(),"losses":total_losses,"strongest_summon":strongest.duplicate()}
