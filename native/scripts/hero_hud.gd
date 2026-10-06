extends Control
const Art=preload("res://scripts/ui_art.gd")
const Icons=preload("res://scripts/atlas_icons.gd")
const Discovery=preload("res://scripts/discoveries.gd")
const HudSkin=preload("res://scripts/hud_skin.gd")
const NAMES={1:"Ancestral Forge",0:"Field Command",2:"Astral Grimoire",3:"Wild Sanctuary",4:"Iron Bastion",5:"Black Covenant"}
const COLORS={1:Color("e9b95d"),0:Color("cf7770"),2:Color("b39aef"),3:Color("8ac394"),4:Color("a4c5d5"),5:Color("79eac0")}
var game
var slots=[]
var regions={}
var active_theme="kael"
var xp_display=0.0
var last_level=-1
var xp_node
var health_node
var portrait_node
var portraits={}
var map_texture
var map_origin=Vector2.ZERO
var map_clock=0.0
var item_page=0
var item_pages=1
var zones={}
var plates={}
static func available(save):
 var result=[]
 for id in [1,0,2,5]:
  if Discovery.hero_open(save,id):result.append(id)
 return result
static func selected(save,hero):
 var preference=save.get("settings",{}).get("hud_skin",-1)
 var id=int(preference) if preference is int or preference is float else -1
 return id if id in available(save) else hero
func _ready():
 mouse_filter=Control.MOUSE_FILTER_STOP
 for key in ["left_zone","center","right_zone"]:
  var zone=Control.new();zone.name=key;zone.mouse_filter=Control.MOUSE_FILTER_IGNORE;zone.clip_contents=true
  add_child(zone);zones[key]=zone
 for key in ["name","currency","backpack","relics","reroll"]:
  var plate=preload("res://scripts/hud_plate.gd").new();plate.name=key
  zones["left_zone" if key=="name" else "right_zone"].add_child(plate);plates[key]=plate
 plates.currency.tooltip_text="Amber collected this run. Click to inspect your backpack."
 plates.backpack.tooltip_text="Open backpack: items, weapons and detailed stats."
 plates.relics.tooltip_text="Inspect your relics and their effects."
 plates.reroll.tooltip_text="Re-rolls remaining. Use R when choosing a level-up upgrade."
 plates.currency.activated.connect(func():game.ledger_menu())
 plates.backpack.activated.connect(func():game.ledger_menu())
 plates.relics.activated.connect(func():game.ledger_menu(true))
 plates.reroll.activated.connect(func():game.show_toast("%s RE-ROLLS AVAILABLE"%game.sim.rerolls,"Use R when choosing a level-up upgrade."))
 portrait_node=TextureRect.new();portrait_node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 portrait_node.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 portrait_node.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var mask=ShaderMaterial.new();mask.shader=preload("res://shaders/hud_portrait.gdshader");portrait_node.material=mask
 zones.left_zone.add_child(portrait_node)
 health_node=preload("res://scripts/hud_resource_bar.gd").new();zones.left_zone.add_child(health_node)
 xp_node=preload("res://scripts/hud_xp_bar.gd").new();zones.center.add_child(xp_node)
func layout():
 regions=preload("res://scripts/hud_layout.gd").arrange(size,HudSkin.configuration(active_theme).layout)
