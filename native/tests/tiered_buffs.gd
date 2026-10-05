extends SceneTree
func _initialize():call_deferred("run")
func give(g,o):
 g.options=[o];g.choosing=true;g.choose(0)
func run():
 var g=preload("res://scripts/expedition.gd").new();g.setup(1,"expedition",{},7123)
 var b=g.BuffRewards
 var armor=g.armor;var hp=g.max_hp
 give(g,b.decorate(g,{"type":"passive","id":"armor"},"ARTIFACT"))
 assert(g.passives.armor==1);assert(g.armor==armor+6);assert(g.max_hp==hp+36);assert(b.power(g,"armor")==3)
 give(g,b.decorate(g,{"type":"passive","id":"haste"},"RARE"));assert(g.passives.haste==1);assert(is_equal_approx(b.power(g,"haste"),1.5))
 give(g,b.decorate(g,{"type":"augment","id":"echo"},"ARTIFACT"));assert(g.augments.echo==1);assert(b.power(g,"echo")==3);assert(g.Rules.modifiers(g,"club").repeat==3)
 give(g,b.decorate(g,{"type":"weapon","id":"frost"},"ARTIFACT"));assert(g.weapons.frost.level==g.Relics.RANK_GAINS[5])
 give(g,{"type":"passive","id":"damage"});assert(g.passives.damage==1);assert(b.power(g,"damage")==1)
 g.open_choices(false);var old=g.options.duplicate(true)
 for o in old:assert(o.has("rarity") and o.has("stat_gain") and o.has("effects"))
 g.rerolls=1;assert(g.reroll_choices())
 for o in g.options:assert(not old.any(func(a):return a.id==o.id and a.type==o.type))
 assert(g.report().reward_schema==3 and g.report().buff_stacks.size()>0)
 g.choosing=false;g.mode="daily";g.open_choices(false);assert(g.options[0].has("rarity") and g.options[0].daily_offered.size()==3)
 print("TIERED BUFF INTEGRATION / grants, stats, armor, new weapons, rerolls, report, daily passed")
 quit()
