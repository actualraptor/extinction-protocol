extends RefCounted
## Alternate painted art is opt-in per run. Never mutates the original atlases.
const ACCESSORIES = preload("res://assets/hollow-harvest-accessories.png")
const CREATURES = preload("res://assets/hollow-harvest-creatures.png")
const MONSTERS = preload("res://assets/hollow-harvest-monsters.png")
const FRONTIERS = preload("res://assets/hollow-harvest-frontiers.png")
static var cached_regions: Dictionary = {}

static func texture_for(group: int):
	return [CREATURES, MONSTERS, FRONTIERS][clampi(group, 0, 2)]

static func regions_for(group: int):
	if cached_regions.has(group): return cached_regions[group]
	var texture = texture_for(group)
	var image = texture.get_image()
	var columns = 4 if group == 2 else 3
	var rows = 3
	var cell = Vector2i(image.get_width()/columns, image.get_height()/rows)
	var regions = []
	for index in range(4 if group == 2 else 9):
		var x = index%columns
		var y = 1 if group == 2 else index/columns
		var box = Rect2i(Vector2i(x,y)*cell,cell)
		var used = image.get_region(box).get_used_rect()
		# Base atlas intentionally retains padding so themed creatures have the
		# same physical footprint as their non-seasonal counterparts.
		regions.append(Rect2(box) if group == 0 else Rect2(box.position+used.position,used.size))
	cached_regions[group] = regions
	return regions

static func accessory(index: int):
	# Hand-authored regions respect the wide hat brims rather than clipping to grid cells.
	var bounds = [Rect2(0,0,541,437),Rect2(541,0,505,437),Rect2(1046,0,490,437),Rect2(0,440,541,584),Rect2(541,440,598,584),Rect2(1139,440,397,584)]
	var result = AtlasTexture.new()
	result.atlas = ACCESSORIES
	result.region = bounds[clampi(index,0,5)]
	return result

static func draw_survivor(target, hero: int, row: int, dimensions: Vector2, tint: Color):
	if hero == 2:
		var hat = accessory(row)
		var width = 31.0 if row != 1 else 29.0
		target.draw_texture_rect(hat,Rect2(Vector2(-width*0.5,-dimensions.y-10),Vector2(width,25)),false,tint)
	elif hero == 1:
		# Replace the stone head at the end of Kael's existing animated handle.
		var source = Rect2(285,445,249,267)
		var at = Vector2(-dimensions.x*0.33,-dimensions.y*0.19)
		if row == 1: at = Vector2(dimensions.x*0.05,-dimensions.y*0.07)
		if row == 2: at = Vector2(dimensions.x*0.31,-dimensions.y*0.32)
		target.draw_texture_rect_region(ACCESSORIES,Rect2(at-Vector2(8,9),Vector2(17,19)),source,tint)

static func draw_prop(target, at: Vector2, index: int, width: float, time: float):
	var art = accessory(4+index%2)
	var dimensions = Vector2(width,width*art.get_height()/art.get_width())
	var shimmer = 0.95+sin(time*3.0+at.x*0.02)*0.05
	target.draw_texture_rect(art,Rect2(at-Vector2(dimensions.x*0.5,dimensions.y*0.82),dimensions),false,Color(shimmer,shimmer,shimmer))
