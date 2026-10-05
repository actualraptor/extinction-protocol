extends RefCounted

static var data = {}
static var registered = false
static var textures = {}
const PROFILE = "07"
const FLAG = "route_07"

static func install(catalog):
	if registered: return
	if not ProjectSettings.load_resource_pack("res://assets/blocks/04.bin"): return
	if FileAccess.file_exists("res://assets/blocks/05.bin"):ProjectSettings.load_resource_pack("res://assets/blocks/05.bin")
	if FileAccess.file_exists("res://assets/blocks/06.bin"):ProjectSettings.load_resource_pack("res://assets/blocks/06.bin")
	data = JSON.parse_string(FileAccess.get_file_as_string("res://payload/007.dat"))
	if not data is Dictionary: data = {}; return
	catalog.HEROES.append(data.hero)
	catalog.WEAPONS.merge(data.weapons)
	catalog.PASSIVES.merge(data.passives)
	catalog.RELICS.merge(data.relics)
	preload("res://scripts/relic_system.gd").definitions_cache.merge(data.relics)
	registered = true

static func is_profile(g):
	return g.C.HEROES[g.hero].get("profile","") == PROFILE

static func visible(save):
	return save.get("campaign",{}).get(FLAG,false)

static func eligible_finish(g):
	return g.won and g.finale_defeated and g.hero == 1 and g.mode == "expedition" and g.boss_stage == 3

static func allowed(g,category,id):
	var table = g.C.WEAPONS if category == "weapons" else g.C.PASSIVES if category == "passives" else g.C.RELICS if category == "relics" else g.C.AUGMENTS
	var exclusive = table.get(id,{}).get("profile","")
	if exclusive != "": return exclusive == g.C.HEROES[g.hero].get("profile","")
	if not is_profile(g): return true
	return category in ["passives","augments","relics"]

static func icon(id):
	if not data.get("icons",{}).has(id): return null
	if not textures.has(id):
		var im = Image.new()
		if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://payload/%02d.dat"%int(data.icons[id]))) != OK: return null
		textures[id] = ImageTexture.create_from_image(im)
	return textures[id]

static func sprite(index):
	var key="sprite_%s"%index
	if textures.has(key):return textures[key]
	if not textures.has("atlas"):
		var im=Image.new()
		if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://payload/036.dat"))!=OK:return null
		textures.atlas=ImageTexture.create_from_image(im)
	var region=AtlasTexture.new()
	region.atlas=textures.atlas
	region.region=Rect2((index%3)*512,(index/3)*512,512,512)
	textures[key]=region
	return region

static func voice(event,index):
	var path="res://payload/voices/%s_%s.dat"%[event,index]
	if not FileAccess.file_exists(path):return null
	var stream=AudioStreamMP3.new()
	stream.data=FileAccess.get_file_as_bytes(path)
	return stream

static func milestone_icon(index):
	var key="milestone_%s"%index
	if not textures.has(key):
		var im=Image.new()
		if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://payload/%02d.dat"%(10+index)))!=OK:return null
		textures[key]=ImageTexture.create_from_image(im)
	return textures[key]

static func owner_pose(index):
	if not FileAccess.file_exists("res://payload/037.dat"):return sprite(0)
	var key="owner_%s"%index
	if textures.has(key):return textures[key]
	if not textures.has("owner_atlas"):
		var im=Image.new()
		if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://payload/037.dat"))!=OK:return sprite(0)
		textures.owner_atlas=ImageTexture.create_from_image(im)
	var atlas=textures.owner_atlas
	var cell=Vector2(atlas.get_width()/4.0,atlas.get_height()/2.0)
	var texture=AtlasTexture.new()
	texture.atlas=atlas
	texture.region=Rect2(Vector2(index%4,int(index/4))*cell,cell)
	textures[key]=texture
	return texture

static func unit_pose(unit,frame):
	var key="unit_%s_%s"%[unit,frame]
	if textures.has(key):return textures[key]
	var source="unit_sheet_%s"%unit
	if not textures.has(source):
		var path="res://payload/%03d.dat"%(38+unit)
		if not FileAccess.file_exists(path):return sprite(unit+1)
		var im=Image.new()
		if im.load_png_from_buffer(FileAccess.get_file_as_bytes(path))!=OK:return sprite(unit+1)
		textures[source]=ImageTexture.create_from_image(im)
		var cell_size=Vector2(im.get_width()/4.0,im.get_height()/2.0)
		var metrics=data.motion_layouts[unit]
		var factor=64.0/maxf(1,metrics.height)
		textures[source+"_layout"]={"size":cell_size*factor,"base":[metrics.base[0]*factor,metrics.base[1]*factor]}

	var atlas=textures[source]
	var cell=Vector2(atlas.get_width()/4.0,atlas.get_height()/2.0)
	var texture=AtlasTexture.new()
	texture.atlas=atlas
	var bounds=data.get("motion_regions",[])[unit][frame]
	texture.region=Rect2(bounds[0],bounds[1],bounds[2],bounds[3])
	textures[key]=texture
	return texture

static func unit_layout(unit,frame):
	var key="unit_sheet_%s_layout"%unit
	if not textures.has(key):return Rect2(-38,-68,76,76)
	var layout=textures[key]
	var bounds=data.motion_regions[unit][frame]
	var cell_width=textures["unit_sheet_%s"%unit].get_width()/4.0
	var factor=layout.size.x/cell_width
	var left=(bounds[0]-(frame%4+.5)*cell_width)*factor
	return Rect2(Vector2(left,-layout.base[int(frame/4)]),Vector2(bounds[2]*factor,layout.size.y))
