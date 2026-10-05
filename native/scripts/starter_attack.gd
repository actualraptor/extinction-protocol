extends RefCounted
const Chain=preload("res://scripts/chain_system.gd")
const Art=preload("res://scripts/hero_attack_animation.gd")
const IMPACT_PROGRESS=.62
static func applies(g,id):return (g.hero==0 and id=="revolver") or (g.hero==2 and id=="lightning")
static func aim(g,id,fallback):
	var target=g.weapon_target(id)
	return (target.p-g.pos).normalized() if target!=null else fallback
static func emission(g,direction):return g.pos+Art.emission_offset(g.hero,g.halloween,direction.x<0)
static func release_aim(g,id,origin,fallback):
	var target=g.weapon_target(id)
	return (target.p-origin).normalized() if target!=null else fallback
static func volley(g,v):
	var facing=aim(g,v.id,v.dir)
	if g.starter_attack.is_empty():
		g.starter_attack={"id":v.id,"aim":facing,"stats":{},"start":g.time,"duration":.06,"hit":true,"visual_until":g.time+.04,"carry_until":0.0}
	else:
		g.starter_attack.aim=facing
		g.starter_attack.carry_until=g.time+.04
	var origin=emission(g,facing)
	g.shoot(v.id,origin,release_aim(g,v.id,origin,facing).rotated(v.get("spread",0.0)),v.power,v.velocity,v.life,v.pierce)
static func start(g,id,direction,stats):
	# Resolve an overdue attack before replacing its pose, even after a long
	# frame. One bounded state cannot silently discard a scheduled shot.
	if not g.starter_attack.is_empty() and not g.starter_attack.hit:release(g,g.starter_attack)
	var carry_until=g.starter_attack.get("visual_until",0.0)
	var duration=minf(.32 if id=="revolver" else .56,stats.cooldown*.85)
	g.starter_attack={"id":id,"aim":direction,"stats":stats.duplicate(true),"start":g.time,"duration":duration,"hit":false,"visual_until":0.0,"carry_until":carry_until}
static func update(g):
	if g.starter_attack.is_empty():return
	var a=g.starter_attack
	if not g.weapons.has(a.id):g.starter_attack.clear();return
	if not a.hit and g.time-a.start>=a.duration*IMPACT_PROGRESS:release(g,a)
	if g.time-a.start>=a.duration and g.time>a.visual_until:g.starter_attack.clear()
static func progress(g):
	var a=g.starter_attack
	if a.is_empty():return -1.0
	if a.get("carry_until",0)>g.time:return .67
	if a.hit and g.time<=a.visual_until:return .67
	return clampf((g.time-a.start)/a.duration,0,1)
static func release(g,a):
	if a.hit or not g.weapons.has(a.id):return
	a.hit=true;a.visual_until=g.time+minf(.04,a.duration*.15)
	a.aim=aim(g,a.id,a.aim)
	var origin=emission(g,a.aim)
	var trajectory=release_aim(g,a.id,origin,a.aim)
	var s=a.stats
	var d=g.C.WEAPONS[a.id]
	g.sound.emit(a.id)
	if d.has("secondary"):
		var extra=d.secondary
		for j in range(extra.count):g.shoot(a.id,origin,trajectory.rotated((j-(extra.count-1)*.5)*.14),s.power*extra.power,extra.velocity,extra.lifetime,extra.pierce)
	if a.id=="lightning":
		Chain.cast(g,origin,s.power,a.id,s.count,s.range,s.falloff,s.fork,s.rechain,g.pos)
	else:
		var pierce=1 if "EXPLOSION" in d.tags or "RICOCHET" in d.tags else s.pierce
		for j in range(mini(24,s.count)):
			var spread=0.0 if j==0 else ceilf(j/2.0)*.13*(1 if j%2==1 else -1)
			if j==0:g.shoot(a.id,origin,trajectory,s.power,s.velocity,s.lifetime,pierce)
			elif g.volleys.size()<80:g.volleys.append({"wait":j*d.projectile_interval,"id":a.id,"dir":a.aim,"spread":spread,"starter":true,"power":s.power,"velocity":s.velocity,"life":s.lifetime,"pierce":pierce})
