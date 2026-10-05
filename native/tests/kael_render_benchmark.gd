extends SceneTree
class Fixture:
 extends RefCounted
 var sim={}
 var effects=[]
 func screen(p):return p
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(1280,720);DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED);Engine.max_fps=0
 for script in ["res://build/slam_renderer_baseline.gd","res://scripts/kael_ground_fracture.gd"]:
  if not FileAccess.file_exists(script):continue
  var fixture=Fixture.new()
  for i in range(16 if script.contains("baseline") else 64):fixture.effects.append({"kind":("kael_slam_dirt_%s_4_460_2"%[i%4]) if script.contains("baseline") else "kael_crater_dirt_0_4_900_2","p":Vector2(640,360),"size":80*(i%4+1),"life":.3,"max":.46})
  var layer=load(script).new();layer.world=fixture;root.add_child(layer)
  for i in range(30):await process_frame;await RenderingServer.frame_post_draw
  var times=[]
  for i in range(180):
   var start=Time.get_ticks_usec();await process_frame;await RenderingServer.frame_post_draw
   times.append((Time.get_ticks_usec()-start)/1000.0)
  times.sort();print("SLAM RENDER BENCH / ",script," / median ms ",times[90]," / p95 ms ",times[171])
  layer.queue_free();await process_frame
 quit()
