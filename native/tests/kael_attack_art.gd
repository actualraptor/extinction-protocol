extends SceneTree
const Attack=preload("res://scripts/kael_attack_animation.gd")
var checks=0
var failures=0
func check(ok,message):
	checks+=1
	if not ok:
		failures+=1
		push_error(message)
func _initialize():
	var d=Attack.data()
	for seasonal in [false,true]:
		var seen=[]
		for i in range(6):
			var frame=Attack.pose(Attack.PHASES[i],seasonal)
			check(frame.index==i,"Pose boundary selected wrong attack frame")
			check(frame.texture!=null,"Missing attack pose texture")
			if frame.texture==null:continue
			var image=frame.texture.get_image()
			check(image.get_pixel(0,0).a<0.01 and image.get_pixel(image.get_width()-1,image.get_height()-1).a<0.01,"Attack frame has opaque canvas background")
			check(Rect2(Vector2.ZERO,image.get_size()).has_point(frame.anchor),"Ground anchor outside authored frame")
			check(is_equal_approx(frame.scale,68.0/380.0),"Frame changes character size instead of pose")
			var signature=hash(image.get_data())
			check(signature not in seen,"Duplicate attack art instead of distinct pose")
			seen.append(signature)
	check(Attack.pose(.62).name=="impact","Gameplay impact must align with contact pose")
	check(Attack.pose(.30).name=="overhead","Windup must show raised overhead club")
	check(Attack.pose(.50).name=="downstroke","Release must show downstroke")
	check(Attack.pose(-1).name=="anticipation" and Attack.pose(2).name=="recovery","Pose lookup must clamp out-of-range progress")
	check(Attack.impact_point(Vector2.ZERO,false).x==-Attack.impact_point(Vector2.ZERO,true).x,"Left/right strike offsets must mirror")
	check(FileAccess.file_exists("res://assets/kael-walk.png"),"Original movement artwork must remain")
	print("Kael slam artwork: %s checks / %s failures"%[checks,failures])
	quit(failures)
