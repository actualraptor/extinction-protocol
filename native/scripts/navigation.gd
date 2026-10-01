extends Control
var game
func _process(_dt): queue_redraw()
func objective():
	var g = game.sim
	if g.waypoint!=null: return {"p":g.waypoint,"name":"WAYPOINT"}
	if g.portal!=null: return {"p":g.portal,"name":"NEXT BIOME"}
	var best = null
	for marker in g.landmarks:
		if marker.found: continue
		if best==null or g.pos.distance_squared_to(marker.p)<g.pos.distance_squared_to(best.p): best = marker
	return best
func _draw():
	var g = game.sim
	if g==null or not g.active or game.paused or g.choosing or game.page=="map": return
	var goal = objective()
	if goal==null: return
	var at = game.world.position+game.world.screen(goal.p)
	var viewport = get_viewport_rect().size
	# Only guide to an objective outside the visible arena; never mark routine loot.
	if Rect2(Vector2.ZERO,viewport).has_point(at): return
	var d = at-viewport/2
	var factor = minf((viewport.x/2-60)/maxf(1,absf(d.x)),(viewport.y/2-100)/maxf(1,absf(d.y)))
	var p = viewport/2+d*factor
	var dir = d.normalized()
	draw_circle(p,17,Color("142731"))
	draw_colored_polygon(PackedVector2Array([p+dir*11,p-dir*8+dir.orthogonal()*7,p-dir*4,p-dir*8-dir.orthogonal()*7]),Color("ffe7a6"))
	var caption = goal.name+" / %sm"%int(g.pos.distance_to(goal.p)/10)
	var width = preload("res://scripts/ui_art.gd").body_font().get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
	draw_string(preload("res://scripts/ui_art.gd").body_font(),Vector2(clampf(p.x-width/2,15,viewport.x-15-width),p.y+31),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("e9dfbf"))
