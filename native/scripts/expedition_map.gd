extends Control
const Icons = preload("res://scripts/atlas_icons.gd")
var game
var center = Vector2(720,440)
var scale_value = 0.16
var rect = Rect2(105,155,1230,565)
var font = preload("res://scripts/ui_art.gd").body_font()

func _process(_dt): queue_redraw()

func map_point(p): return center+(p-game.sim.pos)*scale_value
func known(p): return game.sim.explored[game.sim.depth].has(Vector2i(floor(p.x/160),floor(p.y/160)))
func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and rect.has_point(event.position):
		game.sim.waypoint = game.sim.pos+(event.position-center)/scale_value
		queue_redraw()
		accept_event()

func marker(p,id,title,color = Color(1,1,1,0.7)):
	var at = map_point(p)
	if not rect.grow(-35).has_point(at): return
	draw_texture_rect(Icons.get_icon(id,"relic"),Rect2(at-Vector2(12,12),Vector2(24,24)),false,color)
	draw_string(font,at+Vector2(-52,25),title,HORIZONTAL_ALIGNMENT_LEFT,160,12,color)

func _draw():
	var g = game.sim
	# Unframed cartographic lines: the world remains completely visible underneath.
	rect = Rect2(-game.menu_root.position,get_viewport_rect().size).grow(-28)
	var visited = {}
	for cell in g.explored[g.depth]:
		for x in range(-1,4):
			for y in range(-1,4):
				var tile = g.terrain.cell(Vector2(cell)*160)+Vector2i(x,y)
				if visited.has(tile): continue
				visited[tile] = true
				var pos = Vector2(tile)*64
				if not known(pos): continue
				var at = map_point(pos)
				if not rect.grow(-16).has_point(at): continue
				var kind = g.terrain.kind(tile)
				if kind!=1: continue
				var edge = 64*scale_value
				for side in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
					if g.terrain.kind(tile+side)==1: continue
					var start = at+Vector2(edge if side.x>0 else 0,edge if side.y>0 else 0)
					var end = start+Vector2(0,edge) if side.x!=0 else start+Vector2(edge,0)
					draw_line(start,end,Color(0.74,0.79,0.72,0.58),1.4,true)
	for landmark in g.landmarks:
		if landmark.found: continue
		var seen = known(landmark.p)
		marker(landmark.p,"camp",landmark.name if seen else "UNKNOWN SIGNAL",Color("98d9b2") if landmark.found else Color("e9c97f") if seen else Color("d8bf83"))
	if g.mode!="safari" and g.boss_stage<3:
		if g.cache_timer<=0 and known(g.cache_pos): marker(g.cache_pos,"chest","RELIC CACHE")
		if not g.shrine_done and known(g.shrine_pos): marker(g.shrine_pos,"portal","RIFT SHRINE")
	for chest in g.relic_chests:
		if known(chest): marker(chest,"chest","LOOT")
	if g.portal!=null: marker(g.portal,"portal","NEXT BIOME",Color("bcabff"))
	if g.boss!=null: marker(g.boss.p,"meteor","BOSS",Color("ff9276"))
	if g.waypoint!=null:
		var at = map_point(g.waypoint)
		if rect.has_point(at): draw_arc(at,10,0,TAU,24,Color("ffe7ad"),3,true)
	draw_circle(center,4,Color("d9f4ff"))
	draw_arc(center,8,0,TAU,24,Color("9ee6ff"),2,true)
	
