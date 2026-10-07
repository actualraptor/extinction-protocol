extends Control
const D=preload("res://scripts/discoveries.gd")
const Art=preload("res://scripts/ui_art.gd")
const Icons=preload("res://scripts/atlas_icons.gd")
const Campaign=preload("res://scripts/campaign.gd")
var game
var category="All"
var selected="kael"
var grid_page=0

func menu_button(parent,caption,callback,primary=false):
	return preload("res://scripts/main_menu_scene.gd").add_button(game,parent,caption,callback,primary)

func group(id):
	var d=D.ENTRIES[id]
	return "Survivors" if d.has("hero") else "Maps" if id.begins_with("map_") else "Relics" if d.has("relics") else "Equipment"

func icon(parent,id,extent):
	var d=D.ENTRIES[id]
	if d.has("hero"):
		var p=TextureRect.new();p.texture=game.texture(d.hero)
		p.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;p.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		p.custom_minimum_size=Vector2(extent,extent);parent.add_child(p)
	elif id.begins_with("map_"):Icons.control(parent,id,"discovery",extent)
	else:
		var kind="weapon" if d.has("weapons") else "augment" if d.has("augments") else "relic"
		Icons.control(parent,d.get("weapons",d.get("augments",d.get("relics",["tablet"])))[0],kind,extent)

func panel(rect):
	var p=Panel.new();p.position=rect.position;p.size=rect.size
	var s=StyleBoxFlat.new();s.bg_color=Color("101b20");s.border_color=Color("786647")
	s.set_border_width_all(1);s.set_corner_radius_all(8);p.add_theme_stylebox_override("panel",s);add_child(p)
	return p

func build():
	for child in get_children():remove_child(child);child.queue_free()
	game.label(self,"DISCOVERIES",36,"f0d5a0").position=Vector2(65,42)
	game.label(self,"Explore. Discover. Expand your arsenal.",18,"afc6cf").position=Vector2(65,96)
	game.label(self,"%s AMBER  •  %s / %s UNLOCKED"%[game.save_data.amber,game.save_data.unlocks.size(),D.ENTRIES.size()],18,"dfb67a").position=Vector2(890,65)
	for i in range(6):
		var tab=["All","Survivors","Equipment","Maps","Relics","Combinations"][i]
		var b=menu_button(self,tab,func():category=tab;grid_page=0;build(),category==tab)
		b.position=Vector2(65+i*218,137);b.size=Vector2(205,55)
	var ids=[]
	if category=="Combinations":
		for id in game.save_data.recipes:
			if game.C.WEAPONS.has(id):ids.append(id)
	else:
		for id in D.ENTRIES:
			if category=="All" or group(id)==category:ids.append(id)
	if not ids.is_empty() and selected not in ids:selected=ids[0]
	var start=grid_page*20
	for n in range(start,mini(start+20,ids.size())):
		var id=ids[n];var recipe=category=="Combinations"
		var bought=id in game.save_data.unlocks or recipe;var found=id in game.save_data.discoveries or recipe
		var card=Button.new();card.position=Vector2(65+(n-start)%4*222,215+int((n-start)/4)*106);card.size=Vector2(209,94)
		card.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		for state in ["normal","hover","pressed","focus"]:
			var style=StyleBoxFlat.new();style.bg_color=Color("20332f") if selected==id else Color("111d23")
			style.border_color=Color("eac282") if selected==id or state in ["hover","focus"] else Color("59756b") if bought else Color("514d43")
			style.set_border_width_all(2 if selected==id else 1);style.set_corner_radius_all(6);card.add_theme_stylebox_override(state,style)
		add_child(card)
		var content=HBoxContainer.new();content.position=Vector2(10,10);content.size=Vector2(189,74);content.add_theme_constant_override("separation",9);card.add_child(content)
		if recipe:Icons.control(content,id,"weapon",54)
		else:icon(content,id,54)
		var copy=VBoxContainer.new();copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_child(copy)
		var title=game.label(copy,game.C.WEAPONS[id].name if recipe else D.ENTRIES[id].name,16,"e9d2a9")
		title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;title.custom_minimum_size.x=119
		game.label(copy,"UNLOCKED" if bought else "READY" if found else "UNDISCOVERED",12,"9dd8ba" if bought else "e7bb72" if found else "8a9ba4")
		ignore_mouse(content)
		card.pressed.connect(func():selected=id;build())
		if selected==id:card.call_deferred("grab_focus")
	var details=panel(Rect2(980,215,395,518))
	var v=game.column(details,Vector2(24,24),Vector2(347,470),16)
	if ids.is_empty():
		game.label(v,"NO COMBINATIONS YET",23,"e9d2a9").autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		game.label(v,"Max both compatible weapons to rank 10, then open a chest to discover a combination.",19,"b3c5cb").autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	elif category=="Combinations":
		Icons.control(v,selected,"weapon",100)
		game.label(v,game.C.WEAPONS[selected].name,25,"e9d2a9").autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		var parts=game.Expedition.Evolutions.UNIONS[selected].parts
		game.label(v,"%s + %s"%[game.C.WEAPONS[parts[0]].name,game.C.WEAPONS[parts[1]].name],19,"b3c5cb").autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	else:
		icon(v,selected,100)
		var d=D.ENTRIES[selected];var bought=selected in game.save_data.unlocks;var found=selected in game.save_data.discoveries
		game.label(v,d.name,25,"e9d2a9").autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		game.label(v,d.desc,19,"b3c5cb").autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		game.label(v,Campaign.requirement(game.save_data,selected),17,"dfb67a").autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		var action=menu_button(v,"Unlocked" if bought else "Unlock • %s amber"%d.cost if found else "Not discovered yet",func():
			if preload("res://scripts/archive_respec.gd").buy_discovery(game.save_data,selected):game.persist();build(),true)
		action.disabled=bought or not found or game.save_data.amber<d.cost
		if not bought:
			menu_button(v,"Track this discovery",func():Campaign.track_goal(game.save_data,selected);game.persist();build())
			if game.save_data.campaign.get("tracked_goal","")==selected:game.label(v,"◆ Tracked during expeditions",16,"9dd8ba")
	game.label(self,"Select a tile to inspect its rewards and unlock requirements.",17,"afc6cf").position=Vector2(65,750)
	var back=menu_button(self,"← Main menu",game.main_menu);back.position=Vector2(65,800);back.size=Vector2(420,60)
	var refund=menu_button(self,"Refund paid unlocks",func():game.archive_refund_menu(false));refund.position=Vector2(955,800);refund.size=Vector2(420,60)
	refund.disabled=preload("res://scripts/archive_respec.gd").discovery_total(game.save_data)<=0
	if ids.size()>20:
		var next=menu_button(self,"Next page →",func():grid_page=(grid_page+1)%int(ceil(ids.size()/20.0));build());next.position=Vector2(600,800)

func ignore_mouse(node):
	if node is Control:node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():ignore_mouse(child)
