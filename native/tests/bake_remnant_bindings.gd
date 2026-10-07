extends SceneTree
class Paint extends Node2D:
	var art
	var identity
	var frame
	var dimensions
	func _draw():
		draw_texture_rect(art,Rect2(Vector2.ZERO,dimensions),false)
		preload("res://scripts/remnant_bindings.gd").draw(self,identity,dimensions,frame,art.get_image())
func _initialize():call_deferred("run")
func run():
	var rig=preload("res://scripts/remnant_rig.gd")
	DirAccess.make_dir_recursive_absolute("res://assets/minions-bound")
	for identity in rig.IDS:
		for frame in [0,1,2,4,5]:
			var art=rig.raw_pose(identity,frame)
			var viewport=SubViewport.new()
			viewport.disable_3d=true;viewport.transparent_bg=true
			viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
			# Preserve original pose bounds so existing rig geometry stays exact.
			viewport.size=Vector2i(art.get_size());root.add_child(viewport)
			var paint=Paint.new();paint.art=art;paint.identity=identity;paint.frame=frame;paint.dimensions=art.get_size();viewport.add_child(paint)
			await process_frame;await RenderingServer.frame_post_draw
			var image=viewport.get_texture().get_image()
			assert(image.get_used_rect().size.x>art.get_width()*.6,"Baked pose must contain its full dinosaur")
			assert(image.save_png("res://assets/minions-bound/%s-%s.png"%[identity,frame])==OK)
			viewport.queue_free();await process_frame
	print("BINDINGS: 30 standalone bound minion poses baked for six species")
	quit()
