extends Node2D
var world
const SHEET=preload("res://assets/ancestor-earth-fragments.png")
func _process(_dt):
	if world!=null and world.sim!=null and not world.sim.ancestor_ruptures.is_empty():queue_redraw()
	elif visible:queue_redraw()
func _draw():
	if world==null or world.sim==null:return
	for wave in world.sim.ancestor_ruptures:
		if wave.get("primary",false):render_impact(wave)
		render_wave(wave)
func render_impact(wave):
	if wave.age>.55:return
	var center:Vector2=world.screen(wave.origin)
	var fade=1-wave.age/.55
	var radius:float=wave.impact_radius
	# An uneven, flattened crater anchors the strike to the floor.
	for i in range(9):
		var angle=i*TAU/9
		var reach=radius*(.34+wave.age*.65)*(1+.13*sin(i*3.1))
		var at=center+Vector2(cos(angle),sin(angle)*.45)*reach
		draw_line(center,at,Color(.07,.045,.02,fade*.5),3,true)
		draw_circle(at,5+wave.age*12,Color(.48,.38,.23,fade*.16))
		var chip=at+Vector2(0,-sin(clampf(wave.age/.4,0,1)*PI)*(12+i%3*7))
		draw_line(chip,chip+Vector2(3,-2),Color(.85,.67,.38,fade*.65),2,true)
func render_wave(wave):
	var side:Vector2=wave.aim.orthogonal()
	var step=maxf(28,wave.length/48.0)
	var cells=Vector2(SHEET.get_width()/3.0,SHEET.get_height())
	var visible_area=world.visible_rect().grow(150)
	for index in range(ceili(wave.distance/step)+1):
		var distance=minf(wave.distance,index*step)
		var age=maxf(0,wave.age-distance/520.0)
		if age>.62:continue
		var fade=clampf((.62-age)/.25,0,1)
		var growth=sin(clampf(age/.4,0,1)*PI)*.25+.75
		var center:Vector2=wave.origin+wave.aim*distance
		var previous=center-wave.aim*minf(step,distance)
		var p=world.screen(center)
		if not visible_area.has_point(p):continue
		for lane in range(3):
			var lateral=(lane-1)*wave.width*.62
			var at=world.screen(center+side*(lateral+sin(index*4.1+lane)*wave.width*.08))
			var size=clampf(wave.width*(1.25 if lane==1 else .85),25,110)*growth
			draw_set_transform(at,0,Vector2(1,.4))
			draw_circle(Vector2.ZERO,size*.42,Color(.02,.015,.01,fade*.24))
			draw_set_transform(Vector2.ZERO)
			var source=Rect2(Vector2(((index+lane)%3)*cells.x,0),cells)
			draw_texture_rect_region(SHEET,Rect2(at+Vector2(-size*.5,-size*.85),Vector2.ONE*size),source,Color(1,1,1,fade*.9))
		if age<.2:
			for chip in range(3):
				var at=p+side*(chip-1)*wave.width*.35+Vector2(0,-sin(age/.2*PI)*(12+chip*5))
				draw_circle(at,1.5,Color(.75,.6,.35,fade*.55))
