extends MultiMeshInstance2D
## One draw batch for regular creatures. Elites and bosses retain their
## individual health bars and authored encounter presentation in World.
var world
var extra = false
var frontier = false
var seasonal_active = false
var seasonal_regions = []
var buffer = PackedFloat32Array()
const CAPACITY = 2400
func _ready():
	texture = world.frontier_sheet if frontier else world.monster_sheet if extra else world.atlas
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.use_colors = true
	multimesh.use_custom_data = true
	var quad = QuadMesh.new()
	quad.size = Vector2.ONE
	multimesh.mesh = quad
	multimesh.instance_count = CAPACITY
	multimesh.visible_instance_count = 0
	buffer.resize(CAPACITY*16)
	var shader = ShaderMaterial.new()
	shader.shader = preload("res://shaders/swarm.gdshader")
	if extra or frontier:
		shader.set_shader_parameter("custom_regions",true)
		var regions = PackedVector4Array()
		for r in (world.frontier_regions if frontier else world.monster_regions):
			regions.append(Vector4(r.position.x/texture.get_width(),r.position.y/texture.get_height(),r.size.x/texture.get_width(),r.size.y/texture.get_height()))
		while regions.size()<9: regions.append(Vector4.ZERO)
		shader.set_shader_parameter("regions",regions)
	material = shader

func _apply_seasonal(enabled: bool):
	seasonal_active = enabled
	if enabled:
		var theme = preload("res://scripts/seasonal_theme.gd")
		var group = 2 if frontier else 1 if extra else 0
		texture = theme.texture_for(group)
		seasonal_regions = theme.regions_for(group)
	else:
		texture = world.frontier_sheet if frontier else world.monster_sheet if extra else world.atlas
	material.set_shader_parameter("custom_regions",enabled or extra or frontier)
	if enabled or extra or frontier:
		var regions = PackedVector4Array()
		var source = seasonal_regions if enabled else world.frontier_regions if frontier else world.monster_regions
		for r in source:
			regions.append(Vector4(r.position.x/texture.get_width(),r.position.y/texture.get_height(),r.size.x/texture.get_width(),r.size.y/texture.get_height()))
		while regions.size()<9: regions.append(Vector4.ZERO)
		material.set_shader_parameter("regions",regions)

func _process(dt):
	var s = world.sim
	if s==null:
		multimesh.visible_instance_count = 0
		return
	if seasonal_active != s.halloween: _apply_seasonal(s.halloween)
	var count = 0
	var frozen = s.buffs.get("freeze",0)>0
	for e in s.enemies:
		if e.dead or e.boss or e.anchor or e.elite or e.get("breakable",false) or e.get("boss_prop",false): continue
		if frontier:
			if e.kind<14: continue
		elif e.kind>=14 or (e.kind>=5)!=extra: continue
		e.render_p = e.get("render_p",e.p).lerp(e.p,1-exp(-dt*35)) if not s.rooted(e) else e.p
		var p = world.screen(e.render_p)
		if not world.visible_rect().grow(100).has_point(p): continue
		if count>=CAPACITY: break
		var size_value = e.size*3
		var index = e.kind-14 if frontier else e.kind-5 if extra else 3+e.kind
		var aspect = Vector2.ONE
		if extra or frontier or seasonal_active:
			var dimensions = (seasonal_regions if seasonal_active else world.frontier_regions if frontier else world.monster_regions)[index].size
			aspect = dimensions/maxf(dimensions.x,dimensions.y)
		var tint = Color(1.8,1.8,1.8) if e.flash>0 else Color("a2c3ff") if frozen or e.slow>0 or e.get("frozen",0)>0 else Color("eabcff") if e.mutated else Color.WHITE
		var offset = count*16
		# 2D transform is two rows of four floats, then RGBA and custom RGBA.
		buffer[offset] = (-size_value if e.p.x>s.pos.x else size_value)*aspect.x
		buffer[offset+1] = 0
		buffer[offset+2] = 0
		buffer[offset+3] = p.x
		buffer[offset+4] = 0
		buffer[offset+5] = size_value*aspect.y
		buffer[offset+6] = 0
		buffer[offset+7] = p.y-size_value*0.25
		buffer[offset+8] = tint.r
		buffer[offset+9] = tint.g
		buffer[offset+10] = tint.b
		buffer[offset+11] = 1
		buffer[offset+12] = index%3
		buffer[offset+13] = floorf(index/3.0)
		buffer[offset+14] = float(e.uid%100)*0.17
		buffer[offset+15] = 0.0 if frozen or e.get("frozen",0)>0 else 1.0
		count += 1
	multimesh.buffer = buffer
	multimesh.visible_instance_count = count
