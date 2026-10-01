extends RefCounted
const WEAPONS = ["revolver","club","frost","fire","lightning","shotgun","orbital","mortar","spear","pyre","winter","miasma","dread","aegis","stasis","thunderstorm","whiteout","supernova","lastword","earthshaker","bastion","ricochet","return","compass","tablet"]
const UPGRADES = ["luck","damage","haste","area","count","crit","armor","speed","pickup","regen","velocity","pierce","homing","bounce","reach","echo","conductor","fork","pulse","linger","ward","eternity","sorcery","winterbite","combustion"]
const RELICS = ["ember","storm","blood","glass","clock","magnet","frost","boots","crown","shell","volley","branch","cyclone","shatter","wildfire","garden","reaper","laststand","momentum","apex","flint","wrap","coil","lens","prism","chronicle","portal","chest","camp","meteor"]
static var cache = {}
static func field(index):
	var t=AtlasTexture.new();t.atlas=preload("res://assets/thorns-breakables-08.png")
	var cell=Vector2(t.atlas.get_size())/2
	t.region=Rect2(Vector2(index%2,floori(index/2.0))*cell,cell)
	return t
static func frontier(index):
	var atlas = preload("res://assets/frontiers-07.png")
	var region = AtlasTexture.new()
	region.atlas=atlas
	var cell=Vector2(atlas.get_size())/Vector2(4,3)
	region.region=Rect2(Vector2(index%4,floori(index/4.0))*cell,cell)
	return region


static func get_icon(id,category = "weapon"):
	var key = category+":"+id
	if cache.has(key): return cache[key]
	if id in ["thorns","thornking","spines","retribution"]: return field(0)
	if id in ["harpoon","lantern","glacier","sunbow"]:
		cache[key]=frontier(["harpoon","lantern","glacier","sunbow"].find(id))
		return cache[key]
	var list = RELICS if category=="relic" else UPGRADES if category in ["passive","augment"] else WEAPONS
	var index = list.find(id)
	if index<0: index = list.find("tablet") if list==WEAPONS else 0
	var name = "relics" if category=="relic" else "upgrades" if category in ["passive","augment"] else "weapons"
	var atlas = load("res://assets/icons-"+name+"-06.png")
	var cols = 6 if name=="relics" else 5
	var size = Vector2(atlas.get_size())/Vector2(cols,5)
	var texture = AtlasTexture.new()
	texture.atlas = atlas
	texture.region = Rect2(Vector2(index%cols,floori(float(index)/cols))*size+Vector2.ONE*2,size-Vector2.ONE*4)
	cache[key] = texture
	return texture

static func control(parent,id,category = "weapon",size = 76):
	var icon = TextureRect.new()
	icon.texture = get_icon(id,category)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(size,size)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)
	return icon
