extends SceneTree
const Exp=preload("res://scripts/expedition.gd")
var results=[]
func _initialize():call_deferred("run")
func priority(g,o,orbit):
 if o.type=="beam_path":return 100 if o.branch==("orbit" if orbit else "bounce") else 50
 if o.type in ["fusion","evolution"]:return 95
 if o.type=="weapon":return 85 if g.weapons.has(o.id) else 90 if g.weapons.size()<3 and o.id in ["gungnir","ninefold","oathsplitter","winter_claim"] else 75
 if o.type=="passive":return 80 if o.id in ["damage","haste","count","armor","regen","crit"] else 15
 if o.type=="augment":return 65
 return 20
func run():
 for orbit in [false,true]:
  var g=Exp.new();g.setup(7,"expedition",{},87 if orbit else 42)
  var peak=0;var bosses=0;var decisions=0
  for tick in 30*1200:
   if not g.active:break
   if g.choosing:
    var best=0
    for i in g.options.size():
     if priority(g,g.options[i],orbit)>priority(g,g.options[best],orbit):best=i
    g.choose(best);decisions+=1
   var target=g.pos+Vector2.RIGHT.rotated(g.time*.18)*100
   if g.portal!=null:target=g.portal
   elif g.boss!=null:
    target=g.anchors[0].p+Vector2(0,85) if not g.anchors.is_empty() else g.boss.p+(g.pos-g.boss.p).normalized()*240+Vector2(0,100)
   elif not g.gems.is_empty():
    var closest=g.gems[0]
    for gem in g.gems:
     if gem.p.distance_squared_to(g.pos)<closest.p.distance_squared_to(g.pos):closest=gem
    target=closest.p
   var move=(target-g.pos).limit_length(1)
   for e in g.nearby(g.pos,100):
    if not e.dead and not e.anchor:move+=(g.pos-e.p).normalized()*clampf((85-g.pos.distance_to(e.p))/35,0,2)
   g.tick(1.0/30,move.limit_length(1))
   peak=maxi(peak,g.enemies.size());bosses=maxi(bosses,g.boss_stage)
   if g.portal!=null and g.pos.distance_to(g.portal)<55:g.enter_portal()
   if tick%120==0:await process_frame
  var row={"orbit":orbit,"seconds":g.time,"won":g.won,"active":g.active,"level":g.level,"kills":g.kills,"peak_enemies":peak,"boss_stage":bosses,"decisions":decisions,"damage":g.damage_total,"reason":g.death_reason,"weapons":g.weapons}
  results.append(row);print("TORR PROGRESSION / ",JSON.stringify(row))
 var f=FileAccess.open("res://build/torr-progression-review.json",FileAccess.WRITE);f.store_string(JSON.stringify(results,"  "));f.close();quit()
