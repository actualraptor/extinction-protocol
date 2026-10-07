extends RefCounted
static func entries(save):
	var result=[{"id":"intro","title":"The opening"}]
	if save.get("campaign",{}).get("route_07",false):
		result.append({"id":"reveal","title":"The awakening"})
	if save.get("settings",{}).get("rite_07_seen",false):
		for pair in [["thorn","The Lost Cradle / The rite"],["hunt","Frostbreak / The rite"],["warden","The Observatory / The rite"]]:
			result.append({"id":pair[0],"title":pair[1]})
	if save.get("settings",{}).get("extinction_cinematic_seen",false):
		result.append({"id":"extinction","title":"The last light"})
	return result
