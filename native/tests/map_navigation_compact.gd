extends SceneTree
const Expedition=preload("res://scripts/expedition.gd")
class Game extends Node:
 var sim
 var menu_root=Control.new()
var checks=0
var failures=0
func check(ok,message):
 checks+=1
 if not ok:failures+=1;printerr("FAIL / ",message)
func _initialize():call_deferred("run")
func run():
 var g=Game.new();root.add_child(g);g.add_child(g.menu_root)
 g.sim=Expedition.new();g.sim.setup(1,"expedition",{},81927,"cradle")
 var map=preload("res://scripts/expedition_map.gd").new();map.game=g;g.menu_root.add_child(map)
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(3440,1440)]:
  root.size=resolution;map.size=Vector2(resolution);map.recenter()
  check(map.zoom==2 and map.origin==g.sim.pos,"Readable local view is default")
  check(map.rect.has_point(map.map_point(g.sim.stage_objects[0].p)),"First supply visible immediately")
  check(map.rect.end.y<=map.size.y-110*map.ui_scale,"Footer independently reserved")
  for zoom in [1,2,4,8]:
   map.zoom=zoom;map.pan_offset=Vector2(2300,-1100);map.layout_map()
   var target=map.world_point(map.center+Vector2(45,30))
   check(map.map_point(target).distance_to(map.center+Vector2(45,30))<.01,"Pin projection reversible after zoom/pan/resize")
   var click=InputEventMouseButton.new();click.pressed=true;click.button_index=MOUSE_BUTTON_LEFT;click.position=map.center+Vector2(45,30)
   map._gui_input(click)
   var projected=map.map_point(g.sim.waypoint)
   check(projected.distance_to(click.position)<24,"Pin corresponds to clicked world point")
  map.toggle_overview()
  check(map.zoom==1,"Full overview available")
  for item in g.sim.stage_objects:check(map.rect.has_point(map.map_point(item.p)),"Overview includes distant reward")
  map.recenter();map.dragging=true
  var motion=InputEventMouseMotion.new();motion.relative=Vector2(70,30);motion.position=map.center;map._gui_input(motion)
  check(map.pan_offset.length()>0,"Middle drag pans local view")
  map.recenter();check(map.pan_offset==Vector2.ZERO,"Recenter restores player navigation")
  var wheel=InputEventMouseButton.new();wheel.pressed=true;wheel.button_index=MOUSE_BUTTON_WHEEL_UP;wheel.position=map.center+Vector2(60,30)
  var before=map.world_point(wheel.position);map._gui_input(wheel)
  check(before.distance_to(map.world_point(wheel.position))<.1,"Wheel preserves world point beneath cursor")
 await process_frame
 if "--screens" in OS.get_cmdline_user_args():
  for resolution in [Vector2i(1280,720),Vector2i(3440,1440)]:
   root.size=resolution;map.size=Vector2(resolution);map.recenter();await create_timer(.1).timeout
   await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://build/map-readable-%s.png"%resolution.x)
  map.toggle_overview();await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://build/map-readable-overview.png")
 g.queue_free();await process_frame;await process_frame
 print("READABLE MAP / %s checks / %s failures"%[checks,failures]);quit(1 if failures else 0)

