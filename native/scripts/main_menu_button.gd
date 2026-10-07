extends Button
## Bespoke shared menu metalwork. No survivor-specific skin.
var primary=false
var heat=0.0
func _ready():
 mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 for state in ["normal","hover","pressed","disabled","focus"]:add_theme_stylebox_override(state,StyleBoxEmpty.new())
 for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:add_theme_color_override(state,Color.TRANSPARENT)
func _process(dt):
 var target=1.0 if not disabled and (is_hovered() or has_focus()) else 0.0
 var next=move_toward(heat,target,dt*5)
 if next!=heat:heat=next;queue_redraw()
func outline(inset):
 var r=Rect2(Vector2.ONE*inset,size-Vector2.ONE*inset*2);var c=12.0
 return PackedVector2Array([r.position+Vector2(c,0),Vector2(r.end.x-c,r.position.y),Vector2(r.end.x,r.position.y+c),r.end-Vector2(0,c),r.end-Vector2(c,0),Vector2(r.position.x+c,r.end.y),Vector2(r.position.x,r.end.y-c),r.position+Vector2(0,c),r.position+Vector2(c,0)])
func _draw():
 var texture=preload("res://assets/main-menu/amber-crescent-button-v1.png")
 var dims=texture.get_size();var cap=300.0;var width=size.y*.62
 var tint=Color.WHITE.lerp(Color(1.24,1.13,.92),heat)
 if primary:tint=Color(1.18,1.08,.91).lerp(Color(1.36,1.20,.94),heat)
 if is_pressed():tint=Color(.75,.73,.68)
 if disabled:tint=Color(.48,.50,.49)
 draw_texture_rect_region(texture,Rect2(0,-7,width,size.y+14),Rect2(0,0,cap,dims.y),tint)
 draw_texture_rect_region(texture,Rect2(width,-7,size.x-width*2,size.y+14),Rect2(cap,0,dims.x-cap*2,dims.y),tint)
 draw_texture_rect_region(texture,Rect2(size.x-width,-7,width,size.y+14),Rect2(dims.x-cap,0,cap,dims.y),tint)
 var font=preload("res://scripts/ui_art.gd").heading_font();var px=23 if primary else 19
 while px>13 and font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x>size.x-90:px-=1
 var measured=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,px)
 var pos=Vector2((size.x-measured.x)/2,(size.y-font.get_height(px))/2+font.get_ascent(px))
 draw_string(font,pos+Vector2(0,2),text,HORIZONTAL_ALIGNMENT_LEFT,-1,px,Color("040809"))
 draw_string(font,pos,text,HORIZONTAL_ALIGNMENT_LEFT,-1,px,Color("89928e") if disabled else Color("f7e7c3").lerp(Color.WHITE,heat))
