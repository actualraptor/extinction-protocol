extends Node2D
var world
func _ready():
	material=ShaderMaterial.new()
	material.shader=preload("res://shaders/meteor_fire_front.gdshader")
func _process(_dt):
	if "--meteor-no-fire-render-review" in OS.get_cmdline_user_args():
		visible=false;return
	var s=world.sim
	visible=s!=null and s.boss!=null and s.boss_stage==3
	if not visible:return
	var rect=world.visible_rect()
	material.set_shader_parameter("center",world.screen(s.boss.p))
	material.set_shader_parameter("world_offset",s.boss.p-world.screen(s.boss.p))
	material.set_shader_parameter("rect_origin",rect.position)
	material.set_shader_parameter("rect_size",rect.size)
	material.set_shader_parameter("elapsed",s.boss_time)
	material.set_shader_parameter("boundary_radius",preload("res://scripts/meteor_fire_front.gd").base_radius_at(s.boss_time))
	material.set_shader_parameter("boundary_weather",preload("res://scripts/meteor_fire_front.gd").remaining_at(s.boss_time))
	material.set_shader_parameter("clock",s.time)
	queue_redraw()
func _draw():
	if world!=null:draw_rect(world.visible_rect(),Color.WHITE)
