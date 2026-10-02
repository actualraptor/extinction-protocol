extends SceneTree
const S=preload("res://scripts/profile_store.gd")
const D=preload("res://scripts/discoveries.gd")
const R=preload("res://scripts/archive_respec.gd")
var checks=0
var fails=0
func check(ok,msg):
 checks+=1
 if not ok:fails+=1;printerr("FAIL / ",msg)
func _initialize():
 var fresh=S.migrate(S.defaults())
 for hero in range(5):check(D.hero_open(fresh,hero)==(hero==1),"Kael is only new-profile starter / %s"%hero)
 check(D.ENTRIES.vesper.hero==2 and D.ENTRIES.vesper.cost==0,"Vesper is a free exploration unlock")
 fresh.discoveries.append("vesper")
 check(D.purchase(fresh,"vesper") and D.hero_open(fresh,2),"Finding Vesper makes her recruitable")
 for runs in [0,8]:
  var old=S.defaults();old.erase("starter_rules");old.runs=runs;old.amber=456;old.research={"power":3};old.unlocks=["mara","iona","unknown_future"]
  old.discoveries=old.unlocks.duplicate();old.recipes=["whiteout"]
  var migrated=S.migrate(old)
  check(D.hero_open(migrated,2),"Old implicit Vesper preserved even at zero runs")
  check(migrated.amber==456 and migrated.research.power==3 and "unknown_future" in migrated.unlocks and migrated.recipes==["whiteout"],"Existing progress preserved")
  check(JSON.stringify(S.migrate(migrated))==JSON.stringify(migrated),"Starter migration idempotent")
 var paid=S.migrate(S.defaults());paid.amber=180;paid.discoveries.append("mara");R.buy_discovery(paid,"mara");paid.hero=0
 R.refund_discoveries(paid)
 check(paid.hero==1 and D.hero_open(paid,1),"Refund fallback is available Kael")
 var path="res://build/starter-new-profile.json"
 check(S.save_profile(path,S.migrate(S.defaults()))=="","New profile serializes")
 var loaded=S.load_profile(path).data
 check(D.hero_open(loaded,1) and not D.hero_open(loaded,2),"Reload does not accidentally grant Vesper")
 print("STARTER MIGRATION / %s checks / %s failures"%[checks,fails]);quit(1 if fails else 0)
