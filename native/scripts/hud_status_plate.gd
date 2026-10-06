extends Control
# Top status displays share behavior; their art follows the selected HUD PlateSkin.
const PlateSkin=preload("res://scripts/hud_skin.gd")
const Art=preload("res://scripts/ui_art.gd")
var part="location"
var artwork:TextureRect
var primary:Label
var secondary:Label
func _ready():
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 artwork=TextureRect.new();artwork.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 artwork.mouse_filter=Control.MOUSE_FILTER_IGNORE
 artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(artwork)
 primary=make_label();secondary=make_label()
func make_label():
 var item=Label.new();item.mouse_filter=Control.MOUSE_FILTER_IGNORE
 item.clip_text=true;item.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 item.add_theme_font_override("font",Art.body_font())
 item.add_theme_color_override("font_color",Color("f2dba9"))
 item.add_theme_color_override("font_shadow_color",Color("100c08"))
 item.add_theme_constant_override("shadow_offset_y",1)
 add_child(item);return item
func configure(theme):
 var spec=PlateSkin.configuration(theme).menu[part]
 artwork.texture=PlateSkin.asset(spec.texture)
 fit(primary,spec.primary,23 if part=="score" else 22)
 secondary.visible=part=="location"
 if secondary.visible:fit(secondary,spec.secondary,16)
func fit(item,area,font_size):
 item.add_theme_font_size_override("font_size",font_size)
 item.position=Vector2(area[0],area[1])*size
 item.size=Vector2(area[2],area[3])*size
 item.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var font=item.get_theme_font("font")
 while font_size>11:
  var widest=0.0
  for line in item.text.split("\n"):widest=maxf(widest,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x)
  if widest<=item.size.x-4 and font.get_height(font_size)*item.text.split("\n").size()<=item.size.y:break
  font_size-=1
 item.add_theme_font_size_override("font_size",font_size)