func _process(dt):
 if game.sim==null or size.x<100 or size.y<100:return
 var g=game.sim
 var skin=selected(game.save_data,g.hero);active_theme=HudSkin.THEMES[skin]
 layout()
 for key in zones:
  zones[key].position=regions[key].position;zones[key].size=regions[key].size
 for key in plates:
  var zone=regions.left_zone if key=="name" else regions.right_zone
  plates[key].position=regions[key].position-zone.position;plates[key].size=regions[key].size
  var value=HudSkin.format_amount(g.amber) if key=="currency" else str(g.rerolls) if key=="reroll" else ""
  plates[key].configure(active_theme,key,value,g.hero if key=="name" else -1)
 var ratio=clampf(g.xp/maxf(1,g.xp_goal),0,1)
 xp_display=ratio if last_level!=g.level else lerpf(xp_display,ratio,1-exp(-dt*10));last_level=g.level
 if not portraits.has(g.hero):portraits[g.hero]=HudSkin.portrait(g.hero)
 portrait_node.texture=portraits[g.hero]
 var aperture=HudSkin.region(active_theme,"portrait",regions.portrait).grow(-2)
 portrait_node.position=aperture.position-regions.left_zone.position;portrait_node.size=aperture.size
 health_node.position=regions.health.position-regions.left_zone.position;health_node.size=regions.health.size
 health_node.update_value(g.hp/maxf(1,g.max_hp),"%s / %s"%[ceili(maxf(0,g.hp)),int(g.max_hp)],active_theme)
 xp_node.position=regions.xp.position-regions.center.position;xp_node.size=regions.xp.size
 xp_node.update_value(xp_display,"LEVEL %s  •  %s / %s XP"%[g.level,int(g.xp),int(g.xp_goal)],active_theme)
 map_clock-=dt
 if map_clock<=0 and game.save_data.settings.get("hud_minimap",true):
  map_clock=.35
  rebuild_minimap(g,HudSkin.region(active_theme,"map",regions.map))
 queue_redraw()
func text(value,at,fs=16,color=Color("e9dfca"),width=-1):
 draw_string(Art.body_font(),at,value,HORIZONTAL_ALIGNMENT_LEFT,width,fs,color)
func label_in(value,rect,fs=16,color=Color("e9dfca"),heading=false):
 var font=Art.heading_font() if heading else Art.body_font()
 while fs>11 and font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x>rect.size.x:fs-=1
 var at=Vector2(rect.position.x,rect.get_center().y+font.get_ascent(fs)/2-font.get_descent(fs)/2)
 draw_string(font,at,value,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,fs,color)
func part(name,rect,tone=Color.WHITE):draw_texture_rect(HudSkin.texture(active_theme,name),rect,false,tone)
func icon_in(texture,rect):
 if texture==null:return
 var centered=preload("res://scripts/stone_card.gd").centered(texture)
 var factor=minf(rect.size.x/centered.get_width(),rect.size.y/centered.get_height())
 var dimensions=centered.get_size()*factor
 draw_texture_rect(centered,Rect2(rect.get_center()-dimensions/2,dimensions),false)
