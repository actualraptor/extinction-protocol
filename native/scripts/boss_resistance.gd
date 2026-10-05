extends RefCounted
## Innate resistance is applied once, at the final health-removal boundary.
## Status/proc source damage must stay pre-resistance so subsequent ticks are not taxed twice.
const INNATE = [0.50,0.60,0.70]
const EXPOSED_REDUCTION = 0.25
const SEALED_CORE = 0.88
const OPEN_CORE = 0.40
static func profile(g,e):
 if e==null or not e.get("boss",false):return {"reduction":0.0,"label":""}
 var stage=clampi(int(g.boss_stage),1,3)
 if (stage==2 and e.get("reform",0)>0) or (stage==3 and (g.boss_time<3 or e.get("reform",0)>0)):
  return {"reduction":1.0,"label":"ARRIVING" if stage==3 and g.boss_time<3 else "REFORMING"}
 if stage==3:
  if not g.anchors.is_empty():return {"reduction":SEALED_CORE,"label":"BREAK THE ANCHORS"}
  if g.core_time>0:return {"reduction":OPEN_CORE,"label":"CORE EXPOSED"}
 if e.get("exposed",0)>0:return {"reduction":maxf(0,INNATE[stage-1]-EXPOSED_REDUCTION),"label":"ARMOR EXPOSED"}
 return {"reduction":INNATE[stage-1],"label":"INNATE ARMOR"}
static func multiplier(g,e):
 if not e.get("boss",false):return 1.0
 return 1.0-profile(g,e).reduction
static func caption(g,e):
 var state=profile(g,e)
 return "%s%% DR / %s"%[roundi(state.reduction*100),state.label]
