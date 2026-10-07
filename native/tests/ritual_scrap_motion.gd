extends SceneTree
const A=preload("res://scripts/rite_animation.gd")
const B=preload("res://scripts/dinosaur_boss_art.gd")
func _initialize():
	for identity in B.IDS:
		var c={"identity":identity,"size":B.WIDTH[identity]/3.2,"ritual_seed":.7}
		var other={"identity":identity,"size":c.size,"ritual_seed":2.1}
		var bounds=Rect2();var first=true;var changed=0;var staggered=0
		for id in range(9):
			if A.surface(identity,id).is_empty():continue
			var start=A.scrap_flight(c,id,0)
			var finish=A.scrap_flight(c,id,2)
			if start.source.distance_to(finish.source)>8:staggered+=1
			for flake in range(3):
				var motion=A.scrap_flight(c,id,flake)
				var at=motion.source+motion.plane*motion.flight+Vector2(0,motion.height)
				var terminal=motion.source+motion.plane*motion.flight+Vector2(0,motion.velocity.y*motion.flight+130*motion.flight*motion.flight)
				assert(at.distance_to(terminal)<.01)
				if first:bounds=Rect2(at,Vector2.ZERO);first=false
				else:bounds=bounds.expand(at)
				var alternate=A.scrap_flight(other,id,flake)
				var landing=alternate.source+alternate.plane*alternate.flight+Vector2(0,alternate.height)
				if at.distance_to(landing)>20:changed+=1
		assert(bounds.size.x>180 and bounds.size.y>120 and staggered>=2 and changed>=8)
		print("SCRAP MOTION ",identity,": spread=",bounds.size," staggered_sections=",staggered," changed_landings=",changed)
	quit()
