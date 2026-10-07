extends SceneTree
const OUT="D:/Utveckling CODEX/Dummy test/native/build/"
func _initialize():call_deferred("run")
func run():
 preload("res://scripts/content_extension.gd").install(preload("res://scripts/catalog.gd"))
 root.size=Vector2i(1920,1080);root.content_scale_size=root.size
 var opening=preload("res://scripts/opening_story.gd").new();opening.external_clock=true;root.add_child(opening)
 for time in [15.0,40.5]:
  opening.clock=time;opening.update_frame();await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(OUT+"intro-dinosaurs-"+str(time)+".png")
 opening.finish();await process_frame
 for id in ["thorn","basalt","hunt","aurora","warden","bloom"]:
  var player=preload("res://scripts/first_rite_player.gd").new();player.identity=id;player.external_clock=true;root.add_child(player)
  await process_frame;await process_frame;player.layout()
  for i in range(4):
   assert(player.pages[i].texture.get_width()>1000)
   player.clock=player.CUES[i]+3;player.update_frame();await process_frame;await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(OUT+"storybook-"+id+"-"+str(i)+".png")
  player.finish();await process_frame
 print("STORYBOOK ART: 24 complete private paintings and two updated intro pages rendered")
 quit()
