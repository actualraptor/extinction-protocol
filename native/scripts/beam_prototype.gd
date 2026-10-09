extends RefCounted
## Beam prototype: branch state belongs to the owned weapon, never the catalog.
const WEAPONS={
 "plasma_tether":{"name":"Rift Conduit","damage":36.0,"range":220.0,"width":21.0,"duration":1.8,"cooldown":3.4,"tags":["WEAPON","ARCANE","PLASMA","BEAM","AREA","CRITICAL","DURATION"]},
 "flametorch":{"name":"Flametorch","damage":32.0,"range":155.0,"width":34.0,"duration":1.25,"cooldown":3.0,"tags":["WEAPON","FIRE","BEAM","AREA","CRITICAL","DURATION"]}}
const CHOICES={
 "plasma_tether":{5:[{"id":"reach","name":"Far Conduit","desc":"+45% connection length."},{"id":"sustain","name":"Lasting Bond","desc":"+60% connection duration."}],10:[{"id":"split","name":"Rift Web","desc":"Three simultaneous connections. Crossing enemies take damage too."},{"id":"power","name":"Overcharged","desc":"+85% plasma damage."}]},
 "flametorch":{5:[{"id":"reach","name":"Longburn","desc":"+45% beam length."},{"id":"sustain","name":"Deep Fuel","desc":"+60% firing duration."}],10:[{"id":"split","name":"Twin Pyres","desc":"Two full-strength streams aimed at separate nearby enemies."},{"id":"power","name":"White Heat","desc":"+85% beam damage."}]}}
static func pending(id,weapon):
 if not CHOICES.has(id):return 0
 for milestone in [5,10]:
  if weapon.get("level",1)>=milestone and not weapon.get("branches",{}).has(str(milestone)):return milestone
 return 0
static func choose(id,weapon,milestone,choice):
 if pending(id,weapon)!=milestone:return false
 if not CHOICES[id][milestone].any(func(o):return o.id==choice):return false
 if not weapon.has("branches"):weapon.branches={}
 weapon.branches[str(milestone)]=choice
 return true
static func stats(id,weapon,modifiers={}):
 var s=WEAPONS[id].duplicate(true)
 var branches=weapon.get("branches",{})
 s.damage*=1+.3*(weapon.get("level",1)-1)
 s.range*= (1.45 if branches.get("5","")=="reach" else 1.0)*(1+modifiers.get("range",0.0))
 s.duration=s.duration*(1.6 if branches.get("5","")=="sustain" else 1.0)+modifiers.get("duration",0.0)
 s.width*=1+modifiers.get("area",0.0)
 s.damage*= (1.85 if branches.get("10","")=="power" else 1.0)*(1+modifiers.get("power",0.0))
 s.count=(3 if id=="plasma_tether" else 2) if branches.get("10","")=="split" else 1
 s.cooldown/=1+modifiers.get("haste",0.0)
 return s
static func intersects(origin,direction,length,width,point,radius):
 var axis=direction.normalized()
 var delta=point-origin
 var along=delta.dot(axis)
 # Capsule footprint: width buffs genuinely increase the damage footprint.
 var nearest=origin+axis*clampf(along,0,length)
 return nearest.distance_squared_to(point)<=pow(width*.5+radius,2)
