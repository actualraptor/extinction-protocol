extends Button
const Art=preload("res://scripts/ui_art.gd")
var artwork=preload("res://assets/cards-modular/legendary-button.tres")
func _ready():
	add_theme_font_override("font",Art.heading_font())
	add_theme_font_size_override("font_size",22)
	add_theme_color_override("font_color",Color("e6d2a1"))
	add_theme_color_override("font_disabled_color",Color("847b69"))
	add_theme_color_override("font_hover_color",Color("fff2cb"))
	add_theme_color_override("font_pressed_color",Color("d2b774"))
	add_theme_color_override("font_outline_color",Color("100d09"))
	add_theme_constant_override("outline_size",2)
	for state in ["normal","hover","pressed","disabled","focus"]:
		add_theme_stylebox_override(state,StyleBoxEmpty.new())
	mouse_entered.connect(queue_redraw);mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw);button_up.connect(queue_redraw)
	focus_entered.connect(queue_redraw);focus_exited.connect(queue_redraw)
func _draw():
	var tone=Color(.5,.48,.43) if disabled else Color(.78,.74,.65) if is_pressed() else Color(1.3,1.22,1.08) if is_hovered() or has_focus() else Color.WHITE
	draw_texture_rect(artwork,Rect2(Vector2.ZERO,size),false,tone)
	var color=Color("847b69") if disabled else Color("fff2cb") if is_hovered() else Color("e6d2a1")
	draw_string(Art.heading_font(),Vector2(0,size.y/2+8),text,HORIZONTAL_ALIGNMENT_CENTER,size.x,22,color)
