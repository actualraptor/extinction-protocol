extends Control
const ResourceSkin=preload("res://scripts/hud_skin.gd")
var theme_id="voss"
var caption=""
var insert:TextureRect
var material_fill:ShaderMaterial
var plaque:TextureRect
func _ready():
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 insert=TextureRect.new();insert.texture=load(ResourceSkin.ROOT+"health-ruby-v2.png")
 insert.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;insert.mouse_filter=Control.MOUSE_FILTER_IGNORE
 material_fill=ShaderMaterial.new();material_fill.shader=preload("res://shaders/hud_resource_fill.gdshader")
 insert.material=material_fill;add_child(insert)
 plaque=TextureRect.new();plaque.texture=load(ResourceSkin.ROOT+"xp-plaque-v2.png")
 plaque.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;plaque.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(plaque)
 var lettering=Control.new();lettering.mouse_filter=Control.MOUSE_FILTER_IGNORE
 lettering.draw.connect(draw_caption.bind(lettering));add_child(lettering)
func update_value(value,text_value,skin):
 theme_id=skin;caption=text_value
 if insert!=null:
  insert.position=Vector2(45,(size.y-10)/2);insert.size=Vector2(maxf(1,size.x-90),10)
  material_fill.set_shader_parameter("fraction",clampf(value,0,1))
  plaque.size=Vector2(232,42);plaque.position=(size-plaque.size)/2
 for child in get_children():child.queue_redraw()
 queue_redraw()
func _draw():
 var rail=ResourceSkin.texture(theme_id,"xp");var source=rail.get_size();var cap=source.x*.15
 var top=(size.y-36)/2
 for pair in [[Rect2(0,top,44,36),Rect2(0,0,cap,source.y)],[Rect2(44,top,size.x-88,36),Rect2(cap,0,source.x-cap*2,source.y)],[Rect2(size.x-44,top,44,36),Rect2(source.x-cap,0,cap,source.y)]]:
  draw_texture_rect_region(rail,pair[0],pair[1])
func draw_caption(control):
 var font=preload("res://scripts/ui_art.gd").heading_font()
 var region=Rect2(plaque.position+Vector2(35,10),plaque.size-Vector2(70,20))
 var fs=12
 while fs>9 and font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x>region.size.x:fs-=1
 var baseline=region.get_center().y+(font.get_ascent(fs)-font.get_descent(fs))/2
 control.draw_string(font,Vector2(region.position.x,baseline),caption,HORIZONTAL_ALIGNMENT_CENTER,region.size.x,fs,Color("f5e8ce"))
