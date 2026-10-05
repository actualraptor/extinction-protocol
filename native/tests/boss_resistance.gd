extends SceneTree
const E=preload("res://scripts/expedition.gd")
const DR=preload("res://scripts/boss_resistance.gd")
var checks=0
var failures=0
func check(ok,msg):
 checks+=1
 if not ok:failures+=1;printerr("FAIL / ",msg)
func game(stage=1):
 var g=E.new();g.setup(1,"expedition",{},1101);g.spawn_boss(stage);g.boss_time=4;return g
func _initialize():
 for stage in [1,2,3]:
  var g=game(stage);g.anchors.clear();g.core_time=0
  var before=g.boss.hp
  var damage=g.hit(g.boss,100,"revolver",false,false)
  check(is_equal_approx(damage,100*(1-DR.INNATE[stage-1])),"Innate resistance / stage%s"%stage)
  check(is_equal_approx(before-g.boss.hp,damage) and is_equal_approx(g.damage_total,damage) and is_equal_approx(g.damage_by_weapon.revolver,damage),"Health and ledger use actual resisted damage")
  if stage<3:
   g.boss.exposed=2.5
   check(is_equal_approx(g.hit(g.boss,100,"revolver",false,false),100*(1-DR.INNATE[stage-1]+DR.EXPOSED_REDUCTION)),"Earned exposure lowers resistance")
   check("ARMOR EXPOSED" in DR.caption(g,g.boss),"Exposure state explained")
 var g=game(1);g.passives.crit=60
 var dealt=g.hit(g.boss,100,"revolver",true,false)
 check(g.boss.last_crit_tier>0 and is_equal_approx(dealt,100*pow(1.9,g.boss.last_crit_tier)*.5),"Multi-crits apply before resistance exactly once")
 var position=g.boss.p
 g.hit(g.boss,1,"club",false,false)
 check(g.boss.p==position,"Resistance does not change boss knockback immunity")
 g=game(1);g.hit(g.boss,100,"fire",false,true)
 check(is_equal_approx(g.boss.burn_damage,12),"Burn snapshots pre-resistance source damage")
 var before=g.boss.hp;g.boss.burn_tick=0;g.update_enemies(.01)
 check(is_equal_approx(before-g.boss.hp,6),"Burn tick receives one50% reduction")
 before=g.boss.hp;g.boss.exposed=2;g.boss.burn_tick=0;g.update_enemies(.01)
 check(is_equal_approx(before-g.boss.hp,9),"Existing burn benefits from earned exposure without double taxation")
 g=game(1);g.hit(g.boss,100,"miasma",false,true)
 check(is_equal_approx(g.boss.poison_damage,10),"Poison snapshots pre-resistance source damage")
 before=g.boss.hp;g.boss.poison_tick=0;g.update_enemies(.01)
 check(is_equal_approx(before-g.boss.hp,5),"Poison tick receives one50% reduction")
 g=game(1)
 for source in ["relic","pickup","thorns","lightning"]:
  check(is_equal_approx(g.hit(g.boss,100,source,false,false),50),"All damage channels resist / "+source)
 g=game(2);var b=g.boss
 dealt=g.hit(b,1e10,"revolver",false,false)
 check(g.phase==2 and is_equal_approx(b.hp,b.max_hp*.5),"Second boss phase gate preserved")
 check(is_equal_approx(dealt,b.max_hp*.5),"Phase-clamped ledger excludes prevented damage")
 before=b.hp
 check(g.hit(b,10000,"revolver",false,false)==0 and b.hp==before and DR.multiplier(g,b)==0,"Reformation immunity remains")
 g=game(3);b=g.boss
 check(is_equal_approx(g.hit(b,100,"revolver",false,false),12),"Sealed anchors keep88% total DR, not multiplicative96.4%")
 check("BREAK THE ANCHORS" in DR.caption(g,b),"Sealed-core instruction visible")
 for anchor in g.anchors.duplicate():g.hit(anchor,1e10,"revolver",false,false)
 check(g.core_time==12 and is_equal_approx(g.hit(b,100,"revolver",false,false),60),"Breaking anchors earns40% DR core window")
 check("CORE EXPOSED" in DR.caption(g,b),"Core window state visible")
 g.hit(b,1e10,"revolver",false,false)
 check(g.phase==2 and is_equal_approx(b.hp,b.max_hp*.67) and not g.anchors.is_empty(),"Meteor phase2 gate survives godlike burst")
 before=b.hp;g.hit(b,1e10,"revolver",false,false)
 check(b.hp==before and DR.multiplier(g,b)==0,"Meteor reformation blocks skipped phases")
 b.reform=0
 for anchor in g.anchors.duplicate():g.hit(anchor,1e10,"revolver",false,false)
 g.hit(b,1e10,"revolver",false,false)
 check(g.phase==3 and is_equal_approx(b.hp,b.max_hp*.34),"Meteor phase3 gate remains")
 b.reform=0
 for anchor in g.anchors.duplicate():g.hit(anchor,1e10,"revolver",false,false)
 g.hit(b,1e10,"revolver",false,false)
 check(g.won and not g.active,"Godlike damage can still win after all mechanics")
 g=game(1);b=g.boss;b.hp=10
 var damage=g.hit(b,100,"revolver",false,false)
 check(damage==10 and g.damage_total==10,"Overkill excluded after resistance")
 g=game(1);g.weapons.clear();g.boss.hp=1000;g.update_boss(1)
 check(g.boss.hp==1000,"No passive boss healing introduced")
 var normal=g.spawn_enemy(false,g.pos+Vector2(100,0),0,false)
 normal.hp=1000
 check(is_equal_approx(g.hit(normal,100,"revolver",false,false),100),"Normal enemies unaffected")
 print("BOSS RESISTANCE / %s checks / %s failures"%[checks,failures]);quit(1 if failures else 0)
