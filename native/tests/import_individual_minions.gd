extends SceneTree
const R=preload("res://scripts/remnant_rig.gd")
func _initialize():
	DirAccess.make_dir_recursive_absolute("res://assets/minions-individual-runtime")
	var count=0
	for id in R.IDS:
		for frame in [0,1,2,4,5]:
			var path="res://assets/minions-individual-v2/%s-%s.png"%[id,frame]
			if not FileAccess.file_exists(path):continue
			var source=Image.load_from_file(path)
			assert(source!=null and not source.is_empty())
			var used=source.get_used_rect()
			assert(used.size.x>100 and used.size.y>100)
			assert(source.get_pixel(0,0).a<.05 and source.get_pixel(source.get_width()-1,source.get_height()-1).a<.05,"Sprite must have genuine transparency")
			var target=R.raw_pose(id,frame).get_size()
			var fitted=source.get_region(used)
			var scale=minf((target.x-4)/used.size.x,(target.y-4)/used.size.y)
			fitted.resize(maxi(1,roundi(used.size.x*scale)),maxi(1,roundi(used.size.y*scale)),Image.INTERPOLATE_LANCZOS)
			var padded=Image.create(int(target.x),int(target.y),false,Image.FORMAT_RGBA8)
			padded.blit_rect(fitted,Rect2i(Vector2i.ZERO,fitted.get_size()),Vector2i((int(target.x)-fitted.get_width())/2,int(target.y)-fitted.get_height()-2))
			assert(padded.save_png("res://assets/minions-individual-runtime/%s-%s.png"%[id,frame])==OK)
			count+=1
	print("INDIVIDUAL MINIONS: ",count," standalone poses imported with preserved proportions, transparent borders and bounded texture sizes")
	quit()
