extends SceneTree
const Attack=preload("res://scripts/hero_attack_animation.gd")
var checks=0
var failures=0
func check(ok,message):
	checks+=1
	if not ok:
		failures+=1
		push_error(message)
func _initialize():
	for hero in [0,2]:
		for seasonal in [false,true]:
			var seen=[]
			for i in range(6):
				var frame=Attack.pose(hero,Attack.PHASES[i],seasonal)
				check(frame.index==i,"Wrong pose at gameplay phase boundary")
				check(frame.texture!=null,"Missing attack texture")
				if frame.texture==null: continue
				var image=frame.texture.get_image()
				check(image.get_pixel(0,0).a<.01 and image.get_pixel(image.get_width()-1,image.get_height()-1).a<.01,"Opaque background or neighboring alpha in frame corners")
				check(Rect2(Vector2.ZERO,image.get_size()).has_point(frame.anchor),"Foot anchor outside frame")
				check(is_equal_approx(frame.scale,68.0/(440.0 if hero==0 else 430.0)),"Body scale changed during casting")
				var signature=hash(image.get_data())
				check(signature not in seen,"Repeated art instead of real sequential pose")
				seen.append(signature)
			check(Attack.pose(hero,-1,seasonal).index==0 and Attack.pose(hero,2,seasonal).index==5,"Out-of-range progress not clamped")
		check(Attack.pose(hero,.62).name==("fire" if hero==0 else "release"),"Weapon release not aligned to cast art")
	check(Attack.pose(1,.5).is_empty(),"Kael must remain with independent slam renderer")
	check(FileAccess.file_exists("res://assets/mara-walk.png") and FileAccess.file_exists("res://assets/vesper-walk-v2.png"),"Original walk art removed")
	print("Hero starter artwork: %s checks / %s failures"%[checks,failures])
	quit(failures)
