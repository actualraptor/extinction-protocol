extends SceneTree
const E = preload("res://scripts/expedition.gd")
func value(g,o):
	if o.type in ["evolution","fusion"]: return 120
	if o.type=="weapon":
		# Once unions consume the original ingredients, refill the freed slots
		# with compatible offense rather than leaving two slots empty forever.
		if o.id not in ["frost","fire","lightning","orbital","mortar","thunderstorm","spear","shotgun"]: return 0
		return 95 if not g.weapons.has(o.id) else 80
	if o.type=="passive":
		if o.id in ["area","damage","haste","speed","pickup"] and g.rank_of(o.id)<2: return 100
		return {"damage":90,"haste":88,"count":92,"crit":85,"area":70,"pickup":75}.get(o.id,5)
	if o.type=="augment": return {"sorcery":85,"fork":84,"linger":83,"conductor":81,"combustion":77,"pierce":65}.get(o.id,10)
	if o.type=="relic": return {"glass":90,"branch":95,"momentum":90,"wildfire":95,"apex":100}.get(o.id,50)
	return 0
func _initialize():
	var g = E.new()
	g.setup(2,"expedition",{},9021)
	var target = Vector2.ZERO
	var pilot_map = preload("res://scripts/terrain_map.gd").new()
	pilot_map.seed_value = g.terrain.seed_value
	var start = Time.get_ticks_msec()
	for frame in range(35000):
		if not g.active: break
		# Invulnerability isolates progression and attainable damage, not dodge skill.
		g.invul = 10
		if g.choosing:
			var best = 0
			for i in range(g.options.size()):
				if value(g,g.options[i])>value(g,g.options[best]): best=i
			g.choose(best)
		if frame%10==0:
			if g.portal!=null: target = g.portal
			elif g.boss!=null: target = g.anchors[0].p+Vector2(0,75) if not g.anchors.is_empty() else g.boss.p+Vector2(0,120)
			elif not g.relic_chests.is_empty(): target = g.relic_chests[0]
			elif g.cache_timer<=0: target = g.cache_pos
			else:
				var distance = INF
				target = g.pos+Vector2.from_angle(g.time*0.13)*300
				for gem in g.gems:
					var d = gem.p.distance_squared_to(g.pos)
					if d<distance:
						distance = d
						target = gem.p
		if pilot_map.seed_value != g.terrain.seed_value:
			pilot_map.seed_value = g.terrain.seed_value
			pilot_map.cached.clear()
			pilot_map.flow.clear()
			pilot_map.refresh = 0
		pilot_map.arena = g.terrain.arena
		pilot_map.update(1.0/30,target)
		g.tick(1.0/30,pilot_map.direction(g.pos,target))
		if frame%4500==0: print("PROGRESSION / ",g.time,"s / level ",g.level," / kills ",g.kills)
	print("NATURAL BUILD / won=",g.won," / time=",g.time," / level=",g.level," / ranks=",g.weapons," / relics=",g.relics," / wall=",Time.get_ticks_msec()-start,"ms")
	var file = FileAccess.open("res://build/progression-report-06.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(g.report()))
	file.close()
	quit(0 if g.won else 1)
