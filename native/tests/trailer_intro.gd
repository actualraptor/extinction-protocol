extends SceneTree
var story
var frame=0
var title
var subtitle
func _initialize():call_deferred("begin")
func begin():
 root.content_scale_size=Vector2i(1920,1080)
 story=preload("res://scripts/opening_story.gd").new()
 story.external_clock=true
 root.add_child(story)
 var shade=ColorRect.new();shade.color=Color(0,0,0,.32)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(shade)
 title=Label.new();title.text="EXTINCTION\nPROTOCOL"
 title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 title.position=Vector2(160,315);title.size=Vector2(1600,340)
 title.add_theme_font_override("font",preload("res://scripts/ui_art.gd").heading_font())
 title.add_theme_font_size_override("font_size",106)
 title.add_theme_color_override("font_color",Color("eee1c5"))
 title.add_theme_color_override("font_shadow_color",Color.BLACK)
 title.add_theme_constant_override("shadow_offset_y",5)
 root.add_child(title)
 subtitle=Label.new();subtitle.text="SURVIVE  /  ADAPT  /  DENY EXTINCTION"
 subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 subtitle.position=Vector2(160,690);subtitle.size=Vector2(1600,70)
 subtitle.add_theme_font_override("font",preload("res://scripts/ui_art.gd").heading_font())
 subtitle.add_theme_font_size_override("font_size",28)
 subtitle.add_theme_color_override("font_color",Color("eee1c5"))
 root.add_child(subtitle)
func _process(_dt):
 if story==null:return false
 var t=frame/30.0
 story.clock=t+.5;story.update_frame()
 title.modulate.a=smoothstep(3.5,4.6,t)
 subtitle.modulate.a=smoothstep(4.8,5.6,t)
 title.scale=Vector2.ONE*lerpf(1.03,1.0,clampf(t/8,0,1))
 frame+=1
 if frame>=240:quit()
 return false
