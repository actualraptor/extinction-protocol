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
static func update(g):
 if not g.active or g.choosing:return
 for item in g.stage_objects:
  if item.collected:continue
  var distance=g.pos.distance_squared_to(item.p)
  if distance<=900*900:item.seen=true
  if distance>44*44:continue
  if item.type=="cache":
   mark(g,item)
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
   owned[item.id]=rank_value+1
   if item.type=="passive" and item.id=="armor":
    g.armor+=2;g.max_hp+=12;g.hp+=12
  mark(g,item)
  g.modifier_cache.clear()
  g.banner.emit(item.name.to_upper(),"MAX RANK / +%s AMBER"%int(item.maxed_amber) if maxed else "WORLD DISCOVERY / RANK %s"%(rank_value+1))
  g.sound.emit("loot")
  g.effect.emit("evolve",item.p,Color("edce8e"),200)
  g.log_event("stage-passive",{"id":item.id,"map":g.map_id,"rank":rank_value if maxed else rank_value+1,"amber":int(item.maxed_amber) if maxed else 0})
static func mark(g,item):
 item.collected=true
 g.collected_stage_objects[item.key]=true
