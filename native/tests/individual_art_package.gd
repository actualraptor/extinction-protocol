extends SceneTree
const ROOT="D:/Utveckling CODEX/Dummy test/native/build/"
func digest(bytes):
 var hashing=HashingContext.new();hashing.start(HashingContext.HASH_SHA256);hashing.update(bytes)
 return hashing.finish().hex_encode()
func _initialize():
 var snapshot={}
 for path in ["res://assets/dinosaurs/regular-atlas.png","res://assets/dinosaurs/boss-atlas.png"]:
  snapshot[path]=digest(load(path).get_image().get_data())
 for id in range(1,7):
  var path="res://payload/dinosaurs/%02d.dat"%id
  snapshot[path]=digest(FileAccess.get_file_as_bytes(path))
 for id in ["thorn","basalt","hunt","aurora","warden","bloom"]:
  for shot in range(4):
   var path="res://payload/dinosaurs/story-"+id+"-"+str(shot)+".dat"
   snapshot[path]=digest(FileAccess.get_file_as_bytes(path))
 for name in ["02-returning-beasts","04-last-stand"]:
  var path="res://assets/intro/"+name+".png"
  snapshot[path]=digest(load(path).get_image().get_data())
 if "--record-art" in OS.get_cmdline_user_args():
  var file=FileAccess.open(ROOT+"individual-art-package-hashes.json",FileAccess.WRITE)
  file.store_string(JSON.stringify(snapshot));file.close()
  print("Recorded source runtime texture and private pose payload hashes")
 else:
  var expected=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"individual-art-package-hashes.json"))
  assert(expected==snapshot,"Exported art differs from the validated source build")
  print("PACKAGED ART: dinosaur poses, 24 story paintings and two updated intro pages match source exactly")
 quit()
