extends Node2D
var world
var corpse
var bounds=Rect2()
var clock=0.0
var shader_material:ShaderMaterial
var fallback_cloud:GradientTexture2D
const FOG="""
shader_type canvas_item;
render_mode unshaded;
uniform float clock=0.0;
uniform float strength=0.0;
uniform float impact=0.0;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
float clouds(vec2 p){return noise(p)*.55+noise(p*2.03)*.28+noise(p*4.1)*.12+noise(p*8.3)*.05;}
void fragment(){
 vec2 uv=UV;
 vec2 flow=vec2(uv.x*4.5,uv.y*3.6+clock*.34);
 vec2 warp=vec2(clouds(flow+vec2(clock*.08,0)),clouds(flow+vec2(4.3,-clock*.07)));
 float billow=clouds(flow+warp*2.1);
 float curl=clouds(flow*1.7+warp*3.0-vec2(clock*.12,0));
 float sides=1.0-smoothstep(.28,.50,abs(uv.x-.5));
 float ground=1.0-smoothstep(.77,1.0,uv.y);
 float top=smoothstep(.02,.30,uv.y);
 float column=sin(uv.y*3.14159);
 float alpha=smoothstep(.24,.67,billow*.78+curl*.22)*sides*ground*top*strength;
 vec3 dark=vec3(.07,.23,.17);vec3 light=vec3(.34,.68,.49);
 vec3 tint=mix(dark,light,smoothstep(.28,.78,billow));
 tint+=vec3(.12,.36,.20)*pow(curl,4.0)*column;
 tint=mix(tint,vec3(.70,.94,.78),impact*.65);
 COLOR=vec4(tint,min(.92,alpha*.88+impact*sides*ground*top*.38)*texture(TEXTURE,UV).a);
}
"""
func _ready():
	var gradient=Gradient.new()
	gradient.colors=PackedColorArray([Color(.2,.55,.38,.7),Color(.2,.55,.38,0)])
	fallback_cloud=GradientTexture2D.new()
	fallback_cloud.gradient=gradient
	fallback_cloud.fill=GradientTexture2D.FILL_RADIAL
	fallback_cloud.fill_from=Vector2(.5,.5)
	fallback_cloud.fill_to=Vector2(1,.5)
	fallback_cloud.width=256;fallback_cloud.height=256
	var shader=Shader.new();shader.code=FOG
	shader_material=ShaderMaterial.new();shader_material.shader=shader
	# Fog has its own canvas item; parchment is drawn on a separate child above it.
	material=shader_material

func _process(_dt):
	corpse=null
	if world.sim!=null:
		for c in world.sim.boss_corpses:
			if c.raising and not c.consumed:corpse=c;break
	visible=corpse!=null
	if not visible:return
	clock=corpse.ritual
	var t=clampf(clock/preload("res://scripts/rite_animation.gd").DURATION,0,1)
	var art=preload("res://scripts/remnant_system.gd").corpse_art(corpse.identity)
	var dimensions=art.get_size()/art.get_width()*corpse.size*3.2
	var extent=Vector2(maxf(650,dimensions.x*1.95),maxf(380,dimensions.y*1.8))
	extent.y*=lerpf(.28,1.0,smoothstep(1.7,5.5,clock))
	var p=world.screen(corpse.p)
	bounds=Rect2(p-Vector2(extent.x*.5,extent.y*.64),extent)
	shader_material.set_shader_parameter("clock",clock)
	var snap_age=clock-preload("res://scripts/rite_animation.gd").split_time(0)
	shader_material.set_shader_parameter("impact",exp(-snap_age*35) if snap_age>=0 and snap_age<.18 else 0.0)
	shader_material.set_shader_parameter("strength",smoothstep(0,.9,clock)*lerpf(.20,1.0,smoothstep(2.5,7.5,clock))*lerpf(1.0,.32,smoothstep(8.0,10.0,clock))*(1-smoothstep(.77,.99,t)))
	queue_redraw()
func _draw():
	if corpse!=null and fallback_cloud!=null:draw_texture_rect(fallback_cloud,bounds,false)
