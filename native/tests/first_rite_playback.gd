extends SceneTree
const X=preload("res://scripts/content_extension.gd")
const P=preload("res://scripts/first_rite_player.gd")
var checks=0
func check(ok):
 checks+=1;assert(ok)
func _initialize():call_deferred("run")
func run():
 X.install(preload("res://scripts/catalog.gd"))
 check(P.available())
 for identity in ["thorn","hunt","warden"]:
  var player=P.new();player.identity=identity;player.external_clock=true
  root.add_child(player)
  check(player.pages.size()==4)
  check(player.stage.size==player.size and not player.title.visible)
  check(player.pages[0].size==player.stage.size and player.pages[0].position==Vector2.ZERO)
  check(abs(player.narration.stream.get_length()-120.48)<.1)
  check(player.score.stream.get_length()>120)
  for at in [0,48,72,104,120]:
   player.clock=at;player.update_frame();await process_frame
   await RenderingServer.frame_post_draw
  var completed=[false];player.completed.connect(func():completed[0]=true)
  player.finish();check(completed[0]);await process_frame
 print("FIRST RITE PLAYBACK / ",checks," checks passed; three variants rendered")
 quit()
