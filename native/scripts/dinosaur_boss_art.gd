extends RefCounted
const SHEET=preload("res://assets/dinosaurs/boss-atlas.png")
static var corpses={}
const IDS=["thorn","basalt","hunt","aurora","warden","bloom"]
const WIDTH={"thorn":340.0,"basalt":430.0,"hunt":300.0,"aurora":385.0,"warden":340.0,"bloom":460.0}
static func frame(b,clock):
 var action=b.get("action","recover")
 var t=clampf(1-b.get("action_left",0)/maxf(.01,b.get("action_length",1)),0,1)
 if b.get("dead",false):return 7
 if b.get("reform",0)>0:return 3
 if action=="intro":return 3 if t>.65 else 1+int(clock*6)%2
 if action=="windup":return 4
 if action in ["charge","pounce"]:return 5
 if action=="strike":return 3 if b.move in ["PACK CALL","APEX ROAR"] else 6 if b.move in ["TAIL SWEEP","CROSS SLASH","JAW SWEEP"] else 5
 return 1+int(clock*6)%2 if b.get("motion",Vector2.ZERO).length_squared()>.01 else 0
static func draw(c,b,p,clock,tint=Color.WHITE):
 var index=IDS.find(b.identity)
 if index<0:return
 var pose=frame(b,clock)
 if b.get("render_frame",pose)!=pose:
  b.render_previous=b.get("render_frame",pose);b.render_changed=clock
 b.render_frame=pose
 var source=Rect2(Vector2(pose%4*512,(index*2+floori(float(pose)/4))*384),Vector2(512,384))
 var width=WIDTH[b.identity]
 var progress=clampf(1-b.get("action_left",0)/maxf(.01,b.get("action_length",1)),0,1)
 var offset=Vector2(0,-b.get("lift",0))
 if b.action=="windup":offset-=b.get("motion",Vector2.RIGHT)*sin(progress*PI)*9
 if b.action=="strike":offset+=b.get("motion",Vector2.RIGHT)*sin(progress*PI)*15
 c.draw_set_transform(p+offset,b.get("pose",0),Vector2(-1 if b.get("motion",b.aim).x<0 else 1,1))
 var blend=smoothstep(0,.12,clock-b.get("render_changed",clock-.12))
 var destination=Rect2(Vector2(-width/2,-width*.73),Vector2(width,width*.75))
 if blend<1:
  var previous=b.get("render_previous",pose)
  var before=Rect2(Vector2(previous%4*512,(index*2+floori(float(previous)/4))*384),Vector2(512,384))
  c.draw_texture_rect_region(SHEET,destination,before,Color(tint,tint.a*(1-blend)))
 c.draw_texture_rect_region(SHEET,destination,source,Color(tint,tint.a*blend))
 c.draw_set_transform(Vector2.ZERO)
static func corpse(identity):
 if corpses.has(identity):return corpses[identity]
 var bounds=preload("res://scripts/dinosaur_layout.gd").CORPSES[identity]
 var pose=ImageTexture.create_from_image(SHEET.get_image().get_region(Rect2i(bounds)))
 corpses[identity]=pose
 return pose
