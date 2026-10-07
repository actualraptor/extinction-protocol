extends RefCounted
## Curated exploration rewards. Unlike dropped consumables, these never expire or magnetize.
const C=preload("res://scripts/catalog.gd")
const Rules=preload("res://scripts/combat_rules.gd")
static func setup(g):
 g.stage_objects=[]
 for group in ["passives","caches"]:
  for entry in g.stage.get(group,[]):
   var kind=entry.get("category","passive") if group=="passives" else "cache"
   var catalog=C.AUGMENTS if kind=="augment" else C.PASSIVES
   if kind!="cache" and not catalog.has(entry.id):
    push_warning("Unknown stage reward: "+entry.id);continue
   if entry.has("depth") and int(entry.depth)!=g.depth:continue
   var key=g.map_id+":"+entry.id
   var p=g.terrain.open_position(entry.p)
   if p.distance_to(entry.p)>640 or not g.terrain.walkable(p,22):
    push_warning("Unreachable stage reward: "+entry.id);continue
   g.stage_objects.append({"key":key,"id":entry.id,"p":p,"type":kind,"name":entry.get("name",catalog[entry.id].name if kind!="cache" else "Ancient Cache"),"collected":g.collected_stage_objects.has(key),"seen":false,"overflow":entry.get("overflow",true),"maxed_amber":entry.get("maxed_amber",25)})
   g.stage_objects[-1].encounter=entry.get("encounter","")
   g.stage_objects[-1].guard_count=clampi(int(entry.get("guards",8)),1,12)
   g.stage_objects[-1].guards=[]
   g.stage_objects[-1].started=false
   g.stage_objects[-1].reward=entry.get("reward","relic")
static func update(g):
 if not g.active or g.choosing:return
 for item in g.stage_objects:
  if item.collected:continue
  var distance=g.pos.distance_squared_to(item.p)
  if distance<=900*900:item.seen=true
  if item.get("encounter","")=="ambush":
   if not item.started and distance<=150*150 and g.spawn_respite<=0:
    item.started=true
    for i in range(item.guard_count):
     var at=item.p+Vector2.from_angle(TAU*i/item.guard_count)*260
     var guard=g.spawn_enemy(false,at,-1,false)
     guard.encounter_guard=true
     item.guards.append(guard)
    g.banner.emit(item.name.to_upper(),"Defeat guardians / forge your strongest unfinished weapon" if item.reward=="forge" else "Defeat its guardians, then claim the chest")
    g.effect.emit("evolve",item.p,Color("b982ed"),230)
    g.log_event("stage-ambush",{"id":item.id,"guards":item.guard_count})
   if not item.started or item.guards.any(func(e):return not e.dead):continue
  if distance>44*44:continue
  if item.type=="cache":
   mark(g,item)
   if item.get("reward","")=="forge":
    var candidate=""
    for weapon in g.weapons:
     var state=g.weapons[weapon]
     if int(state.level)>=10 or state.get("evolved",false):continue
     if candidate=="" or int(state.level)>int(g.weapons[candidate].level):candidate=weapon
    if candidate!="":
     g.weapons[candidate].level+=1
     g.banner.emit("ANCIENT FORGE",C.WEAPONS[candidate].name+" / RANK "+str(g.weapons[candidate].level))
    else:
     g.amber+=40
     g.banner.emit("ANCIENT FORGE","ARSENAL COMPLETE / +40 AMBER")
    g.modifier_cache.clear()
    g.sound.emit("loot")
    g.effect.emit("evolve",item.p,Color("edce8e"),200)
    g.log_event("stage-forge",{"id":candidate,"map":g.map_id})
    return
   g.log_event("stage-cache",{"id":item.id,"map":g.map_id})
   g.open_choices(true)
   return
  var catalog=C.AUGMENTS if item.type=="augment" else C.PASSIVES
  if not catalog.has(item.id):continue
  if item.type=="augment" and not Rules.eligible(g.weapons,C.WEAPONS,catalog[item.id].filter):continue
  var owned=g.augments if item.type=="augment" else g.passives
  if not owned.has(item.id) and not item.overflow and not g.can_take_buff(item.id):continue
  var rank_value=int(owned.get(item.id,0))
  var maxed=rank_value>=catalog[item.id].max
  if maxed:g.amber+=int(item.maxed_amber)
  else:
   var reward=g.BuffRewards.decorate(g,{"type":item.type,"id":item.id},"",1,"map")
   owned[item.id]=rank_value+1
   g.BuffRewards.grant(g,reward,1)
   if item.type=="passive" and item.id=="armor":
    g.armor+=2*reward.stat_gain;g.max_hp+=roundi(12*reward.stat_gain);g.hp+=roundi(12*reward.stat_gain)
   g.log_event("map-buff-tier",reward)
  mark(g,item)
  g.modifier_cache.clear()
  g.banner.emit(item.name.to_upper(),"MAX RANK / +%s AMBER"%int(item.maxed_amber) if maxed else "WORLD DISCOVERY / RANK %s"%(rank_value+1))
  g.sound.emit("loot")
  g.effect.emit("evolve",item.p,Color("edce8e"),200)
  g.log_event("stage-passive",{"id":item.id,"map":g.map_id,"rank":rank_value if maxed else rank_value+1,"amber":int(item.maxed_amber) if maxed else 0})
static func mark(g,item):
 item.collected=true
 g.collected_stage_objects[item.key]=true
