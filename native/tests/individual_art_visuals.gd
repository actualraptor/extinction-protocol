extends SceneTree
class Board extends Node2D:
 var images=[]
 var caption=""
 func _draw():
  draw_rect(Rect2(0,0,1920,1080),Color(.08,.12,.11))
  draw_string(ThemeDB.fallback_font,Vector2(20,30),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,24)
  for i in range(images.size()):
   var cell=Rect2(Vector2(i%4*480+15,(i/4)*255+50),Vector2(450,225))
   var art=images[i]
   var factor=minf(cell.size.x/art.get_width(),cell.size.y/art.get_height())
   var size=art.get_size()*factor
   draw_texture_rect(art,Rect2(cell.get_center()-size/2,size),false)
   draw_string(ThemeDB.fallback_font,cell.position+Vector2(4,12),str(i),HORIZONTAL_ALIGNMENT_LEFT,-1,16)
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(1920,1080)
 root.content_scale_size=Vector2i(1920,1080)
 var board=Board.new();root.add_child(board)
 var selected=""
 var selected_regular=-1
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--review-boss="):selected=arg.trim_prefix("--review-boss=")
  if arg.begins_with("--review-regular="):selected_regular=arg.trim_prefix("--review-regular=").to_int()
 for kind in ["thorn","basalt","hunt","aurora","warden","bloom"]:
  if selected_regular>=0:continue
  if selected!="" and selected!=kind:continue
  board.images.clear();board.caption=kind+" / independent source poses"
  for frame in range(16):
   var path="res://build/individual-dinosaur-sources/boss/%s/%02d.png"%[kind,frame]
   if "--review-available" in OS.get_cmdline_user_args() and not FileAccess.file_exists(path):continue
   var image=Image.load_from_file(path)
   assert(image!=null)
   board.images.append(ImageTexture.create_from_image(image))
  board.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://build/individual-art-review-"+kind+".png")
 if selected!="":quit();return
 for kind in range(19):
  if selected_regular>=0 and selected_regular!=kind:continue
  board.images.clear();board.caption=str(kind)+" / independent source poses"
  for frame in range(6):
   var image=Image.load_from_file("res://build/individual-dinosaur-sources/regular/%d/%02d.png"%[kind,frame])
   assert(image!=null)
   board.images.append(ImageTexture.create_from_image(image))
  board.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://build/individual-art-review-%02d.png"%kind)
 print("Independent poses rendered for visual review")
 quit()
