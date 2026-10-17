extends SceneTree
const Exp=preload("res://scripts/expedition.gd")
const God=preload("res://scripts/god_content.gd")
var results=[]
var failures=0
func _initialize():call_deferred("run")
func loadout(g,route,tier):
 g.level=50;g.weapons.clear()
 var ids=["mjolnir","gungnir","cloudbreaker","ninefold","winter_claim"] if route=="throw" else ["mjolnir","summer_edge","winter_claim","worldwake","oathsplitter"] if route=="orbit" else God.UNIONS.keys()
 for id in ids:
  var first=God.choices(id,5)[0].id
  if God.base_id(id)=="mjolnir":first="orbit" if route=="orbit" else "bounce"
  var w={"level":10,"evolved":true,"timer":.1,"branches":{"5":first}}
  w.branches["10"]=God.choices(id,10,w)[0].id;g.weapons[id]=w
 for id in {"damage":5,"haste":5,"count":3,"area":4,"crit":5,"speed":3}:
  var ranks={"damage":5,"haste":5,"count":3,"area":4,"crit":5,"speed":3}[id]
  g.options=[g.BuffRewards.decorate(g,{"type":"passive","id":id},tier,ranks)];g.choosing=true;g.choose(0)
 for id in ["flint","coil","glass","shell","wrap","blood"]:
  if g.Relics.candidates(g).has(id):g.options=[g.Relics.reward(id,tier)];g.choosing=true;g.choose(0)
 for id in ["echo","sorcery"]:
  if God.eligible_augment(g,id):g.options=[g.BuffRewards.decorate(g,{"type":"augment","id":id},tier,g.C.AUGMENTS[id].max)];g.choosing=true;g.choose(0)
 g.choosing=false;g.options=[];g.enemies.clear();g.hazards.clear();g.gems.clear();g.relic_chests.clear()
 g.spawn_respite=100000;g.next_boss=100000;g.cache_timer=100000;g.shrine_done=true;g.xp_goal=1e12
func run():
 for route in ["throw","orbit","unions"]:
  for stage in [1,2,3]:
   var g=Exp.new();g.setup(1,"expedition",{},171017)
   g.hero=God.install(g.C);g.depth=stage-1;g.time=stage*300
   loadout(g,route,"EPIC")
   g.spawn_boss(stage)
   # Damage-budget fixture only: immunity isolates output from this simple circling bot.
   g.invul=10000;g.pos=g.boss.p+Vector2(220,100)
   for tick in 45*30:
    if g.boss==null or not g.active:break
    var offset=g.pos-g.boss.p
    var desired=g.boss.p+Vector2.from_angle(tick/30.0*.45)*250
    g.tick(1.0/30,(desired-g.pos).limit_length(1))
    if g.choosing:g.choose(0)
   var remaining=g.boss.hp if g.boss!=null else 0.0
   var full=[90000.0,900000.0,20000000.0][stage-1]
   var row={"route":route,"stage":stage,"damage":g.damage_total,"remaining":remaining,"boss_fraction_removed":1-remaining/full,"seconds":g.boss_time,"credit":g.damage_by_weapon,"shots":g.shots.size(),"effects":g.god_state.get("effects",[]).size()}
   results.append(row)
   if g.damage_total<=0 or g.shots.size()>240 or row.effects>64:failures+=1
   print("TORR BUDGET / ",route," / boss ",stage," / removed ",snappedf(row.boss_fraction_removed*100,.1),"% / damage ",roundi(g.damage_total)," / credits ",g.damage_by_weapon)
 var f=FileAccess.open("res://build/torr-balance-review.json",FileAccess.WRITE);f.store_string(JSON.stringify(results,"  "));f.close()
 print("TORR BALANCE / 9 boss budgets / ",failures," failures")
 quit(1 if failures else 0)
