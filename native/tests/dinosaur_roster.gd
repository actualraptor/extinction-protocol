extends SceneTree
func _initialize():call_deferred("run")
func run():
 var B=preload("res://scripts/bestiary.gd")
 var M=preload("res://scripts/expedition_maps.gd")
 var names={}
 for e in B.DATA:
  assert(not names.has(e.species));names[e.species]=true
  var region=preload("res://scripts/dinosaur_art.gd").region(B.DATA.find(e),5)
  assert(region.end.x<=preload("res://scripts/dinosaur_art.gd").SHEET.get_width() and region.end.y<=preload("res://scripts/dinosaur_art.gd").SHEET.get_height())
  assert(e.role in ["chase","armor","fly","spit","brood","charge","slam","phase","stampede"])
 var owners={}
 for id in M.DATA:
  for pool in M.DATA[id].pools:
   for k in pool:
    assert(k>=0 and k<B.DATA.size() and k!=4)
    assert(not owners.has(k) or owners[k]==id);owners[k]=id
 var g=preload("res://scripts/expedition.gd").new();g.setup(1,"expedition",{},9301)
 var p=g.terrain.open_position(Vector2.ZERO)
 g.pos=p;g.hp=g.max_hp;g.invul=0
 var e=g.spawn_enemy(false,p-Vector2(20,0),4)
 preload("res://scripts/compy_stampede.gd").configure(g,e,Vector2.RIGHT)
 var before=e.p;var player_before=g.pos;var health=g.hp
 g.update_enemies(.1)
 assert(e.p.x>before.x and g.pos.x>player_before.x and g.hp<health)
 assert(e.hp==3 and e.flow==Vector2.RIGHT)
 g.pos=p+Vector2(0,500)
 before=e.p
 g.update_enemies(.1)
 assert(e.p.x>before.x,"Stampede must not turn toward player")
 e.flow_age=e.flow_lifetime+1
 g.update_enemies(.1)
 assert(e.dead,"Exit despawn must not grant XP")
 var victim=g.spawn_enemy(false,p+Vector2(200,0),4)
 preload("res://scripts/compy_stampede.gd").configure(g,victim,Vector2.RIGHT)
 var kills_before=g.kills;var gems_before=g.gems.size()
 g.hit(victim,5,"spear",false,false)
 assert(victim.dead and g.kills==kills_before+1 and g.gems.size()==gems_before+1,"An early hit must kill a Compy and award XP")
 g.enemies.clear();g.time=g.director.EVENTS[0].at+.1
 for i in range(240):
  g.director.update(g,1.0/30);g.time+=1.0/30
 var flock=g.enemies.filter(func(animal):return animal.kind==4)
 assert(flock.size()>=200)
 for animal in flock:assert(animal.has("flow") and animal.hp==3)
 print("Dinosaur roster unique; map pools distinct; 200+ directional Compys; collision damage/push/continuation/despawn passed")
 quit()
