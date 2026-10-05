extends SceneTree
const E = preload("res://scripts/expedition.gd")
const X = preload("res://scripts/content_extension.gd")
const C = preload("res://scripts/catalog.gd")
var errors = 0
var checks = 0
func check(ok,message):
	checks+=1
	if not ok:errors+=1;push_error(message)
func _initialize():
	X.install(C)
	check(C.HEROES.size()==6,"Supplemental registry loaded")
	check(not X.visible({}),"Undiscovered profile omitted")
	check(not E.Daily.plan(81273).hero==5,"Daily roster unchanged")
	for i in range(200):check(E.Daily.plan(i).hero<5,"Daily must use public roster")
	var ordinary=E.new();ordinary.setup(1,"expedition",{},3123)
	for o in ordinary.upgrade_pool():check((C.WEAPONS if o.type=="weapon" else C.PASSIVES if o.type=="passive" else C.AUGMENTS)[o.id].get("profile","")=="","Ordinary pool isolated")
	check(not X.eligible_finish(ordinary),"No premature completion")
	ordinary.won=true;ordinary.boss_stage=3
	check(not X.eligible_finish(ordinary),"Victory without finale kill cannot discover profile")
	ordinary.finale_defeated=true
	check(X.eligible_finish(ordinary),"Expedition finale qualifies")
	ordinary.won=false
	check(not X.eligible_finish(ordinary),"Defeat cannot discover profile")
	ordinary.won=true
	ordinary.mode="safari";check(not X.eligible_finish(ordinary),"Practice cannot discover profile")
	ordinary.mode="daily";check(not X.eligible_finish(ordinary),"Daily cannot discover profile")
	var g=E.new();g.setup(5,"expedition",{},8127)
	check(g.companions!=null and g.weapons.has("u00"),"Companion starter")
	for o in g.upgrade_pool():
		if o.type=="weapon":check(o.id.begins_with("u"),"Exclusive weapon pool")
	for i in range(100):g.companions.summon(g,"u00")
	check(g.companions.units.size()==4,"Initial permanent cap")
	for i in range(100):g.companions.summon(g,"u00",12)
	check(g.companions.units.size()==20,"Temporary cap is bounded")
	for u in g.companions.units:u.p=g.pos+Vector2(1000,0)
	g.companions.update(g,.1)
	for u in g.companions.units:check(u.p.distance_to(g.pos)<200,"Separated units reform")
	g.weapons.u00.level=10;g.weapons.u00.evolved=true
	check(g.companions.capacity(g,"u00")>=13,"Evolved capacity")
	for i in range(1,10):g.weapons["u%02d"%i]={"level":10,"evolved":true,"timer":0.0}
	for i in range(13):g.passives["p%02d"%i]=1
	for i in range(8):
		var id="r%02d"%i
		g.Relics.apply(g,g.Relics.reward(id,"ARTIFACT" if i==7 else "RARE"))
	for i in range(40):g.spawn_enemy(false,g.pos+Vector2.from_angle(i*TAU/40)*180,0,false)
	g.build_grid()
	for id in g.weapons:g.companions.cast(g,id,g.Rules.stats(g,id))
	for i in range(120):
		g.time+=.033
		g.build_grid();g.companions.update(g,.033);g.update_shots(.033)
	check(g.damage_total>0,"Army inflicts real damage")
	check(g.companions.units.size()<=64 and g.companions.pending.size()<=24,"Proc budgets")
	check(g.companions.souls>0,"Deaths fuel soul system")
	var h=E.new();h.setup(5,"expedition",{},123)
	var event=h.spawn_enemy(false,h.pos+Vector2(200,0),0,false)
	for i in range(250):h.kills+=1;h.companions.on_kill(h,event)
	check(h.companions.threshold_index==4,"All four soul thresholds")
	check(not h.weapons.has("u09"),"Threshold summon consumes no backpack slot")
	check(h.companions.units.any(func(u):return u.role=="colossus"),"Threshold giant")
	check(h.companions.next_threshold==275,"Soul cycle continues")
	for id in X.data.icons:check(X.icon(id)!=null,"Bundled icon loads")
	var final_run=E.new();final_run.setup(1,"expedition",{},77)
	final_run.spawn_boss(3)
	final_run.phase=3
	final_run.kill(final_run.boss)
	check(final_run.won and final_run.finale_defeated and X.eligible_finish(final_run),"Actual final kill qualifies")
	var lost=E.new();lost.setup(1,"expedition",{},78)
	lost.spawn_boss(3);lost.finish(false)
	check(not X.eligible_finish(lost),"Losing to final boss cannot unlock")
	for index in range(6):check(X.sprite(index)!=null,"Unit sprite loads")
	for index in range(8):check(X.owner_pose(index)!=null,"Directional pose loads")
	var a=E.new();a.setup(5,"expedition",{},987)
	a.companions.summon(a,"u00")
	var u=a.companions.units[0]
	var victim=a.spawn_enemy(false,u.p+Vector2(20,0),0,false)
	victim.hp=100000;victim.max_hp=100000
	a.build_grid();u.attack=0
	a.companions.update(a,.01)
	check(u.has("swing") and a.damage_total==0,"Windup precedes damage")
	a.companions.animate_attack(a,u,.1)
	check(a.damage_total==0,"No damage before impact")
	a.companions.animate_attack(a,u,.15)
	check(a.damage_total>0,"Impact deals damage")
	var dealt=a.damage_total
	a.companions.animate_attack(a,u,.1)
	check(a.damage_total==dealt,"Recovery cannot hit twice")
	a.companions.animate_attack(a,u,1)
	check(not u.has("swing"),"Attack returns to idle")
	var movement=E.new();movement.setup(5,"expedition",{},99)
	movement.velocity=Vector2.RIGHT*200
	for j in range(20):movement.time+=.05;movement.companions.update_owner(movement,.05)
	check(movement.companions.pose==2,"Floating body turns right")
	movement.velocity=Vector2.UP*200
	for j in range(20):movement.time+=.05;movement.companions.update_owner(movement,.05)
	check(movement.companions.pose==4,"Floating body turns away")
	check(movement.companions.trail.size()<=12,"Shroud remains bounded")
	movement.companions.summon(movement,"u00")
	movement.companions.units[0].hp=0
	movement.companions.update(movement,.05)
	check(movement.companions.reform.size()==1,"Permanent losses schedule replacement")
	movement.time+=3.1;movement.companions.update(movement,.05)
	check(movement.companions.units.size()==1,"Permanent summon automatically returns")
	var stable_pose=movement.companions.pose
	for j in range(60):
		movement.time+=.016
		movement.velocity=Vector2.UP.rotated(.03 if j%2==0 else -.03)*200
		movement.companions.update_owner(movement,.016)
		check(movement.companions.pose==stable_pose,"Small movement variations retain stable facing")
	for unit in range(5):
		for frame in range(8):
			check(X.unit_pose(unit,frame)!=null,"Actual weapon animation frame loads")
			check(X.unit_layout(unit,frame).size.x>0,"Frame uses stable layout")
	for duration in [.12,.2,.5]:
		var sequence={"elapsed":0.0,"duration":duration,"hit":false,"target":victim,"power":1.0,"stats":a.Rules.stats(a,"u00"),"aim":Vector2.RIGHT}
		u.swing=sequence
		a.companions.animate_attack(a,u,duration*.44)
		check(not sequence.hit,"Fast attack retains windup")
		a.companions.animate_attack(a,u,duration*.02)
		check(sequence.hit,"Fast attack resolves at impact pose")
		a.companions.animate_attack(a,u,duration)
		check(not u.has("swing"),"Fast attack completes recovery")
	print("Content profiles: %s checks, %s errors"%[checks,errors])
	quit(1 if errors else 0)
