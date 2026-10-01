extends Node2D

const C = preload("res://scripts/catalog.gd")
const Expedition = preload("res://scripts/expedition.gd")
const World = preload("res://scripts/world.gd")
const Sound = preload("res://scripts/sound.gd")
const Discoveries = preload("res://scripts/discoveries.gd")
const Maps = preload("res://scripts/expedition_maps.gd")
const Campaign = preload("res://scripts/campaign.gd")
var selected_map = "cradle"
var campaign_last_kills = 0
var campaign_last_bosses = 0
var campaign_clock = 0.0
var campaign_save_clock = 0.0
const Icons = preload("res://scripts/atlas_icons.gd")
var world
var audio
var sim = null
var layer
var menu_root
var hud_root
var toast_label
var toast_panel
var toast_time = 0.0
var health_bar
var xp_bar
var health_label
var timer_label
var score_label
var biome_label
var loadout_label
var boss_bar
var boss_label
var boss_panel
var objective_label
var paused = false
var selected = 2
var chosen_mode = "expedition"
var daily_date = ""
var page = "menu"
var finish_delay = -1.0
var defeat_cinematic = null
var save_data = {"version":1,"amber":0,"wins":0,"runs":0,"research":{},"records":[],"settings":{"sound":true,"music":true,"shake":true}}
var save_error = ""
var save_blocked = false
var ui_clock = 0.0
var reveal_index = -1
var buff_label
var hud_layout = []
var weapons_hud
var buffs_hud
const PatchNotes=preload("res://scripts/patch_notes.gd")
const UIArt=preload("res://scripts/ui_art.gd")
const UpgradeCopy=preload("res://scripts/upgrade_copy.gd")
var score_plate
var timer_plate
var progress_path = "user://progress.json"

func _ready():
	# Package smoke checks never touch a player's real progression.
	if "--verify-package" in OS.get_cmdline_user_args():
		progress_path=OS.get_executable_path().get_base_dir().path_join("verification-profile.json")
	elif "--capture" in OS.get_cmdline_user_args():
		progress_path="res://build/capture-profile.json"
	load_progress()
	Discoveries.migrate(save_data)
	Campaign.ensure(save_data)
	world = World.new()
	add_child(world)
	audio = Sound.new()
	add_child(audio)
	apply_settings()
	layer = CanvasLayer.new()
	add_child(layer)
	var atmosphere = ColorRect.new()
	atmosphere.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader = ShaderMaterial.new()
	shader.shader = preload("res://shaders/atmosphere.gdshader")
	atmosphere.material = shader
	world.vignette = shader
	layer.add_child(atmosphere)
	hud_root = Control.new()
	hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud_root)
	menu_root = Control.new()
	menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(menu_root)
	var theme = Theme.new()
	theme.default_font_size = 20
	theme.default_font = UIArt.body_font()
	for type in ["Button","PanelContainer"]:
		theme.set_stylebox("normal" if type=="Button" else "panel",type,box(Color("152730"),Color("405357")))
	theme.set_stylebox("hover","Button",box(Color("2c4449"),Color("e9c88d")))
	theme.set_stylebox("pressed","Button",box(Color("4a5149"),Color("ffdfa1")))
	theme.set_stylebox("focus","Button",box(Color(0,0,0,0),Color("ffdfa1")))
	theme.set_color("font_color","Button",Color("f5eee1"))
	theme.set_color("font_color","Label",Color("e6e7e5"))
	menu_root.theme = theme
	hud_root.theme = theme
	build_hud()
	buff_label = label(hud_root,"",17,"c8e9ff")
	buff_label.position = Vector2(35,155)
	for item in hud_root.get_children():
		if item is Control and not item is ColorRect and item != xp_bar and item.get_script()!=preload("res://scripts/player_health.gd") and item.get_script()!=preload("res://scripts/navigation.gd"):
			hud_layout.append({"node":item,"position":item.position})
	main_menu()
	if "--verify-package" in OS.get_cmdline_user_args():
		selected = 2
		chosen_mode = "safari"
		start_run()
		await get_tree().create_timer(3).timeout
		paused = true
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OS.get_executable_path().get_base_dir().path_join("package-preview.png"))
		get_tree().quit()
	if "--capture" in OS.get_cmdline_user_args():
		selected = 2
		chosen_mode = "safari"
		start_run()
		await get_tree().create_timer(4).timeout
		paused = true
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://build/native-preview.png")
		get_tree().quit()

func box(background, border, radius = 10):
	var b = StyleBoxFlat.new()
	b.bg_color = background
	b.border_color = border
	b.set_border_width_all(1)
	b.set_corner_radius_all(radius)
	b.content_margin_left = 20
	b.content_margin_right = 20
	b.content_margin_top = 12
	b.content_margin_bottom = 12
	return b

func label(parent,text,size = 20,color = "e8e8e4"):
	var l = Label.new()
	l.text = text
	if size>=23:
		l.add_theme_font_override("font",UIArt.heading_font())
		l.add_theme_color_override("font_shadow_color",Color("04080b"))
		l.add_theme_constant_override("shadow_offset_y",2)
	l.add_theme_font_size_override("font_size",size)
	l.add_theme_color_override("font_color",Color(color))
	parent.add_child(l)
	return l

func button(parent,text,callback,primary = false):
	var b = preload("res://scripts/art_button.gd").new()
	b.text = text
	# Containers own width; fitting must not let long captions stretch the layout.
	b.clip_text = true
	b.custom_minimum_size = Vector2(140,55)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font",UIArt.heading_font())
	for state in ["normal","hover","pressed","disabled"]:b.add_theme_stylebox_override(state,UIArt.button_style(state,primary))
	b.add_theme_color_override("font_color",Color("f1d89d") if primary else Color("dfd2b4"))
	b.add_theme_color_override("font_hover_color",Color("fff0c5"))
	b.add_theme_color_override("font_pressed_color",Color("fff0c5"))
	b.add_theme_color_override("font_disabled_color",Color("aaa79c"))
	b.add_theme_color_override("font_shadow_color",Color("05090c"))
	b.add_theme_constant_override("shadow_offset_y",2)
	b.pressed.connect(func(): audio.play("loot",-21,1.4);callback.call())
	parent.add_child(b)
	return b

func clear_menu():
	for child in menu_root.get_children():
		menu_root.remove_child(child)
		child.queue_free()

func column(parent,p,size_value,spacing = 14):
	var v = VBoxContainer.new()
	v.position = p
	v.size = size_value
	v.add_theme_constant_override("separation",spacing)
	parent.add_child(v)
	return v

func shade(alpha = 0.82):
	var bg = ColorRect.new()
	bg.color = Color(0.018,0.027,0.042,alpha)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_root.add_child(bg)