func _draw():
 if game.sim==null or size.x<100 or size.y<100:return
 layout()
 var g=game.sim;var accent=COLORS[selected(game.save_data,g.hero)]
 draw_rect(Rect2(0,24,size.x,size.y-24),Color("101311"))
 var rail=HudSkin.configuration(active_theme).rail_geometry
 draw_master_frame(Rect2(0,rail[0],size.x,rail[1]),regions.xp.get_center().x)
 draw_console("left",Rect2(0,0,regions.left_zone.end.x+20,230))
 draw_console("right",Rect2(regions.right_zone.position.x-20,0,size.x-regions.right_zone.position.x+20,230))

 if game.save_data.settings.get("hud_minimap",true):
  part("map",regions.map)
  draw_map(g,HudSkin.region(active_theme,"map",regions.map),accent)
 part("portrait",regions.portrait)
 var level_badge=regions.level
 part("level",level_badge)
 label_in(str(g.level),level_badge.grow(-9),17,Color("ecd8ad"),true)
 var slot_size=minf(minf(110,regions.weapons.size.y/1.12),(regions.weapons.size.x-24)/5)
 var slot_height=slot_size*1.12
 var slot_start=regions.weapons.get_center().x-(5*slot_size+24)/2
 slots.clear()
 for i in range(5):
  var r=Rect2(slot_start+i*(slot_size+6),regions.weapons.get_center().y-slot_height/2,slot_size,slot_height)
  part("weapon",r)
  if i>=g.weapons.size():continue
  var id=g.weapons.keys()[i];var weapon=g.weapons[id];var d=g.C.WEAPONS[id]
  var content=HudSkin.region(active_theme,"weapon",r)
  icon_in(Icons.get_icon(id,"weapon",g.halloween),content.grow(-3))
  var rank=Rect2(r.position+Vector2(slot_size*.14,slot_height-22),Vector2(26,21))
  draw_style_box(HudSkin.panel(active_theme,true),rank)
  label_in(str(weapon.level),rank,13,Color("f1dfb3"),true)
  var cooldown=preload("res://scripts/combat_rules.gd").stats(g,id).cooldown
  var ratio=clampf(weapon.get("timer",0.0)/maxf(.001,cooldown),0,1)
  if ratio>0:draw_arc(content.get_center(),minf(content.size.x,content.size.y)*.48,-PI/2,-PI/2+TAU*ratio,32,Color(accent,.7),2,true)
  slots.append({"rect":r,"text":(d.evolution if weapon.evolved else d.name)+" / Rank %s"%weapon.level+"\n"+d.get("desc","")})
 var summary=""
 if g.companions!=null:
  var army=g.companions;var census=preload("res://scripts/companion_meter.gd").census(army.units,g.time)
  summary="SOULS %s / %s     •     ARMY %s"%[int(army.remnant_souls if not army.fallen_remnant.is_empty() else army.souls),2000 if not army.fallen_remnant.is_empty() else int(army.next_threshold),census.total]
 if g.companions!=null:label_in(summary,regions.summary,16,accent)
 var carried=[]
 for id in g.relics:carried.append({"id":id,"type":"relic","rank":g.Relics.tiers(g,id).size(),"name":g.Relics.inventory_data(g,id).name})
 for category in ["passive","augment"]:
  var owned=g.passives if category=="passive" else g.augments
  var catalog=g.C.PASSIVES if category=="passive" else g.C.AUGMENTS
  for id in owned:
   if owned[id]>0 and catalog.has(id):carried.append({"id":id,"type":category,"rank":owned[id],"name":catalog[id].name})
 item_pages=maxi(1,ceili(carried.size()/8.0))
 item_page=clampi(item_page,0,item_pages-1)
 var count=8
 var columns=4
 var cell=minf(58,minf(regions.inventory.size.x/columns,regions.inventory.size.y/2))
 var start=regions.inventory.get_center().x-columns*cell/2
 var grid_top=regions.inventory.get_center().y-cell
 for i in range(count):
  var r=Rect2(start+i%columns*cell,grid_top+int(i/columns)*cell,cell,cell)
  part("relic",r)
  var item_index=item_page*8+i
  if item_index>=carried.size():continue
  var item=carried[item_index]
  icon_in(Icons.get_icon(item.id,item.type),HudSkin.region(active_theme,"relic",r))
  label_in(str(item.rank),Rect2(r.end-Vector2(18,16),Vector2(15,14)),11,Color("f2dfb2"))
  slots.append({"rect":r,"text":item.name+" / Rank %s"%item.rank})

 if item_pages>1:label_in("<   %s / %s   >"%[item_page+1,item_pages],regions.inventory_pages,12,Color("e7d3a7"))
 draw_notification()
func draw_master_frame(rect,centerline):
 # One connected parent shell. Preserve both end ornaments and align the central
 # crest with XP/abilities, allocating surplus width to the two continuous rails.
 var texture=HudSkin.texture(active_theme,"master")
 var source=texture.get_size()
 var left_edge=200.0
 var right_edge=190.0
 var crest=180.0
 var target=[0.0,left_edge,centerline-crest/2,centerline+crest/2,size.x-right_edge,size.x]
 var cuts=[0.0,.18,.42,.58,.82,1.0]
 for i in range(5):
  draw_texture_rect_region(texture,Rect2(target[i],rect.position.y,target[i+1]-target[i],rect.size.y),Rect2(source.x*cuts[i],0,source.x*(cuts[i+1]-cuts[i]),source.y))
