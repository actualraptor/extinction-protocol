extends RefCounted
## Permanent discoveries are separate from purchases. Existing research is never reset.
const BASE_WEAPONS = ["lightning","frost","fire","winter","revolver","club"]
const KITS = [["revolver","club","shotgun"],["club","spear","thorns"],["lightning","frost","fire"],["harpoon","frost","return"],["lantern","fire","orbital"]]
const ENTRIES = {
	"ironbriar":{"name":"The Ironbriar Cache","desc":"Unlock Ironbriar: armor-scaling thorn bursts and retaliation.","cost":0,"depth":0,"pos":Vector2(-510,980),"map":"cradle","weapons":["thorns"],"goal":"kills","target":800},
	"map_frost":{"name":"Frostbreak Expanse","desc":"Open a new expedition map: glacial avenues, ice packs and three original score cues.","cost":0,"depth":0,"pos":Vector2.ZERO,"map":"frostbreak","goal":"kills","target":250,"discoverable":false},
	"map_observatory":{"name":"The Sunken Observatory","desc":"Open the second new expedition: courtyard arenas, constructs and three original score cues.","cost":0,"depth":0,"pos":Vector2.ZERO,"map":"observatory","goal":"bosses","target":1,"discoverable":false},
	"iona":{"name":"Iona / Polar Arsenal","desc":"Recruit Iona and unlock Fossil Harpoon. Find her expedition camp on Frostbreak's first biome.","cost":0,"depth":0,"pos":Vector2(700,-620),"map":"frostbreak","hero":3,"weapons":["harpoon"]},
	"orin":{"name":"Orin / Occult Instruments","desc":"Recruit Orin and unlock Hollow Lantern. Find his signal in the Observatory's first biome.","cost":0,"depth":0,"pos":Vector2(-740,640),"map":"observatory","hero":4,"weapons":["lantern"]},
	"glacier":{"name":"Glacier Wheel","desc":"Unlock a ricocheting ice chakram. Kill 1,000 creatures in Frostbreak across expeditions.","cost":0,"depth":1,"pos":Vector2(1080,330),"map":"frostbreak","weapons":["glacier"],"goal":"map_kills","target":1000},
	"sunbow":{"name":"Helios Repeater","desc":"Unlock a rapid piercing sun crossbow. Kill 1,500 creatures in the Observatory.","cost":0,"depth":1,"pos":Vector2(-1050,-430),"map":"observatory","weapons":["sunbow"],"goal":"map_kills","target":1500},
	"mara":{"goal":"kills","target":100,"name":"Mara Voss","desc":"Unlock the gunslinger. Graveshot, raw damage and critical shots.","cost":180,"depth":0,"pos":Vector2(820,-480),"hero":0},
	"ballistics":{"goal":"kills","target":500,"name":"Lost Ballistics","desc":"Bone Rattler and Extinction Mortar enter the upgrade pool.","cost":140,"depth":0,"pos":Vector2(-760,610),"weapons":["shotgun","mortar"]},
	"riftcraft":{"goal":"kills","target":1200,"name":"Riftcraft","desc":"Rift Blades, Thunderstorm and Prism Aegis enter the upgrade pool.","cost":180,"depth":0,"pos":Vector2(650,820),"weapons":["orbital","thunderstorm","aegis"]},
	"tracking":{"name":"Predator Engineering","desc":"Unlock homing, ricochet and projectile accelerator upgrades.","cost":100,"depth":0,"pos":Vector2(-980,-590),"augments":["homing","bounce","velocity"]},
	"kael":{"goal":"kills","target":700,"name":"Kael, the First Man","desc":"Unlock the ancestor. Heavy melee, armor and endurance.","cost":260,"depth":1,"pos":Vector2(760,670),"hero":1},
	"ancients":{"name":"Voices of the Ancients","desc":"Epoch Lance and Ancestor Choir enter the upgrade pool.","cost":220,"depth":1,"pos":Vector2(-800,-620),"weapons":["spear","dread"]},
	"alchemy":{"name":"Ashen Alchemy","desc":"Walking Pyre and Black Bloom enter the upgrade pool.","cost":220,"depth":1,"pos":Vector2(920,-720),"weapons":["pyre","miasma"]},
	"fracture":{"name":"Fractured Time","desc":"Borrowed Seconds, Stolen Eternity and Violent Echo.","cost":300,"depth":1,"pos":Vector2(-700,860),"weapons":["stasis"],"augments":["eternity","echo"]},
	"myths":{"name":"Relics of the Impossible","desc":"Unlock Forked Prophecy, Grave Garden, Threefold Violence and Refusal.","cost":280,"depth":2,"pos":Vector2(810,-460),"relics":["branch","garden","cyclone","laststand"]},
	"chronicle":{"name":"The Last Chronicle","desc":"Unlock the ultra-rare Artifact relic in compatible chests.","cost":500,"depth":2,"pos":Vector2(-880,540),"relics":["chronicle"]},
	"prismwork":{"name":"Prismwork","desc":"Unlock Prism Skipper: crystal bolts ricochet between different enemies.","cost":220,"depth":1,"pos":Vector2(340,1100),"weapons":["ricochet"]},
	"sundial":{"name":"The Broken Sundial","desc":"Unlock Sun Chaser: thrown crescents return through the horde to you.","cost":280,"depth":2,"pos":Vector2(980,820),"weapons":["return"]}
}

static func migrate(save):
	if not save.has("discoveries"): save.discoveries = []
	if not save.has("recipes"): save.recipes = []
	if not save.has("unlocks"):
		save.unlocks = []
		# A catalog introduced after the original release must not revoke gear
		# from returning players. New discoveries remain earnable for everyone.
		if save.get("runs",0)>0:
			for key in ENTRIES:
				if key in ["mara","kael","ballistics","riftcraft","tracking","ancients","alchemy","fracture","myths","chronicle"]: save.unlocks.append(key)
		# Returning players keep the heroes recorded in their existing save.
		for record in save.get("records",[]):
			var key = "mara" if record.get("hero","")=="MARA VOSS" else "kael" if record.get("hero","")=="KAEL" else ""
			if key!="" and key not in save.unlocks: save.unlocks.append(key)
		for key in save.unlocks:
			if key not in save.discoveries: save.discoveries.append(key)

static func hero_open(save,index):
	return index==2 or ["mara","kael","", "iona","orin"][index] in save.get("unlocks",[])

static func allowed(save,category,id):
	if category=="weapons" and id in KITS[save.get("hero",2)]: return true
	for key in ENTRIES:
		if id in ENTRIES[key].get(category,[]): return key in save.get("unlocks",[])
	return true

static func purchase(save,id):
	if not ENTRIES.has(id) or id not in save.discoveries or id in save.unlocks: return false
	if save.amber<ENTRIES[id].cost: return false
	save.amber -= ENTRIES[id].cost
	save.unlocks.append(id)
	return true

static func landmarks(g):
	var out = []
	for id in ENTRIES:
		var d = ENTRIES[id]
		if d.get("discoverable",true) and d.depth==g.depth and d.get("map",g.map_id)==g.map_id:
			out.append({"id":id,"name":d.name,"p":g.terrain.open_position(d.pos),"found":id in g.discovered})
	return out
