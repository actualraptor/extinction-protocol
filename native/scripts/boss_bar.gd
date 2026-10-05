extends Control
var value = 100.0
var health = 0
var maximum = 0
var trail = 100.0
var resistance_text = ""
func set_encounter(g):
	resistance_text = preload("res://scripts/boss_resistance.gd").caption(g,g.boss) if g.boss!=null else ""
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

	if not resistance_text.is_empty():
		var text_size=14
		while text_size>9 and font.get_string_size(resistance_text,HORIZONTAL_ALIGNMENT_LEFT,-1,text_size).x>channel.size.x:text_size-=1
		var below=Vector2(channel.position.x+(channel.size.x-font.get_string_size(resistance_text,HORIZONTAL_ALIGNMENT_LEFT,-1,text_size).x)/2,channel.end.y+21)
		var caption_width=font.get_string_size(resistance_text,HORIZONTAL_ALIGNMENT_LEFT,-1,text_size).x+24
		var plaque=Rect2(Vector2(channel.get_center().x-caption_width/2,channel.end.y+5),Vector2(caption_width,22))
		draw_style_box(preload("res://scripts/ui_art.gd").inset_button_style(),plaque)
		draw_string_outline(font,below,resistance_text,HORIZONTAL_ALIGNMENT_LEFT,-1,text_size,3,Color("15121c"))
		draw_string(font,below,resistance_text,HORIZONTAL_ALIGNMENT_LEFT,-1,text_size,Color("efce8d"))
