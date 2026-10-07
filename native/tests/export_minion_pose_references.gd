extends SceneTree
func _initialize():
	var rig=preload("res://scripts/remnant_rig.gd")
	for identity in rig.IDS:
		for frame in [0,1,2,4,5]:
			rig.raw_pose(identity,frame).get_image().save_png("res://build/minion-remake-review/%s-%s-reference.png"%[identity,frame])
	quit()
