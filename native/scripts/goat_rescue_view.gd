extends Node2D
const Trial=preload("res://scripts/goat_rescue.gd")
const REST=preload("res://assets/torr-goats/resting.png")
const STAND=preload("res://assets/torr-goats/standing.png")
const DESCENT=preload("res://assets/torr-poses/descent.png")
const LANDING=preload("res://assets/torr-poses/landing.png")
const TORR=preload("res://assets/torr-poses/ready.png")
var world
var plate_style=preload("res://scripts/ui_art.gd").button_style()
func _process(_dt):queue_redraw()
func text(at,words,size=16,color=Color("ecdfbb")):
 draw_string_outline(world.font,at,words,HORIZONTAL_ALIGNMENT_LEFT,-1,size,4,Color("101719"))
 draw_string(world.font,at,words,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func _draw():
 if world==null or world.sim==null:return
 var g=world.sim
 var t=g.goat_trial
 if t.is_empty() or t.state=="failed":return
 if t.state=="saved" and g.time-t.finished_at>16:return
 var at=world.screen(t.p)
 var active=Trial.running(g)
 var tending=active and g.pos.distance_to(t.p)<=Trial.RADIUS
 var blue=Color("a9dcf1")
 if active:
  draw_circle(at,Trial.RADIUS,Color(.35,.7,.85,.025))
  draw_arc(at,Trial.RADIUS,0,TAU,96,Color(blue,.6 if tending else .25),2,true)
  for i in 12:
   var mark=at+Vector2.from_angle(i*TAU/12)*Trial.RADIUS
   draw_line(mark,at+(mark-at)*.95,Color(blue,.45),2,true)
 for i in 2:
  var goat=t.goats[i]
  var p=world.screen(goat.p)
  var saved_age=g.time-t.get("finished_at",g.time)
  var healed=t.state=="saved" and saved_age>=1.2
  var fade=clampf((15.0-saved_age)*2,0,1) if healed else 1.0
  if healed and saved_age>11:
   p=p.lerp(at+Vector2(104 if i==0 else 236,-5),clampf((saved_age-11)/2,0,1))
   if saved_age>14:p.y-=pow(clampf((saved_age-14)/.9,0,1),2)*550
  if not world.visible_rect().grow(130).has_point(p):continue
  draw_set_transform(p,0,Vector2(1,.3));draw_circle(Vector2.ZERO,48,Color(.01,.015,.02,.45*fade));draw_set_transform(Vector2.ZERO)
  var image=STAND if healed else REST
  var dimensions=Vector2(133,145 if healed else 118)
  var color=Color.WHITE if i==0 else Color(.77,.84,.91)
  if goat.flash>0:color=Color("ffb5a0")
  color.a=fade
  var breathe=sin(g.time*1.8+i)*.7
  draw_texture_rect(image,Rect2(p-Vector2(dimensions.x*.5,dimensions.y*.85+breathe),dimensions),false,color)
  if tending and goat.hp<100:
   draw_arc(p,45+sin(g.time*2+i)*4,0,TAU,32,Color(.6,.85,1,.35),1.5,true)
  if active:
   draw_rect(Rect2(p+Vector2(-39,13),Vector2(78,7)),Color("182426"))
   draw_rect(Rect2(p+Vector2(-39,13),Vector2(78*goat.hp/100,7)),Color("88c8b0"))
   draw_rect(Rect2(p+Vector2(-39,13),Vector2(78,7)),Color("bfa267"),false,1)
 for attack in t.attacks:
  var source=world.screen(attack.enemy.p)
  var target=world.screen(t.goats[attack.goat].p)
  var progress=clampf(1-attack.wait/1.25,0,1)
  draw_line(source,target,Color(.95,.48,.3,.5),2,true)
  draw_arc(source,attack.enemy.size+8,-PI/2,-PI/2+TAU*progress,32,Color("ffb070"),3,true)
 if t.state=="waiting" and g.pos.distance_to(t.p)<350:
  text(at+Vector2(-120,-120),"THE THUNDERER'S DEBT",18)
  var prompt="DEFEAT THE BOSS FIRST" if g.boss!=null else "LET THE AREA SETTLE FIRST" if g.spawn_respite>0 else "E · TEND THE WOUNDED PAIR"
  text(at+Vector2(-115,42),prompt,15,blue)
  text(at+Vector2(-145,63),"A dangerous hunt. Begin when you are ready.",14)
 if active:
  var origin=Vector2(720,155)
  var plate=Rect2(origin-Vector2(300,0),Vector2(600,138))
  draw_style_box(plate_style,plate)
  text(plate.position+Vector2(64,38),"THE THUNDERER'S DEBT",19)
  for i in 2:
   var p=plate.position+Vector2(64+i*238,48)
   text(p+Vector2(0,14),("GRINDER" if i==0 else "GNASHER")+" · "+str(roundi(t.goats[i].hp))+"%",14)
   draw_rect(Rect2(p+Vector2(0,21),Vector2(210,8)),Color("142327"))
   draw_rect(Rect2(p+Vector2(0,21),Vector2(210*t.goats[i].hp/100,8)),Color("86c7ba"))
  var detail="Tending · keep hunters away" if tending else "Healing paused · return to the circle"
  if t.final>0:detail="FINAL STAND · "+str(ceili(15-t.final))+" seconds · keep both healed"
  if t.away>0:detail="ABANDONMENT · return within "+str(ceili(8-t.away))+" seconds"
  text(plate.position+Vector2(64,107),detail,15,blue)
  if not world.visible_rect().grow(-100).has_point(at):
   var edge=Vector2(clampf(at.x,110,1330),clampf(at.y,290,650))
   text(edge,"GOATS →",16,blue)
 if t.state=="saved":arrival(at,g.time-t.finished_at)
func bolt(first,last,seed,alpha,width=3.0):
 var previous=first
 for i in range(1,11):
  var f=float(i)/10
  var p=first.lerp(last,f)+Vector2(sin(seed+i*2.7)*26*sin(f*PI),0)
  draw_line(previous,p,Color(.34,.64,.85,alpha*.18),width*5,true)
  draw_line(previous,p,Color(.6,.84,1,alpha*.7),width*2,true)
  draw_line(previous,p,Color(.92,.98,1,alpha),width,true)
  previous=p
func arrival(at,age):
 var reduced=world.reduced_effects
 var landing=at+Vector2(170,60)
 var ground=landing+Vector2(-35,12)
 var impact=age-1.2
 if age<1.2:
  var charge=clampf(age/1.2,0,1)
  draw_arc(ground,32+charge*80,0,TAU,64,Color(.6,.86,1,.5*charge),2,true)
  if age>.35:
   var height=650*(1-pow(clampf((age-.35)/.85,0,1),2))
   var p=landing-Vector2(0,height)
   bolt(p-Vector2(0,330),p,3,.6,2 if reduced else 4)
   draw_texture_rect(DESCENT,Rect2(p-Vector2(80,145),Vector2(160,160)),false)
 if impact>=0 and impact<1.35:
  var glow=clampf(1-impact/1.35,0,1)
  draw_circle(ground,110+impact*230,Color(.45,.72,.9,glow*(.025 if reduced else .07)))
  for ring in (1 if reduced else 3):
   var radius=maxf(0,impact*520-ring*38)
   draw_arc(ground,radius,0,TAU,96,Color(.65,.9,1,glow*.65),maxf(1,4-ring),true)
  if impact<.6:
   bolt(ground-Vector2(0,900),ground,1,1-impact/.6,3 if reduced else 7)
   if not reduced:
    for i in 4:
     var p=ground+Vector2.from_angle(i*TAU/4+.4)*(70+i*24)
     bolt(p-Vector2(130-i*65,650),p,i+2,(1-impact/.6)*.7,2)
 if impact>=0 and impact<10:
  var fade=clampf(1-impact/10,0,1)
  for i in (5 if reduced else 12):
   var ray=Vector2.from_angle(i*TAU/12+sin(i*3.7)*.21)
   var previous=ground+ray*20
   for joint in range(1,5):
    var crack=ground+ray*(20+joint*(18+sin(i*2.2)*8))+ray.orthogonal()*sin(i*4.1+joint*2)*12
    draw_line(previous,crack,Color(.06,.1,.12,fade),4,true)
    draw_line(previous,crack,Color(.5,.79,.9,fade*.5),1,true)
    previous=crack
 if age>=1.2 and age<15:
  var p=landing
  var fade=clampf((15-age)*2,0,1)
  if age>14:p.y-=pow(clampf((age-14)/.9,0,1),2)*550
  var rise=clampf((age-2.0)/.6,0,1)
  draw_set_transform(landing+Vector2(0,15),0,Vector2(1,.3));draw_circle(Vector2.ZERO,43,Color(.01,.015,.02,.5*fade));draw_set_transform(Vector2.ZERO)
  if rise<1:draw_texture_rect(LANDING,Rect2(p-Vector2(90,110),Vector2(180,140)),false,Color(1,1,1,1-rise))
  if rise>0:draw_texture_rect(TORR,Rect2(p-Vector2(75,155),Vector2(150,170)),false,Color(1,1,1,rise*fade))
 if age>=14 and age<15:
  bolt(landing-Vector2(0,900),landing,4,(15-age)*.8,3 if reduced else 6)
  draw_arc(at,120+(age-14)*290,0,TAU,80,Color(.65,.9,1,(15-age)*.6),3,true)
 var words=""
 if age>=2.2 and age<6.6:words="You stood for them when they could not. Thank you, mortal."
 elif age>=6.6 and age<10.8:words="A debt to Torr Stormbuk is a debt the storm remembers."
 elif age>=10.8 and age<14:words="Come, you two. Home."
 if words!="":
  var head=landing+Vector2(0,-185)
  preload("res://scripts/tfk_speech.gd").draw(self,world.font,words,head,19,Color("eff8ff"),360)
  preload("res://scripts/tfk_speech.gd").draw(self,world.font,"TORR STORMBUK",head+Vector2(0,-65),14,Color("d9b970"),360)