func main_menu():
	page = "menu"
	release_run()
	paused = false
	hud_root.hide()
	clear_menu()
	var v = column(menu_root,Vector2(90,78),Vector2(590,730),13)
	label(v,"A WORLD OUT OF TIME. A SPECIES OUT OF LUCK.",15,"b9ac91")
	label(v,"EXTINCTION\nPROTOCOL",65,"f1e5cf")
	label(v,"The end of the world has a health bar.",24,"c0cbc8")
	label(v,"Guns. Ancient fury. Forbidden magic.\nSurvive the ecosystem. Kill the extinction.",18,"8daba8")
	button(v,"ENTER THE RIFT",func():chosen_mode="expedition";characters(),true)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	v.add_child(row)
	var daily = button(row,"Daily challenge",daily_menu)
	daily.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var safari = button(row,"Meteor trial",func():chosen_mode="safari";characters())
	safari.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button(v,"The archive / permanent upgrades",research_menu)
	button(v,"Discoveries / survivors & equipment",discovery_menu)
	button(v,"Field manual / controls",manual)
	var row2 = HBoxContainer.new()
	row2.add_theme_constant_override("separation",12)
	v.add_child(row2)
	button(row2,"Settings",settings).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button(row2,"Quit",func():get_tree().quit()).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label(v,"%s AMBER    /    %s EXTINCTIONS DENIED    /    NATIVE %s"%[save_data.amber,save_data.wins,ProjectSettings.get_setting("application/config/version")],14,"c5ac82")
	if save_error!="": label(v,save_error,14,"ff877e")
	var caption = column(menu_root,Vector2(870,715),Vector2(475,100))
	label(caption,"THE EXTINCTION ENGINE",23,"f2bc88")
	label(caption,"It ended an era. You brought a revolver.",16,"bcb4b5")
	var news=PanelContainer.new()
	news.position=Vector2(875,110);news.size=Vector2(450,250)
	news.add_theme_stylebox_override("panel",UIArt.button_style())
	menu_root.add_child(news)
	var info=VBoxContainer.new();info.add_theme_constant_override("separation",12);news.add_child(info)
	label(info,"LATEST INFO / "+PatchNotes.VERSION,16,"d3ad69").add_theme_font_override("font",UIArt.heading_font())
	label(info,PatchNotes.TITLE,25,"eed8ac")
	var teaser=label(info,"News from the rift. See what changed in the latest update.",18,"c6baa3")
	teaser.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button(info,"Open patch notes",patch_notes,true)
	audio.tension = 0.1
	audio.biome = -1

func texture(index):
	if index>=3:
		var image=load("res://assets/"+("iona" if index==3 else "orin")+"-walk.png")
		var r=JSON.parse_string(FileAccess.get_file_as_string("res://assets/walk-regions.json"))[index][1]
		var portrait=AtlasTexture.new()
		portrait.atlas=image
		portrait.region=Rect2(r[0],r[1],r[2],r[3])
		return portrait
	var t = AtlasTexture.new()
	t.atlas = world.atlas
	var cell_size = Vector2(world.atlas.get_size())/3
	t.region = Rect2(Vector2(index%3,floori(index/3.0))*cell_size,cell_size)
	return t

func characters():
	page = "characters"
	clear_menu()
	shade(0.91)
	var head = column(menu_root,Vector2(80,45),Vector2(1280,100))
	label(head,"CHOOSE WHO HISTORY FORGOT",16,"d1ae77")
	label(head,"Five survivors. New frontiers.",40)
	var row = HBoxContainer.new()
	row.position = Vector2(80,168)
	row.size = Vector2(1280,540)
	row.add_theme_constant_override("separation",22)
	menu_root.add_child(row)
	for i in range(C.HEROES.size()):
		var data = C.HEROES[i]
		var panel = PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.custom_minimum_size.x = 238
		panel.add_theme_stylebox_override("panel",box(Color("172830"),Color(data.color) if selected==i else Color("394950")))
		row.add_child(panel)
		var v = VBoxContainer.new()
		v.add_theme_constant_override("separation",13)
		panel.add_child(v)
		label(v,data.title,14,data.color).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var art = TextureRect.new()
		art.texture = texture(i)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.custom_minimum_size = Vector2(170,215)
		v.add_child(art)
		label(v,data.name,23)
		var desc = label(v,data.desc,15,"bac8c8")
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size.y = 110
		var unlocked = chosen_mode!="expedition" or Discoveries.hero_open(save_data,i)
		var choose = button(v,"SELECTED" if selected==i and unlocked else "CHOOSE" if unlocked else "LOCKED",func():selected=i;characters(),selected==i and unlocked)
		choose.add_theme_font_size_override("font_size",13)
		choose.disabled = not unlocked
	var bottom = column(menu_root,Vector2(80,742),Vector2(1280,120),8)
	var actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation",18)
	bottom.add_child(actions)
	button(actions,"← Back",main_menu)
	button(actions,"CHOOSE MAP" if chosen_mode=="expedition" else "BEGIN / "+chosen_mode.to_upper(),maps_menu if chosen_mode=="expedition" else start_run,true).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label(bottom,"WASD / arrows to move  •  Auto-aim, auto-fire  •  Esc to pause  •  F11 fullscreen",17,"9fb5b5")
	if chosen_mode=="safari": label(bottom,"Prepared evolved build. No progression rewards. The meteor is still lethal.",15,"eab685")
	if chosen_mode=="daily": label(bottom,"Same daily seed. No permanent upgrades. Records stay local to this computer.",15,"eab685")

func maps_menu():
	page="maps"
	clear_menu()
	shade(0.93)
	label(menu_root,"CHOOSE AN EXPEDITION",36,"efd6a7").position=Vector2(80,65)
	label(menu_root,"Each map has three biome sections, its own terrain, score and ecosystem.",19,"adc6ca").position=Vector2(80,120)
	var index=0
	for id in Maps.DATA:
		var d=Maps.DATA[id]
		var v=column(menu_root,Vector2(80+index*435,195),Vector2(405,520),18)
		Icons.control(v,"camp" if index==0 else "frost" if index==1 else "clock","relic",125)
		label(v,d.name,27,d.color)
		var desc=label(v,d.desc,18,"bcd0d5")
		desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size.y=105
		label(v," → ".join(d.biomes),15,"acbec6").autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		var unlocked=Maps.available(save_data,id)
		label(v,"READY TO EXPLORE" if unlocked else Campaign.requirement(save_data,d.unlock),16,d.color)
		var play=button(v,"ENTER MAP" if unlocked else "LOCKED",func():selected_map=id;start_run(),unlocked)
		play.disabled=not unlocked
		index+=1
	var back=button(menu_root,"← Survivors",characters)
	back.position=Vector2(80,780)
	back.size=Vector2(1280,55)

func flush_campaign(force=false):
	if sim==null or sim.mode!="expedition": return
	Campaign.ensure(save_data)
	var progress=save_data.campaign
	var added=maxi(0,sim.kills-campaign_last_kills)
	progress.kills+=added
	progress.map_kills[sim.map_id]=progress.map_kills.get(sim.map_id,0)+added
	progress.bosses+=maxi(0,sim.campaign_bosses-campaign_last_bosses)
	campaign_last_kills=sim.kills
	campaign_last_bosses=sim.campaign_bosses
	var earned=Campaign.evaluate(save_data)
	if not earned.is_empty():
		var names=[]
		for id in earned: names.append(Discoveries.ENTRIES[id].name)
		show_toast("PERMANENT UNLOCK",", ".join(names))
		sim.configure_content(save_data)
	if force or not earned.is_empty() or campaign_save_clock>=15:
		persist()
		campaign_save_clock=0

func start_run():
	if chosen_mode=="expedition" and not Discoveries.hero_open(save_data,selected): selected = 2
	release_run()
	clear_menu()
	page = "playing"
	paused = false
	finish_delay = -1
	sim = Expedition.new()
	sim.effect.connect(world.fx)
	sim.sound.connect(func(id):audio.play(id))
	sim.banner.connect(show_toast)
	sim.choice_requested.connect(present_upgrade)
	sim.ended.connect(run_ended)
	sim.discovered_content.connect(on_discovery)
	world.sim = sim
	daily_date=Time.get_date_string_from_system(true)
	var seed_value = hash("daily-"+Expedition.Daily.RULESET+"/"+daily_date) if chosen_mode=="daily" else 0
	campaign_last_kills=0
	campaign_last_bosses=0
	campaign_clock=0
	campaign_save_clock=0
	if chosen_mode=="expedition" and not Maps.available(save_data,selected_map): selected_map="cradle"
	sim.setup(selected,chosen_mode,save_data.research,seed_value,selected_map if chosen_mode=="expedition" else "cradle")
	if chosen_mode=="expedition": sim.configure_content(save_data)
	sim.update_exploration()
	hud_root.show()
	show_toast("HISTORY HAS NO RECORD OF THIS","SURVIVE / ADAPT / DENY EXTINCTION")
	if chosen_mode == "safari": show_toast("THE EXTINCTION ENGINE","BREAK THE THREE ANCHORS / EXPOSE THE CORE")

