extends RefCounted
const Content=preload("res://scripts/tfk_content.gd")
const MAX_CHARGE=100.0
const EMPOWER_SECONDS=8.0
static func update(g,dt):
	if not Content.active(g):return
	var dense=g.enemies.size()>=80
	if dense and not g.tfk_state.get("dense_wave",false):preload("res://scripts/tfk_dialogue.gd").speak(g,"large_wave")
	g.tfk_state.dense_wave=dense
	g.tfk_state.empowered=maxf(0,g.tfk_state.get("empowered",0.0)-dt)
	g.tfk_state.weapon_visuals=g.tfk_state.get("weapon_visuals",[]).filter(func(v):return g.time-v.at<v.duration)
	var visuals=g.tfk_state.get("scenario_visuals",[])
	g.tfk_state.scenario_visuals=[]
	for visual in visuals:
		visual.age+=dt
		if visual.age<visual.duration:g.tfk_state.scenario_visuals.append(visual)
	var events=g.tfk_state.get("events",[]);g.tfk_state.events=[]
	for event in events:
		event.wait-=dt
		if event.wait>0:g.tfk_state.events.append(event)
		else:resolve(g,event)
	var missiles=g.tfk_state.get("missiles",[]);g.tfk_state.missiles=[]
	for missile in missiles:
		missile.life-=dt
		if missile.life<=0:continue
		var target=missile.target
		if target.dead:target=g.nearest(missile.p);missile.target=target
		if target==null:continue
		missile.p=missile.p.move_toward(target.p,300*dt)
		if missile.p.distance_to(target.p)<18:
			fact(g,target,missile.power,missile.effect,missile.duration,missile.get("propagated",false),missile.get("id","tfk_facts"))
		else:g.tfk_state.missiles.append(missile)
static func charge(g,amount):
	if not Content.active(g) or g.tfk_state.get("empowered",0.0)>0 or g.tfk_state.get("replaying",false):return
	g.tfk_state.charge=minf(MAX_CHARGE,g.tfk_state.get("charge",0.0)+amount)
	if g.tfk_state.charge>=MAX_CHARGE:
		g.tfk_state.charge=0.0;g.tfk_state.empowered=EMPOWER_SECONDS
		g.effect.emit("ring",g.pos,Color("ffd76c"),120)
		g.sound.emit("tfk_reveal")
		g.banner.emit("FULLSTÄNDIGT URSPÅRAT","Nu spårar det ur!")
		preload("res://scripts/tfk_dialogue.gd").speak(g,"meter_full")
		if g.Relics.modifiers(g).get("tfk_reunion",0)>0:
			preload("res://scripts/tfk_items.gd").cameo(g,"Jimmy Woolke",2.0)
			preload("res://scripts/tfk_dialogue.gd").speak(g,"reunion")
			if g.weapons.has("tfk_scenario") or g.weapons.has("tfk_disaster"):
				var id="tfk_scenario" if g.weapons.has("tfk_scenario") else "tfk_disaster"
				schedule(g,{"wait":.4,"kind":"blast","id":id,"p":g.pos,"radius":180.0,"power":g.Rules.stats(g,id).power,"label":"TACK FÖR KAFFET!"})
static func cast(g,id,s):
	if id!="tfk_phone":return arsenal_cast(g,id,s)
	var origin=g.pos+Vector2(-17,0)
	var result={}
	var branches=g.weapons[id].get("branches",{})
	var count=mini(24,s.count+(2 if branches.get("5","")=="chain" else 0)+(2 if g.tfk_state.get("empowered",0.0)>0 else 0))
	var reach=s.range*(1.45 if branches.get("5","")=="reach" else 1.0)
	var chain=preload("res://scripts/chain_system.gd")
	if chain.cast(g,origin,s.power,id,count,reach,s.falloff,s.fork,s.rechain,Vector2.INF,result,500.0)==0:return false
	var last=result.last
	if branches.get("10","")=="blast" or g.weapons[id].evolved:g.blast(last.p,s.radius,s.power*.65,id)
	if branches.get("10","")=="repeat":
		chain.cast(g,g.pos,s.power*.5,id,mini(12,count),reach,s.falloff,s.fork,s.rechain)
	preload("res://scripts/tfk_weapon_animation.gd").cue(g,id,g.pos,45)
	g.tfk_state.pose_until=g.time+.35
	g.tfk_state.pose_host="mathie"
	g.tfk_state.phone_pose_until=g.time+.5
	var alternating=g.tfk_state.get("last_host","mathie")!="mathie"
	g.tfk_state.last_host="mathie"
	charge(g,6.0 if alternating else 3.0)
	preload("res://scripts/tfk_dialogue.gd").speak(g,"ring_en_framling")
	return true

