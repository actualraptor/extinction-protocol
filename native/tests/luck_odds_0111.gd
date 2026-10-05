extends SceneTree
const E=preload("res://scripts/expedition.gd")
var checks=0
var failures=0
func check(ok,msg):
	checks+=1
	if not ok:failures+=1;printerr("FAIL / ",msg)
func expected(ticket,odds):
	for i in range(6):
		ticket-=odds[i]
		if ticket<=0:return i
	return 5
func _initialize():
	var g=E.new();g.setup(1,"expedition",{},11011)
	var previous=0.0
	for luck in [0.0,.01,.1,.5,1.0,2.0,3.49,3.5,4.0,100.0]:
		g.permanent_luck=luck
		var odds=g.Relics.odds(g,false)
		check(is_equal_approx(odds.reduce(func(a,b):return a+b,0.0),100),"Normalized / %s"%luck)
		check(is_equal_approx(odds[0],40.0/rarity_total(luck)*100),"Original weighted Common reduction / %s"%luck)
		check(is_equal_approx(odds[5],.3*pow(1+luck,5)/rarity_total(luck)*100),"Original weighted Artifact increase / %s"%luck)
		check(odds[5]>=previous,"Artifact chance does not decrease")
		previous=odds[5]
		g.relic_state.dry_chests=4
		var pity=g.Relics.odds(g,true)
		check(pity[0]==0 and pity[1]==0,"Pity excludes Common and Uncommon")
		var mass=odds[2]+odds[3]+odds[4]+odds[5]
		for i in range(2,6):check(is_equal_approx(pity[i],odds[i]/mass*100),"Pity preserves current Rare+ proportions")
		g.relic_state.dry_chests=0
	g.permanent_luck=-2
	for i in range(6):check(is_equal_approx(g.Relics.odds(g,false)[i],g.Relics.WEIGHTS[i]),"Negative luck safely clamps to baseline")
	g.permanent_luck=.2;g.passives.luck=1
	g.buff_stacks.luck=[{"rank_gain":1,"stat_gain":3.0,"rarity":"ARTIFACT"}]
	check(is_equal_approx(g.Relics.odds(g,false)[5],.3*pow(1.5,5)/rarity_total(.5)*100),"Artifact Luck quality and permanent Luck combine (0.3 + 0.2)")
	# Replay each exact RNG ticket through both real reward paths. Pity must
	# affect chests only; level rewards must neither read nor consume it.
	var different=0
	for sample in range(1000):
		g.relic_state.dry_chests=4
		var state=g.rng.state
		var ticket=g.rng.randf()*100
		var level_tier=expected(ticket,g.Relics.odds(g,false))
		var chest_tier=expected(ticket,g.Relics.odds(g,true))
		g.rng.state=state
		check(g.BuffRewards.roll(g)==g.Relics.TIERS[level_tier],"Level reward uses non-pity odds")
		check(g.relic_state.dry_chests==4,"Level reward preserves chest pity")
		g.rng.state=state
		check(g.Relics.roll_tier(g)==g.Relics.TIERS[chest_tier],"Chest reward uses pity odds")
		check(g.relic_state.dry_chests==0,"Rare+ chest resets pity")
		if level_tier!=chest_tier:different+=1
	check(different>0,"Replay exercises genuinely different level/chest results")
	print("LUCK ODDS / ",checks," checks / ",failures," failures")
	quit(1 if failures else 0)

func rarity_total(luck):
	var sum=0.0
	for tier in range(6):sum+=[40.0,30.0,18.0,9.0,2.7,0.3][tier]*pow(1+luck,tier)
	return sum
