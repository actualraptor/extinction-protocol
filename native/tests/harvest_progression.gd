extends SceneTree
const Stages=preload("res://scripts/stage_definition.gd")
const Campaign=preload("res://scripts/campaign.gd")
const Discoveries=preload("res://scripts/discoveries.gd")
var checks=0
var failures=0
class Survivor extends RefCounted:
 var max_hp=100.0
 var hp=50.0
func check(ok,message):
 checks+=1
 if not ok:failures+=1;printerr("FAIL / ",message)
func _initialize():
 for id in Stages.DATA:
  var stage=Stages.stage(id)
  check(stage.bounds.size==Vector2(44000,38000),"Compact authored stage bounds")
  check(stage.passives[0].p.length()<5000,"First supply reachable early")
  check(stage.signals.any(func(s):return s.p.length()<8000),"Nearby unlock goal")
  check(stage.caches.any(func(c):return c.get("encounter","")=="ambush"),"Optional guarded cache")
  check(stage.caches.any(func(c):return c.get("reward","")=="forge"),"Optional weapon forge")
  check(Stages.validate(id).is_empty(),"No overlapping objectives or boundary conflicts")
  check(Stages.stage(id).passives[0].p==stage.passives[0].p,"Biome rebuild does not shrink authored positions twice")
 var profile={"campaign":{"kills":0},"unlocks":[],"discoveries":[]}
 Discoveries.migrate(profile);Campaign.ensure(profile)
 check(profile.campaign.has("map_kills") and profile.campaign.has("weapon_damage"),"Old campaign gains missing counters")
 Campaign.record_build(profile,{"hero":"KAEL","damage_by_weapon":{"club":60000}})
 check("ironbriar" in Campaign.evaluate(profile),"Playing starter melee unlocks its armor retaliation build")
 check(Campaign.evaluate(profile).is_empty(),"Unlocks awarded only once")
 Campaign.record_build(profile,{"hero":"MARA VOSS","damage_by_weapon":{"revolver":100000}})
 check("ballistics" in Campaign.evaluate(profile),"Gun use unlocks gun progression without kill grind")
 check(Campaign.suggested_goals(profile,"cradle").size()<=3,"Suggested goal list stays bounded")
 check(Campaign.suggested_goals(profile,"cradle").all(func(g):return g.id not in profile.unlocks),"Suggested goals exclude completed unlocks")
 check(Campaign.track_goal(profile,"vesper"),"Unfinished discoveries can be tracked")
 check(Campaign.suggested_goals(profile,"cradle")[0].id=="vesper","Tracked goal stays first")
 check(Campaign.tracked_goal(profile).id=="vesper","Tracked goal includes display information")
 check(not Campaign.track_goal(profile,"ironbriar"),"Completed unlock cannot replace tracked goal")
 var survivor=Survivor.new()
 check(Discoveries.field_reward(survivor,"vesper")==12 and survivor.hp==62,"Finding a survivor provides immediate healing")
 survivor.hp=99
 check(Discoveries.field_reward(survivor,"vesper")==1 and survivor.hp==100,"Discovery heal never exceeds max health")
 check(Discoveries.field_reward(survivor,"invalid")==0,"Invalid signal never grants a reward")
 print("HARVEST PROGRESSION / %s checks / %s failures"%[checks,failures]);quit(1 if failures else 0)

