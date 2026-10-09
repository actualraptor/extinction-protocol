extends Node2D
## Private ground-only heat and floating-mass shadow, below actors.
var world
var soft:GradientTexture2D
func _ready():
	var gradient=Gradient.new()
	gradient.offsets=PackedFloat32Array([0,.3,.65,1])
	gradient.colors=PackedColorArray([Color.WHITE,Color(1,1,1,.65),Color(1,1,1,.16),Color(1,1,1,0)])
	soft=GradientTexture2D.new();soft.gradient=gradient
	soft.width=256;soft.height=256;soft.fill=GradientTexture2D.FILL_RADIAL
	soft.fill_from=Vector2(.5,.5);soft.fill_to=Vector2(1,.5)
func _process(_dt):queue_redraw()
func _draw():
	if world.sim==null or world.sim.boss==null or world.sim.boss_stage!=3:return
	var g=world.sim;var at=world.screen(g.boss.p)
	var scale_factor=1.0+(g.phase-1)*.12
	var arriving=clampf(g.boss_time/3.0,0,1)
	draw_texture_rect(soft,Rect2(at+Vector2(-118,18)*scale_factor,Vector2(236,92)*scale_factor),false,Color(0,0,0,.32*arriving))
	for index in range(3):
		var offset=Vector2.from_angle(index*TAU/3)*24
		var flicker=.11+sin(world.clock*1.7+index*2)*.015
		var size=Vector2(260+index*12,210-index*18)*scale_factor
		draw_texture_rect(soft,Rect2(at+offset-size/2,size),false,Color(1,.27,.025,flicker*arriving))
