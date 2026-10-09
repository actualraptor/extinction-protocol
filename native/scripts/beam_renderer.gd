extends Node2D
var world
var visuals={}
func _process(_dt):
	var active={}
	if world.sim!=null:
		for beam in world.sim.beams:
			active[beam.visual_id]=true
			if not visuals.has(beam.visual_id):
				var node=preload("res://scripts/beam_vfx.gd").new();node.beam=beam;node.world=world;add_child(node);visuals[beam.visual_id]=node
			visuals[beam.visual_id].refresh()
	for id in visuals.keys():
		if not active.has(id):visuals[id].queue_free();visuals.erase(id)
	queue_redraw()
func screen(p):return world.screen(p)
func _draw():
	if world.sim==null:return
	preload("res://scripts/beam_system.gd").draw(self,world.sim)
