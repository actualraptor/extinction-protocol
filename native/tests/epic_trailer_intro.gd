extends SceneTree
var story
var frame=0
var title
var subtitle
func _initialize():call_deferred("begin")
func begin():
 root.size=Vector2i(1920,1080)
 root.content_scale_size=root.size
 story=preload("res://scripts/opening_story.gd").new()
 story.external_clock=true
 root.add_child(story)
 var shade=ColorRect.new();shade.color=Color(0,0,0,.32)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(shade)
 title=preload("res://scripts/official_brand.gd").logo(0)
 title.position=Vector2(365,325);title.size=Vector2(1190,437)
 root.add_child(title)
 subtitle=Label.new();subtitle.text="SURVIVE  /  ADAPT  /  DENY EXTINCTION"
 subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 subtitle.position=Vector2(160,810);subtitle.size=Vector2(1600,70)
 subtitle.add_theme_font_override("font",preload("res://scripts/ui_art.gd").heading_font())
 subtitle.add_theme_font_size_override("font_size",28)
 subtitle.add_theme_color_override("font_color",Color("eee1c5"))
 root.add_child(subtitle)
func _process(_dt):
 if story==null:return false
 var t=frame/30.0
 story.clock=t+.5;story.update_frame()
 title.modulate.a=smoothstep(.6,1.5,t)
 subtitle.modulate.a=smoothstep(1.8,2.4,t)
 title.scale=Vector2.ONE*lerpf(1.03,1.0,clampf(t/8,0,1))
 frame+=1
 if frame>=120:quit()
 return false
