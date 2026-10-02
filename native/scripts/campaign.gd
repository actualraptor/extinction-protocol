extends RefCounted
const Discoveries = preload("res://scripts/discoveries.gd")
static func ensure(profile):
	if not profile.has("campaign"): profile.campaign={"kills":0,"bosses":0,"map_kills":{},"map_wins":{}}
static func value(profile,entry):
	ensure(profile)
	match entry.get("goal",""):
		"kills": return profile.campaign.kills
		"bosses": return profile.campaign.bosses
		"map_kills": return profile.campaign.map_kills.get(entry.map,0)
		"wins": return profile.campaign.map_wins.get(entry.map,0)
	return 0
static func evaluate(profile):
	ensure(profile)
	var earned=[]
	for id in Discoveries.ENTRIES:
		var d=Discoveries.ENTRIES[id]
		if not d.has("goal") or id in profile.unlocks: continue
		if value(profile,d)<d.target: continue
		profile.unlocks.append(id)
		if id not in profile.discoveries: profile.discoveries.append(id)
		earned.append(id)
	return earned
static func requirement(profile,id):
	if id=="kael": return "Available from the start"
	var d=Discoveries.ENTRIES[id]
	if d.has("goal"):
		var what={"kills":"total kills","bosses":"bosses defeated","map_kills":"kills in "+d.get("map",""),"wins":"victories in "+d.get("map","")}[d.goal]
		return "%s / %s %s%s"%[mini(value(profile,d),d.target),d.target,what," OR find its signal" if d.get("discoverable",true) else ""]
	return "Find in %s / biome %s"%[d.get("map","any map"),d.depth+1]
