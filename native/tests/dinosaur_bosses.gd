extends SceneTree
const E=preload("res://scripts/expedition.gd")
const B=preload("res://scripts/boss_encounters.gd")
const A=preload("res://scripts/dinosaur_attacks.gd")
const Art=preload("res://scripts/dinosaur_boss_art.gd")
const Rig=preload("res://scripts/remnant_rig.gd")
var checks=0
var failures=0
func check(ok,message):
 checks+=1
 if not ok:failures+=1;printerr("FAIL / ",message)
func _initialize():call_deferred("run")
func run():
 preload("res://scripts/content_extension.gd").install(preload("res://scripts/catalog.gd"))
 var species={}
 for e in preload("res://scripts/bestiary.gd").DATA:species[e.species]=true
 for map in B.IDS:
  for stage in [1,2]:
   var g=E.new();g.setup(1,"expedition",{},906,map);g.weapons.clear();g.enemies.clear();g.spawn_boss(stage)
   var b=g.boss;var id=b.identity
   var name=preload("res://scripts/boss_identity.gd").DATA[id].species
   check(not species.has(name),"No enemy/boss duplicate / "+name);species[name]=true
   check(b.action=="intro","Entrance starts / "+id)
   for j in range(65):g.update_boss(.05)
   check(b.action=="recover" and b.intro_roared,"Entrance completes / "+id)
   for phase in [1,2]:
    g.phase=phase;b.hp=b.max_hp*(.4 if phase==2 else 1.0)
    for move in A.MOVES[id]:
     b.attack_index=A.MOVES[id].find(move);g.hazards.clear();g.pos=b.p+Vector2(180,0)
     B.prepare(g)
     check(b.move==move and b.action=="windup","Move begins / "+id+" / "+move)
     check(not g.hazards.is_empty(),"Move telegraph exists / "+move)
     var locked=b.aim;var target=b.target;g.pos+=Vector2(500,500)
     B.update(g,.1);check(b.aim==locked and b.target==target,"Tell remains committed / "+move)
     var steps=0
     while b.action!="recover" and steps<100:
      g.invul=100;B.update(g,.05);steps+=1
     check(b.action=="recover","Move recovers / "+move)
     check(g.hostile_shots.is_empty() and b.props.is_empty(),"Physical attacks do not spawn legacy spell props / "+id)
   for frame in range(8):
    var art=Rig.atlas_pose(id,frame)
    check(art!=null and art.get_width()>0,"Undead animation cell / "+id+str(frame))
   check(Art.corpse(id) is ImageTexture,"Cinematic corpse is a standalone texture / "+id)
   check(Art.corpse(id).get_height()<384,"Corpse excludes transparent atlas padding / "+id)
   b.aim=Vector2.RIGHT;b.motion=Vector2.RIGHT
   check(A.segment_hits(b,b.p+Vector2(70,-100),b.p+Vector2(70,100),9),"Projectile can strike extended body / "+id)
   check(not A.segment_hits(b,b.p+Vector2(-100,180),b.p+Vector2(100,180),9),"Projectile misses outside body / "+id)
   b.reform=0;g.boss_time=4;g.kill(b)
   check(g.boss==null and g.portal!=null and g.choosing,"Death rewards and progression / "+id)
   check(g.boss_corpses.size()==1 and g.boss_corpses[0].identity==id,"Correct corpse / "+id)
 var g=E.new();g.setup(1,"expedition",{},906);g.spawn_boss(3)
 check(not g.boss.has("identity") and g.boss.immovable and g.anchors.size()==3,"Meteor backbone unchanged")
 check("meteor" not in preload("res://scripts/remnant_system.gd").IDENTITIES,"Meteor not eligible")
 print("DINOSAUR BOSSES / ",checks," checks / ",failures," failures")
 quit(1 if failures else 0)
