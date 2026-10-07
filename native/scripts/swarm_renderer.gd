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
	texture = preload("res://scripts/dinosaur_art.gd").SHEET
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
	material = shader

func _apply_seasonal(enabled: bool):
	seasonal_active=enabled

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
		var size_value=e.size*4.0*e.get("visual_scale",1.0)
		var index=e.kind
		var aspect=Vector2(1,.75)
		var tint = Color(1.8,1.8,1.8) if e.flash>0 else Color("a2c3ff") if frozen or e.slow>0 or e.get("frozen",0)>0 else Color("eabcff") if e.mutated else Color.WHITE
		tint*=e.get("visual_tint",Color.WHITE)
		var offset = count*16
		# 2D transform is two rows of four floats, then RGBA and custom RGBA.
		buffer[offset] = (-size_value if e.get("motion",Vector2.RIGHT).x<-.01 else size_value)*aspect.x
		buffer[offset+1] = 0
		buffer[offset+2] = 0
		buffer[offset+3] = p.x
		buffer[offset+4] = 0
		buffer[offset+5] = size_value*aspect.y
		buffer[offset+6] = 0
		buffer[offset+7] = p.y-size_value*0.345
		buffer[offset+8] = tint.r
		buffer[offset+9] = tint.g
		buffer[offset+10] = tint.b
		buffer[offset+11] = 1
		buffer[offset+12] = index
		buffer[offset+13] = preload("res://scripts/dinosaur_art.gd").frame(e,world.clock,frozen)
		buffer[offset+14] = float(e.uid%100)*0.17
		buffer[offset+15] = 0.0 if frozen or e.get("frozen",0)>0 else 1.0
		count += 1
	multimesh.buffer = buffer
	multimesh.visible_instance_count = count
