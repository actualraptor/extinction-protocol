extends SceneTree
func _initialize():
 preload("res://scripts/content_extension.gd").install(preload("res://scripts/catalog.gd"))
 var g=preload("res://scripts/expedition.gd").new();g.setup(5,"safari",{},17)
 g.spawn_boss(1);g.kill(g.boss);g.pos=g.boss_corpses[0].marker
 var r=preload("res://scripts/remnant_system.gd");var events=[]
 g.sound.connect(func(id):events.append(id))
 r.update(g,r.CHANNEL);assert(events.count("rite_hum")==1)
 r.update(g,1.2);assert(events.count("rite_crunch")==1)
 g.pos+=Vector2(100,0);r.update(g,.1);assert(events.count("rite_stop")==1)
 g.pos=g.boss_corpses[0].marker;r.update(g,r.CHANNEL);events.clear()
 for i in range(120):r.update(g,.1)
 r.update(g,.01)
 assert(events.count("rite_crunch")==4 and events.count("rite_finish")==1 and events.count("rite_stop")==1)
 assert(events.count("rite_lock")==9 and events.count("rite_pulse")==9)
 assert(g.boss_corpses[0].consumed)
 assert(g.boss_corpses[0].afterglow>0)
 r.update(g,1.0);assert(g.boss_corpses[0].afterglow==0)
 var animation=preload("res://scripts/rite_animation.gd")
 var order=[4,3,7,6,0,1,8,5,2]
 for i in range(8):
  var at=(5.92+i*.64)/animation.DURATION
  assert(animation.assembly_join(order[i],at)>.999 and animation.assembly_join(order[i+1],at)==0)
 for id in range(9):
  var at=animation.split_time(id)/animation.DURATION
  assert(animation.fold_amount(id,at-.001)==0)
  assert(animation.fold_amount(id,at+.01)>0)
 assert(animation.spread_amount(0)==0 and animation.spread_amount(.12)>.99)
 assert(animation.spread_amount(.02)>.9 and animation.spread_amount(.2)==1 and animation.spread_amount(1)==0)
 assert(animation.inward_amount(.15)==0 and animation.inward_amount(.6)>0)
 for id in range(9):
  var start=(animation.split_time(id)+.468)/animation.DURATION
  assert(animation.passage(id,start-.001)==0 and animation.passage(id,start+.15)==1)
 var offset=Vector2(60,35)
 var centre=animation.passage_position(offset,Vector2.ZERO,.5)
 assert(centre==Vector2(0,-48))
 assert(animation.passage_position(offset,Vector2.ZERO,0).x>0 and animation.passage_position(offset,Vector2.ZERO,1).x<0)
 var exit_time=(animation.split_time(0)+.468+1.7)/animation.DURATION
 assert(animation.orbit_position(offset,Vector2.ZERO,0,exit_time).distance_to(animation.passage_position(offset,Vector2.ZERO,1))<.001)
 assert(animation.orbit_position(offset,Vector2.ZERO,0,exit_time+.1).distance_to(animation.orbit_position(offset,Vector2.ZERO,0,exit_time+.15))>10)
 for speed in [-60.0,10.0]:
  var flight=animation.fluid_flight(40,speed)
  assert(flight>0 and absf(speed*flight+130*flight*flight-40)<.001)
 assert(animation.fluid("basalt").r>.9 and animation.fluid("aurora").b>.9)
 print("RITUAL FOLEY / start, four cues, cancellation and completion verified")
 quit()
