extends SceneTree
const R=preload("res://scripts/archive_respec.gd")
const S=preload("res://scripts/profile_store.gd")
const I=preload("res://scripts/atlas_icons.gd")
var checks=0
var fails=0
func check(ok,text):
 checks+=1
 if not ok:fails+=1;printerr("FAIL / ",text)
func _initialize():
 var p=S.migrate(S.defaults());p.amber=100000;p.hero=0
 p.discoveries=R.D.ENTRIES.keys();p.recipes=["whiteout"];p.records=[{"score":12,"hero":"VESPER"}];p.campaign.kills=123
 var initial=p.amber
 for id in R.C.RESEARCH:
  check(I.RESEARCH_ICONS.has(id) and I.get_icon(id,"research")!=null,"Explicit art / "+id)
  for rank_value in range(R.C.RESEARCH[id].max):
   if p.amber<R.rank_cost(id,rank_value):p.amber+=100000;initial+=100000
   check(R.buy_research(p,id),"Purchase / "+id)
 var spent=initial-p.amber
 check(R.research_total(p)==spent,"All rank prices refunded exactly")
 var records=p.records.duplicate(true);var recipes=p.recipes.duplicate();var discovered=p.discoveries.duplicate()
 check(R.refund_research(p)==spent and p.amber==initial and p.research.is_empty(),"Full research reset")
 check(R.refund_research(p)==0 and p.amber==initial,"Research refund cannot duplicate amber")
 for id in R.D.ENTRIES:
  if id not in p.unlocks:check(R.buy_discovery(p,id),"Discovery purchase / "+id)
 var paid=initial-p.amber
 check(R.refund_discoveries(p)==paid and p.amber==initial,"Paid unlock refund")
 check(R.refund_discoveries(p)==0 and p.amber==initial,"Unlock refund cannot duplicate amber")
 check(p.hero==1 and not R.D.hero_open(p,0),"Relocked selected hero falls back to Kael")
 check(p.records==records and p.recipes==recipes and p.discoveries==discovered and p.campaign.kills==123,"Records recipes discoveries milestones preserved")
 for id in R.D.ENTRIES:
  if R.D.ENTRIES[id].cost==0:check(id in p.unlocks,"Free unlock retained / "+id)
 check(R.buy_discovery(p,"mara") and p.amber==initial-180,"Refunded discovery immediately repurchasable")
 check(I.get_icon("map_frost","discovery").region!=I.get_icon("map_observatory","discovery").region,"Maps have distinct painted icons")
 var legacy=S.migrate(S.defaults());legacy.research={"vitality":3};legacy.unlocks=["mara","map_frost"];legacy.discoveries=legacy.unlocks.duplicate()
 check(R.refund_research(legacy)==70+115+190,"Legacy research uses accumulated catalog prices")
 check(R.refund_discoveries(legacy)==180 and legacy.unlocks==["map_frost"],"Legacy paid unlock refunded and free map preserved")
 var saved=S.migrate(JSON.parse_string(JSON.stringify(p)))
 check(saved.research_spent==p.research_spent and int(saved.discovery_spent.mara)==int(p.discovery_spent.mara),"Receipt dictionaries preserved by save migration")
 check(S.validate(saved),"Refunded profile remains valid")
 var free=S.migrate(S.defaults());free.campaign.kills=1000
 preload("res://scripts/campaign.gd").evaluate(free)
 var granted=free.unlocks.duplicate()
 check(R.refund_discoveries(free)==0 and free.unlocks==granted,"Milestone-earned legacy unlocks stay free and unlocked")
 var paid_profile=S.migrate(S.defaults());paid_profile.amber=180;paid_profile.discoveries=["mara"]
 R.buy_discovery(paid_profile,"mara");paid_profile.campaign.kills=100
 check(R.refund_discoveries(paid_profile)==180,"Recorded paid purchase refunded even if milestone later reached")
 preload("res://scripts/campaign.gd").evaluate(paid_profile)
 check(R.refund_discoveries(paid_profile)==0 and paid_profile.amber==180 and "mara" in paid_profile.unlocks,"Milestone regrant cannot generate duplicate refunds")
 print("ARCHIVE RESPEC / %s checks / %s failures"%[checks,fails]);quit(1 if fails else 0)
