extends SceneTree
const Store=preload("res://scripts/profile_store.gd")
const Lesson=preload("res://scripts/torr_lesson.gd")
const Exp=preload("res://scripts/expedition.gd")
var failures=0
var checks=0
func check(ok,why):
 checks+=1
 if not ok:failures+=1;printerr("FAIL / ",why)
func _initialize():call_deferred("run")
func fresh(hero=-1):
 var g=Exp.new();g.setup(1,"expedition",{},171017)
 g.hero=preload("res://scripts/god_content.gd").install(g.C) if hero<0 else hero
 g.weapons={g.C.HEROES[g.hero].weapon:{"level":1,"evolved":false,"timer":0.0}}
 g.configure_content(Store.migrate(Store.defaults()))
 return g
func run():
 var g=fresh()
 check(Lesson.eligible(g),"First Torr expedition can receive the mortal lesson")
 g.open_choices(false)
 check(g.options.any(func(o):return o.get("torr_lesson",false)),"Lesson has a visible slot in the first eligible draft")
 var index=0
 for i in g.options.size():
  if g.options[i].get("torr_lesson",false):index=i
 var slots=g.weapons.size()
 g.choose(index)
 check(g.choosing and g.god_state.lesson_pending and not g.weapons.has("club"),"Choosing the lesson reserves its reward without equipping a mortal weapon")
 check(not Lesson.request(g),"Duplicate request cannot start a second story")
 check(Lesson.complete(g) and g.weapons.mjolnir.level==2 and g.weapons.size()==slots,"Completion grants one real divine rank without spending a weapon slot")
 check(not Lesson.complete(g) and g.weapons.mjolnir.level==2,"Repeated completion cannot duplicate rewards")
 check(not g.upgrade_pool().any(func(o):return o.get("torr_lesson",false)),"Lesson does not repeat within the run")
 var full=fresh();full.weapons.mjolnir.level=10
 for id in ["gungnir","cloudbreaker","ninefold","summer_edge"]:full.weapons[id]={"level":10,"evolved":true,"timer":0.0}
 full.options=[{"type":"weapon","id":"club","torr_lesson":true}];full.choosing=true;full.choose(0)
 var before=full.amber;Lesson.complete(full)
 check(full.amber==before+50 and full.weapons.size()==5,"Fully upgraded inventory receives meaningful supplies without losing an item")
 var milestone=fresh();milestone.weapons.mjolnir.level=4
 milestone.options=[{"type":"weapon","id":"club","torr_lesson":true}];milestone.choosing=true;milestone.choose(0);Lesson.complete(milestone)
 check(milestone.choosing and milestone.options[0].type=="beam_path" and milestone.options[0].milestone==5,"Replacement preserves the rank-5 branch choice")
 for hero in range(g.hero):
  var other=fresh(hero);other.options=[{"type":"weapon","id":"club","torr_lesson":true}];other.choosing=true;other.choose(0)
  check(not other.god_state.get("lesson_pending",false),"Other heroes cannot inject Torr's story reward")
 var profile=Store.migrate(Store.defaults());profile.settings[Lesson.SEEN]=true;profile.future_keep="retained"
 var path="res://build/torr-lesson-profile.json"
 check(Store.save_profile(path,profile)=="","Seen flag saves through ProfileStore")
 var loaded=Store.load_profile(path).data
 check(loaded.settings[Lesson.SEEN] and loaded.future_keep=="retained","Seen flag and unrelated fields survive disk reload")
 var veteran=fresh();veteran.configure_content(loaded)
 check(not Lesson.eligible(veteran),"Returning Torr never receives another mortal lesson")
 check(preload("res://scripts/cinematic_gallery.gd").entries(loaded).any(func(o):return o.id=="torr_mortal"),"Completed lesson appears in replay gallery")
 profile.settings[Lesson.SEEN]="yes"
 check(not Store.validate(profile),"Malformed completion flag is rejected")
 var dead=fresh();Lesson.request(dead);dead.finish(false)
 check(not Lesson.complete(dead),"An interrupted/ended run cannot receive a late reward")
 print("TORR LESSON / ",checks," checks / ",failures," failures")
 quit(1 if failures else 0)
