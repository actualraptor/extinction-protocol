extends RefCounted

const HEROES = [
	{"name":"MARA VOSS", "title":"THE GUNSLINGER", "weapon":"revolver", "hp":110.0, "speed":250.0, "armor":1.0, "crit":0.16, "color":"edb968", "desc":"Six shots between you and extinction.\n+16% critical chance. +1 projectile every 10 levels (max 3)."},
	{"name":"KAEL", "title":"THE FIRST HUNTER", "weapon":"club", "hp":170.0, "speed":220.0, "armor":4.0, "crit":0.05, "color":"ec8962", "desc":"A Neanderthal who refuses to disappear.\n+1% physical damage per level (max 50%). Armor strengthens Ironbriar."},
	{"name":"VESPER", "title":"THE RIFTWALKER", "weapon":"lightning", "hp":85.0, "speed":245.0, "armor":0.0, "crit":0.08, "color":"97a9ff", "desc":"The collision of eras woke something ancient.\nStormbinder. +20% spell damage, +1% per level (max +40%)."},
	{"name":"IONA", "title":"THE POLAR HUNTER", "weapon":"harpoon", "hp":115.0, "speed":265.0, "armor":2.0, "crit":0.12, "color":"99e7ee", "desc":"Hunts through ice and time.\n+20% ice damage. +0.5% speed per level (max 15%)."},
	{"name":"ORIN", "title":"THE LOST ASTRONOMER", "weapon":"lantern", "hp":100.0, "speed":235.0, "armor":1.0, "crit":0.10, "color":"d4abff", "desc":"Brings a lantern to the end of the universe.\n+20% arcane damage. +0.5% arcane speed per level (max 20%)."}
]
const BASE_WEAPONS = {
	"revolver":{"name":"Graveshot", "desc":"Piercing rounds seek the nearest threat.", "color":"ffd78c", "damage":28.0,"cooldown":0.65,"evolution":"SIX FEET UNDER","requires":"crit"},
	"club":{"name":"Ancestor's Wrath", "desc":"A heavy circular cleave knocks back nearby foes.", "color":"ffbd84","damage":52.0,"cooldown":1.5,"evolution":"WORLD BREAKER","requires":"armor"},
	"frost":{"name":"Winterglass", "desc":"Ice lances slow foes; three hits freeze. Fire detonates frozen prey.","color":"83e6ff","damage":21.0,"cooldown":0.85,"evolution":"ABSOLUTE ZERO","requires":"area"},
	"fire":{"name":"Cinder Gospel", "desc":"Explosive fireballs burn tightly packed enemies.","color":"ff9562","damage":38.0,"cooldown":1.3,"evolution":"SUN EATER","requires":"damage"},
	"lightning":{"name":"Stormbinder", "desc":"Lightning jumps between nearby enemies.","color":"c9a6ff","damage":31.0,"cooldown":1.5,"evolution":"THUNDER GOD","requires":"haste"},
	"shotgun":{"name":"Bone Rattler", "desc":"A brutal fan of short-range pellets.","color":"ffe7ae","damage":17.0,"cooldown":1.4,"evolution":"DOOM CHOIR","requires":"count"},
	"orbital":{"name":"Rift Blades", "desc":"Orbiting blades carve a path through the horde.","color":"73ffcb","damage":22.0,"cooldown":0.6,"evolution":"EVENT HORIZON","requires":"speed"},
	"mortar":{"name":"Extinction Mortar", "desc":"Calls delayed bombardments on clustered enemies.","color":"ff727a","damage":90.0,"cooldown":3.8,"evolution":"HEAVEN FALLS","requires":"pickup"}
}
const BASE_PASSIVES = {
	"luck":{"name":"Fortune's Favor","desc":"+10% Luck (+2 points to rarity rolls). Luck stacks additively; rolls above 100 are Artifact.","max":5},
	"damage":{"name":"Brutality","desc":"+14% damage", "max":5},
	"haste":{"name":"Overclock","desc":"+10% attack speed", "max":5},
	"area":{"name":"Cataclysm","desc":"+12% area radius", "max":5},
	"count":{"name":"Double Down","desc":"+1 projectile / chain target", "max":3},
	"crit":{"name":"Deadeye","desc":"+7% critical chance. Every 100% adds a guaranteed crit tier.", "max":60},
	"armor":{"name":"Iron Will","desc":"+2 armor and +12 maximum health", "max":5},
	"speed":{"name":"Afterimage","desc":"+8% movement speed", "max":5},
	"pickup":{"name":"Gravitation","desc":"+35 pickup radius and +8% XP", "max":5},
	"regen":{"name":"Second Wind","desc":"Regenerate 0.35 health / second", "max":5}
}
const BASE_RELICS = {
	"ember":{"name":"Phoenix Ash","desc":"Every 18 kills ignites a nearby explosion.","color":"ff8e69"},
	"storm":{"name":"Bottled Thunder","desc":"Critical hits arc to a second target. 0.6s cooldown.","color":"c1adff"},
	"blood":{"name":"Blood Chalice","desc":"Every 30 kills restores 4 health. Maximum once every 2 seconds.","color":"ff7790"},
	"glass":{"name":"Glass Covenant","desc":"+30% damage. Take 20% more damage.","color":"83dfea"},
	"clock":{"name":"Broken Hourglass","desc":"Negate one hit every 25 seconds.","color":"efd8a4"},
	"magnet":{"name":"Singularity Seed","desc":"Vacuum nearby XP every 18 seconds.","color":"85ffd2"},
	"frost":{"name":"Winter's Heart","desc":"Frozen enemies take 25% more damage.","color":"a6eeff"},
	"boots":{"name":"Comet Treads","desc":"Moving for 4 seconds drops an explosive wake.","color":"ffb670"},
	"crown":{"name":"King of Nothing","desc":"+20% score and XP. Hordes gain 15% health.","color":"e8c77d"},
	"shell":{"name":"Titan Fragment","desc":"+35 maximum health and +2 armor.","color":"c1bbb5"}
}
const BIOMES = [
	{"name":"THE LOST CRADLE", "tag":"01 / THE WORLD BEFORE", "ground":"152b2d", "accent":"83b998"},
	{"name":"THE ASHEN RIFT", "tag":"02 / A WORLD ON FIRE", "ground":"30212c", "accent":"e88767"},
	{"name":"THE STAR GRAVE", "tag":"03 / THE END OF EVERYTHING", "ground":"1b243b", "accent":"8da8ef"}
]
const Rules = preload("res://scripts/combat_rules.gd")
static var WEAPONS = Rules.weapon_data(BASE_WEAPONS)
static var PASSIVES = Rules.passive_data(BASE_PASSIVES)
static var RELICS = preload("res://scripts/relic_system.gd").definitions(BASE_RELICS)
const AUGMENTS = Rules.AUGMENTS
const RESEARCH = {
	"critical":{"name":"Hunter's Eye","desc":"+2% critical chance / rank. Stacks above 100%.","cost":200,"max":10},
	"vitality":{"name":"Survivor's Blood", "desc":"+10 starting health / rank", "cost":70,"max":5},
	"power":{"name":"Forbidden Knowledge", "desc":"+3% starting damage / rank", "cost":100,"max":5},
	"fortune":{"name":"Scavenger's Legacy", "desc":"+5% amber and luck / rank", "cost":80,"max":5},
	"reroll":{"name":"Second Thoughts","desc":"+1 starting reroll / rank","cost":180,"max":5},
	"luck":{"name":"Lucky Fossil","desc":"+1% luck / rank","cost":120,"max":10},
	"projectiles":{"name":"Full Magazine","desc":"+1 projectile / rank","cost":1800,"max":2},
	"chains":{"name":"Storm Memory","desc":"+1 chain target / rank","cost":2000,"max":2},
	"revive":{"name":"Refuse Extinction","desc":"One revival at 50% health per run","cost":3000,"max":1},
	"greed":{"name":"Amber Prospector","desc":"+5% amber earned / rank","cost":100,"max":8},
	"growth":{"name":"Ancient Insight","desc":"+3% XP earned / rank","cost":120,"max":8},
	"magnet":{"name":"Gathering Instinct","desc":"+12 XP pickup radius / rank","cost":90,"max":8},
	"armor":{"name":"Fossil Plating","desc":"+1 armor / rank","cost":220,"max":3},
	"recovery":{"name":"Living History","desc":"+0.15 health per second / rank","cost":240,"max":4}
}
