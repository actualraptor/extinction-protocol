extends Control
const Icons=preload("res://scripts/atlas_icons.gd")
const Art=preload("res://scripts/ui_art.gd")
var game
var center=Vector2.ZERO
var scale_value=0.01
var rect=Rect2()
var origin=Vector2.ZERO
var zoom=2.0
var pan_offset=Vector2.ZERO
var dragging=false
var hovered={}
var font=Art.body_font()
var ui_scale=1.0
var overview_rect=Rect2()
var recenter_rect=Rect2()
func _process(_dt):
 position=-game.menu_root.position
 size=get_viewport_rect().size
 layout_map();queue_redraw()
func layout_map():
 ui_scale=clampf(size.y/900.0,0.9,1.6)
 rect=Rect2(36*ui_scale,106*ui_scale,maxf(300,size.x-72*ui_scale),maxf(180,size.y-226*ui_scale))
 center=rect.get_center()
 var bounds=game.sim.stage.bounds
 scale_value=minf((rect.size.x-50)/bounds.size.x,(rect.size.y-50)/bounds.size.y) if zoom==1 else (rect.size.y-50)/14000.0*(zoom/2.0)
 origin=bounds.get_center() if zoom==1.0 else game.sim.pos+pan_offset
 overview_rect=Rect2(Vector2(size.x-348*ui_scale,52*ui_scale),Vector2(156,34)*ui_scale)
 recenter_rect=Rect2(Vector2(size.x-180*ui_scale,52*ui_scale),Vector2(144,34)*ui_scale)
func map_point(p):return center+(p-origin)*scale_value
func world_point(p):return origin+(p-center)/scale_value
func known(p):return game.sim.explored[game.sim.depth].has(Vector2i(floor(p.x/160),floor(p.y/160)))
func objectives():
 return preload("res://scripts/map_markers.gd").collect(game.sim)
func nearest_marker(at):
 var best={};var distance=24.0*ui_scale
 for item in objectives():
  var p=map_point(item.p)
  if not rect.grow(-14).has_point(p):continue
  var d=at.distance_to(p)
  if d<distance:best=item;distance=d
 return best
func recenter():
 pan_offset=Vector2.ZERO;zoom=2;layout_map();queue_redraw()
func toggle_overview():
 zoom=2 if zoom==1 else 1
 pan_offset=Vector2.ZERO;layout_map();queue_redraw()
func _unhandled_key_input(event):
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_O:toggle_overview();accept_event()
  elif event.keycode==KEY_F:recenter();accept_event()
func _gui_input(event):
 if event is InputEventMouseMotion:
  if dragging and zoom>1:pan_offset-=event.relative/scale_value;layout_map()
  hovered=nearest_marker(event.position);queue_redraw()
 if not event is InputEventMouseButton:return
 if event.button_index==MOUSE_BUTTON_MIDDLE:dragging=event.pressed;accept_event();return
 if not event.pressed:return
 if event.button_index==MOUSE_BUTTON_RIGHT:game.sim.waypoint=null;accept_event()
 elif event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
  var before=world_point(event.position)
  zoom=clampf(zoom*(2 if event.button_index==MOUSE_BUTTON_WHEEL_UP else .5),1,8)
  layout_map()
  if zoom>1:pan_offset+=before-world_point(event.position);layout_map()
  accept_event()
 elif event.button_index==MOUSE_BUTTON_LEFT:
  if overview_rect.has_point(event.position):toggle_overview()
  elif recenter_rect.has_point(event.position):recenter()
  elif rect.has_point(event.position):
   var target=nearest_marker(event.position)
   game.sim.waypoint=target.p if not target.is_empty() else world_point(event.position).clamp(game.sim.stage.bounds.position,game.sim.stage.bounds.end)
  accept_event()
 queue_redraw()
