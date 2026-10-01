from pathlib import Path
p=Path('native/scripts/main.gd');s=p.read_text(encoding='utf-8-sig')
s=s.replace('var progress_path =','const UIArt=preload("res://scripts/ui_art.gd")\nconst UpgradeCopy=preload("res://scripts/upgrade_copy.gd")\nvar score_plate\nvar timer_plate\nvar progress_path =')
s=s.replace('func():chosen_mode="daily";characters()','daily_menu')
s=s.replace('func build_hud():','''func daily_menu():
	chosen_mode="daily"
	page="daily"
	clear_menu();shade(0.92)
	var plan=Expedition.Daily.plan(hash("0.8/"+Time.get_date_string_from_system(true)))
	var v=column(menu_root,Vector2(170,100),Vector2(1100,700),20)
	label(v,"DAILY EXPEDITION / "+Time.get_date_string_from_system(true),22,"e6c58c")
	label(v,C.HEROES[plan.hero].name+" / "+Maps.DATA[plan.map].name,34)
	label(v,"A fixed build. A shared seed. Beat all three bosses.",24)
	label(v,"Gear arrives automatically as you level. Chests award a fixed relic order or an evolution.\nNo rerolls, permanent bonuses, or gear choices. Records are stored on this computer.",20,"b2cdd3")
	var icons=HBoxContainer.new();icons.add_theme_constant_override("separation",24);v.add_child(icons)
	for id in plan.weapons:
		var col=VBoxContainer.new();icons.add_child(col)
		Icons.control(col,id,"weapon",90)
		label(col,C.WEAPONS[id].name,17)
	label(v,"Levels 2–5: receive the remaining weapons. Then improve the lowest-ranked weapon.\nFrom level 15: gain two weapon ranks. Every third level: a scheduled stat upgrade.",19,"e0cfab")
	button(v,"PLAY TODAY'S BUILD",func():selected=plan.hero;start_run(),true)
	button(v,"Main menu",main_menu)

func build_hud():''')
s=s.replace('hash("0.7/"','hash("0.8/"')
s=s.replace('\tvar left = column(hud_root','\tscore_plate=UIArt.plate(hud_root,0,Rect2(1080,10,350,96))\n\ttimer_plate=UIArt.plate(hud_root,1,Rect2(8,8,420,116))\n\tvar left = column(hud_root')
s=s.replace('var factor = clampf(pow(1.0/pixel_ratio,0.45),0.65,1.15)*float(save_data.settings.get("hud_scale",1.0))','var factor = clampf(float(save_data.settings.get("hud_scale",1.0)),0.65,1.35)')
s=s.replace('timer_label.position = Vector2(24,18)*factor','timer_plate.position=Vector2(8,8)*factor\n\tscore_plate.position=Vector2(viewport.x-358*factor,8*factor)\n\ttimer_label.position = Vector2(48,25)*factor')
s=s.replace('biome_label.position = Vector2(24,63)*factor','biome_label.position = Vector2(48,68)*factor')
s=s.replace('score_label.position = Vector2(viewport.x-310*factor,18*factor)','score_label.position = Vector2(viewport.x-300*factor,28*factor)')
s=s.replace('boss_bar.position = Vector2(viewport.x/2-330*factor,64*factor)','var boss_y=112.0 if viewport.x<1900*factor else 12.0\n\tboss_bar.position = Vector2(viewport.x/2-330*factor,(boss_y+50)*factor)')
s=s.replace('boss_label.position = Vector2(viewport.x/2-420*factor,18*factor)','boss_label.position = Vector2(viewport.x/2-420*factor,boss_y*factor)')
s=s.replace('(250 if viewport.x<1800 and sim!=null and sim.boss!=null else 100)*factor','120*factor')
s=s.replace('xp_bar.position = Vector2(20,viewport.y-23)\n\txp_bar.size = Vector2(viewport.x-40,20)','xp_bar.position = Vector2(20,viewport.y-23*factor)\n\txp_bar.size = Vector2(viewport.x-40,20*factor)')
s=s.replace('scale_slider.min_value = 0.75','scale_slider.min_value = 0.65').replace('scale_slider.max_value = 1.1','scale_slider.max_value = 1.35')
s=s.replace('HUD size (automatic resolution scaling + preference)','HUD size (live preview; menus stay readable)')
s=s.replace('\t\tpanel.size_flags_horizontal = Control.SIZE_EXPAND_FILL\n\t\trow.add_child(panel)','\t\tpanel.size_flags_horizontal = Control.SIZE_EXPAND_FILL\n\t\tpanel.add_theme_stylebox_override("panel",UIArt.style())\n\t\trow.add_child(panel)')
a=s.index('\t\tvar tag_label = label(v,',s.index('func upgrade_menu'))
b=s.index('\t\tvar description = label(v,desc',a)
s=s[:a]+'''		var title = data.evolution if o.type=="evolution" else data.name
		var name_label = label(v,title,27)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var desc = UpgradeCopy.description(sim,o)
		var affected=UpgradeCopy.affected(sim,o)
		label(v,"AFFECTS YOUR WEAPONS" if not affected.is_empty() else "NEW WEAPON" if o.type=="weapon" else "SURVIVOR BONUS",13,"e2c691")
		var icon_row=HBoxContainer.new();icon_row.add_theme_constant_override("separation",8);v.add_child(icon_row)
		for id in affected:
			var icon=Icons.control(icon_row,id,"weapon",42)
			icon.tooltip_text=C.WEAPONS[id].name
			icon.mouse_filter=Control.MOUSE_FILTER_PASS
		if o.type=="weapon":
			desc+="\\nMax rank + chest: evolves."
			var hint=sim.Evolutions.hint(o.id,C.WEAPONS)
			if hint!="": desc+="\\n"+hint.replace("Union: ","Merge: ").replace(" (chest)","")
'''+s[b:]
a=s.index('func research_menu():');b=s.index('\nfunc buy(id):',a)
s=s[:a]+'''func research_menu():
	clear_menu();shade(0.94);page="research"
	label(menu_root,"THE ARCHIVE / %s AMBER"%int(save_data.amber),27,"e7c88c").position=Vector2(100,45)
	label(menu_root,"Permanent upgrades · expedition only",21,"b9ced3").position=Vector2(100,88)
	var grid=GridContainer.new();grid.columns=3;grid.position=Vector2(100,145);grid.size=Vector2(1240,590)
	grid.add_theme_constant_override("h_separation",14);grid.add_theme_constant_override("v_separation",12);menu_root.add_child(grid)
	for id in C.RESEARCH:
		var r=C.RESEARCH[id];var rank_value=int(save_data.research.get(id,0));var cost=int(r.cost*pow(1.65,rank_value))
		var b=button(grid,"%s  %s/%s\\n%s\\n%s"%[r.name,rank_value,r.max,r.desc,"MAXED" if rank_value>=r.max else str(cost)+" AMBER"],func():buy(id))
		b.custom_minimum_size=Vector2(404,120);b.add_theme_font_size_override("font_size",17)
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
''' +s[b:]
a=s.index('func summary():');b=s.index('\nfunc research_menu():',a)
s=s[:a]+'''func summary():
	page="summary";clear_menu();shade(0.82)
	UIArt.plate(menu_root,2,Rect2(90,12,1260,770))
	label(menu_root,"EXTINCTION DENIED" if sim.won else "EXPEDITION COMPLETE",36,"f4d49b").position=Vector2(190,212)
	label(menu_root,"%s · %02d:%02d · %s · %s"%[C.HEROES[sim.hero].name,int(sim.time)/60,int(sim.time)%60,sim.mode.to_upper(),Maps.DATA[sim.map_id].name],19,"b7cbd0").position=Vector2(190,262)
	var grid=GridContainer.new();grid.columns=3;grid.position=Vector2(190,305);grid.size=Vector2(1060,150);grid.add_theme_constant_override("h_separation",70);menu_root.add_child(grid)
	for metric in [["SCORE",sim.score],["KILLS",sim.kills],["AMBER",0 if sim.mode=="safari" else int(sim.amber*sim.fortune)],["BEST STREAK",sim.best_streak],["PEAK HORDE",sim.peak_enemies],["HITS TAKEN",sim.hits]]:
		var v=VBoxContainer.new();v.custom_minimum_size=Vector2(275,70);grid.add_child(v);label(v,metric[0],14,"afbdc2");label(v,str(metric[1]),28,"f0d098")
	label(menu_root,"WEAPON                         DAMAGE                 SHARE",16,"b7cbd0").position=Vector2(190,490)
	var ids=sim.damage_by_weapon.keys();ids.sort_custom(func(a,b):return sim.damage_by_weapon[a]>sim.damage_by_weapon[b])
	var total=maxf(1,sim.damage_total)
	for i in range(mini(5,ids.size())):
		var id=ids[i];var damage=sim.damage_by_weapon[id]
		var icon=Icons.control(menu_root,id,"weapon",29);icon.position=Vector2(190,522+i*33)
		label(menu_root,C.WEAPONS.get(id,{"name":"Relics"}).name,18,"e4d9c3").position=Vector2(228,523+i*33)
		label(menu_root,str(int(damage)),18).position=Vector2(620,523+i*33)
		label(menu_root,"%.1f%%"%(damage/total*100),18,"8fdac8").position=Vector2(875,523+i*33)
	if not sim.won: label(menu_root,sim.death_reason,17,"ecb4a4").position=Vector2(190,704)
	var row=HBoxContainer.new();row.position=Vector2(100,800);row.size=Vector2(1240,60);row.add_theme_constant_override("separation",16);menu_root.add_child(row)
	button(row,"RUN IT BACK",start_run,true).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button(row,"Change survivor",characters).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button(row,"Run report",func():export_report(true)).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button(row,"Main menu",main_menu).size_flags_horizontal=Control.SIZE_EXPAND_FILL
''' +s[b:]
s=s.replace('Rank VIII + linked passive II + chest evolves.','Max weapon rank + chest evolves.').replace('Two compatible rank-X weapons + chest unite, freeing one slot.','Max weapon + compatible partner (any rank) + chest merge, freeing one slot.').replace('Daily/trial use the full catalog and clean stats.','Daily uses a fixed automatic build; trial uses prepared gear.').replace('"ruleset":"0.7"','"ruleset":"0.8"')
p.write_text(s,encoding='utf-8')
print('UI updated')
