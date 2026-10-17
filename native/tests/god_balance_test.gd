extends SceneTree
const Exp=preload("res://scripts/expedition.gd")
const God=preload("res://scripts/god_system.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok,why):
 checks+=1
 if not ok:failures+=1;printerr("FAIL / ",why)
func fresh(id,rank=1):
 var g=Exp.new();g.setup(7,"expedition",{},42)
 g.enemies.clear();g.weapons={id:{"level":rank,"evolved":false,"timer":999,"branches":{}}}
 return g
func enemy(g,p):
 var e=g.spawn_enemy(false,p,0,false);e.p=p;e.hp=100000;e.max_hp=e.hp;e.speed=0;g.build_grid();return e
func run():
 for id in ["summer_edge","cloudbreaker","oathsplitter"]:
  var damage=[]
  for echoes in [0,2]:
   var g=fresh(id);var prey=enemy(g,g.pos+Vector2(90,0));var stats=g.Rules.stats(g,id);stats.repeat=echoes
   God.cast(g,id,stats)
   for tick in 90:g.time+=1.0/30;g.build_grid();God.update(g,1.0/30)
   damage.append(g.damage_total)
   check(g.god_state.events.is_empty(),id+" echoes finish without recursively scheduling more casts")
  check(damage[1]>damage[0]*2,id+" actually repeats its strikes")
 var wide=fresh("cloudbreaker",5);wide.weapons.cloudbreaker.branches["5"]="wide"
 var outer=enemy(wide,wide.pos+Vector2.from_angle(1.5)*90)
 God.cast(wide,"cloudbreaker",wide.Rules.stats(wide,"cloudbreaker"))
 check(outer.hp<outer.max_hp,"Wide gauntlet cone reaches its promised side angle")
 check(is_equal_approx(wide.god_state.effects[0].arc,1.65),"Drawn cone follows its hit angle")
 var boss=fresh("oathsplitter");boss.spawn_boss(2);boss.boss.reform=0;boss.boss.rig_heading=0
 var edge=boss.boss.p+Vector2(100,0);var stats=boss.Rules.stats(boss,"oathsplitter");stats.radius=10
 var before=boss.boss.hp;God.cut(boss,"oathsplitter",edge,Vector2.UP,stats)
 check(boss.boss.hp<before,"Small oath cut hits the dinosaur body away from its centre")
 var hammer=fresh("mjolnir",10);var s=hammer.Rules.stats(hammer,"mjolnir")
 var preview=preload("res://scripts/reward_preview.gd").effective(hammer,"mjolnir",s,10,false)
 check(is_equal_approx(preview.power,s.power),"Hammer rank-10 damage agrees with its card")
 var rebuke=fresh("ninefold")
 check(not preload("res://scripts/god_content.gd").eligible_augment(rebuke,"linger"),"No unused ground-linger augment in divine drafts")
 print("GOD BALANCE / ",checks," checks / ",failures," failures")
 quit(1 if failures else 0)
