extends Control
## Optional seasonal menu backdrop. No progression or gameplay state changes.
const BACKDROP="res://assets/hollow-harvest-menu-v1.png"
const ATMOSPHERE="""
shader_type canvas_item;
render_mode unshaded;
void fragment() {
 float phase=mod(TIME,24.0)*0.261799;
 vec4 art=texture(TEXTURE,UV);
 // Candlelight belongs to the painted heart and lanterns, not menu labels.
 float pulse=0.78+sin(phase*10.0)*0.10+sin(phase*26.0)*0.045;
 float heart=exp(-length((UV-vec2(0.73,0.39))*vec2(12.0,15.0)));
 art.rgb+=vec3(0.24,0.095,0.028)*heart*pulse;
 float lantern=exp(-length((UV-vec2(0.69,0.77))*vec2(22.0,28.0)))+exp(-length((UV-vec2(0.85,0.70))*vec2(25.0,30.0)));
 art.rgb+=vec3(0.28,0.11,0.025)*lantern*pulse;
 // Two soft mist layers move independently and meet seamlessly every 24 seconds.
 float fog_a=sin(UV.x*19.0+phase+sin(UV.y*9.0-phase)*1.4);
 float fog_b=sin(UV.x*11.0-phase*2.0+sin(UV.y*17.0+phase)*0.9);
 float fog=smoothstep(0.15,0.95,fog_a*0.55+fog_b*0.45);
 float ground_mist=smoothstep(0.30,0.85,UV.y)*smoothstep(0.35,0.75,UV.x);
 art.rgb=mix(art.rgb,vec3(0.29,0.34,0.38),fog*ground_mist*0.12);
 // Slow wisps of ambient ash float through the illustration's right half.
 for (int i=0;i<18;i++) {
  float seed=float(i);
  float x=0.56+fract(sin(seed*17.43+2.0)*431.6)*0.40;
  float y=fract(sin(seed*12.63)*61.2-mod(TIME,24.0)/24.0);
  x+=sin(phase*3.0+seed*1.9)*0.009;
  float d=length((UV-vec2(x,y))*vec2(1.6,1.0));
  float spark=exp(-d*1800.0)*(0.3+0.2*sin(phase*8.0+seed));
  art.rgb+=vec3(1.0,0.40,0.08)*spark;
 }
 COLOR=art;
}
"""

static func create(parent):
 var backdrop=load("res://scripts/seasonal_menu.gd").new()
 backdrop.name="HollowHarvestBackdrop"
 backdrop.set_meta("fullscreen_background",true)
 backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE
 backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 parent.add_child(backdrop)
 parent.move_child(backdrop,0)
 return backdrop

func _ready():
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 var art=TextureRect.new()
 art.name="PaintedHauntedJungle"
 art.texture=load(BACKDROP)
 art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 art.mouse_filter=Control.MOUSE_FILTER_IGNORE
 art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var shader=Shader.new()
 shader.code=ATMOSPHERE
 var material_value=ShaderMaterial.new()
 material_value.shader=shader
 art.material=material_value
 add_child(art)
 # A feathered shading veil preserves title/control contrast on wide screens.
 var gradient=Gradient.new()
 gradient.set_color(0,Color(0.015,0.020,0.035,0.40))
 gradient.set_color(1,Color(0.015,0.020,0.035,0))
 gradient.add_point(0.45,Color(0.015,0.020,0.035,0.17))
 var shade_texture=GradientTexture2D.new()
 shade_texture.gradient=gradient
 shade_texture.fill_from=Vector2.ZERO
 shade_texture.fill_to=Vector2(0.62,0)
 var veil=TextureRect.new()
 veil.name="MenuReadabilityVeil"
 veil.texture=shade_texture
 veil.mouse_filter=Control.MOUSE_FILTER_IGNORE
 veil.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(veil)
