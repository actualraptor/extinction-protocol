extends Button
# The engraved label lives in its themed artwork; text remains accessible.
const PlateSkin=preload("res://scripts/hud_skin.gd")
var artwork:TextureRect
func _ready():
 mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 artwork=TextureRect.new();artwork.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 artwork.mouse_filter=Control.MOUSE_FILTER_IGNORE
 artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(artwork)
 for state in ["normal","hover","pressed","disabled","focus"]:add_theme_stylebox_override(state,StyleBoxEmpty.new())
 for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:add_theme_color_override(state,Color.TRANSPARENT)
 mouse_entered.connect(func():artwork.modulate=Color(1.18,1.12,1.03))
 mouse_exited.connect(func():artwork.modulate=Color.WHITE)
 button_down.connect(func():artwork.modulate=Color(.8,.78,.74))
 button_up.connect(func():artwork.modulate=Color(1.18,1.12,1.03) if is_hovered() else Color.WHITE)
 focus_entered.connect(func():artwork.self_modulate=Color(1.16,1.12,1.03))
 focus_exited.connect(func():artwork.self_modulate=Color.WHITE)
func configure(theme,part):artwork.texture=PlateSkin.asset(PlateSkin.configuration(theme).menu[part].texture)