func draw_console(side,rect):
 # Only decorative rails stretch; the end ornaments retain fixed footprints.
 var spec=HudSkin.configuration(active_theme).shells[side]
 var texture=HudSkin.asset(spec.texture);var source=texture.get_size()
 var xs=[0.0,float(spec.caps[0]),rect.size.x-float(spec.caps[1]),rect.size.x]
 var ys=[0.0,38.0,202.0,rect.size.y]
 var uv_y=[0.0,.28,.76,1.0]
 for x in range(3):
  for y in range(3):
   draw_texture_rect_region(texture,Rect2(rect.position+Vector2(xs[x],ys[y]),Vector2(xs[x+1]-xs[x],ys[y+1]-ys[y])),Rect2(Vector2(spec.cuts[x],uv_y[y])*source,Vector2(spec.cuts[x+1]-spec.cuts[x],uv_y[y+1]-uv_y[y])*source))
func draw_notification():
 if game.toast_time<=0 or game.sim.choosing:return
 var opacity=minf(1,game.toast_time)
 var width=clampf(size.x*.35,480,660)
 var panel=Rect2(size.x/2-width/2,-112,width,130)
 draw_texture_rect(HudSkin.texture(active_theme,"event"),panel,false,Color(1,1,1,opacity))
 var lines=game.toast_label.text.split("\n",true,1)
 var event_areas={"voss":Rect2(.20,.40,.60,.32),"kael":Rect2(.20,.28,.60,.34),"vesper":Rect2(.22,.32,.56,.34),"covenant":Rect2(.19,.34,.62,.34)}
 var event_area=event_areas[active_theme]
 var body=Rect2(panel.position+panel.size*event_area.position,panel.size*event_area.size)
 if active_theme=="covenant":draw_rect(body.grow(2),Color(.018,.02,.018,opacity))
 if lines.size()==1 or lines[1].is_empty():label_in(lines[0],body,20,Color(1,.9,.72,opacity),true)
 else:
  label_in(lines[0],Rect2(body.position,Vector2(body.size.x,body.size.y/2)),18,Color(1,.9,.72,opacity),true)
  label_in(lines[1],Rect2(body.position+Vector2(0,body.size.y/2),Vector2(body.size.x,body.size.y/2)),15,Color(.9,.84,.72,opacity))
func map_point(p,_g,r):return r.get_center()+(p-map_origin)*.025
func map_known(p,g):return g.explored[g.depth].has(Vector2i(floori(p.x/160),floori(p.y/160)))
func map_marker(p,g,r,color,radius=3):
 var at=map_point(p,g,r)
 if r.grow(-6).has_point(at):draw_circle(at,radius,color)
func draw_map(g,r,accent):
 draw_rect(r,Color("0c1718"))
 if map_texture!=null:draw_texture_rect(map_texture,r,false)
 for item in preload("res://scripts/map_markers.gd").collect(g):
  var at=map_point(item.p,g,r)
  if r.grow(-8).has_point(at):icon_in(Icons.get_icon(item.id,item.category,g.halloween),Rect2(at-Vector2(6,6),Vector2(12,12)))
 for region in g.stage.get("regions",[]):
  var at=map_point(region.p,g,r)
  if r.grow(-10).has_point(at):draw_arc(at,8,0,TAU,24,Color(accent,.25),1,true)
 if g.companions!=null:
  for unit in g.companions.units:
   if unit.hp>0:map_marker(unit.p,g,r,Color("77c8a0"),1.5)
 if g.boss!=null:map_marker(g.boss.p,g,r,Color("ef6863"),4)
 if g.portal!=null:
  var at=map_point(g.portal,g,r).clamp(r.position+Vector2(7,7),r.end-Vector2(7,7))
  draw_arc(at,5,0,TAU,16,Color("edd89b"),2)
 if g.waypoint!=null:map_marker(g.waypoint,g,r,Color("f9e3a5"),4)
 var center=r.get_center()
 var angle=g.velocity.angle() if g.velocity.length_squared()>1 else -PI/2
 var points=PackedVector2Array()
 for p in [Vector2(6,0),Vector2(-4,4),Vector2(-2,0),Vector2(-4,-4)]:points.append(center+p.rotated(angle))
 draw_colored_polygon(points,Color("fff3cc"))
 text("N",r.position+Vector2(r.size.x/2-4,12),11,Color("dfd7b4"))
