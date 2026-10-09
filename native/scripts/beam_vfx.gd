extends MeshInstance2D
var beam
var world
var shader_material
func _ready():
 shader_material=ShaderMaterial.new();shader_material.shader=preload("res://shaders/beam_flow.gdshader");material=shader_material
func refresh():
 var s=beam.stats;var t=beam.age
 var flame=beam.id=="flametorch"
 var points=beam.get("path",PackedVector2Array([world.sim.pos,world.sim.pos+beam.aim])) if flame else PackedVector2Array([world.sim.pos,world.sim.pos+(beam.target.p-world.sim.pos).limit_length(s.range)])
 var vertices=PackedVector3Array();var uvs=PackedVector2Array();var indices=PackedInt32Array()
 position=world.screen(world.sim.pos)+Vector2(0,-30)
 for i in range(points.size()):
  var tangent=points[mini(i+1,points.size()-1)]-points[maxi(0,i-1)]
  if tangent.length_squared()<.001:tangent=beam.aim
  var side=tangent.normalized().orthogonal()*s.width*(1.1 if flame else 1.0)
  var center=points[i]-world.sim.pos
  vertices.append(Vector3(center.x-side.x,center.y-side.y,0));vertices.append(Vector3(center.x+side.x,center.y+side.y,0))
  var u=float(i)/(points.size()-1)
  uvs.append(Vector2(u,0));uvs.append(Vector2(u,1))
  if i>0:
   var k=i*2;indices.append_array(PackedInt32Array([k-2,k-1,k,k-1,k+1,k]))
 var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_TEX_UV]=uvs;arrays[Mesh.ARRAY_INDEX]=indices
 var strip=ArrayMesh.new();strip.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);mesh=strip
 shader_material.set_shader_parameter("age",t)
 shader_material.set_shader_parameter("seed",beam.seed)
 shader_material.set_shader_parameter("mode",0 if flame else 2)
 shader_material.set_shader_parameter("envelope",minf(1,t/.1)*minf(1,(beam.life-t)/.15))
