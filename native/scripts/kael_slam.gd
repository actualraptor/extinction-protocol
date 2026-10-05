extends RefCounted
const Art=preload("res://scripts/kael_attack_animation.gd")
static func applies(g,id):return g.hero==1 and id in ["club","earthshaker"]
static func start(g,id,aim,stats):
	# Even extreme cadence must reach impact before another attack replaces it.
	var duration=clampf(stats.cooldown*.85,.01,.60)
	g.kael_attack={"id":id,"aim":aim,"stats":stats.duplicate(true),"start":g.time,"duration":duration,"hit":false,"visual_until":0.0}
static func update(g):
	if g.kael_attack.is_empty():return
	var a=g.kael_attack
	if not g.weapons.has(a.id):g.kael_attack={};return
	var age=g.time-a.start
	if not a.hit and age>=a.duration*Art.IMPACT_PROGRESS:
		a.hit=true;a.visual_until=g.time+minf(.04,a.duration*.15)
		impact(g,a.id,a.aim,a.stats)
		for i in range(mini(8,a.stats.repeat)):
			if g.echoes.size()<32:g.echoes.append({"wait":.16*(i+1),"id":a.id,"aim":a.aim,"stats":a.stats.duplicate(),"slam":true})
		if g.weapons[a.id].level>=7 and g.echoes.size()<96:
			var aftershock=a.stats.duplicate(true)
			aftershock.power*=.55;aftershock.hit_limit=8
			g.echoes.append({"wait":.24,"id":a.id,"aim":a.aim,"stats":aftershock,"slam":true})
	if age>=a.duration and g.time>=a.visual_until:g.kael_attack={}
static func progress(g):
	if g.kael_attack.is_empty():return -1.0
	var a=g.kael_attack
	if a.hit and g.time<=a.visual_until:return .67
	return clampf((g.time-a.start)/a.duration,0,1)
static func impact(g,id,aim,s,echo=false):
	var origin=Art.impact_point(g.pos,aim.x<0)
	var strong=id=="earthshaker" or g.weapons.get(id,{}).get("evolved",false)
	var bands=4 if strong else 3
	var material="ice" if g.map_id=="frostbreak" else "dirt" if g.map_id=="cradle" and g.depth==0 else "stone"
	var cadence=maxf(.01,s.cooldown)
	var interval=clampf(cadence*.16,.012,.065)
	var life=clampf(cadence*.72,.10,.46)
	var shared={"seen":{},"origin":origin,"radius":s.radius,"power":s.power,"bands":bands,"material":material,"strong":strong,"id":id,"hit_limit":s.get("hit_limit",0),"life":life,"glow":2 if id=="earthshaker" else 1 if strong else 0}
	g.effect.emit("kael_crater_%s_0_%s_%s_%s"%[material,bands,roundi(life*1000),shared.glow],origin,Color("b4edff" if material=="ice" else "e6ad66"),s.radius/float(bands)*.6)
	pulse(g,shared,0)
	for band in range(1,bands):
		if g.echoes.size()<96:g.echoes.append({"wait":band*interval,"id":id,"radial":shared,"band":band})
	if not echo:
		g.sound.emit("club")
		g.effect.emit("impact",origin,Color("b9edff" if material=="ice" else "e1c398"),1)
static func pulse(g,wave,band):
	var outer=wave.radius*float(band+1)/wave.bands
	var inner=wave.radius*float(band)/wave.bands
	var color=Color("b4edff" if wave.material=="ice" else "bc9460" if wave.material=="dirt" else "a5afbd")
	g.effect.emit("kael_slam_%s_%s_%s_%s_%s"%[wave.material,band,wave.bands,roundi(wave.get("life",.46)*1000),wave.get("glow",0)],wave.origin,color,outer)
	for e in g.nearby(wave.origin,outer):
		if wave.hit_limit>0 and wave.seen.size()>=wave.hit_limit:break
		if wave.seen.has(e.uid):continue
		var delta=e.p-wave.origin
		if delta.length()>outer+e.size or delta.length()+e.size<inner:continue
		wave.seen[e.uid]=true
		g.hit(e,wave.power,wave.id)
		if not e.boss and not e.anchor and not e.get("boss_prop",false) and not g.rooted(e):e.p=g.terrain.move(e.p,delta.normalized()*(60 if wave.strong else 45))
