extends Button
var fitting=false
var desired_size=0
var last_fitted_size=0
func _ready():
	resized.connect(fit_text)
	call_deferred("fit_text")
func fit_text():
	if fitting or size.x<60:return
	fitting=true
	var font=get_theme_font("font")
	var style=get_theme_stylebox("normal")
	var available=size-style.get_minimum_size()-Vector2(8,4)
	var current=get_theme_font_size("font_size")
	if desired_size==0 or current!=last_fitted_size:desired_size=current
	var chosen=desired_size
	while chosen>13:
		var widest=0.0
		for line in text.split("\n"):widest=maxf(widest,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,chosen).x)
		if widest<=available.x and font.get_height(chosen)*text.split("\n").size()<=available.y:break
		chosen-=1
	if chosen!=get_theme_font_size("font_size"):add_theme_font_size_override("font_size",chosen)
	last_fitted_size=chosen
	fitting=false

func _draw():
	if not get_meta("inset_button",false):return
	var border=StyleBoxFlat.new();border.draw_center=false;border.border_color=Color("d1ad68");border.set_border_width_all(2);border.set_corner_radius_all(3)
	draw_style_box(border,Rect2(Vector2.ZERO,size))
	draw_rect(Rect2(Vector2(5,5),size-Vector2(10,10)),Color(0.75,0.59,0.33,0.35),false,1)
