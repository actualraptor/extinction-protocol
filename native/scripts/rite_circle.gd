extends RefCounted
const BEAT_START=.65
const BEAT_PERIOD=1.35
static func beats(g,before,after):
 for i in range(12):
  var at=BEAT_START+i*BEAT_PERIOD
  if before<at and after>=at:g.sound.emit("rite_pulse")
static func flare(clock):
 if clock<BEAT_START:return 0.0
 var age=fposmod(clock-BEAT_START,BEAT_PERIOD)
 return exp(-age*9)*smoothstep(0,.025,age)
# Aurebesh stroke forms traced from the supplied alphabet reference.
# Paths use a small local square, making every glyph reusable at any scale.
const GLYPHS={
 "A":[[0,.1,.5,.1,1,-.1],[0,.5,.5,.5,1,.85],[0,.35,0,.85]],
 "B":[[0,.15,.2,0,.8,0,1,.2],[0,.75,.2,.9,.8,.9,1,.7],[.2,.4,.75,.4]],
 "D":[[0,.1,1,.1,.4,.6,.7,.6,.1,1]],
 "E":[[0,0,.35,.9,.55,.9,.9,0,1,0],[.85,0,.85,.85]],
 "G":[[.35,0,.35,.9,1,.9,1,0,.6,0,.6,.55,.2,.55]],
 "H":[[0,0,1,0],[.2,.45,.8,.45],[0,.9,1,.9]],
 "I":[[.6,0,.6,.9,1,.9]],
 "K":[[0,0,1,0,1,.9]],
 "L":[[0,.35,.8,.95,.8,0]],
 "M":[[0,.95,.35,0,.75,0],[.2,.95,.65,.95]],
 "N":[[0,0,.35,.9,.65,.15,1,.9]],
 "O":[[.2,0,.8,0,1,.9,0,.9,.2,0]],
 "R":[[0,0,1,0,.2,.9]],
 "S":[[0,0,.85,.9,.85,0],[0,.6,.4,.9]],
 "T":[[0,.2,.5,.95,1,.2],[.5,0,.5,.95]],
 "U":[[0,.3,.3,0,.85,0,.85,.9,0,.9]],
 "V":[[0,0,.5,.45,1,0],[.5,.45,.5,1]],
 "X":[[0,.9,.5,0,1,.9,0,.9]],
 "Y":[[0,0,.45,.9,1,0],[.2,0,.6,.65]],
 "W":[[0,0,1,0,1,.9,0,.9,0,0]]
}
static func stroke(canvas,origin,points,color,width=1.0):
 var projected=PackedVector2Array()
 for point in points:projected.append(origin+point*Vector2(1,.72))
 canvas.draw_polyline(projected,Color(color,color.a*.12),width+7,true)
 canvas.draw_polyline(projected,Color(color,color.a*.23),width+3,true)
 canvas.draw_polyline(projected,color,width,true)
static func glyph(canvas,origin,letter,centre,angle,size,color):
 for path in GLYPHS.get(letter,[]):
  var points=PackedVector2Array()
  for i in range(0,path.size(),2):
   points.append(centre+(Vector2(path[i]-.5,path[i+1]-.45)*size).rotated(angle))
  stroke(canvas,origin,points,color,1.45)
static func draw(canvas,g,c,marker,blocked,complete=false,opacity=1.0):
 var active=c.raising or c.charge>0
 var pulse=.5+.5*sin(g.time*2.4)
 var charged=clampf(c.charge/2.5,0,1)
 var beat=flare(c.charge+c.get("ritual",0.0) if c.raising else c.charge) if not blocked else 0.0
 var ink=Color("647770") if blocked else Color("64cfa0").lerp(Color("d4ffe7"),.55*charged)
 ink=ink.lerp(Color("f0fff6"),beat*.9)
 if complete:ink=Color("e3fff0")
 ink.a=(.4 if blocked else 1.0 if complete else minf(1,.4+charged*.5+pulse*.1+beat*.5) if active else .4)*opacity
 # Ground projection; no floating icon or instruction label.
 canvas.draw_set_transform(marker,0,Vector2(1,.72))
 canvas.draw_circle(Vector2.ZERO,74,Color(ink,(.09 if complete else .025)*opacity))
 canvas.draw_arc(Vector2.ZERO,74+beat*9,0,TAU,96,Color(ink,beat*.45*opacity),2+beat*2,true)
 for radius in [40,65,74]:
  canvas.draw_arc(Vector2.ZERO,radius,0,TAU,96,Color(ink,ink.a*.6),1,true)
 canvas.draw_arc(Vector2.ZERO,77,-PI/2,-PI/2+TAU*charged,96,ink,2,true)
 canvas.draw_set_transform(Vector2.ZERO)
 var chant=(preload("res://scripts/boss_identity.gd").short_name(c.identity)+" ").repeat(3)
 var rotation=g.time*.045 if active else 0.0
 for i in range(chant.length()):
  var angle=-PI/2+i*TAU/chant.length()+rotation
  var centre=Vector2.from_angle(angle)*53
  if chant[i]==" ":
   stroke(canvas,marker,[centre-Vector2.from_angle(angle)*1.4,centre+Vector2.from_angle(angle)*1.4],ink)
  else:
   if beat>.02 or complete:
    var glow=Color("baffd7");glow.a=(1.0 if complete else beat)*opacity
    for path in GLYPHS.get(chant[i],[]):
     var points=PackedVector2Array()
     for n in range(0,path.size(),2):points.append(centre+(Vector2(path[n]-.5,path[n+1]-.45)*Vector2(8,11)).rotated(angle+PI/2))
     stroke(canvas,marker,points,Color(glow,glow.a*.55),3.5)
   glyph(canvas,marker,chant[i],centre,angle+PI/2,Vector2(8,11),ink)
 # Six warding signs link the inscription to the outer seal.
 for i in range(6):
  var angle=i*TAU/6-PI/2
  var centre=Vector2.from_angle(angle)*69.5
  var points=PackedVector2Array()
  for v in [Vector2(-2,0),Vector2(0,-3),Vector2(2,0),Vector2(0,3),Vector2(-2,0)]:
   points.append(centre+v.rotated(angle+PI/2))
  stroke(canvas,marker,points,ink,.9)
  stroke(canvas,marker,[Vector2.from_angle(angle)*38,Vector2.from_angle(angle)*43],ink,.9)
