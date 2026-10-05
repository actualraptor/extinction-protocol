extends RefCounted
## Player-facing changes only.
const VERSION="0.11.6"
const TITLE="Earth Awakens"
const ENTRIES=[
 {
  "icon": "map",
  "category": "relic",
  "title": "FEEL THE IMPACT",
  "body": "Kael slams a crater into the ground, sending staggered fracture fronts and lifted debris outward. Dirt, ice and stone each respond to the blow."
 },
 {
  "icon": "map",
  "category": "relic",
  "title": "THE EARTH BREAKS OPEN",
  "body": "World Breaker ignites brighter fissures. Earth Shaker adds broader glowing cracks and brilliant cores while preserving Kael's slam animation."
 },
 {
  "icon": "map",
  "category": "relic",
  "title": "POWER AT ANY SPEED",
  "body": "Wind-up and shock fronts compress with attack speed. Visual overlap stays bounded while damage waves complete independently."
 }
]
static func releases():
	var all=[{"version":VERSION,"title":TITLE,"entries":ENTRIES}]
	all.append_array(JSON.parse_string(FileAccess.get_file_as_string("res://assets/patch-history.json")))
	return all
