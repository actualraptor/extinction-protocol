extends SceneTree
const E=preload("res://scripts/expedition.gd")
const Copy=preload("res://scripts/upgrade_copy.gd")
var checks=0
var failures=0
func check(ok,msg):
	checks+=1
	if not ok:failures+=1;printerr("FAIL / ",msg)
func claim(g,o):
	g.options=[o];g.choosing=true;g.choose(0)
func _initialize():
	var g=E.new();g.setup(1,"expedition",{},831)
	for id in g.C.RELICS:
		for tier in g.Relics.TIERS:
			var o=g.Relics.reward(id,tier)
			check(o.effects==g.Relics.effects(id,tier) and not g.Relics.description(o).is_empty() and Copy.description(g,o)==g.Relics.description(o),"Payload and description / "+id+" / "+tier)
	claim(g,g.Relics.reward("lens","COMMON"))
	check(is_equal_approx(g.Relics.modifiers(g).xp,.05),"Common lens gives 5% XP")
	g.gems=[{"p":g.pos,"value":100,"magnet":true}];g.update_gems(.01)
	var first=g.xp
	claim(g,g.Relics.reward("lens","ARTIFACT"))
	g.gems=[{"p":g.pos,"value":100,"magnet":true}];g.update_gems(.01)
	check(is_equal_approx(g.xp-first,135),"Stacked lens gives 35% XP from actual pickup")
	check(g.relics==["lens"] and g.relic_stacks.lens.size()==2,"Repeats preserve one unique slot")
	check(is_equal_approx(g.Relics.modifiers(g).xp,.35),"Warm cache invalidated on stack")
	g.Relics.remove(g,"lens")
	check(not g.Relics.modifiers(g).has("xp"),"Removal invalidates cache")
	for id in ["lens","wrap","flint","coil","blood","shell","glass","magnet"]:claim(g,g.Relics.reward(id,"COMMON"))
	var before=g.relics.duplicate()
	for i in range(100):
		g.open_choices(true)
		check(g.options[0].type=="relic" and g.options[0].id in before,"Full satchel offers existing stacks")
		g.choose(0)
		if g.Relics.candidates(g).is_empty():break
	check(g.relics==before,"Stacks never consume a ninth slot")
	for id in before:
		while g.Relics.tiers(g,id).size()<10:claim(g,g.Relics.reward(id,"COMMON"))
	g.weapons={"club":{"level":10,"evolved":true,"timer":0}}
	g.passives={"armor":5,"damage":5,"haste":5,"area":5,"speed":5,"pickup":5,"regen":5,"luck":5}
	g.open_choices(true)
	check(g.options[0].type=="supplies","Exhausted satchel/build gets tiered amber")
	var a=g.amber;var amount=g.options[0].amber_gain;g.choose(0);g.choose(0)
	check(g.amber==a+amount,"Supplies award once")
	for kind in ["weapon","passive","augment"]:
		g.weapons.club.level=10;g.passives.armor=5;g.augments.clear()
		if kind=="weapon":g.weapons.club.level=9
		elif kind=="passive":g.passives.armor=4
		else:g.augments.reach=g.C.AUGMENTS.reach.max-1
		g.open_choices(true)
		check(g.options[0].type==kind and g.options[0].rank_gain==1 and g.options[0].effects.ranks==1,"Refinement payload contains actual remaining rank / "+kind)
		g.choose(0)
	for tier in ["COMMON","ARTIFACT"]:
		var h=E.new();h.setup(1,"expedition",{},3)
		var hp=h.max_hp
		claim(h,{"type":"passive","id":"armor","rarity":tier,"rank_gain":h.Relics.RANK_GAINS[h.Relics.TIERS.find(tier)]})
		check(h.max_hp-hp==(12 if tier=="COMMON" else 48),"Tier affects actual health refinement")
	for luck in [0.0,.5]:
		var h=E.new();h.setup(1,"expedition",{},223);h.permanent_luck=luck
		var counts=[0,0,0,0,0,0];var odds=h.Relics.odds(h)
		for i in range(30000):
			h.relic_state.dry_chests=0
			counts[h.Relics.TIERS.find(h.Relics.roll_tier(h))]+=1
		for t in range(6):check(absf(counts[t]/300.0-odds[t])<1.0,"Distribution matches odds / luck "+str(luck)+" tier "+str(t))
		if luck>0:check(odds[4]>2.7 and odds[5]>.3,"Luck increases high rarity chance")
		print("ODDS / luck=",luck," displayed=",odds," observed=",counts)
	g.relic_state.dry_chests=4
	check(g.Relics.odds(g)[0]==0 and g.Relics.odds(g)[1]==0,"Pity suppresses low tiers")
	var x=E.new();x.setup(1,"expedition",{},9)
	x.spawn_boss(3);var boss_hp=x.boss.max_hp
	var old=x.spawn_enemy(false,Vector2(200,0),0)
	claim(x,x.Relics.reward("crown","RARE"))
	var new_enemy=x.spawn_enemy(false,Vector2(300,0),0)
	check(is_equal_approx(new_enemy.max_hp,old.max_hp*1.1),"Crown scales only future normal horde health")
	check(x.boss.max_hp==boss_hp and old.max_hp==old.hp,"Existing enemies and boss never heal from Crown")
	for id in ["reaper","shatter","wildfire","volley"]:
		for i in range(10):claim(x,x.Relics.reward(id,"ARTIFACT"))
	var e=x.spawn_enemy(false,Vector2(100,0),0);e.last_critical=true;e.frozen=1;e.burn=1
	for i in range(100):x.Relics.on_kill(x,e)
	check(x.proc_queue.size()<=32,"Proc queue stays bounded")
	var s={"count":10};x.Relics.on_cast(x,x.C.WEAPONS.revolver,5,s)
	check(s.count==12,"Bonus volleys respect projectile ceiling")
	x.proc_depth=1;x.proc_queue.clear();x.Relics.on_kill(x,e)
	check(x.proc_queue.is_empty(),"Status bursts cannot recursively spawn bursts")
	for seed_value in range(5):
		var d=E.new();d.setup(2,"daily",{},seed_value+512)
		var b=E.new();b.setup(2,"daily",{},seed_value+512)
		for lv in range(2,70):
			d.level=lv;b.level=lv;d.rng.randf()
			d.open_choices(lv%3==0);b.open_choices(lv%3==0)
			check(d.options==b.options,"Daily payload independent of combat RNG")
			d.choose(0);b.choose(0)
			check(d.relic_stacks==b.relic_stacks,"Daily tier stacks deterministic")
	print("TIERED RELICS / ",checks," checks / ",failures," failures")
	quit(1 if failures else 0)
