extends Control
var world
var audio
var elapsed=0.0
var origin=Vector2.ZERO
var detonated=false
var caption
var curtain
func _ready():
	mouse_filter=Control.MOUSE_FILTER_STOP
	origin=world.screen(world.sim.boss.p) if world.sim.boss!=null else get_viewport_rect().size*0.5
	curtain=ColorRect.new();curtain.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var shader=ShaderMaterial.new();shader.shader=preload("res://shaders/extinction_end.gdshader");curtain.material=shader
	add_child(curtain)
	caption=Label.new();caption.text="THE LAST LIGHT GOES OUT";caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_color_override("font_color",Color("bfa68a"));add_child(caption)
	audio.music_duck=6.0
	audio.play("boss",-9,0.65)
func _process(dt):
	elapsed+=dt
	size=get_viewport_rect().size
	curtain.size=size
	caption.position=Vector2(0,size.y*0.46);caption.size=Vector2(size.x,60)
	caption.add_theme_font_size_override("font_size",int(clampf(size.y*0.025,18,34)))
	caption.modulate.a=clampf((elapsed-3.5)*2,0,1)
	curtain.material.set_shader_parameter("elapsed",elapsed)
	curtain.material.set_shader_parameter("origin",origin/size)
	curtain.material.set_shader_parameter("viewport_size",size)
	if elapsed>=0.9 and not detonated:
		detonated=true
		audio.play("nuke",-5,0.65)
		audio.play("mortar",-5,0.6)
		if world.shake_enabled: world.shake=22
	queue_redraw()
func _draw():
	if elapsed<1.5:
		var grow=1.0+elapsed*elapsed*0.6
		world.sprite(8,origin,310*grow,false,Color(1+elapsed,1+elapsed*0.35,1,1-smoothstep(0.9,1.5,elapsed)),sin(elapsed*18)*0.025,self)