static func schedule(g,event):
	if not g.active:return
	if not g.tfk_state.has("events"):g.tfk_state.events=[]
	if g.tfk_state.events.size()<48:g.tfk_state.events.append(event)
static func arsenal_cast(g,id,s):
	if id in preload("res://scripts/tfk_items.gd").RECIPES:return union_cast(g,id,s)
	var b=g.weapons[id].get("branches",{})
	var evolved=g.weapons[id].evolved
	var target=g.weapon_target(id)
	if target==null and id!="tfk_backpack":return false
	var radius=s.radius*(1.4 if b.get("5","")=="area" else 1.0)
	match id:
		"tfk_backpack":
			var stored=g.tfk_state.get("stored",0.0)
			if stored<15:return false
			g.tfk_state.stored=0.0
			var waves=3 if evolved or b.get("10","")=="waves" else 1
			for i in range(waves):schedule(g,{"wait":i*.3,"kind":"blast","id":id,"p":g.pos,"radius":radius*(1+i*.35),"power":s.power+stored*.65/waves})
		"tfk_list":
			for i in range(5):
				var p=target.p+Vector2.from_angle(i*TAU/5)*i*12
				schedule(g,{"wait":.5+i*(.25 if b.get("5","")=="tempo" else .4),"kind":"blast","id":id,"p":p,"radius":radius,"power":s.power*(1+i*.25),"number":5-i})
				g.effect.emit("ring",p,Color("ffd76c"),radius)
			if evolved or b.get("10","")=="finale":schedule(g,{"wait":.5+5*(.25 if b.get("5","")=="tempo" else .4),"kind":"blast","id":id,"p":target.p,"radius":radius*2.5,"power":s.power*3.6,"number":1,"finale":true})
			if b.get("10","")=="double":schedule(g,{"wait":2.2,"kind":"blast","id":id,"p":target.p+Vector2(90,0),"radius":radius,"power":s.power*2,"number":1})
		"tfk_facts":
			if not g.tfk_state.has("missiles"):g.tfk_state.missiles=[]
			for i in range(mini(8,s.count+(2 if b.get("5","")=="count" else 0))):
				if g.tfk_state.missiles.size()>=32:break
				g.tfk_state.missiles.append({"p":g.pos+Vector2(-18,i*6),"target":target,"life":3.0,"power":s.power,"effect":g.rng.randi_range(0,3),"duration":4.0 if b.get("5","")=="status" else 2.0})
		"tfk_eyes":
			g.tfk_state.eyes_visual={"p":target.p,"at":g.time,"duration":.8,"radius":radius}
			for e in g.nearby(target.p,radius):
				g.hit(e,s.power,id)
				if not e.boss and not e.anchor:e.frozen=maxf(e.get("frozen",0),3.0 if b.get("5","")=="duration" else 1.5)
				if evolved or b.get("10","")=="fear":
					e.tfk_vulnerable_until=g.time+3
					if not e.boss and not e.anchor:e.tfk_fear_until=g.time+3
			g.effect.emit("ring",target.p,Color("89d8ed"),radius)
			if b.get("10","")=="pulse":schedule(g,{"wait":.6,"kind":"eyes","id":id,"p":target.p,"radius":radius,"power":s.power})
		"tfk_mac":
			g.tfk_state.mac_visual={"p":g.pos+Vector2(18,0),"at":g.time,"duration":.65}
			preload("res://scripts/chain_system.gd").cast(g,g.pos,s.power,id,mini(24,s.count+(3 if b.get("5","")=="chain" else 0)),s.range*(1.5 if b.get("10","")=="network" else 1.0),s.falloff,s.fork,s.rechain)
			g.tfk_state.mac_casts=g.tfk_state.get("mac_casts",0)+1
			if (evolved or b.get("10","")=="overheat") and g.tfk_state.mac_casts%3==0:
				g.blast(g.pos,radius,s.power*1.2,id)
				for e in g.nearby(g.pos,radius):
					if not e.boss and not e.anchor:e.frozen=maxf(e.get("frozen",0),.6)
		"tfk_scenario":
			var count=3 if g.tfk_state.get("empowered",0)>0 and (evolved or b.get("10","")=="double") else 2 if evolved or b.get("10","")=="double" else 1
			g.tfk_state.cameo_until=g.time+2.5
			g.tfk_state.cameo="Jimmy Woolke"
			for i in range(count):
				var scenario=g.rng.randi_range(0,4)
				g.tfk_state.scenario=scenario
				var power=s.power*(1.6 if b.get("10","")=="focus" else 1.0)
				var size=radius*(1.4 if b.get("5","")=="scale" else 1.0)
				scenario_event(g,scenario,id,target.p,power,size,i*.2)
		_:return false
	preload("res://scripts/tfk_weapon_animation.gd").cue(g,id,g.pos,45)
	g.tfk_state.pose_until=g.time+.35
	var host="mathie" if id in ["tfk_facts","tfk_phone","tfk_backpack"] else "johan"
	g.tfk_state.pose_host=host
	var alternating=g.tfk_state.get("last_host",host)!=host
	g.tfk_state.last_host=host
	var dialogue={"tfk_list":"johans_topplista","tfk_facts":"mathies_fakta","tfk_scenario":"dagens_scenario"}
	if dialogue.has(id):preload("res://scripts/tfk_dialogue.gd").speak(g,dialogue[id])
	charge(g,6.0 if alternating else 3.0)
	return true

