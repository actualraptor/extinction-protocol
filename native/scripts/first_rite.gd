extends RefCounted
## Shared introduction, selected by first defeated boss rather than starting map.
const SEEN_FLAG="rite_07_seen"
const ROUTES={"cradle":"thorn","frostbreak":"hunt","observatory":"warden"}
static func variant(map_id):return ROUTES.get(map_id,"thorn")
static func eligible(g,defeated,save):
	return g.hero==5 and defeated.get("boss",false) and defeated.get("dead",false) and g.boss_stage<3 and not save.get("settings",{}).get(SEEN_FLAG,false)
static func plan(map_id):
	return {"identity":variant(map_id),"narration_seconds":120.480003,"shared_narration":true,"return_to_corpse":true,"automatic_raise":false}
