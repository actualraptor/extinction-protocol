extends Node2D
var world
var shader_material = ShaderMaterial.new()
var stage_key = ""
func _ready():
	shader_material.shader = preload("res://shaders/continuous_ground.gdshader")
	material = shader_material
func _process(_dt): queue_redraw()
func _draw():
	var sim = world.sim
	var view = get_viewport_rect().size
	var center = world.camera_pos if sim!=null else Vector2(world.clock*7,0)
	shader_material.set_shader_parameter("viewport_size",view)
	shader_material.set_shader_parameter("world_origin",center-Vector2(720,465)-world.camera_offset-world.position)
	var biome = sim.Maps.biome(sim.map_id,sim.depth) if sim!=null else world.C.BIOMES[0]
	shader_material.set_shader_parameter("ground_color",Color(biome.ground))
	var key = sim.map_id+str(sim.depth)+str(sim.terrain.seed_value) if sim!=null else "menu"
	if key!=stage_key:
		stage_key = key
		var frontier = sim!=null and sim.map_id!="cradle"
		shader_material.set_shader_parameter("ground_tex",world.frontier_ground if frontier else preload("res://assets/dinosaurs/grasslands-ground.png") if sim!=null else world.terrain)
		var index = sim.depth+(3 if sim.map_id=="observatory" else 0) if frontier else 0
		shader_material.set_shader_parameter("atlas_region",Vector4((index%3)/3.0,floori(index/3.0)/2.0,1.0/3,0.5) if frontier else Vector4(0,0,1,1))
		var locations = PackedVector4Array()
		var colors = PackedVector4Array()
		var regions = sim.terrain.stage.get("regions",[]) if sim!=null else []
		for i in range(16):
			var r = regions[i] if i<regions.size() else {}
			var p = r.get("p",Vector2.ZERO)
			locations.append(Vector4(p.x,p.y,r.get("radius",1.0),0))
			var color = Color(r.get("color",biome.ground))
			colors.append(Vector4(color.r,color.g,color.b,1))
		shader_material.set_shader_parameter("region_count",mini(16,regions.size()))
		shader_material.set_shader_parameter("regions",locations)
		shader_material.set_shader_parameter("region_colors",colors)
	draw_rect(Rect2(-world.position,view),Color.WHITE)