func daily_menu():
	chosen_mode="daily"
	page="daily"
	clear_menu();shade(0.92)
	var plan=Expedition.Daily.plan(hash("daily-"+Expedition.Daily.RULESET+"/"+Time.get_date_string_from_system(true)))
	var v=column(menu_root,Vector2(170,100),Vector2(1100,700),20)
	label(v,"DAILY EXPEDITION / "+Time.get_date_string_from_system(true),22,"e6c58c")
	label(v,C.HEROES[plan.hero].name+" / "+Maps.DATA[plan.map].name,34)
	label(v,"A random build. One shared daily seed. Survive as long as you can.",24)
	label(v,"Play normally. Every level-up rolls the usual choices and picks one for you.\nChests use normal rarity, evolution and replacement rules — fate makes the decisions.",20,"b2cdd3")
	Icons.control(v,C.HEROES[plan.hero].weapon,"weapon",100)
	label(v,"STARTING WEAPON / "+C.WEAPONS[C.HEROES[plan.hero].weapon].name,21,"e0cfab")
	label(v,"No fixed build list. New content joins through the normal reward pools.\nNo permanent bonuses or rerolls. Defeat the meteor to enter a harder circuit.\nKeep going until you die. Longest survival wins; kills and score break ties.",19,"e0cfab")
	button(v,"PLAY TODAY'S BUILD",func():selected=plan.hero;start_run(),true)
	button(v,"Daily leaderboard / this computer",daily_records_menu)
	button(v,"Main menu",main_menu)

func build_hud():
	for rect in [Rect2(0,827,1440,73)]:
		var back = ColorRect.new()
		back.position = rect.position
		back.size = rect.size
		back.color = Color(0.015,0.025,0.036,0.72)
		back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hud_root.add_child(back)
	score_plate=UIArt.plate(hud_root,0,Rect2(1080,10,350,96))
	timer_plate=UIArt.plate(hud_root,1,Rect2(8,8,420,116))
	var left = column(hud_root,Vector2(30,24),Vector2(300,100),7)
	left.visible = false
	health_label = label(left,"",19,"eed5af")
	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(300,18)
	health_bar.show_percentage = false
	health_bar.add_theme_stylebox_override("background",box(Color("312834"),Color("4a3640"),5))
	health_bar.add_theme_stylebox_override("fill",box(Color("ea8172"),Color("ffab89"),5))
	left.add_child(health_bar)
	xp_bar = preload("res://scripts/experience_bar.gd").new()
	xp_bar.position = Vector2(30,876)
	xp_bar.size = Vector2(1380,22)
	xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(xp_bar)
	timer_label = label(hud_root,"",36)
	timer_label.position = Vector2(610,18)
	biome_label = label(hud_root,"",14,"95b5b7")
	biome_label.position = Vector2(530,65)
	biome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	biome_label.custom_minimum_size.x = 0
	biome_label.size=Vector2(265,53)
	biome_label.clip_text=true
	biome_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	score_label = label(hud_root,"",20,"ead9a7")
	score_label.position = Vector2(1110,28)
	loadout_label = label(hud_root,"",13,"e8cf9a")
	loadout_label.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
	loadout_label.add_theme_font_override("font",UIArt.heading_font())
	loadout_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	loadout_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	loadout_label.position = Vector2(1110,832)
	var backpack = preload("res://scripts/backpack.gd").new()
	backpack.game = self
	backpack.position = Vector2(30,830)
	backpack.size = Vector2(290,92)
	weapons_hud = backpack
	backpack.mouse_filter = Control.MOUSE_FILTER_PASS
	hud_root.add_child(backpack)
	buffs_hud = preload("res://scripts/backpack.gd").new()
	buffs_hud.game = self
	buffs_hud.buffs_only = true
	buffs_hud.size = Vector2(360,315)
	buffs_hud.mouse_filter = Control.MOUSE_FILTER_PASS
	hud_root.add_child(buffs_hud)
	var player_health = preload("res://scripts/player_health.gd").new()
	player_health.game = self
	hud_root.add_child(player_health)
	var navigation = preload("res://scripts/navigation.gd").new()
	navigation.game = self
	navigation.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(navigation)
	objective_label = label(hud_root,"",17,"c7b2ed")
	objective_label.position = Vector2(30,130)
	toast_panel = PanelContainer.new()
	toast_panel.position = Vector2(270,687)
	toast_panel.size = Vector2(900,84)
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.add_theme_stylebox_override("panel",box(Color(0.025,0.045,0.065,0.88),Color(0.6,0.48,0.3,0.65)))
	hud_root.add_child(toast_panel)
	toast_label = label(hud_root,"",21,"ffe5b4")
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.position = Vector2(280,698)
	toast_label.size = Vector2(880,69)
	boss_panel = PanelContainer.new()
	boss_panel.position = Vector2(285,80)
	boss_panel.size = Vector2(870,96)
	boss_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_panel.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	hud_root.add_child(boss_panel)
	boss_label = label(hud_root,"",19,"ffd1a1")
	boss_label.position = Vector2(300,83)
	boss_label.size = Vector2(840,65)
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_bar = preload("res://scripts/boss_bar.gd").new()
	boss_bar.position = Vector2(390,51)
	boss_bar.size = Vector2(660,165)
	boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(boss_bar)

func show_toast(title,subtitle):
	toast_label.text = title+"\n"+subtitle
	toast_time = 1.8 if sim!=null and sim.boss!=null else 3.0

func _physics_process(dt):
	if sim == null or paused or not sim.active: return
	var d = Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	sim.tick(dt,d)

func update_hud_scale():
	var viewport = get_viewport_rect().size
	var offset = (viewport-Vector2(1440,900))/2
	world.position = offset
	menu_root.position = offset
	var pixel_ratio = maxf(0.1,get_viewport().get_screen_transform().get_scale().y)
	var factor = clampf(float(save_data.settings.get("hud_scale",1.0)),0.65,1.35)
	for entry in hud_layout:
		var p = entry.position
		var anchor = Vector2(0 if p.x<150 else 1440 if p.x>1000 else 720,900 if p.y>650 else 0)
		var destination = Vector2(0 if anchor.x==0 else viewport.x if anchor.x==1440 else viewport.x/2,viewport.y if anchor.y==900 else 0)
		entry.node.scale = Vector2.ONE*factor
		entry.node.position = destination+(p-anchor)*factor
	# Each region has an explicit owner. No independently scaled overlapping text.
	timer_plate.position=Vector2(20,18)*factor
	timer_plate.size=Vector2(540,140)
	score_plate.position=Vector2(viewport.x-378*factor,18*factor)
	timer_label.position=Vector2(354,67)*factor
	timer_label.add_theme_font_override("font",UIArt.heading_font())
	timer_label.add_theme_font_size_override("font_size",23)
	timer_label.size=Vector2(92,36)
	timer_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	biome_label.position=Vector2(112,64)*factor
	biome_label.add_theme_font_override("font",UIArt.heading_font())
	biome_label.add_theme_font_size_override("font_size",15)
	biome_label.size=Vector2(232,60)
	biome_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	score_label.position=Vector2(viewport.x-318*factor,49*factor)
	score_label.size=Vector2(242,38)
	score_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_override("font",UIArt.heading_font())
	score_label.add_theme_font_size_override("font_size",23)
	var boss_y=150.0 if viewport.x<1900*factor else 12.0
	boss_bar.position = Vector2(viewport.x/2-330*factor,(boss_y+5)*factor)
	boss_label.position = Vector2(viewport.x/2-420*factor,boss_y*factor)
	boss_label.size = Vector2(840,65)
	weapons_hud.scale = Vector2.ONE*factor
	weapons_hud.position = Vector2(56*factor,viewport.y-116*factor)
	weapons_hud.size=Vector2(250,62)
	buffs_hud.scale = Vector2.ONE*factor
	buffs_hud.position = Vector2(viewport.x-384*factor,120*factor)
	buff_label.visible = false
	loadout_label.position=Vector2(viewport.x-347*factor,viewport.y-112*factor)
	loadout_label.size=Vector2(285,58)
	loadout_label.add_theme_font_size_override("font_size",15)
	objective_label.position = Vector2(24,150)*factor
	xp_bar.scale=Vector2.ONE*factor
	xp_bar.position = Vector2(24*factor,viewport.y-130*factor)
	xp_bar.size = Vector2(viewport.x/factor-48,106)
	var dock_visible=sim!=null and not sim.choosing and page!="upgrade"
	if sim!=null:hud_root.visible=page not in ["upgrade","summary"]
	xp_bar.visible=dock_visible
	weapons_hud.visible=dock_visible
	loadout_label.visible=dock_visible
	for child in hud_root.get_children():
		if child is ColorRect:
			child.position = Vector2(0,viewport.y-110)
			child.size = Vector2(viewport.x,110)
			child.visible=false
	for child in menu_root.get_children():
		if child is ColorRect:
			child.position = -offset
			child.size = viewport

