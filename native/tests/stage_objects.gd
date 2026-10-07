extends SceneTree
const Objects=preload("res://scripts/stage_objects.gd")
class Harness extends RefCounted:
 const BuffRewards=preload("res://scripts/buff_rewards.gd")
 const C=preload("res://scripts/catalog.gd")
 const Relics=preload("res://scripts/relic_system.gd")
 var rng=RandomNumberGenerator.new();var buff_stacks={}
 var research_ranks={};var mods={};var luck=0;var chest_pity=0;var level=1
 var permanent_luck=0.0;var relic_state={}
 func rank_of(id):return int(passives.get(id,augments.get(id,0)))
 func buff_power(id):return BuffRewards.power(self,id)
 var stage={};var stage_objects=[];var collected_stage_objects={};var map_id="cradle";var depth=0
 var terrain=preload("res://scripts/terrain_map.gd").new()
 var active=true;var choosing=false;var pos=Vector2.ZERO;var spawn_respite=0.0
 var passives={};var augments={};var weapons={"club":{"level":1,"evolved":false,"timer":0}}
 var armor=4;var hp=100;var max_hp=170;var amber=0;var modifier_cache={"test":1}
 var cache_calls=0;var events=[];var discovered=[]
 signal banner(a,b)
 signal sound(id)
 signal effect(a,b,c,d)
 func can_take_buff(id):return passives.has(id) or augments.has(id) or passives.size()+augments.size()<8
 func log_event(kind,data):events.append({"kind":kind,"data":data})
 func open_choices(_relic):cache_calls+=1;choosing=true
 func spawn_enemy(_elite,_at,_kind,_announce):return {"dead":false,"p":_at}
var checks=0
var failures=0
func check(ok,text):
 checks+=1
 if not ok:failures+=1;printerr("FAIL / ",text)
func _initialize():
 var g=Harness.new()
 g.stage={"passives":[{"id":"armor","p":Vector2(6500,6000),"category":"passive","overflow":true}],"caches":[{"id":"ruin-cache","p":Vector2(-12000,9000),"name":"Ruin Cache"}]}
 for id in ["damage","haste","crit","luck","area","pickup","regen","count"]:g.passives[id]=1
 Objects.setup(g)
 check(g.stage_objects.size()==2,"Curated passive and cache created")
 check(g.stage_objects.all(func(o):return not o.seen and not o.collected),"Far objectives start unseen and uncollected")
 var item=g.stage_objects[0]
 check(item.p.distance_to(Vector2(6500,6000))<640,"Far pickup never collapses to spawn")
 Objects.update(g)
 check(not item.collected and not g.passives.has("armor"),"No remote or magnet pickup")
 g.pos=item.p+Vector2(45,0);Objects.update(g)
 check(item.seen and not item.collected,"Close enough to see but outside collection range")
 g.pos=item.p;Objects.update(g)
 check(item.collected and g.passives.armor==1 and g.passives.size()==9,"World passive exceeds normal capacity")
 check(g.armor>4 and g.max_hp>170 and g.hp==100+(g.max_hp-170),"Armor includes rolled health and armor benefits")
 check(g.modifier_cache.is_empty(),"Cached modifiers invalidated")
 Objects.update(g);check(g.passives.armor==1,"Collection only once")
 Objects.setup(g);check(g.stage_objects[0].collected,"Collected state survives setup and depth rebuild")
 g.pos=g.stage_objects[1].p;g.choosing=true;Objects.update(g)
 check(not g.stage_objects[1].collected and g.cache_calls==0,"Cache waits for current reward")
 g.choosing=false;Objects.update(g)
 check(g.stage_objects[1].collected and g.cache_calls==1 and g.choosing,"Cache opens actual reward flow exactly once")
 g.choosing=false;Objects.update(g);check(g.cache_calls==1,"Claimed cache cannot reopen")
 g.collected_stage_objects.clear();g.passives.armor=5;g.choosing=false;Objects.setup(g);g.pos=g.stage_objects[0].p;Objects.update(g)
 check(g.passives.armor==5 and g.amber==25,"Max rank becomes configured amber reward")
 g.collected_stage_objects.clear();g.stage.passives[0].overflow=false;g.passives.erase("armor");Objects.setup(g);g.pos=g.stage_objects[0].p;Objects.update(g)
 check(not g.stage_objects[0].collected and not g.passives.has("armor"),"Non-overflow item respects full inventory")
 g.passives.erase("damage");Objects.update(g);check(g.passives.armor==1,"Non-overflow pickup works when a slot opens")
 g=Harness.new();g.passives.speed=2;g.stage={"passives":[{"id":"speed","p":Vector2(6000,0)}]};Objects.setup(g);g.pos=g.stage_objects[0].p;Objects.update(g)
 check(g.passives.speed==3,"Owned passive gains one rank")
 g=Harness.new();g.stage={"passives":[{"id":"sorcery","category":"augment","p":Vector2(6000,0)}]};Objects.setup(g);g.pos=g.stage_objects[0].p;Objects.update(g)
 check(not g.stage_objects[0].collected and g.augments.is_empty(),"Incompatible augment remains available")
 g.weapons={"lightning":{"level":1,"evolved":false,"timer":0}};Objects.update(g)
 check(g.stage_objects[0].collected and g.augments.sorcery==1,"Compatible augment applies after build changes")
 g=Harness.new();g.stage={"signals":[{"id":"vesper","p":Vector2(16000,-16000),"depth":0},{"id":"mara","p":Vector2(-16000,14000),"depth":1}]}
 var markers=preload("res://scripts/discoveries.gd").landmarks(g)
 check(markers.size()==1 and markers[0].id=="vesper","Only configured signals in active depth appear")
 check(markers[0].p.length()>20000,"Character signal stays far from spawn")
 g.discovered=["vesper"];markers=preload("res://scripts/discoveries.gd").landmarks(g)
 check(markers[0].found,"Previously found signal remains recorded")
 g.depth=1;markers=preload("res://scripts/discoveries.gd").landmarks(g)
 check(markers.size()==1 and markers[0].id=="mara","Changing depth uses that depth's curated signals")
 g.stage={"signals":[]};check(preload("res://scripts/discoveries.gd").landmarks(g).is_empty(),"No fallback duplicate mapless signals")
 g=Harness.new();g.stage={"caches":[{"id":"challenge","name":"Cursed Reliquary","p":Vector2(6000,0),"encounter":"ambush","guards":8}]};Objects.setup(g)
 g.pos=g.stage_objects[0].p;Objects.update(g)
 item=g.stage_objects[0]
 check(item.started and item.guards.size()==8 and g.cache_calls==0,"Ambush starts a bounded pack before reward")
 Objects.update(g);check(item.guards.size()==8,"Ambush cannot continuously spawn more guardians")
 for guardian in item.guards:guardian.dead=true
 Objects.update(g);check(item.collected and g.cache_calls==1,"Defeated guardians unlock the reward once")
 g=Harness.new();g.stage={"caches":[{"id":"forge","name":"Ancient Forge","p":Vector2(6000,0),"reward":"forge"}]};g.weapons.club.level=9;Objects.setup(g);g.pos=g.stage_objects[0].p;Objects.update(g)
 check(g.weapons.club.level==10 and g.cache_calls==0,"Forge advances unfinished weapon to evolution readiness without random chest")
 g.collected_stage_objects.clear();Objects.setup(g);Objects.update(g)
 check(g.weapons.club.level==10 and g.amber==40,"Completed arsenal gets amber instead of a wasted forge")
 print("STAGE OBJECTS / %s checks / %s failures"%[checks,failures]);quit(1 if failures else 0)
