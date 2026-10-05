extends SceneTree
const E=preload("res://scripts/expedition.gd")
var checks=0
var failures=0
func check(ok,msg):
	checks+=1
	if not ok:failures+=1;printerr("FAIL / ",msg)
func claim(g):
	var prior=g.relic_stacks.duplicate(true)
	g.choose(0)
	var awarded=g.relic_stacks.duplicate(true);var amber=g.amber
	g.choose(0)
	check(g.relic_stacks==awarded and g.amber==amber,"Integrated reward is awarded once")
func _initialize():
	for map_id in E.Maps.DATA:
		for mode in ["expedition","daily"]:
			var g=E.new();g.setup(2,mode,{},914,map_id)
			for id in ["lens","crown","reaper","shatter","wildfire","volley","storm","coil"]:
				for copy in range(10):g.Relics.apply(g,g.Relics.reward(id,"ARTIFACT"))
			g.weapons={"lightning":{"level":10,"evolved":false,"timer":.1},"frost":{"level":10,"evolved":false,"timer":.1},"fire":{"level":10,"evolved":false,"timer":.1}}
			for stage in range(1,4):
				g.transition_time=0;g.time=g.next_boss-5;g.invul=100
				for i in range(100):
					var e=g.spawn_enemy(false,g.pos+Vector2.from_angle(i*.4)*float(100+i%10*10),0)
					if i%2==0:e.frozen=1;e.burn=1
				for frame in range(180):
					g.tick(1.0/30,Vector2.from_angle(frame*.02))
					if g.choosing:claim(g)
					check(g.proc_queue.size()<=32 and g.level<500,"Live casts and XP remain bounded")
				check(g.kills>0 and g.level>1,"Actual combat earns XP with stacked Lens")
				check(g.boss!=null,"Real ticking schedules the next boss")
				if g.boss==null:break
				var boss=g.boss;g.boss_time=4
				for phase in range(3):
					if boss.dead:break
					boss.reform=0
					for anchor in g.anchors.duplicate():g.hit(anchor,1e10,"lightning",false)
					g.hit(boss,1e10,"lightning",false)
				check(boss.dead,"Stacked build passes actual boss phase damage gates")
				if stage==3 and mode=="expedition":
					check(g.won and not g.active,"Expedition ends successfully")
					break
				if g.choosing:claim(g)
				for frame in range(60):
					g.tick(.01,Vector2.ZERO)
					if g.choosing:claim(g)
				g.enter_portal()
				check(g.portal==null and g.proc_queue.is_empty(),"Portal clears procs and completes transition")
				check(g.relic_stacks.lens.size()==10 and is_equal_approx(g.Relics.modifiers(g).xp,6.0),"XP build persists across biomes")
	print("FORTUNE RUNS / ",checks," checks / ",failures," failures")
	quit(1 if failures else 0)