func _process(dt):
	update_hud_scale()
	ui_clock += dt
	toast_time = maxf(0,toast_time-dt)
	if toast_label: toast_label.modulate.a = minf(1,toast_time)
	if toast_panel:
		toast_panel.modulate.a = minf(1,toast_time)
		toast_panel.visible = sim!=null and not sim.choosing and toast_time>0
	if finish_delay>=0:
		finish_delay -= dt
		if finish_delay<0: summary()
	if sim == null: return
	if sim.active and not paused:
		campaign_clock+=dt
		campaign_save_clock+=dt
		if campaign_clock>=1:
			campaign_clock=0
			flush_campaign()
	toast_label.visible = not sim.choosing
	health_label.text = "%s   %s / %s"%[C.HEROES[sim.hero].name,int(maxf(0,sim.hp)),int(sim.max_hp)]
	health_bar.value = sim.hp/sim.max_hp*100
	xp_bar.set_progress(sim.xp,sim.xp_goal,sim.level,dt)
	timer_label.text = "%02d:%02d"%[int(sim.time)/60,int(sim.time)%60]
	biome_label.text = Maps.biome(sim.map_id,sim.depth).name
	if sim.mode=="daily":biome_label.text="CIRCUIT %s / "%[sim.daily_loop+1]+Maps.biome(sim.map_id,sim.depth).name
	if sim.active and sim.boss==null and sim.portal==null:
		var remaining = maxi(0,ceili(sim.next_boss-sim.time))
		biome_label.text += "\nNEXT BOSS IN %02d:%02d"%[remaining/60,remaining%60]
	score_label.text = "%s  SCORE"%sim.score
	var weapon_text = []
	for id in sim.weapons:
		weapon_text.append(C.WEAPONS[id].evolution if sim.weapons[id].evolved else "%s %s"%[C.WEAPONS[id].name,sim.weapons[id].level])
	var relic_text = []
	for id in sim.relics: relic_text.append(C.RELICS[id].name)
	loadout_label.text = "Amber %s  ·  %s\n[Tab] Map    [B] Backpack"%[sim.amber,"FATE DECIDES" if sim.mode=="daily" else "Rerolls %s"%sim.rerolls]
	loadout_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	loadout_label.size = Vector2(285,58)
	UIArt.fit_label(loadout_label,15)
	UIArt.fit_label(timer_label,23)
	UIArt.fit_label(biome_label,15)
	UIArt.fit_label(score_label,23)
	boss_bar.visible = sim.boss!=null
	boss_label.visible = sim.boss!=null
	boss_panel.visible = sim.boss!=null
	if sim.boss!=null:
		boss_bar.value = sim.boss.hp/sim.boss.max_hp*100
		boss_bar.health=sim.boss.hp
		boss_bar.maximum=sim.boss.max_hp
		boss_label.text = Maps.boss_name(sim.map_id,sim.boss_stage)+" / PHASE %s"%sim.phase
		if sim.boss_stage<3:
			boss_label.text += " / %s%%"%ceili(sim.boss.hp/sim.boss.max_hp*100)
			if sim.boss.get("reform",0)>0: boss_label.text += " / CARAPACE BREAK"
		if sim.boss_stage==3:
			boss_label.text += "\n"+("%s ANCHORS / ARMORED"%sim.anchors.size() if not sim.anchors.is_empty() else "CORE EXPOSED / %.1fs"%sim.core_time)+"   ·   EXTINCTION IN %ss"%maxi(0,int(210-sim.boss_time))
	objective_label.text = ""
	if sim.portal!=null:
		objective_label.text = "RIFT / %sm · %ss · ENEMY HP ×%.1f / DMG ×%.1f"%[int(sim.pos.distance_to(sim.portal)/10),int(sim.linger),sim.linger_health(),sim.linger_damage()]
	elif sim.shrine_progress>0 and not sim.shrine_done:
		objective_label.text = "HOLD THE RIFT: %s / %s"%[int(sim.shrine_progress),int(sim.RIFT_CHARGE_SECONDS)]
	audio.tension = clampf(sim.time/1000+(0.3 if sim.boss!=null else 0),0,1)
	audio.biome = sim.depth
	audio.map_index = Maps.DATA[sim.map_id].music
	var buffs = []
	if sim.shield>0: buffs.append("BARRIER %s"%int(sim.shield))
	for id in sim.buffs:
		if sim.buffs[id]>0: buffs.append("%s / %ss"%[id.to_upper(),ceili(sim.buffs[id])])
	if not sim.director.current.is_empty(): buffs.append("HORDE / %ss"%ceili(sim.director.current.at+sim.director.current.duration-sim.time))
	buff_label.text = "   ·   ".join(buffs)

func _input(event):
	if not event is InputEventKey or not event.pressed or event.echo: return
	if sim!=null and sim.active and not sim.choosing:
		if event.keycode in [KEY_TAB,KEY_M]:
			if page=="map": resume()
			else: map_menu()
			get_viewport().set_input_as_handled()
			return
		if event.keycode==KEY_B:
			if page=="ledger": resume()
			else: ledger_menu()
			get_viewport().set_input_as_handled()
			return

func _unhandled_key_input(event):
	if not event.pressed or event.echo: return
	if page=="upgrade" and event.keycode==KEY_R:
		sim.reroll_choices()
		return
	if event.keycode==KEY_F11:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
	if event.keycode==KEY_ESCAPE:
		if page=="map":
			resume()
			return
		if sim!=null and sim.active and not sim.choosing:
			if paused: resume()
			else: pause_menu()
	if sim!=null and sim.choosing:
		var index = [KEY_1,KEY_2,KEY_3].find(event.keycode)
		if index>=0: pick_upgrade(index)

func item_icon(parent,index,pickup = true,size_value = 76):
	var icon = TextureRect.new()
	var texture = AtlasTexture.new()
	texture.atlas = preload("res://assets/pickups.png") if pickup else preload("res://assets/weapon-fx.png")
	var columns = 3 if pickup else 4
	var rows = 3 if pickup else 2
	var cell_size = Vector2(texture.atlas.get_size())/Vector2(columns,rows)
	texture.region = Rect2(Vector2(index%columns,floori(float(index)/columns))*cell_size,cell_size)
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(size_value,size_value)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)
	return icon

