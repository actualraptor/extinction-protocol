extends RefCounted
## Declared late-game inventory for private human play; not campaign drop odds.
static func apply(g,tier:String="RARE"):
	assert(tier in ["RARE","EPIC"])
	g.level=50;g.weapons.clear();g.passives.clear();g.buff_stacks.clear()
	g.armor=g.C.HEROES[g.hero].armor;g.max_hp=g.C.HEROES[g.hero].hp;g.hp=g.max_hp
	for id in ["earthshaker","fire","lightning","orbital","mortar","revolver"]:
		g.weapons[id]={"level":10,"evolved":true,"timer":.1,"casts":0}
	var ranks={"damage":5,"haste":5,"count":3,"area":4,"crit":5,"speed":3}
	for id in ranks:
		g.options=[g.BuffRewards.decorate(g,{"type":"passive","id":id},tier,ranks[id])]
		g.choosing=true;g.choose(0)
	for id in ["flint","coil","glass","shell","wrap","blood"]:
		assert(g.Relics.candidates(g).has(id),"Invalid private loadout relic")
		g.options=[g.Relics.reward(id,tier)];g.choosing=true;g.choose(0)
	for id in ["sorcery","echo"]:
		g.options=[g.BuffRewards.decorate(g,{"type":"augment","id":id},tier,g.C.AUGMENTS[id].max)]
		g.choosing=true;g.choose(0)
	g.choosing=false;g.options=[]
	g.enemies.clear();g.hazards.clear();g.gems.clear();g.relic_chests.clear()
	g.spawn_budget=-100000;g.next_boss=100000;g.cache_timer=100000;g.shrine_done=true