static func scenario_event(g,scenario,id,p,power,radius,delay):
	match scenario:
		0:
			if not g.tfk_state.has("scenario_visuals"):g.tfk_state.scenario_visuals=[]
			if g.tfk_state.scenario_visuals.size()<8:
				g.tfk_state.scenario_visuals.append({"age":-delay,"duration":1.4,"p":g.pos,"kind":"trex"})
			for i in range(6):schedule(g,{"wait":delay+.15+.2*i,"kind":"blast","id":id,"p":g.pos+Vector2(-240+i*90,0),"radius":radius*.4,"power":power*.65,"visual":"trex"})
		1:
			schedule(g,{"wait":delay+.3,"kind":"knockback","id":id,"p":g.pos,"radius":radius*1.5,"power":power})
		2:
			schedule(g,{"wait":delay+5,"kind":"blast","id":id,"p":p,"radius":radius,"power":power*2,"label":"5 SEKUNDER"});g.effect.emit("ring",p,Color("f5b08b"),radius)
		3:
			for i in range(8):schedule(g,{"wait":delay+.6+.2*i,"kind":"blast","id":id,"p":p+Vector2.from_angle(i*TAU/8)*80,"radius":radius*.19,"power":power*.35,"visual":"coin"})
		4:
			g.tfk_state.separate_started=g.time
			g.tfk_state.separate_until=g.time+1.0
			schedule(g,{"wait":delay+1,"kind":"blast","id":id,"p":g.pos,"radius":radius,"power":power*1.5,"label":"TILLSAMMANS"})
static func resolve(g,event):
	if not g.active or not g.weapons.has(event.id):return
	if event.kind=="replay":
		g.tfk_state.replaying=true
		cast(g,event.id,event.stats)
		g.tfk_state.replaying=false
		return
	if event.kind=="fact_spread":
		var count=0
		for e in g.nearby(event.p,120):
			if e.dead:continue
			fact(g,e,event.power*.35,event.effect,1.0,true)
			count+=1
			if count>=3:break
		return
	g.blast(event.p,event.radius,event.power,event.id)
	if event.get("finale",false):g.tfk_state.list_impact={"p":event.p,"at":g.time,"radius":event.radius}
	if event.get("label","")=="MIKROFON":g.tfk_state.microphone_impact={"p":event.p,"at":g.time,"radius":event.radius}
	if event.kind=="knockback":
		for e in g.nearby(event.p,event.radius):
			if not e.boss and not e.anchor:e.p=g.terrain.move(e.p,(e.p-event.p).normalized()*100)
	if event.kind=="eyes":
		for e in g.nearby(event.p,event.radius):
			if not e.boss and not e.anchor:e.frozen=maxf(e.get("frozen",0),1.0)
