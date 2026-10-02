extends RefCounted
## Refunds preserve discovery knowledge, free rewards and historical records.
const C=preload("res://scripts/catalog.gd")
const D=preload("res://scripts/discoveries.gd")
static func rank_cost(id,rank_value):return int(C.RESEARCH[id].cost*pow(1.65,rank_value))
static func research_receipts(save,id):
 var receipts=save.get("research_spent",{}).get(id,[])
 var result=[]
 for rank_value in range(clampi(int(save.research.get(id,0)),0,C.RESEARCH[id].max)):
  result.append(int(receipts[rank_value]) if rank_value<receipts.size() else rank_cost(id,rank_value))
 return result
static func research_total(save):
 var total=0
 for id in C.RESEARCH:
  for paid in research_receipts(save,id):total+=paid
 return total
static func discovery_cost(save,id):
 if save.get("discovery_spent",{}).has(id):return int(save.discovery_spent[id])
 var entry=D.ENTRIES[id]
 if entry.has("goal") and preload("res://scripts/campaign.gd").value(save,entry)>=entry.target:return 0
 return int(entry.cost)
static func discovery_total(save):
 var total=0
 for id in D.ENTRIES:
  if id in save.get("unlocks",[]) and D.ENTRIES[id].cost>0:total+=discovery_cost(save,id)
 return total
static func buy_research(save,id):
 if not C.RESEARCH.has(id):return false
 var rank_value=int(save.research.get(id,0));var cost=rank_cost(id,rank_value)
 if rank_value>=C.RESEARCH[id].max or save.amber<cost:return false
 var receipts=research_receipts(save,id);receipts.append(cost)
 if not save.has("research_spent"):save.research_spent={}
 save.research_spent[id]=receipts
 save.amber-=cost;save.research[id]=rank_value+1
 return true
static func buy_discovery(save,id):
 if not D.purchase(save,id):return false
 if not save.has("discovery_spent"):save.discovery_spent={}
 save.discovery_spent[id]=D.ENTRIES[id].cost
 return true
static func refund_research(save):
 var total=research_total(save)
 for id in C.RESEARCH:
  save.research.erase(id)
  if save.has("research_spent"):save.research_spent.erase(id)
 save.amber+=total
 return total
static func refund_discoveries(save):
 var total=discovery_total(save)
 for id in D.ENTRIES:
  if D.ENTRIES[id].cost<=0 or id not in save.unlocks or discovery_cost(save,id)<=0:continue
  save.unlocks=save.unlocks.filter(func(key):return key!=id)
  if id not in save.discoveries:save.discoveries.append(id)
  if not save.has("discovery_spent"):save.discovery_spent={}
  # A later milestone may regrant this entry for free; it cannot be refunded twice.
  save.discovery_spent[id]=0
 save.amber+=total
 if not D.hero_open(save,int(save.get("hero",1))):save.hero=1
 return total
