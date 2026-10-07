extends SceneTree
const Gallery=preload("res://scripts/cinematic_gallery.gd")
func _initialize():
	assert(Gallery.entries({}).map(func(e):return e.id)==["intro"])
	var profile={"campaign":{"route_07":true},"settings":{}}
	assert(Gallery.entries(profile).map(func(e):return e.id)==["intro","reveal"])
	profile.settings.rite_07_seen=true
	assert(Gallery.entries(profile).map(func(e):return e.id)==["intro","reveal","thorn","hunt","warden"])
	profile.settings.extinction_cinematic_seen=true
	assert(Gallery.entries(profile).size()==6)
	assert(not Gallery.entries(profile).any(func(e):return e.id in ["basalt","aurora","bloom"]))
	print("GALLERY: new-player visibility, legacy reveal unlock, tutorial variants and extinction unlock passed")
	quit()
