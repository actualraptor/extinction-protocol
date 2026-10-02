extends RefCounted
## Authored route atlas; map geometry and rewards consume this same data.
const DATA={
 "cradle":{
  "bounds":Rect2(-40000,-34000,80000,68000),"spawn":Vector2.ZERO,
  "identity":"Wide jungle trails. +5% movement speed. Hunt for recovery and physical-build supplies.",
  "modifiers":{"player_speed":1.05},"ground_profile":"jungle","environment_profile":"grove",
  "passives":[
   {"id":"speed","p":Vector2(6000,-1000),"category":"passive","overflow":true,"maxed_amber":25},
   {"id":"regen","p":Vector2(-14000,8000),"category":"passive","overflow":true,"maxed_amber":25},
   {"id":"armor","p":Vector2(19000,16000),"category":"passive","overflow":true,"maxed_amber":25},
   {"id":"crit","p":Vector2(-27000,-14000),"category":"passive","overflow":true,"maxed_amber":25}],
  "signals":[
   {"id":"vesper","p":Vector2(16000,-16000),"depth":0},
   {"id":"mara","p":Vector2(-22000,16000),"depth":0},
   {"id":"ironbriar","p":Vector2(9500,8500),"depth":0},
   {"id":"ballistics","p":Vector2(-11500,-7000),"depth":0},
   {"id":"tracking","p":Vector2(23500,2500),"depth":0},
   {"id":"ancients","p":Vector2(-21000,-16000),"depth":1},
   {"id":"alchemy","p":Vector2(23000,18000),"depth":1},
   {"id":"myths","p":Vector2(-24000,19000),"depth":2}],
  "caches":[{"id":"heartwood_cache","name":"Heartwood Reliquary","p":Vector2(-5000,-21000)},{"id":"caldera_cache","name":"Caldera Hoard","p":Vector2(28000,4000)}],
  "regions":[
   {"name":"Firstfire Clearing","p":Vector2.ZERO,"radius":2800.0,"kind":"grove","color":"496e49"},
   {"name":"Hunter's Trail","p":Vector2(6000,-1000),"radius":4000.0,"kind":"grove","color":"7f7351"},
   {"name":"Mammoth Graveyard","p":Vector2(-11500,-7000),"radius":5500.0,"kind":"bones","color":"887860"},
   {"name":"Mosswater Basin","p":Vector2(-14000,8000),"radius":6000.0,"kind":"marsh","color":"335e58"},
   {"name":"Stormsplit Ruins","p":Vector2(16000,-16000),"radius":6500.0,"kind":"ruins","color":"54626f"},
   {"name":"Last Camp","p":Vector2(-22000,16000),"radius":4800.0,"kind":"grove","color":"726347"},
   {"name":"Titan's Spine","p":Vector2(19000,16000),"radius":6500.0,"kind":"ridge","color":"71685a"},
   {"name":"Amber Caldera","p":Vector2(28000,4000),"radius":5000.0,"kind":"crater","color":"7d5340"}],
  "landmarks":[
   {"id":"firstfire","name":"Firstfire Camp","p":Vector2(0,-320),"landmark_art":0,"scale":260.0},
   {"id":"ancient_tree","name":"Heartwood Giant","p":Vector2(-5000,-21350),"landmark_art":2,"scale":620.0},
   {"id":"mammoth","name":"Mammoth Graveyard","p":Vector2(-11500,-7350),"landmark_art":1,"scale":600.0},
   {"id":"rift_ruins","name":"Stormsplit Ruins","p":Vector2(16000,-16400),"landmark_art":3,"scale":480.0},
   {"id":"last_camp","name":"Voss's Last Camp","p":Vector2(-22000,15650),"landmark_art":0,"scale":420.0},
   {"id":"spine","name":"Titan's Spine","p":Vector2(19000,15650),"landmark_art":1,"scale":560.0}]},
 "frostbreak":{
  "bounds":Rect2(-40000,-34000,80000,68000),"spawn":Vector2.ZERO,
  "identity":"Glacial avenues and ice basins. +8% horde density and +8% XP from creatures.",
  "modifiers":{"density":1.08,"xp":1.08},"ground_profile":"snow","environment_profile":"ice",
  "passives":[
   {"id":"pickup","p":Vector2(-6500,0),"category":"passive","overflow":true,"maxed_amber":25},
   {"id":"haste","p":Vector2(11000,-8500),"category":"passive","overflow":true,"maxed_amber":25},
   {"id":"area","p":Vector2(-19000,-13000),"category":"passive","overflow":true,"maxed_amber":25},
   {"id":"regen","p":Vector2(21000,19000),"category":"passive","overflow":true,"maxed_amber":25}],
  "signals":[
   {"id":"iona","p":Vector2(23000,-21000),"depth":0},
   {"id":"glacier","p":Vector2(-16000,13000),"depth":1},
   {"id":"fracture","p":Vector2(16000,16000),"depth":1},
   {"id":"sundial","p":Vector2(-27000,-17000),"depth":2}],
  "caches":[{"id":"blue_cache","name":"Blue Ice Vault","p":Vector2(5000,18500)},{"id":"aurora_cache","name":"Aurora Reliquary","p":Vector2(-28500,4000)}],
  "regions":[
   {"name":"Sheltered Landing","p":Vector2.ZERO,"radius":3200.0,"kind":"ice","color":"75899a"},
   {"name":"Blue Ice Basin","p":Vector2(-6500,0),"radius":4800.0,"kind":"ice","color":"497b8b"},
   {"name":"Howling Pass","p":Vector2(11000,-8500),"radius":6000.0,"kind":"ridge","color":"919795"},
   {"name":"Frozen Colossus","p":Vector2(-19000,-13000),"radius":6000.0,"kind":"bones","color":"759098"},
   {"name":"Polar Expedition","p":Vector2(23000,-21000),"radius":5000.0,"kind":"ruins","color":"7c7a8d"},
   {"name":"Thawwater Springs","p":Vector2(21000,19000),"radius":7000.0,"kind":"marsh","color":"446b72"},
   {"name":"Aurora Shelf","p":Vector2(-28500,4000),"radius":7000.0,"kind":"ice","color":"637190"}],
  "landmarks":[
   {"id":"landing","name":"Sheltered Landing","p":Vector2(0,-340),"landmark_art":0,"scale":260.0},
   {"id":"colossus","name":"Frozen Colossus","p":Vector2(-19000,-13400),"landmark_art":1,"scale":650.0},
   {"id":"polar_camp","name":"Iona's Expedition","p":Vector2(23000,-21400),"landmark_art":0,"scale":460.0},
   {"id":"ice_vault","name":"Blue Ice Vault","p":Vector2(5000,18100),"landmark_art":4,"scale":460.0},
   {"id":"broken_sundial","name":"The Broken Sundial","p":Vector2(-27000,-17400),"landmark_art":5,"scale":500.0}]},
 "observatory":{
  "bounds":Rect2(-40000,-34000,80000,68000),"spawn":Vector2.ZERO,
  "identity":"Broken astronomical plazas. Elites arrive 12% more often; +5% chest luck.",
  "modifiers":{"elite_interval":0.88,"luck":0.05},"ground_profile":"ruins","environment_profile":"ruins",
  "passives":[
   {"id":"luck","p":Vector2(5000,4500),"category":"passive","overflow":true,"maxed_amber":25},
   {"id":"damage","p":Vector2(-12500,9000),"category":"passive","overflow":true,"maxed_amber":25},
   {"id":"count","p":Vector2(16500,-18000),"category":"passive","overflow":true,"maxed_amber":25},
   {"id":"armor","p":Vector2(-26000,-15000),"category":"passive","overflow":true,"maxed_amber":25}],
  "signals":[
   {"id":"orin","p":Vector2(-26000,22000),"depth":0},
   {"id":"riftcraft","p":Vector2(11000,-6000),"depth":0},
   {"id":"sunbow","p":Vector2(24500,11000),"depth":1},
   {"id":"prismwork","p":Vector2(-17500,-19000),"depth":1},
   {"id":"chronicle","p":Vector2(28500,-16000),"depth":2}],
  "caches":[{"id":"meridian_cache","name":"Meridian Vault","p":Vector2(-6500,-18000)},{"id":"star_cache","name":"Fallen Star Hoard","p":Vector2(19000,22000)}],
  "regions":[
   {"name":"Arrival Court","p":Vector2.ZERO,"radius":3200.0,"kind":"ruins","color":"52696b"},
   {"name":"Fortune Gardens","p":Vector2(5000,4500),"radius":4500.0,"kind":"grove","color":"4e6c62"},
   {"name":"Drowned Archive","p":Vector2(-12500,9000),"radius":6000.0,"kind":"marsh","color":"3b666d"},
   {"name":"Prism Array","p":Vector2(16500,-18000),"radius":5500.0,"kind":"ruins","color":"71658b"},
   {"name":"Shattered Bastion","p":Vector2(-26000,-15000),"radius":6000.0,"kind":"ridge","color":"84755b"},
   {"name":"Lost Astronomer's Camp","p":Vector2(-26000,22000),"radius":5500.0,"kind":"ruins","color":"6b6286"},
   {"name":"Fallen Star Crater","p":Vector2(19000,22000),"radius":7000.0,"kind":"crater","color":"73537b"},
   {"name":"Chronicle Spire","p":Vector2(28500,-16000),"radius":4500.0,"kind":"ruins","color":"8b7955"}],
  "landmarks":[
   {"id":"arrival","name":"Arrival Court","p":Vector2(0,-380),"landmark_art":3,"scale":320.0},
   {"id":"array","name":"Prism Array","p":Vector2(16500,-18400),"landmark_art":3,"scale":540.0},
   {"id":"astronomer","name":"Orin's Observatory","p":Vector2(-26000,21600),"landmark_art":3,"scale":600.0},
   {"id":"vault","name":"Meridian Vault","p":Vector2(-6500,-18400),"landmark_art":4,"scale":480.0},
   {"id":"spire","name":"Chronicle Spire","p":Vector2(28500,-16400),"landmark_art":3,"scale":650.0}]}
}
static func stage(id):
 var data=DATA.get(id,DATA.cradle).duplicate(true)
 data.id=id;data.routes=[]
 for group in ["passives","signals","caches","landmarks"]:
  for item in data[group]:data.routes.append(item.p)
 return data
static func validate(id):
 var s=stage(id);var errors=[];var objectives=[]
 for group in ["passives","signals","caches"]:
  for item in s[group]:
   if not s.bounds.grow(-1200).has_point(item.p):errors.append("Outside safe bounds: "+item.id)
   if item.p.distance_to(s.spawn)<4500:errors.append("Too close to spawn: "+item.id)
   for other in objectives:
    if item.p.distance_to(other.p)<1200:errors.append("Overlapping objectives: "+item.id+" / "+other.id)
   objectives.append(item)
 return errors
