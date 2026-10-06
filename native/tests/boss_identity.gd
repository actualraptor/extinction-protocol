extends SceneTree
func _initialize():call_deferred("run")
func run():
 var identities=preload("res://scripts/boss_identity.gd")
 var circles=preload("res://scripts/rite_circle.gd")
 var maps=preload("res://scripts/expedition_maps.gd")
 var frames=[]
 for identity in identities.DATA:
  var entry=identities.DATA[identity]
  assert(entry.frame not in frames);frames.append(entry.frame)
  if identity!="meteor":
   for letter in entry.name:assert(circles.GLYPHS.has(letter))
 for map in ["cradle","frostbreak","observatory"]:
  for stage in [1,2]:assert(", THE " in maps.boss_name(map,stage))
 assert(maps.boss_name("cradle",3)=="THE EXTINCTION ENGINE")
 assert(identities.short_name("basalt")=="BASALT")
 print("BOSS IDENTITIES / unique frames, names and complete Aurebesh coverage verified")
 quit()
