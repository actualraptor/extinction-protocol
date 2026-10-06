extends RefCounted
static func collect(g):
 var result=[]
 for item in g.stage_objects:
  if not item.collected:result.append({"p":item.p,"name":item.name,"id":"chest" if item.type=="cache" else item.id,"category":"relic" if item.type=="cache" else item.type})
 for p in g.relic_chests:result.append({"p":p,"name":"RELIC CHEST","id":"chest","category":"relic"})
 var pickup_icons={"heal":"blood","magnet":"magnet","frenzy":"boots","surge":"storm","freeze":"frost","immune":"shell","nuke":"ember"}
 for item in g.pickups:
  result.append({"p":item.p,"name":preload("res://scripts/world_pickups.gd").DEFINITIONS[item.id].name,"id":pickup_icons.get(item.id,"ember"),"category":"relic"})
 for marker in g.landmarks:
  if not marker.found:result.append({"p":marker.p,"name":marker.name,"id":"camp","category":"relic"})
 if g.portal!=null:result.append({"p":g.portal,"name":"NEXT BIOME","id":"portal","category":"relic"})
 if g.boss!=null:result.append({"p":g.boss.p,"name":preload("res://scripts/boss_identity.gd").short_name(g.boss.get("identity","meteor")),"id":g.boss.get("identity","meteor"),"category":"boss"})
 return result
