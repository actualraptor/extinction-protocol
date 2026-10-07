extends Node2D
var world
func _process(_dt):queue_redraw()
func _draw():
	if world.sim!=null and world.sim.companions!=null:
		world.sim.companions.draw(self,world.sim,world.screen)
