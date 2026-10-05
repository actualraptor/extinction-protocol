extends RefCounted
const WEAPONS = ["revolver","club","frost","fire","lightning","shotgun","orbital","mortar","spear","pyre","winter","miasma","dread","aegis","stasis","thunderstorm","whiteout","supernova","lastword","earthshaker","bastion","ricochet","return","compass","tablet"]
const UPGRADES = ["luck","damage","haste","area","count","crit","armor","speed","pickup","regen","velocity","pierce","homing","bounce","reach","echo","conductor","fork","pulse","linger","ward","eternity","sorcery","winterbite","combustion"]
const RELICS = ["ember","storm","blood","glass","clock","magnet","frost","boots","crown","shell","volley","branch","cyclone","shatter","wildfire","garden","reaper","laststand","momentum","apex","flint","wrap","coil","lens","prism","chronicle","portal","chest","camp","meteor"]
const BOSSES = ["thorn","basalt","hunt","aurora","warden","bloom","meteor"]
const RESEARCH_ICONS = {
 "critical":["crit","passive"],"vitality":["wrap","relic"],"power":["damage","passive"],
 "fortune":["crown","relic"],"reroll":["echo","augment"],"luck":["luck","passive"],
 "projectiles":["volley","relic"],"chains":["conductor","augment"],"revive":["laststand","relic"],
 "greed":["ember","relic"],"growth":["lens","relic"],"magnet":["magnet","relic"],
 "armor":["armor","passive"],"recovery":["regen","passive"]}
static var cache = {}
static var missing = {}
static func field(index):
	if index<0 or index>3: return null
	return _clean("field-"+["thorns","urn","crate","stump"][index])
static func frontier(index):
	if index<0 or index>11: return null
	return _clean("frontier-"+str(index))

static func _clean(name):
	var path="res://assets/clean-icons/"+name+".png"
	if not cache.has(path): cache[path]=load(path)
	return cache[path]

static func _icon_name(id,category="weapon",halloween=false):
	if category in ["fusion","evolution"]: category="weapon"
	if category=="supplies":
		if id in ["supplies","lens"]: return "relics-lens"
		if id=="chest": return "relics-chest"
		if id=="amber": return "relics-ember"
		return ""
	if category=="research":
		if not RESEARCH_ICONS.has(id): return ""
		return _icon_name(RESEARCH_ICONS[id][0],RESEARCH_ICONS[id][1],halloween)
	if category=="boss":
		return "boss-"+("halloween-" if halloween else "")+id if id in BOSSES else ""
	if category=="discovery" and id in ["map_frost","map_observatory"]:
		return "frontier-"+str(8 if id=="map_frost" else 10)
	# Explicit backward-compatible map alias also fixes historic patch entries.
	if id=="map" and category in ["map","relic"]: return "weapons-compass"
	if category=="map" and id=="compass": return "weapons-compass"
	if id in ["thorns","thornking","spines","retribution"] and category in ["weapon","passive","augment"]: return "field-thorns"
	if category=="weapon" and id in ["harpoon","lantern","glacier","sunbow"]:
		return "frontier-"+str(["harpoon","lantern","glacier","sunbow"].find(id))
	if category=="relic": return "relics-"+id if id in RELICS else ""
	if category in ["passive","augment"]: return "upgrades-"+id if id in UPGRADES else ""
	if category=="weapon": return "weapons-"+id if id in WEAPONS else ""
	return ""

static func has_icon(id,category="weapon",halloween=false):
	if preload("res://scripts/content_extension.gd").data.get("icons",{}).has(id):return true
	var name=_icon_name(id,category,halloween)
	return not name.is_empty() and ResourceLoader.exists("res://assets/clean-icons/"+name+".png")


static func get_icon(id,category = "weapon",halloween = false):
	var extension=preload("res://scripts/content_extension.gd").icon(id)
	if extension!=null:return extension
	var name=_icon_name(id,category,halloween)
	if name.is_empty():
		var key=category+":"+id
		if not missing.has(key):
			missing[key]=true
			push_warning("Missing explicit icon mapping: "+key)
		return null
	return _clean(name)

static func control(parent,id,category = "weapon",size = 76):
	var icon = TextureRect.new()
	icon.texture = get_icon(id,category)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(size,size)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)
	return icon
