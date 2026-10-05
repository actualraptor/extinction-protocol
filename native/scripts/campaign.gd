extends RefCounted
const Discoveries = preload("res://scripts/discoveries.gd")
static func ensure(profile):
	if not profile.has("campaign"): profile.campaign={"kills":0,"bosses":0,"map_kills":{},"map_wins":{}}
	for key in ["kills","bosses"]:
		if not profile.campaign.has(key):profile.campaign[key]=0
	for key in ["map_kills","map_wins","weapon_damage","survivor_runs"]:
		if not profile.campaign.has(key):profile.campaign[key]={}
static func value(profile,entry):
	ensure(profile)
	match entry.get("goal",""):
		"kills": return profile.campaign.kills
		"bosses": return profile.campaign.bosses
		"map_kills": return profile.campaign.map_kills.get(entry.map,0)
		"wins": return profile.campaign.map_wins.get(entry.map,0)
		"weapon_damage": return profile.campaign.weapon_damage.get(entry.weapon,0)
	return 0
static func record_build(profile,report):
	# Called once when a run ends. Amounts are effective damage, excluding overkill.
	ensure(profile)
	for weapon in report.get("damage_by_weapon",{}):
		profile.campaign.weapon_damage[weapon]=profile.campaign.weapon_damage.get(weapon,0)+maxf(0,float(report.damage_by_weapon[weapon]))
	var hero=str(report.get("hero",""))
	profile.campaign.survivor_runs[hero]=profile.campaign.survivor_runs.get(hero,0)+1
static func completed(profile,entry):
	if entry.has("goal") and value(profile,entry)>=entry.target:return true
	var alternate=entry.get("alternate",{})
	return not alternate.is_empty() and value(profile,alternate)>=alternate.target
static func evaluate(profile):
	ensure(profile)
	var earned=[]
	for id in Discoveries.ENTRIES:
		var d=Discoveries.ENTRIES[id]
		if not d.has("goal") or id in profile.unlocks: continue
		if not completed(profile,d): continue
		profile.unlocks.append(id)
		if id not in profile.discoveries: profile.discoveries.append(id)
		earned.append(id)
	return earned
static func requirement(profile,id):
	if id=="kael": return "Available from the start"
	var d=Discoveries.ENTRIES[id]
	if d.has("goal"):
		var what={"kills":"total kills","bosses":"bosses defeated","map_kills":"kills in "+d.get("map",""),"wins":"victories in "+d.get("map","")}[d.goal]
		var text="%s / %s %s"%[mini(value(profile,d),d.target),d.target,what]
		if d.has("alternate"):
			var a=d.alternate
			text+=" OR deal %s / %s damage with %s"%[mini(value(profile,a),a.target),a.target,a.get("weapon_name",a.weapon)]
		return text+(" OR find its signal" if d.get("discoverable",true) else "")
	return "Find in %s / biome %s"%[d.get("map","any map"),d.depth+1]
static func suggested_goals(profile,map_id="cradle",limit=3):
	ensure(profile)
	var goals=[]
	for id in Discoveries.ENTRIES:
		var d=Discoveries.ENTRIES[id]
		if id in profile.get("unlocks",[]) or d.get("discoverable",true)==false and not d.has("goal"):continue
		if d.get("map",map_id)!=map_id:continue
		goals.append({"id":id,"name":d.name,"requirement":requirement(profile,id),"progress":clampf(float(value(profile,d))/maxf(1,float(d.get("target",1))),0,1) if d.has("goal") else 0.0})
	var tracked=profile.campaign.get("tracked_goal","")
	goals.sort_custom(func(a,b):
		if a.id==tracked or b.id==tracked:return a.id==tracked
		return a.progress>b.progress if a.progress!=b.progress else a.id<b.id)
	return goals.slice(0,maxi(0,limit))
static func track_goal(profile,id):
	ensure(profile)
	if not Discoveries.ENTRIES.has(id) or id in profile.get("unlocks",[]):return false
	profile.campaign.tracked_goal=id
	return true
static func tracked_goal(profile):
	ensure(profile)
	var id=profile.campaign.get("tracked_goal","")
	if not Discoveries.ENTRIES.has(id) or id in profile.get("unlocks",[]):return {}
	return {"id":id,"name":Discoveries.ENTRIES[id].name,"requirement":requirement(profile,id)}
