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
				g.hazards.clear();g.boss_timer=0;g.boss_pattern=pattern;g.update_boss(0.1)
				check(g.hazards.size()>=2 and g.hazards.size()<=3,"Bounded boss pattern / %s / %s / %s"%[map,stage,pattern])
			g.kill(g.boss)
			check(g.portal!=null,"Gate boss leaves portal / "+map)
			g.choose(0);g.enter_portal()
			check(g.depth==stage and g.map_id==map and g.terrain.layout==g.Maps.DATA[map].layout,"Portal retains selected map / %s / %s"%[map,stage])
			var seen={Vector2i.ZERO:true};var queue=[Vector2i.ZERO];var cursor=0
			while cursor<queue.size():
				var cell=queue[cursor];cursor+=1
				for dir in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
					var next=cell+dir
					if abs(next.x)>30 or abs(next.y)>30 or seen.has(next) or g.terrain.kind(next)==1: continue
					seen[next]=true;queue.append(next)
			for marker in g.landmarks: check(seen.has(g.terrain.cell(marker.p)),"Deeper discovery reachable / %s / %s"%[map,marker.id])
	print("FRONTIERS ROUTES / %s checks / %s failures"%[checks,failures])
	quit(1 if failures else 0)
