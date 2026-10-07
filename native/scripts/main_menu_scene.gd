extends RefCounted
static func create(g,seasonal):
 var v=g.column(g.menu_root,Vector2(90,58),Vector2(600,798),10)
 g.label(v,"HOLLOW HARVEST  /  LIMITED EVENT" if seasonal else "A WORLD OUT OF TIME",13,"d3aa6d")
 v.add_child(preload("res://scripts/official_brand.gd").logo(170))
 g.label(v,"The end of the world has a health bar.",23,"e6dac0")
 g.label(v,"Guns. Ancient fury. Forbidden magic.",17,"a7b9b6")
 separator(v)
 add_button(g,v,"ENTER THE RIFT",func():g.chosen_mode="expedition";g.characters(),true).custom_minimum_size.y=76
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",12);v.add_child(row)
 add_button(g,row,"Daily challenge",g.daily_menu)
 add_button(g,row,"Meteor trial",func():g.chosen_mode="safari";g.characters())
 add_button(g,v,"Permanent upgrades",g.research_menu)
 add_button(g,v,"Discoveries",g.discovery_menu)
 add_button(g,v,"Field manual",g.manual)
 var row2=HBoxContainer.new();row2.add_theme_constant_override("separation",12);v.add_child(row2)
 add_button(g,row2,"Settings",g.settings)
 add_button(g,row2,"Quit",func():g.get_tree().quit())
 g.label(v,"%s AMBER     /     %s EXTINCTIONS DENIED"%[int(g.save_data.amber),int(g.save_data.wins)],14,"c5ac82")
 g.label(v,"EXTINCTION PROTOCOL  /  "+ProjectSettings.get_setting("application/config/version"),12,"809492")
 if g.save_error!="":g.label(v,g.save_error,14,"ff877e")
 var caption=g.column(g.menu_root,Vector2(900,730),Vector2(430,100),9)
 g.label(caption,"THE HOLLOW HARVEST" if seasonal else "SURVIVE THE IMPOSSIBLE",25,"f1ce98")
 var flavor=g.label(caption,"The rift burns. The hunt continues." if seasonal else "Survive the ecosystem. Kill the extinction.",17,"c3cbc6")
 flavor.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 var news=preload("res://scripts/main_menu_panel.gd").new()
 news.position=Vector2(900,92);news.size=Vector2(425,420)
 var plate=g.box(Color.TRANSPARENT,Color.TRANSPARENT,3)
 plate.content_margin_left=40;plate.content_margin_right=40;plate.content_margin_top=78;plate.content_margin_bottom=62
 news.add_theme_stylebox_override("panel",plate);g.menu_root.add_child(news)
 var info=VBoxContainer.new();info.add_theme_constant_override("separation",14);news.add_child(info)
 g.label(info,"LATEST FROM THE RIFT  /  "+g.PatchNotes.VERSION,13,"d8b16d")
 var headline=g.label(info,g.PatchNotes.TITLE,24,"f0dfbd");headline.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 var teaser=g.label(info,"The latest changes, improvements and expedition news.",17,"aebbb7");teaser.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 separator(info)
 add_button(g,info,"Patch notes",g.patch_notes)
 add_button(g,info,"Opening cinematic",g.play_opening)
static func add_button(g,parent,text,callback,primary=false):
 var b=preload("res://scripts/main_menu_button.gd").new()
 b.text=text;b.primary=primary;b.custom_minimum_size=Vector2(140,60)
 b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 b.pressed.connect(func():g.audio.play("loot",-21,1.4);callback.call())
 parent.add_child(b)
 return b

static func separator(parent):
 var line=HSeparator.new();var style=StyleBoxFlat.new();style.bg_color=Color("785d36");style.content_margin_top=1
 line.add_theme_stylebox_override("separator",style);parent.add_child(line)
