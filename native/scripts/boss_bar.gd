extends Control
var value = 100.0
var health = 0
var maximum = 0
var trail = 100.0
var frame = preload("res://assets/boss-frame.png")
func _process(dt):
	trail = maxf(value,move_toward(trail,value,dt*32))
	if value>trail: trail = value
	queue_redraw()
func _draw():
	# Coordinates refer to the authored trough, not a generic widget border.
	draw_texture_rect(frame,Rect2(Vector2.ZERO,size),false)
	var channel = Rect2(size.x*0.207,size.y*0.485,size.x*0.667,size.y*0.096)
	draw_rect(channel,Color("251c2c"))
	draw_rect(Rect2(channel.position,Vector2(channel.size.x*clampf(trail/100,0,1),channel.size.y)),Color("f6c18a"))
	for y in range(ceili(channel.size.y)):
		var tone = Color("fa9b55").lerp(Color("a5253b"),float(y)/channel.size.y)
		draw_line(channel.position+Vector2(0,y),channel.position+Vector2(channel.size.x*clampf(value/100,0,1),y),tone,1)

	var text="%s / %s HP"%[maxi(0,ceili(health)),ceili(maximum)]
	var font=preload("res://scripts/ui_art.gd").body_font()
	var at=channel.position+Vector2((channel.size.x-font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x)/2,channel.size.y/2+4)
	draw_string_outline(font,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,2,Color("15121c"))
	draw_string(font,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("fff2d5"))
