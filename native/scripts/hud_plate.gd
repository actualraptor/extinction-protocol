extends Control
# Authored label and shared live number, inside an explicitly reserved aperture.
const PlateSkin=preload("res://scripts/hud_skin.gd")
signal activated
var artwork:TextureRect
var number:Label
var interactive=false
func _ready():
 artwork=TextureRect.new()
 artwork.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 artwork.stretch_mode=TextureRect.STRETCH_SCALE
 artwork.mouse_filter=Control.MOUSE_FILTER_IGNORE
 artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(artwork)
 number=Label.new()
 number.mouse_filter=Control.MOUSE_FILTER_IGNORE
 number.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 number.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 var digits=FontVariation.new();digits.base_font=preload("res://assets/fonts/SourceSans3.ttf")
 digits.variation_opentype={2003265652:550.0}
 digits.opentype_features={"tnum":1}
 number.add_theme_font_override("font",digits)
 number.add_theme_color_override("font_color",Color("f2dba9"))
 number.add_theme_color_override("font_shadow_color",Color("100c08"))
 number.add_theme_constant_override("shadow_offset_y",1)
 number.clip_text=true
 add_child(number)
 mouse_entered.connect(func():if interactive:artwork.modulate=Color(1.22,1.18,1.08))
 mouse_exited.connect(func():artwork.modulate=Color.WHITE)
func configure(theme,part,value="",hero=-1):
 artwork.texture=PlateSkin.nameplate(theme,hero) if hero>=0 else PlateSkin.plate_texture(theme,part)
 interactive=part in ["backpack","relics","reroll","currency"] and hero<0
 mouse_filter=Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
 mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND if interactive else Control.CURSOR_ARROW
 number.visible=not value.is_empty()
 number.text=value
 if not number.visible:return
 var spec=PlateSkin.plate_spec(theme,part)
 var area=spec.value_region
 number.position=Vector2(area[0],area[1])*size
 number.size=Vector2(area[2],area[3])*size
 var fs=int(spec.font_size)
 var font=number.get_theme_font("font")
 while fs>11 and font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x>number.size.x-4:fs-=1
 number.add_theme_font_size_override("font_size",fs)
func _gui_input(event):
 if interactive and event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
  activated.emit();accept_event()