func daily_reel_data(o):
	var data=(C.WEAPONS.get(o.id,C.PASSIVES.get(o.id,C.AUGMENTS.get(o.id,C.RELICS.get(o.id,{"name":"Field supplies","desc":"Gain amber and restore health."}))))).duplicate(true)
	data.art_id=o.id;data.art_type=o.type;data.rarity=o.get("rarity",data.get("rarity","COMMON"));data.color=data.get("color","d6b878")
	return data

func present_upgrade(opts,relic):
	var run = sim
	reveal_index = -1
	if relic or sim.mode=="daily":
		page = "relic-spin"
		clear_menu()
		var reel = preload("res://scripts/relic_reel.gd").new()
		reel.size = Vector2(1440,900)
		reel.reward = opts[0].id
		var o = opts[0]
		var chest_data = (C.RELICS[o.id] if o.type=="relic" else C.PASSIVES[o.id] if o.type=="passive" else C.AUGMENTS[o.id] if o.type=="augment" else {"name":"Field Supplies","desc":"+25 amber and restore 15 health.","color":"eac786"} if o.type=="supplies" else C.WEAPONS[o.id]).duplicate(true)
		chest_data.art_id = o.id
		chest_data.art_type = o.type
		chest_data.color = chest_data.get("color","c4dfff")
		if o.type in ["fusion","evolution"]:
			chest_data.name = chest_data.evolution
			chest_data.rarity = "LEGENDARY"
			chest_data.icon = 6
			chest_data.desc = chest_data.desc if o.type=="fusion" else chest_data.evolution_desc
			reel.reveal_title = "MERGING / TWO WEAPONS BECOME ONE" if o.type=="fusion" else "WEAPON EVOLUTION"
			if o.type=="fusion":
				reel.ingredients = sim.Evolutions.UNIONS[o.id].parts
				reel.new_combination = o.id not in save_data.recipes
		else:
			reel.odds = sim.relic_state.get("chest_odds",sim.Relics.odds(sim))
			chest_data.rarity = o.get("rarity",chest_data.get("rarity","COMMON"))
			if o.get("refinement",false):
				reel.reveal_title = "SATCHEL FULL / THE RIFT REFINES YOUR BUILD"
				chest_data.desc = "Rank +1 / "+chest_data.desc if o.type!="supplies" else chest_data.desc
				reel.odds_caption = "RELIC RARITY ODDS / NON-REPLACEMENT FINDS BECOME A COMPATIBLE UPGRADE OR SUPPLIES"
			if o.has("replace") and sim.mode!="daily":
				reel.reveal_title = "RELIC CHALLENGER / YOUR SATCHEL IS FULL"
				reel.replacement_data = C.RELICS[o.replace]
		if sim.mode=="daily" and not relic:
			reel.daily_level=true
			reel.reveal_title="FATE CHOOSES / LEVEL %s"%sim.level
			reel.odds=[]
			for candidate in o.get("daily_offered",[]):reel.offered_data.append(daily_reel_data(candidate))
			chest_data.desc=UpgradeCopy.description(sim,o).replace("\n"," / ")
		reel.reward_data = chest_data
		reel.audio = audio
		menu_root.add_child(reel)
		reel.awarded.connect(func():
			if sim==run and sim.choosing and page=="relic-spin":
				var data = chest_data
				if reel.keep_existing:
					sim.options[0] = {"type":"supplies","id":"supplies","salvaged":o.id}
				world.fx("evolve" if data.rarity in ["EPIC","LEGENDARY","ARTIFACT"] else "ring",sim.pos,Color(data.color),350)
				finish_upgrade(0)
				show_toast("SALVAGED / +25 AMBER" if reel.keep_existing else data.name,"CURRENT RELIC KEPT" if reel.keep_existing else "BUILD REFINED" if o.get("refinement",false) else "WEAPON TRANSFORMED" if o.type!="relic" else data.rarity+" RELIC BOUND"))
		return
	page = "anticipation"
	await get_tree().create_timer(0.16).timeout
	if sim==run and sim.choosing: upgrade_menu(opts,false)

