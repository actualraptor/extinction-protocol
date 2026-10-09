extends RefCounted
## External study assets are shipped only alongside the private playtest.
static func resolve(path:String)->String:
	if not OS.has_feature("boss_rig_playtest"):
		return ProjectSettings.globalize_path(path)
	var relative=""
	if path.begins_with("res://../art-source/"):
		relative="art-source/"+path.trim_prefix("res://../art-source/")
	elif path.begins_with("res://build/boss-animation-review/"):
		relative="review/"+path.trim_prefix("res://build/boss-animation-review/")
	else:
		return ProjectSettings.globalize_path(path)
	return OS.get_executable_path().get_base_dir().path_join("private-assets").path_join(relative)