func text_center(value,p,font_size,color):
 font_size=roundi(font_size*ui_scale)
 var width=font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
 draw_string(font,p-Vector2(width/2,0),value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
func clipped_line(a,b,color,width=1.0):
 var delta=b-a;var low=0.0;var high=1.0
 var coefficients=[-delta.x,delta.x,-delta.y,delta.y]
 var distances=[a.x-rect.position.x,rect.end.x-a.x,a.y-rect.position.y,rect.end.y-a.y]
 for i in range(4):
  if absf(coefficients[i])<0.00001:
   if distances[i]<0:return
  else:
   var ratio=distances[i]/coefficients[i]
   if coefficients[i]<0:low=maxf(low,ratio)
   else:high=minf(high,ratio)
   if low>high:return
 draw_line(a+delta*low,a+delta*high,color,width,true)
func terrain_context(g):
 var terrain=g.get("terrain")
 if terrain==null:return
 var world_rect=Rect2(world_point(rect.position),rect.size/scale_value)
 var step=1024.0 if zoom==1 else 320.0 if zoom==2 else 160.0
 for x in range(floori(world_rect.position.x/step),ceili(world_rect.end.x/step)):
  for y in range(floori(world_rect.position.y/step),ceili(world_rect.end.y/step)):
   var p=Vector2(x,y)*step+Vector2.ONE*step*0.5
   if not g.stage.bounds.has_point(p):continue
   var kind=terrain.kind(terrain.cell(p))
   if kind==0:continue
   var tile=Rect2(map_point(p-Vector2.ONE*step*.5),Vector2.ONE*step*scale_value).intersection(rect)
   var shade=Color(.62,.69,.62,.25) if kind==1 else Color(.22,.55,.59,.13) if kind==2 else Color(.96,.34,.12,.20)
   draw_rect(tile,shade)
 for target in g.stage.get("routes",[]):clipped_line(map_point(g.stage.spawn),map_point(target),Color(.70,.65,.40,.12),3)
func short_name(value,max_width=180):
 var result=value
 while result.length()>3 and font.get_string_size(result,HORIZONTAL_ALIGNMENT_LEFT,-1,roundi(13*ui_scale)).x>max_width:result=result.left(result.length()-1)
 return result+"â€¦" if result!=value else result
func _draw():
 if game.sim==null:return
 if rect.size==Vector2.ZERO:
  size=get_viewport_rect().size;layout_map()
 var g=game.sim
 draw_rect(rect,Color(.02,.04,.035,.24));draw_rect(rect,Color(.7,.6,.4,.38),false,1)
 draw_string(Art.heading_font(),Vector2(38,77)*ui_scale,"EXPEDITION ATLAS",HORIZONTAL_ALIGNMENT_LEFT,-1,roundi(23*ui_scale),Color("e5cc94"))
 for button_data in [[overview_rect,"LOCAL / O" if zoom==1 else "OVERVIEW / O"],[recenter_rect,"RECENTER / F"]]:
  draw_rect(button_data[0],Color(.06,.085,.09,.75));draw_rect(button_data[0],Color(.65,.56,.37,.6),false,1)
  text_center(button_data[1],button_data[0].get_center()+Vector2(0,5)*ui_scale,13,Color("dfcc9d"))
 terrain_context(g)
 var label_boxes=[]
 for region in g.stage.get("regions",[]):
  var at=map_point(region.p)
  if not rect.grow(-minf(180,rect.size.y*.25)).has_point(at):continue
  var radius=clampf(region.radius*scale_value,12,170)
  draw_arc(at,radius,0,TAU,48,Color(.6,.7,.62,.12),1,true)
 var items=objectives()
 items.sort_custom(func(a,b):
  var a_priority=not hovered.is_empty() and a.p==hovered.p or g.waypoint!=null and a.p==g.waypoint
  var b_priority=not hovered.is_empty() and b.p==hovered.p or g.waypoint!=null and b.p==g.waypoint
  if a_priority!=b_priority:return a_priority
  return a.p.distance_squared_to(g.pos)<b.p.distance_squared_to(g.pos))
 for item in items:
  var at=map_point(item.p)
  if not rect.grow(-24*ui_scale).has_point(at):continue
  draw_texture_rect(Icons.get_icon(item.id,item.category,g.get("halloween")==true),Rect2(at-Vector2(12,12)*ui_scale,Vector2(24,24)*ui_scale),false)
  var caption=short_name(item.name)
  var width=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,roundi(13*ui_scale)).x
  var bounds=Rect2(at+Vector2(-width/2,16*ui_scale),Vector2(width,18*ui_scale))
  if not rect.encloses(bounds) or label_boxes.any(func(r):return r.grow(6).intersects(bounds)):continue
  label_boxes.append(bounds);text_center(caption,at+Vector2(0,30)*ui_scale,13,Color("e0ce9c"))
 var spawn=map_point(g.stage.spawn)
 if rect.grow(-14).has_point(spawn):draw_arc(spawn,7,0,TAU,16,Color("809886"),1,true)
 var player=map_point(g.pos)
 if g.waypoint!=null:
  var at=map_point(g.waypoint);clipped_line(player,at,Color(.95,.8,.5,.55),2)
  if rect.grow(-18).has_point(at):draw_arc(at,17,0,TAU,32,Color("ffe8a4"),2,true)
 if rect.grow(-12).has_point(player):draw_circle(player,4,Color("d9f4ff"));draw_arc(player,9,0,TAU,24,Color("9ee6ff"),2,true)
 var detail="LOCAL NAVIGATION" if zoom>1 else "FULL STAGE / DISTANT SIGNALS"
 if not hovered.is_empty():detail=hovered.name+" / %s m"%int(g.pos.distance_to(hovered.p)/10)
 text_center(detail,Vector2(size.x/2,size.y-86*ui_scale),16,Color("ffe4a7"))
 text_center("CLICK PIN Â· RIGHT CLICK CLEAR Â· MIDDLE DRAG PAN Â· WHEEL ZOOM Â· TAB CLOSE",Vector2(size.x/2,size.y-57*ui_scale),13,Color("c4c3ab"))
 text_center("1 m = 10 world units Â· pale blocks: obstacles Â· teal: mud Â· orange: lava",Vector2(size.x/2,size.y-33*ui_scale),12,Color("899888"))
