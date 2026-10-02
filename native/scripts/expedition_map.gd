extends Control
const Icons=preload("res://scripts/atlas_icons.gd")
const Art=preload("res://scripts/ui_art.gd")
var game
var center=Vector2.ZERO
var scale_value=0.01
var rect=Rect2()
var origin=Vector2.ZERO
var zoom=1.0
var hovered={}
var font=Art.body_font()
func _process(_dt):
 position=-game.menu_root.position
 size=get_viewport_rect().size
 layout_map()
 queue_redraw()
func layout_map():
 rect=Rect2(70,165,maxf(300,size.x-140),maxf(250,size.y-320))
 center=rect.get_center()
 var bounds=game.sim.stage.bounds
 scale_value=minf((rect.size.x-90)/bounds.size.x,(rect.size.y-70)/bounds.size.y)*zoom
 origin=bounds.get_center() if zoom==1.0 else game.sim.pos
func map_point(p):return center+(p-origin)*scale_value
func world_point(p):return origin+(p-center)/scale_value
func known(p):return game.sim.explored[game.sim.depth].has(Vector2i(floor(p.x/160),floor(p.y/160)))
func objectives():
 var result=[]
 for item in game.sim.stage_objects:
  if item.collected:continue
  result.append({"p":item.p,"name":item.name,"id":"chest" if item.type=="cache" else item.id,"category":"relic" if item.type=="cache" else item.type})
 for signal_data in game.sim.landmarks:
  if signal_data.found:continue
  result.append({"p":signal_data.p,"name":signal_data.name if known(signal_data.p) else "UNKNOWN SIGNAL","id":"camp","category":"relic"})
 if game.sim.portal!=null:result.append({"p":game.sim.portal,"name":"NEXT BIOME","id":"portal","category":"relic"})
 if game.sim.boss!=null:result.append({"p":game.sim.boss.p,"name":"BOSS","id":"meteor","category":"relic"})
 return result
func nearest_marker(at):
 var best={};var distance=28.0
 for item in objectives():
  var p=map_point(item.p)
  if not rect.has_point(p):continue
  var d=at.distance_to(p)
  if d<distance:best=item;distance=d
 return best
func _gui_input(event):
 if event is InputEventMouseMotion:hovered=nearest_marker(event.position)
 if not event is InputEventMouseButton or not event.pressed:return
 if event.button_index==MOUSE_BUTTON_RIGHT:
  game.sim.waypoint=null;accept_event()
 elif event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
  zoom=clampf(zoom*(2 if event.button_index==MOUSE_BUTTON_WHEEL_UP else .5),1,8);layout_map();accept_event()
 elif event.button_index==MOUSE_BUTTON_LEFT and rect.has_point(event.position):
  var target=nearest_marker(event.position)
  game.sim.waypoint=target.p if not target.is_empty() else world_point(event.position).clamp(game.sim.stage.bounds.position,game.sim.stage.bounds.end)
  accept_event()
 queue_redraw()
func text_center(value,p,font_size,color):
 var width=font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
 draw_string(font,p-Vector2(width/2,0),value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
func _draw():
 if game.sim==null:return
 var g=game.sim
 var inset50=Vector2(minf(50.0,rect.size.x*0.45),minf(50.0,rect.size.y*0.45))
 var inset24=Vector2(minf(24.0,rect.size.x*0.45),minf(24.0,rect.size.y*0.45))
 var inset12=Vector2(minf(12.0,rect.size.x*0.45),minf(12.0,rect.size.y*0.45))
 var region_rect=Rect2(rect.position+inset50,rect.size-inset50*2.0)
 var marker_rect=Rect2(rect.position+inset24,rect.size-inset24*2.0)
 var waypoint_rect=Rect2(rect.position+inset12,rect.size-inset12*2.0)
 # Readable cartography without a solid window or a scan of all visited cells.
 draw_rect(rect,Color(.02,.04,.035,.35))
 draw_rect(rect,Color(.7,.6,.4,.32),false,1)
 text_center("EXPEDITION ATLAS",Vector2(size.x/2,133),23,Color("e5cc94"))
 for region in g.stage.get("regions",[]):
  var at=map_point(region.p)
  if not region_rect.has_point(at):continue
  var radius=clampf(region.radius*scale_value,12,100)
  draw_arc(at,radius,0,TAU,48,Color(.6,.7,.62,.17),1,true)
  text_center(region.name.to_upper(),at+Vector2(0,-radius-8),12,Color(.65,.72,.64,.55))
 var spawn=map_point(g.stage.spawn)
 if rect.has_point(spawn):
  draw_arc(spawn,7,0,TAU,16,Color("809886"),1,true)
  text_center("START",spawn+Vector2(0,21),10,Color("809886"))
 for item in objectives():
  var at=map_point(item.p)
  if not marker_rect.has_point(at):continue
  draw_texture_rect(Icons.get_icon(item.id,item.category),Rect2(at-Vector2(12,12),Vector2(24,24)),false)
  text_center(item.name,at+Vector2(0,27),12,Color("e0ce9c"))
 if g.waypoint!=null:
  var at=map_point(g.waypoint)
  if waypoint_rect.has_point(at):
   draw_arc(at,17,0,TAU,32,Color("ffe8a4"),2,true)
   var player=map_point(g.pos)
   if rect.has_point(player):draw_line(player,at,Color(.95,.8,.5,.45),1,true)
 var player=map_point(g.pos)
 if rect.has_point(player):
  draw_circle(player,4,Color("d9f4ff"));draw_arc(player,8,0,TAU,24,Color("9ee6ff"),2,true)
 if not hovered.is_empty():text_center(hovered.name+" / %sm"%int(g.pos.distance_to(hovered.p)/10),Vector2(size.x/2,rect.end.y+30),16,Color("ffe4a7"))
 text_center("CLICK TO PIN · RIGHT CLICK TO CLEAR · WHEEL TO ZOOM · TAB TO CLOSE",Vector2(size.x/2,size.y-94),13,Color("c4c3ab"))
 text_center("STAGE OVERVIEW" if zoom==1 else "LOCAL VIEW ×%s"%int(zoom),Vector2(size.x/2,size.y-70),11,Color("899888"))
