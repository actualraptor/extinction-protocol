extends RefCounted
const SEEN="torr_mortal_seen"
static func eligible(g):
 return g.active and g.mode=="expedition" and g.C.HEROES[g.hero].get("voice_key","")=="torr" and g.content_profile.has("settings") and not g.content_profile.settings.get(SEEN,false) and not g.god_state.get("lesson_done",false)
static func reward(g):
 var candidate="mjolnir" if g.weapons.has("mjolnir") and g.weapons.mjolnir.level<10 else ""
 if candidate=="":
  for id in g.weapons:
   if "GOD" in g.C.WEAPONS[id].get("tags",[]) and g.weapons[id].level<10 and (candidate=="" or g.weapons[id].level<g.weapons[candidate].level):candidate=id
 if candidate!="":return {"type":"weapon","id":candidate,"rank_gain":1}
 return {"type":"supplies","id":"supplies","amber_gain":50,"heal_gain":25}
static func description(g):
 var r=reward(g)
 var benefit="Gain one rank of "+g.C.WEAPONS[r.id].name+"." if r.type=="weapon" else "Gain 50 amber and restore 25 health."
 return "A mortal offers Ancestor's Wrath. Torr tries one easy swing.\nA short illustrated story, then a divine replacement.\n"+benefit+" No weapon slot is used."
static func request(g):
 if not eligible(g) or g.god_state.get("lesson_pending",false):return false
 g.god_state.lesson_pending=true
 g.torr_lesson_requested.emit()
 return true
static func complete(g):
 if not g.active or not g.god_state.get("lesson_pending",false):return false
 g.god_state.lesson_pending=false;g.god_state.lesson_done=true
 var r=reward(g)
 g.options=[r];g.choosing=true
 g.choose(0)
 g.log_event("torr-mortal-lesson",{"replacement":r.id})
 return true
