extends Control
# Independent art layers: dark/filled shaped insert, foreground shell and text.
const ROOT="res://assets/hud-modular/"
var fraction=1.0
var caption=""
var fill_node:TextureRect
var fill_material:ShaderMaterial
var frame:Texture2D
var shell_node:TextureRect
var content=Rect2()
var active_skin=""
const APERTURES={"voss":Rect2(.13,.305,.74,.345),"kael":Rect2(.154,.30,.692,.40),"vesper":Rect2(.16,.29,.68,.37),"covenant":Rect2(.16,.31,.68,.34)}
func _ready():
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 frame=load(ROOT+"health-shell-v2.png")
 fill_node=TextureRect.new()
 fill_node.texture=load(ROOT+"health-ruby-v2.png")
 fill_node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 fill_node.stretch_mode=TextureRect.STRETCH_SCALE
 fill_node.mouse_filter=Control.MOUSE_FILTER_IGNORE
 fill_material=ShaderMaterial.new();fill_material.shader=preload("res://shaders/hud_resource_fill.gdshader")
 fill_node.material=fill_material
 add_child(fill_node)
 shell_node=TextureRect.new();shell_node.texture=frame
 shell_node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 shell_node.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var shell_material=ShaderMaterial.new();shell_material.shader=preload("res://shaders/hud_health_shell.gdshader")
 shell_node.material=shell_material;add_child(shell_node)
 # This child paints text after the textured fill.
 var lettering=Control.new();lettering.mouse_filter=Control.MOUSE_FILTER_IGNORE
 lettering.draw.connect(draw_caption.bind(lettering));add_child(lettering)
func update_value(value,text_value,skin="voss"):
 if active_skin!=skin and shell_node!=null:
  active_skin=skin
  shell_node.texture=preload("res://scripts/hud_skin.gd").texture(active_skin,"health-shell")
  var aperture=APERTURES[active_skin]
  shell_node.material.set_shader_parameter("aperture",Vector4(aperture.position.x-.015,aperture.position.y-.015,aperture.end.x+.015,aperture.end.y+.015))
 fraction=clampf(value,0,1);caption=text_value
 var area=APERTURES.get(skin,APERTURES.voss)
 content=Rect2(size*area.position,size*area.size)
 if fill_node!=null:
  fill_node.position=content.position;fill_node.size=content.size
  fill_material.set_shader_parameter("fraction",fraction)
  shell_node.size=size
 for child in get_children():child.queue_redraw()
 queue_redraw()
func _draw():
 draw_rect(content,Color("0c0609"))
func draw_caption(control):
 var font=preload("res://assets/fonts/Alegreya.ttf")
 var font_size=19
 while font_size>12 and font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>content.size.x-8:font_size-=1
 var baseline=content.get_center().y+(font.get_ascent(font_size)-font.get_descent(font_size))/2
 control.draw_string(font,Vector2(content.position.x,baseline+1),caption,HORIZONTAL_ALIGNMENT_CENTER,content.size.x,font_size,Color("320405"))
 control.draw_string(font,Vector2(content.position.x,baseline),caption,HORIZONTAL_ALIGNMENT_CENTER,content.size.x,font_size,Color("fff1d6"))
