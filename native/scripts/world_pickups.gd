extends RefCounted
const DEFINITIONS = {
	"amber":{"name":"AMBER CACHE","desc":"+8 amber","duration":0.0,"icon":7,"color":"ffc76e"},
	"freeze":{"name":"TIME FRACTURE","desc":"Ecosystem frozen for 6s. Bosses resist.","duration":6.0,"icon":0,"color":"91eaff"},
	"magnet":{"name":"GRAVITY WELL","desc":"Draw in all experience, including new drops, for 5 seconds.","duration":5.0,"icon":1,"color":"81ffd0"},
	"heal":{"name":"SECOND CHANCE","desc":"35% maximum health restored.","duration":0.0,"icon":2,"color":"ff819a"},
	"nuke":{"name":"LOCAL EXTINCTION","desc":"Lesser creatures erased. Bosses endure.","duration":0.0,"icon":3,"color":"ffb36f"},
	"frenzy":{"name":"BLOOD RUSH","desc":"65% faster attacks for 10s.","duration":10.0,"icon":4,"color":"ff8073"},
	"immune":{"name":"UNTOUCHABLE","desc":"Damage immunity for 4s.","duration":4.0,"icon":5,"color":"ffdf96"},
	"surge":{"name":"RIFT KNOWLEDGE","desc":"Double XP for 12s.","duration":12.0,"icon":6,"color":"cba5ff"}}
const WEIGHTS = {"heal":25.0,"magnet":24.0,"frenzy":16.0,"surge":14.0,"freeze":10.0,"immune":7.0,"nuke":4.0}

static func roll(g):
	var weights = WEIGHTS.duplicate()
	if g.hp<g.max_hp*0.4: weights.heal *= 2.0
	if g.gems.size()>450: weights.magnet *= 1.8
	var total = 0.0
	for id in weights: total += weights[id]
	var ticket = g.rng.randf()*total
	for id in weights:
		ticket -= weights[id]
		if ticket<=0: return id
	return "heal"

static func drop(g,p,guaranteed = false,elite = false):
	if g.pickups.size()>=10: return
	if not guaranteed and (g.pickup_cooldown>0 or g.rng.randf()>(0.22 if elite else 0.004)): return
	var id = roll(g)
	g.pickups.append({"id":id,"p":g.terrain.open_position(p),"life":65.0,"magnet":false})
	g.pickup_cooldown = 14

static func activate(g,id):
	var d = DEFINITIONS[id]
	if d.duration>0: g.buffs[id] = maxf(g.buffs.get(id,0),d.duration)
	match id:
		"amber": g.amber+=8
		"magnet":
			for gem in g.gems: gem.magnet = true
		"heal": g.hp = minf(g.max_hp,g.hp+g.max_hp*0.35)
		"nuke":
			for e in g.enemies.duplicate():
				if not e.dead: g.hit(e,e.max_hp*(0.012 if e.boss else 0.45 if e.elite or e.anchor else 2.0),"pickup",false)
	g.effect.emit("victory" if id=="nuke" else "level",g.pos,Color(d.color),500)
	g.sound.emit(id if id in ["nuke","freeze","magnet","frenzy"] else "loot")
	g.banner.emit(d.name,d.desc)
	g.log_event("pickup",{"id":id})

static func update(g,dt):
	g.pickup_cooldown = maxf(0,g.pickup_cooldown-dt)
	for id in g.buffs: g.buffs[id] = maxf(0,g.buffs[id]-dt)
	# Detach the array: nuke kills may append new drops during activation.
	var pending = g.pickups
	g.pickups = []
	for item in pending:
		item.life -= dt
		if item.p.distance_squared_to(g.pos)<32*32:
			activate(g,item.id)
		elif item.life>0: g.pickups.append(item)
