extends SceneTree
const E=preload("res://scripts/expedition.gd")
const P=preload("res://scripts/reward_preview.gd")
var checks=0
var failures=0
func check(ok,message):
	checks+=1
	if not ok:failures+=1;printerr("FAIL / ",message)
func _initialize():
	for id in E.C.WEAPONS:
		for rank in [0,1,4,6,9]:
			for tier in E.Relics.TIERS:
				var g=E.new();g.setup(1,"expedition",{},42)
				g.weapons={} if rank==0 else {id:{"level":rank,"evolved":false,"timer":.7}}
				g.passives={"damage":2,"haste":3,"area":4,"count":1};g.modifier_cache.clear()
				var o=g.BuffRewards.decorate(g,{"type":"weapon","id":id},tier)
				var saved=g.weapons.duplicate(true);var rng_state=g.rng.state
				var pair=P.weapon_stats(g,o)
				check(saved==g.weapons and rng_state==g.rng.state,"Preview preserves run state")
				g.options=[o];g.choosing=true;g.choose(0)
				check(pair[1]==g.Rules.stats(g,id),"Preview equals actual accepted reward / "+id)
	for rank in [0,8,20,80]:
		var g=E.new();g.setup(1,"expedition",{},13);g.passives={"crit":rank}
		var o={"type":"passive","id":"crit","rank_gain":1,"stat_gain":3.0}
		# The displayed curve must account for diminished chance at higher stacks.
		var rows=P.rows(g,o);var expected=P.number(g.crit_curve(g.C.HEROES[g.hero].crit+(rank+3)*.07)*100)+"%"
		check(rows[0].after==expected,"Critical chance preview respects diminishing returns")
	var g=E.new();g.setup(5,"expedition",{},12);g.enemies.clear()
	g.weapons.u06={"level":1,"evolved":false,"timer":0.0}
	var foe=g.spawn_enemy(false,g.pos+Vector2(180,0),0);foe.hp=100000;g.build_grid()
	g.companions.units.append({"champion":true,"p":g.pos+Vector2(90,0)})
	g.companions.cast(g,"u06",g.Rules.stats(g,"u06"))
	check(not g.shots.is_empty() and g.shots[0].p==g.pos,"Spear always begins at owner despite a champion being present")
	for id in E.Evolutions.UNIONS:
		var run=E.new();run.setup(1,"expedition",{},21);run.weapons={}
		for part in run.Evolutions.UNIONS[id].parts:run.weapons[part]={"level":10,"evolved":false,"timer":0.0}
		var offer={"type":"fusion","id":id};var pair=P.weapon_stats(run,offer)
		run.options=[offer];run.choosing=true;run.choose(0)
		check(pair[1]==run.Rules.stats(run,id),"Union preview accounts for consumed ingredients / "+id)
	for id in E.C.RELICS:
		var run=E.new();run.setup(5,"expedition",{},21)
		var offer=run.Relics.reward(id,"ARTIFACT")
		var state=[run.hp,run.max_hp,run.armor,run.relics.duplicate(),run.relic_stacks.duplicate(true),run.relic_state.duplicate(true),run.rng.state]
		var rows=P.rows(run,offer)
		check(state==[run.hp,run.max_hp,run.armor,run.relics,run.relic_stacks,run.relic_state,run.rng.state],"Relic preview preserves HP, inventory, state and RNG / "+id)
		run.options=[offer];run.choosing=true;run.choose(0)
		for row in rows:
			if row.name=="Maximum health":check(row.after==P.number(run.max_hp),"Relic maximum health matches acceptance")
			if row.name=="Armor":check(row.after==P.number(run.armor),"Relic armor matches acceptance")
	var slam=E.new();slam.setup(1,"expedition",{},21);slam.weapons={"club":{"level":10,"evolved":false,"timer":0.0}}
	var raw=slam.Rules.stats(slam,"club");var effective=P.effective(slam,"club",raw,10,false)
	check(is_equal_approx(effective.power,raw.power*1.2) and effective.arc==TAU,"Rank-ten slam includes combat bonus and radial coverage")
	for id in ["aegis","stasis","thunderstorm","glacier","return"]:
		slam.weapons={id:{"level":10,"evolved":true,"timer":0.0}};slam.modifier_cache.clear()
		raw=slam.Rules.stats(slam,id);effective=P.effective(slam,id,raw,10,true)
		if id=="aegis":check(is_equal_approx(effective.shield,raw.shield*1.7),"Evolved barrier uses actual absorption")
		if id=="stasis":check(is_equal_approx(effective.duration,raw.duration+5.5),"Time fracture includes intrinsic duration")
		if id=="thunderstorm":check(effective.count<=4 and effective.duration==raw.duration+2,"Storm uses actual zone count and duration")
		if id in ["glacier","return"]:
			var shot=slam.shoot(id,slam.pos,Vector2.RIGHT,raw.power,raw.velocity,raw.lifetime,1 if "RICOCHET" in slam.C.WEAPONS[id].tags else raw.pierce)
			check(shot.bounce==effective.bounce and shot.pierce==effective.pierce and shot.homing==effective.homing,"Projectile preview matches spawned shot / "+id)
	print("REWARD PREVIEW / ",checks," checks / ",failures," failures");quit(1 if failures else 0)
