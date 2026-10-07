extends RefCounted
const DATA = {
 "cradle": {
  "name": "The Lost Cradle",
  "desc": "Open prehistoric grasslands, broken ridges and winding paths. Horned herds and hunting packs.",
  "layout": 0,
  "music": 0,
  "unlock": "",
  "color": "83b998",
  "biomes": [
   "The Lost Cradle",
   "The Ashen Rift",
   "The Star Grave"
  ],
  "grounds": [
   "152b2d",
   "30212c",
   "1b243b"
  ],
  "pools": [
   [
    0,
    0,
    1,
    2,
    3,
    5,
    7
   ],
   [
    0,
    0,
    1,
    3,
    5,
    7,
    2
   ],
   [
    0,
    1,
    3,
    3,
    5,
    7,
    2
   ]
  ]
 },
 "frostbreak": {
  "name": "Frostbreak Expanse",
  "desc": "Broad ice avenues between glacial shelves. Feathered hunters and armored herds.",
  "layout": 1,
  "music": 1,
  "unlock": "map_frost",
  "color": "a0dfff",
  "biomes": [
   "The Ivory Shelf",
   "Aurora Trenches",
   "The Frozen Firmament"
  ],
  "grounds": [
   "405e70",
   "263f60",
   "282a51"
  ],
  "pools": [
   [
    18,
    18,
    6,
    14,
    15,
    16,
    17
   ],
   [
    18,
    6,
    14,
    14,
    15,
    16,
    17
   ],
   [
    18,
    6,
    14,
    15,
    15,
    16,
    17
   ]
  ]
 },
 "observatory": {
  "name": "The Sunken Observatory",
  "desc": "Dense prehistoric jungle around drowned courtyards. Ambush predators, nesting dinosaurs and heavy herbivores.",
  "layout": 2,
  "music": 2,
  "unlock": "map_observatory",
  "color": "e7c475",
  "biomes": [
   "The Drowned Court",
   "The Brass Meridian",
   "The Unmade Sky"
  ],
  "grounds": [
   "274b48",
   "504832",
   "352648"
  ],
  "pools": [
   [
    12,
    12,
    8,
    9,
    10,
    11,
    13
   ],
   [
    12,
    8,
    9,
    10,
    11,
    13,
    13
   ],
   [
    12,
    8,
    9,
    10,
    11,
    11,
    13
   ]
  ]
 }
}
static func available(profile,id): return DATA.has(id) and (DATA[id].unlock=="" or DATA[id].unlock in profile.get("unlocks",[]))
static func pool(id,depth,time):
	var pool = DATA[id].pools[depth].duplicate()
	if time<90: return [pool[0],pool[0],pool[0],pool[2]]
	return pool
static func biome(id,depth):
	var d=DATA[id]
	return {"name":d.biomes[depth].to_upper(),"tag":"%02d / %s"%[depth+1,d.biomes[depth].to_upper()],"ground":d.grounds[depth],"accent":d.color}

static func boss_name(id,stage):
	var identities={"cradle":["thorn","basalt"],"frostbreak":["hunt","aurora"],"observatory":["warden","bloom"]}
	return preload("res://scripts/boss_identity.gd").full_name("meteor" if stage==3 else identities[id][stage-1])
