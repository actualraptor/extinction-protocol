extends RefCounted
## Hidden permanent-upgrade definitions. Do not expose names before hero unlock.
const HERO=5
const ENTRIES={
 "army_power":{"name":"Bound Strength","desc":"Summons deal 6% more damage per rank.","max":5,"cost":240,"stat":"power","amount":.06,"icon":"power"},
 "army_health":{"name":"Deathless Bond","desc":"Summons gain 8% maximum health per rank.","max":5,"cost":220,"stat":"health","amount":.08,"icon":"vitality"},
 "army_haste":{"name":"Restless Legion","desc":"Summons attack 4% faster per rank.","max":5,"cost":300,"stat":"haste","amount":.04,"icon":"haste"}}
static func unlocked(save):return preload("res://scripts/discoveries.gd").hero_open(save,HERO)
static func visible_entry(save,id):
 if not ENTRIES.has(id):return {}
 if not unlocked(save):return {"locked":true,"icon":ENTRIES[id].icon,"silhouette":true}
 return ENTRIES[id].duplicate(true)
static func modifiers(save,hero):
 var result={"power":0.0,"health":0.0,"haste":0.0}
 if hero!=HERO or not unlocked(save):return result
 for id in ENTRIES:
  var e=ENTRIES[id]
  result[e.stat]+=clampi(int(save.get("research",{}).get(id,0)),0,e.max)*e.amount
 return result