func upgrade_menu(opts,relic):
	page = "upgrade"
	clear_menu()
	shade(0.82)
	var head = column(menu_root,Vector2(95,95),Vector2(1250,110))
	var tier=label(head,"RELIC RECOVERED" if relic else "LEVEL %s / CHOOSE YOUR POWER"%sim.level,17,"c7a76b")
	tier.add_theme_font_override("font",UIArt.heading_font())
	label(head,"Take something dangerous" if relic else "Become their extinction",32,"d9bd83")
	label(menu_root,"Weapons %s / 5  ·  Upgrade your build or fill an empty slot."%sim.weapons.size(),16,"c6baa3").position = Vector2(95,202)
	var row = HBoxContainer.new()
	var reward_width = minf(1250,opts.size()*400+maxi(0,opts.size()-1)*22)
	row.position = Vector2((1440-reward_width)/2,230)
	row.size = Vector2(reward_width,535)
	row.add_theme_constant_override("separation",22)
	menu_root.add_child(row)
	for i in range(opts.size()):
		var o = opts[i]
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(400,535)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel",UIArt.style())
		row.add_child(panel)
		var v = VBoxContainer.new()
		v.add_theme_constant_override("separation",6)
		panel.add_child(v)
		var data = C.RELICS[o.id] if o.type=="relic" else C.PASSIVES[o.id] if o.type=="passive" else C.AUGMENTS[o.id] if o.type=="augment" else {"name":"Amber Supplies","desc":"+25 amber and restore 15 health."} if o.type=="supplies" else C.WEAPONS[o.id]
		var rarity = "EVOLUTION" if o.type=="evolution" else data.get("rarity","RARE" if o.type=="augment" else "")
		if rarity in ["LEGENDARY","EVOLUTION"]: panel.self_modulate=Color("fff0cd")
		if not rarity.is_empty(): panel.tooltip_text=rarity
		Icons.control(v,"lens" if o.type=="supplies" else o.id,"relic" if o.type=="supplies" else o.type,32)
		var title = data.evolution if o.type=="evolution" else data.name
		var name_label = label(v,title,23)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var desc = UpgradeCopy.description(sim,o)
		var affected=UpgradeCopy.affected(sim,o)
		label(v,"AFFECTED WEAPONS" if not affected.is_empty() else "NEW WEAPON" if o.type=="weapon" else "SURVIVOR BONUS",13,"e2c691")
		var icon_row=HBoxContainer.new();icon_row.add_theme_constant_override("separation",6);v.add_child(icon_row)
		for id in affected:
			var icon=Icons.control(icon_row,id,"weapon",36)
			icon.tooltip_text=C.WEAPONS[id].name
			icon.mouse_filter=Control.MOUSE_FILTER_PASS
		if o.type=="weapon":
			desc+="\nMax rank + chest: evolves."
			var hint=sim.Evolutions.hint(o.id,C.WEAPONS)
			if hint!="": panel.tooltip_text=hint
		var description = label(v,desc,16,"c6cbbf")
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var take=button(v,"TAKE IT / %s"%(i+1),func():pick_upgrade(i),true)
		take.set_meta("inset_button",true)
		for state in ["normal","hover","pressed","disabled"]:take.add_theme_stylebox_override(state,UIArt.inset_button_style(state))
		panel.modulate.a = 0
		panel.pivot_offset = Vector2(200,245)
		panel.scale = Vector2.ONE*0.96
		var tween = create_tween()
		tween.tween_interval(i*0.09)
		tween.tween_property(panel,"modulate:a",1.0,0.2)
		tween.parallel().tween_property(panel,"scale",Vector2.ONE,0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	label(menu_root,"1 / 2 / 3 to choose. Buff types %s / 8. One offensive aura."%sim.buff_slots_used(),18,"95aeae").position=Vector2(95,800)
	var reroll = button(menu_root,"R / REROLL (%s)"%sim.rerolls,func():sim.reroll_choices())
	reroll.position = Vector2(1015,785)
	reroll.size = Vector2(320,58)
	reroll.disabled = sim.rerolls<=0

func pick_upgrade(index):
	if sim==null or not sim.choosing or index>=sim.options.size() or page!="upgrade": return
	finish_upgrade(index)

func finish_upgrade(index):
	var option = sim.options[index]
	if option.type=="fusion" and sim.mode=="expedition" and option.id not in save_data.recipes:
		save_data.recipes.append(option.id)
		persist()
	sim.choose(index)
	clear_menu()
	page = "playing"

func pause_menu():
	paused = true
	page = "pause"
	clear_menu()
	shade()
	var v = column(menu_root,Vector2(470,210),Vector2(500,500),18)
	label(v,"THE APOCALYPSE CAN WAIT.",16,"c4b69e")
	label(v,"Take a breath.",45)
	button(v,"Resume",resume,true)
	button(v,"TAB / Overlay map",map_menu)
	button(v,"B / Backpack & stats",ledger_menu)
	button(v,"Settings",settings)
	button(v,"End expedition / bank amber",func():sim.death_reason="You withdrew from the rift.";sim.finish(false))

func resume():
	paused = false
	page = "playing"
	clear_menu()

func on_discovery(id):
	if sim.mode!="expedition" or id in save_data.discoveries: return
	save_data.discoveries.append(id)
	if Discoveries.ENTRIES[id].cost==0 and id not in save_data.unlocks: save_data.unlocks.append(id)
	persist()

func scrolling_body(y = 185,height = 555):
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(100,y)
	scroll.size = Vector2(1240,height)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu_root.add_child(scroll)
	var body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",12)
	scroll.add_child(body)
	return body

func discovery_menu():
	page = "discoveries"
	clear_menu()
	shade(0.96)
	label(menu_root,"THE DISCOVERY ARCHIVE",36,"f0d5a0").position = Vector2(100,55)
	label(menu_root,"%s AMBER  /  Kill milestones unlock automatically. Explore signals with Tab for other discoveries."%save_data.amber,18,"afc6cf").position = Vector2(100,113)
	var body = scrolling_body()
	for id in Discoveries.ENTRIES:
		var d = Discoveries.ENTRIES[id]
		var found = id in save_data.discoveries
		var bought = id in save_data.unlocks
		var panel = PanelContainer.new()
		panel.add_theme_stylebox_override("panel",UIArt.button_style())
		body.add_child(panel)
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation",16)
		panel.add_child(row)
		if d.has("hero"):
			var portrait = TextureRect.new()
			portrait.texture = texture(d.hero)
			portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			portrait.custom_minimum_size = Vector2(60,60)
			row.add_child(portrait)
		elif id in ["map_frost","map_observatory"]:
			Icons.control(row,id,"discovery",60)
		else:
			var category = "weapon" if d.has("weapons") else "augment" if d.has("augments") else "relic"
			var id_list = d.get("weapons",d.get("augments",d.get("relics",["tablet"])))
			Icons.control(row,id_list[0],category,60)
		var text = VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		label(text,d.name,23,"e9d2a9").autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		label(text,Campaign.requirement(save_data,id),14,"dfb67a").autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		label(text,d.desc,16,"b3c5cb").autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		var buy_button = button(row,"UNLOCKED" if bought else "%s AMBER"%d.cost if found else "IN PROGRESS" if d.has("goal") else "UNDISCOVERED",func():
			if preload("res://scripts/archive_respec.gd").buy_discovery(save_data,id):
				persist()
				discovery_menu())
		buy_button.custom_minimum_size.x = 220
		buy_button.disabled = bought or not found or save_data.amber<d.cost
	label(body,"DISCOVERED COMBINATIONS / %s"%save_data.recipes.size(),23,"d6b580")
	if save_data.recipes.is_empty(): label(body,"Max both compatible weapons to rank 10, then open a chest.",18,"b3c5cb")
	for id in save_data.recipes:
		if not C.WEAPONS.has(id): continue
		var parts = Expedition.Evolutions.UNIONS[id].parts
		label(body,"%s + %s → %s"%[C.WEAPONS[parts[0]].name,C.WEAPONS[parts[1]].name,C.WEAPONS[id].name],21,"e6d2b2")
	var back = button(menu_root,"← Main menu",main_menu)
	back.position = Vector2(100,780)
	back.size = Vector2(605,60)
	var refund=button(menu_root,"Refund paid unlocks",func():archive_refund_menu(false))
	refund.position=Vector2(720,780);refund.size=Vector2(620,60)
	refund.disabled=preload("res://scripts/archive_respec.gd").discovery_total(save_data)<=0

func map_menu():
	paused = false
	page = "map"
	clear_menu()
	var map = preload("res://scripts/expedition_map.gd").new()
	map.game = self
	map.size = Vector2(1440,900)
	map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_root.add_child(map)


func ledger_menu():
	paused = true
	page = "ledger"
	clear_menu()
	shade(0.97)
	var panel = preload("res://scripts/backpack_panel.gd").new()
	panel.game = self
	panel.size = Vector2(1440,900)
	menu_root.add_child(panel)

func run_ended(victory):
	flush_campaign(true)
	if sim.mode=="expedition" and victory:
		save_data.campaign.map_wins[sim.map_id]=save_data.campaign.map_wins.get(sim.map_id,0)+1
	paused = true
	clear_menu()
	if sim.mode!="safari":
		save_data.runs += 1
		save_data.wins += 1 if victory else 0
		save_data.amber += int(sim.amber*sim.fortune)
		save_data.records.append({"date":Time.get_date_string_from_system(),"hero":C.HEROES[sim.hero].name,"map":sim.map_id,"mode":sim.mode,"score":sim.score,"won":victory,"ruleset":"0.8"})
		if sim.mode=="daily":
			if not save_data.has("daily_records"):save_data.daily_records=[]
			save_data.daily_records.append({"date":daily_date,"seconds":sim.time,"kills":sim.kills,"score":sim.score,"bosses":sim.campaign_bosses,"circuit":sim.daily_loop+1,"seed":sim.daily_plan.seed,"ruleset":Expedition.Daily.RULESET})
			if save_data.daily_records.size()>200:save_data.daily_records=save_data.daily_records.slice(-200)
		save_data.records.sort_custom(func(a,b):return a.score>b.score)
		save_data.records = save_data.records.slice(0,20)
		persist()
	export_report(false)
	if victory:
		show_toast("EXTINCTION DENIED","HISTORY WILL REMEMBER THIS")
		for i in range(12): world.fx("victory",sim.pos+Vector2.from_angle(i*TAU/12)*180,Color("ffbf82"),320)
		finish_delay = 3.5
	elif sim.extinction_timeout:
		page="extinction-ending"
		hud_root.hide()
		defeat_cinematic=preload("res://scripts/extinction_end.gd").new()
		defeat_cinematic.world=world;defeat_cinematic.audio=audio
		layer.add_child(defeat_cinematic)
		finish_delay=5.2
	else: summary()

func summary():
	if is_instance_valid(defeat_cinematic):
		defeat_cinematic.set_process(false)
		defeat_cinematic.caption.hide()
		layer.move_child(defeat_cinematic,0)
	page="summary";clear_menu();shade(1.0 if sim.extinction_timeout else 0.82)
	hud_root.hide()
	UIArt.plate(menu_root,2,Rect2(90,12,1260,770))
	# This inset excludes the skull crest and the lower corner fossils. All
	# results belong to it, rather than treating the art's outer bounds as usable.
	var content=Control.new();content.name="SummaryContent"
	content.position=Vector2(235,218);content.size=Vector2(970,390);menu_root.add_child(content)
	var title=label(content,"EXTINCTION DENIED" if sim.won else "EXPEDITION COMPLETE",32,"f4d49b")
	title.size=Vector2(970,42)
	var detail=label(content,"%s · %02d:%02d · %s · %s"%[C.HEROES[sim.hero].name,int(sim.time)/60,int(sim.time)%60,sim.mode.to_upper(),Maps.DATA[sim.map_id].name],18,"b7cbd0")
	detail.position=Vector2(0,45);detail.size=Vector2(970,25);detail.clip_text=true;UIArt.fit_label(detail,18)
	if not sim.won:
		var reason=label(content,sim.death_reason,15,"ecb4a4")
		reason.position=Vector2(0,69);reason.size=Vector2(970,22);reason.clip_text=true;UIArt.fit_label(reason,15)
	var metrics=[["SCORE",sim.score],["KILLS",sim.kills],["AMBER",0 if sim.mode=="safari" else int(sim.amber*sim.fortune)],["BEST STREAK",sim.best_streak],["PEAK HORDE",sim.peak_enemies],["HITS TAKEN",sim.hits]]
	for i in range(metrics.size()):
		var x=(i%3)*330;var y=98+(i/3)*55
		var caption=label(content,metrics[i][0],13,"afbdc2");caption.position=Vector2(x,y)
		var value=label(content,str(metrics[i][1]),24,"f0d098");value.position=Vector2(x,y+17);value.size=Vector2(290,32);value.clip_text=true;UIArt.fit_label(value,24)
	for heading in [["WEAPON",0],["DAMAGE",470],["SHARE",785]]:
		label(content,heading[0],14,"b7cbd0").position=Vector2(heading[1],209)
	var ids=sim.damage_by_weapon.keys();ids.sort_custom(func(a,b):return sim.damage_by_weapon[a]>sim.damage_by_weapon[b])
	var total=maxf(1,sim.damage_total)
	for i in range(mini(5,ids.size())):
		var id=ids[i];var damage=sim.damage_by_weapon[id];var y=236+i*28
		var icon=Icons.control(content,id,"weapon",24);icon.position=Vector2(0,y)
		var name_label=label(content,C.WEAPONS.get(id,{"name":"Relics"}).name,17,"e4d9c3")
		name_label.position=Vector2(34,y);name_label.size=Vector2(420,25);name_label.clip_text=true;UIArt.fit_label(name_label,17)
		var damage_label=label(content,str(int(damage)),17);damage_label.position=Vector2(470,y);damage_label.size=Vector2(295,25);damage_label.clip_text=true;UIArt.fit_label(damage_label,17)
		label(content,"%.1f%%"%(damage/total*100),17,"8fdac8").position=Vector2(785,y)
	var row=HBoxContainer.new();row.position=Vector2(100,800);row.size=Vector2(1240,60);row.add_theme_constant_override("separation",16);menu_root.add_child(row)
	button(row,"RUN IT BACK",start_run,true).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button(row,"Today's build" if sim.mode=="daily" else "Change survivor",daily_menu if sim.mode=="daily" else characters).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button(row,"Leaderboard" if sim.mode=="daily" else "Run report",daily_records_menu if sim.mode=="daily" else func():export_report(true)).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button(row,"Main menu",main_menu).size_flags_horizontal=Control.SIZE_EXPAND_FILL

func research_menu():
	clear_menu();shade(0.94);page="research"
	label(menu_root,"THE ARCHIVE / %s AMBER"%int(save_data.amber),27,"e7c88c").position=Vector2(100,45)
	label(menu_root,"Permanent upgrades · expedition only",21,"b9ced3").position=Vector2(100,88)
	var refund=button(menu_root,"Reset upgrades / refund amber",func():archive_refund_menu(true))
	refund.position=Vector2(885,65);refund.size=Vector2(455,56)
	refund.disabled=preload("res://scripts/archive_respec.gd").research_total(save_data)<=0
	var grid=GridContainer.new();grid.columns=3;grid.position=Vector2(100,145);grid.size=Vector2(1240,590)
	grid.add_theme_constant_override("h_separation",14);grid.add_theme_constant_override("v_separation",12);menu_root.add_child(grid)
	for id in C.RESEARCH:
		var r=C.RESEARCH[id];var rank_value=int(save_data.research.get(id,0));var cost=int(r.cost*pow(1.65,rank_value))
		var b=button(grid,"%s  %s/%s\n%s\n%s"%[r.name,rank_value,r.max,UIArt.wrap_copy(r.desc,preload("res://scripts/ui_art.gd").body_font(),16,240),"MAXED" if rank_value>=r.max else str(cost)+" AMBER"],func():buy(id))
		b.icon=Icons.get_icon(id,"research");b.expand_icon=true;b.add_theme_constant_override("icon_max_width",42);b.add_theme_constant_override("h_separation",12)
		b.custom_minimum_size=Vector2(404,110);b.add_theme_font_size_override("font_size",16)
		b.add_theme_font_override("font",preload("res://scripts/ui_art.gd").body_font())
		b.disabled=rank_value>=r.max or save_data.amber<cost
	var back=button(menu_root,"Main menu",main_menu,true);back.position=Vector2(100,785);back.size=Vector2(390,60)
	var records=button(menu_root,"Local records",records_menu);records.position=Vector2(515,785);records.size=Vector2(400,60)
	var discoveries=button(menu_root,"Discoveries",discovery_menu);discoveries.position=Vector2(940,785);discoveries.size=Vector2(400,60)

func records_menu():
	clear_menu();shade(0.94);page="records"
	var v=column(menu_root,Vector2(150,90),Vector2(1140,700),16)
	label(v,"LOCAL RECORDS / THIS COMPUTER",32,"e7c88c")
	for record in save_data.records.slice(0,12):
		label(v,"%s    %s    %s    %s / v%s"%[int(record.score),record.hero,record.mode.to_upper(),record.date,record.get("ruleset","0.2")],21)
	button(v,"Back to archive",research_menu)

func buy(id):
	if not preload("res://scripts/archive_respec.gd").buy_research(save_data,id):return
	persist()
	research_menu()

func archive_refund_menu(research_only):
	clear_menu();shade(0.96);page="archive-refund"
	var respec=preload("res://scripts/archive_respec.gd")
	var amount=respec.research_total(save_data) if research_only else respec.discovery_total(save_data)
	var v=column(menu_root,Vector2(190,180),Vector2(1060,540),24)
	label(v,"RESET PERMANENT UPGRADES" if research_only else "REFUND PAID UNLOCKS",30,"e7c88c")
	label(v,"Return %s amber to your balance."%amount,27,"ead6aa")
	var copy="All purchased permanent upgrade ranks return to zero. Discoveries and unlocked equipment remain yours." if research_only else "Paid characters and equipment become locked again. Found discoveries stay found, ready to purchase again. Free characters, free equipment and unlocked maps stay yours. If your selected character is relocked, Vesper becomes selected."
	copy+="\nYour runs, records, discovered recipes and milestone progress are preserved."
	var details=label(v,copy,22,"c7c3b4");details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button(v,"Confirm refund / %s amber"%amount,func():
		if research_only:respec.refund_research(save_data)
		else:
			respec.refund_discoveries(save_data)
			if not Discoveries.hero_open(save_data,selected):selected=2
		persist()
		if research_only:research_menu()
		else:discovery_menu(),true)
	button(v,"Keep my upgrades" if research_only else "Keep my unlocks",research_menu if research_only else discovery_menu)

func manual():
	clear_menu()
	shade(0.95)
	var v = column(menu_root,Vector2(130,95),Vector2(1180,700),20)
	label(v,"FIELD MANUAL",45)
	label(v,"WASD / arrows: move. Every attack aims and fires automatically.\n1 / 2 / 3: upgrades. Tab: overlay map. B: backpack & stats. Esc: pause. F11: fullscreen.",21)
	label(v,"THE BUILD",18,"d6b27e")
	label(v,"Five weapons. Eight passive/augment types. Eight relics. Max weapon rank + chest evolves.\nTwo compatible rank-10 weapons + chest merge, freeing one slot.\nChest odds include Luck and Fortune research. Rocks block; mud slows; lava burns.",21,"b4c6c9")
	label(v,"THE DESCENT",18,"d6b27e")
	label(v,"Bosses arrive at 5, 10 and 15 minutes. The first two open harder biomes.\nThe meteor is an endgame build check: destroy three anchors to expose its core.\nYou have 12 seconds per opening. Phase transitions restore its armor.\nIt enrages at 150 seconds and completes extinction at 210. Read the ground warnings.",21,"b4c6c9")
	label(v,"Explore map signals, then spend amber on discoveries in the archive.\nFull slots: improve equipped buffs. Maxed builds receive amber and healing.\nDeath banks amber. Daily rolls each reward automatically; trial uses prepared gear. Records are local.",18,"adc1bd")
	button(v,"I'LL MAKE HISTORY",main_menu,true)

func settings():
	clear_menu()
	shade(0.94)
	var v = column(menu_root,Vector2(410,170),Vector2(620,560),22)
	label(v,"Make the apocalypse yours.",36)
	for key in ["sound","music","shake"]:
		var check = CheckButton.new()
		check.text = {"sound":"Sound effects","music":"Procedural soundtrack","shake":"Screen shake"}[key]
		check.button_pressed = save_data.settings[key]
		check.custom_minimum_size.y = 55
		check.toggled.connect(func(value):save_data.settings[key]=value;apply_settings();persist())
		v.add_child(check)
	label(v,"HUD size (live preview; menus stay readable)",18,"b8cdd3")
	var scale_slider = HSlider.new()
	scale_slider.min_value = 0.65
	scale_slider.max_value = 1.35
	scale_slider.step = 0.05
	scale_slider.value = save_data.settings.get("hud_scale",1.0)
	scale_slider.custom_minimum_size = Vector2(500,25)
	scale_slider.value_changed.connect(func(value):save_data.settings.hud_scale=value;persist())
	v.add_child(scale_slider)
	button(v,"Toggle fullscreen / F11",func():DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN))
	button(v,"Back",func():pause_menu() if sim!=null and sim.active else main_menu())

