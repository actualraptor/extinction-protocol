extends RefCounted
const DATA = [
	{"name":"Raptor","hp":24,"speed":85,"size":19,"role":"chase"},
	{"name":"Triceratops","hp":52,"speed":62,"size":21,"role":"armor"},
	{"name":"Pteranodon","hp":17,"speed":130,"size":19,"role":"fly"},
	{"name":"Sabretooth","hp":38,"speed":112,"size":19,"role":"chase"},
	{"name":"Carapace Beetle","hp":16,"speed":100,"size":16,"role":"chase"},
	{"name":"Venomcrest","hp":34,"speed":72,"size":21,"role":"spit"},
	{"name":"Ironback","hp":110,"speed":49,"size":26,"role":"armor"},
	{"name":"Tuskbreaker","hp":140,"speed":55,"size":32,"role":"charge"},
	{"name":"Brood Widow","hp":72,"speed":61,"size":24,"role":"brood"},
	{"name":"Amberwing","hp":20,"speed":145,"size":17,"role":"fly"},
	{"name":"Mossjaw","hp":145,"speed":40,"size":27,"role":"armor","resists":{"FIRE":1.2}},
	{"name":"Cinder Colossus","hp":180,"speed":50,"size":32,"role":"slam","resists":{"FIRE":0.6,"ICE":1.2}},
	{"name":"Rift Stalker","hp":45,"speed":137,"size":20,"role":"phase"},
	{"name":"Embersail","hp":85,"speed":88,"size":25,"role":"spit"},
	{"name":"Frostfang","hp":40,"speed":107,"size":21,"role":"charge","resists":{"ICE":0.8,"FIRE":1.2}},
	{"name":"Aurora Drifter","hp":28,"speed":115,"size":23,"role":"phase","resists":{"ARCANE":0.8}},
	{"name":"Meridian Scarab","hp":85,"speed":65,"size":25,"role":"armor"},
	{"name":"Spore Reliquary","hp":60,"speed":66,"size":24,"role":"brood"}
]

static func pool(depth,time):
	if time<45: return [0,0,0,0,4]
	if depth==0 and time<110: return [0,0,0,1,2,4,5,9]
	if depth==0: return [0,0,0,1,2,3,4,5,6,7,8,9,10]
	if depth==1: return [0,1,3,5,6,7,8,9,11,11,13]
	return [3,6,7,8,9,10,11,12,12,13,13]
