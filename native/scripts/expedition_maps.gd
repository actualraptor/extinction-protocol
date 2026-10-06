extends RefCounted
const DATA = {
	"cradle":{"name":"The Lost Cradle","desc":"Open jungle clearings, broken ridges and winding paths. The original expedition.","layout":0,"music":0,"unlock":"","color":"83b998","biomes":["The Lost Cradle","The Ashen Rift","The Star Grave"],"grounds":["152b2d","30212c","1b243b"],"pools":[[0,0,1,2,4,5,8,9,10],[0,4,3,5,6,7,9,11,13],[0,4,6,9,11,12,13]]},
	"frostbreak":{"name":"Frostbreak Expanse","desc":"Broad ice avenues between glacial shelves. Charging packs and spectral drifters.","layout":1,"music":1,"unlock":"map_frost","color":"a0dfff","biomes":["The Ivory Shelf","Aurora Trenches","The Frozen Firmament"],"grounds":["405e70","263f60","282a51"],"pools":[[0,0,4,4,14,2,3],[0,0,4,4,14,15,15,7],[0,4,4,14,15,15,6,12]]},
	"observatory":{"name":"The Sunken Observatory","desc":"Astronomical courtyards connected by generous gates. Armored constructs and spore broods.","layout":2,"music":2,"unlock":"map_observatory","color":"e7c475","biomes":["The Drowned Court","The Brass Meridian","The Unmade Sky"],"grounds":["274b48","504832","352648"],"pools":[[0,4,16,16,17,5],[0,4,16,17,17,8,9],[0,4,16,17,15,11,13]]}
}
static func available(profile,id): return DATA.has(id) and (DATA[id].unlock=="" or DATA[id].unlock in profile.get("unlocks",[]))
static func pool(id,depth,time):
	var pool = DATA[id].pools[depth].duplicate()
	if time<90: return [0,0,4,4,4,pool[2]]
	return pool
static func biome(id,depth):
	var d=DATA[id]
	return {"name":d.biomes[depth].to_upper(),"tag":"%02d / %s"%[depth+1,d.biomes[depth].to_upper()],"ground":d.grounds[depth],"accent":d.color}

static func boss_name(id,stage):
	var identities={"cradle":["thorn","basalt"],"frostbreak":["hunt","aurora"],"observatory":["warden","bloom"]}
	return preload("res://scripts/boss_identity.gd").full_name("meteor" if stage==3 else identities[id][stage-1])