func apply_settings():
	audio.enabled = save_data.settings.sound
	audio.music_enabled = save_data.settings.music
	world.shake_enabled = save_data.settings.shake

func load_progress():
	var result=preload("res://scripts/profile_store.gd").load_profile(progress_path)
	save_data=result.data
	save_error=result.message
	save_blocked=result.blocked

func persist():
	if save_blocked: return
	save_error=preload("res://scripts/profile_store.gd").save_profile(progress_path,save_data)

func export_report(open_folder):
	if sim==null: return
	DirAccess.make_dir_recursive_absolute("user://reports")
	var path = "user://reports/run-%s.json"%Time.get_datetime_string_from_system().replace(":","-")
	var file = FileAccess.open(path,FileAccess.WRITE)
	if file!=null:
		file.store_string(JSON.stringify(sim.report(),"\t"))
		file.close()
	if open_folder: OS.shell_open(ProjectSettings.globalize_path("user://reports"))

func _exit_tree():
	release_run()
	Icons.cache.clear()

func release_run():
	if is_instance_valid(defeat_cinematic): defeat_cinematic.queue_free()
	defeat_cinematic=null
	if world!=null: world.sim = null
	if sim!=null:
		for signal_name in ["effect","sound","banner","choice_requested","ended","discovered_content"]:
			for connection in sim.get_signal_connection_list(signal_name):
				sim.disconnect(signal_name,connection.callable)
	sim = null