static func fact(g,e,power,effect,duration,propagated=false,id="tfk_facts"):
	if not g.weapons.has(id):return
	var b=g.weapons[id].get("branches",{})
	for i in range(2 if b.get("10","")=="mix" else 1):
		match (effect+i)%4:
			0:e.burn=duration;e.burn_tick=.5;e.burn_damage=power*.12;e.burn_source=id
			1:
				if not e.boss and not e.anchor:e.frozen=duration
			2:
				if not e.boss and not e.anchor:e.tfk_fear_until=g.time+duration
			3:e.tfk_vulnerable_until=g.time+duration
	if not propagated and (g.weapons[id].evolved or b.get("10","")=="spread"):e.tfk_fact_mark=true;e.tfk_fact_effect=effect;e.tfk_fact_power=power
	g.hit(e,power,id)
static func absorb(g,amount):
	if not Content.active(g) or not (g.weapons.has("tfk_backpack") or g.weapons.has("tfk_meltdown")):return amount
	var id="tfk_backpack" if g.weapons.has("tfk_backpack") else "tfk_meltdown"
	var b=g.weapons[id].get("branches",{})
	var cap=150.0 if b.get("5","")=="capacity" else 100.0
	var stored=g.tfk_state.get("stored",0.0)
	var absorbed=minf(amount*(.35 if b.get("10","")=="guard" else .2),maxf(0,cap-stored))
	g.tfk_state.stored=stored+absorbed
	return amount-absorbed
static func on_kill(g,e):
	if not Content.active(g):return
	charge(g,2.0)
	if not e.get("tfk_fact_mark",false):return
	e.tfk_fact_mark=false
	schedule(g,{"wait":.01,"kind":"fact_spread","id":"tfk_facts","p":e.p,"power":e.get("tfk_fact_power",0),"effect":e.get("tfk_fact_effect",0)})
static func union_cast(g,id,s):
	var mods=g.Rules.modifiers(g,id)
	var target=g.weapon_target(id)
	if target==null:return false
	match id:
		"tfk_broadcast":
			preload("res://scripts/chain_system.gd").cast(g,g.pos,s.power,id,mini(24,s.count+3),s.range,s.falloff,s.fork,s.rechain)
			for echo in 1+int(mods.get("union_microphone",0)):
				schedule(g,{"wait":.8+echo*.35,"kind":"knockback" if mods.get("union_push",0)>0 else "blast","id":id,"p":target.p,"radius":s.radius,"power":s.power*(1.8 if echo==0 else .9),"label":"MIKROFON"})
		"tfk_meltdown":
			var stored=g.tfk_state.get("stored",0.0)
			if stored<15:return false
			g.tfk_state.stored=0.0
			g.blast(g.pos,s.radius,s.power+stored*.5,id)
			if not g.active:return true
			if not g.tfk_state.has("missiles"):g.tfk_state.missiles=[]
			var count=0
			for e in g.nearby(g.pos,s.radius):
				if e.dead:continue
				if g.tfk_state.missiles.size()>=32:break
				g.tfk_state.missiles.append({"p":g.pos+Vector2.from_angle(count*TAU/12)*25,"target":e,"life":3.0,"power":s.power*.4,"effect":g.rng.randi_range(0,3),"duration":2.0+mods.get("status",0),"propagated":true,"id":id})
				count+=1
				if count>=mini(16,12+int(mods.get("union_missiles",0))):break
		"tfk_disaster":
			preload("res://scripts/tfk_items.gd").cameo(g,"Jimmy Woolke",2.5)
			g.tfk_state.broadcast_visual={"p":g.pos,"at":g.time,"duration":2.5}
			var bonus=1+minf(.5,g.Relics.modifiers(g).get("tfk_reunion",0))
			var radius=s.radius*(1+mods.get("scenario_area",0))
			for i in mini(4,(3 if g.tfk_state.get("empowered",0)>0 else 2)+int(mods.get("union_scenarios",0))):
				var scenario=g.rng.randi_range(0,4)
				scenario_event(g,scenario,id,target.p,s.power*bonus,radius,i*.3)
				if mods.get("union_echo",0)>0:scenario_event(g,scenario,id,target.p,s.power*bonus*.5,radius,1.25+i*.3)
			if mods.get("union_push",0)>0:schedule(g,{"wait":2.0,"kind":"knockback","id":id,"p":g.pos,"radius":s.radius,"power":s.power*.8})
	charge(g,6)
	return true
