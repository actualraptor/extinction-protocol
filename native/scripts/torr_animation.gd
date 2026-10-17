extends RefCounted
const PHASES=[0.0,.12,.30,.50,.62,.80]
const NAMES=["ready","draw","load","accelerate","release","recover","unarmed","catch"]
const ANCHORS=[Vector2(780,1140),Vector2(790,1140),Vector2(720,1120),Vector2(660,1120),Vector2(660,1120),Vector2(780,1140),Vector2(780,1140),Vector2(780,1140)]
const SCALE=.068
static var textures={}
static var walk=JSON.parse_string(FileAccess.get_file_as_string("res://assets/torr-walk/frames.json"))
static var walks={}
static func walk_frame(phase,rear=false):
 var view="rear" if rear else "front"
 var index=posmod(floori(phase*2),8)
 var key=view+str(index)
 if not walks.has(key):
  var data=walk.views[view][index]
  walks[key]={"texture":load("res://assets/torr-walk/"+data.file),"anchor":Vector2(data.anchor[0],data.anchor[1]),"scale":walk.scale,"hand":Vector2(data.hand[0],data.hand[1])}
 return walks[key]
static func part(target,frame,region,tint):
 var bounds=Rect2(-frame.anchor*frame.scale,frame.texture.get_size()*frame.scale)
 var clipped=bounds.intersection(region)
 if clipped.has_area():target.draw_texture_rect_region(frame.texture,clipped,Rect2((clipped.position-bounds.position)/frame.scale,clipped.size/frame.scale),tint)
static func texture(index):
 if not textures.has(index):textures[index]=load("res://assets/torr-poses/"+NAMES[index]+".png")
 return textures[index]
static func emission_offset(flip=false):
 var offset=(Vector2(1030,350)-ANCHORS[4])*SCALE
 if flip:offset.x=-offset.x
 return offset+Vector2(0,8)
static func draw(target,g,p,tint,phase,moving,direction):
 var index=0
 var facing=direction.x<0
 if not g.starter_attack.is_empty():
  var progress=g.Combat.Starter.progress(g)
  for i in PHASES.size():
   if progress>=PHASES[i]:index=i
  facing=g.starter_attack.aim.x<0
 elif g.god_state.get("catch_until",0)>g.time:index=7
 else:
  for shot in g.shots:
   if shot.get("god_hammer",false) and shot.life>0:index=6;break
 var frame={"texture":texture(index),"anchor":ANCHORS[index],"scale":SCALE}
 target.draw_set_transform(p+Vector2(0,8),0,Vector2(-1 if facing else 1,1))
 if moving:
  var action=(not g.starter_attack.is_empty() and index>0) or index==7
  var gait=walk_frame(phase,direction.y<-.45 and not action)
  if action:
   # Keep the authored planted legs under the throw; weapon and emission remain rigid.
   part(target,gait,Rect2(-24,-28,51,60),tint)
   part(target,frame,Rect2(-200,-200,400,172),tint)
   part(target,frame,Rect2(-200,-28,176,100),tint)
   part(target,frame,Rect2(27,-28,173,100),tint)
  else:
   target.draw_texture_rect(gait.texture,Rect2(-gait.anchor*gait.scale,gait.texture.get_size()*gait.scale),false,tint)
   if index==0:
    var hand=(gait.hand-gait.anchor)*gait.scale
    var hammer=preload("res://assets/torr-story/hammer.png")
    target.draw_texture_rect(hammer,Rect2(hand-Vector2(8,13),Vector2(20,30)),false,tint)
 else:target.draw_texture_rect(frame.texture,Rect2(-frame.anchor*SCALE,frame.texture.get_size()*SCALE),false,tint)
 target.draw_set_transform(Vector2.ZERO)
