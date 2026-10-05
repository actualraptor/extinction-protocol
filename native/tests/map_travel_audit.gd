extends SceneTree
const Stages=preload("res://scripts/stage_definition.gd")
const Expedition=preload("res://scripts/expedition.gd")
var checks=0
var failures=0
func check(ok,message):
 checks+=1
 if not ok:failures+=1;printerr("FAIL / ",message)
func _initialize():
 var rows=[]
 for id in Stages.DATA:
  var g=Expedition.new();g.setup(1,"expedition",{},81927,id)
  check(g.hero==1 and g.passives.is_empty(),"Fresh starter Kael, no upgrades")
  check(Stages.validate(id).is_empty(),"Authored objective spacing / "+id)
  var times=[]
  for group in ["passives","signals","caches"]:
   for objective in g.stage[group]:
    g.pos=g.stage.spawn
    var destination=g.terrain.open_position(objective.p)
    var seconds=0.0
    while g.pos.distance_to(destination)>40 and seconds<100:
     var movement=(destination-g.pos).normalized()*g.speed()/30.0
     if g.terrain.kind(g.terrain.cell(g.pos))==2:movement*=0.65
     g.pos=g.terrain.move(g.pos,movement)
     seconds+=1.0/30.0
    check(seconds<90,"Reachable in under 90s / "+id+" / "+objective.id)
    times.append(seconds)
    rows.append("| %s | %s | %.1f s |"%[id,objective.id,seconds])
  check(times[0]>=15 and times[0]<=25,"First supply 15–25s / "+id)
  check(times.filter(func(t):return t>=25 and t<=60).size()>=times.size()/2,"Most objectives roughly 30–60s / "+id)
 var report="# Measured compact stage travel\n\nFresh Kael (no research, no items), seeded terrain 81927, using actual terrain movement/collision at 30Hz and map speed modifiers; includes mud slowing if encountered. Movement-only isolated route measurement; combat and detours add time. Arena and attack ranges unchanged.\n\n| Map | Objective | Terrain route time |\n|---|---|---|\n"+"\n".join(rows)+"\n"
 var f=FileAccess.open("res://build/map-travel-measured.md",FileAccess.WRITE);f.store_string(report);f.close()
 print(report)
 print("COMPACT TRAVEL / %s checks / %s failures"%[checks,failures]);quit(1 if failures else 0)
