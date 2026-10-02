extends SceneTree
class Sim extends RefCounted:
 var stage={"bounds":Rect2(-40000,-34000,80000,68000),"spawn":Vector2.ZERO,"regions":[{"p":Vector2(0,-20000),"radius":6000,"name":"NORTHERN RUINS"}]}
 var stage_objects=[{"p":Vector2(32000,-24000),"name":"Far projectile altar","id":"count","type":"passive","collected":false,"seen":false}]
 var landmarks=[{"p":Vector2(-30000,20000),"name":"Lost survivor","id":"kael","found":false}]
 var pos=Vector2.ZERO
 var depth=0
 var explored=[{},{},{}]
 var waypoint=null
 var portal=null
 var boss=null
class Game extends Node:
 var sim=Sim.new()
 var menu_root=Control.new()
var checks=0
func check(ok,message):
 checks+=1
 assert(ok,message)
func _initialize():call_deferred("run")
func run():
 var g=Game.new();root.add_child(g);g.add_child(g.menu_root)
 var map=preload("res://scripts/expedition_map.gd").new();map.game=g;g.menu_root.add_child(map)
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(3440,1440)]:
  root.size=resolution;map.size=root.get_visible_rect().size;map.layout_map()
  for p in [Vector2(-39000,-33000),Vector2(39000,33000),Vector2.ZERO,g.sim.stage_objects[0].p]:
   check(map.rect.has_point(map.map_point(p)),"Distant map coordinate visible")
   check(map.world_point(map.map_point(p)).distance_to(p)<.1,"Projection reversible")
  var click=InputEventMouseButton.new();click.pressed=true;click.button_index=MOUSE_BUTTON_LEFT;click.position=map.map_point(g.sim.stage_objects[0].p);map._gui_input(click)
  check(g.sim.waypoint==g.sim.stage_objects[0].p,"Click snaps to exact objective")
  click.button_index=MOUSE_BUTTON_RIGHT;map._gui_input(click);check(g.sim.waypoint==null,"Right-click clears pin")
  click.button_index=MOUSE_BUTTON_WHEEL_UP;map._gui_input(click);check(map.zoom==2,"Local zoom works");click.button_index=MOUSE_BUTTON_WHEEL_DOWN;map._gui_input(click);check(map.zoom==1,"Stage overview restored")
  check(map.objectives()[1].name=="UNKNOWN SIGNAL","Undiscovered name hidden")
  g.sim.stage_objects[0].collected=true;check(map.objectives().size()==1,"Collected reward removed");g.sim.stage_objects[0].collected=false
 await process_frame
 if "--screens" in OS.get_cmdline_user_args():
  root.size=Vector2i(1280,800);await create_timer(.1).timeout;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://build/stage-atlas-contract.png")
 print("STAGE ATLAS / ",checks," checks passed")
 g.queue_free();await process_frame;quit()