func _get_tooltip(at):
 if regions.relics.has_point(at):return "Inspect your relics and their effects."
 if regions.reroll.has_point(at):return "Re-rolls remaining. Use R while choosing a level-up upgrade."
 if regions.currency.has_point(at):return "Amber collected this run. Click to inspect your backpack."
 for slot in slots:
  if slot.rect.has_point(at):return slot.text
 if regions.inventory.has_point(at) and item_pages>1:return "Scroll to browse items / Page %s of %s. Click an item to open the backpack."%[item_page+1,item_pages]
 if game.sim!=null and game.sim.companions!=null and regions.get("summary",Rect2()).has_point(at):
  var army=game.sim.companions
  var counts=preload("res://scripts/companion_meter.gd").census(army.units,game.sim.time)
  return "Next: "+("Restore fallen boss / 2000 new souls" if not army.fallen_remnant.is_empty() else preload("res://scripts/companion_meter.gd").REWARDS[army.threshold_index%4])+"\nWarriors %s • Guards %s • Archers %s\nWraiths %s • Colossi %s • Bosses %s"%[counts.warrior,counts.guard,counts.archer,counts.wraith,counts.colossus,counts.boss]
 for slot in slots:
  if slot.rect.has_point(at):return slot.text
 return "Open backpack for all relics, passives and detailed stats." if regions.inventory.has_point(at) or regions.backpack.has_point(at) else ""
func _gui_input(event):
 var pages=regions.inventory_pages
 if event is InputEventMouseButton and event.pressed and (regions.inventory.has_point(event.position) or pages.has_point(event.position)):
  if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
   item_page=posmod(item_page+(1 if event.button_index==MOUSE_BUTTON_WHEEL_DOWN else -1),item_pages);accept_event();queue_redraw();return
  if event.button_index==MOUSE_BUTTON_LEFT and pages.has_point(event.position) and item_pages>1:
   item_page=posmod(item_page+(1 if event.position.x>=regions.inventory.get_center().x else -1),item_pages);accept_event();queue_redraw();return
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
  if regions.reroll.has_point(event.position):
   game.show_toast("%s RE-ROLLS AVAILABLE"%game.sim.rerolls,"Use R when choosing a level-up upgrade.")
  elif regions.relics.has_point(event.position):game.ledger_menu(true)
  elif regions.backpack.has_point(event.position) or regions.inventory.has_point(event.position) or regions.currency.has_point(event.position):game.ledger_menu()
  elif regions.map.has_point(event.position) and game.save_data.settings.get("hud_minimap",true):game.map_menu()

func rebuild_minimap(g,r):
 map_origin=g.pos
 var image=Image.create(128,128,false,Image.FORMAT_RGBA8)
 var world_size=r.size/.025
 for y in range(128):
  for x in range(128):
   var p=map_origin+(Vector2(x+.5,y+.5)/128.0-Vector2(.5,.5))*world_size
   var kind=g.terrain.kind(g.terrain.cell(p))
   var shade=[Color("40534b"),Color("838078"),Color("2e6775"),Color("a85c37")][clampi(kind,0,3)]
   if not map_known(p,g):shade=shade.darkened(.68)
   image.set_pixel(x,y,shade)
 if map_texture==null:map_texture=ImageTexture.create_from_image(image)
 else:map_texture.update(image)
