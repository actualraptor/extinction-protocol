extends PanelContainer
const Art=preload("res://scripts/ui_art.gd")
const COLORS={"COMMON":"d4d1c2","UNCOMMON":"9bde93","RARE":"9bccff","EPIC":"d5b0fa","LEGENDARY":"ffc780","ARTIFACT":"fff0b2","EVOLUTION":"ffc780"}
var rarity="COMMON"
var regions=[]
var surface
func _ready():
 add_theme_stylebox_override("panel",StyleBoxEmpty.new())
 mouse_filter=Control.MOUSE_FILTER_PASS
 resized.connect(layout_regions)
 call_deferred("load_surface")
func load_surface():
 var id="legendary" if rarity=="EVOLUTION" else rarity.to_lower()
 var path="res://assets/cards-0115/"+id+".png"
 if ResourceLoader.exists(path):surface=load(path)
 queue_redraw();layout_regions()
func place(control,area,font_size=0):
 regions.append({"node":control,"area":area,"font_size":font_size})
 call_deferred("layout_regions")
func layout_regions():
 for entry in regions:
  var c=entry.node;var area=entry.area
  c.position=area.position*size;c.size=area.size*size
  if entry.font_size>0 and c is Label:
   var font=c.get_theme_font("font");var fs=entry.font_size
   while fs>14 and font.get_multiline_string_size(c.text,HORIZONTAL_ALIGNMENT_LEFT,c.size.x,fs).y>c.size.y:fs-=1
   c.add_theme_font_size_override("font_size",fs)
func _draw():
 if surface:draw_texture_rect(surface,Rect2(Vector2.ZERO,size),false)
 else:draw_rect(Rect2(Vector2.ZERO,size),Color("172019"))
static func action_style(hover=false):
 var style=StyleBoxFlat.new();style.bg_color=Color(1,.85,.55,.09) if hover else Color(0,0,0,0)
 style.border_color=Color(1,.9,.65,.45) if hover else Color(0,0,0,0);style.set_border_width_all(1)
 style.set_content_margin(SIDE_LEFT,6);style.set_content_margin(SIDE_RIGHT,6)
 return style
