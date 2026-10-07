extends Node2D
## Animated species layer over shared cinematic environments and narration.
var player
func _process(_dt):queue_redraw()
func _draw():
 if player==null or player.stage.size.x<=0:return
 var index=player.shot_at(player.clock)
 var image_height=minf(player.stage.size.y,player.stage.size.x/3.0)
 var at=Vector2(player.stage.size.x*.66,(player.stage.size.y-image_height)/2+image_height*.78)
 var width=player.stage.size.x*(.42 if player.identity=="basalt" else .38)
 var rig=preload("res://scripts/remnant_rig.gd")
 var boss=preload("res://scripts/dinosaur_boss_art.gd")
 if index<2:
  var art=boss.corpse(player.identity)
  var scale_factor=minf(width/maxf(1,art.get_width()),image_height*.5/maxf(1,art.get_height()))
  var size=art.get_size()*scale_factor
  var bounds=Rect2(at-Vector2(size.x/2,size.y*.88),size)
  preload("res://scripts/dinosaur_blood.gd").pools(self,bounds)
  draw_texture_rect(art,bounds,false)
 else:
  var elapsed=player.clock-player.CUES[index]
  var pose=6 if index==2 and elapsed<5 else 7 if index==2 and elapsed<10 else 3 if index==3 and elapsed<4 else 0
  var art=rig.atlas_pose(player.identity,pose)
  if art==null:return
  var scale_factor=minf(width/maxf(1,art.get_width()),image_height*.7/maxf(1,art.get_height()))
  var size=art.get_size()*scale_factor
  var rising=smoothstep(0,7,elapsed) if index==2 else 1.0
  var jitter=sin(player.clock*18)*2*(1-rising)
  var sink=(1-rising)*size.y*.15
  draw_texture_rect(art,Rect2(at+Vector2(-size.x/2,-size.y+sink+jitter),size),false)
  draw_set_transform(at,0,Vector2(1,.35))
  draw_arc(Vector2.ZERO,size.x*.4,0,TAU,72,Color(.4,1,.65,.24+.15*sin(player.clock*2)),3,true)
  draw_set_transform(Vector2.ZERO)