func daily_records_menu():
	page="daily-records";clear_menu();shade(0.96)
	var v=column(menu_root,Vector2(120,75),Vector2(1200,750),18)
	label(v,"DAILY SURVIVAL / LOCAL LEADERBOARD",32,"ead19b")
	label(v,Time.get_date_string_from_system(true)+" · Longest survival first, then kills, then score.",18)
	var records=save_data.get("daily_records",[]).filter(func(r):return r.date==Time.get_date_string_from_system(true) and r.get("ruleset","")==Expedition.Daily.RULESET)
	records.sort_custom(func(a,b):return a.seconds>b.seconds if a.seconds!=b.seconds else a.kills>b.kills if a.kills!=b.kills else a.score>b.score)
	var table=GridContainer.new();table.columns=6;table.add_theme_constant_override("h_separation",32);table.add_theme_constant_override("v_separation",16);v.add_child(table)
	for name in ["RANK","SURVIVED","KILLS","SCORE","BOSSES","CIRCUIT"]:label(table,name,18,"d4b575").custom_minimum_size.x=150
	for i in range(mini(10,records.size())):
		var r=records[i]
		for text in [str(i+1),"%02d:%02d"%[int(r.seconds)/60,int(r.seconds)%60],str(int(r.kills)),str(int(r.score)),str(int(r.bosses)),str(int(r.circuit))]:label(table,text,22)
	if records.is_empty():label(v,"No attempts today. Your next daily run will be recorded here.",20)
	button(v,"Today's random build",daily_menu,true)
	button(v,"Main menu",main_menu)

func patch_notes(index=0):
	page="patch_notes"
	clear_menu()
	shade(0.80)
	UIArt.plate(menu_root,2,Rect2(70,25,1300,810))
	var releases=PatchNotes.releases()
	index=clampi(index,0,releases.size()-1)
	var selected_release=releases[index]
	var selector=OptionButton.new();selector.position=Vector2(200,246);selector.size=Vector2(280,44)
	selector.add_theme_font_override("font",UIArt.heading_font())
	for state in ["normal","hover","pressed"]:selector.add_theme_stylebox_override(state,UIArt.button_style(state))
	for item in releases:selector.add_item("Version "+item.version)
	selector.select(index);selector.item_selected.connect(patch_notes);menu_root.add_child(selector)
	var release_heading=label(menu_root,selected_release.title,26,"ecd19a")
	release_heading.position=Vector2(510,248);release_heading.size=Vector2(730,44)
	release_heading.clip_text=true
	UIArt.fit_label(release_heading,26,18)
	var scroll=ScrollContainer.new();scroll.position=Vector2(200,305);scroll.size=Vector2(1040,395);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;menu_root.add_child(scroll)
	var content=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_theme_constant_override("separation",14);scroll.add_child(content)
	for entry in selected_release.entries:
		var row=HBoxContainer.new();row.add_theme_constant_override("separation",22);content.add_child(row)
		var icon=TextureRect.new();icon.texture=Icons.get_icon(entry.icon,entry.get("category","weapon"));icon.custom_minimum_size=Vector2(60,60);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;row.add_child(icon)
		var copy=VBoxContainer.new();copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;copy.add_theme_constant_override("separation",4);row.add_child(copy)
		if entry.title!="":
			var heading=label(copy,entry.title,23,"dfbd7b");heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		var body=label(copy,entry.body,18,"d3cbb8");body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var back=button(menu_root,"Return to main menu",main_menu,true)
	back.position=Vector2(490,750);back.size=Vector2(460,58)
	var newer=button(menu_root,"Newer",func():patch_notes(index-1));newer.position=Vector2(200,750);newer.size=Vector2(260,58);newer.disabled=index==0
	var older=button(menu_root,"Older",func():patch_notes(index+1));older.position=Vector2(980,750);older.size=Vector2(260,58);older.disabled=index==releases.size()-1
	var latest=button(menu_root,"Latest",func():patch_notes(0));latest.position=Vector2(1030,704);latest.size=Vector2(210,42);latest.custom_minimum_size.y=42







