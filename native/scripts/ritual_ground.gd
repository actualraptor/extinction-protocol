extends Node2D
var world
var patches={}
class Paint extends Node2D:
	var corpse
	var clock=0.0
	var draw_count=0
	func _draw():
		draw_count+=1
		preload("res://scripts/rite_animation.gd").runoff(self,corpse,Vector2(640,640),clock/preload("res://scripts/rite_animation.gd").DURATION,true)
		preload("res://scripts/rite_animation.gd").shedding(self,corpse,Vector2(640,640),clock/preload("res://scripts/rite_animation.gd").DURATION,true)
func _process(_dt):
	if world.sim==null:
		clear_patches()
		return
	var alive={}
	for corpse in world.sim.boss_corpses:
		var clock=maxf(corpse.get("stain_time",0.0),corpse.ritual)
		if clock<=0:continue
		var key=corpse.uid
		alive[key]=true
		if patches.has(key) and not is_same(patches[key].paint.corpse,corpse):
			patches[key].viewport.queue_free();patches[key].stamp.queue_free();patches.erase(key)
		if not patches.has(key):
			var viewport=SubViewport.new()
			viewport.size=Vector2i(1280,1280)
			viewport.transparent_bg=true
			viewport.disable_3d=true
			viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
			add_child(viewport)
			var paint=Paint.new();paint.corpse=corpse;viewport.add_child(paint)
			var stamp=Sprite2D.new();stamp.texture=viewport.get_texture();add_child(stamp)
			patches[key]={"viewport":viewport,"paint":paint,"stamp":stamp,"clock":-1.0,"prepared":0}
		var patch=patches[key]
		# Prepare one small species-matched texture per frame before conversion,
		# avoiding a burst of pixel masking when the scraps first appear.
		if patch.prepared<27:
			preload("res://scripts/rite_animation.gd").hide_scrap(corpse.identity,int(patch.prepared/3),patch.prepared%3)
			patch.prepared+=1
		patch.stamp.position=world.screen(corpse.p)
		patch.stamp.visible=world.visible_rect().grow(640).has_point(patch.stamp.position)
		# Once time stops advancing, retain the GPU texture. Camera motion moves
		# one sprite without rebuilding splashes or reading pixels back to CPU.
		if clock!=patch.clock:
			patch.clock=clock;patch.paint.clock=clock;patch.paint.queue_redraw()
			patch.viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
		else:
			patch.viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	for key in patches.keys():
		if not alive.has(key):
			patches[key].viewport.queue_free();patches[key].stamp.queue_free();patches.erase(key)
func clear_patches():
	for patch in patches.values():
		patch.viewport.queue_free();patch.stamp.queue_free()
	patches.clear()
