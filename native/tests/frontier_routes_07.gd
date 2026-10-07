extends SceneTree
const E=preload("res://scripts/expedition.gd")
var failures=0
var checks=0
func check(ok,message):
	checks+=1
	if not ok: failures+=1
	print("PASS / " if ok else "FAIL / ",message)
func _initialize():
	for map in ["frostbreak","observatory"]:
		var g=E.new();g.setup(2,"expedition",{},707,map)
		for stage in [1,2]:
			g.time=stage*300;g.spawn_boss(stage)
			for pattern in [0,1]:
				g.hazards.clear();g.boss.attack_index=pattern;preload("res://scripts/boss_encounters.gd").prepare(g)
				check(g.hazards.size()>=1 and g.hazards.size()<=3 and g.hazards.all(func(h):return h.get("physical",false)),"Bounded physical boss pattern / %s / %s / %s"%[map,stage,pattern])
			g.kill(g.boss)
			check(g.portal!=null,"Gate boss leaves portal / "+map)
			g.choose(0);g.enter_portal()
			check(g.depth==stage and g.map_id==map and g.terrain.layout==g.Maps.DATA[map].layout,"Portal retains selected map / %s / %s"%[map,stage])
			for marker in g.landmarks:
				var reachable=true
				var distance=g.stage.spawn.distance_to(marker.p)
				for step in range(ceili(distance/64.0)+1):
					var point=g.stage.spawn.lerp(marker.p,minf(1,step*64.0/maxf(1,distance)))
					if not g.terrain.walkable(point,15):reachable=false;break
				check(reachable,"Authored route reaches discovery / %s / %s"%[map,marker.id])
	print("FRONTIERS ROUTES / %s checks / %s failures"%[checks,failures])
	quit(1 if failures else 0)
